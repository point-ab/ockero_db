{{config(alias='roller')}}
{{config(enable='false')}}

select
    d.id                as duty_id
    ,d.person__id       as person_id
    ,d.duty_at__id      as duty_at_id
    ,d.duty_role        as duty_role
    ,d.signature        as duty_signature
    ,d.end_date         as duty_end_date
    ,d.meta__created    as meta_created
    ,d.meta__modified   as meta_modified
    ,d._dlt_load_id     as dlt_load_id
    ,d._dlt_id          as dlt_id    
from
    dlt_ss12000.duties   as d

