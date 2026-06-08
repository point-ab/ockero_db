select * from {{ source('brons_api', 'schoolsoft_schools') }}

-- Byt till raden nedan när ingest-flödet lägger tabellen i linked server:
-- select * from {{ linked_source('ockero_db', 'brons_api', 'schoolsoft_schools') }}
