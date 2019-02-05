CREATE OR REPLACE PACKAGE APPS.XX_GI_TRANSFER_PKG1 
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                                                                             |
-- +=============================================================================+
-- +=============================================================================+
-- |Package Name : XX_GI_TRANSFER_PKG                                            |
-- |Purpose      : This package contains procedures that is used the other RICE  |
-- |                elements to create/update/delete/search/display store        |
-- |                transfer information in EBS custom tables. Also moves these  |
-- |                information to MTL_TRANSACTIONS_INTERFACE                    |
-- |               ,MTL_SERIAL_NUMBERS_INTERFACE tables.                         |
-- |                                                                             |
-- |                                                                             |
-- |Change History                                                               |
-- |                                                                             |
-- |Ver      Date          Author           Description                          |
-- |---      -----------   ---------------  -----------------------------        |
-- |1.0      16-JAN-2008   Ramesh Kurapati  Initial Version                      |
-- +=============================================================================+
IS

   TYPE shipment_rec_type IS RECORD
   (
     header_id                 xx_gi_transfer_headers.header_id%TYPE
    ,source_system             xx_gi_transfer_headers.source_system%TYPE
    ,transfer_number           xx_gi_transfer_headers.transfer_number%TYPE
    ,from_org_id               xx_gi_transfer_headers.from_org_id%TYPE
    ,to_org_id                 xx_gi_transfer_headers.to_org_id%TYPE
    ,transaction_type_id       xx_gi_transfer_headers.transaction_type_id%TYPE
    ,from_loc_nbr                xx_gi_transfer_headers.from_loc_nbr%TYPE
    ,to_loc_nbr                  xx_gi_transfer_headers.to_loc_nbr%TYPE
    ,trans_type_cd          xx_gi_transfer_headers.trans_type_cd%TYPE
    ,doc_type_cd xx_gi_transfer_headers.doc_type_cd%TYPE
    ,source_created_by         xx_gi_transfer_headers.source_created_by%TYPE
    ,source_creation_date      xx_gi_transfer_headers.source_creation_date%TYPE
    ,source_subinv_cd          xx_gi_transfer_headers.source_subinv_cd%TYPE
    ,carton_count              xx_gi_transfer_headers.carton_count%TYPE
    ,source_vendor_id          xx_gi_transfer_headers.source_vendor_id%TYPE
    ,ship_to_location_id       xx_gi_transfer_headers.ship_to_location_id%TYPE
    ,buyback_number            xx_gi_transfer_headers.buyback_number%TYPE
    ,line_id                   xx_gi_transfer_lines.line_id%TYPE
    ,inventory_item_id         xx_gi_transfer_lines.inventory_item_id%TYPE
    ,shipped_qty               xx_gi_transfer_lines.shipped_qty%TYPE    
    ,item                       xx_gi_transfer_lines.item%TYPE
    ,uom                       xx_gi_transfer_lines.uom%TYPE
    ,ebs_subinventory_code     xx_gi_transfer_lines.ebs_subinventory_code%TYPE
    ,transaction_header_id     xx_gi_transfer_lines.transaction_header_id%TYPE
);


TYPE xx_gi_xfer_input_hdr_type IS RECORD
    (
  source_system         xx_gi_transfer_headers.source_system%TYPE
 ,transfer_number       xx_gi_transfer_headers.transfer_number%TYPE
 ,from_loc_nbr          xx_gi_transfer_headers.from_loc_nbr%TYPE
 ,to_loc_nbr            xx_gi_transfer_headers.to_loc_nbr%TYPE                         
 ,trans_type_cd         xx_gi_transfer_headers.trans_type_cd%TYPE
 ,doc_type_cd           xx_gi_transfer_headers.doc_type_cd%TYPE
 ,source_creation_date  xx_gi_transfer_headers.source_creation_date%TYPE
 ,source_created_by     xx_gi_transfer_headers.source_created_by%TYPE
 ,buyback_number        xx_gi_transfer_headers.buyback_number%TYPE
 ,carton_count          xx_gi_transfer_headers.carton_count%TYPE
 ,transfer_cost         xx_gi_transfer_headers.transfer_cost%TYPE
 ,ship_date             xx_gi_transfer_headers.ship_date%TYPE
 ,shipped_qty           xx_gi_transfer_headers.shipped_qty%TYPE
 ,comments              xx_gi_transfer_headers.comments%TYPE
 ,source_subinv_cd      xx_gi_transfer_headers.source_subinv_cd%TYPE
 ,source_vendor_id      xx_gi_transfer_headers.source_vendor_id%TYPE
 ,no_of_detail_lines    xx_gi_transfer_headers.no_of_detail_lines%TYPE
 ,header_id             xx_gi_transfer_headers.header_id%TYPE
 ,action                VARCHAR2(30)
 ,attribute_category    xx_gi_transfer_headers.attribute_category%TYPE
 ,attribute1            xx_gi_transfer_headers.attribute1%TYPE
 ,attribute2            xx_gi_transfer_headers.attribute2%TYPE
 ,attribute3            xx_gi_transfer_headers.attribute3%TYPE
 ,attribute4            xx_gi_transfer_headers.attribute4%TYPE
 ,attribute5            xx_gi_transfer_headers.attribute5%TYPE
 ,attribute6            xx_gi_transfer_headers.attribute6%TYPE
 ,attribute7            xx_gi_transfer_headers.attribute7%TYPE
 ,attribute8            xx_gi_transfer_headers.attribute8%TYPE
 ,attribute9            xx_gi_transfer_headers.attribute9%TYPE
 ,attribute10           xx_gi_transfer_headers.attribute10%TYPE
 ,attribute11           xx_gi_transfer_headers.attribute11%TYPE
 ,attribute12           xx_gi_transfer_headers.attribute12%TYPE
 ,attribute13           xx_gi_transfer_headers.attribute13%TYPE
 ,attribute14           xx_gi_transfer_headers.attribute14%TYPE
 ,attribute15            xx_gi_transfer_headers.attribute15%TYPE
    );
                         
                         
TYPE xx_gi_xfer_input_line_type IS RECORD
    (
 item                   xx_gi_transfer_lines.item%TYPE
,shipped_qty            xx_gi_transfer_lines.shipped_qty%TYPE
,requested_qty          xx_gi_transfer_lines.requested_qty%TYPE
,from_loc_uom           xx_gi_transfer_lines.from_loc_uom%TYPE
,from_loc_unit_cost     xx_gi_transfer_lines.from_loc_unit_cost%TYPE
,line_id                xx_gi_transfer_lines.line_id%TYPE
,attribute_category     xx_gi_transfer_headers.attribute_category%TYPE
,attribute1             xx_gi_transfer_lines.attribute1%TYPE
,attribute2             xx_gi_transfer_lines.attribute2%TYPE
,attribute3             xx_gi_transfer_lines.attribute3%TYPE
,attribute4             xx_gi_transfer_lines.attribute4%TYPE
,attribute5             xx_gi_transfer_lines.attribute5%TYPE
,attribute6             xx_gi_transfer_lines.attribute6%TYPE
,attribute7             xx_gi_transfer_lines.attribute7%TYPE
,attribute8             xx_gi_transfer_lines.attribute8%TYPE
,attribute9             xx_gi_transfer_lines.attribute9%TYPE
,attribute10            xx_gi_transfer_lines.attribute10%TYPE
,attribute11            xx_gi_transfer_lines.attribute11%TYPE
,attribute12            xx_gi_transfer_lines.attribute12%TYPE
,attribute13            xx_gi_transfer_lines.attribute13%TYPE
,attribute14            xx_gi_transfer_lines.attribute14%TYPE
,attribute15            xx_gi_transfer_lines.attribute15%TYPE 
    );

    TYPE xx_gi_xfer_input_line_tbl_type IS TABLE OF xx_gi_xfer_input_line_type;
    
    TYPE xx_gi_xfer_out_hdr_type IS TABLE OF xxptp.xx_gi_transfer_headers%rowtype;
    
    TYPE xx_gi_xfer_in_hdr_type IS TABLE OF xxptp.xx_gi_transfer_headers%rowtype;
    
    TYPE xx_gi_xfer_out_line_tbl_type IS TABLE OF xxptp.xx_gi_transfer_lines%rowtype;
    
    TYPE xx_gi_xfer_in_line_tbl_type IS TABLE OF xxptp.xx_gi_transfer_lines%rowtype;
    
    TYPE xx_gi_hdr_tbl_type IS TABLE OF xxptp.xx_gi_transfer_lines%rowtype;

--   TYPE shipment_input_tbl_type IS TABLE OF shipment_input_rec_type;

 PROCEDURE VALIDATE_TRANSFER
                        ( 
                          p_in_hdr_rec IN xx_gi_transfer_headers%rowtype
                         ,p_in_line_tbl   IN         xx_gi_xfer_in_line_tbl_type
                         ,x_out_hdr_rec   OUT NOCOPY xx_gi_xfer_out_hdr_type
                         ,x_out_line_tbl  OUT NOCOPY xx_gi_xfer_out_line_tbl_type
                         ,x_return_status OUT NOCOPY VARCHAR2
                         ,x_error_message OUT NOCOPY VARCHAR2
                         );

                         

                         
PROCEDURE CREATE_MAINTAIN_TRANSFER
                        (                                                
                          p_in_hdr_rec    IN         xx_gi_xfer_input_hdr_type
                         ,p_in_line_tbl   IN         xx_gi_xfer_input_line_tbl_type
                         ,x_return_status OUT NOCOPY VARCHAR2
                         ,x_error_message OUT NOCOPY VARCHAR2
                         );


   PROCEDURE CREATE_EBS_SHIPMENT
                       (
                        x_return_status     OUT NOCOPY VARCHAR2
                       ,x_error_message     OUT NOCOPY VARCHAR2
                       ,p_header_id         IN NUMBER                       
                       );
                       
  PROCEDURE RECONCILE_TRANSFER_SHIPMENT
                        (
                        x_error_code           OUT VARCHAR2--PLS_INTEGER
                        ,x_error_message        OUT VARCHAR2
                           );


  PROCEDURE REPROCESS_TRANSFER
                        (
                           x_error_code           OUT VARCHAR2
                           ,x_error_message        OUT VARCHAR2
                           );




END XX_GI_TRANSFER_PKG1;
/
