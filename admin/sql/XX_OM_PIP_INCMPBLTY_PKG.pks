SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_PIP_INCMPBLTY_PKG                                                
  
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name         :XX_OM_PIP_INCMPBLTY_PKG                             |
-- | Rice ID      :E1259_PIPCampaignDefinition                         |
-- | Description  :This package specification is used to Insert,Update |
-- |               and Lock rows of XX_OM_PIP_INCOMPATIBILITY Table    | 
-- |                                                                   |
-- |                                                                   |
-- |                                                                   | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |Draft1A   28-MAR-2007 Hema Chikkanna   Initial draft version       |
-- |1.0       18-APR-2007 Hema Chikkanna   Baselined after testing     |
-- |1.1       27-APR-2007 Hema Chikkanna   Updated the Comments Section|
-- |                                       as per onsite requirement   |
-- |1.2      14-JUN-2007  Hema Chikkanna   Incorporated the file name  |
-- |                                       change as per onsite        |
-- |                                       requirement                 |
-- +===================================================================+
AS
-------------------------------------
-- Procedure to insert the row into
-- XX_OM_PIP_INCOMPATIBILITY table
-------------------------------------
PROCEDURE insert_row (
             x_rowid                    IN OUT NOCOPY VARCHAR2
            ,p_insert_item_id           IN NUMBER  
            ,p_incompatible_item_id     IN NUMBER  
            ,p_active_flag              IN VARCHAR2
            ,p_creation_date            IN DATE
            ,p_created_by               IN NUMBER
            ,p_last_update_date         IN DATE
            ,p_last_updated_by          IN NUMBER
            ,p_last_update_login        IN NUMBER
          ) ;

-------------------------------------
-- Procedure to lock the row of
-- XX_OM_PIP_INCOMPATIBILITY table
-------------------------------------

PROCEDURE lock_row (
              x_rowid                    IN VARCHAR2
             ,p_insert_item_id           IN NUMBER  
             ,p_incompatible_item_id     IN NUMBER  
             ,p_active_flag              IN VARCHAR2
            );


-------------------------------------
-- Procedure to update the rows of
-- XX_OM_PIP_INCOMPATIBILITY table
-------------------------------------
PROCEDURE update_row (
            x_rowid                    IN VARCHAR2 
           ,p_insert_item_id           IN NUMBER  
           ,p_incompatible_item_id     IN NUMBER  
           ,p_active_flag              IN VARCHAR2
           ,p_last_update_date         IN DATE
           ,p_last_updated_by          IN NUMBER
           ,p_last_update_login        IN NUMBER
        );


END XX_OM_PIP_INCMPBLTY_PKG;
/

SHOW ERRORS

EXIT;