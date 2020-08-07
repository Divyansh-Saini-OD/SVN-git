SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package XX_TDS_INV_COST_HOOK_EXT
PROMPT Program exits if the creation is not successful
CREATE OR REPLACE PACKAGE XX_TDS_INV_COST_HOOK_EXT AS
-- +============================================================================================+
-- |  Office Depot - TDS project                                                                |
-- |  Oracle GSD Consulting                                                                     |
-- +============================================================================================+
-- |  Name:  XX_TDS_INV_COST_HOOK_EXT                                                           |
-- |  Rice Id : I3029                                                                           |
-- |  Description:  This OD Package that contains a function to define custom extension    Item |
-- |                accounting derivation.                                                      |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    =================================================|
-- | 1.0         12-JUL-2011  Suraj Charan     Initial version                                  |
-- +============================================================================================+
   function cost_dist_hook_ext (
                                           i_org_id        IN              NUMBER,
                       i_txn_id        IN              NUMBER,
                       i_user_id       IN              NUMBER,
                       i_login_id      IN              NUMBER,
                       i_req_id        IN              NUMBER,
                       i_prg_appl_id   IN              NUMBER,
                       i_prg_id        IN              NUMBER,
                       o_err_num       OUT NOCOPY      NUMBER,
                       o_err_code      OUT NOCOPY      VARCHAR2,
                       o_err_msg       OUT NOCOPY      VARCHAR2
                                )
return integer  ;
END XX_TDS_INV_COST_HOOK_EXT;
/
SHOW ERROR