SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE XX_WFL_POSCHORD_PKG
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  WIPRO Organization                                            |
-- +================================================================================+
-- | Name        :  XXWFLPOSCHORDPKGS.pks                                           |
-- | Rice Id     :  E0242 PO cancellation from ISP                                  |
-- | Description :  This script creates custom package specification required for   |
-- |                PoCancellationFromIsp.                                          |                                                                                                    		    |                                
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author           Remarks            	                    |
-- |=======   ==========  =============    ============================             |
-- |DRAFT 1A 09-FEB-2007  Niharika           Initial draft version                  |
-- |1.0      10-Mar-2007  Niharika           Baselined after testing                |
-- |                                                                                |
-- +================================================================================+
AS

PROCEDURE GET_POSRC_TYPE_PROC(p_itemtype     IN  VARCHAR2
                             ,p_itemkey      IN  VARCHAR2
                             ,p_actid        IN  NUMBER
                             ,p_funcmode     IN  VARCHAR2
                             ,x_resultout    OUT VARCHAR2);
-- +================================================================================+
-- | Name        :  GET_POSRC_TYPE_PROC                                             |
-- | Description :  This  custom procedure to get value of                          |
-- |                attribute_category and to check whether it exist in custom      |
-- |                lookup code or not                                              |
-- +================================================================================+

PROCEDURE VALIDATE_POSTATUS_PROC(p_itemtype       IN  VARCHAR2
                             	,p_itemkey      IN  VARCHAR2
                             	,p_actid        IN  NUMBER
                             	,p_funcmode     IN  VARCHAR2
                             	,x_resultout    OUT VARCHAR2);
-- +================================================================================+
-- | Name        :  VALIDATE_POSTATUS_PROC                                          |
-- | Description :  This script creates custom procedure to check status of PO      |
-- |                whether it is cancelled or not. If it is cancelled then it will |
-- |                update table apps.po_change_requests with request_status        |
-- |                ='BUYER_APP'                                                    |
-- +================================================================================+

END XX_WFL_POSCHORD_PKG;
/
SHOW ERROR