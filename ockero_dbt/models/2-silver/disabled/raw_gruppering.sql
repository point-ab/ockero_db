{{config(alias='gruppering')}}
{{config(enable='false')}}

    select
        gm.person__id       as person_id
        ,g.organisation__id as organisation_id
        ,g.id               as grupp_id
        ,g.display_name     as grupp_namn
        ,g.group_type       as grupp_typ
        ,concat(left(g.start_date,4),'-', left(g.end_date,4)) as läsår
        ,g.start_date       as start_datum
        ,g.end_date         as slut_datum
    from
                dlt_ss12000.groups__group_memberships    as gm
    left join   dlt_ss12000.groups                       as g on g._dlt_id = gm._dlt_parent_id
    where
        g.group_type in( 'Klass','Avdelning') -- finns undervisning och mentor med!