-- Parallell till d_skola tills Skola24-skolorna mappas mot schoolsoft-skolorna.
select * from {{ ref('skola_skola24') }}
