{{config(alias='placering')}}
{{config(enabled=false)}}

select
    p.id                as placement_id
    ,p.placed_at__id    as organisation_id
    ,p.group__id        as grupp_id
    ,p.child__id        as person_id
    ,p.school_type      as skol_typ
    ,p.start_date       as placerings_start_datum
    ,p.end_date         as placerings_slut_datum    
    ,p.max_weekly_schedule_hours as max_schemalagda_veckor_timmar
    
    ,p.meta__created    as meta_created
    ,p.meta__modified   as meta_modified
    ,p._dlt_load_id     as dlt_load_id
    ,p._dlt_id          as dlt_id   
from
    dlt_ss12000.placements   as p