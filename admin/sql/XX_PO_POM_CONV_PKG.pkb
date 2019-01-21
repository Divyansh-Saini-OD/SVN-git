CREATE OR REPLACE PACKAGE Body XX_PO_POM_CONV_PKG AS


-- +===========================================================================+
-- |    Office Depot - Project Simplify                                        |
-- |     Office Depot                                                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name  : XX_PO_POM_INTERFACE_CNV_PKG
-- | Description      : Package Body
-- |
-- |
-- |
-- |Change Record:
-- |
-- |===============
-- |
-- |Version    Date          Author           Remarks
-- |=======    ===========   ===============  =================================+
-- |DRAFT 1A   10-JAN-2017   Antonio Morales  Initial draft version  
-- |
-- | 1.1       28-JUL-2017   Vinay Singh      Added procedure to populate
-- |                                          the header attribute
-- |
-- |Objective: Conversion/Validation of POM to PO
-- |
-- |Concurrent Program: OD: PO Purchase Order Conversion Child Program
-- |                    XXPOCNVCH
-- +===========================================================================+

    cn_commit    CONSTANT INTEGER := 70000;  --- Number of transactions per commit and/or bulk limit
    cc_module    CONSTANT VARCHAR2(100) := 'XX_PO_POM_CONV_PKG';
    cc_procedure CONSTANT VARCHAR2(100) := 'CHILD_MAIN';
    cn_max_loop  CONSTANT INTEGER := 9999999;     --- Max. time in minutes to wait in a loop

    ex_dml_errors EXCEPTION;

    PRAGMA EXCEPTION_INIT(ex_dml_errors, -24381);

PROCEDURE child_main(x_retcode            OUT NOCOPY NUMBER
                    ,x_errbuf             OUT NOCOPY VARCHAR2
                    ,p_validate_only_flag  IN        VARCHAR2  DEFAULT 'N' -- Y/N
                    ,p_reset_status_flag   IN        VARCHAR2  DEFAULT 'N' -- Y/N
                    ,p_batch_id            IN        INTEGER   DEFAULT NULL
                    ,p_debug_flag          IN        VARCHAR2  DEFAULT 'N' -- Y/N
                    ,p_pdoi_batch_size     IN        INTEGER   DEFAULT 5000
                    ) IS

    ln_request_id           INTEGER := fnd_global.conc_request_id();
    ln_debug_level          INTEGER := oe_debug_pub.g_debug_level;
    lc_errbuf               VARCHAR2(4000);
    ln_retcode              INTEGER := 0;
    ln_errors               INTEGER := 0;
    ln_error_hdr            INTEGER := 0;
    ln_error_lin            INTEGER := 0;
    ln_read_hdr             INTEGER := 0;
    ln_read_lin             INTEGER := 0;
    ln_write_hdr            INTEGER := 0;
    ln_write_lin            INTEGER := 0;
    ln_write_dis            INTEGER := 0;
    ln_write_loc            INTEGER := 0;
    ln_skip_rec             INTEGER := 0;
    ln_closed_lines         INTEGER := 0;
    lc_error_flag           VARCHAR2(1) := 'N';
    lc_message              VARCHAR2(100);

    ln_count_0              INTEGER := 0;
    ln_lint                 INTEGER := 0;
    ln_po                   VARCHAR2(30);

    lr_rowid                ROWID;

    ln_conversion_id        INTEGER := 0;
    lc_system_code          VARCHAR2(100);
    ln_error_flag           INTEGER := 0;
    ln_ven_site_code        INTEGER := 0;
    ln_process_flag         INTEGER := 0;
    ln_failed_process       INTEGER := 0;
    ln_last_int_id          INTEGER := 0;
    
    lc_approval_status      VARCHAR2(20);
    lc_closed_code          VARCHAR2(20);
    ld_need_by_date         DATE;
    ld_promised_date        DATE;
    lc_fob                  VARCHAR2(20);
    lc_freight_terms        VARCHAR2(20);
    ld_creation_date        DATE;
    lc_note_to_vendor       VARCHAR2(4000);
    lc_note_to_receiver     VARCHAR2(4000);
    lc_process_flag         VARCHAR2(20);
    lc_organization_id      VARCHAR2(20);
    lc_attribute_category   VARCHAR2(100);
    lc_drop_ship_flag       VARCHAR2(20);

    CURSOR c_hdr (p_batch_id INTEGER
                 ,p_status   VARCHAR2
                 ,p_reset    VARCHAR2
               ) IS
    WITH vendor AS
    (
     SELECT /*+ materialize parallel(2) */
            ven.vendor_id
           ,ven.vendor_site_id
           ,ven.org_id
           ,ven.attribute7
           ,ven.attribute9
           ,ven.vendor_site_code_alt
           ,ven.attribute8 vendor_site_category
           ,ven.vendor_site_code  vendor_site_code_ebs
           ,sup.vendor_name
           ,ven.terms_id venterms_id
       FROM ap_supplier_sites_all ven
           ,ap_suppliers          sup
      WHERE ven.purchasing_site_flag = 'Y'
        AND NVL(ven.inactive_date,sysdate) >= trunc(sysdate)
        AND ven.vendor_id = sup.vendor_id
    )
   ,apterms AS
    (
      SELECT /*+ materialize parallel(2) */
             apt.term_id
            ,nvl(apt.discount_percent,0) discount_percent
            ,nvl(apt.discount_days,0) discount_days
            ,nvl(apt.due_days,0) due_days
        FROM ap_terms_lines apt
            ,ap_terms_tl aph
       WHERE NVL(trunc(aph.end_date_active),sysdate+1) >= trunc(sysdate)
         AND aph.term_id = apt.term_id
    )
   ,atc AS
    (
     SELECT /*+ materialize parallel(2) */
            a.segment6
           ,l.location_id
       FROM mtl_parameters p
           ,hr_locations l
           ,gl_code_combinations a
      WHERE l.inventory_organization_id = p.organization_id
        AND a.code_Combination_id = p.material_Account
    )
   ,int_ven AS
    (
     SELECT /*+ materialize parallel(2) */
            source_value1 int_ven_code
       FROM xx_fin_translatedefinition xtd,
            xx_fin_translatevalues xtv
      WHERE xtd.translation_name = 'PO_POM_INT_VENDOR_EXCL'
        AND xtd.translate_id = xtv.translate_id
    )
     SELECT /*+ parallel(2) */
            stg.rowid rid
           ,stg.control_id
           ,stg.conv_action
           ,stg.source_system_code
           ,stg.source_system_ref
           ,stg.audit_id
           ,stg.record_id
           ,stg.batch_id
           ,stg.interface_header_id
           ,stg.document_num
           ,stg.currency_code
           ,stg.vendor_site_code
           ,stg.ship_to_location
           ,stg.fob
           ,stg.freight_terms
           ,stg.note_to_vendor
           ,stg.note_to_receiver
           ,stg.approval_status
           ,stg.closed_code
           ,stg.vendor_doc_num
           ,stg.attribute10
           ,stg.creation_date
           ,stg.last_update_date
           ,stg.reference_num
           ,stg.rate_type
           ,stg.agent_id
           ,stg.request_id
           ,stg.distribution_code   
           ,stg.po_type             
           ,stg.num_lines           
           ,stg.cost                
           ,stg.ord_rec_shpd        
           ,stg.lb                  
           ,stg.net_po_total_cost   
           ,stg.drop_ship_flag      
           ,stg.ship_via            
           ,stg.back_orders         
           ,stg.order_dt            
           ,stg.ship_dt             
           ,stg.arrival_dt          
           ,stg.cancel_dt           
           ,stg.release_date        
           ,stg.revision_flag       
           ,stg.last_ship_dt        
           ,stg.last_receipt_dt     
           ,stg.terms_disc_pct      
           ,stg.terms_disc_days     
           ,stg.terms_net_days      
           ,stg.allowance_basis_code
           ,stg.allowance_dollars   
           ,stg.allowance_percent   
           ,stg.pom_created_by      
           ,stg.pgm_entered_by      
           ,stg.pom_changed_by      
           ,stg.pgm_changed_by      
           ,stg.cust_order_sub_nbr  
           ,stg.cust_order_nbr
           ,apt.term_id  terms_id
           ,stg.ship_to_location_id
           ,stg.process_flag
           ,stg.attribute15
           ,hrl.location_id
           ,hrl.location_code      
           ,NVL(ven7.vendor_id,NVL(ven9.vendor_id,vena.vendor_id)) vendor_id
           ,NVL(ven7.org_id,NVL(ven9.org_id,vena.org_id)) org_id
           ,NVL(ven7.attribute7,NVL(ven9.attribute7,vena.attribute9)) vendor_num
           ,NVL(ven7.vendor_site_id,NVL(ven9.vendor_site_id,vena.vendor_site_id)) vendor_site_id
           ,NVL(ven7.vendor_name,NVL(ven9.vendor_name,vena.vendor_name)) vendor_name
           ,NVL(ven7.vendor_site_category,NVL(ven9.vendor_site_category,vena.vendor_site_category)) vendor_site_category
           ,NVL(ven7.venterms_id,NVL(ven9.venterms_id,vena.venterms_id)) venterms_id
           ,NVL(atc.segment6,'10') segment6
           ,int_ven.int_ven_code
       FROM xx_po_hdrs_conv_stg stg
            LEFT JOIN hr_locations_all hrl
                   ON hrl.attribute1 = lpad(stg.ship_to_location,6,'0')
                  AND hrl.inventory_organization_id IS NOT NULL
            LEFT JOIN vendor ven7
                   ON ltrim(ven7.attribute7,'0') = ltrim(stg.vendor_site_code,'0')
            LEFT JOIN vendor ven9
                   ON ltrim(ven9.attribute9,'0') = ltrim(stg.vendor_site_code,'0')
            LEFT JOIN vendor vena
                   ON ltrim(vena.vendor_site_code_alt,'0') = ltrim(stg.vendor_site_code,'0')
            LEFT JOIN apterms apt
                   ON apt.discount_percent = stg.terms_disc_pct*100
                  AND apt.discount_days = stg.terms_disc_days
                  AND apt.due_days = stg.terms_net_days
            LEFT JOIN atc
                   ON atc.location_id = hrl.location_id
            LEFT JOIN int_ven
                   ON int_ven.int_ven_code = ltrim(stg.vendor_site_code,'0')
      WHERE batch_id = p_batch_id
        AND process_flag LIKE (CASE WHEN p_reset = 'Y' THEN '%'
                                   ELSE p_status
                               END)
        AND process_flag < 6;

    TYPE thdr IS TABLE OF c_hdr%ROWTYPE;
    
    t_hdr thdr := thdr();

    CURSOR c_lin (p_batch_id NUMBER) IS
    WITH uom_trans AS
    (
     SELECT /*+ materialize parallel(2) */
            source_value1
           ,target_value1
       FROM xx_fin_translatedefinition xtd
           ,xx_fin_translatevalues xtv
      WHERE xtd.translation_name = 'PO_POM_UOM'
        AND xtd.translate_id = xtv.translate_id
    )
    SELECT /*+ index(ipo,mtl_system_items_b_n1) parallel(2) */
           stg.rowid rid
          ,stg.control_id
          ,stg.conv_action
          ,stg.source_system_code
          ,stg.request_id
          ,stg.source_system_ref
          ,stg.interface_line_id
          ,stg.interface_header_id
          ,stg.line_num
          ,stg.item
          ,stg.quantity
          ,stg.ship_to_location
          ,stg.line_reference_num
          ,stg.uom_code
-- (AM 9/29/17)
-- Defect NAIT-12514 UOM is blank on conversion data file and is failing
          ,DECODE(stg.uom_code,NULL,ipo.primary_uom_code,uom.target_value1) new_uom_code
          ,stg.unit_price
          ,stg.line_attribute6
          ,stg.shipment_num
          ,stg.dept                
          ,stg.class               
          ,stg.vendor_product_code 
          ,stg.extended_cost       
          ,stg.qty_shipped         
          ,stg.qty_received  
          ,stg.seasonal_large_order
          ,stg.organization_id
          ,stg.note_to_vendor
          ,stg.creation_date
          ,stg.note_to_receiver
          ,stg.need_by_date
          ,stg.promised_date
          ,stg.fob
          ,stg.freight_terms
          ,stg.process_flag
          ,stg.ship_to_location_id
          ,stg.closed_code
-- (AM 9-29-17) 
-- Defect NAIT-12518 Receipt conversion records are failing due to PO LINE CLOSED. The PO line status is being closed due to Integral file record.
-- The Integral file should not be utilized to close PO lines during conversion.
-- The lines should remain open so receipts can come in.
--          ,CASE WHEN poi.po_number IS NOT NULL AND NVL(poi.received_qty,0) = NVL(stg.quantity,0) AND NVL(poi.billed_qty,0) = 0 THEN 'CLOSED'
--                ELSE NULL
--           END closed_code_final
          ,stg.document_num
          ,hrl.location_id
          ,hrl.location_code
          ,itm.inventory_item_id item_id
          ,NULL attribute_category
          ,NULL drop_ship_flag
      FROM xx_po_lines_conv_stg stg
           LEFT JOIN hr_locations_all hrl
                  ON hrl.attribute1 = lpad(stg.ship_to_location,6,'0')
                 AND hrl.inventory_organization_id IS NOT NULL
           LEFT JOIN mtl_system_items_b itm
                  ON itm.segment1 = ltrim(stg.item,'0')
                 AND hrl.inventory_organization_id = itm.organization_id 
           LEFT JOIN uom_trans uom
                  ON uom.source_value1 = stg.uom_code
           LEFT JOIN mtl_system_items_b ipo
                  ON ipo.segment1 = ltrim(stg.item,'0')
                 AND ipo.organization_id = 441 
     WHERE batch_id = p_batch_id
       AND process_flag = 2
     ORDER BY interface_header_id;
    
    TYPE tlin IS TABLE OF c_lin%ROWTYPE;
    
    t_lin tlin := tlin();

    TYPE teflag IS TABLE OF INTEGER;
    
    t_eflag_hdr teflag := teflag();

    t_eflag_lin teflag := teflag();

PROCEDURE log_errors (p_error_msg         IN VARCHAR2
                     ,p_control_id        IN INTEGER
                     ,p_staging_table     IN VARCHAR2
                     ,p_column            IN VARCHAR2
                     ,p_value             IN VARCHAR2
                     ,p_oracle_code       IN VARCHAR2
                     ,p_oracle_msg        IN VARCHAR2
                     ,p_source_system_ref IN VARCHAR2
                     ) IS

BEGIN
      xx_com_conv_elements_pkg.log_exceptions_proc(p_conversion_id        => ln_conversion_id
                                                  ,p_record_control_id    => p_control_id
                                                  ,p_source_system_code   => ''
                                                  ,p_package_name         => cc_module
                                                  ,p_procedure_name       => cc_procedure
                                                  ,p_staging_table_name   => p_staging_table
                                                  ,p_staging_column_name  => p_column
                                                  ,p_staging_column_value => p_value
                                                  ,p_source_system_ref    => p_source_system_ref 
                                                  ,p_batch_id             => p_batch_id
                                                  ,p_exception_log        => p_error_msg
                                                  ,p_oracle_error_code    => p_oracle_code
                                                  ,p_oracle_error_msg     => p_oracle_msg
                                                  );
END log_errors;

PROCEDURE od_po_conv_status_prc IS

  l_error_log            VARCHAR2(2):= 'N';
  l_error_msg            VARCHAR2(2000);
  l_success_req_cnt      NUMBER;

  --- Cursor to Fetch records with Success Status

  CURSOR cur_validate_req IS

      SELECT DISTINCT
             xxd.document_num
            ,xxd.cust_order_nbr
            ,xxd.cust_order_sub_nbr
            ,xxd.cust_id
        FROM xx_po_hdrs_conv_stg xxd,
             xx_po_lines_conv_stg xxi
       WHERE xxd.interface_header_id = xxi.interface_header_id
         AND xxd.process_flag = 7
         AND xxd.batch_id = p_batch_id
         AND NOT EXISTS (SELECT 1
                           FROM xx_po_header_attributes
                          WHERE po_number = xxd.document_num);
     
      TYPE tsuccess IS TABLE OF cur_validate_req%ROWTYPE;

      t_success tsuccess;

  BEGIN

      -- fetch all successful records from staging table

      FND_FILE.PUT_LINE(FND_FILE.LOG,' Starting The PO Conversion Status Prc ');

     OPEN cur_validate_req;

     LOOP

           FETCH cur_validate_req
           BULK COLLECT
           INTO t_success LIMIT cn_commit;

           EXIT WHEN t_success.COUNT = 0;

           FORALL i IN t_success.FIRST .. t_success.LAST
           
                  INSERT
                    INTO xx_po_header_attributes
                        (po_number,          
                         cust_order_nbr,        
                         cust_order_sub_nbr,
                         creation_date,
                         last_update_date,
                         cust_id                     
                        )
                select  t_success(i).document_num
                       ,t_success(i).cust_order_nbr
                       ,t_success(i).cust_order_sub_nbr
                       ,sysdate
                       ,sysdate
                       ,t_success(i).cust_id
             FROM dual;
                       
           COMMIT;

              END LOOP;
           
END od_po_conv_status_prc;

PROCEDURE update_errored_rows IS

  ln_count INTEGER := 0;

  CURSOR c_del IS
  SELECT DISTINCT
         NVL(il.interface_header_id,hi.interface_header_id) interface_header_id
    FROM xx_po_hdrs_conv_stg hr
             JOIN xx_po_lines_conv_stg li
               ON hr.interface_header_id = li.interface_header_id
        LEFT JOIN po_lines_interface il
               ON hr.interface_header_id = il.interface_header_id
        LEFT JOIN po_headers_interface hi
               ON hr.interface_header_id = hi.interface_header_id
   WHERE 1=1
     AND hr.batch_id = p_batch_id
     AND (li.process_flag = 3 OR hr.process_flag = 3)
     AND (il.interface_header_id IS NOT NULL
          OR hi.interface_header_id IS NOT NULL);

  TYPE tdel IS TABLE OF c_del%ROWTYPE;

  t_del tdel;


BEGIN

 fnd_file.put_line(fnd_file.log,'Start update_errored_rows rest_flag');

 OPEN c_del;

 LOOP

   FETCH c_del
    BULK COLLECT
    INTO t_del LIMIT cn_commit;

   EXIT WHEN t_del.COUNT = 0;

   FORALL d IN t_del.FIRST .. t_del.LAST
          DELETE
            FROM po_headers_interface
           WHERE interface_header_id = t_del(d).interface_header_id;

   FOR d IN t_del.FIRST .. t_del.LAST
   LOOP
      ln_write_hdr := ln_write_hdr - SQL%BULK_ROWCOUNT(d);
      ln_count := ln_count + SQL%BULK_ROWCOUNT(d);
   END LOOP;

   COMMIT;

   fnd_file.put_line(fnd_file.log,'Deleted from po_headers_interface='||ln_count);

   FORALL d IN t_del.FIRST .. t_del.LAST
          DELETE
            FROM po_lines_interface
           WHERE interface_header_id = t_del(d).interface_header_id;

   FOR d IN t_del.FIRST .. t_del.LAST
   LOOP
       ln_write_lin := ln_write_lin - SQL%BULK_ROWCOUNT(d);
      ln_count := ln_count + SQL%BULK_ROWCOUNT(d);
   END LOOP;

   COMMIT;

   fnd_file.put_line(fnd_file.log,'Deleted from po_lines_interface='||ln_count);

   FORALL d IN t_del.FIRST .. t_del.LAST
          DELETE
            FROM po_distributions_interface
           WHERE interface_header_id = t_del(d).interface_header_id;

   FOR d IN t_del.FIRST .. t_del.LAST
   LOOP
       ln_write_dis := ln_write_dis - SQL%BULK_ROWCOUNT(d);
      ln_count := ln_count + SQL%BULK_ROWCOUNT(d);
   END LOOP;

   COMMIT;

   fnd_file.put_line(fnd_file.log,'Deleted from po_distributions_interface='||ln_count);

   FORALL d IN t_del.FIRST .. t_del.LAST
          DELETE
            FROM po_line_locations_interface
           WHERE interface_header_id = t_del(d).interface_header_id;

   FOR d IN t_del.FIRST .. t_del.LAST
   LOOP
       ln_write_loc := ln_write_loc - SQL%BULK_ROWCOUNT(d);
      ln_count := ln_count + SQL%BULK_ROWCOUNT(d);
   END LOOP;

   COMMIT;

   fnd_file.put_line(fnd_file.log,'Deleted from po_line_locations_interface='||ln_count);

 END LOOP;

 CLOSE c_del;

 fnd_file.put_line(fnd_file.log,'End update_errored_rows');

END update_errored_rows;

PROCEDURE sync_process_flag IS

  CURSOR c_sync IS
  SELECT distinct 
         hr.interface_header_id
        ,li.process_flag lin_flag
        ,hr.process_flag hdr_flag
    FROM xx_po_hdrs_conv_stg hr
        ,xx_po_lines_conv_stg li
   WHERE hr.interface_header_id = li.interface_header_id
     AND hr.batch_id = p_batch_id
     AND li.process_flag <> hr.process_flag;


  TYPE tsync IS TABLE OF c_sync%ROWTYPE;

  t_sync tsync;

BEGIN

 fnd_file.put_line(fnd_file.log,'Start sync_process_flag');

 OPEN c_sync;

 fnd_file.put_line(fnd_file.log,'Open cursor sync_process_flag');

 LOOP

   FETCH c_sync
   BULK COLLECT
   INTO t_sync LIMIT cn_commit;

   EXIT WHEN t_sync.COUNT = 0;

   FORALL d IN t_sync.FIRST .. t_sync.LAST
          UPDATE xx_po_hdrs_conv_stg
             SET process_flag = t_sync(d).lin_flag
           WHERE t_sync(d).hdr_flag <> 3
             AND interface_header_id = t_sync(d).interface_header_id
             AND batch_id = p_batch_id;
   COMMIT;

   FORALL d IN t_sync.FIRST .. t_sync.LAST
          UPDATE xx_po_lines_conv_stg
             SET process_flag = t_sync(d).hdr_flag
           WHERE t_sync(d).lin_flag <> 3
             AND interface_header_id = t_sync(d).interface_header_id
             AND batch_id = p_batch_id;
   COMMIT;

 END LOOP;

 CLOSE c_sync;

 fnd_file.put_line(fnd_file.log,'End sync_process_flag');

END sync_process_flag;

PROCEDURE insert_headers IS

 ln_int_id INTEGER;

BEGIN

-- Insert in headers interface table

     FOR i IN t_hdr.FIRST .. t_hdr.LAST
     LOOP
             ln_int_id := t_hdr(i).interface_header_id;
             BEGIN
                INSERT
                  INTO po_headers_interface
                      (interface_header_id
                      ,batch_id
                      ,document_num
                      ,currency_code
                      ,vendor_site_code
                      ,ship_to_location
                      ,fob
                      ,freight_terms
                      ,note_to_vendor
                      ,note_to_receiver
                      ,approval_status
                      ,closed_code
                      ,vendor_doc_num
                      ,attribute10
                      ,creation_date
                      ,reference_num
                      ,vendor_num
                      ,interface_source_code
                      ,attribute1
                      ,process_code
                      ,action
                      ,document_type_code
                      ,org_id
                      ,rate_type
                      ,vendor_id
                      ,agent_id
                      ,vendor_name
                      ,vendor_site_id
                      ,terms_id
                      ,attribute_category
                      ,attribute15  -- saved legacy po number
                       ) 
                SELECT t_hdr(i).interface_header_id
                      ,t_hdr(i).batch_id
                      ,t_hdr(i).document_num
                      ,CASE t_hdr(i).currency_code
                            WHEN 'USA' THEN 'USD'
                            WHEN 'CAN' THEN 'CAD'
                            ELSE t_hdr(i).currency_code
                       END
                      ,t_hdr(i).vendor_id
                      ,t_hdr(i).ship_to_location
                      ,CASE t_hdr(i).fob WHEN 'D' THEN 'RECEIVING'
                                         WHEN 'B' THEN 'SHIPPING'
                                         WHEN 'O' THEN 'SHIPPING'
                                         ELSE substr(t_hdr(i).fob,1,2)
                       END
                      ,DECODE(t_hdr(i).freight_terms,'CO','CC',t_hdr(i).freight_terms)  -- Defect NAIT-12515 Freight Terms errors from PO Conversion 
                      ,t_hdr(i).note_to_vendor
                      ,t_hdr(i).note_to_receiver
-- Changed 1/26/18 Antonio Morales (by Suresh P)
                      ,'APPROVED'
--                      ,CASE t_hdr(i).closed_code
--                            WHEN 'PD' THEN 'INCOMPLETE'
--                            ELSE 'APPROVED'
--                       END  -- approval_status
--                      ,CASE t_hdr(i).closed_code
--                            WHEN 'PD' THEN 'INCOMPLETE'
--                            ELSE 'OPEN'
--                       END  -- close_code
                      ,'OPEN'
-- end change
                      ,t_hdr(i).vendor_doc_num
                      ,t_hdr(i).attribute10
                      ,t_hdr(i).creation_date
                      ,'PO_MULTI_SHIPMENT'
                      ,t_hdr(i).vendor_num
                      ,'NA-POCONV'
                      ,'NA-POCONV'
                      ,'PENDING'
                      ,'ORIGINAL'
                      ,'STANDARD'
                      ,t_hdr(i).org_id
                      ,t_hdr(i).rate_type
                      ,t_hdr(i).vendor_id
                      ,t_hdr(i).agent_id
                      ,t_hdr(i).vendor_name
                      ,t_hdr(i).vendor_site_id
                      ,t_hdr(i).terms_id
-- May 16
-- July 19 Nisha updated 9/19/17
                      ,CASE t_hdr(i).vendor_site_category
                            WHEN 'TR-CON' THEN 'Consignment'
                            WHEN 'TR-FRONTDOOR' THEN CASE WHEN t_hdr(i).segment6 = 10 THEN 'FrontDoor Retail'
                                                          ELSE 'FrontDoor DC'
                                                     END
                            WHEN 'TR-IMP' THEN 'Direct Import'
                            ELSE  CASE t_hdr(i).po_type 
                                       WHEN 'NC'  THEN DECODE(t_hdr(i).drop_ship_flag,'Y','DropShip NonCode-SPL Order','Non-Code')
                                       WHEN 'NS'  THEN 'New Store'
                                       WHEN 'RE'  THEN 'Replenishment'
                                       WHEN 'SO'  THEN 'DropShip NonCode-SPL Order'
                                       WHEN 'VW'  THEN 'DropShip VW'
                                       ELSE 'Trade'
                                  END
                       END  -- attribute_category
                      ,t_hdr(i).attribute15 -- legacy po number
                  FROM dual
                 WHERE t_eflag_hdr(i) = 0;

                ln_write_hdr := ln_write_hdr + 1;

             EXCEPTION
                    WHEN DUP_VAL_ON_INDEX THEN
                         log_errors (p_error_msg         => 'Insert duplicated header id='||t_hdr(i).interface_header_id
                                    ,p_control_id        => t_hdr(i).control_id
                                    ,p_staging_table     => 'XX_PO_HDRS_CONV_STG'
                                    ,p_column            => NULL
                                    ,p_value             => NULL
                                    ,p_oracle_code       => sqlcode
                                    ,p_oracle_msg        => sqlerrm
                                    ,p_source_system_ref => t_hdr(i).source_system_ref
                                    );        
                         fnd_file.put_line(fnd_file.log,'Insert duplicated header id='||t_hdr(i).interface_header_id);
                         t_eflag_hdr(i) := 1;
                         UPDATE xx_po_hdrs_conv_stg
                            SET process_flag = 3
                          WHERE process_flag <> 3
                            AND interface_header_id = t_hdr(i).interface_header_id;
                         COMMIT;
                    WHEN OTHERS THEN
                         log_errors (p_error_msg         => 'Insert error header id='||t_hdr(i).interface_header_id
                                    ,p_control_id        => t_hdr(i).control_id
                                    ,p_staging_table     => 'XX_PO_HDRS_CONV_STG'
                                    ,p_column            => NULL
                                    ,p_value             => NULL
                                    ,p_oracle_code       => sqlcode
                                    ,p_oracle_msg        => sqlerrm
                                    ,p_source_system_ref => t_hdr(i).source_system_ref
                                    );        
                         fnd_file.put_line(fnd_file.log,'Insert error header id='||t_hdr(i).interface_header_id);
                         t_eflag_hdr(i) := 1;
                         UPDATE xx_po_hdrs_conv_stg
                            SET process_flag = 3
                          WHERE process_flag <> 3
                            AND interface_header_id = t_hdr(i).interface_header_id;
                         COMMIT;
             END;

     END LOOP;

     COMMIT;
EXCEPTION

     WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Insert error header id='||ln_int_id);
          ROLLBACK;
          RAISE;

END insert_headers;

PROCEDURE insert_lines AS

  ln_lin_next_val INTEGER;
  ln_dis_next_val INTEGER;
  ln_llc_next_val INTEGER;

  lc_match        VARCHAR2(1) := NULL;

BEGIN


     FOR i IN t_lin.FIRST .. t_lin.LAST
     LOOP

          IF t_eflag_lin(i) = 0 THEN

             -- Collect all sequences
             SELECT po_lines_interface_s.NEXTVAL
                   ,po_distributions_interface_s.NEXTVAL
                   ,po_line_locations_interface_s.NEXTVAL
               INTO ln_lin_next_val
                   ,ln_dis_next_val
                   ,ln_llc_next_val
               FROM dual;

             -- Match approval level

             IF    t_lin(i).attribute_category = 'FrontDoor Retail' THEN
                   lc_match := 'N';
             ELSIF t_lin(i).attribute_category = 'FrontDoor DC' THEN
                   lc_match := 'Y';
             ELSIF t_lin(i).attribute_category = 'DropShip NonCode-SPL Order' AND t_lin(i).drop_ship_flag = 'Y' THEN
                   lc_match := 'N';                         
             ELSIF t_lin(i).attribute_category = 'Non-Code' AND t_lin(i).drop_ship_flag = 'N' THEN
                   lc_match := 'Y';                         
             ELSIF t_lin(i).attribute_category = 'New Store' THEN
                   lc_match := 'Y';
             ELSIF t_lin(i).attribute_category = 'Replenishment' THEN
                   lc_match := 'Y';
             ELSIF t_lin(i).attribute_category = 'DropShip NonCode-SPL Order' THEN
                   lc_match := 'N';
             ELSIF t_lin(i).attribute_category = 'DropShip VW' THEN
                   lc_match := 'N';
             ELSE --default receipt required flag
                   lc_match := 'N';             
             END IF;

             -- Insert in lines interface table --

             BEGIN
                INSERT
                  INTO po_lines_interface
                      (interface_line_id
                      ,interface_header_id
                      ,line_num
                      ,item
                      ,item_id
                      ,vendor_product_num
                      ,quantity
                      ,ship_to_location
                      ,shipment_num
                      ,line_reference_num
                      ,uom_code
                      ,unit_price
                      ,line_attribute6
                      ,need_by_date
                      ,promised_date
                      ,fob
                      ,freight_terms
                      ,creation_date
                      ,note_to_vendor
                      ,note_to_receiver
                      ,action
                      ,shipment_type
                      ,line_type
                      ,line_loc_populated_flag
                      ,organization_id
                      ,closed_code
                      ,closed_reason
                      ,closed_by
                      ,inspection_required_flag
                      ,receipt_required_flag
                      ) 
                SELECT ln_lin_next_val
                      ,t_lin(i).interface_header_id
                      ,t_lin(i).line_num
                      ,t_lin(i).item
                      ,t_lin(i).item_id
                      ,t_lin(i).vendor_product_code
                      ,DECODE(t_lin(i).quantity,0,0.0000000001,t_lin(i).quantity)
                      ,t_lin(i).ship_to_location
                      ,t_lin(i).shipment_num
                      ,t_lin(i).line_reference_num
                      ,t_lin(i).new_uom_code
                      ,t_lin(i).unit_price
                      ,t_lin(i).line_attribute6
                      ,t_lin(i).need_by_date
                      ,t_lin(i).promised_date
                      ,t_lin(i).fob
                      ,t_lin(i).freight_terms
                      ,t_lin(i).creation_date
                      ,t_lin(i).note_to_vendor
                      ,t_lin(i).note_to_receiver
                      ,'ORIGINAL'
                      ,'STANDARD'
                      ,'Goods'
                      ,'Y'
                      ,t_lin(i).organization_id
-- (AM 9-29-17) 
-- Defect NAIT-12518 Receipt conversion records are failing due to PO LINE CLOSED.
-- The PO line status is being closed due to Integral file record.
-- The Integral file should not be utilized to close PO lines during conversion.
-- The lines should remain open so receipts can come in.
                      ,t_lin(i).closed_code
--                      ,DECODE(t_lin(i).closed_code_final,NULL,NULL,'Closed by conversion')  closed_reason
--                      ,DECODE(t_lin(i).closed_code_final,NULL,NULL,'461848') closed_by
                      ,NULL closed_reason
                      ,NULL closed_by
                      ,'N'       -- Combination to determine 2 or 3 way matching 
                      ,lc_match  -- 'Y' =3 way matching 'N'=2 way matching
                  FROM dual;

                  ln_write_lin := ln_write_lin + 1;

             EXCEPTION
                  WHEN OTHERS THEN
                       log_errors (p_error_msg         => 'Error inserting line='||t_lin(i).interface_header_id||
                                                         ' line='||t_lin(i).line_num
                                  ,p_control_id        => t_lin(i).control_id
                                  ,p_staging_table     => 'XX_PO_LINES_CONV_STG'
                                  ,p_column            => NULL
                                  ,p_value             => NULL
                                  ,p_oracle_code       => sqlcode
                                  ,p_oracle_msg        => sqlerrm
                                  ,p_source_system_ref => t_lin(i).source_system_ref
                                  );        
                      UPDATE xx_po_hdrs_conv_stg
                         SET process_flag = 3
                       WHERE process_flag <> 3
                         AND interface_header_id = t_hdr(i).interface_header_id;
                       UPDATE xx_po_lines_conv_stg
                          SET process_flag = 3
                        WHERE process_flag <> 3
                          AND interface_header_id = t_hdr(i).interface_header_id;
                       COMMIT;
                       t_eflag_lin(i) := 1;
                       RAISE;
             END;

             -- Insert line locations for Dropship --

             BEGIN
                INSERT
                  INTO po_line_locations_interface
                      (interface_line_location_id
                      ,interface_header_id
                      ,interface_line_id
                      ,process_code
                      ,shipment_type
                      ,shipment_num
                      ,ship_to_location
                      ,fob
                      ,freight_terms
                      ,need_by_date
                      ,promised_date
                      ,quantity
                      ,creation_date
                      ,unit_of_measure
                      ,action
                      ,inspection_required_flag
                      ,receipt_required_flag
                       ) 
                SELECT ln_llc_next_val
                      ,t_lin(i).interface_header_id
                      ,ln_lin_next_val
                      ,'PENDING'
                      ,'STANDARD'
                      ,t_lin(i).shipment_num
                      ,t_lin(i).ship_to_location
                      ,t_lin(i).fob
                      ,t_lin(i).freight_terms
                      ,t_lin(i).need_by_date
                      ,t_lin(i).promised_date
                      ,DECODE(t_lin(i).quantity,0,0.0000000001,t_lin(i).quantity)
                      ,t_lin(i).creation_date
                      ,t_lin(i).new_uom_code
                      ,'ADD'
                      ,'N'  -- Combination to determine 2 or 3 way matching this is
                      ,lc_match  -- 'Y' =3 way matching 'N'=2 way matching
                  FROM dual;

                ln_write_loc := ln_write_loc + 1;

             EXCEPTION
               WHEN OTHERS THEN
                    log_errors (p_error_msg         => 'Error inserting line locations for='||t_lin(i).interface_header_id||
                                                       ' line='||t_lin(i).line_num
                               ,p_control_id        => t_lin(i).control_id
                               ,p_staging_table     => 'XX_PO_LINES_CONV_STG'
                               ,p_column            => NULL
                               ,p_value             => NULL
                               ,p_oracle_code       => sqlcode
                               ,p_oracle_msg        => sqlerrm
                               ,p_source_system_ref => t_hdr(i).source_system_ref
                               );        
                    t_eflag_lin(i) := 1;
                    RAISE;
             END;

             -- Insert distributions --


             BEGIN
                INSERT
                  INTO po_distributions_interface
                      (interface_header_id
                      ,interface_line_id
                      ,interface_line_location_id
                      ,interface_distribution_id
                      ,org_id
                      ,quantity_ordered
                      ,quantity_delivered
                      ,quantity_billed
                      ,destination_type_code
                      ,destination_subinventory 
                       ) 
                SELECT t_lin(i).interface_header_id
                      ,ln_lin_next_val
                      ,ln_llc_next_val
                      ,ln_dis_next_val
                      ,t_lin(i).organization_id
                      ,DECODE(t_lin(i).quantity,0,0.0000000001,t_lin(i).quantity)
                      ,t_lin(i).qty_received
                      ,t_lin(i).qty_shipped
                      ,'INVENTORY'
                      ,'STOCK'
                  FROM dual;

                ln_write_dis := ln_write_dis + 1;

             EXCEPTION
               WHEN OTHERS THEN
                    fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                    fnd_file.put_line (fnd_file.LOG,'Error inserting distribution for='||t_lin(i).interface_header_id||
                                                       ' line='||t_lin(i).line_num);
                    log_errors (p_error_msg         => 'Error inserting distribution for='||t_lin(i).interface_header_id||
                                                       ' line='||t_lin(i).line_num
                               ,p_control_id        => t_lin(i).control_id
                               ,p_staging_table     => 'XX_PO_LINES_CONV_STG'
                               ,p_column            => NULL
                               ,p_value             => NULL
                               ,p_oracle_code       => sqlcode
                               ,p_oracle_msg        => sqlerrm
                               ,p_source_system_ref => t_hdr(i).source_system_ref
                               );        
                    t_eflag_lin(i) := 1;
                    RAISE;
             END;

          END IF;

     END LOOP;

     COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            lc_error_flag := 'Y';
            ROLLBACK;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error in Process Child :'||SQLERRM);
            fnd_file.put_line (fnd_file.LOG, 'Total no. of PO Header Records       - '||ln_read_hdr);
            fnd_file.put_line (fnd_file.LOG, 'No. of PO Header Records Processed   - '||ln_write_hdr);
            fnd_file.put_line (fnd_file.LOG, 'No. of PO Header Records Erroed      - '||ln_error_hdr);
            fnd_file.put_line (fnd_file.LOG, 'Total no. of PO Line Records         - '||ln_read_lin);
            fnd_file.put_line (fnd_file.LOG, 'No. of PO Distribution Records       - '||ln_write_dis);
            fnd_file.put_line (fnd_file.LOG, 'No. of PO Line Locations Records     - '||ln_write_loc);
            fnd_file.put_line (fnd_file.LOG, 'No. of PO Line Records Processed     - '||ln_write_lin);
            fnd_file.put_line (fnd_file.LOG, 'No. of PO Line Records Erroed        - '||ln_error_lin);

            fnd_file.put_line (fnd_file.LOG, 'No. of count 0                       - '||ln_count_0);
            RAISE;
     
END insert_lines;


PROCEDURE set_process_status_flag_hdr(p_batch_id    IN INTEGER
                                     ,p_from_status IN VARCHAR2
                                     ,p_to_status   IN INTEGER
                                     ,p_reset_flag  IN VARCHAR2 DEFAULT 'N') IS

    CURSOR c_hdrs(p_batch_id INTEGER
                 ,p_status   VARCHAR2
                 ,p_reset    VARCHAR2
               ) IS
    SELECT rowid rid
      FROM xx_po_hdrs_conv_stg stg
     WHERE batch_id = p_batch_id
       AND process_flag LIKE (CASE WHEN p_reset = 'Y' THEN '%'
                                   ELSE p_status
                              END)
       AND process_flag < 6;

    TYPE thdrs IS TABLE OF c_hdrs%ROWTYPE;

    t_hdrs thdrs := thdrs();

    ln_count INTEGER := 0;

BEGIN

  fnd_file.put_line (fnd_file.LOG,'Updating header status for batch='||p_batch_id||', from '||p_from_status||' to '||p_to_status);


  OPEN c_hdrs(p_batch_id
             ,p_from_status
             ,p_reset_flag);

  LOOP
     FETCH c_hdrs
      BULK COLLECT
      INTO t_hdrs LIMIT cn_commit;

     EXIT WHEN t_hdrs.COUNT = 0;
  
     FORALL r_hdr IN t_hdrs.FIRST .. t_hdrs.LAST
            UPDATE xx_po_hdrs_conv_stg
               SET process_flag = p_to_status
                  ,request_id = ln_request_id
             WHERE rowid = t_hdrs(r_hdr).rid
               AND batch_id = p_batch_id;


     COMMIT;
     
     ln_count := ln_count + t_hdrs.COUNT;

  END LOOP;

  CLOSE c_hdrs;

  EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
         IF c_hdrs%ISOPEN THEN
            CLOSE c_hdrs;
         END IF;
         RAISE;

END set_process_status_flag_hdr;

PROCEDURE set_process_status_flag_lin(p_batch_id    IN INTEGER
                                     ,p_from_status IN VARCHAR2
                                     ,p_to_status   IN INTEGER
                                     ,p_reset_flag  IN VARCHAR2 DEFAULT 'N') IS

    ln_error_count INTEGER;

    CURSOR c_lins(p_batch_id NUMBER
                 ,p_status   VARCHAR2
                 ,p_reset    VARCHAR2
                 ) IS

    SELECT rowid rid
      FROM xx_po_lines_conv_stg stg
     WHERE batch_id = p_batch_id
       AND process_flag LIKE (CASE WHEN p_reset = 'Y' THEN '%'
                                   ELSE p_status
                              END)
       AND process_flag < 6;

    TYPE tlins IS TABLE OF c_lins%ROWTYPE;

    t_lins tlins := tlins();

    ln_count INTEGER := 0;

BEGIN

  fnd_file.put_line (fnd_file.LOG,'Updating lines status for batch='||p_batch_id||', from '||p_from_status||' to '||p_to_status);

  OPEN c_lins(p_batch_id
             ,p_from_status
             ,p_reset_flag);

  LOOP
     FETCH c_lins
      BULK COLLECT
      INTO t_lins LIMIT cn_commit;
     
     EXIT WHEN t_lins.COUNT = 0;
 
     FORALL r_lins IN t_lins.FIRST .. t_lins.LAST
            UPDATE xx_po_lines_conv_stg
               SET process_flag = p_to_status
                  ,request_id = ln_request_id
             WHERE rowid = t_lins(r_lins).rid
               AND batch_id = p_batch_id;


     COMMIT;

     ln_count := ln_count + t_lins.COUNT;

  END LOOP;

  CLOSE c_lins;

  EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
         IF c_lins%ISOPEN THEN
            CLOSE c_lins;
         END IF;
         RAISE;

END set_process_status_flag_lin;

FUNCTION submit_po_import_cp RETURN INTEGER IS

    ln_active_jobs INTEGER := 0;
    ln_job_id      INTEGER := 0;
    ln_max_loop    INTEGER := 0;
    ln_orig_org_id VARCHAR2(10);

    lc_phase       VARCHAR2(100);
    lc_status      VARCHAR2(100);
    lc_dev_phase   VARCHAR2(100);
    lc_dev_status  VARCHAR2(100);
    lc_message     VARCHAR2(4000);
    
    CURSOR c_po IS
    SELECT batch_id
          ,interface_header_id
          ,process_code
      FROM po_headers_interface
     WHERE 1=1
       AND batch_id = p_batch_id;

    TYPE tpo IS TABLE OF c_po%ROWTYPE;

    t_po tpo;

    CURSOR c_org IS
    SELECT DISTINCT
           org_id
      FROM po_headers_interface
     WHERE batch_id = p_batch_id
       AND interface_source_code = 'NA-POCONV'
       AND org_id IS NOT NULL;

    TYPE torg IS TABLE OF c_org%ROWTYPE;

    t_org torg;

    TYPE rbatch_job IS RECORD
         ( batch_id   INTEGER
          ,job_no     INTEGER
          ,job_status VARCHAR2(100)
         );

    TYPE tbatch_job IS TABLE OF rbatch_job;

    t_batch_job tbatch_job := tbatch_job();

FUNCTION check_completed_jobs RETURN INTEGER IS

  ln_jobs_sub INTEGER:= 0;
  lb_bool     BOOLEAN;

BEGIN

    LOOP

       EXIT WHEN ln_jobs_sub >= t_batch_job.COUNT OR ln_max_loop > cn_max_loop;

       FOR i IN t_batch_job.FIRST .. t_batch_job.LAST
       LOOP

          IF NVL(t_batch_job(i).job_status,'X') <> 'COMPLETE' THEN
             lb_bool := fnd_concurrent.wait_for_request(request_id => t_batch_job(i).job_no 
                                                       ,interval   => 60
                                                       ,max_wait   => 0
                                                       ,phase      => lc_phase
                                                       ,status     => lc_status
                                                       ,dev_phase  => t_batch_job(i).job_status
                                                       ,dev_status => lc_dev_status
                                                       ,message    => lc_message
                                                       );
             IF t_batch_job(i).job_status = 'COMPLETE' THEN
                ln_jobs_sub := ln_jobs_sub + 1;
                IF ln_jobs_sub >= t_batch_job.COUNT THEN
                   RETURN 0;
                END IF;
             END IF;
          ELSE
             ln_max_loop := ln_max_loop + 1;
             IF ln_max_loop > cn_max_loop THEN
                RETURN 1;
             END IF;

          END IF; 

       END LOOP;

    END LOOP;

    RETURN 1;

END check_completed_jobs;

BEGIN

     ln_orig_org_id := FND_PROFILE.VALUE('ORG_ID') ; 

     OPEN c_org;

     FETCH c_org
      BULK COLLECT
      INTO t_org;

     IF t_org.COUNT = 0 THEN
        RETURN 0;
     END IF;

     FOR i IN t_org.FIRST .. t_org.LAST
     LOOP

           -- set org_id

          dbms_application_info.set_client_info (t_org(i).org_id);

          fnd_file.put_line(fnd_file.log,'Initializing apps');
          fnd_global.apps_initialize(90102,20707,201);
          mo_global.init('PO');
          mo_global.set_policy_context('S',404);

           ---------------------------------------------------------
           -- Submit Concurrent Program for Conversion
           ---------------------------------------------------------
           -- THE XXPOCNVCH concurrent program for PO Conversion
       
           fnd_file.put_line(fnd_file.log,'Submitting : '|| 'POXPOPDOI');

           ln_job_id := fnd_request.submit_request(application => 'PO'
                                                  ,program     => 'POXPOPDOI'
                                                  ,argument1   => ''                -- Default Buyer
                                                  ,argument2   => 'STANDARD'        -- Doc. Type
                                                  ,argument3   => ''
                                                  ,argument4   => 'N'               -- Create or Update Items
                                                  ,argument5   => ''
                                                  ,argument6   => 'APPROVED'        -- Approval Status
                                                  ,argument7   => 'Y'               -- Group Lines
                                                  ,argument8   => p_batch_id        -- batch_id
                                                  ,argument9   => t_org(i).org_id   -- org_id
                                                  ,argument10  => ''
                                                  ,argument11  => ''
                                                  ,argument12  => ''
                                                  ,argument13  => ''
                                                  ,argument14  => ''
                                                  ,argument15  => ''
                                                  ,argument16  => 'N'
                                                  ,argument17  => p_pdoi_batch_size -- batch size
                                                  ,argument18  => 'N'               -- Gather stats
                                              );

           COMMIT;

           IF NVL(ln_job_id,0) = 0 THEN
              fnd_file.put_line(fnd_file.log,'Error submitting POXPOPDOI='|| p_batch_id||' '||t_org(i).org_id);
              UPDATE xx_po_hdrs_conv_stg
                 SET process_flag = 6
               WHERE batch_id = p_batch_id
                 AND org_id = t_org(i).org_id
                 AND process_flag = 5;
              COMMIT;
           ELSE
              fnd_file.put_line(fnd_file.log,'Submitted batch_id='|| p_batch_id ||', job_no='|| ln_job_id);
              t_batch_job.EXTEND;
              t_batch_job(t_batch_job.LAST).batch_id := p_batch_id;
              t_batch_job(t_batch_job.LAST).job_no := ln_job_id;
           END IF;

     END LOOP;

     CLOSE c_org;

     -- restore original org_id

     dbms_application_info.set_client_info (ln_orig_org_id);

     IF (NOT t_batch_job.EXISTS(1)) OR t_batch_job.COUNT = 0 THEN
        RETURN 0;
     END IF;

     -- Loop until all jobs are completed

     IF check_completed_jobs = 1 THEN
        fnd_file.put_line(fnd_file.log,'Loop pass '||cn_max_loop||' iterations');
        RETURN 1;
     ELSE
        fnd_file.put_line(fnd_file.log,'All jobs completed');
     END IF;

     -- Update accepted PO's

     OPEN c_po;

     LOOP

        FETCH c_po
         BULK COLLECT
         INTO t_po LIMIT cn_commit;

        EXIT WHEN t_po.COUNT = 0;

        ---- Headers
        FORALL i IN t_po.FIRST .. t_po.LAST
              UPDATE xx_po_hdrs_conv_stg
                 SET process_flag = DECODE(t_po(i).process_code,'ACCEPTED',7,6)
               WHERE interface_header_id = t_po(i).interface_header_id
                 AND batch_id = t_po(i).batch_id
                 AND process_flag = 5;

        ln_failed_process := ln_failed_process + SQL%ROWCOUNT;

        COMMIT;

        ---- Lines

        FORALL i IN t_po.FIRST .. t_po.LAST
              UPDATE xx_po_lines_conv_stg
                 SET process_flag = DECODE(t_po(i).process_code,'ACCEPTED',7,6)
               WHERE interface_header_id = t_po(i).interface_header_id
                 AND batch_id = t_po(i).batch_id
                 AND process_flag = 5;

        ln_failed_process := ln_failed_process + SQL%ROWCOUNT;

        COMMIT;

     END LOOP;

     CLOSE c_po;

     RETURN 0;

END submit_po_import_cp;

-------- MAIN --------
 
BEGIN

    fnd_file.put_line (fnd_file.LOG, 'Parameters ');
    fnd_file.put_line (fnd_file.LOG, ' p_validate_only_flag: ' || p_validate_only_flag);
    fnd_file.put_line (fnd_file.LOG, ' p_batch_id          : ' || p_batch_id);
    fnd_file.put_line (fnd_file.LOG, ' p_reset_status_flag : ' || p_reset_status_flag);
    fnd_file.put_line (fnd_file.LOG, ' p_debug_flag        : ' || p_debug_flag);

    fnd_file.put_line (fnd_file.OUTPUT, 'OD: PO Purchase Order Conversion Child Program');
    fnd_file.put_line (fnd_file.OUTPUT, '============================================== ');
    fnd_file.put_line (fnd_file.OUTPUT, ' ');
    fnd_file.put_line (fnd_file.OUTPUT, ' ');

    BEGIN

       SELECT conversion_id
             ,system_code
         INTO ln_conversion_id
             ,lc_system_code
         FROM xx_com_conversions_conv
        WHERE conversion_code = 'CXXXX_PurchaseOrders';
        
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
           fnd_file.put_line (fnd_file.LOG, 'No data found for CXXXX_PurchaseOrders');
           RAISE;
      WHEN OTHERS THEN
           fnd_file.put_line (fnd_file.LOG, 'Error reading xx_com_conversions_conv, '||sqlerrm);
           RAISE;
    END;

--    IF p_reset_status_flag = 'Y' THEN
--       set_process_status_flag_hdr(p_batch_id
--                                   ,'%'
--                                  ,'1'
--                                  ,'Y'
--                                  );
--       set_process_status_flag_lin(p_batch_id
--                                  ,'%'
--                                  ,'1'
--                                  ,'Y'
--                                  );
--    END IF;

    set_process_status_flag_hdr(p_batch_id
                               ,'1'  -- from
                               ,'2'  -- to
                               );

    set_process_status_flag_lin(p_batch_id
                               ,'1'  -- from
                               ,'2'  -- to
                               );

    ln_read_hdr := 0;
    ln_read_lin := 0;
    ln_write_hdr := 0;
    ln_write_lin := 0;

    ---------- Validate Headers ----------
    fnd_file.put_line(fnd_file.LOG, 'Validate headers=['||to_char(sysdate,'mm/dd/yy hh24:mi:ss')||']');

    IF t_eflag_hdr.EXISTS(1) THEN
       t_eflag_hdr.DELETE;
    END IF;

    OPEN c_hdr(p_batch_id
              ,2
              ,'N'
              );

    LOOP
       FETCH c_hdr
        BULK COLLECT
        INTO t_hdr LIMIT cn_commit;

       EXIT WHEN t_hdr.COUNT = 0;

       ln_read_hdr := ln_read_hdr + t_hdr.COUNT;

           --- Validate/Derive vendor information

       FOR i_hdr IN t_hdr.FIRST .. t_hdr.LAST
       LOOP

          ln_error_flag := 0;  -- no error

          IF t_hdr(i_hdr).int_ven_code IS NOT NULL THEN
             log_errors (p_error_msg         => 'Internal vendor, record skipped'
                        ,p_control_id        => t_hdr(i_hdr).control_id
                        ,p_staging_table     => 'XX_PO_HDRS_CONV_STG'
                        ,p_column            => 'INTERNAL_VENDOR_SITE_CODE'
                        ,p_value             => t_hdr(i_hdr).vendor_site_code
                        ,p_oracle_code       => null
                        ,p_oracle_msg        => null
                        ,p_source_system_ref => t_hdr(i_hdr).source_system_ref
                        );
             fnd_file.put_line(fnd_file.LOG, t_hdr(i_hdr).interface_header_id||' Internal vendor, record skipped=['||t_hdr(i_hdr).vendor_site_code||']');
             ln_error_flag := 1;
             ln_skip_rec := 1;
          ELSE
             IF t_hdr(i_hdr).vendor_id IS NULL
                OR t_hdr(i_hdr).vendor_site_id IS  NULL
                OR t_hdr(i_hdr).org_id IS NULL
                OR t_hdr(i_hdr).vendor_name IS NULL THEN
                log_errors (p_error_msg         => 'Invalid vendor_site_code'
                           ,p_control_id        => t_hdr(i_hdr).control_id
                           ,p_staging_table     => 'XX_PO_HDRS_CONV_STG'
                           ,p_column            => 'VENDOR_SITE_CODE'
                           ,p_value             => t_hdr(i_hdr).vendor_site_code
                           ,p_oracle_code       => null
                           ,p_oracle_msg        => null
                           ,p_source_system_ref => t_hdr(i_hdr).source_system_ref
                           );
                fnd_file.put_line(fnd_file.LOG, t_hdr(i_hdr).interface_header_id||' Invalid vendor_site_code=['||t_hdr(i_hdr).vendor_site_code||']');
                ln_error_flag := 1;
             ELSE
                t_hdr(i_hdr).vendor_site_code := t_hdr(i_hdr).vendor_num;
             END IF;

          END IF;

         -- validate/derive ship to location

          IF t_hdr(i_hdr).location_id IS NOT NULL THEN
                 t_hdr(i_hdr).ship_to_location_id := t_hdr(i_hdr).location_id;
                 t_hdr(i_hdr).ship_to_location := t_hdr(i_hdr).location_code;
          ELSE
               log_errors (p_error_msg         => 'Invalid ship_to_location'
                          ,p_control_id        => t_hdr(i_hdr).control_id
                          ,p_staging_table     => 'XX_PO_HDRS_CONV_STG'
                          ,p_column            => 'SHIP_TO_LOCATION'
                          ,p_value             => t_hdr(i_hdr).ship_to_location
                          ,p_oracle_code       => null
                          ,p_oracle_msg        => null
                          ,p_source_system_ref => t_hdr(i_hdr).source_system_ref
                          );        
               fnd_file.put_line(fnd_file.LOG,t_hdr(i_hdr).interface_header_id||
                                              ' Invalid ship_to_location in hdr=['||t_hdr(i_hdr).ship_to_location||']');
               ln_error_flag := 1;
          END IF;

         -- validate/derive terms
-- AM Changed back on 6/23/17
-- AM Changed to default to vendor terms id when terms does not exists (venterms_id)
         IF t_hdr(i_hdr).vendor_id IS NULL
            OR t_hdr(i_hdr).vendor_site_id IS  NULL
            OR t_hdr(i_hdr).org_id IS NULL
            OR t_hdr(i_hdr).vendor_name IS NULL
            OR t_hdr(i_hdr).terms_id IS NOT NULL THEN
            NULL;
          ELSIF t_hdr(i_hdr).terms_id IS NULL 
                AND t_hdr(i_hdr).venterms_id IS NULL THEN
                    log_errors (p_error_msg         => 'Invalid terms id'
                               ,p_control_id        => t_hdr(i_hdr).control_id
                               ,p_staging_table     => 'XX_PO_HDRS_CONV_STG'
                               ,p_column            => 'TERMS_ID'
                               ,p_value             => 'terms_disc_pct='||t_hdr(i_hdr).terms_disc_pct||
                                                       ' terms_disc_days='||t_hdr(i_hdr).terms_disc_days||
                                                       ' terms_net_days='||t_hdr(i_hdr).terms_net_days
                               ,p_oracle_code       => null
                               ,p_oracle_msg        => null
                               ,p_source_system_ref => t_hdr(i_hdr).source_system_ref
                               );        
                    fnd_file.put_line(fnd_file.LOG,t_hdr(i_hdr).interface_header_id||', ['||t_hdr(i_hdr).terms_disc_pct*100||'/'||
                                          t_hdr(i_hdr).terms_disc_days||'N'||t_hdr(i_hdr).terms_net_days||
                                          '], Not Found');
                    ln_error_flag := 1;
              ELSE
                    t_hdr(i_hdr).terms_id := t_hdr(i_hdr).venterms_id;
                    log_errors (p_error_msg         => 'defaulted terms id'
                               ,p_control_id        => t_hdr(i_hdr).control_id
                               ,p_staging_table     => 'XX_PO_HDRS_CONV_STG'
                               ,p_column            => 'DEFAULTED_TERMS_ID'
                               ,p_value             => 'terms_disc_pct='||t_hdr(i_hdr).terms_disc_pct||
                                                       ' terms_disc_days='||t_hdr(i_hdr).terms_disc_days||
                                                       ' terms_net_days='||t_hdr(i_hdr).terms_net_days ||
                                                       ' defaulted to='|| t_hdr(i_hdr).venterms_id
                               ,p_oracle_code       => null
                               ,p_oracle_msg        => null
                               ,p_source_system_ref => t_hdr(i_hdr).source_system_ref
                               );        
                    fnd_file.put_line(fnd_file.LOG,t_hdr(i_hdr).interface_header_id||', ['||t_hdr(i_hdr).terms_disc_pct*100||'/'||
                                          t_hdr(i_hdr).terms_disc_days||'N'||t_hdr(i_hdr).terms_net_days||
                                          '], defaulted to='||t_hdr(i_hdr).venterms_id);
          END IF;

         -- keep track of invalid rows
         t_eflag_hdr.EXTEND;
         t_eflag_hdr(t_eflag_hdr.COUNT) := ln_error_flag;

         ln_error_hdr := ln_error_hdr + ln_error_flag;

       END LOOP;


       -- set status to 3 for invalid rows
       FORALL i_hdr IN t_hdr.FIRST .. t_hdr.LAST
              UPDATE xx_po_hdrs_conv_stg
                 SET process_flag = 3
               WHERE rowid = t_hdr(i_hdr).rid
                 AND t_eflag_hdr(i_hdr) = 1
                 AND batch_id = p_batch_id;


       fnd_file.put_line(fnd_file.LOG,'Rows updated with process_flag = 3: '||sql%rowcount);

       IF p_validate_only_flag <> 'Y' THEN
          insert_headers;
       END IF;

       COMMIT;

    END LOOP;

    set_process_status_flag_hdr(p_batch_id
                               ,'2'  -- from
                               ,'4'  -- to
                               );

    set_process_status_flag_hdr(p_batch_id
                               ,'4'  -- from
                               ,'5'  -- to
                                );

    IF c_hdr%ISOPEN THEN
       CLOSE c_hdr;
    END IF;

    -------------- Validate Lines
    fnd_file.put_line(fnd_file.LOG, 'Validate lines=['||to_char(sysdate,'mm/dd/yy hh24:mi:ss')||']');

    IF t_eflag_lin.EXISTS(1) THEN
       t_eflag_lin.DELETE;
    END IF;

    IF t_lin.EXISTS(1) THEN
       t_lin.DELETE;
    END IF;

    OPEN c_lin (p_batch_id);

    LOOP
       FETCH c_lin
        BULK COLLECT
        INTO t_lin LIMIT cn_commit;

       EXIT WHEN t_lin.COUNT = 0;

       ln_read_lin := ln_read_lin + t_lin.COUNT;

       ln_last_int_id := 0;

       FOR i_lin IN t_lin.FIRST .. t_lin.LAST
       LOOP

          ln_error_flag := 0;  -- no error

          IF ln_last_int_id <> t_lin(i_lin).interface_header_id THEN
             ln_last_int_id := t_lin(i_lin).interface_header_id;

              BEGIN

                SELECT phs.rowid
                      ,phs.closed_code
                      ,trunc(phs.creation_date) need_by_date
                      ,trunc(phs.creation_date) promised_date
                      ,phs.fob
                      ,phs.freight_terms
                      ,phs.creation_date
                      ,phs.note_to_vendor
                      ,phs.note_to_receiver
                      ,phs.org_id
                      ,phs.process_flag
                      ,phi.attribute_category
                      ,phs.document_num
                      ,phs.drop_ship_flag
                  INTO lr_rowid
                      ,t_lin(i_lin).closed_code
                      ,t_lin(i_lin).need_by_date
                      ,t_lin(i_lin).promised_date
                      ,t_lin(i_lin).fob
                      ,t_lin(i_lin).freight_terms
                      ,t_lin(i_lin).creation_date
                      ,t_lin(i_lin).note_to_vendor
                      ,t_lin(i_lin).note_to_receiver
                      ,t_lin(i_lin).organization_id
                      ,ln_process_flag
                      ,t_lin(i_lin).attribute_category
                      ,ln_po
                      ,t_lin(i_lin).drop_ship_flag
                  FROM xx_po_hdrs_conv_stg phs
                      ,po_headers_interface phi
                 WHERE phs.interface_header_id = phi.interface_header_id(+)
                   AND phs.interface_header_id = t_lin(i_lin).interface_header_id;
                ln_lint := t_lin(i_lin).interface_header_id;

              EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                      ln_error_flag := 1;
                      ln_process_flag := 3;
                      ln_po := '9999999999';
                      ln_lint := t_lin(i_lin).interface_header_id;
              END;
              lc_closed_code        := t_lin(i_lin).closed_code;
              ld_need_by_date       := t_lin(i_lin).need_by_date;
              ld_promised_date      := t_lin(i_lin).promised_date;
              lc_fob                := t_lin(i_lin).fob;
              lc_freight_terms      := t_lin(i_lin).freight_terms;
              ld_creation_date      := t_lin(i_lin).creation_date;
              lc_note_to_vendor     := t_lin(i_lin).note_to_vendor;
              lc_note_to_receiver   := t_lin(i_lin).note_to_receiver;
              lc_organization_id    := t_lin(i_lin).organization_id;
              lc_attribute_category := t_lin(i_lin).attribute_category;
              lc_drop_ship_flag     := t_lin(i_lin).drop_ship_flag;
          ELSE
              t_lin(i_lin).closed_code        := lc_closed_code;
              t_lin(i_lin).need_by_date       := ld_need_by_date;
              t_lin(i_lin).promised_date      := ld_promised_date;
              t_lin(i_lin).fob                := lc_fob;
              t_lin(i_lin).freight_terms      := lc_freight_terms;
              t_lin(i_lin).creation_date      := ld_creation_date;
              t_lin(i_lin).note_to_vendor     := lc_note_to_vendor;
              t_lin(i_lin).note_to_receiver   := lc_note_to_receiver;
              t_lin(i_lin).organization_id    := lc_organization_id;
              t_lin(i_lin).attribute_category := lc_attribute_category;
              t_lin(i_lin).drop_ship_flag     := lc_drop_ship_flag;
          END IF;

          IF t_lin(i_lin).item_id IS NULL THEN
             log_errors (p_error_msg         => 'Invalid item'
                        ,p_control_id        => t_lin(i_lin).control_id
                        ,p_staging_table     => 'XX_PO_LINES_CONV_STG'
                        ,p_column            => 'ITEM'
                        ,p_value             => t_lin(i_lin).item||'/'||t_lin(i_lin).ship_to_location 
                        ,p_oracle_code       => null
                        ,p_oracle_msg        => null
                        ,p_source_system_ref => t_lin(i_lin).source_system_ref
                        );        
             fnd_file.put_line(fnd_file.LOG,t_lin(i_lin).interface_header_id||', '||t_lin(i_lin).interface_line_id||
                                            ' Invalid item=['||t_lin(i_lin).item||'], location=['||
                                            t_lin(i_lin).location_id||']');
             ln_error_flag := 1;
          END IF;

          ---- Validate UOM_CODE

           IF t_lin(i_lin).new_uom_code IS NULL THEN
              log_errors (p_error_msg         => 'UOM code not found'
                         ,p_control_id        => t_lin(i_lin).control_id
                         ,p_staging_table     => 'XX_PO_LINES_CONV_STG'
                         ,p_column            => 'UOM_CODE'
                         ,p_value             => t_lin(i_lin).uom_code
                         ,p_oracle_code       => sqlcode
                         ,p_oracle_msg        => sqlerrm
                         ,p_source_system_ref => t_lin(i_lin).source_system_ref
                         );
              ln_error_flag := 1;
              fnd_file.put_line(fnd_file.LOG, t_lin(i_lin).interface_header_id||', '||t_lin(i_lin).interface_line_id||
                                              ' UOM code not found legacy_uom=['||t_lin(i_lin).uom_code||']');
           END IF;

           IF t_lin(i_lin).location_id IS NOT NULL THEN
              t_lin(i_lin).ship_to_location_id := t_lin(i_lin).location_id;
              t_lin(i_lin).ship_to_location := t_lin(i_lin).location_code;
           ELSE
              log_errors (p_error_msg         => 'Invalid ship_to_location'
                         ,p_control_id        => t_lin(i_lin).control_id
                         ,p_staging_table     => 'XX_PO_LINES_CONV_STG'
                         ,p_column            => 'SHIP_TO_LOCATION'
                         ,p_value             => t_lin(i_lin).ship_to_location
                         ,p_oracle_code       => null
                         ,p_oracle_msg        => null
                         ,p_source_system_ref => t_lin(i_lin).source_system_ref
                          );
              fnd_file.put_line(fnd_file.LOG, t_lin(i_lin).interface_header_id||', '||t_lin(i_lin).interface_line_id||' Invalid ship_to_location in lines=['||t_lin(i_lin).ship_to_location||']');
              ln_error_flag := 1;
           END IF;

           ---------- PO Header is invalid -----------
           IF ln_process_flag IN (3,6) AND ln_error_flag = 0 THEN      
              ln_error_flag := 1;
              fnd_file.put_line(fnd_file.LOG,t_lin(i_lin).interface_line_id||' Header invalid interface_header_id=['||
                                              t_lin(i_lin).interface_header_id||'], Line=['||t_lin(i_lin).line_num||'], Flag='||
                                              ln_process_flag);
              log_errors (p_error_msg         => 'Header invalid for line='||t_lin(i_lin).line_num
                         ,p_control_id        => t_lin(i_lin).control_id
                         ,p_staging_table     => 'XX_PO_LINES_CONV_STG'
                         ,p_column            => 'INTERFACE_HEADER_ID'
                         ,p_value             => t_lin(i_lin).interface_header_id
                         ,p_oracle_code       => null
                         ,p_oracle_msg        => null
                         ,p_source_system_ref => t_lin(i_lin).source_system_ref
                         );
           END IF;

           -- keep track of invalid rows
           t_eflag_lin.EXTEND;
           t_eflag_lin(t_eflag_lin.COUNT) := ln_error_flag;

           ln_error_lin := ln_error_lin + ln_error_flag;
           IF ln_error_flag = 1 THEN
              DELETE 
                FROM po_headers_interface
               WHERE interface_header_id = t_lin(i_lin).interface_header_id;

              IF lr_rowid IS NOT NULL THEN
                 UPDATE xx_po_hdrs_conv_stg
                    SET process_flag = 3
                  WHERE rowid = lr_rowid
                    AND process_flag <> 3;
              END IF;

             COMMIT;

              IF SQL%ROWCOUNT > 0 THEN
                 log_errors (p_error_msg         => 'Header Invalidated because there are errors in Lines'
                            ,p_control_id        => t_lin(i_lin).control_id
                            ,p_staging_table     => 'XX_PO_HDRS_CONV_STG'
                            ,p_column            => 'INTERFACE_HEADER_ID'
                            ,p_value             => t_lin(i_lin).interface_header_id
                            ,p_oracle_code       => null
                            ,p_oracle_msg        => null
                            ,p_source_system_ref => t_lin(i_lin).source_system_ref
                             );
                 ln_error_hdr := ln_error_hdr + 1;
                 ln_write_hdr := ln_write_hdr - 1;
              END IF;

              ln_process_flag := 3;

           END IF;

       END LOOP;

       -- set status to 3 for invalid rows
       FORALL i_lin IN t_lin.FIRST .. t_lin.LAST
              UPDATE xx_po_lines_conv_stg
                 SET process_flag = 3
               WHERE rowid = t_lin(i_lin).rid
                 AND t_eflag_lin(i_lin) = 1
                 AND batch_id = p_batch_id;

       COMMIT;

-- (AM 9-29-17) 
-- Defect NAIT-12518 Receipt conversion records are failing due to PO LINE CLOSED.
-- The PO line status is being closed due to Integral file record.
-- The Integral file should not be utilized to close PO lines during conversion.
-- The lines should remain open so receipts can come in.

       -- Update closed code for PO lines

--       FORALL i_lin IN t_lin.FIRST .. t_lin.LAST
--              UPDATE xx_po_lines_conv_stg
--                 SET closed_code = t_lin(i_lin).closed_code_final
--               WHERE rowid = t_lin(i_lin).rid;

--       COMMIT;

       IF p_validate_only_flag <> 'Y' THEN
          insert_lines;
        END IF;

    END LOOP;


    set_process_status_flag_lin(p_batch_id
                               ,'2'  -- from
                               ,'4'  -- to
                               );

    set_process_status_flag_lin(p_batch_id
                              ,'4'  -- from
                              ,'5'  -- to
                                  );

    IF p_validate_only_flag <> 'Y' THEN
       sync_process_flag;
       update_errored_rows;
    END IF;

    IF p_validate_only_flag <> 'Y' THEN NULL;
       IF submit_po_import_cp = 1 THEN
          set_process_status_flag_lin(p_batch_id  --submitted job ends with error
                                     ,'5'         -- from
                                     ,'6'         -- to
                                     );
       END IF;
-- (AM 9-29-17) 
-- Defect NAIT-12518 Receipt conversion records are failing due to PO LINE CLOSED.
-- The PO line status is being closed due to Integral file record.
-- The Integral file should not be utilized to close PO lines during conversion.
-- The lines should remain open so receipts can come in.
--       close_po_lines;
    ELSE
       fnd_file.put_line (fnd_file.LOG, 'End of Validation, ['||to_char(sysdate,'mm/dd/yy hh24:mi:ss')||']');
    END IF;

-- Set process flag to error for unprocessed headers/lines.

    IF p_validate_only_flag <> 'Y' THEN
       set_process_status_flag_hdr(p_batch_id
                                  ,'5'  -- from
                                  ,'3'  -- to
                                  );

       set_process_status_flag_lin(p_batch_id
                                  ,'5'  -- from
                                  ,'3'  -- to
                                  );
    END IF;

    SELECT count(*)
      INTO ln_write_hdr
      FROM po_headers_interface
     WHERE batch_id = p_batch_id;

    SELECT count(*)
      INTO ln_error_hdr
      FROM xx_po_hdrs_conv_stg
     WHERE batch_id = p_batch_id
       AND process_flag = 3;

    SELECT count(*)
      INTO ln_error_lin
      FROM xx_po_lines_conv_stg
     WHERE batch_id = p_batch_id
       AND process_flag = 3;

    fnd_file.put_line (fnd_file.LOG, 'Total no. of PO Header Records       - '||ln_read_hdr);
    fnd_file.put_line (fnd_file.LOG, 'No. of PO Header Records Processed   - '||ln_write_hdr);
    fnd_file.put_line (fnd_file.LOG, 'No. of PO Header Records Erroed      - '||ln_error_hdr);
    fnd_file.put_line (fnd_file.LOG, 'No. of PO Header Records Skipped     - '||ln_skip_rec);
    fnd_file.put_line (fnd_file.LOG, 'Total no. of PO Line Records         - '||ln_read_lin);
    fnd_file.put_line (fnd_file.LOG, 'No. of PO Distribution Records       - '||ln_write_dis);
    fnd_file.put_line (fnd_file.LOG, 'No. of PO Line Locations Records     - '||ln_write_loc);
    fnd_file.put_line (fnd_file.LOG, 'No. of PO Line Records Processed     - '||ln_write_lin);
    fnd_file.put_line (fnd_file.LOG, 'No. of PO Line Records Erroed        - '||ln_error_lin);

    fnd_file.put_line (fnd_file.OUTPUT, ' ');
    fnd_file.put_line (fnd_file.OUTPUT, 'Total no. of PO Header Records     - '||lpad(to_char(ln_read_hdr,'99,999,990'),12));
    fnd_file.put_line (fnd_file.OUTPUT, 'No. of PO Header Records Processed - '||lpad(to_char(ln_write_hdr,'99,999,990'),12));
    fnd_file.put_line (fnd_file.OUTPUT, 'No. of PO Header Records Erroed    - '||lpad(to_char(ln_error_hdr,'99,999,990'),12));
    fnd_file.put_line (fnd_file.OUTPUT, 'No. of PO Header Records Skipped   - '||lpad(to_char(ln_skip_rec,'99,999,990'),12));

    fnd_file.put_line (fnd_file.OUTPUT, ' ');
    fnd_file.put_line (fnd_file.OUTPUT, ' ');
    fnd_file.put_line (fnd_file.OUTPUT, ' ');

    fnd_file.put_line (fnd_file.OUTPUT, 'Total no. of PO Line Records       - '||lpad(to_char(ln_read_lin,'99,999,990'),12));
    fnd_file.put_line (fnd_file.OUTPUT, 'No. of PO Line Records Processed   - '||lpad(to_char(ln_write_lin,'99,999,990'),12));
    fnd_file.put_line (fnd_file.OUTPUT, 'No. of PO Line Records Erroed      - '||lpad(to_char(ln_error_lin,'99,999,990'),12));
    fnd_file.put_line (fnd_file.OUTPUT, 'No. of PO Lines closed             - '||lpad(to_char(ln_closed_lines,'99,999,990'),12));

    fnd_file.put_line (fnd_file.OUTPUT, ' ');
    fnd_file.put_line (fnd_file.OUTPUT, ' ');
    fnd_file.put_line (fnd_file.OUTPUT, ' ');

    fnd_file.put_line (fnd_file.OUTPUT, 'No. of PO Distribution Records     - '||lpad(to_char(ln_write_dis,'99,999,990'),12));
    fnd_file.put_line (fnd_file.OUTPUT, 'No. of PO Line Locations Records   - '||lpad(to_char(ln_write_loc,'99,999,990'),12));

    xx_com_conv_elements_pkg.upd_control_info_proc(fnd_global.conc_request_id
                                                  ,p_batch_id
                                                  ,'1.0'
                                                  ,ln_error_hdr + ln_error_lin
                                                  ,ln_failed_process
                                                  ,ln_write_hdr+ln_write_lin
                                                  );
    x_retcode := 0;
    
    IF c_lin%ISOPEN THEN
       CLOSE c_lin;
    END IF;
    
--------   Calling update header attribute process--------

   
    IF x_retcode <> 2 THEN
   
       od_po_conv_status_prc;
       fnd_file.put_line (fnd_file.OUTPUT, 'Status program submitted successfully - ');
   
    END IF;


   --------   end of update header attribute process--------

EXCEPTION

      WHEN OTHERS THEN
           ROLLBACK;
           fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
           fnd_file.put_line (fnd_file.LOG,sqlerrm);
           fnd_file.put_line (fnd_file.LOG,'Error in process aborted.');

           IF c_hdr%ISOPEN THEN
              CLOSE c_hdr;
           END IF;

           IF c_lin%ISOPEN THEN
              CLOSE c_lin;
           END IF;

           IF NOT (p_validate_only_flag = 'Y' OR p_reset_status_flag = 'Y') THEN
              set_process_status_flag_hdr(p_batch_id
                                         ,'5'  -- from
                                         ,'6'  -- to
                                         );
           END IF;

           x_retcode := 1;

           RAISE;

END child_main;

END XX_PO_POM_CONV_PKG;
/