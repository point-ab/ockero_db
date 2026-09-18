select * from {{ source('brons_api', 'skola24_calendar_events__rooms') }}

-- dlt-barntabell till skola24_calendar_events (salar per lektion), kopplas via _dlt_parent_id = _dlt_id.
-- Byt till linked_source när ingest-flödet lägger tabellen i linked server.
