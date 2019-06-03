-- Name:      od_po_create_log_errors.sql
-- Objective: Create tables for to maintain and log errors


CREATE TABLE xxmer.xx_po_log_errors
(
ERROR_PROCESS_DATE  DATE NOT NULL,
ERROR_MODULE_NAME   VARCHAR2(200 BYTE) NOT NULL,
ERROR_EVENT         VARCHAR2(1000),
ERROR_SEVERITY      VARCHAR2(1 BYTE) NOT NULL,
ERROR_CDE           VARCHAR2(10 BYTE) NOT NULL,
ERROR_DSC           VARCHAR2(400 BYTE),
ERROR_USER_ID       NUMBER,
ERROR_LOGIN_ID      NUMBER,
ERROR_STATUS        VARCHAR2(1 BYTE) NOT NULL,
ERROR_ATTRIB1       VARCHAR2(1000 BYTE),
ERROR_ATTRIB2       VARCHAR2(1000 BYTE),
ERROR_ATTRIB3       VARCHAR2(1000 BYTE),
ERROR_ATTRIB4       VARCHAR2(1000 BYTE),
ERROR_ATTRIB5       VARCHAR2(1000 BYTE),
ERROR_ATTRIB6       VARCHAR2(1000 BYTE),
ERROR_LOG_TIME      VARCHAR2(30) NOT NULL,
ERROR_SND_TIME      DATE
)
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
NOMONITORING;

create synonym xx_po_log_errors for xxmer.xx_po_log_errors;

COMMENT ON COLUMN xx_po_log_errors.ERROR_PROCESS_DATE IS 'Virtual or day of the process';

COMMENT ON COLUMN xx_po_log_errors.ERROR_MODULE_NAME IS 'Module/Job in where the error was detected';

COMMENT ON COLUMN xx_po_log_errors.ERROR_EVENT IS 'Description on where the error occurred';

COMMENT ON COLUMN xx_po_log_errors.ERROR_SEVERITY IS 'SEVERITY of error=''W''=Warning, ''E''=Error or ''I''=Informational';

COMMENT ON COLUMN xx_po_log_errors.ERROR_CDE IS 'Error code, could be any code including sqlcodes';

COMMENT ON COLUMN xx_po_log_errors.ERROR_DSC IS 'Description of error';

COMMENT ON COLUMN xx_po_log_errors.ERROR_STATUS IS 'Status of the error, ''P''=Pending to be processed, ''S''=Email has been sent, ''W''=Processed and waiting to be sent';

COMMENT ON COLUMN xx_po_log_errors.ERROR_ATTRIB1 IS 'Miscellaneous';

COMMENT ON COLUMN xx_po_log_errors.ERROR_ATTRIB2 IS 'Miscellaneous';

COMMENT ON COLUMN xx_po_log_errors.ERROR_ATTRIB3 IS 'Miscellaneous';

COMMENT ON COLUMN xx_po_log_errors.ERROR_ATTRIB4 IS 'Miscellaneous';

COMMENT ON COLUMN xx_po_log_errors.ERROR_ATTRIB5 IS 'Miscellaneous';

COMMENT ON COLUMN xx_po_log_errors.ERROR_ATTRIB6 IS 'Miscellaneous';

COMMENT ON COLUMN xx_po_log_errors.ERROR_LOG_TIME IS 'Time when the error was logged into this table';

COMMENT ON COLUMN xx_po_log_errors.ERROR_SND_TIME IS 'Time when the error message was sent by email';

--======================================================

CREATE TABLE xxmer.xx_po_log_modules
(
 MODULE_GROUP   NUMBER(10)         NOT NULL,
 MODULE_NAME    VARCHAR2(100 BYTE) NOT NULL,
 MODULE_DESC    VARCHAR2(200 BYTE) NOT NULL,
 MODULE_TITLE   VARCHAR2(100 BYTE),
 MODULE_USER_ID NUMBER(10)
)
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
NOMONITORING;

 CREATE SYNONYM xx_po_log_modules FOR xxmer.xx_po_log_modules;


CREATE UNIQUE INDEX xx_po_log_modules_PK ON xxmer.xx_po_log_modules
(MODULE_GROUP, MODULE_NAME)
LOGGING
NOPARALLEL;


ALTER TABLE xxmer.xx_po_log_modules ADD (
CONSTRAINT xx_po_log_modules_pk
PRIMARY KEY
(MODULE_GROUP, MODULE_NAME));

create synonym xx_po_log_groups for xxmer.xx_po_log_groups;

CREATE TABLE xxmer.xx_po_log_groups
(
 group_code  NUMBER(10)    NOT NULL,
 group_desc  VARCHAR2(100) NOT NULL
);

ALTER TABLE xxmer.xx_po_log_groups ADD (
CONSTRAINT xx_po_log_groups_pk
PRIMARY KEY
(GROUP_CODE));
