

    select 
        elev_id
        ,personnummer
        ,org_id
        ,födelseår
        ,kön
        ,ålder
        ,elev_gruppering
        ,skola_typ
        ,skola_namn
        ,årskurs
        ,klass
        ,post_ort
        ,is_aktiv_elev
        ,is_öckerö_kommun
        ,is_kommunal_verksamhet
        ,senaste_uppdaterad
    from
       {{ref('raw_schoolsoft_students')}}  
union all

    select 
        elev_id
        ,null as personnummer
        ,org_id
        ,födelseår
        ,kön
        ,ålder
        ,elev_gruppering
        ,skola_typ
        ,skola_namn
        ,årskurs
        ,klass
        ,post_ort
        ,is_aktiv_elev
        ,is_öckerö_kommun
        ,is_kommunal_verksamhet
        ,senaste_uppdaterad
    from
        {{ref('raw_elin_students')}}  
