SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_PIP_INST_CNT_PKG                                                
  
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_OM_PIP_INST_CNT_PKG.pks                          |
-- | Rice ID      :E1259_PIPCampaignDefinition                         |
-- | Description  :This package specification is used to Insert,Update |
-- |               and Lock rows of XX_OM_PIP_INSERT_COUNT Table       | 
-- |                                                                   |
-- |                                                                   |
-- |                                                                   | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |Draft1A  28-MAR-2007  Hema Chikkanna   Initial draft version       |
-- |1.0      18-APR-2007  Hema Chikkanna   Baselined after testing     |
-- |1.1      27-APR-2007  Hema Chikkanna   Updated the Comments Section|
-- |                                       as per onsite requirement   |
-- |1.2      14-JUN-2007  Hema Chikkanna   Incorporated the file name  |
-- |                                       change as per onsite        |
-- |                                       requirement                 |
-- +===================================================================+
AS
-------------------------------------
-- Procedure to insert the row into
-- XX_OM_PIP_INSERT_COUNT table
-------------------------------------
PROCEDURE insert_row (
                         x_rowid                    IN OUT NOCOPY VARCHAR2
                        ,p_ship_from_org_id         IN NUMBER
                        ,p_max_csc_count            IN NUMBER
                        ,p_csc_count                IN NUMBER
                        ,p_count_last_update_time   IN DATE
                        ,p_creation_date            IN DATE
                        ,p_created_by               IN NUMBER
                        ,p_last_update_date         IN DATE
                        ,p_last_updated_by          IN NUMBER
                        ,p_last_update_login        IN NUMBER
                     );

-------------------------------------
-- Procedure to lock the row of
-- XX_OM_PIP_INSERT_COUNT table
-------------------------------------

PROCEDURE lock_row (
                      x_rowid                    IN VARCHAR2
                     ,p_ship_from_org_id         IN NUMBER
                     ,p_max_csc_count            IN NUMBER  
                     ,p_csc_count                IN NUMBER
                     ,p_count_last_update_time   IN DATE
                   );


-------------------------------------
-- Procedure to update the rows of
-- XX_OM_PIP_INSERT_COUNT table
-------------------------------------
PROCEDURE update_row (
                        x_rowid                    IN VARCHAR2
                       ,p_ship_from_org_id         IN NUMBER
                       ,p_max_csc_count            IN NUMBER  
                       ,p_csc_count                IN NUMBER
                       ,p_count_last_update_time   IN DATE
                       ,p_last_update_date         IN DATE
                       ,p_last_updated_by          IN NUMBER
                       ,p_last_update_login        IN NUMBER
                     );


END XX_OM_PIP_INST_CNT_PKG;
/

SHOW ERRORS

EXIT;