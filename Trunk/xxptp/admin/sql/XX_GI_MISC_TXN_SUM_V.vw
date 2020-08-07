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
-- | Description      :Custom View for Miscellaneous Transactions Summary  |
-- |                   as part of E0352_MiscTransaction                    |                          |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author        Remarks                             |
-- |-------  ----------- ------------  -------------------------------     |
-- |Draft1a  04-May-2007 Remya Sasi    Initial Draft Version               |
-- |Draft1b  08-Aug-2007 Remya Sasi    Changes made to include attribute   |
-- |                                   columns                             |
-- |1.0      16-Aug-2007 Remya Sasi    Baselined                           |
-- |1.1      09-Oct-2007 Remya Sasi    Removed 'ODADJ' hardcoding and added|
-- |                                   source_code column                  |
-- +=======================================================================+



PROMPT
PROMPT Creating or Replacing View xx_gi_misc_txn_sum_v....
PROMPT

-- ===========================
--  Creating custom View
-- ===========================

CREATE OR REPLACE VIEW xx_gi_misc_txn_sum_v
(adjustment_header_id
,new_adjustment_number
,legacy_adjustment_number
,comments
,reference
,organization_code
,subinventory_code
,item_number
,item_description
,uom
,net_quantity
,transaction_reason_name
,attribute_category      -- Added by Remya, Draft 1b, 08-Aug-07
,attribute1              -- Added by Remya, Draft 1b, 08-Aug-07
,attribute2              -- Added by Remya, Draft 1b, 08-Aug-07
,attribute3              -- Added by Remya, Draft 1b, 08-Aug-07
,attribute4              -- Added by Remya, Draft 1b, 08-Aug-07
,attribute5              -- Added by Remya, Draft 1b, 08-Aug-07
,attribute6              -- Added by Remya, Draft 1b, 08-Aug-07
,attribute7              -- Added by Remya, Draft 1b, 08-Aug-07
,attribute8              -- Added by Remya, Draft 1b, 08-Aug-07
,attribute9              -- Added by Remya, Draft 1b, 08-Aug-07
,attribute10             -- Added by Remya, Draft 1b, 08-Aug-07
,attribute11             -- Added by Remya, Draft 1b, 08-Aug-07
,attribute12             -- Added by Remya, Draft 1b, 08-Aug-07
,attribute13             -- Added by Remya, Draft 1b, 08-Aug-07
,attribute14             -- Added by Remya, Draft 1b, 08-Aug-07
,attribute15             -- Added by Remya, Draft 1b, 08-Aug-07
,source_code             -- Added by Remya, V1.1 
,process_flag
)
AS
SELECT
    XGA.adjustment_header_id
    ,XGA.new_adjustment_number
    ,XGA.legacy_adjustment_number
    ,XGA.comments
    ,XGA.reference
    ,MP.organization_code
    ,MMT.subinventory_code 
    ,MSI.segment1
    ,MSI.description 
    ,MMT.transaction_uom 
    ,SUM(MMT.transaction_quantity) 
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
    ,MMT.source_code                -- Added by Remya, V1.1
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
GROUP BY
     XGA.adjustment_header_id
    ,XGA.new_adjustment_number
    ,XGA.legacy_adjustment_number
    ,XGA.comments
    ,XGA.reference
    ,MP.organization_code
    ,MMT.subinventory_code 
    ,MSI.segment1
    ,MSI.description 
    ,MMT.transaction_uom
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
    ,MMT.source_code                -- Added by Remya, V1.1
UNION ALL
SELECT
     XGA.adjustment_header_id
    ,XGA.new_adjustment_number
    ,XGA.legacy_adjustment_number
    ,XGA.comments
    ,XGA.reference
    ,MP.organization_code
    ,MTI.subinventory_code
    ,MSI.segment1
    ,MSI.description 
    ,MTI.transaction_uom 
    ,SUM(MTI.transaction_quantity)
    ,XGA.transaction_reason_name            
    ,XGA.attribute_category                 -- Added by Remya, Draft 1b
    ,XGA.attribute1                         -- Added by Remya, Draft 1b
    ,XGA.attribute2                         -- Added by Remya, Draft 1b
    ,XGA.attribute3                         -- Added by Remya, Draft 1b
    ,XGA.attribute4                         -- Added by Remya, Draft 1b
    ,XGA.attribute5                         -- Added by Remya, Draft 1b
    ,XGA.attribute6                         -- Added by Remya, Draft 1b
    ,XGA.attribute7                         -- Added by Remya, Draft 1b
    ,XGA.attribute8                         -- Added by Remya, Draft 1b
    ,XGA.attribute9                         -- Added by Remya, Draft 1b
    ,XGA.attribute10                        -- Added by Remya, Draft 1b
    ,XGA.attribute11                        -- Added by Remya, Draft 1b
    ,XGA.attribute12                        -- Added by Remya, Draft 1b
    ,XGA.attribute13                        -- Added by Remya, Draft 1b
    ,XGA.attribute14                        -- Added by Remya, Draft 1b
    ,XGA.attribute15                        -- Added by Remya, Draft 1b
    ,MTI.source_code                        -- Added by Remya, V1.1 
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
AND MTI.organization_id         =   XGA.organization_id 
--AND MTI.source_code            =   'ODADJ' -- Commented by Remya, V1.1
GROUP BY
     XGA.adjustment_header_id
    ,XGA.new_adjustment_number
    ,XGA.legacy_adjustment_number
    ,XGA.comments
    ,XGA.reference
    ,MP.organization_code
    ,MTI.subinventory_code
    ,MSI.segment1
    ,MSI.description 
    ,MTI.transaction_uom
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
    ,MTI.source_code                -- Added by Remya, V1.1
    
/
SHOW ERRORS;

EXIT;
REM=================================================================================================
REM                                   End Of Script
REM=================================================================================================
