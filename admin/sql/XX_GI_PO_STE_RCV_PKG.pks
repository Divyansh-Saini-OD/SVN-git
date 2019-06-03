SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET FEEDBACK     OFF
SET TAB          OFF
SET TERM         ON
CREATE OR REPLACE
PACKAGE  XX_GI_PO_STE_RCV_PKG
AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Implemented to perform the PO Online Receipts       |
-- | Description : To perform the Online PO Receipts of the RICE ID    |
-- |               E0342a.Receiving is the process of receiving        |
-- |               inventory into a location or organization.          |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0      28-June-2007  Rahul Bagul           Initial version       |
-- |                                                                   |
-- +===================================================================+

--gc_err_code                        xxom.xxod_global_exceptions_tbl.error_code%type;
--gc_err_desc                        xxom.xxod_global_exceptions_tbl.description%type;
gn_ship_to_organization_id         NUMBER;
gn_from_organization_id            NUMBER;
lc_sqlcode                         NUMBER;
lc_sqlerrm                         VARCHAR2 (2000);
lc_error_message                   VARCHAR2 (1000);

TYPE lt_ins_rec_online_typ IS RECORD  (
                                 rhi_asn_type                        VARCHAR2(25)
                               , rhi_carrier_equipment               VARCHAR2(10)
                               , rhi_carrier_method                  VARCHAR2(2)
                               , rhi_conversion_rate                 NUMBER
                               , rhi_conversion_rate_date            DATE
                               , rhi_conversion_rate_type            VARCHAR2(30)
                               , rhi_edi_control_num                 VARCHAR2(10)
                               , rhi_employee_name                   VARCHAR2(240)
                               , rhi_freight_amount                  NUMBER
                               , rhi_freight_bill_number             VARCHAR2(35)
                               , rhi_freight_terms                   VARCHAR2(25)
                               , rhi_gross_weight                    NUMBER
                               , rhi_gross_weight_uom_code           VARCHAR2(3)
                               , rhi_hazard_class                    VARCHAR2(4)
                               , rhi_hazard_code                     VARCHAR2(1)
                               , rhi_hazard_description              VARCHAR2(80)
                               , rhi_invoice_date                    DATE
                               , rhi_invoice_num                     VARCHAR2(30)
                               , rhi_invoice_status_code             VARCHAR2(25)
                               , rhi_receipt_source_code             VARCHAR2(25)
                               , rhi_net_weight                      NUMBER
                               , rhi_net_weight_uom_code             VARCHAR2(3)
                               , rhi_notice_creation_date            DATE
                               , rhi_packaging_code                  VARCHAR2(5)
                               , rhi_payment_terms_name              VARCHAR2(50)
                               , rhi_receipt_header_id               NUMBER
                               , rhi_receipt_num                     VARCHAR2(30)
                               , rhi_ship_to_organization_code       VARCHAR2(3)
                               , rhi_special_handling_code           VARCHAR2(3)
                               , rhi_tar_weight                      NUMBER
                               , rhi_tar_weight_uom_code             VARCHAR2(3)
                               , rhi_total_invoice_amount            NUMBER
                               , rhi_expected_receipt_date           DATE
                               , rhi_attribute_category              VARCHAR2(30)
                               , rhi_attribute1                      VARCHAR2(150)
                               , rhi_attribute2                      VARCHAR2(150)
                               , rhi_attribute3                      VARCHAR2(150)
                               , rhi_attribute4                      VARCHAR2(150)
                               , rhi_attribute5                      VARCHAR2(150)
                               , rhi_attribute6                      VARCHAR2(150)
                               , rhi_attribute7                      VARCHAR2(150)
                               , rhi_attribute8                      VARCHAR2(150)
                               , rhi_attribute9                      VARCHAR2(150)
                               , rhi_attribute10                     VARCHAR2(150)
                               , rhi_attribute11                     VARCHAR2(150)
                               , rhi_attribute12                     VARCHAR2(150)
                               , rhi_attribute13                     VARCHAR2(150)
                               , rhi_attribute14                     VARCHAR2(150)
                               , rhi_attribute15                     VARCHAR2(150)
                               , rti_attribute_category              VARCHAR2(30)
                               , rti_created_by                      NUMBER
                               , rti_creation_date                   DATE
                               , rti_currency_code                   VARCHAR2(30)
                               , rti_currency_conversion_date        DATE
                               , rti_currency_conversion_rate        NUMBER
                               , rti_currency_conversion_type        VARCHAR2(30)
                               , rti_last_update_date                DATE
                               , rti_last_update_login               NUMBER
                               , rti_last_updated_by                 NUMBER
                               , rti_lpn_id                          NUMBER
                               , rti_primary_quantity                NUMBER
                               , rti_program_update_date             DATE
                               , rti_request_id                      NUMBER
                               , rti_secondary_uom_code              VARCHAR2(240)
                               , rti_transaction_date                DATE
                               , rti_transfer_cost                   NUMBER
                               , rti_transfer_percentage             NUMBER
                               , rti_transportation_cost             NUMBER
                               , rti_ussgl_transaction_code          VARCHAR2(30)
                               , rti_from_organization_code          VARCHAR2(3)
                               , rti_accrual_status_code             VARCHAR2(25)
                               , rti_actual_cost                     NUMBER
                               , rti_amount                          NUMBER
                               , rti_auto_transact_code              VARCHAR2(25)
                               , rti_barcode_label                   VARCHAR2(35)
                               , rti_bill_of_lading                  VARCHAR2(25)
                               , rti_comments                        VARCHAR2(240)
                               , rti_container_num                   VARCHAR2(35)
                               , rti_country_of_origin_code          VARCHAR2(2)
                               , rti_customer_account_number         NUMBER
                               , rti_customer_item_num               VARCHAR2(50)
                               , rti_customer_party_name             VARCHAR2(360)
                               , rti_deliver_to_location_code        VARCHAR2(60)
                               , rti_deliver_to_person_name          VARCHAR2(240)
                               , rti_department_code                 VARCHAR2(10)
                               , rti_destination_context             VARCHAR2(30)
                               , rti_destination_type_code           VARCHAR2(25)
                               , rti_document_distribution_num       NUMBER
                               , rti_document_line_num               NUMBER
                               , rti_document_num                    VARCHAR2(30)
                               , rti_document_shipment_line_num      NUMBER
                               , rti_expected_receipt_date           DATE
                               , rti_freight_carrier_code            VARCHAR2(25)
                               , rti_from_locator                    VARCHAR2(81)
                               , rti_from_subinventory               VARCHAR2(10)
                               , rti_government_context              VARCHAR2(30)
                               , rti_inspection_quality_code         VARCHAR2(25)
                               , rti_inspection_status_code          VARCHAR2(25)
                               , rti_interface_available_amt         NUMBER
                               , rti_interface_available_qty         NUMBER
                               , rti_interface_source_code           VARCHAR2(30)
                               , rti_interface_transaction_amt       NUMBER
                               , rti_interface_transaction_qty       NUMBER
                               , rti_intransit_owning_org_code       VARCHAR2(3)
                               , rti_inv_transaction_id              NUMBER
                               , rti_item_category                   VARCHAR2(81)
                               , rti_item_id                         NUMBER
                               , rti_item_description                VARCHAR2(240)
                               , rti_item_num                        VARCHAR2(81)
                               , rti_item_revision                   VARCHAR2(3)
                               , rti_license_plate_number            VARCHAR2(30)
                               , rti_location_code                   VARCHAR2(60)
                               , rti_locator                         VARCHAR2(81)
                               , rti_mobile_txn                      VARCHAR2(2)
                               , rti_notice_unit_price               NUMBER
                               , rti_num_of_containers               NUMBER
                               , rti_oe_order_header_id              NUMBER
                               , rti_oe_order_line_id                NUMBER
                               , rti_oe_order_line_num               NUMBER
                               , rti_oe_order_num                    NUMBER
                               , rti_order_transaction_id            NUMBER
                               , rti_packing_slip                    VARCHAR2(25)
                               , rti_parent_source_trans_num         VARCHAR2(25)
                               , rti_parent_transaction_id           NUMBER
                               , rti_po_revision_num                 NUMBER
                               , rti_po_unit_price                   NUMBER
                               , rti_primary_unit_of_measure         VARCHAR2(25)
                               , rti_processing_mode_code            VARCHAR2(25)
                               , rti_processing_status_code          VARCHAR2(25)
                               , rti_qc_grade                        VARCHAR2(25)
                               , rti_quantity                        NUMBER
                               , rti_quantity_invoiced               NUMBER
                               , rti_quantity_shipped                NUMBER
                               , rti_reason_name                     VARCHAR2(30)
                               , rti_receipt_exception_flag          VARCHAR2(1)
                               , rti_receipt_source_code             VARCHAR2(25)
                               , rti_release_num                     NUMBER
                               , rti_req_distribution_num            NUMBER
                               , rti_req_line_num                    NUMBER
                               , rti_req_num                         VARCHAR2(25)
                               , rti_resource_code                   VARCHAR2(30)
                               , rti_rma_reference                   VARCHAR2(30)
                               , rti_routing_code                    VARCHAR2(30)
                               , rti_routing_step                    VARCHAR2(30)
                               , rti_secondary_quantity              NUMBER
                               , rti_secondary_unit_of_measure       VARCHAR2(25)
                               , rti_sh_att_cat                      VARCHAR2(30)
                               , rti_sh_att1                         VARCHAR2(150)
                               , rti_sh_att10                        VARCHAR2(150)
                               , rti_sh_att11                        VARCHAR2(150)
                               , rti_sh_att12                        VARCHAR2(150)
                               , rti_sh_att13                        VARCHAR2(150)
                               , rti_sh_att14                        VARCHAR2(150)
                               , rti_sh_att15                        VARCHAR2(150)
                               , rti_sh_att2                         VARCHAR2(150)
                               , rti_sh_att3                         VARCHAR2(150)
                               , rti_sh_att4                         VARCHAR2(150)
                               , rti_sh_att5                         VARCHAR2(150)
                               , rti_sh_att6                         VARCHAR2(150)
                               , rti_sh_att7                         VARCHAR2(150)
                               , rti_sh_att8                         VARCHAR2(150)
                               , rti_sh_att9                         VARCHAR2(150)
                               , rti_sl_att_cat                      VARCHAR2(30)
                               , rti_sl_att1                         VARCHAR2(150)
                               , rti_sl_att10                        VARCHAR2(150)
                               , rti_sl_att11                        VARCHAR2(150)
                               , rti_sl_att12                        VARCHAR2(150)
                               , rti_sl_att13                        VARCHAR2(150)
                               , rti_sl_att14                        VARCHAR2(150)
                               , rti_sl_att15                        VARCHAR2(150)
                               , rti_sl_att2                         VARCHAR2(150)
                               , rti_sl_att3                         VARCHAR2(150)
                               , rti_sl_att4                         VARCHAR2(150)
                               , rti_sl_att5                         VARCHAR2(150)
                               , rti_sl_att6                         VARCHAR2(150)
                               , rti_sl_att7                         VARCHAR2(150)
                               , rti_sl_att8                         VARCHAR2(150)
                               , rti_sl_att9                         VARCHAR2(150)
                               , rti_ship_to_location_code           VARCHAR2(60)
                               , rti_shipment_line_status_code       VARCHAR2(25)
                               , rti_shipment_num                    VARCHAR2(30)
                               , rti_shipped_date                    DATE
                               , rti_source_doc_quantity             NUMBER
                               , rti_source_doc_unit_of_measure      VARCHAR2(25)
                               , rti_source_document_code            VARCHAR2(25)
                               , rti_source_transaction_num          VARCHAR2(25)
                               , rti_subinventory                    VARCHAR2(10)
                               , rti_substitute_item_num             VARCHAR2(81)
                               , rti_substitute_unordered_code       VARCHAR2(25)
                               , rti_tax_amount                      NUMBER
                               , rti_tax_name                        VARCHAR2(15)
                               , rti_timecard_ovn                    NUMBER
                               , rti_to_organization_code            VARCHAR2(3)
                               , rti_transaction_status_code         VARCHAR2(25)
                               , rti_transaction_type                VARCHAR2(25)
                               , rti_transfer_license_plate_no       VARCHAR2(30)
                               , rti_truck_num                       VARCHAR2(35)
                               , rti_unit_of_measure                 VARCHAR2(25)
                               , rti_uom_code                        VARCHAR2(3)
                               , rti_use_mtl_lot                     NUMBER
                               , rti_use_mtl_serial                  NUMBER
                               , rti_validation_flag                 VARCHAR2(1)
                               , rti_vendor_cum_shipped_qty          NUMBER
                               , rti_vendor_item_num                 VARCHAR2(25)
                               , rti_vendor_lot_num                  VARCHAR2(30)
                               , rti_vendor_name                     VARCHAR2(240)
                               , rti_vendor_num                      VARCHAR2(30)
                               , rti_vendor_site_code                VARCHAR2(15)
                               , rti_waybill_airbill_num             VARCHAR2(20)
                               , rti_wip_entity_name                 VARCHAR2(24)
                               , rti_wip_line_code                   VARCHAR2(10)
                               , rti_wip_operation_seq_num           NUMBER
                               , rti_wip_resource_seq_num            NUMBER
                               , rti_E0342_first_rec_time            DATE
                               , rti_po_line_id                      NUMBER
                               , rti_po_line_location_id             NUMBER
                               , rti_po_distribution_id              NUMBER
                               , rti_shipment_line_id                NUMBER
                               , rti_deliver_to_location_id          NUMBER
                               , rti_employee_id                     NUMBER
                               , rti_ship_to_location_id             NUMBER
                               , rti_deliver_to_person_id             NUMBER
                               , rti_routing_header_id                NUMBER
                               );

                                                        
TYPE lt_ins_rec_online_tab IS TABLE OF lt_ins_rec_online_typ
INDEX BY BINARY_INTEGER;
-- +===================================================================+
-- | Name        : xx_gi_ins_rcv                                       |
-- | Description : This procedure will be invoked by the external      |
-- |               process which will be inserting the Online PO       |
-- |               receiving data into custom staging tables with all  |
-- |               the mandatory columns                               |
-- | Parameters : x_error_buff, x_retcode,x_error_msg,p_ins_rec_typ    |
-- |              ,p_commingling_receipts                              |
-- +===================================================================+

PROCEDURE XX_GI_INS_ONLINE_RCV_PROC(
                        x_errbuff               OUT VARCHAR2
                       ,x_retcode               OUT NUMBER
                       ,x_error_msg             OUT VARCHAR2
                       ,p_ins_rec_tab           IN  OUT lt_ins_rec_online_tab
                       ,p_commingling_receipts  IN  VARCHAR2
          );
  
-- +===================================================================+
                                                            
-- +===================================================================+
-- | Name        : xx_gi_cln_stg_po_rcv                                |
-- | Description : This procedure will check the RTI table for         |
-- |               successful records and delete the corresponding     |
-- |               detail record of XX_GI_RCV_PO_DTL table.            |
-- |             i.e., for cleaning of staging tables                  |
-- | Parameters : p_purge_days,x_error_buff, x_ret_code                |
-- +===================================================================+
                                                             
-- +===================================================================+
-- Procedure 2 Start for purging staging tables                        |
-- +===================================================================+
PROCEDURE XX_GI_CLN_STG_RCV_PO(
                               x_error_buff        OUT VARCHAR2
                              ,x_ret_code          OUT NUMBER
                              ,p_purge_days        IN  NUMBER
                               );
  
-- +===================================================================+
-- | Name        : xx_gi_pop_rti_po_rcv                                |
-- | Description : This procedure will populate processed records from |
-- |             staging into standard receiving interface tables      |
-- | Parameters : x_error_buff, x_ret_code                             |
-- +===================================================================+
                                                             
-- +===================================================================+
-- Procedure 3  Start for populating RCV interface  tables             |
-- +===================================================================+
PROCEDURE XX_GI_POP_RTI_RCV_PO(
                               x_err_buf   OUT VARCHAR2
                               ,x_ret_code OUT NUMBER
                              );
  
END XX_GI_PO_STE_RCV_PKG;
/
sho err