SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_GL_SYNC_EXCHANGE_RATES_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_GL_SYNC_EXCHANGE_RATES_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name             :  XX_GL_SYNC_EXCHANGE_RATES_PKG                 |
-- | Description      :  Invoke the BPEL process to sync the currency  |
-- |                     exchange rates from Teradata                  |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |Draft    10-NOV-2009  Aravind A         Initial Version            |
-- |                                        for defect 3314            |
-- +===================================================================|

   PROCEDURE INVOKE_BPEL_PROCESS(
                                  x_ret_code         OUT     NUMBER
                                 ,x_err_buff         OUT     VARCHAR2
                                 ,p_req_system       IN      VARCHAR2     DEFAULT  'EBS'
                                 ,p_start_date       IN      VARCHAR2     DEFAULT  NULL
                                 ,p_end_date         IN      VARCHAR2
                                 ,p_timeout          IN      PLS_INTEGER  DEFAULT  180
                                );

END XX_GL_SYNC_EXCHANGE_RATES_PKG;

/

SHOW ERROR