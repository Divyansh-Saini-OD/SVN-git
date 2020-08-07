SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_DPS_APPS_INIT_PKG
-- +===================================================================+
-- | Name  :    XX_DPS_CONF_REL_PKG                                    |
-- | Description      : This package is used to call the various       |
-- |                    procedures to do all necessary validations     |
-- |                    get the informaton needed for updating the     |
-- |                    sales order.                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |  1.0     23.03.07   Ganesan JV                                    |
-- +===================================================================+
AS 
   PROCEDURE DPS_APPS_INIT(
   			   p_user_name IN VARCHAR
			   ,p_resp_name IN VARCHAR
			   ,x_status   OUT VARCHAR
			   ,x_message   OUT VARCHAR
			  );
-- +===================================================================+
-- | Name  : DPS_APPS_INIT                                             |
-- | Description   : This Procedure will be used Initialise the Apps   |
-- |                 			                               |
-- |                                                                   |
-- | Parameters :       p_user_name                                    |
-- |  			p_resp_name				       |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_return_status				       |
-- |                    ,x_message                                     |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

END XX_OM_DPS_APPS_INIT_PKG;
/
SHOW ERROR