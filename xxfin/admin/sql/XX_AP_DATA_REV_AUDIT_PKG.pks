SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_AP_DATA_REV_AUDIT_PKG

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name : AP Data For Reverse Audit                                  |
-- | Rice ID : R1091                                                   |
-- | Description : AP detail to aid with conduction reverse            |
-- |               audits regarding sales tax payments.                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |1.0       10-JAN-2008  Sowmya M S           Initial version        |
-- |                                                                   |
-- +===================================================================+
AS

-- +===================================================================+
-- | Name       : DATA_REV_AUDIT                                       |
-- | Parameters :p_state,p_gl_account,p_location,p_legal entity,       |
-- |             p_from_date,p_to_date,p_vendor_name,p_delimiter,      |
-- |             p_file_path,p_dest_file_path,p_file_name,             |
-- |             p_file_extension                                      |
-- |                                                                   |
-- | Returns    : Return Code                                          |
-- |              Error Message                                        |
-- +===================================================================+

 PROCEDURE DATA_REV_AUDIT(
                             x_error_buff      OUT  VARCHAR2
                            ,x_ret_code        OUT  NUMBER
                            ,p_state           IN   VARCHAR2
                            ,p_gl_account      IN   VARCHAR2
                            ,p_location        IN   VARCHAR2
                            ,p_legal_entity    IN   VARCHAR2
                            ,p_from_date       IN   VARCHAR2
                            ,p_to_date         IN   VARCHAR2
                            ,p_vendor_name     IN   VARCHAR2
                            ,p_delimiter       IN   VARCHAR2
                            ,p_file_path       IN   VARCHAR2
                            ,p_dest_file_path  IN   VARCHAR2
                            ,p_file_name       IN   VARCHAR2
                            ,p_file_extension  IN   VARCHAR2
                            );

-- +===================================================================+
-- | Name       : DATA_REV_AUDIT_WRITE_FILE                            |
-- |                                                                   |
-- | Parameters : lc_valconcat,p_file_path,lc_flag                     |
-- |                                                                   |
-- +===================================================================+

 PROCEDURE DATA_REV_AUDIT_WRITE_FILE(
                                      p_valconcat                 IN VARCHAR2
                                     ,p_file_path                  IN  VARCHAR2
                                     ,p_flag                      IN  VARCHAR2
                                     );

END XX_AP_DATA_REV_AUDIT_PKG;

/
SHOW ERROR
