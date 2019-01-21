SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE BODY XX_JTF_RSC_ASGN_SIM_REP
-- +===================================================================================+
-- |                      Office Depot - Project Simplify                              |
-- |                    Oracle NAIO Consulting Organization                            |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_RSC_ASGN_SIM_REP                                       |
-- |                                                                                   |
-- | Description      :  Package body to report the resource details assigned          |
-- |                     as per autoname program for manually created party site       |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    RSC_ASSIGN_MAIN         This is the public procedure                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1A  25-Aug-08   Hema Chikkanna               Initial draft version           |
-- |V 1.0     04-Sep-08   Hema Chikkanna               Incorporated the changes after  |
-- |                                                   Internal Review                 |
-- +===================================================================================+
AS

-- +===================================================================+
-- | Name       : WRITE_LOG                                            |
-- |                                                                   |
-- | Description: This Procedure shall write to the concurrent         |
-- |              program log file                                     |
-- |                                                                   |
-- | Parameters : Name        IN/OUT  Type        Description          |
-- |                                                                   |
-- |              p_message    IN     VARCHAR2    Error Message        |
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
   WHEN OTHERS 
   THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while writing to the log file.';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_error_message);
       
END WRITE_LOG;

-- +===================================================================+
-- | Name       :  WRITE_OUT                                           |
-- |                                                                   |
-- | Description:  This Procedure shall write to the concurrent        |
-- |               program output file                                 |
-- |                                                                   |
-- | Parameters :  Name        IN/OUT  Type        Description         |
-- |                                                                   |
-- |               p_message    IN     VARCHAR2    Output Message      |
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
   WHEN OTHERS 
   THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while writing to the log file.';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_error_message);
       
END WRITE_OUT;

-- +===================================================================+
-- | Name         : RSC_ASSIGN_MAIN                                    |
-- |                                                                   |
-- | Description  : Main procedure to report the resource details      | 
-- |                                                                   |
-- | Parameters :  Name            IN/OUT  Type        Description     |
-- |                                                                   |
-- |               p_created_by    IN     NUMBER      Created By       |
-- |               p_cust_prospect IN     VARCHAR2    CUSTOMER/PROSPECT|
-- |               p_cnty_code     IN     VARCHAR2    Country Code     |
-- |               p_postal_code   IN     VARCHAR2    Postal Code      |
-- |               p_wcw_count     IN     NUMBER      WCW Count        |
-- |               p_sic_code      IN     VARCHAR2    SIC Code(Opt)    |
-- |               p_run_mode      IN     VARCHAR2    Mode of Run      |
-- |                                                  Batch/Manual     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE rsc_assign_main
            (
               x_errbuf          OUT NOCOPY VARCHAR2
             , x_retcode         OUT NOCOPY NUMBER
             , p_run_mode        IN VARCHAR2
             , p_created_by      IN NUMBER
             , p_cust_prospect   IN VARCHAR2
             , p_cnty_code       IN VARCHAR2
             , p_postal_code     IN VARCHAR2
             , p_wcw_count       IN NUMBER
             , p_sic_code        IN VARCHAR2
           )
IS


EX_RESOURCE_ERROR               EXCEPTION;
EX_CREATE_ERR                   EXCEPTION;

ln_api_version                  NUMBER := 1.0;
lc_return_status                VARCHAR2(03);
ln_msg_count                    NUMBER;
lc_msg_data                     VARCHAR2(2000);
l_counter                       NUMBER;
lc_error_message                VARCHAR2(2000);
lc_set_message                  VARCHAR2(2000);
l_squal_char06                  VARCHAR2(4000);
l_squal_char07                  VARCHAR2(4000);
l_squal_char59                  VARCHAR2(4000);
l_squal_char60                  VARCHAR2(4000);
l_squal_num60                   VARCHAR2(4000);

ln_salesforce_id                NUMBER;
ln_sales_group_id               NUMBER;


ln_creator_idx                  PLS_INTEGER := 1;
ln_creator_resource_id          PLS_INTEGER;
ln_creator_role_id              PLS_INTEGER;
lc_creator_role_division        VARCHAR2(50);
ln_creator_group_id             PLS_INTEGER;
lc_creator_group_name           JTF_RS_RESOURCE_EXTNS.source_name%TYPE;
ln_creator_manager_id           PLS_INTEGER;
lc_creator_manager_name         JTF_RS_RESOURCE_EXTNS.source_name%TYPE;
lc_creator_admin_flag           JTF_RS_GROUP_MBR_ROLE_VL.admin_flag%TYPE;
lc_creator_manager_flag         JTF_RS_GROUP_MBR_ROLE_VL.manager_flag%TYPE;
lc_creator_member_flag          JTF_RS_GROUP_MBR_ROLE_VL.member_flag%TYPE; 
lc_role                         VARCHAR2(50);
ln_manager_count                PLS_INTEGER;
ln_admin_count                  PLS_INTEGER;

lc_cr_resource_name             JTF_RS_RESOURCE_EXTNS.source_name%TYPE; 
lc_asgn_resource_name           JTF_RS_RESOURCE_EXTNS.source_name%TYPE;  

lc_assignee_admin_flag          VARCHAR2(10);
lc_assignee_manager_flag        VARCHAR2(10);
lc_assignee_member_flag         VARCHAR2(10);
lc_assignee_group_name          JTF_RS_GROUPS_TL.group_name%TYPE;
lc_assignee_role_division       JTF_RS_ROLES_VL.attribute15%TYPE;
ln_assignee_role_id             NUMBER;
ln_assignee_manager_id          JTF_RS_RESOURCE_EXTNS.resource_id%TYPE;
lc_assignee_manager_name        JTF_RS_RESOURCE_EXTNS.source_name%TYPE;


lc_group_name                   JTF_RS_GROUPS_TL.group_name%TYPE;
ln_is_member                    PLS_INTEGER;

ln_count                        PLS_INTEGER;
ln_group_count                  PLS_INTEGER;



-- ----------------------------------
-- --Declaring Record Type Variables
-- ----------------------------------
lp_gen_bulk_rec           XX_TM_GET_WINNERS_ON_QUALS.lrec_trans_rec_type;
lr_gen_return_rec         JTF_TERR_ASSIGN_PUB.bulk_winners_rec_type;

TYPE resource_det_rec IS RECORD
( resource_id        JTF_RS_RESOURCE_EXTNS.resource_id%TYPE,
  resource_number    JTF_RS_RESOURCE_EXTNS.resource_number%TYPE,
  resource_name      JTF_RS_RESOURCE_EXTNS.source_name%TYPE,
  group_name         JTF_RS_GROUPS_TL.group_name%TYPE,
  manager_name       JTF_RS_RESOURCE_EXTNS.source_name%TYPE,
  member_flag        JTF_RS_GROUP_MBR_ROLE_VL.member_flag%TYPE,
  manager_flag       JTF_RS_GROUP_MBR_ROLE_VL.manager_flag%TYPE, 
  admin_flag         JTF_RS_GROUP_MBR_ROLE_VL.admin_flag%TYPE,
  division           JTF_RS_ROLES_VL.attribute15%TYPE
 );
 
TYPE resource_det_tbl IS TABLE OF resource_det_rec INDEX BY BINARY_INTEGER;

lr_created_det  resource_det_tbl;
lr_winner_det   resource_det_tbl;
lr_assignee_det resource_det_tbl;
lr_null_rec     resource_det_tbl;
 
-- ---------------------------------------------------------
-- Declare cursor to get the resource deatils
-- ---------------------------------------------------------
CURSOR lcu_rsc_det (p_resource_id IN NUMBER)
IS
SELECT JRRE.resource_id
      ,JRRE.resource_number 
      ,JRRE.source_name
FROM   jtf_rs_resource_extns JRRE
WHERE  JRRE.resource_id = p_resource_id;
-- ---------------------------------------------------------
-- Declare cursor to check whether the resource is an admin
-- ---------------------------------------------------------
CURSOR lcu_admin(
                   p_resource_id IN NUMBER
                 , p_group_id    IN NUMBER DEFAULT NULL
                )
IS
SELECT COUNT(ROL.admin_flag)
FROM     jtf_rs_role_relations JRR
       , jtf_rs_group_members  MEM
       , jtf_rs_group_usages   JRU
       , jtf_rs_roles_b        ROL
WHERE  MEM.resource_id           = p_resource_id
AND    NVL(MEM.delete_flag,'N') <> 'Y'
AND    MEM.group_id             = NVL(p_group_id,MEM.group_id)
AND    JRU.group_id             = MEM.group_id
AND    JRU.USAGE                = 'SALES'
AND    JRR.role_resource_id     = MEM.group_member_id
AND    JRR.role_resource_type   = 'RS_GROUP_MEMBER'
AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active)
                      AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
AND    NVL(JRR.delete_flag,'N') <> 'Y'
AND    ROL.role_id              = JRR.role_id
AND    ROL.role_type_code       ='SALES'
AND    ROL.admin_flag           = 'Y'
AND    ROL.active_flag          = 'Y';

-- ----------------------------------------------------------
-- Declare cursor to check whether the resource is a manager
-- ----------------------------------------------------------
CURSOR lcu_manager(
                     p_resource_id IN NUMBER
                   , p_group_id    IN NUMBER DEFAULT NULL
                  )
IS
SELECT COUNT(ROL.manager_flag)
FROM     jtf_rs_role_relations JRR
       , jtf_rs_group_members  MEM
       , jtf_rs_group_usages   JRU
       , jtf_rs_roles_b        ROL
WHERE  MEM.resource_id          = p_resource_id
AND    NVL(MEM.delete_flag,'N') <> 'Y'
AND    MEM.group_id             = NVL(p_group_id,MEM.group_id)
AND    JRU.group_id             = MEM.group_id
AND    JRU.USAGE                = 'SALES'
AND    JRR.role_resource_id     = MEM.group_member_id
AND    JRR.role_resource_type   = 'RS_GROUP_MEMBER'
AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active)
                      AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
AND    NVL(JRR.delete_flag,'N') <> 'Y'
AND    ROL.role_id              = JRR.role_id
AND    ROL.role_type_code       ='SALES'
AND    ROL.manager_flag         = 'Y'
AND    ROL.active_flag          = 'Y'; 

-- -----------------------------------------------------------------------
-- Declare cursor to derive Supervisor name for admin and Manager resource
-- -----------------------------------------------------------------------
CURSOR lcu_sup (
                 p_group_id IN NUMBER
               )
IS               
SELECT  RES.resource_name        
       ,MGR.resource_id          
FROM    jtf_rs_groups_vl         GRPNM
       ,jtf_rs_resource_extns_vl RES
       ,jtf_rs_roles_vl          RLES
       ,jtf_rs_group_mbr_role_vl MGR
       ,jtf_rs_grp_relations_vl  GR
WHERE  GR.group_id            = p_group_id
AND    SYSDATE BETWEEN NVL(GR.start_date_active,SYSDATE - 1) AND NVL(GR.end_date_active,SYSDATE + 1)
AND    NVL(delete_flag,'N')   = 'N'
AND    MGR.group_id           = GR.related_group_id
AND    MGR.manager_flag       = 'Y' 
AND    SYSDATE BETWEEN NVL(MGR.start_date_active,SYSDATE - 1) AND NVL(MGR.end_date_active,SYSDATE + 1)
AND    RLES.role_id           = MGR.role_id
AND    RLES.role_type_code    = 'SALES'
AND    RES.resource_id        = MGR.resource_id
AND    GRPNM.group_id         = MGR.group_id
AND    EXISTS  ( SELECT 1
                 FROM jtf_rs_group_usages  USGS
                 WHERE MGR.group_id    = USGS.group_id 
                 AND   USGS.USAGE = 'SALES'
               )
GROUP BY  RES.resource_name ,MGR.resource_id;

-- ------------------------------------------------------
-- Declare cursor to get the group count of the resource
-- ------------------------------------------------------

CURSOR lcu_res_groups (p_resource_id IN jtf_rs_resource_extns_vl.resource_id%TYPE)
IS
SELECT   COUNT(GRP.group_id)      group_cnt
FROM     jtf_rs_groups_vl         GRPNM     
        ,jtf_rs_group_mbr_role_vl GRP
        ,jtf_rs_group_usages      USAGES
        ,jtf_rs_roles_b           ROLS
WHERE GRPNM.group_id      = GRP.group_id
AND   SYSDATE BETWEEN NVL(GRP.start_date_active,SYSDATE - 1) AND NVL(GRP.end_date_active,SYSDATE + 1)
AND   USAGES.usage        = 'SALES'
AND   GRP.group_id        = USAGES.group_id
AND   ROLS.role_type_code = 'SALES'
AND   GRP.role_id         = ROLS.role_id
AND   GRP.resource_id     = p_resource_id
GROUP BY  GRP.group_id 
         ,GRPNM.group_name;
  

BEGIN
    ----
    -- Deriving the details of the created by resource
    ----
    lr_created_det.DELETE;
    lr_created_det := lr_null_rec;
    
    ln_creator_resource_id := NULL;
    ln_creator_group_id    := NULL;
    lc_cr_resource_name    := NULL;
    
    FOR lr_rsc_det IN lcu_rsc_det (p_resource_id => p_created_by)
    LOOP
        ln_creator_resource_id                         := lr_rsc_det.resource_id;
        lr_created_det(ln_creator_idx).resource_id     := lr_rsc_det.resource_id;
        lr_created_det(ln_creator_idx).resource_number := lr_rsc_det.resource_number;
        lr_created_det(ln_creator_idx).resource_name   := lr_rsc_det.source_name;
        lc_cr_resource_name                            := lr_rsc_det.source_name;

    END LOOP;

    WRITE_LOG('');
    WRITE_LOG(  RPAD('Office DEPOT',40,' ')
                ||LPAD('DATE: ',90,' ')
                ||TO_DATE(SYSDATE,'DD-MON-YYYY HH:MI'));
    WRITE_LOG('');
    WRITE_LOG(LPAD('OD: SFA Assignment Simulation Report', 90,' '));
    WRITE_LOG('');
    WRITE_LOG('Parameter List');
    WRITE_LOG('--------------');
    WRITE_LOG('');
    WRITE_LOG('Mode of RUN :'       || p_run_mode);
    WRITE_LOG('Created By :'        || lc_cr_resource_name);
    WRITE_LOG('Customer/Prospect :' || p_cust_prospect);
    WRITE_LOG('Country Code :'      || p_cnty_code);
    WRITE_LOG('Postal Code :'       || p_postal_code);
    WRITE_LOG('WCW Count :'         || p_wcw_count);
    WRITE_LOG('SIC Code :'          || p_sic_code);
    WRITE_LOG(' ');
    WRITE_LOG(' ');
    WRITE_LOG('Log Details ');
    WRITE_LOG('-------------------');
    WRITE_LOG(' ');

    
    
    WRITE_OUT('');
    WRITE_OUT(  RPAD('Office DEPOT',40,' ')
                     ||LPAD('DATE: ',90,' ')
                     ||TO_DATE(SYSDATE,'DD-MON-YYYY HH:MI'));
    WRITE_OUT('');
    WRITE_OUT(LPAD('OD: SFA Assignment Simulation Report', 90,' '));
    WRITE_OUT('');
    WRITE_OUT('Parameter List');
    WRITE_OUT('--------------');
    WRITE_OUT('');
    WRITE_OUT('Mode of RUN :'       || p_run_mode);
    WRITE_OUT('Created By :'        || lc_cr_resource_name);
    WRITE_OUT('Customer/Prospect :' || p_cust_prospect);
    WRITE_OUT('Country Code :'      || p_cnty_code);
    WRITE_OUT('Postal Code :'       || p_postal_code);
    WRITE_OUT('WCW Count :'         || p_wcw_count);
    WRITE_OUT('SIC Code :'          || p_sic_code);
    WRITE_OUT('');
    
   
    lc_creator_admin_flag   := 'N';
    lc_creator_manager_flag := 'N';
    lc_creator_member_flag  := 'N';
    
    -- Check for the Creator Resource Group
    ln_group_count          := 0;
    
    FOR lr_res_groups IN lcu_res_groups ( p_resource_id => ln_creator_resource_id )
    LOOP
        
        ln_group_count := ln_group_count + 1;
        
    END LOOP;
    
    IF ln_group_count > 1 
    THEN
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0224_MANY_SALES_GROUP');
        FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
        lc_error_message := FND_MESSAGE.GET;
        lc_error_message := REPLACE (lc_error_message,ln_creator_resource_id,lc_cr_resource_name);
        WRITE_LOG(lc_error_message);
        WRITE_LOG('Creator Resource ID: '||ln_creator_resource_id);
        WRITE_LOG(' ');

        RAISE EX_RESOURCE_ERROR;
    
    ELSIF  ln_group_count = 0
    THEN
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0223_NO_SALES_GROUP');
        FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
        lc_error_message := FND_MESSAGE.GET;
        lc_error_message := REPLACE (lc_error_message,ln_creator_resource_id,lc_cr_resource_name);
        WRITE_LOG(lc_error_message);
        WRITE_LOG('Creator Resource ID: '||ln_creator_resource_id);
        WRITE_LOG(' ');

        RAISE EX_RESOURCE_ERROR;
    
    END IF; -- End Of ln_group_count > 1 Sales Group Check
    
    -- Check whether the creator resource is an admin
    ln_admin_count          := NULL;
    
    OPEN  lcu_admin(
                     p_resource_id => ln_creator_resource_id
                   , p_group_id    => ln_creator_group_id
                  );
    FETCH lcu_admin INTO ln_admin_count;
    CLOSE lcu_admin;
    
    IF ln_admin_count = 0 
    THEN
        
        lc_creator_admin_flag := 'N';

        -- As the resource is not an admin
        -- then check whether the resource is a manager
        ln_manager_count      := NULL;
        
        OPEN lcu_manager(
                           p_resource_id => ln_creator_resource_id
                         , p_group_id    => ln_creator_group_id
                        );

        FETCH lcu_manager INTO ln_manager_count;

        CLOSE lcu_manager;

        IF ln_manager_count = 0 
        THEN

            -- The creator resource is a sales-rep
            lc_creator_manager_flag := 'N';

        ELSIF ln_manager_count = 1 
        THEN

            -- The creator resource is a manager
            lc_creator_manager_flag := 'Y';

        ELSE

            -- The resource has more than one manager role
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0226_CR_MGR_MR_THAN_ONE');
            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
            lc_error_message := FND_MESSAGE.GET;
            lc_error_message := REPLACE (lc_error_message,ln_creator_resource_id,lc_cr_resource_name);
            WRITE_LOG(lc_error_message);
            WRITE_LOG('Creator Resource ID: '||ln_creator_resource_id);
            WRITE_LOG(' ');

            RAISE EX_RESOURCE_ERROR;

        END IF; -- ln_manager_count = 0
    
    ELSIF ln_admin_count = 1 THEN
        
        -- The creator resource is an admin
        lc_creator_admin_flag := 'Y';
    
    ELSE
    
       -- The resource has more than one admin role
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0225_ADM_MORE_THAN_ONE');
       FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
       lc_error_message := FND_MESSAGE.GET;
       lc_error_message := REPLACE (lc_error_message,ln_creator_resource_id,lc_cr_resource_name);
       WRITE_LOG(lc_error_message);
       WRITE_LOG('Creator Resource ID: '||ln_creator_resource_id);
       WRITE_LOG(' ');

       RAISE EX_RESOURCE_ERROR;
    
    END IF ; -- ln_admin_count = 0
   
    lr_created_det(ln_creator_idx).admin_flag       := lc_creator_admin_flag;
    lr_created_det(ln_creator_idx).manager_flag     := lc_creator_manager_flag;
   
    -- check for the member flag
         
    IF lc_creator_admin_flag = 'N' AND lc_creator_manager_flag = 'N'
    THEN
       lc_creator_member_flag := 'Y';
    ELSE    
       lc_creator_member_flag := 'N';
    END IF;
       
    lr_created_det(ln_creator_idx).member_flag     := lc_creator_member_flag;
    
        
    -- Derive the role_id , group_id and role_division of creator resource

    BEGIN
        
        lc_creator_group_name    := NULL;
        lc_creator_role_division := NULL;
        
        SELECT  JRR_CR.role_id
               ,ROL_CR.attribute15
               ,MEM_CR.group_id
               ,GRP_CR.group_name
        INTO    ln_creator_role_id
               ,lc_creator_role_division
               ,ln_creator_group_id
               ,lc_creator_group_name
        FROM    jtf_rs_group_members       MEM_CR
               ,jtf_rs_role_relations      JRR_CR
               ,jtf_rs_group_usages        JRU_CR
               ,jtf_rs_roles_b             ROL_CR
               ,jtf_rs_groups_tl           GRP_CR
        WHERE  MEM_CR.resource_id          = ln_creator_resource_id
        AND    NVL(MEM_CR.delete_flag,'N') <> 'Y'
        AND    JRU_CR.group_id             = MEM_CR.group_id
        AND    MEM_CR.group_id             = GRP_CR.group_id 
        AND    JRU_CR.USAGE                = 'SALES'
        AND    JRR_CR.role_resource_id     = MEM_CR.group_member_id
        AND    JRR_CR.role_resource_type   = 'RS_GROUP_MEMBER'
        AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR_CR.start_date_active)
                              AND NVL(TRUNC(JRR_CR.end_date_active),TRUNC(SYSDATE))
        AND    NVL(JRR_CR.delete_flag,'N') <> 'Y'
        AND    ROL_CR.role_id              = JRR_CR.role_id
        AND    ROL_CR.role_type_code       = 'SALES'
        AND    ROL_CR.active_flag          = 'Y'
        AND    (CASE lc_creator_admin_flag
                     WHEN 'Y' THEN ROL_CR.admin_flag
                     ELSE 'N'
                             END) = (CASE lc_creator_admin_flag
                                          WHEN 'Y' THEN 'Y'
                                          ELSE 'N'
                                                  END)
        AND    (CASE lc_creator_manager_flag
                     WHEN 'Y' THEN ROL_CR.attribute14
                     ELSE 'N'
                             END) = (CASE lc_creator_manager_flag
                                          WHEN 'Y' THEN 'HSE'
                                          ELSE 'N'
                                                  END);
                                                  
                                                     
        lr_created_det(ln_creator_idx).group_name     := lc_creator_group_name;
        lr_created_det(ln_creator_idx).division       := lc_creator_role_division;

    EXCEPTION
    
        WHEN NO_DATA_FOUND 
        THEN
            IF lc_creator_manager_flag = 'Y' 
            THEN
                FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0227_CR_MGR_NO_HSE_ROLE');
                FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
                lc_error_message := FND_MESSAGE.GET;
                lc_error_message := REPLACE (lc_error_message,ln_creator_resource_id,lc_cr_resource_name);
                WRITE_LOG(lc_error_message);
                WRITE_LOG('Creator Resource ID: '||ln_creator_resource_id);
                WRITE_LOG(' ');

            ELSE
                FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0160_CR_NO_SALES_ROLE');
                FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
                lc_error_message := FND_MESSAGE.GET;
                lc_error_message := REPLACE (lc_error_message,ln_creator_resource_id,lc_cr_resource_name);
                WRITE_LOG(lc_error_message);
                WRITE_LOG('Creator Resource ID: '||ln_creator_resource_id);
                WRITE_LOG(' ');

            END IF;
          
            RAISE EX_RESOURCE_ERROR;
          
        WHEN TOO_MANY_ROWS 
        THEN
            IF lc_creator_manager_flag = 'Y' 
            THEN

                FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0228_CR_MGR_HSE_ROLE');
                FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
                lc_error_message := FND_MESSAGE.GET;
                lc_error_message := REPLACE (lc_error_message,ln_creator_resource_id,lc_cr_resource_name);
                WRITE_LOG(lc_error_message);
                WRITE_LOG('Creator Resource ID: '||ln_creator_resource_id);
                WRITE_LOG(' ');


            ELSE
                FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0118_CR_MANY_SALES_ROLE');
                FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
                lc_error_message := FND_MESSAGE.GET;
                lc_error_message := REPLACE (lc_error_message,ln_creator_resource_id,lc_cr_resource_name);
                WRITE_LOG(lc_error_message);
                WRITE_LOG('Creator Resource ID: '||ln_creator_resource_id);
                WRITE_LOG(' ');

            END IF;

            RAISE EX_RESOURCE_ERROR;
          
        WHEN OTHERS 
        THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
            lc_set_message     :=  'Unexpected Error while deriving role_id and role_division of the creator';
            FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
            FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
            FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
            lc_error_message := FND_MESSAGE.GET;
            lc_error_message := REPLACE (lc_error_message,ln_creator_resource_id,lc_cr_resource_name);
            WRITE_LOG(lc_error_message);
            WRITE_LOG('Creator Resource ID: '||ln_creator_resource_id);
            WRITE_LOG(' ');

            RAISE EX_RESOURCE_ERROR;
    END;
    
    -- If Creator is not a manager and admin

    IF (lc_creator_admin_flag <> 'Y' AND lc_creator_manager_flag <> 'Y') 
    THEN

        -- Derive the manager resource_id, resource_name of the creator

        BEGIN

            SELECT  MEM_MGR.resource_id
                   ,MGR_CR.source_name
            INTO    ln_creator_manager_id
                   ,lc_creator_manager_name
            FROM    jtf_rs_group_members    MEM_CR
                   ,jtf_rs_role_relations   JRR_CR
                   ,jtf_rs_roles_b          ROL_CR
                   ,jtf_rs_group_usages     JRU
                   ,jtf_rs_group_members    MEM_MGR
                   ,jtf_rs_role_relations   JRR_MGR
                   ,jtf_rs_roles_b          ROL_MGR
                   ,jtf_rs_resource_extns   MGR_CR
            WHERE  MEM_CR.resource_id          = ln_creator_resource_id
            AND    MGR_CR.resource_id          = MEM_MGR.resource_id
            AND    NVL(MEM_CR.delete_flag,'N') <> 'Y'
            AND    JRU.group_id                = MEM_CR.group_id
            AND    JRU.USAGE                   = 'SALES'
            AND    JRR_CR.role_resource_id     = MEM_CR.group_member_id
            AND    JRR_CR.role_resource_type   = 'RS_GROUP_MEMBER'
            AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR_CR.start_date_active)
                                 AND NVL(TRUNC(JRR_CR.end_date_active),TRUNC(SYSDATE))
            AND    NVL(JRR_CR.delete_flag,'N') <> 'Y'
            AND    ROL_CR.role_id              = JRR_CR.role_id
            AND    ROL_CR.role_type_code       = 'SALES'
            AND    ROL_CR.active_flag          = 'Y'
            AND    MEM_MGR.group_id            = MEM_CR.group_id
            AND    NVL(MEM_MGR.delete_flag,'N') <> 'Y'
            AND    JRU.group_id                = MEM_MGR.group_id
            AND    JRU.USAGE                   = 'SALES'
            AND    JRR_MGR.role_resource_id    = MEM_MGR.group_member_id
            AND    JRR_MGR.role_resource_type  = 'RS_GROUP_MEMBER'
            AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR_MGR.start_date_active)
                                 AND NVL(TRUNC(JRR_MGR.end_date_active),TRUNC(SYSDATE))
            AND    NVL(JRR_MGR.delete_flag,'N') <> 'Y'
            AND    ROL_MGR.role_id              = JRR_MGR.role_id
            AND    ROL_MGR.role_type_code       = 'SALES'
            AND    ROL_MGR.active_flag          = 'Y'
            AND    ROL_MGR.manager_flag         = 'Y'
            AND    ROL_CR.role_id               = ln_creator_role_id;

            lr_created_det(ln_creator_idx).manager_name     := lc_creator_manager_name;
                  
     
        EXCEPTION
            WHEN NO_DATA_FOUND 
            THEN
                FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0119_CR_NO_MANAGER');
                FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
                lc_error_message := FND_MESSAGE.GET;
                lc_error_message := REPLACE (lc_error_message,ln_creator_resource_id,lc_cr_resource_name);
                WRITE_LOG(lc_error_message);
                WRITE_LOG('Creator Resource ID: '||ln_creator_resource_id);
                WRITE_LOG(' ');

                RAISE EX_RESOURCE_ERROR;
            
            WHEN TOO_MANY_ROWS 
            THEN
                FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0120_CR_MANY_MANAGERS');
                FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
                lc_error_message := FND_MESSAGE.GET;
                lc_error_message := REPLACE (lc_error_message,ln_creator_resource_id,lc_cr_resource_name);
                WRITE_LOG(lc_error_message);
                WRITE_LOG('Creator Resource ID: '||ln_creator_resource_id);
                WRITE_LOG(' ');
            
                RAISE EX_RESOURCE_ERROR;
            
            WHEN OTHERS 
            THEN
                FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                lc_set_message     :=  'Unexpected Error while deriving manager_id of the creator.';
                FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                lc_error_message := FND_MESSAGE.GET;
                WRITE_LOG(lc_error_message);
                WRITE_LOG(' ');
            
                RAISE EX_RESOURCE_ERROR;
        END;
        
    ELSE
        
        ln_count  := 0;
        
        FOR lr_sup IN lcu_sup (p_group_id => ln_creator_group_id)
        LOOP
           
            lr_created_det(ln_creator_idx).manager_name     := lr_sup.resource_name;
            
            ln_count := ln_count + 1;
        
        END LOOP;
        
        lc_error_message := NULL;
        IF ln_count > 1
        THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0120_CR_MANY_MANAGERS');
            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
            lc_error_message := FND_MESSAGE.GET;
            lc_error_message := REPLACE (lc_error_message,ln_creator_resource_id,lc_cr_resource_name);
            WRITE_LOG(lc_error_message);
            WRITE_LOG('Creator Resource ID: '||ln_creator_resource_id);
            WRITE_LOG(' ');
                        
           RAISE EX_RESOURCE_ERROR;
        
        END IF;

    END IF; -- End of (lc_creator_admin_flag <> 'Y' AND lc_creator_manager_flag <> 'Y') check
    
    
    -- -----------------------------------------
    -- Calling the custom get winner procedure
    -- -----------------------------------------
    
    -- Extend Qualifier Elements
    
    lp_gen_bulk_rec.squal_char06.EXTEND;
    lp_gen_bulk_rec.squal_char07.EXTEND;
    lp_gen_bulk_rec.squal_char59.EXTEND;
    lp_gen_bulk_rec.squal_char60.EXTEND;
    lp_gen_bulk_rec.squal_num60.EXTEND;

    lp_gen_bulk_rec.squal_char06(1) := p_postal_code;
    lp_gen_bulk_rec.squal_char07(1) := p_cnty_code;
    lp_gen_bulk_rec.squal_char59(1) := p_sic_code;
    lp_gen_bulk_rec.squal_char60(1) := p_cust_prospect;
    lp_gen_bulk_rec.squal_num60(1)  := p_wcw_count;
  
    -- Call to XX_TM_GET_WINNERS_ON_QUALS.get_winners
 
    XX_TM_GET_WINNERS_ON_QUALS.get_winners(  p_api_version_number  => ln_api_version
                                           , p_init_msg_list       => FND_API.G_FALSE
                                           , p_use_type            => 'LOOKUP'
                                           , p_source_id           => -1001
                                           , p_trans_id            => -1002
                                           , p_trans_rec           => lp_gen_bulk_rec
                                           , p_resource_type       => FND_API.G_MISS_CHAR
                                           , p_role                => FND_API.G_MISS_CHAR
                                           , p_top_level_terr_id   => FND_API.G_MISS_NUM
                                           , p_num_winners         => FND_API.G_MISS_NUM
                                           , x_return_status       => lc_return_status
                                           , x_msg_count           => ln_msg_count
                                           , x_msg_data            => lc_msg_data
                                           , x_winners_rec         => lr_gen_return_rec
                                         );
 
    IF lc_return_status <> FND_API.G_RET_STS_SUCCESS 
    THEN
        FOR idx IN 1 .. ln_msg_count
        LOOP
           
           lc_msg_data := FND_MSG_PUB.GET(
                                             p_encoded     => FND_API.G_FALSE
                                           , p_msg_index   => idx
                                         );           
           WRITE_LOG('Error :'||lc_msg_data);
           WRITE_LOG(' ');
        END LOOP;
        
        RAISE EX_RESOURCE_ERROR;
    ELSE
        -- For each resource returned from XX_TM_GET_WINNERS_ON_QUALS.get_winners

        lr_winner_det.DELETE;
        lr_assignee_det.DELETE;
        lr_winner_det   := lr_null_rec;
        lr_assignee_det := lr_null_rec;

        l_counter       := lr_gen_return_rec.resource_id.FIRST;
       
        IF NVL(l_counter,0) = 0 
        THEN
          
            WRITE_LOG('No Resources Returned From GET_WINNERS Procedure');
            WRITE_LOG(' ');
            RAISE EX_RESOURCE_ERROR;
       
        ELSE
         
            WHILE (l_counter <= lr_gen_return_rec.terr_id.LAST)
            LOOP
         
                BEGIN 
            
                    -- Initialize the variables
                    ln_salesforce_id          := NULL;
                    ln_sales_group_id         := NULL;
                    lc_role                   := NULL;

                    -- Fetch the assignee resource_id, sales_group_id and full_access_flag
                    ln_salesforce_id    := lr_gen_return_rec.resource_id(l_counter);
                    ln_sales_group_id   := lr_gen_return_rec.group_id(l_counter);
                    lc_role             := lr_gen_return_rec.role(l_counter);
                    
                    WRITE_LOG(' ');
                    WRITE_LOG('Record Number :'||l_counter);
                    WRITE_LOG(' ');
                    WRITE_LOG('Sales Force ID: '|| ln_salesforce_id );
                    WRITE_LOG('Sales Group ID: '|| ln_sales_group_id);
                    WRITE_LOG('Sales Role ID: ' || lc_role);
                    WRITE_LOG(' ');
                    
                    ----
                    -- Deriving the details of the winning resource
                    ----
                    lc_assignee_admin_flag   := 'N';
                    lc_assignee_manager_flag := 'N';
                    lc_asgn_resource_name    := NULL;

                    FOR lr_rsc_det IN lcu_rsc_det (p_resource_id => ln_salesforce_id )
                    LOOP
                
                        lr_winner_det(l_counter).resource_id     := lr_rsc_det.resource_id;
                        lr_winner_det(l_counter).resource_number := lr_rsc_det.resource_number;
                        lr_winner_det(l_counter).resource_name   := lr_rsc_det.source_name;
                        lc_asgn_resource_name                    := lr_rsc_det.source_name;

                    END LOOP;
                    
                    lr_winner_det(l_counter).manager_name := lr_gen_return_rec.resource_mgr_name(l_counter);
                    
                    -- Check for the Assignee Resource Group
                    ln_group_count          := 0;

                    FOR lr_res_groups IN lcu_res_groups ( p_resource_id => ln_salesforce_id )
                    LOOP

                        ln_group_count := ln_group_count + 1;

                    END LOOP;

                    IF ln_group_count > 1 
                    THEN
                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0216_MANY_SALES_GROUP');
                        FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                        lc_error_message := FND_MESSAGE.GET;
                        lc_error_message := REPLACE (lc_error_message,ln_salesforce_id,lc_asgn_resource_name);
                        WRITE_LOG(lc_error_message);
                        WRITE_LOG('Assignee Resource ID: '||ln_salesforce_id);
                        WRITE_LOG(' ');

                        RAISE EX_CREATE_ERR;

                    ELSIF  ln_group_count = 0
                    THEN
                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0215_NO_SALES_GROUP');
                        FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                        lc_error_message := FND_MESSAGE.GET;
                        lc_error_message := REPLACE (lc_error_message,ln_salesforce_id,lc_asgn_resource_name);
                        WRITE_LOG(lc_error_message);
                        WRITE_LOG('Assignee Resource ID: '||ln_salesforce_id);
                        WRITE_LOG(' ');

                        RAISE EX_CREATE_ERR;

                    END IF; -- End Of ln_group_count > 1 Sales Group Check
                    

                    -- Check whether the assignee resource is an admin
                    ln_admin_count := NULL;
             
                    OPEN  lcu_admin(
                                     p_resource_id => ln_salesforce_id
                                    ,p_group_id    => ln_sales_group_id
                                   );
                    FETCH lcu_admin INTO ln_admin_count;
                    CLOSE lcu_admin;

                    IF ln_admin_count = 0 
                    THEN

                        lc_assignee_admin_flag := 'N';

                        -- Check whether the assignee resource is a manager
                        ln_manager_count := NULL;
                
                        OPEN lcu_manager(
                                           p_resource_id => ln_salesforce_id
                                         , p_group_id    => ln_sales_group_id
                                        );
                        FETCH lcu_manager INTO ln_manager_count;
                        CLOSE lcu_manager;

                        IF (ln_manager_count = 0) 
                        THEN

                            -- This means the assignee resource is a sales-rep
                            lc_assignee_manager_flag := 'N';

                        ELSIF ln_manager_count = 1 
                        THEN

                            -- This means the assignee resource is a manager
                            lc_assignee_manager_flag := 'Y';

                        ELSE

                            -- The assignee resource is a manger of more than one group
                            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0219_MGR_MORE_THAN_ONE');
                            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                            lc_error_message := REPLACE (lc_error_message,ln_salesforce_id,lc_asgn_resource_name);
                            WRITE_LOG(lc_error_message);
                            WRITE_LOG('Assignee Resource ID: '||ln_salesforce_id);
                            WRITE_LOG(' ');
                    
                            RAISE EX_CREATE_ERR;

                        END IF; -- ln_manager_count = 0

                    ELSIF ln_admin_count = 1 
                    THEN

                        lc_assignee_admin_flag := 'Y';

                    ELSE

                        -- The assignee resource has more than one admin role
                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0243_ADM_MORE_THAN_ONE');
                        FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                        lc_error_message := REPLACE (lc_error_message,ln_salesforce_id,lc_asgn_resource_name);
                        WRITE_LOG(lc_error_message);
                        WRITE_LOG('Assignee Resource ID: '||ln_salesforce_id);
                        WRITE_LOG(' ');
                 
                        RAISE EX_CREATE_ERR;

                    END IF ; -- ln_admin_count = 0
             
                    lr_winner_det(l_counter).admin_flag     := lc_assignee_admin_flag;
                    lr_winner_det(l_counter).manager_flag   := lc_assignee_manager_flag;
             
                    -- check for the member flag
                    lc_assignee_member_flag := 'N';
                    
                    IF lc_assignee_admin_flag = 'N' AND lc_assignee_manager_flag = 'N'
                    THEN
                        lc_assignee_member_flag := 'Y';
                    ELSE    
                        lc_assignee_member_flag := 'N';
                    END IF;

                        
                    lr_winner_det(l_counter).member_flag   := lc_assignee_member_flag;

                    
                    -- Deriving the group id of the resource if ln_sales_group_id IS NULL

                    IF (ln_sales_group_id IS NULL) 
                    THEN

                        IF lc_assignee_admin_flag = 'Y' 
                        THEN

                            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0244_ADM_GRP_MANDATORY');
                            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                            lc_error_message := REPLACE (lc_error_message,ln_salesforce_id,lc_asgn_resource_name);
                            WRITE_LOG(lc_error_message);
                            WRITE_LOG('Assignee Resource ID: '||ln_salesforce_id);
                            WRITE_LOG(' ');
  
                            RAISE EX_CREATE_ERR;

                        END IF; -- lc_assignee_admin_flag = 'Y'

                    END IF; -- ln_sales_group_id IS NULL

                    -- Deriving the role of the resource if lc_role IS NULL

                    IF (lc_role IS NULL ) 
                    THEN

                        IF lc_assignee_admin_flag = 'Y' 
                        THEN

                            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0245_ADM_ROLE_MANDATORY');
                            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                            lc_error_message := REPLACE (lc_error_message,ln_salesforce_id,lc_asgn_resource_name);
                            WRITE_LOG(lc_error_message);
                            WRITE_LOG('Assignee Resource ID: '||ln_salesforce_id);
                            WRITE_LOG(' ');

                            RAISE EX_CREATE_ERR;

                        END IF; -- lc_assignee_admin_flag = 'Y'

                        -- Derive the role_id group_id and role_division of assignee resource
                        -- with the resource_id and group_id derived

                        BEGIN

                            lc_assignee_group_name    := NULL;
                            lc_assignee_role_division := NULL;
                            ln_assignee_role_id       := NULL;
                
                            SELECT  JRR_ASG.role_id
                                   ,ROL_ASG.attribute15
                                   ,MEM_ASG.group_id
                                   ,GRP_ASG.group_name
                            INTO    ln_assignee_role_id
                                   ,lc_assignee_role_division
                                   ,ln_sales_group_id
                                   ,lc_assignee_group_name
                            FROM    jtf_rs_group_members      MEM_ASG
                                   ,jtf_rs_role_relations     JRR_ASG
                                   ,jtf_rs_group_usages       JRU_ASG
                                   ,jtf_rs_roles_b            ROL_ASG
                                   ,jtf_rs_groups_tl          GRP_ASG
                            WHERE  MEM_ASG.resource_id      = ln_salesforce_id
                            AND    NVL(MEM_ASG.delete_flag,'N') <> 'Y'
                            AND    MEM_ASG.group_id         = NVL(ln_sales_group_id,MEM_ASG.group_id)
                            AND    JRU_ASG.group_id         = MEM_ASG.group_id
                            AND    MEM_ASG.group_id         = GRP_ASG.group_id
                            AND    JRU_ASG.USAGE            = 'SALES'
                            AND    JRR_ASG.role_resource_id = MEM_ASG.group_member_id
                            AND    JRR_ASG.role_resource_type  = 'RS_GROUP_MEMBER'
                            AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR_ASG.start_date_active)
                                     AND NVL(TRUNC(JRR_ASG.end_date_active),TRUNC(SYSDATE))
                            AND    NVL(JRR_ASG.delete_flag,'N') <> 'Y'
                            AND    ROL_ASG.role_id         = JRR_ASG.role_id
                            AND    ROL_ASG.role_type_code  = 'SALES'
                            AND    ROL_ASG.active_flag     = 'Y'
                            AND    (CASE lc_assignee_manager_flag
                                         WHEN 'Y' THEN ROL_ASG.attribute14
                                         ELSE 'N'
                                                 END) = (CASE lc_assignee_manager_flag
                                                              WHEN 'Y' THEN 'HSE'
                                                              ELSE 'N'
                                                                      END);

                            lr_winner_det(l_counter).group_name     := lc_assignee_group_name;
                            lr_winner_det(l_counter).division       := lc_assignee_role_division;
                     

                        EXCEPTION
                            WHEN NO_DATA_FOUND 
                            THEN
                                IF lc_assignee_manager_flag = 'Y' 
                                THEN
                                    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0229_AS_MGR_NO_HSE_ROLE');
                                    FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                    lc_error_message := REPLACE (lc_error_message,ln_salesforce_id,lc_asgn_resource_name);
                                    WRITE_LOG(lc_error_message);
                                    WRITE_LOG('Assignee Resource ID: '||ln_salesforce_id);
                                    WRITE_LOG(' ');
                        
                                ELSE
                                    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0122_AS_NO_SALES_ROLE');
                                    FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                    lc_error_message := REPLACE (lc_error_message,ln_salesforce_id,lc_asgn_resource_name);
                                    WRITE_LOG(lc_error_message);
                                    WRITE_LOG('Assignee Resource ID: '||ln_salesforce_id);
                                    WRITE_LOG(' ');
                          
                                END IF;

                                RAISE EX_CREATE_ERR;
                      
                            WHEN TOO_MANY_ROWS 
                            THEN
                                IF lc_assignee_manager_flag = 'Y' 
                                THEN
                                    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0230_AS_MGR_HSE_ROLE');
                                    FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                    lc_error_message := REPLACE (lc_error_message,ln_salesforce_id,lc_asgn_resource_name);
                                    WRITE_LOG(lc_error_message);
                                    WRITE_LOG('Assignee Resource ID: '||ln_salesforce_id);
                                    WRITE_LOG(' ');
                       
                                ELSE
                                    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0123_AS_MANY_SALES_ROLE');
                                    FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                    lc_error_message := REPLACE (lc_error_message,ln_salesforce_id,lc_asgn_resource_name);
                                    WRITE_LOG(lc_error_message);
                                    WRITE_LOG('Assignee Resource ID: '||ln_salesforce_id);
                                    WRITE_LOG(' ');
                          
                                END IF;

                                RAISE EX_CREATE_ERR;
                      
                            WHEN OTHERS 
                            THEN
                                FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                                lc_set_message     :=  'Unexpected Error while deriving role_id and role_division of the assignee.';
                                FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                                FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                                FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                                lc_error_message := FND_MESSAGE.GET;
                                WRITE_LOG(lc_error_message);
                                WRITE_LOG(' ');
                                RAISE EX_CREATE_ERR;

                        END; -- end of role_id ,division 

                    ELSE

                        -- Derive the role_id and role_division of assignee resource
                        -- with the resource_id, group_id and role_code returned
                        -- from get_winners

                        BEGIN
                            lc_assignee_group_name    := NULL;
                            lc_assignee_role_division := NULL;
                            ln_assignee_role_id       := NULL;

                            SELECT  JRR_ASG.role_id
                                   ,ROL_ASG.attribute15
                                   ,MEM_ASG.group_id
                                   ,GRP_ASG.group_name
                            INTO    ln_assignee_role_id
                                   ,lc_assignee_role_division
                                   ,ln_sales_group_id
                                   ,lc_assignee_group_name
                            FROM    jtf_rs_group_members      MEM_ASG
                                   ,jtf_rs_role_relations     JRR_ASG
                                   ,jtf_rs_group_usages       JRU_ASG
                                   ,jtf_rs_roles_b            ROL_ASG
                                   ,jtf_rs_groups_tl          GRP_ASG
                            WHERE  MEM_ASG.resource_id         = ln_salesforce_id
                            AND    MEM_ASG.group_id            = NVL(ln_sales_group_id,MEM_ASG.group_id)
                            AND    NVL(MEM_ASG.delete_flag,'N') <> 'Y'
                            AND    JRU_ASG.group_id            = MEM_ASG.group_id
                            AND    GRP_ASG.group_id            = MEM_ASG.group_id
                            AND    JRU_ASG.USAGE               = 'SALES'
                            AND    JRR_ASG.role_resource_id    = MEM_ASG.group_member_id
                            AND    JRR_ASG.role_resource_type  = 'RS_GROUP_MEMBER'
                            AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR_ASG.start_date_active)
                                                  AND NVL(TRUNC(JRR_ASG.end_date_active),TRUNC(SYSDATE))
                            AND    NVL(JRR_ASG.delete_flag,'N') <> 'Y'
                            AND    ROL_ASG.role_id         = JRR_ASG.role_id
                            AND    ROL_ASG.role_code       = lc_role
                            AND    ROL_ASG.role_type_code  = 'SALES'
                            AND    ROL_ASG.active_flag     = 'Y';

                            lr_winner_det(l_counter).group_name     := lc_assignee_group_name;
                            lr_winner_det(l_counter).division       := lc_assignee_role_division;


                        EXCEPTION
                            WHEN NO_DATA_FOUND 
                            THEN
                                FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0218_NO_SALES_ROLE');
                                FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                FND_MESSAGE.SET_TOKEN('P_ROLE_CODE', lc_role);
                                FND_MESSAGE.SET_TOKEN('P_GROUP_ID', ln_sales_group_id);
                                lc_error_message := FND_MESSAGE.GET;
                                lc_error_message := REPLACE (lc_error_message,ln_salesforce_id,lc_asgn_resource_name);
                                WRITE_LOG(lc_error_message);
                                WRITE_LOG('Assignee Resource ID: '||ln_salesforce_id);
                                RAISE EX_CREATE_ERR;
                        
                            WHEN OTHERS 
                            THEN
                                FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                                lc_set_message     :=  'Unexpected Error while deriving role_id and role_division of the assignee with the role_code';
                                FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                                FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                                FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                                lc_error_message := FND_MESSAGE.GET;
                                WRITE_LOG(lc_error_message);
                                WRITE_LOG(' ');

                                RAISE EX_CREATE_ERR;
                                
                        END; -- End of role id derivation with role code

                    END IF; -- lc_role IS NULL

                    IF (lc_creator_admin_flag = 'Y' 
                        OR lc_creator_manager_flag = 'Y'
                            OR lc_assignee_admin_flag = 'Y')
                    THEN
                
                        lr_assignee_det(l_counter) := lr_winner_det(l_counter);
               

                    ELSE

                        -- Compare the division of assignee and creator resource

                        IF lc_assignee_role_division = lc_creator_role_division 
                        THEN

                            -- If the resource returned is a manager

                            IF lc_assignee_manager_flag = 'Y' 
                            THEN

                                -- Check whether the creator and the assignee belong to the same group

                                IF ln_creator_group_id <> ln_sales_group_id 
                                THEN

                                    -- This means that the manager and the creator belong to seperate group
                                    -- So assign it to the manager
                                    lr_assignee_det(l_counter) := lr_winner_det(l_counter);


                                ELSE

                                    -- This means that the manager and the creator belong to the same group
                                    -- So assign it to the creator

                                    lr_assignee_det(l_counter) := lr_created_det(ln_creator_idx);

                                END IF; -- ln_creator_group_id <> ln_sales_group_id

                            ELSE

                                -- Derive the manager of the asignee
                                lc_assignee_manager_name  := NULL;
                                ln_assignee_manager_id    := NULL;
                       
                                BEGIN
                          
                                    SELECT   MEM_MGR.resource_id
                                            ,MGR_ASG.source_name 
                                    INTO     ln_assignee_manager_id
                                            ,lc_assignee_manager_name
                                    FROM     jtf_rs_group_members       MEM_ASG
                                           , jtf_rs_role_relations      JRR_ASG
                                           , jtf_rs_roles_b             ROL_ASG
                                           , jtf_rs_group_usages        JRU
                                           , jtf_rs_group_members       MEM_MGR
                                           , jtf_rs_role_relations      JRR_MGR
                                           , jtf_rs_roles_b             ROL_MGR
                                           ,jtf_rs_resource_extns       MGR_ASG
                                    WHERE  MEM_ASG.resource_id          = ln_salesforce_id
                                    AND    MGR_ASG.resource_id          = MEM_MGR.resource_id
                                    AND    NVL(MEM_ASG.delete_flag,'N') <> 'Y'
                                    AND    JRU.group_id                 = MEM_ASG.group_id
                                    AND    JRU.USAGE                    = 'SALES'
                                    AND    JRR_ASG.role_resource_id     = MEM_ASG.group_member_id
                                    AND    JRR_ASG.role_resource_type   = 'RS_GROUP_MEMBER'
                                    AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR_ASG.start_date_active)
                                                          AND NVL(TRUNC(JRR_ASG.end_date_active),TRUNC(SYSDATE))
                                    AND    NVL(JRR_ASG.delete_flag,'N') <> 'Y'
                                    AND    ROL_ASG.role_id              = JRR_ASG.role_id
                                    AND    ROL_ASG.role_type_code       = 'SALES'
                                    AND    ROL_ASG.active_flag          = 'Y'
                                    AND    MEM_MGR.group_id             = MEM_ASG.group_id
                                    AND    NVL(MEM_MGR.delete_flag,'N') <> 'Y'
                                    AND    JRU.group_id                 = MEM_MGR.group_id
                                    AND    JRU.USAGE                    = 'SALES'
                                    AND    JRR_MGR.role_resource_id     = MEM_MGR.group_member_id
                                    AND    JRR_MGR.role_resource_type   = 'RS_GROUP_MEMBER'
                                    AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR_MGR.start_date_active)
                                                          AND NVL(TRUNC(JRR_MGR.end_date_active),TRUNC(SYSDATE))
                                    AND    NVL(JRR_MGR.delete_flag,'N') <> 'Y'
                                    AND    ROL_MGR.role_id               = JRR_MGR.role_id
                                    AND    ROL_MGR.role_type_code        = 'SALES'
                                    AND    ROL_MGR.active_flag           = 'Y'
                                    AND    ROL_MGR.manager_flag          = 'Y'
                                    AND    ROL_ASG.role_id               = ln_assignee_role_id;

                                    lr_winner_det(l_counter).manager_name     := lc_assignee_manager_name;


                                EXCEPTION
                                    WHEN NO_DATA_FOUND 
                                    THEN
                                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0127_AS_NO_MANAGER');
                                        FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                        lc_error_message := FND_MESSAGE.GET;
                                        lc_error_message := REPLACE (lc_error_message,ln_salesforce_id,lc_asgn_resource_name);
                                        WRITE_LOG(lc_error_message);
                                        WRITE_LOG('Assignee Resource ID: '||ln_salesforce_id);
                                        RAISE EX_CREATE_ERR;
                              
                                    WHEN TOO_MANY_ROWS 
                                    THEN
                                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0128_AS_MANY_MANAGERS');
                                        FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                        lc_error_message := FND_MESSAGE.GET;
                                        lc_error_message := REPLACE (lc_error_message,ln_salesforce_id,lc_asgn_resource_name);
                                        WRITE_LOG(lc_error_message);
                                        WRITE_LOG('Assignee Resource ID: '||ln_salesforce_id);
                                        RAISE EX_CREATE_ERR;
                              
                                    WHEN OTHERS 
                                    THEN
                                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                                        lc_set_message     :=  'Unexpected Error while deriving manager_id of the assignee';
                                        FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                                        FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                                        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                                        lc_error_message := FND_MESSAGE.GET;
                                        WRITE_LOG(lc_error_message);
                                        WRITE_LOG(' ');

                                        RAISE EX_CREATE_ERR;

                                END; -- End of assignee manager derivation

                                -- Compare the manager of the creator to that of the asignee

                                IF ln_creator_manager_id = ln_assignee_manager_id 
                                THEN

                         
                                    lr_assignee_det(l_counter) := lr_created_det(ln_creator_idx);

                                ELSE

                           
                                    lr_assignee_det(l_counter) := lr_winner_det(l_counter);

                                END IF; -- ln_creator_manager_id = ln_assignee_manager_id

                            END IF; -- lc_assignee_manager_flag = 'Y'

                        ELSE

                            lr_assignee_det(l_counter) := lr_winner_det(l_counter);

                        END IF; -- lc_assignee_role_division = lc_creator_role_division

                    END IF; -- lc_creator_admin_flag = 'Y'
             
                    
       
                EXCEPTION
 
                    WHEN EX_CREATE_ERR 
                    THEN
                        x_retcode := 1;
                        NULL; 
                        
                    WHEN OTHERS 
                    THEN
                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                        lc_set_message     :=  'Unexpected Error while deriving resource details : ';
                        FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                        FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                        lc_error_message := FND_MESSAGE.GET;
                        WRITE_LOG(lc_error_message);
                        WRITE_LOG(' ');
                END;
       
                l_counter   := l_counter + 1;
            
            END LOOP; -- l_counter <= lr_gen_return_rec.terr_id.LAST
          
        END IF; -- End of l_counter check
       
    END IF; -- End of lc_return_status check

    -----------
    -- Reporting the assignment details
    -----------
    -- created by resource details
    WRITE_OUT(' ');
    WRITE_OUT('Created By Resource Details');
    WRITE_OUT('---------------------------');
    WRITE_OUT(' ');
    WRITE_OUT(    RPAD('RESOURCE ID',30,' ')||RPAD('RESOURCE NUMBER',30,' ')||RPAD('RESOURCE NAME',30,' ')
                ||RPAD('GROUP NAME',30,' ') ||RPAD('MANAGER NAME',30,' ')   ||RPAD('MEMBER FLAG',30,' ')
                ||RPAD('ADMIN FLAG',30,' ') ||RPAD('MANAGER FLAG',30,' ')   ||RPAD('DIVISION',30,' ')
             );
    WRITE_OUT(RPAD('-',250,'-'));         
    WRITE_OUT(' ');

    IF lr_created_det.COUNT > 0
    THEN
        WRITE_OUT( RPAD(lr_created_det(ln_creator_idx).resource_id,30,' ')
                || RPAD(lr_created_det(ln_creator_idx).resource_number,30,' ')
                || RPAD(lr_created_det(ln_creator_idx).resource_name,30,' ')
                || RPAD(NVL(lr_created_det(ln_creator_idx).group_name,' '),30,' ')
                || RPAD(NVL(lr_created_det(ln_creator_idx).manager_name,' '),30,' ')
                || RPAD(lr_created_det(ln_creator_idx).member_flag,30,' ')
                || RPAD(lr_created_det(ln_creator_idx).admin_flag,30,' ')
                || RPAD(lr_created_det(ln_creator_idx).manager_flag,30,' ')
                || RPAD(lr_created_det(ln_creator_idx).division,30,' ')
             );

    ELSE
        write_out ('Please refer to concurrent log file for error deatils');
        x_retcode := 1;

    END IF; -- lr_created_det.COUNT > 0

    -- Resource details from Get_winner
    WRITE_OUT(' ');
    WRITE_OUT(' ');
    WRITE_OUT('Get Winner Resource Details');
    WRITE_OUT('----------------------------');
    WRITE_OUT(' ');
    WRITE_OUT(  RPAD('RESOURCE ID',30,' ')||RPAD('RESOURCE NUMBER',30,' ')||RPAD('RESOURCE NAME',30,' ')
                ||RPAD('GROUP NAME',30,' ') ||RPAD('MANAGER NAME',30,' ')   ||RPAD('MEMBER FLAG',30,' ')
             ||RPAD('ADMIN FLAG',30,' ') ||RPAD('MANAGER FLAG',30,' ')   ||RPAD('DIVISION',30,' ')
            );
    WRITE_OUT(RPAD('-',250,'-'));         
    WRITE_OUT(' ');
    IF lr_winner_det.COUNT > 0
    THEN
        FOR idx IN lr_winner_det.FIRST .. lr_winner_det.LAST
        LOOP
            WRITE_OUT (   RPAD(lr_winner_det(idx).resource_id,30,' ')
                        || RPAD(lr_winner_det(idx).resource_number,30,' ')
                        || RPAD(lr_winner_det(idx).resource_name,30,' ')
                        || RPAD(NVL(lr_winner_det(idx).group_name,' '),30,' ')
                        || RPAD(NVL(lr_winner_det(idx).manager_name,' '),30,' ')
                        || RPAD(lr_winner_det(idx).member_flag,30,' ')
                        || RPAD(lr_winner_det(idx).admin_flag,30,' ')
                        || RPAD(lr_winner_det(idx).manager_flag,30,' ')
                        || RPAD(lr_winner_det(idx).division,30,' ')
                    );
        END LOOP;
    ELSE
        WRITE_OUT ('Please refer to concurrent log file for error deatils');
        x_retcode := 1;

    END IF; --lr_winner_det.COUNT > 0


    --Resource Assignment after Autonamed 
    IF p_run_mode ='MANUAL'
    THEN
        WRITE_OUT(' ');
        WRITE_OUT(' ');
        WRITE_OUT('Resource Assignment after Autonamed');
        WRITE_OUT('-----------------------------------');
        WRITE_OUT(' ');
        WRITE_OUT(  RPAD('RESOURCE ID',30,' ')||RPAD('RESOURCE NUMBER',30,' ')||RPAD('RESOURCE NAME',30,' ')
                  ||RPAD('GROUP NAME',30,' ') ||RPAD('MANAGER NAME',30,' ')   ||RPAD('MEMBER FLAG',30,' ')
                  ||RPAD('ADMIN FLAG',30,' ') ||RPAD('MANAGER FLAG',30,' ')   ||RPAD('DIVISION',30,' ')
                 );
        WRITE_OUT(RPAD('-',250,'-'));         
        WRITE_OUT(' ');

        IF lr_assignee_det.COUNT > 0
        THEN
            FOR idx IN lr_assignee_det.FIRST .. lr_assignee_det.LAST
            LOOP
                WRITE_OUT (   RPAD(lr_assignee_det(idx).resource_id,30,' ')
                           || RPAD(lr_assignee_det(idx).resource_number,30,' ')
                           || RPAD(lr_assignee_det(idx).resource_name,30,' ')
                           || RPAD(NVL(lr_assignee_det(idx).group_name,' '),30,' ')
                           || RPAD(NVL(lr_assignee_det(idx).manager_name,' '),30,' ')
                           || RPAD(lr_assignee_det(idx).member_flag,30,' ')
                           || RPAD(lr_assignee_det(idx).admin_flag,30,' ')
                           || RPAD(lr_assignee_det(idx).manager_flag,30,' ')
                           || RPAD(lr_assignee_det(idx).division,30,' ')
                         );
            END LOOP;
        ELSE
           WRITE_OUT ('Please refer to concurrent log file for error deatils');
           WRITE_OUT (' ');
           x_retcode := 1;
        END IF;


    ELSIF p_run_mode ='BATCH'
    THEN
        WRITE_OUT(' ');
        WRITE_OUT(' ');
        WRITE_OUT('Resource Assignment as per Autonaming rules');
        WRITE_OUT('-------------------------------------------');
        WRITE_OUT(' ');
        WRITE_OUT(  RPAD('RESOURCE ID',30,' ')||RPAD('RESOURCE NUMBER',30,' ')||RPAD('RESOURCE NAME',30,' ')
                  ||RPAD('GROUP NAME',30,' ') ||RPAD('MANAGER NAME',30,' ')   ||RPAD('MEMBER FLAG',30,' ')
                  ||RPAD('ADMIN FLAG',30,' ') ||RPAD('MANAGER FLAG',30,' ')   ||RPAD('DIVISION',30,' ')
                 );
        WRITE_OUT(RPAD('-',270,'-'));         
        WRITE_OUT(' ');
        WRITE_OUT('Assignee Resource deatils are same as above (Get Winner Resource Deatils)');
        WRITE_OUT(' ');
    END IF; -- p_run_mode ='MANUAL'  
    
    WRITE_OUT(' ');
    WRITE_OUT(' ');
    WRITE_OUT(' ');
    WRITE_OUT(LPAD('--------------  End of report -----------------',100,' '));
  
EXCEPTION

   WHEN EX_RESOURCE_ERROR 
   THEN
       
        
       WRITE_OUT ('Please refer to concurrent log file for error deatils');
       x_retcode := 1;
       
       IF lcu_admin%ISOPEN
       THEN
       
        CLOSE lcu_admin;
        
       END IF; 
       
       IF lcu_manager%ISOPEN
       THEN
              
           CLOSE lcu_manager;
               
       END IF; 

           
   WHEN OTHERS 
   THEN
   
       IF lcu_admin%ISOPEN
       THEN       
           CLOSE lcu_admin;
       
       END IF; 

       IF lcu_manager%ISOPEN
       THEN
              
           CLOSE lcu_manager;
               
       END IF; 
   
       WRITE_OUT ('Please refer to concurrent log file for error deatils');
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while deriving resource details : ';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       
       lc_error_message := FND_MESSAGE.GET;
       
       WRITE_LOG(lc_error_message);
       
       x_retcode := 2;
       
       

END RSC_ASSIGN_MAIN;


END XX_JTF_RSC_ASGN_SIM_REP;

/
SHOW ERRORS;
EXIT
