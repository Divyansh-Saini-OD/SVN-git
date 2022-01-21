SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_PO_AUTORECEIPT_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name  	:  XX_PO_AUTORECEIPT_PKG                               |
-- | Rice ID 	:  E0220  PO Auto Receipts                             |
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
AS
-- +===================================================================+
-- | Name  : XX_LOG_EXCEPTION_PROC                                     |
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
                                )
AS
BEGIN

           gc_err_report_type.p_exception_header  :=    gc_exception_header;
           gc_err_report_type.p_track_code        :=    gc_track_code;
           gc_err_report_type.p_solution_domain   :=    gc_solution_domain;
           gc_err_report_type.p_function          :=    gc_function;
           gc_err_report_type.p_error_code        :=    p_error_code;
	   gc_err_report_type.p_error_description :=    p_error_description;
	   gc_err_report_type.p_entity_ref        :=    p_entity_ref;
 	   gc_err_report_type.p_entity_ref_id     :=    p_entity_ref_id;


           XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(p_report_exception => gc_err_report_type,
                                                       x_err_buf          =>x_errbuf,
                                                       x_ret_code         =>x_retcode
                                                       );
EXCEPTION
WHEN OTHERS THEN
 ROLLBACK;
 x_retcode    := FND_API.G_RET_STS_ERROR;
 gc_err_desc  :=SUBSTR(SQLERRM,1,500);
 gc_err_code  := SQLCODE;
 x_errbuf     :=  gc_err_desc||'-'||gc_err_code;		
 FND_FILE.PUT_LINE (FND_FILE.LOG, 'Exception Handler Error'||x_errbuf);
 
END XX_LOG_EXCEPTION_PROC;

-- +===================================================================+
-- | Name  : PREVALIDATE_PROC                                          |
-- | Description      : This program fetch/validates the PO/Invoice for|
-- |                    the following cases:			       |
-- |			Case1: If Invoice exists for a PO and ASN not  |
-- |			recieved in <n> days from inv creation date.   |
-- |			Case2: If invoice is not made for a PO till <n>|
-- |			business days and ASN not received.	       |
-- |                                                                   |
-- | Parameters :      p_vendor_id                                     |
-- |                   x_ret_code                                      |
-- |                   x_err_buff                                      |
-- +===================================================================+

PROCEDURE PREVALIDATE_PROC (x_errbuf OUT NOCOPY VARCHAR2
			   ,x_retcode OUT NOCOPY VARCHAR2
			   ,p_vendor_id IN  po_vendors.vendor_id%TYPE
			   )
IS

	 --Declaration of local variables
	ln_business_days_winv    NUMBER;
	ln_business_days_woinv   NUMBER;
	ln_quantity_to_receive   NUMBER;
	ln_rcv_tolerance         mtl_system_items_b.qty_rcv_tolerance%TYPE;
	ln_received_quantity     rcv_shipment_lines.quantity_received%TYPE;
        ln_invoice_amount        ap_invoices_all.invoice_amount%TYPE DEFAULT 0;
        ln_invoice_amt           ap_invoices_all.invoice_amount%TYPE DEFAULT 0;
       	ln_invoice_tot_quantity  ap_invoice_distributions_all.quantity_invoiced%TYPE DEFAULT 0;
        ln_invoice_temp_qty      ap_invoice_distributions_all.quantity_invoiced%TYPE DEFAULT 0;
	ln_quantity_cum_rcv      rcv_shipment_lines.quantity_received%TYPE DEFAULT 0;
	ln_user_id               fnd_user.user_id%TYPE := FND_GLOBAL.USER_ID;
	ln_quantity_due          rcv_shipment_lines.quantity_received%TYPE DEFAULT 0;
	ln_tolerable_quantity    mtl_system_items_b.qty_rcv_tolerance%TYPE;
	lc_unit_of_measure       rcv_shipment_lines.primary_unit_of_measure%TYPE;
        ln_po_transactions       NUMBER DEFAULT 0;
        ln_inv_transactions      NUMBER DEFAULT 0;
        ln_po_total_records      NUMBER DEFAULT 0;

      --Definition of cursors
      --Fetch all purchase order details with order type DropShip and auto receipt enabled
      --at the supplier site level
      CURSOR lcu_fetch_po
      IS
         SELECT   PHA.po_header_id po_header_id
	         ,PLA.po_line_id po_line_id
                 ,PDA.po_distribution_id po_distribution_id
                 ,PLLA.line_location_id line_location_id
                 ,PV.vendor_id vendor_id
                 ,PLLA.ship_to_location_id ship_to_loc_id
                 ,PLA.item_id item_id
                 ,PLA.vendor_product_num vendor_product_num
                 ,PLA.item_revision item_revision
                 ,PLA.unit_meas_lookup_code unit_meas_lookup_code
                 ,PLA.item_description item_description
                 ,PLA.unit_price unit_price
                 ,PLLA.ship_to_organization_id ship_to_organization_id
                 ,PDA.deliver_to_location_id deliver_to_location_id
                 ,PDA.deliver_to_person_id deliver_to_person_id
                 ,SUM (PLLA.quantity) quantity_ordered
                 ,SUM (PLLA.quantity_received) quantity_received
                 ,PLLA.need_by_date need_by_date
                 ,MSI.qty_rcv_tolerance qty_rcv_tolerance
         FROM     po_headers_all PHA
                 ,po_lines_all PLA
		 ,po_vendors PV
                 ,po_line_locations_all PLLA
                 ,po_distributions_all PDA
		 ,xx_po_vendor_sites_kff_v XPVS
		 ,mtl_system_items_b MSI
         WHERE    PHA.vendor_id = PV.vendor_id
         AND      PHA.po_header_id = PLA.po_header_id
         AND      PLA.po_line_id = PLLA.po_line_id
         AND      PLLA.quantity_received <= PLLA.quantity
         AND      PDA.line_location_id = PLLA.line_location_id
         AND      PHA.attribute_category = (
						SELECT	MEANING
						FROM	FND_LOOKUPS
						WHERE	LOOKUP_TYPE = 'OD_PO_CANCEL_ISP'
						AND	LOOKUP_CODE = 'DROPSHIP'
					   )
         AND	  XPVS.vendor_site_id = PHA.vendor_site_id
	 AND	  MSI.inventory_item_id = PLA.item_id
	 AND	  MSI.serial_number_control_code = 1
	 AND      PLLA.ship_to_organization_id = MSI.organization_id
	 AND	  NVL(XPVS.allow_auto_receipt,'N')='Y'
         AND      PHA.authorization_status = 'APPROVED'
         AND	  NVL(PLA.closed_code,'OPEN') = 'OPEN'
         AND      PV.vendor_id = NVL (p_vendor_id, pv.vendor_id)
         GROUP BY PV.vendor_id
                 ,PHA.po_header_id
                 ,PLA.po_line_id
                 ,PLA.item_id
                 ,PLA.vendor_product_num
                 ,PLA.item_revision
                 ,PLA.unit_meas_lookup_code
                 ,PLA.item_description
                 ,PLA.unit_price
                 ,PLLA.line_location_id
                 ,PLLA.ship_to_location_id
                 ,PLLA.need_by_date
                 ,PLLA.ship_to_organization_id
                 ,PDA.po_distribution_id
                 ,PDA.deliver_to_location_id
                 ,PDA.deliver_to_person_id
                 ,MSI.qty_rcv_tolerance
         ORDER BY PHA.po_header_id;

     
      -- Fetch all the invoice details
      CURSOR lcu_inv_details (p_po_distribution_id NUMBER)
      IS
         SELECT   AIA.creation_date invoice_date
		 ,AIA.invoice_num invoice_num
                 ,AIA.vendor_id vendor_id
		 ,AIA.invoice_id invoice_id
                 ,AIDA.quantity_invoiced
                 ,AIA.invoice_amount
         FROM     ap_invoice_distributions_all AIDA
		 ,ap_invoices_all AIA
         WHERE    AIDA.invoice_id = AIA.invoice_id
         AND      AIDA.po_distribution_id = p_po_distribution_id
         AND      (TRUNC(AIA.creation_date) + ln_business_days_winv)<=TRUNC(SYSDATE)
         GROUP BY AIA.vendor_id
                  ,AIA.invoice_num
		 ,AIA.invoice_id
		 ,AIA.creation_date
                 ,AIDA.quantity_invoiced
                 ,AIA.invoice_amount
         ORDER BY AIDA.quantity_invoiced;


 BEGIN

      
      ln_business_days_winv  := FND_PROFILE.VALUE ('XX_PO_AUTORCPT_WINV');
      ln_business_days_woinv := FND_PROFILE.VALUE ('XX_PO_AUTORCPT_WOINV');
      
    -- Loop for the list of purchase order distributions (Open loop)
      FOR c_lcu_fetch_po IN lcu_fetch_po
      LOOP
       ln_po_total_records := ln_po_total_records + 1;
	-- Call API to get QUANTITY_DUE
	RCV_QUANTITIES_S.GET_AVAILABLE_QUANTITY(
				'RECEIVE',
				 c_lcu_fetch_po.LINE_LOCATION_ID,
				'VENDOR',
				NULL,
				NULL,
				NULL,
				ln_quantity_due,
				ln_tolerable_quantity,
				lc_unit_of_measure);
      
       -- variable initialize

         
         ln_received_quantity    :=c_lcu_fetch_po.quantity_received;
         ln_invoice_temp_qty     := 0;
         ln_quantity_to_receive  := 0;
         ln_quantity_cum_rcv     := 0;
         ln_invoice_tot_quantity := 0;
         

          
         
	-- open a Loop of fetching the invoice details
	-- as there can be multiple invoice for a purchase order and we need to
	-- fetch all the invoice details. After fetching the invoice details
	-- calculate the quantity to be received and insert into the staging table.

     
            FOR c_lcu_inv_details IN lcu_inv_details (c_lcu_fetch_po.po_distribution_id)
            LOOP
	    -- Receipt should be created for all the invoice where Invoice date should be
	    -- less than 3(set in profile) days in the past and invoice quantity
	    -- should not be equal to zero

              
              ln_invoice_amt      := c_lcu_inv_details.invoice_amount;
              ln_invoice_temp_qty  := c_lcu_inv_details.quantity_invoiced;

              

              -- Assign the Running Total to the Variable
              ln_invoice_tot_quantity := ln_invoice_tot_quantity + ln_invoice_temp_qty;

              
              -- If the Quantity is greater than Ordered Quantity with tolerance pickup the lesser value i.e
              -- Ordered Quantity with tolerance
              IF ln_invoice_tot_quantity>FLOOR(c_lcu_fetch_po.quantity_ordered
                       + (c_lcu_fetch_po.quantity_ordered * NVL(c_lcu_fetch_po.qty_rcv_tolerance/100,0))) 
              THEN
              
               ln_invoice_tot_quantity := FLOOR(c_lcu_fetch_po.quantity_ordered
                       + (c_lcu_fetch_po.quantity_ordered * NVL(c_lcu_fetch_po.qty_rcv_tolerance/100,0)));
              END IF;
                  
      

               -- Validate if the 3 days Scenario is set and if received quantity is lesser than Total
               -- ordered quantity with tolerance and also invoice quantity is more than Received quantity
               IF TRUNC(c_lcu_inv_details.invoice_date) + ln_business_days_winv <= TRUNC(SYSDATE)
                  AND ln_invoice_tot_quantity > 0 
                  AND FLOOR(c_lcu_fetch_po.quantity_ordered
                       + (c_lcu_fetch_po.quantity_ordered * NVL(c_lcu_fetch_po.qty_rcv_tolerance/100,0))) 
                       >  ln_received_quantity
                  AND ln_invoice_tot_quantity > ln_received_quantity 
               THEN
                                             
                       ln_quantity_to_receive := (ln_invoice_tot_quantity - ln_received_quantity) - ln_quantity_to_receive;
                       ln_quantity_cum_rcv    := ln_quantity_cum_rcv + ln_quantity_to_receive;
		       
                -- call to procedure INSERT_STGBL_PROC
                	IF ln_quantity_to_receive > 0
			THEN
                               ln_inv_transactions := ln_inv_transactions + 1;
                               
  		  		INSERT_STGTBL_PROC
                     		(p_shipment_num              => 'POAutoRecpt'|| c_lcu_inv_details.invoice_num
                     		,p_shipped_date              => c_lcu_inv_details.invoice_date
	                	,p_auto_transact_code        => 'RECEIVE'
                    		,p_employee_id               => ln_user_id
                     		,p_transaction_type1         => 'NEW'
                     		,p_invoice_num               => c_lcu_inv_details.invoice_num
                     		,p_invoice_date              => c_lcu_inv_details.invoice_date
                     		,p_tot_invoice_amt           => ln_invoice_amt
                     		,p_vendor_id                 => c_lcu_inv_details.vendor_id
                     		,p_ship_to_org_id            => c_lcu_fetch_po.ship_to_loc_id
                     		,p_processing_status         => 'PENDING'
                     		,p_receipt_source_code       => 'VENDOR'
                     		,p_validation_flag           => 'Y'
                     		,p_item_id                   => c_lcu_fetch_po.item_id
                     		,p_vendor_item_num           => c_lcu_fetch_po.vendor_product_num
                     		,p_item_revision             => c_lcu_fetch_po.item_revision
                     		,p_po_header_id              => c_lcu_fetch_po.po_header_id
                     		,p_po_line_id                => c_lcu_fetch_po.po_line_id
                     		,p_quantity                  => ln_quantity_to_receive
                     		,p_uom                       => c_lcu_fetch_po.unit_meas_lookup_code
                     		,p_item_desc                 => c_lcu_fetch_po.item_description
                     		,p_ship_to_loc_id            => c_lcu_fetch_po.ship_to_loc_id
                     		,p_deliver_to_loc_id         => c_lcu_fetch_po.deliver_to_location_id
                     		,p_deliver_to_person_id      => c_lcu_fetch_po.deliver_to_person_id
                     		,p_process_mode_code         => 'BATCH'
                     		,p_source_doc_code           => 'PO'
                     		,p_transaction_date          => SYSDATE
                     		,p_trans_status_code         => 'PENDING'
                     		,p_transaction_type2         => 'SHIP'
                     		,p_exp_receipt_date          => SYSDATE
                     		);
			ELSE
		    		FND_MESSAGE.SET_NAME ('XXOM', 'ODP_PO_ZERO_RECEIVE_QTY');
	                        gc_err_desc := fnd_message.get;
		    		gc_entity_ref := 'po_header_id';
		    		gn_entity_ref_id := c_lcu_fetch_po.po_header_id;
                                XX_LOG_EXCEPTION_PROC( p_error_code          =>'ODP_PO_ZERO_RECEIVE_QTY'
                                                      ,p_error_description   =>gc_err_desc
                                                      ,p_entity_ref          =>gc_entity_ref
                                                      ,p_entity_ref_id       =>gn_entity_ref_id
                                                      ,x_errbuf              =>x_errbuf
                                                      ,x_retcode             =>x_retcode
                                );
		    		
		  		FND_FILE.PUT_LINE (FND_FILE.LOG, gc_err_desc||c_lcu_fetch_po.po_header_id);
		 	END IF;
                  
               END IF;
            END LOOP;
        
         -- If PO need by date is past 30 days from sysdate then receipt should be
	 -- created for the due quantity. So insert records into the staging table with
	 -- the due quantity
         IF   TRUNC(c_lcu_fetch_po.need_by_date) + ln_business_days_woinv <= TRUNC(SYSDATE)
              AND NVL(ln_quantity_due,0) > NVL(ln_quantity_cum_rcv,0)
         THEN
          -- Quantity Due is derived from the Standard API  hence commented below code

            ln_quantity_to_receive := (ln_quantity_due - ln_quantity_cum_rcv);

            ln_invoice_amount := ln_quantity_to_receive * c_lcu_fetch_po.unit_price;
            ln_po_transactions := ln_po_transactions + 1;
              
               -- call to procedure insert_stgbl_proc
               INSERT_STGTBL_PROC
                  (p_shipment_num              => 'POAutoRecpt'|| c_lcu_fetch_po.po_header_id
                  ,p_shipped_date              => SYSDATE
                  ,p_auto_transact_code        => 'RECEIVE'
                  ,p_employee_id               => ln_user_id
                  ,p_transaction_type1         => 'NEW'
                  ,p_invoice_num               => 'POAutoRecpt'|| c_lcu_fetch_po.po_header_id
                  ,p_invoice_date              => SYSDATE
                  ,p_tot_invoice_amt           => ln_invoice_amount
                  ,p_vendor_id                 => c_lcu_fetch_po.vendor_id
                  ,p_ship_to_org_id            => c_lcu_fetch_po.ship_to_loc_id
                  ,p_processing_status         => 'PENDING'
                  ,p_receipt_source_code       => 'VENDOR'
                  ,p_validation_flag           => 'Y'
                  ,p_item_id                   => c_lcu_fetch_po.item_id
                  ,p_vendor_item_num           => c_lcu_fetch_po.vendor_product_num
                  ,p_item_revision             => c_lcu_fetch_po.item_revision
                  ,p_po_header_id              => c_lcu_fetch_po.po_header_id
                  ,p_po_line_id                => c_lcu_fetch_po.po_line_id
                  ,p_quantity                  => ln_quantity_to_receive
                  ,p_uom                       => c_lcu_fetch_po.unit_meas_lookup_code
                  ,p_item_desc                 => c_lcu_fetch_po.item_description
                  ,p_ship_to_loc_id            => c_lcu_fetch_po.ship_to_loc_id
                  ,p_deliver_to_loc_id         => c_lcu_fetch_po.deliver_to_location_id
                  ,p_deliver_to_person_id      => c_lcu_fetch_po.deliver_to_person_id
                  ,p_process_mode_code         => 'BATCH'
                  ,p_source_doc_code           => 'PO'
                  ,p_transaction_date          => SYSDATE
                  ,p_trans_status_code         => 'PENDING'
                  ,p_transaction_type2         => 'SHIP'
                  ,p_exp_receipt_date          => SYSDATE
                 );
	     
        END IF;
         
      END LOOP;
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Total Number of Records'||ln_po_total_records);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Total Number Processed Receipt Records'||ln_po_transactions);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Total Number Processed Invoice Records'||ln_inv_transactions);
      x_retcode := FND_API.G_RET_STS_SUCCESS ;
      x_errbuf  := 'Success';
      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK;
         gc_err_desc 	  := SUBSTR(SQLERRM,1,500);
         x_retcode   := FND_API.G_RET_STS_ERROR;
         x_errbuf  :=  SQLCODE||'-'||gc_err_desc;		
         gc_entity_ref 	  := 'Vendor_id';
         gn_entity_ref_id := NVL (p_vendor_id, 0);
         XX_LOG_EXCEPTION_PROC(p_error_code           =>SQLCODE
                              ,p_error_description    =>gc_err_desc
                              ,p_entity_ref           =>gc_entity_ref
                              ,p_entity_ref_id        =>gn_entity_ref_id
                              ,x_errbuf               =>x_errbuf
                              ,x_retcode              =>x_retcode
                                );
         FND_FILE.PUT_LINE (fnd_file.LOG, gc_err_desc);
   END PREVALIDATE_PROC;

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
   PROCEDURE INSERT_STGTBL_PROC (
      p_shipment_num           IN xx_po_rcv_headers_stg.shipment_num%TYPE
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
     )
   IS
      ln_interface_id   xx_po_rcv_headers_stg.header_interface_id%TYPE;
      ln_errbuf         VARCHAR2(2000);
      ln_retcode        VARCHAR2(100);
      
   BEGIN
      -- Since we do not have the custom API which will insert into the staging
      -- table, created a dummy table for inserting which will not be used in
      -- future
      -- Dummy sequence
      SELECT XX_PO_AUTORECEIPT_HEADER_S.NEXTVAL
      INTO   ln_interface_id
      FROM   DUAL;

      INSERT INTO xx_po_rcv_headers_stg
                  (header_interface_id
                  ,processing_status_code
                  ,receipt_source_code
                  ,transaction_type
                  ,auto_transact_code
                  ,shipment_num
                  ,employee_id
                  ,invoice_num
                  ,invoice_date
                  ,total_invoice_amount
                  ,vendor_id
                  ,ship_to_organization_id
                  ,shipped_date
                  ,expected_receipt_date
                  ,validation_flag
                  ,created_by
                  ,creation_date
                  ,last_update_date
                  ,last_updated_by
                  )
           VALUES (ln_interface_id
                   ,p_processing_status
                   ,p_receipt_source_code
                   ,p_transaction_type1
                   ,p_auto_transact_code
                   ,p_shipment_num
                   ,p_employee_id
                   ,p_invoice_num
                   ,p_invoice_date
                   ,p_tot_invoice_amt
                   ,p_vendor_id
                   ,p_ship_to_org_id
                   ,p_shipped_date
                   ,p_exp_receipt_date
                   ,p_validation_flag
                   ,p_employee_id
                   ,SYSDATE
                   ,SYSDATE
                   ,p_employee_id
                  );

      INSERT INTO xx_po_rcv_transactions_stg
                  (interface_transaction_id, 
                  transaction_type
                  ,transaction_date
                  ,processing_status_code
                  ,processing_mode_code
                  ,transaction_status_code
                  ,quantity
                  ,unit_of_measure
                  ,item_id
                  ,vendor_item_num
                  ,item_revision
                  ,item_description
                  ,auto_transact_code
                  ,ship_to_location_id
                  ,receipt_source_code
                  ,source_document_code
                  ,po_header_id
                  ,po_line_id
                  ,location_id
                  ,deliver_to_location_id
                  ,deliver_to_person_id
                  ,expected_receipt_date
                  ,header_interface_id
                  ,validation_flag
                  ,last_update_date
                  ,last_updated_by
                  ,creation_date
                  ,created_by
                  )
           VALUES (XX_PO_AUTORECEIPT_TRANSID_S.NEXTVAL
                  ,p_transaction_type2
                  ,p_transaction_date
                  ,p_processing_status
                  ,p_process_mode_code
                  ,p_trans_status_code
                  ,p_quantity
                  ,p_uom
                  ,p_item_id
                  ,p_vendor_item_num
                  ,p_item_revision
                  ,p_item_desc
                  ,p_auto_transact_code
                  ,p_ship_to_loc_id
                  ,p_receipt_source_code
                  ,p_source_doc_code
                  ,p_po_header_id
                  ,p_po_line_id
                  ,p_ship_to_loc_id
                  ,p_deliver_to_loc_id
                  ,p_deliver_to_person_id
                  ,p_exp_receipt_date
                  ,ln_interface_id
                  ,p_validation_flag
                  ,SYSDATE
                  ,p_employee_id
                  ,SYSDATE
                  ,p_employee_id
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         gc_err_desc      := SUBSTR(SQLERRM,1,500);
         gc_entity_ref    := 'Vendor_id';
         gn_entity_ref_id := NVL (p_vendor_id, 0);
         XX_LOG_EXCEPTION_PROC(p_error_code          =>SQLCODE
                              ,p_error_description   =>gc_err_desc
                              ,p_entity_ref          =>gc_entity_ref
                              ,p_entity_ref_id       =>gn_entity_ref_id
                              ,x_errbuf              =>ln_errbuf
                              ,x_retcode             =>ln_retcode
                               );
         FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE||'-'||gc_err_desc);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Insertion Status'||'-'||ln_errbuf||'-'||ln_retcode);
         
   END INSERT_STGTBL_PROC;
END XX_PO_AUTORECEIPT_PKG;
/
SHOW ERRORS