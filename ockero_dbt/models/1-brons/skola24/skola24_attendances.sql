select * from {{ source('brons_api', 'skola24_attendances') }}

-- Byt till linked_source när ingest-flödet lägger tabellen i linked server.
