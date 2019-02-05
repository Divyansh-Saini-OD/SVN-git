SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE XX_GI_RECEIVING_PKG AUTHID CURRENT_USER
--Version 1.0
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- +=============================================================================+
-- |Package Name : XX_GI_RECEIVING_PKG                                           |
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
-- |Draft1A  08-Jan-2008   Arun Andavar     Draft version                        |
-- |1.0      05-Feb-2008   Arun Andavar     baselined                            |
-- +=============================================================================+
IS

   TYPE detail_rec_type IS RECORD (interface_transaction_id      NUMBER
                                  ,group_id                      NUMBER
                                  ,last_update_date              DATE 
                                  ,last_updated_by               NUMBER
                                  ,creation_date                 DATE 
                                  ,created_by                    NUMBER
                                  ,last_update_login             NUMBER
                                  ,request_id                    NUMBER
                                  ,program_application_id        NUMBER
                                  ,program_id                    NUMBER
                                  ,program_update_date           DATE 
                                  ,transaction_type              VARCHAR (25) 
                                  ,transaction_date              DATE 
                                  ,processing_status_code        VARCHAR (25) 
                                  ,processing_mode_code          VARCHAR (25) 
                                  ,processing_request_id         NUMBER
                                  ,transaction_status_code       VARCHAR (25) 
                                  ,category_id                   NUMBER
                                  ,quantity                      NUMBER
                                  ,unit_of_measure               VARCHAR (25) 
                                  ,interface_source_code         VARCHAR (25) 
                                  ,interface_source_line_id      NUMBER
                                  ,inv_transaction_id            NUMBER
                                  ,item_id                       NUMBER
                                  ,item_description              VARCHAR (240) 
                                  ,item_revision                 VARCHAR (3) 
                                  ,uom_code                      VARCHAR (3) 
                                  ,employee_id                   NUMBER
                                  ,auto_transact_code            VARCHAR (25) 
                                  ,shipment_header_id            NUMBER
                                  ,shipment_line_id              NUMBER
                                  ,ship_to_location_id           NUMBER
                                  ,primary_quantity              NUMBER
                                  ,primary_unit_of_measure       VARCHAR (25) 
                                  ,receipt_source_code           VARCHAR (25) 
                                  ,vendor_id                     NUMBER
                                  ,vendor_site_id                NUMBER
                                  ,from_organization_id          NUMBER
                                  ,from_subinventory             VARCHAR (10) 
                                  ,to_organization_id            NUMBER
                                  ,intransit_owning_org_id       NUMBER
                                  ,routing_header_id             NUMBER
                                  ,routing_step_id               NUMBER
                                  ,source_document_code          VARCHAR (25) 
                                  ,parent_transaction_id         NUMBER
                                  ,po_header_id                  NUMBER
                                  ,po_revision_num               NUMBER
                                  ,po_release_id                 NUMBER
                                  ,po_line_id                    NUMBER
                                  ,po_line_location_id           NUMBER
                                  ,po_unit_price                 NUMBER
                                  ,currency_code                 VARCHAR (15) 
                                  ,currency_conversion_type      VARCHAR (30) 
                                  ,currency_conversion_rate      NUMBER
                                  ,currency_conversion_date      DATE 
                                  ,po_distribution_id            NUMBER
                                  ,requisition_line_id           NUMBER
                                  ,req_distribution_id           NUMBER
                                  ,charge_account_id             NUMBER
                                  ,substitute_unordered_code     VARCHAR (25) 
                                  ,receipt_exception_flag        VARCHAR (1) 
                                  ,accrual_status_code           VARCHAR (25) 
                                  ,inspection_status_code        VARCHAR (25) 
                                  ,inspection_quality_code       VARCHAR (25) 
                                  ,destination_type_code         VARCHAR (25) 
                                  ,deliver_to_person_id          NUMBER
                                  ,location_id                   NUMBER
                                  ,deliver_to_location_id        NUMBER
                                  ,subinventory                  VARCHAR (10) 
                                  ,locator_id                    NUMBER
                                  ,wip_entity_id                 NUMBER
                                  ,wip_line_id                   NUMBER
                                  ,department_code               VARCHAR (10) 
                                  ,wip_repetitive_schedule_id    NUMBER
                                  ,wip_operation_seq_num         NUMBER
                                  ,wip_resource_seq_num          NUMBER
                                  ,bom_resource_id               NUMBER
                                  ,shipment_num                  VARCHAR (30) 
                                  ,freight_carrier_code          VARCHAR (25) 
                                  ,bill_of_lading                VARCHAR (25) 
                                  ,packing_slip                  VARCHAR (25) 
                                  ,shipped_date                  DATE 
                                  ,expected_receipt_date         DATE 
                                  ,actual_cost                   NUMBER
                                  ,transfer_cost                 NUMBER
                                  ,transportation_cost           NUMBER
                                  ,transportation_account_id     NUMBER
                                  ,num_of_containers             NUMBER
                                  ,waybill_airbill_num           VARCHAR (20) 
                                  ,vendor_item_num               VARCHAR (25) 
                                  ,vendor_lot_num                VARCHAR (30) 
                                  ,rma_reference                 VARCHAR (30) 
                                  ,comments                      VARCHAR (240) 
                                  ,attribute_category            VARCHAR (30) 
                                  ,attribute1                    VARCHAR (150) 
                                  ,attribute2                    VARCHAR (150) 
                                  ,attribute3                    VARCHAR (150) 
                                  ,attribute4                    VARCHAR (150) 
                                  ,attribute5                    VARCHAR (150) 
                                  ,attribute6                    VARCHAR (150) 
                                  ,attribute7                    VARCHAR (150) 
                                  ,attribute9                    VARCHAR (150) 
                                  ,attribute10                   VARCHAR (150) 
                                  ,attribute11                   VARCHAR (150) 
                                  ,attribute12                   VARCHAR (150) 
                                  ,attribute13                   VARCHAR (150) 
                                  ,attribute14                   VARCHAR (150) 
                                  ,attribute15                   VARCHAR (150) 
                                  ,ship_head_attribute_categorY  VARCHAR (30) 
                                  ,ship_head_attribute1          VARCHAR (150) 
                                  ,ship_head_attribute2          VARCHAR (150) 
                                  ,ship_head_attribute3          VARCHAR (150) 
                                  ,ship_head_attribute4          VARCHAR (150) 
                                  ,ship_head_attribute5          VARCHAR (150) 
                                  ,ship_head_attribute6          VARCHAR (150) 
                                  ,ship_head_attribute7          VARCHAR (150) 
                                  ,ship_head_attribute8          VARCHAR (150) 
                                  ,ship_head_attribute9          VARCHAR (150) 
                                  ,ship_head_attribute10         VARCHAR (150) 
                                  ,ship_head_attribute11         VARCHAR (150) 
                                  ,ship_head_attribute12         VARCHAR (150) 
                                  ,ship_head_attribute13         VARCHAR (150) 
                                  ,ship_head_attribute14         VARCHAR (150) 
                                  ,ship_head_attribute15         VARCHAR (150) 
                                  ,ship_line_attribute_categorY  VARCHAR (30) 
                                  ,ship_line_attribute1          VARCHAR (150) 
                                  ,ship_line_attribute2          VARCHAR (150) 
                                  ,ship_line_attribute3          VARCHAR (150) 
                                  ,ship_line_attribute4          VARCHAR (150) 
                                  ,ship_line_attribute5          VARCHAR (150) 
                                  ,ship_line_attribute6          VARCHAR (150) 
                                  ,ship_line_attribute7          VARCHAR (150) 
                                  ,ship_line_attribute8          VARCHAR (150) 
                                  ,ship_line_attribute9          VARCHAR (150) 
                                  ,ship_line_attribute10         VARCHAR (150) 
                                  ,ship_line_attribute11         VARCHAR (150) 
                                  ,ship_line_attribute12         VARCHAR (150) 
                                  ,ship_line_attribute13         VARCHAR (150) 
                                  ,ship_line_attribute14         VARCHAR (150) 
                                  ,ship_line_attribute15         VARCHAR (150) 
                                  ,ussgl_transaction_code        VARCHAR (30) 
                                  ,government_context            VARCHAR (30) 
                                  ,reason_id                     NUMBER
                                  ,destination_context           VARCHAR (30) 
                                  ,source_doc_quantity           NUMBER
                                  ,source_doc_unit_of_measure    VARCHAR (25) 
                                  ,movement_id                   NUMBER
                                  ,header_interface_id           NUMBER
                                  ,vendor_cum_shipped_qty        NUMBER
                                  ,item_num                      VARCHAR (81) 
                                  ,document_num                  VARCHAR (30) 
                                  ,document_line_num             NUMBER
                                  ,truck_num                     VARCHAR (35) 
                                  ,ship_to_location_code         VARCHAR (60) 
                                  ,container_num                 VARCHAR (35) 
                                  ,substitute_item_num           VARCHAR (81) 
                                  ,notice_unit_price             NUMBER
                                  ,item_category                 VARCHAR (81) 
                                  ,location_code                 VARCHAR (60) 
                                  ,vendor_name                   VARCHAR (240) 
                                  ,vendor_num                    VARCHAR (30) 
                                  ,vendor_site_code              VARCHAR (15) 
                                  ,from_organization_code        VARCHAR (3) 
                                  ,to_organization_code          VARCHAR (3) 
                                  ,intransit_owning_org_code     VARCHAR (3) 
                                  ,routing_code                  VARCHAR (30) 
                                  ,routing_step                  VARCHAR (30) 
                                  ,release_num                   NUMBER
                                  ,document_shipment_line_num    NUMBER
                                  ,document_distribution_num     NUMBER
                                  ,deliver_to_person_name        VARCHAR (240) 
                                  ,deliver_to_location_code      VARCHAR (60) 
                                  ,use_mtl_lot                   NUMBER
                                  ,use_mtl_serial                NUMBER
                                  ,locator                       VARCHAR (81) 
                                  ,reason_name                   VARCHAR (30) 
                                  ,validation_flag               VARCHAR (1) 
                                  ,substitute_item_id            NUMBER
                                  ,quantity_shipped              NUMBER
                                  ,quantity_invoiced             NUMBER
                                  ,tax_name                      VARCHAR (15) 
                                  ,tax_amount                    NUMBER
                                  ,req_num                       VARCHAR (25) 
                                  ,req_line_num                  NUMBER
                                  ,req_distribution_num          NUMBER
                                  ,wip_entity_name               VARCHAR (24) 
                                  ,wip_line_code                 VARCHAR (10) 
                                  ,resource_code                 VARCHAR (30) 
                                  ,shipment_line_status_code     VARCHAR (25) 
                                  ,barcode_label                 VARCHAR (35) 
                                  ,transfer_percentage           NUMBER
                                  ,qa_collection_id              NUMBER
                                  ,country_of_origin_code        VARCHAR (2) 
                                  ,oe_order_header_id            NUMBER
                                  ,oe_order_line_id              NUMBER
                                  ,customer_id                   NUMBER
                                  ,customer_site_id              NUMBER
                                  ,customer_item_num             VARCHAR (50) 
                                  ,create_debit_memo_flag        VARCHAR (1) 
                                  ,put_away_rule_id              NUMBER
                                  ,put_away_strategy_id          NUMBER
                                  ,lpn_id                        NUMBER
                                  ,transfer_lpn_id               NUMBER
                                  ,cost_group_id                 NUMBER
                                  ,mobile_txn                    VARCHAR (2) 
                                  ,mmtt_temp_id                  NUMBER
                                  ,transfer_cost_group_id        NUMBER
                                  ,secondary_quantity            NUMBER
                                  ,secondary_unit_of_measure     VARCHAR (25) 
                                  ,secondary_uom_code            VARCHAR (3) 
                                  ,qc_grade                      VARCHAR (150) 
                                  ,from_locator                  VARCHAR (81) 
                                  ,from_locator_id               NUMBER
                                  ,parent_source_transaction_nUM VARCHAR (25) 
                                  ,interface_available_qty       NUMBER
                                  ,interface_transaction_qty     NUMBER
                                  ,interface_available_amt       NUMBER
                                  ,interface_transaction_amt     NUMBER
                                  ,license_plate_number          VARCHAR (30) 
                                  ,source_transaction_num        VARCHAR (25) 
                                  ,transfer_license_plate_numbER VARCHAR (30) 
                                  ,lpn_group_id                  NUMBER
                                  ,order_transaction_id          NUMBER
                                  ,customer_account_number       NUMBER
                                  ,customer_party_name           VARCHAR (360) 
                                  ,oe_order_line_num             NUMBER
                                  ,oe_order_num                  NUMBER
                                  ,parent_interface_txn_id       NUMBER
                                  ,customer_item_id              NUMBER
                                  ,amount                        NUMBER
                                  ,job_id                        NUMBER
                                  ,timecard_id                   NUMBER
                                  ,timecard_ovn                  NUMBER
                                  ,erecord_id                    NUMBER
                                  ,project_id                    NUMBER
                                  ,task_id                       NUMBER
                                  ,asn_attach_id                 NUMBER
                                  ,org_id                        NUMBER
                                  ,operating_unit                VARCHAR (240) 
                                  ,requested_amount              NUMBER
                                  ,material_stored_amount        NUMBER
                                  ,amount_shipped                NUMBER
                                  ,matching_basis                VARCHAR (30) 
                                  ,replenish_order_line_id       NUMBER
                                  ,e0346_status_flag             VARCHAR (1) 
                                  ,od_rcv_error_description      VARCHAR (5000) 
                                  ,attribute8                    VARCHAR (150) 
                                  ,od_rvc_correction_flag        VARCHAR (10) 
                                  ,od_rcv_status_flag            VARCHAR (10) 
                                  ,legacy_transaction_type       VARCHAR (30) 
                                  );
      TYPE detail_tbl_type IS TABLE OF detail_rec_type
   INDEX BY BINARY_INTEGER;   
    
   PROCEDURE VALIDATE_STG_PO_RECEIVING_DATA(p_calling_pgm     IN      VARCHAR2     DEFAULT NULL
                                           ,x_header_rec      IN OUT  xx_gi_rcv_po_hdr%ROWTYPE    
                                           ,x_detail_tbl      IN OUT  detail_tbl_type    
                                           ,x_return_status      OUT  VARCHAR2                    
                                           ,x_return_message     OUT  VARCHAR2                    
                                           );

   PROCEDURE POPULATE_STG_PO_RECEIVING_DATA(x_keyrec_rec      IN OUT xx_gi_rcv_keyrec%ROWTYPE    
                                           ,x_header_rec      IN OUT xx_gi_rcv_po_hdr%ROWTYPE    
                                           ,x_detail_tbl      IN OUT detail_tbl_type    
                                           ,x_return_status   OUT    VARCHAR2                    
                                           ,x_return_message  OUT    VARCHAR2                    
                                           );
                                           
   PROCEDURE VALIDATE_STG_XFR_RCV_DATA(p_calling_pgm     IN      VARCHAR2     DEFAULT NULL
                                      ,x_header_rec      IN OUT  xx_gi_rcv_xfr_hdr%ROWTYPE    
                                      ,x_detail_tbl      IN OUT  detail_tbl_type    
                                      ,x_return_status      OUT  VARCHAR2                    
                                      ,x_return_message     OUT  VARCHAR2                    
                                      );

   PROCEDURE POPULATE_STG_XFR_RCV_DATA(x_keyrec_rec      IN OUT xx_gi_rcv_keyrec%ROWTYPE    
                                      ,x_header_rec      IN OUT xx_gi_rcv_xfr_hdr%ROWTYPE    
                                      ,x_detail_tbl      IN OUT detail_tbl_type    
                                      ,x_return_status   OUT    VARCHAR2                    
                                      ,x_return_message  OUT    VARCHAR2                    
                                      );
                                           
                                
   PROCEDURE XFR_RCV_UPDATE( x_errbuf    OUT NOCOPY VARCHAR2
                            ,x_retcode   OUT NOCOPY NUMBER
                           ) ;
                            
   PROCEDURE XFR_RCV_PURGE( x_errbuf    OUT NOCOPY VARCHAR2
                           ,x_retcode   OUT NOCOPY NUMBER
                          );


   PROCEDURE INSERT_INTO_XFR_RCVING_TBLS(p_header_interface_id IN NUMBER                                
                                        ,p_keyrec_nbr          IN VARCHAR2
                                        ,p_loc_nbr             IN VARCHAR2                                     
                                        ,x_ret_status          OUT PLS_INTEGER
                                        ,x_ret_message         OUT VARCHAR2
                                        );
                                     
   PROCEDURE POPULATE_INT_XFR_RCVING_DATA(x_errbuf   OUT NOCOPY VARCHAR2
                                         ,x_retcode  OUT NOCOPY NUMBER
                                         );
                                         
   PROCEDURE POPULATE_INT_PO_RCVING_DATA ( x_errbuf   OUT NOCOPY VARCHAR2
                                          ,x_retcode  OUT NOCOPY NUMBER
                                         );
                                         
   PROCEDURE INSERT_INTO_RCVING_TBLS(p_header_interface_id IN NUMBER                                
                                    ,p_keyrec_nbr          IN VARCHAR2
                                    ,p_loc_nbr             IN VARCHAR2
                                    ,x_ret_status          OUT PLS_INTEGER
                                    ,x_ret_message         OUT VARCHAR2
                                   );
                                    
   PROCEDURE PO_RCV_UPDATE( x_errbuf    OUT NOCOPY VARCHAR2
                           ,x_retcode   OUT NOCOPY NUMBER
                          );
                                           
   PROCEDURE PO_RCV_PURGE( x_errbuf    OUT NOCOPY VARCHAR2
                          ,x_retcode   OUT NOCOPY NUMBER
                         );
                         
   PROCEDURE XFR_RCV_REPROCESS(x_errbuf    OUT NOCOPY VARCHAR2
                              ,x_retcode   OUT NOCOPY NUMBER
                              );
                              
   PROCEDURE PO_RCV_REPROCESS(x_errbuf    OUT NOCOPY VARCHAR2
                             ,x_retcode   OUT NOCOPY NUMBER
                             );
                         
   PROCEDURE CORRECT_PO_RCVING(x_ret_status    OUT PLS_INTEGER
                              ,x_ret_message   OUT VARCHAR2
                              );
                                 
   PROCEDURE CORRECT_XFR_RCVING( x_ret_status  OUT PLS_INTEGER
                                ,x_ret_message OUT VARCHAR2
                               ) ;
END XX_GI_RECEIVING_PKG;
/
SHOW ERRORS;
EXIT
