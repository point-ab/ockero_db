{{config(alias='person')}}
{{config(enable='false')}}




with person_email as (
    select
        _dlt_parent_id
        ,max(case when type ='Skola personal'   then 1 else 0 end) as is_teacher
        ,max(case when type ='Skola elev'       then 1 else 0 end) as is_student
    from
        dlt_ss12000.persons__emails
    group by
        _dlt_parent_id
),

person_duties as (
    select
        person__id as person_id
        ,_dlt_load_id
        ,max(1)  as has_duty
    from
        dlt_ss12000.duties
    group by
        person__id
        ,_dlt_load_id
),

person_external as (
     select
        _dlt_parent_id
        ,max(case when context ='teacherguid' then 1 else 0 end) as is_teacher_ext
        ,max(case when context ='studentguid' then 1 else 0 end) as is_student_ext
    from
        dlt_ss12000.persons__external_identifiers
    group by
        _dlt_parent_id

 )

select
    p.id                as person_id
    ,year(cast(p.birth_date as date)) as födelseår
    ,floor((current_date - cast(p.birth_date as date)) / 365.25 )   as ålder
    ,p.sex              as kön
    ,p.person_status    as person_status
    ,pa.type            as adress_typ    
    ,{{ clean_uppercase_text('pa.locality') }} as stad
    ,pa.postal_code     as postkod  
    ,case when left( postkod,3) = 475 then 1 else 0 end as is_öckerö_kommun
    ,coalesce(pe.is_teacher,0)      as is_lärare
    ,coalesce(pe.is_student,0)      as is_student
    ,coalesce(px.is_teacher_ext,0)  as is_lärare_ext
    ,coalesce(px.is_student_ext,0)  as is_student_ext
    ,coalesce(d.has_duty,0)         as has_duty

    ,p.meta__created    as meta_created
    ,p.meta__modified   as meta_modified
    ,p._dlt_load_id     as dlt_load_id
    ,p._dlt_id          as dlt_id   
from
            dlt_ss12000.persons  as p
left join   dlt_ss12000.persons__addresses   as pa   on p._dlt_id = pa._dlt_parent_id
left join   person_email                as pe   on p._dlt_id = pe._dlt_parent_id
left join   person_duties               as d    on p.id = d.person_id and p._dlt_load_id = d._dlt_load_id
left join   person_external             as px   on p._dlt_id = px._dlt_parent_id



