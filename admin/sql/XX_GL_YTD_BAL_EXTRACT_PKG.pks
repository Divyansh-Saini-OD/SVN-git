SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Spec xx_gl_ytd_bal_extract_pkg
PROMPT Program exits if the creation is not successful

CREATE OR REPLACE PACKAGE xx_gl_ytd_bal_extract_pkg
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- +=================================================================================+
-- | Name       : XX_GL_YTD_BAL_EXTRACT_PKG.pks                                      |
-- | Description: Extension I2131_Oracle_GL_Feed_to_Hyperion_HFM for                 |
-- |              OD: GL Monthly YTD Balance Extract Program                         |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |1.0      27-MAY-2011   Jagadeesh S        Creation                               |
-- |                                                                                 |
---+=================================================================================+
-- ----------------------------------------------
-- Global Variables
-- ----------------------------------------------
   g_lt_file                     UTL_FILE.FILE_TYPE;

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  gl_ytd_bal_monthly_extract                                                     |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | Main procedure to get GL Monthly YTD balance extract                            |
-- |                                                                                 |
-- |HISTORY                                                                          |
-- | 1.0          Creation                                                           |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errbuf                 OUT     Error message.                                  |
-- |x_retcode                OUT     Error code.                                     |
-- |p_sob_name               IN      Set of Books Name                               |
-- |p_company                IN      Company Name                                    |
-- |p_year                   IN      Year                                            |
-- |p_period_name            IN      Period Name                                     |
-- |p_acc_rolup_grp          IN      Account Rollup Group Name                       |
-- |p_cc_rolup_grp           IN      Cost Center Rollup Group Name                   |
-- |                                                                                 |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  None.                                                                          |
-- +=================================================================================+

   PROCEDURE gl_ytd_bal_monthly_extract (
      x_err_buff        OUT NOCOPY      VARCHAR2,
      x_ret_code        OUT NOCOPY      NUMBER,
      p_sob_name        IN              VARCHAR2,
      p_company         IN              VARCHAR2,
      p_year            IN              VARCHAR2,
      p_period_name     IN              VARCHAR2,
      p_acc_rolup_grp   IN              VARCHAR2,
      p_cc_rolup_grp    IN              VARCHAR2
   );
END xx_gl_ytd_bal_extract_pkg;
/
SHOW errors;
