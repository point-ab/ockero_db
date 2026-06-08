
    select
        concat(g.archive,g.term,g.year,g.gradesubjectid,g.gradeid,g.gradedate,g.studentid) as betyg_rad_id

        --Migrering till schoolsoft runt 2022-isch, där blev de fel på några betyg, så behöver hårdkoda detta
        ,case   when g.year  = 6 and ss.name = 'Brattebergsskolan 7-9'  then 'aacf9b09-f0c5-11ed-8ff5-ac1f6b00772e'
                when g.year  = 6 and ss.name = 'Hedens skola 7-9'       then 'dc6f0033-f0c5-11ed-8ff5-ac1f6b00772e' else o.skola_id end as skola_id
        ,e.elev_id
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
                {{ ref('schoolsoft_api_studentgrades') }}       as g
    left join   {{ ref('schoolsoft_api_subjects') }}            as s    on g.gradesubjectid = s.gradesubjectid
    left join   {{ ref('schoolsoft_api_subjects') }}            as m    on g.specializationid = m.gradesubjectid and g.specializationid <> ''
    left join   {{ ref('schoolsoft_api_schools')}}              as ss   on g.orgid = ss.orgid
    left join   {{ ref('schoolsoft_skola')}}                    as o    on o.skola_namn = ss.name
    left join   {{ ref('schoolsoft_elever')}}                   as e    on e.personnummer = concat('20',replace(g.socialnumber,'-',''))

    where
        cast(left(g.archive,2) as int) > 22