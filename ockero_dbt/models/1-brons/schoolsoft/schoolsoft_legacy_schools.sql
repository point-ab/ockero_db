select * from {{ linked_source('OckeroDatabase', 'SchoolSoft', 'LegacySchools') }}
