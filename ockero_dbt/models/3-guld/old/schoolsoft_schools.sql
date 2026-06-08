
    select
        orgid       as org_id
        ,active     as is_aktiv_skola
        ,name       as skola_namn
        ,case   when authority like '%kommun'   then 1
                when preschool = 1              then 1 else 0 end as is_kommunal
        ,case   when preschool = 1      then 'Förskola'
                when gymnschool11 = 1   then 'Gymnasieskola'
                when grundschool11 = 1  then 'Grundskola' end as skola_typ_org
        ,gymnschool11       as is_gymnasieskola
        ,sargrundschool11   as is_grundskola_särskola
        ,sargymnschool13    as is_gymnasie_särskola
        ,grundschool11      as is_grundskola
        ,preschool          as is_förskola
    from
        {{ ref('brons_schoolsoft_schools') }}
    