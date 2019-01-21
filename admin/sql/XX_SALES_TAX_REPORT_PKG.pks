SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
SET DEFINE OFF

PROMPT Creating Package XX_SALES_TAX_REPORT_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_SALES_TAX_REPORT_PKG

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name : Sales Tax Reporting Interface                              |
-- | Rice ID : I0431                                                   |
-- | Description : This feeds all the transactions from the Oracle     |
-- |               E-Business to Vertex, for Sales Reporting and filing|
-- |               tax returns                                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |1.0       13-JAN-2009     Lincy K           Initial version        |
-- |1.1       07-FEB-2009    Aravind A.         Performance changes    |
-- |                                                                   |
-- +===================================================================+
AS

-- +===================================================================+
-- | Name       : SALES_TAX                                            |
-- | Parameters : p_order_type ,p_file_path,p_cycle_date ,p_debug      |
-- | Returns    : Return Code                                          |
-- |              Error Message                                        |
-- +===================================================================+

 PROCEDURE SALES_TAX (       x_error_buff      OUT  VARCHAR2
                            ,x_ret_code        OUT  NUMBER
                            ,p_order_type      IN   VARCHAR2
                            ,p_file_path       IN   VARCHAR2
                            ,p_cycle_date      IN   VARCHAR2
                            ,p_debug           IN   VARCHAR2
                         );

END XX_SALES_TAX_REPORT_PKG;

/

SHOW ERROR
