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
  -- |  Name  		:  XXDELETEBYPASSINVRTF.sql                                                         |
  -- |  RICE ID   	:                                                                               |
  -- |  Description :  This script will delete XML template for Bypassinv XML since territory is 
  --				   missing
  --                           																	  |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         11/13/2017   Ragni Gupta       Initial version                                  |
  -- +============================================================================================+


-- API to delete Data Definition from XDO_TEMPLATES_B and XDO_TEMPLATES_TL table
BEGIN
XDO_TEMPLATES_PKG.DELETE_ROW ('XXFIN', 'XXAPBYPASSINV');
COMMIT;
END;

-- Delete the Templates from XDO_LOBS table (There is no API)
DELETE FROM XDO_LOBS
      WHERE     LOB_CODE = 'XXAPBYPASSINV'
            AND APPLICATION_SHORT_NAME = 'XXFIN'
            AND LOB_TYPE IN ('TEMPLATE_SOURCE', 'TEMPLATE');
COMMIT; 

SHOW ERRORS;