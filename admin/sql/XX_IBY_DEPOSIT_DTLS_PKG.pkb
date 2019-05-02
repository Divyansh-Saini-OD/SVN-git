SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT Creating Package Body XX_IBY_DEPOSIT_DTLS_PKG
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE
PACKAGE BODY XX_IBY_DEPOSIT_DTLS_PKG
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
  -- |2.0       30-Apr-2019   M K Pramod Kumar   Code changes to replace DB
  --              link with Web service for NAIT-92905|
  -- +===================================================================+
  lc_error_loc   VARCHAR2(2000);
  lc_error_debug VARCHAR2(250);
  lc_err_msg     VARCHAR2(250);
  -- +===================================================================+
  -- | Name : DETAIL                                                     |
  -- | Description : It fetches order deposit details from AOPS system   |
  -- |               and inserts the details into the new custom table   |
  -- |               XX_IBY_DEPOSIT_AOPS_ORDER_DTLS for every AOPS order |
  -- |               number in the XX_IBY_DEPOSIT_AOPS_ORDERS table.     |
  -- |                                                                   |
  -- +===================================================================+
PROCEDURE DETAIL(
    x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER )
  --                     ,lc_link             IN  VARCHAR2) -- Commented since it can be handled in exception for Defect 2447
AS
  lc_description mtl_system_items_b.description%TYPE;
  lc_sku_uom mtl_system_items_b.primary_uom_code%TYPE; -- Added for the Defect 3819
  lc_status   VARCHAR2(1);
  lc_err_flag VARCHAR2(1);
  lc_exists   VARCHAR2(1);
  ln_count    NUMBER := 0 ;
  dup_count   NUMBER := 0 ; --Added for defect# 36094
  ln_discount_amount xx_iby_deposit_aops_order_dtls.ws_discount_amount%TYPE;
  -- Added for Defect 2447
TYPE c_ref
IS
  REF
  CURSOR;                                                        -- Added for Defect 2447
    resource_unavailable EXCEPTION;                              -- Added for Defect 2447
    PRAGMA EXCEPTION_INIT(resource_unavailable, -28545);         -- -02019);  -- Added for Defect 2447
    ld_date DATE;                                                -- Added for Defect 2447
    c_ref_csr_type c_ref;                                        -- Added for Defect 2447
    p_ord_nbr xx_iby_deposit_aops_orders.aops_order_number%TYPE; -- Added for Defect 2447
    p_ord_sub xx_iby_deposit_aops_orders.aops_order_number%TYPE; -- Added for Defect 2447
    lc_link VARCHAR2(50);                                        -- Added for Defect 2447
  TYPE c_ref_dis
IS
  REF
  CURSOR;                         -- Added for Defect 2447
    c_ref_dis_csr_type c_ref_dis; -- Added for Defect 2447
    p_odord  VARCHAR2(250);
    p_odsub  VARCHAR2(250);
    p_odseq  VARCHAR2(250);
    p_odqtor VARCHAR2(250);
    p_odqboq VARCHAR2(250); ----Added for defect 1844
  TYPE c_rec_type
IS
  RECORD
  (
    odord  VARCHAR2(250) ,
    odsub# VARCHAR2(250) ,
    ods#od VARCHAR2(250) ,
    oddept VARCHAR2(250) ,
    odskod VARCHAR2(250) ,
    od$art VARCHAR2(250) ,
    odqtor VARCHAR2(250) ,
    odqboq VARCHAR2(250)----Added for defect 1844
    ,
    vencode VARCHAR2(250) ,
    odzip   VARCHAR2(250) ,
    odstate VARCHAR2(250) --- Added for Defect# 6232
  );
  lr_c_rec_type c_rec_type;
  CURSOR c_pick_order_numbers
  IS
    SELECT XIDAO.rowid ,
      XIDAO.aops_order_number ,
      XIDAO.receipt_number ,
      XIDAO.program_application_id ,
      XIDAO.program_id ,
      XIDAO.program_update_date ,
      XIDAO.process_flag
    FROM xx_iby_deposit_aops_orders XIDAO
    WHERE process_flag = 'New'
	--and aops_order_number in ('271348608001','408434160001')
	;
	 -- Added by Anitha for Defect 11555
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
  lc_csr_query     VARCHAR2(4000);
  lc_csr_dis_query VARCHAR2(4000);
  lc_chk_query     VARCHAR2(4000);
  lc_primary_link xx_fin_translatevalues.target_value1%TYPE;
  lc_secondary_link xx_fin_translatevalues.target_value2%TYPE;
TYPE c_dblink_check
IS
  REF
  CURSOR;
    c_ref_dblink_chk_type c_dblink_check;
    CURSOR get_service_params_cur
    IS
      SELECT XFTV.source_value1,
        XFTV.target_value1
      FROM xx_fin_translatedefinition XFTD ,
        xx_fin_translatevalues XFTV
      WHERE XFTD.translate_id   = XFTV.translate_id
      AND XFTD.translation_name = 'OD_AOPS_LINE_DEPOSITS_WS'
      AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
      AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
      AND XFTV.enabled_flag                                         = 'Y'
      AND XFTD.enabled_flag                                         = 'Y';
    lc_wallet_location xx_fin_translatevalues.target_value1%TYPE   := NULL;
    lc_wallet_password xx_fin_translatevalues.target_value2%TYPE   := NULL;
    lc_auth_service_user xx_fin_translatevalues.target_value2%TYPE := NULL;
    lc_auth_service_pwd xx_fin_translatevalues.target_value3%TYPE  := NULL;
    l_request UTL_HTTP.req;
    l_response UTL_HTTP.resp;
    lc_auth_service_url xx_fin_translatevalues.target_value1%TYPE      :=NULL;
    lc_auth_service_url_main xx_fin_translatevalues.target_value1%TYPE :=NULL;
    lc_auth_payload VARCHAR2(32000)                                    :='Get SKU Information for AOPS Order Number and Sub Order Number';
    lclob_buffer CLOB;
    lc_buffer     VARCHAR2(10000);
    lc_lineNumber VARCHAR2(60);
    lc_department VARCHAR2(60);
    lc_skuNumber  VARCHAR2(60);
    lc_price      NUMBER;
    lc_qtyOrdered NUMBER;
    lc_qtyBackOrd NUMBER;
    lc_vendorCode VARCHAR2(100);
    lc_shipZip    VARCHAR2(60);
    lc_shipState  VARCHAR2(60);
    lc_discount   NUMBER;
    lc_message    VARCHAR2(200);
    lc_code       VARCHAR2(30);
    lc_tranStatus VARCHAR2(30);
  BEGIN
    /*************************
    * Get wallet information
    **************************/
    BEGIN
      SELECT vals.target_value1,
        vals.target_value2
      INTO lc_wallet_location,
        lc_wallet_password
      FROM xx_fin_translatevalues vals,
        xx_fin_translatedefinition defn
      WHERE defn.translation_name = 'XX_FIN_IREC_TOKEN_PARAMS'
      AND defn.translate_id       = vals.translate_id
      AND vals.source_value1      = 'WALLET_LOCATION'
      AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
      AND SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
      AND vals.enabled_flag = 'Y'
      AND defn.enabled_flag = 'Y';
    EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(fnd_file.log,'Error occured to derive the Wallet Information from Translation XX_FIN_IREC_TOKEN_PARAMS . SQLERRM: '||sqlerrm);
    END;
    /*************************
    * Get REST Web service information
    **************************/
    FOR get_service_params_rec IN get_service_params_cur
    LOOP
      IF get_service_params_rec.source_value1    = 'URL' THEN
        lc_auth_service_url                     := get_service_params_rec.target_value1;
      ELSIF get_service_params_rec.source_value1 = 'USERNAME' THEN
        lc_auth_service_user                    := get_service_params_rec.target_value1;
      ELSIF get_service_params_rec.source_value1 = 'PASSWORD' THEN
        lc_auth_service_pwd                     := get_service_params_rec.target_value1;
      END IF;
    END LOOP;
	if lc_auth_service_url is null then 	
	FND_FILE.PUT_LINE(fnd_file.log,'Unable to derive Webservice URL from Translation OD_AOPS_LINE_DEPOSITS_WS.');
	
	end if;
    /*************************
    * Getting the Concurrent Program Name
    **************************/
    lc_error_loc   := 'Getting the Concurrent Program Name';
    lc_error_debug := '';
    SELECT FCPT.user_concurrent_program_name
    INTO gc_concurrent_program_name
    FROM fnd_concurrent_programs_tl FCPT
    WHERE FCPT.concurrent_program_id = fnd_global.conc_program_id
    AND FCPT.language                = USERENV('LANG');
    --Printing the failed records in output file
    lc_error_loc   := 'Printing the Records that were not inserted into the dtls table';
    lc_error_debug := '';
    FND_FILE.PUT_LINE(fnd_file.output,'');
    FND_FILE.PUT_LINE(fnd_file.output,'                             OD: Line Level 3 Detail for Deposits Program                    ');
    FND_FILE.PUT_LINE(fnd_file.output,'                             --------------------------------------------                    ');
    FND_FILE.PUT_LINE(fnd_file.output,'');
    FND_FILE.PUT_LINE(fnd_file.output,'************************************Records that failed insertion****************************');
    FND_FILE.PUT_LINE(fnd_file.output,'');
    FND_FILE.PUT_LINE(fnd_file.output,RPAD('AOPS Order Number',35,' ') ||RPAD('SKU/Item No.',25,' ') ||'Reason for failure');
    FND_FILE.PUT_LINE(fnd_file.output,RPAD('-----------------',35,' ') ||RPAD('------------',25,' ') ||'------------------');
    --Opening the outer cursor loop
    lc_error_loc   := 'Opening the cursor loop';
    lc_error_debug := '';
    FOR lcu_pick_order_numbers_rec IN c_pick_order_numbers
    LOOP
      --Resetting the error flag
      lc_err_flag             := 'N';
      lc_exists               := 'N';
      lc_auth_service_url_main:=NULL;
      -- Added for Defect 2447
      p_ord_nbr               := LTRIM(SUBSTR(lcu_pick_order_numbers_rec.aops_order_number,1,9),'0');
      p_ord_sub               := SUBSTR(lcu_pick_order_numbers_rec.aops_order_number,10,3);
      lc_auth_service_url_main:=lc_auth_service_url||'OrderNumber='||p_ord_nbr||chr(38)||'SubOrderNumber='||p_ord_sub;
      lc_error_loc            := 'Querying for the order details from AOPS';
      lc_error_debug          := 'aops_order_number: '||lcu_pick_order_numbers_rec.aops_order_number;
      FND_FILE.PUT_LINE(fnd_file.log,'');
      FND_FILE.PUT_LINE(fnd_file.log,'Querying the order details for '||lcu_pick_order_numbers_rec.aops_order_number);
      --Code modified for V2.0 starts here..
      IF lc_wallet_location IS NOT NULL THEN
        UTL_HTTP.SET_WALLET(lc_wallet_location, lc_wallet_password);
      END IF;
      l_request := UTL_HTTP.begin_request(lc_auth_service_url_main, 'GET', ' HTTP/1.1');
      UTL_HTTP.set_header(l_request, 'user-agent', 'mozilla/4.0');
      UTL_HTTP.set_header(l_request, 'content-type', 'application/json');
      UTL_HTTP.set_header(l_request, 'Content-Length', LENGTH(lc_auth_payload));
      UTL_HTTP.set_header(l_request, 'Authorization', 'Basic ' || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(lc_auth_service_user || ':' || lc_auth_service_pwd ))));
      UTL_HTTP.write_text(l_request, lc_auth_payload);
      l_response := UTL_HTTP.get_response(l_request);
      BEGIN
        lclob_buffer := EMPTY_CLOB;
        LOOP
          UTL_HTTP.read_text(l_response, lc_buffer, LENGTH(lc_buffer));
          lclob_buffer := lclob_buffer || lc_buffer;
        END LOOP;
        UTL_HTTP.end_response(l_response);
      EXCEPTION
      WHEN UTL_HTTP.end_of_body THEN
        UTL_HTTP.end_response(l_response);
      END;
	 -- FND_FILE.PUT_LINE(fnd_file.log,'Response XML:' 
     --             || cast(lclob_buffer as varchar2));
      BEGIN
        SELECT message,
          code,
          transtatus
        INTO lc_message,
          lc_code,
          lc_tranStatus
        FROM JSON_TABLE ( lclob_buffer, '$.transactionStatus' COLUMNS ( "MESSAGE" VARCHAR2(200) PATH '$.message' ,"CODE" VARCHAR2(30) PATH '$.code' ,"TRANSTATUS" VARCHAR2(30) PATH '$.successfull')) "JT0" ;
        IF lc_code IN ('404' ,'01') THEN
          x_ret_code := 1;
          FND_FILE.PUT_LINE(fnd_file.log,'Webservice returned Error for AOPS Order Number '||lcu_pick_order_numbers_rec.aops_order_number||'. Webservice Error Code:'||lc_code||'.Error Message:'||NVL(trim(lc_message),'NULL'));
          --CONTINUE;
        END IF;
      EXCEPTION
      WHEN No_data_found THEN
        FND_FILE.PUT_LINE(fnd_file.log,'No data Fetched from Webservice call for AOPS order Number '||lcu_pick_order_numbers_rec.aops_order_number);
       -- CONTINUE;
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(fnd_file.log,'Exception occured to pull Webservice Transaction Status for AOPS Order Number '||lcu_pick_order_numbers_rec.aops_order_number||'.SQLERRM-'||sqlerrm);
       -- CONTINUE;
      END;
      IF lc_code='00' THEN
        FOR rec IN
        (SELECT  *
        FROM JSON_TABLE ( lclob_buffer, '$' COLUMNS (NESTED PATH '$.skuListInfo[*]' COLUMNS ("LINENUMBER" VARCHAR2(60) PATH '$.lineNumber', "DEPARTMENT" VARCHAR2(60) PATH '$.department', "SKUNUMBER" VARCHAR2(60) PATH '$.skuNumber', "PRICE" VARCHAR2(60) PATH '$.price', "QTYORDERED" VARCHAR2(60) PATH '$.qtyOrdered', "QTYBACKORD" VARCHAR2(60) PATH '$.qtyBackOrd', "VENDORCODE" VARCHAR2(100) PATH '$.vendorCode', "SHIPZIP" VARCHAR2(60) PATH '$.shipZip', "SHIPSTATE" VARCHAR2(60) PATH '$.shipState', "DISCOUNT" VARCHAR2(60) PATH '$.discount')))
        )
        LOOP
          BEGIN
            --Resetting the status flag
            lc_status          := 'Y';
            lc_exists          := 'Y';
            ln_discount_amount := 0 ;
            BEGIN
              -- Added for the defect 5462 -- START
              lc_error_loc         := 'Getting the discount amount description ';
              lc_error_debug       := 'fco101p_sku: '||rec.skuNumber; --Added for defect 2447
              lc_lineNumber        :=to_number(rec.lineNumber);
              lc_department        :=rec.department;
              lc_skuNumber         :=rec.skuNumber;
              lc_price             :=Round((to_number(NVL(rec.price,0)))/100,2);
              lc_qtyOrdered        :=to_number(NVL(rec.qtyOrdered,0));
              lc_qtyBackOrd        :=to_number(NVL(rec.qtyBackOrd ,0));
              lc_vendorCode        :=rec.vendorCode;
              lc_shipZip           :=rec.shipZip;
              lc_shipState         :=rec.shipState;
              lc_discount          :=Round((to_number(NVL(rec.discount,0)))/100,2);
              IF (lc_qtyOrdered     =0) AND (lc_qtyBackOrd=0) THEN
                ln_discount_amount :=0;
              ELSE
                IF(lc_qtyOrdered =0) THEN
                  lc_qtyOrdered := lc_qtyBackOrd;
                END IF;
                ln_discount_amount:=lc_discount;
              END IF;
              FND_FILE.PUT_LINE(fnd_file.log,' Discount amount for the Item : '||ln_discount_amount ||' -  '||' UOM : ' ||lc_sku_uom);
              lc_error_loc   := 'Getting the item description ';
              lc_error_debug := 'fco101p_sku: '||lr_c_rec_type.odskod;
              FND_FILE.PUT_LINE(fnd_file.log,'Getting the decription for the Item '||lc_skuNumber);
              SELECT MSI.description ,
                MSI.primary_uom_code
              INTO lc_description ,
                lc_sku_uom -- Added for the Defect 3819
              FROM mtl_system_items_b MSI ,
                mtl_parameters MP
                --WHERE  segment1 = TRIM(lcu_order_details.odskod)  -- Commented for the Defect 3819
                -- Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
              WHERE segment1          = NVL2(lc_vendorCode ,lc_skuNumber ,LTRIM(lc_skuNumber,'0') )
              AND MSI.organization_id = MP.master_organization_id
              AND MP.organization_id  = MP.master_organization_id;
              FND_FILE.PUT_LINE(fnd_file.log,' Decription for the Item : '||lc_description ||' -  '||' UOM : ' ||lc_sku_uom);
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lc_description := '';
              FND_MESSAGE.SET_NAME('XXFIN','XX_IBY_0003_NO_ITM');
              lc_err_msg := FND_MESSAGE.GET;
              FND_FILE.PUT_LINE(fnd_file.log, 'Error - '||lc_err_msg);
              XX_COM_ERROR_LOG_PUB.LOG_ERROR ( p_program_type => 'CONCURRENT PROGRAM' ,p_program_name => gc_concurrent_program_name ,p_program_id => FND_GLOBAL.CONC_PROGRAM_ID ,p_module_name => 'IBY' ,p_error_location => 'Error at ' ||lc_error_loc ,p_error_message_count => 1 ,p_error_message_code => 'E' ,p_error_message => lc_err_msg ,p_error_message_severity => 'Major' ,p_notify_flag => 'N' ,p_object_type => 'Line Level 3 Detail' ,p_object_id => lc_error_debug );
            END;
            -- Inserting the order details into the custom table
            lc_error_loc := 'Inserting values into the Custom Table';
            -- Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
            lc_error_debug := 'fco101p_order_nbr: '||p_ord_nbr||' '||'fco101p_detail_seq: '||lc_lineNumber;
            FND_FILE.PUT_LINE(fnd_file.log,'Inserting values into Custom Table for fco101p_order_nbr: ' ||p_ord_nbr||' '||'fco101p_detail_seq: '||lc_lineNumber);
            --Added for defect# 36094
            --Added Begin block to get duplicate record count
            BEGIN
              lc_error_loc := 'Checking for duplicate records';
              dup_count    := 0;
              SELECT COUNT(1)
              INTO dup_count
              FROM xx_iby_deposit_aops_order_dtls
              WHERE aops_order_number = lcu_pick_order_numbers_rec.aops_order_number
              AND receipt_number      = lcu_pick_order_numbers_rec.receipt_number
              AND ws_seq_number       = lc_lineNumber;
            EXCEPTION
            WHEN OTHERS THEN
              FND_FILE.PUT_LINE(fnd_file.log, 'AOPS Order Number = '|| lcu_pick_order_numbers_rec.aops_order_number || ' - ' || 'Error : '||lc_err_msg);
            END;
            IF (dup_count = 0) --Added for defect# 36094
              THEN
              INSERT
              INTO xx_iby_deposit_aops_order_dtls
                (
                  aops_order_number ,
                  receipt_number ,
                  ws_seq_number ,
                  ws_merch_dept ,
                  ws_sku ,
                  ws_price_retail ,
                  ws_sku_qty ,
                  ws_sku_desc ,
                  ws_sku_uom -- Added for the Defect 3819
                  ,
                  creation_date ,
                  created_by ,
                  last_update_date ,
                  last_updated_by ,
                  last_update_login ,
                  program_application_id ,
                  program_id ,
                  program_update_date ,
                  ws_discount_amount -- Added for the defect 5462
                  ,
                  attribute1 -- Added for the defect 552
                  ,
                  attribute2 -- Added for defect 6232
                )
                VALUES
                (
                  lcu_pick_order_numbers_rec.aops_order_number ,
                  lcu_pick_order_numbers_rec.receipt_number ,
                  lc_lineNumber --Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                  ,
                  lc_department --Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                  ,
                  TRIM(lc_skuNumber) --Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                  ,
                  lc_price --Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                  ,
                  lc_qtyOrdered--Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                  ,
                  lc_description ,
                  lc_sku_uom -- Added for the Defect 3819
                  ,
                  SYSDATE ,
                  FND_GLOBAL.USER_ID ,
                  SYSDATE ,
                  FND_GLOBAL.USER_ID ,
                  FND_GLOBAL.LOGIN_ID ,
                  lcu_pick_order_numbers_rec.program_application_id ,
                  lcu_pick_order_numbers_rec.program_id ,
                  lcu_pick_order_numbers_rec.program_update_date ,
                  ln_discount_amount -- Added for the defect 5462
                  ,
                  lc_shipZip --Commented lcu_order_details and Added lr_c_rec_type for Defect 2447
                  ,
                  lc_shipState -- Added for defect 6232
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
            ||RPAD(NVL(lc_skuNumber,' '),25, ' ') ||lc_err_msg);
            XX_COM_ERROR_LOG_PUB.LOG_ERROR ( p_program_type => 'CONCURRENT PROGRAM' ,p_program_name => gc_concurrent_program_name ,p_program_id => FND_GLOBAL.CONC_PROGRAM_ID ,p_module_name => 'IBY' ,p_error_location => 'Error at ' || lc_error_loc ,p_error_message_count => 1 ,p_error_message_code => 'E' ,p_error_message => lc_err_msg ,p_error_message_severity => 'Major' ,p_notify_flag => 'N' ,p_object_type => 'Line Level 3 Detail' ,p_object_id => lc_error_debug );
          END;
          IF (lc_status  = 'N') THEN
            lc_err_flag := 'Y';
          END IF;
        END LOOP;
      END IF;
      ---Code modified for V2.0 ends here.
      -- Deleting the original record from the table for those which were succesfully inserted
      IF ( lc_exists    = 'Y' AND lc_err_flag = 'N' ) THEN
        lc_error_loc   := 'Updating the record from the order table';
        lc_error_debug := 'aops_order_number: '||lcu_pick_order_numbers_rec.aops_order_number;
        --  Commented by Anitha for Defect 11555
        /*                DELETE FROM xx_iby_deposit_aops_orders
        WHERE  aops_order_number = lcu_pick_order_numbers_rec.aops_order_number;*/
        --  Added by Anitha for Defect 11555
        UPDATE xx_iby_deposit_aops_orders
        SET process_flag = 'Complete'
        WHERE rowid      = lcu_pick_order_numbers_rec.rowid;
        FND_FILE.PUT_LINE(fnd_file.log,'Updated the original record for '||lcu_pick_order_numbers_rec.aops_order_number);
        FND_FILE.PUT_LINE(fnd_file.log,'');
      END IF;
      IF ( lc_exists = 'N') THEN
        -- Addressed Defect 2347 for proper logging messages if record not found in AS400 system
        FND_FILE.PUT_LINE(fnd_file.log,'Order Number not Found in the AS400 System' );
        FND_FILE.PUT_LINE(fnd_file.output,'');
        FND_FILE.PUT_LINE(fnd_file.output,RPAD(lcu_pick_order_numbers_rec.aops_order_number,35,' ') || RPAD(' ',25,' ') || 'Order Number not Found in the AS400 System. Webservice Error Code:'||lc_code||'.Error Message:'||NVL(trim(lc_message),'NULL') );
        x_ret_code := 1;
        -- Addition for defect 2347 ends here
      END IF;
      ln_count    := ln_count + 1;
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
    XX_COM_ERROR_LOG_PUB.LOG_ERROR ( p_program_type => 'CONCURRENT PROGRAM' ,p_program_name => gc_concurrent_program_name ,p_program_id => FND_GLOBAL.CONC_PROGRAM_ID ,p_module_name => 'IBY' ,p_error_location => 'Error at ' || lc_error_loc ,p_error_message_count => 1 ,p_error_message_code => 'E' ,p_error_message => lc_err_msg ,p_error_message_severity => 'Major' ,p_notify_flag => 'N' ,p_object_type => 'Line Level 3 Detail' );
    x_ret_code := 2;
  END DETAIL;
END XX_IBY_DEPOSIT_DTLS_PKG;
/
SHOW ERROR
