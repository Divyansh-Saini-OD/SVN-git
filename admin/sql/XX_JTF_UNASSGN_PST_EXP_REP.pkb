SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_UNASSGN_PST_EXP_REP package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_JTF_UNASSGN_PST_EXP_REP 
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_UNASSGN_PST_EXP_REP                                    |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: TM Unassigned Party Sites Exception Report' with |
-- |                     Party Site ID From and Party Site ID To as the Input          |  
-- |                     parameters. This public procedure will create a report        |
-- |                     consisting of the party sites of external customers that are  |
-- |                     not assigned to any of the sales reps                         |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Create_Exception_Report This is the public procedure.                 |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  30-Jan-07   Abhradip Ghosh               Initial draft version           |
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
                                          , p_program_name           => 'XX_JTF_UNASSGN_PST_EXP_REP.WRITE_LOG'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_UNASSGN_PST_EXP_REP.WRITE_LOG'
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

PROCEDURE write_out(
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
       lc_set_message     :=  'Unexpected Error while writing to the output file.';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR 
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_UNASSGN_PST_EXP_REP.WRITE_OUT'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_UNASSGN_PST_EXP_REP.WRITE_OUT'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
      
END write_out;

-- +===================================================================+
-- | Name  : print_display                                             |
-- |                                                                   |
-- | Description:       This is the private procedure to print the     |
-- |                    details of the record in the log file          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE print_display(
                        p_party_id        VARCHAR2
                        , p_party_site_id VARCHAR2
                        , p_wcw           VARCHAR2
                        , p_sic_code      VARCHAR2
                        , p_postal_code   VARCHAR2
                        , p_resource_id   VARCHAR2
                       )
IS
---------------------------
--Declaring local variables
---------------------------
lc_message            VARCHAR2(2000);
lc_err_message        VARCHAR2(2000);

BEGIN
   
   WRITE_LOG(
             RPAD(p_party_id,15,' ')||RPAD(' ',3,' ')||
             RPAD(p_party_site_id,15,' ')||RPAD(' ',3,' ')||
             RPAD(NVL(p_wcw,'XX'),15,' ')||RPAD(' ',3,' ')||
             RPAD(NVL(p_sic_code,'XX'),15,' ')||RPAD(' ',3,' ')||
             RPAD(NVL(p_postal_code,'XX'),15,' ')||RPAD(' ',3,' ')||
             RPAD(NVL(p_resource_id,'XX'),15,' ')
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
                                          , p_program_name           => 'XX_JTF_UNASSGN_PST_EXP_REP.PRINT_DISPLAY'
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_UNASSGN_PST_EXP_REP.PRINT_DISPLAY' 
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
END print_display;

-- +===================================================================+
-- | Name  : check_for_external_org                                    |
-- |                                                                   |
-- | Description:       This is the private procedure to check whether |
-- |                    the party is an external organization          |
-- |                                                                   |
-- +===================================================================+

PROCEDURE check_for_external_org(
                                 p_party_id           NUMBER
                                 , p_external_org OUT VARCHAR2
                                )
IS
---------------------------
--Declaring local variables
---------------------------
lc_party_org   VARCHAR2(02);
lc_ext_party   VARCHAR2(02);
lc_int_party   VARCHAR2(02);
BEGIN
   
   -- First check whether the party_type = 'ORGANIZATION'
   
   SELECT 'Y'
   INTO   lc_party_org
   FROM   hz_parties HP
   WHERE  HP.party_id = p_party_id
   AND    HP.party_type = 'ORGANIZATION';
   
   -- Next check whether the party_id is of external type
   
   BEGIN
        SELECT 'N'
        INTO   lc_int_party
        FROM   hz_cust_accounts HCA
        WHERE  HCA.party_id = p_party_id
        AND    HCA.customer_type = 'I';
   EXCEPTION
      WHEN OTHERS THEN
          lc_int_party := 'Y';
   END;       
   
   IF lc_party_org = 'Y' AND lc_int_party = 'Y' THEN
     p_external_org := 'Y';
   ELSE
       p_external_org := 'N';
   END IF;    
   
EXCEPTION
   WHEN OTHERS THEN
       p_external_org := 'N';
END check_for_external_org;

-- +===================================================================+
-- | Name  : create_exception_report                                   |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD: TM     | 
-- |                    Unassigned Party Sites Exception Report' with  |
-- |                    Party Site ID From and Party Site ID To as the |
-- |                    Input parameters to  create a report consisting|
-- |                    of the party sites of external customers that  |
-- |                    that are not assigned to any of the sales reps |
-- |                                                                   |
-- +===================================================================+

PROCEDURE create_exception_report
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
             , p_from_party_site_id IN  NUMBER
             , p_to_party_site_id   IN  NUMBER
            )
IS
---------------------------
--Declaring local variables
---------------------------
EX_ATTR_GRP_ID       EXCEPTION;
ln_last_party_id     PLS_INTEGER := 0;
ln_party_id          PLS_INTEGER ;
ln_attr_group_id     PLS_INTEGER;
ln_total_count       PLS_INTEGER := 0;
ln_party_site_id     PLS_INTEGER;
ln_wcw               PLS_INTEGER;
ln_wcw_count         PLS_INTEGER := 0;
ln_exists_count      PLS_INTEGER;
ln_un_pty_site_count PLS_INTEGER := 0;
ln_location_id       PLS_INTEGER;
ln_count             PLS_INTEGER;
lc_ext_org_flag      VARCHAR2(03) := 'Y';
lc_manager_flag      VARCHAR2(03);
lc_error_message     VARCHAR2(2000);
lc_exists            VARCHAR2(03) := 'Y';
lc_postal_code       VARCHAR2(30);
lc_sic_code          VARCHAR2(30);
lc_wcw_value         VARCHAR2(30);
lc_print_flag        VARCHAR2(03);
lc_un_pty_site_count VARCHAR2(2000);
lc_wcw_count         VARCHAR2(2000);
lc_resource_id       VARCHAR2(2000);
lc_set_message       VARCHAR2(2000);

-- -----------------------
-- Declaring record types
-- -----------------------
TYPE pty_psite_rec_type  IS RECORD
(
 PARTY_ID        PLS_INTEGER
 , PARTY_SITE_ID PLS_INTEGER
 , LOCATION_ID   PLS_INTEGER
);

-- -----------------------
-- Declaring table types
-- -----------------------
TYPE pty_psite_tbl_type IS TABLE OF pty_psite_rec_type INDEX BY BINARY_INTEGER;
lt_pty_psite_tbl  pty_psite_tbl_type;

-- --------------------------------------------------------------------------------
-- Cursor to fetch records from the hz_party_sites based on the input parameters
-- --------------------------------------------------------------------------------
CURSOR lcu_get_party_dtls
IS
SELECT HPS.party_id 
       , HPS.party_site_id
       , HPS.location_id
FROM   hz_party_sites HPS
WHERE  (
         (
          p_from_party_site_id IS NOT NULL AND
          p_to_party_site_id IS NOT NULL AND
          HPS.party_site_id BETWEEN p_from_party_site_id AND p_to_party_site_id
         )
        OR(
           p_from_party_site_id IS NULL AND
           p_to_party_site_id IS NULL AND
           HPS.party_site_id > 0
          )
      )
ORDER BY HPS.party_id
         , HPS.party_site_id;
         

-- ----------------------------------------------------------------------------------------------
-- Cursor to fetch resource records from xx_tm_nam_terr_curr_assign_v based on the party_site_id
-- ----------------------------------------------------------------------------------------------
CURSOR lcu_get_resource_dtls(
                             p_party_site_id NUMBER
                            )
IS
SELECT XTN.resource_id
       , XTN.resource_role_id
       , XTN.group_id
FROM   xx_tm_nam_terr_curr_assign_v XTN
WHERE  XTN.entity_type = 'PARTY_SITE'
AND    XTN.entity_id   = p_party_site_id;


BEGIN
   
   -- Derive the attribute_group_id
   
   BEGIN
        
        SELECT EAG.attr_group_id
        INTO   ln_attr_group_id
        FROM   ego_attr_groups_v EAG
        WHERE  EAG.attr_group_type = 'HZ_PARTY_SITES_GROUP'
        AND    EAG.attr_group_name = 'SITE_DEMOGRAPHICS';
   
   EXCEPTION
      WHEN OTHERS THEN
          RAISE EX_ATTR_GRP_ID;
   END;
   
   
   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------
   WRITE_LOG(RPAD('-',105,'-'));
   WRITE_LOG(RPAD(' ',39,' ')||'Office Depot'||RPAD(' ',39,' ')||'DATE: '||TRUNC(SYSDATE));
   WRITE_LOG(RPAD('-',105,'-'));
   WRITE_LOG(RPAD(' ',30,' ')||'OD: TM Unassigned Party Sites Exception Report'||RPAD(' ',19,' '));
   WRITE_LOG(RPAD('-',105,'-'));
   WRITE_LOG(
             RPAD('Party_Id',15,' ')||RPAD(' ',3,' ')||
             RPAD('Party_Site_Id',15,' ')||RPAD(' ',3,' ')||
             RPAD('WCW',15,' ')||RPAD(' ',3,' ')||
             RPAD('SIC Code',15,' ')||RPAD(' ',3,' ')||
             RPAD('Postal Code',15,' ')||RPAD(' ',3,' ')||
             RPAD('Resource_Id',15,' ')
            );
   WRITE_LOG(
             RPAD('-',15,'-')||RPAD(' ',3,' ')||
             RPAD('-',15,'-')||RPAD(' ',3,' ')||
             RPAD('-',15,'-')||RPAD(' ',3,' ')||
             RPAD('-',15,'-')||RPAD(' ',3,' ')||
             RPAD('-',15,'-')||RPAD(' ',3,' ')||
             RPAD('-',15,'-')
            );
   
   WRITE_OUT(RPAD('-',105,'-'));
   WRITE_OUT(RPAD(' ',39,' ')||'Office Depot'||RPAD(' ',39,' ')||'DATE: '||TRUNC(SYSDATE));
   WRITE_OUT(RPAD('-',105,'-'));
   WRITE_OUT(RPAD(' ',30,' ')||'OD: TM Unassigned Party Sites Exception Report'||RPAD(' ',19,' '));
   WRITE_OUT(RPAD('-',105,'-'));
   
   -- Retrieve the records from HZ_PARTY_SITES based on the two input parameters to the table type
   
   OPEN lcu_get_party_dtls;
   LOOP
       
       FETCH lcu_get_party_dtls BULK COLLECT INTO lt_pty_psite_tbl LIMIT G_LIMIT;
       
       IF lt_pty_psite_tbl.COUNT <> 0 THEN
         
         FOR i IN lt_pty_psite_tbl.FIRST .. lt_pty_psite_tbl.LAST
         LOOP
             
             ln_total_count := ln_total_count + 1;
             ln_party_id    := lt_pty_psite_tbl(i).party_id;
             
             IF (
                 (ln_last_party_id <> ln_party_id)
                  OR ((ln_last_party_id = ln_party_id) AND lc_ext_org_flag <> 'N')
                )THEN
               
               -- Initializing the variables
               
               ln_party_site_id := NULL;
               lc_exists        := NULL;
               ln_location_id   := NULL;
               lc_postal_code   := NULL;
               lc_sic_code      := NULL;
               ln_wcw           := NULL;
               lc_wcw_value     := NULL;
               ln_exists_count  := 0;
               lc_print_flag    := NULL;
               
               ln_party_site_id := lt_pty_psite_tbl(i).party_site_id;
               ln_location_id   := lt_pty_psite_tbl(i).location_id;
               
               IF (ln_last_party_id <> ln_party_id) THEN
                 
                 check_for_external_org(
                                        p_party_id       => ln_party_id
                                        , p_external_org => lc_exists
                                       );
               
               END IF; -- ln_last_party_id <> ln_party_id
               
               IF lc_exists = 'N' THEN
                 
                 lc_ext_org_flag := 'N';
               
               ELSE
                   
                   -- Derive the postal_code for this party_site
                   
                   SELECT NVL(HZL.postal_code,'NULL')
                   INTO   lc_postal_code
                   FROM   HZ_LOCATIONS HZL
                   WHERE  HZL.location_id = ln_location_id;
                   
                   -- Derive the White Colar Worker and SIC Code for this party_site
                   
                   BEGIN
                   
                        SELECT NVL(HZPSE.c_ext_attr10,'NULL')    -- SIC Code
                               , NVL(HZPSE.n_ext_attr8,-1)       -- White Colar Worker
                        INTO   lc_sic_code
                               , ln_wcw
                        FROM   HZ_PARTY_SITES_EXT_VL HZPSE
                        WHERE  HZPSE.attr_group_id = ln_attr_group_id
                        AND    HZPSE.party_site_id = ln_party_site_id;
                   
                   EXCEPTION
                      WHEN OTHERS THEN
                          lc_sic_code := NULL;
                          ln_wcw      := NULL;
                   END;
                   
                   IF ln_wcw = -1 THEN
                     
                     lc_wcw_value := 'NULL';
                   
                   ELSE
                       
                       lc_wcw_value := ln_wcw;
                       
                   END IF;
                   
                   IF ((ln_wcw BETWEEN 0 AND 25) OR (lc_wcw_value = 'NULL') OR (ln_wcw IS NULL)) THEN
                     
                     ln_wcw_count := ln_wcw_count + 1;
                   
                   END IF; -- ((ln_wcw = 0) OR (lc_wcw_value = 'NULL'))
                   
                   -- Check whether the party_site_record exists in custom assignments table
                                        
                   SELECT count(1)
                   INTO   ln_exists_count
                   FROM   xx_tm_nam_terr_entity_dtls XTN
                   WHERE  XTN.entity_id   = ln_party_site_id
                   AND    XTN.entity_type = 'PARTY_SITE'
                   AND    XTN.end_date_active IS NULL
                   AND    NVL(XTN.status,'A') = 'A';
                                        
                   IF ln_exists_count = 0 THEN
                                          
                     lc_print_flag := 'Y';
                     ln_un_pty_site_count := ln_un_pty_site_count + 1;
                                        
                   END IF; -- lc_print_flag = 'Y';
                   
                   IF (
                       ( 
                        (lc_sic_code IS NULL) OR (lc_sic_code = 'NULL') OR (ln_wcw BETWEEN 0 AND 25) 
                           OR (lc_wcw_value = 'NULL') OR (ln_wcw IS NULL) 
                       )
                       AND (ln_exists_count <> 0)
                      ) THEN
                      
                      lc_print_flag := 'N';
                      
                      FOR lcu_get_resource_rec IN lcu_get_resource_dtls(ln_party_site_id)
                      LOOP
                          
                          -- Initializaing the variables
                          lc_manager_flag := NULL;
                          ln_count        := 0;
                          lc_resource_id  := NULL;
                          
                          -- Check whether the resource is a manager
                          
                          BEGIN
                               
                               SELECT 'Y'
                               INTO   lc_manager_flag
                               FROM   jtf_rs_role_relations JRR
                                      , jtf_rs_group_members MEM
                                      , jtf_rs_group_usages JRU
                                      , jtf_rs_roles_b ROL
                               WHERE  JRR.role_resource_id = MEM.group_member_id
                               AND    MEM.resource_id = lcu_get_resource_rec.resource_id
                               AND    MEM.group_id = lcu_get_resource_rec.group_id
                               AND    ROL.role_id = lcu_get_resource_rec.resource_role_id
                               AND    MEM.group_id = JRU.group_id
                               AND    JRU.USAGE='SALES'
                               AND    ROL.attribute14 = 'HSE'
                               AND    JRR.role_id = ROL.role_id
                               AND    ROL.role_type_code='SALES'
                               AND    ROL.active_flag = 'Y'
                               AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active) AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
                               AND    NVL(JRR.delete_flag,'N') <> 'Y'
                               AND    NVL(MEM.delete_flag,'N') <> 'Y';
                          
                          EXCEPTION
                             WHEN OTHERS THEN
                                 lc_manager_flag := 'N';
                          END;
                          
                          
                          IF lc_manager_flag = 'N' THEN
                            
                            -- Cross verify to check whether the resource is a manager
                            
                            SELECT count(ROL.manager_flag)
                            INTO   ln_count
                            FROM   jtf_rs_role_relations JRR
                                   , jtf_rs_group_members MEM
                                   , jtf_rs_group_usages JRU
                                   , jtf_rs_roles_b ROL
                            WHERE  JRR.role_resource_id = MEM.group_member_id
                            AND    MEM.resource_id = lcu_get_resource_rec.resource_id
                            AND    MEM.group_id = lcu_get_resource_rec.group_id
                            AND    MEM.group_id = JRU.group_id
                            AND    JRU.USAGE='SALES'
                            AND    JRR.role_id = ROL.role_id
                            AND    ROL.role_type_code='SALES'
                            AND    ROL.manager_flag = 'Y'
                            AND    ROL.active_flag = 'Y'
                            AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active) AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
                            AND    NVL(JRR.delete_flag,'N') <> 'Y'
                            AND    NVL(MEM.delete_flag,'N') <> 'Y';
                            
                            IF ln_count = 0 THEN
                                          
                              -- This means the resource is a sales-rep
                              lc_manager_flag := 'N';
                                                
                            ELSIF ln_count = 1 THEN
                                                               
                                 -- This means the resource is a manager
                                 lc_manager_flag := 'Y'; 
                            
                            END IF; -- ln_count = 0
                          
                          END IF; -- lc_manager_flag = 'N'
                          
                          IF lc_manager_flag = 'Y' THEN
                            
                            -- Print the resource_id
                            lc_resource_id := lcu_get_resource_rec.resource_id;
                            
                            -- Print the record
                            print_display(
                                          p_party_id        => ln_party_id
                                          , p_party_site_id => ln_party_site_id
                                          , p_wcw           => lc_wcw_value
                                          , p_sic_code      => lc_sic_code
                                          , p_postal_code   => lc_postal_code
                                          , p_resource_id   => lc_resource_id
                                         );
                            
                          END IF; -- lc_manager_flag = 'Y'
                          
                      END LOOP;
                       
                   ELSE
                       
                       lc_print_flag := 'Y';
                   
                   END IF; 
                   
                   IF lc_print_flag = 'Y' THEN
                     
                     print_display(
                                   p_party_id        => ln_party_id
                                   , p_party_site_id => ln_party_site_id
                                   , p_wcw           => lc_wcw_value
                                   , p_sic_code      => lc_sic_code
                                   , p_postal_code   => lc_postal_code
                                   , p_resource_id   => lc_resource_id
                                  );
                                  
                   END IF; -- lc_print_flag = 'Y'
                   
                   ln_last_party_id := lt_pty_psite_tbl(i).party_id;
                 
               END IF; -- lc_exists
             
             END IF; -- ((ln_last_party_id <> ln_party_id)OR ((ln_last_party_id = ln_party_id) AND lc_ext_org_flag <> 'N'))
             
         END LOOP; -- lt_pty_psite_tbl.FIRST .. lt_pty_psite_tbl.LAST
       
       END IF ; -- lt_pty_psite_tbl.COUNT
       
       EXIT WHEN lcu_get_party_dtls%NOTFOUND;
   
   END LOOP; -- lcu_get_party_dtls
   
   CLOSE lcu_get_party_dtls;
   
   IF ln_total_count = 0 THEN
     
     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0129_NO_RECORDS');
     FND_MESSAGE.SET_TOKEN('P_FROM_PARTY_SITE_ID', p_from_party_site_id );
     FND_MESSAGE.SET_TOKEN('P_TO_PARTY_SITE_ID', p_to_party_site_id );
     lc_error_message := FND_MESSAGE.GET;
     WRITE_LOG(lc_error_message);
     XX_COM_ERROR_LOG_PUB.log_error_crm(
                                        p_return_code               => FND_API.G_RET_STS_ERROR
                                        , p_application_name        => G_APPLICATION_NAME
                                        , p_program_type            => G_PROGRAM_TYPE
                                        , p_program_name            => 'XX_JTF_UNASSGN_PST_EXP_REP.CREATE_EXCEPTION_REPORT'
                                        , p_program_id              => gn_program_id
                                        , p_module_name             => G_MODULE_NAME
                                        , p_error_location          => 'XX_JTF_UNASSGN_PST_EXP_REP.CREATE_EXCEPTION_REPORT'
                                        , p_error_message_code      => 'XX_TM_0129_NO_RECORDS'
                                        , p_error_message           => lc_error_message
                                        , p_error_message_severity  => G_MEDIUM_ERROR_MSG_SEVERTY
                                        , p_error_status            => G_ERROR_STATUS_FLAG
                                       );
   END IF; -- ln_total_count = 0
   
   -- ---------------------
   -- Write to output file
   -- ---------------------
   
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0232_UNASSGN_PTY_SITE');
   FND_MESSAGE.SET_TOKEN('P_RECORD_COUNT', ln_un_pty_site_count);
   lc_un_pty_site_count    := FND_MESSAGE.GET;
   WRITE_OUT(lc_un_pty_site_count);
   
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0233_WCW_NULL_ZERO');
   FND_MESSAGE.SET_TOKEN('P_RECORD_COUNT', ln_wcw_count);
   lc_wcw_count    := FND_MESSAGE.GET;
   WRITE_OUT(lc_wcw_count);
   
   WRITE_LOG(RPAD('-',105,'-'));
   
EXCEPTION
   WHEN EX_ATTR_GRP_ID THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0231_ATTR_GROUP_ID_ERR');
       lc_error_message := FND_MESSAGE.GET;
       x_errbuf         := lc_error_message;
       x_retcode        := 2 ;
       WRITE_LOG(x_errbuf);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_UNASSGN_PST_EXP_REP.CREATE_EXCEPTION_REPORT'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_UNASSGN_PST_EXP_REP.CREATE_EXCEPTION_REPORT'
                                          , p_error_message_code     => 'XX_TM_0231_ATTR_GROUP_ID_ERR'
                                          , p_error_message          => lc_error_message 
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error in the procedure create_exception_report';
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
                                          , p_program_name           => 'XX_JTF_UNASSGN_PST_EXP_REP.CREATE_EXCEPTION_REPORT'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_UNASSGN_PST_EXP_REP.CREATE_EXCEPTION_REPORT'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message 
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );                                          
END create_exception_report;
END XX_JTF_UNASSGN_PST_EXP_REP;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
