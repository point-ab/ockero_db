
-- ============================================================
-- Närvaro från Skola24: en rad per elev och lektion (attendances).
-- Händelsetabell -- bara nycklar, datum, minuter och flaggor.
-- Namn på elev, skola, ämne och lektionstider hämtas via dimensionerna:
--   elev_id    -> d_elever_skola24
--   skola_id   -> d_skola_skola24
--   lektion_id -> d_lektioner (ämne, aktivitet, start/slut, sal)
--
-- Närvaroraden i API:t innehåller bara calendar_event-id och elev-id, så
-- lektionens datum och skola kommer från lektioner_skola24.
--
-- OBS: API:t returnerar hela historiken för varje aktivitet, medan lektioner
-- bara hämtas för calendar_start..calendar_end. Rader utanför det intervallet
-- får null i skola_id/lektion_datum tills en fullständig engångsladdning av
-- kalendern är gjord.
-- ============================================================

with
attendances as (select * from {{ ref('skola24_attendances') }}),
lektioner   as (select * from {{ ref('lektioner_skola24') }}),
elever      as (select * from {{ ref('elever_skola24') }})

select
     a.id                                                                               as närvaro_id
    ,e.elev_id
    ,l.skola_id
    ,a.calendar_event__id                                                               as lektion_id
    ,l.lektion_datum
    ,a.attendance_minutes                                                               as närvaro_minuter
    ,a.valid_absence_minutes                                                            as giltig_frånvaro_minuter
    ,a.invalid_absence_minutes                                                          as ogiltig_frånvaro_minuter
    ,a.other_attendance_minutes                                                         as övrig_närvaro_minuter
    ,a.absence_reason                                                                   as frånvaro_orsak
    ,cast(a.is_reported as int)                                                         as is_rapporterad
    ,case when a.valid_absence_minutes > 0 or a.invalid_absence_minutes > 0 then 1 else 0 end as is_frånvaro
    ,case when a.invalid_absence_minutes > 0 then 1 else 0 end                          as is_ogiltig_frånvaro
    ,cast(a.reported_timestamp at time zone 'W. Europe Standard Time' as datetime2(0))  as rapporterad_tidpunkt
    ,cast(getdate() as date)                                                            as senaste_uppdaterad
from
            attendances as a
left join   lektioner   as l    on a.calendar_event__id = l.lektion_id
left join   elever      as e    on a.student__id        = e.elev_id_skola24
