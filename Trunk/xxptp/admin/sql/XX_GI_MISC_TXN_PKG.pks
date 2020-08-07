SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_GI_MISC_TXN_PKG AUTHID CURRENT_USER 
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_GI_MISC_TXN_PKG                                                   |
-- | Description      : Package spec for E0352_MiscTransaction                               |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========       =============    ========================                    |
-- |Draft 1a   03-MAY-2007       Remya Sasi       Initial draft version                      |
-- |Draft 1b   08-Aug-2007       Remya Sasi       Changes made for CR to include p_attribute1|
-- |                                              to 15 and p_attribute_category parameters  |
-- |1.0        16-Aug-2007       Remya Sasi       Baselined                                  |
-- |1.1        07-Sep-2007       Remya Sasi       Incorporated changes for CR. Added comments|
-- |                                              to indicate truncation of API parameters   |
-- |                                              during insert/update of xx_gi_adjustments  |
-- +=========================================================================================+
AS

TYPE adj_lines_rec_type IS RECORD
        ( subinventory_code        VARCHAR2(10)
         ,item_number              VARCHAR2(50)
         ,quantity                 NUMBER
         ,uom                      VARCHAR2(3)
         ,currency_code            VARCHAR2(30)
         ,currency_conversion_type VARCHAR2(30)
         ,conversion_rate          NUMBER
         ,transaction_reference    VARCHAR2(240)
         ,transaction_cost         NUMBER
         ,attribute_category       VARCHAR2(30)
         ,attribute1               VARCHAR2(150)
         ,attribute2               VARCHAR2(150)
         ,attribute3               VARCHAR2(150)
         ,attribute4               VARCHAR2(150)
         ,attribute5               VARCHAR2(150)
         ,attribute6               VARCHAR2(150)
         ,attribute7               VARCHAR2(150)
         ,attribute8               VARCHAR2(150)
         ,attribute9               VARCHAR2(150)
         ,attribute10              VARCHAR2(150)
         ,attribute11              VARCHAR2(150)
         ,attribute12              VARCHAR2(150)
         ,attribute13              VARCHAR2(150)
         ,attribute14              VARCHAR2(150)
         ,attribute15              VARCHAR2(150)
            );
            
TYPE adj_lines_tbl IS TABLE OF adj_lines_rec_type INDEX BY BINARY_INTEGER;

PROCEDURE Process_Misc_Txn(
                     p_adjustment_number     IN OUT  VARCHAR2
                    ,p_legacy_adj_type_comb  IN      VARCHAR2
                    ,p_entered_user_id       IN      VARCHAR2 -- Truncated to 15 char during insert into table
                    ,p_user_id               IN      NUMBER
                    ,p_comment               IN      VARCHAR2 -- Truncated to 200 char during insert/update of table
                    ,p_reference             IN      VARCHAR2 -- Truncated to 200 char during insert/update of table
                    ,p_action                IN      VARCHAR2
                    ,p_organization_code     IN      VARCHAR2
                    ,p_source_code           IN      VARCHAR2
                    ,p_commit_flag           IN      VARCHAR2
                    ,p_attribute_category    IN      VARCHAR2 -- Truncated to 150 char during insert into table
                    ,p_attribute1            IN      VARCHAR2 -- Truncated to 150 char during insert into table
                    ,p_attribute2            IN      VARCHAR2 -- Truncated to 150 char during insert into table
                    ,p_attribute3            IN      VARCHAR2 -- Truncated to 150 char during insert into table
                    ,p_attribute4            IN      VARCHAR2 -- Truncated to 150 char during insert into table
                    ,p_attribute5            IN      VARCHAR2 -- Truncated to 150 char during insert into table
                    ,p_attribute6            IN      VARCHAR2 -- Truncated to 150 char during insert into table
                    ,p_attribute7            IN      VARCHAR2 -- Truncated to 150 char during insert into table
                    ,p_attribute8            IN      VARCHAR2 -- Truncated to 150 char during insert into table
                    ,p_attribute9            IN      VARCHAR2 -- Truncated to 150 char during insert into table
                    ,p_attribute10           IN      VARCHAR2 -- Truncated to 150 char during insert into table
                    ,p_attribute11           IN      VARCHAR2 -- Truncated to 150 char during insert into table
                    ,p_attribute12           IN      VARCHAR2 -- Truncated to 150 char during insert into table
                    ,p_attribute13           IN      VARCHAR2 -- Truncated to 150 char during insert into table
                    ,p_attribute14           IN      VARCHAR2 -- Truncated to 150 char during insert into table
                    ,p_attribute15           IN      VARCHAR2 -- Truncated to 150 char during insert into table
                    ,p_adjustment_lines_tbl  IN      adj_lines_tbl
                    ,x_error_code            OUT     NUMBER
                    ,x_error_message         OUT     VARCHAR2
                    );
    

END XX_GI_MISC_TXN_PKG;

/
SHOW ERRORS;
EXIT;