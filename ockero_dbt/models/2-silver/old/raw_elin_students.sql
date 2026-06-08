with student_step1 as (

    select
        substring(elev__person__personnummer, 1, 4)
        + '-' + substring(elev__person__personnummer, 5, 2)
        + '-' + substring(elev__person__personnummer, 7, 2) as födelsedag
        ,e.*
    from
        {{ ref('brons_elin_export_data') }} as e
    where
        handelsenamn = 'Antagen'
    and cast(handelsedatum as date) > '2025-08-01'
),
--Elever kan ha avbrott eller Examen, dessa måste tas bort från antagna ovanför, tas ut separat och joinas ihop längre ner
avbrott as (
    select
        *
    from
        {{ ref('brons_elin_export_data') }}
    where
        handelsenamn in ('Avbrott', 'Examen')
    and cast(handelsedatum as date) > '2025-08-01'
),

skolform as (
    select
        _dlt_parent_id  as dlt_parent_id
        ,string_agg([value], ', ') as skola_typ_kort
    from
        {{ ref('brons_elin_export_data_skolformer') }}
    group by
        _dlt_parent_id
),

student_final as (
    select
        dense_rank() over (order by b.elev__person__personnummer) as elev_id
        ,b.elev__person__personnummer                               as personnummer
        ,b.elev__skola__cs_nkod                                     as org_id
        ,cast(b.handelsedatum as date)                              as start_datum_skola
        --Student
        ,left(b.födelsedag, 4) as födelseår
        ,case   when cast(substring(b.elev__person__personnummer, 11, 1) as int) % 2 = 0 then 'Flicka'
                when cast(substring(b.elev__person__personnummer, 11, 1) as int) % 2 = 1 then 'Pojke' end as kön
        ,cast(floor(datediff(day, try_cast(b.födelsedag as date), cast(getdate() as date)) / 365.25) as int) as ålder

        --Skola
        ,'Gymnasieskola' as elev_gruppering
        ,case when s.skola_typ_kort = 'GY, GYAN' then 'Gymnasieskola anpassad' else 'Gymnasieskola' end as skola_typ
        ,b.elev__skola__namn                as skola_namn
        ,'G ' + b.elev__arskurs             as årskurs
        ,b.elev__studievagkod               as klass
        -- Adress
        ,b.elev__person__folkbokforingsadress__postnummer   as post_kod
        ,{{ clean_uppercase_text('b.elev__person__folkbokforingsadress__ort') }} as post_ort
        --Flaggor
        ,1 as is_aktiv_elev
        ,1 as is_öckerö_kommun
        ,case when b.elev__skola__namn = 'Öckerö seglande gymnasieskola' then 1 else 0 end as is_kommunal_verksamhet
        ,row_number() over (partition by b.elev__person__personnummer order by b.handelsedatum desc) as is_unik_person
        ,case when a.handelsedatum > b.handelsedatum then 1 else 0 end as is_avbrott
    from
                student_step1   as b
    left join   skolform        as s on b._dlt_id = s.dlt_parent_id
    --Joinar på avbrott, dvs elever som blivit antagna med sedan gjort avbrott, dessa ska inte med i statistiken
    left join   avbrott         as a on     a.elev__person__personnummer = b.elev__person__personnummer
                                        and a.handelsedatum > b.handelsedatum
                                        and b.elev__skola__namn = a.elev__skola__namn
)

select
    elev_id
    ,personnummer
    ,org_id
    ,start_datum_skola
    ,födelseår
    ,kön
    ,ålder
    ,elev_gruppering
    ,skola_typ
    ,skola_namn
    ,årskurs
    ,klass
    ,post_ort
    ,post_kod
    ,is_aktiv_elev
    ,is_öckerö_kommun
    ,is_kommunal_verksamhet
    ,is_unik_person
    ,is_avbrott
    ,cast(getdate() as date) as senaste_uppdaterad
from
    student_final
where
    is_unik_person = 1
and is_avbrott = 0
