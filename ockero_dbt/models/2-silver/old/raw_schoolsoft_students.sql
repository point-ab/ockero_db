
with student_step1 as (
    -- Förbered födelsedatum
    select
        cast(case   when left(socialnumber, 1) > left(cast(year(getdate()) as varchar), 1)
                    then '19' + substring(socialnumber, 1, 2)
                    else '20' + substring(socialnumber, 1, 2) end as int) as födelseår
        ,case   when left(socialnumber, 1) > left(cast(year(getdate()) as varchar), 1)
                    then '19' + substring(socialnumber, 1, 2)
                    else '20' + substring(socialnumber, 1, 2) end
        + '-' + substring(socialnumber, 3, 2)
        + '-' + substring(socialnumber, 5, 2) as födelsedag
        ,*
    from
        {{ ref('brons_schoolsoft_students') }}
),

student_step2 as (
    select
        *
        ,case   when substring(pocode, 1, 3) = '475'    then 1
                when coalesce(pocode, '') = ''           then -1
                when pocode in ('430 90' --Öckerö
                                ,'430 93' --Hälsö
                                ,'430 94' --Bohus‑Björkö
                                ,'430 95' --Källö‑Knippla
                                ,'430 92' --Fotö
                                ,'430 97' --Rörö
                                ,'430 96' --Hyppeln
                                )
                                then 1 else 0 end as is_öckerö_kommun
    from
        student_step1
),

student_final as (
    select
        id          as elev_id
        ,concat(replace(födelsedag,'-',''), right(socialnumber,4)) as personnummer
        ,orgid      as org_id

        ,cast(case when startdate = ''  then null           else startdate  end as date) as start_datum_skola
        ,cast(case when enddate = ''    then '3999-01-01'   else enddate    end as date) as slut_datum_skola

        --Student
        ,födelsedag
        ,födelseår
        ,case   when sex = 'f'  then 'Flicka'
                when sex = 'p'  then 'Pojke'  end as kön
        ,cast(floor(datediff(day, try_cast(födelsedag as date), cast(getdate() as date)) / 365.25) as int) as ålder
        ,case   when floor(datediff(day, try_cast(födelsedag as date), cast(getdate() as date)) / 365.25) between 0  and 6  then '0-6'
                when floor(datediff(day, try_cast(födelsedag as date), cast(getdate() as date)) / 365.25) between 7  and 10 then '7-10'
                when floor(datediff(day, try_cast(födelsedag as date), cast(getdate() as date)) / 365.25) between 11 and 16 then '11-16'
                when floor(datediff(day, try_cast(födelsedag as date), cast(getdate() as date)) / 365.25) between 17 and 80 then '16+' end as ålders_grupp

        -- Skola
        ,case   when month(getdate()) >= 8  and födelseår >= year(getdate()) - 5 then 'Förskola'
                when month(getdate()) < 8   and födelseår >= year(getdate()) - 6 then 'Förskola'
                when schooltype = 'GR11'                                         then 'Grundskola'
                when schooltype = 'GRAN'                                         then 'Grundskola anpassad'
                when schooltype in ('GY11', 'GY25')                              then 'Gymnasieskola' end as elev_gruppering

        ,case   when schooltype = 'BO'   then 'Förskola'
                when schooltype = 'GR11' then 'Grundskola'
                when schooltype = 'GRAN' then 'Grundskola anpassad'
                when schooltype = 'GY11' then 'Gymnasieskola'
                when schooltype = 'GY25' then 'Gymnasieskola' end as skola_typ
        ,schooltype     as skola_typ_kort
        ,schoolname     as skola_namn
        ,case   when schooltype in ('GY11', 'GY25')     then 'G ' + year
                when year = 'F'                         then 'FK'
                when year = '' and schooltype in ('BO') then 'F' else year end as årskurs
        ,class          as klass
        ,leisureschool  as is_elev_fritids

        -- Adress
        ,{{ clean_uppercase_text('city') }}     as post_ort
        ,pocode                                 as post_kod
        ,case when try_cast(födelsedag as date) is null then 1 else 0 end as is_pnr_error

        --Flaggor
        ,case when active = 1 and coalesce(class, '') <> '' then 1 else 0 end as is_aktiv_elev
        ,is_öckerö_kommun
        ,case   when o.is_kommunal = 1
                     and schooltype in ('GR11', 'GRAN')
                     and (case when schooltype in ('GY11', 'GY25') then 'G ' + year
                               when year = 'F'                     then 'FK'
                               when year = '' and schooltype in ('BO') then 'F'
                               else year end) = ''
                then 0 else o.is_kommunal end as is_kommunal_verksamhet
        ,cast(getdate() as date) as senaste_uppdaterad
    from
                student_step2                       as s
    left join   {{ ref('schoolsoft_schools') }}     as o on s.orgid = o.org_id
)

select * from student_final
where ålder < 25
