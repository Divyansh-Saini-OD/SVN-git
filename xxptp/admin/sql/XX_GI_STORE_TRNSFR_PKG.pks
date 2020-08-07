SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE XX_GI_STORE_TRNSFR_PKG AUTHID CURRENT_USER
--Version 1.0
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- +=============================================================================+
-- |Package Name : XX_GI_STORE_TRNSFR_PKG                                        |
-- |Purpose      : This package contains procedures that is used the other RICE  |
-- |                elements to create/update/delete/search/display store        |
-- |                transfer information in EBS custom tables. Also moves these  |
-- |                information to MTL_TRANSACTIONS_INTERFACE                    |
-- |               ,MTL_SERIAL_NUMBERS_INTERFACE tables.                         |
-- |                                                                             |
-- |Tables Accessed :                                                            |
-- |Access Type----------------- (I - Insert, S - Select, U - Update, D - Delete)|
-- | XX_GI_TRANSFER_HEADERS       : I, S, U, D                                   |
-- | XX_GI_TRANSFER_LINES         : I, S, U, D                                   |
-- | XX_GI_SERIAL_NUMBERS         : I, S, U, D                                   |
-- | MTL_TRANSACTIONS_INTERFACE   : I                                            |
-- | MTL_SERIAL_NUMBERS_INTERFACE : I                                            |
-- | MTL_SYSTEM_ITEMS_B           : S                                            |
-- | MTL_INTERORG_PARAMETERS      : S                                            |
-- | HR_ALL_ORGANIZATION_UNITS    : S                                            |
-- | XX_GI_SHIPMENT_TRACKING      : S                                            |
-- | RCV_SHIPMENT_LINES           : S                                            |
-- | RCV_SHIPMENT_HEADERS         : S                                            |
-- | RCV_TRANSACTIONS             : S                                            |
-- |                                                                             |
-- |                                                                             |
-- |Change History                                                               |
-- |                                                                             |
-- |Ver      Date          Author           Description                          |
-- |---      -----------   ---------------  -----------------------------        |
-- |Draft1A  26-Oct-2007   Arun Andavar     Draft version                        |
-- |1.0      05-Dec-2007   Arun Andavar     a)After adding subinventory parameter|
-- |                                         in create_shipment API              |
-- +=============================================================================+
IS
    
   TYPE search_output_rec_type IS RECORD
   (transfer_number      xx_gi_transfer_headers.transfer_number%TYPE
   ,from_store           xx_gi_transfer_headers.from_store%TYPE           
   ,to_store             xx_gi_transfer_headers.to_store%TYPE           
   ,transfer_created_by  xx_gi_transfer_headers.created_by%TYPE 
   ,creation_date        xx_gi_transfer_headers.creation_date%TYPE 
   ,transfer_cost        PLS_INTEGER
   ,status               xx_gi_transfer_lines.status%TYPE
   ,comments             xx_gi_transfer_headers.comments%TYPE 
   ,item                 mtl_system_items_b.segment1%TYPE
   );

   TYPE inquiry_output_rec_type IS RECORD
   (
    item               mtl_system_items_b.segment1%TYPE
   ,item_description   mtl_system_items_b.description%TYPE
   ,transfer_qty       PLS_INTEGER
   ,shipped_quantity   PLS_INTEGER
   ,received_quantity  PLS_INTEGER
   ,uom                VARCHAR2(10)
   ,unit_cost          PLS_INTEGER
   );

   TYPE display_output_rec_type IS RECORD
   (
    item             mtl_system_items_b.segment1%TYPE
   ,item_description mtl_system_items_b.description%TYPE
   ,uom              VARCHAR2(10)
   ,unit_cost        PLS_INTEGER
   ,qty_onhand       PLS_INTEGER
   ,transfer_qty     PLS_INTEGER
   ,created_by       VARCHAR2(50)
   ,creation_date    DATE
   ,status           VARCHAR2(10)
   ,line_id          PLS_INTEGER
   ,header_id        PLS_INTEGER
   ,error_message    VARCHAR2(500)
   );
   
   TYPE validate_output_rec_type IS RECORD
   (
    item                     mtl_system_items_b.segment1%TYPE
   ,item_id                  mtl_system_items_b.inventory_item_id%TYPE    
   ,item_description         mtl_system_items_b.description%TYPE
   ,uom                      VARCHAR2(10)
   ,unit_cost                PLS_INTEGER
   ,qty_onhand               PLS_INTEGER
   ,transfer_qty             PLS_INTEGER
   ,item_from_org_serialized VARCHAR2(1)
   ,item_to_org_serialized   VARCHAR2(1)  
   ,currency_code            VARCHAR2(15)
   ,serial_numbers           xx_gi_serial_numbers_tab_t 
   ,error_message            VARCHAR2(500)
   ,line_id                  PLS_INTEGER
   );
  
  

   TYPE shipment_input_rec_type IS RECORD
   (
    item              mtl_system_items_b.segment1%TYPE
   ,shipped_quantity  PLS_INTEGER
   ,line_id           xx_gi_transfer_lines.line_id%TYPE
   ,error_message     VARCHAR2(500)
   );

   TYPE carrier_input_rec_type IS RECORD
   (
     line_id                     PLS_INTEGER
    ,document_number             VARCHAR2(10)
    ,carrier_id                  VARCHAR2(20)
    ,carrier_tracking_number     VARCHAR2(20)
    ,carrier_tracking_status     VARCHAR2(20)
    ,weight_uom                  VARCHAR2(20)
    ,weight                      PLS_INTEGER
    ,pickup_number               VARCHAR2(20)
    ,declared_value              VARCHAR2(20)
    ,carrier_confirmation_number VARCHAR2(20)
   );
   
   TYPE carrier_output_rec_type IS RECORD
   (
     carrier_tracking_number     VARCHAR2(20)
    ,carrier_confirmation_number VARCHAR2(20)
    ,line_id                     PLS_INTEGER
    ,error_messsage              VARCHAR2(500)
   );
     
   TYPE search_output_tbl_type IS TABLE OF search_output_rec_type;

   TYPE inquiry_output_tbl_type IS TABLE OF inquiry_output_rec_type;

   TYPE display_output_tbl_type IS TABLE OF display_output_rec_type;
   
   TYPE validate_output_tbl_type IS TABLE OF validate_output_rec_type;
  

   TYPE shipment_input_tbl_type IS TABLE OF shipment_input_rec_type;

   TYPE carrier_input_tbl_type IS TABLE OF carrier_input_rec_type;

   TYPE carrier_output_tbl_type IS TABLE OF carrier_output_rec_type;
   

    
   PROCEDURE SEARCH_DATA(
                         p_source_system         IN    VARCHAR2
                        ,p_start_transfer_number IN    VARCHAR2 
                        ,p_start_date            IN    DATE     
                        ,p_end_date              IN    DATE     
                        ,p_from_store            IN    VARCHAR2 
                        ,p_to_store              IN    VARCHAR2 
                        ,p_status                IN    VARCHAR2 
                        ,p_item                  IN    VARCHAR2 
                        ,x_search_out_dtl        OUT   NOCOPY   search_output_tbl_type
                        ,x_return_status         OUT   NOCOPY   VARCHAR2
                        ,x_error_message         OUT   NOCOPY   VARCHAR2
                       );
                     
   PROCEDURE INQUIRY_DATA(
                           p_source_system          IN             VARCHAR2
                          ,p_transfer_number        IN  OUT NOCOPY VARCHAR2
                          ,p_from_store             IN  OUT NOCOPY VARCHAR2
                          ,x_to_store               OUT            VARCHAR2
                          ,x_status                 OUT            VARCHAR2
                          ,x_transfer_created_by    OUT            VARCHAR2
                          ,x_transfer_creation_date OUT            DATE
                          ,x_keyrec                 OUT            VARCHAR2
                          ,x_ebs_receipt_number     OUT            VARCHAR2
                          ,x_receipt_date           OUT            DATE
                          ,x_received_by            OUT            VARCHAR2
                          ,x_inq_out_dtl            OUT NOCOPY     inquiry_output_tbl_type
                          ,x_return_status          OUT NOCOPY     VARCHAR2
                          ,x_error_message          OUT NOCOPY     VARCHAR2
                      );
                         
   PROCEDURE DISPLAY_DATA(
                           p_source_system          IN             VARCHAR2
                          ,p_transfer_number        IN             VARCHAR2
                          ,x_from_store             IN  OUT NOCOPY VARCHAR2
                          ,x_to_store               IN  OUT NOCOPY VARCHAR2
                          ,x_header_id              OUT NOCOPY     VARCHAR2
                          ,x_disp_out_dtl           OUT NOCOPY     display_output_tbl_type
                          ,x_comments               OUT NOCOPY     VARCHAR2
                          ,x_return_status          OUT NOCOPY     VARCHAR2
                          ,x_error_message          OUT NOCOPY     VARCHAR2
                         );

   PROCEDURE VALIDATE_DATA
                        ( p_source_system IN         VARCHAR2
                         ,p_from_location IN         VARCHAR2
                         ,p_to_location   IN         VARCHAR2
                         ,p_creation_date IN         DATE
                         ,p_created_by    IN         VARCHAR2    
                         ,p_comments      IN         VARCHAR2    
                         ,p_item_in_dtl   IN         xx_gi_validate_item_tab_t
                         ,x_item_out_dtl  OUT NOCOPY validate_output_tbl_type
                         ,x_return_status OUT NOCOPY VARCHAR2
                         ,x_error_message OUT NOCOPY VARCHAR2
                         );
                         
   PROCEDURE CREATE_DATA
                        (
                         p_source_system    IN         VARCHAR2
                        ,p_from_store       IN         VARCHAR2
                        ,p_to_store         IN         VARCHAR2
                        ,p_creation_date    IN         DATE
                        ,p_created_by       IN         VARCHAR2
                        ,p_transfer_number  IN         VARCHAR2
                        ,p_transaction_type IN         VARCHAR2
                        ,p_comments         IN         VARCHAR2
                        ,p_item_in_dtl      IN         xx_gi_validate_item_tab_t
                        ,x_item_out_dtl     OUT NOCOPY validate_output_tbl_type
                        ,x_error_message    OUT NOCOPY VARCHAR2
                        ,x_return_status    OUT NOCOPY VARCHAR2
                        );
   PROCEDURE UPDATE_DATA
                       (
                        p_source_system   IN             VARCHAR2
                       ,x_transfer_number IN  OUT NOCOPY VARCHAR2
                       ,x_new_comments    IN  OUT NOCOPY VARCHAR2
                       ,p_line_action     IN             VARCHAR2
                       ,p_new_item        IN             VARCHAR2
                       ,p_header_id       IN             PLS_INTEGER
                       ,p_update_in_dtl   IN             xx_gi_validate_item_tab_t
                       ,x_update_out_dtl  OUT NOCOPY     validate_output_tbl_type
                       ,x_error_message   OUT NOCOPY     VARCHAR2
                       ,x_return_status   OUT NOCOPY     VARCHAR2
                       );

   PROCEDURE CREATE_SHIPMENT
                       (
                        p_source_system     IN VARCHAR2
                       ,p_transfer_number   IN VARCHAR2
                       ,p_carton_count      IN VARCHAR2
                       ,p_subinventory_code IN VARCHAR2 DEFAULT 'STOCK'
                       ,p_comments          IN VARCHAR2
                       ,p_header_id         IN PLS_INTEGER
                       ,p_ship_in_dtl       IN shipment_input_tbl_type
                       ,x_ship_out_dtl      OUT NOCOPY shipment_input_tbl_type
                       ,x_error_message     OUT NOCOPY VARCHAR2
                       ,x_return_status     OUT NOCOPY VARCHAR2
                       );
                       
   PROCEDURE CAPTURE_CARRIER
                       (
                         p_source_system           IN         VARCHAR2
                        ,p_transfer_number         IN         VARCHAR2
                        ,p_carrier_id              IN         VARCHAR2
                        ,p_carrier_tracking_status IN         VARCHAR2          
                        ,p_carrier_in_dtl          IN         carrier_input_tbl_type
                        ,p_header_id               IN         PLS_INTEGER
                        ,x_carrier_out_dtl         OUT NOCOPY carrier_output_tbl_type
                        ,x_error_message           OUT NOCOPY VARCHAR2
                        ,x_return_status           OUT NOCOPY VARCHAR2                        
                       );
                       
   PROCEDURE INTER_ORG_INFO(x_error_message        OUT VARCHAR2
                           ,x_error_code           OUT PLS_INTEGER
                           );




END XX_GI_STORE_TRNSFR_PKG;
/
SHOW ERRORS;
EXIT
