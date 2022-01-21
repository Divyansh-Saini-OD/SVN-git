create or replace 
package XX_GL_BAL_ARCS_OB_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_GL_BAL_ARCS_OB_PKG                                                            |
  -- |  RICE ID   :  I3120-GL Balanaces Outbound to ARCS                                                |
  -- |  Description:                                                                              |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         16-APR-18    Sasidhar Kota      Initial version                                |
  -- | 1.1         15-MAY-18    M K Pramod Kumar   Modified to include active accounts and period_name validation
  -- | 1.2         12-SEP-18    Priyam Parmar      Modified to fetch enabled and disabled code combinations for  NAIT-59916
  -- | 1.3         09-OCT-18    Priyam Parmar      Added procedure to fetch reportin currency balance for NAIT-63426
  -- +============================================================================================+


PROCEDURE populate_gl_out_file(p_errbuf  OUT  VARCHAR2
                         ,p_retcode      OUT  NUMBER
                         ,p_period_name   IN  VARCHAR2
                      	 ,p_debug         IN  VARCHAR2);

PROCEDURE process_gl_balances_ob (p_errbuf  OUT  VARCHAR2
                         ,p_retcode       OUT  NUMBER
                         ,P_PERIOD_NAME    in   varchar2
                      	 ,P_DEBUG         in   varchar2,
                         P_flag_rc in varchar2);

PROCEDURE populate_gl_out_file_rc (p_errbuf  OUT  VARCHAR2
                         ,p_retcode      OUT  NUMBER
                         ,p_period_name   IN  VARCHAR2
                      	 ,p_debug         IN  VARCHAR2);

END XX_GL_BAL_ARCS_OB_PKG;
/
