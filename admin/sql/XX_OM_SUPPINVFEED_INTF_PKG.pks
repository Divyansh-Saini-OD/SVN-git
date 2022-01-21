SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_SUPPINVFEED_INTF_PKG
-- +===================================================================+
-- | Name  :    XX_OM_SUPPINVFEED_INTF_PKG                             |
-- | RICE ID :  I1186                                                  |
-- | Description      : This package contains the following            |
-- |                    procedures                                     |
-- |                    1)  PROCESS_FEED_MASTER                        |
-- |                        Read feed from work table and notifies     |
-- |                        supply management team about the suppliers |
-- |                        who did not send feed and checks if the    |
-- |                        supplier is active and then spawns the     |
-- |                        child concurrent program for those active  |
-- |                        suppliers                                  |
-- |                                                                   |
-- |                    2)  PROCESS_FEED_CHILD                         |
-- |                        Perform ITEM,UOM,VPC validatiions,         | 
-- |                        decrement quantity,calculate available to  |
-- |                        resreve and update/insert data into the    |
-- |                        production table                           |
-- |                                                                   |
-- |                    3)  PURGE_WORKTABLE_SKUS                       |
-- |                        Purges successfully processed records from |
-- |                        work table and error records if they have  |
-- |                        threshold days                             |
-- |                                                                   |
-- |                    4)  PURGE_INACTIVE_PROD_SKUS                   |
-- |                        Purges inactive SKUs from production table |
-- |                        based on the threshold days                |
-- |                                                                   |
-- |                    5)  SYNC_ONHOLD_QTY                            |
-- |                        Synchronizes on hold quantity in production|
-- |                        table and sales order tables               |
-- |                                                                   |
-- |                    6)  WRITE_LOG                                  |
-- |                        This procedure is used to write into       |
-- |                        the log file                               |
-- |                                                                   |
-- |                    7)  STRIP_CHAR                                 |
-- |                        Strips non alpha numeric characters from   |
-- |                        the given string                           |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       06-July-07  Aravind A.       Initial Version             |
-- +===================================================================+
AS
-- +===================================================================+
-- | Name  : PROCESS_FEED_MASTER                                       |
-- | Description   : Read feed from work table and notifies            |
-- |                 supply management team about the suppliers        |
-- |                 who did not send feed and checks if the           |
-- |                 supplier is active and then spawns the            |
-- |                 child concurrent program for those active         |
-- |                 suppliers                                         |
-- |                                                                   |
-- | Parameters :      NONE                                            |
-- |                                                                   |
-- |                                                                   |
-- | Returns :         x_errbuff                                       |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+
PROCEDURE PROCESS_FEED_MASTER(                              
                              x_errbuff         OUT NOCOPY VARCHAR2
                              ,x_retcode        OUT NOCOPY VARCHAR2
                              ,p_debug_flag     IN  VARCHAR2      DEFAULT 'N'
                             );

-- +===================================================================+
-- | Name  : PROCESS_FEED_CHILD                                        |
-- | Description   : Perform ITEM,UOM,VPC validatiions,                |
-- |                 decrement quantity,calculate available to         |
-- |                 resreve and update/insert data into the           |
-- |                 production table                                  |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :      p_supplier_name                                 |
-- |                                                                   |
-- |                                                                   |
-- | Returns :         x_errbuff                                       |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE PROCESS_FEED_CHILD(
                             x_errbuff          OUT NOCOPY VARCHAR2
                             ,x_retcode         OUT NOCOPY VARCHAR2
                             ,p_supplier_number IN  VARCHAR2
                             ,p_supplier_id     IN  NUMBER
                             ,p_debug_flag      IN  VARCHAR2   DEFAULT 'N'
                             );
-- +===================================================================+
-- | Name  :   PURGE_WORKTABLE_SKUS                                    |
-- | Description   : Purges successfully processed records from        |
-- |                 work table and error records if they have         |
-- |                 threshold days                                    |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :      p_supplier_name                                 |
-- |                                                                   |
-- |                                                                   |
-- | Returns :         x_errbuff                                       |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE PURGE_WORKTABLE_SKUS(                               
                               x_errbuff            OUT NOCOPY VARCHAR2
                               ,x_retcode           OUT NOCOPY VARCHAR2
                               ,p_supplier_number   IN  VARCHAR2   DEFAULT NULL
                               ,p_supplier_id       IN  NUMBER     DEFAULT NULL
                               ,p_debug_flag        IN  VARCHAR2   DEFAULT 'N'
                               );

-- +===================================================================+
-- | Name  :   PURGE_INACTIVE_PROD_SKUS                                |
-- | Description   : Purges inactive SKUs from production table        |
-- |                 based on the threshold days                       |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :      p_supplier_name                                 |
-- |                                                                   |
-- |                                                                   |
-- | Returns :         x_errbuff                                       |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE PURGE_INACTIVE_PROD_SKUS(                                   
                                   x_errbuff            OUT NOCOPY VARCHAR2
                                   ,x_retcode           OUT NOCOPY VARCHAR2
                                   ,p_supplier_number   IN  VARCHAR2   DEFAULT NULL
                                   ,p_all_rows          IN  VARCHAR2   DEFAULT 'N'
                                   ,p_debug_flag        IN  VARCHAR2   DEFAULT 'N'
                                  );

-- +===================================================================+
-- | Name  :   SYNC_ONHOLD_QTY                                         |
-- | Description   : Synchronizes on hold quantity in production       |
-- |                 table and sales order tables                      |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :      p_supplier_name                                 |
-- |                   p_item_name                                     |
-- |                                                                   |
-- | Returns :         x_errbuff                                       |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE SYNC_ONHOLD_QTY(                          
                          x_errbuff                 OUT NOCOPY VARCHAR2
                          ,x_retcode                OUT NOCOPY VARCHAR2
                          ,p_supplier_number        IN           VARCHAR2
                          ,p_item_number            IN           VARCHAR2   DEFAULT NULL
                          ,p_debug_flag             IN           VARCHAR2   DEFAULT 'N'
                         );

-- +===================================================================+
-- | Name  :   WRITE_LOG                                               |
-- | Description   : This procedure is used to write into the log file |
-- |                                                                   |
-- | Parameters :      p_log_msg                                       |
-- |                                                                   |
-- |                                                                   |
-- | Returns :         x_errbuff                                       |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE WRITE_LOG(
                    p_log_msg           IN           VARCHAR2
                    ,p_debug_flag       IN           VARCHAR2
                    );

-- +===================================================================+
-- | Name  :   STRIP_CHAR                                              |
-- | Description   : This function is used to strip non alpha numeric  |
-- |                 characters from the input and returns the         |
-- |                 stripped string                                   |
-- |                                                                   |
-- | Parameters :      p_log_msg                                       |
-- |                                                                   |
-- |                                                                   |
-- | Returns :         x_errbuff                                       |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+

FUNCTION STRIP_CHAR(
                    p_input             IN           VARCHAR2
                    )
RETURN VARCHAR2;

END XX_OM_SUPPINVFEED_INTF_PKG;
/
SHOW ERROR