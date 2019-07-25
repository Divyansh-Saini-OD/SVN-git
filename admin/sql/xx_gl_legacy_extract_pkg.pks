SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
  
WHENEVER SQLERROR CONTINUE; 
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE xx_gl_legacy_extract_pkg
AS
  -- +=================================================================================+
  -- |                       Office Depot - Project Simplify                           |
  -- +=================================================================================+
  -- | Name       : xx_gl_legacy_extract_pkg.pks                                      |
  -- | Description: Extension I2131_Oracle_GL_Feed_to_FCC for                 |
  -- |              OD: GL Monthly YTD Balance Extract Program                         |
  -- |                                                                                 |
  -- |Change Record                                                                    |
  -- |==============                                                                   |
  -- |Version   Date         Authors            Remarks                                |
  -- |========  ===========  ===============    ============================           |
  -- |1.0      29-JAN-2019   Priyam P        Creation                               |
  -- |                                                                                 |
  ---+=================================================================================+
  -- ----------------------------------------------
  -- Global Variables
  -- ----------------------------------------------
  g_lt_file UTL_FILE.FILE_TYPE;
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
  -- |p_period_name            IN      Period Name                                     |                 |
  -- |                                                                                 |
  -- |                                                                                 |
  -- |PREREQUISITES                                                                    |
  -- |  None.                                                                          |
  -- |                                                                                 |
  -- |CALLED BY                                                                        |
  -- |  None.                                                                          |
  -- +=================================================================================+
  PROCEDURE gl_ytd_bal_monthly_extract(
      x_err_buff OUT NOCOPY VARCHAR2,
      x_ret_code OUT NOCOPY NUMBER,
      p_sob_name    IN VARCHAR2,
      p_company     IN VARCHAR2,
      p_year        IN VARCHAR2,
      p_period_name IN VARCHAR2
      -- p_acc_rolup_grp   IN              VARCHAR2,
      --- p_cc_rolup_grp    IN              VARCHAR2
    );
    
    
    procedure gl_ytd_wrapper(  
    p_sob_name    IN VARCHAR2,
    p_company     IN VARCHAR2,
    p_year        in varchar2,
    p_period_name in varchar2);
END xx_gl_legacy_extract_pkg;
/

SHOW ERRORS;