SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_IBY_DEPOSIT_DTLS_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE


CREATE OR REPLACE PACKAGE BODY XX_IBY_DEPOSIT_DTLS_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :        Line Level 3 Detail for Deposits                    |
-- | RICE ID :     E1325                                               |
-- | Description : To get the sku level details from the AOPS system   |
-- |               for every AOPS order number stored in oracle        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========    =============       =======================|
-- |1.0       05-JUL-2007   Anusha Ramanujam    Initial version        |
-- |1.1       05-OCT-2007   Rama Krishna K      log files and warning  |
-- |                                            for defect 2347        |
-- |1.2       31-JAN-2008   SubbaRao B          Fixed the Defect 3819  |
-- |                                            Added UOM Column       |
-- |1.3       10-Apr-2008   SubbaRao B          Fix for the defect 5462|
-- |                                                                   |
-- |1.4       17-Oct-2008   Anitha D           Fix for the defect 11555|
-- |                                                                   |
-- |1.5       07-Jul-2009   Anitha D           Fix for the defect 552  |
-- |                                                                   |
-- |1.6       24-Sep-2009   Ganesan JV         Fix for the defect 2447
-- |                                                                   |
-- |1.7       07-Oct-2009   Usha R             Fix for the defect 1844 |
-- |1.8       18-Jun-2010   Sundaram S         Fix for defect 6232     |
-- |1.9       30-Oct-2015   Rakesh Polepalli   Fix for defect 36094    |
-- +===================================================================+
    lc_error_loc      VARCHAR2(2000);
    lc_error_debug    VARCHAR2(250);
    lc_err_msg        VARCHAR2(250);
-- +===================================================================+
-- | Name : DETAIL                                                     |
-- | Description : It fetches order deposit details from AOPS system   |
-- |               and inserts the details into the new custom table   |
-- |               XX_IBY_DEPOSIT_AOPS_ORDER_DTLS for every AOPS order |
-- |               number in the XX_IBY_DEPOSIT_AOPS_ORDERS table.     |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE DETAIL(
                     x_error_buff        OUT VARCHAR2
                     ,x_ret_code         OUT NUMBER )
--                     ,lc_link             IN  VARCHAR2) -- Commented since it can be handled in exception for Defect 2447
    AS
      lc_description      mtl_system_items_b.description%TYPE;
      lc_sku_uom          mtl_system_items_b.primary_uom_code%TYPE; -- Added for the Defect 3819
      lc_status           VARCHAR2(1);
      lc_err_flag         VARCHAR2(1);
      lc_exists           VARCHAR2(1);
      ln_count            NUMBER := 0 ;
	  dup_count           NUMBER := 0 ;  --Added for defect# 36094
      ln_discount_amount  xx_iby_deposit_aops_order_dtls.ws_discount_amount%TYPE;
 -- Added for Defect 2447
      TYPE c_ref IS REF CURSOR;                            -- Added for Defect 2447
      resource_unavailable EXCEPTION;                       -- Added for Defect 2447
      PRAGMA EXCEPTION_INIT(resource_unavailable, -28545);-- -02019);  -- Added for Defect 2447
      ld_date       DATE;                                    -- Added for Defect 2447
      c_ref_csr_type      c_ref;                              -- Added for Defect 2447
      p_ord_nbr           xx_iby_deposit_aops_orders.aops_order_number%TYPE;  -- Added for Defect 2447
      p_ord_sub           xx_iby_deposit_aops_orders.aops_order_number%TYPE;  -- Added for Defect 2447
      lc_link              VARCHAR2(50);                       -- Added for Defect 2447
      TYPE c_ref_dis IS REF CURSOR;                             -- Added for Defect 2447
      c_ref_dis_csr_type  c_ref_dis;                             -- Added for Defect 2447
      p_odord             VARCHAR2(250);
      p_odsub             VARCHAR2(250);
      p_odseq             VARCHAR2(250);
      p_odqtor            VARCHAR2(250);
      p_odqboq            VARCHAR2(250); ----Added for defect 1844
      TYPE c_rec_type IS RECORD(
        odord             VARCHAR2(250)
       ,odsub#            VARCHAR2(250)
       ,ods#od            VARCHAR2(250)
       ,oddept            VARCHAR2(250)
       ,odskod            VARCHAR2(250)
       ,od$art            VARCHAR2(250)
       ,odqtor            VARCHAR2(250)
       ,odqboq            VARCHAR2(250)----Added for defect 1844
       ,vencode           VARCHAR2(250)
       ,odzip             VARCHAR2(250)
       ,odstate           VARCHAR2(250) --- Added for Defect# 6232
        );
      lr_c_rec_type         c_rec_type;
      CURSOR c_pick_order_numbers
      IS
      SELECT XIDAO.rowid
             ,XIDAO.aops_order_number
             ,XIDAO.receipt_number
             ,XIDAO.program_application_id
             ,XIDAO.program_id
             ,XIDAO.program_update_date
             ,XIDAO.process_flag
      FROM   xx_iby_deposit_aops_orders XIDAO
      WHERE  process_flag = 'New'; -- Added by Anitha for Defect 11555
--Commented for Defect 2447
/*      CURSOR c_order_details(p_ord_num IN VARCHAR2)
      IS
      SELECT  fco101p_order_nbr           odord
              ,fco101p_order_sub          odsub#
              ,fco101p_detail_seq         ods#od
              ,fco101p_department         oddept
              ,TRIM(fco101p_sku)          odskod 
              ,fco101p_sku_price          od$art
              ,fco101p_qty_ordered        odqtor
              ,TRIM(fco101p_vendor_code)  vencode -- Added for the Defect 3819
              ,fco100p_zip                odzip   -- Added for the defect 552
      FROM    racoondta.fco101p@as400.na.odcorp.net  r101p
              ,racoondta.fco100p@as400.na.odcorp.net r100p -- Added for the defect 552
      WHERE   r100p.FCO100P_ORDER_NBR = r101p.FCO101P_ORDER_NBR -- Added for the defect 552
      AND     r100p.FCO100P_ORDER_SUB = r101p.FCO101P_ORDER_SUB -- Added for the defect 552
      AND     fco101p_order_nbr = LTRIM(SUBSTR(p_ord_num,1,9),'0')
      AND     fco101p_order_sub = LTRIM(SUBSTR(p_ord_num,10,3),'0');*/
 -- Added for Defect 2447
      lc_csr_query       VARCHAR2(4000);
      lc_csr_dis_query   VARCHAR2(4000);
      lc_chk_query       VARCHAR2(4000);
      lc_primary_link    xx_fin_translatevalues.target_value1%TYPE;
      lc_secondary_link  xx_fin_translatevalues.target_value2%TYPE;
      TYPE c_dblink_check IS REF CURSOR;
      c_ref_dblink_chk_type  c_dblink_check;
    BEGIN
     -- Checking which dblink is up for defect 2447
     /*
     Getting the DBLinks from Translation XXOD_AS400_DB_LINK for defect 2447
     */
       lc_error_loc   := 'Getting primary and secondary dblinks';
       lc_error_debug := '';
      BEGIN
         SELECT xftv.target_value1,xftv.target_value2
           INTO lc_primary_link,lc_secondary_link
           FROM  xx_fin_translatedefinition xftd
                ,xx_fin_translatevalues xftv
          WHERE 1=1  
            AND xftd.TRANSLATION_NAME = 'XXOD_AS400_DB_LINK'
            AND xftd.translate_id = xftv.translate_id
            AND sysdate between xftd.START_DATE_ACTIVE and nvl(xftd.end_date_ACTIVE,sysdate+1)
            AND sysdate between xftv.start_date_active and nvl(xftd.end_date_ACTIVE,sysdate+1);
            FND_FILE.PUT_LINE(fnd_file.log,'lc_primary_link: ' || lc_primary_link);
            FND_FILE.PUT_LINE(fnd_file.log,'lc_secondary_link: ' || lc_secondary_link);
         EXCEPTION
          WHEN NO_DATA_FOUND THEN
             FND_FILE.PUT_LINE(fnd_file.log,'No Links are provided');
      END;
       lc_error_loc   := 'Checking the dblink';
       lc_error_debug := '';
       lc_link       := lc_primary_link;                        -- trying with primary dblink first
       lc_chk_query := 'SELECT SYSDATE FROM racoondta.fco101p@' || lc_primary_link || ' WHERE ROWNUM < 2'; -- query to test the primary link
       BEGIN
          OPEN c_ref_dblink_chk_type FOR lc_chk_query;
          LOOP
            FETCH c_ref_dblink_chk_type INTO ld_date;
            EXIT WHEN c_ref_dblink_chk_type%NOTFOUND;
          END LOOP;
       EXCEPTION
         WHEN RESOURCE_UNAVAILABLE THEN
           /* Checking for Secondary Link for defect 2447*/
           BEGIN
             lc_chk_query := 'SELECT SYSDATE FROM racoondta.fco101p@' || lc_secondary_link || ' WHERE ROWNUM < 2'; -- query to test the primary link
             OPEN c_ref_dblink_chk_type FOR lc_chk_query;
             LOOP
               FETCH c_ref_dblink_chk_type INTO ld_date;
               EXIT WHEN c_ref_dblink_chk_type%NOTFOUND;
             END LOOP;
           EXCEPTION 
             WHEN RESOURCE_UNAVAILABLE THEN
               /* Erroring out if secondary Link is not available for defect 2447*/
               FND_FILE.PUT_LINE(fnd_file.log,'AS400 Links are not available');
               x_ret_code := 2;
           END;
           lc_link := lc_secondary_link;
           FND_FILE.PUT_LINE(fnd_file.log,'AS400.NA.ODCORP.NET is unavailable');
           FND_FILE.PUT_LINE(fnd_file.log,'RESOURCE_UNAVAILABLE');
         WHEN OTHERS THEN
            lc_link := lc_secondary_link;
           FND_FILE.PUT_LINE(fnd_file.log,'AS400.NA.ODCORP.NET is unavailable');
           FND_FILE.PUT_LINE(fnd_file.log,'OTHERS');
       END;
       FND_FILE.PUT_LINE(fnd_file.log,'Trying to access: ' || lc_link);
       -- Updating the cursor variable for Defect 2447
      lc_csr_query   := ' SELECT  fco101p_order_nbr                  odord '
                      ||' ,fco101p_order_sub                    odsub# '
                      ||' ,fco101p_detail_seq                   ods#od '
                      ||' ,fco101p_department                   oddept '
                      ||' ,TRIM(fco101p_sku)                    odskod '
                      ||' ,fco101p_sku_price                    od$art '
                      ||' ,fco101p_qty_ordered                  odqtor '
                      ||' ,fco101p_qty_backorder                odqboq ' ---Added for defect 1844
                      ||' ,TRIM(fco101p_vendor_code)            vencode '
                      ||' ,fco100p_zip                          odzip '
                      ||' ,NVL(TRIM(fco100p_state), fco100p_province) odstate ' -- Added for Defect# 6232
                      ||' FROM    racoondta.fco101p@'||lc_link||' r101p '
                      ||'        ,racoondta.fco100p@'||lc_link||' r100p '
                      ||' WHERE   r100p.FCO100P_ORDER_NBR = r101p.FCO101P_ORDER_NBR '
                      ||' AND     r100p.FCO100P_ORDER_SUB = r101p.FCO101P_ORDER_SUB '
                      ||' AND     fco101p_order_nbr = :p_ord_nbr '
                      || 'AND     fco101p_order_sub = :p_ord_sub ';
      lc_csr_dis_query   := 'SELECT ABS(ROUND(NVL(SUM(CCO062F.CCO062F_DOLLAR_AMT/:p_odqtor),0),2)) '
                         ||' FROM   racoondta.cco062f@'||lc_link||' CCO062F '
                         ||' WHERE  CCO062F.cco062f_detail_seq > 0 '
                         ||' AND    CCO062F.cco062f_dsc_type = ''CD'' '
                         ||' AND    CCO062F.cco062f_detail_seq = :p_odseq '
                         ||' AND    CCO062F.cco062f_order_sub  = :p_odsub '
                         ||' AND    CCO062F.cco062f_order_nbr  = :p_odord ';
     --Getting the Concurrent Program Name
       lc_error_loc   := 'Getting the Concurrent Program Name';
       lc_error_debug := '';

       SELECT FCPT.user_concurrent_program_name
       INTO   gc_concurrent_program_name
       FROM   fnd_concurrent_programs_tl FCPT
       WHERE  FCPT.concurrent_program_id = fnd_global.conc_program_id
       AND    FCPT.language = USERENV('LANG');
     --Printing the failed records in output file
       lc_error_loc   := 'Printing the Records that were not inserted into the dtls table';
       lc_error_debug := '';
       FND_FILE.PUT_LINE(fnd_file.output,'');
       FND_FILE.PUT_LINE(fnd_file.output,'                             OD: Line Level 3 Detail for Deposits Program                    ');
       FND_FILE.PUT_LINE(fnd_file.output,'                             --------------------------------------------                    ');
       FND_FILE.PUT_LINE(fnd_file.output,'');
       FND_FILE.PUT_LINE(fnd_file.output,'************************************Records that failed insertion****************************');
       FND_FILE.PUT_LINE(fnd_file.output,'');
       FND_FILE.PUT_LINE(fnd_file.output,RPAD('AOPS Order Number',35,' ')
                                       ||RPAD('SKU/Item No.',25,' ')
                                       ||'Reason for failure');
       FND_FILE.PUT_LINE(fnd_file.output,RPAD('-----------------',35,' ')
                                       ||RPAD('------------',25,' ')
                                       ||'------------------');
     --Opening the outer cursor loop
       lc_error_loc := 'Opening the cursor loop';
       lc_error_debug := '';
       FOR lcu_pick_order_numbers_rec IN c_pick_order_numbers
       LOOP
           --Resetting the error flag
             lc_err_flag := 'N';
             lc_exists   := 'N';
       -- Added for Defect 2447
             p_ord_nbr  := LTRIM(SUBSTR(lcu_pick_order_numbers_rec.aops_order_number,1,9),'0');
             p_ord_sub  := LTRIM(SUBSTR(lcu_pick_order_numbers_rec.aops_order_number,10,3),'0');
             lc_error_loc := 'Querying for the order details from AOPS';
             lc_error_debug := 'aops_order_number: '||lcu_pick_order_numbers_rec.aops_order_number;
             FND_FILE.PUT_LINE(fnd_file.log,'');
             FND_FILE.PUT_LINE(fnd_file.log,'Querying the order details for '||lcu_pick_order_numbers_rec.aops_order_number);
            -- Commented for Defect 2447
            -- FOR lcu_order_details IN c_order_details(lcu_pick_order_numbers_rec.aops_order_number)
            -- Added for Defect 2447 -- Starting
             OPEN c_ref_csr_type FOR lc_csr_query USING p_ord_nbr,p_ord_sub;
                   
             LOOP
                FETCH c_ref_csr_type INTO lr_c_rec_type;
                EXIT WHEN c_ref_csr_type%NOTFOUND;
          -- Added for Defect 2447 -- Ending
                BEGIN
                 --Resetting the status flag
                   lc_status := 'Y';
                   lc_exists := 'Y';
                   ln_discount_amount := 0 ; 
                 --Getting the Item description and UOM
                   BEGIN
                      -- Added for the defect 5462 -- START
                      lc_error_loc := 'Getting the discount amount description ';
                    -- Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                    --  lc_error_debug := 'fco101p_sku: '||lcu_order_details.odskod;
                      lc_error_debug := 'fco101p_sku: '||lr_c_rec_type.odskod; --Added for defect 2447
                      p_odqtor := lr_c_rec_type.odqtor;
                      p_odord  := lr_c_rec_type.odord;
                      p_odsub  := lr_c_rec_type.odsub#;
                      p_odseq  := lr_c_rec_type.ods#od;
                      p_odqboq := lr_c_rec_type.odqboq; -- Added for defect 1844
                     -- Added for the defect 5462 -- Discount per Unit
                    -- Commented for Defect 2447
                     /*    SELECT ABS(ROUND(NVL(SUM(CCO062F.CCO062F_DOLLAR_AMT/lr_c_rec_type.odqtor),0),2))
                         INTO   ln_discount_amount
                         FROM   racoondta.cco062f@as400.na.odcorp.net CCO062F
                         WHERE  CCO062F.cco062f_detail_seq > 0
                         AND    CCO062F.cco062f_dsc_type = 'CD'
                         AND    CCO062F.cco062f_detail_seq = lr_c_rec_type.ods#od
                         AND    CCO062F.cco062f_order_sub  = lr_c_rec_type.odsub#
                         AND    CCO062F.cco062f_order_nbr  = lr_c_rec_type.odord;*/

                         ---Added if condition for defect 1844
                      IF (p_odqtor=0) AND (p_odqboq=0) THEN
                         ln_discount_amount :=0;
                      ELSE
                         IF(p_odqtor=0) THEN
                            p_odqtor := lr_c_rec_type.odqboq;
                         END IF;
                    -- Added for Defect 2447 -- Starting
                         OPEN c_ref_dis_csr_type FOR lc_csr_dis_query USING p_odqtor,p_odseq,p_odsub,p_odord;
                         LOOP
                            FETCH c_ref_dis_csr_type INTO ln_discount_amount;
                            EXIT WHEN c_ref_dis_csr_type%NOTFOUND;
                         END LOOP;
                      END IF;
                    -- Added for Defect 2447 -- Ending
                       FND_FILE.PUT_LINE(fnd_file.log,' Discount amount for the Item : '||ln_discount_amount
                                                         ||' -  '||' UOM : ' ||lc_sku_uom);
                     -- Added for the defect 5462 -- END
                      lc_error_loc := 'Getting the item description ';
                    -- Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                      lc_error_debug := 'fco101p_sku: '||lr_c_rec_type.odskod;
                    -- Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                      FND_FILE.PUT_LINE(fnd_file.log,'Getting the decription for the Item '||lr_c_rec_type.odskod);
                      SELECT MSI.description
                            ,MSI.primary_uom_code
                      INTO   lc_description
                            ,lc_sku_uom  -- Added for the Defect 3819
                      FROM   mtl_system_items_b MSI
                            ,mtl_parameters  MP
                    --WHERE  segment1 = TRIM(lcu_order_details.odskod)  -- Commented for the Defect 3819
                    -- Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                      WHERE  segment1 = NVL2(lr_c_rec_type.vencode
                                            ,lr_c_rec_type.odskod
                                            ,LTRIM(lr_c_rec_type.odskod,'0')
                                            )
                      AND    MSI.organization_id = MP.master_organization_id
                      AND    MP.organization_id  = MP.master_organization_id;
                      FND_FILE.PUT_LINE(fnd_file.log,' Decription for the Item : '||lc_description
                                                      ||' -  '||' UOM : ' ||lc_sku_uom);
                   EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                         lc_description := '';
                         FND_MESSAGE.SET_NAME('XXFIN','XX_IBY_0003_NO_ITM');
                         lc_err_msg := FND_MESSAGE.GET;
                         FND_FILE.PUT_LINE(fnd_file.log, 'Error - '||lc_err_msg);
                         XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                             p_program_type            => 'CONCURRENT PROGRAM'
                            ,p_program_name            => gc_concurrent_program_name
                            ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                            ,p_module_name             => 'IBY'
                            ,p_error_location          => 'Error at ' ||lc_error_loc
                            ,p_error_message_count     => 1
                            ,p_error_message_code      => 'E'
                            ,p_error_message           => lc_err_msg
                            ,p_error_message_severity  => 'Major'
                            ,p_notify_flag             => 'N'
                            ,p_object_type             => 'Line Level 3 Detail'
                            ,p_object_id               => lc_error_debug
                         );
                   END;
                -- Inserting the order details into the custom table
                   lc_error_loc := 'Inserting values into the Custom Table';
               -- Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                   lc_error_debug := 'fco101p_order_nbr: '||lr_c_rec_type.odord||' '||'fco101p_detail_seq: '||lr_c_rec_type.ods#od;
                   FND_FILE.PUT_LINE(fnd_file.log,'Inserting values into Custom Table for fco101p_order_nbr: '
                                                  ||lr_c_rec_type.odord||' '||'fco101p_detail_seq: '||lr_c_rec_type.ods#od);
				--Added for defect# 36094
				--Added Begin block to get duplicate record count
				  BEGIN
					lc_error_loc := 'Checking for duplicate records';
					
					dup_count := 0;
					select count(1) into dup_count
					from xx_iby_deposit_aops_order_dtls
					where aops_order_number = lcu_pick_order_numbers_rec.aops_order_number
					and receipt_number = lcu_pick_order_numbers_rec.receipt_number
					and ws_seq_number = lr_c_rec_type.ods#od;
					
					EXCEPTION
					WHEN OTHERS THEN
					FND_FILE.PUT_LINE(fnd_file.log, 'AOPS Order Number = '|| lcu_pick_order_numbers_rec.aops_order_number
							|| ' - ' || 'Error : '||lc_err_msg);
				  END;
					
				  IF (dup_count = 0)		--Added for defect# 36094
				  THEN 
						INSERT INTO xx_iby_deposit_aops_order_dtls
                                    (
                                    aops_order_number
                                   ,receipt_number
                                   ,ws_seq_number
                                   ,ws_merch_dept
                                   ,ws_sku
                                   ,ws_price_retail
                                   ,ws_sku_qty
                                   ,ws_sku_desc
                                   ,ws_sku_uom -- Added for the Defect 3819
                                   ,creation_date
                                   ,created_by
                                   ,last_update_date
                                   ,last_updated_by
                                   ,last_update_login
                                   ,program_application_id
                                   ,program_id
                                   ,program_update_date
                                   ,ws_discount_amount   -- Added for the defect 5462
                                   ,attribute1           -- Added for the defect 552
                                   ,attribute2           -- Added for defect 6232
                                    )
                                VALUES
                                   (
                                    lcu_pick_order_numbers_rec.aops_order_number
                                   ,lcu_pick_order_numbers_rec.receipt_number
                                   ,lr_c_rec_type.ods#od --Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                                   ,lr_c_rec_type.oddept --Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                                   ,TRIM(lr_c_rec_type.odskod) --Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                                   ,lr_c_rec_type.od$art --Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                                   ,lr_c_rec_type.odqtor --Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                                   ,lc_description
                                   ,lc_sku_uom -- Added for the Defect 3819
                                   ,SYSDATE
                                   ,FND_GLOBAL.USER_ID
                                   ,SYSDATE
                                   ,FND_GLOBAL.USER_ID
                                   ,FND_GLOBAL.LOGIN_ID
                                   ,lcu_pick_order_numbers_rec.program_application_id
                                   ,lcu_pick_order_numbers_rec.program_id
                                   ,lcu_pick_order_numbers_rec.program_update_date
                                   ,ln_discount_amount       -- Added for the defect 5462
                                   ,lr_c_rec_type.odzip      --Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                                   ,lr_c_rec_type.odstate    -- Added for defect 6232
                                   );
				  END IF;
				EXCEPTION
                   WHEN OTHERS THEN
                      lc_status := 'N';
                      FND_MESSAGE.SET_NAME('XXFIN','XX_IBY_0001_ERR');
                      FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
                      FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
                      FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
                      lc_err_msg := FND_MESSAGE.GET;
                      x_ret_code := 1;
                      FND_FILE.PUT_LINE(fnd_file.log, 'Error : '||lc_err_msg);
                      FND_FILE.PUT_LINE(fnd_file.output,RPAD(NVL(lcu_pick_order_numbers_rec.aops_order_number,' '),35, ' ')
                             -- Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                                                      ||RPAD(NVL(lr_c_rec_type.odskod,' '),25, ' ')
                                                      ||lc_err_msg);
                      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                          p_program_type            => 'CONCURRENT PROGRAM'
                         ,p_program_name            => gc_concurrent_program_name
                         ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                         ,p_module_name             => 'IBY'
                         ,p_error_location          => 'Error at ' || lc_error_loc
                         ,p_error_message_count     => 1
                         ,p_error_message_code      => 'E'
                         ,p_error_message           => lc_err_msg
                         ,p_error_message_severity  => 'Major'
                         ,p_notify_flag             => 'N'
                         ,p_object_type             => 'Line Level 3 Detail'
                         ,p_object_id               => lc_error_debug
                      );
                END;
             -- Setting the error flag to Y whenever error occurs and insert fails
                IF (lc_status = 'N') THEN
                   lc_err_flag := 'Y';
                END IF;
             END LOOP;
          -- Deleting the original record from the table for those which were succesfully inserted
             IF ( lc_exists = 'Y'
                 AND lc_err_flag = 'N' ) THEN
                lc_error_loc   := 'Updating the record from the order table';
                lc_error_debug := 'aops_order_number: '||lcu_pick_order_numbers_rec.aops_order_number;
--  Commented by Anitha for Defect 11555
/*                DELETE FROM xx_iby_deposit_aops_orders
                WHERE  aops_order_number = lcu_pick_order_numbers_rec.aops_order_number;*/
--  Added by Anitha for Defect 11555
                UPDATE xx_iby_deposit_aops_orders
                SET process_flag = 'Complete'
                WHERE  rowid = lcu_pick_order_numbers_rec.rowid;
                FND_FILE.PUT_LINE(fnd_file.log,'Updated the original record for '||lcu_pick_order_numbers_rec.aops_order_number);
                FND_FILE.PUT_LINE(fnd_file.log,'');
             END IF;
             IF ( lc_exists = 'N') THEN
             -- Addressed Defect 2347 for proper logging messages if record not found in AS400 system
             FND_FILE.PUT_LINE(fnd_file.log,'Order Number not Found in the AS400 System' );
             FND_FILE.PUT_LINE(fnd_file.output,'');
             FND_FILE.PUT_LINE(fnd_file.output,RPAD(lcu_pick_order_numbers_rec.aops_order_number,35,' ')
                                                || RPAD(' ',25,' ')
                                                || 'Order Number not Found in the AS400 System' );
             x_ret_code := 1;
             -- Addition for defect 2347 ends here
             END IF;
             ln_count := ln_count + 1;
             IF (ln_count = 500) THEN
                COMMIT;
                ln_count := 0;
             END IF;
       END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
                FND_MESSAGE.SET_NAME('XXFIN','XX_IBY_0001_ERR');
                FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
                FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
                FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
                lc_err_msg := FND_MESSAGE.GET;
                FND_FILE.PUT_LINE(fnd_file.log, 'Error- '||lc_err_msg);
                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                    p_program_type            => 'CONCURRENT PROGRAM'
                   ,p_program_name            => gc_concurrent_program_name
                   ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                   ,p_module_name             => 'IBY'
                   ,p_error_location          => 'Error at ' || lc_error_loc
                   ,p_error_message_count     => 1
                   ,p_error_message_code      => 'E'
                   ,p_error_message           => lc_err_msg
                   ,p_error_message_severity  => 'Major'
                   ,p_notify_flag             => 'N'
                   ,p_object_type             => 'Line Level 3 Detail'
                );
                x_ret_code := 2;
    END DETAIL;
END XX_IBY_DEPOSIT_DTLS_PKG;
/
SHOW ERROR
