SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Oracle GSD   - Hyderabad, India                  |
-- +===================================================================+
-- | Name  :    XX_CS_TDS_QUOTE_REC                                   |
-- | Description  : This script creates object type       	           |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                |
-- |=======   ==========  =============    	=======================|
-- |1.0      02-AUG-11    Gaurav Agarwal      Initial draft version  |
-- |                                                                   |
-- +===================================================================+



SET TERM ON
PROMPT Creating Record type XX_CS_TDS_QUOTE_REC
SET TERM OFF

create or replace  TYPE xx_cs_tds_quote_rec IS OBJECT (
    quote_number     VARCHAR2(25),
    expire_date      DATE,
    Manufacturer	   VARCHAR2(50),
    Model_no	       VARCHAR2(25),
    Serial_number	   VARCHAR2(25),
    Prob_descr	     VARCHAR2(250),
    Special_instr	   VARCHAR2(1000),
    attribute1       VARCHAR2(250),
    attribute2       VARCHAR2(250),
    attribute3       VARCHAR2(250),
    attribute4       VARCHAR2(250),
    attribute5       VARCHAR2(250)
   );
/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF


SHOW ERROR


