REM================================================================================================
REM                                 Start Of Script
REM================================================================================================
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |      Oracle NAIO/Office Depot/Consulting Organization                 |
-- +=======================================================================+
-- | Name             :XX_GI_MISC_TXN_SUM_V                                |
-- | Description      :Custom View for Miscellaneous Transaction Details   |
-- |                   as part of E0352_MiscTransaction                    |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author        Remarks                             |
-- |-------  ----------- ------------  -------------------------------     |
-- |Draft1a  04-May-2007 Remya Sasi    Initial Draft Version               |
-- |Draft1b  08-Aug-2007 Remya Sasi    Changes made for CR to include      |
-- |                                   attribute columns                   |
-- |1.0      16-Aug-2007 Remya Sasi    Baselined                           |
-- |1.1      09-Oct-2007 Remya Sasi    Removed hardcoding for 'ODADJ' and  |
-- |                                   added source_code column            |
-- +=======================================================================+


PROMPT
PROMPT Creating or Replacing View xx_gi_misc_txn_dtl_v....
PROMPT

-- ===========================
--  Creating custom View
-- ===========================

CREATE OR REPLACE VIEW xx_gi_misc_txn_dtl_v
(adjustment_header_id
,new_adjustment_number
,legacy_adjustment_number
,comments
,organization_code
,subinventory_code
,item_number
,item_description
,uom
,quantity
,transaction_reason_name
,attribute_category             -- Added by Remya, Draft 1b
,master_attribute1              -- Added by Remya, Draft 1b
,master_attribute2              -- Added by Remya, Draft 1b
,master_attribute3              -- Added by Remya, Draft 1b
,master_attribute4              -- Added by Remya, Draft 1b
,master_attribute5              -- Added by Remya, Draft 1b
,master_attribute6              -- Added by Remya, Draft 1b
,master_attribute7              -- Added by Remya, Draft 1b
,master_attribute8              -- Added by Remya, Draft 1b
,master_attribute9              -- Added by Remya, Draft 1b
,master_attribute10             -- Added by Remya, Draft 1b
,master_attribute11             -- Added by Remya, Draft 1b
,master_attribute12             -- Added by Remya, Draft 1b
,master_attribute13             -- Added by Remya, Draft 1b
,master_attribute14             -- Added by Remya, Draft 1b
,master_attribute15             -- Added by Remya, Draft 1b
,detail_attribute1              -- Added by Remya, Draft 1b
,detail_attribute2              -- Added by Remya, Draft 1b
,detail_attribute3              -- Added by Remya, Draft 1b
,detail_attribute4              -- Added by Remya, Draft 1b
,detail_attribute5              -- Added by Remya, Draft 1b
,detail_attribute6              -- Added by Remya, Draft 1b
,detail_attribute7              -- Added by Remya, Draft 1b
,detail_attribute8              -- Added by Remya, Draft 1b
,detail_attribute9              -- Added by Remya, Draft 1b
,detail_attribute10             -- Added by Remya, Draft 1b
,detail_attribute11             -- Added by Remya, Draft 1b
,detail_attribute12             -- Added by Remya, Draft 1b
,detail_attribute13             -- Added by Remya, Draft 1b
,detail_attribute14             -- Added by Remya, Draft 1b
,detail_attribute15             -- Added by Remya, Draft 1b
,source_code                    -- Added by Remya, V1.1 
,creation_date
,created_by
,last_update_date
,last_update_by
,process_flag
)
AS
SELECT
     XGA.adjustment_header_id
    ,XGA.new_adjustment_number
    ,XGA.legacy_adjustment_number
    ,XGA.comments
    ,MP.organization_code
    ,MMT.subinventory_code
    ,MSI.segment1
    ,MSI.description
    ,MMT.transaction_uom
    ,MMT.transaction_quantity
    ,XGA.transaction_reason_name
    ,XGA.attribute_category         -- Added by Remya, Draft 1b
    ,XGA.attribute1                 -- Added by Remya, Draft 1b
    ,XGA.attribute2                 -- Added by Remya, Draft 1b
    ,XGA.attribute3                 -- Added by Remya, Draft 1b
    ,XGA.attribute4                 -- Added by Remya, Draft 1b
    ,XGA.attribute5                 -- Added by Remya, Draft 1b
    ,XGA.attribute6                 -- Added by Remya, Draft 1b
    ,XGA.attribute7                 -- Added by Remya, Draft 1b
    ,XGA.attribute8                 -- Added by Remya, Draft 1b
    ,XGA.attribute9                 -- Added by Remya, Draft 1b
    ,XGA.attribute10                -- Added by Remya, Draft 1b
    ,XGA.attribute11                -- Added by Remya, Draft 1b
    ,XGA.attribute12                -- Added by Remya, Draft 1b
    ,XGA.attribute13                -- Added by Remya, Draft 1b
    ,XGA.attribute14                -- Added by Remya, Draft 1b
    ,XGA.attribute15                -- Added by Remya, Draft 1b
    ,MMT.attribute1                 -- Added by Remya, Draft 1b
    ,MMT.attribute2                 -- Added by Remya, Draft 1b
    ,MMT.attribute3                 -- Added by Remya, Draft 1b
    ,MMT.attribute4                 -- Added by Remya, Draft 1b
    ,MMT.attribute5                 -- Added by Remya, Draft 1b
    ,MMT.attribute6                 -- Added by Remya, Draft 1b
    ,MMT.attribute7                 -- Added by Remya, Draft 1b
    ,MMT.attribute8                 -- Added by Remya, Draft 1b
    ,MMT.attribute9                 -- Added by Remya, Draft 1b
    ,MMT.attribute10                -- Added by Remya, Draft 1b
    ,MMT.attribute11                -- Added by Remya, Draft 1b
    ,MMT.attribute12                -- Added by Remya, Draft 1b
    ,MMT.attribute13                -- Added by Remya, Draft 1b
    ,MMT.attribute14                -- Added by Remya, Draft 1b
    ,MMT.attribute15                -- Added by Remya, Draft 1b
    ,MMT.source_code                -- Added by Remya, V1.1 
    ,MMT.creation_date
    ,MMT.created_by
    ,MMT.last_update_date
    ,MMT.last_updated_by
    ,'Y' 
FROM
    mtl_material_transactions   MMT
   ,mtl_system_items            MSI
   ,mtl_parameters              MP
   ,xx_gi_adjustments           XGA
WHERE
    MP.organization_id          =   MSI.organization_id 
AND MMT.organization_id         =   MSI.organization_id
AND MMT.inventory_item_id       =   MSI.inventory_item_id
AND MMT.organization_id         =   XGA.organization_id
AND MMT.source_line_id          =   XGA.adjustment_header_id
--AND MMT.source_code             =   'ODADJ' -- Commented by Remya, V1.1
UNION ALL
SELECT
     XGA.adjustment_header_id
    ,XGA.new_adjustment_number
    ,XGA.legacy_adjustment_number
    ,XGA.comments
    ,MP.organization_code
    ,MTI.subinventory_code 
    ,MSI.segment1
    ,MSI.description 
    ,MTI.transaction_uom 
    ,MTI.transaction_quantity 
    ,XGA.transaction_reason_name
    ,XGA.attribute_category             -- Added by Remya, Draft 1b
    ,XGA.attribute1                     -- Added by Remya, Draft 1b
    ,XGA.attribute2                     -- Added by Remya, Draft 1b
    ,XGA.attribute3                     -- Added by Remya, Draft 1b
    ,XGA.attribute4                     -- Added by Remya, Draft 1b
    ,XGA.attribute5                     -- Added by Remya, Draft 1b
    ,XGA.attribute6                     -- Added by Remya, Draft 1b
    ,XGA.attribute7                     -- Added by Remya, Draft 1b
    ,XGA.attribute8                     -- Added by Remya, Draft 1b
    ,XGA.attribute9                     -- Added by Remya, Draft 1b
    ,XGA.attribute10                    -- Added by Remya, Draft 1b
    ,XGA.attribute11                    -- Added by Remya, Draft 1b
    ,XGA.attribute12                    -- Added by Remya, Draft 1b
    ,XGA.attribute13                    -- Added by Remya, Draft 1b
    ,XGA.attribute14                    -- Added by Remya, Draft 1b
    ,XGA.attribute15                    -- Added by Remya, Draft 1b
    ,MTI.attribute1                     -- Added by Remya, Draft 1b
    ,MTI.attribute2                     -- Added by Remya, Draft 1b
    ,MTI.attribute3                     -- Added by Remya, Draft 1b
    ,MTI.attribute4                     -- Added by Remya, Draft 1b
    ,MTI.attribute5                     -- Added by Remya, Draft 1b
    ,MTI.attribute6                     -- Added by Remya, Draft 1b
    ,MTI.attribute7                     -- Added by Remya, Draft 1b
    ,MTI.attribute8                     -- Added by Remya, Draft 1b
    ,MTI.attribute9                     -- Added by Remya, Draft 1b
    ,MTI.attribute10                    -- Added by Remya, Draft 1b
    ,MTI.attribute11                    -- Added by Remya, Draft 1b
    ,MTI.attribute12                    -- Added by Remya, Draft 1b
    ,MTI.attribute13                    -- Added by Remya, Draft 1b
    ,MTI.attribute14                    -- Added by Remya, Draft 1b
    ,MTI.attribute15                    -- Added by Remya, Draft 1b
    ,MTI.source_code                    -- Added by Remya, V1.1 
    ,MTI.creation_date
    ,MTI.created_by
    ,MTI.last_update_date
    ,MTI.last_updated_by
    ,'N'   
FROM
    mtl_transactions_interface  MTI
   ,mtl_system_items            MSI
   ,mtl_parameters              MP
   ,xx_gi_adjustments           XGA 
WHERE
    MP.organization_id          =   MSI.organization_id
AND MTI.organization_id         =   MSI.organization_id
AND MTI.inventory_item_id       =   MSI.inventory_item_id 
AND MTI.source_line_id          =   XGA.adjustment_header_id
AND MTI.organization_id         =   XGA.organization_id; 
--AND MTI.source_code             =   'ODADJ'; -- Commented by Remya, V1.1

/
SHOW ERRORS;

EXIT;
REM=================================================================================================
REM                                   End Of Script
REM=================================================================================================
