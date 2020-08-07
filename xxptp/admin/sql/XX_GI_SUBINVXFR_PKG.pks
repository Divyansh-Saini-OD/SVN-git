SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE XX_GI_SUBINVXFR_PKG AUTHID CURRENT_USER
--Version Draft 1A
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- +=============================================================================+
-- |Package Name : XX_GI_SUBINVXFR_PKG                                           |
-- |Purpose      : This package contains procedures that validates the message   |
-- |                passed by Rice element I1106 and populates the EBS custom    |
-- |                table XX_GI_RCC_TRANSFER_STG and interface table             |
-- |                MTL_TRANSACTIONS_INTERFACE.                                  |
-- |                                                                             |
-- |Tables Accessed :                                                            |
-- |Access Type----------------- (I - Insert, S - Select, U - Update, D - Delete)|
-- | XX_GI_RCC_TRANSFER_STG       : I, S, U, D                                   |
-- | MTL_TRANSACTIONS_INTERFACE   : I                                            |
-- | MTL_SYSTEM_ITEMS_B           : S                                            |
-- | MTL_INTERORG_PARAMETERS      : S                                            |
-- | HR_ALL_ORGANIZATION_UNITS    : S                                            |
-- |                                                                             |
-- |                                                                             |
-- |Change History                                                               |
-- |                                                                             |
-- |Ver      Date          Author           Description                          |
-- |---      -----------   ---------------  -----------------------------        |
-- |Draft1A  26-Feb-2008   Arun Andavar     Draft version                        |
-- +=============================================================================+
IS
   TYPE detail_tbl_type IS TABLE OF  xx_gi_rcc_transfer_stg%ROWTYPE
   INDEX BY BINARY_INTEGER; 

   PROCEDURE POPULATE_SUBINV_XFR_DATA(
                                            p_calling_pgm     IN      VARCHAR2     DEFAULT NULL
                                           ,x_detail_tbl      IN OUT  detail_tbl_type    
                                           ,x_return_status      OUT  VARCHAR2                    
                                           ,x_return_message     OUT  VARCHAR2                    
                                            );
    PROCEDURE REPROCESS_SUBINV_XFR_DATA ( x_retcode        OUT NUMBER
                                         ,x_return_message OUT VARCHAR2
                                        );
 
    PROCEDURE RECONCILE_SUBINV_XFR_DATA (x_retcode        OUT NUMBER
                                        ,x_return_message OUT VARCHAR2
                                        );

END XX_GI_SUBINVXFR_PKG;
/
SHOW ERRORS;
EXIT
