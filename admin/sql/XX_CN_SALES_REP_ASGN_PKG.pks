SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_cn_sales_rep_asgn_pkg AUTHID CURRENT_USER

-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                    Oracle NAIO Consulting Organization                   |
-- +==========================================================================+
-- | Name        : XX_CN_SALES_REP_ASGN_PKG.pks                               |
-- | Rice ID     : E1004E_CustomCollections_(SalesRep_Assignment)             |
-- | Description : Custom Package that contains all the utility functions and |
-- |               procedures required to do Sales Rep Assignments.           |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |Draft 1a 11-Oct-2007 Vidhya Valantina T     Initial draft version         |
-- |1.0      23-Oct-2007 Vidhya Valantina T     Baselined after review        |
-- |1.1      05-Nov-2007 Vidhya Valantina T     Changes due to addition of new|
-- |                                            column 'Party_Site_Id' in the |
-- |                                            Extract Tables.               |
-- |1.2      15-Nov-2007 Vidhya Valantina T     Global Cursor Query Changes   |
-- |                                            and New Error Tables Defined  |
-- |                                                                          |
-- +==========================================================================+

AS

-- --------------------------
-- Global Cursor Declarations
-- --------------------------

    -- -------------------------
    -- Sales Reps Details Cursor
    -- -------------------------

    --
    -- Begin of Changes
    --
    -- Changes done by Vidhya Valantina Tamilmani on 05-Nov-2007
    --
    -- Added Party_Site_Id to the Query
    --
    -- Changes done by Vidhya Valantina Tamilmani on 15-Nov-2007
    --
    -- Removed PER_ALL_PEOPLE_F Join from the Query
    -- Added JRS.salesrep_number as Employee Number
    -- Changed the Start Date from Effective Start Date to Job Effective Date on the Assignment DFF
    --
    -- Following Cursor is replaced
    -- Commented by Vidhya Valantina Tamilmani on 15-Nov-2007
    --
/*  CURSOR gcu_sales_rep_details ( p_ship_to_address_id  NUMBER
                                  ,p_party_site_id       NUMBER -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 05-Nov-2007
                                  ,p_rollup_date         DATE
                                  ,p_resource_id         NUMBER
                                  ,p_named_acct_terr_id  NUMBER
                                  ,p_batch_id            NUMBER
                                  ,p_process_audit_id    NUMBER
                                 )
    IS
    SELECT p_ship_to_address_id         ship_to_address_id
          ,p_party_site_id              party_site_id           -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 05-Nov-2007
          ,p_rollup_date                rollup_date
          ,JRR.attribute15              division
          ,p_named_acct_terr_id         named_acct_terr_id
          ,JRGM.resource_id             resource_id
          ,HOU.organization_id          resource_org_id
          ,JRR.attribute15              salesrep_division
          ,JRR.role_id                  resource_role_id
          ,JRGM.group_id                group_id
          ,JRS.salesrep_id              salesrep_id
          ,PAPF.employee_number         employee_number
          ,JRR.attribute14              role_code
          ,JRS.start_date_active        start_date_active
          ,JRS.end_date_active          end_date_active
          ,''                           comments
          ,p_batch_id                   batch_id
          ,p_process_audit_id           process_audit_id
    FROM   jtf_rs_group_members         JRGM
          ,jtf_rs_role_relations        JRRR
          ,jtf_rs_roles_vl              JRR
          ,jtf_rs_resource_extns        JRRE
          ,jtf_rs_salesreps             JRS
          ,hr_organization_units_v      HOU
          ,per_all_assignments_f        PAAF
          ,per_all_people_f             PAPF
    WHERE  JRGM.group_member_id       = JRRR.role_resource_id
    AND    nvl(JRGM.delete_flag,'N') <> 'Y'
    AND    JRRR.role_resource_type    = 'RS_GROUP_MEMBER'
    AND    nvl(JRRR.delete_flag,'N') <> 'Y'
    AND    p_rollup_date             BETWEEN  JRRR.start_date_active
                                     AND NVL( JRRR.end_date_active
                                             ,TO_DATE('12/31/4012','MM/DD/YYYY HH24:MI:SS'))
    AND    JRRR.role_id               = JRR.role_id
    AND    JRR.role_type_code         = 'SALES_COMP'
    AND    JRR.member_flag            = 'Y'
    AND    JRRE.resource_id           = JRGM.resource_id
    AND    JRS.resource_id            = JRGM.resource_id
    AND    p_rollup_date             BETWEEN  JRS.start_date_active
                                     AND NVL( JRS.end_date_active
                                             ,TO_DATE('12/31/4012','MM/DD/YYYY HH24:MI:SS'))
    AND    HOU.organization_id        = JRS.org_id
    AND    HOU.organization_type      = 'Operating Unit'
    AND    HOU.attribute5             = PAAF.ass_attribute1
    AND    JRRE.source_id             = PAAF.person_id
    AND    p_rollup_date             BETWEEN  PAAF.effective_start_date
                                     AND NVL( PAAF.effective_end_date
                                             ,TO_DATE('12/31/4012','MM/DD/YYYY HH24:MI:SS'))
    AND    PAAF.person_id             = PAPF.person_id
    AND    p_rollup_date             BETWEEN  PAPF.effective_start_date
                                     AND NVL( PAPF.effective_end_date
                                             ,TO_DATE('12/31/4012','MM/DD/YYYY HH24:MI:SS'))
    AND    JRGM.resource_id           = p_resource_id;*/
    --
    -- Added Party_Site_Id to the Query
    --
    -- Removed PER_ALL_PEOPLE_F Join from the Query
    -- Added JRS.salesrep_number as Employee Number
    -- Changed the Start Date from Effective Start Date to Job Effective Date on the Assignment DFF
    --
    -- Cursor Modified by Vidhya Valantina Tamilmani on 15-Nov-2007
    --
    CURSOR gcu_sales_rep_details ( p_ship_to_address_id  NUMBER
                                  ,p_party_site_id       NUMBER
                                  ,p_rollup_date         DATE
                                  ,p_resource_id         NUMBER
                                  ,p_named_acct_terr_id  NUMBER
                                  ,p_batch_id            NUMBER
                                  ,p_process_audit_id    NUMBER
                                 )
    IS
    SELECT p_ship_to_address_id         ship_to_address_id
          ,p_party_site_id              party_site_id
          ,p_rollup_date                rollup_date
          ,JRR.attribute15              division
          ,p_named_acct_terr_id         named_acct_terr_id
          ,JRGM.resource_id             resource_id
          ,HOU.organization_id          resource_org_id
          ,JRR.attribute15              salesrep_division
          ,JRR.role_id                  resource_role_id
          ,JRGM.group_id                group_id
          ,JRS.salesrep_id              salesrep_id
          ,JRS.salesrep_number          employee_number
          ,JRR.attribute14              role_code
          ,JRS.start_date_active        start_date_active
          ,JRS.end_date_active          end_date_active
          ,''                           comments
          ,p_batch_id                   batch_id
          ,p_process_audit_id           process_audit_id
    FROM   jtf_rs_group_members         JRGM
          ,jtf_rs_role_relations        JRRR
          ,jtf_rs_roles_vl              JRR
          ,jtf_rs_resource_extns        JRRE
          ,jtf_rs_salesreps             JRS
          ,hr_organization_units_v      HOU
          ,per_all_assignments_f        PAAF
    WHERE  JRGM.group_member_id       = JRRR.role_resource_id
    AND    nvl(JRGM.delete_flag,'N') <> 'Y'
    AND    JRRR.role_resource_type    = 'RS_GROUP_MEMBER'
    AND    nvl(JRRR.delete_flag,'N') <> 'Y'
    AND    p_rollup_date             BETWEEN  JRRR.start_date_active
                                     AND NVL( JRRR.end_date_active
                                             ,TO_DATE('12/31/4012','MM/DD/YYYY HH24:MI:SS'))
    AND    JRRR.role_id               = JRR.role_id
    AND    JRR.role_type_code         = 'SALES_COMP'
    AND    JRR.member_flag            = 'Y'
    AND    JRRE.resource_id           = JRGM.resource_id
    AND    JRS.resource_id            = JRGM.resource_id
    AND    p_rollup_date             BETWEEN  JRS.start_date_active
                                     AND NVL( JRS.end_date_active
                                            ,TO_DATE('12/31/4012','MM/DD/YYYY HH24:MI:SS'))
    AND    HOU.organization_id        = JRS.org_id
    AND    HOU.organization_type      = 'Operating Unit'
    AND    HOU.attribute5             = PAAF.ass_attribute1
    AND    JRRE.source_id             = PAAF.person_id
    AND    PAAF.effective_start_date <= NVL( TO_DATE(PAAF.ass_attribute9,'YYYY/MM/DD HH24:MI:SS')
                                            ,PAAF.effective_start_date)
    AND    NVL( TO_DATE(PAAF.ass_attribute9,'YYYY/MM/DD HH24:MI:SS')
               ,PAAF.effective_start_date) = ( SELECT MAX( NVL( TO_DATE(PAAF1.ass_attribute9,'YYYY/MM/DD HH24:MI:SS')
                                                               ,PAAF1.effective_start_date))
                                               FROM   per_all_assignments_f  PAAF1
                                               WHERE  PAAF1.person_id      = PAAF.person_id )
    AND    JRGM.resource_id           = p_resource_id;
    --
    -- End of Changes
    --

-- ----------------------------
-- Collection Type Declarations
-- ----------------------------

  -- ----------------------
  -- Collection Record Type
  -- ----------------------

    -- ---------------------------------
    -- Territory API Error PL/SQL Record
    -- ---------------------------------

    TYPE terr_api_error_type IS RECORD ( ship_to_address_id NUMBER
                                        ,party_site_id      NUMBER
                                        ,rollup_date        DATE
                                        ,source_doc_type    VARCHAR2(30)
                                        ,source_trx_id      NUMBER
                                        ,source_trx_line_id NUMBER
                                        ,error_message      VARCHAR2(2000) );

    -- -------------------------------------
    -- Sales Rep Details Error PL/SQL Record
    -- -------------------------------------

    TYPE sales_rep_error_type IS RECORD ( ship_to_address_id NUMBER
                                         ,party_site_id      NUMBER
                                         ,rollup_date        DATE
                                         ,resource_id        NUMBER
                                         ,nam_terr_id        NUMBER );

    -- -------------------------------------
    -- Sales Rep Details Error PL/SQL Record
    -- -------------------------------------

    TYPE rev_type_error_type IS RECORD ( ship_to_address_id  NUMBER(15)
                                        ,party_site_id       NUMBER(15)
                                        ,rollup_date         DATE
                                        ,resource_id         NUMBER(15)
                                        ,role_id             NUMBER(15)
                                        ,group_id            NUMBER(15)
                                        ,salesrep_division   VARCHAR2(40)
                                        ,role_code           VARCHAR2(50)
                                        ,revenue_type        VARCHAR2(50)
                                        ,comments            VARCHAR2(2000) );
  -- ---------------------
  -- Collection Table Type
  -- ---------------------

    -- --------------------------------
    -- Concurrent Requests PL/SQL Table
    -- --------------------------------

    TYPE conc_req_tbl_type IS TABLE OF NUMBER
    INDEX BY BINARY_INTEGER;

    -- ---------------------------------
    -- Sales Rep Assignment PL/SQL Table
    -- ---------------------------------

    TYPE sales_rep_asgn_tbl_type IS TABLE OF xx_cn_sales_rep_asgn%ROWTYPE
    INDEX BY BINARY_INTEGER;

    -- --------------------------------
    -- Territory API Error PL/SQL Table
    -- --------------------------------

    TYPE terr_api_error_tbl_type IS TABLE OF terr_api_error_type
    INDEX BY BINARY_INTEGER;

    -- ------------------------------------
    -- Sales Rep Details Error PL/SQL Table
    -- ------------------------------------

    TYPE sales_rep_error_tbl_type IS TABLE OF sales_rep_error_type
    INDEX BY BINARY_INTEGER;

    -- -------------------------------
    -- Revenue Type Error PL/SQL Table
    -- -------------------------------

    TYPE rev_type_error_tbl_type IS TABLE OF rev_type_error_type
    INDEX BY BINARY_INTEGER;

-- ----------------------------
-- Global Variable Declarations
-- ----------------------------

  -- -------------------------
  -- Global Constant Variables
  -- -------------------------

    G_ENTITY_TYPE            CONSTANT VARCHAR2(10) := 'PARTY_SITE';
    G_MAIN_PROG              CONSTANT VARCHAR2(35) := 'OD: CN SalesRep Assignment Program';
    G_MAIN_PROG_EXECUTABLE   CONSTANT VARCHAR2(21) := 'XXCNSALESREPASGNMAIN';
    G_NON_REVENUE            CONSTANT VARCHAR2(12) := 'NON-REVENUE';
    G_PROG_TYPE              CONSTANT VARCHAR2(50) := 'E1004E_CustomCollections_(SalesRep_Assignment)';
    G_PROG_APPLICATION       CONSTANT CHAR(5)      := 'XXCRM';
    G_REVENUE                CONSTANT VARCHAR2(7)  := 'REVENUE';
    G_ROLE_AM                CONSTANT VARCHAR2(2)  := 'AM';
    G_ROLE_BDM               CONSTANT VARCHAR2(3)  := 'BDM';
    G_ROLE_HSE               CONSTANT VARCHAR2(3)  := 'HSE';
    G_ROLE_SALES_SUPPORT     CONSTANT VARCHAR2(13) := 'SALES_SUPPORT';
    G_SALES_REP_ASGN_WRKER   CONSTANT VARCHAR2(20) := 'SALES_REP_ASGN_WRKER';
    G_SALES_REP_ASGN_MAIN    CONSTANT VARCHAR2(20) := 'SALES_REP_ASGN_MAIN';
    G_SR_DIV_BSD             CONSTANT VARCHAR2(3)  := 'BSD';
    G_SR_DIV_DPS             CONSTANT VARCHAR2(3)  := 'DPS';
    G_SR_DIV_FUR             CONSTANT VARCHAR2(10) := 'FURNITURE';
    G_WRKER_PROG             CONSTANT VARCHAR2(35) := 'OD: CN SalesRep Assignment Worker';
    G_WRKER_PROG_EXECUTABLE  CONSTANT VARCHAR2(21) := 'XXCNSALESREPASGNWRKER';

  -- ----------------------
  -- PL/SQL Table Variables
  -- ----------------------

    -- --------------------------
    -- Sales Rep Assignment Table
    -- --------------------------

    gt_sales_rep_asgn     sales_rep_asgn_tbl_type;

    -- -------------------------
    -- Territory API Error Table
    -- -------------------------

    gt_terr_api_error     terr_api_error_tbl_type;

    -- -----------------------------
    -- Sales Rep Details Error Table
    -- -----------------------------

    gt_sales_rep_error    sales_rep_error_tbl_type;

    -- ------------------------
    -- Revenue Type Error Table
    -- ------------------------

    gt_rev_type_error     rev_type_error_tbl_type;

  -- ----------------
  -- Global Variables
  -- ----------------

    gn_xfer_batch_size     NUMBER := FND_PROFILE.Value('XX_CN_SRA_BATCH_SIZE');

-- ---------------------
-- Function Declarations
-- ---------------------

    -- --------------------------
    -- Ins_Sales_Reps
    --
    -- XX_CN_SALES_REP_ASGN Table
    --
    -- Function for Insert
    -- --------------------------

    FUNCTION ins_sales_reps ( x_sales_rep_asgn_tbl  IN OUT sales_rep_asgn_tbl_type
                             ,p_commit_flag         IN     BOOLEAN  DEFAULT FALSE )
    RETURN BOOLEAN;

    -- --------------------------
    -- Upd_Sales_Reps
    --
    -- XX_CN_SALES_REP_ASGN Table
    --
    -- Function for Update
    -- --------------------------

    FUNCTION upd_sales_reps ( x_sales_rep_asgn_tbl  IN OUT sales_rep_asgn_tbl_type
                             ,p_commit_flag         IN     BOOLEAN  DEFAULT FALSE )
    RETURN BOOLEAN;

    -- ------------------------------
    -- Obs_Sales_Reps
    --
    -- XX_CN_SALES_REP_ASGN Table
    --
    -- Function for Delete / Obsolete
    -- ------------------------------

    FUNCTION obs_sales_reps ( x_sales_rep_asgn_tbl  IN OUT sales_rep_asgn_tbl_type
                             ,p_commit_flag         IN     BOOLEAN  DEFAULT FALSE )
    RETURN BOOLEAN;

-- ----------------------
-- Procedure Declarations
-- ----------------------

    -- -----------------------------------------
    -- Report_Error
    --
    -- Procedure to print Error Output
    -- -----------------------------------------

    PROCEDURE report_error;

    -- -----------------------------------------
    -- Get_Resources
    --
    -- Procedure to obtain Sales Rep Assignments
    -- from Custom Territory API and details of
    -- the Sales Reps
    -- -----------------------------------------

    PROCEDURE get_resources ( p_ship_to_address_id IN  NUMBER
                             ,p_party_site_id      IN  NUMBER -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 05-Nov-2007
                             ,p_rollup_date        IN  DATE
                             ,p_batch_id           IN  NUMBER
                             ,p_process_audit_id   IN  NUMBER
                             ,x_sales_rep_asgn_tbl OUT sales_rep_asgn_tbl_type
                             ,x_retcode            OUT NUMBER
                             ,x_errbuf             OUT VARCHAR2 );

    -- -----------------------------------------
    -- Set_Revenue_Type
    --
    -- Procedure to update Revenue Type for the
    -- the Sales Reps
    -- -----------------------------------------

    PROCEDURE set_revenue_type ( p_process_audit_id   IN     NUMBER
                                ,x_sales_rep_asgn_tbl IN OUT sales_rep_asgn_tbl_type
                                ,x_retcode            OUT    NUMBER
                                ,x_errbuf             OUT    VARCHAR2 );

    -- -----------------------------------------
    -- Insert_Salesreps
    --
    -- Procedure to obtain Sales Rep Assignments
    -- from Custom Territory API and to insert
    -- Sales Rep Assignment Records into Custom
    -- Table XX_CN_SALES_REP_ASGN
    -- -----------------------------------------

    PROCEDURE insert_salesreps ( p_ship_to_address_id IN  NUMBER
                                ,p_party_site_id      IN  NUMBER -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 05-Nov-2007
                                ,p_rollup_date        IN  DATE
                                ,p_batch_id           IN  NUMBER DEFAULT NULL
                                ,p_process_audit_id   IN  NUMBER
                                ,x_no_of_records      OUT NUMBER
                                ,x_retcode            OUT NUMBER
                                ,x_errbuf             OUT VARCHAR2 );

    -- -----------------------------------
    -- Sales_Rep_Asgn_Wrker
    --
    -- Sales Rep Assignment Worker Program
    -- -----------------------------------

    PROCEDURE sales_rep_asgn_wrker  ( x_errbuf           OUT VARCHAR2
                                     ,x_retcode          OUT NUMBER
                                     ,p_batch_id         IN  NUMBER
                                     ,p_process_audit_id IN  NUMBER );

    -- ---------------------------------
    -- Sales_Rep_Asgn_Main
    --
    -- Sales Rep Assignment Main Program
    -- ---------------------------------

    PROCEDURE sales_rep_asgn_main ( x_errbuf  OUT VARCHAR2
                                   ,x_retcode OUT NUMBER );

END xx_cn_sales_rep_asgn_pkg;
/

SHOW ERRORS;
