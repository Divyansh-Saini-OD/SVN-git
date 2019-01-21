SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE XX_GL_BAL_RATES_EXT_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_GL_BAL_RATES_EXT_PKG
AS

-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                       WIPRO Technologies                           |
-- +====================================================================+
-- | Name   :      Ledger balances and Exchange rates extract program   |
-- | Rice ID:      I1360                                                |
-- | Description : extracts Ledger balances and Exchange rates from     |
-- |               Oracle General Ledger  based on the input parameters |
-- |               and writes it into a  data file                      |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version   Date          Author              Remarks                 |
-- |=======   ==========   ===============      ========================|
-- |  1.0   17-Aug-2007   Nandini Bhimana     Initial version           |
-- |                         Boina                                      |
-- +====================================================================+
-- +====================================================================+
-- | Name : GL_BAL_EXTRACT                                              |
-- | Description : extracts the ledger balances and COA segments  on a  |
-- |               monthly basis from Oracle General Ledger and copies  |
-- |               on to a data file                                    |
-- | Parameters :  x_error_buff, x_ret_code,p_period_name,p_sob_name    |
-- | Returns :     Returns Code                                         |
-- |               Error Message                                        |
-- +====================================================================+

   PROCEDURE GL_BAL_EXTRACT(
                           x_err_buff         OUT NOCOPY VARCHAR2
                           ,x_ret_code        OUT NOCOPY VARCHAR2
                           ,p_sob_name        IN  VARCHAR2
                           ,p_period_name     IN  VARCHAR2
                           );

-- +===================================================================+
-- | Name : GL_AVG_END_RATES_EXT                                       |
-- | Description : extract the period exchange rates on a              |
-- |               daily basis from Oracle General Ledger and copies   |
-- |               on to a data file                                   |
-- | Parameters :  x_error_buff, x_ret_code,p_run_date                 |
-- | Returns :     Returns Code                                        |
-- |               Error Message                                       |
-- +===================================================================+

   PROCEDURE GL_AVG_END_RATES_EXT(
                                 x_err_buff     OUT NOCOPY VARCHAR2
                                 ,x_ret_code    OUT NOCOPY VARCHAR2
                                 ,p_period_name     IN  VARCHAR2
                                 );
END XX_GL_BAL_RATES_EXT_PKG;
/
SHOW ERROR
