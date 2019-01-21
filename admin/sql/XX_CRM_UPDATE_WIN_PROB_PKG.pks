SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_CRM_UPDATE_WIN_PROB_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_CRM_UPDATE_WIN_PROB_PKG
AS

-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name        : XX_CRM_UPDATE_WIN_PROB_PKG                               |
-- | Description : To update win_probabability to 25 in as_leads_all table  |
-- |               from 50.                                                 |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      28-MAY-2010  Anitha Devarajulu     Initial version             |
-- |1.1      03-JUN-2010  Anitha Devarajulu     Added IN paramets           |
-- +========================================================================+

-- +===================================================================+
-- | Name        : UPDATE_WIN_PROB_VALUE                               |
-- | Description : To update the values                                |
-- | Returns     : x_error_buf, x_ret_code                             |
-- +===================================================================+

   PROCEDURE UPDATE_WIN_PROB_VALUE (
                                    x_error_buf          OUT VARCHAR2
                                   ,x_ret_code           OUT NUMBER
                                   ,p_from_wp            IN  NUMBER
                                   ,p_to_wp              IN  NUMBER
                                   ,p_opp_num            IN  NUMBER DEFAULT NULL
                                   );

END XX_CRM_UPDATE_WIN_PROB_PKG;
/
SHOW ERR