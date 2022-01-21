SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  		:  XXDELETEAPPENDSTROYMERCHREP.sql                                              |
  -- |  RICE ID   	:                                                                             |
  -- |  Description :  This script will delete XML template for Pending Destroyed report     |
  -- |				   XML since territory is missing													  |
  -- |                          																  |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         11/14/2017   Jitendra Atale 	 Initial version                                  |
  -- +============================================================================================+


-- API to delete Data Definition from XDO_TEMPLATES_B and XDO_TEMPLATES_TL table
BEGIN
XDO_TEMPLATES_PKG.DELETE_ROW ('XXFIN', 'XXAPPENDSTROYMERCHREP');
COMMIT;

-- Delete the Templates from XDO_LOBS table (There is no API)
DELETE FROM XDO_LOBS
      WHERE     LOB_CODE = 'XXAPPENDSTROYMERCHREP'
            AND APPLICATION_SHORT_NAME = 'XXFIN'
            AND LOB_TYPE IN ('TEMPLATE_SOURCE', 'TEMPLATE');
COMMIT; 
END;
/
SHOW ERRORS;

