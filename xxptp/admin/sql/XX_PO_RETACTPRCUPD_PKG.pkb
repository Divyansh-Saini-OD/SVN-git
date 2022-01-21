SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_PO_RETACTPRCUPD_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/Office Depot/Consulting Organization             |
-- +===================================================================+
-- | Name       : XX_PO_RETACTPRCUPD_PKG.pkb                           |
-- | Description: This package is used to select all the quotations,   |
-- | which got cost changes and past effective date. This package also |
-- | selects all the PO, that are created after the effective date for |
-- | that item against that quotation. This package also updates the PO|
-- | price and submits PO for approval if current status of PO is approved|
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 23-Jul-2007  Sriramdas S      Initial draft version       |
-- |DRAFT 1B 30-Jul-2007  Sriramdas S      updated after Peer review   |
-- |DRAFT 1C 04-Sep-2007  Siddharth S      Added code for launching    |
-- |                                       approval PO.                |
-- |                                       Changed p_price_protection  |
-- |                                       Decode                      |
-- |1.0      25-Sep-2007  Seemant Gour     Updated as per Onsite       |
-- |                                       Review comments             |
-- |                                       and OD IT Design review comments.|
-- |1.1      25-Oct-2007  Vikas Raina      Changed for paramter value  |
-- |                                       Added last_update_date in   |
-- |                                       lcu_fetch_po cursor         |
-- |1.2      25-Feb-2008  Vikas Raina      Changes made as per onsite review
-- |                                       comments                    |
-- +===================================================================+
AS
-- ---------------------------
-- Global Variable Declaration
-- ---------------------------
   lc_err_buf  VARCHAR2(5000);
   GN_USER_ID  PLS_INTEGER := FND_GLOBAL.USER_ID ;
   -- +====================================================================+
   -- | Name         : GET_UPD_PRICE_QUO                                   |
   -- | Description  : This procedure select the quotations and purchase   |
   -- | order lines that are created after the effective date for that item|
   -- | against that quotation                                             |
   -- |                                                                    |
   -- |                                                                    |
   -- | Parameters   : x_err_buf    OUT  VARCHAR2  Error Message           |
   -- |                x_retcode    OUT  NUMBER    Error Code              |
   -- |                                                                    |
   -- | Returns      : None                                                |
   -- +====================================================================+
   PROCEDURE GET_UPD_PRICE_QUO(
                      x_err_buf          OUT   VARCHAR2
                     ,x_retcode          OUT   NUMBER
                     ,p_price_protection IN    VARCHAR2
                     ,x_ln_total         OUT   NUMBER
                     ,x_ln_total1        OUT   NUMBER
                     ,x_line_document    OUT   tbl_line_document
                     ,x_line_document1   OUT   tbl_line_document
                     )
   IS
      -- -----------------------------------------------------------------
      -- Declaring Local variables
      -- -----------------------------------------------------------------
      lb_ret                    BOOLEAN;
      lb_ret_site               BOOLEAN;
      lb_chk_for_data           BOOLEAN := FALSE ; -- Captures if any record was picked for processing
      lb_flag_curr_po           BOOLEAN;           
      lb_flag_prev_po           BOOLEAN;            
      ld_last_run_date          DATE;              -- Capture last run date in date format
      
      lc_item_number            MTL_SYSTEM_ITEMS_B.segment1%TYPE;      --Capture the Item Number
      ln_curr_po_header_id      XX_PO_PRICE_PROTECTION_ERR.PO_HEADER_ID%TYPE   := NULL;
      ln_prev_po_header_id      XX_PO_PRICE_PROTECTION_ERR.PO_HEADER_ID%TYPE   := NULL;
      ln_prev_header_id         XX_PO_PRICE_PROTECTION_ERR.PO_HEADER_ID%TYPE   := NULL;
      
      ln_org_id                 PLS_INTEGER  := FND_PROFILE.VALUE('ORG_ID') ; -- Get the org id
      lc_api_return             PLS_INTEGER;       --API Returns: 1 if the API completed successfully; 0 if there will any errors.
      ln_ctr                    PLS_INTEGER  := 0;
      ln_ctr1                   PLS_INTEGER  := 0;
      
      ln_prev_buyer_id          NUMBER      := NULL;
      ln_new_revision_num       NUMBER      := NULL;
      lc_api_errors             PO_API_ERRORS_REC_TYPE;
      ln_old_price              NUMBER;               -- Capture the old price
      ln_new_price              NUMBER;               -- Capture the new price using po_sourcing2_sv.get_break_price API
      ln_change_amt             NUMBER;               -- Capture the change amt, difference between old price and new price.
      ln_total                  NUMBER := 0;          -- Capture the total change amt
      ln_total1                 NUMBER := 0;          -- Capture the total change amt
      ln_total_quantity         NUMBER := 0;          -- Capture total quantity on Po's for a Quotation
      ln_total_cost             NUMBER := 0 ;
      ln_indx                   NUMBER := 0 ; -- Initialize the index variable for collection
      
      lc_curr_launch_approvals_flag   VARCHAR2(1) := NULL;
      lc_prev_launch_approvals_flag   VARCHAR2(1) := NULL;
      
      lc_country                VARCHAR2(60) := NULL; -- Capture country
      lc_loc_type_code          VARCHAR2(80) := NULL; -- Capture location_type_code
      lc_line_document          VARCHAR2(2000);
      lc_line_document1         VARCHAR2(2000);
      lc_return_status          VARCHAR2(1);              
      -- -----------------------------------------------------------------
      -- Declaring PL/SQL table type
      -- ----------------------------------------------------------------- 
      xx_po_wf_approve_tbl_type  xx_po_wf_app_tbl_type; 
      
      -- ==========================================================================
      -- Get all quotations for the items from the quotation table that
      -- have cost changes and past effective start date based on the price
      -- protection parameter, which got updated after the last run of the program.
      -- ==========================================================================
      CURSOR lcu_fetch_quotations(p_price_protection  VARCHAR2
                                 ,ld_last_run_date     DATE)
      IS
      SELECT  DISTINCT PHA.segment1
             ,PHA.po_header_id
             ,PHA.vendor_id
             ,PHA.vendor_site_id
             ,PHA.currency_code
             ,PHA.rate
             ,PLA.po_line_id
             ,PLA.line_num
             ,PLA.vendor_product_num
             ,PLLA.ship_to_location_id
             ,PLLA.ship_to_organization_id
             ,PLLA.start_date
             ,PLLA.attribute8
             ,PLLA.last_update_date
      FROM    po_headers        PHA
             ,po_lines          PLA
             ,po_line_locations PLLA
      WHERE   PHA.po_header_id               = PLA.po_header_id
      AND     PLA.po_header_id               = PLLA.po_header_id
      AND     PLA.po_line_id                 = PLLA.po_line_id
      AND     UPPER(PHA.attribute_category)  = 'TRADE QUOTATION'  -- V1.2
      AND     PHA.type_lookup_code           = 'QUOTATION'
      AND     PHA.quote_type_lookup_code     = 'CATALOG'
      AND     PLLA.last_update_date          > TRUNC(ld_last_run_date)
      AND     PLLA.attribute7                = p_price_protection
      AND     SYSDATE BETWEEN NVL (PLLA.start_date, SYSDATE-1) AND NVL (PLLA.end_date, SYSDATE+1)
      AND     TRUNC(NVL(PLLA.start_date, SYSDATE)) <> TRUNC(TO_DATE(NVL(PLLA.attribute8,SYSDATE),'DD-MON-YYYY'))  -- added as per Review comments version 1.0
      ORDER BY PLLA.last_update_date ASC ;
      -- ==========================================================================
      -- Get all the purchase order lines that are created after the effective date
      -- for that item against that quotation.
      -- ==========================================================================
      CURSOR lcu_fetch_po (p_po_header_id        NUMBER
                          ,p_po_line_id          NUMBER
                          ,p_start_date          DATE)
      IS
      SELECT  PHA.po_header_id
             ,PHA.segment1  segment1
             ,PHA.attribute_category
             ,PHA.type_lookup_code
             ,PHA.revision_num revision_num
             ,PHA.vendor_id
             ,PV.vendor_name
             ,PLLA.ship_to_location_id
             ,PLLA.need_by_date
             ,PLLA.line_location_id
             ,PHA.rate
             ,PLA.negotiated_by_preparer_flag
             ,PLA.po_line_id
             ,PLA.line_num  line_num
             ,PLA.list_price_per_unit
             ,PLA.unit_price
             ,PLA.quantity
             ,PLA.vendor_product_num
             ,PLA.item_id
             ,PLLA.creation_date
             ,PLLA.promised_date
             ,PLLA.shipment_num
             ,DECODE(PHA.authorization_status, 'APPROVED', 'N', 'Y') LAUNCH_APPROVALS_FLAG
             ,PLLA.ship_to_organization_id
             ,PHA.agent_id
      FROM    po_headers         PHA
             ,po_lines           PLA
             ,po_line_locations  PLLA
             ,po_vendors         PV
      WHERE   PHA.po_header_id                      = PLA.po_header_id
      AND     PLA.po_header_id                      = PLLA.po_header_id
      AND     PLA.po_line_id                        = PLLA.po_line_id
      AND     NVL(PHA.closed_code,'OPEN')           IN ('OPEN', 'CLOSED FOR RECEIVING')
      AND     UPPER(PHA.attribute_category)         IN ('TRADE', 'BACKTOBACK', 'DROPSHIP')
      AND     NVL(PLLA.quantity_billed,0)           = 0
      AND     PHA.type_lookup_code                  = 'STANDARD'
      AND     PHA.vendor_id                         = PV.vendor_id
      AND     PLLA.from_header_id                   = p_po_header_id
      AND     PLLA.from_line_id                     = p_po_line_id
      AND     DECODE(p_price_protection,'P', 1, 2) = 1 
      AND     PLA.negotiated_by_preparer_flag = 'N'
      UNION
      SELECT  PHA.po_header_id
             ,PHA.segment1  SEGMENT1
             ,PHA.attribute_category
             ,PHA.type_lookup_code
             ,PHA.revision_num REVISION_NUM
             ,PHA.vendor_id
             ,PV.vendor_name
             ,PLLA.ship_to_location_id
             ,PLLA.need_by_date
             ,PLLA.line_location_id
             ,PHA.rate
             ,PLA.negotiated_by_preparer_flag
             ,PLA.po_line_id
             ,PLA.line_num LINE_NUM
             ,PLA.list_price_per_unit
             ,PLA.unit_price
             ,PLA.quantity
             ,PLA.vendor_product_num
             ,PLA.item_id
             ,PLLA.creation_date
             ,PLLA.promised_date
             ,PLLA.shipment_num
             ,DECODE(PHA.authorization_status, 'APPROVED', 'N', 'Y') LAUNCH_APPROVALS_FLAG
             ,PLLA.ship_to_organization_id
             ,PHA.agent_id
      FROM    po_headers        PHA
             ,po_lines          PLA
             ,po_line_locations PLLA
             ,po_vendors         PV
      WHERE   PHA.po_header_id                      = PLA.po_header_id
      AND     PLA.po_header_id                      = PLLA.po_header_id
      AND     PLA.po_line_id                        = PLLA.po_line_id
      AND     NVL(PHA.closed_code,'OPEN')           IN ('OPEN', 'CLOSED FOR RECEIVING')
      AND     UPPER(PHA.attribute_category)         IN ('TRADE', 'BACKTOBACK', 'DROPSHIP')
      AND     NVL(PLLA.quantity_billed,0)           = 0
      AND     PHA.type_lookup_code                  = 'STANDARD'
      AND     PLA.negotiated_by_preparer_flag       = 'N'
      AND     PHA.vendor_id                         = PV.vendor_id
      AND     PLLA.from_header_id                   = p_po_header_id
      AND     PLLA.from_line_id                     = p_po_line_id      
      AND     DECODE(p_price_protection,'P', 1, 2) = 2 
      AND    ((TRUNC(PLA.creation_date)              > TRUNC(p_start_date))
           OR (TRUNC(PLA.last_update_date)           > TRUNC(p_start_date))) 
      ORDER BY 1 ASC;
   -- -----------------------------------------------------------------
   -- Begining of the Procedure
   --------------------------------------------------------------------
   BEGIN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Invoking Procedure GET_UPD_PRICE_QUO');
       xx_po_wf_approve_tbl_type  := xx_po_wf_app_tbl_type(); --- Initialize collection      
        --
        -- Get the last run date of the concurrent program from the profile.
        --
        lc_last_run_date1 := fnd_profile.VALUE_SPECIFIC(name              =>  'XX_PO_RETACTPRCUPD_LSTRUNDT',
                                                        responsibility_id =>  fnd_profile.value('RESP_ID'),
                                                        application_id    =>  fnd_profile.value('RESP_APPL_ID'),
                                                        org_id            =>  ln_org_id);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Last Run date : '||lc_last_run_date1);
        
        IF lc_last_run_date1 IS NULL THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    ');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'OD: PO Retroactive Last Run Date profile is NULL');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'OD: PO Retroactive Last Run Date profile is NULL');
            x_err_buf   := 'OD: PO Retroactive Last Run Date profile is NULL';
            x_retcode   := 1;
            RETURN;
        END IF;
        
        ld_last_run_date :=  TO_DATE(lc_last_run_date1,'DD-MON-YYYY HH24:MI:SS');  
        lb_flag_curr_po   := FALSE;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Last Run date after conversion to date: '||ld_last_run_date);
        -- Fetch all the Quotations that are to be processed
        FOR lcu_fetch_quotations_cur IN lcu_fetch_quotations(p_price_protection
                                                            ,ld_last_run_date)
        LOOP
            -- Getting country_code for the Quotation
            BEGIN
               SELECT HLA.country
               INTO   lc_country
               FROM   hr_locations_all HLA
               WHERE  HLA.ship_to_location_id = lcu_fetch_quotations_cur.ship_to_location_id ;
            EXCEPTION
               WHEN OTHERS THEN 
                  lc_country := NULL ;
            END ;
            
            -- Getting location_type_code for the Quotation
            BEGIN
               SELECT HOUV.organization_type
               INTO   lc_loc_type_code
               FROM   hr_organization_units_v HOUV
               WHERE  HOUV.organization_id = lcu_fetch_quotations_cur.ship_to_organization_id;
            EXCEPTION
               WHEN OTHERS THEN 
                  lc_loc_type_code := NULL ;
            END ;
            
            -- Fetch all the PO's that are to linked to the above Quotations
            FOR lcu_fetch_po_cur IN lcu_fetch_po(lcu_fetch_quotations_cur.po_header_id
                                                ,lcu_fetch_quotations_cur.po_line_id
                                                ,lcu_fetch_quotations_cur.start_date)
            LOOP
                -- Initialize the variable which holds PO Details
                lc_line_document  := NULL;
                lc_line_document1 := NULL; 
                
                -- Get the current unit price of the PO Line
                ln_old_price := lcu_fetch_po_cur.unit_price;
                
                -- Getting total quantity ordered for all the PO's for the Quotation
                SELECT sum(PLA.quantity)
                INTO   ln_total_quantity
                FROM   po_lines_all PLA  
                WHERE  PLA.po_header_id  = lcu_fetch_po_cur.po_header_id
                AND    PLA.item_id       = lcu_fetch_po_cur.item_id;
                
                -- Process only when negotiated flag is N
--                IF NVL(lcu_fetch_po_cur.negotiated_by_preparer_flag,'N') = 'N' THEN -- v1.2
                    --Get the PO Line Item number for display
                    SELECT MSI.segment1
                    INTO   lc_item_number
                    FROM   mtl_system_items MSI
                         , mtl_parameters MP
                    WHERE  MSI.inventory_item_id = lcu_fetch_po_cur.item_id
                    AND    MP.organization_id    = MSI.organization_id
                    AND    ROWNUM = 1;                             
                    --
                    --Calling Standard API PO_SOURCING2_SV.GET_BREAK_PRICE to get the price
                    --from the referenced quote.
                    --
                    ln_new_price := PO_SOURCING2_SV.get_break_price(x_order_quantity   => lcu_fetch_po_cur.quantity
                                                                   ,x_ship_to_org      => lcu_fetch_quotations_cur.ship_to_organization_id
                                                                   ,x_ship_to_loc      => lcu_fetch_quotations_cur.ship_to_location_id
                                                                   ,x_po_line_id       => lcu_fetch_quotations_cur.po_line_id
                                                                   ,x_cum_flag         => FALSE
                                                                   ,p_need_by_date     => NULL
                                                                   ,x_line_location_id => NULL);
                                                                   
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'PO # '|| lcu_fetch_po_cur.segment1||' New price:'||ln_new_price||' Old price: '||ln_old_price||'PO Line ID: '||lcu_fetch_quotations_cur.po_line_id);
                    -- Update only when new price is different from old price                    
                    lb_flag_prev_po                := lb_flag_curr_po ;
                    ln_prev_po_header_id           := ln_curr_po_header_id;
                    lc_prev_launch_approvals_flag  := lc_curr_launch_approvals_flag ;
                    lc_curr_launch_approvals_flag  := lcu_fetch_po_cur.launch_approvals_flag;
                    ln_curr_po_header_id           := lcu_fetch_po_cur.po_header_id ;                                        
                    
                    IF (ln_curr_po_header_id <> NVL(ln_prev_po_header_id,0) ) THEN
                        ln_new_revision_num           := lcu_fetch_po_cur.revision_num;      
                        lc_curr_launch_approvals_flag := lcu_fetch_po_cur.launch_approvals_flag ; --lc_curr_launch_approvals_flag1;
                    END IF;

                    IF ln_new_price <> ln_old_price THEN
                        --
                        -- Calling PO_CHANGE_API1_S.update_po API to update the po price and submit po for Approval
                        -- if current status is Approved
                        --
                        lc_api_return := PO_CHANGE_API1_S.update_po ( x_po_number             => lcu_fetch_po_cur.segment1
                                                                     ,x_release_number        => NULL
                                                                     ,x_revision_number       => ln_new_revision_num
                                                                     ,x_line_number           => lcu_fetch_po_cur.line_num
                                                                     ,x_shipment_number       => 1 --every PO line has only shipment
                                                                     ,new_quantity            => NULL
                                                                     ,new_price               => ln_new_price
                                                                     ,new_promised_date       => lcu_fetch_po_cur.promised_date
                                                                     ,launch_approvals_flag   => lcu_fetch_po_cur.launch_approvals_flag
                                                                     ,update_source           => NULL
                                                                     ,version                 => '1.1'
                                                                     ,x_override_date         => NULL
                                                                     ,x_api_errors            =>  lc_api_errors
                                                                     ,p_buyer_name            => NULL
                                                                     );
                        -- Get the Change Amount     
                        ln_change_amt :=  ln_new_price - ln_old_price;
                        lb_flag_curr_po := TRUE;
                        --If Current PO Line returns error during updation then don’t launch approval wf.
                        IF (lcu_fetch_po_cur.po_header_id = ln_curr_po_header_id AND lc_api_return = 0) THEN
                            lb_flag_curr_po := FALSE;
                        END IF;
              --If API returns in success
                IF  lc_api_return <> 0 THEN -- Vikas
                IF ((NVL(ln_prev_po_header_id,-1) <> NVL(ln_curr_po_header_id,0) ) AND (lc_curr_launch_approvals_flag = 'N'))
                 THEN

                        xx_po_wf_approve_tbl_type.EXTEND;

                        ln_indx   := ln_indx + 1;
                        xx_po_wf_approve_tbl_type(ln_indx).po_header_id          := ln_curr_po_header_id;
                        xx_po_wf_approve_tbl_type(ln_indx).buyer_id              := ln_prev_buyer_id;
                        xx_po_wf_approve_tbl_type(ln_indx).update_po_flag        := lb_flag_curr_po;
                        xx_po_wf_approve_tbl_type(ln_indx).last_update_date      := lcu_fetch_quotations_cur.last_update_date ;
                        xx_po_wf_approve_tbl_type(ln_indx).launch_approvals_flag := lc_curr_launch_approvals_flag;              
                        lb_flag_curr_po   := FALSE;
            
               END IF;
                            ln_total           := ln_total + ln_change_amt;
                            lc_line_document1  := lc_line_document1||RPAD(lcu_fetch_po_cur.vendor_name,14) ||CHR(09);
                            lc_line_document1  := lc_line_document1||RPAD(lcu_fetch_po_cur.segment1,14) ||CHR(09);
                            lc_line_document1  := lc_line_document1||RPAD(lc_item_number,12)||CHR(09);
                            lc_line_document1  := lc_line_document1||RPAD(ln_old_price,10)||CHR(09);
                            lc_line_document1  := lc_line_document1||RPAD(ln_new_price,10)||CHR(09);
                            lc_line_document1  := lc_line_document1||RPAD(lcu_fetch_po_cur.quantity,10)||CHR(09);
                            lc_line_document1  := lc_line_document1||RPAD(ln_change_amt,14)||CHR(13);
                            ln_ctr1                   := ln_ctr1 + 1 ;
                            x_line_document1(ln_ctr1) := lc_line_document1 ;
                            x_ln_total                := ln_total ;
                            ln_new_revision_num := lcu_fetch_po_cur.revision_num + 1;
                            -- Calculating total cost of the PO's for a Quotation
                            ln_total_cost := ln_total_quantity * ln_change_amt ;
                            -- **** Inserting into Price protect history header table **--
                            IF p_price_protection = 'P' THEN
                             FND_FILE.PUT_LINE(FND_FILE.LOG,'Inserting into Archive tables ');
                               INSERT INTO XX_PO_PRICE_PROTECTION_HDR
                                        ( vendor_id
                                         ,vendor_site_id                              
                                         ,country_code  
                                         ,effective_date
                                         ,total_quantity_onhand
                                         ,total_vendor_bill
                                         ,currency_code
                                         ,invoice_number
                                         ,total_po_cost
                                         ,conversion_rate
                                         ,created_by
                                         ,last_updated_by
                                         ,creation_date
                                         ,last_update_date
                                        )
                               VALUES( 
                                          lcu_fetch_quotations_cur.vendor_id
                                         ,lcu_fetch_quotations_cur.vendor_site_id
                                         ,lc_country
                                         ,lcu_fetch_quotations_cur.attribute8
                                         ,NULL
                                         ,NULL
                                         ,lcu_fetch_quotations_cur.currency_code
                                         ,NULL
                                         ,ln_total_cost
                                         ,lcu_fetch_quotations_cur.rate
                                         ,GN_USER_ID
                                         ,GN_USER_ID
                                         ,SYSDATE
                                         ,SYSDATE
                                        );
                                
                            -- Inserting into Price protect history detail table 
                                
                               INSERT INTO XX_PO_PRICE_PROTECTION_DETAIL
                                        ( vendor_id
                                         ,vendor_site_id
                                         ,country_code 
                                         ,effective_date
                                         ,sku
                                         ,location
                                         ,vendor_product_code
                                         ,quantity_onhand
                                         ,trans_type_code
                                         ,original_po_cost
                                         ,location_type_code
                                         ,new_po_cost
                                         ,document_number
                                         ,original_average_cost
                                         ,new_average_cost
                                         ,status_code
                                         ,original_date
                                         ,sitran_update_flag
                                         ,reason_code
                                         ,status_code_rtv
                                         ,intransit_conversion_rate
                                         ,created_by
                                         ,last_updated_by
                                         ,creation_date
                                         ,last_update_date
                                        )
                               VALUES(
                                          lcu_fetch_quotations_cur.vendor_id
                                         ,lcu_fetch_quotations_cur.vendor_site_id
                                         ,lc_country
                                         ,lcu_fetch_quotations_cur.attribute8
                                         ,lc_item_number
                                         ,NULL
                                         ,lcu_fetch_quotations_cur.vendor_product_num
                                         ,NULL
                                         ,NULL
                                         ,ln_old_price
                                         ,lc_loc_type_code
                                         ,ln_new_price
                                         ,lcu_fetch_po_cur.segment1
                                         ,NULL
                                         ,NULL
                                         ,lcu_fetch_po_cur.launch_approvals_flag
                                         ,lcu_fetch_quotations_cur.attribute8
                                         ,NULL
                                         ,NULL
                                         ,NULL
                                         ,NULL
                                         ,GN_USER_ID
                                         ,GN_USER_ID
                                         ,SYSDATE
                                         ,SYSDATE
                                        );
                            END IF;
                        ELSE
                            -- In case the API fails, populate the error table
                            INSERT INTO xx_po_price_protection_err
                                  (vendor_id                           
                                  ,vendor_name                         
                                  ,item_number                         
                                  ,po_header_id                        
                                  ,segment1                            
                                  ,revision_num                        
                                  ,po_line_id                          
                                  ,line_num                            
                                  ,from_line_id                        
                                  ,from_line_location_id               
                                  ,ship_to_org_id                      
                                  ,ship_to_loc_id                      
                                  ,line_location_id                    
                                  ,need_by_date                        
                                  ,unit_price                          
                                  ,quantity                            
                                  ,effective_date                      
                                  ,quantity_onhand                     
                                  ,original_po_cost                    
                                  ,new_po_cost                         
                                  ,line_locn_last_update_date          
                                  ,document_number                     
                                  ,process_flag                        
                                  ,negotiated_by_preparer_flag         
                                  ,error_message                       
                                  ,vendor_product_num     
                                  ,rate
                                  ,currency_code
                                  ,launch_approval_flag
                                  ,org_id
                                  ,item_id
                                  ,created_by                          
                                  ,last_updated_by                     
                                  ,creation_date                       
                                  ,last_update_date                    
                                  )                                    
                            VALUES(lcu_fetch_po_cur.vendor_id          
                                  ,lcu_fetch_po_cur.vendor_name        
                                  ,lc_item_number                      
                                  ,lcu_fetch_po_cur.po_header_id       
                                  ,lcu_fetch_po_cur.segment1           
                                  ,lcu_fetch_po_cur.revision_num       
                                  ,lcu_fetch_po_cur.po_line_id         
                                  ,lcu_fetch_po_cur.line_num           
                                  ,lcu_fetch_quotations_cur.po_line_id
                                  ,NULL
                                  ,lcu_fetch_quotations_cur.ship_to_organization_id
                                  ,lcu_fetch_po_cur.ship_to_location_id
                                  ,null
                                  ,lcu_fetch_po_cur.need_by_date
                                  ,lcu_fetch_po_cur.unit_price
                                  ,lcu_fetch_po_cur.quantity
                                  ,NULL
                                  ,NULL
                                  ,lcu_fetch_po_cur.unit_price
                                  ,ln_new_price
                                  ,lcu_fetch_quotations_cur.last_update_date
                                  ,lcu_fetch_po_cur.segment1
                                  ,NULL
                                  ,lcu_fetch_po_cur.negotiated_by_preparer_flag
                                  ,lc_api_errors.message_text(1)                                  
                                  ,lcu_fetch_quotations_cur.vendor_product_num
                                  ,lcu_fetch_quotations_cur.rate
                                  ,lcu_fetch_quotations_cur.currency_code
                                  ,lcu_fetch_po_cur.launch_approvals_flag
                                  ,ln_org_id
                                  ,lcu_fetch_po_cur.item_id
                                  ,GN_USER_ID
                                  ,GN_USER_ID
                                  ,SYSDATE
                                  ,SYSDATE
                                  );
                                  
                                    lc_line_document  := lc_line_document||RPAD(lcu_fetch_po_cur.vendor_name,14) ||CHR(09);
                                    lc_line_document  := lc_line_document||RPAD(lcu_fetch_po_cur.segment1,14) ||CHR(09);
                                    lc_line_document  := lc_line_document||RPAD(lc_item_number,12)||CHR(09);
                                    lc_line_document  := lc_line_document||RPAD(ln_old_price,10)||CHR(09);
                                    lc_line_document  := lc_line_document||RPAD(ln_new_price,10)||CHR(09);
                                    lc_line_document  := lc_line_document||RPAD(lcu_fetch_po_cur.quantity,10)||CHR(09);
                                    lc_line_document  := lc_line_document||RPAD(ln_change_amt,14)||CHR(13);
                                    ln_total1         := ln_total1 + ln_change_amt;
                                    ln_ctr            := ln_ctr + 1 ;
                                    x_line_document(ln_ctr)    := lc_line_document;
                                    x_ln_total1                := ln_total1;
                        END IF; -- IF  lc_api_return <> 0 THEN  
                    END IF;   -- IF ln_new_price <> ln_old_price THEN
--                END IF;     -- IF NVL(lcu_fetch_po_cur.negotiated_by_preparer_flag,'N') = 'N' 
                
                ln_prev_buyer_id  := lcu_fetch_po_cur.agent_id;
                
            END LOOP;
            COMMIT;
            
            --
            -- Updating profile value 'XX_PO_RETACTPRCUPD_LSTRUNDT' with the last_update of the Quotation at organization level.
            --
            BEGIN
               -- Updating profile for the organization
               lb_ret      := FND_PROFILE.SAVE('XX_PO_RETACTPRCUPD_LSTRUNDT',TO_CHAR((lcu_fetch_quotations_cur.last_update_date),'DD-MON-YYYY HH24:MI:SS'),'ORG',ln_org_id);
               lb_ret_site := FND_PROFILE.SAVE('XX_PO_RETACTPRCUPD_LSTRUNDT', TO_CHAR((lcu_fetch_quotations_cur.last_update_date),'DD-MON-YYYY HH24:MI:SS'), 'SITE');
               
            END;
            
            FND_FILE.PUT_LINE (FND_FILE.LOG, lcu_fetch_quotations_cur.last_update_date ||'                 '||TO_CHAR(lcu_fetch_quotations_cur.last_update_date,'DD-MON-YYYY HH24:MI:SS'));
            
        END LOOP;
 
       ln_curr_po_header_id := 0 ; -- Re-initialize
       
       IF xx_po_wf_approve_tbl_type.COUNT > 0 THEN
       FOR ln_loop in xx_po_wf_approve_tbl_type.FIRST..xx_po_wf_approve_tbl_type.LAST
           LOOP
                      
           IF (xx_po_wf_approve_tbl_type(ln_loop).launch_approvals_flag = 'N' AND xx_po_wf_approve_tbl_type(ln_loop).update_po_flag
               AND xx_po_wf_approve_tbl_type(ln_loop).po_header_id <> NVL(ln_curr_po_header_id,0)
              ) 
           THEN
            
                FND_FILE.PUT_LINE (FND_FILE.LOG,'Header id for approval wf:'||xx_po_wf_approve_tbl_type(ln_loop).po_header_id); 
                ln_curr_po_header_id := xx_po_wf_approve_tbl_type(ln_loop).po_header_id ;
                
                PO_DOCUMENT_UPDATE_PVT.launch_po_approval_wf( p_api_version              => 1.0
                                                             ,p_init_msg_list            => FND_API.G_FALSE
                                                             ,x_return_status            => lc_return_status   
                                                             ,p_document_id              => xx_po_wf_approve_tbl_type(ln_loop).po_header_id
                                                             ,p_document_type            => 'PO'
                                                             ,p_document_subtype         => 'STANDARD'
                                                             ,p_preparer_id              => xx_po_wf_approve_tbl_type(ln_loop).buyer_id
                                                             ,p_approval_background_flag => NULL
                                                             ,p_mass_update_releases     => NULL
                                                             ,p_retroactive_price_change => NULL
                                                             );           
           END IF;
         END LOOP;
       ELSE
         FND_FILE.PUT_LINE(Fnd_File.LOG, 'No Purchase Order found for Update ');
       END IF;
   EXCEPTION
       WHEN OTHERS THEN
           ROLLBACK;
           x_retcode := 2;
           --Logging error as per the standards;
           Fnd_File.PUT_LINE(Fnd_File.LOG, 'Error in XX_PO_RETACTPRCUPD_PKG.GET_UPD_PRICE_QUO: ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));
           x_err_buf  := 'Error in XX_PO_RETACTPRCUPD_PKG.GET_UPD_PRICE_QUO: ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);
   END GET_UPD_PRICE_QUO;
   
   -- +====================================================================+
   -- | Name         : GET_ERR_PRICE_PO                                    |
   -- | Description  : This procedure will select all the records from the |
   -- | error table, call the API PO_SOURCING2_SV.GET_PRICE_BREAK to get   |
   -- | the new purchase order price and API  PO_CHANGE_API1_S.update_po   |
   -- | to update the po price and submit po for approval if current       |
   -- | status of the PO is approved.                                      |
   -- |                                                                    |
   -- |                                                                    |
   -- | Parameters   : x_err_buf            OUT  VARCHAR2  Error Message   |
   -- |                x_retcode            OUT  NUMBER    Error Code      |
   -- |                p_prcs_only_err_flag IN   VARCHAR2                  |
   -- |                                                                    |
   -- | Returns      : None                                                |
   -- +====================================================================+
   PROCEDURE GET_ERR_PRICE_PO(
                      x_err_buf            OUT   VARCHAR2
                     ,x_retcode            OUT   NUMBER
                     ,p_prcs_only_err_flag IN    VARCHAR2
                     ,x_ln_total           OUT   NUMBER
                     ,x_ln_total1          OUT   NUMBER
                     ,x_line_document      OUT   tbl_line_document
                     ,x_line_document1     OUT   tbl_line_document
                     )
   IS
   -- Declaring Local variables
       ln_prev_po_header_id         XX_PO_PRICE_PROTECTION_ERR.po_header_id%TYPE     := NULL;       
       ln_prev_header_id            XX_PO_PRICE_PROTECTION_ERR.po_header_id%TYPE     := NULL;       
       ln_curr_po_header_id         XX_PO_PRICE_PROTECTION_ERR.po_header_id%TYPE     := NULL;       
       lc_prev_launch_approval_flag XX_PO_PRICE_PROTECTION_ERR.launch_approval_flag%TYPE := NULL;   
       lc_curr_launch_approval_flag XX_PO_PRICE_PROTECTION_ERR.launch_approval_flag%TYPE := NULL;   
       lb_ret                       BOOLEAN;
       lb_ret_site                  BOOLEAN;
       lb_flag_curr_po              BOOLEAN;            
       lb_prev_flag_curr_po         BOOLEAN;            
       lb_chk_for_data              BOOLEAN := FALSE ; -- Captures if any record was picked for processing
       lc_return_status             VARCHAR2(1);   
       ld_last_run_date             DATE;              -- Capture last run date in date format
       lc_api_errors                PO_API_ERRORS_REC_TYPE;
       ln_ctr                       PLS_INTEGER  := 0;
       ln_ctr1                      PLS_INTEGER  := 0;
       ln_org_id                    PLS_INTEGER  := FND_PROFILE.VALUE('ORG_ID') ; -- Get the org id
       ln_prev_agent_id             XX_PO_PRICE_PROTECTION_ERR.agent_id%TYPE := NULL;            
       ln_curr_agent_id             XX_PO_PRICE_PROTECTION_ERR.agent_id%TYPE := NULL;
       ln_new_revision_num          NUMBER := NULL;
       lc_api_return                NUMBER;           -- API Returns: 1 if the API completed successfully; 0 if there will any errors.
       ln_new_price                 NUMBER := 0;      -- Capture the new price using po_sourcing2_sv.get_break_price API
       ln_old_price                 NUMBER := 0;      -- Capture the old price
       ln_change_amt                NUMBER := 0;      -- Capture the change amt, difference between old price and new price.
       ln_total                     NUMBER := 0;      -- Capture the total change amt
       ln_total1                    NUMBER := 0;      -- Capture the total change amt
       ln_total_quantity1           NUMBER := 0;      -- Capture the total quantity on PO's for a quotation
       ln_total_cost1               NUMBER := 0;       
       ln_indx                      NUMBER := 0;
       lc_country1                  VARCHAR2(60) := NULL; -- Capture country
       lc_loc_type_code1            VARCHAR2(80) := NULL; -- Capture location_type_code
       lc_line_document             VARCHAR2(2000):=NULL;
       lc_line_document1            VARCHAR2(2000):=NULL;
 
       xx_po_err_wf_approve_tbl_type  xx_po_wf_app_tbl_type ;       

-- =======================================================================
-- Cursor to pick all error records and also PO Line status corrosponding 
-- to it.
-- =======================================================================

CURSOR lcu_fetch_err_po
IS
SELECT NVL(PL.closed_code, 'OPEN') closed_code
     ,XPPPE.*
FROM   xx_po_price_protection_err XPPPE
     ,po_lines              PL
WHERE  XPPPE.process_flag = 'P'
AND    PL.po_line_id     = XPPPE.po_line_id
AND    PL.org_id         = XPPPE.org_id
ORDER BY XPPPE.po_header_id, XPPPE.line_num;

BEGIN

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Invoking Procedure GET_ERR_PRICE_PO');
       xx_po_err_wf_approve_tbl_type  := xx_po_wf_app_tbl_type(); --- Initialize collection
       
       FOR lcu_fetch_err_po_cur IN lcu_fetch_err_po
       LOOP  
       -- BEGIN Loop for error table records
          --Checking for the Closed Code for the PO Line for the errored table record
          IF (lcu_fetch_err_po_cur.closed_code NOT IN ('CLOSED', 'CLOSED FOR INVOICE', 'CANCELLED')) THEN
          
              --If negotiated flag is N then go to next step
--              IF (lcu_fetch_err_po_cur.negotiated_by_preparer_flag = 'N') THEN -- V1.2
                  -- Initialize the variable which holds PO Details
                     lc_line_document  := NULL ;
                     lc_line_document1 := NULL ;
                  --- Getting old Price
                      ln_old_price := lcu_fetch_err_po_cur.unit_price;
                  -- Getting country_code for the Quotation
                  BEGIN
                    SELECT HL.country
                    INTO   lc_country1
                    FROM   hr_locations_all HL
                    WHERE  HL.ship_to_location_id = lcu_fetch_err_po_cur.ship_to_loc_id ;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                       lc_country1 := NULL;
                  END;
                  
                  -- Getting location_type_code for the Quotation
                  BEGIN
                    SELECT HOUV.organization_type
                    INTO   lc_loc_type_code1
                    FROM   hr_organization_units_v HOUV
                    WHERE  HOUV.organization_id = lcu_fetch_err_po_cur.ship_to_org_id;
                    
                  EXCEPTION
		    WHEN NO_DATA_FOUND THEN
		         lc_loc_type_code1 := NULL;
                  END;
                  
                  -- Getting total quantity ordered for all the PO's for the Quotation
                  SELECT sum(quantity)
                  INTO   ln_total_quantity1
                  FROM   po_lines_all  
                  WHERE  po_header_id  = lcu_fetch_err_po_cur.po_header_id
                  AND    item_id       = lcu_fetch_err_po_cur.item_number;
                  -- Calling Standard API PO_SOURCING2_SV.GET_BREAK_PRICE to get the price
                  -- from the referenced quote.
                  ln_new_price := PO_SOURCING2_SV.get_break_price(x_order_quantity   => lcu_fetch_err_po_cur.quantity
                                                                 ,x_ship_to_org      => lcu_fetch_err_po_cur.ship_to_org_id
                                                                 ,x_ship_to_loc      => lcu_fetch_err_po_cur.ship_to_loc_id
                                                                 ,x_po_line_id       => lcu_fetch_err_po_cur.from_line_id
                                                                 ,x_cum_flag         => FALSE
                                                                 ,p_need_by_date     => NULL
                                                                 ,x_line_location_id => NULL
                                                                 );

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error PO# '||lcu_fetch_err_po_cur.segment1||' New price:'||ln_new_price||' Old price: '||ln_old_price||'PO Line ID: '||lcu_fetch_err_po_cur.from_line_id);
                    
                  --Get prev Record Values  
                  lb_prev_flag_curr_po         := lb_flag_curr_po;
                  ln_prev_po_header_id         := ln_curr_po_header_id;
                  lc_prev_launch_approval_flag := lc_curr_launch_approval_flag;
                  ln_prev_agent_id             := ln_curr_agent_id; 
                  --get vals for new record 
                  ln_curr_po_header_id         := lcu_fetch_err_po_cur.po_header_id;
                  lc_curr_launch_approval_flag := lcu_fetch_err_po_cur.launch_approval_flag;
                  ln_curr_agent_id             := lcu_fetch_err_po_cur.agent_id;
                --if pos are different get revision no from cursor and get the prev val of launch_approval_flag 
                  IF (ln_curr_po_header_id <> NVL(ln_prev_po_header_id,0)) THEN
                      ln_new_revision_num           := lcu_fetch_err_po_cur.revision_num;
                      lc_curr_launch_approval_flag  := lc_prev_launch_approval_flag; 
                  END IF;
                  
                  -- The API will be called only if the old and new Price is different.
                  IF ln_old_price <> ln_new_price THEN
                  --
                  -- Calling PO_CHANGE_API1_S.update_po API to update the po price and submit po for Approval
                  -- if current status is Approved
                  --
                      lc_api_return := PO_CHANGE_API1_S.update_po ( x_po_number             => lcu_fetch_err_po_cur.segment1
                                                                   ,x_release_number        => NULL
                                                                   ,x_revision_number       => ln_new_revision_num
                                                                   ,x_line_number           => lcu_fetch_err_po_cur.line_num
                                                                   ,x_shipment_number       => 1
                                                                   ,new_quantity            => NULL
                                                                   ,new_price               => ln_new_price
                                                                   ,new_promised_date       => lcu_fetch_err_po_cur.effective_date
                                                                   ,launch_approvals_flag   => lcu_fetch_err_po_cur.launch_approval_flag
                                                                   ,update_source           => NULL
                                                                   ,version                 => '1.1'
                                                                   ,x_override_date         => NULL
                                                                   ,x_api_errors            => lc_api_errors
                                                                   ,p_buyer_name            => NULL
                                                                   );
                      -- geting the change Amt
                       ln_change_amt :=  ln_new_price - ln_old_price;
                      -- API Returns:
                      -- 1 if the API completed successfully;
                      -- 0 if there will any errors.
                      --If API Success
                      
                      IF lc_api_return  <> 0 THEN
 
		          xx_po_err_wf_approve_tbl_type.EXTEND;
		          ln_indx   := ln_indx + 1;
		          xx_po_err_wf_approve_tbl_type(ln_indx).po_header_id         := lcu_fetch_err_po_cur.po_header_id;
		          xx_po_err_wf_approve_tbl_type(ln_indx).buyer_id             := lcu_fetch_err_po_cur.agent_id;
		          xx_po_err_wf_approve_tbl_type(ln_indx).last_update_date     := lcu_fetch_err_po_cur.last_update_date ;
		          xx_po_err_wf_approve_tbl_type(ln_indx).launch_approvals_flag:= lcu_fetch_err_po_cur.launch_approval_flag;
 
                          ln_total            := ln_total + ln_change_amt;
                          lc_line_document1   := lc_line_document1||RPAD(lcu_fetch_err_po_cur.vendor_name,14) ||CHR(09);
                          lc_line_document1   := lc_line_document1||RPAD(lcu_fetch_err_po_cur.segment1,14) ||CHR(09);
                          lc_line_document1   := lc_line_document1||RPAD(lcu_fetch_err_po_cur.item_number,12)||CHR(09);
                          lc_line_document1   := lc_line_document1||RPAD(lcu_fetch_err_po_cur.unit_price,10)||CHR(09);
                          lc_line_document1   := lc_line_document1||RPAD(ln_new_price,10)||CHR(09);
                          lc_line_document1   := lc_line_document1||RPAD(lcu_fetch_err_po_cur.quantity,10)||CHR(09);
                          lc_line_document1   := lc_line_document1||RPAD(ln_change_amt,14)||CHR(13);
                          ln_ctr1 := ln_ctr1 + 1 ;
                          x_line_document1(ln_ctr1)     := lc_line_document1 ;
                          x_ln_total                    := ln_total;
                          ln_new_revision_num := lcu_fetch_err_po_cur.revision_num + 1;   --Added in DRAFT1C
                          -- Calculating total cost of the PO's for a Quotation
                          ln_total_cost1 := ln_total_quantity1 * ln_change_amt ;
                          -- **** Insertion into Price protect history header and detail table **--
                          IF p_prcs_only_err_flag = 'Y' THEN
                               INSERT INTO XX_PO_PRICE_PROTECTION_HDR
                                        ( vendor_id
                                         ,vendor_site_id                              
                                         ,country_code 
                                         ,effective_date
                                         ,total_quantity_onhand
                                         ,total_vendor_bill
                                         ,currency_code
                                         ,invoice_number
                                         ,total_po_cost
                                         ,conversion_rate
                                         ,created_by
                                         ,last_updated_by
                                         ,creation_date
                                         ,last_update_date
                                        )
                               VALUES( 
                                          lcu_fetch_err_po_cur.vendor_id
                                         ,lcu_fetch_err_po_cur.vendor_site_id
                                         ,lc_country1
                                         ,lcu_fetch_err_po_cur.effective_date
                                         ,NULL
                                         ,NULL
                                         ,lcu_fetch_err_po_cur.currency_code
                                         ,NULL
                                         ,ln_total_cost1
                                         ,lcu_fetch_err_po_cur.rate
                                         ,GN_USER_ID
                                         ,GN_USER_ID
                                         ,SYSDATE
                                         ,SYSDATE
                                        );
                               -- **** Inserting into Price protect history detail table **--
                               INSERT INTO XX_PO_PRICE_PROTECTION_DETAIL
                                        ( vendor_id
                                         ,vendor_site_id
                                         ,country_code
                                         ,effective_date
                                         ,sku
                                         ,location
                                         ,vendor_product_code
                                         ,quantity_onhand
                                         ,trans_type_code
                                         ,original_po_cost
                                         ,location_type_code
                                         ,new_po_cost
                                         ,document_number
                                         ,original_average_cost
                                         ,new_average_cost
                                         ,status_code
                                         ,original_date
                                         ,sitran_update_flag
                                         ,reason_code
                                         ,status_code_rtv
                                         ,intransit_conversion_rate
                                         ,created_by
                                         ,last_updated_by
                                         ,creation_date
                                         ,last_update_date
                                        )
                               VALUES(
                                          lcu_fetch_err_po_cur.vendor_id
                                         ,lcu_fetch_err_po_cur.vendor_site_id
                                         ,lc_country1
                                         ,lcu_fetch_err_po_cur.effective_date
                                         ,lcu_fetch_err_po_cur.segment1
                                         ,NULL
                                         ,lcu_fetch_err_po_cur.vendor_product_num
                                         ,NULL
                                         ,NULL
                                         ,ln_old_price
                                         ,lc_loc_type_code1
                                         ,ln_new_price
                                         ,lcu_fetch_err_po_cur.segment1
                                         ,NULL
                                         ,NULL
                                         ,lcu_fetch_err_po_cur.launch_approval_flag
                                         ,lcu_fetch_err_po_cur.effective_date
                                         ,NULL
                                         ,NULL
                                         ,NULL
                                         ,NULL
                                         ,GN_USER_ID
                                         ,GN_USER_ID
                                         ,SYSDATE
                                         ,SYSDATE
                                        );
                            END IF;
                      ELSE  ---  IF lc_api_return  <> 0 THEN
                      
                          UPDATE xx_po_price_protection_err XPPPE
                          SET    XPPPE.process_flag                = NULL
                                ,XPPPE.error_message               = lc_api_errors.message_text(1)
                                ,XPPPE.last_updated_by             = GN_USER_ID
                                ,XPPPE.last_update_date            = SYSDATE
                          WHERE  po_header_id       = lcu_fetch_err_po_cur.po_header_id
                          AND    po_line_id         = lcu_fetch_err_po_cur.po_line_id;
                          
                          lc_line_document  := lc_line_document||RPAD(lcu_fetch_err_po_cur.vendor_name,14) ||CHR(09);
                          lc_line_document  := lc_line_document||RPAD(lcu_fetch_err_po_cur.segment1,14) ||CHR(09);
                          lc_line_document  := lc_line_document||RPAD(lcu_fetch_err_po_cur.item_number,12)||CHR(09);
                          lc_line_document  := lc_line_document||RPAD(lcu_fetch_err_po_cur.unit_price,10)||CHR(09);
                          lc_line_document  := lc_line_document||RPAD(ln_new_price,10)||CHR(09);
                          lc_line_document  := lc_line_document||RPAD(lcu_fetch_err_po_cur.quantity,10)||CHR(09);
                          lc_line_document  := lc_line_document||RPAD(ln_change_amt,14)||CHR(13);
                          ln_total1         := ln_total1 + ln_change_amt;
                          ln_ctr            := ln_ctr + 1 ;
                          x_line_document(ln_ctr)      := lc_line_document;
                          x_ln_total1                   := ln_total1;
                   END IF; -- IF lc_api_return  <> 0 THEN
             END IF;    -- IF ln_old_price <> ln_new_price THEN

--        END IF;    /* --check for negotiated flag ends */  -- V1.2
        
        ELSE --- IF (lcu_fetch_err_po_cur.closed_code NOT IN ('CLOSED', 'CLOSED FOR INVOICE', 'CANCELLED')) 
           UPDATE xx_po_price_protection_err XPPPE 
           SET    XPPPE.process_flag = 'E'
                 ,XPPPE.error_message = lcu_fetch_err_po_cur.closed_code
           WHERE  XPPPE.po_header_id = lcu_fetch_err_po_cur.po_header_id
           AND    XPPPE.po_line_id   = lcu_fetch_err_po_cur.po_line_id
           AND    XPPPE.org_id       = lcu_fetch_err_po_cur.org_id;
        END IF; -- END IF for checking the Closed Code for the PO Line for the errored table record
          
     END LOOP; 
       
     IF xx_po_err_wf_approve_tbl_type.COUNT > 0 THEN
       FOR ln_loop IN xx_po_err_wf_approve_tbl_type.FIRST..xx_po_err_wf_approve_tbl_type.LAST
         LOOP
           IF (xx_po_err_wf_approve_tbl_type(ln_loop).launch_approvals_flag = 'N' 
            AND xx_po_err_wf_approve_tbl_type(ln_loop).po_header_id <> NVL(ln_prev_header_id,0) -- To avoid reapproving same records
           ) 
           THEN
              FND_FILE.PUT_LINE(Fnd_File.LOG,'Error PO id for approval wf :'||xx_po_err_wf_approve_tbl_type(ln_loop).po_header_id);
                ln_prev_header_id  := xx_po_err_wf_approve_tbl_type(ln_loop).po_header_id;
                
                PO_DOCUMENT_UPDATE_PVT.launch_po_approval_wf( p_api_version              => 1.0
                                                             ,p_init_msg_list            => FND_API.G_FALSE
                                                             ,x_return_status            => lc_return_status   
                                                             ,p_document_id              => xx_po_err_wf_approve_tbl_type(ln_loop).po_header_id
                                                             ,p_document_type            => 'PO'
                                                             ,p_document_subtype         => 'STANDARD'
                                                             ,p_preparer_id              => xx_po_err_wf_approve_tbl_type(ln_loop).buyer_id
                                                             ,p_approval_background_flag => NULL
                                                             ,p_mass_update_releases     => NULL
                                                             ,p_retroactive_price_change => NULL
                                                             );
           lb_ret      := FND_PROFILE.SAVE('XX_PO_RETACTPRCUPD_LSTRUNDT',TO_CHAR((xx_po_err_wf_approve_tbl_type(ln_loop).last_update_date),'DD-MON-YYYY HH24:MI:SS'),'ORG',ln_org_id);
           lb_ret_site := FND_PROFILE.SAVE('XX_PO_RETACTPRCUPD_LSTRUNDT',TO_CHAR((xx_po_err_wf_approve_tbl_type(ln_loop).last_update_date),'DD-MON-YYYY HH24:MI:SS'), 'SITE');
           END IF;
         END LOOP;
       ELSE
         FND_FILE.PUT_LINE(Fnd_File.LOG, 'No errored Purchase Order found for approval in this run ');
       END IF;
       
       COMMIT;
       
   EXCEPTION
       WHEN OTHERS THEN
              ROLLBACK;
             --Logging error as per the standards;
              FND_FILE.PUT_LINE(Fnd_File.LOG, 'Error in XX_PO_RETACTPRCUPD_PKG.GET_ERR_PRICE_PO: '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));
              x_err_buf := 'Error in XX_PO_RETACTPRCUPD_PKG.GET_ERR_PRICE_PO.'||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);
              x_retcode  := 2;
   END GET_ERR_PRICE_PO;
   
    -- +====================================================================+
    -- | Name         : PRINT_HEADER                                        |
    -- | Description  : This is useing for header  printing                 |
    -- |                                                                    |
    -- |                                                                    |
    -- | Parameters   : x_err_buf            OUT   VARCHAR2  Error Message  |
    -- |                x_retcode            OUT   NUMBER    Error Code     |
    -- |                p_total              IN    NUMBER                   |
    -- |                p_total1             IN    NUMBER                   |
    -- |                p_line_document      IN    tbl_line_document        | 
    -- |                p_line_document1     IN    tbl_line_document1       |
    -- |                                                                    |
    -- | Returns      : None                                                |
    -- +====================================================================+
   PROCEDURE PRINT_HEADER(
                          x_errbuf            OUT   VARCHAR2
                         ,x_retcode           OUT   NUMBER
                         ,p_total             IN    NUMBER
                         ,p_total1            IN    NUMBER
                         ,p_line_document     IN    tbl_line_document
                         ,p_line_document1    IN    tbl_line_document
                         )
   IS
   lc_header_document VARCHAR2(2000) := NULL;
   BEGIN
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('Office Depot',25)||LPAD('Date: ',55)||TO_DATE(SYSDATE,'DD-MM-RR'));
       FND_FILE.PUT_LINE(Fnd_File.OUTPUT,LPAD('Last Run Date: ',80)||lc_last_run_date1);
       lc_header_document  := lc_header_document||RPAD('Supplier Name',14) ||CHR(09);
       lc_header_document  := lc_header_document||RPAD('PO Number',14)     ||CHR(09);
       lc_header_document  := lc_header_document||RPAD('Item Number',12)   ||CHR(09);
       lc_header_document  := lc_header_document||RPAD('Old Price',10)     ||CHR(09);
       lc_header_document  := lc_header_document||RPAD('New Price',10)     ||CHR(09);
       lc_header_document  := lc_header_document||RPAD('Quantity',10)      ||CHR(09);
       lc_header_document  := lc_header_document||RPAD('Price difference',17) ||CHR(13);
       FND_FILE.PUT_LINE(Fnd_File.OUTPUT,'                              Retroactive Price Update');
       Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'                            Cost Change/Price Protection ');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'================================================================================================================');
       Fnd_File.PUT_LINE(FND_File.OUTPUT,lc_header_document);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'================================================================================================================');
       IF p_line_document1.COUNT > 0 THEN
           FOR ln_suc_counter IN p_line_document1.FIRST..p_line_document1.LAST
              LOOP
                 FND_FILE.PUT_LINE (FND_FILE.OUTPUT,p_line_document1(ln_suc_counter));
           END LOOP;
       END IF;
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'=============================================================================================================='||CHR(13)||CHR(10)||LPAD('Total: ',96)||p_total);
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'');
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'');
       Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'                              Retroactive Price Update');
       Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'                         Cost Change/Price Protection Failures');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'================================================================================================================');
       Fnd_File.PUT_LINE(FND_File.OUTPUT,lc_header_document);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'================================================================================================================');
       IF p_line_document.COUNT > 0 THEN
           FOR ln_fail_counter IN p_line_document.FIRST..p_line_document.LAST
              LOOP
                 FND_FILE.PUT_LINE (FND_FILE.OUTPUT,p_line_document(ln_fail_counter));
           END LOOP;
       END IF;
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'================================================================================================================='||CHR(13)||CHR(10)||LPAD('Total: ',96)||p_total1);
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT,' ');
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT,' ');
   EXCEPTION
      WHEN OTHERS THEN
          x_errbuf  := 'Error in print_header procedure. '||SUBSTR(SQLERRM,1,255);
          x_retcode := 2;
   END PRINT_HEADER;
   
    -- +====================================================================+
    -- | Name         : MAIN_PROC                                           |
    -- | Description  : This is the main procedure of the package, which is |
    -- |                invoked by the CP and which in turn calls the       |
    -- |                other procedures of the package.                    |
    -- |                                                                    |
    -- |                                                                    |
    -- | Parameters   : x_err_buf            OUT  VARCHAR2  Error Message   |
    -- |                x_retcode            OUT  NUMBER    Error Code      |
    -- |                p_price_protection   IN   VARCHAR2                  |
    -- |                p_prcs_only_err_flag IN   VARCHAR2                  |
    -- |                                                                    |
    -- | Returns      : None                                                |
    -- +====================================================================+
    PROCEDURE MAIN_PROC(  x_errbuf             OUT   VARCHAR2
                         ,x_retcode            OUT   NUMBER
                         ,p_price_protection   IN    VARCHAR2
                         ,p_prcs_only_err_flag IN    VARCHAR2
                       )
    IS
       -- table type variable declaration.
       x_line_document           tbl_line_document;
       x_line_document1          tbl_line_document;
       x_line_document2          tbl_line_document;
       x_line_document3          tbl_line_document;
       
       -- Local variable declaration.
       x_ln_total_get_err        NUMBER;
       x_ln_total1_get_err       NUMBER;
       x_ln_total_get_upd        NUMBER;
       x_ln_total1_get_upd       NUMBER;
    BEGIN
    -- Updating error table with process_flag to 'P' for the current run records
    -- so that they can be deleted after the run
    UPDATE xx_po_price_protection_err
    SET    process_flag  = 'P'
    WHERE  NVL(process_flag,'#') <> 'E';
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of Records updated to status P: '||SQL%ROWCOUNT);
    
    --  Process all the records errored out in the last run of the program.
    GET_ERR_PRICE_PO ( x_errbuf
                      ,x_retcode
                      ,p_price_protection
                      ,x_ln_total_get_err
                      ,x_ln_total1_get_err
                      ,x_line_document
                      ,x_line_document1
                      );
    -- Stop processing when the API errors out.
    IF (x_retcode = 2)  THEN
      RETURN ;
    END IF;
    
    IF  p_prcs_only_err_flag = 'N' THEN
    -- Process records only when new records need to be updated.
        GET_UPD_PRICE_QUO (x_errbuf
                          ,x_retcode
                          ,p_price_protection
                          ,x_ln_total_get_upd
                          ,x_ln_total1_get_upd
                          ,x_line_document2
                          ,x_line_document3
                          );
    
    -- Stop processing when the API errors out.
    IF (x_retcode = 2)  THEN
          RETURN ;
    END IF;
    
    END IF;
    
    --  Purging error table with the processed record in the current run
    DELETE FROM xx_po_price_protection_err
    WHERE  process_flag = 'P';
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of Records deleted from error table: '||SQL%ROWCOUNT);
    IF x_line_document2.COUNT > 0 THEN
        FOR ln_merge IN x_line_document2.FIRST..x_line_document2.LAST
        LOOP
            x_line_document(x_line_document.COUNT+1) :=  x_line_document2(ln_merge);
        END LOOP;
    END IF;
    IF x_line_document3.COUNT > 0 THEN
        FOR ln_err_merge IN x_line_document3.FIRST..x_line_document3.LAST
        LOOP
           x_line_document1(x_line_document1.COUNT+1) :=  x_line_document3(ln_err_merge);
        END LOOP;
    END IF;
    
    --Printing the Output
    PRINT_HEADER( x_errbuf
                 ,x_retcode
                 ,NVL(x_ln_total_get_err,0)  + NVL(x_ln_total_get_upd,0)
                 ,NVL(x_ln_total1_get_err,0) + NVL(x_ln_total1_get_upd,0)
                 ,x_line_document
                 ,x_line_document1
                 );
                 
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                           ***** End of Report - OD: PO RetroactivePriceUpdate *****');
    
    COMMIT ;
    
    EXCEPTION
        WHEN OTHERS THEN
        x_errbuf  := 'Error in MAIN_PROC. '||SUBSTR(SQLERRM,1,255);
        x_retcode := 2;
    END MAIN_PROC;
END XX_PO_RETACTPRCUPD_PKG;
/

SHOW ERRORS;

EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================