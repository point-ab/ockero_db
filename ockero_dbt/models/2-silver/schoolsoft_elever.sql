
-- ============================================================
-- Elever från SS12000 via SchoolSoft
--
-- Källa 1: PersonEnrolments → Grundskola (GR/GRS) + Gymnasieskola (GY)
-- Källa 2: Placements (SchoolType=FS) → Förskola
--
-- Klass-kolumn:
--   GR/GRS/GY → PersonGroupMemberships (GroupType='Klass')
--   FS        → Placements.GroupDisplayName (avdelning)
--
-- Årskurs-mapping:
--   GY            → 'G ' + SchoolYear  (ex: 'G 1', 'G 2', 'G 3')
--   GR/GRS, år=0  → 'FK'              (Förskoleklass)
--   GR/GRS, år>0  → '1'..'9'
--   FS            → 'F'
--
-- is_kommunal_verksamhet: Organisations.MunicipalityCode = '1407' (Öckerö)
-- is_öckerö_kommun:       PostalCode (475xx eller 430 90-97)
-- Kulturskolan exkluderas - ingår ej i skolstatistiken
-- ============================================================

with 
persons             as (select * from   {{ ref('schoolsoft_persons') }}),
addresses           as (select * from   {{ ref('schoolsoft_persons_addresses') }}),
placement           as (select * from   {{ ref('schoolsoft_placements') }}),
placement_persons   as (select * from   {{ ref('schoolsoft_placement_persons') }}),
organisations       as (select * from   {{ ref('schoolsoft_skola') }}),
enrolments_ranked as (
    select
        *
        ,row_number() over (partition by PersonSourceId order by SequenceNo desc) as rn
    from
        {{ ref('schoolsoft_persons_enrolments') }}
    where
        EnroledAtDisplayName != 'Kulturskolan'
    and SchoolYear is not null
    and EndDate is null
),

enrolments as (select * from enrolments_ranked where rn = 1),


-- StartDate <= today utesluter klasser satta för nästa läsår (aug+)
klass as (
    select
         PersonSourceId
        ,GroupDisplayName   as klass_namn
        ,row_number() over (partition by PersonSourceId order by StartDate desc) as rn
    from {{ ref('schoolsoft_person_group_memberships') }}
    where GroupType = 'Klass'
    and StartDate <= cast(getdate() as date)
    and (EndDate is null or EndDate >= cast(getdate() as date))
),

aktiv_klass as (
    select PersonSourceId, klass_namn from klass where rn = 1
),

fritids as (
    select distinct
         pp.PersonId    as person_schoolsoft_id
        ,1              as is_elev_fritids
    from
                placement           as pl
    inner join  placement_persons   as pp on pl.SchoolSoftId = pp.PlacementSchoolSoftId
    where pl.SchoolType = 'FTH'
    and pl.EndDate is null
),

-- ============================================================
-- Gren 1: Grundskola + Gymnasieskola (GR, GRS, GY)
-- Branch-specifika kolumner + råvärden som beräknas nedan
-- ============================================================
enrolment_raw as (
    select
         p.SourceId                                         as elev_id
        ,p.CivicNo                                          as personnummer
        ,lower(cast(pe.EnroledAtId as nvarchar(36)))        as skola_id
        ,cast(pe.StartDate as date)                         as start_datum_skola       
        ,cast(case when pe.StartDate is null then null else isnull(pe.EndDate, '3999-01-01') end as date) as slut_datum_skola
        ,p.GivenName                                        as förnamn
        ,p.FamilyName                                       as efternamn
        ,p.BirthDate                                        as birth_date
        ,p.Sex                                              as sex
        ,case pe.SchoolType
            when 'GR'  then 'Grundskola'
            when 'GRS' then 'Grundskola anpassad'
            when 'GY'  then 'Gymnasieskola'
            else pe.SchoolType end                          as skolform
        ,pe.SchoolType                                      as skolform_kort
        ,pe.EnroledAtDisplayName                            as skola_namn
        ,case
            when pe.SchoolType = 'GY' then 'G ' + cast(pe.SchoolYear as nvarchar(10))
            when pe.SchoolYear = 0    then 'FK'
            else cast(pe.SchoolYear as nvarchar(10))
        end                                                 as arskurs
        ,k.klass_namn                                       as klass
        ,coalesce(f.is_elev_fritids, 0)                     as is_elev_fritids
        ,a.Locality                                         as locality
        ,a.PostalCode                                       as post_kod
        ,case when pe.PersonSourceId is not null 
                and pe.EndDate is null
               and (pe.Cancelled is null or pe.Cancelled = 0)
              then 1 else 0 end                             as is_aktiv_elev
        ,coalesce(o.is_kommunal, 0)                         as is_kommunal_verksamhet
    from
                persons         as p
    left join   enrolments      as pe   on p.SourceId       = pe.PersonSourceId
    left join   addresses       as a    on p.SourceId       = a.PersonSourceId
    left join   aktiv_klass     as k    on p.SourceId       = k.PersonSourceId
    left join   organisations   as o    on o.skola_id       = pe.EnroledAtId
    left join   fritids         as f    on p.SchoolSoftId   = f.person_schoolsoft_id
),

-- ============================================================
-- Gren 2: Förskola via Placements (SchoolType = 'FS')
-- ============================================================
forskola_raw as (
    select
         p.SourceId                                         as elev_id
        ,p.CivicNo                                          as personnummer
        ,lower(cast(pl.PlacedAtId as nvarchar(36)))         as skola_id
        ,cast(pl.StartDate as date)                         as start_datum_skola
        ,cast('3999-01-01' as date)                         as slut_datum_skola
        ,p.GivenName                                        as förnamn
        ,p.FamilyName                                       as efternamn
        ,p.BirthDate                                        as birth_date
        ,p.Sex                                              as sex
        ,'Förskola'                                         as skolform
        ,'FS'                                               as skolform_kort
        ,pl.PlacedAtDisplayName                             as skola_namn
        ,'F'                                                as arskurs
        ,pl.GroupDisplayName                                as klass
        ,0                                                  as is_elev_fritids
        ,a.Locality                                         as locality
        ,a.PostalCode                                       as post_kod
        ,1                                                  as is_aktiv_elev
        ,coalesce(o.is_kommunal, 0)                         as is_kommunal_verksamhet
    from
                placement           as pl
    inner join  placement_persons   as pp   on pl.SchoolSoftId  = pp.PlacementSchoolSoftId
    inner join  persons             as p    on pp.PersonId      = p.SchoolSoftId
    left join   addresses           as a    on p.SourceId       = a.PersonSourceId
    left join   organisations       as o    on pl.PlacedAtId    = o.skola_id
    where pl.SchoolType = 'FS'
    and pl.EndDate is null
),

-- ============================================================
-- Kombinera grenar och applicera gemensamma beräkningar en gång
-- ============================================================
alla_elever as (
    select * from enrolment_raw
    union all
    select * from forskola_raw
)

select
    elev_id
    ,personnummer
    ,skola_id
    ,is_aktiv_elev
    ,start_datum_skola
    ,slut_datum_skola
    ,skolform
    ,skolform_kort
    ,skola_namn
    ,arskurs    as årskurs
    ,klass
    ,förnamn
    ,efternamn
    ,cast(birth_date as date)                                           as födelsedag
    ,year(birth_date)                                                   as födelseår
    ,case when sex = 'Kvinna' then 'Flicka' when sex = 'Man' then 'Pojke' end as kön
    ,cast(floor(datediff(day, birth_date, getdate()) / 365.25) as int)  as ålder
    ,case   when cast(floor(datediff(day, birth_date, getdate()) / 365.25) as int) between 0  and 6  then '0-6'
            when cast(floor(datediff(day, birth_date, getdate()) / 365.25) as int) between 7  and 10 then '7-10'
            when cast(floor(datediff(day, birth_date, getdate()) / 365.25) as int) between 11 and 16 then '11-16'
            when cast(floor(datediff(day, birth_date, getdate()) / 365.25) as int) between 17 and 80 then '16+' end as ålders_grupp

    ,is_elev_fritids
    ,{{ clean_uppercase_text('locality') }} as post_ort
    ,post_kod
    ,case when personnummer like '%tf%' then 1 else 0 end as is_pnr_error
    ,case
        when substring(post_kod, 1, 3) = '475'  then 1
        when coalesce(post_kod, '') = ''        then -1
        when post_kod in (
             '430 90' --Öckerö
            ,'430 93' --Hälsö
            ,'430 94' --Bohus-Björkö
            ,'430 95' --Källö-Knippla
            ,'430 92' --Fotö
            ,'430 97' --Rörö
            ,'430 96' --Hyppeln
        )       then 1 else 0 end as is_öckerö_kommun
    ,is_kommunal_verksamhet
    ,cast(getdate() as date)    as senaste_uppdaterad
from
    alla_elever
where
    cast(floor(datediff(day, birth_date, getdate()) / 365.25) as int) < 25
