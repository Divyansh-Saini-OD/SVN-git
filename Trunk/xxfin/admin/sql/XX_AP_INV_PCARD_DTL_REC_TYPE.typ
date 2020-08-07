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
-- | Name  :    XX_AP_INVINB_PCARD_DTL_REC                             |
-- | Description  : This script creates object type 		       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                |
-- |=======   ==========  =============    	=======================|
-- |DRAFT 1A 13-SEP-11  Bala E   Initial draft version  |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


SET TERM ON
PROMPT Creating Record type XX_AP_INVINB_PCARD_DTL_REC
SET TERM OFF



CREATE OR REPLACE
TYPE XX_AP_INVINB_PCARD_DTL_REC AS OBJECT (
LINE_TRANSACT_AMOUNT   VARCHAR2(250),
LINE_SALES_TAX_AMOUNT  VARCHAR2(250),
ACCOUNTING_CODE        VARCHAR2(250),
EMPLOYEE_NO            VARCHAR2(250),
ACCOUNT_NUMBER         VARCHAR2(250),
LINE_TRASACT_DATE      VARCHAR2(25),
ATTRIBUTE1    VARCHAR2(150),
ATTRIBUTE2    VARCHAR2(150),
ATTRIBUTE3    VARCHAR2(150),
ATTRIBUTE4    VARCHAR2(150),
ATTRIBUTE5    VARCHAR2(150),
ATTRIBUTE6    VARCHAR2(150),
ATTRIBUTE7    VARCHAR2(150),
ATTRIBUTE8    VARCHAR2(150),
ATTRIBUTE9    VARCHAR2(150),
ATTRIBUTE10   VARCHAR2(150),
ATTRIBUTE11   VARCHAR2(150),
ATTRIBUTE12   VARCHAR2(150),
ATTRIBUTE13   VARCHAR2(150),
ATTRIBUTE14   VARCHAR2(150),
ATTRIBUTE15   VARCHAR2(150)
)


/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type XX_AP_INVINB_PCARD_DTL_TBL
SET TERM OFF

CREATE OR REPLACE
TYPE XX_AP_INVINB_PCARD_DTL_TBL AS TABLE OF XX_AP_INVINB_PCARD_DTL_REC

/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR



