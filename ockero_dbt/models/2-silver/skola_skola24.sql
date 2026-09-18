
-- ============================================================
-- Skolor från Skola24: organisationer av typen 'Skola'.
-- Skolenhet-raderna (bara skolenhetskod) ligger kvar i organisation_skola24
-- och blir aktuella först när Skola24-skolor ska mappas mot schoolsoft.
-- Alla aktiviteter, gruppmedlemskap och närvarorader pekar på Skola-orgar.
-- ============================================================

select * from {{ ref('organisation_skola24') }}
where organisation_typ = 'Skola'
