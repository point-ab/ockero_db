
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
    from
        {{ref('schoolsoft_elever_ea')}}

union all

    select
        personnummer
        ,case when is_öckerö_kommun = 1 then 'Öckerö' else post_ort end as kommun_folkboksföring
        ,cast(födelseår as int) as årskull
        ,elev_gruppering as skolform
        ,skola_namn as skola
        ,klass
        ,post_ort
        ,case when is_kommunal_verksamhet = 1 then 'Intern' else 'Extern' end as intern_extern
        ,kön
        ,is_öckerö_kommun
        ,is_kommunal_verksamhet
        ,null as senaste_uppdaterad
    from
        {{ref('raw_elin_students')}}
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
    from
        alla
