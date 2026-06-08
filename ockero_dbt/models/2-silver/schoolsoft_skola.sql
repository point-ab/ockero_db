
with organisations as (
    select * from {{ ref('schoolsoft_organisations') }}
),

-- Pivotera OrganisationSchoolTypes till en rad per organisation
school_types as (
    select
         OrganisationSourceId
        ,max(case when SchoolType = 'FS'                    then 1 else 0 end) as is_förskola
        ,max(case when SchoolType = 'FKLASS'                then 1 else 0 end) as is_forskoleklass
        ,max(case when SchoolType = 'GR'                    then 1 else 0 end) as is_grundskola
        ,max(case when SchoolType = 'GRS'                   then 1 else 0 end) as is_grundskola_anpassad
        ,max(case when SchoolType = 'GY'                    then 1 else 0 end) as is_gymnasieskola
        ,max(case when SchoolType = 'GYS'                   then 1 else 0 end) as is_gymnasieskola_anpassad
        ,max(case when SchoolType in ('FTH', 'OPPFTH')      then 1 else 0 end) as is_fritidshem
    from {{ ref('schoolsoft_organisation_school_types') }}
    group by OrganisationSourceId
)

select
     lower(o.SourceId)                                          as skola_id
    --,o.SchoolSoftId                                             as org_schoolsoft_id
    ,o.DisplayName                                              as skola_namn
    ,case when o.EndDate is null then 1 else 0 end              as is_aktiv_skola
    ,case when o.MunicipalityCode = '1407' then 1 else 0 end    as is_kommunal

    -- Huvudsaklig skolform: primär verksamhet, inte specialspår
    -- Skolor med GRS/GYS men även GR/GY räknas som vanlig grundskola/gymnasie
    ,case   when coalesce(st.is_förskola, 0) = 1       then 'Förskola'
            when coalesce(st.is_gymnasieskola, 0) = 1  then 'Gymnasieskola'
            when coalesce(st.is_grundskola, 0) = 1     then 'Grundskola'  end   as skola_typ_org

    -- Typ-flaggor (en per verksamhetsform, från OrganisationSchoolTypes)
    ,coalesce(st.is_förskola, 0)                                as is_förskola
    ,coalesce(st.is_forskoleklass, 0)                           as is_forskoleklass
    ,coalesce(st.is_grundskola, 0)                              as is_grundskola
    ,coalesce(st.is_grundskola_anpassad, 0)                     as is_grundskola_anpassad
    ,coalesce(st.is_gymnasieskola, 0)                           as is_gymnasieskola
    ,coalesce(st.is_gymnasieskola_anpassad, 0)                  as is_gymnasieskola_anpassad
    ,coalesce(st.is_fritidshem, 0)                              as is_fritidshem

from
            organisations   as o
left join   school_types    as st   on o.SourceId = st.OrganisationSourceId

where o.enddate is null
