SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE SPECIFICATION XX_CM_TENDER_TYPE_WRAP_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_CM_TENDER_TYPE_WRAP_PKG
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name        : XX_CM_TENDER_TYPE_WRAP_PKG                               |
-- | RICE ID     : R0471                                                    |
-- | Description : This package is the executable of the wrapper program    |
-- |               that is used for submitting the OD: CM Tender Type Report|
-- |               with the desirable format of the user, and the default   | 
-- |               format is EXCEL                                          |
-- |                                                                        |
-- | Change Record:                                                         |
-- | ==============                                                         |
-- | Version      Date          Author            Remarks                   |
-- | ========     =========     =============     ===============           |
-- | Draft 1A     09-APR-09     Trisha Saxena     Initial version           |
-- |                                                                        |
-- +========================================================================+

-- +========================================================================+
-- | Name        : XX_CM_TENDER_TYPE_WRAP_PROC                              |
-- | Description : The procedure will submit the OD: CM Tender Type Report  |
-- |               in the specified format                                  |
-- | Parameters  : p_tender_type_from, p_tender_type_to                     | 
-- |               , p_accounting_period_from, p_accounting_period_to       |  
-- |               , p_dummy                                                |
-- | Returns     :  x_err_buff,x_ret_code                                   |
-- +========================================================================+

PROCEDURE XX_CM_TENDER_TYPE_WRAP_PROC(x_err_buff                 OUT VARCHAR2
                                      ,x_ret_code                OUT NUMBER
                  		      ,p_tender_type_from        IN  VARCHAR2
				      ,p_tender_type_to          IN  VARCHAR2
				      ,p_accounting_period_from  IN  VARCHAR2
				      ,p_accounting_period_to    IN  VARCHAR2
				      ,p_dummy                   IN  VARCHAR2
       				     );
END XX_CM_TENDER_TYPE_WRAP_PKG;
/

SHO ERR 
