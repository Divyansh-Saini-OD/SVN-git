SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_PO_AUTORECEIPT_PKG
IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name  :  XX_PO_AUTORECEIPT_PKG                                    |
-- | Rice ID : E0220  PO Auto Receipts                                 |
-- | Description:  This package fetches data from PO/Invoice tables to |
-- |               create receipts                                     |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version  Date         Author           Remarks                     |
-- |=======  ==========   =============    ============================|
-- |DRAFT 1A 14-MAY-2007  Srividhya        Initial draft version       |
-- |                      Nagarajan                                    |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

	 gc_err_desc           xxom.xx_om_global_exceptions.description%TYPE;
         gc_err_code           xxom.xx_om_global_exceptions.error_code%TYPE;
	 gc_entity_ref         xxom.xx_om_global_exceptions.entity_ref%TYPE;
	 gn_entity_ref_id      xxom.xx_om_global_exceptions.entity_ref_id%TYPE;
         gc_exception_header   CONSTANT VARCHAR2(40) := 'PO AutoReceipt Process';
         gc_track_code         CONSTANT VARCHAR2(5)  := 'OTC';
         gc_solution_domain    CONSTANT VARCHAR2(40) := 'Purchasing';
         gc_function           CONSTANT VARCHAR2(40) := 'Auto Receiving';
         gc_err_report_type    xxom.xx_om_report_exception_t := xxom.xx_om_report_exception_t(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
-- +===================================================================+
-- | Name  : PREVALIDATE_PROC                                          |
-- | Description      : This program fetch/validates the PO/Invoice for|
-- |			the following cases:			       |
-- |			Case1: If Invoice exists for a PO and ASN not  |
-- |			recieved in 3 days from invoice creation date. |
-- |			Case2: If invoice is not made for a PO till 30 |
-- |			business days and ASN not received.	       |
-- |                                                                   |
-- | Parameters :      p_vendor_id                                     |
-- |                   x_ret_code                                      |
-- |                   x_err_buff                                      |
-- +===================================================================+

	PROCEDURE PREVALIDATE_PROC (x_errbuf    OUT NOCOPY VARCHAR2
				   ,x_retcode   OUT NOCOPY VARCHAR2
				   ,p_vendor_id IN  po_vendors.vendor_id%TYPE
				   );
-- +===================================================================+
-- | Name  : INSERT_STGTBL_PROC                                        |
-- | Description      : This program calls the custom API for inserting|
-- |			the fetched record into the staging table      |
-- |                                                                   |
-- | Parameters :       p_shipment_num  			       |
-- |			p_shipped_date	 	                       |
-- |			p_auto_transact_code 	                       |
-- |			p_employee_id		                       |
-- |			p_transaction_type1 	                       |
-- |			p_invoice_num				       |
-- |			p_invoice_date				       |
-- |			p_tot_invoice_amt 			       |
-- |			p_vendor_id 		                       |
-- |			p_ship_to_org_id 	                       |
-- |			p_processing_status 	                       |
-- |			p_receipt_source_code                          |
-- |			p_validation_flag 	                       |
-- |			p_item_id 		                       |
-- |			p_vendor_item_num 	                       |
-- |			p_item_revision 	                       |
-- |			p_po_header_id		                       |
-- |			p_po_line_id 	                               |
-- |			p_quantity 		                       |
-- |			p_UOM			                       |
-- |			p_item_desc 		                       |
-- |			p_ship_to_loc_id                               |
-- |			p_deliver_to_loc_id 	                       |
-- |			p_deliver_to_person_id                         |
-- |			p_process_mode_code                            |
-- |			p_source_doc_code			       |
-- |			p_transaction_date 			       |
-- |			p_trans_status_code			       |
-- |			p_transaction_type2			       |
-- |			p_exp_receipt_date                             |
-- +===================================================================+
	PROCEDURE INSERT_STGTBL_PROC(    p_shipment_num           IN xx_po_rcv_headers_stg.shipment_num%TYPE
                                        ,p_shipped_date           IN xx_po_rcv_headers_stg.shipped_date%TYPE
                                        ,p_auto_transact_code     IN xx_po_rcv_headers_stg.auto_transact_code%TYPE
                                        ,p_employee_id            IN xx_po_rcv_headers_stg.last_updated_by%TYPE
                                        ,p_transaction_type1      IN xx_po_rcv_headers_stg.transaction_type%TYPE
                                        ,p_invoice_num            IN xx_po_rcv_headers_stg.invoice_num%TYPE
                                        ,p_invoice_date           IN xx_po_rcv_headers_stg.invoice_date%TYPE
                                        ,p_tot_invoice_amt        IN xx_po_rcv_headers_stg.total_invoice_amount%TYPE
                                        ,p_vendor_id              IN xx_po_rcv_headers_stg.vendor_id%TYPE
                                        ,p_ship_to_org_id         IN xx_po_rcv_headers_stg.ship_to_organization_id%TYPE
                                        ,p_processing_status      IN xx_po_rcv_transactions_stg.processing_status_code%TYPE
                                        ,p_receipt_source_code    IN xx_po_rcv_transactions_stg.receipt_source_code%TYPE
                                        ,p_validation_flag        IN xx_po_rcv_headers_stg.validation_flag%TYPE
                                        ,p_item_id                IN xx_po_rcv_transactions_stg.item_id%TYPE
                                        ,p_vendor_item_num        IN xx_po_rcv_transactions_stg.vendor_item_num%TYPE
                                        ,p_item_revision          IN xx_po_rcv_transactions_stg.item_revision%TYPE
                                        ,p_po_header_id           IN xx_po_rcv_transactions_stg.po_header_id%TYPE
                                        ,p_po_line_id             IN xx_po_rcv_transactions_stg.po_line_id%TYPE
                                        ,p_quantity               IN xx_po_rcv_transactions_stg.quantity%TYPE
                                        ,p_uom                    IN xx_po_rcv_transactions_stg.unit_of_measure%TYPE
                                        ,p_item_desc              IN xx_po_rcv_transactions_stg.item_description%TYPE
                                        ,p_ship_to_loc_id         IN xx_po_rcv_transactions_stg.ship_to_location_id%TYPE
                                        ,p_deliver_to_loc_id      IN xx_po_rcv_transactions_stg.deliver_to_location_id%TYPE
                                        ,p_deliver_to_person_id   IN xx_po_rcv_transactions_stg.deliver_to_person_id%TYPE
                                        ,p_process_mode_code      IN xx_po_rcv_transactions_stg.processing_mode_code%TYPE
                                        ,p_source_doc_code        IN xx_po_rcv_transactions_stg.source_document_code%TYPE
                                        ,p_transaction_date       IN xx_po_rcv_transactions_stg.transaction_date%TYPE
                                        ,p_trans_status_code      IN xx_po_rcv_transactions_stg.transaction_status_code%TYPE
                                        ,p_transaction_type2      IN xx_po_rcv_transactions_stg.transaction_type%TYPE
                                        ,p_exp_receipt_date       IN xx_po_rcv_transactions_stg.expected_receipt_date%TYPE
                                    );

-- +===================================================================+
-- | Name  : PREVALIDATE_PROC                                          |
-- | Description      : This program Inovkes exception routine         |
-- |                                                                   |
-- | Parameters :      p_error_code                                    |
-- |                   p_error_description                             |
-- |                   p_entity_ref                                    |
-- |                   p_entity_ref_id                                 |
-- |                   x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+
                                        
PROCEDURE XX_LOG_EXCEPTION_PROC(p_error_code        IN  VARCHAR2
                               ,p_error_description IN  VARCHAR2
                               ,p_entity_ref        IN  VARCHAR2
                               ,p_entity_ref_id     IN  NUMBER
                               ,x_errbuf            OUT NOCOPY VARCHAR2
                               ,x_retcode           OUT NOCOPY VARCHAR2
                                );
END XX_PO_AUTORECEIPT_PKG;
/
SHOW ERROR