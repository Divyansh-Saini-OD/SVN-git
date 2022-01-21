SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_PO_PUNCHOUT_CONF_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_PO_PUNCHOUT_DETAILS_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_PO_PUNCHOUT_DETAILS_PKG                                                         |
  -- |                                                                                            |
  -- |  Description:  This package is used by WEB services to load Punchout confirmation          |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         13-JUN-2017  Arun Gannarapu    Initial version                                 |
  -- | 2.0         10-Nov-2017  Suresh Naragam    Changes for Buy From Ourselves Phase 2          |
  -- |                                            (Defect#43530)                                  |
  -- +============================================================================================+

  lc_processed           VARCHAR2(30):= 'PROCESSED';
  lc_debug_flag          BOOLEAN := FALSE;
  
  -- +===============================================================================================+
  -- | Name  : insert_row                                                                            |
  -- | Description     : This Procedure is used to insert the data into Shipment Tables              |
  -- | Parameters      : p_aops_order, p_po_num, p_qty, p_po_line_num, p_unit_cost, p_item, P_OUT    |
  -- +================================================================================================+
  PROCEDURE insert_row(p_aops_order    IN   VARCHAR2,
                       p_po_num        IN   VARCHAR2,
                       p_qty           IN   NUMBER,
                       p_po_line_num   IN   NUMBER,
                       p_unit_cost     IN   VARCHAR2,
                       p_item          IN   VARCHAR2,
                       P_OUT           OUT  VARCHAR2)
  IS
  BEGIN
    INSERT
    INTO xx_po_shipment_details
      (RECORD_ID,
       AOPS_ORDER,
       po_number,
       Po_line_num,
       item,
       QTY,
       unit_price,
       CREATION_DATE,
       CREATED_BY,
       LAST_UPDATE_DATE,
       LAST_UPDATED_BY,
       RECORD_STATUS)
    VALUES
      ( XX_PO_PUNCHOUT_RECORD_ID_S.NEXTVAL,
        p_aops_order,    
        p_po_num,
        p_po_line_num,
        p_item,
        p_qty,
        p_unit_cost,
        SYSDATE,
        fnd_global.user_id,
        SYSDATE,
        fnd_global.user_id,
        'NEW'
      );
      p_out := 'Record Inserted Successfully';
    COMMIT;
  EXCEPTION
    WHEN OTHERS
    THEN
      ROLLBACK;
      p_out:= 'Unexpected error inserting into staging table'||SUBSTR(sqlerrm,1,200);
      xx_po_punchout_conf_pkg.log_msg(TRUE, p_out); 
  END INSERT_ROW;

  -- +===============================================================================================+
  -- | Name  : load_ship_details                                                                     |
  -- | Description     : This Procedure to call the Receipt Record Insert Row Procedure              |
  -- | Parameters      : Aops_Order_Number, Po_Number, Qty, Po_Line_Num, Unit_Cost,  Item, Out       |
  -- +================================================================================================+

 PROCEDURE load_ship_details(
        Aops_Order_Number  IN   VARCHAR2,
        Po_Number          IN   VARCHAR2,
        Qty                IN   NUMBER,
        Po_Line_Num        IN   NUMBER,
        Unit_Cost          IN   VARCHAR2,
        Item               IN   VARCHAR2,
        Out                OUT  VARCHAR2)
  IS
  BEGIN 
    xx_po_punchout_details_pkg.insert_row(p_aops_order      => aops_order_number,
                                          p_po_num          => po_number,
                                          p_qty             => qty,
                                          p_po_line_num     => po_line_num,
                                          p_unit_cost       => unit_cost,
                                          p_item            => item,
                                          p_out             => out);
  EXCEPTION
    WHEN OTHERS
    THEN
      out := 'Error '||sqlerrm;
      xx_po_punchout_conf_pkg.log_msg(TRUE, 'ERROR '|| SQLERRM); 
  END load_ship_details;

-- +===============================================================================================+
-- | Name  : update_record_status                                                                  |
-- | Description : This Procedure updates Shipment record status                                   |
-- | Parameters : pi_po_number, pi_po_line_num, pi_record_id, pi_rec_status, pio_error_msg         |
-- +================================================================================================+
  procedure update_record_status(
        pi_po_number       IN      po_headers_all.segment1%TYPE,
        pi_po_line_num     IN      po_lines_all.line_num%TYPE,
        pi_record_id       IN      xx_po_shipment_details.record_status%TYPE,
        pi_rec_status      IN      xx_po_punch_header_info.record_status%TYPE,
        pio_error_msg      IN OUT  VARCHAR2
       )
   IS
    BEGIN
      UPDATE xx_po_shipment_details
      SET record_status = pi_rec_status,
          error_message = pio_error_msg
      where record_id   = NVL(pi_record_id, record_id)
      AND substr(po_number,1,instr(po_number,':',1)-1)     = NVL(pi_po_number, po_number)
      AND po_line_num   = NVL(pi_po_line_num, po_line_num);
 
  EXCEPTION
    WHEN OTHERS
    THEN
      pio_error_msg := 'Error while Updating the header status for: '|| pi_po_number ||' '||SUBSTR(sqlerrm,1,200);
      xx_po_punchout_conf_pkg.log_msg(TRUE, pio_error_msg); 
  END update_record_status;
  
  -- +===============================================================================================+
  -- | Name  : verify_shipment_lines                                                                 |
  -- | Description     : This Procedure used to Verify the shipment Details wiht PO Lines            |
  -- |    pi_po_number                   IN   -- PO Number                                           |
  -- |    pi_record_status               IN   -- Record Status                                       |
  -- |    po_error_msg                   OUT  -- Error Message                                       |
  -- +================================================================================================+
  PROCEDURE verify_shipment_lines(pi_po_number      IN  VARCHAR2,
                                  pi_aops_number    IN  VARCHAR2,
                                  pi_record_status  IN  VARCHAR2,
                                  po_error_msg      OUT VARCHAR2)
  IS
    ln_po_lines_count  				NUMBER;
    ln_shipment_lines_count			NUMBER;
    ln_mail_sent                    NUMBER;
    lc_error_message                VARCHAR2(4000);
    lc_translation_info             xx_fin_translatevalues%ROWTYPE;
    lc_mail_body                    VARCHAR2(32767) := NULL;
    lc_mail_subject                 VARCHAR2 (4000) := NULL;
    lc_return_status                VARCHAR2(2000) := null;
  BEGIN
    po_error_msg        := NULL;

    SELECT count(1)
    INTO ln_po_lines_count
    FROM po_lines_all pla
    WHERE EXISTS (SELECT po_header_id FROM po_headers_all pha
	          WHERE pha.po_header_id = pla.po_header_id 
                  AND segment1 = pi_po_number
                  AND org_id = fnd_global.org_id)
    AND quantity !=0;
	
    SELECT count(1)
    INTO ln_shipment_lines_count
    FROM xx_po_shipment_details
    WHERE substr(po_number,1,instr(po_number,':',1)-1) = pi_po_number;
	
    xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'PO Lines Count :'||ln_po_lines_count);
    xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Shipment Lines Count :'||ln_po_lines_count);
	
    IF ln_shipment_lines_count <> ln_po_lines_count THEN
      po_error_msg := 'Shipment Lines are not matched with PO Lines';
      xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Sending the Mail.'); 
	  
      SELECT count(1)
      INTO ln_mail_sent
      FROM xx_po_shipment_details
      WHERE substr(po_number,1,instr(po_number,':',1)-1) = pi_po_number
      AND NVL(mail_sent,'N') = 'Y';
	  
      IF ln_mail_sent = 0 THEN
        lc_mail_body := '<html> <body> <font face = "Arial" size = "2">
                         PO Lines count is not matched with the Shipment Lines Count. Please check with EAI/Inventory Team.
                        <br>
                        <br> PO Number : '||pi_po_number||
                        '<br> PO Lines Count : '||ln_po_lines_count||
                        '<br> Shipment Lines Count : '||ln_shipment_lines_count||
                        '</body></html>';

        lc_return_status := xx_po_punchout_conf_pkg.get_translation_info( pi_translation_name => 'XXPO_PUNCHOUT_CONFIG',
                                                                          pi_source_record    => 'SHIPMENT_NOTIFY',
                                                                          po_translation_info => lc_translation_info,
                                                                          po_error_msg        => lc_error_message);
																		    
        IF lc_error_message IS NULL
        THEN
    	  xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Sending the Mail.');  

          lc_mail_subject := lc_translation_info.target_value6 ||' Purchase Order :'||pi_po_number||' AOPS Order Number :'||pi_aops_number ||lc_translation_info.target_value9 ;		  

          xx_po_punchout_conf_pkg.send_mail(pi_mail_subject      =>  lc_mail_subject,
                                            pi_mail_body          =>  lc_mail_body,
                                            pi_mail_sender        =>  lc_translation_info.target_value3,
                                            pi_mail_recipient     =>  lc_translation_info.target_value4,
                                            pi_mail_cc_recipient  =>  lc_translation_info.target_value5,
                                            po_return_msg         =>  lc_error_message);
          IF lc_error_message IS NULL THEN
            UPDATE xx_po_shipment_details
            SET mail_sent = 'Y'
            WHERE substr(po_number,1,instr(po_number,':',1)-1) = pi_po_number;
            COMMIT;
          END IF;
        END IF;
      END IF;
	  
   END IF;
							   
   EXCEPTION
     WHEN OTHERS
     THEN
       po_error_msg := 'Error in verify_shipment_lines '|| substr(SQLERRM,1,2000);
       xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, po_error_msg);
  END verify_shipment_lines;

-- +===============================================================================================+
-- | Name  : perform_po_receipt                                                                    |
-- | Description : This procedure is used to create Receipt Interface Records                      |
-- | Parameters  : pi_po_number, pi_prev_po_number, pi_po_line_num, pi_transaction_date,           |
-- |               pi_transaction_qty, pi_unit_cost, pio_group_id, po_error_msg                    | 
-- +================================================================================================+

  PROCEDURE perform_po_receipt(pi_po_number          IN   po_headers_all.segment1%TYPE,
                               pi_prev_po_number     IN   po_headers_all.segment1%TYPE,
                               pi_po_line_num        IN   po_lines_all.line_num%TYPE,
                               pi_transaction_date   IN   DATE,
                               pi_transaction_qty    IN   PO_LINES_ALL.QUANTITY%type,
                               pi_unit_cost          IN   po_lines_all.unit_price%TYPE,
                               pio_group_id          IN OUT  NUMBER,
                               po_error_msg          OUT  VARCHAR2)
  IS

   lc_Vendor_rec              po_asl_suppliers_v%ROWTYPE := NULL;
   lc_rcv_header_rec          rcv_headers_interface%ROWTYPE := NULL;
   lc_rcv_tran_interface_rec  rcv_transactions_interface%ROWTYPE := NULL;
   lc_group_id                  rcv_headers_interface.group_id%TYPE := NULL;
   lc_interface_transaction_id  rcv_transactions_interface.interface_transaction_id%TYPE := NULL;
   lc_header_interface_id       rcv_headers_interface.header_interface_id%TYPE := NULL;
   lc_receipt_quantity          rcv_shipment_lines.quantity_received%type := 0;
   lc_po_rec                    po_headers_all%ROWTYPE := null;
   lc_po_line_rec               po_lines_all%ROWTYPE := null;
   lc_po_line_loc_rec           po_line_locations_all%ROWTYPE := NULL;

  BEGIN
  
    xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Inside PO reciept procedure...');
    xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Po Number'||' '||pi_po_number);
    xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'pi_prev_po_number'||' '||pi_prev_po_number);
    xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'pi_transaction_qty'||' '||pi_transaction_qty);
    xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'pi_transaction_date'||' '||pi_transaction_date);
    
    xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Getting the PO header info ..');
      
    SELECT *
    INTO lc_po_rec
    FROM po_headers_all
    WHERE segment1 = pi_po_number
    AND org_id = fnd_global.org_id;
      
    xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Getting the PO Line info ..');
 
    SELECT *
    INTO lc_po_line_rec
    FROM po_lines_all
    WHERE po_header_id = lc_po_rec.po_header_id
    AND line_num = pi_po_line_num;
      
    xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Getting the PO Line location info ..');

    SELECT *
    INTO lc_po_line_loc_rec
    FROM po_line_locations_all
    WHERE po_header_id = lc_po_rec.po_header_id
    AND po_line_id = lc_po_line_rec.po_line_id;
      
    IF ( pi_prev_po_number IS NULL OR pi_prev_po_number != pi_po_number )
    THEN
      
      SELECT rcv_headers_interface_s.NEXTVAL,
             rcv_interface_groups_s.NEXTVAL
      INTO   lc_header_interface_id,
             lc_group_id
      FROM DUAL;
      
      xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Header Interface ID : '||lc_header_interface_id);
      xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Group id : '||lc_group_id);


      xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Setting the RCV header rec ..');
      
      pio_group_id := lc_group_id;
      lc_rcv_header_rec.header_interface_id     := lc_header_interface_id;
      lc_rcv_header_rec.group_id                := lc_group_id;
      lc_rcv_header_rec.processing_status_code  := 'PENDING'; 
      lc_rcv_header_rec.receipt_source_code     := 'VENDOR'; 
      lc_rcv_header_rec.transaction_type        := 'NEW'; 
      lc_rcv_header_rec.auto_transact_code      := 'DELIVER'; 
      lc_rcv_header_rec.shipment_num            := pi_po_number;
      lc_rcv_header_rec.ship_to_organization_id := lc_po_line_loc_rec.ship_to_organization_id; 
      lc_rcv_header_rec.last_update_date        := SYSDATE;
      lc_rcv_header_rec.last_updated_by         := fnd_global.user_id;
      lc_rcv_header_rec.created_by              := fnd_global.user_id;
      lc_rcv_header_rec.creation_date           := SYSDATE;
      lc_rcv_header_rec.shipped_date            := pi_transaction_date;
      lc_rcv_header_rec.expected_receipt_date   := pi_transaction_date;
      lc_rcv_header_rec.validation_flag         := 'Y';
      lc_rcv_header_rec.vendor_id               := lc_po_rec.vendor_id;
      lc_rcv_header_rec.vendor_site_id          := lc_po_rec.vendor_site_id;

      INSERT INTO rcv_headers_interface
      VALUES lc_rcv_header_rec;
      
      xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'inserted rcv record ..');
    END IF;
   
    SELECT rcv_transactions_interface_s.NEXTVAL
    INTO   lc_interface_transaction_id
    FROM DUAL;
    
    xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Setting RCV transactions record');

    lc_rcv_tran_interface_rec.interface_transaction_id   := lc_interface_transaction_id;
    lc_rcv_tran_interface_rec.group_id                   := pio_group_id; 
    lc_rcv_tran_interface_rec.header_interface_id        := lc_header_interface_id;
    lc_rcv_tran_interface_rec.transaction_type           := 'RECEIVE';
    lc_rcv_tran_interface_rec.transaction_date           :=  pi_transaction_date; 
    lc_rcv_tran_interface_rec.processing_status_code     := 'PENDING';
    lc_rcv_tran_interface_rec.processing_mode_code       := 'BATCH';
    lc_rcv_tran_interface_rec.transaction_status_code    := 'PENDING';
    lc_rcv_tran_interface_rec.quantity                   := pi_transaction_qty;
    lc_rcv_tran_interface_rec.unit_of_measure            := lc_po_line_rec.unit_meas_lookup_code;
    lc_rcv_tran_interface_rec.interface_source_code      := 'RCV';
    lc_rcv_tran_interface_rec.item_description           := lc_po_line_rec.item_description;
    lc_rcv_tran_interface_rec.auto_transact_code         := 'DELIVER';
    lc_rcv_tran_interface_rec.receipt_source_code        := 'VENDOR';
    lc_rcv_tran_interface_rec.source_document_code       := 'PO';
    lc_rcv_tran_interface_rec.po_header_id               := lc_po_rec.po_header_id;
    lc_rcv_tran_interface_rec.po_line_id                 := lc_po_line_rec.po_line_id;
    lc_rcv_tran_interface_rec.po_line_location_id        := lc_po_line_loc_rec.line_location_id;
    lc_rcv_tran_interface_rec.validation_flag            := 'Y';
    lc_rcv_tran_interface_rec.org_id                     := lc_po_line_loc_rec.org_id;
    lc_rcv_tran_interface_rec.last_update_date           := SYSDATE;
    lc_rcv_tran_interface_rec.last_updated_by            := fnd_global.user_id;
    lc_rcv_tran_interface_rec.created_by                 := fnd_global.user_id;
    lc_rcv_tran_interface_rec.creation_date              := SYSDATE;

    INSERT INTO rcv_transactions_interface
    VALUES lc_rcv_tran_interface_rec;
    
    xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'inserted rcv transactions record ..');

  EXCEPTION
    WHEN OTHERS
    THEN
      PO_ERROR_MSG := 'Error while cancelling the PO Line number: '|| PI_PO_LINE_NUM ||' '||SUBSTR(SQLERRM,1,200);
      xx_po_punchout_conf_pkg.log_msg(TRUE, po_error_msg); 
  END perform_po_receipt; 
-- +===============================================================================================+
-- | Name  : process_pending_receipts                                                              |
-- | Description     : This is the main process, it process all the pending receipts               |
-- |                   to recieve the PO                                                           |
-- |                   This will be triggered from Concurrent Program and will run for every       |
-- |                   30 minutes as scheduled in ESP.                                             |
-- | Parameters      : errbuf, retcode, pi_status, pi_po_number                                    |
-- +================================================================================================+
     
  PROCEDURE process_pending_receipts(errbuf        OUT  VARCHAR2,
                                     retcode       OUT  VARCHAR2,
                                     pi_status     IN   xx_po_shipment_details.record_status%TYPE,
                                     pi_po_number  IN   po_headers_all.segment1%TYPE ) 
  IS
    CURSOR cur_pending_rect
    IS
    SELECT distinct substr(po_number,1,instr(po_number,':',1)-1) po_number, 
       aops_order 
       --record_id
    FROM   xx_po_shipment_details
    where  record_status       = NVL(pi_status, record_status)
    and    po_number           = NVL(pi_po_number, po_number)
    AND    record_status NOT IN (lc_processed)
    ORDER BY po_number ; --, record_id;

    CURSOR cur_pending_rect_lines(pi_po_number po_headers_all.segment1%TYPE)
    is
    SELECT pla.po_line_id, pla.unit_price po_unit_price,xpsd.qty qty_received, pla.quantity
          ,xpsd.*
    FROM   xx_po_shipment_details xpsd,
           po_headers_all pha,
           po_lines_all pla
    where  xpsd.record_status       = NVL(pi_status, xpsd.record_status)
    and    substr(xpsd.po_number,1,instr(xpsd.po_number,':',1)-1)           = pi_po_number
    AND    xpsd.po_line_num         = pla.line_num
    AND    xpsd.record_status NOT IN (lc_processed)
    AND    pha.po_header_id         = pla.po_header_id
    AND    pha.segment1             = substr(xpsd.po_number,1,instr(xpsd.po_number,':',1)-1)
    AND    pha.org_id               = fnd_global.org_id
    ORDER BY xpsd.po_number, xpsd.po_line_num;

    lc_error_message       VARCHAR2(4000);
    lc_translation_info    xx_fin_translatevalues%ROWTYPE;
    lc_trans_name          xx_fin_translatedefinition.translation_name%TYPE := 'XXPO_PUNCHOUT_CONFIG';
    lc_return_status       varchar2(2000) := null;
    lc_mail_body           VARCHAR2(32767) := NULL;
    lc_mail_subject        VARCHAR2 (4000) := NULL;
    lc_group_id            NUMBER := NULL;

    e_process_exception    EXCEPTION;
    lc_prev_po_number      po_headers_all.segment1%type;
    lc_send_email          varchar2(1);
    lc_send_final_email    varchar2(1);
    lc_quantity            po_lines_all.quantity%TYPE;
    lc_dest_location       hr_locations.location_code%TYPE;
    lc_item_num            po_lines_all.vendor_product_num%TYPE;
    lc_item_description    po_lines_all.item_description%TYPE;
    ln_receipt_unit_price  po_lines_all.unit_price%TYPE;
    ln_batch_id            NUMBER := NULL;
	
    lr_req_line_rec        po_requisition_lines_all%ROWTYPE;
    indx                   NUMBER; 
    lr_po_req_hdr_rec      xx_po_create_punchout_req_pkg.xx_po_req_hdr_rec%TYPE;
    lt_po_req_line_tbl     xx_po_create_punchout_req_pkg.xx_po_req_line_tbl%TYPE;
    lc_submit_req_import   VARCHAR2(1) := 'N';
    lc_translation_rec     xx_fin_translatevalues%ROWTYPE;
    lc_body_hdr            VARCHAR2(32000) := NULL;
    lc_body_trl            VARCHAR2(32000) := NULL;
	l_req_info             per_people_v7%ROWTYPE;

    BEGIN 

      lc_prev_po_number := NULL;

      xx_po_punchout_conf_pkg.log_msg(TRUE, 'Status :'|| pi_Status);
      xx_po_punchout_conf_pkg.log_msg(TRUE, 'Getting translation info :');
      
      lc_return_status := xx_po_punchout_conf_pkg.get_translation_info( pi_translation_name => lc_trans_name,
                                                                        pi_source_record    => 'CONFIG_DETAILS',
                                                                        po_translation_info => lc_translation_info,
                                                                        po_error_msg        => lc_error_message);
      
      IF lc_error_message IS NOT NULL
      THEN
        RAISE e_process_exception ;
      END IF;
      
      xx_po_punchout_conf_pkg.log_msg(TRUE, 'Debug flag :'|| lc_translation_info.target_value7);
      xx_po_punchout_conf_pkg.log_msg(TRUE, 'Send email flag :'|| lc_translation_info.target_value8);
      
      IF lc_translation_info.target_value7 = 'Y'
      THEN 
        lc_debug_flag := TRUE;
      END IF;
  
      -- Setting the Org Context ..
      xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Setting the Org Context. ');

      xx_po_punchout_conf_pkg.set_context(pi_translation_info => lc_translation_info,
                                          po_error_msg        => lc_error_message);

      IF lc_error_message IS NOT NULL
      THEN
        RAISE e_process_exception ;
      END IF;

      FOR cur_pending_rect_rec IN cur_pending_rect
      LOOP
        BEGIN 

          lc_error_message := NULL;
          lc_mail_body     := NULL;
          lc_group_id      := NULL;
          ln_batch_id      := fnd_global.session_id;
          indx             := 1;
          lc_translation_rec := NULL;
          lr_po_req_hdr_rec  := NULL;
          lt_po_req_line_tbl.DELETE;
 
          xx_po_punchout_conf_pkg.log_msg(TRUE, 'Processing Purchase Order :'|| cur_pending_rect_rec.po_number);
		  
          xx_po_punchout_conf_pkg.log_msg(TRUE, 'Verifying the Shipment Lines with PO Lines');
          verify_shipment_lines( pi_po_number      => cur_pending_rect_rec.po_number,
                                 pi_aops_number    => cur_pending_rect_rec.aops_order, 
                                 pi_record_status  => pi_status,
                                 po_error_msg      => lc_error_message);

          IF lc_error_message IS NULL
          THEN
            lc_send_email := 'N';
            lc_send_final_email := 'N';

            -- Get the Requisition Header Record 
            xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Getting Requisition Header Record for: '||cur_pending_rect_rec.po_number);
            lc_return_status := XX_PO_PUNCHOUT_CONF_PKG.get_req_hdr_record(pi_po_number    => cur_pending_rect_rec.po_number,
                                                                           po_req_hdr_rec  => lr_po_req_hdr_rec,
                                                                           po_error_msg    => lc_error_message);
										 
            IF lc_error_message IS NOT NULL
            THEN 
              RAISE e_process_exception; 
            END IF;

          FOR cur_rect_lines_rec IN cur_pending_rect_lines(pi_po_number => cur_pending_rect_rec.po_number)
          LOOP
            BEGIN
              lc_send_email := 'N';
			  lc_send_final_email := 'N';
              lc_quantity       := NULL;
              lc_return_status  := NULL;
              lc_error_message  := NULL;
              lc_item_num       := NULL;
              lc_item_description := NULL;
              lc_dest_location  := NULL;
              ln_receipt_unit_price := NULL;
              lr_req_line_rec   := NULL;

              --xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Unit Price before:'||cur_rect_lines_rec.unit_price);
              ln_receipt_unit_price := to_number(substr(cur_rect_lines_rec.unit_price,1,length(cur_rect_lines_rec.unit_price)-3)||'.'||substr(cur_rect_lines_rec.unit_price,length(cur_rect_lines_rec.unit_price)-2));
              
              --xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Unit Price after:'||ln_receipt_unit_price);
              

              xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Checking the PO unit Price '||cur_rect_lines_rec.po_unit_price||' With Receipt Unit Price : '||ln_receipt_unit_price);
              xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'PO Line quantity :'||cur_rect_lines_rec.quantity);
              
              xx_po_punchout_Conf_pkg.log_msg(lc_debug_flag, 'Getting the Requisition Line Record for the PO: '||cur_pending_rect_rec.po_number||' Line: '||cur_rect_lines_rec.po_line_num);				
              -- Get the Requisition Line Record 
              lc_return_status := xx_po_punchout_conf_pkg.get_req_line_record(pi_po_number    => cur_pending_rect_rec.po_number,
                                                        pi_po_line_num  => cur_rect_lines_rec.po_line_num,
                                                        po_req_line_rec => lr_req_line_rec,
                                                        po_error_msg    => lc_error_message);
              IF lc_error_message IS NOT NULL
              THEN 
                RAISE e_process_exception; 
              END IF;
			  
             --fnd_file.put_line(fnd_file.log,'Preparing Mail Body '||cur_rect_lines_rec.po_line_num||' - '||lc_item_num||' - '||cur_rect_lines_rec.quantity||' - '||lc_dest_location||' - '||cur_rect_lines_rec.qty_received);
             xx_po_punchout_conf_pkg.log_msg(lc_debug_flag,'Supplier Duns Number is '||lr_req_line_rec.supplier_duns);
             
             lc_return_status := xx_po_punchout_conf_pkg.get_translation_info( pi_translation_name => lc_trans_name,
                                                       pi_source_record    => 'SUPPLIER_DUNS',
                                                       pi_target_record    => lr_req_line_rec.supplier_duns,
                                                       po_translation_info => lc_translation_rec,
                                                       po_error_msg        => lc_error_message);
      
              IF lc_error_message IS NOT NULL
              THEN
                RAISE e_process_exception ;
              END IF;
			  
              IF cur_rect_lines_rec.qty_received > 0  -- not cancelled lines
              THEN
                -- check its fully shipped or partial 
                xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'QTY received :'||cur_rect_lines_rec.qty_received);
                xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'PO line qty :'||cur_rect_lines_rec.quantity );
                
                IF ( cur_rect_lines_rec.qty_received != 0 AND cur_rect_lines_rec.qty_received != cur_rect_lines_rec.quantity )
                THEN 
                  lc_quantity := cur_rect_lines_rec.qty_received;
                  lc_send_email := lc_translation_rec.target_value8;
                  
                  -- Partial Quantity shipped, We need to create new requisition for remaining quantity.
				  lr_req_line_rec.quantity := cur_rect_lines_rec.quantity - cur_rect_lines_rec.qty_received;
                  lt_po_req_line_tbl(indx) := lr_req_line_rec;
                  indx := indx+1;
                END IF;

               xx_po_punchout_Conf_pkg.log_msg(lc_debug_flag, 'Getting the Line Details for the PO: '||cur_pending_rect_rec.po_number||' Line: '||cur_rect_lines_rec.po_line_num);
               
               xx_po_punchout_Conf_pkg.get_line_details(pi_po_number        => cur_pending_rect_rec.po_number,
                                                        pi_po_line_num      => cur_rect_lines_rec.po_line_num,
                                                        po_item_num         => lc_item_num,
                                                        po_item_description => lc_item_description,
                                                        po_requested_qty    => cur_rect_lines_rec.quantity,
                                                        po_dest_location    => lc_dest_location,
                                                        po_error_msg        => lc_error_message);
                IF lc_error_message IS NOT NULL
                THEN
                  RAISE e_process_exception ;
                END IF;
				
                IF ( cur_rect_lines_rec.po_unit_price != ln_receipt_unit_price OR lc_quantity > 0 ) 
                THEN
                  xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Updating the PO Line with Receipt Quantity.'||'PO line:'||cur_rect_lines_rec.po_line_num || 'Confirmed qty :'||
                                                cur_rect_lines_rec.qty_received ||' New Unit Price :'||ln_receipt_unit_price );

                  xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Calling Update PO Line .....');
                  xx_po_punchout_Conf_pkg.update_po_line(pi_po_number     => cur_pending_rect_rec.po_number,
                                                         pi_po_line_num   => cur_rect_lines_rec.po_line_num ,
                                                         pi_confirmed_qty => lc_quantity,
                                                         pi_new_price     => ln_receipt_unit_price,
                                                         po_return_status => lc_return_status,
                                                         po_error_msg     => lc_error_message);

                 IF lc_error_message IS NOT NULL
                 THEN
                   RAISE e_process_exception ;
                 END IF;
               END IF;  

               xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Calling Perform PO Receipt.....');
                
               perform_po_receipt(pi_po_number        =>   cur_pending_rect_rec.po_number,
                                  pi_prev_po_number   =>   lc_prev_po_number,
                                  pi_po_line_num      =>   cur_rect_lines_rec.po_line_num,
                                  pi_transaction_date =>   cur_rect_lines_rec.creation_date,
                                  pi_transaction_qty  =>   cur_rect_lines_rec.qty_received,
                                  pi_unit_cost        =>   ln_receipt_unit_price,
                                  pio_group_id        =>   lc_group_id,
                                  po_error_msg        =>   lc_error_message);

               lc_prev_po_number := cur_pending_rect_rec.po_number;
      
               IF lc_error_message IS NOT NULL
               THEN
                RAISE e_process_exception ;
               END IF;

              ELSIF cur_rect_lines_rec.qty_received = 0 -- cancelled lines
              THEN
                xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Received Quantity is 0, Canceling the PO Line.');
                lc_send_email := lc_translation_rec.target_value8;

                xx_po_punchout_Conf_pkg.log_msg(lc_debug_flag, 'Getting the Line Details for the PO: '||cur_pending_rect_rec.po_number||' Line: '||cur_rect_lines_rec.po_line_num);
               
                xx_po_punchout_Conf_pkg.get_line_details(pi_po_number       => cur_pending_rect_rec.po_number,
                                                        pi_po_line_num      => cur_rect_lines_rec.po_line_num,
                                                        po_item_num         => lc_item_num,
                                                        po_item_description => lc_item_description,
                                                        po_requested_qty    => cur_rect_lines_rec.quantity,
                                                        po_dest_location    => lc_dest_location,
                                                        po_error_msg        => lc_error_message);
														
                IF lc_error_message IS NOT NULL
                THEN 
                  RAISE e_process_exception; 
                END IF;

                lt_po_req_line_tbl(indx) := lr_req_line_rec;
                indx := indx+1;

                -- Call the API to cancel the PO and Requisition lines .
                xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Cancelling PO Lines and Requsition Lines for the PO: '||cur_pending_rect_rec.po_number||' ,Line: '||cur_rect_lines_rec.po_line_num);
                xx_po_punchout_Conf_pkg.cancel_po_req_lines(pi_po_number     => cur_pending_rect_rec.po_number,
                                                            pi_po_line_num   => cur_rect_lines_rec.po_line_num,
                                                            po_return_status => lc_return_status,
                                                            po_error_msg     => lc_error_message);
                       
                IF lc_error_message IS NOT NULL
                THEN 
                  RAISE e_process_exception; 
                END IF; 
				  
			END IF;
 
              -- Get line details for Email body --If line has been cancelled or paritally shipped .
              
              IF lc_send_email = 'Y'
              THEN 
                lc_send_final_email := 'Y';
                --xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Mail Body: '||lc_mail_body);
                lc_mail_body := lc_mail_body||xx_po_punchout_conf_pkg.get_mail_body (lc_translation_rec.target_value19,
                                                           NULL,
                                                           NULL,
                                                           cur_rect_lines_rec.po_line_num,
                                                           cur_rect_lines_rec.item,
                                                           lc_item_description,
                                                           cur_rect_lines_rec.quantity,
                                                           lc_dest_location,
                                                           NULL,
                                                           cur_rect_lines_rec.qty_received);
              END IF;

              xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Updating the Record Status to PROCESSED for Record id :'||cur_rect_lines_rec.record_id);   
              update_record_status(pi_po_number       => cur_pending_rect_rec.po_number,
                                   pi_po_line_num     => cur_rect_lines_rec.po_line_num,
                                   PI_RECORD_ID       => cur_rect_lines_rec.record_id,
                                   pi_rec_status      => lc_processed,
                                   pio_error_msg      => lc_error_message);
            EXCEPTION 
              WHEN OTHERS
              THEN 
                xx_po_punchout_conf_pkg.log_msg(TRUE,'Error Message :'||NVL(lc_error_message,substr(sqlerrm,1,2000)));
                xx_po_punchout_conf_pkg.log_msg(TRUE, 'Updating the Record Status to ERROR for record id :'|| cur_rect_lines_rec.record_id);   
                xx_po_punchout_conf_pkg.log_error(null,NVL(lc_error_message,substr(sqlerrm,1,2000)));   
                update_record_status( pi_po_number       => cur_pending_rect_rec.po_number,
                                      pi_po_line_num     => cur_rect_lines_rec.po_line_num,
                                      pi_record_id       => cur_rect_lines_rec.record_id,
                                      pi_rec_status      => 'ERROR',
                                      pio_error_msg      => lc_error_message);
            END;
          END LOOP;  -- Lines  
   
          IF lc_send_final_email = 'Y'
          THEN
            xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Sending the Mail.');               

            lc_mail_subject := NULL;
            lc_body_hdr     := NULL;
            lc_body_trl     := NULL;
            -- Getting Mail Body Header
            xx_po_punchout_conf_pkg.get_mailing_info(pi_template           => lc_translation_rec.target_value19,
                             pi_requisition_number => lr_po_req_hdr_rec.segment1,
                             pi_po_number          => cur_pending_rect_rec.po_number,
                             pi_aops_number        => cur_pending_rect_rec.aops_order,
                             po_mail_subject       => lc_mail_subject,
                             po_mail_body_hdr      => lc_body_hdr,
                             po_mail_body_trl      => lc_body_trl,
                             pi_translation_info   => lc_translation_rec);
            IF NVL(lc_translation_rec.target_value17,'N') = 'Y' THEN   -- Send Mail to Requestor Flag
              xx_po_punchout_conf_pkg.log_msg(TRUE, 'Getting the Requestor Info, Requestor Name, Requestor Email ');
              l_req_info := NULL;
	          lc_return_status := xx_po_punchout_conf_pkg.get_requestor_info (pi_preparer_id     => lr_po_req_hdr_rec.preparer_id ,
                                                                           xx_requestor_info  => l_req_info,
                                                                           xx_error_message   => lc_error_message);

              IF lc_error_message IS NOT NULL
              THEN
                RAISE e_process_exception;
              END IF;	
              xx_po_punchout_conf_pkg.send_mail(pi_mail_subject       =>  lc_mail_subject,
                                                pi_mail_body          =>  lc_body_hdr||lc_mail_body||lc_body_trl,
                                                pi_mail_sender        =>  lc_translation_rec.target_value3,
                                                pi_mail_recipient     =>  l_req_info.email_address,
                                                pi_mail_cc_recipient  =>  NULL,
                                                po_return_msg         =>  lc_error_message);
              IF lc_error_message IS NOT NULL
              THEN
                RAISE e_process_exception ;
              END IF;
			ELSE 
              xx_po_punchout_conf_pkg.send_mail(pi_mail_subject      =>  lc_mail_subject,
                                                pi_mail_body          =>  lc_body_hdr||lc_mail_body||lc_body_trl,
                                                pi_mail_sender        =>  lc_translation_rec.target_value3,
                                                pi_mail_recipient     =>  lc_translation_rec.target_value4,
                                                pi_mail_cc_recipient  =>  lc_translation_rec.target_value5,
                                                po_return_msg         =>  lc_error_message);
            END IF;
          END IF;

          xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Commiting the changes..');
          COMMIT;
		  END IF;
       EXCEPTION 
         WHEN OTHERS 
         THEN 
           rollback;
           xx_po_punchout_conf_pkg.log_msg(TRUE, 'unable to process the Pending Punchout Receipts :'|| SQLERRM);   
           xx_po_punchout_conf_pkg.log_error(null,NVL(lc_error_message,substr(sqlerrm,1,2000)));   
           update_record_status(pi_po_number        => cur_pending_rect_rec.po_number,
                                pi_po_line_num      => NULL,
                                pi_record_id        => NULL,
                                pi_rec_status       => 'ERROR',
                                pio_error_msg       => lc_error_message);

       END;
       IF NVL(lc_translation_rec.target_value13,'N') = 'Y'
       THEN
         xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Creating Purchase Requisition: ');
            xx_po_create_punchout_req_pkg.create_purchase_requisition( 
                  po_req_return_status      => lc_return_status,
                  po_req_return_message     => lc_error_message,
                  po_submit_req_import      => lc_submit_req_import,
                  pi_debug_flag             => lc_debug_flag,
                  pi_batch_id               => ln_batch_id,
                  pi_req_header_rec         => lr_po_req_hdr_rec,
                  pi_req_line_detail_tab    => lt_po_req_line_tbl,
                  pi_translation_info       => lc_translation_rec);

         IF lc_error_message IS NOT NULL
         THEN
           xx_po_punchout_conf_pkg.log_msg(lc_debug_flag, 'Error While Creating Purchase Requisition: '||lc_error_message);
           xx_po_punchout_conf_pkg.mail_error_info( pi_translation_info       => lc_translation_rec,
                            pi_req_header_rec         => lr_po_req_hdr_rec,
                            pi_req_line_detail_tab    => lt_po_req_line_tbl,
                            pi_po_number              => cur_pending_rect_rec.po_number,
                            pi_aops_number            => cur_pending_rect_rec.aops_order,
                            pi_error_message          => lc_error_message);
           RAISE e_process_exception ;
         END IF;
         --lc_submit_req_import := 'Y';
       END IF;
         lc_prev_po_number := cur_pending_rect_rec.po_number;
      end LOOP; -- Header 
	  
      -- Calling the Requisition Import
      IF NVL(lc_submit_req_import,'N') = 'Y'
      THEN
        xx_po_punchout_conf_pkg.log_msg(TRUE, 'Submitting PO import process for Batch id '|| ln_batch_id );
        xx_po_punchout_conf_pkg.submit_req_import(p_batch_id         =>  ln_batch_id,
                                                  p_debug_flag       =>  lc_debug_flag,
                                                  x_error_message    =>  lc_error_message,
                                                  x_return_status    =>  lc_return_status);
        IF NVL(lc_return_status,'S') != 'S'
        THEN
          RAISE e_process_exception;
        END IF;
      END IF;
  EXCEPTION 
  WHEN OTHERS 
    THEN 
      xx_po_punchout_conf_pkg.log_msg(TRUE, 'unable to process the PO confirmation details :'|| SQLERRM);   
      xx_po_punchout_conf_pkg.log_error(null,NVL(lc_error_message,substr(sqlerrm,1,2000)));   
  end PROCESS_PENDING_RECEIPTS;
end XX_PO_PUNCHOUT_DETAILS_PKG;
/