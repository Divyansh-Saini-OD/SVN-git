create or replace PACKAGE XX_AR_WC_MASTER_PKG 
AS
-- +=======================================================================+
-- |                  Office Depot - Project Simplify                      |
-- |                        Office Depot Organization                      |
-- +=======================================================================+
-- | Name         : XX_AR_WC_MASTER_PKG                                    |
-- |                                                                       |
-- | RICE#        : I2158                                                  |
-- |                                                                       |
-- | Description  :                                                        |
-- |                                                                       |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version    Date         Author         Remarks                         |
-- |=========  ===========  =============  ================================|
-- |                                                                       |
-- |                                                                       |
-- |                                                                       |
-- |                                                                        |
-- +=======================================================================+

   -- Table type declaration
   TYPE REQ_ID IS TABLE OF NUMBER
      INDEX BY PLS_INTEGER;

   --Global Initialization
   gn_user_id   NUMBER := fnd_profile.VALUE ('USER_ID');
   gn_appl_id   NUMBER := fnd_profile.VALUE ('RESP_APPL_ID');
   gn_resp_id   NUMBER := FND_PROFILE.VALUE ('RESP_ID');

   -- +====================================================================+
   -- | Name       : master_ext                                            |
   -- |                                                                    |
   -- | Description:                                                       |
   -- |                                                                    |
   -- | Parameters :                                                       |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE master_ext (p_errbuf          OUT      VARCHAR2
                        ,p_retcode         OUT      NUMBER
                        ,p_cycle_date      IN       VARCHAR2
                        ,p_batch_num       IN       NUMBER     
                        ,p_compute_stats   IN       VARCHAR2
                        ,p_debug           IN       VARCHAR2
                        ,p_process_type    IN       VARCHAR2
                        ,p_action_type     IN       VARCHAR2);

END XX_AR_WC_MASTER_PKG;
/
show errors
