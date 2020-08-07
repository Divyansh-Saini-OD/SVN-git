SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT Creating PACKAGE BODY XX_CE_TMS_JE_PKG
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE
---------
create or replace 
PACKAGE BODY XX_CE_MPL_SETTLEMENT_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify       --- Test                                                    |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_CE_MPL_SETTLEMENT_PKG                                                         |
  -- |  RICE ID   :  I3091_CM Marketplace Inbound Interface                                       |
  -- |  Description:  Load staging XX_CE_MPL_SETTLEMENT_STG table validate and insert into        |
  -- |                XX_CE_AJB996,XX_CE_AJB998,XX_CE_AJB999                                      |
  -- |                                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         03/02/2014   Avinash Baddam   Initial version                                  |
  -- | 1.1         05/06/2015   Avinash Baddam   Defect#34376 Fixed 999 cost_funds_amt            |
  -- | 1.2         05/12/2015   Avinash Baddam   Defect#34377 Round cost_funds_amt to 2 decimals  |
  -- | 1.3         06/12/2015   Avinash Baddam   Defect#34508 cost_funds_amt sign                 |
  -- | 1.3         07/16/2015   Avinash Baddam   V2 File Version changes from Amazon              |
  -- | 1.4         10/05/2015   Avinash Baddam   Defect#34514                                     |
  -- | 1.5         12/14/2015   Avinash Baddam   Defect#34514 - Fix store numbers on returns      |
  -- | 1.6         11/10/2017   Digamber S       Enhancement  for LLC file processing             |
  -- |                                           main_llc ,process_data_998,process_data_999      |
  -- |                                           main_wraper procedure Added                      |
  -- | 1.7         19-NOV-2017  Pramod M K       Defect# 43424 Code changes to default Status=NEW |
  -- +============================================================================================+
  -- +============================================================================================+
  -- |  Name  : Log Exception                                                                     |
  -- |  Description: The log_exception procedure logs all exceptions                              |
  -- =============================================================================================|
PROCEDURE log_exception(
    p_program_name   IN VARCHAR2 ,
    p_error_location IN VARCHAR2 ,
    p_error_msg      IN VARCHAR2)
IS
  ln_login   NUMBER := FND_GLOBAL.LOGIN_ID;
  ln_user_id NUMBER := FND_GLOBAL.USER_ID;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error( p_return_code => FND_API.G_RET_STS_ERROR ,p_msg_count => 1 ,p_application_name => 'XXFIN' ,p_program_type => 'Custom Messages' ,p_program_name => p_program_name ,p_attribute15 => p_program_name ,p_program_id => NULL ,p_module_name => 'AR' ,p_error_location => p_error_location ,p_error_message_code => NULL ,p_error_message => p_error_msg ,p_error_message_severity => 'MAJOR' ,p_error_status => 'ACTIVE' ,p_created_by => ln_user_id ,p_last_updated_by => ln_user_id ,p_last_update_login => ln_login );
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Error while writting to the log ...'|| SQLERRM);
END log_exception;
-- +============================================================================================+
-- |  Name  : DUPLICATE_CHECK                                                             |
-- |  Description: This procedure checks if the settlement data already exists in 998/999 tables|
-- =============================================================================================|
PROCEDURE duplicate_check(
    p_ajb_file_name VARCHAR2,
    p_error_msg OUT VARCHAR2,
    p_retcode OUT VARCHAR2)
AS
  CURSOR dup_check_cur(p_ajb_file_name VARCHAR2)
  IS
    SELECT ajb_file_name FROM xx_ce_ajb998 WHERE ajb_file_name = p_ajb_file_name
  UNION
  SELECT ajb_file_name FROM xx_ce_ajb999 WHERE ajb_file_name = p_ajb_file_name;
  l_ajb_file_name VARCHAR2(200);
BEGIN
  write_log('Selecting ajb_file_name:'||p_ajb_file_name||' from 998/999 tables');
  OPEN dup_check_cur(p_ajb_file_name);
  FETCH dup_check_cur INTO l_ajb_file_name;
  CLOSE dup_check_cur;
  IF l_ajb_file_name IS NOT NULL THEN
    p_error_msg      := 'DUPLICATE ERROR - Settlement data(ajb_file_name:'||l_ajb_file_name||') already exists in 998/999 tables';
    p_retcode        := '2';
  ELSE
    p_retcode := '0';
  END IF;
END duplicate_check;
-- +============================================================================================+
-- |  Name  : parse                                                                 |
-- |  Description: Procedure to parse delimited string and load them into table                 |
-- =============================================================================================|
PROCEDURE parse(
    p_delimstring IN VARCHAR2 ,
    p_table OUT varchar2_table ,
    p_nfields OUT INTEGER ,
    p_delim IN VARCHAR2 DEFAULT chr(
      9) ,
    p_error_msg OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2)
IS
  l_string VARCHAR2(32767) := p_delimstring;
  l_nfields PLS_INTEGER    := 1;
  l_table varchar2_table;
  l_delimpos PLS_INTEGER := INSTR(p_delimstring, p_delim);
  l_delimlen PLS_INTEGER := LENGTH(p_delim);
BEGIN
  WHILE l_delimpos > 0
  LOOP
    l_table(l_nfields) := SUBSTR(l_string,1,l_delimpos-1);
    l_string           := SUBSTR(l_string,l_delimpos  +l_delimlen);
    l_nfields          := l_nfields                   +1;
    l_delimpos         := INSTR(l_string, p_delim);
  END LOOP;
  l_table(l_nfields) := l_string;
  p_table            := l_table;
  p_nfields          := l_nfields;
EXCEPTION
WHEN OTHERS THEN
  p_retcode   := '2';
  p_error_msg := 'Error in XX_CE_MPL_SETTLEMENT_PKG.parse - record:'||SUBSTR(p_delimstring,150)||SUBSTR(sqlerrm,1,150);
END parse;
-- +============================================================================================+
-- |  Name  : load_staging                                                             |
-- |  Description: This procedure reads data from the file and inserts into staging table       |
-- =============================================================================================|
PROCEDURE load_staging(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2 ,
    p_file_name VARCHAR2)
AS
  CURSOR dup_check_cur(p_settlement_id NUMBER)
  IS
    SELECT settlement_id
    FROM xx_ce_mpl_settlement_stg
    WHERE settlement_id = p_settlement_id;
  l_filehandle UTL_FILE.FILE_TYPE;
  l_filedir VARCHAR2(20) := 'XXFIN_INBOUND';
  l_dirpath VARCHAR2(500);
  l_newline VARCHAR2(4000); -- Input line
  l_max_linesize BINARY_INTEGER := 32767;
  l_user_id    NUMBER              := fnd_global.user_id;
  l_login_id   NUMBER              := fnd_global.login_id;
  l_request_id NUMBER              := fnd_global.conc_request_id;
  l_rec_cnt    NUMBER              := 0;
  l_table varchar2_table;
  l_nfields           INTEGER;
  l_error_msg         VARCHAR2(1000) := NULL;
  l_error_loc         VARCHAR2(2000) := 'XX_CE_MPL_SETTLEMENT_PKG.LOAD_STAGING';
  l_retcode           VARCHAR2(3)    := NULL;
  l_ajb_file_name     VARCHAR2(200);
  PARSE_EXCEPTION     EXCEPTION;
  DUP_EXCEPTION       EXCEPTION;
  l_dup_settlement_id NUMBER;
  /*staging table columns*/
  l_record_id                    NUMBER;
  l_settlement_id                NUMBER;
  l_settlement_start_date        VARCHAR2(50);
  l_settlement_end_date          VARCHAR2(50);
  l_deposit_date                 VARCHAR2(50);
  l_total_amount                 NUMBER;
  l_currency                     VARCHAR2(30);
  l_transaction_type             VARCHAR2(100);
  l_order_id                     VARCHAR2(100);
  l_merchant_order_id            VARCHAR2(100);
  l_adjustment_id                VARCHAR2(100);
  l_shipment_id                  VARCHAR2(50);
  l_marketplace_name             VARCHAR2(25);
  l_shipment_fee_type            VARCHAR2(50);
  l_shipment_fee_amount          VARCHAR2(25);
  l_order_fee_type               VARCHAR2(50);
  l_order_fee_amount             VARCHAR2(25);
  l_fulfillment_id               VARCHAR2(50);
  l_posted_date                  VARCHAR2(50);
  l_order_item_code              VARCHAR2(50);
  l_merchant_order_item_id       VARCHAR2(25);
  l_merchant_adjustment_item_id  VARCHAR2(50);
  l_sku                          VARCHAR2(50);
  l_quantity_purchased           VARCHAR2(25);
  l_price_type                   VARCHAR2(50);
  l_price_amount                 VARCHAR2(25);
  l_item_related_fee_type        VARCHAR2(50);
  l_item_related_fee_amount      VARCHAR2(25);
  l_misc_fee_amount              VARCHAR2(25);
  l_other_fee_amount             VARCHAR2(25);
  l_other_fee_reason_description VARCHAR2(1000);
  l_promotion_id                 VARCHAR2(2000);
  l_promotion_type               VARCHAR2(50);
  l_promotion_amount             VARCHAR2(25);
  l_direct_payment_type          VARCHAR2(50);
  l_direct_payment_amount        VARCHAR2(25);
  l_other_amount                 VARCHAR2(25);
BEGIN
  write_log('start load_staging from file:'||p_file_name);
  l_filehandle := UTL_FILE.FOPEN(l_filedir,p_file_name,'r',l_max_linesize);
  write_log('File open successfull');
  LOOP
    BEGIN
      UTL_FILE.GET_LINE(l_filehandle,l_newline);
      IF l_newline IS NULL THEN
        EXIT;
      END IF;
      /*skip parsing the header labels record*/
      CONTINUE
    WHEN SUBSTR(l_newline,1,10) = 'settlement';
      parse(l_newline,l_table,l_nfields,chr(9),l_error_msg,l_retcode);
      IF l_retcode = '2' THEN
        raise PARSE_EXCEPTION;
      END IF;
      -- Use the values
      l_settlement_id := to_number(l_table(1));
      /* check for duplicate using the first data record*/
      IF l_rec_cnt = 0 THEN
        write_log('Checking if settlement_id:'||TO_CHAR(l_settlement_id)||' exists in staging XX_CE_MPL_SETTLEMENT_STG table');
        l_dup_settlement_id := NULL;
        OPEN dup_check_cur(l_settlement_id);
        FETCH dup_check_cur INTO l_dup_settlement_id;
        CLOSE dup_check_cur;
        IF l_dup_settlement_id IS NOT NULL THEN
          l_error_msg          := 'DUPLICATE ERROR - Settlement data(settlementid:'||TO_CHAR(l_settlement_id)||') already exists in staging XX_CE_MPL_SETTLEMENT_STG table';
          write_log(l_error_msg);
          RAISE DUP_EXCEPTION;
        END IF;
        l_ajb_file_name := p_file_name||TO_CHAR(l_settlement_id);
        /*Check if the settlement id already has records in 998 and 999 using ajb_file_name*/
        write_log('Checking if ajb_file_name:'||l_ajb_file_name||' exists in 998/999 tables');
        l_retcode   := NULL;
        l_error_msg := NULL;
        duplicate_check(l_ajb_file_name,l_error_msg,l_retcode);
        IF l_retcode = '2' THEN
          raise DUP_EXCEPTION;
        END IF;
      END IF;
      l_settlement_start_date := l_table(2);
      l_settlement_end_date   := l_table(3);
      l_deposit_date          := l_table(4);
      l_total_amount          := l_table(5);
      l_currency              := l_table(6);
      l_transaction_type      := l_table(7);
      --V2 File changes
      IF l_transaction_type LIKE '%Refund%' THEN
        l_transaction_type := 'Adjustment';
      END IF;
      l_order_id            := l_table(8);
      l_merchant_order_id   := l_table(9);
      l_adjustment_id       := l_table(10);
      l_shipment_id         := l_table(11);
      l_marketplace_name    := l_table(12);
      l_shipment_fee_type   := l_table(13);
      l_shipment_fee_amount := l_table(14);
      l_order_fee_type      := l_table(15);
      l_order_fee_amount    := l_table(16);
      l_fulfillment_id      := l_table(17);
      l_posted_date         := l_table(18);
      l_order_item_code     := l_table(19);
      --V2 File changes - use sku if merchant_order_item_id is null
      l_merchant_order_item_id       := NVL(l_table(20),l_table(22));
      l_merchant_adjustment_item_id  := l_table(21);
      l_sku                          := l_table(22);
      l_quantity_purchased           := l_table(23);
      l_price_type                   := l_table(24);
      l_price_amount                 := l_table(25);
      l_item_related_fee_type        := l_table(26);
      l_item_related_fee_amount      := l_table(27);
      l_misc_fee_amount              := l_table(28);
      l_other_fee_amount             := l_table(29);
      l_other_fee_reason_description := l_table(30);
      --Defect#34514
      l_promotion_id          := SUBSTR(l_table(31),1,2000);
      l_promotion_type        := l_table(32);
      l_promotion_amount      := l_table(33);
      l_direct_payment_type   := l_table(34);
      l_direct_payment_amount := l_table(35);
      l_other_amount          := l_table(36);
      SELECT XX_CE_MPL_SETTLEMENT_STG_ID_S.nextval INTO l_record_id FROM dual;
      INSERT
      INTO xx_ce_mpl_settlement_stg
        (
          record_id ,
          settlement_id ,
          settlement_start_date ,
          settlement_end_date ,
          deposit_date ,
          total_amount ,
          currency ,
          transaction_type ,
          order_id ,
          merchant_order_id ,
          adjustment_id ,
          shipment_id ,
          marketplace_name ,
          shipment_fee_type ,
          shipment_fee_amount ,
          order_fee_type ,
          order_fee_amount ,
          fulfillment_id ,
          posted_date ,
          order_item_code ,
          merchant_order_item_id ,
          merchant_adjustment_item_id ,
          sku ,
          quantity_purchased ,
          price_type ,
          price_amount ,
          item_related_fee_type ,
          item_related_fee_amount ,
          misc_fee_amount ,
          other_fee_amount ,
          other_fee_reason_description ,
          promotion_id ,
          promotion_type ,
          promotion_amount ,
          direct_payment_type ,
          direct_payment_amount ,
          other_amount ,
          request_id ,
          created_by ,
          creation_date ,
          last_updated_by ,
          last_update_date ,
          last_update_login
        )
        VALUES
        (
          l_record_id ,
          l_settlement_id ,
          l_settlement_start_date ,
          l_settlement_end_date ,
          l_deposit_date ,
          l_total_amount ,
          l_currency ,
          l_transaction_type ,
          l_order_id ,
          l_merchant_order_id ,
          l_adjustment_id ,
          l_shipment_id ,
          l_marketplace_name ,
          l_shipment_fee_type ,
          l_shipment_fee_amount ,
          l_order_fee_type ,
          l_order_fee_amount ,
          l_fulfillment_id ,
          l_posted_date ,
          l_order_item_code ,
          l_merchant_order_item_id ,
          l_merchant_adjustment_item_id ,
          l_sku ,
          l_quantity_purchased ,
          l_price_type ,
          l_price_amount ,
          l_item_related_fee_type ,
          l_item_related_fee_amount ,
          l_misc_fee_amount ,
          l_other_fee_amount ,
          l_other_fee_reason_description ,
          l_promotion_id ,
          l_promotion_type ,
          l_promotion_amount ,
          l_direct_payment_type ,
          l_direct_payment_amount ,
          to_number(l_other_amount) ,
          l_request_id ,
          l_user_id ,
          sysdate ,
          l_user_id ,
          sysdate ,
          l_login_id
        );
      l_rec_cnt := l_rec_cnt + 1;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      EXIT;
    END;
  END LOOP;
  UTL_FILE.FCLOSE(l_filehandle);
  COMMIT;
  write_log(TO_CHAR(l_rec_cnt)||' records successfully loaded into staging');
EXCEPTION
WHEN DUP_EXCEPTION THEN
  p_errbuf  := l_error_msg;
  p_retcode := '2';
  log_exception (p_program_name => 'XXCEMPLSTG' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
WHEN PARSE_EXCEPTION THEN
  ROLLBACK;
  p_errbuf  := l_error_msg;
  p_retcode := l_retcode;
  log_exception (p_program_name => 'XXCEMPLSTG' ,p_error_location => l_error_loc ,p_error_msg => l_error_msg);
WHEN UTL_FILE.INVALID_OPERATION THEN
  UTL_FILE.FCLOSE(l_filehandle);
  p_errbuf := 'XX_CE_MPL_SETTLEMENT_PKG.LOAD_STAGING: Invalid Operation';
  p_retcode:= '2';
  log_exception (p_program_name => 'XXCEMPLSTG' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
WHEN UTL_FILE.INVALID_FILEHANDLE THEN
  UTL_FILE.FCLOSE(l_filehandle);
  p_errbuf := 'XX_CE_MPL_SETTLEMENT_PKG.LOAD_STAGING: Invalid File Handle';
  p_retcode:= '2';
  log_exception (p_program_name => 'XXCEMPLSTG' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
WHEN UTL_FILE.READ_ERROR THEN
  UTL_FILE.FCLOSE(l_filehandle);
  p_errbuf := 'XX_CE_MPL_SETTLEMENT_PKG.LOAD_STAGING: Read Error';
  p_retcode:= '2';
  log_exception (p_program_name => 'XXCEMPLSTG' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
WHEN UTL_FILE.INVALID_PATH THEN
  UTL_FILE.FCLOSE(l_filehandle);
  p_errbuf := 'XX_CE_MPL_SETTLEMENT_PKG.LOAD_STAGING: Invalid Path';
  p_retcode:= '2';
  log_exception (p_program_name => 'XXCEMPLSTG' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
WHEN UTL_FILE.INVALID_MODE THEN
  UTL_FILE.FCLOSE(l_filehandle);
  p_errbuf := 'XX_CE_MPL_SETTLEMENT_PKG.LOAD_STAGING: Invalid Mode';
  p_retcode:= '2';
  log_exception (p_program_name => 'XXCEMPLSTG' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
WHEN UTL_FILE.INTERNAL_ERROR THEN
  UTL_FILE.FCLOSE(l_filehandle);
  p_errbuf := 'XX_CE_MPL_SETTLEMENT_PKG.LOAD_STAGING: Internal Error';
  p_retcode:= '2';
  log_exception (p_program_name => 'XXCEMPLSTG' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
WHEN VALUE_ERROR THEN
  ROLLBACK;
  UTL_FILE.FCLOSE(l_filehandle);
  p_errbuf := 'XX_CE_MPL_SETTLEMENT_PKG.LOAD_STAGING: Value Error MPL Order Id:'||l_order_id;
  p_retcode:= '2';
  log_exception (p_program_name => 'XXCEMPLSTG' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
WHEN OTHERS THEN
  ROLLBACK;
  UTL_FILE.FCLOSE(l_filehandle);
  p_retcode:= '2';
  p_errbuf := 'XX_CE_MPL_SETTLEMENT_PKG.LOAD_STAGING: MPL Order Id:'||l_order_id||SUBSTR(sqlerrm,1,250);
  log_exception (p_program_name => 'XXCEMPLSTG' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
END load_staging;
-- +============================================================================================+
-- |  Name  : PROCESS_STAGING                                                             |
-- |  Description: This procedure will populate store_number,split_order_flag and aops_order_num|
-- |               in XX_CE_MPL_SETTLEMENT_STG.This will also validate the data and flag errors |
-- =============================================================================================|
PROCEDURE process_staging
  (
    p_settlement_id NUMBER,
    p_error_msg OUT VARCHAR2,
    p_retcode OUT VARCHAR2
  )
AS
  CURSOR stlmt_stg_cur
    (
      p_settlement_id NUMBER
    )
  IS
    SELECT settlement_id,
      order_id,
      transaction_type
    FROM xx_ce_mpl_settlement_stg
    WHERE transaction_type IN('Order','Adjustment')
      --AND record_status IS NULL
    AND settlement_id = p_settlement_id
    GROUP BY settlement_id,
      order_id,
      transaction_type;
TYPE stlmt_stg
IS
  TABLE OF stlmt_stg_cur%ROWTYPE INDEX BY PLS_INTEGER;
  l_stlmt_stg_tab stlmt_stg;
  CURSOR ORDT_cur(p_order_id VARCHAR2,p_trx_type VARCHAR2)
  IS
    SELECT xordt.store_number,
      xordt.orig_sys_document_ref
    FROM xx_ar_order_receipt_dtl xordt
    WHERE xordt.mpl_order_id = p_order_id
    AND XORDT.SALE_TYPE      = P_TRX_TYPE
      --  AND XORDT.ORDER_SOURCE   ||'' = 'MPL';
    AND XORDT.ORDER_SOURCE IN ('MPL','MPL4S');
TYPE ORDT
IS
  TABLE OF ORDT_cur%ROWTYPE INDEX BY PLS_INTEGER;
  l_ORDT_tab ORDT;
  CURSOR stlmt_stg_split_cur(p_settlement_id NUMBER,p_order_id VARCHAR2,p_transaction_type VARCHAR2)
  IS
    SELECT settlement_id,
      order_id,
      transaction_type,
      merchant_order_item_id
    FROM xx_ce_mpl_settlement_stg
    WHERE transaction_type IN('Order','Adjustment')
      --AND record_status IS NULL
    AND settlement_id    = p_settlement_id
    AND order_id         = p_order_id
    AND transaction_type = p_transaction_type
    GROUP BY settlement_id,
      order_id,
      transaction_type,
      merchant_order_item_id;
TYPE stlmt_stg_split
IS
  TABLE OF stlmt_stg_split_cur%ROWTYPE INDEX BY PLS_INTEGER;
  l_stlmt_stg_split_tab stlmt_stg_split;
  CURSOR ORDT1_cur(p_order_id VARCHAR2,p_trx_type VARCHAR2,p_merchant_order_item_id VARCHAR2)
  IS
    SELECT xordt.store_number,
      xordt.orig_sys_document_ref
    FROM xx_ar_order_receipt_dtl xordt
    WHERE xordt.mpl_order_id = p_order_id
    AND XORDT.SALE_TYPE      = P_TRX_TYPE
      --AND XORDT.ORDER_SOURCE  ||'' = 'MPL'
    AND XORDT.ORDER_SOURCE IN ('MPL','MPL4S')
    AND EXISTS
      (SELECT 'x'
      FROM oe_order_headers_all oeh,
        oe_order_lines_all oel
      WHERE xordt.order_number = oeh.order_number
      AND oeh.header_id        = oel.header_id
      AND oel.ordered_item     = ltrim(p_merchant_order_item_id,'0')
      );
TYPE ORDT1
IS
  TABLE OF ORDT1_cur%ROWTYPE INDEX BY PLS_INTEGER;
  l_ORDT1_tab ORDT1;
  CURSOR ORDT_Ship_cur(p_order_id VARCHAR2,p_trx_type VARCHAR2)
  IS
    SELECT xordt.store_number,
      xordt.orig_sys_document_ref,
      xordt.header_id
    FROM xx_ar_order_receipt_dtl xordt
    WHERE xordt.mpl_order_id = p_order_id
    AND XORDT.SALE_TYPE      = P_TRX_TYPE
      -- AND xordt.order_source    ||'' = 'MPL'
    AND XORDT.ORDER_SOURCE IN ('MPL','MPL4S')
    AND EXISTS
      (SELECT 'x'
      FROM oe_order_headers_all oeh,
        oe_order_lines_all oel
      WHERE oeh.header_id       = xordt.header_id
      AND oel.header_id         = xordt.header_id
      AND oel.inventory_item_id = 2001
      );
TYPE ORDT_Ship
IS
  TABLE OF ORDT_Ship_cur%ROWTYPE INDEX BY PLS_INTEGER;
  l_ORDT_Ship_tab ORDT_Ship;
  l_error_msg             VARCHAR2(1000);
  indx                    NUMBER;
  l_batch_size            NUMBER := 1000;
  l_trx_type              VARCHAR2(50);
  l_store_number          VARCHAR2(30);
  l_split_order           VARCHAR2(1);
  l_aops_order_number     VARCHAR2(30);
  l_order_id              VARCHAR2(100);
  l_header_id             NUMBER;
  l_line_count            NUMBER;
  l_check_ship_order_flag VARCHAR2(1);
  l_rows_updated          NUMBER := 0;
  l_rec_err_cnt           NUMBER := 0;
  l_user_id               NUMBER := NVL(fnd_global.user_id,0);
  l_login_id              NUMBER := NVL(fnd_global.login_id,0);
  DATA_ERROR              EXCEPTION;
BEGIN
  l_rec_err_cnt := 0;
  write_log('Processing staging records to populate store_number,split_order_flag and aops_order_number...');
  OPEN stlmt_stg_cur(p_settlement_id);
  LOOP
    FETCH stlmt_stg_cur BULK COLLECT INTO l_stlmt_stg_tab LIMIT l_batch_size;
    EXIT
  WHEN l_stlmt_stg_tab.COUNT = 0;
    l_order_id              := NULL;
    FOR indx IN l_stlmt_stg_tab.FIRST..l_stlmt_stg_tab.LAST
    LOOP
      BEGIN
        l_order_id                               := l_stlmt_stg_tab(indx).order_id;
        IF l_stlmt_stg_tab(indx).transaction_type = 'Order' THEN
          l_trx_type                             := 'SALE';
        ELSE
          l_trx_type := 'REFUND';
        END IF;
        /*Check if the the mpl_order_id and trx_type exists in ORDT.
        If more than one record then its split order*/
        l_store_number      := NULL;
        l_split_order       := 'N';
        l_aops_order_number := NULL;
        OPEN ORDT_cur(l_order_id,l_trx_type);
        FETCH ORDT_cur BULK COLLECT INTO l_ORDT_tab;
        CLOSE ORDT_cur;
        IF l_ORDT_tab.COUNT = 0 THEN
          --If no record found in ORDT then default to store 010000
          l_store_number      := '010000';
          l_aops_order_number := NULL;
          --l_error_msg := 'ERROR - MPL Order '||l_order_id||' in settlement file does not have matching Order Receipt Detail Record';
          --raise DATA_ERROR;
        END IF;
        IF l_ORDT_tab.COUNT    = 1 THEN
          l_store_number      := l_ORDT_tab(1).store_number;
          l_aops_order_number := l_ORDT_tab(1).orig_sys_document_ref;
        END IF;
        /*V2 */
        IF l_ORDT_tab.COUNT IN(0,1) THEN
          UPDATE xx_ce_mpl_settlement_stg
          SET store_number     = l_store_number,
            aops_order_number  = l_aops_order_number,
            split_order        = l_split_order,
            last_update_date   = sysdate,
            last_updated_by    = l_user_id,
            last_update_login  = l_login_id
          WHERE settlement_id  = l_stlmt_stg_tab(indx).settlement_id
          AND order_id         = l_stlmt_stg_tab(indx).order_id
          AND transaction_type = l_stlmt_stg_tab(indx).transaction_type;
          l_rows_updated      := l_rows_updated + SQL%ROWCOUNT;
        END IF;
        /* Check for split order */
        IF l_ORDT_tab.COUNT > 1 THEN
          l_split_order    := 'Y';
          --l_check_ship_order_flag := 'Y';
          OPEN stlmt_stg_split_cur(l_stlmt_stg_tab(indx).settlement_id,l_stlmt_stg_tab(indx).order_id,l_stlmt_stg_tab(indx).transaction_type);
          FETCH stlmt_stg_split_cur BULK COLLECT INTO l_stlmt_stg_split_tab;
          CLOSE stlmt_stg_split_cur;
          FOR i IN l_stlmt_stg_split_tab.FIRST..l_stlmt_stg_split_tab.LAST
          LOOP
            BEGIN
              l_store_number      := NULL;
              l_aops_order_number := NULL;
              OPEN ORDT1_cur(l_stlmt_stg_split_tab(i).order_id,l_trx_type,l_stlmt_stg_split_tab(i).merchant_order_item_id);
              FETCH ORDT1_cur INTO l_store_number,l_aops_order_number;
              CLOSE ORDT1_cur;
              IF l_store_number IS NULL THEN
                --If no record found then default to store 010000
                l_store_number      := '010000';
                l_aops_order_number := NULL;
                --l_error_msg := 'ERROR processing split order details - MPL Order '||l_order_id||' or Merchant_order_item_id '||l_stlmt_stg_split_tab(i).merchant_order_item_id||' in settlement file does not have matching ORDT/Order record';
                --raise DATA_ERROR;
              END IF;
              /*CA confirmed that merchant_order_item_id will not be null but
              if it is null, then populate with default store number value*/
              UPDATE xx_ce_mpl_settlement_stg
              SET store_number                    = l_store_number,
                aops_order_number                 = l_aops_order_number,
                split_order                       = l_split_order,
                last_update_date                  = sysdate,
                last_updated_by                   = l_user_id,
                last_update_login                 = l_login_id
              WHERE settlement_id                 = l_stlmt_stg_split_tab(i).settlement_id
              AND order_id                        = l_stlmt_stg_split_tab(i).order_id
              AND transaction_type                = l_stlmt_stg_split_tab(i).transaction_type
              AND NVL(merchant_order_item_id,'x') = NVL(l_stlmt_stg_split_tab(i).merchant_order_item_id,'x');
              l_rows_updated                     := l_rows_updated + SQL%ROWCOUNT;
              /*If its return, check if there is order only for shipping*/
              IF l_trx_type = 'REFUND' THEN --AND l_check_ship_order_flag = 'Y' THEN
                /* Check if the ORDT return order has line with inventory_item_id 2001*/
                --l_check_ship_order_flag  := 'N'; --check for shipping order is done only once for mpl_order.
                l_store_number      := NULL;
                l_aops_order_number := NULL;
                OPEN ORDT_Ship_cur(l_stlmt_stg_split_tab(i).order_id,l_trx_type);
                FETCH ORDT_Ship_cur INTO l_store_number,l_aops_order_number,l_header_id;
                CLOSE ORDT_Ship_cur;
                IF l_store_number IS NOT NULL THEN
                  /* Check if this is a single line shipping order */
                  SELECT COUNT(*)
                  INTO l_line_count
                  FROM oe_order_headers_all oeh,
                    oe_order_lines_all oel
                  WHERE oeh.header_id = l_header_id
                  AND oeh.header_id   = oel.header_id;
                  IF l_line_count     = 1 THEN
                    UPDATE xx_ce_mpl_settlement_stg
                    SET store_number           = l_store_number,
                      aops_order_number        = l_aops_order_number,
                      split_order              = l_split_order,
                      last_update_date         = sysdate,
                      last_updated_by          = l_user_id,
                      last_update_login        = l_login_id
                    WHERE settlement_id        = l_stlmt_stg_split_tab(i).settlement_id
                    AND order_id               = l_stlmt_stg_split_tab(i).order_id
                    AND transaction_type       = l_stlmt_stg_split_tab(i).transaction_type
                    AND merchant_order_item_id = l_stlmt_stg_split_tab(i).merchant_order_item_id
                    AND price_type            IN('Shipping','ShippingTax');
                  END IF;
                END IF;
              END IF;
            EXCEPTION
            WHEN DATA_ERROR THEN
              UPDATE xx_ce_mpl_settlement_stg
              SET record_status          = 'ERROR',
                error_description        = l_error_msg,
                last_update_date         = sysdate,
                last_updated_by          = l_user_id,
                last_update_login        = l_login_id
              WHERE settlement_id        = l_stlmt_stg_split_tab(i).settlement_id
              AND order_id               = l_stlmt_stg_split_tab(i).order_id
              AND transaction_type       = l_stlmt_stg_split_tab(i).transaction_type
              AND merchant_order_item_id = l_stlmt_stg_split_tab(i).merchant_order_item_id;
              l_rec_err_cnt             := l_rec_err_cnt + SQL%ROWCOUNT;
            END;
          END LOOP;
        END IF; --End check for split order
      EXCEPTION
      WHEN DATA_ERROR THEN
        UPDATE xx_ce_mpl_settlement_stg
        SET record_status    = 'ERROR',
          error_description  = l_error_msg,
          last_update_date   = sysdate,
          last_updated_by    = l_user_id,
          last_update_login  = l_login_id
        WHERE settlement_id  = l_stlmt_stg_tab(indx).settlement_id
        AND order_id         = l_stlmt_stg_tab(indx).order_id
        AND transaction_type = l_stlmt_stg_tab(indx).transaction_type;
        l_rec_err_cnt       := l_rec_err_cnt + SQL%ROWCOUNT;
      END;
    END LOOP;
  END LOOP;
  COMMIT;
  write_log(TO_CHAR(l_rows_updated)||' row(s) updated in staging with store_number,split_order and aops_order_number');
  write_log(TO_CHAR(l_rec_err_cnt)||' row(s) updated in staging as errors');
  IF l_rec_err_cnt > 0 THEN
    p_retcode     := '2';
    p_error_msg   := TO_CHAR(l_rec_err_cnt)||' Order/Return records updated in staging as errors - check log/staging table for details';
  ELSE
    p_retcode := '0';
    write_log('XX_CE_MPL_SETTLEMENT_PKG.process_staging completed successfully');
  END IF;
EXCEPTION
WHEN OTHERS THEN
  IF stlmt_stg_cur%ISOPEN THEN
    CLOSE stlmt_stg_cur;
  END IF;
  p_retcode   := '2';
  p_error_msg := 'Error in XX_CE_MPL_SETTLEMENT_PKG.process_staging- Order'||l_order_id||'-'||SUBSTR(sqlerrm,1,240);
END process_staging;
-- +============================================================================================+
-- |  Name  : PROCESS_DATA_998                                                             |
-- |  Description: This procedure groups settlement data in XX_CE_MPL_SETTLEMENT_STG by order_no|
-- |               and inserts into XX_CE_AJB998 table.          |
-- =============================================================================================|
PROCEDURE process_data_998(
    p_process_name  VARCHAR2,
    p_settlement_id NUMBER,
    p_deposit_date  DATE,
    p_ajb_file_name VARCHAR2,
    p_error_msg OUT VARCHAR2,
    p_retcode OUT VARCHAR2)
AS
  CURSOR stlmt_stg_cur(p_settlement_id NUMBER)
  IS
    SELECT stg.settlement_id,
      stg.transaction_type,
      stg.aops_order_number,
      stg.order_id,
      stg.store_number,
      SUM(
      CASE
        WHEN stg.price_type IN('Principal','Shipping','ShippingTax','Tax')
        THEN to_number(stg.price_amount)
        ELSE 0
      END) Transaction_amt,
      --sum(price_amount) Transaction_amt,
      --sum(decode(price_type,'Principal',price_amount,'Shipping',price_amount,'ShippingTax',price_amount,'Tax',price_amount,0)) Transaction_amt,
      CAST(to_timestamp_tz(MAX(stg.posted_date), 'yyyy-mm-dd"T"hh24:mi:ss TZH:TZM') at TIME zone DBTIMEZONE AS DATE) posted_date
    FROM xx_ce_mpl_settlement_stg stg
    WHERE stg.transaction_type IN('Order','Adjustment')
      --AND record_status IS NULL
    AND stg.settlement_id = p_settlement_id
      --Defect#34514
    AND NOT EXISTS
      (SELECT 'x'
      FROM xx_ce_mpl_settlement_stg ostg
      WHERE ostg.settlement_id  = stg.settlement_id
      AND ostg.order_id         = stg.order_id
      AND ostg.transaction_type = 'Order'
      AND ostg.split_order      = 'N'
      AND EXISTS
        (SELECT 'x'
        FROM xx_ce_mpl_settlement_stg rstg
        WHERE ostg.settlement_id    = rstg.settlement_id
        AND ostg.order_id           = rstg.order_id
        AND rstg.transaction_type   = 'Adjustment'
        AND rstg.split_order        = 'N'
        AND rstg.aops_order_number IS NULL
        )
      )
    GROUP BY stg.settlement_id,
      stg.transaction_type,
      stg.aops_order_number,
      stg.order_id,
      stg.store_number
    ORDER BY stg.transaction_type DESC;
  TYPE stlmt_stg
IS
  TABLE OF stlmt_stg_cur%ROWTYPE INDEX BY PLS_INTEGER;
  l_stlmt_stg_tab stlmt_stg;
  /*--Defect#34514 If a refund exists in Amazon settlement file and it does not exist in ORDT then net total of refund and sales in the
  same file and create one record in 998.*/
  CURSOR stlmt_stg_cur1(p_settlement_id NUMBER)
  IS
    SELECT stg.settlement_id,
      stg.order_id,
      SUM(
      CASE
        WHEN stg.price_type IN('Principal','Shipping','ShippingTax','Tax')
        THEN to_number(stg.price_amount)
        ELSE 0
      END) Transaction_amt,
      CAST(to_timestamp_tz(MAX(stg.posted_date), 'yyyy-mm-dd"T"hh24:mi:ss TZH:TZM') at TIME zone DBTIMEZONE AS DATE) posted_date
    FROM xx_ce_mpl_settlement_stg stg
    WHERE stg.transaction_type IN('Order','Adjustment')
    AND stg.settlement_id       = p_settlement_id
    AND EXISTS
      (SELECT 'x'
      FROM xx_ce_mpl_settlement_stg ostg
      WHERE ostg.settlement_id  = stg.settlement_id
      AND ostg.order_id         = stg.order_id
      AND ostg.transaction_type = 'Order'
      AND ostg.split_order      = 'N'
      AND EXISTS
        (SELECT 'x'
        FROM xx_ce_mpl_settlement_stg rstg
        WHERE ostg.settlement_id    = rstg.settlement_id
        AND ostg.order_id           = rstg.order_id
        AND rstg.transaction_type   = 'Adjustment'
        AND rstg.split_order        = 'N'
        AND rstg.aops_order_number IS NULL
        )
      )
    GROUP BY settlement_id,
      order_id;
  TYPE stlmt_stg1
IS
  TABLE OF stlmt_stg_cur1%ROWTYPE INDEX BY PLS_INTEGER;
  l_stlmt_stg_tab1 stlmt_stg1;
  CURSOR get_order_details(p_settlement_id VARCHAR2,p_order_id VARCHAR2,p_transaction_type VARCHAR2)
  IS
    SELECT aops_order_number,
      store_number
    FROM xx_ce_mpl_settlement_stg
    WHERE settlement_id  = p_settlement_id
    AND order_id         = p_order_id
    AND transaction_type = p_transaction_type;
  l_error_msg                  VARCHAR2(1000);
  l_user_id                    NUMBER := NVL(fnd_global.user_id,0);
  l_login_id                   NUMBER := NVL(fnd_global.login_id,0);
  l_rec_succ_cnt               NUMBER := 0;
  indx                         NUMBER;
  l_batch_size                 NUMBER := 1000;
  l_record_type_998            VARCHAR2(30);
  l_action_code                NUMBER;
  l_provider_type              VARCHAR2(50);
  l_trx_type                   VARCHAR2(50);
  l_store_number               VARCHAR2(30);
  l_country_code               VARCHAR2(6);
  l_currency_code              VARCHAR2(10);
  l_bank_rec_id                VARCHAR2(50);
  l_deposit_date               DATE;
  l_processor_id               VARCHAR2(100);
  l_status_1310                VARCHAR2(30);
  l_ajb_file_name              VARCHAR2(200);
  l_org_id                     NUMBER;
  l_territory_code             VARCHAR2(2);
  l_currency                   VARCHAR2(15);
  l_card_type                  VARCHAR2(80);
  l_customer_receipt_reference VARCHAR2(80);
  l_order_id                   VARCHAR2(100);
BEGIN
  write_log('Processing 998 staging records...');
  --LLC Change  start
  BEGIN
    SELECT xftv.target_value13 ,
      xftv.target_value14 ,
      xftv.target_value15
    INTO l_processor_id ,
      l_provider_type ,
      l_card_type
    FROM xx_fin_translatedefinition xftd,
      xx_fin_translatevalues xftv
    WHERE XFTD.TRANSLATION_NAME = 'OD_SETTLEMENT_PROCESSES'
    AND xftv.source_value1      = p_process_name --'AMAZON_MWS'
    AND xftd.translate_id       = xftv.translate_id
    AND nvl(xftv.end_date_active ,sysdate+1) > sysdate;
  EXCEPTION
  WHEN OTHERS THEN
    --Need to check what could be the default value
    l_processor_id := 'AMAZON';
	l_provider_type := 'AMAZON';
    l_card_type     := 'AMAZON';
  END;
  --LLC Change  end
  l_deposit_date    := p_deposit_date;
  l_record_type_998 := '998';
  l_action_code     := 0;
  -- l_provider_type   := 'AMAZON';  -- LLC Change
  l_country_code  := '840';
  l_currency_code := '840';
  -- LLC Change  Start
  -- l_processor_id    := 'AMAZON';  -- llc change
  -- LLC Change  end
  l_bank_rec_id    := TO_CHAR(l_deposit_date,'YYYYMMDD');
  l_ajb_file_name  := p_ajb_file_name;
  l_status_1310    := 'NEW';
  l_org_id         := 404;
  l_territory_code := 'US';
  l_currency       := 'USD';
  -- l_card_type      := 'AMAZON'; -- LLC Change
  write_log('Processing Order/Refund(s) from staging...');
  OPEN stlmt_stg_cur(p_settlement_id);
  LOOP
    FETCH stlmt_stg_cur BULK COLLECT INTO l_stlmt_stg_tab LIMIT l_batch_size;
    EXIT
  WHEN l_stlmt_stg_tab.COUNT = 0;
    FOR indx IN l_stlmt_stg_tab.FIRST..l_stlmt_stg_tab.LAST
    LOOP
      l_order_id                               := l_stlmt_stg_tab(indx).order_id;
      IF l_stlmt_stg_tab(indx).transaction_type = 'Order' THEN
        l_trx_type                             := 'SALE';
      ELSE
        l_trx_type := 'REFUND';
      END IF;
      --Customer_receipt_reference and orig_sys_document_ref(aops_order_number) is going to be same for amazon.
      l_customer_receipt_reference := l_stlmt_stg_tab(indx).aops_order_number;
      l_store_number               := l_stlmt_stg_tab(indx).store_number;
      insert_ajb998(l_record_type_998, l_action_code, l_provider_type, l_store_number, l_trx_type, l_stlmt_stg_tab(indx).transaction_amt, l_customer_receipt_reference, l_country_code, l_currency_code, l_order_id, l_bank_rec_id, l_stlmt_stg_tab(indx).posted_date, l_processor_id, l_status_1310, l_ajb_file_name, l_user_id, l_user_id, l_org_id, l_deposit_date, l_territory_code, l_currency, l_card_type);
      l_rec_succ_cnt := l_rec_succ_cnt + 1;
    END LOOP;
  END LOOP;
  CLOSE stlmt_stg_cur;
  /*--Defect#34514 If a refund exists in Amazon settlement file and it does not exist in ORDT then net total of
  refund and sales in the same file and create one record in 998.*/
  write_log('Processing Net Order-Refund(s) from staging...');
  OPEN stlmt_stg_cur1(p_settlement_id);
  LOOP
    FETCH stlmt_stg_cur1 BULK COLLECT INTO l_stlmt_stg_tab1 LIMIT l_batch_size;
    EXIT
  WHEN l_stlmt_stg_tab1.COUNT = 0;
    FOR indx IN l_stlmt_stg_tab1.FIRST..l_stlmt_stg_tab1.LAST
    LOOP
      l_order_id                   := l_stlmt_stg_tab1(indx).order_id;
      l_trx_type                   := 'SALE'; --Order/returned combined record is always Order(SALE)
      l_store_number               := NULL;
      l_customer_receipt_reference := NULL;
      OPEN get_order_details(p_settlement_id,l_order_id,'Order');
      FETCH get_order_details INTO l_customer_receipt_reference,l_store_number;
      CLOSE get_order_details;
      /*Defect#34514 V1.5 changes - if order has a store number and refund has default store number
      then update refund records with order store number */
      IF l_store_number <> '010000' THEN
        UPDATE xx_ce_mpl_settlement_stg
        SET aops_order_number = l_customer_receipt_reference ,
          store_number        = l_store_number ,
          last_updated_by     = l_user_id ,
          last_update_date    = sysdate ,
          last_update_login   = l_login_id
        WHERE settlement_id   = p_settlement_id
        AND order_id          = l_order_id
        AND transaction_type  = 'Adjustment';
      END IF;
      insert_ajb998(l_record_type_998, l_action_code, l_provider_type, l_store_number, l_trx_type, l_stlmt_stg_tab1(indx).transaction_amt, l_customer_receipt_reference, l_country_code, l_currency_code, l_order_id, l_bank_rec_id, l_stlmt_stg_tab1(indx).posted_date, l_processor_id, l_status_1310, l_ajb_file_name, l_user_id, l_user_id, l_org_id, l_deposit_date, l_territory_code, l_currency, l_card_type);
      l_rec_succ_cnt := l_rec_succ_cnt + 1;
    END LOOP;
  END LOOP;
  CLOSE stlmt_stg_cur1;
  write_log(TO_CHAR(l_rec_succ_cnt)||' records successfully loaded in 998');
  write_log('process_data_998 completed successfully');
  p_retcode := '0';
EXCEPTION
WHEN OTHERS THEN
  write_log('Error in XX_CE_MPL_SETTLEMENT_PKG.process_data_998- Order'||l_order_id||'-'||SUBSTR(sqlerrm,1,240));
  ROLLBACK;
  write_log('rolled back all the updates to 998');
  IF stlmt_stg_cur%ISOPEN THEN
    CLOSE stlmt_stg_cur;
  END IF;
  IF stlmt_stg_cur1%ISOPEN THEN
    CLOSE stlmt_stg_cur1;
  END IF;
  p_retcode   := '2';
  p_error_msg := 'Error in XX_CE_MPL_SETTLEMENT_PKG.process_data_998- Order'||l_order_id||'-'||SUBSTR(sqlerrm,1,240);
END process_data_998;
-- +============================================================================================+
-- |  Name  : PROCESS_DATA_999                                                             |
-- |  Description: This procedure groups settlement data in XX_CE_MPL_SETTLEMENT_STG by store |
-- |               and inserts into XX_CE_AJB999 table.         |
-- =============================================================================================|
PROCEDURE process_data_999(
    p_process_name  VARCHAR2,
    p_settlement_id NUMBER,
    p_deposit_date  DATE,
    p_ajb_file_name VARCHAR2,
    p_error_msg OUT VARCHAR2,
    p_retcode OUT VARCHAR2)
AS
  CURSOR stlmt_stg_cur(p_settlement_id NUMBER)
  IS
    SELECT sstg.settlement_id,
      sstg.store_number,
      SUM(
      CASE
        WHEN price_type IN('Principal','Shipping','ShippingTax','Tax')
        THEN to_number(price_amount)
        ELSE 0
      END) net_sales,
      SUM(
      CASE
        WHEN item_related_fee_type IN('Commission','SalesTaxServiceFee','ShippingHB','RefundCommission')
        THEN to_number(item_related_fee_amount)
        ELSE 0
      END) item_fees,
      --sum(sstg.item_related_fee_amount) item_related_fee_amount,
      CAST(to_timestamp_tz(MAX(sstg.posted_date), 'yyyy-mm-dd"T"hh24:mi:ss TZH:TZM') at TIME zone DBTIMEZONE AS DATE) posted_date
    FROM xx_ce_mpl_settlement_stg sstg
    WHERE transaction_type IN('Order','Adjustment')
      --AND record_status IS NULL
    AND settlement_id = p_settlement_id
    GROUP BY settlement_id,
      sstg.store_number;
TYPE stlmt_stg
IS
  TABLE OF stlmt_stg_cur%ROWTYPE INDEX BY PLS_INTEGER;
  l_stlmt_stg_tab stlmt_stg;
  CURSOR Tot_ItemPrice_cur(p_settlement_id NUMBER)
  IS
    SELECT NVL(SUM(
      CASE
        WHEN price_type IN('Principal','Shipping','ShippingTax','Tax')
        THEN to_number(price_amount)
        ELSE 0
      END),0) Total_ItemPrice
    FROM xx_ce_mpl_settlement_stg
    WHERE transaction_type IN('Order','Adjustment')
    AND settlement_id       = p_settlement_id;
  /*V2 version changes added subscription fee*/
  CURSOR other_amount_cur(p_settlement_id NUMBER)
  IS
    SELECT NVL(SUM(other_amount),0)
    FROM xx_ce_mpl_settlement_stg
    WHERE transaction_type IN('Previous Reserve Amount Balance','Current Reserve Amount','Subscription Fee')
    AND settlement_id       = p_settlement_id;
  CURSOR variable_fee_cur(p_settlement_id NUMBER)
  IS
    SELECT NVL(SUM(item_related_fee_amount),0) variableclosingfee
    FROM xx_ce_mpl_settlement_stg
    WHERE item_related_fee_type = 'VariableClosingFee'
    AND settlement_id           = p_settlement_id;
  l_error_msg            VARCHAR2(1000);
  l_user_id              NUMBER := NVL(fnd_global.user_id,0);
  l_login_id             NUMBER := NVL(fnd_global.login_id,0);
  l_rec_succ_cnt         NUMBER := 0;
  indx                   NUMBER;
  l_batch_size           NUMBER := 1000;
  l_provider_type        VARCHAR2(50);
  l_trx_type             VARCHAR2(50);
  l_store_number         VARCHAR2(30);
  l_country_code         VARCHAR2(6);
  l_currency_code        VARCHAR2(10);
  l_bank_rec_id          VARCHAR2(50);
  l_deposit_date         DATE;
  l_processor_id         VARCHAR2(100);
  l_status_1310          VARCHAR2(30);
  l_ajb_file_name        VARCHAR2(200);
  l_org_id               NUMBER;
  l_territory_code       VARCHAR2(2);
  l_currency             VARCHAR2(15);
  l_card_type            VARCHAR2(80);
  l_order_number         NUMBER;
  l_net_sales            NUMBER;
  l_total_itemprice      NUMBER;
  l_record_type_999      VARCHAR2(30);
  l_submission_date      DATE;
  l_item_fees            NUMBER;
  l_other_amt            NUMBER;
  l_variableclosingfees  NUMBER;
  l_total_fees_for_store NUMBER;
BEGIN
  write_log('Processing 999 staging records...');
  write_log('Processing Order/Refund(s) from staging with status as PROCESSED_998...');
  -- BEGIN
  write_log('Processing 998 staging records...');
  --llc change  start
  BEGIN
    SELECT xftv.target_value13 ,
      xftv.target_value14 ,
      xftv.target_value15
    INTO l_processor_id ,
      l_provider_type ,
      l_card_type
    FROM xx_fin_translatedefinition xftd,
      xx_fin_translatevalues xftv
    WHERE XFTD.TRANSLATION_NAME = 'OD_SETTLEMENT_PROCESSES'
    AND xftv.source_value1      = p_process_name --'AMAZON_MWS'
    AND xftd.translate_id       = xftv.translate_id
    AND nvl(xftv.end_date_active ,sysdate+1) > sysdate;
  EXCEPTION
  WHEN OTHERS THEN
    --Need to check what could be the default value
    l_processor_id  := 'AMAZON';
    l_provider_type := 'AMAZON';
    l_card_type     := 'AMAZON';
  END;
  --llc change  end
  l_deposit_date    := p_deposit_date;
  l_record_type_999 := '999';
  l_submission_date := l_deposit_date;
  --l_provider_type   := 'AMAZON'; --LLC Change
  l_country_code  := '840';
  l_currency_code := '840';
  l_bank_rec_id   := TO_CHAR(l_deposit_date,'YYYYMMDD');
  -- l_processor_id    := 'AMAZON'; -- LLC Change
  l_ajb_file_name  := p_ajb_file_name;
  l_status_1310    := 'NEW';
  l_org_id         := 404;
  l_territory_code := 'US';
  l_currency       := 'USD';
  --l_card_type      := 'AMAZON'; --LLC Change
  OPEN Tot_ItemPrice_cur(p_settlement_id);
  FETCH Tot_ItemPrice_cur INTO l_total_itemprice;
  CLOSE Tot_ItemPrice_cur;
  OPEN other_amount_cur(p_settlement_id);
  FETCH other_amount_cur INTO l_other_amt;
  CLOSE other_amount_cur;
  OPEN variable_fee_cur(p_settlement_id);
  FETCH variable_fee_cur INTO l_variableclosingfees;
  CLOSE variable_fee_cur;
  OPEN stlmt_stg_cur(p_settlement_id);
  LOOP
    FETCH stlmt_stg_cur BULK COLLECT INTO l_stlmt_stg_tab LIMIT l_batch_size;
    EXIT
  WHEN l_stlmt_stg_tab.COUNT = 0;
    FOR indx IN l_stlmt_stg_tab.FIRST..l_stlmt_stg_tab.LAST
    LOOP
      /*Amount-Type.ItemFee?s  or Other-Transaction by Location
      (Commission + SalesTaxSerivceFee + ShippingHB + Refund Commission) +
      (Previous Reserve Amount Balance + Current Reserve Amount+VariableClosingFee*Total of location/total of ItemPriceof Settlment File)*/
      l_store_number := l_stlmt_stg_tab(indx).store_number;
      l_net_sales    := l_stlmt_stg_tab(indx).net_sales;
      l_item_fees    := l_stlmt_stg_tab(indx).item_fees;
      --Defect#34376 absolute value. Defect#34377 round to two decimals
      --Defect#34508 Change sign based on net sales
      l_total_fees_for_store := ABS(ROUND(l_item_fees + ((l_other_amt + l_variableclosingfees)*l_net_sales/l_total_itemprice),2));
      --Defect#34508 Change sign based on net sales
      IF l_net_sales            < 0 THEN
        l_total_fees_for_store := -1 * l_total_fees_for_store;
      END IF;
      insert_ajb999(l_record_type_999, l_store_number, l_provider_type, l_submission_date, l_country_code, l_currency_code, l_processor_id, l_bank_rec_id, l_card_type, l_net_sales, l_total_fees_for_store, l_status_1310, l_ajb_file_name, l_user_id, l_user_id, l_org_id, l_deposit_date, l_territory_code, l_currency);
      l_rec_succ_cnt := l_rec_succ_cnt + 1;
    END LOOP;
  END LOOP;
  write_log(TO_CHAR(l_rec_succ_cnt)||' records successfully loaded into 999');
  write_log('process_data_999 completed successfully');
  p_retcode := '0';
EXCEPTION
WHEN OTHERS THEN
  write_log('999 Load failed - Error in XX_CE_MPL_SETTLEMENT_PKG.process_data_999-Store'||l_store_number||'-'||SUBSTR(sqlerrm,1,240));
  ROLLBACK;
  write_log('rolled back all the updates to 998 and 999');
  IF stlmt_stg_cur%ISOPEN THEN
    CLOSE stlmt_stg_cur;
  END IF;
  p_retcode   := '2';
  p_error_msg := '999 Load failed - Error in XX_CE_MPL_SETTLEMENT_PKG.process_data_999-Store'||l_store_number||'-'||SUBSTR(sqlerrm,1,240);
END process_data_999;
PROCEDURE insert_ajb998(
    p_record_type     VARCHAR2 ,
    p_action_code     VARCHAR2 ,
    p_provider_type   VARCHAR2 ,
    p_store_num       VARCHAR2 ,
    p_trx_type        VARCHAR2 ,
    p_trx_amount      NUMBER ,
    p_invoice_num     VARCHAR2 ,
    p_country_code    VARCHAR2 ,
    p_currency_code   VARCHAR2 ,
    p_receipt_num     VARCHAR2 ,
    p_bank_rec_id     VARCHAR2 ,
    p_trx_date        DATE ,
    p_processor_id    VARCHAR2 ,
    p_status_1310     VARCHAR2 ,
    p_ajb_file_name   VARCHAR2 ,
    p_created_by      NUMBER ,
    p_last_updated_by NUMBER ,
    p_org_id          NUMBER ,
    p_recon_date      DATE ,
    p_territory_code  VARCHAR2 ,
    p_currency        VARCHAR2 ,
    p_card_type       VARCHAR2)
AS
  l_sequence_id_998 NUMBER;
BEGIN
  SELECT xx_ce_ajb998_s.nextval INTO l_sequence_id_998 FROM dual;
  --Populating settlementid in AJB_FILE_NAME and using that for duplicate checking
  INSERT
  INTO xx_ce_ajb998
    (
      record_type,
      action_code,
      provider_type,
      store_num,
      trx_type,
      trx_amount,
      invoice_num,
      country_code,
      currency_code,
      receipt_num,
      bank_rec_id,
      trx_date,
      processor_id,
      status_1310,
      sequence_id_998,
      ajb_file_name,
      creation_date,
      created_by,
      last_update_date,
      last_updated_by,
      org_id,
      recon_date,
      territory_code,
      currency,
      card_type,
	  status --Added for V1.6 Defect 43424
    )
    VALUES
    (
      p_record_type,
      p_action_code,
      p_provider_type,
      p_store_num,
      p_trx_type,
      p_trx_amount,
      p_invoice_num,
      p_country_code,
      p_currency_code,
      p_receipt_num,
      p_bank_rec_id,
      p_trx_date,
      p_processor_id,
      p_status_1310,
      l_sequence_id_998,
      p_ajb_file_name,
      sysdate,
      p_created_by,
      sysdate,
      p_last_updated_by,
      p_org_id,
      p_recon_date,
      p_territory_code,
      p_currency,
      p_card_type,
	  'NEW'--Added for V1.6 Defect 43424
    );
END insert_ajb998;
PROCEDURE insert_ajb999
  (
    p_record_type     VARCHAR2,
    p_store_num       VARCHAR2,
    p_provider_type   VARCHAR2,
    p_submission_date DATE,
    p_country_code    VARCHAR2,
    p_currency_code   VARCHAR2,
    p_processor_id    VARCHAR2,
    p_bank_rec_id     VARCHAR2,
    p_cardtype        VARCHAR2,
    p_net_sales       NUMBER,
    p_cost_funds_amt  NUMBER,
    p_status_1310     VARCHAR2,
    p_ajb_file_name   VARCHAR2,
    p_created_by      VARCHAR2,
    p_last_updated_by VARCHAR2,
    p_org_id          NUMBER,
    p_recon_date      DATE,
    p_territory_code  VARCHAR2,
    p_currency        VARCHAR2
  )
AS
  l_sequence_id_999 NUMBER;
BEGIN
  SELECT xx_ce_ajb999_s.nextval INTO l_sequence_id_999 FROM dual;
  INSERT
  INTO xx_ce_ajb999
    (
      record_type,
      store_num,
      provider_type,
      submission_date,
      country_code,
      currency_code,
      processor_id,
      bank_rec_id,
      cardtype,
      net_sales,
      cost_funds_amt,
      status_1310,
      sequence_id_999,
      ajb_file_name,
      creation_date,
      created_by,
      last_update_date,
      last_updated_by,
      org_id,
      recon_date,
      territory_code,
      currency,
	  status--Added for V1.6 Defect 43424
    )
    VALUES
    (
      p_record_type,
      p_store_num,
      p_provider_type,
      p_submission_date,
      p_country_code,
      p_currency_code,
      p_processor_id,
      p_bank_rec_id,
      p_cardtype,
      p_net_sales,
      p_cost_funds_amt,
      p_status_1310,
      l_sequence_id_999,
      p_ajb_file_name,
      sysdate,
      p_created_by,
      sysdate,
      p_last_updated_by,
      p_org_id,
      p_recon_date,
      p_territory_code,
      p_currency,
	  'NEW'--Added for V1.6 Defect 43424
    );
END insert_ajb999;
-- +===========================================================================
-- =================+
-- |  Name  : MAIN_LLC
-- |
-- |  Description: Main procedure to process and load data from staging to 998/
-- 999 tables. |
-- ============================================================================
-- =================|
PROCEDURE main_llc
  (
    p_errbuf OUT VARCHAR2 ,
    P_RETCODE OUT VARCHAR2 ,
    p_process_name  VARCHAR2,
    p_settlement_id NUMBER
  )
AS
  CURSOR settlement_id_cur
  IS
    SELECT settlement_id,
      CAST(to_timestamp_tz(DEPOSIT_DATE, 'yyyy-mm-dd"T"hh24:mi:ss TZH:TZM') at TIME zone DBTIMEZONE AS DATE) deposit_date
    FROM xx_ce_mpl_settlement_stg
    WHERE transaction_type IS NULL
    AND record_status      IS NULL;
  CURSOR val_settlement_id_cur(p_settlement_id NUMBER)
  IS
    SELECT settlement_id,
      CAST(to_timestamp_tz(DEPOSIT_DATE, 'yyyy-mm-dd"T"hh24:mi:ss TZH:TZM') at TIME zone DBTIMEZONE AS DATE) deposit_date
    FROM xx_ce_mpl_settlement_stg
    WHERE transaction_type IS NULL
    AND settlement_id       = p_settlement_id;
TYPE settlement_id
IS
  TABLE OF settlement_id_cur%ROWTYPE INDEX BY PLS_INTEGER;
  l_settlement_id_tab settlement_id;
  l_file_name           VARCHAR2(200);
  l_ajb_file_name       VARCHAR2(200);
  l_error_msg           VARCHAR2(500);
  l_error_loc           VARCHAR2(2000);
  l_retcode             VARCHAR2(3);
  l_settlement_id       NUMBER;
  l_deposit_date        DATE;
  l_rows_updated        NUMBER := 0;
  l_user_id             NUMBER := NVL(fnd_global.user_id,0);
  l_login_id            NUMBER := NVL(fnd_global.login_id,0);
  INVALID_SETTLEMENT_ID EXCEPTION;
  PROCESS_DATA_ERROR    EXCEPTION;
  no_data_to_process    EXCEPTION;
BEGIN
  l_error_loc := 'Start main process..';
  write_log(l_error_loc);
  BEGIN
    SELECT xftv.target_value9
    INTO l_file_name
    FROM xx_fin_translatedefinition xftd,
      xx_fin_translatevalues xftv
    WHERE XFTD.TRANSLATION_NAME = 'OD_SETTLEMENT_PROCESSES'
    AND xftv.source_value1      = p_process_name --'AMAZON_MWS'  --llc change
    AND xftd.translate_id       = xftv.translate_id
    AND nvl(xftv.end_date_active ,sysdate+1) > sysdate;
  EXCEPTION
  WHEN OTHERS THEN
    --Need to check what could be the default value
    l_file_name := 'AmazonSettlement.txt';
  END;
  l_settlement_id := NULL;
  /* settlement_id value is passed to the program*/
  IF p_settlement_id IS NOT NULL THEN
    /*validate settlment_id, select the deposit date*/
    l_error_loc := 'Validating the settlement_id:'||TO_CHAR(p_settlement_id);
    write_log(l_error_loc);
    OPEN val_settlement_id_cur(p_settlement_id);
    FETCH val_settlement_id_cur INTO l_settlement_id, l_deposit_date;
    CLOSE val_settlement_id_cur;
    IF l_settlement_id IS NULL THEN
      l_error_msg      := 'ERROR Invalid settlement_id:'||TO_CHAR( p_settlement_id);
      l_retcode        := '2';
      raise INVALID_SETTLEMENT_ID;
    END IF;
  END IF;
  /* if no settlement_id is passed to the program then select new settlement id
  */
  IF p_settlement_id IS NULL THEN
    OPEN settlement_id_cur;
    FETCH settlement_id_cur INTO l_settlement_id, l_deposit_date;
    CLOSE settlement_id_cur;
    IF l_settlement_id IS NULL THEN
      l_error_loc      := 'No new settlement data to process in staging table..';
      write_log(l_error_loc);
      raise NO_DATA_TO_PROCESS;
    END IF;
  END IF;
  l_ajb_file_name := l_file_name||TO_CHAR(l_settlement_id);
  /*Check if the settlement id already has records in 998 and 999 using
  ajb_file_name*/
  l_error_loc := 'Checking if ajb_file_name:'||l_ajb_file_name|| ' exists in 998/999 tables';
  write_log(l_error_loc);
  l_retcode   := NULL;
  l_error_msg := NULL;
  duplicate_check(l_ajb_file_name,l_error_msg,l_retcode);
  IF l_retcode = '2' THEN
    raise PROCESS_DATA_ERROR;
  END IF;
  l_error_loc := 'Processing Settlement_id:'||TO_CHAR(l_settlement_id);
  write_log(l_error_loc);
  l_retcode   := NULL;
  l_error_msg := NULL;
  process_staging(l_settlement_id,l_error_msg,l_retcode);
  IF l_retcode = '2' THEN
    raise PROCESS_DATA_ERROR;
  END IF;
  l_error_loc := 'Processing 998 data for Settlement_id:'||TO_CHAR( l_settlement_id);
  write_log(l_error_loc);
  l_retcode   := NULL;
  l_error_msg := NULL;
  -- LLC Changes start
  -- process_data_998(l_settlement_id,l_deposit_date,l_ajb_file_name,l_error_msg, l_retcode);
  process_data_998(p_process_name,l_settlement_id,l_deposit_date,l_ajb_file_name,l_error_msg, l_retcode);
  -- LLC Changes end
  IF l_retcode = '2' THEN
    raise PROCESS_DATA_ERROR;
  END IF;
  l_error_loc := 'Processing 999 data for Settlement_id:'||TO_CHAR( l_settlement_id);
  write_log(l_error_loc);
  l_retcode   := NULL;
  l_error_msg := NULL;
  -- LLC Changes start
  -- process_data_999(l_settlement_id,l_deposit_date,l_ajb_file_name,l_error_msg, l_retcode);
  process_data_999(p_process_name,l_settlement_id,l_deposit_date,l_ajb_file_name,l_error_msg, l_retcode);
  -- LLC Changes end
  IF l_retcode = '2' THEN
    raise PROCESS_DATA_ERROR;
  END IF;
  l_error_loc := 'Updating settlement(settlement_id:'||TO_CHAR(l_settlement_id) ||') records as PROCESSED in staging';
  write_log(l_error_loc);
  --Update the settlement records as processed
  UPDATE xx_ce_mpl_settlement_stg
  SET record_status   = 'PROCESSED',
    last_updated_by   = l_user_id,
    last_update_date  = sysdate,
    last_update_login = l_login_id
  WHERE settlement_id = l_settlement_id;
  l_rows_updated     := SQL%ROWCOUNT;
  write_log(TO_CHAR(l_rows_updated)|| ' record(s) updated as PROCESSED in staging');
  write_log(l_error_loc);
  COMMIT;
  p_retcode := '0';
EXCEPTION
WHEN NO_DATA_TO_PROCESS THEN
  p_retcode := '0';
WHEN INVALID_SETTLEMENT_ID THEN
  p_errbuf  := l_error_msg;
  p_retcode := l_retcode;
  log_exception (p_program_name => 'XXCEMPLPRC' ,p_error_location => l_error_loc ,p_error_msg => l_error_msg);
WHEN PROCESS_DATA_ERROR THEN
  --Update the settlement header record as error
  write_log('Updating settlement(settlment_id:'||TO_CHAR(l_settlement_id)|| ') header record as ERROR in staging');
  UPDATE xx_ce_mpl_settlement_stg
  SET record_status     = 'ERROR',
    error_description   = l_error_msg,
    last_updated_by     = l_user_id,
    last_update_date    = sysdate,
    last_update_login   = l_login_id
  WHERE settlement_id   = l_settlement_id
  AND transaction_type IS NULL;
  l_rows_updated       := SQL%ROWCOUNT;
  write_log(TO_CHAR(l_rows_updated)||' record(s) updated as ERROR in staging');
  COMMIT;
  p_errbuf  := l_error_msg;
  p_retcode := l_retcode;
  log_exception (p_program_name => 'XXCEMPLPRC' ,p_error_location => l_error_loc ,p_error_msg => l_error_msg);
WHEN OTHERS THEN
  l_error_msg := 'Others Exception in XX_CE_MPL_SETTLEMENT_PKG.main_llc procedure ' ||SUBSTR(SQLERRM,1,240);
  p_errbuf    := l_error_msg;
  p_retcode   := '2';
  Log_Exception (P_Program_Name => 'XXCEMPLPRC' ,P_Error_Location => L_Error_Loc ,P_Error_Msg => L_Error_Msg);
END main_llc;
-- +============================================================================================+
-- |  Name  : MAIN                                                               |
-- |  Description: Main procedure to process and load data from staging to 998/999 tables. |
-- =============================================================================================|
/*PROCEDURE main
(
p_errbuf OUT VARCHAR2 ,
p_retcode OUT VARCHAR2 ,
p_settlement_id NUMBER
)
AS
CURSOR settlement_id_cur
IS
SELECT settlement_id,
CAST(to_timestamp_tz(DEPOSIT_DATE, 'yyyy-mm-dd"T"hh24:mi:ss TZH:TZM') at TIME zone DBTIMEZONE AS DATE) deposit_date
FROM xx_ce_mpl_settlement_stg
WHERE transaction_type IS NULL
AND record_status      IS NULL;
CURSOR val_settlement_id_cur(p_settlement_id NUMBER)
IS
SELECT settlement_id,
CAST(to_timestamp_tz(DEPOSIT_DATE, 'yyyy-mm-dd"T"hh24:mi:ss TZH:TZM') at TIME zone DBTIMEZONE AS DATE) deposit_date
FROM xx_ce_mpl_settlement_stg
WHERE transaction_type IS NULL
AND settlement_id       = p_settlement_id;
TYPE settlement_id
IS
TABLE OF settlement_id_cur%ROWTYPE INDEX BY PLS_INTEGER;
l_settlement_id_tab settlement_id;
l_file_name           VARCHAR2(200);
l_ajb_file_name       VARCHAR2(200);
l_error_msg           VARCHAR2(500);
l_error_loc           VARCHAR2(2000);
l_retcode             VARCHAR2(3);
l_settlement_id       NUMBER;
l_deposit_date        DATE;
l_rows_updated        NUMBER := 0;
l_user_id             NUMBER := NVL(fnd_global.user_id,0);
l_login_id            NUMBER := NVL(fnd_global.login_id,0);
INVALID_SETTLEMENT_ID EXCEPTION;
PROCESS_DATA_ERROR    EXCEPTION;
NO_DATA_TO_PROCESS    EXCEPTION;
BEGIN
l_error_loc := 'Start main process..';
write_log(l_error_loc);
BEGIN
SELECT xftv.Target_value9
INTO l_file_name
FROM xx_fin_translatedefinition xftd,
xx_fin_translatevalues xftv
WHERE xftd.translation_name = 'OD_SETTLEMENT_PROCESSES'
AND xftv.source_value1      = 'AMAZON_MWS'
AND xftd.translate_id       = xftv.translate_id;
EXCEPTION
WHEN OTHERS THEN
--Need to check what could be the default value
l_file_name := 'AmazonSettlement.txt';
END;
l_settlement_id := NULL;
/* settlement_id value is passed to the program*/
/*IF p_settlement_id IS NOT NULL THEN
/*validate settlment_id, select the deposit date*/
/* l_error_loc := 'Validating the settlement_id:'||TO_CHAR(p_settlement_id);
write_log(l_error_loc);
OPEN val_settlement_id_cur(p_settlement_id);
FETCH val_settlement_id_cur INTO l_settlement_id,l_deposit_date;
CLOSE val_settlement_id_cur;
IF l_settlement_id IS NULL THEN
l_error_msg      := 'ERROR Invalid settlement_id:'||TO_CHAR(p_settlement_id);
l_retcode        := '2';
raise INVALID_SETTLEMENT_ID;
END IF;
END IF;
/* if no settlement_id is passed to the program then select new settlement id*/
/*IF p_settlement_id IS NULL THEN
OPEN settlement_id_cur;
FETCH settlement_id_cur INTO l_settlement_id,l_deposit_date;
CLOSE settlement_id_cur;
IF l_settlement_id IS NULL THEN
l_error_loc      := 'No new settlement data to process in staging table..';
write_log(l_error_loc);
raise NO_DATA_TO_PROCESS;
END IF;
END IF;
l_ajb_file_name := l_file_name||TO_CHAR(l_settlement_id);
/*Check if the settlement id already has records in 998 and 999 using ajb_file_name*/
/*l_error_loc := 'Checking if ajb_file_name:'||l_ajb_file_name||' exists in 998/999 tables';
write_log(l_error_loc);
l_retcode   := NULL;
l_error_msg := NULL;
duplicate_check(l_ajb_file_name,l_error_msg,l_retcode);
IF l_retcode = '2' THEN
raise PROCESS_DATA_ERROR;
END IF;
l_error_loc := 'Processing Settlement_id:'||TO_CHAR(l_settlement_id);
write_log(l_error_loc);
l_retcode   := NULL;
l_error_msg := NULL;
process_staging(l_settlement_id,l_error_msg,l_retcode);
IF l_retcode = '2' THEN
raise PROCESS_DATA_ERROR;
END IF;
l_error_loc := 'Processing 998 data for Settlement_id:'||TO_CHAR(l_settlement_id);
write_log(l_error_loc);
l_retcode   := NULL;
l_error_msg := NULL;
process_data_998(l_settlement_id,l_deposit_date,l_ajb_file_name,l_error_msg,l_retcode);
IF l_retcode = '2' THEN
raise PROCESS_DATA_ERROR;
END IF;
l_error_loc := 'Processing 999 data for Settlement_id:'||TO_CHAR(l_settlement_id);
write_log(l_error_loc);
l_retcode   := NULL;
l_error_msg := NULL;
process_data_999(l_settlement_id,l_deposit_date,l_ajb_file_name,l_error_msg,l_retcode);
IF l_retcode = '2' THEN
raise PROCESS_DATA_ERROR;
END IF;
l_error_loc := 'Updating settlement(settlement_id:'||TO_CHAR(l_settlement_id)||') records as PROCESSED in staging';
write_log(l_error_loc);
--Update the settlement records as processed
UPDATE xx_ce_mpl_settlement_stg
SET record_status   = 'PROCESSED',
last_updated_by   = l_user_id,
last_update_date  = sysdate,
last_update_login = l_login_id
WHERE settlement_id = l_settlement_id;
l_rows_updated     := SQL%ROWCOUNT;
write_log(TO_CHAR(l_rows_updated)||' record(s) updated as PROCESSED in staging');
write_log(l_error_loc);
COMMIT;
p_retcode := '0';
EXCEPTION
WHEN NO_DATA_TO_PROCESS THEN
p_retcode := '0';
WHEN INVALID_SETTLEMENT_ID THEN
p_errbuf  := l_error_msg;
p_retcode := l_retcode;
log_exception (p_program_name => 'XXCEMPLPRC' ,p_error_location => l_error_loc ,p_error_msg => l_error_msg);
WHEN PROCESS_DATA_ERROR THEN
--Update the settlement header record as error
write_log('Updating settlement(settlment_id:'||TO_CHAR(l_settlement_id)||') header record as ERROR in staging');
UPDATE xx_ce_mpl_settlement_stg
SET record_status     = 'ERROR',
error_description   = l_error_msg,
last_updated_by     = l_user_id,
last_update_date    = sysdate,
last_update_login   = l_login_id
WHERE settlement_id   = l_settlement_id
AND transaction_type IS NULL;
l_rows_updated       := SQL%ROWCOUNT;
write_log(TO_CHAR(l_rows_updated)||' record(s) updated as ERROR in staging');
COMMIT;
p_errbuf  := l_error_msg;
p_retcode := l_retcode;
log_exception (p_program_name => 'XXCEMPLPRC' ,p_error_location => l_error_loc ,p_error_msg => l_error_msg);
WHEN OTHERS THEN
l_error_msg := 'Others Exception in XX_CE_MPL_SETTLEMENT_PKG.main procedure '||SUBSTR(SQLERRM,1,240);
p_errbuf    := l_error_msg;
p_retcode   := '2';
Log_Exception (P_Program_Name => 'XXCEMPLPRC' ,P_Error_Location => L_Error_Loc ,P_Error_Msg => L_Error_Msg);
END main;
*/
-- +===================================================================+
-- | Name  : WRITE_OUT                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program output file                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE write_out(
    p_message IN VARCHAR2 )
IS
  ---------------------------
  --Declaring local variables
  ---------------------------
  lc_error_message VARCHAR2(2000);
  lc_set_message   VARCHAR2(2000);
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
END write_out;
-- +===================================================================+
-- | Name  : WRITE_LOG                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program log file                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE write_log(
    p_message IN VARCHAR2 )
IS
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
END Write_Log;
-- +===========================================================================
-- =================+
-- |  Name  : main_wrapper
-- |
-- |  Description: Main procedure to process exceute 3 stage programs sequentially
-- |               OD MPL Invoke Settlement
-- |               OD CE MPL Stage Settlement
-- |               OD CE MPL Process Settlement
-- ============================================================================
-- =================|
PROCEDURE main_wraper(
    p_errbuf OUT VARCHAR2 ,
    P_RETCODE OUT VARCHAR2 ,
    P_PROCESS_NAME VARCHAR2,
    p_report_id    VARCHAR2 )
AS
  X NUMBER;
  CURSOR C1
  IS
    SELECT XFTV.SOURCE_VALUE1 process_name ,
      XFTV.TARGET_VALUE9 file_name
    FROM xx_fin_translatedefinition xftd,
      xx_fin_translatevalues xftv
    WHERE Xftd.Translation_Name = 'OD_SETTLEMENT_PROCESSES'
    AND XFTD.TRANSLATE_ID       = XFTV.TRANSLATE_ID
    AND nvl(xftv.end_date_active ,sysdate+1) > sysdate
    AND XFTV.TARGET_VALUE12     = P_PROCESS_NAME
      ---- LLC Change for specific report process start
    AND ( NVL(P_REPORT_ID,'X') = 'X'
    OR (NVL(P_REPORT_ID,'X')  <> 'X'
    AND ROWNUM                 < 2))
      -- LLC Change for specific report process End
    ORDER BY XFTV.SOURCE_VALUE1,
      XFTV.Target_value11;
  ln_conc_id    NUMBER;
  LB_BOOL       BOOLEAN;
  lc_phase      VARCHAR2(100);
  Lc_Status     VARCHAR2(100);
  lc_dev_phase  VARCHAR2(100);
  Lc_Dev_Status VARCHAR2(100);
  Lc_Message    VARCHAR2(100);
  l_settlement_id Xx_Ce_Mpl_Settlement_Stg.Settlement_Id%type := 0;
BEGIN
  FOR I IN C1
  LOOP
    L_Settlement_Id := 0;
    -- Start OD MPL Invoke Settlement
    Write_Log('OD MPL Invoke Settlement, parameter - Process Name  '||I.Process_Name);
    BEGIN
      ln_conc_id := fnd_request.submit_request( application => 'XXFIN' ,program => 'XXCEMPLINVK' ,description => NULL ,start_time => SYSDATE ,sub_request => FALSE ,argument1 => i.process_name ,argument2 => p_report_id);
      COMMIT;
      LB_BOOL := FND_CONCURRENT.WAIT_FOR_REQUEST(LN_CONC_ID ,5 ,5000 ,LC_PHASE ,LC_STATUS ,LC_DEV_PHASE ,LC_DEV_STATUS ,LC_MESSAGE );
    EXCEPTION
    WHEN OTHERS THEN
      Fnd_File.Put_Line(Fnd_File.Log,'Error:'|| Sqlerrm);
      FND_FILE.PUT_LINE(FND_FILE.output,'Error:'|| SQLERRM);
    END;
    --
    -- Start OD CE MPL Stage Settlement file Name
    Write_Log('OD CE MPL Stage Settlement file Name, parameter -  '||I.File_Name);
    BEGIN
      ln_conc_id := fnd_request.submit_request( application => 'XXFIN' ,program => 'XXCEMPLSTG' ,description => NULL ,start_time => SYSDATE ,sub_request => FALSE ,argument1 => I.File_Name );
      COMMIT;
      LB_BOOL := FND_CONCURRENT.WAIT_FOR_REQUEST(LN_CONC_ID ,5 ,5000 ,LC_PHASE ,LC_STATUS ,LC_DEV_PHASE ,LC_DEV_STATUS ,LC_MESSAGE );
      FND_FILE.PUT_LINE(FND_FILE.LOG,'LC_PHASE '||' '||LC_PHASE||' '||'LC_STATUS'||' '||LC_STATUS||'LC_MESSAGE'||' '||LC_MESSAGE);
      IF ( LC_PHASE = 'Completed' AND LC_STATUS = 'Normal') THEN
        --  get settlement ID
        BEGIN
          SELECT Settlement_Id
          INTO l_settlement_id
          FROM Xx_Ce_Mpl_Settlement_Stg
          WHERE Request_Id = ln_conc_id
          AND Rownum       < 2;
          Write_Log('Settlement ID  -  '||l_settlement_id);
        EXCEPTION
        WHEN No_Data_Found THEN
          L_Settlement_Id := 0;
          Write_Log('Error -  Settlement_id not found in xx_ce_mpl_settlement_stg table for request_id :'||ln_conc_id||' - '||Sqlerrm);
        WHEN OTHERS THEN
          l_settlement_id := 0;
          WRITE_LOG('Error  getting Settlement ID  -  '||SQLERRM);
        END;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      Fnd_File.Put_Line(Fnd_File.Log,'Error:'|| Sqlerrm);
      Fnd_File.Put_Line(Fnd_File.Output,'Error:'|| Sqlerrm);
    END;
    -- Start OD CE MPL Process Settlement
    Write_Log('OD CE MPL Process Settlement ,parameter - Settlement ID'|| l_settlement_id );
    IF l_settlement_id <> 0 THEN
      BEGIN
        ln_conc_id := fnd_request.submit_request( application => 'XXFIN' ,program => 'XXCEMPLPRC' ,description => NULL ,start_time => SYSDATE ,sub_request => FALSE ,argument1 => i.process_name , argument2 => l_settlement_id );
        COMMIT;
        lb_bool := fnd_concurrent.wait_for_request(ln_conc_id ,5 ,5000 ,lc_phase ,lc_status ,lc_dev_phase ,lc_dev_status ,lc_message );
      EXCEPTION
      WHEN OTHERS THEN
        Fnd_File.Put_Line(Fnd_File.Log,'Error:'|| Sqlerrm);
        Fnd_File.Put_Line(Fnd_File.Output,'Error:'|| Sqlerrm);
      END;
    ELSE
      Write_Log('Error in getting Settlement ID , Check if Program : OD CE MPL Stage Settlement is completed Normal');
    END IF;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  Fnd_File.Put_Line(Fnd_File.Log,'Error:'|| Sqlerrm);
  Fnd_File.Put_Line(Fnd_File.Output,'Error:'|| Sqlerrm);
END MAIN_WRAPER;
END XX_CE_MPL_SETTLEMENT_PKG;
/
SHOW ERROR
