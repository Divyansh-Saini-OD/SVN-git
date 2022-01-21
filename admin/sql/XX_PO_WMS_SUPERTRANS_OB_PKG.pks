create or replace package XX_PO_WMS_SUPERTRANS_OB_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_PO_WMS_SUPERTRANS_OB_PKG                                                     |
-- |  RICE ID 	 :  E3522 Trade Match SuperTrans outbound to WMS    	                        |
-- |  Description:         								        								|
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         09-Oct-17    Madhu Bolli      Initial version                                  |
-- +============================================================================================+

                      
PROCEDURE adj_cost_generate(p_errbuf      OUT  VARCHAR2
                         ,p_retcode       OUT  NUMBER
                         ,p_batch_id      IN   NUMBER
                         ,p_acct_run_date IN   DATE
                      	 ,p_debug         IN   VARCHAR2); 

PROCEDURE match_recpt_generate(p_errbuf   OUT  VARCHAR2
                         ,p_retcode       OUT  NUMBER
                         ,p_batch_id      IN   NUMBER
                         ,p_acct_run_date IN   DATE
                      	 ,p_debug         IN   VARCHAR2);

PROCEDURE populate_supertrans_file(p_errbuf     OUT  VARCHAR2
                         ,p_retcode      OUT  NUMBER
                         ,p_batch_id     IN   NUMBER
                      	 ,p_debug        IN   VARCHAR2);
						 
PROCEDURE process_supertrans_ob(p_errbuf  OUT  VARCHAR2
                          ,p_retcode      OUT  NUMBER
                          ,p_acct_run_date IN  VARCHAR2
                      	  ,p_debug        IN   VARCHAR2); 
						  
                      	  
END XX_PO_WMS_SUPERTRANS_OB_PKG;
/