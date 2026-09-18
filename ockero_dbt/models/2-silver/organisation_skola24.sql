
-- ============================================================
-- Skolor/organisationer från Skola24 (SS12000 organisations)
--
-- Motsvarar skola_schoolsoft men med Skola24:s egna id:n. Skola24 saknar
-- kommunkod och skolformer per organisation, så kopplingen till
-- schoolsoft-skolan görs i guld när den behövs (t.ex. via skolenhetskod/namn).
-- organisation_typ: 'Skola' eller 'Skolenhet'.
-- ============================================================

with organisations as (
    select * from {{ ref('skola24_organisations') }}
)

select
     lower(id)                                                  as skola_id
    ,display_name                                               as skola_namn
    ,organisation_type                                          as organisation_typ
    ,school_unit_code                                           as skolenhetskod
    ,cast(start_date as date)                                   as start_datum
    ,cast(end_date as date)                                     as slut_datum
    ,case when cast(end_date as date) >= cast(getdate() as date) then 1 else 0 end as is_aktiv_skola
    ,cast(getdate() as date)                                    as senaste_uppdaterad
from
    organisations
