CREATE OR REPLACE PACKAGE XX_INV_ITEM_IN_PKG AUTHID CURRENT_USER
--Version 1.1
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- +=============================================================================+
-- |Package Name : XX_INV_ITEM_IN_PKG                                            |
-- |Purpose      : This package contains three procedures that interface the data|
-- |                 from RMS to EBS.                                            |
-- |                                                                             |
-- |Tables Accessed :                                                            |
-- |Access Type----------------- (I - Insert, S - Select, U - Update, D - Delete)|
-- |                                                                             |
-- |MTL_SYSTEM_ITEMS_B          : I,S,U                                          |
-- |MTL_ITEM_CATEGORIES         : I,U                                            |
-- |MTL_CATEGORIES_B            : S                                              |
-- |MTL_CATEGORY_SETS           : S                                              |
-- |MTL_PARAMETERS              : S                                              |
-- |HR_ORGAINZATION_UNTIS       : S                                              |
-- |MTL_CATEGORY_SET_VALID_CATS : S                                              |
-- |FND_ID_FLEX_STRUCTURES_VL   : S                                              |
-- |HR_LOOKUPS                  : S                                              |
-- |                                                                             |
-- |Change History                                                               |
-- |                                                                             |
-- |Ver   Date          Author           Description                             |
-- |---   -----------   ---------------  -----------------------------           |
-- |1.0   23-May-2007   Arun Andavar     Original Code                           |
-- |1.1   27-Jun-2007   Susheel/Jayshree Reviewed and updated                    |
-- |1.2   17-Sep-2007   Basu Patil	 Added new parameter RMS Timestamp     	 |
-- |					 in INTERFACE_ITEM_DATA  procedure       |
-- |					 to maintain RMS time stamp in EBS	 |
-- +=============================================================================+
IS
   -- -----------------------------------------------------
   -- User defined record type that stores item information
   -- -----------------------------------------------------
   TYPE g_master_itm_hdr_rec_type
   IS
   RECORD
      (description   VARCHAR2(500) --Item Description
      ,item_number   VARCHAR2(40)  --Item Number
      ,tax_category  VARCHAR2(50)  --Tax Code
      ,item_type     VARCHAR2(30)  --Item Type
      ,item_status   VARCHAR2(10)  --Inventory Item Status Code
      ,base_uom_code VARCHAR2(3)   --Primary UOM Code
      ,sellable      VARCHAR2(1)   --Purchasing Item Flag
      ,orderable_ind VARCHAR2(1)   --Customer Order Flag
      );
   -- --------------------------------------------------------------
   -- User defined record type that stores item category information
   -- --------------------------------------------------------------
   TYPE g_master_itm_category_rec_type
   IS
   RECORD
      (dept                VARCHAR2(40)--Segment3 of MTL_CATEGORIES_B
      ,class               VARCHAR2(40)--Segment4 of MTL_CATEGORIES_B
      ,subclass            VARCHAR2(40)--Segment5 of MTL_CATEGORIES_B
      ,private_brand_label VARCHAR2(40)--Segment1 of MTL_CATEGORIES_B
      );

   -- ---------------------------------------------------------------------------
   -- User defined record type that stores location and its attribute information
   -- ---------------------------------------------------------------------------
   TYPE g_location_rec
   IS
   RECORD
      (attribute       xx_inv_item_org_attributes%ROWTYPE
      ,location        hr_organization_units.attribute1%TYPE
      ,item_status     mtl_system_items_b.inventory_item_status_code%TYPE
      );

   -- +================================================================================+
   -- |Name       : INTERFACE_ITEM_DATA                                                |
   -- |                                                                                |
   -- |Description: This procedure is the main procedure invoked by BPEL               |
   -- |              process. XML message fields are mapped to the                     |
   -- |              respective columns of this procedure parameters.                  |
   -- |              Depending upon the parameters passed to this procedure            |
   -- |              item is either created/updated in master org (or)                 |
   -- |              assigned to other organizations and category assignment           |
   -- |              is created/updated and finally attributes are                     |
   -- |              created/updated.                                                  |
   -- |                                                                                |
   -- |Parameters : p_actionexpression         IN VARCHAR2                             |
   -- |             p_reason_code              IN VARCHAR2                             |
   -- |             p_master_item_hdr_rec      IN g_master_item_hdr_rec                |
   -- |             p_master_item_category_rec IN g_master_item_category_rec           |
   -- |             p_master_item_attri_rec    IN xx_inv_item_master_attributes%ROWTYPE|
   -- |             p_location_rec             IN g_location_rec                       |
   -- |             x_message_code             OUT NUMBER                              |
   -- |             x_message_data             OUT VARCHAR2                            |
   -- |                                                                                |
   -- +================================================================================+
   PROCEDURE INTERFACE_ITEM_DATA
      (p_actionexpression         IN VARCHAR2
      ,p_reason_code              IN VARCHAR2
      ,p_rms_timestamp            IN VARCHAR2
      ,p_master_item_hdr_rec      IN g_master_itm_hdr_rec_type
      ,p_master_item_category_rec IN g_master_itm_category_rec_type
      ,p_master_item_attri_rec    IN xx_inv_item_master_attributes%ROWTYPE
      ,p_location_rec             IN g_location_rec
      ,x_message_code             OUT NUMBER
      ,x_message_data             OUT VARCHAR2
      );
END XX_INV_ITEM_IN_PKG;
/

