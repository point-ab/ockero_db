with student_step1 as (

    select
        substring(personnummer, 1, 4)
        + '-' + substring(personnummer, 5, 2)
        + '-' + substring(personnummer, 7, 2) as födelsedag
        ,e.*
    from
        {{ ref('elin_export_data') }} as e
    where
        handelsenamn = 'Antagen'
    and cast(handelsedatum as date) > '2025-08-01'
),
--Elever kan ha avbrott eller Examen, dessa måste tas bort från antagna ovanför, tas ut separat och joinas ihop längre ner
avbrott as (
    select
        *
    from
        {{ ref('elin_export_data') }}
    where
        handelsenamn in ('Avbrott', 'Examen')
    and cast(handelsedatum as date) > '2025-08-01'
),

skolform as (
    select
        handelsesourceordinal
        ,string_agg([Skolform], ', ') as skola_typ_kort
    from
        {{ ref('elin_export_data_skolformer') }}
    group by
        handelsesourceordinal
),

student_final as (
    select
        cast(dense_rank() over (order by b.personnummer) as varchar) as elev_id
        ,b.personnummer                               as personnummer
        ,b.csnkod                                     as skola_id
        ,cast(b.handelsedatum as date)                              as start_datum_skola
        --Student
        ,left(b.födelsedag, 4) as födelseår
        ,case   when cast(substring(b.personnummer, 11, 1) as int) % 2 = 0 then 'Flicka'
                when cast(substring(b.personnummer, 11, 1) as int) % 2 = 1 then 'Pojke' end as kön
        ,cast(floor(datediff(day, try_cast(b.födelsedag as date), cast(getdate() as date)) / 365.25) as int) as ålder

        --Skola
        ,'Gymnasieskola' as elev_gruppering
        ,case when s.skola_typ_kort = 'GY, GYAN' then 'Gymnasieskola anpassad' else 'Gymnasieskola' end as skolform
        ,b.SkolaNamn        as skola_namn
        ,'G ' + b.Arskurs   as årskurs
        ,b.studievagkod   as klass
        -- Adress
        ,b.FolkbokforingsadressPostnummer   as post_kod
        ,{{ clean_uppercase_text('b.FolkbokforingsadressOrt') }} as post_ort
        --Flaggor
        ,1 as is_aktiv_elev
        ,1 as is_öckerö_kommun
        ,case when b.SkolaNamn = 'Öckerö seglande gymnasieskola' then 1 else 0 end as is_kommunal_verksamhet
        ,row_number() over (partition by b.personnummer order by b.handelsedatum desc) as is_unik_person
        ,case when a.handelsedatum > b.handelsedatum then 1 else 0 end as is_avbrott
    from
                student_step1   as b
    left join   skolform        as s on b.sourceordinal = s.handelsesourceordinal
    --Joinar på avbrott, dvs elever som blivit antagna med sedan gjort avbrott, dessa ska inte med i statistiken
    left join   avbrott         as a on     a.personnummer = b.personnummer
                                        and a.handelsedatum > b.handelsedatum
                                        and b.SkolaNamn = a.SkolaNamn
)

select
    elev_id
    ,personnummer
    ,skola_id
    ,start_datum_skola
    ,födelseår
    ,kön
    ,ålder
   -- ,elev_gruppering
    ,elev_gruppering as skolform
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
