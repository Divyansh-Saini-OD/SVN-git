create or replace 
PACKAGE BODY      XX_AP_INV_TERMS_PKG
AS
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name :  E1281                                                            |
-- | Description : TO extend the Oracle validation process to                 |
-- |               automatically assign the receipt date to the invoice       |
-- |               terms date when the invoice and PO match takes place       |
-- |               If no receipt exists the invoice should be placed on       |
-- |               'OD No Receipt Hold'                                       |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date              Author              Remarks                   |
-- |======   ==========     =============        =======================      |
-- |1.0       01-JUN-2007   Chaitanya Nath.G      Initial version             |
-- |                        Wipro Technologies                                |
-- |1.1       13-sep-2007   Chaitanya Nath.G      To fix defect 2004          |
-- |1.2       19-sep-2007   Chaitanya Nath.G      To fix defect 2053          |
-- |1.3       10-OCT-2007   Chaitanya Nath.G      To fix defect 2053          |
-- |1.4       22-OCT-2007   Sandeep Pandhare      To fix defect 2053          |
-- |1.5       14-FEB-2008   Greg Dill             To fix defect 3845          |
-- |1.6       02-AUG-2010   Peter Marco           CR-729 TDM Invoice          |  
-- |                                              Build - Report corrections  |
-- |                                              and Ability to manage In-   |
-- |                                              voices w/issue              |
-- |1.7       3-JUN-2013    Shruthi Vasisht       Modified for R12 Upgrade    |
-- |                                              retrofit                    |
-- |1.8       17-MAR-2013   Jay Gupta           Defect# 28912 - performance   |
-- |1.9       07-AUG-2014   N.Pradhan           Defect# 30798                 |
-- +==========================================================================+



-- +==========================================================================+
-- | Name : INV_TERMS_DATE                                                    |
-- | Description :  To populate the terms date of the invoice in the table    |
-- |                XX_AP_INV_INTERFACE with the receipt date and if more     |
-- |                than one receipt exists then terms date will be populted  |
-- |                with the latest of all the receipt dates.                 |
-- |                                                                          |
-- | Parameters : p_invoice_num,p_po_number,p_invoice_date ,p_vendor_id       |
-- |                                                                          |
-- |                                                                          |
-- +==========================================================================+

   PROCEDURE INV_TERMS_DATE(
      p_invoice_num    IN VARCHAR2
     ,p_po_number      IN po_headers.SEGMENT1%TYPE --defect 3845
     ,P_INVOICE_DATE   IN OUT DATE  -- defect 2053
     ,P_DATE_GOODS_REC OUT DATE     -- Added per CR729
     ,P_RELEASE_NUM    IN  NUMBER   -- Added per CR729
     ,p_vendor_id      IN  NUMBER
      )
   AS
      lc_concurrent_program_name    fnd_concurrent_programs_vl.user_concurrent_program_name%TYPE;
      lc_terms_date_basis           po_vendor_sites.terms_date_basis%TYPE;
      ld_transaction_date           rcv_transactions.transaction_date%TYPE;
      lc_po_number                  xx_ap_inv_interface_stg.po_number%TYPE;
      lc_match_level                VARCHAR2(1):='N';
      lc_error_loc                  VARCHAR2(2000);
      lc_error_debug                VARCHAR2(2000);
      lc_loc_err_msg                VARCHAR2(2000);

      CURSOR  C_INV_TERMS_DATE(
               p_po_number NUMBER, p_release NUMBER
      )IS
      --------------------------------------------
      -- Removed cursor code per CR729
      --------------------------------------------
      --   SELECT     PLL.inspection_required_flag
      --             ,PLL.receipt_required_flag
      --   FROM       po_headers PH
      --             ,po_line_locations PLL
      --   WHERE      PLL.PO_HEADER_ID = PH.PO_HEADER_ID
      --   AND        PH.SEGMENT1 = P_PO_NUMBER ;

     --------------------------------------------------------
     -- CR729 Added view to cursor below to handle release PO 
     --------------------------------------------------------
     SELECT     POLL.INSPECTION_REQUIRED_FLAG
               ,POLL.receipt_required_flag
       /*V1.8     FROM  APPS.PO_LINE_LOCATIONS_INQ_V POLL
           WHERE  POLL.PO_NUM = P_PO_NUMBER    
             AND (POLL.RELEASE_NUM = P_RELEASE
                OR POLL.RELEASE_NUM IS NULL);
      */
      		--V1.8, Added tables instead of view
		FROM PO_LINE_LOCATIONS PoLL,
   			PO_HEADERS poh,
  			PO_RELEASES POR
		WHERE poll.po_header_id = poh.po_header_id
		-- AND por.po_header_id   = poh.po_header_id    -- 30798 
		AND por.po_header_id   (+)= poll.po_header_id   -- 30798
		AND poll.po_release_id  = por.po_release_id(+)
		AND Poh.segment1       = P_PO_NUMBER
		AND (POR.RELEASE_NUM   = P_RELEASE
		OR POR.RELEASE_NUM    IS NULL);                    
             
             
      BEGIN
         --Printing the Parameters
         lc_error_loc   := 'Printing the Parameters of the program';
         lc_error_debug := '';

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameters');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'----------');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Invoice Num: ' ||p_invoice_num);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'PO Number: '   ||p_po_number);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Invoice Date: '||p_invoice_date);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Vendor id: '   ||p_vendor_id);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'----------');

         BEGIN
            -- To Get the Concurrent Program Name
            lc_error_loc   := 'Get the Concurrent Program Name:';
            lc_error_debug := 'Concurrent Program id: '||FND_GLOBAL.CONC_PROGRAM_ID;

            SELECT   user_concurrent_program_name
            INTO     lc_concurrent_program_name
            FROM     fnd_concurrent_programs_vl
            WHERE    concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID;

         EXCEPTION
         WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('XXFIN',' XX_AP_0001_ERROR');
            FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
            FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
            FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
            lc_loc_err_msg :=  FND_MESSAGE.GET;
            FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
               p_program_type            => 'CONCURRENT PROGRAM'
              ,p_program_name            => 'XX_AP_INV_TERMS_PKG.INV_TERMS_DATE'
              ,p_module_name             => 'AP'
              ,p_error_location          => 'Error at ' || SUBSTR(lc_error_loc,1,50)
              ,p_error_message_count     => 1
              ,p_error_message_code      => 'E'
              ,p_error_message           => lc_loc_err_msg
              ,p_error_message_severity  => 'Major'
              ,p_notify_flag             => 'N'
              ,p_object_type             => 'Updating the Terms Date'
            );
         END;

         FOR lcu_inv_terms_date IN c_inv_terms_date ( p_po_number,P_RELEASE_NUM )

         LOOP
          -- Checking for 3-way match level
            IF( NVL(lcu_inv_terms_date.inspection_required_flag,'N')='N'
               AND lcu_inv_terms_date.receipt_required_flag = 'Y') THEN

               LC_MATCH_LEVEL :='Y' ;
               FND_FILE.PUT_LINE(FND_FILE.LOG,'xx_ap_inv_terms: Match Level=Y');
            END IF;

        END LOOP;
        
        
        



        IF (p_po_number IS NOT NULL
            AND p_vendor_id IS NOT NULL) THEN

            BEGIN
               -- To Get the Terms Date Basis
               lc_error_loc   := 'To  Get the  Terms Date Basis at supplier site level.';
               lc_error_debug := ' Purchse order number : '||p_po_number ||
                                 'VENDOR ID :'||p_vendor_id;

               SELECT   ASSA.terms_date_basis
               INTO     lc_terms_date_basis
               --  commented and added by shruthi for R12 Upgrade Retrofit
               --FROM     po_vendor_sites PVS
                 FROM     ap_supplier_sites_all ASSA
               -- end of addition
                       ,po_headers PH
               WHERE    ASSA.vendor_site_id = PH.vendor_site_id
               AND      ASSA.vendor_id = p_vendor_id
               AND      PH.segment1 = p_po_number;

               FND_FILE.PUT_LINE(FND_FILE.LOG,
                    'xx_ap_inv_terms: Terms Date Basis'|| lc_terms_date_basis);

            EXCEPTION

            WHEN NO_DATA_FOUND THEN
               FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERROR ');
               FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
               FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
               FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
               lc_loc_err_msg :=  FND_MESSAGE.GET;
               FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);

               XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                  p_program_type            => 'CONCURRENT PROGRAM'
                 ,p_program_name            => lc_concurrent_program_name
                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                 ,p_module_name             => 'AP'
                 ,p_error_location          => 'Error at ' || SUBSTR(lc_error_loc,1,50)
                 ,p_error_message_count     => 1
                 ,p_error_message_code      => 'E'
                 ,p_error_message           => lc_loc_err_msg
                 ,p_error_message_severity  => 'Major'
                 ,p_notify_flag             => 'N'
                 ,p_object_type             => 'Updating the Terms Date'
                 );

            WHEN OTHERS THEN
               FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERROR ');
               FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
               FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
               FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
               lc_loc_err_msg :=  FND_MESSAGE.GET;
               FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);

               XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                  p_program_type            => 'CONCURRENT PROGRAM'
                 ,p_program_name            => lc_concurrent_program_name
                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                 ,p_module_name             => 'AP'
                 ,p_error_location          => 'Error at ' || SUBSTR(lc_error_loc,1,50)
                 ,p_error_message_count     => 1
                 ,p_error_message_code      => 'E'
                 ,p_error_message           => lc_loc_err_msg
                 ,p_error_message_severity  => 'Major'
                 ,p_notify_flag             => 'N'
                 ,p_object_type             => 'Updating the Terms Date'
                 );
            END;

            lc_error_loc   := ' Checking the Terms Date Basis  at supplier site';
            lc_error_debug := ' Goods Received ';

            IF (UPPER(LC_TERMS_DATE_BASIS) ='GOODS RECEIVED') 
                OR (UPPER(LC_TERMS_DATE_BASIS) ='INVOICE')  THEN   --Added perCR729 
                     
               -- To get the latest receipt date.
               BEGIN
                  lc_error_loc   := ' Get the latest receipt date ';
                  lc_error_debug := ' Purchase order number  : '||p_po_number;

                  SELECT   MAX(RT.transaction_date)
                  INTO     ld_transaction_date
                  FROM     rcv_transactions RT
                          ,po_headers PH
                          ,po_line_locations PLL
                  WHERE    RT.transaction_type='DELIVER'
                  AND      NVL(PLL.inspection_required_flag,'N')='N'
                  AND      PLL.receipt_required_flag = 'Y'
                --AND      PLL.match_option = 'R'   -- Changed as per the Defect ID: 2053
                  AND      RT.po_header_id= PH.po_header_id
                  AND      RT.po_line_location_id= PLL.line_location_id
                  AND      PH.segment1 = p_po_number;

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'xx_ap_inv_terms: Transaction Date'
                                          || ld_transaction_date);

               EXCEPTION
               WHEN OTHERS THEN
                  FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERROR ');
                  FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
                  FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
                  FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
                  lc_loc_err_msg :=  FND_MESSAGE.GET;
                  FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);

                  XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => lc_concurrent_program_name
                    ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                    ,p_module_name             => 'AP'
                    ,p_error_location          => 'Error at ' || SUBSTR(lc_error_loc,1,50)
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => lc_loc_err_msg
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'Updating the Terms Date'
                    );
               END;
               -----------------
               --3-way match
               ------------------
               IF (LC_MATCH_LEVEL = 'Y') THEN
                   IF (UPPER(LC_TERMS_DATE_BASIS) ='GOODS RECEIVED')  THEN    
                         IF (ld_transaction_date IS NOT NULL ) THEN    
                                P_INVOICE_DATE    :=  LD_TRANSACTION_DATE;
                                P_DATE_GOODS_REC  :=  LD_TRANSACTION_DATE; --Added CR729
                         ELSE  
                                --------------------
                                -- No receipt found
                                --------------------
                                FND_FILE.PUT_LINE(FND_FILE.LOG,
                                'xx_ap_inv_terms: No Receipt Date available. ');
                                
                                P_INVOICE_DATE := NVL((P_INVOICE_DATE),SYSDATE);
                         END IF;  
                   --------------------------------------           
                   -- terms_date_basis = INVOICE
                   --------------------------------------
                   ELSE
                       P_INVOICE_DATE := NVL((P_INVOICE_DATE),SYSDATE);
                       P_DATE_GOODS_REC := LD_TRANSACTION_DATE; --Added CR729

                   END IF;                                    
              -----------------
              --2-way match 
              ------------------
              ELSE
                 P_INVOICE_DATE := NVL((P_INVOICE_DATE),SYSDATE);
                 P_DATE_GOODS_REC  := P_INVOICE_DATE;       --Added CR729
       
              END IF;                                                              

            ELSE
               FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0005_VALIDATIONS_FAIL');
               lc_loc_err_msg :=  FND_MESSAGE.GET;
               FND_FILE.PUT_LINE(FND_FILE.LOG,LC_LOC_ERR_MSG);
               P_INVOICE_DATE := NVL((P_INVOICE_DATE),SYSDATE);
               P_DATE_GOODS_REC  := P_INVOICE_DATE;            --Added CR729                            
               
            END IF;
              
       ELSE

           FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0004_PO_NUM_VEND_ID_NULL');
           LC_LOC_ERR_MSG :=  FND_MESSAGE.GET;
           FND_FILE.PUT_LINE(FND_FILE.LOG,LC_LOC_ERR_MSG);
            
        END IF;

      EXCEPTION
      WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERROR ');
      FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
      FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
      FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
      lc_loc_err_msg :=  FND_MESSAGE.GET;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);

      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
         p_program_type            => 'CONCURRENT PROGRAM'
        ,p_program_name            => lc_concurrent_program_name
        ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
        ,p_module_name             => 'AP'
        ,p_error_location          => 'Error at ' || SUBSTR(lc_error_loc,1,50)
        ,p_error_message_count     => 1
        ,p_error_message_code      => 'E'
        ,p_error_message           => lc_loc_err_msg
        ,p_error_message_severity  => 'Major'
        ,p_notify_flag             => 'N'
        ,p_object_type             => 'Updating the Terms Date'
        );

   END INV_TERMS_DATE;


-- +==========================================================================+
-- | Name : INV_HOLD                                                          |
-- | Description :  To keep the invocies without the receipt on 'OD No Receipt|
-- |                 Hold' and update the global_attribute2  column in the    |
-- |                table  xx_ap_inv_interface_stg with 'H'                   |
-- |                                                                          |
-- | Parameters : p_batch_id,p_source,p_group_id,p_hold_name                  |
-- |                                                                          |
-- | Returns    :  x_error_buff,x_ret_code                                    |
-- +==========================================================================+

   PROCEDURE  INV_HOLD(
      x_error_buff       OUT  VARCHAR2
     ,x_ret_code         OUT  NUMBER
     ,p_batch_id         IN   VARCHAR2
     ,p_group_id         IN   VARCHAR2
     ,p_source           IN   VARCHAR2
     ,p_hold_name        IN   VARCHAR2
      )
   AS

      lcu_pick_hold_invoices       xx_ap_inv_interface_stg.invoice_id%TYPE;
      lc_hold_lookup_code          ap_hold_codes_v.hold_lookup_code%TYPE;
      lc_description               ap_hold_codes_v.description%TYPE;
      lc_concurrent_program_name   fnd_concurrent_programs_vl.user_concurrent_program_name%TYPE;
      lc_row_id                    VARCHAR2(1000);
      -- added by shruthi for R12 Upgrade Retrofit
      lc_hold_id                   VARCHAR2(1000);
      -- end of addition
      lc_error_loc                 VARCHAR2(2000);
      lc_error_debug               VARCHAR2(2000);
      lc_loc_err_msg               VARCHAR2(2000);
      lc_record_found              VARCHAR2(1):= 'N';

       -- To store the invoice id into the cursor

      CURSOR   c_pick_hold_invoices(
         p_batch_id   VARCHAR2
        ,p_group_id   VARCHAR2
        ,p_source     VARCHAR2
         )IS
         SELECT   AIA.invoice_id
                 ,AIA.invoice_num
        -- added by shruthi for R12 Upgrade Retrofit
                 , AIA.org_id
         -- end of addition
         FROM     ap_invoices AIA
                 ,xx_ap_inv_interface_stg XXA
         WHERE    XXA.batch_id = p_batch_id
         AND      XXA.group_id = NVL(p_group_id,XXA.group_id)
         AND      XXA.source   = NVL(p_source,XXA.source)
         AND      XXA.global_attribute2 = 'Y'
         AND      XXA.vendor_id = AIA.vendor_id
         AND      XXA.invoice_num = AIA.invoice_num;

   BEGIN

      --Printing the Parameters
        lc_error_loc   := 'Printing the Parameters of the program';
        lc_error_debug := '';

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameters');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'----------');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Batch id: ' ||p_batch_id);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Group id: ' ||p_group_id);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Source: '   ||p_source);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Hold Name: '||p_hold_name);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'----------');

         --To Get the  Concurrent Program Name
         lc_error_loc   := 'Get the Concurrent Program Name:';
         lc_error_debug := 'Concurrent Program id: '||fnd_global.conc_program_id;

            SELECT   user_concurrent_program_name
            INTO     lc_concurrent_program_name
            FROM     fnd_concurrent_programs_vl
            WHERE    concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID;

      BEGIN

         -- To Get the Hold Lookup Code
         SELECT   hold_lookup_code
                 ,description
         INTO     lc_hold_lookup_code
                 ,lc_description
         FROM     ap_hold_codes_v
         WHERE    hold_lookup_code = p_hold_name
         AND      NVL(inactive_date,SYSDATE+1)> SYSDATE;

      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0002_HOLD_NOT_DEFINED ');
         lc_loc_err_msg :=  FND_MESSAGE.GET;
         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);
      END;

      IF (lc_hold_lookup_code IS NOT NULL) THEN

            FOR lcu_pick_hold_invoices  IN c_pick_hold_invoices(p_batch_id
                                                               ,p_group_id
                                                               ,p_source)
            LOOP

               lc_record_found := 'Y';
               lc_error_loc := ' Putting the Hold on invoice ';
               lc_error_debug := 'Invoice id :'||lcu_pick_hold_invoices.invoice_id;

               BEGIN
            -- To put the invoice without receipt on OD No Receipt Hold
                  AP_HOLDS_PKG.INSERT_ROW(
                     x_rowid                   =>   lc_row_id
                     -- added by shruthi for R12 Upgrade Retrofit
                    ,x_hold_id                 =>   lc_hold_id
                    -- end of addition
                    ,x_invoice_id              =>   lcu_pick_hold_invoices.invoice_id
                    ,x_line_location_id        =>   NULL
                    ,x_hold_lookup_code        =>   lc_hold_lookup_code
                    ,x_last_update_date        =>   SYSDATE
                    ,x_last_updated_by         =>   FND_PROFILE.VALUE('USER_ID')
                    ,x_held_by                 =>   FND_PROFILE.VALUE('USER_ID')
                    ,x_hold_date               =>   SYSDATE
                    ,x_hold_reason             =>   lc_description
                    ,x_release_lookup_code     =>   NULL
                    ,x_release_reason          =>   NULL
                    ,x_status_flag             =>   NULL
                    ,x_last_update_login       =>   FND_PROFILE.VALUE('LOGIN_ID')
                    ,x_creation_date           =>   SYSDATE
                    ,x_created_by              =>   FND_PROFILE.VALUE('USER_ID')
                    ,x_responsibility_id       =>   FND_PROFILE.VALUE('USER_ID')
                    ,x_attribute1              =>   NULL
                    ,x_attribute2              =>   NULL
                    ,x_attribute3              =>   NULL
                    ,x_attribute4              =>   NULL
                    ,x_attribute5              =>   NULL
                    ,x_attribute6              =>   NULL
                    ,x_attribute7              =>   NULL
                    ,x_attribute8              =>   NULL
                    ,x_attribute9              =>   NULL
                    ,x_attribute10             =>   NULL
                    ,x_attribute11             =>   NULL
                    ,x_attribute12             =>   NULL
                    ,x_attribute13             =>   NULL
                    ,x_attribute14             =>   NULL
                    ,x_attribute15             =>   NULL
                    ,x_attribute_category      =>   NULL
                     -- added by shruthi for R12 Upgrade Retrofit
                    ,x_org_id                   =>  lcu_pick_hold_invoices.org_id
                     -- end of addition
                    ,x_calling_sequence        =>   NULL
                     );

               EXCEPTION

               WHEN OTHERS THEN
                  FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0001_ERROR ');
                  FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
                  FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
                  FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
                  lc_loc_err_msg :=  FND_MESSAGE.GET;
                  FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);

                  XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => lc_concurrent_program_name
                    ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                    ,p_module_name             => 'AP'
                    ,p_error_location          => 'Error at ' || SUBSTR(lc_error_loc,1,50)
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => lc_loc_err_msg
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'No Receipt Hold'
                     );
                END;
                   -- To update the global attribute2 column with 'H'
                  UPDATE  xx_ap_inv_interface_stg
                  SET     global_attribute2 = 'H'
                  WHERE   global_attribute2 = 'Y'
                  AND     invoice_id = lcu_pick_hold_invoices.invoice_id
                  AND     batch_id =   p_batch_id;

                  IF (SQL%ROWCOUNT <> 0) THEN   -- Added as per the defect id 2053

                     FND_MESSAGE.SET_NAME('XXFIN','XX_AP_0006_HOLD_UPDATE');
                     FND_MESSAGE.SET_TOKEN('INV_NUM',lcu_pick_hold_invoices.invoice_num);
                     FND_MESSAGE.SET_TOKEN('BATCH_ID',p_batch_id);
                     FND_MESSAGE.SET_TOKEN('GROUP_ID',p_group_id);
                     FND_MESSAGE.SET_TOKEN('SOURCE',p_source);
                     --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,FND_MESSAGE.GET);
                     FND_FILE.PUT_LINE(FND_FILE.LOG,FND_MESSAGE.GET);-- Changed as per the defect id 2004

                  ELSE

                     FND_MESSAGE.SET_NAME('XXFIN','XX_AP_00012_HOLD_NOT_APPLIED');
                     FND_MESSAGE.SET_TOKEN('INV_NUM',lcu_pick_hold_invoices.invoice_num);
                     FND_MESSAGE.SET_TOKEN('BATCH_ID',p_batch_id);
                     FND_MESSAGE.SET_TOKEN('GROUP_ID',p_group_id);
                     FND_MESSAGE.SET_TOKEN('SOURCE',p_source);
                     --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,FND_MESSAGE.GET);
                     FND_FILE.PUT_LINE(FND_FILE.LOG,FND_MESSAGE.GET);-- Changed as per the defect id 2004

                  END IF;

            END LOOP;

            IF (lc_record_found = 'N') THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,'');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'---------------------------------');
            FND_FILE.PUT_LINE(FND_FILE.LOG,('---------No Records Found--------'));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'---------------------------------');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'');

            END IF;

      END IF;

   -- To log error details into xx_com_error_log table
   EXCEPTION
   WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXFIN',' XX_AP_0001_ERROR');
      FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
      FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
      FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
      lc_loc_err_msg :=  FND_MESSAGE.GET;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);

      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
         p_program_type            => 'CONCURRENT PROGRAM'
        ,p_program_name            => lc_concurrent_program_name
        ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
        ,p_module_name             => 'AP'
        ,p_error_location          => 'Error at ' || SUBSTR(lc_error_loc,1,50)
        ,p_error_message_count     => 1
        ,p_error_message_code      => 'E'
        ,p_error_message           => lc_loc_err_msg
        ,p_error_message_severity  => 'Major'
        ,p_notify_flag             => 'N'
        ,p_object_type             => 'No Receipt Hold'
         ); 
   END INV_HOLD;

END  XX_AP_INV_TERMS_PKG; 
/