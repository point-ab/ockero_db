
-- ============================================================
-- Lektioner från Skola24: en rad per calendar_event (schemalagt tillfälle).
-- Dimension till f_narvaro via lektion_id.
--
-- Aktivitetens attribut (ämne, typ) är platta på lektionsraden -- en
-- aktivitet (kurs/ämnesgrupp) har många lektioner, så aktivitet_id behålls
-- för att kunna gruppera "detta ämne för denna klass", medan ämne grupperar
-- ämnet över alla klasser.
--
-- Skola24 levererar tider i UTC -- konverteras till svensk tid här.
-- Vilka lektioner som finns styrs av calendar_start/calendar_end i
-- ockero_data_ingest/config.yml.
-- ============================================================


with
calendar_events as (select * from {{ ref('skola24_calendar_events') }}),
activities      as (select * from {{ ref('skola24_activities') }}),
skolor          as (select * from {{ ref('skola_skola24') }}),

salar as (
    select
         _dlt_parent_id
        ,string_agg(display_name, ', ') within group (order by display_name) as sal
    from
        {{ ref('skola24_calendar_events__rooms') }}
    group by
        _dlt_parent_id
)

select
     ce.id                                                                          as lektion_id
    ,s.skola_id
    ,s.skola_namn
    ,ac.id                                                                          as aktivitet_id
    ,ac.display_name                                                                as ämne
    ,ac.activity_type                                                               as aktivitet_typ
    ,cast(ce.start_time at time zone 'W. Europe Standard Time' as date)             as lektion_datum
    ,cast(ce.start_time at time zone 'W. Europe Standard Time' as datetime2(0))     as lektion_start
    ,cast(ce.end_time   at time zone 'W. Europe Standard Time' as datetime2(0))     as lektion_slut
    ,datediff(minute, ce.start_time, ce.end_time)                                   as lektion_minuter
    ,r.sal
    ,cast(getdate() as date)                                                        as senaste_uppdaterad
from
            calendar_events as ce
left join   activities      as ac   on ce.activity__id = ac.id
left join   skolor          as s    on lower(ac.organisation__id) = s.skola_id
left join   salar           as r    on ce._dlt_id = r._dlt_parent_id
