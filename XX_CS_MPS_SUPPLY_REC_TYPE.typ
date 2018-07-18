SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :    XX_CS_MPS_DEVICE_TBL_TYPE                               |
-- | Description  : This script creates object type 		       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                |
-- |=======   ==========  =============    	=======================|
-- |DRAFT 1A 23-SEP-12  Rajeswari Jagarlamudi   Initial draft version  |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+



SET TERM ON
PROMPT Creating Record type XX_CS_MPS_SUPPLY_REC_TYPE
SET TERM OFF

create or replace
TYPE XX_CS_MPS_SUPPLY_REC_TYPE
IS object
( LABEL         VARCHAR2(100),
  STATUS        VARCHAR2(25),
  HIGH_LEVEL    VARCHAR2(25),
  LOW_LEVEL     VARCHAR2(25),
  TYPE_ID       VARCHAR2(25),
  COLOR         VARCHAR2(50),
  FIRST_REPORT  DATE,
  LAST_REPORT   DATE);

/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_CS_MPS_SUPPLY_TBL_TYPE
SET TERM OFF

create or replace
TYPE XX_CS_MPS_SUPPLY_TBL_TYPE Is Table Of XX_CS_MPS_SUPPLY_REC_TYPE;
/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR


