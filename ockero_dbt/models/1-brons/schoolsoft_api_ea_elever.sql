select * from {{ source('brons_api', 'schoolsoft_csv_ea_elever') }}

-- Byt till raden nedan när ingest-flödet lägger tabellen i linked server:
-- select * from {{ linked_source('OckeroDatabase', 'SchoolSoft', 'Elever') }}