SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_cn_retro_asgn_pkg AUTHID CURRENT_USER

-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                    Oracle NAIO Consulting Organization                   |
-- +==========================================================================+
-- | Name        : XX_CN_RETRO_ASGN_PKG.pks                                   |
-- | Rice ID     : I1005_RetroAssignmentChanges                               |
-- | Description : Custom Package that contains all the utility functions and |
-- |               procedures required to do Retro Assignments.               |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |Draft 1a 17-Oct-2007 Vidhya Valantina T     Initial draft version         |
-- |1.0      23-Oct-2007 Vidhya Valantina T     Baselined after review        |
-- |1.1      13-Nov-2007 Vidhya Valantina T     Changes due to Error Logging  |
-- |                                            Standards                     |
-- |                                                                          |
-- +==========================================================================+

AS

-- --------------------------
-- Global Cursor Declarations
-- --------------------------

    -- ------------------------------
    -- Processed Site Requests Cursor
    -- ------------------------------

    CURSOR gcu_site_requests ( p_party_site_id NUMBER )
    IS
    SELECT rowid                     row_id
          ,party_site_id             party_site_id
          ,site_request_id           site_request_id
          ,effective_date            effective_date
    FROM   xxtps_site_requests       XSR
    WHERE  XSR.request_status_code = 'COMPLETED'
    AND    XSR.party_site_id       = p_party_site_id
    AND    XSR.site_request_id     NOT IN ( SELECT XCSR.site_request_id
                                            FROM   xx_cn_site_requests   XCSR );

-- ----------------------------
-- Global Variable Declarations
-- ----------------------------

    G_PROG_TYPE   CONSTANT VARCHAR2(100):= 'I1005_RetroAssignmentChanges';
    G_RETRO_PROG  CONSTANT VARCHAR2(35) := 'OD: CN Retro Assignment Program';
    G_RETRO_ASGN  CONSTANT VARCHAR2(10) := 'RETRO_ASGN';

    -- --------------------------
    -- PL/SQL Table Variable
    --
    -- Sales Rep Assignment Table
    -- --------------------------

    gt_sales_rep_asgn     xx_cn_sales_rep_asgn_pkg.sales_rep_asgn_tbl_type;

-- ----------------------
-- Procedure Declarations
-- ----------------------

    -- ------------------------
    -- Run_Retro_Asgn
    --
    -- Retro Assignment Program
    -- ------------------------

    PROCEDURE run_retro_asgn( x_errbuf           OUT VARCHAR2
                             ,x_retcode          OUT NUMBER
                             ,p_start_date       IN  VARCHAR2
                             ,p_end_date         IN  VARCHAR2 );

END xx_cn_retro_asgn_pkg;
/

SHOW ERRORS;

