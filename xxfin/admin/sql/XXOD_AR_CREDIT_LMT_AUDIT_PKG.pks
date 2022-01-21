 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF
 SET FEEDBACK OFF
 SET TERM ON

 PROMPT Creating Package Specification XXOD_AR_CREDIT_LMT_AUDIT_PKG
 PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

 CREATE OR REPLACE
 PACKAGE XXOD_AR_CREDIT_LMT_AUDIT_PKG

 -- +===================================================================+
 -- |                  Office Depot - Project Simplify                  |
 -- |                       WIPRO Technologies                          |
 -- +===================================================================+
 -- | Name        : R0429-Credit Limit Change Audit Report              |
 -- |                                                                   |
 -- | Description : This report displays the customer details and the   |
 -- |               credit limit changes of that customer which has     |
 -- |               happened yesterday.                                 |
 -- |Change Record:                                                     |
 -- |===============                                                    |
 -- |Version   Date          Author              Remarks                |
 -- |=======   ==========   =============        =======================|
 -- |1.0       10-MAR-2007  Sailaja              Initial version        |
 -- |                       Wipro Technologies   Added for Defect 4429  |
 -- +===================================================================+
 -- +===================================================================+
 -- | Name        : XXOD_AR_CREDIT_LMT_AUDIT_PKG                 |
 -- | Description : This procedure calculates the oustanding amount     |
 -- |               ,60 + past due, credit limit change and displays the|
 -- |               customer details, credit limit prior, credit limit  |
 -- |               current, credit date changed.                       |
 -- |                                                                   |
 -- +===================================================================+

 AS

 PROCEDURE CREDIT_LIMIT_CHANGE(p_date DATE);

 END XXOD_AR_CREDIT_LMT_AUDIT_PKG;
/
SHOW ERROR
