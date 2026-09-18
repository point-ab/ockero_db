
with alla_elever  as (
    select 
        CivicNo as personnummer
        ,SourceId as elev_id_schoolsoft
    from
        {{ ref('schoolsoft_persons') }} as e
union all 
    select 
        personnummer
        ,null as elev_id_schoolsoft
    from
        {{ ref('elin_export_data') }} as e
)

    select
        convert(varchar(64), hashbytes('SHA2_256', personnummer), 2) as elev_id
        ,personnummer
        ,elev_id_schoolsoft
    from
        alla_elever