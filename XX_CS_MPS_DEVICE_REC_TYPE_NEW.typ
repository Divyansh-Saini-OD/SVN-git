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
-- | Name  :    XX_CS_MPS_DEVICE_REC_TYPE                              |
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

drop type XX_CS_MPS_DEVICE_TBL_TYPE
/


SET TERM ON
PROMPT Creating Record type XX_CS_MPS_DEVICE_REC_TYPE
SET TERM OFF

create or replace
TYPE XX_CS_MPS_DEVICE_REC_TYPE
IS object
(Group_id         Varchar2(100),
device_id        	varchar2(150),
device_name       	varchar2(250),
device_status     	varchar2(100),
Account_Number      varchar2(100),
current_count		    number,  -- page this month
black_count     	  number,
color_count		      number,
total_count         Integer,
supply_tbl          XX_CS_MPS_SUPPLY_TBL_TYPE,
First_seen          date,
last_active         date,
ip_address          varchar2(100),
serial_number       varchar2(100),
attribute1		      varchar2(150),
attribute2		      varchar2(150),
attribute3		      varchar2(150),
attribute4		      varchar2(150),
attribute5		      varchar2(150));
/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_CS_MPS_DEVICE_TBL_TYPE
SET TERM OFF


create or replace
TYPE XX_CS_MPS_DEVICE_TBL_TYPE Is Table Of XX_CS_MPS_DEVICE_REC_TYPE

/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR


