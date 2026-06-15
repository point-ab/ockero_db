
with ea_barn as (
    select
        personnummer
        ,folkbokf_ringskommun    as kommun_folkbokföring
        ,kull        as årskull
        ,'Förskola'  as skolform
        ,f_rskola    as skola
        ,avdelning   as klass
        ,{{ clean_uppercase_text('postort') }}  as post_ort
        ,intern_extern
        ,cast(getdate() as date) as senaste_uppdaterad --- Måste justeras!!! , ändra kanske till pyhton ingest tills IT är klara
    from
        {{ ref('schoolsoft_api_ea_barn') }}

union all
    select
        personnummer
        ,folkbokf_ringskommun  as kommun_folkbokföring
        ,kull      as årskull
        ,case   when skolform like 'Gymnasie%'              then 'Gymnasieskola' 
                when skolform like 'Anpassad grundskola'    then 'Grundskola anpassad' else skolform end as skolform
        ,skola
        ,klass
        ,{{ clean_uppercase_text('postort') }}  as post_ort
        ,case when skola = 'Skolpliktsbevakning' then 'Intern' else intern_extern end as intern_extern
        ,cast(getdate() as date) as senaste_uppdaterad --- Måste justeras!!! , ändra kanske till pyhton ingest tills IT är klara
    from
        {{ ref('schoolsoft_api_ea_elever') }}
)

    select
        cast(personnummer           as varchar(32)) as personnummer
        ,cast(kommun_folkbokföring  as varchar(64)) as kommun_folkbokföring
        ,cast(årskull               as int)         as årskull
        ,cast(skolform              as varchar(32)) as skolform
        ,cast(skola                 as varchar(64)) as skola
        ,cast(klass                 as varchar(32)) as klass
        ,cast(post_ort              as varchar(32)) as post_ort
        ,cast(intern_extern         as varchar(16)) as intern_extern
        ,senaste_uppdaterad

        ,case   when cast(substring(personnummer, 11, 1) as int) % 2 = 0 then 'Flicka'
                when cast(substring(personnummer, 11, 1) as int) % 2 = 1 then 'Pojke' end as kön

        ,1  as is_aktiv_elev
        ,case   when kommun_folkbokföring = 'Öckerö'    then 1
                when kommun_folkbokföring is not null   then 0 else -1 end  as is_öckerö_kommun
        ,case   when intern_extern = 'Intern'           then 1
                when intern_extern = 'Extern'           then 0  else -1 end as is_kommunal_verksamhet
    from
        ea_barn
    where
         personnummer not like '%TF%'
    and skolform is not null
    and skolform <> ''