select 
    elev_id
    --,personnummer
    ,skola_id
    ,is_aktiv_elev
    ,skolform
    ,skola_namn
    ,årskurs
    ,klass
    ,födelseår
    ,kön
    ,ålder
    ,post_ort
  --  ,post_kod
   -- ,is_elev_fritids
    ,is_pnr_error
    ,is_öckerö_kommun
    ,is_kommunal_verksamhet
    ,senaste_uppdaterad
    --,start_datum_skola
    --,slut_datum_skola
    --,skola_typ_kort
    --,förnamn
    --,efternamn
    --,födelsedag
    --,ålders_grupp	
from {{ ref('schoolsoft_elever') }}

union all

select 
    elev_id
   -- ,null as personnummer
    ,skola_id
    ,is_aktiv_elev
    ,skolform
    ,skola_namn
    ,årskurs
    ,klass
    ,födelseår
    ,kön
    ,ålder
    ,post_ort
    ,0 as is_pnr_error
    ,is_öckerö_kommun
    ,is_kommunal_verksamhet
    ,senaste_uppdaterad
from
    {{ref('elin_elever')}}  
