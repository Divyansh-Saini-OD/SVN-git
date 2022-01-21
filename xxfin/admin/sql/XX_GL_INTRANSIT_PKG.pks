SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE Body XX_GL_INTRANSIT_PKG
PROMPT Program exits IF the creation is not successful

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE
PACKAGE XX_GL_INTRANSIT_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_GL_INTRANSIT_PKG                                          |
-- | RICE ID :  R0493                                                    |
-- | Description : This package houses the report submission procedure   |
-- |              and as well as the detail report                       |
-- |              OD: GL In-Transit Orders Detail                        |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  22-JAN-09      Manovinayak         Initial version         |
-- |                         Ayyappan                                    |
-- |                         Wipro Technologies                          |
-- |1.1       5-MAR-09       Manovinayak         Changes for a defect    |
-- |                         Ayyappan            #13560                  |
-- |1.2      18-SEP-09       Anitha.D            Changes for a defect    |
-- |                                             #2253                   |
-- |1.3      19-Dec-2013     Jay Gupta           Defect# 27303           |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_GL_SUBMIT_PROC                                           |
-- | Description : This procedure will submit the detail and summary     |
-- |               reports for R0493                                     |
-- | Parameters  : p_period_from, p_period_to, p_sob_id, p_mode          |
-- | Returns     : x_err_buff,x_ret_code                                 |
-- +=====================================================================+

PROCEDURE XX_GL_SUBMIT_PROC (
                             x_err_buff    OUT VARCHAR2
                            ,x_ret_code    OUT  NUMBER
                            ,p_ledger_id   IN  NUMBER --v1.3,p_sob_id   							
                            ,p_period_from IN  VARCHAR2
                            ,p_period_to   IN  VARCHAR2   
                            ,p_mode        IN  VARCHAR2
                            );

-- +=====================================================================+
-- | Name :  XX_GL_DETAIL_PROC                                           |
-- | Description :This procedure is used for insert the In-Transit orders|
-- |              into the global temporary table                        |
-- | Parameters  : p_start_date, p_end_date, p_sobks_id                  |
-- |               ,p_cust_trx_id_from,p_cust_trx_id_to(Added for #2253) |
-- | Returns     : NULL                                                  |
-- +=====================================================================+

PROCEDURE XX_GL_DETAIL_PROC (
                             p_start_date       IN  DATE
                            ,p_end_date         IN  DATE
                            ,p_ledger_id        IN  NUMBER --v1.3,p_sob_id      
                            ,p_cust_trx_id_from IN  NUMBER -- Added for Defect 2253
                            ,p_cust_trx_id_to   IN  NUMBER -- Added for Defect 2253
                            );

--Added for the defect#13560
-- +=====================================================================+
-- | Name :  XX_GL_TAX_AMT_FUNC                                          |
-- | Description : This Function will calculate the total TAX amount for |
-- |               an Invoice                                            |
-- | Parameters  : p_cust_trx_id                                         |
-- | Returns     : ln_tax_amount                                         |
-- +=====================================================================+

FUNCTION XX_GL_TAX_AMT_FUNC(p_cust_trx_id IN NUMBER)
RETURN NUMBER;

PROCEDURE XX_GL_IN_TRN_ORD_DTL_RPT(
err_buff    OUT VARCHAR2,
ret_code    OUT NUMBER,
P_LEDGER_ID  NUMBER,
P_PERIOD_FROM VARCHAR2,
P_PERIOD_TO VARCHAR2
);

END XX_GL_INTRANSIT_PKG;
/
SHO ERR;
