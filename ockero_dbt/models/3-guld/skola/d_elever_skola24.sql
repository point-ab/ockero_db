-- Parallell till d_elever tills Skola24-eleverna slås ihop dit (kopplas via elev_id).
select * from {{ ref('elever_skola24') }}
