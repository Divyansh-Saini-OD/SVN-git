SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_TERR_RSC_REP package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_JTF_TERR_RSC_REP
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_TERR_RSC_REP                                   |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: TM Territories Resources Report' with    |
-- |                     Territory Name as the mandatory Input parameter.              |
-- |                     This public procedure will display the lowest-level child     |
-- |                     records in which the following conditions are met             |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Terr_without_rsc        This is the public procedure                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  04-Mar-08   Abhradip Ghosh               Initial draft version           |
-- +===================================================================================+
AS

----------------------------
--Declaring Global Constants
----------------------------

----------------------------
--Declaring Global Variables
----------------------------


-----------------------------------
--Declaring Global Record Variables
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

-- +===================================================================+
-- | Name  : WRITE_LOG                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program log file                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_log(
                    p_message IN VARCHAR2
                   )
IS
---------------------------
--Declaring local variables
---------------------------
lc_error_message  VARCHAR2(2000);
lc_set_message    VARCHAR2(2000);

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while writing to the log file.';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_TERR_WITHOUT_RSC_REP.WRITE_LOG'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_TERR_WITHOUT_RSC_REP.WRITE_LOG'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END write_log;
-- +===================================================================+
-- | Name  : WRITE_OUT                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program output file                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE WRITE_OUT(
                    p_message IN VARCHAR2
                   )
IS
---------------------------
--Declaring local variables
---------------------------
lc_error_message  VARCHAR2(2000);
lc_set_message    VARCHAR2(2000);

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while writing to the log file.';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_TERR_WITHOUT_RSC_REP.WRITE_LOG'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_TERR_WITHOUT_RSC_REP.WRITE_LOG'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END WRITE_OUT;
-- +===================================================================+
-- | Name  : print_display                                             |
-- |                                                                   |
-- | Description:       This is the private procedure to print the     |
-- |                    details of the record in the log file          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE print_display(
                        p_parent_terr_name  VARCHAR2
                        , p_child_terr_name VARCHAR2 
                        , p_resource_id     varchar2
                        , p_resource_name   VARCHAR2 
                        , p_access_type     VARCHAR2 
                        , p_role_name       varchar2
                        , p_group_name      varchar2
                        , p_division        varchar2
                       )
IS
---------------------------
--Declaring local variables
---------------------------
lc_message            VARCHAR2(2000);
lc_err_message        VARCHAR2(2000);

BEGIN
   
   /*WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD(p_child_terr_name,45,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD(p_parent_terr_name,45,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD(p_reason,83,' ')||RPAD(' ',3,' ')
            );
   */
   /*WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD(p_child_terr_name,45,' ')||RPAD(' ',2,' ')||
             RPAD(p_parent_terr_name,45,' ')||RPAD(' ',2,' ')||
             RPAD(p_resource_id,20,' ')||RPAD(' ',2,' ')||
             RPAD(p_resource_name,30,' ')||RPAD(' ',2,' ')||
             RPAD(p_role_name,30,' ')||RPAD(' ',2,' ')||
             RPAD(p_group_name,30,' ')||RPAD(' ',2,' ')||
             RPAD(p_division,30,' ')
            );   */
            WRITE_OUT(
                         RPAD(p_child_terr_name,45,' ')||chr(9)
                         ||RPAD(p_parent_terr_name,45,' ')||chr(9)
                         ||RPAD(p_resource_id,20,' ')||chr(9)
                         ||RPAD(p_resource_name,30,' ')||chr(9)
                         ||RPAD(p_access_type,20,' ')||chr(9)
                         ||RPAD(p_role_name,30,' ')||chr(9)
                         ||RPAD(p_group_name,30,' ')||chr(9)
                         ||RPAD(p_division,30,' ')||chr(9)
            );  
            
            
EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_err_message     :=  'Unexpected Error in procedure: PRINT_DISPLAY';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_err_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_message := FND_MESSAGE.GET;
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR 
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_TERR_WITHOUT_RSC_REP.PRINT_DISPLAY'
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_TERR_WITHOUT_RSC_REP.PRINT_DISPLAY' 
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
END print_display;

-- +===================================================================+
-- | Name  : terr_without_rsc                                          |
-- |                                                                   |
-- | Description:  This is the public procedure which will get called  |
-- |               from the concurrent program 'OD: TM Territories     |
-- |               without Resources Report' with Territory Name as the|
-- |               mandatory Input parameter.                          |
-- |               This public procedure will display the lowest-level |
-- |               child records in which the following conditions are |
-- |               met                                                 |
-- |               1. No resource is assigned to territory             |
-- |               2. End Dated resource on the territory (and no other|
-- |                  active resource is assigned to that territory)   |
-- |               3.There is a mismatch of the group and role for a   |
-- |                 resource between the rule-based territory and that|
-- |                 of in the Resource Manager.                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE terr_rsc
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
             , p_terr_id            IN  NUMBER
            )
IS
---------------------------
--Declaring local variables
---------------------------
EX_RSC_ERR             EXCEPTION;
ln_count               PLS_INTEGER := 0;
ln_index               PLS_INTEGER := 0;
lc_parent_terr_name    VARCHAR2(2000);
lc_set_message         VARCHAR2(2000);
lc_error_message       VARCHAR2(2000); 
lc_resource_exists     VARCHAR2(10); 
lc_resource_active     VARCHAR2(10);
lc_resource_group      VARCHAR2(10);
lc_resource_group_role VARCHAR2(10);
lc_manager_flag      varchar2(2);
--
ln_res_count           NUMBER;
-- ----------------------------------------------
-- Declare cursor to fetch the child territories
-- ----------------------------------------------
CURSOR lcu_child_territories(
                             p_terr_id NUMBER
                            )
IS
SELECT  JTA.terr_id 
        , JTA.name
        , JTA.parent_territory_id
        , (
           SELECT JTA1.name 
           FROM   jtf_terr_all JTA1 
           WHERE  JTA1.terr_id = JTA.parent_territory_id
           AND    rownum = 1
          ) as parent_territory_name
FROM    jtf_terr_all JTA
WHERE   SYSDATE BETWEEN JTA.start_date_active AND NVL(JTA.end_date_active,SYSDATE)
START   WITH JTA.terr_id = p_terr_id
CONNECT BY PRIOR JTA.terr_id = JTA.parent_territory_id;

-- -------------------------------------------------------------------------------
-- Declare cursor to fetch the details of the resource for a particular territory
-- -------------------------------------------------------------------------------
CURSOR lcu_resource_details(
                            p_terr_id NUMBER
                           )
IS
SELECT JTRA.resource_id
       , JTRA.role
       , JTRA.group_id
       , JRRE.resource_number
FROM   jtf_terr_rsc_all JTRA
       , jtf_rs_resource_extns JRRE
WHERE  JTRA.terr_id = p_terr_id
AND    JRRE.resource_id = JTRA.resource_id
AND    SYSDATE BETWEEN NVL(JTRA.start_date_active,SYSDATE) AND NVL(JTRA.end_date_active,SYSDATE);

cursor lcu_resource_dtls 
                       ( p_resource_id number, 
                         p_group_id number,
                         p_role varchar2)
is 
select
      papf.employee_number,
      jrre.source_name, 
      jrgt.group_name, 
      jrrt.role_name,
      jrrb.attribute15
from 
       per_all_people_f papf,
       jtf_rs_resource_extns jrre, 
       jtf_rs_group_members jrgm, 
       jtf_rs_groups_tl jrgt, 
       jtf_rs_group_usages jrgu,
       jtf_rs_role_relations jrrr, 
       jtf_rs_roles_b jrrb, 
       jtf_rs_roles_tl jrrt
where 
    papf.person_id = jrre.source_id 
AND sysdate between papf.effective_start_date and nvl(papf.effective_end_date,sysdate)
AND jrre.resource_id = p_resource_id 
AND jrgm.resource_id = jrre.resource_id
AND jrgm.group_id =p_group_id 
AND jrgt.group_id = jrgm.group_id
AND jrgu.group_id = jrgt.group_id 
AND jrgu.usage   ='SALES'
AND NVL(jrgm.delete_flag,'N') <> 'Y'
AND jrgt.language = userenv('LANG')
AND jrrr.role_resource_id = jrgm.group_member_id 
AND jrrr.role_id = jrrb.role_id 
AND sysdate between jrrr.start_date_active and nvl(jrrr.start_date_active,sysdate)
AND jrrb.role_id = jrrt.role_id
AND jrrb.role_code = p_role
AND jrrb.role_type_code  = 'SALES'
AND jrrb.active_flag     = 'Y'
AND jrrt.language= userenv('LANG')
;

CURSOR lcu_manager(p_resource_id number,p_group_id number default null) 
is
SELECT 
       case when count(ROL.manager_flag) > 0 then 'Y' Else 'N' end
FROM   
         jtf_rs_role_relations JRR
       , jtf_rs_group_members MEM
       , jtf_rs_group_usages JRU
       , jtf_rs_roles_b ROL
WHERE  
    MEM.resource_id = p_resource_id
AND NVL(MEM.delete_flag,'N') <> 'Y'
AND MEM.group_id = NVL(p_group_id,MEM.group_id)
AND JRU.group_id = MEM.group_id
AND JRU.usage = 'SALES'
AND JRR.role_resource_id    = MEM.group_member_id
AND JRR.role_resource_type = 'RS_GROUP_MEMBER'
AND TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active) 
                   AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
AND NVL(JRR.delete_flag,'N') <> 'Y'
AND ROL.role_id = JRR.role_id
AND ROL.role_type_code='SALES'
AND ROL.manager_flag = 'Y'
AND ROL.active_flag = 'Y';  


CURSOR lcu_resource_dtls2(p_resource_id number,p_group_id number default null)
is 
SELECT 
      papf.employee_number,
      jrre.source_name, 
      jrgt.group_name, 
      jrrt.role_name,
      jrrb.attribute15
FROM   
         per_all_people_f papf
       , jtf_rs_resource_extns jrre 
       , jtf_rs_group_members jrgm
       , jtf_rs_role_relations jrrr
       , jtf_rs_groups_tl jrgt
       , jtf_rs_group_usages jrgu
       , jtf_rs_roles_b jrrb
       , jtf_rs_roles_tl jrrt
WHERE
    papf.person_id = jrre.source_id 
and SYSDATE between papf.effective_start_date and nvl(papf.effective_end_date,sysdate)
and jrre.resource_id = p_resource_id 
AND jrgm.resource_id      = jrre.resource_id
AND NVL(jrgm.delete_flag,'N') <> 'Y'
AND jrgm.group_id         = NVL(p_group_id,jrgm.group_id)
AND jrgu.group_id         = jrgm.group_id
and jrgt.group_id         = jrgu.group_id 
AND jrgt.language         = userenv('LANG')
AND jrgu.usage            = 'SALES'
AND jrrr.role_resource_id = jrgm.group_member_id
AND jrrr.role_resource_type  = 'RS_GROUP_MEMBER'
AND TRUNC(SYSDATE) BETWEEN TRUNC(jrrr.start_date_active) 
                                                AND NVL(TRUNC(jrrr.end_date_active),TRUNC(SYSDATE))
AND NVL(jrrr.delete_flag,'N') <> 'Y'
AND jrrb.role_id         = jrrr.role_id
AND jrrt.role_id         = jrrb.role_id 
AND jrrt.language        = userenv('LANG')
AND jrrb.role_type_code  = 'SALES'
AND jrrb.active_flag     = 'Y'
AND (CASE lc_manager_flag 
              WHEN 'Y' THEN jrrb.attribute14 
              ELSE 'N' 
                      END) = (CASE lc_manager_flag 
                                   WHEN 'Y' THEN 'HSE' 
                                   ELSE 'N' 
                                           END); 
                                           
CURSOR LCU_ACCESS_TYPE (p_terr_id number)
IS 
SELECT 
initcap(JTRAA.ACCESS_TYPE) access_type
FROM 
jtf_terr_rsc_all jtra, 
jtf_terr_rsc_access_all jtraa
WHERE  
       JTRA.TERR_ID = P_TERR_ID 
AND    JTRA.TERR_RSC_ID = JTRAA.TERR_RSC_ID
AND    SYSDATE BETWEEN NVL(JTRA.start_date_active,SYSDATE) AND NVL(JTRA.end_date_active,SYSDATE);
--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE child_territories_tbl_type IS TABLE OF lcu_child_territories%ROWTYPE INDEX BY BINARY_INTEGER;
lt_child_territories child_territories_tbl_type;
lt_lowest_child_territories child_territories_tbl_type;

lc_resource_details  lcu_resource_dtls%rowtype;
lc_access_type       jtf_terr_rsc_access_all.access_type%type;
BEGIN

   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------

   --WRITE_OUT(RPAD(' ',243,'-'));
   --WRITE_OUT(RPAD(' ',1,' ')||RPAD('Office Depot',110)||RPAD(' ',110,' ')||'Date: '||trunc(SYSDATE));
   --WRITE_OUT(RPAD(' ',243,'-'));
   --WRITE_OUT(RPAD(' ',115,' ')||RPAD('OD: TM Territories Resources Report',43));
   -- WRITE_OUT(RPAD(' ',243,'-'));
   --WRITE_OUT('');
   
   SELECT JTA.name 
   INTO   lc_parent_terr_name
   FROM   jtf_terr_all JTA
   WHERE  JTA.terr_id = p_terr_id;
   
   --WRITE_OUT(RPAD(' ',1,' ')||'Input Parameters ');
   --WRITE_OUT(RPAD(' ',1,' ')||'Territory Name : '||lc_parent_terr_name);
   --WRITE_OUT(RPAD(' ',243,'-'));
   
   WRITE_OUT('Input Parameters ');
   WRITE_OUT('Territory Name : '||lc_parent_terr_name);
   /*WRITE_OUT(
             RPAD(' ',1,' ')||chr(9)
             ||RPAD('Territory Name',45,' ')||RPAD(' ',2,' ')||chr(9)
             ||RPAD('Parent Territory Name',45,' ')||RPAD(' ',2,' ')||chr(9)
             ||RPAD('Employee Number ',20,' ')||RPAD(' ',2,' ')||chr(9)
             ||RPAD('Resource Name ',30,' ')||RPAD(' ',2,' ')||chr(9)
             ||RPAD('Role Name ',30,' ')||RPAD(' ',2,' ')||chr(9)
             ||RPAD('Group Name ',30,' ')||RPAD(' ',2,' ')||chr(9)
             ||RPAD('Division ',30,' ')||chr(9)
            );*/
            
            WRITE_OUT(
                         RPAD('Territory Name',45,' ')||chr(9)
                         ||RPAD('Parent Territory Name',45,' ')||chr(9)
                         ||RPAD('Employee Number ',20,' ')||chr(9)
                         ||RPAD('Resource Name ',30,' ')||chr(9)
                         ||RPAD('Access Type ',20,' ')||chr(9)
                         ||RPAD('Role Name ',30,' ')||chr(9)
                         ||RPAD('Group Name ',30,' ')||chr(9)
             ||RPAD('Division ',30,' ')||chr(9));
  /* WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD('-',45,'-')||RPAD(' ',2,' ')||
             RPAD('-',45,'-')||RPAD(' ',2,' ')||
             RPAD('-',20,'-')||RPAD(' ',2,' ')||
             RPAD('-',30,'-')||RPAD(' ',2,' ')||
             RPAD('-',30,'-')||RPAD(' ',2,' ')||
             RPAD('-',30,'-')||RPAD(' ',2,' ')||
             RPAD('-',30,'-')

            );*/
            
   
   OPEN lcu_child_territories(
                              p_terr_id => p_terr_id
                             );
   FETCH lcu_child_territories BULK COLLECT INTO lt_child_territories;
   CLOSE lcu_child_territories;
   
   IF lt_child_territories.COUNT > 0 THEN    
     
       FOR i IN lt_child_territories.FIRST .. lt_child_territories.LAST
       LOOP
           
           ln_count := NULL;
           
           -- For each child territory chech whether it is the lowest-level child territory
           
           SELECT COUNT(1)
           INTO   ln_count
           FROM   jtf_terr_all JTA
           WHERE  JTA.parent_territory_id = lt_child_territories(i).terr_id;
           
           IF ln_count = 0 THEN
              
              ln_index := ln_index + 1;
              lt_lowest_child_territories(ln_index) := lt_child_territories(i);
              
           END IF;
       
       END LOOP; -- lt_child_territories.FIRST .. lt_child_territories.LAST
       
       -- Delete the table
       lt_child_territories.DELETE;
       
       IF lt_lowest_child_territories.COUNT <> 0 THEN
          
          FOR j IN lt_lowest_child_territories.FIRST .. lt_lowest_child_territories.LAST
          LOOP
              
              lc_resource_exists     := 'N';
              lc_resource_active     := NULL;
              lc_resource_group      := NULL;
              lc_resource_group_role := NULL;
              ln_res_count           :=0;
              FOR lcu_resource_details_rec IN lcu_resource_details(lt_lowest_child_territories(j).terr_id)
              LOOP
                  
                  lc_resource_exists := 'Y';
                  BEGIN
                       
                       -- Check whether the resource is terminated in the Resource Manager
                      lc_access_type:='(null)'; 
                      BEGIN 
                      OPEN lcu_access_type(lt_lowest_child_territories(j).terr_id);
                      FETCH lcu_access_type into lc_access_type;
                      CLOSE lcu_access_type;

                      EXCEPTION 
                      WHEN OTHERS THEN
                      lc_access_type := '(null)';
                      END; 

                       
                       IF lcu_resource_details_rec.resource_id IS NOT NULL and
                          lcu_resource_details_rec.group_id IS NOT NULL and
                          lcu_resource_details_rec.role IS NOT NULL THEN
                          
                          open lcu_resource_dtls (p_resource_id =>lcu_resource_details_rec.resource_id,
                                                  p_group_id =>lcu_resource_details_rec.group_id,
                                                  p_role =>lcu_resource_details_rec.role);
                          fetch lcu_resource_dtls into  lc_resource_details;
                          
                          close lcu_resource_dtls;
                          
                          print_display(
                                       p_parent_terr_name  =>lt_lowest_child_territories(j).parent_territory_name
                                     , p_child_terr_name  =>lt_lowest_child_territories(j).name
                                     , p_resource_id      => lc_resource_details.employee_number
                                     , p_resource_name    =>lc_resource_details.source_name
                                     , p_access_type      =>lc_access_type
                                     , p_role_name       =>lc_resource_details.role_name
                                     , p_group_name      =>lc_resource_details.group_name
                                     , p_division        =>lc_resource_details.attribute15
                                     );
                            
                       --END IF; -- lcu_resource_details_rec.group_id IS NOT NULL
                       ELSE
                        open lcu_manager(p_resource_id => lcu_resource_details_rec.resource_id,
                                         p_group_id =>lcu_resource_details_rec.group_id);
                        fetch lcu_manager into lc_manager_flag; 
                        close lcu_manager;
                        
                        open lcu_resource_dtls2(p_resource_id => lcu_resource_details_rec.resource_id,
                                                p_group_id =>lcu_resource_details_rec.group_id);
                        
                        fetch lcu_resource_dtls2 into lc_resource_details;
                        close lcu_resource_dtls2;
                          print_display(
                                       p_parent_terr_name  =>lt_lowest_child_territories(j).parent_territory_name
                                     , p_child_terr_name  =>lt_lowest_child_territories(j).name
                                     , p_resource_id      => lc_resource_details.employee_number
                                     , p_resource_name    =>lc_resource_details.source_name
                                     , p_access_type      =>lc_access_type
                                     , p_role_name       =>lc_resource_details.role_name
                                     , p_group_name      =>lc_resource_details.group_name
                                     , p_division        =>lc_resource_details.attribute15
                                     );                        
                       END IF;
                  EXCEPTION
                     WHEN EX_RSC_ERR THEN
                         NULL;
                     WHEN OTHERS THEN
                        null;
                  END;
                  
                  
              END LOOP; -- lcu_resource_details_rec IN lcu_resource_details              
          END LOOP; -- lt_lowest_child_territories.FIRST .. lt_lowest_child_territories.LAST       
       END IF; -- lt_lowest_child_territories.COUNT <> 0
    
   END IF; -- lt_child_territories.COUNT = 0 
   
  -- WRITE_OUT(RPAD(' ',243,'-'));
      
EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while creating the report';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       x_errbuf         := lc_error_message;
       x_retcode        := 2 ;
       WRITE_LOG(x_errbuf);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_TERR_WITHOUT_RSC_REP.TERR_WITHOUT_RSC'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_TERR_WITHOUT_RSC_REP.TERR_WITHOUT_RSC'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );   
END terr_rsc;

END XX_JTF_TERR_RSC_REP;
/
SHOW ERRORS;
--EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================