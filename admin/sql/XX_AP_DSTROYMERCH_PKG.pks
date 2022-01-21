SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_AP_DSTROYMERCH_PKG

WHENEVER SQLERROR CONTINUE
CREATE or REPLACE PACKAGE XX_AP_DSTROYMERCH_PKG AUTHID CURRENT_USER
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_AP_DSTROYMERCH_PKG.pks                               |
-- | Description :  Plsql package for Destroyed Merchandised Summary Report                     |
-- | RICE ID     :  R7034 OD: Destroyed Merchandise Summary Report                          |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |1.0       15-Oct-2017 Ragni Gupta	     Initial version                 |
-- +=========================================================================+
AS
P_Frequency varchar2(10);
P_Start_date varchar2(30);
P_End_Date   varchar2(30); 
G_where_clause varchar2(2000) := ' ';

FUNCTION beforeReport RETURN BOOLEAN;

END XX_AP_DSTROYMERCH_PKG;
/
SHOW ERRORS;