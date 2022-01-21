SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_PO_MLSS_HDR_PKG                                            
  
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_PO_MLSS_HDR_PKG.pks                              |
-- | Rice ID      :E1252_MultiLocationSupplierSourcing                 |
-- | Description  :This package specification is used to Insert, Update|
-- |               Delete, Lock rows of XX_PO_MLSS_HDR Table           | 
-- |                                                                   |
-- |                                                                   |
-- |                                                                   | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 15-MAR-2007  Hema Chikkanna   Initial draft version       |
-- |1.0      17-MAR-2007  Hema Chikkanna   Baselined after testing     |
-- |1.1      27-APR-2007  Hema Chikkanna   Updated the Comments Section|
-- |                                       as per onsite requirement   |
-- |1.2      18-JUN-2007  Hema Chikkanna   Incorporated the file name  |
-- |                                       change as per onsite        |
-- |                                       requirement                 |
-- |                                                                   |
-- +===================================================================+
AS
-------------------------------------
-- Procedure to insert the row into
-- XX_PO_MLSS_HDR table
-------------------------------------
PROCEDURE insert_row (
                         x_rowid             IN OUT NOCOPY VARCHAR2
                        ,p_mlss_header_id    IN NUMBER
                        ,p_organization_id   IN NUMBER
                        ,p_category          IN VARCHAR2
                        ,p_category_level    IN VARCHAR2
                        ,p_start_date        IN DATE
                        ,p_end_date          IN DATE
                        ,p_imu_amt_pt        IN VARCHAR2
                        ,p_imu_value         IN NUMBER
                        ,p_creation_date     IN DATE
                        ,p_created_by        IN NUMBER
                        ,p_last_update_date  IN DATE
                        ,p_last_updated_by   IN NUMBER
                        ,p_last_update_login IN NUMBER
                     );

-------------------------------------
-- Procedure to lock the row of
-- XX_PO_MLSS_HDR table
-------------------------------------

PROCEDURE lock_row (
                      p_mlss_header_id    IN NUMBER
                     ,p_end_date          IN DATE
                     ,p_imu_amt_pt        IN VARCHAR2
                     ,p_imu_value         IN NUMBER
                   );


-------------------------------------
-- Procedure to update the rows of
-- XX_PO_MLSS_HDR table
-------------------------------------
PROCEDURE update_row (
                       p_mlss_header_id    IN NUMBER
                      ,p_end_date          IN DATE
                      ,p_imu_amt_pt        IN VARCHAR2 
                      ,p_imu_value         IN NUMBER
                      ,p_last_update_date  IN DATE
                      ,p_last_updated_by   IN NUMBER
                      ,p_last_update_login IN NUMBER
                    );

-------------------------------------
-- Procedure to delete rows from
-- XX_PO_MLSS_HDR table
-------------------------------------
PROCEDURE delete_row (
                       p_mlss_header_id IN NUMBER  
                     );

END XX_PO_MLSS_HDR_PKG;
/

SHOW ERRORS

EXIT;