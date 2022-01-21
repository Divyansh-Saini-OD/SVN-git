SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE Body XX_LONG_RUN_ALERT_PKG
PROMPT Program exits IF the creation is not successful

CREATE OR REPLACE PACKAGE APPS.XX_LONG_RUN_ALERT_PKG 
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		       |
-- +===================================================================+
-- | Name  : XX_LONG_RUN_ALERT_PKG                                     |
-- | Description      :  This PKG is used for long running alert       |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 19-Oct-2010  Sundaram S       Initial draft version       |
-- +===================================================================+

  PROCEDURE RUN_ALERT ( x_errmsg                 OUT   NOCOPY  VARCHAR2
                       ,x_retcode              OUT   NOCOPY  NUMBER);
END XX_LONG_RUN_ALERT_PKG;
/
SHO ERR;