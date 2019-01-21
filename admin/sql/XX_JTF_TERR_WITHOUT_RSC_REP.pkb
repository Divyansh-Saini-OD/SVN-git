SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_TERR_WITHOUT_RSC_REP package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_JTF_TERR_WITHOUT_RSC_REP
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_TERR_WITHOUT_RSC_REP                                   |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: TM Territories without Resources Report' with    |
-- |                     Territory Name as the mandatory Input parameter.              |
-- |                     This public procedure will display the lowest-level child     |
-- |                     records in which the following conditions are met             |
-- |                     1. No resource is assigned to territory                       |
-- |                     2. End Dated resource on the territory (and no other active   |
-- |                            resource is assigned to that territory)                |
-- |                     3.There is a mismatch of the group and role for a resource    |
-- |                       between the rule-based territory and that of in the Resource| 
-- |                       Manager.                                                    |
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
                        , p_reason          VARCHAR2 
                        ,  p_count_zip_code NUMBER
                       )
IS
---------------------------
--Declaring local variables
---------------------------
lc_message            VARCHAR2(2000);
lc_err_message        VARCHAR2(2000);

BEGIN
   
  /* WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD(p_parent_terr_name,45,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD(p_child_terr_name,45,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD(p_reason,83,' ')||RPAD(' ',3,' ')
            );*/
            
            WRITE_OUT(
	                 RPAD(' ',1,' ')
	                 ||RPAD(p_parent_terr_name,45,' ')||RPAD(' ',3,' ')
	                 ||RPAD(' ',3,' ')||chr(9)
	                 ||RPAD(p_child_terr_name,45,' ')||RPAD(' ',3,' ')
	                 ||RPAD(' ',3,' ')||chr(9)
	                 ||RPAD(p_reason,83,' ')||RPAD(' ',3,' ')||chr(9)
                         ||p_count_zip_code
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

PROCEDURE terr_without_rsc
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
          , (
          SELECT count(JTV.low_value_char)
          from jtf_terr_values_all JTV
              , jtf_qual_usgs_all JQU
              , jtf_terr_qual_all JTQ
          WHERE jta.terr_id = jtq.terr_id
AND        jtq.terr_qual_id = jtv.terr_qual_id
AND        jtq.qual_usg_id = jqu.qual_usg_id
AND        jqu.qual_usg_id = -1007
AND        jqu.enabled_flag = 'Y'
          ) as count_zip_codes
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

--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE child_territories_tbl_type IS TABLE OF lcu_child_territories%ROWTYPE INDEX BY BINARY_INTEGER;
lt_child_territories child_territories_tbl_type;
lt_lowest_child_territories child_territories_tbl_type;

BEGIN

   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------

   /*WRITE_OUT(RPAD(' ',186,'-'));
   WRITE_OUT(RPAD(' ',1,' ')||RPAD('Office Depot',110)||RPAD(' ',40,' ')||'Date: '||trunc(SYSDATE));
   WRITE_OUT(RPAD(' ',186,'-'));
   WRITE_OUT(RPAD(' ',90,' ')||RPAD('OD: TM Territories without Resources Report',43));
   WRITE_OUT(RPAD(' ',186,'-'));
   WRITE_OUT('');
   
   SELECT JTA.name 
   INTO   lc_parent_terr_name
   FROM   jtf_terr_all JTA
   WHERE  JTA.terr_id = p_terr_id;
   
   WRITE_OUT(RPAD(' ',1,' ')||'Input Parameters ');
   WRITE_OUT(RPAD(' ',1,' ')||'Territory Name : '||lc_parent_terr_name);
   WRITE_OUT(RPAD(' ',186,'-'));
   WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD('Parent Territory Name',45,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD('Child Territory Name',45,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD('Reason',83,' ')
            );
   WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD('-',45,'-')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD('-',45,'-')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD('-',83,'-')
            );*/
           
               	       
	       SELECT JTA.name 
	       INTO   lc_parent_terr_name
	       FROM   jtf_terr_all JTA
	       WHERE  JTA.terr_id = p_terr_id;
	       
	       WRITE_OUT(RPAD(' ',1,' ')||'Input Parameters ');
	       WRITE_OUT(RPAD(' ',1,' ')||'Territory Name : '||lc_parent_terr_name);
	       WRITE_OUT(
	                 RPAD(' ',1,' ')
	                 ||RPAD('Parent Territory Name',45,' ')||RPAD(' ',3,' ')
	                 ||RPAD(' ',3,' ')||chr(9)
	                 ||RPAD('Child Territory Name',45,' ')||RPAD(' ',3,' ')
	                 ||RPAD(' ',3,' ')||chr(9)
	                 ||RPAD('Reason',83,' ')||chr(9)
                         ||'No of Zip Codes'
	                );
	       
            
   
   OPEN lcu_child_territories(
                              p_terr_id => p_terr_id
                             );
   FETCH lcu_child_territories BULK COLLECT INTO lt_child_territories;
   CLOSE lcu_child_territories;
   
   IF lt_child_territories.COUNT = 0 THEN
      
      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0247_NO_CHILD_TERRITORY');
      FND_MESSAGE.SET_TOKEN('P_TERR_NAME', lc_parent_terr_name);
      lc_error_message := FND_MESSAGE.GET;
      WRITE_OUT(lc_error_message);
      
   ELSE
       
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
                       
                       BEGIN
                            
                            SELECT 'Y'
                            INTO   lc_resource_active
                            FROM   jtf_rs_resource_extns JRRE
                            WHERE  JRRE.resource_id = lcu_resource_details_rec.resource_id
                            AND    SYSDATE BETWEEN NVL(JRRE.start_date_active,SYSDATE) AND NVL(JRRE.end_date_active,SYSDATE); 
                       
                       EXCEPTION
                          WHEN OTHERS THEN
                              lc_resource_active := 'N';
                       END;
                       
                       IF lc_resource_active = 'N' THEN
                          
                          -- As the resource is end-dated log the message as resource end-dated
                          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0248_RSC_END_DATED_RM');
                          FND_MESSAGE.SET_TOKEN('P_RESOURCE_NUMBER', lcu_resource_details_rec.resource_number);
                          lc_error_message := FND_MESSAGE.GET;
                          
                          print_display(
                                        p_parent_terr_name  => lt_lowest_child_territories(j).parent_territory_name
                                        , p_child_terr_name => lt_lowest_child_territories(j).name
                                        , p_reason          => lc_error_message
                                        , p_count_zip_code => lt_lowest_child_territories(j).count_zip_codes
                                       );
                          
                          RAISE EX_RSC_ERR;
                       
                       END IF; -- lc_resource_active = 'N'
                       
                       IF lcu_resource_details_rec.group_id IS NOT NULL THEN
                                                   
                          -- Check whether the resource - group combination is valid
                          
                          BEGIN
                                                                        
                               SELECT 'Y'
                               INTO   lc_resource_group
                               FROM   jtf_rs_group_members JRG
                               WHERE  JRG.resource_id = lcu_resource_details_rec.resource_id
                               AND    JRG.group_id = lcu_resource_details_rec.group_id
                               AND    NVL(JRG.delete_flag,'N') <> 'Y'; 
                                                      
                          EXCEPTION
                             WHEN OTHERS THEN
                                 lc_resource_group := 'N';
                          END;
                          
                          IF lc_resource_group = 'N' THEN
                             
                             -- As the resource - group combination is invalid, log the message in the log file
                             FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0249_RSC_GRP_INVALID');
                             FND_MESSAGE.SET_TOKEN('P_RESOURCE_NUMBER', lcu_resource_details_rec.resource_number);
                             FND_MESSAGE.SET_TOKEN('P_GROUP_ID', lcu_resource_details_rec.group_id);
                             lc_error_message := FND_MESSAGE.GET;
                                                                     
                             print_display(
                                           p_parent_terr_name  => lt_lowest_child_territories(j).parent_territory_name
                                           , p_child_terr_name => lt_lowest_child_territories(j).name
                                           , p_reason          => lc_error_message
                                           , p_count_zip_code => lt_lowest_child_territories(j).count_zip_codes
                                          );
                                                    
                             RAISE EX_RSC_ERR;
                                 
                          END IF;
                          
                          IF lcu_resource_details_rec.role IS NOT NULL THEN
                                                    
                             -- Check whether the resource - group - role combination is valid
                             BEGIN
                                  
                                  SELECT 'Y'
                                  INTO   lc_resource_group_role
                                  FROM   jtf_rs_role_relations JRR
                                         , jtf_rs_group_members JRG
                                         , jtf_rs_roles_b ROL
                                  WHERE  JRR.role_resource_id  = JRG.group_member_id
                                  AND    JRG.resource_id = lcu_resource_details_rec.resource_id
                                  AND    JRG.group_id = lcu_resource_details_rec.group_id
                                  AND    ROL.role_code = lcu_resource_details_rec.role
                                  AND    ROL.active_flag = 'Y'
                                  AND    JRR.role_id = ROL.role_id
                                  AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active) AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
                                  AND    NVL(JRR.delete_flag,'N') <> 'Y'
                                  AND    NVL(JRG.delete_flag,'N') <> 'Y';
                             
                             EXCEPTION
                                WHEN OTHERS THEN
                                    lc_resource_group_role := 'N';
                             END;
                             
                             IF lc_resource_group_role = 'N' THEN
                                
                                -- As the resource - group - role combination is invalid, log the message in the log file
                                FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0250_RSC_GRP_ROLE_INVALD');
                                FND_MESSAGE.SET_TOKEN('P_RESOURCE_NUMBER', lcu_resource_details_rec.resource_number);
                                FND_MESSAGE.SET_TOKEN('P_GROUP_ID', lcu_resource_details_rec.group_id);
                                FND_MESSAGE.SET_TOKEN('P_ROLE', lcu_resource_details_rec.role);
                                lc_error_message := FND_MESSAGE.GET;
                                                                                                                      
                                print_display(
                                              p_parent_terr_name  => lt_lowest_child_territories(j).parent_territory_name
                                              , p_child_terr_name => lt_lowest_child_territories(j).name
                                              , p_reason          => lc_error_message
                                              , p_count_zip_code => lt_lowest_child_territories(j).count_zip_codes
                                             );
                                                                                    
                                RAISE EX_RSC_ERR;
                                                                 
                             END IF; -- lc_resource_group_role = 'N'
                                                 
                          END IF; -- lcu_resource_details_rec.role IS NOT NULL
                            
                       END IF; -- lcu_resource_details_rec.group_id IS NOT NULL
                       
                  EXCEPTION
                     WHEN EX_RSC_ERR THEN
                         NULL;
                     WHEN OTHERS THEN
                         NULL;
                  END;
                  
                  IF lc_resource_active ='Y' 
                  and lc_resource_group='Y'
                  and lc_resource_group_role ='Y' Then 
                     ln_res_count := ln_res_count +1;
                  end if;
                  
              END LOOP; -- lcu_resource_details_rec IN lcu_resource_details
              
              IF lc_resource_exists = 'N' THEN
                 
                 FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0251_NO_ACTIVE_RSC');
                 lc_error_message := FND_MESSAGE.GET;
                 
                 print_display(
                               p_parent_terr_name  => lt_lowest_child_territories(j).parent_territory_name
                               , p_child_terr_name => lt_lowest_child_territories(j).name
                               , p_reason          => lc_error_message
                               , p_count_zip_code => lt_lowest_child_territories(j).count_zip_codes
                              );
                              
              END IF; -- lc_resource_exists = 'N'
              IF ln_res_count > 1 THEN
                 
                 FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0263_MULTI_RESOURCE');
                 lc_error_message := FND_MESSAGE.GET;
                 write_log (lt_lowest_child_territories(j).name ||'   '||lt_lowest_child_territories(j).parent_territory_name);
                 print_display(
                               p_parent_terr_name  => lt_lowest_child_territories(j).parent_territory_name
                               , p_child_terr_name => lt_lowest_child_territories(j).name
                               , p_reason          => lc_error_message
                               , p_count_zip_code => lt_lowest_child_territories(j).count_zip_codes
                              );
                              
              END IF; -- lc_resource_exists = 'N'              
              
          END LOOP; -- lt_lowest_child_territories.FIRST .. lt_lowest_child_territories.LAST
       
       END IF; -- lt_lowest_child_territories.COUNT <> 0
    
   END IF; -- lt_child_territories.COUNT = 0 
   
 --  WRITE_OUT(RPAD(' ',186,'-'));
      
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
END terr_without_rsc;

END XX_JTF_TERR_WITHOUT_RSC_REP;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================