create or replace 
package XX_GL_BAL_ARCS_RC_OB_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_GL_BAL_ARCS_OB_PKG                                                       |
-- |  RICE ID 	 :  GL Balances Outbound Interface to ARCS   	                                |
-- |  Description:         								        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         03-OCT-18    Priyam       Jira -63426 GL ARCS modified for Reporting currency               |
-- +============================================================================================+


PROCEDURE populate_gl_out_file(p_errbuf  OUT  VARCHAR2
                         ,p_retcode      OUT  NUMBER
                         ,p_period_name   IN  VARCHAR2
                      	 ,p_debug         IN  VARCHAR2);

PROCEDURE process_gl_balances_ob (p_errbuf  OUT  VARCHAR2
                         ,p_retcode       OUT  NUMBER
                         ,P_PERIOD_NAME    in   varchar2
                      	 ,p_debug         IN   VARCHAR2);

END XX_GL_BAL_ARCS_RC_OB_PKG;
/
