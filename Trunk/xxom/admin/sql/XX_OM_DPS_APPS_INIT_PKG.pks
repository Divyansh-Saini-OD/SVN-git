SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_DPS_APPS_INIT_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name  :    XX_OM_DPS_APPS_INIT_PKG                                |
-- | Description      : This package is used to call a procedures      |
-- |                    to initialise Apps.                            |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |  1.0     23-Mar-07   Ganesan JV        Initial Version            |
-- +===================================================================+
AS 
   PROCEDURE DPS_APPS_INIT(
                            p_user_name IN  VARCHAR
                           ,p_resp_name IN  VARCHAR
                           ,x_status    OUT VARCHAR
                           ,x_message   OUT VARCHAR
                          );
-- +===================================================================+
-- | Name  : DPS_APPS_INIT                                             |
-- | Description   : This Procedure will be used to initialise the Apps|
-- |                                                                   |
-- | Parameters :       p_user_name                                    |
-- |                    p_resp_name                                    |
-- |                                                                   |
-- | Returns :          x_return_status                                |
-- |                    ,x_message                                     |
-- |                                                                   |
-- +===================================================================+

END XX_OM_DPS_APPS_INIT_PKG;
/
SHOW ERROR