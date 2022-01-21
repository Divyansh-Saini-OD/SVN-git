CREATE OR REPLACE PACKAGE BODY XX_AR_RCC_EXTRACT
AS
-- +=========================================================================+
-- |                           Oracle - GSD                                  |
-- |                             Bangalore                                   |
-- +=========================================================================+
-- | Name  : XX_AR_RCC_EXTRACT                                               |
-- | Rice ID: I-3090                                                         |
-- | Description      : This Program will extract all the RCC transactions   |
-- |                    into an XML file for RACE                            |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== =============== =====================================|
-- |1.0     30-JUN-2014 Darshini G      Initial draft version                |
-- |2.0     15-JUL-2014 Arun G          Added debug messages/exceptions      |
-- |3.0     17-JUL-2014 Darshini G      Modified to display negative values  |
-- |                                    of amount and quantity for RETURN    |
-- |                                    order line                           |
-- |4.0     22-JUL-2014 Arun G          Made changes to send the Extended    |
-- |                                    price                                |
-- |5.0     25-JUL-2014 Darshini G      Modified to fix the issue with       |
-- |                                    missing spaces in the Address for    |
-- |                                    defect#31151                         |
-- |6.0     25-JUL-2014 Darshini G      Modified to return just 14 bytes     |
-- |                                    for UPC Code and get the transaction |
-- |                                    type for return orders for Defect#   |
-- |                                    31208 and 31209                      |
-- |7.0     31-JUL-2014 Darshini G      Modified to add order by line number |
-- |                                    clause for Defect#31235              |
-- |8.0     04-AUG-2014 Darshini G      Modified Original transaction date   |
-- |                                    format to MM/DD/YYYY for Defect#31266|
-- |9.0     08-AUG-2014 Darshini G      Modified the line cost to display the|
-- |                                    extended cost for Defect#31323       |
-- |10.0    18-AUG-2014 Darshini G      Modified to fetch all unprocessed    |
-- |                                    transactions <= transaction date     |
-- |                                    for the merger-project defect#42     |
-- |11.0    18-AUG-2014 Arun G          Modified to send the transaction in  |
-- |                                    sequential order to RACE system      |
-- |                                    defect # 46
-- |12.0    15-SEP-2014 Arun G          Modified to update the flag on       |
-- |                                    inv header level dff 
-- |                                    Made changes to multitender section  |
-- |                                    to send the appr.payment type code   |
-- |13.0    29-SEP-2014 Arun G          Made changes to ADD NVL Clause       |
-- |14.0    01-OCT-2014 Arun G          Made changes to include Return tran  |
-- |                                    sactions in the payment record #97,96|
-- |15.0    31-MAR-2015 Madhan Sanjeevi Modified based on Defect# 33521      |
-- |16.0    10-JUL-2015 Madhan Sanjeevi Modified based on Defect# 35071      |
-- |17.0    30-JUl-2015 Arun G          Made changes to support AOPS RCC     |
-- |                                    orders .Defect # 35323               |
-- |18.0    02-SEP-2015 Arun G          Made changes to fix the store num issue |
-- |19.0    22-OCT-2015 Vasu R          Removed Schema References for R12.2  |
-- +=========================================================================+

  PROCEDURE log_exception ( p_error_location     IN  VARCHAR2
                           ,p_error_msg          IN  VARCHAR2 )
  IS
  -- +===================================================================+
  -- | Name  : log_exception                                             |
  -- | Description     : The log_exception procedure logs all exceptions |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters      : p_error_location     IN -> Error location       |
  -- |                   p_error_msg          IN -> Error message        |
  -- +===================================================================+

   --------------------------------
   -- Local Variable Declaration --
   --------------------------------
  ln_login     NUMBER                :=  FND_GLOBAL.LOGIN_ID;
  ln_user_id   NUMBER                :=  FND_GLOBAL.USER_ID;

  BEGIN

    XX_COM_ERROR_LOG_PUB.log_error(
                                     p_return_code             => FND_API.G_RET_STS_ERROR
                                    ,p_msg_count               => 1
                                    ,p_application_name        => 'XXFIN'
                                    ,p_program_type            => 'Custom Messages'
                                    ,p_program_name            => 'XX_RCC_AB_TRX_EXTRACT'
                                    ,p_attribute15             => 'XX_RCC_AB_TRX_EXTRACT'
                                    ,p_program_id              => null
                                    ,p_module_name             => 'AR'
                                    ,p_error_location          => p_error_location
                                    ,p_error_message_code      => null
                                    ,p_error_message           => p_error_msg
                                    ,p_error_message_severity  => 'MAJOR'
                                    ,p_error_status            => 'ACTIVE'
                                    ,p_created_by              => ln_user_id
                                    ,p_last_updated_by         => ln_user_id
                                    ,p_last_update_login       => ln_login
                                    );

  EXCEPTION 
    WHEN OTHERS 
    THEN 
      fnd_file.put_line(fnd_file.log, 'Error while writting to the log ...'|| SQLERRM);
  END log_exception;


  PROCEDURE log_msg( 
                    p_string IN VARCHAR2
                   )
  IS
  -- +===================================================================+
  -- | Name  : log_msg                                                   |
  -- | Description     : The log_msg procedure displays the log messages |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters      : p_string             IN -> Log Message          |
  -- +===================================================================+

  BEGIN

    IF (g_debug_flag)
    THEN
      fnd_file.put_line(fnd_file.LOG,p_string);
    END IF;
  END log_msg;

  PROCEDURE get_orig_ref_ret(p_header_id     IN   NUMBER,
                             p_ret_orig_ref  OUT  VARCHAR,
                             p_ret_orig_date OUT  DATE)
--  RETURN VARCHAR2
  IS
  -- +===================================================================+
  -- | Name  : get_orig_ref_ret                                          |
  -- | Description     : The get_orig_ref_ret function returns           |
  -- |                   ret_orig_order_num for return orders            |
  -- |                                                                   |
  -- | Parameters      : p_header_id  IN -> header_id                    |
  -- +===================================================================+

   --------------------------------
   -- Local Variable Declaration --
   --------------------------------
   lc_ret_orig_ref xx_om_line_attributes_all.ret_orig_order_num%type;
   lc_error_msg    VARCHAR2(1000);

   BEGIN
    -- log_msg('Deriving the Original Order details for Header id :'|| p_header_id);

     SELECT ret_orig_order_num,
            ret_orig_order_date
     INTO   p_ret_orig_ref,
            p_ret_orig_date
     FROM   xx_om_line_attributes_all xola
            ,oe_order_lines_all oola
     WHERE  oola.line_id            = xola.line_id
     AND    oola.line_category_code = 'RETURN'
     AND    oola.line_number        = 1
     AND    oola.header_id          = p_header_id;

     log_msg('Return Order number ...:' ||lc_ret_orig_ref);

--     RETURN lc_ret_orig_ref;
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       fnd_file.put_line(fnd_file.log,'Original return order number not found for header id :'||p_header_id);
       lc_error_msg := 'Original return order number not found for header id :'||p_header_id;
       log_exception ( p_error_location      =>  'XX_AR_RCC_EXTRACT.GET_ORIG_REF_RET'
                       ,p_error_msg          =>  lc_error_msg);
       p_ret_orig_ref    := NULL;
       p_ret_orig_date   := NULL;
       --RETURN NULL;
     WHEN OTHERS
     THEN
       fnd_file.put_line(fnd_file.log,'Unable to fetch Original return order number for header id :'||p_header_id||' '||SQLERRM);
       lc_error_msg := 'Unable to fetch Original return order number for header id :'||p_header_id||' '||SQLERRM;
       log_exception ( p_error_location     =>  'XX_AR_RCC_EXTRACT.GET_ORIG_REF_RET'
                      ,p_error_msg          =>  lc_error_msg);
       p_ret_orig_ref    := NULL;
       p_ret_orig_date   := NULL;
--       RETURN NULL;
   END;


  PROCEDURE get_store_num( p_location_code IN  VARCHAR2,
                           p_store_number  OUT VARCHAR2)
  IS

  BEGIN
    p_store_number := NULL;

    SELECT SUBSTR(hl.attribute1,3,4)
    INTO p_store_number
    FROM hr_locations                hl
    WHERE hl.location_code = p_location_code;

  EXCEPTION 
    WHEN NO_DATA_FOUND
    THEN 
      fnd_file.put_line(fnd_file.log, 'Store Number not found for location code:'|| p_location_code);
      p_store_number := NULL;
    WHEN OTHERS 
    THEN 
      fnd_file.put_line(fnd_file.log, 'Error while writting to the log ...'|| SQLERRM);
  END get_store_num;

  --Function added for defect#31209
  FUNCTION get_trans_type(p_header_id IN NUMBER)
  RETURN VARCHAR2
  IS
  -- +===================================================================+
  -- | Name  : get_trans_type                                            |
  -- | Description     : The get_trans_type function returns             |
  -- |                   transaction type for return orders              |
  -- |                                                                   |
  -- | Parameters      : p_header_id  IN -> header_id                    |
  -- +===================================================================+

   --------------------------------
   -- Local Variable Declaration --
   --------------------------------
   lc_trans_type   oe_order_lines_all.line_category_code%type;
   lc_error_msg    VARCHAR2(1000);

   BEGIN
     log_msg('Deriving the transaction type for Header id :'|| p_header_id);

     SELECT line_category_code 
     INTO   lc_trans_type
     FROM   oe_order_lines_all oola
     WHERE  oola.line_category_code = 'RETURN'
     AND    oola.line_number        = 1
     AND    oola.header_id          = p_header_id;
     
     log_msg('Order transaction type ...:' ||lc_trans_type);

     RETURN lc_trans_type;
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       fnd_file.put_line(fnd_file.log,'Transaction type not found for header id :'||p_header_id);
       lc_error_msg := 'Transaction type not found for header id :'||p_header_id;
       log_exception ( p_error_location      =>  'XX_AR_RCC_EXTRACT.GET_TRANS_TYPE'
                       ,p_error_msg          =>  lc_error_msg);
       RETURN NULL;
     WHEN OTHERS
     THEN
       fnd_file.put_line(fnd_file.log,'Unable to fetch transaction type for header id :'||p_header_id||' '||SQLERRM);
       lc_error_msg := 'Unable to fetch transaction type for header id :'||p_header_id||' '||SQLERRM;
       log_exception ( p_error_location     =>  'XX_AR_RCC_EXTRACT.GET_TRANS_TYPE'
                      ,p_error_msg          =>  lc_error_msg);
       RETURN NULL;
   END get_trans_type;

  FUNCTION get_cost( p_customer_trx_id       IN NUMBER
                     ,p_customer_trx_line_id IN NUMBER)
  RETURN NUMBER
  IS

  -- +===================================================================+
  -- | Name  : get_cost                                                  |
  -- | Description     : The get_cost function returns                   |
  -- |                   item cost.                                      |
  -- |                                                                   |
  -- | Parameters      : p_customer_trx_id  IN -> customer_trx_id        |
  -- |                   p_customer_trx_line_id IN -> customer_trx_line_id|
  -- +===================================================================+

   --------------------------------
   -- Local Variable Declaration --
   --------------------------------
   xn_item_cost ra_cust_trx_line_gl_dist_all.attribute9%type;
   lc_error_msg VARCHAR2(1000);

   BEGIN

     log_msg('Deriving the cost for customer trx id :'|| p_customer_trx_id || 'And trx line id ..'|| p_customer_trx_line_id );

     SELECT attribute9  
     INTO   xn_item_cost
     FROM   ra_cust_trx_line_gl_dist_all 
     WHERE  customer_trx_id      = p_customer_trx_id
     AND    account_class        = 'REV'
     AND    customer_trx_line_id = p_customer_trx_line_id;

     log_msg('Cost .....'|| xn_item_cost);

     RETURN xn_item_cost;
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       fnd_file.put_line(fnd_file.log,'Item cost not found');
       lc_error_msg := 'Item cost not found';
       log_exception ( p_error_location      =>  'XX_AR_RCC_EXTRACT.GET_COST'
                       ,p_error_msg          =>  lc_error_msg);
       RETURN NULL;
      WHEN OTHERS
      THEN
        fnd_file.put_line(fnd_file.log,'Unable to fetch Item cost'||SQLERRM);   
        lc_error_msg := 'Unable to fetch Item cost'||SQLERRM;
        log_exception ( p_error_location     =>  'XX_AR_RCC_EXTRACT.GET_COST'
                       ,p_error_msg          =>  lc_error_msg);
        RETURN NULL;
   END;

PROCEDURE replace_tag_labels(xc_xml_out IN OUT CLOB)
IS
-- +===================================================================+
-- | Name  : replace_tag_labels                                        |
-- | Description     : The replace_tag_labels procedure replaces labels|
-- |                   of XML tags with custom labels                  |
-- |                                                                   |
-- | Parameters      : xc_xml_out       IN OUT -> XML data             |
-- +===================================================================+
   lc_error_msg            VARCHAR(1000);

   BEGIN
      xc_xml_out := REPLACE(xc_xml_out,'SALESORDERLINES_ROW','SalesOrderLine');
      xc_xml_out := REPLACE(xc_xml_out,'ORACLEINVOICENUMBER','OracleInvoiceNumber');
      xc_xml_out := REPLACE(xc_xml_out,'CUSTOMERPONUMBER','CustomerPONumber');
      xc_xml_out := REPLACE(xc_xml_out,'STORENUMBER','StoreNumber');
      xc_xml_out := REPLACE(xc_xml_out,'REGISTERNUMBER','RegisterNumber');
      xc_xml_out := REPLACE(xc_xml_out,'TRANSACTIONNUMBER','TransactionNumber');
      xc_xml_out := REPLACE(xc_xml_out,'TRANSDATE','OrderDate');
      xc_xml_out := REPLACE(xc_xml_out,'ORIGStoreNumber','OrigStoreNumber');
      xc_xml_out := REPLACE(xc_xml_out,'ORIGRegisterNumber','OrigRegisterNumber');
      xc_xml_out := REPLACE(xc_xml_out,'ORIGTransactionNumber','OrigTransactionNumber');
      xc_xml_out := REPLACE(xc_xml_out,'ORIGTRANSACTIONDATE','OrigTransactionDate');
      xc_xml_out := REPLACE(xc_xml_out,'RCCNUMBER','RCCNumber');
      xc_xml_out := REPLACE(xc_xml_out,'STOREADDRESS','StoreAddress');
      xc_xml_out := REPLACE(xc_xml_out,'STORECITY','StoreCity');
      xc_xml_out := REPLACE(xc_xml_out,'STORESTATE','StoreState');
      xc_xml_out := REPLACE(xc_xml_out,'STOREZIP','StoreZip');
      xc_xml_out := REPLACE(xc_xml_out,'CUSTLABEL1','CustLabel1');
      xc_xml_out := REPLACE(xc_xml_out,'CUSTVALUE1','CustValue1');
      xc_xml_out := REPLACE(xc_xml_out,'CUSTLABEL2','CustLabel2');
      xc_xml_out := REPLACE(xc_xml_out,'CUSTVALUE2','CustValue2');
      xc_xml_out := REPLACE(xc_xml_out,'ARTICLENUMBER','ArticleNumber');
      xc_xml_out := REPLACE(xc_xml_out,'ITEMDESCRIPTION','ItemDescription');
      xc_xml_out := REPLACE(xc_xml_out,'UPCCODE','UPCCode');
      xc_xml_out := REPLACE(xc_xml_out,'ORDERUOM','OrderUom');
      xc_xml_out := REPLACE(xc_xml_out,'ORDERQUANTITY','OrderQuantity');
      xc_xml_out := REPLACE(xc_xml_out,'COST','Cost');
      xc_xml_out := REPLACE(xc_xml_out,'ACTUALSLSAMT','ActualSlsAmt');
      xc_xml_out := REPLACE(xc_xml_out,'PRICEUSED','PriceUsed');
      xc_xml_out := REPLACE(xc_xml_out,'LINETAX','LineTax');
      xc_xml_out := REPLACE(xc_xml_out,'SALESORDERLINES','SalesOrderLines');
      xc_xml_out := REPLACE(xc_xml_out,'PAYMENTTYPE','PaymentType');
      xc_xml_out := REPLACE(xc_xml_out,'PAYMENTAMOUNT','PaymentAmount');
   EXCEPTION
      WHEN OTHERS 
      THEN
         fnd_file.put_line(fnd_file.log,'Unable to replace XML tags'||SQLERRM);   
         lc_error_msg := 'Unable to replace XML tags'||SQLERRM;
         log_exception ( p_error_location     =>  'XX_AR_RCC_EXTRACT.GET_XML'
                        ,p_error_msg          =>  lc_error_msg);
   END;


  PROCEDURE get_xml(xc_xml_gen_flag  OUT VARCHAR2,
                    p_return_status  OUT VARCHAR2,
                    p_return_msg     OUT VARCHAR2,
                    p_status         IN  VARCHAR2)
  IS
  -- +===================================================================+
  -- | Name  : get_xml                                                   |
  -- | Description     : The get_xml procedure generates RCC Transaction |
  -- |                   data in XML format                              |
  -- |                                                                   |
  -- | Parameters      : xc_xml_gen_flag          OUT -> process_flag    |
  -- |                   p_return_status          OUT -> return status   |
  -- |                   p_return_msg             OUT -> return message  |
  -- |                   p_status                 IN  -> record status   |
  -- +===================================================================+

   --------------------------------
   -- Local Variable Declaration --
   --------------------------------
   v_ctx_hdr           DBMS_XMLGEN.ctxHandle;
   v_ctx_line          DBMS_XMLGEN.ctxHandle;
   v_ctx_pmt           DBMS_XMLGEN.ctxHandle;
   v_ctx_cost_center   DBMS_XMLGEN.ctxHandle;
   lc_xml_hdr          CLOB;
   lc_xml_lines        CLOB;
   lc_xml_pmt          CLOB;
   lc_xml_cost_center  CLOB;
   lc_xml_concat       CLOB;
   lc_xml_out          CLOB;
   rc_data_hdr         SYS_REFCURSOR;
   rc_data_line        SYS_REFCURSOR;
   rc_data_cost_center SYS_REFCURSOR;
   rc_data_pmt         SYS_REFCURSOR;
   ln_header_id        NUMBER;
   lc_error_msg        VARCHAR2(1000);
   lc_xml_trantype     CLOB;
   ln_cur_count        NUMBER;
   lc_data_exixts      VARCHAR2(5) := 'N';
   lc_filehandle       UTL_FILE.file_type;
   lc_dirpath          VARCHAR2 (2000) := 'XX_UTL_FILE_OUT_DIR';
   lc_order_file_name  VARCHAR2 (100)  := 'XXOD_AR_RCC_BILLING';
   lc_mode             VARCHAR2 (1)    := 'W';
   ln_max_linesize     BINARY_INTEGER  := 32767;  

   ln_amt_due_original   ar_payment_schedules_all.amount_due_original%TYPE;
   ln_nonab_amount       oe_payments.payment_amount%TYPE;
   ln_nonabcredit_amount oe_payments.payment_amount%TYPE;
   ln_ab_amount          oe_payments.payment_amount%TYPE;


   ln_hdr_processed       NUMBER;
   ln_hdr_failed_records  NUMBER;

   CURSOR header_id_cur 
   IS
   SELECT header_id,
          oracle_invoice_number
   FROM   xx_om_rcc_headers_staging
   WHERE  NVL(STATUS,p_status) = p_status
   Order By oracle_invoice_number ;

   BEGIN
     ln_hdr_processed       := 0;
     ln_hdr_failed_records  := 0;

     log_msg('Opening file to write XML Data'); 
     lc_filehandle    := UTL_FILE.FOPEN (lc_dirpath, lc_order_file_name, lc_mode,ln_max_linesize);

     log_msg('Generating XML Data');

     FOR hdr_xml in header_id_cur
     LOOP
       BEGIN
         lc_xml_hdr        := NULL;
         lc_xml_lines      := NULL;
         lc_xml_concat     := NULL;
         lc_xml_trantype   := NULL;
         lc_xml_pmt        := NULL;
         lc_xml_cost_center:= NULL;
         ln_header_id      := hdr_xml.header_id;
         lc_data_exixts    :='Y';
         ln_amt_due_original := 0;
         ln_nonab_amount     := 0;
         ln_ab_amount        := 0;

         log_msg('Generating XML tag for Transaction Type for Trx No: '||hdr_xml.oracle_invoice_number);

         BEGIN
           SELECT XMLELEMENT("TranType",TRANSACTION_TYPE).getClobVal()
           INTO   lc_xml_trantype
           FROM   xx_om_rcc_headers_staging
           WHERE  header_id = ln_header_id;
         EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
             fnd_file.put_line(fnd_file.log,'Transaction Type not found');
             lc_error_msg := 'Transaction Type not found';
             log_exception ( p_error_location      =>  'XX_AR_RCC_EXTRACT.GET_XML'
                             ,p_error_msg          =>  lc_error_msg);
           WHEN OTHERS
           THEN
             fnd_file.put_line(fnd_file.log,'Unable to fetch Transaction Type'||SQLERRM);   
             lc_error_msg := 'Unable to fetch Transaction Type'||SQLERRM;
             log_exception ( p_error_location     =>  'XX_AR_RCC_EXTRACT.GET_XML'
                            ,p_error_msg          =>  lc_error_msg);
           END;


           log_msg('Opening header XML Reference Cursor for Trx No: '||hdr_xml.oracle_invoice_number);

           OPEN rc_data_hdr FOR 'SELECT oracle_invoice_number OracleInvoiceNumber
                                        ,customer_po_number CustomerPONumber
                                        ,store_number StoreNumber
                                        ,register_number RegisterNumber
                                        ,transaction_number TransactionNumber
                                        ,order_date TransDate
                                        ,orig_store_number OrigStoreNumber
                                        ,orig_register_number OrigRegisterNumber
                                        ,orig_transaction_number OrigTransactionNumber
                                        ,TO_CHAR(TO_DATE(orig_tranaction_date,''YYYYMMDD''),''MM/DD/YYYY'') OrigTransactionDate /*Modified for defect# 31266*/
                                        ,boise_card_number RCCNumber
                                        ,store_address StoreAddress
                                        ,store_city StoreCity
                                        ,store_state StoreState
                                        ,store_zip StoreZip
                                 FROM   xx_om_rcc_headers_staging
                                 WHERE  header_id = '||ln_header_id||'';

           v_ctx_hdr := dbms_xmlgen.newcontext(rc_data_hdr);
           dbms_xmlgen.setRowTag(v_ctx_hdr, NULL);
           dbms_xmlgen.setRowSetTag(v_ctx_hdr, 'SalesOrderHeader');
           dbms_xmlgen.setNullHandling(v_ctx_hdr, dbms_xmlgen.EMPTY_TAG);
           lc_xml_hdr := dbms_xmlgen.getxml(v_ctx_hdr);
           DBMS_XMLGEN.closeContext(v_ctx_hdr);
           lc_xml_hdr := SUBSTR(lc_xml_hdr,23,LENGTH(lc_xml_hdr)-23);
           lc_xml_hdr := REPLACE(REPLACE(REPLACE(lc_xml_hdr,CHR(10),NULL),'> <','><'),'>  <','><'); --Modified for Defect#31151

           log_msg('Opening cost center XML Reference Cursor for Trx No: '||hdr_xml.oracle_invoice_number);

           OPEN rc_data_cost_center FOR 'SELECT routing_line1 CustLabel1
                                                ,routing_line2 CustValue1
                                                ,routing_line3 CustLabel2
                                                ,routing_line4 CustValue2
                                         FROM   XX_OM_RCC_HEADERS_STAGING d
                                         WHERE  d.header_id = '||ln_header_id||'';

           v_ctx_cost_center := dbms_xmlgen.newcontext(rc_data_cost_center);
           dbms_xmlgen.setRowTag(v_ctx_cost_center, NULL);
           dbms_xmlgen.setRowSetTag(v_ctx_cost_center, 'CostCenter');
           dbms_xmlgen.setNullHandling(v_ctx_cost_center, dbms_xmlgen.EMPTY_TAG);
           lc_xml_cost_center := dbms_xmlgen.getxml(v_ctx_cost_center);
           DBMS_XMLGEN.closeContext(v_ctx_cost_center);
           lc_xml_cost_center := SUBSTR(lc_xml_cost_center,23,LENGTH(lc_xml_cost_center)-23);
           lc_xml_cost_center := REPLACE(REPLACE(REPLACE(lc_xml_cost_center,CHR(10),NULL),'> <','><'),'>  <','><'); --Modified for Defect#31151

           log_msg('Opening line XML Reference Cursor for Trx No: '||hdr_xml.oracle_invoice_number);

           OPEN rc_data_line FOR 'SELECT item_number ArticleNumber
                                         ,item_description ItemDescription
                                         ,SUBSTR(upc_code,2,14) UPCCode /*Modified for Defect#31208*/
                                         ,order_uom OrderUom
                                         ,order_quantity OrderQuantity
                                         ,cost Cost
                                         ,actual_sales_amount ActualSlsAmt
                                         ,price_used PriceUsed
                                         ,line_tax LineTax
                                  FROM   XX_OM_RCC_LINES_STAGING 
                                  WHERE  header_id = '||ln_header_id||''; 

           v_ctx_line := dbms_xmlgen.newcontext(rc_data_line);

           dbms_xmlgen.setRowTag(v_ctx_line, 'SalesOrderLine');
           dbms_xmlgen.setRowSetTag(v_ctx_line, 'SalesOrderLines');
           dbms_xmlgen.setNullHandling(v_ctx_line, dbms_xmlgen.EMPTY_TAG);
           lc_xml_lines := dbms_xmlgen.getxml(v_ctx_line);
           DBMS_XMLGEN.closeContext(v_ctx_line);
           lc_xml_lines := SUBSTR(lc_xml_lines,23,LENGTH(lc_xml_lines)-23);
           lc_xml_lines := REPLACE(REPLACE(REPLACE(lc_xml_lines,CHR(10),NULL),'> <','><'),'>  <','><'); --Modified for Defect#31151
           lc_xml_lines := '<SubOrder>'||lc_xml_lines||'</SubOrder>';

           log_msg('Opening payment XML Reference Cursor for Trx No: '||hdr_xml.oracle_invoice_number);


           -- Get the total due amount

           BEGIN 
             SELECT amount_due_original
             INTO ln_amt_due_original
             FROM ar_payment_schedules_all aps,
                  ra_customer_trx_all rcta
             WHERE rcta.customer_trx_id = aps.customer_trx_id
             AND class IN ( 'INV' , 'CM')
             AND rcta.trx_number = hdr_xml.oracle_invoice_number;

             log_msg('Original Due Amount :'|| ln_amt_due_original);

             SELECT NVL(SUM(payment_amount),0)
             INTO ln_nonab_amount
             FROM oe_payments op
             WHERE op.header_id = ln_header_id;

             log_msg('Total Sum of Tenders ..'|| ln_nonab_amount);
       
             IF ln_amt_due_original > 0 
             THEN 
               ln_ab_amount := NVL(ln_amt_due_original,0) - ln_nonab_amount;

             ELSE
               ln_ab_amount := 0;
             END IF;
 
             log_msg('AB Amount :'|| ln_ab_amount);

             SELECT NVL(SUM(credit_amount),0)
             INTO ln_nonabcredit_amount
             FROM XX_OM_RETURN_TENDERS_ALL op
             WHERE op.header_id = ln_header_id;

             log_msg('sum of credit'|| ln_nonabcredit_amount);

             IF ln_nonabcredit_amount > 0
             THEN 
               ln_ab_amount := NVL(ln_amt_due_original,0) + ln_nonabcredit_amount;
 
               log_msg('AB Credit amt'|| ln_ab_amount);
             END IF;
  
           EXCEPTION 
             WHEN NO_DATA_FOUND 
             THEN
               log_msg('NO open balance found ..');
             WHEN OTHERS 
             THEN 
               log_msg('Error while getting the AB Amount ..');
           END;

           OPEN rc_data_pmt FOR 'SELECT DECODE(op.Payment_type_code , ''CHECK'', 
                                        DECODE( arm.NAME, ''US_GIFT CARD_OD'' ,''GIFT'' ,''US_GIFT CARD_OMX'' ,''GIFT''), ''CHECK'', 
                                        ''CASH'', ''CASH'') PaymentType
                                       ,PAYMENT_AMOUNT   PaymentAmount
                                 FROM   oe_payments op ,ar_Receipt_methods arm
                                 WHERE  op.receipt_method_id = arm.receipt_method_id
                                 AND  op.header_id = '||ln_header_id||'
                                 UNION ALL
                                 SELECT DECODE(op.Payment_type_code , ''CHECK'', 
                                        DECODE( arm.NAME, ''US_GIFT CARD_OD'' ,''GIFT'' ,''US_GIFT CARD_OMX'' ,''GIFT''), ''CHECK'', 
                                        ''CASH'', ''CASH'') PaymentType
                                       ,(-1) *  credit_AMOUNT   PaymentAmount
                                 FROM   XX_OM_RETURN_TENDERS_ALL op ,ar_Receipt_methods arm
                                 WHERE  op.receipt_method_id = arm.receipt_method_id
                                 AND  op.header_id = '||ln_header_id||'  
                                 UNION ALL
                                 SELECT ''BINV'','||ln_ab_amount||'
                                 FROM DUAL
                                 ';

           v_ctx_pmt := dbms_xmlgen.newcontext(rc_data_pmt);
           dbms_xmlgen.setRowTag(v_ctx_pmt, 'MultiplePayments');
           dbms_xmlgen.setRowSetTag(v_ctx_pmt, 'PaymentData');
           dbms_xmlgen.setNullHandling(v_ctx_pmt, dbms_xmlgen.EMPTY_TAG);
           lc_xml_pmt := dbms_xmlgen.getxml(v_ctx_pmt);
           DBMS_XMLGEN.closeContext(v_ctx_pmt);
 
           lc_xml_pmt := SUBSTR(lc_xml_pmt,23,LENGTH(lc_xml_pmt)-23);
           lc_xml_pmt := REPLACE(REPLACE(REPLACE(lc_xml_pmt,CHR(10),NULL),'> <','><'),'>  <','><'); --Modified for Defect#31151
  
           IF(lc_xml_pmt IS NOT NULL) AND ( ln_nonab_amount > 0 OR ln_nonabcredit_amount > 0 )
           THEN
             log_msg('Concatinating header and line XML with payment data');
             --lc_xml_concat:='<?xml version=”1.0” encoding=”IBM037”?>'||'<OMXSalesOrders>'||'<SalesOrder>'||lc_xml_trantype||lc_xml_hdr||lc_xml_cost_center||lc_xml_lines||lc_xml_pmt||'</SalesOrder>'||'</OMXSalesOrders>';
             lc_xml_concat := '<OMXSalesOrders>'||'<SalesOrder>'||lc_xml_trantype||lc_xml_hdr||lc_xml_cost_center||lc_xml_lines||lc_xml_pmt||'</SalesOrder>'||'</OMXSalesOrders>';
           ELSE
             log_msg('Concatinating header and line XML without payment data');
             --lc_xml_concat:='<?xml version=”1.0” encoding=”IBM037”?>'||'<OMXSalesOrders>'||'<SalesOrder>'||lc_xml_trantype||lc_xml_hdr||lc_xml_cost_center||lc_xml_lines||'</SalesOrder>'||'</OMXSalesOrders>';
             lc_xml_concat := '<OMXSalesOrders>'||'<SalesOrder>'||lc_xml_trantype||lc_xml_hdr||lc_xml_cost_center||lc_xml_lines||'</SalesOrder>'||'</OMXSalesOrders>';

           END IF;

           log_msg('Replacing XML tag lables with Custom lables');
           replace_tag_labels(lc_xml_concat);

           log_msg('Writing XML tags into the file');

           UTL_FILE.put_line (lc_filehandle, lc_xml_concat);

           xc_xml_gen_flag := 'Y';

           log_msg('Updating the STATUS for processed data for Trx No: '||hdr_xml.oracle_invoice_number);

           UPDATE XX_OM_RCC_HEADERS_STAGING
           SET    STATUS   = 'PROCESSED'
           WHERE header_id = hdr_xml.header_id;

           ln_hdr_processed := ln_hdr_processed +1;

        EXCEPTION
          WHEN UTL_FILE.INVALID_PATH
          THEN
            UTL_FILE.FCLOSE_ALL;
            RAISE_APPLICATION_ERROR(-20051, 'Invalid Path');

          WHEN UTL_FILE.INVALID_MODE
          THEN
            UTL_FILE.FCLOSE_ALL;
            RAISE_APPLICATION_ERROR(-20052, 'Invalid Mode');

          WHEN UTL_FILE.INTERNAL_ERROR
          THEN
           UTL_FILE.FCLOSE_ALL;
           RAISE_APPLICATION_ERROR(-20053, 'Internal Error');
          WHEN UTL_FILE.INVALID_OPERATION
          THEN
          UTL_FILE.FCLOSE_ALL;
          RAISE_APPLICATION_ERROR(-20054, 'Invalid Operation');

          WHEN UTL_FILE.INVALID_FILEHANDLE
          THEN
           UTL_FILE.FCLOSE_ALL;
           RAISE_APPLICATION_ERROR(-20055, 'Invalid Operation');

          WHEN UTL_FILE.WRITE_ERROR
          THEN
           UTL_FILE.FCLOSE_ALL;
           RAISE_APPLICATION_ERROR(-20056, 'Invalid Operation');
         
          WHEN OTHERS
          THEN
            UPDATE XX_OM_RCC_HEADERS_STAGING
            SET    STATUS   = 'ERROR'
            WHERE header_id = hdr_xml.header_id;

            lc_error_msg := ' Error while writing the invoice number ..'||hdr_xml.oracle_invoice_number ||SQLERRM;
            fnd_file.put_line(fnd_file.log , lc_error_msg);
            log_exception ( p_error_location    =>  'XX_AR_RCC_EXTRACT.GET_XML'
                           ,p_error_msg         =>  lc_error_msg);
            ln_hdr_failed_records := ln_hdr_failed_records +1;
            p_return_status :=  'W';
            p_return_msg    := lc_error_msg;

        END;
      END LOOP;  -- Header loop;

      FND_FILE.PUT_LINE(fnd_file.log, 'Total Number of Invoices written to File ....'||ln_hdr_processed );
      FND_FILE.PUT_LINE(fnd_file.log, 'Total Number of Invoices Fail to write to File ....'||ln_hdr_failed_records );

      UTL_FILE.FCLOSE(LC_FILEHANDLE);

      IF(lc_data_exixts = 'N')
      THEN
        FND_FILE.PUT_LINE(fnd_file.log, 'No data present so generating the file with Dummy record .....');

           OPEN header_id_cur;
           IF(header_id_cur%ROWCOUNT = 0)
           THEN
             --lc_xml_concat := '<?xml version=”1.0” encoding=”IBM037”?>'||'<OMXSalesOrders>'||'<TranType>9999</TranType>'||'</OMXSalesOrders>';
            lc_xml_concat := '<OMXSalesOrders>'||'<TranType>9999</TranType>'||'</OMXSalesOrders>';
            lc_filehandle := UTL_FILE.FOPEN (lc_dirpath, lc_order_file_name, lc_mode, ln_max_linesize);
            UTL_FILE.put_line (lc_filehandle, lc_xml_concat);
            UTL_FILE.FCLOSE(LC_FILEHANDLE);
            xc_xml_gen_flag := 'Y';
           END IF;
           CLOSE header_id_cur;
         END IF;
      p_return_status:= 'S';

    EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line(fnd_file.log,'Unable to generate XML'||SQLERRM);   
         lc_error_msg := 'Unable to generate XML'||SQLERRM;
         log_exception ( p_error_location     =>  'XX_AR_RCC_EXTRACT.GET_XML'
                         ,p_error_msg         =>  lc_error_msg);
         p_return_status := 'F';
         p_return_msg    := lc_error_msg;
   END get_xml;


PROCEDURE ftp_xml_file(p_return_status         OUT VARCHAR2,
                       p_return_msg            OUT VARCHAR2
                       )

IS
-- +===================================================================+
-- | Name  : ftp_xml_file                                              |
-- | Description     : The ftp_xml_file procedure FTP the XML file to  |
-- |                   the required directory.                         |
-- |                                                                   |
-- | Parameters      : p_return_status -> return status                |
-- |                   p_return_msg    -> return message               |
-- +===================================================================+

   --------------------------------
   -- Local Variable Declaration --
   --------------------------------
   lc_sourcepath           VARCHAR2(4000);
   lc_destpath             VARCHAR2(4000);
   lc_dest_filename        VARCHAR2(4000);
   lc_archive              VARCHAR2(100);
   lc_dirpath              VARCHAR2 (2000) := 'XX_UTL_FILE_OUT_DIR';
   lc_order_file_name      VARCHAR2 (100)  := 'XXOD_AR_RCC_BILLING';
   lc_timestamp            VARCHAR2 (100)  := TO_CHAR (SYSDATE, 'YYYYMMDD');
   ln_copy_conc_request_id NUMBER;
   lc_error_msg            VARCHAR(1000);
   l_wait                  BOOLEAN;
   l_phase                 VARCHAR2 (50);
   l_wait_status           VARCHAR2 (50);
   l_dev_phase             VARCHAR2 (15);
   l_dev_status            VARCHAR2 (15);
   l_message               VARCHAR2 (2000);

   BEGIN
      FND_GLOBAL.APPS_INITIALIZE(fnd_profile.value('USER_ID') 
                                 ,fnd_profile.value('RESP_ID') 
                                 ,fnd_profile.value ('APPLICATION_ID'));

      lc_dest_filename    := lc_order_file_name||'_'||lc_timestamp||'.xml';

      log_msg('Fetching source directory path');
      BEGIN
         SELECT directory_path
         INTO   lc_sourcepath
         FROM   dba_directories
         WHERE  directory_name = lc_dirpath;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            fnd_file.put_line(fnd_file.log,'Directory path not found');
            lc_error_msg := 'Directory path not found';
            log_exception ( p_error_location      =>  'XX_AR_RCC_EXTRACT.FTP_XML_FILE'
                            ,p_error_msg          =>  lc_error_msg);
         WHEN OTHERS THEN
               fnd_file.put_line(fnd_file.log,'Unable to fetch Directory path'||SQLERRM);   
               lc_error_msg := 'Unable to fetch Directory path'||SQLERRM;
               log_exception ( p_error_location     =>  'XX_AR_RCC_EXTRACT.FTP_XML_FILE'
                              ,p_error_msg          =>  lc_error_msg);
      END;

      IF(lc_sourcepath IS NOT NULL)
      THEN

        lc_sourcepath:= lc_sourcepath||'/'||lc_order_file_name;
        lc_destpath  := '$XXFIN_DATA/ftp/out/arinvoice/rcc/'||lc_dest_filename;
        lc_archive   := '$XXFIN_DATA/archive/outbound/';

        log_msg('Calling File Copy Program to copy XML File to RCC directory');

        ln_copy_conc_request_id:=FND_REQUEST.SUBMIT_REQUEST(application => 'XXFIN' 
                                                           ,program     => 'XXCOMFILCOPY' 
                                                           ,description => NULL 
                                                           ,start_time  => NULL 
                                                           ,sub_request => FALSE 
                                                           ,argument1   => lc_sourcepath
                                                           ,argument2   => lc_destpath 
                                                           ,argument3   => NULL 
                                                           ,argument4   => NULL 
                                                           ,argument5   => 'Y' 
                                                           ,argument6   => lc_archive 
                                                           ,argument7   => NULL 
                                                           ,argument8   => NULL 
                                                           ,argument9   => NULL 
                                                           ,argument10  => NULL 
                                                           ,argument11  => NULL 
                                                           ,argument12  => NULL 
                                                           ,argument13  => NULL 
                                                           );
       p_return_status := 'S';
       END IF;
       COMMIT;
     EXCEPTION
       WHEN OTHERS 
       THEN
         fnd_file.put_line(fnd_file.log,'Unable to FTP XML file'||SQLERRM);   
         lc_error_msg := 'Unable to FTP XML file'||SQLERRM;
         log_exception ( p_error_location     =>  'XX_AR_RCC_EXTRACT.FTP_XML_FILE'
                         ,p_error_msg         =>  lc_error_msg);
         p_return_status := 'F';
         p_return_msg    := lc_error_msg;
   END ftp_xml_file;

PROCEDURE xx_rcc_ab_trx_extract(
                                x_retcode          OUT NOCOPY     NUMBER
                                ,x_errbuf          OUT NOCOPY     VARCHAR2
                                ,p_trx_date        IN             VARCHAR2
                                ,p_account_number  IN             VARCHAR2
                                ,p_debug_flag      IN             VARCHAR2
                                ,p_status          IN             VARCHAR2
                                )
IS
-- +===================================================================+
-- | Name  : xx_rcc_ab_trx_extract                                     |
-- | Description     : The xx_rcc_ab_trx_extract procedure is the main |
-- |                   procedure that will extract the RCC Transactions|
-- |                   and write them into the output file             |
-- |                                                                   |
-- | Parameters      : p_trx_date          IN -> Transaction Date      |
-- |                   p_account_number    IN -> Account Number        |
-- |                   x_retcode           OUT                         |
-- |                   x_errbuf            OUT                         |
-- |                   p_debug_flag        IN -> Debug Flag            |
-- |                   p_status            IN -> Record status         |
-- +===================================================================+

   --------------------------------
   -- Local Variable Declaration --
   --------------------------------
   ld_trx_date             DATE         := FND_DATE.CANONICAL_TO_DATE(p_trx_date);
   lc_error_loc            VARCHAR2 (2000);
   ln_cost                 NUMBER       := 0;
   lc_orig_trx_date        VARCHAR2(10) DEFAULT NULL;
   lc_orig_store_num       VARCHAR2(10) DEFAULT NULL;
   lc_orig_reg_num         VARCHAR2(10) DEFAULT NULL;
   lc_orig_trx_num         VARCHAR2(10) DEFAULT NULL;
   lc_orig_store_id        VARCHAR2(10) DEFAULT NULL;
   ln_line_num             NUMBER;
   lc_error_msg            VARCHAR2(1000);
   lc_xml_gen_flag         VARCHAR2(5);
   xc_status               VARCHAR2(30) := p_status;
   ln_hdr_records          NUMBER       := 0;
   ln_line_records         NUMBER       := 0;
   ln_hdr_failed_records   NUMBER       := 0;
   lc_return_status        VARCHAR2(5);
   lc_trans_type           VARCHAR2(15); --Added for defect#31209
   lc_store_number         VARCHAR2(10) DEFAULT NULL;
   lc_reg_number           VARCHAR2(10) DEFAULT NULL;
   lc_tran_number          VARCHAR2(10) DEFAULT NULL;
   lc_ret_orig_ref         VARCHAR2(40) DEFAULT NULL;
   lc_ret_orig_date        DATE;

   e_process_exception     EXCEPTION;

   CURSOR rcc_header_cur(ld_trx_date IN DATE,p_account_number IN VARCHAR2)
   IS
      SELECT  oeh.header_id
             ,oeh.cust_po_number                     CustomerPONumber
             ,rct.trx_number                         OracleInvoiceNumber
             ,TO_CHAR(rct.trx_date,'MM/DD/YYYY')     TransDate
             ,SUBSTR(hl.attribute1,3,4)              StoreNumber
             ,SUBSTR(oeh.orig_sys_document_ref,13,3) RegisterNumber
             ,SUBSTR(oeh.orig_sys_document_ref,16,5) TransactionNumber
             ,rct.customer_trx_id
             ,xmh.spc_card_number                    BoiseCardNumber
             ,hl.address_line_1                      StoreAddress
             ,hl.town_or_city                        StoreCity
             ,hl.region_2                            StoreState
             ,hl.postal_code                         StoreZip
             ,routing_line1                          CustLabel1
             ,routing_line2                          CustValue1
             ,routing_line3                          CustLabel2
             ,routing_line4                          CustValue2
             ,oeh.orig_sys_document_ref              Orig_sys_doc_ref
      FROM   ra_customer_trx_all          rct
             ,oe_order_headers_all        oeh
             ,xx_om_header_attributes_all xmh
             ,hr_locations                hl
             ,hz_cust_accounts            hca
             ,xx_om_tender_attr_iface_all xotai
      WHERE  1=1
      AND    rct.attribute14                                       = oeh.header_id
      AND    oeh.header_id                                         = xmh.header_id
      AND    SUBSTR(oeh.orig_sys_document_ref,1,4)                 = SUBSTR(hl.location_code(+),3,4)
      AND    xotai.orig_sys_document_ref(+)                        = oeh.orig_sys_document_ref
      AND    xotai.order_source_id(+)                              = oeh.order_source_id
      AND    rct.trx_date                                          <= TRUNC(ld_trx_date) --Modified for Merger Project Defect#42
      AND    rct.bill_to_customer_id                               = hca.cust_account_id
      AND    hca.account_number                                    = p_account_number
      AND    NVL(rct.attribute15, 'N') != 'Y' ;

/*      AND    NOT EXISTS ( SELECT 1
                          FROM  XX_OM_RCC_HEADERS_STAGING  xorhs
                          WHERE xorhs.header_id = oeh.header_id)  */


   CURSOR rcc_lines_cur(p_customer_trx_id IN NUMBER)
   IS
      SELECT oel.header_id
             ,oel.line_number --Added for defect#31235
             ,NVL(xml.external_sku,msi.segment1)                articlenumber
             ,msi.description                                   itemdescription
             ,xml.upc_code                                      upccode
             ,oel.order_quantity_uom                            orderuom
            -- ,oel.ordered_quantity                              orderquantity -- Commented based on the defect# 33521
			-- ,rctl.quantity_invoiced                            orderquantity  -- Added based on the defect# 33521, commented based on the defect# 35071
			,(CASE WHEN NVL(rctl.quantity_invoiced,0) <> 0 THEN
			           abs(rctl.quantity_invoiced)
				   WHEN NVL(rctl.quantity_credited,0) <> 0 THEN
				       abs(rctl.quantity_credited)
				   ELSE abs(NVL(rctl.quantity_invoiced,0)) END)              orderquantity -- Added based on the defect# 35071
            -- ,(oel.unit_selling_price)*oel.ordered_quantity     actualslsamt  -- Commmented based on the defect# 33521
			 --,(oel.unit_selling_price)*rctl.quantity_invoiced   actualslsamt   -- Added based on the defect# 33521, commented based on the defect# 35071
			 ,(CASE WHEN NVL(rctl.quantity_invoiced,0) <> 0 THEN
			           abs(NVL(oel.unit_selling_price,0) * rctl.quantity_invoiced)
				   WHEN NVL(rctl.quantity_credited,0) <> 0 THEN
				       abs(NVL(oel.unit_selling_price,0) * rctl.quantity_credited)
				   ELSE abs(NVL(rctl.quantity_invoiced*oel.unit_selling_price,0)) END)              actualslsamt   -- Added based on the defect# 35071
             ,xml.price_type                                    priceused
             ,rctl.customer_trx_id
             ,rctl.customer_trx_line_id
             ,oel.line_category_code
             ,rctl.quantity_invoiced --Added for Defect#31323
      FROM   mtl_system_items msi
             ,ra_customer_trx_lines_all rctl
             ,oe_order_lines_all oel
             ,xx_om_line_attributes_all xml
      WHERE  msi.inventory_item_id           = rctl.inventory_item_id
      AND    xml.line_id                     = oel.line_id
      AND    oel.ship_from_org_id            = msi.organization_id
      AND    rctl.interface_line_attribute6  = oel.line_id
      AND    rctl.interface_line_attribute11 = 0   -- This condition eliminates the discount records 
      AND    rctl.customer_trx_id            = p_customer_trx_id
      ORDER BY oel.line_number; --Added for defect#31235

  BEGIN

    fnd_file.put_line(fnd_file.log , 'Input parameters .....:');
    fnd_file.put_line(fnd_file.log , 'p_account_number:'||p_account_number);
    fnd_file.put_line(fnd_file.log , 'p_debug_flag: '||p_debug_flag);
    fnd_file.put_line(fnd_file.log , 'p_trx_date:'|| p_trx_date);

    IF(p_debug_flag = 'Y') THEN 
       g_debug_flag := TRUE;
    ELSE
       g_debug_flag := FALSE;
    END IF;

    FOR hdr_data IN rcc_header_cur(ld_trx_date,p_account_number)
    LOOP
      BEGIN
        log_msg('Processing invoice number ....'||hdr_data.OracleInvoiceNumber);

        lc_orig_trx_date  := NULL;
        lc_orig_store_num := NULL;
        lc_orig_reg_num   := NULL;
        lc_orig_trx_num   := NULL;
        lc_orig_store_id  := NULL;
        lc_store_number   := NULL;
        lc_reg_number     := NULL;
        lc_tran_number    := NULL;
        lc_ret_orig_ref   := NULL;
        lc_ret_orig_date  := NULL;

        log_msg('calling get orig order details ..');

        get_orig_ref_ret(p_header_id      =>  hdr_data.header_id ,
                         p_ret_orig_ref   =>  lc_ret_orig_ref,
                         p_ret_orig_date  =>  lc_ret_orig_date);

        IF length(hdr_data.orig_sys_doc_ref) = 12  -- AOPS Order 
        THEN 
          lc_store_number := SUBSTR(hdr_data.orig_sys_doc_ref,1,4);
          lc_reg_number   := SUBSTR(hdr_data.orig_sys_doc_ref,5,5); 
          lc_tran_number  := SUBSTR(hdr_data.orig_sys_doc_ref,10,12);

          IF lc_ret_orig_ref IS NOT NULL
          THEN 
            lc_orig_trx_date  := TO_CHAR(lc_ret_orig_date,'RRRRMMDD');
            lc_orig_store_id  := SUBSTR(lc_ret_orig_ref,1,4);
            lc_orig_reg_num   := SUBSTR(lc_ret_orig_ref,5,5); 
            lc_orig_trx_num   := SUBSTR(lc_ret_orig_ref,10,12);
          END IF;

        ELSE  -- POS order 
          log_msg('Fetching store number');
          /*get_store_num( p_location_code  => SUBSTR(hdr_data.orig_sys_doc_ref,1,4),
                         p_store_number   => lc_store_number); */

          lc_store_number   := hdr_data.StoreNumber;
          lc_reg_number     := hdr_data.RegisterNumber; 
          lc_tran_number    := hdr_data.TransactionNumber;
          lc_orig_trx_date  := SUBSTR(lc_ret_orig_ref,5,8);
          lc_orig_store_id  := SUBSTR(lc_ret_orig_ref,1,4);
          lc_orig_reg_num   := SUBSTR(lc_ret_orig_ref,13,3); 
          lc_orig_trx_num   := SUBSTR(lc_ret_orig_ref,16,5);
        END IF;

        lc_trans_type     := get_trans_type(hdr_data.header_id); --Added for defect#31209
        lc_error_msg      := NULL;

        log_msg('Fetching store id ');
        IF(lc_orig_store_id IS NOT NULL)
        THEN
          BEGIN
            SELECT SUBSTR(attribute1,3,4)
            INTO   lc_orig_store_num
            FROM   hr_locations
            WHERE  SUBSTR(location_code,3,4) = lc_orig_store_id;
          EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
             fnd_file.put_line(fnd_file.log,'Store number not found'||lc_orig_store_id);
             lc_error_msg := 'Store number not found';
             log_exception ( p_error_location      =>  'XX_AR_RCC_EXTRACT.XX_RCC_AB_TRX_EXTRACT'
                             ,p_error_msg          =>  lc_error_msg);
            WHEN OTHERS
            THEN
              fnd_file.put_line(fnd_file.log,'Unable to fetch Store number'||SQLERRM);   
              lc_error_msg := 'Unable to fetch Store number'||SQLERRM;
              log_exception ( p_error_location     =>  'XX_AR_RCC_EXTRACT.XX_RCC_AB_TRX_EXTRACT'
                             ,p_error_msg          =>  lc_error_msg);
           END;
        END IF;

        ------------------------------------------------
        -- Inserting data into header staging table   --
        ------------------------------------------------

        log_msg('Inserting header records into XX_OM_RCC_HEADERS_STAGING');

        INSERT INTO xx_om_rcc_headers_staging(header_id
                                                   ,routing_line1
                                                   ,routing_line2
                                                   ,routing_line3
                                                   ,routing_line4
                                                   ,customer_po_number
                                                   ,oracle_invoice_number
                                                   ,order_date
                                                   ,store_number
                                                   ,register_number
                                                   ,transaction_number
                                                   ,transaction_type
                                                   ,orig_tranaction_date
                                                   ,orig_store_number
                                                   ,orig_register_number
                                                   ,orig_transaction_number
                                                   ,boise_card_number
                                                   ,store_address
                                                   ,store_city
                                                   ,store_state
                                                   ,store_zip
                                                   ,creation_date
                                                   ,created_by
                                                   ,last_update_date
                                                   ,last_updated_by
                                                   ,last_update_login 
                                                    )
                                             VALUES(
                                                    hdr_data.header_id
                                                   ,hdr_data.CustLabel1
                                                   ,hdr_data.CustValue1
                                                   ,hdr_data.CustLabel2
                                                   ,hdr_data.CustValue2
                                                   ,hdr_data.CustomerPONumber
                                                   ,hdr_data.OracleInvoiceNumber
                                                   ,hdr_data.TransDate
                                                   ,lc_store_number --hdr_data.StoreNumber
                                                   ,lc_reg_number   --hdr_data.RegisterNumber
                                                   ,lc_tran_number  --hdr_data.TransactionNumber
                                                   ,DECODE(lc_trans_type,NULL,'POB1','POR1') --Modified for defect#31209
                                                   ,lc_orig_trx_date
                                                   ,lc_orig_store_num
                                                   ,lc_orig_reg_num
                                                   ,lc_orig_trx_num
                                                   ,hdr_data.BoiseCardNumber
                                                   ,hdr_data.StoreAddress
                                                   ,hdr_data.StoreCity
                                                   ,hdr_data.StoreState
                                                   ,hdr_data.StoreZip
                                                   ,SYSDATE
                                                   ,FND_PROFILE.VALUE('USER_ID')
                                                   ,SYSDATE
                                                   ,FND_PROFILE.VALUE('USER_ID')
                                                   ,FND_PROFILE.VALUE('USER_ID')
                                                   );

        ln_line_num    := 1;
        ln_hdr_records := ln_hdr_records + 1;   
                       
        FOR line_data IN rcc_lines_cur(hdr_data.customer_trx_id)
        LOOP
          BEGIN

            lc_error_msg := NULL;

            log_msg('Processing Line :'|| line_data.customer_trx_line_id);
            ln_cost := NULL;
            ln_cost := get_cost(line_data.customer_trx_id,line_data.customer_trx_line_id);
            log_msg('Displaying Cost as negatice for all RETURN order lines...');
            IF line_data.line_category_code = 'RETURN'
            THEN
              ln_cost := (-1)*ln_cost;
            END IF;
            ------------------------------------------------
            -- Inserting data into Line staging table     --
            ------------------------------------------------

            log_msg('Inserting line records into XX_OM_RCC_LINES_STAGING');

            INSERT INTO xx_om_rcc_lines_staging(header_id
                                                      ,line_num
                                                      ,item_number
                                                      ,item_description
                                                      ,upc_code
                                                      ,order_uom
                                                      ,order_quantity
                                                      ,actual_sales_amount
                                                      ,cost
                                                      ,price_used
                                                      ,creation_date
                                                      ,created_by
                                                      ,last_update_date
                                                      ,last_updated_by
                                                      ,last_update_login
                                                       )
                                                VALUES(line_data.header_id
                                                      ,ln_line_num
                                                      ,line_data.articlenumber
                                                      ,line_data.itemdescription
                                                      ,line_data.upccode
                                                      ,line_data.orderuom
                                                      ,DECODE(line_data.line_category_code,'RETURN',(line_data.orderquantity*(-1)),line_data.orderquantity)
                                                      ,DECODE(line_data.line_category_code,'RETURN',(line_data.actualslsamt*(-1)),line_data.actualslsamt)
                                                      ,ROUND((NVL(line_data.quantity_invoiced,0) * ln_cost),2) --Modified for Defect#31323
                                                      ,line_data.priceused
                                                      ,SYSDATE
                                                      ,FND_PROFILE.VALUE('USER_ID')
                                                      ,SYSDATE
                                                      ,FND_PROFILE.VALUE('USER_ID')
                                                      ,FND_PROFILE.VALUE('USER_ID')
                                                       );
            ln_line_num     := ln_line_num+1;
            ln_line_records := ln_line_records + 1;

          EXCEPTION
            WHEN OTHERS
            THEN
              fnd_file.put_line(fnd_file.log,'Unable to insert lines data into XX_OM_RCC_LINES_STAGING'||SQLERRM);
              lc_error_msg := 'Unable to insert lines data for trx line id '||line_data.customer_trx_line_id||' '||SQLERRM;
              log_exception ( p_error_location     =>  'XX_AR_RCC_EXTRACT.XX_RCC_AB_TRX_EXTRACT'
                              ,p_error_msg         =>  lc_error_msg);
              RAISE e_process_exception;
          END; --End line Insert
        END LOOP; -- line loop 

        log_msg('populating the tax amount at Line 1');

        UPDATE XX_OM_RCC_LINES_STAGING
        SET    LINE_TAX  = (SELECT SUM(tax_amt)
                            FROM   zx_lines
                            WHERE  trx_id = hdr_data.customer_trx_id)
        WHERE  header_id = hdr_data.header_id
        AND    LINE_NUM  = 1;

        UPDATE ra_customer_Trx_all
        SET attribute15 = 'Y'
        WHERE customer_trx_id = hdr_data.customer_trx_id;

        log_msg(' Commit the record ...');

        COMMIT;

      EXCEPTION
        WHEN OTHERS
        THEN
          IF lc_error_msg IS NULL
          THEN
            fnd_file.put_line(fnd_file.log,'Unable to insert header data into XX_OM_RCC_HEADERS_STAGING'||SQLERRM);
            lc_error_msg := 'Unable to insert header data for customer trx id:'||hdr_data.customer_trx_id||' '||SQLERRM;
            log_exception ( p_error_location     =>  'XX_AR_RCC_EXTRACT.XX_RCC_AB_TRX_EXTRACT'
                            ,p_error_msg         =>  lc_error_msg);
            x_retcode := 1;
            ln_hdr_failed_records := ln_hdr_failed_records +1 ;
          END IF;
         ROLLBACK;
       END; --End header Insert


     END LOOP;   -- header loop

     fnd_file.put_line(fnd_file.log , 'Number of Headers Inserted Successfully ..'|| ln_hdr_records);
     fnd_file.put_line(fnd_file.log , 'Number of Lines Inserted Successfully ....'|| ln_line_records);
     fnd_file.put_line(fnd_file.log , 'Number of headers failed to Insert ....'|| ln_hdr_failed_records);

    ----------------------------------------------------------
    -- Calling  procedure get_xml to generate the XML data  --
    ----------------------------------------------------------

    fnd_file.put_line(fnd_file.log ,'Calling  procedure get_xml');

    get_xml(xc_xml_gen_flag  => lc_xml_gen_flag,
            p_status         => xc_status,
            p_return_status  => lc_return_status,
            p_return_msg     => lc_error_msg);

    IF lc_return_status = 'W'
    THEN
      x_retcode := 1;
    ELSIF lc_return_status = 'F'
    THEN 
      x_retcode := 2;
    END IF;


    ---------------------------------------------------------------------------------------------------
    -- Calling  ftp_xml_file to write the XML data into a file and copy it to the RCC FTP Directory  --
    ---------------------------------------------------------------------------------------------------

    fnd_file.put_line(fnd_file.log ,'lc_xml_gen_flag ..'||lc_xml_gen_flag);

    IF(lc_xml_gen_flag = 'Y')
    THEN
      fnd_file.put_line(fnd_file.log ,'Calling  procedure ftp_xml_file');
      lc_return_status := NULL;
      lc_error_msg     := NULL;

      ftp_xml_file(p_return_status        => lc_return_status,
                   p_return_msg           => lc_error_msg
                   );
    END IF;

    IF lc_return_status != 'F'
         THEN 
           UPDATE xx_om_rcc_headers_staging
           SET    process_flag = 'Y'
           WHERE  to_date(order_date,'MM/DD/RRRR')   = TRUNC(ld_trx_date);
         ELSE
           RAISE e_process_exception;
         END IF;

    log_msg('Commit the changes ..');

    COMMIT;
  EXCEPTION
    WHEN OTHERS
    THEN
      IF lc_error_msg IS NULL
      THEN
        lc_error_msg := 'Unable to process the RCC transactions'||SQLERRM;
      END IF;
      fnd_file.put_line(fnd_file.log,lc_error_msg);
      log_exception ( p_error_location     =>  'XX_AR_RCC_EXTRACT.XX_RCC_AB_TRX_EXTRACT'
                      ,p_error_msg         =>  lc_error_msg);
      x_retcode := 2;
    ROLLBACK;
 END xx_rcc_ab_trx_extract;


PROCEDURE xx_rcc_trx_purge(
                            x_retcode          OUT NOCOPY     NUMBER
                            ,x_errbuf          OUT NOCOPY     VARCHAR2
                            ,p_purge_days      IN             NUMBER
                           )
IS
-- +===================================================================+
-- | Name  : xx_rcc_trx_purge                                          |
-- | Description     : The xx_rcc_trx_purge procedure is the process   |
-- |                   used to purge data in the staging tables.       |
-- |                                                                   |
-- | Parameters      : p_purge_days        IN -> Purge Date            |
-- |                   x_retcode           OUT                         |
-- |                   x_errbuf            OUT                         |
-- +===================================================================+
   lc_error_msg            VARCHAR(1000);
   BEGIN

      --------------------------------------------
      -- Purging data from line staging table   --
      --------------------------------------------
      fnd_file.put_line(fnd_file.log,'Purging data from line staging table....');

      DELETE FROM xx_om_rcc_lines_staging
      WHERE  header_id IN ( SELECT header_id
                            FROM   xx_om_rcc_headers_staging
                            WHERE  status       = 'PROCESSED'
                            AND    process_flag = 'Y'
                            AND    to_date(order_date,'MM/DD/RRRR')   < TRUNC(SYSDATE-p_purge_days));

     fnd_file.put_line(fnd_file.log,'No of Line records deleted: '||SQL%ROWCOUNT);

      ----------------------------------------------
      -- Purging data from header staging table   --
      ----------------------------------------------
      fnd_file.put_line(fnd_file.log,'Purging data from header staging table....');

      DELETE FROM xx_om_rcc_headers_staging
      WHERE  to_date(order_date,'MM/DD/RRRR')   < TRUNC(SYSDATE-p_purge_days)
      AND    status       = 'PROCESSED'
      AND    process_flag = 'Y';

      fnd_file.put_line(fnd_file.log,'No of Header records deleted: '||SQL%ROWCOUNT);

      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line(fnd_file.log,'Unable to purge data'||SQLERRM);
         lc_error_msg := 'Unable to purge data'||SQLERRM;
         log_exception ( p_error_location     =>  'XX_AR_RCC_EXTRACT.XX_RCC_AB_TRX_EXTRACT'
                         ,p_error_msg         =>  lc_error_msg);
      ROLLBACK;
      x_retcode := 2;
   END xx_rcc_trx_purge;
END XX_AR_RCC_EXTRACT;
/
SHOW ERROR