

    select
        case    when g.year  = 6  and o.skola_namn = 'Brattebergsskolan 7-9'  then '6'
                when g.year  = 6  and o.skola_namn = 'Hedens skola 7-9'       then '10' else g.orgid end as org_id
        ,g.studentid        as elev_id
        ,g.archive          as läsår
        ,case   when g.term = 'VT'  then 'VT - ' + right(g.archive, 2)
                when g.term = 'HT'  then 'HT - ' + left(g.archive, 2) end as termin
        ,g.term                                 as termin_typ
        ,g.year                                 as årskurs
        ,coalesce(m.description,s.description)  as betyg_ämne
        ,coalesce(m.name,s.name )               as betyg_ämne_kort
        ,g.grade                                as betyg
        ,g.gradedate                            as betygs_datum
        ,g.finalgrade                           as slutbetyg
        ,g.active                               as is_aktiv -- ska flyttas med till nästa termin!       
        ,case when g.gradesubject in('SV','EN','MA')    then 1 else 0 end as is_kärnämne
        ,case when g.grade in('F','Saknas')             then 1 else 0 end as is_betyg_f
        ,case when g.grade in('F','Saknas')             then 0 else 1 end as is_betyg_godkänt
        ,case when g.grade in('Saknas')                 then 1 else 0 end as is_betyg_saknas
        ,case when g.grade in('3')                      then 1 else 0 end as is_betyg_3     
      
        --,g.specialization     as betyg_ämne_special_namn_kort
        --,g.specializationid as betyg_ämne_special_id
        --,g.gradeid            as betyg_id
        --,g.catalogid          as betygs_katalog_id
        --,g.schooltype         as betyg_ämne_skol_typ
            ,cast(getdate() as date) as senaste_uppdaterad
    from
                {{ ref('brons_schoolsoft_studentgrades') }}    as g
    left join   {{ ref('brons_schoolsoft_subjects') }}         as s on g.gradesubjectid = s.gradesubjectid
    left join   {{ ref('brons_schoolsoft_subjects') }}         as m on g.specializationid = m.gradesubjectid and g.specializationid <> ''
    left join   {{ref('schoolsoft_schools')}}   as o on g.orgid = o.org_id

    where
        cast(left(g.archive,2) as int) > 22