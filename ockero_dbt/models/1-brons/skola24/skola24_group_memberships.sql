select * from {{ source('brons_api', 'skola24_group_memberships') }}

-- Byt till linked_source när ingest-flödet lägger tabellen i linked server.
