SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET FEEDBACK     OFF
SET TAB          OFF
SET TERM         ON
PROMPT 'Creating Package Specification  - XX_GI_RCV_STR_PKG'
CREATE OR REPLACE PACKAGE XX_GI_RCV_STR_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : XX_GI_RCV_STR_PKG                                   |
-- | Description : To convert the 'GI InterOrg RECEIPTS' that are fully|
-- |               received as well as partially received              |
-- |               from the OD Legacy system to Oracle EBS.            |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       18-MAY-2007  Thilak Daniel         Initial version       |
-- |                                                                   |
-- +===================================================================+
AS  
   gc_err_code                        xxptp.xx_gi_error_tbl.msg_code%TYPE;
   gc_err_desc                        xxptp.xx_gi_error_tbl.msg_desc%TYPE;
   gc_entity_ref                      xxptp.xx_gi_error_tbl.entity_ref%TYPE;
   gn_entity_ref_id                   xxptp.xx_gi_error_tbl.entity_ref_id%TYPE;
   gn_ship_to_organization_id         NUMBER;
   gn_from_organization_id            NUMBER;
                                            
-- +===================================================================+
-- | Name          : XX_GI_VAL_ASSDET_STR_RCV                          |
-- | Description   : This is the procedure which is used to perform    |
-- |                  assumed/detailed validation.                     |
-- |               Concurrent program  Name is                         |
-- |    "OD : Inventory Assumed-Detailed Receipts Validation Program"  |
-- | Parameters     : x_err_buf,x_ret_code                             |
-- |                                                                   |
-- +===================================================================+
                                                             
   PROCEDURE  XX_GI_VAL_ASSDET_STR_RCV (
                                        x_err_buf   OUT VARCHAR2
                                        ,x_ret_code OUT NUMBER
                                       );
                                            
-- +===================================================================+
-- |Name            : XX_GI_VAL_STR_RCV                                |
-- |Description     : This is the procedure which is used to perform   |
-- |                   Store Transfer Receipts Validation              |
-- |               Concurrent program  Name is                         |
-- |    "OD: Inventory Store Transfer Receipts Validation Program"     |
-- |Parameters      : x_err_buf,x_ret_code                             |
-- |                                                                   |
-- +===================================================================+
                                                             
   PROCEDURE XX_GI_VAL_STR_RCV (
                                x_err_buf  OUT VARCHAR2
                                ,x_ret_code OUT NUMBER
                               );
                                                                        
-- +===================================================================+
-- |Name            :XX_GI_DIRECTORG_TRANSFER                          |
-- |Description     :This is the private  procedure which to perform   |
-- |                  Direct Org transfers                             |
-- |Parameters      :itemnum, trans_qty ,from_organization_id,         |
-- |                 to_organization_id,from_subinventory, uom,        |
-- |                 to_subinventory,uom,header_id,line_id             |
-- +===================================================================+
   PROCEDURE XX_GI_DIRECTORG_TRANSFER
                                     (
                                      p_itemnum               NUMBER
                                      ,p_trans_qty            NUMBER
                                      ,p_fr_organization_id   NUMBER
                                      ,p_to_organization_id   NUMBER
                                      ,p_from_subinventory    VARCHAR2
                                      ,p_to_subinventory      VARCHAR2
                                      ,p_uom                  VARCHAR2
                                      ,p_header_id            NUMBER
                                      ,p_line_id              NUMBER
                                      ,p_shipment_num         VARCHAR2
                                     );
                                                                        
-- +===================================================================+
-- |Name            :XX_GI_INTERORG_TRANSFER                           |
-- |Description     :This is the private  procedure which to perform   |
-- |                  Intransit shipments                              |
-- |Parameters      :itemnum, trans_qty ,from_organization_id,         |
-- |                 to_organization_id,from_subinventory,             |
-- |                 to_subinventory,uom,header_id,line_id,shipment_num|
-- +===================================================================+
   PROCEDURE XX_GI_INTERORG_TRANSFER
                                    (
                                     p_itemnum               NUMBER
                                     ,p_trans_qty            NUMBER
                                     ,p_fr_organization_id   NUMBER
                                     ,p_to_organization_id   NUMBER
                                     ,p_from_subinventory    VARCHAR2
                                     ,p_to_subinventory      VARCHAR2
                                     ,p_uom                  VARCHAR2
                                     ,p_header_id            NUMBER
                                     ,p_line_id              NUMBER
                                     ,p_shipment_num         VARCHAR2
                                    );
-- +===================================================================+
-- | Name           : GET_ORGANIZATION_CODE                            |
-- |Description     : This is the internal  Function  which to get     |
-- |                  organization code from given organization id     |
-- |Paramater       : organization_id                                  |
-- | Return         : organization_code                                |
-- +===================================================================+
   FUNCTION GET_ORGANIZATION_CODE(p_organization_id NUMBER)
     RETURN VARCHAR2;
                                                                        
-- +===================================================================+
-- |Name            : GET_ITEM_CODE                                    |
-- |Description     : This is the internal  function  which to get     |
-- |                   item name from given item id                    |
-- |Paramater       :  item_id,organization_id                         |
-- | Return         : item_name                                        |
-- +===================================================================+
 FUNCTION GET_ITEM_CODE(
                        p_item_id NUMBER
                        ,p_org_id NUMBER
                        )
      RETURN VARCHAR2;
                                                                        
-- +===================================================================+
-- |Name            : GET_ITEM_ID                                      |
-- |Description     : This is the internal  function  which to get     |
-- |                  item name from given item id                     |
-- |Paramater       : item_num,organization_id                         |
-- | Return         : item_id                                          |
-- +===================================================================+
    FUNCTION GET_ITEM_ID(
                         p_item_num VARCHAR2
                         ,p_org_id  NUMBER
                        )
      RETURN NUMBER;
   
-- +===================================================================+
-- |Name            : XX_GI_POP_RTI_STR_RCV                            |
-- |Description     : This is the procedure which is used to populte   |
-- |                   Interface tbl Store Transfer Receipts Validation|
-- |               Concurrent program  Name is                         |
-- |    "OD: Inventory Store Transfer Receipts Validation Program"     |
-- |Parameters      : x_err_buf,x_ret_code                             |
-- |                                                                   |
-- +===================================================================+
                                               
   PROCEDURE XX_GI_POP_RTI_STR_RCV(
                                   x_err_buf   OUT VARCHAR2
                                   ,x_ret_code OUT NUMBER
                                  );
END XX_GI_RCV_STR_PKG;
/
SHOW ERR