
-- ============================================================
-- Elever från Skola24 (SS12000 persons)
--
-- persons går inte att lista i Skola24:s API -- eleverna är de personer som
-- förekommer i gruppmedlemskap (ingest hämtar dem via persons/lookup).
--
-- Klass + skola: aktivt medlemskap i grupp av typen 'Klass' (samma princip
-- som elever_schoolsoft). Övriga grupptyper (Undervisning, Schema, Övrigt)
-- används inte här.
--
-- elev_id = SHA2_256(personnummer), samma formel och datatyp (nvarchar) som
-- elever_anonymisering, så att Skola24-elever kan kopplas till d_elever.
-- ============================================================

with
persons         as (select * from {{ ref('skola24_persons') }}),
organisations   as (select * from {{ ref('skola_skola24') }}),

-- StartDate <= idag utesluter klasser satta för nästa läsår
klass as (
    select
         person_id
        ,group_display_name         as klass_namn
        ,lower(organisation_id)     as skola_id
        ,row_number() over (partition by person_id order by start_date desc) as rn
    from {{ ref('skola24_group_memberships') }}
    where group_type = 'Klass'
    and cast(start_date as date) <= cast(getdate() as date)
    and (end_date is null or cast(end_date as date) >= cast(getdate() as date))
),

aktiv_klass as (
    select person_id, klass_namn, skola_id from klass where rn = 1
),

-- Elever utan klassgrupp (ca 10 %) får skola från sitt senaste aktiva
-- medlemskap i valfri grupp (Undervisning/Schema/Övrigt) i stället.
skola_fallback as (
    select
         person_id
        ,lower(organisation_id)     as skola_id
        ,row_number() over (partition by person_id order by start_date desc) as rn
    from {{ ref('skola24_group_memberships') }}
    where cast(start_date as date) <= cast(getdate() as date)
    and (end_date is null or cast(end_date as date) >= cast(getdate() as date))
)

select
     convert(varchar(64), hashbytes('SHA2_256', p.civic_no__value), 2)     as elev_id
    ,p.id                                                                   as elev_id_skola24
    ,p.civic_no__value                                                      as personnummer
    ,coalesce(k.skola_id, f.skola_id)                                       as skola_id
    ,o.skola_namn
    ,k.klass_namn                                                           as klass
    ,p.given_name                                                           as förnamn
    ,p.family_name                                                          as efternamn
    ,cast(p.birth_date as date)                                             as födelsedag
    ,year(cast(p.birth_date as date))                                       as födelseår
    ,case   when p.sex = 'Kvinna' then 'Flicka'
            when p.sex = 'Man'    then 'Pojke'
            -- Skola24 anger ofta 'Okänt' -- fall tillbaka på personnumrets näst sista siffra
            when try_cast(substring(p.civic_no__value, 11, 1) as int) % 2 = 0 then 'Flicka'
            when try_cast(substring(p.civic_no__value, 11, 1) as int) % 2 = 1 then 'Pojke' end as kön
    ,cast(floor(datediff(day, cast(p.birth_date as date), getdate()) / 365.25) as int) as ålder
    ,case when coalesce(k.person_id, f.person_id) is not null then 1 else 0 end as is_aktiv_elev
    ,case when p.civic_no__value like '%tf%' then 1 else 0 end              as is_pnr_error
    ,cast(getdate() as date)                                                as senaste_uppdaterad
from
            persons         as p
left join   aktiv_klass     as k    on p.id = k.person_id
left join   skola_fallback  as f    on p.id = f.person_id and f.rn = 1
left join   organisations   as o    on coalesce(k.skola_id, f.skola_id) = o.skola_id
