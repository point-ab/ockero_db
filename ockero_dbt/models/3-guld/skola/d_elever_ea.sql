
with alla as (

    select
        personnummer
        ,kommun_folkbokföring
        ,årskull
        ,skolform
        ,skola
        ,klass
        ,post_ort
        ,intern_extern
        ,kön
        ,is_öckerö_kommun
        ,is_kommunal_verksamhet
        ,senaste_uppdaterad
        ,'schoolsoft' as sql_part
    from
        {{ref('elever_schoolsoft_ea')}}

union all

    select
        personnummer
        ,case when is_öckerö_kommun = 1 then 'Öckerö' else post_ort end as kommun_folkboksföring
        ,cast(födelseår as int) as årskull
        ,skolform
        ,skola_namn as skola
        ,klass
        ,post_ort
        ,case when is_kommunal_verksamhet = 1 then 'Intern' else 'Extern' end as intern_extern
        ,kön
        ,is_öckerö_kommun
        ,is_kommunal_verksamhet
        ,null as senaste_uppdaterad
        ,'elin' as sql_part

    from
        {{ref('elever_elin')}}
    where 
        skola_namn <> 'Öckerö Seglande gymnasieskola' --Finns i skolsoft
    )

    select
        dense_rank() over (order by personnummer) as elev_id
        --,kommun_folkbokföring
        ,årskull
        ,skolform
        ,skola
        ,klass
        ,post_ort
        ,kön
        ,is_öckerö_kommun
        ,is_kommunal_verksamhet
        ,senaste_uppdaterad
        ,sql_part
    from
        alla

    where 
        skolform is not null
    and skolform <> ''