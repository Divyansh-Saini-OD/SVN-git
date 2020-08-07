CREATE OR REPLACE PACKAGE BODY XX_CNV_GI_RCV_PKG
AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : PO, Inter-Org Transfer Rec, RTV Conversion          |
-- | Description : To convert the 'GI- RECEIPTS' that are fully        |
-- |               received as well as partially received,             |
-- |               from the OD Legacy system to Oracle EBS.            |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       2-APR-2007  Murali Krishnan       Initial version        |
-- |                      Ramachandran                                 |
-- +===================================================================+
-- +===================================================================+
-- | Name        : xx_gi_conv_mst                                   |
-- | Description : To create the batches of Receipt Source Code and    |
-- |               Receipt Number lines not exceeding 10000 records    |
-- |               from the custom staging tables XX_GI_RCV_STG.       |
-- |               It will call the "OD: GI Conversion                 |
-- |               Child Program", "OD Conversion Exception Log Report",|
-- |              "OD Conversion Processing Summary Report"            |
-- |               for each batch.  This procedure will be the         |
-- |               executable of Concurrent program                    |
-- |               "OD: RECEIVING TRANSACTION PROCESSOR" and           |
-- |               "OD: PROCESS TRANSACTIONS INTERFACE".               |
-- | Parameters : x_error_buff, x_ret_code,p_process_name,             |
-- |              ,p_validate_only_flag,p_reset_status_flag            |
-- +===================================================================+

-- +=======================================================================+
-- |PROCESS_FLAG – To indicate Status:                                     |
-- |         •  0 – Not Ready, Batch Extraction in progress                |
-- |         •  1 – Ready for Validation                                   |
-- |         •  2 – Validation In Progress                                 |
-- |         •  3 – Validation Failed                                      |
-- |         •  6 – Processing Failed                                      |
-- |         •  7 – Processing Successful                                  |
-- |         •  8 – Validation Failed      (For Inter-org Receipt)         |
-- |         •  9 – Processing Failed      (For Inter-org Receipt)         |
-- |         •  10– Validation In Progress (For Intransit)            |
-- +=======================================================================+

PROCEDURE xx_gi_conv_mst(
                           x_error_buff         OUT VARCHAR2
                         , x_ret_code           OUT NUMBER
                         , p_process_name       IN  VARCHAR2
                         , p_validate_only_flag IN  VARCHAR2
                         , p_reset_status_flag  IN  VARCHAR2
                           )
AS
      
      -- Cursor to assign the batches
      CURSOR lcu_rec_curr(p_system_code VARCHAR2)
      IS
        SELECT   receipt_source_code
                ,attribute8
                ,COUNT(*) count_val
        FROM     xx_gi_rcv_stg
        WHERE    source_system_code = p_system_code
        GROUP BY receipt_source_code, attribute8;
                                       
     -- Bulk Collect
     TYPE lt_rec_curr_ty IS TABLE OF lcu_rec_curr%ROWTYPE
     INDEX BY BINARY_INTEGER;
                          
     lt_rec_curr  lt_rec_curr_ty;
                                            
      -- Cursor to process individual batches
      CURSOR lcu_stg_curr
      IS
      SELECT batch_id
            ,COUNT(*) count_val
      FROM   xx_gi_rcv_stg
      WHERE  batch_id IS NOT NULL
      GROUP BY batch_id;	

     -- Bulk Collect
     TYPE lt_stg_curr_ty IS TABLE OF lcu_stg_curr%ROWTYPE
     INDEX BY BINARY_INTEGER;
                          
     lt_stg_curr  lt_stg_curr_ty;

      ln_batch_id             NUMBER := 0;
      ln_batch_tot            NUMBER := 0;
      ln_par_conc_request_id  fnd_concurrent_requests.request_id%TYPE;
      ln_chi_conc_request_id  fnd_concurrent_requests.request_id%TYPE;
      ln_conversion_id        xxcomn.xx_com_conversions_conv.conversion_id%TYPE;
      lc_source_system_code   xxcomn.xx_com_conversions_conv.system_code%TYPE;
      ln_org_id               hr_operating_units.organization_id%TYPE;
      lc_error_loc            VARCHAR2(2000);
      lc_error_msg            VARCHAR2(2000);
      lc_error_debug          VARCHAR2(2000);
      lb_req_set              BOOLEAN;
      lb_req_child            BOOLEAN;
      lb_req_excep            BOOLEAN;
      lb_req_summary          BOOLEAN;
      ln_req_submit           NUMBER;
      ln_req_id               NUMBER;
      ln_control_id           NUMBER;
      ln_batch                NUMBER;

  BEGIN
                 
    ln_par_conc_request_id := fnd_global.conc_request_id();
                
    --Printing the Parameters
    fnd_file.put_line(fnd_file.log,'Parameters');
    fnd_file.put_line(fnd_file.log,'----------');
    fnd_file.put_line(fnd_file.log,'Process Name: '||p_process_name);
    fnd_file.put_line(fnd_file.log,'Validate Only Flag: '||p_validate_only_flag);
    fnd_file.put_line(fnd_file.log,'Reset Status Flag: '||p_reset_status_flag);
    fnd_file.put_line(fnd_file.log,'----------------------');
                        
    --Get the Current Operating Unit Organization id
    ln_org_id := fnd_profile.value('ORG_ID');
            
    --Get the Conversion_id
    lc_error_loc := 'Get the Conversion id, Source System Code';
    lc_error_debug := 'Process Name: '||p_process_name;
             
      SELECT conversion_id
             ,system_code
      INTO   ln_conversion_id
             ,lc_source_system_code
      FROM   xxcomn.xx_com_conversions_conv
      WHERE  conversion_code = p_process_name;
                            
        --If Reset flag = 'Y'
        IF (p_reset_status_flag = 'Y') THEN
          lc_error_loc := 'Updating the Process flag to 1';
          lc_error_debug := 'Reset Status Flag: '||p_reset_status_flag;
                                          
          fnd_file.put_line(fnd_file.LOG,'p_reset_status_flag is ' || p_reset_status_flag);
          fnd_file.put_line(fnd_file.LOG,'Resetting the Process Flag to 1 in staging tables.');
                                                
            -- delete records from Interface Tabel
             DELETE FROM mtl_transactions_interface
             WHERE attribute15 IN (SELECT ROWID FROM xx_gi_rcv_stg
             WHERE process_flag = '6');
                                               
             DELETE FROM rcv_headers_interface
             WHERE header_interface_id IN (SELECT header_interface_id
                                           FROM rcv_transactions_interface
                                            WHERE processing_status_code = 'ERROR'
                                            OR transaction_status_code = 'ERROR');
                                                                       
             DELETE FROM rcv_transactions_interface
             WHERE  interface_transaction_id IN (SELECT interface_transaction_id
                                                FROM rcv_transactions_interface
                                                WHERE processing_status_code = 'ERROR'
                                                OR transaction_status_code = 'ERROR')
             AND  interface_transaction_id IN (SELECT interface_line_id
                                            FROM po_interface_errors);
                                                      
            UPDATE  xx_gi_rcv_stg
            SET     process_flag ='1'
                   ,conv_action = 'UPDATE'
            WHERE   source_system_code = lc_source_system_code
            AND     process_flag IN ('2','3','6');
                             
            UPDATE  xx_gi_rcv_stg
            SET     process_flag ='10'
                   ,conv_action = 'UPDATE'
            WHERE   source_system_code = lc_source_system_code
            AND     process_flag IN ('8','9');
         COMMIT;                     
        ELSE                              
            -- Updating the Process flag from 1 to 2
            UPDATE  xx_gi_rcv_stg
            SET     process_flag ='2'
                   ,conv_action = 'UPDATE'
            WHERE   source_system_code = lc_source_system_code
            AND     process_flag = '1';
         COMMIT;                     
        END IF;  -- End If Reset flag = 'Y'
                                      
    BEGIN
      OPEN lcu_rec_curr (lc_source_system_code);
        FETCH lcu_rec_curr BULK COLLECT INTO lt_rec_curr;
                SELECT xx_gi_batch_info_id_s1.Nextval 
                INTO ln_batch_id 
                FROM sys.dual;
        FOR i IN 1..lt_rec_curr.COUNT
        LOOP
          ln_batch_tot := ln_batch_tot + lt_rec_curr(i).count_val;
            IF  ln_batch_tot <= 10000 then
              ln_batch := ln_batch_id;
            ELSE
                SELECT xx_gi_batch_info_id_s1.Nextval 
                INTO ln_batch_id 
                FROM sys.dual;
                  ln_batch_tot := 0;
            END IF;
              UPDATE  xx_gi_rcv_stg
              SET     batch_id            = ln_batch
              WHERE   receipt_source_code = lt_rec_curr(i).receipt_source_code
              AND     attribute8          = lt_rec_curr(i).attribute8;
                               
        END LOOP;
    END;    
         
    BEGIN
      OPEN lcu_stg_curr;
        FETCH lcu_stg_curr BULK COLLECT INTO lt_stg_curr;
        FOR i IN 1..lt_stg_curr.COUNT
        LOOP
          BEGIN 
                                 
            lc_error_loc   := 'Call the Common Elements API to log the control info';
            lc_error_debug := 'Conversion id: '||ln_conversion_id||' Batch id: '||lt_stg_curr(i).batch_id;
                                                    
           fnd_file.put_line(fnd_file.LOG,'Calling log_control_info_proc for batch number '||lt_stg_curr(i).batch_id);
                                                        
           xx_com_conv_elements_pkg.log_control_info_proc(ln_conversion_id
                                                          ,lt_stg_curr(i).batch_id
                                                          ,lt_stg_curr(i).count_val);
                                                                       
            fnd_file.put_line (fnd_file.LOG,'Submitting Request Set for Batch number '|| lt_stg_curr(i).batch_id);
                                                            
            lb_req_set   := fnd_submit.set_request_set('XXCNV','XX_GI_CONV_RS');
                                                                           
            fnd_file.put_line (fnd_file.LOG,'Submitting OD : GI Conversion XX_GI_CONV_CHD '
                        	               ||'Program for batch number '|| lt_stg_curr(i).batch_id);
                                                    
                  lb_req_child := fnd_submit.submit_program('XXCNV'
                                                           ,'XX_GI_CONV_PKG_CHD'
                                                           ,'STAGE10'
                                                           ,p_process_name
                                                           ,p_validate_only_flag
                                                           ,p_reset_status_flag
                                                           ,lt_stg_curr(i).batch_id);
                  lb_req_excep := fnd_submit.submit_program('XXCOMN'
                                                           ,'XXCOMCONVEXPREP'
                                                           ,'STAGE20'
                                                           ,p_process_name
                                                           ,ln_par_conc_request_id
                                                           ,ln_chi_conc_request_id
                                                           ,lt_stg_curr(i).batch_id);
                  lb_req_summary := fnd_submit.submit_program('XXCOMN'
                                                             ,'XXCOMCONVSUMMREP'
                                                             ,'STAGE30'
                                                             ,p_process_name
                                                             ,ln_par_conc_request_id
                                                             ,ln_chi_conc_request_id
                                                             ,lt_stg_curr(i).batch_id);
                  ln_req_submit := fnd_submit.submit_set(SYSDATE, FALSE);
                                                                      
                  --Updating the REQUEST_ID
                  lc_error_loc := 'Update REQUEST_ID of the Staging table ';
                  lc_error_debug := 'Batch ID: '||lt_stg_curr(i).batch_id;
                                                        
                     UPDATE xx_gi_rcv_stg
                     SET    request_id = ln_req_submit
                     WHERE  batch_id   = lt_stg_curr(i).batch_id;
                   COMMIT;
                                                   
    EXCEPTION
       WHEN OTHERS THEN
        fnd_file.put_line (fnd_file.LOG,'See the OD Conversion Exception Log Report.');
                                                                           
        lc_error_msg := 'When Others Exception Raised in PO Conversion Master Program';
                                                                                  
        xx_com_conv_elements_pkg.log_exceptions_proc(
                                               ln_conversion_id
                                              ,ln_control_id
                                              ,lc_source_system_code
                                              ,'XX_GI_RCV_CONV_PKG'
                                              ,'XX_GI_CONV_MST'
                                              ,'XX_GI_RCV_STG'
                                              ,'REQUEST_ID'
                                              ,ln_req_submit
                                              ,NULL
                                              ,lt_stg_curr(i).batch_id
                                              ,lc_error_msg
                                              ,SQLCODE
                                              ,SQLERRM);
          END;
        END LOOP;
    END; 

  END xx_gi_conv_mst;
                                                                            
  -- +===================================================================+
-- | Name        : xx_gi_conv_chd                                       |
-- | Description : To perform validations, Import of                   |
-- |               Receipt Source Code and Receipt Number lines        |
-- |               not exceeding 10000 records, for each batch.        |
-- |               This procedure will be the executable of Concurrent |
-- |               Program "OD: RECEIVING TRANSACTION PROCESSOR" and   |
-- |               "OD: PROCESS TRANSACTIONS INTERFACE".               |
-- | Parameters : x_error_buff, x_ret_code,p_process_name,             |
-- |              ,p_validate_only_flag,p_reset_status_flag,p_batch_id |
-- +===================================================================+
                                                                   
PROCEDURE xx_gi_conv_chd(
                             x_error_buff         OUT VARCHAR2
                            ,x_ret_code           OUT NUMBER
                            ,p_process_name       IN  VARCHAR2
                            ,p_validate_only_flag IN  VARCHAR2
                            ,p_reset_status_flag  IN  VARCHAR2
                            ,p_batch_id           IN  NUMBER
                            )
AS
                                                                
    --Cursor to get the header details of the Particular batch
   CURSOR lcu_child_curr (p_system_code VARCHAR2)
   IS
      SELECT ROWID
            ,XGRS.*
      FROM   xx_gi_rcv_stg XGRS
      WHERE  batch_id = p_batch_id
      AND    process_flag = '2'
      AND    source_system_code = p_system_code
      ORDER BY receipt_source_code 
              ,attribute8;
                                           
     TYPE lt_child_curr_ty IS TABLE OF lcu_child_curr%ROWTYPE
     INDEX BY BINARY_INTEGER;
                          
     lt_child_curr  lt_child_curr_ty;
                                        
    --Cursor to get the details of the Shipments
   CURSOR lcu_expected_curr 
   IS                
       SELECT XGRS.ROWID
             ,XGRS.*
             ,RSH.shipment_header_id    SHI
             ,RSL.shipment_line_id      SHL 
             ,RSH.organization_id       OI
             ,RSH.ship_to_org_id   
             ,RSL.unit_of_measure       UOM
             ,RSH.currency_code         CC
             ,RSH.conversion_rate_type   
             ,RSH.conversion_rate         
             ,RSH.conversion_date            
       FROM   rcv_shipment_headers      RSH
             ,rcv_shipment_lines        RSL
             ,xx_gi_rcv_stg             XGRS
       WHERE  RSH.shipment_header_id        =  RSL.shipment_header_id
       AND    RSL.shipment_line_status_code =  'EXPECTED'
       AND    RSH.shipment_num              =  XGRS.attribute5
       AND    XGRS.batch_id = p_batch_id;
                                                           
     TYPE lt_exp_curr_ty IS TABLE OF lcu_expected_curr%ROWTYPE
     INDEX BY BINARY_INTEGER;
                          
     lt_exp_curr  lt_exp_curr_ty;
                                             
     ln_control_id               NUMBER;
     ln_conc_request_id          fnd_concurrent_requests.request_id%TYPE;
     ln_par_conc_request_id      fnd_concurrent_requests.request_id%TYPE;
     lc_error_flag_val           VARCHAR2(1) := 'N';
     lc_error_flag_proc          VARCHAR2(1) := 'N';
     lc_error_message            VARCHAR2(2000);
     ln_failed_val_count         NUMBER := 0;
     ln_failed_proc_count        NUMBER := 0;
     ln_tot_batch_count          NUMBER := 0;
     ln_success_count            NUMBER := 0;
     lc_org_name                 hr_all_organization_units.name%TYPE;
     ln_org_id                   hr_all_organization_units.organization_id%TYPE;
     ln_conversion_id            xxcomn.xx_com_conversions_conv.conversion_id%TYPE;
     lc_source_system_code       xxcomn.xx_com_conversions_conv.system_code%TYPE;
     lc_error_loc                VARCHAR2(2000);
     lc_error_msg                VARCHAR2(2000);
     lc_error_debug              VARCHAR2(2000);
     lc_phase                    VARCHAR2(50);
     lc_status                   VARCHAR2(50);
     lc_devphase                 VARCHAR2(50);
     lc_devstatus                VARCHAR2(50);
     lc_message                  VARCHAR2(50);
     lc_req_status               BOOLEAN;
     lc_lkp_err_message          VARCHAR2(2000);
     lc_currency_code            fnd_currencies.currency_code%TYPE;
     ln_vendor_id                po_headers_all.vendor_id%TYPE;
     ln_vendor_site_id           po_headers_all.vendor_site_id%TYPE;
     lc_ship_to_organization_id  NUMBER;
     lc_from_organization_id     NUMBER;
     lc_organization_code        org_organization_definitions.organization_code%TYPE;
     lc_po_header_id             po_headers_all.po_header_id%TYPE;
     lc_po_line_id               po_lines_all.po_line_id%TYPE;
     lc_po_line_location_id      po_line_locations_all.line_location_id%TYPE;
     lc_po_distribution_id       po_distributions_all.po_distribution_id%TYPE;
     lc_shipment_num             rcv_shipment_headers.shipment_num%TYPE;
     lc_shipment_header_id       rcv_shipment_headers.shipment_header_id%TYPE;
     lc_shipment_line_id         rcv_shipment_lines.shipment_line_id%TYPE;
     ln_batch_source_id          ra_batch_sources_all.batch_source_id%TYPE;
     ln_distribution_account_id  NUMBER;
     ln_transaction_type_id      NUMBER;
     ln_transaction_Intr_type_id NUMBER;
     lc_currency_conversion_type VARCHAR2(10);
     ln_item_id                  NUMBER;
     lc_subinventory             VARCHAR2(20);
     ln_organization_id          NUMBER;
     lc_primary_uom_code         VARCHAR2(3);
     ln_tran_nex_id              NUMBER;
     ln_head_nex_id              NUMBER;
     ln_grp_nex_id               NUMBER;
     ln_trx_nex_id               NUMBER;
     lc_pri_key                  VARCHAR2(20) := 0;
                                                            
    BEGIN
      --Printing the Parameters
      fnd_file.put_line(fnd_file.log,'Parameters: ');
      fnd_file.put_line(fnd_file.log,'----------');
      fnd_file.put_line(fnd_file.log,'Process Name: '||p_process_name);
      fnd_file.put_line(fnd_file.log,'Validate Only Flag: '||p_validate_only_flag);
      fnd_file.put_line(fnd_file.log,'Reset Status Flag: '||p_reset_status_flag);
      fnd_file.put_line(fnd_file.log,'Batch ID: '||p_batch_id);
      fnd_file.put_line(fnd_file.log,'----------');
                                       
      --Get the Current Operating Unit Organization id
        lc_error_loc := 'Get the Current Operating unit Organization id';
        lc_error_debug := 'Batch id: '||p_batch_id;
                                                             
        ln_org_id := fnd_profile.value('ORG_ID');
                                                        
        fnd_file.put_line(fnd_file.log,'ORG_ID: '||ln_org_id);
                                                        
       --Get the Conversion_id, Source_System_Code from the Conversion Code(p_process_name)
          lc_error_loc := 'Get the Conversion id, Source System Code';
          lc_error_debug := 'Process Name: '||p_process_name;
                                     
        BEGIN
          SELECT conversion_id
                ,system_code
          INTO   ln_conversion_id
                ,lc_source_system_code
          FROM   xxcomn.xx_com_conversions_conv
          WHERE  conversion_code = p_process_name;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lc_error_flag_val := 'Y';
            lc_error_message  :=  'The Conversion_id :' || ln_conversion_id
                                  || 'is not in xxcomn.xx_com_conversions_conv table';
                                                                                                         
            xx_com_conv_elements_pkg.log_exceptions_proc(
                                      ln_conversion_id
                                     ,ln_control_id
                                     ,lc_source_system_code
                                     ,'XX_GI_RCV_CONV_PKG'
                                     ,'XX_GI_CONV_CHD'
                                     ,'XX_GI_RCV_STG'
                                     ,'CURRENCY_CODE'
                                     ,ln_conversion_id
                                     ,''
                                     ,p_batch_id
                                     ,lc_error_message
                                     ,SQLCODE
                                     ,SQLERRM);
                                                                            
          WHEN OTHERS THEN
            lc_error_flag_val := 'Y';
            lc_error_message  :=  'The Conversion_id :'|| ln_conversion_id 
                                  || 'is not in xxcomn.xx_com_conversions_conv table';
                                                                                                 
            xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'CURRENCY_CODE'
                                        ,ln_conversion_id
                                        ,''
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
         END;                                               
                                                        
          --Get the Request id of the "OD: PO Conversion Master Program"
          lc_error_loc := 'Get the Master Request id';
          lc_error_debug := 'Batch id: '||p_batch_id||' Conversion id: '||ln_conversion_id;
                                                               
        BEGIN
          SELECT master_request_id 
          INTO   ln_par_conc_request_id
          FROM   xx_com_control_info_conv
          WHERE  batch_id = p_batch_id
          AND    conversion_id = ln_conversion_id;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lc_error_flag_val := 'Y';
            lc_error_message  :=  'The Master Request id :' || ln_par_conc_request_id
                                  || 'is not in xxcomn.xx_com_conversions_conv table';
                                                                                                         
            xx_com_conv_elements_pkg.log_exceptions_proc(
                                      ln_conversion_id
                                     ,ln_control_id
                                     ,lc_source_system_code
                                     ,'XX_GI_RCV_CONV_PKG'
                                     ,'XX_GI_CONV_CHD'
                                     ,'XX_GI_RCV_STG'
                                     ,'CURRENCY_CODE'
                                     ,ln_par_conc_request_id
                                     ,''
                                     ,p_batch_id
                                     ,lc_error_message
                                     ,SQLCODE
                                     ,SQLERRM);
                                                                            
          WHEN OTHERS THEN
            lc_error_flag_val := 'Y';
            lc_error_message  :=  'The Master Request id :'|| ln_par_conc_request_id 
                                  || 'is not in xxcomn.xx_com_conversions_conv table';
                                                                                                 
            xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'CURRENCY_CODE'
                                        ,ln_par_conc_request_id
                                        ,''
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
        END;       
                                                  
      -- Cursor lcu_child_curr Starts
      OPEN lcu_child_curr (lc_source_system_code);
        FETCH lcu_child_curr BULK COLLECT INTO lt_child_curr;
          FOR i IN 1..lt_child_curr.COUNT
          LOOP
                                   
             --Initialization 
             lc_error_flag_val  := 'N';
             lc_error_flag_proc := 'N';
             lc_error_message   := NULL;
                                                          
             ln_tot_batch_count := ln_tot_batch_count + 1;
                                                       
            -- Validation of Receipt Source Code Begin
            IF lt_child_curr(i).receipt_source_code = 'VENDOR' THEN
                                                           
                 -- Validating for Vendor ID.
                                                                    
                 BEGIN
                   lc_error_loc := 'Validating for Vendor ID';
                   lc_error_debug := 'Vendor ID :' || lt_child_curr(i).vendor_id ;
                                                                                      
                   SELECT vendor_id
                         ,vendor_site_id
                         ,po_header_id
                   INTO   ln_vendor_id
                         ,ln_vendor_site_id
                         ,lc_po_header_id
                   FROM   po_headers_all
                   WHERE  segment1 = lt_child_curr(i).document_num;
                                                                                   
                 EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                  lc_error_flag_val := 'Y';
                  lc_error_message  :=  'The Doc Number :' || lt_child_curr(i).document_num 
                                     || 'is not defined in Oracle EBS System';
                                                                                                         
                  xx_com_conv_elements_pkg.log_exceptions_proc(
                                       ln_conversion_id
                                      ,ln_control_id
                                      ,lc_source_system_code
                                      ,'XX_GI_RCV_CONV_PKG'
                                      ,'XX_GI_CONV_CHD'
                                      ,'XX_GI_RCV_STG'
                                      ,'DOC_NUM'
                                      ,lt_child_curr(i).document_num
                                      ,lt_child_curr(i).source_system_ref
                                      ,p_batch_id
                                      ,lc_error_message
                                      ,SQLCODE
                                      ,SQLERRM);
                                                                            
                  WHEN OTHERS THEN
                  lc_error_flag_val := 'Y';
                  lc_error_message  :=  'The Document Num :'|| lt_child_curr(i).document_num
                                       || 'is not defined in Oracle EBS System';
                                                                                                 
                  xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'DOC_NUM'
                                        ,lt_child_curr(i).document_num
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                 END;
                  -- Validating for Currency Code.
                                                                  
                  BEGIN
                    lc_error_loc   := 'Validating for Currency Code';
                    lc_error_debug := 'Currency Code :' || lt_child_curr(i).currency_code ;
                                                                                      
                      SELECT currency_code
                            ,'User'
                      INTO  lc_currency_code
                           ,lc_currency_conversion_type
                      FROM  fnd_currencies
                      WHERE UPPER (issuing_territory_code) = UPPER (lt_child_curr(i).currency_code)
                      AND   enabled_flag = 'Y';
                                                                                   
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    lc_error_flag_val := 'Y';
                    lc_error_message  :=  'The Currency Code :' || lt_child_curr(i).currency_code 
                                         || 'is not defined in Oracle EBS System';
                                                                                                         
                    xx_com_conv_elements_pkg.log_exceptions_proc(
                                       ln_conversion_id
                                      ,ln_control_id
                                      ,lc_source_system_code
                                      ,'XX_GI_RCV_CONV_PKG'
                                      ,'XX_GI_CONV_CHD'
                                      ,'XX_GI_RCV_STG'
                                      ,'CURRENCY_CODE'
                                      ,lt_child_curr(i).currency_code
                                      ,lt_child_curr(i).source_system_ref
                                      ,p_batch_id
                                      ,lc_error_message
                                      ,SQLCODE
                                      ,SQLERRM);
                                                                            
                    WHEN OTHERS THEN
                    lc_error_flag_val := 'Y';
                    lc_error_message  :=  'The Currency Code :'|| lt_child_curr(i).currency_code 
                                          || 'is not defined in Oracle EBS System';
                                                                                                 
                    xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'CURRENCY_CODE'
                                        ,lt_child_curr(i).currency_code
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                  END;
                                                               
                  -- Validating for Ship to Organization ID.
                                                                  
                  BEGIN
                    lc_error_loc   := 'Validating for Ship to Organization ID';
                    lc_error_debug := 'Ship to Organization ID :' || lt_child_curr(i).attribute2 ;
                                                                     
                    -- calling the function for ship_to_organization_id                
                    BEGIN
                     lc_ship_to_organization_id := xx_gi_comn_utils_pkg.get_ebs_organization_id
                                                  (lt_child_curr(i).attribute2);
                                                                                                                                                       
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    lc_error_flag_val := 'Y';
                    lc_error_message  :=  'The Ship to Organization ID :' || lt_child_curr(i).attribute2 
                                          || 'is not defined in Oracle EBS System';
                                                                                                         
                    xx_com_conv_elements_pkg.log_exceptions_proc(
                                      ln_conversion_id
                                     ,ln_control_id
                                     ,lc_source_system_code
                                     ,'XX_GI_RCV_CONV_PKG'
                                     ,'XX_GI_CONV_CHD' 
                                     ,'XX_GI_RCV_STG'
                                     ,'SHIP_TO_ORGANIZATION_ID'
                                     ,lt_child_curr(i).attribute2
                                     ,lt_child_curr(i).source_system_ref
                                     ,p_batch_id
                                     ,lc_error_message
                                     ,SQLCODE
                                     ,SQLERRM);
                    WHEN OTHERS THEN
                    lc_error_flag_val := 'Y';
                    lc_error_message  :=  'The Ship to Organization ID :'|| lt_child_curr(i).attribute2 
                                          || 'is not defined in Oracle EBS System';
                                                                                                 
                    xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'SHIP_TO_ORGANIZATION_ID'
                                        ,lt_child_curr(i).attribute2
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                    END;
                  END;
                                                           
                  -- Validating for Ship to Organization Code.
                                                                  
                 BEGIN
                  lc_error_loc   := 'Validating for Ship to Organization Code';
                  lc_error_debug := 'Ship to Organization Code :' || lt_child_curr(i).ship_to_organization_code ;
                                                                                      
                    SELECT organization_code
                    INTO   lc_organization_code
                    FROM   org_organization_definitions
                    WHERE  organization_id = lc_ship_to_organization_id;
                                                                              
                 EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                   lc_error_flag_val := 'Y';
                   lc_error_message :=  'The Ship to Organization Code :' || lt_child_curr(i).ship_to_organization_code 
                                        || 'is not defined in Oracle EBS System';
                                                                                                         
                   xx_com_conv_elements_pkg.log_exceptions_proc(
                                       ln_conversion_id
                                      ,ln_control_id
                                      ,lc_source_system_code
                                      ,'XX_GI_RCV_CONV_PKG'
                                      ,'XX_GI_CONV_CHD'
                                      ,'XX_GI_RCV_STG'
                                      ,'ORGANIZATION_CODE'
                                      ,lt_child_curr(i).ship_to_organization_code
                                      ,lt_child_curr(i).source_system_ref
                                      ,p_batch_id
                                      ,lc_error_message
                                      ,SQLCODE
                                      ,SQLERRM);
                                                                            
                   WHEN OTHERS THEN
                   lc_error_flag_val := 'Y';
                   lc_error_message  :=  'The Ship to Organization Code :'|| lt_child_curr(i).ship_to_organization_code
                                         || 'is not defined in Oracle EBS System';
                                                                                                 
                   xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'ORGANIZATION_CODE'
                                        ,lt_child_curr(i).ship_to_organization_code
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                 END;
                                                         
                 -- Validating for Inventory Item ID.
                                                                  
                 BEGIN
                   lc_error_loc   := 'Validating for Inventory Item ID';
                   lc_error_debug := 'Inventory Item ID :' || lt_child_curr(i).attribute3 ;
                                                             
                   -- calling the function for inventory_item_id                        
                         BEGIN
                           ln_item_id := xx_gi_comn_utils_pkg.get_inventory_item_id
                                         (lt_child_curr(i).attribute3, lc_ship_to_organization_id);
                                                                                                                                                       
                 EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                     lc_error_flag_val := 'Y';
                     lc_error_message :=  'The Inventory Item ID :' || lt_child_curr(i).attribute3 
                                          || 'is not defined in Oracle EBS System';
                                                                                                         
                     xx_com_conv_elements_pkg.log_exceptions_proc(
                                       ln_conversion_id
                                      ,ln_control_id
                                      ,lc_source_system_code
                                      ,'XX_GI_RCV_CONV_PKG'
                                      ,'XX_GI_CONV_CHD'
                                      ,'XX_GI_RCV_STG'
                                      ,'INVENTORY_ITEM_ID'
                                      ,lt_child_curr(i).attribute3
                                      ,lt_child_curr(i).source_system_ref
                                      ,p_batch_id
                                      ,lc_error_message
                                      ,SQLCODE
                                      ,SQLERRM);
                   WHEN OTHERS THEN
                     lc_error_flag_val := 'Y';
                     lc_error_message :=  'The Inventory Item ID :'|| lt_child_curr(i).attribute3 
                                          || 'is not defined in Oracle EBS System';
                                                                                                 
                     xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'INVENTORY_ITEM_ID'
                                        ,lt_child_curr(i).attribute3
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                         END; 
                 END;
                                                          
                 -- Validating for PO Line ID.
                                                                  
                 BEGIN
                   lc_error_loc   := 'Validating for PO Line ID';
                   lc_error_debug := 'PO Line ID :' || lt_child_curr(i).po_line_id ;
                                                                                      
                     SELECT po_line_id
                     INTO   lc_po_line_id
                     FROM   po_lines_all
                     WHERE  po_header_id    = lc_po_header_id
                     AND    item_id         = ln_item_id;
                                                                                                                                                       
                 EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                   lc_error_flag_val := 'Y';
                   lc_error_message  :=  'The PO Lines ID :' || lt_child_curr(i).po_line_id 
                                         || 'is not defined in Oracle EBS System';
                                                                                                         
                   xx_com_conv_elements_pkg.log_exceptions_proc(
                                        ln_conversion_id
                                       ,ln_control_id
                                       ,lc_source_system_code
                                       ,'XX_GI_RCV_CONV_PKG'
                                       ,'XX_GI_CONV_CHD'
                                       ,'XX_GI_RCV_STG'
                                       ,'PO_LINE_ID'
                                       ,lt_child_curr(i).po_line_id
                                       ,lt_child_curr(i).source_system_ref
                                       ,p_batch_id
                                       ,lc_error_message
                                       ,SQLCODE
                                       ,SQLERRM);
                                                                            
                   WHEN OTHERS THEN
                   lc_error_flag_val := 'Y';
                   lc_error_message  :=  'The PO Line ID :'|| lt_child_curr(i).po_line_id 
                                         || 'is not defined in Oracle EBS System';
                                                                                                 
                   xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'PO_LINE_ID'
                                        ,lt_child_curr(i).po_line_id
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                 END;
                                                            
                 -- Validating for PO Distribution ID.
                 -- For a PO Line there will be only one Loaction ID in Legacy
                                                                  
                 BEGIN
                   lc_error_loc   := 'Validating for PO Distribution ID';
                   lc_error_debug := 'PO Distribution ID :' || lt_child_curr(i).po_distribution_id ;
                                                                                      
                     SELECT po_distribution_id
                           ,line_location_id
                     INTO   lc_po_distribution_id
                           ,lc_po_line_location_id
                     FROM   po_distributions_all
                     WHERE  po_header_id      = lc_po_header_id
                     AND    po_line_id        = lc_po_line_id;
                                                                   
                 EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                   lc_error_flag_val := 'Y';
                   lc_error_message :=  'The PO Distribution ID :' || lt_child_curr(i).po_distribution_id
                                         || 'is not defined in Oracle EBS System';
                                                                                                         
                   xx_com_conv_elements_pkg.log_exceptions_proc(
                                       ln_conversion_id
                                      ,ln_control_id
                                      ,lc_source_system_code
                                      ,'XX_GI_RCV_CONV_PKG'
                                      ,'XX_GI_CONV_CHD'
                                      ,'XX_GI_RCV_STG'
                                      ,'PO_DISTRIBUTION_ID'
                                      ,lt_child_curr(i).po_distribution_id
                                      ,lt_child_curr(i).source_system_ref
                                      ,p_batch_id
                                      ,lc_error_message
                                      ,SQLCODE
                                      ,SQLERRM);
                                                                            
                   WHEN OTHERS THEN
                   lc_error_flag_val := 'Y';
                   lc_error_message :=  'The PO Distribution ID :'|| lt_child_curr(i).po_distribution_id
                                         || 'is not defined in Oracle EBS System';
                                                                                                 
                   xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'PO_DISTRIBUTION_ID'
                                        ,lt_child_curr(i).po_distribution_id
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                 END;
                                                        
                 -- Validating for Shipment Num.
                                                                  
                 BEGIN
                   lc_error_loc   := 'Validating for Shipment Num';
                   lc_error_debug := 'Shipment Num :' ;
                                                                                      
                     SELECT RSH.shipment_num
                           ,RSH.shipment_header_id 
                           ,RSL.shipment_line_id
                     INTO   lc_shipment_num
                           ,lc_shipment_header_id
                           ,lc_shipment_line_id
                     FROM   rcv_shipment_headers        RSH
                           ,rcv_shipment_lines          RSL
                     WHERE  RSH.shipment_header_id        = RSL.shipment_header_id
                     AND    RSL.shipment_line_status_code = 'EXPECTED'
                     AND    RSL.po_header_id   	         = lc_po_header_id
                     AND    RSL.po_line_id                = lc_po_line_id
                     AND    RSL.po_line_location_id       = lc_po_line_location_id
                     AND    RSL.po_distribution_id        = lc_po_distribution_id;
                                                                              
                 EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                   lc_shipment_num              := NULL;
                   lc_shipment_header_id        := NULL;
                   lc_shipment_line_id          := NULL;
                   WHEN OTHERS THEN
                   lc_error_flag_val             := 'Y';
                   lc_shipment_num               := NULL;
                   lc_shipment_header_id         := NULL;
                   lc_shipment_line_id           := NULL;
                 END;
                                            
                   -- Updating the Process Flag to 3 for Interface Staging Table
                                               
                       IF (lc_error_flag_val = 'Y') THEN
                         UPDATE xx_gi_rcv_stg
                         SET    process_flag = '3'
                         WHERE  ROWID = lt_child_curr(i).ROWID;
                                                                 
                         COMMIT;
                       --Counting No: Validation failed records
                         ln_failed_val_count := ln_failed_val_count + 1;
                                                          
                       END IF; 
                                                 
                 IF (p_validate_only_flag = 'N' 
                          AND lc_error_flag_val = 'N' ) THEN
                                                                      
                   lc_error_loc   := 'Inserting into RCV_HEADERS_INTERFACE';
                   lc_error_debug := 'Header Interface ID: '||ln_head_nex_id;
                                                                      
                   -- Inserting Header records only
                   IF lt_child_curr(i).attribute8 <> lc_pri_key THEN
                     
                    SELECT rcv_headers_interface_s.NEXTVAL
                    INTO   ln_head_nex_id
                    FROM   sys.dual;
                                 
                    SELECT rcv_interface_groups_s.NEXTVAL
                    INTO   ln_grp_nex_id
                    FROM   sys.dual;
                             
                    UPDATE xx_gi_rcv_stg
                    SET    header_interface_id = ln_head_nex_id
                    WHERE ROWID = lt_child_curr(i).ROWID;
                                                   
                     --Insert into RCV_HEADERS_INTERFACE
                     INSERT INTO RCV_HEADERS_INTERFACE(
                      header_interface_id  
                     ,group_id 
                     ,processing_status_code 
                     ,receipt_source_code 
                     ,transaction_type 
                     ,last_update_date 
                     ,last_updated_by 
                     ,last_update_login
                     ,creation_date
                     ,created_by 
                     ,shipment_num
                     ,shipped_date
                     ,vendor_id
                     ,validation_flag 
                     ,ship_to_organization_code
                     ,auto_transact_code
                     ,expected_receipt_date
                     ,receipt_num
                     ,attribute1
                     ,attribute2
                     ,attribute3
                     ,attribute4
                     ,attribute5
                     ,attribute6
                     ,attribute7
                     ,attribute8
                     ,attribute9
                     ,attribute10
                     ,attribute11
                     ,attribute12
                     ,attribute13
                     ,attribute14
                     ,attribute15
                     )
                     VALUES
                    (
                     ln_head_nex_id                      --header_interface_id , 
                    ,ln_grp_nex_id                       --group_id ,
                    ,'PENDING'                           --processing_status_code ,
                    ,lt_child_curr(i).receipt_source_code --receipt_source_code ,
                    ,'NEW'                               --transaction_type ,
                    ,lt_child_curr(i).last_update_date   --last_update_date ,
                    ,fnd_global.user_id                  --last_updated_by ,
                    ,fnd_global.login_id                 --last_update_login ,
                    ,lt_child_curr(i).creation_date      --creation_date ,
                    ,fnd_global.user_id                  --created_by ,
                    ,lc_shipment_num                     --shipment_num ,
                    ,lt_child_curr(i).last_update_date   --shipped_date ,
                    ,ln_vendor_id                        --vendor_id,
                    ,'Y'                                 --validation_flag ,
                    ,lc_organization_code                --ship_to_organization_code ,
                    ,'DELIVER'                           --auto_transact_code,
                    ,lt_child_curr(i).last_update_date  --expected_receipt_date,
                    ,xx_gi_receipt_num_us_s.NEXTVAL     --receipt_num,
                    ,lt_child_curr(i).attribute1        --attribute1,
                    ,lt_child_curr(i).attribute2        --attribute2,
                    ,lt_child_curr(i).attribute3        --attribute3,
                    ,lt_child_curr(i).attribute4        --attribute4,
                    ,lt_child_curr(i).attribute5        --attribute5,
                    ,lt_child_curr(i).attribute6        --attribute6,
                    ,lt_child_curr(i).attribute7        --attribute7,
                    ,lt_child_curr(i).attribute8        --attribute8,
                    ,lt_child_curr(i).attribute9        --attribute9,
                    ,lt_child_curr(i).attribute10       --attribute10,
                    ,lt_child_curr(i).attribute11       --attribute11,
                    ,lt_child_curr(i).attribute12       --attribute12,
                    ,lt_child_curr(i).attribute13       --attribute13,
                    ,lt_child_curr(i).attribute14       --attribute14,
                    ,lt_child_curr(i).attribute15);        --attribute15
                                                
                      lc_pri_key := lt_child_curr(i).attribute8;
                                                          
                   END IF;
                                          
                     SELECT rcv_transactions_interface_s.NEXTVAL
                     INTO   ln_tran_nex_id
                     FROM   sys.dual;
                                        
                     UPDATE xx_gi_rcv_stg
                     SET    interface_transaction_id =  ln_tran_nex_id
                     WHERE ROWID = lt_child_curr(i).ROWID;
                                          
                    -- Inserting Transaction Records only
                    INSERT INTO RCV_TRANSACTIONS_INTERFACE(
                      interface_transaction_id 
                     ,header_interface_id 
                     ,group_id 
                     ,last_update_date 
                     ,last_updated_by 
                     ,last_update_login 
                     ,creation_date 
                     ,created_by 
                     ,transaction_type 
                     ,transaction_date 
                     ,processing_status_code 
                     ,processing_mode_code 
                     ,transaction_status_code 
                     ,quantity 
                     ,unit_of_measure 
                     ,receipt_source_code 
                     ,source_document_code
                     ,po_header_id
                     ,po_line_id
                     ,po_line_location_id
                     ,po_distribution_id
                     ,shipment_header_id
                     ,shipment_line_id
                     ,validation_flag
                     ,auto_transact_code
                     ,subinventory
                     ,currency_code
                     ,currency_conversion_type
                     ,currency_conversion_rate
                     ,currency_conversion_date
                     --,deliver_to_location_id
                     ,attribute1
                     ,attribute2
                     ,attribute3
                     ,attribute4
                     ,attribute5
                     ,attribute6
                     ,attribute7
                     ,attribute8
                     ,attribute9
                     ,attribute10
                     ,attribute11
                     ,attribute12
                     ,attribute13
                     ,attribute14
                     ,attribute15
                     )
                     SELECT
                      ln_tran_nex_id                            --interface_transaction_id ,
                     ,ln_head_nex_id                            --header_interface_id ,
                     ,ln_grp_nex_id                             --group_id ,
                     ,lt_child_curr(i).last_update_date         --last_update_date ,
                     ,fnd_global.user_id                        --last_updated_by ,
                     ,fnd_global.login_id                       --last_update_login ,
                     ,lt_child_curr(i).creation_date            --creation_date ,
                     ,fnd_global.user_id                        --created_by ,
                     ,'RECEIVE'                                 --transaction_type ,
                     ,sysdate                                   --transaction_date ,
                     ,'PENDING'                                 --processing_status_code ,
                     ,'BATCH'                                   --processing_mode_code ,
                     ,'PENDING'                                 --transaction_status_code ,
                     ,lt_child_curr(i).quantity                 --quantity ,
                     ,lt_child_curr(i).unit_of_measure          --unit_of_measure ,
                     ,lt_child_curr(i).receipt_source_code      --receipt_source_code ,
                     ,'PO'                                      --source_document_code ,
                     ,lc_po_header_id                           --po_header_id,
                     ,lc_po_line_id                             --po_line_id,
                     ,lc_po_line_location_id                    --po_line_location_id,
                     ,lc_po_distribution_id                     --po_distribution_id,
                     ,lc_shipment_header_id                     --shipment_header_id,
                     ,lc_shipment_line_id                       --shipment_line_id,
                     ,'Y'                                       --validation_flag,
                     ,'DELIVER'                                 --auto_transact_code,
                     ,'STOCK'                                   --subinventory,
                     ,lc_currency_code                          --currency_code
                     ,lc_currency_conversion_type               --currency_conversion_type
                     ,lt_child_curr(i).currency_conversion_rate --currency_conversion_rate
                     ,sysdate                                   --currency_conversion_date
                     --,lc_ship_to_organization_id                -- deliver_to_location_id
                     ,lt_child_curr(i).attribute1               --attribute1,
                     ,lt_child_curr(i).attribute2               --attribute2,
                     ,lt_child_curr(i).attribute3               --attribute3,
                     ,lt_child_curr(i).attribute4               --attribute4,
                     ,lt_child_curr(i).attribute5               --attribute5,
                     ,lt_child_curr(i).attribute6               --attribute6,
                     ,lt_child_curr(i).attribute7               --attribute7,
                     ,lt_child_curr(i).attribute8               --attribute8,
                     ,lt_child_curr(i).attribute9               --attribute9,
                     ,lt_child_curr(i).attribute10              --attribute10,
                     ,lt_child_curr(i).attribute11              --attribute11,
                     ,lt_child_curr(i).attribute12              --attribute12,
                     ,lt_child_curr(i).attribute13              --attribute13,
                     ,lt_child_curr(i).attribute14              --attribute14,
                     ,lt_child_curr(i).attribute15               --attribute15
                     FROM sys.DUAL;
                 END IF;
                                      
                     --Counting No: of Failed and Processed records
                     --Checking the Error flag
                     IF (lc_error_flag_proc = 'Y') THEN
                       ROLLBACK;
                       lc_error_loc := 'Updating the Process flag = 6';
                       lc_error_debug := 'Header Interface Id: '|| ln_head_nex_id ;
                                      
                         UPDATE xx_gi_rcv_stg
                         SET    process_flag = '6'
                         WHERE  ROWID = lt_child_curr(i).ROWID;
                                                           
                      --Counting No: Processing failed records
                       ln_failed_proc_count :=  ln_failed_proc_count + 1;
                      END IF;
            -- Validation of Receipt Source Code = 'RTV' 
                                         
            ELSIF lt_child_curr(i).receipt_source_code = 'RTV' THEN
                                                     
                 -- Validating for Organization ID.
                                                                  
                 BEGIN
                   lc_error_loc   := 'Validating for Organization ID';
                   lc_error_debug := 'Organization ID :' || lt_child_curr(i).attribute1 ;
                                                            
                    -- calling the function for organization_id                      
                     BEGIN
                      ln_organization_id := xx_gi_comn_utils_pkg.get_ebs_organization_id
                                           (lt_child_curr(i).attribute1);
                     EXCEPTION
                       WHEN OTHERS THEN
                       lc_error_flag_val := 'Y';
                       lc_error_message  :=  'The Organization ID :'|| lt_child_curr(i).attribute2 
                                             || 'is not defined in Oracle EBS System';
                                                                                                 
                       xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'ORGANIZATION_ID'
                                        ,lt_child_curr(i).attribute2
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                     END;
                  END;
            
       	          -- Validating for Distribution Account ID.
                                                                  
                  BEGIN
                    lc_error_loc := 'Validating for Distribution Account ID';
                    lc_error_debug := 'Distribution Account ID :' || lt_child_curr(i).distribution_account_id;
                                                                    
                      -- calling the function for distribution_account_id                 
                      BEGIN
                        ln_distribution_account_id := xx_gi_comn_utils_pkg.get_gi_adj_ccid
                                             (lt_child_curr(i).attribute4,ln_organization_id);
                       EXCEPTION
                         WHEN OTHERS THEN
                         lc_error_flag_val := 'Y';
                         lc_error_message :=  'The Distribution Account ID :'|| lt_child_curr(i).distribution_account_id
                                              || 'is not defined in Oracle EBS System';
                                                                                                  
                         xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'DISTRIBUTION_ACCOUNT_ID'
                                        ,lt_child_curr(i).distribution_account_id
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                       END; 
                  END;
                                                          
                  -- Validating for Transaction Type ID.
                                                                  
                   BEGIN
                     lc_error_loc := 'Validating for Transaction Type ID';
                     lc_error_debug := 'Transaction Type ID :' || lt_child_curr(i).transaction_type_id;
                                                            
                       -- calling the function for transaction_type_id               
                       BEGIN
                         ln_transaction_type_id := xx_gi_comn_utils_pkg.get_gi_trx_type_id
                                                  (substr(lt_child_curr(i).attribute4,1,4)
                                           , substr(lt_child_curr(i).attribute4,9,2), 'Receipt');
                       EXCEPTION
                         WHEN OTHERS THEN
                         lc_error_flag_val := 'Y';
                         lc_error_message :=  'The Transaction Type ID :'|| lt_child_curr(i).transaction_type_id
                                               || 'is not defined in Oracle EBS System';
                                                                                                 
                         xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'TRANSACTION_TYPE_ID'
                                        ,lt_child_curr(i).transaction_type_id
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                       END; 
                   END;
                                                                      
                    -- Validating for Sub-Inventory Code.
                                                                  
                    BEGIN
                      lc_error_loc := 'Validating for Sub-Inventory Code';
                      lc_error_debug := 'Sub-Inventory Code :' || lt_child_curr(i).attribute4;
                                                                                       
                       IF substr(lt_child_curr(i).attribute4,9,2) = 'DD' THEN
                          lc_subinventory := 'DAMAGED';
                       ELSIF substr(lt_child_curr(i).attribute4,9,2) = 'BB' THEN
                          lc_subinventory := 'BUYBACK';
                       END IF;
                         SELECT secondary_inventory_name
                         INTO   lc_subinventory
                         FROM   mtl_secondary_inventories
                         WHERE  secondary_inventory_name = lc_subinventory
                         AND    organization_id = ln_organization_id;          
                    EXCEPTION                                                                                                                                           
                       WHEN OTHERS THEN
                       lc_error_flag_val := 'Y';
                       lc_error_message :=  'The Sub-Inventory :'|| lt_child_curr(i).attribute1
                                            || 'is not defined in Oracle EBS System';
                                                                                                 
                       xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'TRANSACTION_TYPE_ID'
                                        ,lt_child_curr(i).attribute4
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                    END;
                                            
                     -- Validating for Inventory Item ID.
                                                                  
                      BEGIN
                       lc_error_loc   := 'Validating for Inventory Item ID';
                       lc_error_debug := 'Inventory Item ID :' || lt_child_curr(i).attribute3 ;
                                             
                          -- calling the function for item_id                               
                          BEGIN
                            ln_item_id := xx_gi_comn_utils_pkg.get_inventory_item_id
                                         (lt_child_curr(i).attribute3, ln_organization_id);
                          END;          
                                    
                           SELECT  primary_uom_code
                           INTO    lc_primary_uom_code
                           FROM    mtl_system_items_b
                           WHERE   organization_id   = ln_organization_id
                           AND     inventory_item_id = ln_item_id;
                     EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                        lc_error_flag_val := 'Y';
                        lc_error_message :=  'The Inventory Item ID :' || lt_child_curr(i).attribute3 
                                              || 'is not defined in Oracle EBS System';
                                                                                                         
                        xx_com_conv_elements_pkg.log_exceptions_proc(
                                        ln_conversion_id
                                       ,ln_control_id
                                       ,lc_source_system_code
                                       ,'XX_GI_RCV_CONV_PKG'
                                       ,'XX_GI_CONV_CHD'
                                       ,'XX_GI_RCV_STG'
                                       ,'INVENTORY_ITEM_ID'
                                       ,lt_child_curr(i).attribute3
                                       ,lt_child_curr(i).source_system_ref
                                       ,p_batch_id
                                       ,lc_error_message
                                       ,SQLCODE
                                       ,SQLERRM);
                         WHEN OTHERS THEN
                         lc_error_flag_val := 'Y';
                         lc_error_message :=  'The Inventory Item ID :'|| lt_child_curr(i).attribute3 
                                              || 'is not defined in Oracle EBS System';
                                                                                                 
                         xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'INVENTORY_ITEM_ID'
                                        ,lt_child_curr(i).attribute3
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                     END;
                                                   
                     -- Validating for Currency Code.
                                                                  
                     BEGIN
                       lc_error_loc   := 'Validating for Currency Code';
                       lc_error_debug := 'Currency Code :' || lt_child_curr(i).currency_code ;
                                                                                      
                         SELECT currency_code
                               ,'User'
                         INTO  lc_currency_code
                              ,lc_currency_conversion_type
                         FROM  fnd_currencies
                         WHERE UPPER (issuing_territory_code) = UPPER (lt_child_curr(i).currency_code)
                         AND   enabled_flag = 'Y';
                                                                                   
                    EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                       lc_error_flag_val := 'Y';
                       lc_error_message  :=  'The Currency Code :' || lt_child_curr(i).currency_code 
                                              || 'is not defined in Oracle EBS System';
                                                                                                         
                      xx_com_conv_elements_pkg.log_exceptions_proc(
                                      ln_conversion_id
                                     ,ln_control_id
                                     ,lc_source_system_code
                                     ,'XX_GI_RCV_CONV_PKG'
                                     ,'XX_GI_CONV_CHD'
                                     ,'XX_GI_RCV_STG'
                                     ,'CURRENCY_CODE'
                                     ,lt_child_curr(i).currency_code
                                     ,lt_child_curr(i).source_system_ref
                                     ,p_batch_id
                                     ,lc_error_message
                                     ,SQLCODE
                                     ,SQLERRM);
                                                                            
                      WHEN OTHERS THEN
                        lc_error_flag_val := 'Y';
                        lc_error_message  :=  'The Currency Code :'|| lt_child_curr(i).currency_code 
                                             || 'is not defined in Oracle EBS System';
                                                                                                 
                        xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'CURRENCY_CODE'
                                        ,lt_child_curr(i).currency_code
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                    END;
                   -- Updating the Process Flag to 3 for Interface Staging Table
                                               
                       IF (lc_error_flag_val = 'Y') THEN
                         UPDATE xx_gi_rcv_stg
                         SET    process_flag = '3'
                         WHERE  ROWID = lt_child_curr(i).ROWID;
                                                                 
                         COMMIT;
                       --Counting No: Validation failed records
                         ln_failed_val_count := ln_failed_val_count + 1;
                                                          
                       END IF; 
                                                                              
                    IF (p_validate_only_flag = 'N' 
                               AND lc_error_flag_val = 'N' ) THEN
                                                                      
                       lc_error_loc   := 'Inserting into MTL_TRANSACTIONS_INTERFACE';
                       lc_error_debug := 'Transaction Interface ID: '||ln_trx_nex_id;
                                                                                
                      --Insert into MTL_TRANSACTIONS_INTERFACE
                                                            
                       SELECT xx_gi_transaction_int_s.NEXTVAL
                       INTO   ln_trx_nex_id
                       FROM   sys.dual;
                                        
                       UPDATE xx_gi_rcv_stg
                       SET    transaction_interface_id =  ln_tran_nex_id
                       WHERE ROWID = lt_child_curr(i).ROWID;
                                          
                      INSERT INTO MTL_TRANSACTIONS_INTERFACE(
                       transaction_interface_id
                      ,source_code
                      ,source_header_id
                      ,source_line_id
                      ,process_flag
                      ,transaction_mode
                      ,last_update_date 
                      ,last_updated_by 
                      ,last_update_login 
                      ,creation_date 
                      ,created_by 
                      ,distribution_account_id
                      ,organization_id
                      ,transaction_quantity
                      ,transaction_uom
                      ,transaction_date
                      ,transaction_type_id
                      ,inventory_item_id
                      ,subinventory_code
                      ,transaction_reference
                      ,transaction_cost
                      ,currency_code
                      ,currency_conversion_type
                      ,currency_conversion_rate
                      ,currency_conversion_date
                      ,attribute1
                      ,attribute2
                      ,attribute3
                      ,attribute4
                      ,attribute5
                      ,attribute6
                      ,attribute7
                      ,attribute8
                      ,attribute9
                      ,attribute10
                      ,attribute11
                      ,attribute12
                      ,attribute13
                      ,attribute14
                      ,attribute15
                      )
                      Values
                      (
                       ln_trx_nex_id                   --transaction_interface_id
                      ,'SIV RTV Receipts'               --source_code
                      ,lt_child_curr(i).batch_id        --source_header_id
                      ,ln_conversion_id                 --source_line_id
                      ,1                               --process_flag 
                      ,3                               --transaction_mode
                      ,lt_child_curr(i).last_update_date   --last_update_date ,
                      ,fnd_global.user_id                --last_updated_by ,
                      ,fnd_global.login_id               --last_update_login ,
                      ,lt_child_curr(i).creation_date    --creation_date ,
                      ,fnd_global.user_id                --created_by ,
                      ,ln_distribution_account_id        --distribution_account_id
                      ,ln_organization_id                --organization_id
                      ,lt_child_curr(i).quantity         --transaction_quantity
                      ,lc_primary_uom_code               --transaction_uom
                      ,lt_child_curr(i).creation_date    --transaction_date
                      ,ln_transaction_type_id            --transaction_type_id
                      ,ln_item_id                        --inventory_item_id
                      ,lc_subinventory                   --subinventory_code
                      ,lt_child_curr(i).transaction_reference --transaction_reference,
                      ,lt_child_curr(i).transaction_cost      --transaction_cost
                      ,lc_currency_code                       --currency_code
                      ,lc_currency_conversion_type            --currency_conversion_type
                      ,lt_child_curr(i).currency_conversion_rate--currency_conversion_rate
                      ,sysdate                                  --currency_conversion_date
                      ,lt_child_curr(i).attribute1               --attribute1,
                      ,lt_child_curr(i).attribute2               --attribute2,
                      ,lt_child_curr(i).attribute3               --attribute3,
                      ,lt_child_curr(i).attribute4               --attribute4,
                      ,lt_child_curr(i).attribute5               --attribute5,
                      ,lt_child_curr(i).attribute6               --attribute6,
                      ,lt_child_curr(i).attribute7               --attribute7,
                      ,lt_child_curr(i).attribute8               --attribute8,
                      ,lt_child_curr(i).attribute9               --attribute9,
                      ,lt_child_curr(i).attribute10              --attribute10,
                      ,lt_child_curr(i).attribute11             --attribute11,
                      ,lt_child_curr(i).attribute12             --attribute12,
                      ,lt_child_curr(i).attribute13             --attribute13,
                      ,lt_child_curr(i).attribute14             --attribute14,
                      ,lt_child_curr(i).ROWID);              --attribute15
                                                                   
                  END IF;                                      
                                      
                     --Counting No: of Failed and Processed records
                     --Checking the Error flag
                     IF (lc_error_flag_proc = 'Y') THEN
                       ROLLBACK;
                       lc_error_loc := 'Updating the Process flag = 6';
                       lc_error_debug := 'Transaction Interface Id: '|| ln_trx_nex_id;
                                      
                         UPDATE xx_gi_rcv_stg
                         SET    process_flag = '6'
                         WHERE  ROWID = lt_child_curr(i).ROWID;
                                                           
                      --Counting No: Processing failed records
                       ln_failed_proc_count :=  ln_failed_proc_count + 1;
                      END IF;
                                                                  
            -- Validation of Receipt Source Code = 'INVENTORY'
            ELSIF lt_child_curr(i).receipt_source_code = 'INVENTORY' THEN
                                         
       	            -- Validating for Ship to Organization ID.
                    BEGIN
                      lc_error_loc   := 'Validating for Ship to Organization ID';
                      lc_error_debug := 'Ship to Organization ID :' || lt_child_curr(i).attribute2;
                                                                                      
                        BEGIN
                        lc_ship_to_organization_id := xx_gi_comn_utils_pkg.get_ebs_organization_id
                                             (lt_child_curr(i).attribute2);
                        EXCEPTION
                          WHEN OTHERS THEN
                          lc_error_flag_val := 'Y';
                          lc_error_message  :=  'The Ship to Organization ID :'|| lt_child_curr(i).attribute2 
                                                || 'is not defined in Oracle EBS System';
                                                                                                 
                          xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'SHIP_TO_ORGANIZATION_ID'
                                        ,lt_child_curr(i).attribute2
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                        END;
                    END;
                                          
                     -- Validating for Organization ID.
                     BEGIN
                      lc_error_loc   := 'Validating for Organization ID';
                      lc_error_debug := 'Organization ID :' || lt_child_curr(i).attribute1;
                                        
                        -- calling the function for organization_id      
                        BEGIN
                          ln_organization_id := xx_gi_comn_utils_pkg.get_ebs_organization_id
                                             (lt_child_curr(i).attribute1);
                       EXCEPTION
                         WHEN OTHERS THEN
                         lc_error_flag_val := 'Y';
                         lc_error_message  :=  'The Organization ID :'|| lt_child_curr(i).attribute2 
                                               || 'is not defined in Oracle EBS System';
                                                                                                 
                         xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'ORGANIZATION_ID'
                                        ,lt_child_curr(i).attribute2
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                        END;
                     END;
                            
                     -- Validating for Currency Code.
                                                                  
                     BEGIN
                      lc_error_loc   := 'Validating for Currency Code';
                      lc_error_debug := 'Currency Code :' || lt_child_curr(i).currency_code ;
                                                                                      
                       SELECT currency_code
                            ,'User'
                       INTO  lc_currency_code
                           ,lc_currency_conversion_type
                      FROM  fnd_currencies
                      WHERE UPPER (issuing_territory_code) = UPPER (lt_child_curr(i).currency_code)
                      AND   enabled_flag = 'Y';
                   EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                    lc_error_flag_val := 'Y';
                    lc_error_message  :=  'The Currency Code :' || lt_child_curr(i).currency_code 
                                         || 'is not defined in Oracle EBS System';
                                                                                                         
                    xx_com_conv_elements_pkg.log_exceptions_proc(
                                      ln_conversion_id
                                     ,ln_control_id
                                     ,lc_source_system_code
                                     ,'XX_GI_RCV_CONV_PKG'
                                     ,'XX_GI_CONV_CHD'
                                     ,'XX_GI_RCV_STG'
                                     ,'CURRENCY_CODE'
                                     ,lt_child_curr(i).currency_code
                                     ,lt_child_curr(i).source_system_ref
                                     ,p_batch_id
                                     ,lc_error_message
                                     ,SQLCODE
                                     ,SQLERRM);
                                                                            
                    WHEN OTHERS THEN
                      lc_error_flag_val := 'Y';
                      lc_error_message  :=  'The Currency Code :'|| lt_child_curr(i).currency_code 
                                           || 'is not defined in Oracle EBS System';
                                                                                                 
                       xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'CURRENCY_CODE'
                                        ,lt_child_curr(i).currency_code
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                   END;
                                              
                   -- Validating for Inventory Item ID.
                                                                  
                  BEGIN
                   lc_error_loc   := 'Validating for Inventory Item ID';
                   lc_error_debug := 'Inventory Item ID :' || lt_child_curr(i).attribute3 ;
                                 
                     -- calling the function for Inventory Item ID                                         
                     BEGIN
                       ln_item_id := xx_gi_comn_utils_pkg.get_inventory_item_id
                                   (lt_child_curr(i).attribute3, ln_organization_id);
                     END;            
                                    
                      SELECT primary_uom_code
                      INTO   lc_primary_uom_code
                      FROM   mtl_system_items_b
                      WHERE  organization_id   = ln_organization_id
                      AND    inventory_item_id = ln_item_id;
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                      lc_error_flag_val := 'Y';
                      lc_error_message :=  'The Inventory Item ID :' || lt_child_curr(i).attribute3 
                                           || 'is not defined in Oracle EBS System';
                                                                                                         
                      xx_com_conv_elements_pkg.log_exceptions_proc(
                                        ln_conversion_id
                                       ,ln_control_id
                                       ,lc_source_system_code
                                       ,'XX_GI_RCV_CONV_PKG'
                                       ,'XX_GI_CONV_CHD'
                                       ,'XX_GI_RCV_STG'
                                       ,'INVENTORY_ITEM_ID'
                                       ,lt_child_curr(i).attribute3
                                       ,lt_child_curr(i).source_system_ref
                                       ,p_batch_id
                                       ,lc_error_message
                                       ,SQLCODE
                                       ,SQLERRM);
                                                                            
                     WHEN OTHERS THEN
                       lc_error_flag_val := 'Y';
                       lc_error_message :=  'The Inventory Item ID :'|| lt_child_curr(i).attribute3 
                                           || 'is not defined in Oracle EBS System';
                                                                                                 
                        xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'INVENTORY_ITEM_ID'
                                        ,lt_child_curr(i).attribute3
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                  END;
                                                                 
                  -- Validating for Transaction Type ID.
                                                                  
                  BEGIN
                    lc_error_loc := 'Validating for Transaction Type ID';
                    lc_error_debug := 'Transaction Type ID :' || lt_child_curr(i).transaction_type_id;
                                 
                     -- calling the function for  Transaction Type ID
                    BEGIN
                     ln_transaction_Intr_type_id := xx_gi_comn_utils_pkg.get_gi_trx_type_id
                                               (substr(lt_child_curr(i).attribute4,1,4)
                                        , substr(lt_child_curr(i).attribute4,9,2), 'Intransit');
                    END;  
                  EXCEPTION
                    WHEN OTHERS THEN
                     lc_error_flag_val := 'Y';
                     lc_error_message :=  'The Transaction Type ID :'|| lt_child_curr(i).transaction_type_id
                                         || 'is not defined in Oracle EBS System';
                                                                                                 
                     xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'TRANSACTION_TYPE_ID'
                                        ,lt_child_curr(i).transaction_type_id
                                        ,lt_child_curr(i).source_system_ref
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
                  END;
                                       
                   -- Updating the Process Flag to 3 for Interface Staging Table
                                               
                       IF (lc_error_flag_val = 'Y') THEN
                         UPDATE xx_gi_rcv_stg
                         SET    process_flag = '3'
                         WHERE  ROWID = lt_child_curr(i).ROWID;
                                                                 
                         COMMIT;
                       --Counting No: Validation failed records
                         ln_failed_val_count := ln_failed_val_count + 1;
                                                          
                       END IF; 
                                                                              
                  IF (p_validate_only_flag = 'N' 
                           AND lc_error_flag_val = 'N' ) THEN
                                                                      
                      lc_error_loc   := 'Inserting into MTL_TRANSACTIONS_INTERFACE';
                      lc_error_debug := 'Source Header ID: '||lt_child_curr(i).source_header_id;
                                                                                
                        --Insert into MTL_TRANSACTIONS_INTERFACE
                                                            
                       SELECT xx_gi_transaction_int_s.NEXTVAL
                       INTO   ln_trx_nex_id
                       FROM   sys.dual;
                                               
                       UPDATE xx_gi_rcv_stg
                       SET    transaction_interface_id =  ln_tran_nex_id
                       WHERE ROWID = lt_child_curr(i).ROWID;
                                          
                        INSERT INTO MTL_TRANSACTIONS_INTERFACE(
                         transaction_interface_id
                        ,source_code
                        ,source_header_id
                        ,source_line_id
                        ,process_flag
                        ,transaction_mode
                        ,last_update_date
                        ,last_updated_by 
                        ,last_update_login 
                        ,creation_date 
                        ,created_by 
                        ,organization_id
                        ,transaction_quantity
                        ,transaction_uom
                        ,transaction_date
                        ,transaction_type_id
                        ,inventory_item_id
                        ,subinventory_code
                        ,transfer_subinventory
                        ,transfer_organization
                        ,transaction_reference
                        ,transfer_cost
                        ,currency_code
                        ,currency_conversion_type
                        ,currency_conversion_rate
                        ,currency_conversion_date
                        ,shipment_number
                        ,attribute1
                        ,attribute2
                        ,attribute3
                        ,attribute4
                        ,attribute5
                        ,attribute6
                        ,attribute7
                        ,attribute8
                        ,attribute9
                        ,attribute10
                        ,attribute11
                        ,attribute12
                        ,attribute13
                        ,attribute14
                        ,attribute15
                        )
                        Values
                        (
                         ln_trx_nex_id                   --transaction_interface_id
                        ,'SIV Inter Org Receipts'       --source_code
                        ,lt_child_curr(i).batch_id       --source_header_id
                        ,ln_conversion_id                --source_line_id
                        , 1                              --process_flag 
                        , 3                              --transaction_mode
                        ,lt_child_curr(i).last_update_date   --last_update_date ,
                        ,fnd_global.user_id                --last_updated_by ,
                        ,fnd_global.login_id               --last_update_login ,
                        ,lt_child_curr(i).creation_date   --creation_date ,
                        ,fnd_global.user_id               --created_by ,
                        ,ln_organization_id               --organization_id
                        ,'-'||lt_child_curr(i).quantity   --transaction_quantity
                        ,lc_primary_uom_code               --transaction_uom
                        ,lt_child_curr(i).creation_date    --transaction_date
                        ,ln_transaction_Intr_type_id       --transaction_type_id
                        ,ln_item_id                        --inventory_item_id
                        ,'STOCK'                           --subinventory_code
                        ,'STOCK'                           --transfer_subinventory
                        ,lc_ship_to_organization_id        --transfer_organization
                        ,lt_child_curr(i).transaction_reference --transaction_reference,
                        ,lt_child_curr(i).transfer_cost         --transfer_cost
                        ,lc_currency_code                     --currency_code
                        ,lc_currency_conversion_type           --currency_conversion_type
                        ,lt_child_curr(i).currency_conversion_rate--currency_conversion_rate
                        ,sysdate                                  --currency_conversion_date
                        ,lt_child_curr(i).attribute5               --shipment_number
                        ,lt_child_curr(i).attribute1   --attribute1,
                        ,lt_child_curr(i).attribute2   --attribute2,
                        ,lt_child_curr(i).attribute3   --attribute3,
                        ,lt_child_curr(i).attribute4   --attribute4,
                        ,lt_child_curr(i).attribute5   --attribute5,
                        ,lt_child_curr(i).attribute6   --attribute6,
                        ,lt_child_curr(i).attribute7   --attribute7,
                        ,lt_child_curr(i).attribute8   --attribute8,
                        ,lt_child_curr(i).attribute9   --attribute9,
                        ,lt_child_curr(i).attribute10   --attribute10,
                        ,lt_child_curr(i).attribute11   --attribute11,
                        ,lt_child_curr(i).attribute12   --attribute12,
                        ,lt_child_curr(i).attribute13   --attribute13,
                        ,lt_child_curr(i).attribute14   --attribute14,
                        ,lt_child_curr(i).ROWID);    --attribute15
                  END IF;                                           
                                      
                     --Counting No: of Failed and Processed records
                     --Checking the Error flag
                     IF (lc_error_flag_proc = 'Y') THEN
                       ROLLBACK;
                       lc_error_loc := 'Updating the Process flag = 6';
                       lc_error_debug := 'Transaction Interface Id: '|| ln_trx_nex_id ;
                                      
                         UPDATE xx_gi_rcv_stg
                         SET    process_flag = '6'
                         WHERE  ROWID = lt_child_curr(i).ROWID;
                                                           
                      --Counting No: Processing failed records
                       ln_failed_proc_count :=  ln_failed_proc_count + 1;
                      END IF;
                                                                  
            END IF; -- Validation of Receipt Source Code End...            
            COMMIT;
      END LOOP;-- Cursor lcu_child_curr Ends
                                                       
         -- fnd_request.submit_request for RECEIVING TRANSACTION PROCESSOR
                               
            lc_error_loc := 'Submit the RECEIVING TRANSACTION PROCESSOR';
            lc_error_debug := '';
                                                     
            ln_conc_request_id := fnd_request.submit_request (
                                             'PO'
                                            ,'RVCTP'
                                            ,NULL
                                            ,NULL
                                            ,NULL
                                            ,'BATCH'
                                            ,'');
             COMMIT;
             fnd_file.put_line(fnd_file.log,'RECEIVING TRANSACTION PROCESSOR Program Request id: '
                                              ||ln_conc_request_id);
                                                                               
           --Printing the Log details for each batch
           lc_error_loc := 'Wait till the RECEIVING TRANSACTION PROCESSOR';
            lc_error_debug := 'Concurrent Request id: '||ln_conc_request_id;
                                                                       
           --Wait till the completion of RECEIVING TRANSACTION PROCESSOR
            lc_req_status := fnd_concurrent.wait_for_request(ln_conc_request_id
                                                           ,'30'
                                                           ,''
                                                           ,lc_phase 
                                                           ,lc_status
                                                           ,lc_devphase
                                                           ,lc_devstatus
                                                           ,lc_message); 
                                                                      
        --Updating the Process Flag = '6', if the transactions are Rejected by RECEIVING TRANSACTION PROCESSOR
          UPDATE xx_gi_rcv_stg 
          SET    process_flag = '6'
          WHERE  interface_transaction_id IN (SELECT interface_transaction_id
                                            FROM rcv_transactions_interface 
                                            WHERE processing_status_code = 'ERROR')
          AND    batch_id = p_batch_id
          AND    receipt_source_code = 'VENDOR';
                                                        
        --Updating the Process Flag = '7', if the transactions are Success by RECEIVING TRANSACTION PROCESSOR
          UPDATE xx_gi_rcv_stg 
          SET    process_flag = '7'
          WHERE  interface_transaction_id NOT IN (SELECT interface_transaction_id
                                            FROM rcv_transactions_interface 
                                            WHERE processing_status_code = 'ERROR')
          AND    process_flag <> 3
          AND    receipt_source_code = 'VENDOR';
                            
         -- fnd_request.submit_request for "PROCESS TRANSACTIONS INTERFACE"                
                                            
            lc_error_loc := 'PROCESS TRANSACTIONS INTERFACE';
            lc_error_debug := '';
                                                          
            ln_conc_request_id := fnd_request.submit_request (
                                             'INV'
                                            ,'INCTCM'
                                            ,NULL
                                            ,NULL
                                            ,NULL);
          COMMIT;
           fnd_file.put_line(fnd_file.log,'PROCESS TRANSACTIONS INTERFACE Program Request id: '
                                              ||ln_conc_request_id);
                                                                               
            --Printing the Log details for each batch
            lc_error_loc := 'Wait till the PROCESS TRANSACTIONS INTERFACE';
            lc_error_debug := 'Concurrent Request id: '||ln_conc_request_id;
                                                                       
	    --Wait till the completion of PROCESS TRANSACTIONS INTERFACE
            lc_req_status := fnd_concurrent.wait_for_request(ln_conc_request_id
                                                           ,'30'
                                                           ,''
                                                           ,lc_phase 
                                                           ,lc_status
                                                           ,lc_devphase
                                                           ,lc_devstatus
                                                           ,lc_message);
                                                                 
        --Updating the Process Flag = '6', if the transactions are rejected by PROCESS TRANSACTIONS INTERFACE
                                                           
            UPDATE xx_gi_rcv_stg 
            SET    process_flag = '6'
            WHERE  ROWID IN (SELECT attribute15
                               FROM mtl_transactions_interface)
            AND    batch_id = p_batch_id
            AND    process_flag = '2';
                                         
                                                           
        --Updating the Process Flag = '7', if the transactions are Success by PROCESS TRANSACTIONS INTERFACE 
          UPDATE xx_gi_rcv_stg 
          SET    process_flag = '7'
          WHERE  ROWID NOT IN (SELECT attribute15
                               FROM mtl_transactions_interface)
          AND  process_flag <> '3'
          AND  receipt_source_code = 'RTV';
                     
          UPDATE xx_gi_rcv_stg 
          SET    process_flag = '10'
          WHERE  batch_id = p_batch_id
          AND    ROWID NOT IN (SELECT attribute15
                               FROM mtl_transactions_interface)
          AND    process_flag <> 3
          AND    receipt_source_code = 'INVENTORY';
          COMMIT;     
                                    
     -- Second Cursor starting point            
    BEGIN
       OPEN lcu_expected_curr;
         FETCH lcu_expected_curr BULK COLLECT INTO lt_exp_curr;
          FOR i IN 1..lt_exp_curr.COUNT
          LOOP     
                                     
           -- Validating for Ship to Organization Code.
                                                                  
          BEGIN
            lc_error_loc   := 'Validating for Ship to Organization Code';
            lc_error_debug := 'Ship to Organization Code :' || lt_exp_curr(i).ship_to_org_id;
                                                                                      
            SELECT organization_code
            INTO   lc_organization_code
            FROM   org_organization_definitions
            WHERE  organization_id = lt_exp_curr(i).ship_to_org_id;
                                                                                                                                                       
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lc_error_flag_val := 'Y';
              lc_error_message :=  'The Ship to Organization Code :' || lc_organization_code
                                 || 'is not defined in Oracle EBS System';
                                                                                                         
              xx_com_conv_elements_pkg.log_exceptions_proc(
                                       ln_conversion_id
                                      ,ln_control_id
                                      ,lc_source_system_code
                                      ,'XX_GI_RCV_CONV_PKG'
                                      ,'XX_GI_CONV_CHD'
                                      ,'XX_GI_RCV_STG'
                                      ,'ORGANIZATION_CODE'
                                      ,lc_organization_code
                                      ,''
                                      ,p_batch_id
                                      ,lc_error_message
                                      ,SQLCODE
                                      ,SQLERRM);
                                                                            
            WHEN OTHERS THEN
              lc_error_flag_val := 'Y';
              lc_error_message  :=  'The Ship to Organization Code :'|| lc_organization_code
                                  || 'is not defined in Oracle EBS System';
                                                                                                 
              xx_com_conv_elements_pkg.log_exceptions_proc(
                                         ln_conversion_id
                                        ,ln_control_id
                                        ,lc_source_system_code
                                        ,'XX_GI_RCV_CONV_PKG'
                                        ,'XX_GI_CONV_CHD'
                                        ,'XX_GI_RCV_STG'
                                        ,'ORGANIZATION_CODE'
                                        ,lc_organization_code
                                        ,''
                                        ,p_batch_id
                                        ,lc_error_message || ' at ' ||lc_error_loc ||lc_error_debug
                                        ,SQLCODE
                                        ,SQLERRM);
          END;                         
                                        
                   -- Updating the Process Flag to 3 for Interface Staging Table
                                               
                       IF (lc_error_flag_val = 'Y') THEN
                         UPDATE xx_gi_rcv_stg
                         SET    process_flag = '3'
                         WHERE  ROWID = lt_exp_curr(i).ROWID;
                                                                 
                         COMMIT;
                       --Counting No: Validation failed records
                         ln_failed_val_count := ln_failed_val_count + 1;
                                                          
                       END IF; 
                                   
            IF (p_validate_only_flag = 'N' 
                       AND lc_error_flag_val = 'N' ) THEN
                                                                      
               lc_error_loc   := 'Inserting into RCV_HEADERS_INTERFACE';
               lc_error_debug := 'Header Interface ID: '||ln_head_nex_id;
                                              
             IF  lt_exp_curr(i).attribute8 <> lc_pri_key THEN
                                                           
                 SELECT rcv_headers_interface_s.NEXTVAL
                 INTO   ln_head_nex_id
                 FROM   sys.dual;
                                 
                 SELECT rcv_interface_groups_s.NEXTVAL
                 INTO   ln_grp_nex_id
                 FROM   sys.dual;
                             
                 UPDATE xx_gi_rcv_stg
                 SET    header_interface_id = ln_head_nex_id
                 WHERE ROWID = lt_child_curr(i).ROWID;
                                                       
                --Insert into RCV_HEADERS_INTERFACE
                INSERT INTO RCV_HEADERS_INTERFACE(
                 header_interface_id  
                ,group_id 
                ,processing_status_code 
                ,receipt_source_code 
                ,transaction_type 
                ,last_update_date 
                ,last_updated_by 
                ,last_update_login 
                ,creation_date 
                ,created_by 
                ,shipment_num 
                ,shipped_date 
                ,validation_flag 
                ,ship_to_organization_code 
                ,auto_transact_code
                ,expected_receipt_date
                ,receipt_num
                ,attribute1
                ,attribute2
                ,attribute3
                ,attribute4
                ,attribute5
                ,attribute6
                ,attribute7
                ,attribute8
                ,attribute9
                ,attribute10
                ,attribute11
                ,attribute12
                ,attribute13
                ,attribute14
                ,attribute15
                )
                VALUES
                ( 
                 ln_head_nex_id   			--header_interface_id , 
                ,ln_grp_nex_id   			--group_id ,
                ,'PENDING'   				--processing_status_code ,
                ,lt_exp_curr(i).receipt_source_code   	--receipt_source_code ,
                ,'NEW'   				--transaction_type ,
                ,lt_exp_curr(i).last_update_date   	--last_update_date ,
                ,fnd_global.user_id   			--last_updated_by ,
                ,fnd_global.login_id   			--last_update_login ,
                ,lt_exp_curr(i).creation_date 	  	--creation_date ,
                ,fnd_global.user_id   			--created_by ,
                ,lt_exp_curr(i).attribute5  		--shipment_num ,
                ,lt_exp_curr(i).last_update_date   	--shipped_date ,
                ,'N'   					--validation_flag ,
                ,lc_organization_code   		--ship_to_organization_code ,
                ,'DELIVER'   				--auto_transact_code,
                ,lt_exp_curr(i).last_update_date   	--expected_receipt_date,
                ,xx_gi_receipt_num_us_s.NEXTVAL   	--receipt_num,
                ,lt_exp_curr(i).attribute1   		--attribute1,
                ,lt_exp_curr(i).attribute2   		--attribute2,
                ,lt_exp_curr(i).attribute3   		--attribute3,
                ,lt_exp_curr(i).attribute4   		--attribute4,
                ,lt_exp_curr(i).attribute5   		--attribute5,
                ,lt_exp_curr(i).attribute6   		--attribute6,
                ,lt_exp_curr(i).attribute7   		--attribute7,
                ,lt_exp_curr(i).attribute8   		--attribute8,
                ,lt_exp_curr(i).attribute9   		--attribute9,
                ,lt_exp_curr(i).attribute10   		--attribute10,
                ,lt_exp_curr(i).attribute11   		--attribute11,
                ,lt_exp_curr(i).attribute12   		--attribute12,
                ,lt_exp_curr(i).attribute13   		--attribute13,
                ,lt_exp_curr(i).attribute14   		--attribute14,
                ,lt_exp_curr(i).attribute15    		--attribute15
                 );
                                                
                  lc_pri_key := lt_exp_curr(i).attribute8;
                                          
             END IF;
                                                   
                 SELECT rcv_transactions_interface_s.NEXTVAL
                 INTO   ln_tran_nex_id
                 FROM   sys.dual;
                                        
                 UPDATE xx_gi_rcv_stg
                 SET    interface_transaction_id =  ln_tran_nex_id
                 WHERE ROWID = lt_child_curr(i).ROWID;
                                                      
                 INSERT INTO RCV_TRANSACTIONS_INTERFACE(
                   interface_transaction_id 
                  ,header_interface_id 
                  ,group_id 
                  ,last_update_date 
                  ,last_updated_by 
                  ,last_update_login 
                  ,creation_date 
                  ,created_by 
                  ,transaction_type 
                  ,transaction_date 
                  ,processing_status_code 
                  ,processing_mode_code 
                  ,transaction_status_code 
                  ,quantity 
                  ,unit_of_measure 
                  ,receipt_source_code 
                  ,source_document_code
                  ,destination_type_code
                  ,shipment_header_id
                  ,shipment_line_id
                  ,validation_flag
                  ,auto_transact_code
                  ,subinventory
                  ,currency_code
                  ,currency_conversion_type
                  ,currency_conversion_rate
                  ,currency_conversion_date
                  ,to_organization_id
                  ,attribute1
                  ,attribute2
                  ,attribute3
                  ,attribute4
                  ,attribute5
                  ,attribute6
                  ,attribute7
                  ,attribute8
                  ,attribute9
                  ,attribute10
                  ,attribute11
                  ,attribute12
                  ,attribute13
                  ,attribute14
                  ,attribute15
                  ) 
                  SELECT
                   ln_tran_nex_id   				--interface_transaction_id ,
                  ,ln_head_nex_id   				--header_interface_id ,
                  ,ln_grp_nex_id   				--group_id ,
                  ,lt_exp_curr(i).last_update_date   		--last_update_date ,
                  ,fnd_global.user_id   			--last_updated_by ,
                  ,fnd_global.login_id   			--last_update_login ,
                  ,lt_exp_curr(i).creation_date  	 	--creation_date ,
                  ,fnd_global.user_id   			--created_by ,
                  ,'RECEIVE'    				--transaction_type ,
                  ,sysdate   					--transaction_date ,
                  ,'PENDING'   					--processing_status_code ,
                  ,'BATCH'   					--processing_mode_code ,
                  ,'PENDING'   					--transaction_status_code ,
                  ,lt_exp_curr(i).quantity   			--quantity ,
                  ,lt_exp_curr(i).unit_of_measure   		--unit_of_measure ,
                  ,lt_exp_curr(i).receipt_source_code   	--receipt_source_code ,
                  ,'INVENTORY'   				--source_document_code ,
                  ,'INVENTORY'                                  -- destination_type_code
                  ,lt_exp_curr(i).shipment_header_id   		--shipment_header_id,
                  ,lt_exp_curr(i).shipment_line_id   		--shipment_line_id,
                  ,'N'   					--validation_flag,
                  ,'DELIVER'   					--auto_transact_code,
                  ,'STOCK'   					--subinventory,
                  ,lt_exp_curr(i).currency_code			--currency_code
                  ,lt_exp_curr(i).conversion_rate_type		--currency_conversion_type
                  ,lt_exp_curr(i).conversion_rate		--currency_conversion_rate
                  ,lt_exp_curr(i).conversion_date		--currency_conversion_date
                  ,lt_exp_curr(i).ship_to_org_id		--to_organization_id
                  ,lt_exp_curr(i).attribute1   			--attribute1,
                  ,lt_exp_curr(i).attribute2   			--attribute2,
                  ,lt_exp_curr(i).attribute3   			--attribute3,
                  ,lt_exp_curr(i).attribute4   			--attribute4,
                  ,lt_exp_curr(i).attribute5   			--attribute5,
                  ,lt_exp_curr(i).attribute6   			--attribute6,
                  ,lt_exp_curr(i).attribute7   			--attribute7,
                  ,lt_exp_curr(i).attribute8   			--attribute8,
                  ,lt_exp_curr(i).attribute9   			--attribute9,
                  ,lt_exp_curr(i).attribute10   		--attribute10,
                  ,lt_exp_curr(i).attribute11   		--attribute11,
                  ,lt_exp_curr(i).attribute12   		--attribute12,
                  ,lt_exp_curr(i).attribute13   		--attribute13,
                  ,lt_exp_curr(i).attribute14   		--attribute14,
                  ,lt_exp_curr(i).attribute15    		--attribute15
                   FROM sys.dual;
            END IF;
                                      
                     --Counting No: of Failed and Processed records
                     --Checking the Error flag
                     IF (lc_error_flag_proc = 'Y') THEN
                       ROLLBACK;
                       lc_error_loc := 'Updating the Process flag = 6';
                       lc_error_debug := 'Transaction Interface Id: '|| ln_trx_nex_id ;
                                      
                         UPDATE xx_gi_rcv_stg
                         SET    process_flag = '6'
                         WHERE  ROWID = lt_exp_curr(i).ROWID;
                                                           
                      --Counting No: Processing failed records
                       ln_failed_proc_count :=  ln_failed_proc_count + 1;
                      END IF;
                                                                  
       END LOOP; -- Second Cursor ending point
    END;             
                                                       
         -- fnd_request.submit_request for RECEIVING TRANSACTION PROCESSOR
                               
            ln_conc_request_id := fnd_request.submit_request(
                                            'PO'
                                            ,'RVCTP'
                                            ,NULL
                                            ,NULL
                                            ,NULL
                                            ,'BATCH'
                                            ,'');
           COMMIT;
           fnd_file.put_line(fnd_file.log,'RECEIVING TRANSACTION PROCESSOR Program Request id: '
                                              ||ln_conc_request_id);
                                                                               
            --Printing the Log details for each batch
            lc_error_loc := 'Wait till the RECEIVING TRANSACTION PROCESSOR';
            lc_error_debug := 'Concurrent Request id: '||ln_conc_request_id;
                                                                       
	    --Wait till the completion of RECEIVING TRANSACTION PROCESSOR
            lc_req_status := fnd_concurrent.wait_for_request(ln_conc_request_id
                                                           ,'30'
                                                           ,''
                                                           ,lc_phase 
                                                           ,lc_status
                                                           ,lc_devphase
                                                           ,lc_devstatus
                                                           ,lc_message);             
        --To get all the Rejected records from the RECEIVING TRANSACTION PROCESSOR'
        lc_error_loc := 'Updating the Process Flag = 6, if Rejected by RECEIVING TRANSACTION PROCESSOR';
        lc_error_debug := 'Batch id: '||p_batch_id;
                                                                    
        --Updating the Process Flag = '9', if the transactions are Rejected by RECEIVING TRANSACTION PROCESSOR
                                                  
        UPDATE xx_gi_rcv_stg 
        SET    process_flag = '9'
        WHERE  interface_transaction_id IN (SELECT interface_transaction_id
                                            FROM rcv_transactions_interface 
                                            WHERE processing_status_code = 'ERROR'
                                            OR transaction_status_code = 'ERROR')
        AND    batch_id = p_batch_id
        AND    interface_transaction_id IN (SELECT interface_line_id
                                            FROM po_interface_errors)
        AND    process_flag = '10';
                                                                         
        --Updating the Process Flag = '7', if the transactions are Success by RECEIVING TRANSACTION PROCESSOR                                                       
        UPDATE xx_gi_rcv_stg 
        SET    process_flag = '7'
        WHERE  interface_transaction_id NOT IN (SELECT interface_transaction_id
                                            FROM rcv_transactions_interface 
                                            WHERE processing_status_code = 'ERROR'
                                            OR transaction_status_code = 'ERROR')
        AND    process_flag <> 8
        AND    interface_transaction_id NOT IN (SELECT interface_line_id
                                            FROM po_interface_errors)
        AND    receipt_source_code = 'INVENTORY';
                                                                              
             --Counting No: of Sucessfully processed records
             ln_success_count := ln_tot_batch_count - ln_failed_val_count - ln_failed_proc_count;
                                                                    
           --Updating Control information
             lc_error_loc := 'Updating Control information';
             lc_error_debug := 'Updating Control information';
               BEGIN
                 xx_com_conv_elements_pkg.upd_control_info_proc(ln_par_conc_request_id
                                                      ,p_batch_id
                                                      ,ln_conversion_id
                                                      ,ln_failed_val_count
                                                      ,ln_failed_proc_count
                                                      ,ln_success_count);
              EXCEPTION
                 WHEN OTHERS THEN
                 fnd_file.put_line (fnd_file.LOG, 'Error in Submitting the Updation control info Proc');
             END;                                                   
                                                                         
             --Printing the Summary info on the log file
               fnd_file.put_line(fnd_file.log,'Total No. of Records: '
                                    ||(ln_success_count+ln_failed_val_count+ln_failed_proc_count));
               fnd_file.put_line(fnd_file.log,'No. of Sucessfully Processed Records: '||ln_success_count);
               fnd_file.put_line(fnd_file.log,'No. of Validation Failed Records: '||ln_failed_val_count);
               fnd_file.put_line(fnd_file.log,'No. of Processing Failed Records: '||ln_failed_proc_count);
        COMMIT;     
  END xx_gi_conv_chd;
  END XX_CNV_GI_RCV_PKG;
/
SHOW ERROR
/
