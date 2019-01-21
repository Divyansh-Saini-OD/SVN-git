 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF
 SET FEEDBACK OFF
 SET TERM ON

 PROMPT Creating Package Specification XX_GL_BALANCE_EXT_PKG
 PROMPT Program exits if the creation is not successful
 WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_GL_BALANCE_EXT_PKG
AS
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                       WIPRO Technologies                           |
-- +====================================================================+
-- | Name   :      GL Ledger balances extract program                   |
-- | Rice ID:      I1360                                                |
-- | Description : extracts Ledger balances from Oracle General Ledger  |
-- |               on a monthly as well as daily basis based on the     |
-- |               input parameters and writes it into a data file      |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version   Date           Author              Remarks                |
-- |=======   ==========     ===============     =======================|
-- |  1.0     20-Jun-2008    Shabbar Hasan       Initial version        |
-- |  1.1     07-Oct-2010    Mohammed Appas      Added the procedure    |
-- |                                             GL_BAL_MONTHLY_EXTRACT_|
-- |                                             CAD_MTD for            |
-- |                                             Defect# 7916           |
-- |                                                                    |
-- +====================================================================+
-- +====================================================================+
-- | Name : GL_BALANCE_EXTRACT                                          |
-- | Description : calls the daily extract program or the monthly       |
-- |               extract program depending on the value of the        |
-- |               p_program parameter                                  |
-- | Parameters :  x_err_buff, x_ret_code, p_program, p_sob_name,       |
-- |               p_year, p_period_name                                |
-- | Returns :     Returns Code                                         |
-- |               Error Message                                        |
-- +====================================================================+
PROCEDURE GL_BALANCE_EXTRACT(x_err_buff         OUT NOCOPY VARCHAR2
                             ,x_ret_code        OUT NOCOPY NUMBER
                             ,p_program         IN  VARCHAR2
                             ,p_sob_name        IN  VARCHAR2
                             ,p_year            IN  NUMBER
                             ,p_period_name     IN  VARCHAR2
                             ,p_acc_rolup_grp_name   IN VARCHAR2
                             ,p_cc_rolup_grp_name    IN VARCHAR2
                            );
-- +===================================================================+
-- | Name : GL_BAL_DAILY_EXTRACT                                       |
-- | Description : extracts the ledger balances and COA segments on a  |
-- |               daily basis from Oracle General Ledger and copies   |
-- |               on to a data file                                   |
-- | Parameters :  p_sob_name, p_year, p_period_name                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE GL_BAL_DAILY_EXTRACT(p_sob_name       IN  VARCHAR2
                               ,p_year          IN  NUMBER
                               ,p_period_name   IN  VARCHAR2
                               ,p_acc_rolup_grp_name   IN VARCHAR2
                               ,p_cc_rolup_grp_name    IN VARCHAR2
                              );
-- +====================================================================+
-- | Name : GL_BAL_MONTHLY_EXTRACT                                      |
-- | Description : extracts the ledger balances and COA segments on a   |
-- |               monthly basis from Oracle General Ledger and copies  |
-- |               on to a data file                                    |
-- | Parameters :  x_err_buff, x_ret_code, p_sob_name, p_year,          |
-- |               p_period_name                                        |
-- | Returns :     Return Code, Error buff                              |
-- |                                                                    |
-- +====================================================================+
PROCEDURE GL_BAL_MONTHLY_EXTRACT(x_err_buff      OUT NOCOPY VARCHAR2
                                 ,x_ret_code     OUT NUMBER
                                 ,p_sob_name     IN  VARCHAR2
                                 ,p_year         IN  NUMBER
                                 ,p_period_name  IN  VARCHAR2
                                 ,p_acc_rolup_grp_name   IN VARCHAR2
                                 ,p_cc_rolup_grp_name    IN VARCHAR2
                                );
--Added the below procedure GL_BAL_MONTHLY_EXTRACT_CAD_MTD for Defect# 7916 by Mohammed Appas on 07-Oct-2010
-- +====================================================================+
-- | Name : GL_BAL_MONTHLY_EXTRACT_CAD_MTD                              |
-- | Description : extracts the ledger balances and COA segments on a   |
-- |               monthly basis from Oracle General Ledger for CA      |
-- |               Set of books alone with MTD Column and copies on to  |
-- |               a data file                                          |
-- | Parameters :  x_err_buff, x_ret_code, p_sob_name, p_year,          |
-- |               p_period_name                                        |
-- | Returns :     Return Code, Error buff                              |
-- +====================================================================+
PROCEDURE GL_BAL_MONTHLY_EXTRACT_CAD_MTD(x_err_buff      OUT NOCOPY VARCHAR2
                                        ,x_ret_code     OUT NUMBER
                                        ,p_year         IN  NUMBER
                                        ,p_period_name  IN  VARCHAR2
                                        ,p_acc_rolup_grp_name   IN VARCHAR2
                                        ,p_cc_rolup_grp_name    IN VARCHAR2
                                        );
END XX_GL_BALANCE_EXT_PKG;
/
SHOW ERR
