select * from {{ linked_source('OckeroDatabase', 'SchoolSoft', 'Organisations') }}
