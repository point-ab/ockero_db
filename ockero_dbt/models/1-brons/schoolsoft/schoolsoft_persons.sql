select * from {{ linked_source('OckeroDatabase', 'SchoolSoft', 'Persons') }}
