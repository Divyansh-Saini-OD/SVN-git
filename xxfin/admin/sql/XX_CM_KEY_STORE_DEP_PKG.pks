SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE Body XX_CM_KEY_STORE_DEP_PKG
PROMPT Program exits IF the creation is not successful
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE XX_CM_KEY_STORE_DEP_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_CM_KEY_STORE_DEP_PKG                                      |
-- | RICE ID :  R0537                                                    |
-- | Description :This package is the executable of the wrapper program  |
-- |              that used for submitting the OD: CM Keyed Store Deposit|
-- |              report with the desirable format of the user, and the  |
-- |              default format is EXCEL                                |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  29-DEC-08      Manovinayak         Initial version         |
-- |                         Ayyappan                                    |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_CM_KEY_STORE_DEP_PROC                                    |
-- | Description : The procedure will submit the OD: CM Keyed Store      |
-- |               Deposit report in the specified format                |
-- | Parameters :  p_date_from, p_date_to, p_bank_name, p_bank_branch,   |
-- |               p_bank_account, p_location, p_district, p_region      |
-- |               p_deposit_type, p_status_code                         |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

PROCEDURE XX_CM_KEY_STORE_DEP_PROC(
                                   x_err_buff      OUT VARCHAR2
                                  ,x_ret_code      OUT NUMBER
                                  ,p_date_from     IN  VARCHAR2
                                  ,p_date_to       IN  VARCHAR2
                                  ,p_bank_name     IN  VARCHAR2
                                  ,p_bank_branch   IN  VARCHAR2
                                  ,p_bank_account  IN  VARCHAR2
                                  ,p_location_from IN  VARCHAR2
                                  ,p_location_to   IN  VARCHAR2
                                  ,p_district      IN  VARCHAR2
                                  ,p_region        IN  VARCHAR2
                                  ,p_deposit_type  IN  VARCHAR2
                                  ,p_status_code   IN  VARCHAR2
                                  );

END XX_CM_KEY_STORE_DEP_PKG;
/
 SHO ERR;