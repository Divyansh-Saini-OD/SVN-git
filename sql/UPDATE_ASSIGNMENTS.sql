REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    :E1002_HR_CRM_Synchronization                                                                            |--
--|                                                                                             |--
--| Program Name   : UPDATE_ASSIGNMENTS.sql                                                             |--        
--|                                                                                             |--   
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              23-Apr-2008       Jeevan babu             Initial version                  |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Script UPDATE_ASSIGNMENTS....
PROMPT

update per_all_assignments_f
set ass_attribute9='31-DEC-07'
where sysdate between effective_start_date and nvl(effective_end_date,sysdate);

update per_all_assignments_f
set ass_attribute10='30-DEC-07'
where sysdate between effective_start_date and nvl(effective_end_date,sysdate)
and to_date(ass_attribute10) > '30-dec-07';

update jtf_rs_groups_b
set start_date_active='30-DEC-07'
where start_date_active >='30-dec-07';


UPDATE jtf_rs_resource_extns
SET    attribute15 = '31-DEC-06'
WHERE  resource_id IN (                         SELECT resource_id
                         FROM
                         (SELECT  PAAF.person_id           PERSON_ID     
                                , PAAF.ass_attribute9
                                , PAAF.supervisor_id
                                , PAAF.business_group_id     
                        FROM    (SELECT *
                                 FROM per_all_assignments_f p1
                                -- WHERE  p_as_of_date BETWEEN p.effective_start_date AND p.effective_end_date) PAAF -- Commented on 24/04/08
                                 -- Added on 24/04/08
                                 WHERE  trunc(sysdate) BETWEEN p1.effective_start_date 
                                   AND  DECODE((SELECT  system_person_type
                                              FROM    per_person_type_usages_f p
                                                    , per_person_types         ppt
                                              WHERE   TRUNC(sysdate) BETWEEN p.effective_start_date AND p.effective_end_date
                                              AND     PPT. person_type_id   =  p.person_type_id
                                              AND     p.person_id           =  p1.person_id
                                              AND     PPT.business_group_id =  0),
                                             'EX_EMP',TRUNC(sysdate),'EMP', p1.effective_end_date)) PAAF-- Added on 24/04/08
                              , (SELECT *
                                 FROM per_all_people_f p
                                 WHERE  sysdate BETWEEN p.effective_start_date AND p.effective_end_date
                                 ) PAPF
                              ,  per_person_types         PPT
                              , (SELECT *
                                 FROM per_person_type_usages_f p
                                 WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date) PPTU
                        WHERE    PAAF.person_id               = PAPF.person_id
                        AND      PAPF.person_id               = PPTU.person_id
                        AND      PPT. person_type_id          = PPTU.person_type_id
                        AND     (PPT.system_person_type       = 'EMP'
                        OR       PPT.system_person_type       = 'EX_EMP')-- Added on 24/04/08
                        AND      PAAF.business_group_id       = 0
                        AND      PAPF.business_group_id       = 0
                        AND      PPT .business_group_id       = 0
                        CONNECT BY PRIOR PAAF.person_id       = PAAF.supervisor_id
                          START WITH     PAAF.person_id       = 2186
                        ) t
                        , jtf_rs_resource_extns_vl  JRRE
                        where t.person_id = JRRE.source_id
                        AND   TO_DATE(t.ass_attribute9,'DD-MM-YY')< TO_DATE(JRRE.attribute15,'DD-MM-YY')                          
                           );

SET FEEDBACK ON
SET HEAD     ON

REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================