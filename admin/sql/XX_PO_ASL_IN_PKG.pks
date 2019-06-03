CREATE OR REPLACE PACKAGE APPS.XX_PO_ASL_IN_PKG
--Version 1.0
-- +===================================================================== =======+
-- |                  Office Depot - Project Simplify                            |
-- |                                                                             |
-- +=============================================================================+
-- +=============================================================================+
-- |Package Name : XX_PO_ASL_CONV_PKG                                            |
-- |Purpose      : This package contains  procedures     used for  data          |
-- |               from RMS to EBS.                                              |
-- |                                                                             |
-- |Tables Accessed :                                                            |
-- |Access Type----------------- (I - Insert, S - Select, U - Update, D - Delete)|
-- |                                                                             |
-- |PO_APPROVED_SUPPLIER_LIST   : I,S,U                                          |
-- |PO_ASL_ATTRIBUTES           : I,S,U                                          |
-- |PO_ASL_DOCUMENTS            : I,S,U                                          |
-- |                                                                             |
-- |Change History                                                               |
-- |                                                                             |
-- |Ver   Date          Author           Description                             |
-- |---   -----------   ---------------  -----------------------------           |
-- |1.0   04-Oct-2007   Basu Patil     Original Code                             |
--
-- +=============================================================================+
IS
   -- -----------------------------------------------------
   -- User defined record type that stores ASL ITEM SUPP information
   -- -----------------------------------------------------
   TYPE g_item_supp_rec_type
   IS
   RECORD
      (
  	  ITEM                      MTL_SYSTEM_ITEMS_B.SEGMENT1%TYPE,
   	  SUPPLIER                  PO_VENDOR_SITES_ALL.attribute9%TYPE,
   	  PRIMARY_SUPP_IND          PO_APPROVED_SUPPLIER_LIST.attribute6%TYPE,
   	  VPN                       PO_APPROVED_SUPPLIER_LIST.PRIMARY_VENDOR_ITEM%TYPE,
   	  CARCINOGENIC_FLG          XXPO_ITEM_SUPP_RMS_ATTRIBUTE.CARCINOGENIC_FLG%TYPE,
   	  DROP_SHIP_CD              XXPO_ITEM_SUPP_RMS_ATTRIBUTE.DROP_SHIP_CD%TYPE,
   	  GOVT_COMPLIANCE_CD        XXPO_ITEM_SUPP_RMS_ATTRIBUTE.GOVT_COMPLIANCE_CD%TYPE,
   	  HAZARDOUS_FLG             XXPO_ITEM_SUPP_RMS_ATTRIBUTE.HAZARDOUS_FLG%TYPE,
   	  HS_TARIFF_NBR             XXPO_ITEM_SUPP_RMS_ATTRIBUTE.CANADIAN_HS_TARRIFF_NBR%TYPE,
	  MINORITY_BUS_FLG          VARCHAR2(3),
   	  NON_SHIPPABLE_INNER_QTY   XXPO_ITEM_SUPP_RMS_ATTRIBUTE.NON_SHIPPABLE_INNER_QT%TYPE,
   	  VENDOR_DESIGN_ID          XXPO_ITEM_SUPP_RMS_ATTRIBUTE.VENDOR_DESIGN_ID%TYPE,
	  RANK_PRIORITY             XXPO_ITEM_SUPP_RMS_ATTRIBUTE.RANK_PRIORITY%TYPE,
	  BACKORDERS_ALLOWED        XXPO_ITEM_SUPP_RMS_ATTRIBUTE.BACKORDERS_ALLOWED%TYPE
      );
 -- --------------------------------------------------------------
 -- User defined record type that stores ITEM_SUPP_COO  information
 -- --------------------------------------------------------------
   TYPE g_item_supp_coo_rec_type
   IS
   RECORD
      (
    	ITEM                         MTL_SYSTEM_ITEMS_B.SEGMENT1%TYPE,
    	SUPPLIER                     PO_VENDOR_SITES_ALL.attribute9%TYPE,
    	CNTRY_OF_ORIGIN_CD           PO_ASL_ATTRIBUTES.COUNTRY_OF_ORIGIN_CODE%TYPE
      );
 -- ---------------------------------------------------------------------------
 -- User defined record type that stores ITEM_SUPP_UPC attribute information
 -- ---------------------------------------------------------------------------
   TYPE g_item_supp_upc_rec_type
   IS
   RECORD
      (ITEM            MTL_SYSTEM_ITEMS_B.SEGMENT1%TYPE,
       SUPPLIER        PO_VENDOR_SITES_ALL.attribute9%TYPE,
       UPC             XX_PO_ITEM_SUPP_UPC.UPC%TYPE
      );
    -- ---------------------------------------------------------------------------
   -- User defined record type that stores ITEM_SUPP_COUNTRY attribute information
   -- ---------------------------------------------------------------------------
  TYPE g_item_supp_country_rec_type
   IS
   RECORD
      (ITEM                 MTL_SYSTEM_ITEMS_B.SEGMENT1%TYPE,
       SUPPLIER             PO_VENDOR_SITES_ALL.attribute9%TYPE,
       ORIGIN_COUNTRY_ID    VARCHAR2(9),
       HI                   XXPO_ITEM_SUPP_RMS_ATTRIBUTE.HI%TYPE,
       INNER_PACK_SIZE      XXPO_ITEM_SUPP_RMS_ATTRIBUTE.INNER_PACK_SIZE%TYPE,
       MAX_ORDER_QTY        XXPO_ITEM_SUPP_RMS_ATTRIBUTE.MAX_ORDER_QTY%TYPE,
       MIN_ORDER_QTY        XXPO_ITEM_SUPP_RMS_ATTRIBUTE.MIN_ORDER_QTY%TYPE,
       SUPP_PACK_SIZE       XXPO_ITEM_SUPP_RMS_ATTRIBUTE.SUPP_PACK_SIZE%TYPE,
       TI                   XXPO_ITEM_SUPP_RMS_ATTRIBUTE.TI%TYPE
      );
 -- ---------------------------------------------------------------------------
   -- User defined record type that stores ITEM_SUPP_COUNTRY_DIM attribute information
   -- ---------------------------------------------------------------------------
  TYPE g_item_supp_dim_rec_type
   IS
   RECORD
      (ITEM                 MTL_SYSTEM_ITEMS_B.SEGMENT1%TYPE,
       SUPPLIER             PO_VENDOR_SITES_ALL.attribute9%TYPE,
       ORIGIN_COUNTRY       VARCHAR2(9),
       DIM_OBJECT           XX_PO_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE,
       HEIGHT               XX_PO_SUPP_COUNTRY_DIM.HEIGHT%TYPE,
       LENGTH               XX_PO_SUPP_COUNTRY_DIM.LENGTH%TYPE,
       LWH_UOM              XX_PO_SUPP_COUNTRY_DIM.LHW_UOM%TYPE,
       WEIGHT               XX_PO_SUPP_COUNTRY_DIM.WEIGHT%TYPE,
       WEIGHT_UOM           XX_PO_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE,
       WIDTH                XX_PO_SUPP_COUNTRY_DIM.WEIGHT%TYPE
      );
-- ---------------------------------------------------------------------------
-- User defined record type that stores ITEM_SUPP_COUNTRY_LOC attribute information
-- ---------------------------------------------------------------------------
TYPE g_item_supp_loc_rec_type
   IS
   RECORD
      (ITEM                  MTL_SYSTEM_ITEMS_B.SEGMENT1%TYPE,
       SUPPLIER              PO_VENDOR_SITES_ALL.attribute9%TYPE,
       ORIGIN_COUNTRY_ID     VARCHAR2(9),
       LOC                   HR_ALL_ORGANIZATION_UNITS.ATTRIBUTE1%TYPE,
       OD_GSS_REPL_FLG       PO_APPROVED_SUPPLIER_LIST.ATTRIBUTE7%TYPE,
       PICKUP_LEAD_TIME      PO_APPROVED_SUPPLIER_LIST.ATTRIBUTE8%TYPE
     );
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------

   -- +================================================================================+
   -- |Name       : INTERFACE_ITEM_DATA                                                |
   -- |                                                                                |
   -- |Description: This procedure is the main procedure invoked by BPEL               |
   -- |              process. XML message fields are mapped to the                     |
   -- |              respective columns of this procedure parameters.                  |
   -- |              Depending upon the parameters passed to this procedure            |
   -- |              ASL details are  either created/updated.                          |
   -- |                                                                                |
   -- |                                                                                |
   -- |                                                                                |
   -- |                                                                                |
   -- |Parameters : p_actionexpression             IN VARCHAR2                         |
   -- |             p_reason_code                  IN VARCHAR2  					   |
   -- |             p_rms_timestamp                IN VARCHAR2 						   |
   -- |             p_item_supp_rec                IN g_item_supp_rec_type			   |
   -- |              p_item_supp_coo_rec            IN g_item_supp_coo_rec_type		   |
   -- |              p_item_supp_upc_rec            IN g_item_supp_upc_rec_type		   |
   -- |              p_item_supp_country_rec        IN g_item_supp_country_rec_type	   |
   -- |            p_item_supp_country_dim_rec_type IN g_item_supp_country_dim_rec_type |
   -- |            p_item_supp_country_loc_rec      IN g_item_supp_country_loc_rec		|
   -- |             x_message_code                  OUT NUMBER   						|
   -- |             x_message_data                  OUT VARCHAR2                        |
   -- |                                                                                |
   -- +================================================================================+
   PROCEDURE INTERFACE_ASL_DATA
      (p_actionexpression               IN VARCHAR2
      ,p_reason_code                    IN VARCHAR2
      ,p_rms_timestamp                  IN VARCHAR2
      ,p_item_supp_rec                  IN g_item_supp_rec_type
      ,p_item_supp_coo_rec              IN g_item_supp_coo_rec_type
      ,p_item_supp_upc_rec              IN g_item_supp_upc_rec_type
      ,p_item_supp_country_rec          IN g_item_supp_country_rec_type
      ,p_item_supp_dim_rec              IN g_item_supp_dim_rec_type
      ,g_item_supp_loc_rec              IN g_item_supp_loc_rec_type
      ,x_message_code                   OUT NUMBER
      ,x_message_data                   OUT VARCHAR2
      );
END XX_PO_ASL_IN_PKG;
/

