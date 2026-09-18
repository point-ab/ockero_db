
with ea_barn as (
    select
        personnummer
        ,folkbokföringskommun    as kommun_folkbokföring
            --,folkbokf_ringskommun    as kommun_folkbokföring

        ,kull        as årskull
        ,'Förskola'  as skolform
        ,förskola    as skola
        ,'F'        as årskurs
            --,f_rskola        as skola
        ,avdelning   as klass
        ,{{ clean_uppercase_text('postort') }}  as post_ort
        ,[intern/extern] as intern_extern
            --,intern_extern
        ,1 as is_skolplikt
        ,cast([ImportedAtUtc] as date) as senaste_uppdaterad --- Måste justeras!!! , ändra kanske till pyhton ingest tills IT är klara
            --,cast(getdate() as date) as senaste_uppdaterad --- Måste justeras!!! , ändra kanske till pyhton ingest tills IT är klara
    from
        {{ ref('schoolsoft_ea_csv_barn') }}

union all
    select
        personnummer
        ,folkbokföringskommun  as kommun_folkbokföring
            --,folkbokf_ringskommun    as kommun_folkbokföring

        ,kull      as årskull
        ,case   when skolform like 'Gymnasie%'              then 'Gymnasieskola' 
                when skolform like 'Anpassad grundskola'    then 'Grundskola anpassad' 
                when kull >= case when month(getdate()) >= 7  then year(getdate()) - 15 else year(getdate()) - 16 end
                    and skolform = ''                       then 'Grundskola'                    
                       else skolform end as skolform
        
        
        
        ,skola
        ,årskurs
        ,klass
        ,{{ clean_uppercase_text('postort') }}  as post_ort
            --,case when skola = 'Skolpliktsbevakning' then 'Intern' else intern_extern end as intern_extern
        ,[intern/extern] as intern_extern
            --,intern_extern
        ,case when klass ='Ej skolplikt, varaktig vistelse utomlands' and skola ='Skolpliktsbevakning' then 0 else 1 end as is_skolplikt
        ,cast([ImportedAtUtc] as date) as senaste_uppdaterad --- Måste justeras!!! , ändra kanske till pyhton ingest tills IT är klara
            --,cast(getdate() as date) as senaste_uppdaterad --- Måste justeras!!! , ändra kanske till pyhton ingest tills IT är klara
    from
        {{ ref('schoolsoft_ea_csv_elever') }}
    
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
        ,is_skolplikt
        ,case   when kommun_folkbokföring = 'Öckerö'    then 1
                when kommun_folkbokföring =''           then -1
                when kommun_folkbokföring is null       then -1 else 0 end  as is_öckerö_kommun
        ,case   when intern_extern = 'Intern'           then 1
                when intern_extern = 'Extern'           then 0  else -1 end as is_kommunal_verksamhet
    from
        ea_barn
    where
        personnummer not like '%TF%'
    and personnummer is not null
    and is_skolplikt = 1
    -- Grundksola tar bara med elever till och med 15/16 år, beroende vilka sidan årskiftet. Läsåret byts 1 juli
    --and årskull >= case when month(getdate()) >= 7  then year(getdate()) - 15 else year(getdate()) - 16 end 