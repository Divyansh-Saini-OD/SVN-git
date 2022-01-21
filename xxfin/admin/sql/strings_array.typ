SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name        :strings_array                                       |
-- | Description : Create strings_array                        |
-- |Change History:                                                        |
-- |---------------                                                        |
-- | RICE ID :                                                        |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     05-MAR-19 Arun                     |
-- +=======================================================================+

SET TERM ON
PROMPT Varray type strings_array
SET TERM OFF


CREATE OR REPLACE TYPE strings_array AS VARRAY(50) OF VARCHAR2(100); 

/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF