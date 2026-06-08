{{config(alias='organisation')}}
{{config(enable='false')}}

select
    o.id                    as organisation_id
    ,o.display_name         as skola_namn
    ,case
        when o.display_name = 'Bergagårdsskolan'                then 'Grundskola'
        when o.display_name = 'Björkö Förskola'                 then 'Förskola'
        when o.display_name = 'Björkö skola'                    then 'Grundskola'
        when o.display_name = 'Brattebergs förskola'            then 'Förskola'
        when o.display_name = 'Brattebergsskolan 7-9'           then 'Grundskola'
        when o.display_name = 'Brattebergsskolan 4-6'           then 'Grundskola'
        when o.display_name = 'Fotö förskola'                   then 'Förskola'
        when o.display_name = 'Fotö skola'                      then 'Grundskola'
        when o.display_name = 'Hedens förskola'                 then 'Förskola'
        when o.display_name = 'Hedens skola 4-6'                then 'Grundskola'
        when o.display_name = 'Hedens skola 7-9'                then 'Grundskola'
        when o.display_name = 'Hälsö förskola'                  then 'Förskola'
        when o.display_name = 'XXXHälsö skola'                  then 'Grundskola'
        when o.display_name = 'Högåsens förskola'               then 'Förskola'
        when o.display_name = 'Kompassenskolan'                 then 'Grundskola'
        when o.display_name = 'Rörö förskola'                   then 'Förskola'
        when o.display_name = 'Vipekärrs Förskola'              then 'Förskola'
        when o.display_name = 'Öckerö Seglande gymnasieskola'   then 'Gymnasieskola'
        when o.display_name = 'Rörö skola'                      then 'Grundskola'
        when o.display_name = 'Centrum för lärande'             then 'Grundskola'
        when o.display_name = 'Kulturskolan'                    then 'Kulturskola' end as skola_grupp
   
    --,o.organisation_type    as organisation_typ
    --,o.municipality_code    as kommun_kod
    --,o.email                as organisation_email
    --,o.start_date           as organisation_start_datum

    ,o.meta__created    as meta_created
    ,o.meta__modified   as meta_modified
    ,o._dlt_load_id     as dlt_load_id
    ,o._dlt_id          as dlt_id   
from
    dlt_ss12000.organisations    as o

