SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_GI_CON_DECON_LOAD_PKG
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization              |
-- +==========================================================================+
-- | Name        :  XX_GI_CON_DECON_LOAD_PKG.pkb                              |
-- | Description :  This package is used for Consignment Conversion and       |
-- |                Deconversion.                                             |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date        Author           Remarks                            |
-- |=======   ==========  =============    ===================================|
-- |Draft 1a  27-Sep-2007 Madhukar Salunke Initial draft version              |
-- |Draft 1b  08-Oct-2007 Madhukar Salunke Incorporated Peer Review Comments  |
-- |Draft 1c  24-Oct-2007 Siddharth Singh  Modified for Item Based Processing |
-- |Draft 1d  30-Oct-2007 Siddharth Singh  Added STATUS_CODE to CURSOR        |
-- |                                       lcu_get_parameters.                |
-- +==========================================================================+
IS

-------------------------------------------------
-- To display successful records in Output layout
-------------------------------------------------
TYPE log_rec_type IS RECORD
    ( xccp_rec             XX_ITM_CONSIGN_CONV_PARMS%ROWTYPE
     ,change_type          XX_GI_CONSIGN_CHANGES.change_type%TYPE
     ,sku                  MTL_SYSTEM_ITEMS_B.segment1%TYPE
     ,country              VARCHAR2(30)
     ,consign_supplier     VARCHAR2(30)
     ,buy_back_supplier    VARCHAR2(30)
     ,print_flag           VARCHAR2(1)
     ,action_type          VARCHAR2(1)
    );

----------------------------------------------
--Table to hold successfully processed records
----------------------------------------------
TYPE log_rec_tbl_type IS TABLE OF log_rec_type INDEX BY BINARY_INTEGER;
gt_log_rec_tab      log_rec_tbl_type;

---------------------------------------------
-- To display failed records in Output layout
---------------------------------------------
TYPE lr_failed_rec_type IS RECORD
    ( xccp_rec           xx_itm_consign_conv_parms%ROWTYPE
    );

----------------------------------------------
--Table to hold failed records
----------------------------------------------
TYPE fail_rec_tbl_type IS TABLE OF lr_failed_rec_type INDEX BY BINARY_INTEGER;
gt_fail_rec_tab      fail_rec_tbl_type;

gn_processed           PLS_INTEGER       := 0;    -- To hold no of records processed from the parameter table.
gn_rec_inserted        PLS_INTEGER       := 0;
gn_rec_updated         PLS_INTEGER       := 0;
gn_bypassed            PLS_INTEGER       := 0;
gn_failed_records      PLS_INTEGER       := 0;     -- To hold number of failed records.

-- +=========================================================================+
-- | Name        :  display_out                                              |
-- | Description :  This procedure is invoked to print in the output         |
-- |                file                                                     |
-- |                                                                         |
-- |In Parameters:  p_message                                                |
-- +=========================================================================+

PROCEDURE display_out(p_message IN VARCHAR2)
IS
BEGIN
    fnd_file.put_line(fnd_file.output,p_message);
END;

-- +=========================================================================+
-- | Name        :  display_log                                              |
-- | Description :  This procedure is invoked to print in the log file       |
-- |                                                                         |
-- |In Parameters:  p_message                                                |
-- +=========================================================================+

PROCEDURE display_log(p_message IN VARCHAR2)
IS
BEGIN
    fnd_file.put_line(fnd_file.log,p_message);
END;


PROCEDURE PRINT_LOG_OUTPUT
-- +===============================================================================+
-- |                                                                               |
-- | Name             : PRINT_LOG_OUTPUT                                           |
-- |                                                                               |
-- | Description      : This procedure prints the record statistics,column headers |
-- |                    ,failed records, and records inserted successfuly into     |
-- |                    XX_GI_CONSIGN_CHANGES table in the program Output          |
-- |                  : Log Footer Section.                                        |
-- +===============================================================================+
IS

lc_col_header          VARCHAR2(3000);
lc_separator           VARCHAR2(3000);
lc_log_record          VARCHAR2(3000);
lc_out_header          VARCHAR2(3000);
lc_out_separator       VARCHAR2(600);
lc_failed_rec          VARCHAR2(3000);

BEGIN
    -------------------------
    --Printing Program Output
    -------------------------
    display_out('============================================================================================================================');
    display_out('Office Depot'||LPAD('Date:',90,' ')||TO_CHAR(SYSDATE,'DD-MON-YY HH24:MI:SS AM'));
    display_out('');
    display_out('                                     Consignment Conversion Capture Statistics                                     ');
    display_out('============================================================================================================================');
    display_out('');
    display_out(RPAD('Program Start Time:',38,' ')||TO_CHAR(SYSDATE,'DD-MON-YY HH24:MI:SS AM'));
    display_out('');
    display_out(RPAD('No of records processed               :',40,' ')||gn_processed);
    display_out(RPAD('No of records inserted successfully   :',40,' ')||gn_rec_inserted);
    display_out(RPAD('No of records updated  successfully   :',40,' ')||gn_rec_updated);
    display_out(RPAD('No of records bypassed (not effective):',40,' ')||gn_bypassed);
    display_out(RPAD('No of records failed                  :',40,' ')||gn_failed_records);
    display_out('');
    
    display_out('                                                   ------------------------------');
    display_out('                                                   RECORDS PROCESSED SUCCESSFULLY');
    display_out('                                                   ------------------------------');


     lc_col_header := NULL;
     lc_col_header := lc_col_header || RPAD('Action',25,' ')             ||CHR(09);
     lc_col_header := lc_col_header || RPAD('SKU',15,' ')                ||CHR(09);
     lc_col_header := lc_col_header || RPAD('Country',15,' ')            ||CHR(09);
     lc_col_header := lc_col_header || RPAD('Consign Supplier',20,' ')   ||CHR(09);
     lc_col_header := lc_col_header || RPAD('Buy Back Supplier',20,' ')  ||CHR(09);
     lc_col_header := lc_col_header || RPAD('Buyback Cost',20,' ')       ||CHR(09);
     lc_col_header := lc_col_header || RPAD('Effective Date',15,' ')     ||CHR(09);
     
     display_out(lc_col_header);
          
     lc_separator := NULL;
     lc_separator := lc_separator || RPAD('------------------------',25,' ') ||CHR(09);
     lc_separator := lc_separator || RPAD('--------------',15,' ')           ||CHR(09);
     lc_separator := lc_separator || RPAD('--------------',15,' ')           ||CHR(09);
     lc_separator := lc_separator || RPAD('-------------------',20,' ')      ||CHR(09);
     lc_separator := lc_separator || RPAD('-------------------',20,' ')      ||CHR(09);
     lc_separator := lc_separator || RPAD('-------------------',20,' ')      ||CHR(09);
     lc_separator := lc_separator || RPAD('--------------',15,' ')           ||CHR(09);
   
     display_out(lc_separator);

             IF (gt_log_rec_tab.COUNT > 0) THEN

                 FOR  ln_log_counter IN gt_log_rec_tab.FIRST .. gt_log_rec_tab.LAST
                 LOOP

                     IF (gt_log_rec_tab(ln_log_counter).print_flag = 'Y') THEN
                         lc_log_record := NULL;
                         lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_log_rec_tab(ln_log_counter).change_type),' '),25,' ' ) ||CHR(09);
                         lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_log_rec_tab(ln_log_counter).sku),' '),15,' ' ) ||CHR(09);
                         lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_log_rec_tab(ln_log_counter).country),' '),15,' ' )          ||CHR(09);
                         lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_log_rec_tab(ln_log_counter).consign_supplier),' '),20, ' ') ||CHR(09);
                         lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_log_rec_tab(ln_log_counter).buy_back_supplier),' '),20,' ')              ||CHR(09);
                         lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_log_rec_tab(ln_log_counter).xccp_rec.buy_back_po_cost),' '),20,' ')              ||CHR(09);
                         lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_log_rec_tab(ln_log_counter).xccp_rec.effective_date),' '),15,' ') ||CHR(09);

                         fnd_file.put_line (fnd_file.output,lc_log_record);
                     END IF;

                 END LOOP;

            END IF; 

    display_out('');
    display_out('');
    display_out('                                                   ---------------------');
    display_out('                                                   FAILED RECORD DETAILS');
    display_out('                                                   ---------------------');
    display_out('');

       --failed record details here

    lc_out_header  := NULL;
    lc_out_header  := lc_out_header || RPAD('INVENTORY_ITEM_ID',17,' ')      ||CHR(09);
    lc_out_header  := lc_out_header || RPAD('ORGANIZATION_ID',15,' ')        ||CHR(09);
    lc_out_header  := lc_out_header || RPAD('EFFECTIVE_DATE',14,' ')         ||CHR(09);
    lc_out_header  := lc_out_header || RPAD('ACTION_FLAG',12,' ')            ||CHR(09);
    lc_out_header  := lc_out_header || RPAD('CONV_SUPPLIER_SITE',18,' ')     ||CHR(09);
    lc_out_header  := lc_out_header || RPAD('BUY_BACK_SUPPLIER_SITE',22,' ') ||CHR(09);
    lc_out_header  := lc_out_header || RPAD('BUY_BACK_PO_COST',16,' ')       ||CHR(09);
    lc_out_header  := lc_out_header || RPAD('PROCESS_DATE',12,' ')           ||CHR(09);
    lc_out_header  := lc_out_header || RPAD('ERROR_MESSAGE',240,' ')         ||CHR(09);    
    display_out(lc_out_header);

    lc_out_separator := NULL;
    lc_out_separator := lc_out_separator || RPAD('----------------',17,' ')      ||CHR(09);
    lc_out_separator := lc_out_separator || RPAD('--------------',15,' ')        ||CHR(09);
    lc_out_separator := lc_out_separator || RPAD('-------------',14,' ')         ||CHR(09);
    lc_out_separator := lc_out_separator || RPAD('---------',10,' ')             ||CHR(09);
    lc_out_separator := lc_out_separator || RPAD('-----------------',18,' ')     ||CHR(09);
    lc_out_separator := lc_out_separator || RPAD('--------------------',22,' ')  ||CHR(09);
    lc_out_separator := lc_out_separator || RPAD('---------------',16,' ')       ||CHR(09);
    lc_out_separator := lc_out_separator || RPAD('-----------',12,' ')           ||CHR(09);
    lc_out_separator := lc_out_separator || RPAD('----------------',240,' ')     ||CHR(09);
    display_out(lc_out_separator);


    IF (gt_fail_rec_tab.COUNT > 0) THEN

        FOR  ln_fail_counter IN gt_fail_rec_tab.FIRST .. gt_fail_rec_tab.LAST
        LOOP

            display_log('Printing Failed records, inventory_item_id = ' || gt_fail_rec_tab(ln_fail_counter).xccp_rec.inventory_item_id);
            --Printing Failed record details here
            lc_failed_rec := NULL;
            lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_fail_rec_tab(ln_fail_counter).xccp_rec.inventory_item_id),' '),17,' ')      || CHR(09);
            lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_fail_rec_tab(ln_fail_counter).xccp_rec.organization_id),' '),15,' ')        || CHR(09);
            lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_fail_rec_tab(ln_fail_counter).xccp_rec.effective_date),' '),14,' ')         || CHR(09);
            lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_fail_rec_tab(ln_fail_counter).xccp_rec.action_flag),' '),10,' ')            || CHR(09);
            lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_fail_rec_tab(ln_fail_counter).xccp_rec.conv_supplier_site),' '),18,' ')     || CHR(09);
            lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_fail_rec_tab(ln_fail_counter).xccp_rec.buy_back_supplier_site),' '),22,' ') || CHR(09);
            lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_fail_rec_tab(ln_fail_counter).xccp_rec.buy_back_po_cost),' '),16,' ')       || CHR(09);
            lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_fail_rec_tab(ln_fail_counter).xccp_rec.process_date),' '),12,' ')           || CHR(09);
            lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_fail_rec_tab(ln_fail_counter).xccp_rec.error_message),' '),240,' ')         || CHR(09);
            display_out(lc_failed_rec);

            IF (gt_log_rec_tab.COUNT > 0) THEN
                --Loop to print rolled back records from success table
                FOR ln_log_counter IN gt_log_rec_tab.FIRST .. gt_log_rec_tab.LAST
                LOOP

                    IF(gt_fail_rec_tab(ln_fail_counter).xccp_rec.inventory_item_id 
                       = gt_log_rec_tab(ln_log_counter).xccp_rec.inventory_item_id
                    AND gt_log_rec_tab(ln_log_counter).print_flag = 'N')THEN

                        display_log('Printing Rolled Back records from Success Table');
                        gt_log_rec_tab(ln_log_counter).xccp_rec.error_message := 'Exception was raised for the same Item previously.';
                        lc_failed_rec := NULL;
                        lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_log_rec_tab(ln_log_counter).xccp_rec.inventory_item_id),' '),17,' ')       || CHR(09);
                        lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_log_rec_tab(ln_log_counter).xccp_rec.organization_id),' '),15,' ')         || CHR(09);
                        lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_log_rec_tab(ln_log_counter).xccp_rec.effective_date),' '),14,' ')          || CHR(09);
                        lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_log_rec_tab(ln_log_counter).xccp_rec.action_flag),' '),10,' ')             || CHR(09);
                        lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_log_rec_tab(ln_log_counter).xccp_rec.conv_supplier_site),' '),18,' ')      || CHR(09);
                        lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_log_rec_tab(ln_log_counter).xccp_rec.buy_back_supplier_site),' '),22,' ')  || CHR(09);
                        lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_log_rec_tab(ln_log_counter).xccp_rec.buy_back_po_cost),' '),16,' ')        || CHR(09);
                        lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_log_rec_tab(ln_log_counter).xccp_rec.process_date),' '),12,' ')            || CHR(09);
                        lc_failed_rec := lc_failed_rec || RPAD(NVL(TO_CHAR(gt_log_rec_tab(ln_log_counter).xccp_rec.error_message),' '),240,' ')          || CHR(09);

                        display_out(lc_failed_rec);

                        gt_log_rec_tab(ln_log_counter).print_flag := 'X';


                    END IF;

                END LOOP;
                --Loop to print rolled back records from success table ends
            END IF;

        END LOOP;
    END IF;
    
    display_out('');
    display_out('============================================================================================================================');
    display_out('                             *** End of Report - Consignment Conversion Capture Statistics  ***                             ');
    display_out('');
    display_out(RPAD('Program End Time:',38,' ')||TO_CHAR(SYSDATE,'DD-MON-YY HH24:MI:SS AM'));


    --Printing Program Log Footer
    display_log('');
    display_log('============================================================================================================================');
    display_log('                               *** End of Report - Consignment Conversion Capture Summary  ***                              ');

END PRINT_LOG_OUTPUT;


-- +=========================================================================+
-- | Name        :  insert_data                                              |
-- | Description :  This procedure is to insert records in consign changes table|
-- |                                                                         |
-- +=========================================================================+

PROCEDURE insert_data( p_change_type             VARCHAR2
                      ,p_effective_date          DATE       
                      ,p_inventory_item_id       NUMBER      
                      ,p_organization_id         NUMBER      
                      ,p_vendor_id               NUMBER
                      ,p_vendor_site_id          NUMBER
                      ,p_buy_back_vendor_id      NUMBER
                      ,p_buy_back_vendor_site_id NUMBER
                      ,p_old_po_cost             NUMBER
                      ,p_new_po_cost             NUMBER)
IS

BEGIN
     
   -----------------------------------------------
   -- Insert record in XX_GI_CONSIGN_CHANGES table  
   -----------------------------------------------  
   INSERT INTO XX_GI_CONSIGN_CHANGES
   (  change_id 
    , change_type 
    , effective_date         
    , inventory_item_id      
    , organization_id        
    , vendor_id              
    , vendor_site_id         
    , buy_back_vendor_id     
    , buy_back_vendor_site_id
    , old_po_cost            
    , new_po_cost            
    , processed_flag         
    , process_date           
    , error_code             
    , error_message      
    , attribute_category     
    , attribute1             
    , attribute2             
    , attribute3             
    , attribute4             
    , attribute5             
    , attribute6             
    , attribute7             
    , attribute8             
    , attribute9             
    , attribute10            
    , attribute11            
    , attribute12            
    , attribute13            
    , attribute14            
    , attribute15            
    , request_id             
    , program_application_id 
    , program_id             
    , program_update_date    
    , creation_date          
    , created_by             
    , last_update_date       
    , last_updated_by        
    , last_updated_login
    )
    VALUES
   ( xx_gi_consign_changes_s.NEXTVAL
   , p_change_type
   , p_effective_date
   , p_inventory_item_id
   , p_organization_id
   , p_vendor_id
   , p_vendor_site_id
   , p_buy_back_vendor_id
   , p_buy_back_vendor_site_id
   , p_old_po_cost 
   , p_new_po_cost
   ,'N'
   , NULL       
   , NULL
   , NULL
   , NULL
   , NULL
   , NULL
   , NULL
   , NULL
   , NULL
   , NULL
   , NULL
   , NULL
   , NULL
   , NULL
   , NULL
   , NULL
   , NULL
   , NULL
   , NULL
   , gn_conc_req_id
   , gn_prog_app_id
   , gn_conc_prog_id
   , SYSDATE
   , SYSDATE
   , gn_user_id
   , SYSDATE
   , gn_user_id
   , gn_user_id
   );
EXCEPTION
    WHEN OTHERS THEN
       display_log('For '||p_change_type||' ,'||p_effective_date||','|| p_inventory_item_id||','|| p_organization_id ||'Oracle Error: '||SQLERRM);   
END;

--+============================================================================================+
--| PROCEDURE   : Consign_change_load                                                          |
--| Description : This procedures is used to load record from parameters table to consign table|
--| X_ERRBUF               OUT   VARCHAR2                                                      |
--| X_RETCODE              OUT   NUMBER                                                        |
--+============================================================================================+
PROCEDURE consign_change_load(
          x_errbuf               OUT   VARCHAR2
         ,x_retcode              OUT   NUMBER
          )
IS
  
  EX_INVALID_SKU         EXCEPTION;
  
  lc_action              VARCHAR2(100)   := NULL;
  
  lc_vendor_num          VARCHAR2(30);
  lc_buy_vendor_num      VARCHAR2(30);
  
  lc_message             VARCHAR2(3000);
  lc_parameter_flag      VARCHAR2(1)      := NULL;
  
  lc_sku                 mtl_system_items_b.segment1%TYPE;
  lc_exists              VARCHAR2(1)  := 'N';
  lc_param_rec           VARCHAR2(1)  := 'N';
  lc_same_item           VARCHAR2(1)  := 'Y';
  lc_country             VARCHAR2(30);
  
  ln_vendor_id           PLS_INTEGER;
  ln_temp_inv_id         PLS_INTEGER;       
  ln_buy_vendor_id       PLS_INTEGER;
  
  ln_log_index           PLS_INTEGER  := NULL;
  ln_fail_index          PLS_INTEGER  := NULL;
  ---------------------------------------------------------------------------
  -- Select record from xx_itm_consign_conv_parms table and decode action_flag
  ---------------------------------------------------------------------------
  CURSOR lcu_get_parameters
  IS
  SELECT xgccp.*                       
  FROM   xx_itm_consign_conv_parms xgccp 
  WHERE  TRUNC(effective_date) <= TRUNC(SYSDATE)
  AND    action_flag IN ('C','R')
  AND    status_code IN ('E','P')
  ORDER BY xgccp.inventory_item_id ASC;

  ------------------------------------
  -- To hold number of failed records.
  ------------------------------------
  --lr_failed_record    lr_failed_rec_type;

  -------------------------------------------------
  -- Select record from XX_GI_CONSIGN_CHANGES table  
  -------------------------------------------------  
  CURSOR lcu_consign_change(ld_effective_date    DATE,
                            ln_inventory_item_id NUMBER,
                            ln_organization_id   NUMBER)
  IS
  SELECT xgcc.rowid, xgcc.*
  FROM   xx_gi_consign_changes xgcc
  WHERE  TRUNC (effective_date) = TRUNC (ld_effective_date)
  AND    inventory_item_id      = ln_inventory_item_id
  AND    organization_id        = ln_organization_id;


BEGIN

  SELECT COUNT(1)
  INTO   gn_bypassed
  FROM   xx_itm_consign_conv_parms xgccp 
  WHERE  TRUNC(effective_date) > TRUNC(SYSDATE)
  AND    action_flag IN ('C','R');
  
  display_log('============================================================================================================================');
  display_log(RPAD('Office Depot',100,' ')||'Date: '||TO_CHAR(SYSDATE,'DD-MON-YY HH24:MI:SS AM'));
  display_log('');
  display_log('                                     Consignment Conversion Capture Statistics                                     ');
  display_log('============================================================================================================================');

  lc_parameter_flag := 'N';    --Indicates that Parameter Table does not have any Records.

  ln_temp_inv_id := -9999;

  gt_log_rec_tab.DELETE;
  ln_log_index := 1;

  gt_fail_rec_tab.DELETE;
  ln_fail_index := 1;
  -------------------------------------------------
  -- Cursor to fetch xx_itm_consign_conv_parms table
  -------------------------------------------------  
  FOR lcu_get_parameters_rec IN lcu_get_parameters
  LOOP
  
  lc_exists   := 'N';
  
  --Anonymous Block
  BEGIN
     
     IF (lcu_get_parameters_rec.action_flag = 'C') THEN
         lc_action    := 'Regular to Consign';
     ELSIF (lcu_get_parameters_rec.action_flag = 'R') THEN
         lc_action    :='Consign to Regular';
     END IF;

     gn_processed := gn_processed + 1;

     display_log('Processing record No = ' || gn_processed);
     
     lc_parameter_flag := 'Y'; --Indicates that Parameter Table has Records.

     ----------------------------------------------
     -- Rolling back for same SKU vendor_id against conv_supplier_site
     ----------------------------------------------
     IF ln_temp_inv_id <> lcu_get_parameters_rec.inventory_item_id THEN
        display_log('Creating Savepoint for item_id:' || lcu_get_parameters_rec.inventory_item_id);
        lc_same_item := 'Y';
        SAVEPOINT Error_out;

     ELSIF lc_same_item = 'N' AND ln_temp_inv_id = lcu_get_parameters_rec.inventory_item_id THEN
        x_errbuf := 'Exception was raised for the same Item previously';
        RAISE EX_INVALID_SKU;

     END IF;

     ln_temp_inv_id := lcu_get_parameters_rec.inventory_item_id;

     ----------------------------------------------
     -- Select vendor_id against conv_supplier_site
     ----------------------------------------------
     BEGIN

         SELECT PV.segment1, 
                PV.vendor_id
         INTO   lc_vendor_num,
                ln_vendor_id
         FROM   po_vendors PV
               ,po_vendor_sites_all PVSA
         WHERE  PV.vendor_id        = PVSA.vendor_id
         AND    PVSA.vendor_site_id = lcu_get_parameters_rec.conv_supplier_site;

     EXCEPTION
         WHEN OTHERS THEN
         x_errbuf := 'Failed to get vendor id for conv_supplier_site:' || lcu_get_parameters_rec.conv_supplier_site || ' ' || SQLERRM;
         display_log(x_errbuf);
         RAISE EX_INVALID_SKU;

     END;

     --------------------------------------------------
     -- Select vendor_id against buy_back_supplier_site
     --------------------------------------------------  
     BEGIN

         SELECT PV.segment1, 
                PV.vendor_id
         INTO   lc_buy_vendor_num,
                ln_buy_vendor_id
         FROM   po_vendors PV
               ,po_vendor_sites_all PVSA
         WHERE  PV.vendor_id        = PVSA.vendor_id
         AND    PVSA.vendor_site_id = lcu_get_parameters_rec.buy_back_supplier_site;

     EXCEPTION
         WHEN OTHERS THEN
         x_errbuf := 'Failed to get vendor id for buy_back_supplier_site  :' || lcu_get_parameters_rec.buy_back_supplier_site || ' ' || SQLERRM;
         display_log(x_errbuf); 
         RAISE EX_INVALID_SKU;
     END;

     ---------------------------------------
     -- Select sku against inventory_item_id
     ---------------------------------------
     BEGIN

         SELECT segment1
         INTO   lc_sku
         FROM   mtl_system_items_b 
         WHERE  inventory_item_id = lcu_get_parameters_rec.inventory_item_id 
         AND    organization_id   = lcu_get_parameters_rec.organization_id; 

     EXCEPTION
         WHEN OTHERS THEN
         x_errbuf := 'Invalid Item: '||lcu_get_parameters_rec.inventory_item_id||' Or Item does not exist in Inventory organization: '||lcu_get_parameters_rec.organization_id;
         display_log(x_errbuf);
         RAISE EX_INVALID_SKU;

     END;

     -----------------------------------------
     -- Select country against organization_id
     -----------------------------------------
     BEGIN

         SELECT country
         INTO   lc_country
         FROM   hr_organization_units_v 
         WHERE  organization_id   = lcu_get_parameters_rec.organization_id; 

     EXCEPTION
         WHEN OTHERS THEN
         x_errbuf := 'Invalid Oraganization: '||lcu_get_parameters_rec.organization_id||' OR Organization does not exist';
         display_log(x_errbuf);
         RAISE EX_INVALID_SKU;

     END;
     ----------------------------------------------
     -- Cursor to fetch XX_GI_CONSIGN_CHANGES table
     ----------------------------------------------
     FOR lcu_get_changes_rec IN lcu_consign_change(lcu_get_parameters_rec.effective_date,
                                                   lcu_get_parameters_rec.inventory_item_id,
                                                   lcu_get_parameters_rec.organization_id)
     LOOP
   
        lc_exists := 'Y';
        display_log('Exists in XGCC flag = ' || lc_exists);
        display_log('Record in XGCC');
        ----------------------------------------------------------------------------
        -- Check for existing data in XX_GI_CONSIGN_CHANGES table using process flag
        ----------------------------------------------------------------------------
        IF (lcu_get_changes_rec.processed_flag = 'Y') THEN
                       
           display_log('Record in XGCC as Processed, so inerting again');
           display_log('InItem_id = ' || lcu_get_parameters_rec.inventory_item_id);
           
           Insert_data(lc_action
                     , lcu_get_parameters_rec.effective_date
                     , lcu_get_parameters_rec.inventory_item_id
                     , lcu_get_parameters_rec.organization_id
                     , ln_vendor_id
                     , lcu_get_parameters_rec.conv_supplier_site
                     , ln_buy_vendor_id
                     , lcu_get_parameters_rec.buy_back_supplier_site
                     , NULL
                     , lcu_get_parameters_rec.buy_back_po_cost
                     );

           gn_rec_inserted := gn_rec_inserted + 1;

           --Inserting Data into successful table
           display_log('Inserting Data into successful table (for Insert) at index ' || ln_log_index);
           gt_log_rec_tab(ln_log_index).xccp_rec                 := lcu_get_parameters_rec;
           gt_log_rec_tab(ln_log_index).change_type              := lc_action;
           gt_log_rec_tab(ln_log_index).sku                      := lc_sku;
           gt_log_rec_tab(ln_log_index).country                  := lc_country;
           gt_log_rec_tab(ln_log_index).consign_supplier         := lc_vendor_num;
           gt_log_rec_tab(ln_log_index).buy_back_supplier        := lc_buy_vendor_num;
           gt_log_rec_tab(ln_log_index).print_flag               := 'Y';
           gt_log_rec_tab(ln_log_index).action_type              := 'I';
           ln_log_index := ln_log_index + 1;

          --  Processing Error and Unprocessed records

         ELSIF (lcu_get_changes_rec.processed_flag IN ('N','E') ) THEN

         display_log('Record in XGCC as UNprocessed, so updating');
         display_log('InItem_id = ' || lcu_get_parameters_rec.inventory_item_id);

           -----------------------------------------------
           -- Update record in XX_GI_CONSIGN_CHANGES table  
           -----------------------------------------------  
           UPDATE xx_gi_consign_changes 
           SET  vendor_id                = ln_vendor_id
              , vendor_site_id           = lcu_get_parameters_rec.conv_supplier_site
              , buy_back_vendor_id       = ln_buy_vendor_id
              , buy_back_vendor_site_id  = lcu_get_parameters_rec.buy_back_supplier_site
              , old_po_cost              = NULL
              , new_po_cost              = lcu_get_parameters_rec.buy_back_po_cost
              , processed_flag           = 'N'
              , error_code               = NULL
              , error_message            = NULL
              , attribute_category       = NULL
              , attribute1               = NULL
              , attribute2               = NULL
              , attribute3               = NULL
              , attribute4               = NULL
              , attribute5               = NULL
              , attribute6               = NULL
              , attribute7               = NULL
              , attribute8               = NULL
              , attribute9               = NULL
              , attribute10              = NULL
              , attribute11              = NULL
              , attribute12              = NULL
              , attribute13              = NULL
              , attribute14              = NULL
              , attribute15              = NULL
              , request_id               = gn_conc_req_id
              , program_application_id   = gn_prog_app_id
              , program_id               = gn_conc_prog_id
              , program_update_date      = SYSDATE
              , last_update_date         = SYSDATE
              , last_updated_by          = gn_user_id
              , last_updated_login       = gn_user_id
           WHERE rowid                   = lcu_get_changes_rec.rowid;
           

           --Inserting Data into successful table
           display_log('Inserting Data into successful table (for Update) at index ' || ln_log_index);
           
           gt_log_rec_tab(ln_log_index).xccp_rec                 := lcu_get_parameters_rec;
           gt_log_rec_tab(ln_log_index).change_type              := lc_action;
           gt_log_rec_tab(ln_log_index).sku                      := lc_sku;
           gt_log_rec_tab(ln_log_index).country                  := lc_country;
           gt_log_rec_tab(ln_log_index).consign_supplier         := lc_vendor_num;
           gt_log_rec_tab(ln_log_index).buy_back_supplier        := lc_buy_vendor_num;
           gt_log_rec_tab(ln_log_index).print_flag               := 'Y';
           gt_log_rec_tab(ln_log_index).action_type              := 'U';

           ln_log_index := ln_log_index + 1;

           gn_rec_updated := gn_rec_updated + 1;

        END IF;

      END LOOP;

      ------------------------------------------------------------------
      -- Insert record that are not exist in XX_GI_CONSIGN_CHANGES table
      ------------------------------------------------------------------
      IF  lc_exists = 'N' THEN
    
          display_log ('Record not in XGCC, so inserting');
          -----------------------------------------------
          -- Insert record in XX_GI_CONSIGN_CHANGES table  
          -----------------------------------------------  
          insert_data( lc_action
                     , lcu_get_parameters_rec.effective_date
                     , lcu_get_parameters_rec.inventory_item_id
                     , lcu_get_parameters_rec.organization_id
                     , ln_vendor_id
                     , lcu_get_parameters_rec.conv_supplier_site
                     , ln_buy_vendor_id
                     , lcu_get_parameters_rec.buy_back_supplier_site
                     , NULL
                     , lcu_get_parameters_rec.buy_back_po_cost
                     );
          
          gn_rec_inserted := gn_rec_inserted + 1;

          --Inserting Data into successful table
          display_log('Inserting Data into successful table (for NOT in XGCC) at index ' || ln_log_index);

          gt_log_rec_tab(ln_log_index).xccp_rec                 := lcu_get_parameters_rec;
          gt_log_rec_tab(ln_log_index).change_type              := lc_action;
          gt_log_rec_tab(ln_log_index).sku                      := lc_sku;
          gt_log_rec_tab(ln_log_index).country                  := lc_country;
          gt_log_rec_tab(ln_log_index).consign_supplier         := lc_vendor_num;
          gt_log_rec_tab(ln_log_index).buy_back_supplier        := lc_buy_vendor_num;
          gt_log_rec_tab(ln_log_index).print_flag               := 'Y';
          gt_log_rec_tab(ln_log_index).action_type              := 'I';

          ln_log_index := ln_log_index + 1;

       END IF;

       ------------------------------------------------------------------------------------
       -- Update process_date of xx_itm_consign_conv_parms table after insertion or updation
       ------------------------------------------------------------------------------------
       display_log ('Updating process_date,status_code of Param table');

       UPDATE xx_itm_consign_conv_parms 
       SET    process_date          = SYSDATE
             ,status_code           = 'S'
       WHERE  inventory_item_id     = lcu_get_parameters_rec.inventory_item_id
       AND    organization_id       = lcu_get_parameters_rec.organization_id
       AND    effective_date        = lcu_get_parameters_rec.effective_date
       AND    action_flag           = lcu_get_parameters_rec.action_flag;

       display_log ('------------------------------------');

    EXCEPTION
       WHEN EX_INVALID_SKU THEN
          display_log ('EXCEPTION EX_INVALID_SKU');
          display_log ('------------------------------------');
          ROLLBACK TO ERROR_OUT;
          gt_fail_rec_tab(ln_fail_index).xccp_rec               := lcu_get_parameters_rec;
          gt_fail_rec_tab(ln_fail_index).xccp_rec.process_date  := SYSDATE;
          gt_fail_rec_tab(ln_fail_index).xccp_rec.error_message := x_errbuf;

          ln_fail_index                  := ln_fail_index + 1;
          gn_failed_records              := gn_failed_records + 1;
          lc_same_item                   := 'N';

       WHEN OTHERS THEN
          ROLLBACK TO ERROR_OUT;
          display_log ('EXCEPTION OTHERS Anonymous Block');
          lc_same_item := 'N';
    END;
    --Anonymous Block Ends

    END LOOP;
    
    -----------------------------------------------------
    --If there are no records in the Parameter table then
    -----------------------------------------------------
    IF (lc_parameter_flag = 'N') THEN

       display_log('No records in Parameter table to Process.');
       display_out('No records in Parameter table to Process.');
       gn_processed      := 0;
       gn_failed_records := 0;
       gn_rec_updated    := 0;

    END IF;

    --Mark records from success table as errored
    --If there are failed records.
    IF (gt_fail_rec_tab.COUNT > 0) THEN

        FOR  ln_fail_counter IN gt_fail_rec_tab.FIRST .. gt_fail_rec_tab.LAST
        LOOP

             display_log ('Updating process_date of Param table for failed record,inventory_item_id = ' || gt_fail_rec_tab(ln_fail_counter).xccp_rec.inventory_item_id);
             UPDATE xx_itm_consign_conv_parms 
             SET    process_date          = SYSDATE
                   ,status_code           = 'E'
                   ,error_message         = gt_fail_rec_tab(ln_fail_counter).xccp_rec.error_message
             WHERE  inventory_item_id     = gt_fail_rec_tab(ln_fail_counter).xccp_rec.inventory_item_id
             AND    organization_id       = gt_fail_rec_tab(ln_fail_counter).xccp_rec.organization_id
             AND    effective_date        = gt_fail_rec_tab(ln_fail_counter).xccp_rec.effective_date
             AND    action_flag           = gt_fail_rec_tab(ln_fail_counter).xccp_rec.action_flag;

             IF (gt_log_rec_tab.COUNT > 0) THEN

                 --To mark all records in success table as errored if failed table has a record with the same 
                 --inventory_item_id.
                 FOR  ln_log_counter IN gt_log_rec_tab.FIRST .. gt_log_rec_tab.LAST
                 LOOP

                     IF (gt_fail_rec_tab(ln_fail_counter).xccp_rec.inventory_item_id = gt_log_rec_tab(ln_log_counter).xccp_rec.inventory_item_id 
                         AND gt_log_rec_tab(ln_log_counter).print_flag <> 'N') 
                     THEN

                         display_log ('Updating process_date of Param table for rolled back record with inventory_item_id =.' || gt_log_rec_tab(ln_log_counter).xccp_rec.inventory_item_id);
                         UPDATE xx_itm_consign_conv_parms 
                         SET    process_date          = SYSDATE
                               ,status_code           = 'E'
                               ,error_message         = 'Exception was raised for the same Item previously.'
                         WHERE  inventory_item_id     = gt_log_rec_tab(ln_log_counter).xccp_rec.inventory_item_id
                         AND    organization_id       = gt_log_rec_tab(ln_log_counter).xccp_rec.organization_id
                         AND    effective_date        = gt_log_rec_tab(ln_log_counter).xccp_rec.effective_date
                         AND    action_flag           = gt_log_rec_tab(ln_log_counter).xccp_rec.action_flag;

                         gt_log_rec_tab(ln_log_counter).print_flag            := 'N';
                         gt_log_rec_tab(ln_log_counter).xccp_rec.process_date := SYSDATE;

                         gn_failed_records := gn_failed_records + 1;

                         IF (gt_log_rec_tab(ln_log_counter).action_type = 'I') THEN
                         
                             gn_rec_inserted := gn_rec_inserted - 1 ;
                             display_log ('Updating gn_rec_inserted to -- ' || gn_rec_inserted);
                         
                         ELSIF (gt_log_rec_tab(ln_log_counter).action_type = 'U') THEN
                         
                             gn_rec_updated := gn_rec_updated - 1;
                             display_log ('Updating gn_rec_updated to -- ' || gn_rec_updated);
                         
                         END IF;
                         
                     END IF;

                 END LOOP;

            END IF;

        END LOOP;
    END IF;
    --If to mark records from success table as errored Ends
    COMMIT;
    PRINT_LOG_OUTPUT();

   EXCEPTION

       WHEN OTHERS THEN
          display_log ('EXCEPTION OTHERS Procedure consign_change_load');
          ROLLBACK;
          gn_rec_inserted := 0;
          gn_rec_updated  := 0;

          PRINT_LOG_OUTPUT();

END consign_change_load;

END xx_gi_con_decon_load_pkg;
/
SHOW ERRORS;
EXIT;
-- --------------------------------------------------------------------------------
-- +==============================================================================+
-- |                         End of Script                                        |
-- +==============================================================================+
-- --------------------------------------------------------------------------------

