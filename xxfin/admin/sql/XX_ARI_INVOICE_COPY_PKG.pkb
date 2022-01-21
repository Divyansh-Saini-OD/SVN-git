create or replace PACKAGE BODY      XX_ARI_INVOICE_COPY_PKG AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify - E1293                                                   |
-- |  Providge Consulting                                                                       |
-- +============================================================================================+
-- |  Name:  XX_ARI_INVOICE_COPY_PKG                                                            |
-- |  Description:  This package is used by iReceivables to send copies of invoices to the      |
-- |           customer via email or fax (through the use of the XML Publisher Delivery Mgr)    |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    =================================================|
-- | 1.0         25-Jun-2007  B.Looman         Initial version                                  |
-- | 1.1         22-Jul-2008  B.Thomas         Eliminated error message parameter defect 9061   |
-- | 1.2         14-Nov-2008  B.Thomas         Added get_invoice procs for defect 11979         |
-- | 1.3         18-May-2009  B.Thomas         Fixed defect 15266                               |
-- | 1.4         08-Jul-2009  B.Thomas         Fixed prod defect 487                            |
-- | 1.5         20-Oct-2009  B.Thomas         Updated for consolidated bills R1.2 CR629 E2052  |
-- | 1.6         26-May-2010  Sneha Anand      Updated for Email/Fax page for Defect 6067       |
-- | 1.7         23-Jun-2010  Sundaram S       Added ABS() function for amount due original     |
-- |                                           check to allow creditmemo reprint for defect 5215|
-- | 1.8         22-APR-2013  Ankit Arora	   Modified the code for defect 23007 to pick       |
-- |                                           the correct MBS_DOC_ID.                          |
-- | 1.9         11-SEP-2014  Gayathri         Replaced the UTL_FILE API with DBMS_LOB          |
-- |                                           to read XML Output File as part of QC31115.      |
-- | 2.0         16-JUN-2016  Suresh Naragam   Changes to get the wallet location from translations|
-- | 2.1         16-NOV-2016  Suresh Naragam   Changes to purge the XDO requests tables         |
-- |                                           data Defect#39482                                |
-- | 2.2 		 01-MAR-2017  Madhu Bolli      Duplicate Request Validation for send Email      |
-- | 2.3		 03-MAR-2016  Suresh Naragam   Changes done for the defect#41197                 |
-- | 2.4		 10-MAR-2016  Madhu Bolli      Defect#41197 - Added new procedure get_invoice(3 params) |
-- |                                           so that we can return request_id without waiting for Request Complete |
-- | 2.5         21-Apr-2017  Madhu Bolli      Added new proc save_pdf_invoice_copy to store PDF Copy| 
-- | 2.6         25-Apr-2017  Havish Kasina    Replacing the existing program XXCOMFILCOPY with new program XXCOMIRECFILCOPY| 
-- | 2.7 		 29-JAN-2019  Havish Kasina    Made changes as per Bill Complete NAIT-81131		|
-- | 2.8         23-JUN-2019  Dinesh Nagapuri  Replaced DB_Name with V$instance for LNS   		|
-- | 2.9         11-FEB-2020  M K Pramod Kumar Code Changes to allow 50 Invoices and Consolidated Bills to Email/Fax copy -NAIT-119893
-- | 2.10        11-FEB-2020  M K Pramod Kumar Code Changes to increase variable size increase for Trx list -NAIT-119893
-- +============================================================================================+

GC_XDO_TEMPLATE_FORMAT      CONSTANT VARCHAR2(30)     := 'PDF';

GC_UTL_TMP_OUT_DIR_NAME     CONSTANT VARCHAR2(50)     := 'XX_UTL_FILE_OUT_DIR';
                                                      -- '/app/ebs/ctgsidev02/utl_file_out'
GC_FILE_DIR_SEPARATOR       CONSTANT VARCHAR2(1)      := '/';
--GC_TEMP_DIR_LOCATION        CONSTANT VARCHAR2(200)    := GC_FILE_DIR_SEPARATOR || 'tmp';


CURSOR c_invoice
( cp_cust_account_id        IN   NUMBER,
  cp_customer_trx_id        IN   VARCHAR2 )
IS
  SELECT trx_number
    FROM ra_customer_trx_all
   WHERE bill_to_customer_id = cp_cust_account_id
     AND customer_trx_id = cp_customer_trx_id;


-- ===========================================================================
-- procedure for printing to the output
-- ===========================================================================
PROCEDURE put_out_line
( p_buffer     IN      VARCHAR2      DEFAULT ' ' )
IS
BEGIN
  -- if in concurrent program, print to output file
  IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
    FND_FILE.put_line(FND_FILE.OUTPUT,NVL(p_buffer,' '));
  -- else print to DBMS_OUTPUT
  ELSE
    DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
  END IF;
END put_out_line;


-- ===========================================================================
-- procedure for printing to the log
-- ===========================================================================
PROCEDURE put_log_line
( p_buffer     IN      VARCHAR2      DEFAULT ' ' )
IS
BEGIN
  -- if in concurrent program, print to log file
  IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
    FND_FILE.put_line(FND_FILE.LOG,NVL(p_buffer,' '));
  -- else print to DBMS_OUTPUT
  ELSE
    DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
  END IF;
END put_log_line;

-- ===========================================================================
-- procedure for logging errors
-- ===========================================================================
PROCEDURE PUT_ERR_LINE (
  p_error_message IN VARCHAR2 := ' '
 ,p_attribute1   IN VARCHAR2 := null
 ,p_attribute2   IN VARCHAR2 := null
 ,p_attribute3   IN VARCHAR2 := null
) IS
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error(p_module_name   => 'ARI'
                                ,p_program_name  => 'XX_ARI_INVOICE_COPY_PKG'
                                ,p_attribute1    => p_attribute1
                                ,p_attribute2    => p_attribute2
                                ,p_attribute3    => p_attribute3
                                ,p_attribute4    => fnd_global.user_name
                                ,p_error_message => p_error_message
                                ,p_created_by    => fnd_global.user_id);
END PUT_ERR_LINE;



-- ===========================================================================
-- procedure that gets the directory name for the tmp directory
-- ===========================================================================
FUNCTION get_utl_tmp_out_directory_path
RETURN VARCHAR2
IS
  lc_sub_name        CONSTANT VARCHAR2(50)    := 'GET_UTL_TMP_OUT_DIRECTORY_PATH';

  CURSOR c_tmp_dir IS
    SELECT directory_path
      FROM dba_directories
     WHERE directory_name = GC_UTL_TMP_OUT_DIR_NAME;

  v_directory_path      VARCHAR2(200)      DEFAULT NULL;
BEGIN
  -- ===========================================================================
  -- retrieve the directory path for the given DB directory name
  -- ===========================================================================
  OPEN c_tmp_dir;
  FETCH c_tmp_dir
   INTO v_directory_path;   -- should look something like '/app/ebs/ctgsidev02/utl_file_out'
  CLOSE c_tmp_dir;

  RETURN v_directory_path;
END get_utl_tmp_out_directory_path;


-- ===========================================================================
-- function that returns true/false if directory exists
-- ===========================================================================
FUNCTION utl_tmp_out_directory_exists
RETURN BOOLEAN
IS
  lc_sub_name        CONSTANT VARCHAR2(50)    := 'UTL_TMP_OUT_DIRECTORY_EXISTS';
BEGIN
  -- ===========================================================================
  -- check to see if the path for this directory name exists
  -- ===========================================================================
  IF (get_utl_tmp_out_directory_path() IS NOT NULL) THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END utl_tmp_out_directory_exists;


-- ===========================================================================
-- generic function that is used to separate a delimited string into an
--   array of string values
-- ===========================================================================
FUNCTION explode
( p_string         IN   VARCHAR2   ,
  p_delimiter      IN   VARCHAR2   DEFAULT ',' )
RETURN STRINGARRAY
IS
  n_index          NUMBER             DEFAULT 0;
  n_pos            NUMBER             DEFAULT 0;
  n_hold_pos       NUMBER             DEFAULT 1;

  a_return_tab     STRINGARRAY   DEFAULT STRINGARRAY();
BEGIN
  LOOP
    n_pos := INSTR(p_string,p_delimiter,n_hold_pos);

    IF n_pos > 0 THEN
      a_return_tab.EXTEND;
      n_index := n_index + 1;
      a_return_tab(n_index) := LTRIM(SUBSTR(p_string,n_hold_pos,n_pos-n_hold_pos));

    ELSE
      a_return_tab.EXTEND;
      n_index := n_index + 1;
      a_return_tab(n_index) := LTRIM(SUBSTR(p_string,n_hold_pos));
      EXIT;

    END IF;

    n_hold_pos := n_pos+1;
  END LOOP;

  RETURN a_return_tab;

END explode;


-- ===========================================================================
-- function that is used to get the invoice number from the customer trx id
-- ===========================================================================
FUNCTION get_trx_number
( p_cust_account_id        IN   NUMBER,
  p_customer_trx_id        IN   VARCHAR2 )
RETURN VARCHAR2
IS
  lc_sub_name        CONSTANT VARCHAR2(50)    := 'GET_TRX_NUMBER';

  v_trx_number          VARCHAR2(20)      DEFAULT NULL;
BEGIN
  OPEN c_invoice
  ( cp_cust_account_id  => p_cust_account_id,
    cp_customer_trx_id  => p_customer_trx_id );
  FETCH c_invoice
   INTO v_trx_number;
  CLOSE c_invoice;

  RETURN v_trx_number;
END get_trx_number;


-- ===========================================================================
-- function that retrieves the trx list from the global temporary table
--   that stores the transaction list from iReceivables
-- ===========================================================================
FUNCTION get_temp_selected_trx_list
( p_cust_account_id        IN   NUMBER    DEFAULT NULL )
RETURN VARCHAR2
IS
  --lc_trx_list         VARCHAR2(2000)        DEFAULT NULL;
  lc_trx_list         VARCHAR2(10000)        DEFAULT NULL;--changes for V2.10

  CURSOR c_trx IS
    SELECT trx_number
      FROM AR_IREC_PAYMENT_LIST_GT
     WHERE customer_id = NVL(p_cust_account_id,customer_id)
     ORDER BY trx_number;

  TYPE t_trx_tbl IS TABLE OF c_trx%ROWTYPE
    INDEX BY PLS_INTEGER;

  l_trx_tbl           t_trx_tbl;
BEGIN
  OPEN c_trx;
  FETCH c_trx
   BULK COLLECT
   INTO l_trx_tbl;
  CLOSE c_trx;

  IF (l_trx_tbl.COUNT > 0) THEN
    FOR i_index IN l_trx_tbl.FIRST..l_trx_tbl.LAST LOOP
      IF (lc_trx_list IS NOT NULL) THEN
        lc_trx_list := lc_trx_list || ',';
      END IF;
      lc_trx_list := lc_trx_list || l_trx_tbl(i_index).trx_number;
    END LOOP;

    RETURN lc_trx_list;
  ELSE
    RETURN NULL;
  END IF;
END get_temp_selected_trx_list;


-- ===========================================================================
-- function that retrieves the trx list from the global temporary table
--   that stores the transaction list from iReceivables
-- ===========================================================================
FUNCTION get_temp_selected_conbill_list
( p_cust_account_id        IN   NUMBER    DEFAULT NULL )
RETURN VARCHAR2
IS
/*
  CURSOR c_trx IS
    SELECT DISTINCT PS.cons_inv_id
      FROM AR_IREC_PAYMENT_LIST_GT TL, RA_CUSTOMER_TRX_ALL TRX, AR_PAYMENT_SCHEDULES_ALL PS
     WHERE TL.customer_id = NVL(p_cust_account_id,TL.customer_id)
       AND TL.customer_trx_id=TRX.customer_trx_id
       AND TL.payment_schedule_id=PS.payment_schedule_id
       AND TRX.batch_source_id IN (SELECT batch_source_id FROM XX_AR_CONSBILL_BATCH_SOURCES_V)
       AND PS.cons_inv_id IS NOT NULL
     ORDER BY PS.cons_inv_id;
*/
  CURSOR c_trx IS
    SELECT DISTINCT CON.cons_inv_id
      FROM AR_IREC_PAYMENT_LIST_GT TL
      JOIN RA_CUSTOMER_TRX_ALL TRX
        ON TRX.customer_trx_id=TL.customer_trx_id
      JOIN XX_AR_CONSBILL_DELIVERED_V CON
        ON TL.customer_id=CON.customer_id
      JOIN AR_CONS_INV_TRX_ALL CONTRX
        ON CON.cons_inv_id=CONTRX.cons_inv_id
       AND TL.trx_number=CONTRX.trx_number
      JOIN XX_AR_CONSBILL_BATCH_SOURCES_V BS
        ON TRX.batch_source_id=BS.batch_source_id
     WHERE TL.customer_id = p_cust_account_id
--Start of changes for PROD defect 6067
     AND  CONTRX.transaction_type in('INVOICE','CREDIT_MEMO')
--End of changes for PROD defect 6067
     ORDER BY CON.cons_inv_id;

  TYPE t_trx_tbl IS TABLE OF c_trx%ROWTYPE
    INDEX BY PLS_INTEGER;

  --lc_trx_list         VARCHAR2(2000)        DEFAULT NULL;
  lc_trx_list         VARCHAR2(10000)        DEFAULT NULL;--Changes for V2.10
  l_trx_tbl           t_trx_tbl;
BEGIN
  OPEN c_trx;
  FETCH c_trx
   BULK COLLECT
   INTO l_trx_tbl;
  CLOSE c_trx;

  IF (l_trx_tbl.COUNT > 0) THEN
    FOR i_index IN l_trx_tbl.FIRST..l_trx_tbl.LAST LOOP
      IF (lc_trx_list IS NOT NULL) THEN
        lc_trx_list := lc_trx_list || ',';
      END IF;
      lc_trx_list := lc_trx_list || l_trx_tbl(i_index).cons_inv_id;
    END LOOP;

    RETURN lc_trx_list;
  ELSE
    RETURN NULL;
  END IF;
END get_temp_selected_conbill_list;


-- ===========================================================================
-- function that returns TRUE/FALSE if customer has consolidated billing setup
-- ===========================================================================
FUNCTION has_consolidated_bill_setup
( p_cust_account_id          IN   NUMBER)
RETURN VARCHAR2
IS
  ln_count          NUMBER           DEFAULT NULL;

  CURSOR c_billdocs IS
    SELECT COUNT(1)
      FROM xx_cdh_a_ext_billdocs_v
     WHERE billdocs_doc_type = 'Consolidated Bill'
       AND cust_account_id = p_cust_account_id;
BEGIN
  OPEN c_billdocs;
  FETCH c_billdocs
   INTO ln_count;
  CLOSE c_billdocs;

  IF (ln_count > 0) THEN
    RETURN 'Y';
  ELSE
    RETURN 'N';
  END IF;

END has_consolidated_bill_setup;


-- ===========================================================================
-- function that returns Y/N if customer is setup for email/fax invoices
-- ===========================================================================
FUNCTION has_individual_invoice_setup
( p_cust_account_id        IN   NUMBER    DEFAULT NULL )
RETURN VARCHAR2
IS
  ln_count          NUMBER           DEFAULT NULL;

  CURSOR c_billdocs IS
    SELECT COUNT(1)
      FROM xx_cdh_a_ext_billdocs_v
     WHERE billdocs_doc_type = 'Invoice'    -- Invoice Paydoc setup
       AND cust_account_id = p_cust_account_id;
BEGIN
  OPEN c_billdocs;
  FETCH c_billdocs
   INTO ln_count;
  CLOSE c_billdocs;

  IF (ln_count > 0) THEN
    RETURN 'Y';
  ELSE
    RETURN 'N';
  END IF;
END has_individual_invoice_setup;




-- ===========================================================================
-- function that returns not-yet-delivered consolidated bills from a given list
-- Code changes made to this procedure to allow 50 Transactions for Invoice Copy--NAIT-119893-V2.9
-- ===========================================================================
FUNCTION get_not_yet_delivered_conbills
( p_cust_account_id        IN   NUMBER    DEFAULT NULL,
  p_invoice_consbill_list  IN   VARCHAR2  DEFAULT NULL )
RETURN VARCHAR2
IS
  ln_exists                     NUMBER           DEFAULT NULL;
  lc_undelivered_consbill_list  VARCHAR2(4000)   DEFAULT NULL;
  lc_invoice_consbill_list VARCHAR2(4000)   DEFAULT NULL;

  a_cons_inv_id_array           STRINGARRAY      DEFAULT STRINGARRAY();

  CURSOR c_delivered -- every delivered consolidated bill should have a row in XX_AR_CONSBILL_DELIVERED_V
  ( cp_cons_inv_id   IN   VARCHAR2 )
  IS
    SELECT COUNT(1)
      FROM XX_AR_CONSBILL_DELIVERED_V
     WHERE customer_id=p_cust_account_id
       AND cons_inv_id=cp_cons_inv_id;

BEGIN
  -- ===========================================================================
  -- get the transaction list as an array from the comma-delimited values
  -- ===========================================================================
  /*Added for NAIT-119893-To handle 50 Invoices trx list v2.9*/
        BEGIN
  			select consolidate_bill_list 
				into lc_invoice_consbill_list
				from XX_AR_INVOICE_COPY_LIST 
    		where group_id= p_invoice_consbill_list;
  		Exception when others then 
  			lc_invoice_consbill_list:=p_invoice_consbill_list;
  		end;
  
  
  
 -- a_cons_inv_id_array := explode( p_string => p_invoice_consbill_list, p_delimiter  => ',' );
    a_cons_inv_id_array := explode( p_string => lc_invoice_consbill_list, p_delimiter  => ',' );

  -- ===========================================================================
  -- for each transaction build the undelivered trx list to return
  -- ===========================================================================
  IF (a_cons_inv_id_array.COUNT > 0) THEN
    FOR i_index IN a_cons_inv_id_array.FIRST..a_cons_inv_id_array.LAST LOOP
      OPEN c_delivered
      ( cp_cons_inv_id  => a_cons_inv_id_array(i_index) );
      FETCH c_delivered
       INTO ln_exists;
      CLOSE c_delivered;

      -- ===========================================================================
      -- if this trx is an undelivered trx
      -- ===========================================================================
      IF (ln_exists = 0) THEN
        IF (lc_undelivered_consbill_list IS NOT NULL) THEN
          lc_undelivered_consbill_list := lc_undelivered_consbill_list || ',';
        END IF;

        lc_undelivered_consbill_list := lc_undelivered_consbill_list || a_cons_inv_id_array(i_index);
      END IF;
    END LOOP;
  END IF;

  RETURN lc_undelivered_consbill_list;
END get_not_yet_delivered_conbills;



-- ===========================================================================
-- function that evaluates a comma delimited list of transaction numbers and
-- returns the subset that is not re-printable
-- ===========================================================================
FUNCTION get_unreprintable_trxs
( p_cust_account_id        IN   NUMBER    := NULL,
  p_invoice_trx_list       IN   VARCHAR2  := NULL )
RETURN VARCHAR2
IS
  ls_unreprintable_trx_list     VARCHAR2(4000)                                := NULL;
  ln_exists                     NUMBER                                        := NULL;
  ln_customer_trx_id            AR_PAYMENT_SCHEDULES_ALL.customer_trx_id%TYPE;
  ls_class                      AR_PAYMENT_SCHEDULES_ALL.class%TYPE;
  ln_amount_due_original        AR_PAYMENT_SCHEDULES_ALL.amount_due_original%TYPE;
  ls_om_header_id               RA_CUSTOMER_TRX_ALL.attribute14%TYPE;
  lb_reprintable                BOOLEAN;

  a_trx_number_array            STRINGARRAY                          := STRINGARRAY();
  lv_trx_number_array           VARCHAR2(4000);--code changes for v2.9
BEGIN
  -- ===========================================================================
  -- get the transaction list as an array from the comma-delimited values v2.9
  -- =========================================================================== 
  --Code modified for V2.10--
  BEGIN
  select INVOICE_TRX_LIST 
	into lv_trx_number_array 
	from XX_AR_INVOICE_COPY_LIST 
    where group_id= p_invoice_trx_list;
  Exception when others then 
  lv_trx_number_array:=p_invoice_trx_list;
  end;
  
  
  --a_trx_number_array := explode( p_string => p_invoice_trx_list, p_delimiter  => ',' );
  a_trx_number_array := explode( p_string => lv_trx_number_array, p_delimiter  => ',' );
  -- ===========================================================================
  -- for each transaction, build the undelivered trx list to return
  -- ===========================================================================
  IF (a_trx_number_array.COUNT > 0) THEN
    FOR i_index IN a_trx_number_array.FIRST..a_trx_number_array.LAST LOOP

      SELECT customer_trx_id      ,class   ,amount_due_original
        INTO ln_customer_trx_id,ls_class,ln_amount_due_original
        FROM AR_PAYMENT_SCHEDULES_ALL
       WHERE customer_id = p_cust_account_id
         AND trx_number  = a_trx_number_array(i_index);

      IF ls_class<>'INV' AND ls_class<>'CM' THEN
        lb_reprintable := FALSE;
      ELSE
        lb_reprintable := TRUE;

        SELECT COUNT(*)
          INTO ln_exists
          FROM XX_AR_INVOICE_FREQ_HISTORY
         WHERE bill_to_customer_id   =  p_cust_account_id
           AND invoice_id            = ln_customer_trx_id
           AND paydoc_flag           = 'Y';

        IF ln_exists=0 THEN

          SELECT COUNT(*)
            INTO ln_exists
            FROM AR_CONS_INV_ALL     CON
                ,AR_CONS_INV_TRX_ALL CONTRX
           WHERE CON.customer_id     = p_cust_account_id
             AND CON.cons_inv_id     = CONTRX.cons_inv_id
             AND CONTRX.trx_number   = a_trx_number_array(i_index);

          IF ln_exists=0 THEN

            SELECT attribute14
              INTO ls_om_header_id
              FROM RA_CUSTOMER_TRX_ALL
             WHERE customer_trx_id  = ln_customer_trx_id;

            IF ls_class='INV' THEN
              SELECT COUNT(*)
                INTO ln_exists
                FROM OE_PAYMENTS		
               WHERE header_id      = ls_om_header_id
                 AND prepaid_amount = ln_amount_due_original;
            ELSE -- CM
              SELECT COUNT(*)
                INTO ln_exists
                FROM XX_OM_RETURN_TENDERS_ALL
               WHERE header_id      = ls_om_header_id
                 AND credit_amount  = ABS(ln_amount_due_original); -- Added ABS() for Defect # 5215
            END IF;

            IF ln_exists=0 THEN
              lb_reprintable := FALSE;
            END IF;

          END IF;
        END IF;
      END IF;

      -- ===========================================================================
      -- if this trx is unreprintable
      -- ===========================================================================
      IF NOT lb_reprintable THEN
        IF (ls_unreprintable_trx_list IS NOT NULL) THEN
          ls_unreprintable_trx_list := ls_unreprintable_trx_list || ',';
        END IF;
        ls_unreprintable_trx_list := ls_unreprintable_trx_list || a_trx_number_array(i_index);
      END IF;
    END LOOP;
  END IF;

  RETURN ls_unreprintable_trx_list;
END get_unreprintable_trxs;



-- ===========================================================================
--   procedure that submits the consolidated bill reprint program, so that the XML
--   data can be generated (from an rdf - Oracle Report definition)
-- ===========================================================================
FUNCTION get_print_cons_inv_xml_data
( p_cust_account_id        IN   NUMBER,
  p_cons_inv_id            IN   VARCHAR2,
  x_xdo_app_short_name     OUT  VARCHAR2,
  x_xdo_template_code      OUT  VARCHAR2)
RETURN CLOB
IS
  lc_sub_name     CONSTANT VARCHAR2(50)     := 'GET_PRINT_CONS_INV_XML_DATA';

  n_conc_request_id        NUMBER              DEFAULT NULL;

  b_sub_request            BOOLEAN             DEFAULT FALSE;

  v_return_msg             VARCHAR2(4000)      DEFAULT NULL;

  v_phase_code             VARCHAR2(30)        DEFAULT NULL;
  v_phase_desc             VARCHAR2(80)        DEFAULT NULL;
  v_status_code            VARCHAR2(30)        DEFAULT NULL;
  v_status_desc            VARCHAR2(80)        DEFAULT NULL;

  v_request_name           VARCHAR2(200)       DEFAULT NULL;

  v_user_language          VARCHAR2(30)        DEFAULT NULL;
  v_user_territory         VARCHAR2(30)        DEFAULT NULL;

  v_xml_file_location      VARCHAR2(500)       DEFAULT NULL;
  v_copied_xml_file_loc    VARCHAR2(500)       DEFAULT NULL;
  v_copied_xml_file_name   VARCHAR2(500)       DEFAULT NULL;

  b_success                BOOLEAN             DEFAULT NULL;

  n_mbs_document_id        NUMBER              DEFAULT NULL;

  l_result                 CLOB;

  v_tab                    FND_CONCURRENT.REQUESTS_TAB_TYPE;
  n_issue_Date             AR_CONS_INV.issue_date%type;   --added for defect 23007
  
  CURSOR c_cust_doc
  ( cp_cust_account_id    IN    NUMBER,cp_issue_Date IN DATE ) -- cp_issue_Date is added for defect 23007
  IS
    SELECT n_ext_attr1
      INTO n_mbs_document_id
      FROM XX_CDH_CUST_ACCT_EXT_B
     WHERE cust_account_id=cp_cust_account_id
       AND attr_group_id=166
       AND c_ext_attr2='Y'
       AND ( cp_issue_Date BETWEEN D_EXT_ATTR1 AND NVL(D_EXT_ATTR2,SYSDATE+1)) -- Added for 23007
       AND ROWNUM=1;

  CURSOR c_file
  ( cp_conc_request_id    IN    NUMBER )
  IS
    SELECT outfile_name
      FROM fnd_concurrent_requests
     WHERE request_id = cp_conc_request_id;
BEGIN
  put_log_line('Run the Consolidated Invoice Reprint Program and copy the output.  ');
  put_log_line(' Customer Account Id   = ' || p_cust_account_id );
  put_log_line(' Cons Inv List         = ' || p_cons_inv_id );

  -- ===========================================================================
  -- set child flag if this is a child request
  -- ===========================================================================
  IF (FND_GLOBAL.CONC_REQUEST_ID IS NOT NULL) THEN
    b_sub_request := TRUE;
  END IF;

  -- ===========================================================================
  -- get mbs document id
  -- ===========================================================================
  -- Start Added for defect 23007
  SELECT   issue_Date -- Added for 23007
    INTO   n_issue_Date  -- Added for 23007
    FROM AR_CONS_INV
   WHERE 1 = 1
     -- AND cons_inv_id=p_cons_inv_id  -- Commented for Bill Complete as per Version 2.7
	 AND cons_billing_number = p_cons_inv_id; -- Added for Bill Complete as per Version 2.7
  -- End Added for defect 23007
  OPEN c_cust_doc
  ( cp_cust_account_id  => p_cust_account_id,cp_issue_Date => n_issue_Date); --cp_issue_Date Added for defect 23007
  FETCH c_cust_doc
   INTO n_mbs_document_id;
  CLOSE c_cust_doc;

  -- ===========================================================================
  -- default to std invoice document if not found
  -- ===========================================================================
  IF (n_mbs_document_id IS NULL) THEN
    n_mbs_document_id := GN_DEFAULT_DOCUMENT_ID;
  END IF;

  put_log_line(' MBS Document ID = ' || n_mbs_document_id );

  -- ===========================================================================
  -- submit the request
  -- ===========================================================================
  n_conc_request_id :=
    FND_REQUEST.submit_request
    ( application    => 'XXFIN',                 -- application short name
      program        => 'XXARRPSUMMBILL',        -- concurrent program name
      description    => GC_SUB_REQUEST_NAME,     -- additional request description
      start_time     => NULL,                    -- request submit time
      sub_request    => FALSE,                   -- is this a sub-request?
      argument1      => 'N',                     -- Infocopy Reprint
      argument2      => NULL,                    -- Search By
      argument3      => p_cust_account_id,       -- Customer Number
      argument4      => NULL,                    -- Virtual Consolidated Bill
      argument5      => NULL,                    -- Bill Date From
      argument6      => NULL,                    -- Bill Date To
      argument7      => NULL,                    -- Dummy
      argument8      => NULL,                    -- Virtual Cons Bill Dummy
      argument9      => p_cons_inv_id,           -- From Cons Bill Number
      argument10     => p_cons_inv_id,           -- To Cons Bill Number
      argument11     => NULL,                    -- Virtual Cons Bill Number
      argument12     => NULL,                    -- Multiple Cons Bills
      argument13     => NULL,                    -- Customer Document Id
      argument14     => n_mbs_document_id,       -- MBS Document ID
      argument15     => 'N',                     -- Override MBS Doc Id
      argument16     => NULL,                    -- Email Options
      argument17     => NULL,                    -- Dummy
      argument18     => NULL,                    -- Enter Email Address
      argument19     => 'N',                     -- Special Handling Flag
      argument20     => 1,                       -- MBS Extension Id (only used for special handling)
      argument21     => NULL,                    -- Request Id
      argument22     => NULL,                    -- Origin
      argument23     => NULL,                    -- Doc Detail CP
      argument24     => NULL,                    -- Doc Detail
      argument25     => NULL,                    -- As of Date
      argument26     => NULL );                  -- Optional Printer


  -- ===========================================================================
  -- if request was successful
  -- ===========================================================================
  IF (n_conc_request_id > 0) THEN
    -- ===========================================================================
    -- if a child request, then update it for concurrent mgr to process
    -- ===========================================================================
    IF (b_sub_request) THEN
      UPDATE fnd_concurrent_requests
         SET phase_code = 'P',
             status_code = 'I'
       WHERE request_id = n_conc_request_id;
    END IF;

    -- ===========================================================================
    -- must commit work so that the concurrent manager polls the request
    -- ===========================================================================
    COMMIT;

    put_log_line( ' Concurrent Request ID: ' || n_conc_request_id || '.' );

  -- ===========================================================================
  -- else errors have occured for request
  -- ===========================================================================
  ELSE
    -- ===========================================================================
    -- retrieve and raise any errors
    -- ===========================================================================
    FND_MESSAGE.raise_error;
  END IF;

  put_log_line( 'Wait for the Consolidated Invoice Reprint to Complete... ' );

  -- ===========================================================================
  -- wait on the completion of this request
  -- ===========================================================================
  IF NOT FND_CONCURRENT.wait_for_request
    ( request_id    => n_conc_request_id,
      interval      => 5,                      -- check every 5 secs
      max_wait      => 60*60,                  -- check for max of 1 hour
      phase         => v_phase_desc,
      status        => v_status_desc,
      dev_phase     => v_phase_code,
      dev_status    => v_status_code,
      message       => v_return_msg
      )
  THEN
    RAISE_APPLICATION_ERROR( -20200, v_return_msg );
  END IF;

  put_log_line( 'Finished waiting on Concurrent Request ' || n_conc_request_id || '.' );
  put_log_line( '  Phase  : ' || v_phase_code || ' (' || v_phase_desc || ')' );
  put_log_line( '  Status : ' || v_status_code || ' (' || v_status_desc || ')' );
  put_log_line( '' );

  -- ===========================================================================
  -- if request was not successful
  -- ===========================================================================
  IF (v_status_code <> 'NORMAL') THEN
    RAISE_APPLICATION_ERROR( -20201, 'Concurrent Request completed, but had errors or warnings.' );
  ELSE
    v_tab := FND_CONCURRENT.get_sub_requests(n_conc_request_id); -- Need output of child program

    IF NOT v_tab.EXISTS(1) THEN
      RAISE_APPLICATION_ERROR( -20201, 'Concurrent Request completed, but no child spawned.' );
    ELSE
      n_conc_request_id := v_tab(1).request_id;

      put_log_line( 'Wait for the Consolidated Invoice Reprint child program to Complete... ' );

      IF NOT FND_CONCURRENT.wait_for_request
      ( request_id    => n_conc_request_id,
        interval      => 5,                      -- check every 5 secs
        max_wait      => 60*5,                   -- check for max of 5 minutes
        phase         => v_phase_desc,
        status        => v_status_desc,
        dev_phase     => v_phase_code,
        dev_status    => v_status_code,
        message       => v_return_msg
      )
      THEN
        RAISE_APPLICATION_ERROR( -20200, v_return_msg );
      END IF;

      put_log_line( 'Finished waiting on Concurrent Child Request ' || n_conc_request_id || '.' );
      put_log_line( '  Phase  : ' || v_phase_code || ' (' || v_phase_desc || ')' );
      put_log_line( '  Status : ' || v_status_code || ' (' || v_status_desc || ')' );
      put_log_line( '' );

      IF (v_status_code <> 'NORMAL') THEN
        RAISE_APPLICATION_ERROR( -20201, 'Concurrent Child Request completed, but had errors or warnings.' );
      END IF;

      BEGIN -- Lookup the assigned xml template layout as done in Request Details Form FNDRSRUN
        SELECT argument1 template_app_name, a.argument2 template_code
          INTO x_xdo_app_short_name, x_xdo_template_code
          FROM fnd_conc_pp_actions a
         WHERE concurrent_request_id = n_conc_request_id
           AND action_type = 6
           AND ROWNUM=1;

      EXCEPTION WHEN OTHERS THEN -- Should not get here--
        x_xdo_app_short_name := 'XXFIN';
        x_xdo_template_code  := 'XXARCBISUM';
      END;
    END IF;
  END IF;

  -- ===========================================================================
  -- read the report output file location for the Invoice XML Data
  -- ===========================================================================
  OPEN c_file
  ( cp_conc_request_id   => n_conc_request_id );
  FETCH c_file
   INTO v_xml_file_location;
  CLOSE c_file;

  put_log_line( ' Consolidated Invoice Reprint Program Output location = ' );
  put_log_line( '  ' || v_xml_file_location );

  -- ===========================================================================
  -- check that the dba directory name exists for utl tmp out
  -- ===========================================================================
  IF (NOT utl_tmp_out_directory_exists()) THEN
    RAISE_APPLICATION_ERROR
    ( -20145, 'Directory "' || GC_UTL_TMP_OUT_DIR_NAME ||
      '" is not defined in table DBA_DIRECTORIES.' );
  END IF;

  -- ===========================================================================
  -- set the file location where to copy the xml data file
  -- ===========================================================================
  v_copied_xml_file_name := 'xxarinv-' || n_conc_request_id || '.xml';
  v_copied_xml_file_loc  :=
    get_utl_tmp_out_directory_path() || GC_FILE_DIR_SEPARATOR || v_copied_xml_file_name;

  put_log_line( ' Copied XML File Name: ' || v_copied_xml_file_name );
  put_log_line( ' Copied XML File Location: ' || v_copied_xml_file_loc );

  put_log_line( 'Submit the Copy File Program (XXFIN, XXCOMIRECFILCOPY)' );

  -- ===========================================================================
  -- previous request produced XML output, however this directory cannot be
  --   read using UTL_FILE, so we have to call a common file copy concurrent
  --   program to place it in a location where it can be read
  -- ===========================================================================
  n_conc_request_id :=
    FND_REQUEST.submit_request
    ( application    => 'XXFIN',                     -- application short name
      program        => 'XXCOMIRECFILCOPY',          -- concurrent program name
      description    => 'OD: iRec Copy Invoice XML File', -- additional request description
      start_time     => NULL,                        -- request submit time
      sub_request    => b_sub_request,               -- is this a sub-request?
      argument1      => v_xml_file_location,         -- Source file
      argument2      => v_copied_xml_file_loc,       -- Destination file
      argument3      => '',                          -- Source string
      argument4      => '',                          -- Destination string
      argument5      => 'Y',                         -- Delete Flag
      argument6      => '$XXFIN_DATA/archive/inbound');  -- Archive File Path                      
  -- ===========================================================================
  -- if request was successful
  -- ===========================================================================
  IF (n_conc_request_id > 0) THEN
    -- ===========================================================================
    -- if a child request, then update it for concurrent mgr to process
    -- ===========================================================================
    IF (b_sub_request) THEN
      UPDATE fnd_concurrent_requests
         SET phase_code = 'P',
             status_code = 'I'
       WHERE request_id = n_conc_request_id;
    END IF;

    -- ===========================================================================
    -- must commit work so that the concurrent manager polls the request
    -- ===========================================================================
    COMMIT;

    put_log_line( ' Concurrent Request ID: ' || n_conc_request_id || '.' );

  -- ===========================================================================
  -- else errors have occured for request
  -- ===========================================================================
  ELSE
    -- ===========================================================================
    -- retrieve and raise any errors
    -- ===========================================================================
    --FND_MESSAGE.retrieve( v_return_msg );
    FND_MESSAGE.raise_error;
  END IF;

  put_log_line( 'Wait for the Output File Copy Program to Complete... ' );

  -- ===========================================================================
  -- wait on the completion of this copy file request
  -- ===========================================================================
  IF NOT FND_CONCURRENT.wait_for_request
    ( request_id    => n_conc_request_id,
      interval      => 5,                      -- check every 5 secs
      max_wait      => 60*60,                  -- check for max of 1 hour
      phase         => v_phase_desc,
      status        => v_status_desc,
      dev_phase     => v_phase_code,
      dev_status    => v_status_code,
      message       => v_return_msg
      )
  THEN
    RAISE_APPLICATION_ERROR( -20200, v_return_msg );
  END IF;

  put_log_line( 'Finished waiting on Concurrent Request ' || n_conc_request_id || '.' );
  put_log_line( '  Phase  : ' || v_phase_code || ' (' || v_phase_desc || ')' );
  put_log_line( '  Status : ' || v_status_code || ' (' || v_status_desc || ')' );
  put_log_line( '' );

  -- ===========================================================================
  -- if request was not successful
  -- ===========================================================================
  IF (v_status_code <> 'NORMAL') THEN
    RAISE_APPLICATION_ERROR( -20201, 'Concurrent Request completed, but had errors or warnings.' );
  END IF;

  put_log_line( 'Create an empty, temporary BLOB.' );

  -- ===========================================================================
  -- create a temporary clob to store the XML invoice data
  -- ===========================================================================
  l_result := EMPTY_CLOB();
  DBMS_LOB.createtemporary(l_result,TRUE);

  -- ===========================================================================
  -- read the copied file (XML Data) into the CLOB
  -- ===========================================================================
  DECLARE
    l_file       UTL_FILE.FILE_TYPE;
    lc_buffer    VARCHAR2(2000);
	xmlFile BFILE;
	src_offset number := 1 ;
  dest_offset number := 1 ;
  lang_ctx number := DBMS_LOB.DEFAULT_LANG_CTX;
  warning integer;
  BEGIN
    -- ===========================================================================
    -- check that the dba directory name exists for utl tmp out
    -- ===========================================================================
    IF (NOT utl_tmp_out_directory_exists()) THEN
      RAISE_APPLICATION_ERROR
      ( -20145, 'Directory "' || GC_UTL_TMP_OUT_DIR_NAME ||
        '" is not defined in table DBA_DIRECTORIES.' );
    END IF;

    put_log_line( 'Open this XML file for reading.' );

    -- ===========================================================================
    -- open and read the XML data file
    -- ===========================================================================
    --l_file := UTL_FILE.fopen(GC_UTL_TMP_OUT_DIR_NAME,v_copied_xml_file_name,'r'); -- commented for defect#31115
	xmlFile := BFILENAME(GC_UTL_TMP_OUT_DIR_NAME, v_copied_xml_file_name); -- added for defect#31115
    DBMS_LOB.FILEOPEN(xmlFile, DBMS_LOB.FILE_READONLY); -- added for defect#31115

    put_log_line( 'Write the file to the temporary BLOB' );
	
	DBMS_LOB.LOADCLOBFROMFILE(l_result, xmlFile, DBMS_LOB.LOBMAXSIZE, src_offset, dest_offset, DBMS_LOB.DEFAULT_CSID, lang_ctx, warning); -- added for defect#31115

 /*   BEGIN -- Commented for defect#31115
      LOOP
        -- ===========================================================================
        -- read a line from the file
        -- ===========================================================================
        UTL_FILE.get_line(l_file,lc_buffer);

        -- ===========================================================================
        -- add back a carriage return character to the end of the line
        -- ===========================================================================
        lc_buffer := lc_buffer || chr(10);

        -- ===========================================================================
        -- append this buffer to the end of the clob
        -- ===========================================================================
        DBMS_LOB.writeappend(l_result,LENGTH(lc_buffer),lc_buffer);
      END LOOP;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ===========================================================================
        -- occurs at the end of file, which will always happen, so just exit
        -- ===========================================================================
        NULL;
    END;*/ -- commented for defect#31115

    -- ===========================================================================
    -- close and return the file handle
    -- ===========================================================================
    --UTL_FILE.fclose(l_file); -- commented for defect#31115
	DBMS_LOB.FILECLOSEALL(); -- added for defect#31115
  END;

  put_log_line( 'Return the XML File as a BLOB.' );

  -- ===========================================================================
  -- return the CLOB containing the XML data
  -- ===========================================================================
  RETURN l_result;

END get_print_cons_inv_xml_data;




-- ===========================================================================
-- procedure that submits the OD Print Selected Invoices, so that the XML
--   data can be generated (from an rdf - Oracle Report definition)
-- ===========================================================================
FUNCTION get_print_invoice_xml_data
( p_cust_account_id        IN   NUMBER,
  p_invoice_trx_list       IN   VARCHAR2,
  p_fax_number             IN   VARCHAR2,
  p_xdo_template_app       IN   VARCHAR2,
  p_xdo_template_name      IN   VARCHAR2 )
RETURN CLOB
IS
  lc_sub_name     CONSTANT VARCHAR2(50)     := 'GET_PRINT_INVOICE_XML_DATA';

  n_conc_request_id        NUMBER              DEFAULT NULL;

  b_sub_request            BOOLEAN             DEFAULT FALSE;

  v_return_msg             VARCHAR2(4000)      DEFAULT NULL;

  v_phase_code             VARCHAR2(30)        DEFAULT NULL;
  v_phase_desc             VARCHAR2(80)        DEFAULT NULL;
  v_status_code            VARCHAR2(30)        DEFAULT NULL;
  v_status_desc            VARCHAR2(80)        DEFAULT NULL;

  v_request_name           VARCHAR2(200)       DEFAULT NULL;

  v_user_language          VARCHAR2(30)        DEFAULT NULL;
  v_user_territory         VARCHAR2(30)        DEFAULT NULL;

  v_xml_file_location      VARCHAR2(500)       DEFAULT NULL;
  v_copied_xml_file_loc    VARCHAR2(500)       DEFAULT NULL;
  v_copied_xml_file_name   VARCHAR2(500)       DEFAULT NULL;

  b_success                BOOLEAN             DEFAULT NULL;
  n_mbs_document_id        NUMBER              DEFAULT NULL;

  l_result                 CLOB;
  
  b_set_print_options      boolean             default false;
  b_send_fax               boolean             default false;
  l_is_valid_non_prod_fax  VARCHAR2(1)         DEFAULT NULL;
  
  l_fax_printer            VARCHAR2(60)        DEFAULT NULL;
  l_fax_print_style        VARCHAR2(60)        DEFAULT NULL;
  l_instance_name          VARCHAR2(15)        DEFAULT NULL;

  CURSOR c_cust_doc
  ( cp_cust_account_id    IN    NUMBER )
  IS
    SELECT billdocs_doc_id
      FROM XX_CDH_A_EXT_BILLDOCS_V
     WHERE billdocs_doc_type = 'Invoice'
       AND billdocs_delivery_meth = 'PRINT'
       AND cust_account_id = cp_cust_account_id;

  CURSOR c_user_lang IS
    SELECT LOWER(iso_language) user_language,
           iso_territory user_territory
      FROM fnd_languages_vl
     WHERE language_code = FND_GLOBAL.CURRENT_LANGUAGE;

  CURSOR c_file
  ( cp_conc_request_id    IN    NUMBER )
  IS
    SELECT outfile_name
      FROM fnd_concurrent_requests
     WHERE request_id = cp_conc_request_id;
     
  CURSOR c_non_prod_fax_check ( p_fax_number IN VARCHAR2) 
  IS
   SELECT 'Y' from (select XFT.target_value1
    FROM   xx_fin_translatedefinition XFTD
          ,xx_fin_translatevalues XFT
    WHERE  XFTD.translate_id = XFT.translate_id
    AND    XFTD.translation_name = 'XX_IREC_FAX_SETTINGS'
    AND    XFT.enabled_flag = 'Y'
    AND    XFT.source_value1 = 'NON_PROD_FAX_NUMBER') qrlst 
    WHERE  TRIM(TARGET_VALUE1)= p_fax_number;
     
BEGIN
  put_log_line('Run the Invoice Reprint Program and copy the output.  ');
  put_log_line(' Customer Account Id   = ' || p_cust_account_id );
  put_log_line(' Invoice Trx List      = ' || p_invoice_trx_list );
  put_log_line(' Fax Number (if faxed) = ' || p_fax_number );
  put_log_line(' XDO Template Appl     = ' || p_xdo_template_app );
  put_log_line(' XDO Template Code     = ' || p_xdo_template_name );

  -- ===========================================================================
  -- set child flag if this is a child request
  -- ===========================================================================
  IF (FND_GLOBAL.CONC_REQUEST_ID IS NOT NULL) THEN
    b_sub_request := TRUE;
  END IF;

  -- ===========================================================================
  -- get mbs document id
  -- ===========================================================================
  OPEN c_cust_doc
  ( cp_cust_account_id  => p_cust_account_id);
  FETCH c_cust_doc
   INTO n_mbs_document_id;
  CLOSE c_cust_doc;

  -- ===========================================================================
  -- default to std invoice document if not found
  -- ===========================================================================
  IF (n_mbs_document_id IS NULL) THEN
    n_mbs_document_id := GN_DEFAULT_DOCUMENT_ID;
  END IF;

  put_log_line(' MBS Document ID = ' || n_mbs_document_id );

  -- ===========================================================================
  -- get the user's current language and territory
  -- ===========================================================================
  OPEN c_user_lang;
  FETCH c_user_lang
   INTO v_user_language,
        v_user_territory;
  CLOSE c_user_lang;

  put_log_line(' User Language = ' || v_user_language );
  put_log_line(' User Territory = ' || v_user_territory );

  -- ===========================================================================
  -- add the layout for the invoice reprint
  --
  -- ===========================================================================
  b_success :=
    FND_REQUEST.add_layout
    ( template_appl_name    => p_xdo_template_app,
      template_code         => p_xdo_template_name,
      template_language     => v_user_language,
      template_territory    => v_user_territory,
      output_format         => GC_XDO_TEMPLATE_FORMAT );

  IF (b_success) THEN
    put_log_line( ' Successfully added the XML Template as a Layout.' );
  ELSE
    put_log_line( ' *** Unable to add the XML Template to the Layout.' );
  END IF;

  --DEFECT 41430 - FOLLOWING CHANGE HAS BEEN MADE TO SET THE FAX PRINTER AND PRINT STYLE.
  --ALSO, A CONTROL HAS BEEN PLACED TO SAFEGAURD NOT TO SEND ANY FAX TO REAL CUSTOMERS
  --FROM ANY NON-PROD INSTANCE. IF ANY ONE WANTS TO TEST A FAX IN NON-PROD INSTANCE,
  --THEY NEED TO SET THAT FAX NUMBER IN 'NON_PROD_FAX_NUMBER' OF 'XX_IREC_FAX_SETTINGS' TRANSLATION
  IF ( (p_fax_number IS NOT NULL ) OR (trim(p_fax_number) != '')) THEN 
      BEGIN
        SELECT XFT.target_value1
        INTO   l_fax_printer
        FROM   xx_fin_translatedefinition XFTD
              ,xx_fin_translatevalues XFT
        WHERE  XFTD.translate_id = XFT.translate_id
        AND    XFTD.translation_name = 'XX_IREC_FAX_SETTINGS'
        AND    XFT.enabled_flag = 'Y'
        AND    XFT.source_value1 = 'IREC_FAX_PRINTER'
        ;

        SELECT XFT.target_value1
        INTO   l_fax_print_style
        FROM   xx_fin_translatedefinition XFTD
              ,xx_fin_translatevalues XFT
        WHERE  XFTD.translate_id = XFT.translate_id
        AND    XFTD.translation_name = 'XX_IREC_FAX_SETTINGS'
        AND    XFT.enabled_flag = 'Y'
        AND    XFT.source_value1 = 'IREC_FAX_PRINT_STYLE'
        ;
        
        /*
        SELECT INSTANCE_NAME
        INTO   l_instance_name
        FROM   GV$INSTANCE 
        ;
        */
		
		/*
        select name 
        INTO   l_instance_name
        from v$database; 
		*/
		
		SELECT SUBSTR(SYS_CONTEXT('USERENV','DB_NAME'),1,8) 		-- Changed from INSTANCE_NAME to DB_NAME
		INTO l_instance_name
		FROM dual;
        
        OPEN c_non_prod_fax_check (p_fax_number);
        FETCH c_non_prod_fax_check INTO l_is_valid_non_prod_fax;
        
        IF (c_non_prod_fax_check%ROWCOUNT = 0) THEN
          l_is_valid_non_prod_fax := 'N';
        END IF;
        
        EXCEPTION
        WHEN OTHERS THEN
          put_log_line( 'Cannot Retrieve Fax Printer and style details: ' || n_conc_request_id || '.' );
      END;
      
      IF (l_instance_name = 'GSIPRDGB') THEN
         b_send_fax := true;
      ELSIF ( l_is_valid_non_prod_fax = 'Y') THEN
         b_send_fax := true;
      ELSE     
         b_send_fax := false;
      END IF;  

      IF (b_send_fax) THEN
        b_set_print_options := FND_REQUEST.set_print_options (
                                  printer        => l_fax_printer, --'HFPS',
                                  style          => l_fax_print_style, --'PDF Publisher Fax',
                                  copies         => 1
                               );
      END IF;  
  END IF;  
  --END IF DEFECT 41430 CHANGE
  
  put_log_line( 'Submit the Invoice Reprint program (XXFIN, XXARINVIND).' );

  -- ===========================================================================
  -- submit the request
  --   20-Aug-2007 - BLooman - changes made for version 1.1 (new print program)
  -- ===========================================================================
  n_conc_request_id :=
    FND_REQUEST.submit_request
    ( application    => 'XXFIN',                 -- application short name
      program        => 'XXARINVIND',            -- concurrent program name
      description    => GC_SUB_REQUEST_NAME,     -- additional request description
      start_time     => NULL,                    -- request submit time
      sub_request    => b_sub_request,           -- is this a sub-request?
      argument1      => p_cust_account_id,       -- Customer Account number
      argument2      => NULL,                    -- Transaction Number
      argument3      => NULL,                    -- Transaction Date Low
      argument4      => NULL,                    -- Transaction Date High
      argument5      => 'N',                     -- Open Invoices Only
      argument6      => n_mbs_document_id,       -- MBS Document ID
      argument7      => p_fax_number,            -- Fax Number
      argument8      => p_invoice_trx_list,      -- Multiple Trx List
      argument9      => 'HED' );                 -- Source (default "Hedberg")

  -- ===========================================================================
  -- if request was successful
  -- ===========================================================================
  IF (n_conc_request_id > 0) THEN
    -- ===========================================================================
    -- if a child request, then update it for concurrent mgr to process
    -- ===========================================================================
    IF (b_sub_request) THEN
      UPDATE fnd_concurrent_requests
         SET phase_code = 'P',
             status_code = 'I'
       WHERE request_id = n_conc_request_id;
    END IF;

    -- ===========================================================================
    -- must commit work so that the concurrent manager polls the request
    -- ===========================================================================
    COMMIT;

    put_log_line( ' Concurrent Request ID: ' || n_conc_request_id || '.' );

  -- ===========================================================================
  -- else errors have occured for request
  -- ===========================================================================
  ELSE
    -- ===========================================================================
    -- retrieve and raise any errors
    -- ===========================================================================
    --FND_MESSAGE.retrieve( v_return_msg );
    FND_MESSAGE.raise_error;
  END IF;

  put_log_line( 'Wait for the Invoice Reprint to Complete... ' );

  -- ===========================================================================
  -- wait on the completion of this request
  -- ===========================================================================
  IF NOT FND_CONCURRENT.wait_for_request
    ( request_id    => n_conc_request_id,
      interval      => 5,                      -- check every 5 secs
      max_wait      => 60*60,                  -- check for max of 1 hour
      phase         => v_phase_desc,
      status        => v_status_desc,
      dev_phase     => v_phase_code,
      dev_status    => v_status_code,
      message       => v_return_msg
      )
  THEN
    RAISE_APPLICATION_ERROR( -20200, v_return_msg );
  END IF;

  put_log_line( 'Finished waiting on Concurrent Request ' || n_conc_request_id || '.' );
  put_log_line( '  Phase  : ' || v_phase_code || ' (' || v_phase_desc || ')' );
  put_log_line( '  Status : ' || v_status_code || ' (' || v_status_desc || ')' );
  put_log_line( '' );

  -- ===========================================================================
  -- if request was not successful
  -- ===========================================================================
  IF (v_status_code <> 'NORMAL') THEN
    RAISE_APPLICATION_ERROR( -20201, 'Concurrent Request completed, but had errors or warnings.' );
  END IF;

  -- ===========================================================================
  -- read the report output file location for the Invoice XML Data
  -- ===========================================================================
  OPEN c_file
  ( cp_conc_request_id   => n_conc_request_id );
  FETCH c_file
   INTO v_xml_file_location;
  CLOSE c_file;

  put_log_line( ' Invoice Reprint Program Output location = ' );
  put_log_line( '  ' || v_xml_file_location );

  -- ===========================================================================
  -- check that the dba directory name exists for utl tmp out
  -- ===========================================================================
  IF (NOT utl_tmp_out_directory_exists()) THEN
    RAISE_APPLICATION_ERROR
    ( -20145, 'Directory "' || GC_UTL_TMP_OUT_DIR_NAME ||
      '" is not defined in table DBA_DIRECTORIES.' );
  END IF;

  -- ===========================================================================
  -- set the file location where to copy the xml data file
  -- ===========================================================================
  v_copied_xml_file_name := 'xxarinv-' || n_conc_request_id || '.xml';
  v_copied_xml_file_loc  :=
    get_utl_tmp_out_directory_path() || GC_FILE_DIR_SEPARATOR || v_copied_xml_file_name;

  put_log_line( ' Copied XML File Name: ' || v_copied_xml_file_name );
  put_log_line( ' Copied XML File Location: ' || v_copied_xml_file_loc );

  put_log_line( 'Submit the Copy File Program (XXFIN, XXCOMIRECFILCOPY)' );

  -- ===========================================================================
  -- previous request produced XML output, however this directory cannot be
  --   read using UTL_FILE, so we have to call a common file copy concurrent
  --   program to place it in a location where it can be read
  -- ===========================================================================
  n_conc_request_id :=
    FND_REQUEST.submit_request
    ( application    => 'XXFIN',                     -- application short name
      program        => 'XXCOMIRECFILCOPY',          -- concurrent program name
      description    => 'OD: iRec Copy Invoice XML File', -- additional request description
      start_time     => NULL,                        -- request submit time
      sub_request    => b_sub_request,               -- is this a sub-request?
      argument1      => v_xml_file_location,         -- Source file
      argument2      => v_copied_xml_file_loc,       -- Destination file
      argument3      => '',                          -- Source string
      argument4      => '' ,                         -- Destination string
      argument5      => 'Y' ,                         -- Delete Flag
      argument6      => '$XXFIN_DATA/archive/inbound');  -- Archive File Path

  -- ===========================================================================
  -- if request was successful
  -- ===========================================================================
  IF (n_conc_request_id > 0) THEN
    -- ===========================================================================
    -- if a child request, then update it for concurrent mgr to process
    -- ===========================================================================
    IF (b_sub_request) THEN
      UPDATE fnd_concurrent_requests
         SET phase_code = 'P',
             status_code = 'I'
       WHERE request_id = n_conc_request_id;
    END IF;

    -- ===========================================================================
    -- must commit work so that the concurrent manager polls the request
    -- ===========================================================================
    COMMIT;

    put_log_line( ' Concurrent Request ID: ' || n_conc_request_id || '.' );

  -- ===========================================================================
  -- else errors have occured for request
  -- ===========================================================================
  ELSE
    -- ===========================================================================
    -- retrieve and raise any errors
    -- ===========================================================================
    --FND_MESSAGE.retrieve( v_return_msg );
    FND_MESSAGE.raise_error;
  END IF;

  put_log_line( 'Wait for the Output File Copy Program to Complete... ' );

  -- ===========================================================================
  -- wait on the completion of this copy file request
  -- ===========================================================================
  IF NOT FND_CONCURRENT.wait_for_request
    ( request_id    => n_conc_request_id,
      interval      => 5,                      -- check every 5 secs
      max_wait      => 60*60,                  -- check for max of 1 hour
      phase         => v_phase_desc,
      status        => v_status_desc,
      dev_phase     => v_phase_code,
      dev_status    => v_status_code,
      message       => v_return_msg
      )
  THEN
    RAISE_APPLICATION_ERROR( -20200, v_return_msg );
  END IF;

  put_log_line( 'Finished waiting on Concurrent Request ' || n_conc_request_id || '.' );
  put_log_line( '  Phase  : ' || v_phase_code || ' (' || v_phase_desc || ')' );
  put_log_line( '  Status : ' || v_status_code || ' (' || v_status_desc || ')' );
  put_log_line( '' );

  -- ===========================================================================
  -- if request was not successful
  -- ===========================================================================
  IF (v_status_code <> 'NORMAL') THEN
    RAISE_APPLICATION_ERROR( -20201, 'Concurrent Request completed, but had errors or warnings.' );
  END IF;

  put_log_line( 'Create an empty, temporary BLOB.' );

  -- ===========================================================================
  -- create a temporary clob to store the XML invoice data
  -- ===========================================================================
  l_result := EMPTY_CLOB();
  DBMS_LOB.createtemporary(l_result,TRUE);

  -- ===========================================================================
  -- read the copied file (XML Data) into the CLOB
  -- ===========================================================================
  DECLARE
    l_file       UTL_FILE.FILE_TYPE;
    lc_buffer    VARCHAR2(2000);
  src_offset number := 1 ;
  dest_offset number := 1 ;
  lang_ctx number := DBMS_LOB.DEFAULT_LANG_CTX;
  warning integer;	
  BEGIN
    -- ===========================================================================
    -- check that the dba directory name exists for utl tmp out
    -- ===========================================================================
    IF (NOT utl_tmp_out_directory_exists()) THEN
      RAISE_APPLICATION_ERROR
      ( -20145, 'Directory "' || GC_UTL_TMP_OUT_DIR_NAME ||
        '" is not defined in table DBA_DIRECTORIES.' );
    END IF;

    put_log_line( 'Open this XML file for reading.' );

    -- ===========================================================================
    -- open and read the XML data file
    -- ===========================================================================
    l_file := UTL_FILE.fopen(GC_UTL_TMP_OUT_DIR_NAME,v_copied_xml_file_name,'r');
	
    put_log_line( 'Write the file to the temporary BLOB' );

    BEGIN
      LOOP
        -- ===========================================================================
        -- read a line from the file
        -- ===========================================================================
        UTL_FILE.get_line(l_file,lc_buffer);

        -- ===========================================================================
        -- add back a carriage return character to the end of the line
        -- ===========================================================================
        lc_buffer := lc_buffer || chr(10);

        -- ===========================================================================
        -- append this buffer to the end of the clob
        -- ===========================================================================
        DBMS_LOB.writeappend(l_result,LENGTH(lc_buffer),lc_buffer);
      END LOOP;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ===========================================================================
        -- occurs at the end of file, which will always happen, so just exit
        -- ===========================================================================
        NULL;
    END;

    -- ===========================================================================
    -- close and return the file handle
    -- ===========================================================================
    UTL_FILE.fclose(l_file);
  END;

  put_log_line( 'Return the XML File as a BLOB.' );

  -- ===========================================================================
  -- return the CLOB containing the XML data
  -- ===========================================================================
  RETURN l_result;

END get_print_invoice_xml_data;


-- ===========================================================================
-- function that sends consolidated invoices to the customer (returns conc request id)
-- ===========================================================================
FUNCTION send_consolidated_invoices
( p_cust_account_id        IN   NUMBER,
  p_invoice_trx_list       IN   VARCHAR2,
  p_email_flag             IN   VARCHAR2    DEFAULT 'N',
  p_email_address          IN   VARCHAR2    DEFAULT NULL,
  p_fax_flag               IN   VARCHAR2    DEFAULT 'N',
  p_fax_number             IN   VARCHAR2    DEFAULT NULL,
  p_print_flag             IN   VARCHAR2    DEFAULT 'N',
  p_printer_location       IN   VARCHAR2    DEFAULT NULL )
RETURN NUMBER
IS
  lc_sub_name        CONSTANT VARCHAR2(50)    := 'SEND_INVOICES';

  n_doc_index                 NUMBER          DEFAULT 1;
  n_dest_index                NUMBER          DEFAULT 1;
  n_conc_request_id           NUMBER          DEFAULT NULL;

  lc_fax_prefix               VARCHAR2(20)    DEFAULT NULL;
  lc_fax_number               VARCHAR2(100)   DEFAULT NULL;

  ls_xdo_app_short_name       FND_CONC_PP_ACTIONS.argument1%TYPE;
  ls_xdo_template_code        FND_CONC_PP_ACTIONS.argument2%TYPE;

  a_trx_number_array          STRINGARRAY   DEFAULT STRINGARRAY();

  r_xdo_request               XX_XDO_REQUESTS%ROWTYPE;
  r_xdo_request_docs_tab      XX_XDO_REQUESTS_API_PKG.gt_xdo_request_docs_tab;
  r_xdo_request_dests_tab     XX_XDO_REQUESTS_API_PKG.gt_xdo_request_dests_tab;

  x_xdo_request               XX_XDO_REQUESTS%ROWTYPE;
  x_xdo_request_docs_tab      XX_XDO_REQUESTS_API_PKG.gt_xdo_request_docs_tab;
  x_xdo_request_dests_tab     XX_XDO_REQUESTS_API_PKG.gt_xdo_request_dests_tab;
  lc_invoice_trx_list   varchar2(4000) default null;
BEGIN
  -- error if sending more than the allowed number of invoices (the length of trx list should not exceed 150 chars - about 10 invoices)
  IF (LENGTH(p_invoice_trx_list) > 2000) THEN
    FND_MESSAGE.set_name('XXFIN','XX_ARI_0013_001_TRX_LIST_SIZE');
    RAISE_APPLICATION_ERROR(-20013, FND_MESSAGE.get() );
  END IF;

  -- Validate the fax number starts with the corrent Fax prefix (i.e. 9,1...)
  IF (UPPER(p_fax_flag) = 'Y') THEN
    lc_fax_prefix := FND_PROFILE.value('XX_XDO_FAX_PREFIX');
    IF (p_fax_number NOT LIKE lc_fax_prefix || '%') THEN -- If the fax number does not start with the required prefix, add it
      lc_fax_number := FND_PROFILE.value('XX_XDO_FAX_PREFIX') || p_fax_number;
    ELSE
      lc_fax_number := p_fax_number;
    END IF;
  END IF;

  -- define the source application references
  r_xdo_request.source_app_code    := GC_SOURCE_APP_CODE;
  r_xdo_request.source_name        := GC_SOURCE_NAME;
  r_xdo_request.xdo_request_name   := GC_CONC_REQUEST_NAME || ' (' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ')';

  -- get the transaction list as an array from the comma-delimited values
  	/*Added for NAIT-119893-To handle 50 Invoices trx list*/
   	  BEGIN
  			select consolidate_bill_list 
				into lc_invoice_trx_list
				from XX_AR_INVOICE_COPY_LIST 
    		where group_id= p_invoice_trx_list;
  		Exception when others then 
  			lc_invoice_trx_list:=p_invoice_trx_list;
  		end;
  
  --a_trx_number_array := explode( p_string => p_invoice_trx_list, p_delimiter => ',' );
  a_trx_number_array := explode( p_string => lc_invoice_trx_list, p_delimiter => ',' );

  -- for each transaction build the document data and insert the record
  IF (a_trx_number_array.COUNT <= 0) THEN
    RAISE_APPLICATION_ERROR( -20140, 'Unable to parse invoice trx list parameter' );
  ELSE
    FOR i_index IN a_trx_number_array.FIRST..a_trx_number_array.LAST LOOP
      -- get the xml data for the given invoice
      r_xdo_request_docs_tab(n_doc_index).xml_data := get_print_cons_inv_xml_data
                                                      ( p_cust_account_id    => p_cust_account_id
                                                       ,p_cons_inv_id        => a_trx_number_array(i_index)
                                                       ,x_xdo_app_short_name => ls_xdo_app_short_name
                                                       ,x_xdo_template_code  => ls_xdo_template_code);

      -- assign the XML Publisher template name, source key, and document definitions
      r_xdo_request_docs_tab(n_doc_index).xdo_app_short_name     := ls_xdo_app_short_name;
      r_xdo_request_docs_tab(n_doc_index).xdo_template_code      := ls_xdo_template_code;
      r_xdo_request_docs_tab(n_doc_index).source_key1            := a_trx_number_array(i_index);
      --r_xdo_request_docs_tab(n_doc_index).store_document_flag    := 'N';
      r_xdo_request_docs_tab(n_doc_index).document_file_name     := 'inv-' || REPLACE(a_trx_number_array(i_index),' ','_');
      r_xdo_request_docs_tab(n_doc_index).document_file_type     := 'pdf';
      r_xdo_request_docs_tab(n_doc_index).document_content_type  := 'application/pdf';

      n_doc_index := n_doc_index + 1;
    END LOOP;
  END IF;

/*
  -- get the xml data for the given invoice
  r_xdo_request_docs_tab(1).xml_data := get_print_cons_inv_xml_data
                                        ( p_cust_account_id    => p_cust_account_id
                                         ,p_cons_inv_id        => p_invoice_trx_list
                                         ,x_xdo_app_short_name => ls_xdo_app_short_name
                                         ,x_xdo_template_code  => ls_xdo_template_code);

  -- assign the XML Publisher template name, source key, and document definitions

                              --   select application_short_name,template_code from xdo_templates_vl where template_name='OD: AR Print Summary Bill[SUMMARY]'

  r_xdo_request_docs_tab(1).xdo_app_short_name     := ls_xdo_app_short_name; -- 'XXFIN';
  r_xdo_request_docs_tab(1).xdo_template_code      := ls_xdo_template_code;  -- 'XXARCBISUM';
  r_xdo_request_docs_tab(1).source_key1            := p_invoice_trx_list;
  --r_xdo_request_docs_tab(1).store_document_flag    := 'N';
  r_xdo_request_docs_tab(1).document_file_name     := 'inv-' || REPLACE(REPLACE(SUBSTR(p_invoice_trx_list,1,28),',','-'),' ');
  r_xdo_request_docs_tab(1).document_file_type     := 'pdf';
  r_xdo_request_docs_tab(1).document_content_type  := 'application/pdf';
*/

  IF (UPPER(p_email_flag) = 'Y') THEN -- if the invoices should be sent via email

    -- create a destination record with the email address and email subject/body
    r_xdo_request_dests_tab(n_dest_index).delivery_method   := 'EMAIL';
    r_xdo_request_dests_tab(n_dest_index).destination       := p_email_address;
    r_xdo_request_dests_tab(n_dest_index).language_code     := USERENV('LANG');

    -- get the email subject from the application messages
    FND_MESSAGE.set_name('XXFIN','XX_AR_INVOICE_COPY_EMAIL_SUBJ');
    r_xdo_request_dests_tab(n_dest_index).subject_message   := FND_MESSAGE.get();

    -- get the email body from the application messages
    FND_MESSAGE.set_name('XXFIN','XX_AR_INVOICE_COPY_EMAIL_BODY');
    r_xdo_request_dests_tab(n_dest_index).body_message      := FND_MESSAGE.get();

    n_dest_index := n_dest_index + 1;     -- increment the destination record index
  END IF;

  IF (UPPER(p_fax_flag) = 'Y') THEN  -- if the invoices should be sent via fax
    -- ===========================================================================
    -- create a destination record with the fax number
    --   10-SEP-2007 - BLooman - New fax procedures:
    --   Changed the handling of fax destinations - all fax based documents now
    --    are required to have a dummy first page and are to be sent to the
    --    PRINTER /printers/HFPS (Postscript printing through a fax server).
    --   The body message will now contain the fax number since the destination
    --    must contain the printer location
    -- ===========================================================================
    --r_xdo_request_dests_tab(n_dest_index).delivery_method   := 'FAX';
    --r_xdo_request_dests_tab(n_dest_index).destination       := p_fax_number;
    r_xdo_request_dests_tab(n_dest_index).delivery_method := 'PRINTER';
    r_xdo_request_dests_tab(n_dest_index).destination := FND_PROFILE.value('XX_XDO_FAX_PRINTER');
    r_xdo_request_dests_tab(n_dest_index).body_message := 'FAX_NUMBER = ' || lc_fax_number;

    n_dest_index := n_dest_index + 1; -- increment the destination record index
  END IF;

  IF (UPPER(p_print_flag) = 'Y') THEN -- if the invoices should be sent via printer
    -- create a destination record with the printer name (as Unix queue location)
    r_xdo_request_dests_tab(n_dest_index).delivery_method   := 'PRINTER';
    r_xdo_request_dests_tab(n_dest_index).destination       := p_printer_location;

    n_dest_index := n_dest_index + 1; -- increment the destination record index
  END IF;

  IF (n_dest_index <= 1) THEN -- if no destination was defined, then throw an exception
    RAISE_APPLICATION_ERROR ( -20144, 'At least one destination must be given - EMAIL, FAX, PRINTER' );
  END IF;

  -- create the XDO request with all the destination and document records
  XX_XDO_REQUESTS_API_PKG.create_new_request ( P_XDO_REQUEST             => r_xdo_request,
                                               P_XDO_REQUEST_DOCS_TAB    => r_xdo_request_docs_tab,
                                               P_XDO_REQUEST_DESTS_TAB   => r_xdo_request_dests_tab,
                                               X_XDO_REQUEST             => x_xdo_request,
                                               X_XDO_REQUEST_DOCS_TAB    => x_xdo_request_docs_tab,
                                               X_XDO_REQUEST_DESTS_TAB   => x_xdo_request_dests_tab );

  put_log_line( 'XDO Request Group ID= ' || x_xdo_request.xdo_request_group_id );
  put_log_line( 'XDO Request ID= ' || x_xdo_request.xdo_request_id );

  -- submit the java concurrent program that will process the XDO Request that has been created for sending the invoice copies
  n_conc_request_id := XX_XDO_REQUESTS_API_PKG.process_irec_request
                       ( p_xdo_request_group_id  => x_xdo_request.xdo_request_group_id,
                         p_xdo_request_id        => x_xdo_request.xdo_request_id,
                         p_wait_for_completion   => 'N',
                         p_request_name          => GC_CONC_REQUEST_NAME );

  put_log_line( 'Conc Request ID= ' || n_conc_request_id );

  RETURN n_conc_request_id;
END send_consolidated_invoices;



-- ===========================================================================
-- Function that sends invoices to the customer (returns conc request id).
--  Assumes checks have already been made to ensure trx request valid.
-- ===========================================================================
FUNCTION send_individual_invoices
( p_cust_account_id        IN   NUMBER,
  p_invoice_trx_list       IN   VARCHAR2,
  p_xdo_template_app       IN   VARCHAR2,
  p_xdo_template_name      IN   VARCHAR2,
  p_email_flag             IN   VARCHAR2    DEFAULT 'N',
  p_email_address          IN   VARCHAR2    DEFAULT NULL,
  p_fax_flag               IN   VARCHAR2    DEFAULT 'N',
  p_fax_number             IN   VARCHAR2    DEFAULT NULL,
  p_print_flag             IN   VARCHAR2    DEFAULT 'N',
  p_printer_location       IN   VARCHAR2    DEFAULT NULL )
RETURN NUMBER
IS
  lc_sub_name        CONSTANT VARCHAR2(50)    := 'SEND_INVOICES';

  n_dest_index                NUMBER          DEFAULT 1;
  n_conc_request_id           NUMBER          DEFAULT NULL;

  lc_fax_prefix               VARCHAR2(20)    DEFAULT NULL;
  lc_fax_number               VARCHAR2(100)   DEFAULT NULL;

  r_xdo_request               XX_XDO_REQUESTS%ROWTYPE;
  r_xdo_request_docs_tab      XX_XDO_REQUESTS_API_PKG.gt_xdo_request_docs_tab;
  r_xdo_request_dests_tab     XX_XDO_REQUESTS_API_PKG.gt_xdo_request_dests_tab;

  x_xdo_request               XX_XDO_REQUESTS%ROWTYPE;
  x_xdo_request_docs_tab      XX_XDO_REQUESTS_API_PKG.gt_xdo_request_docs_tab;
  x_xdo_request_dests_tab     XX_XDO_REQUESTS_API_PKG.gt_xdo_request_dests_tab;
  lc_invoicelist varchar2(4000);
BEGIN

  -- Validate the fax number starts with the corrent Fax prefix (i.e. 9,1...)
  IF (UPPER(p_fax_flag) = 'Y') THEN
    lc_fax_prefix := FND_PROFILE.value('XX_XDO_FAX_PREFIX');
    IF (p_fax_number NOT LIKE lc_fax_prefix || '%') THEN -- If the fax number does not start with the required prefix, add it
      lc_fax_number := FND_PROFILE.value('XX_XDO_FAX_PREFIX') || p_fax_number;
    ELSE
      lc_fax_number := p_fax_number;
    END IF;
  END IF;

  -- define the source application references
  r_xdo_request.source_app_code    := GC_SOURCE_APP_CODE;
  r_xdo_request.source_name        := GC_SOURCE_NAME;
  r_xdo_request.xdo_request_name   := GC_CONC_REQUEST_NAME || ' (' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ')';

  -- get the xml data for the given invoice
  r_xdo_request_docs_tab(1).xml_data := get_print_invoice_xml_data
                                        ( p_cust_account_id    => p_cust_account_id,
                                          p_invoice_trx_list   => p_invoice_trx_list,
                                          p_fax_number         => lc_fax_number,
                                          p_xdo_template_app   => p_xdo_template_app,
                                          p_xdo_template_name  => p_xdo_template_name );

  -- assign the XML Publisher template name, source key, and document definitions
  r_xdo_request_docs_tab(1).xdo_app_short_name     := p_xdo_template_app;
  r_xdo_request_docs_tab(1).xdo_template_code      := p_xdo_template_name;
  r_xdo_request_docs_tab(1).source_key1            := p_invoice_trx_list;
  --r_xdo_request_docs_tab(1).store_document_flag    := 'N';
  if substr(p_invoice_trx_list,1,6)='INVCPY' then 
	
	BEGIN
		select INVOICE_TRX_LIST 
			into lc_invoicelist
			from XX_AR_INVOICE_COPY_LIST 
		where group_id= p_invoice_trx_list; 
		r_xdo_request_docs_tab(1).document_file_name     := 'inv-' || REPLACE(REPLACE(SUBSTR(lc_invoicelist,1,28),',','-'),' ');
		
	Exception 
	when others then 
	put_log_line( 'Multiple Invoice List not found in XX_AR_INVOICE_COPY_LIST for Inv Group ID-' ||p_invoice_trx_list );
	r_xdo_request_docs_tab(1).document_file_name     := 'inv-' || REPLACE(REPLACE(SUBSTR(p_invoice_trx_list,1,28),',','-'),' ');
	end;
	
  else
  r_xdo_request_docs_tab(1).document_file_name     := 'inv-' || REPLACE(REPLACE(SUBSTR(p_invoice_trx_list,1,28),',','-'),' ');
  end if;
  
  --r_xdo_request_docs_tab(1).document_file_name     := 'inv-' || REPLACE(REPLACE(SUBSTR(p_invoice_trx_list,1,28),',','-'),' ');
  r_xdo_request_docs_tab(1).document_file_type     := 'pdf';
  r_xdo_request_docs_tab(1).document_content_type  := 'application/pdf';

  IF (UPPER(p_email_flag) = 'Y') THEN -- if the invoices should be sent via email

    -- create a destination record with the email address and email subject/body
    r_xdo_request_dests_tab(n_dest_index).delivery_method   := 'EMAIL';
    r_xdo_request_dests_tab(n_dest_index).destination       := p_email_address;
    r_xdo_request_dests_tab(n_dest_index).language_code     := USERENV('LANG');

    -- get the email subject from the application messages
    FND_MESSAGE.set_name('XXFIN','XX_AR_INVOICE_COPY_EMAIL_SUBJ');
    r_xdo_request_dests_tab(n_dest_index).subject_message   := FND_MESSAGE.get();

    -- get the email body from the application messages
    FND_MESSAGE.set_name('XXFIN','XX_AR_INVOICE_COPY_EMAIL_BODY');
    r_xdo_request_dests_tab(n_dest_index).body_message      := FND_MESSAGE.get();

    n_dest_index := n_dest_index + 1;     -- increment the destination record index
  END IF;

  IF (UPPER(p_fax_flag) = 'Y') THEN  -- if the invoices should be sent via fax
    -- ===========================================================================
    -- create a destination record with the fax number
    --   10-SEP-2007 - BLooman - New fax procedures:
    --   Changed the handling of fax destinations - all fax based documents now
    --    are required to have a dummy first page and are to be sent to the
    --    PRINTER /printers/HFPS (Postscript printing through a fax server).
    --   The body message will now contain the fax number since the destination
    --    must contain the printer location
    -- ===========================================================================
    --r_xdo_request_dests_tab(n_dest_index).delivery_method   := 'FAX';
    --r_xdo_request_dests_tab(n_dest_index).destination       := p_fax_number;
    r_xdo_request_dests_tab(n_dest_index).delivery_method := 'PRINTER';
    r_xdo_request_dests_tab(n_dest_index).destination := FND_PROFILE.value('XX_XDO_FAX_PRINTER');
    r_xdo_request_dests_tab(n_dest_index).body_message := 'FAX_NUMBER = ' || lc_fax_number;

    n_dest_index := n_dest_index + 1; -- increment the destination record index
  END IF;

  IF (UPPER(p_print_flag) = 'Y') THEN -- if the invoices should be sent via printer
    -- create a destination record with the printer name (as Unix queue location)
    r_xdo_request_dests_tab(n_dest_index).delivery_method   := 'PRINTER';
    r_xdo_request_dests_tab(n_dest_index).destination       := p_printer_location;

    n_dest_index := n_dest_index + 1; -- increment the destination record index
  END IF;

  IF (n_dest_index <= 1) THEN -- if no destination was defined, then throw an exception
    RAISE_APPLICATION_ERROR ( -20144, 'At least one destination must be given - EMAIL, FAX, PRINTER' );
  END IF;

  -- create the XDO request with all the destination and document records
  XX_XDO_REQUESTS_API_PKG.create_new_request ( P_XDO_REQUEST             => r_xdo_request,
                                               P_XDO_REQUEST_DOCS_TAB    => r_xdo_request_docs_tab,
                                               P_XDO_REQUEST_DESTS_TAB   => r_xdo_request_dests_tab,
                                               X_XDO_REQUEST             => x_xdo_request,
                                               X_XDO_REQUEST_DOCS_TAB    => x_xdo_request_docs_tab,
                                               X_XDO_REQUEST_DESTS_TAB   => x_xdo_request_dests_tab );

  put_log_line( 'XDO Request Group ID= ' || x_xdo_request.xdo_request_group_id );
  put_log_line( 'XDO Request ID= ' || x_xdo_request.xdo_request_id );

  -- submit the java concurrent program that will process the XDO Request that has been created for sending the invoice copies
  n_conc_request_id := XX_XDO_REQUESTS_API_PKG.process_irec_request
                       ( p_xdo_request_group_id  => x_xdo_request.xdo_request_group_id,
                         p_xdo_request_id        => x_xdo_request.xdo_request_id,
                         p_wait_for_completion   => 'N',
                         p_request_name          => GC_CONC_REQUEST_NAME );

  put_log_line( 'Conc Request ID= ' || n_conc_request_id );

  RETURN n_conc_request_id;
END send_individual_invoices;


-- ===========================================================================
-- function that sends invoices or consolidated bills to the customer
--   (returns conc request id)
-- ===========================================================================
FUNCTION send_invoices
( p_cust_account_id        IN   NUMBER,
  p_invoice_trx_list       IN   VARCHAR2,
  p_cons_bill_list         IN   VARCHAR2    DEFAULT NULL,
  p_email_flag             IN   VARCHAR2    DEFAULT 'N',
  p_email_address          IN   VARCHAR2    DEFAULT NULL,
  p_fax_flag               IN   VARCHAR2    DEFAULT 'N',
  p_fax_number             IN   VARCHAR2    DEFAULT NULL,
  p_print_flag             IN   VARCHAR2    DEFAULT 'N',
  p_printer_location       IN   VARCHAR2    DEFAULT NULL )
RETURN NUMBER
IS
  lc_sub_name        CONSTANT VARCHAR2(50)    := 'SEND_INVOICES';

  lc_xdo_template_app        VARCHAR2(50)        DEFAULT NULL;
  lc_xdo_template_name       VARCHAR2(50)        DEFAULT NULL;
BEGIN
  IF p_invoice_trx_list IS NOT NULL THEN
    -- ===========================================================================
    -- get the XML Publisher template from the application profiles
    -- ===========================================================================
    lc_xdo_template_app  := FND_PROFILE.value('XX_AR_INV_COPY_TEMPLATE_APP');
    lc_xdo_template_name := FND_PROFILE.value('XX_AR_INV_COPY_TEMPLATE_NAME');

    -- ===========================================================================
    -- send the invoices
    -- ===========================================================================
    RETURN send_individual_invoices
          ( p_cust_account_id     => p_cust_account_id,
            p_invoice_trx_list    => p_invoice_trx_list,
            p_xdo_template_app    => lc_xdo_template_app,
            p_xdo_template_name   => lc_xdo_template_name,
            p_email_flag          => p_email_flag,
            p_email_address       => p_email_address,
            p_fax_flag            => p_fax_flag,
            p_fax_number          => p_fax_number,
            p_print_flag          => p_print_flag,
            p_printer_location    => p_printer_location );
  ELSIF p_cons_bill_list IS NOT NULL THEN
    RETURN send_consolidated_invoices
          ( p_cust_account_id     => p_cust_account_id,
            p_invoice_trx_list    => p_cons_bill_list,
            p_email_flag          => p_email_flag,
            p_email_address       => p_email_address,
            p_fax_flag            => p_fax_flag,
            p_fax_number          => p_fax_number,
            p_print_flag          => p_print_flag,
            p_printer_location    => p_printer_location );
  ELSE
    RETURN -1;
  END IF;
END send_invoices;

-- +============================================================================================+
-- |  Name: purge_invcopy_requests_data                                                         |
-- |  Description: This procedure delete the Invoice Copy Requests data from XX_AR_INVOICE_COPY_LIST table|
--    Code changes made to this procedure to allow 50 Transactions for Invoice Copy--NAIT-119893-V2.9
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |  p_no_of_days              IN -- number days                                               | 
-- +============================================================================================+

PROCEDURE purge_invcopy_requests_data(
  x_error_buff  OUT  VARCHAR2,
  x_ret_code    OUT  NUMBER,
  p_no_of_days  IN   NUMBER
)
is
BEGIN

	  DELETE FROM XX_AR_INVOICE_COPY_LIST
	  WHERE creation_date < trunc(sysdate) - p_no_of_days;
	  fnd_file.put_line(fnd_file.LOG, 'Number of records deleted from XX_AR_INVOICE_COPY_LIST : '||SQL%ROWCOUNT);

	COMMIT;
EXCEPTION
WHEN OTHERS THEN
	fnd_file.put_line(fnd_file.LOG, 'Purging Table XX_AR_INVOICE_COPY_LIST Failed   '||SQLERRM);
	ROLLBACK;
	x_ret_code := 1;
END purge_invcopy_requests_data;


-- ===========================================================================
-- procedure that inserts Transaction list into table for V
--   it is deferred so that the user does not have to wait on the request.
--
--  Assumes checks have already been made to ensure trx/consbill request valid.
--  The length of the lists should not exceed 150 chars - about 10 invoices.
--Code changes made to this procedure to allow 50 Transactions for Invoice Copy--NAIT-119893
-- ===========================================================================
procedure insert_transaciton_list
( p_cust_account_id        IN   NUMBER,
  p_invoice_trx_list       IN   VARCHAR2 ,   
  p_cons_bill_list         IN   VARCHAR2 ,  
  p_email_flag             IN   VARCHAR2 ,  
  p_email_address          IN   VARCHAR2 ,  
  p_fax_flag               IN   VARCHAR2 ,  
  p_fax_number             IN   VARCHAR2 ,  
  p_print_flag             IN   VARCHAR2 ,  
  p_printer_location       IN   VARCHAR2 ,
  p_group_id               OUT  VARCHAR2
  )
IS


Begin


p_group_id:='INVCPY'||XX_AR_INVOICE_COPY_LIST_S.nextval;

		insert into XX_AR_INVOICE_COPY_LIST( 
			GROUP_ID	               ,
			CUST_ACCOUNT_ID            ,
			INVOICE_TRX_LIST           ,
			CONSOLIDATE_BILL_LIST      ,
			EMAIL_FLAG                 ,
			EMAIL_ADDRESS 			   ,
			FAX_FLAG 				   ,
			FAX_NUMBER 				   ,
			PRINT_FLAG 				   ,
			PRINTER_LOCATION 		   ,
			CREATION_DATE 			   ,
			CREATED_BY  )
		values
			(p_group_id           ,
			p_cust_account_id          ,
			p_invoice_trx_list         ,
			p_cons_bill_list           ,
			p_email_flag               ,
			p_email_address            ,
			p_fax_flag                 ,
			p_fax_number               ,
			p_print_flag               ,
			p_printer_location         ,
			sysdate                    ,
			FND_GLOBAL.user_id		                
			);            
   
Exception when others  then 
  	p_group_id:=null;		 
END  insert_transaciton_list;

-- ===========================================================================
-- function that sends invoices to the customer (returns conc request id)
--   it is deferred so that the user does not have to wait on the request.
--
--  Assumes checks have already been made to ensure trx/consbill request valid.
--  The length of the lists should not exceed 150 chars - about 10 invoices.
--  Code changes made to this procedure to allow 50 Transactions for Invoice Copy--NAIT-119893-V2.9
-- ===========================================================================
FUNCTION send_invoices_deferred
( p_cust_account_id        IN   NUMBER,
  p_invoice_trx_list       IN   VARCHAR2    DEFAULT NULL,
  p_cons_bill_list         IN   VARCHAR2    DEFAULT NULL,
  p_email_flag             IN   VARCHAR2    DEFAULT 'N',
  p_email_address          IN   VARCHAR2    DEFAULT NULL,
  p_fax_flag               IN   VARCHAR2    DEFAULT 'N',
  p_fax_number             IN   VARCHAR2    DEFAULT NULL,
  p_print_flag             IN   VARCHAR2    DEFAULT 'N',
  p_printer_location       IN   VARCHAR2    DEFAULT NULL )
RETURN NUMBER
IS
  lc_sub_name        CONSTANT VARCHAR2(50)    := 'SEND_INVOICES_DEFERRED';

  n_conc_request_id        NUMBER              DEFAULT NULL;

  b_sub_request            BOOLEAN             DEFAULT FALSE;

  v_return_msg             VARCHAR2(4000)      DEFAULT NULL;

  v_phase_code             VARCHAR2(30)        DEFAULT NULL;
  v_phase_desc             VARCHAR2(80)        DEFAULT NULL;
  v_status_code            VARCHAR2(30)        DEFAULT NULL;
  v_status_desc            VARCHAR2(80)        DEFAULT NULL;

  v_request_name           VARCHAR2(200)       DEFAULT NULL;
  l_dup_req                NUMBER;

  b_add_layout             boolean             default false;
  b_set_print_options      boolean             default false;
  lv_group_id varchar2(150);
  lvp_invoice_trx_list  varchar2(4000) default null;
  lvp_cons_bill_list  varchar2(4000) default null;

	
	cursor cr_inv_copy_list
	is
	select request_id From 
	XX_AR_INVOICE_COPY_LIST
	where 1=1
	and created_by=FND_GLOBAL.user_id
	and creation_date>sysdate-1
	and NVL(CUST_ACCOUNT_ID , -1) = NVL(p_cust_account_id, -1)
	and NVL(invoice_trx_list,-1)=NVL(p_invoice_trx_list, -1)
	and NVL(consolidate_bill_list,-1)=NVL(p_cons_bill_list, -1)
	and NVL(EMAIL_FLAG, -1) = NVL(p_email_flag, -1)
    and NVL(EMAIL_ADDRESS, -1) = NVL(p_email_address, -1)
    and NVL(FAX_FLAG, -1) = NVL(p_fax_flag, -1)
    and NVL(FAX_NUMBER , -1) = NVL(p_fax_number, -1)
    and NVL(PRINT_FLAG , -1) = NVL(p_print_flag, -1)
    and NVL(PRINTER_LOCATION, -1) = NVL(p_printer_location, -1) ;
  
BEGIN
      --- Validate that the similar request raised before and still not completed.

    
	  
   /* Commented for NAIT-119893, V2.10*/
  /*select count(1) INTO l_dup_req
  from fnd_concurrent_requests
  where 1=1
    and concurrent_program_id = (select concurrent_program_id from fnd_concurrent_programs_vl where concurrent_program_name = 'XX_AR_SEND_INV_COPY' and application_id = 20043)
    and phase_code <> 'C'
    and requested_by = FND_GLOBAL.user_id
    and NVL(argument1, -1) = NVL(p_cust_account_id, -1)
    and NVL(argument2, -1) = NVL(p_invoice_trx_list, -1)
    and NVL(argument3, -1) = NVL(p_cons_bill_list, -1)
    and NVL(argument4, -1) = NVL(p_email_flag, -1)
    and NVL(argument5, -1) = NVL(p_email_address, -1)
    and NVL(argument6, -1) = NVL(p_fax_flag, -1)
    and NVL(argument7, -1) = NVL(p_fax_number, -1)
    and NVL(argument8, -1) = NVL(p_print_flag, -1)
    and NVL(argument9, -1) = NVL(p_printer_location, -1)
	and actual_start_date > sysdate-1; 
	    IF l_dup_req > 0 THEN
		-- Catch this exception in Java file 'InvoiceCopyAMImpl.java'  -- 2.2
        RAISE_APPLICATION_ERROR( -20300, 'XX_ARI_0020_DUP_REQ_INV_EML' );
    END IF;*/
	

	l_dup_req := 0;
	for inv_list in cr_inv_copy_list loop
	   
	        
	    select count(1) INTO l_dup_req
		from fnd_concurrent_requests
		where 1=1
		and request_id=inv_list.request_id
		and concurrent_program_id = (select concurrent_program_id from fnd_concurrent_programs_vl where concurrent_program_name = 'XX_AR_SEND_INV_COPY' and application_id = 20043)
		and phase_code <> 'C'
		and requested_by = FND_GLOBAL.user_id
		and actual_start_date > sysdate-1; 
		
	    IF l_dup_req > 0 THEN
		-- Catch this exception in Java file 'InvoiceCopyAMImpl.java'  -- 2.2
        RAISE_APPLICATION_ERROR( -20300, 'XX_ARI_0020_DUP_REQ_INV_EML' );
        END IF;
		
		select count(1) INTO l_dup_req
		from fnd_concurrent_requests
		where 1=1
		and concurrent_program_id = (select concurrent_program_id from fnd_concurrent_programs_vl where concurrent_program_name = 'XX_XDO_REQUEST' and application_id = 20043)
		and phase_code <> 'C'
		and requested_by = FND_GLOBAL.user_id
		and parent_request_id =inv_list.request_id;
		
	    IF l_dup_req > 0 THEN
		-- Catch this exception in Java file 'InvoiceCopyAMImpl.java'
        RAISE_APPLICATION_ERROR( -20301, 'XX_ARI_0020_DUP_REQ_INV_EML' );
		END IF;
		
	 end loop;
	   

	
	



	--- Validate that if the child request not yet completed and parent request completes.
	-- In the above case, throw validation error

/*	l_dup_req := 0;
	select count(1) INTO l_dup_req
	from fnd_concurrent_requests
	where 1=1
	  and concurrent_program_id = (select concurrent_program_id from fnd_concurrent_programs_vl where concurrent_program_name = 'XX_XDO_REQUEST' and application_id = 20043)
	  and phase_code <> 'C'
	  and requested_by = FND_GLOBAL.user_id
	  and parent_request_id in (
	  select request_id
	  from fnd_concurrent_requests
	  where 1=1
		and concurrent_program_id = (select concurrent_program_id from fnd_concurrent_programs_vl where concurrent_program_name = 'XX_AR_SEND_INV_COPY' and application_id = 20043)
		and requested_by = FND_GLOBAL.user_id
	    and NVL(argument1, -1) = NVL(p_cust_account_id, -1)
		and NVL(argument2, -1) = NVL(p_invoice_trx_list, -1)
		and NVL(argument3, -1) = NVL(p_cons_bill_list, -1)
		and NVL(argument4, -1) = NVL(p_email_flag, -1)
		and NVL(argument5, -1) = NVL(p_email_address, -1)
		and NVL(argument6, -1) = NVL(p_fax_flag, -1)
		and NVL(argument7, -1) = NVL(p_fax_number, -1)
		and NVL(argument8, -1) = NVL(p_print_flag, -1)
		and NVL(argument9, -1) = NVL(p_printer_location, -1)
		and actual_start_date > sysdate-1
	  );
    IF l_dup_req > 0 THEN
		-- Catch this exception in Java file 'InvoiceCopyAMImpl.java'
        RAISE_APPLICATION_ERROR( -20301, 'XX_ARI_0020_DUP_REQ_INV_EML' );
    END IF; */


  IF (FND_GLOBAL.CONC_REQUEST_ID IS NOT NULL) THEN -- set child flag if this is a child request
    b_sub_request := TRUE;
  END IF;

   /* Added code changes to allow 50 Transactions for Invoice Copy--NAIT-119893*/
  
  insert_transaciton_list(p_cust_account_id    , 
                          p_invoice_trx_list   , 
                          p_cons_bill_list     , 
                          p_email_flag         , 
                          p_email_address      , 
                          p_fax_flag           , 
                          p_fax_number         , 
                          p_print_flag         , 
                          p_printer_location    ,
						  lv_group_id);
		commit;			  
			

   
   if lv_group_id is not null and p_invoice_trx_list is not null 
   then    
		lvp_invoice_trx_list:=lv_group_id;
   end if;
   
   if lv_group_id is not null and p_cons_bill_list is not null 
   then    
		lvp_cons_bill_list:=lv_group_id;
   end if;
   
 /* Added code changes to allow 50 Transactions for Invoice Copy--NAIT-119893*/  
  
  
  -- ===========================================================================
  -- submit the request (OD: AR Send Invoice Copy)
  -- ===========================================================================
  n_conc_request_id :=
    FND_REQUEST.submit_request
    ( application    => 'XXFIN',                 -- application short name
      program        => 'XX_AR_SEND_INV_COPY',   -- concurrent program name
      description    => GC_CONC_REQ_DEF_NAME,    -- additional request description
      start_time     => NULL,                    -- request submit time
      sub_request    => b_sub_request,           -- is this a sub-request?
      argument1      => p_cust_account_id,       -- Customer Account Id
      argument2      => lvp_invoice_trx_list , ---p_invoice_trx_list,      -- Invoice Trx List--Modified for V2.10 
      argument3      => lvp_cons_bill_list, --p_cons_bill_list,        -- Consolidated Bill List--Modified for V2.10 
      argument4      => p_email_flag,            -- Email Flag (Y/N)
      argument5      => p_email_address,         -- Email Address
      argument6      => p_fax_flag,              -- Fax Flag (Y/N)
      argument7      => p_fax_number,            -- Fax Number
      argument8      => p_print_flag,            -- Print Flag (Y/N)
      argument9      => p_printer_location );    -- Printer Queue - Linux Location
  IF (n_conc_request_id > 0) THEN -- request was successful

    IF (b_sub_request) THEN -- if a child request, then update it for concurrent mgr to process
      UPDATE fnd_concurrent_requests
         SET phase_code = 'P',
             status_code = 'I'
       WHERE request_id = n_conc_request_id;
    END IF;
	
	Update XX_AR_INVOICE_COPY_LIST set request_id=n_conc_request_id
	where group_id=lv_group_id;

    COMMIT; -- must commit work so that the concurrent manager polls the request

    put_log_line( ' Concurrent Request ID: ' || n_conc_request_id || '.' );

  ELSE -- errors have occured for request
    FND_MESSAGE.raise_error;
  END IF;

  RETURN n_conc_request_id;
END send_invoices_deferred;



-- ===========================================================================
-- function that sends invoices to the customer - submitted through a
--   concurrent program
-- ===========================================================================
PROCEDURE send_invoices_cp
( x_error_buffer           OUT  VARCHAR2,
  x_return_code            OUT  NUMBER,
  p_cust_account_id        IN   NUMBER,
  p_invoice_trx_list       IN   VARCHAR2    DEFAULT NULL,
  p_cons_bill_list         IN   VARCHAR2    DEFAULT NULL,
  p_email_flag             IN   VARCHAR2    DEFAULT 'N',
  p_email_address          IN   VARCHAR2    DEFAULT NULL,
  p_fax_flag               IN   VARCHAR2    DEFAULT 'N',
  p_fax_number             IN   VARCHAR2    DEFAULT NULL,
  p_print_flag             IN   VARCHAR2    DEFAULT 'N',
  p_printer_location       IN   VARCHAR2    DEFAULT NULL )
IS
  lc_sub_name        CONSTANT VARCHAR2(50) := 'SEND_INVOICES_CP';
  lc_ineligible      VARCHAR2(1000) := NULL;

  x_child_conc_request_id       NUMBER      DEFAULT NULL;
BEGIN

  IF p_cons_bill_list IS NOT NULL THEN
    lc_ineligible := get_not_yet_delivered_conbills(p_cust_account_id, p_cons_bill_list);
    IF lc_ineligible IS NOT NULL THEN
      x_error_buffer := 'Consolidated bill(s) '      || lc_ineligible || ' have not been delivered... reprint request aborted.';
      x_return_code  := 2;
      RETURN;
    END IF;
  END IF;

  IF p_invoice_trx_list IS NOT NULL THEN
    lc_ineligible := get_unreprintable_trxs(p_cust_account_id, p_invoice_trx_list);
    IF lc_ineligible IS NOT NULL THEN
      x_error_buffer := 'Individual transaction(s) ' || lc_ineligible || ' are not reprintable... reprint request aborted.';
      x_return_code  := 2;
      RETURN;
    END IF;
  END IF;

  -- ===========================================================================
  -- send the invoices
  -- ===========================================================================
  x_child_conc_request_id :=
    send_invoices
    ( p_cust_account_id     => p_cust_account_id,
      p_invoice_trx_list    => p_invoice_trx_list,
      p_cons_bill_list      => p_cons_bill_list,
      p_email_flag          => p_email_flag,
      p_email_address       => p_email_address,
      p_fax_flag            => p_fax_flag,
      p_fax_number          => p_fax_number,
      p_print_flag          => p_print_flag,
      p_printer_location    => p_printer_location );

  put_log_line( 'Conc Request ID= ' || x_child_conc_request_id );

EXCEPTION
  WHEN OTHERS THEN
    x_return_code := 2;
    x_error_buffer := SQLERRM;
    XX_COM_ERROR_LOG_PUB.log_error
    ( p_program_type            => 'CONCURRENT PROGRAM',
      p_program_name            => 'XX_AR_SEND_INV_COPY',
      p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID,
      p_module_name             => 'AR',
      p_error_location          => 'OD Customer Invoice Copy',
      p_error_message_count     => 1,
      p_error_message_code      => 'E',
      p_error_message           => SQLERRM,
      p_error_message_severity  => 'Major',
      p_notify_flag             => 'N',
      p_object_type             => lc_sub_name );
    RAISE;
END send_invoices_cp;



-- +============================================================================================+
-- |  Name: run_prog_to_get_cons_bill                                                           |
-- |  Description: Runs a concurrent program to generate the consolidated bill PDF as output    |
-- |                 waits for it to finish, and returns a URL to display it internally.        |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_cons_inv_id          IN --  Consolidated Invoice Id                                   |
-- |                                                                                            |
-- |    x_url                  OUT -- URL to display PDF                                        |
-- |    x_request_id           OUT -- request_id of concurrent program called to get invoice    |
-- +============================================================================================+
PROCEDURE run_prog_to_get_cons_bill
( p_cons_inv_id            IN   NUMBER,
  x_url                    OUT  VARCHAR2,
  x_request_id             OUT  NUMBER)
IS
  n_cust_account_id        HZ_CUST_ACCOUNTS.cust_account_id%TYPE;
  n_mbs_document_id        XX_CDH_CUST_ACCT_EXT_B.n_ext_attr1%TYPE;
  n_issue_Date             AR_CONS_INV.issue_date%type;  -- Added for defect 23007
  n_conc_request_id        NUMBER         := NULL;
  v_return_msg             VARCHAR2(4000) := NULL;
  v_phase_code             VARCHAR2(30)   := NULL;
  v_phase_desc             VARCHAR2(80)   := NULL;
  v_status_code            VARCHAR2(30)   := NULL;
  v_status_desc            VARCHAR2(80)   := NULL;
  v_tab                    FND_CONCURRENT.REQUESTS_TAB_TYPE;
  ln_request_wait_time     NUMBER;
  
  l_dup_req_id			   NUMBER;
  
BEGIN

  x_url := NULL;
  x_request_id := -1;

   SELECT customer_id,
	   issue_Date -- Added for 23007
    INTO n_cust_account_id,
	     n_issue_Date  -- Added for 23007
    FROM AR_CONS_INV
   WHERE 1 =1 
     -- AND cons_inv_id=p_cons_inv_id -- Commented for Bill Complete as per Version 2.7
	 AND cons_billing_number = p_cons_inv_id; -- Added for Bill Complete as per Version 2.7

  BEGIN
    SELECT n_ext_attr1
      INTO n_mbs_document_id
      FROM XX_CDH_CUST_ACCT_EXT_B
     WHERE cust_account_id=n_cust_account_id
       AND attr_group_id=166
       AND c_ext_attr2='Y'
       AND ( n_issue_Date BETWEEN D_EXT_ATTR1 AND NVL(D_EXT_ATTR2,SYSDATE+1)) -- Added for 23007
       AND ROWNUM=1;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    n_mbs_document_id := GN_DEFAULT_DOCUMENT_ID;
  END;


  -- Begin of Duplicate Request Validation
  
  l_dup_req_id := -1;
  
  BEGIN

  select request_id INTO l_dup_req_id
  from fnd_concurrent_requests 
  where 1=1
    and concurrent_program_id = (select concurrent_program_id from fnd_concurrent_programs_vl where concurrent_program_name = 'XXARRPSUMMBILL' and application_id = 20043)
    and phase_code <> 'C'
    and requested_by = FND_GLOBAL.user_id 
    and argument1  = 'N'
	and argument3  = n_cust_account_id
    and argument9  = p_cons_inv_id
	and argument10 = p_cons_inv_id
    and argument14 = n_mbs_document_id
    and argument15 = 'N'
	and argument19 = 'N'
    and argument20 = 1
	and request_date > sysdate-1
	and rownum <= 1;
   
   EXCEPTION
	WHEN NO_DATA_FOUND THEN    
		l_dup_req_id := -2; 
	WHEN OTHERS THEN    
		l_dup_req_id := -3;  
   END;
   
    IF l_dup_req_id > 0 THEN
		x_request_id := l_dup_req_id;
		GC_OD_IS_DUPLICATE_CONC_REQ := 'Y';
		return;		
    END IF;  
  
  -- End of Duplicate Request Validation  


  n_conc_request_id :=
    FND_REQUEST.submit_request
    ( application    => 'XXFIN',                 -- application short name
      program        => 'XXARRPSUMMBILL',        -- concurrent program name
      description    => GC_SUB_REQUEST_NAME,     -- additional request description
      start_time     => NULL,                    -- request submit time
      sub_request    => FALSE,                   -- is this a sub-request?
      argument1      => 'N',                     -- Infocopy Reprint
      argument2      => NULL,                    -- Search By
      argument3      => n_cust_account_id,       -- Customer Number
      argument4      => NULL,                    -- Virtual Consolidated Bill
      argument5      => NULL,                    -- Bill Date From
      argument6      => NULL,                    -- Bill Date To
      argument7      => NULL,                    -- Dummy
      argument8      => NULL,                    -- Virtual Cons Bill Dummy
      argument9      => p_cons_inv_id,           -- From Cons Bill Number
      argument10     => p_cons_inv_id,           -- To Cons Bill Number
      argument11     => NULL,                    -- Virtual Cons Bill Number
      argument12     => NULL,                    -- Multiple Cons Bills
      argument13     => NULL,                    -- Customer Document Id
      argument14     => n_mbs_document_id,       -- MBS Document ID
      argument15     => 'N',                     -- Override MBS Doc Id
      argument16     => NULL,                    -- Email Options
      argument17     => NULL,                    -- Dummy
      argument18     => NULL,                    -- Enter Email Address
      argument19     => 'N',                     -- Special Handling Flag
      argument20     => 1,                       -- MBS Extension Id (only used for special handling)
      argument21     => NULL,                    -- Request Id
      argument22     => NULL,                    -- Origin
      argument23     => NULL,                    -- Doc Detail CP
      argument24     => NULL,                    -- Doc Detail
      argument25     => NULL,                    -- As of Date
      argument26     => NULL );                  -- Optional Printer


  IF (n_conc_request_id > 0) THEN
    COMMIT; -- must commit work so that the concurrent manager polls the request
	
	IF GC_OD_GET_INV_WAIT_FLAG = 'N' THEN
		x_request_id := n_conc_request_id;
		return;
	END IF;	
  ELSE
    PUT_ERR_LINE('Failed to launch concurrent program XXARRPSUMMBILL-- user:' || fnd_global.user_id || ' resp: ' || fnd_global.resp_id || ' appl: ' || fnd_global.resp_appl_id, n_cust_account_id);
    FND_MESSAGE.raise_error;
  END IF;

  ln_request_wait_time := NVL(FND_PROFILE.VALUE('OD_EBILL_PDF_COPY_WAIT_REQUEST_TIME'),4);
  
  IF NOT FND_CONCURRENT.wait_for_request
    ( request_id    => n_conc_request_id,
      interval      => 5,                      -- check every 5 secs
      --max_wait      => 60*5,                   -- check for max of 5 minutes
	  max_wait      => 60*ln_request_wait_time,   -- Checking the wait time based on profile value
      phase         => v_phase_desc,
      status        => v_status_desc,
      dev_phase     => v_phase_code,
      dev_status    => v_status_code,
      message       => v_return_msg
      )
  THEN
    RAISE_APPLICATION_ERROR( -20200, v_return_msg );
  END IF;

  IF (v_status_code <> 'NORMAL') THEN
    RAISE_APPLICATION_ERROR( -20201, 'Concurrent Request completed, but had errors or warnings.' );
  ELSE

    v_tab := FND_CONCURRENT.get_sub_requests(n_conc_request_id); -- Need output of child program

    IF NOT v_tab.EXISTS(1) THEN
      RAISE_APPLICATION_ERROR( -20201, 'Concurrent Request completed, but no child spawned.' );
    ELSE
      n_conc_request_id := v_tab(1).request_id;

      IF NOT FND_CONCURRENT.wait_for_request
      ( request_id    => n_conc_request_id,
        interval      => 5,                      -- check every 5 secs
        --max_wait      => 60*5,                   -- check for max of 5 minutes
		max_wait      => 60*ln_request_wait_time,   -- Checking the wait time based on profile value
        phase         => v_phase_desc,
        status        => v_status_desc,
        dev_phase     => v_phase_code,
        dev_status    => v_status_code,
        message       => v_return_msg
      )
      THEN
        RAISE_APPLICATION_ERROR( -20200, v_return_msg );
      END IF;

      IF (v_status_code <> 'NORMAL') THEN
        RAISE_APPLICATION_ERROR( -20201, 'Concurrent Child Request completed, but had errors or warnings.' );
      END IF;
    END IF;

    x_url := FND_WEBFILE.GET_URL( FND_WEBFILE.REQUEST_OUT, n_conc_request_id, null, null, 10, null, null, null, null );

    IF (NOT fnd_profile.defined('APPS_CGI_AGENT')) THEN -- external iRec server not accessible inside firewall; need to target internal server
      SELECT substr(V.profile_option_value, 1,  instr(V.profile_option_value, '/', 1, 3)-1) || substr(x_url, instr(x_url, '/', 1, 3))
      INTO x_url
      FROM FND_PROFILE_OPTIONS O JOIN FND_PROFILE_OPTION_VALUES V
        ON O.application_id=V.application_id
       AND O.profile_option_id=V.profile_option_id
       AND O.profile_option_name='APPS_WEB_AGENT'
      WHERE level_id=10001 AND level_value=0 AND rownum=1;
    END IF;

    x_request_id := n_conc_request_id;
  END IF;

END run_prog_to_get_cons_bill;







-- +============================================================================================+
-- |  Name: run_prog_to_get_invoice                                                             |
-- |  Description: Runs a concurrent program to generate an invoice PDF as output               |
-- |                 waits for it to finish, and returns a URL to display it internally.        |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_customer_trx_id      IN --  Customer transaction id                                   |
-- |                                                                                            |
-- |    x_url                  OUT -- URL to display PDF                                        |
-- |    x_request_id           OUT -- request_id of concurrent program called to get invoice    |
-- +============================================================================================+
PROCEDURE run_prog_to_get_invoice
( p_customer_trx_id        IN   VARCHAR2,
  x_url                    OUT  VARCHAR2,
  x_request_id             OUT  NUMBER)
IS
  n_mbs_document_id        NUMBER         := GN_DEFAULT_DOCUMENT_ID;
  n_cust_account_id        HZ_CUST_ACCOUNTS.CUST_ACCOUNT_ID%TYPE;
  s_invoice_trx            VARCHAR2(20);
  v_user_language          VARCHAR2(30)   := NULL;
  v_user_territory         VARCHAR2(30)   := NULL;
  n_conc_request_id        NUMBER         := NULL;
  b_success                BOOLEAN        := NULL;
  v_return_msg             VARCHAR2(4000) := NULL;
  v_phase_code             VARCHAR2(30)   := NULL;
  v_phase_desc             VARCHAR2(80)   := NULL;
  v_status_code            VARCHAR2(30)   := NULL;
  v_status_desc            VARCHAR2(80)   := NULL;
  ln_request_wait_time     NUMBER;
  
  l_dup_req_id			   NUMBER;
BEGIN

  x_url := NULL;
  x_request_id := -1;

  SELECT trx.bill_to_customer_id,trx.trx_number
    INTO n_cust_account_id, s_invoice_trx
    FROM RA_CUSTOMER_TRX_ALL trx
   WHERE trx.customer_trx_id=p_customer_trx_id;

  IF get_unreprintable_trxs(n_cust_account_id, s_invoice_trx) IS NOT NULL THEN
    RAISE_APPLICATION_ERROR( -20200, 'Individual transaction(s) are not reprintable... reprint request aborted' ); -- This error message will never be seen;  Exception will result in redirect to "contact us" page
  END IF;

  BEGIN
    SELECT billdocs_doc_id
      INTO n_mbs_document_id
      FROM XX_CDH_A_EXT_BILLDOCS_V
     WHERE billdocs_doc_type = 'Invoice'
       AND billdocs_delivery_meth = 'PRINT'
       AND cust_account_id = n_cust_account_id
       AND ROWNUM=1;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    n_mbs_document_id := GN_DEFAULT_DOCUMENT_ID;
  END;
  
  -- Begin of Duplicate Request Validation
  
  l_dup_req_id := -1;
  
  BEGIN
  
  select request_id INTO l_dup_req_id
  from fnd_concurrent_requests 
  where 1=1
    and concurrent_program_id = (select concurrent_program_id from fnd_concurrent_programs_vl where concurrent_program_name = 'XXARINVIND' and application_id = 20043)
    and phase_code <> 'C'
    and requested_by = FND_GLOBAL.user_id 
    and argument1 = n_cust_account_id
    and argument5 = 'N'
    and argument6 = n_mbs_document_id
    and argument8 = s_invoice_trx
    and argument9 = 'HED'
	and request_date > sysdate-1
	and rownum <= 1;
   
   EXCEPTION
	WHEN NO_DATA_FOUND THEN    
		l_dup_req_id := -2; 
	WHEN OTHERS THEN
        l_dup_req_id := -3;  
   END;
   
    IF l_dup_req_id > 0 THEN
		x_request_id := l_dup_req_id;
		GC_OD_IS_DUPLICATE_CONC_REQ := 'Y';
		return;		
    END IF;  
  
  -- End of Duplicate Request Validation
  
  

  SELECT LOWER(iso_language) user_language,
         iso_territory user_territory
    INTO v_user_language,
         v_user_territory
    FROM FND_LANGUAGES_VL
   WHERE language_code = NVL(FND_GLOBAL.CURRENT_LANGUAGE,'US');

  b_success :=
    FND_REQUEST.add_layout
    ( template_appl_name    => FND_PROFILE.value('XX_AR_INV_COPY_TEMPLATE_APP'),
      template_code         => FND_PROFILE.value('XX_AR_INV_COPY_TEMPLATE_NAME'),
      template_language     => v_user_language,
      template_territory    => v_user_territory,
      output_format         => GC_XDO_TEMPLATE_FORMAT );

  n_conc_request_id :=
    FND_REQUEST.submit_request
    ( application    => 'XXFIN',                 -- application short name
      program        => 'XXARINVIND',            -- concurrent program name
      description    => GC_SUB_REQUEST_NAME,     -- additional request description
      start_time     => NULL,                    -- request submit time
      sub_request    => FALSE,                   -- is this a sub-request?
      argument1      => n_cust_account_id,       -- Customer Account number
      argument2      => NULL,                    -- Transaction Number
      argument3      => NULL,                    -- Transaction Date Low
      argument4      => NULL,                    -- Transaction Date High
      argument5      => 'N',                     -- Open Invoices Only
      argument6      => n_mbs_document_id,       -- MBS Document ID
      argument7      => NULL,                    -- Fax Number
      argument8      => s_invoice_trx,           -- Multiple Trx List
      argument9      => 'HED' );                 -- Source (default "Hedberg")

  IF (n_conc_request_id > 0) THEN
    COMMIT; -- must commit work so that the concurrent manager polls the request
	
	IF GC_OD_GET_INV_WAIT_FLAG = 'N' THEN
		x_request_id := n_conc_request_id;
		return;
	END IF;
  ELSE
    PUT_ERR_LINE('Failed to launch concurrent program XXARINVIND-- user:' || fnd_global.user_id || ' resp: ' || fnd_global.resp_id || ' appl: ' || fnd_global.resp_appl_id, n_cust_account_id);
    FND_MESSAGE.raise_error;
  END IF;
  
  ln_request_wait_time := NVL(FND_PROFILE.VALUE('OD_EBILL_PDF_COPY_WAIT_REQUEST_TIME'),4);

  IF NOT FND_CONCURRENT.wait_for_request
    ( request_id    => n_conc_request_id,
      interval      => 5,                      -- check every 5 secs
      --max_wait      => 60*5,                   -- check for max of 5 minutes
	  max_wait      => 60*ln_request_wait_time,   -- Checking the wait time based on profile value
      phase         => v_phase_desc,
      status        => v_status_desc,
      dev_phase     => v_phase_code,
      dev_status    => v_status_code,
      message       => v_return_msg
      )
  THEN
    RAISE_APPLICATION_ERROR( -20200, v_return_msg );
  END IF;

  IF (v_status_code <> 'NORMAL') THEN
    RAISE_APPLICATION_ERROR( -20201, 'Concurrent Request completed, but had errors or warnings.' );
  ELSE
    x_url := FND_WEBFILE.GET_URL( FND_WEBFILE.REQUEST_OUT, n_conc_request_id, null, null, 10, null, null, null, null );

    IF (NOT fnd_profile.defined('APPS_CGI_AGENT')) THEN -- external iRec server not accessible inside firewall; need to target internal server
      SELECT substr(V.profile_option_value, 1,  instr(V.profile_option_value, '/', 1, 3)-1) || substr(x_url, instr(x_url, '/', 1, 3))
      INTO x_url
      FROM FND_PROFILE_OPTIONS O JOIN FND_PROFILE_OPTION_VALUES V
        ON O.application_id=V.application_id
       AND O.profile_option_id=V.profile_option_id
       AND O.profile_option_name='APPS_WEB_AGENT'
      WHERE level_id=10001 AND level_value=0 AND rownum=1;
    END IF;

    x_request_id := n_conc_request_id;
  END IF;

END run_prog_to_get_invoice;


PROCEDURE get_invoice
( p_customer_trx_id      IN   VARCHAR2,
  x_blob                 OUT  NOCOPY BLOB )
IS
  sURL                   VARCHAR2(2000);
  s_invoice_trx          VARCHAR2(20);
  l_raw                  RAW(32767);
  l_http_request         UTL_HTTP.req;
  l_http_response        UTL_HTTP.resp;
  n_request_id           NUMBER;
  l_wallet_location     VARCHAR2(256)   := NULL;
  l_password            VARCHAR2(256)   := NULL;
BEGIN
--  fnd_global.apps_initialize(10443,51236,222);
--  PUT_ERR_LINE(fnd_global.user_id,p_customer_trx_id);

  SELECT document_data INTO x_blob FROM XX_XDO_REQUEST_DOCS_WEB WHERE customer_trx_id=p_customer_trx_id;

  EXCEPTION WHEN NO_DATA_FOUND THEN BEGIN

    IF p_customer_trx_id>0 THEN -- Individual Transaction
      run_prog_to_get_invoice  ( p_customer_trx_id, sURL, n_request_id);
    ELSE                        -- Consolidated Bill
      run_prog_to_get_cons_bill(-p_customer_trx_id, sURL, n_request_id);
    END IF;
	
	IF n_request_id > 0 AND sURL is NULL THEN
		GN_OD_GET_INV_CONC_REQ_ID := n_request_id;
		return;
	END IF;
	

    IF n_request_id>0 AND length(sURL)>0 THEN BEGIN
      DBMS_LOB.createtemporary(x_blob, FALSE);

      -- Changes for SSL/TSL Upgrade Start
        BEGIN
          SELECT 
             TARGET_VALUE1
            ,TARGET_VALUE2
            into
            l_wallet_location
           ,l_password
          FROM XX_FIN_TRANSLATEVALUES     VAL,
               XX_FIN_TRANSLATEDEFINITION DEF
          WHERE 1=1
          and   DEF.TRANSLATE_ID = VAL.TRANSLATE_ID
          and   DEF.TRANSLATION_NAME='XX_FIN_IREC_TOKEN_PARAMS'
          and   VAL.SOURCE_VALUE1 = 'WALLET_LOCATION'     
          and   VAL.ENABLED_FLAG = 'Y'
          and   SYSDATE between VAL.START_DATE_ACTIVE and nvl(VAL.END_DATE_ACTIVE, SYSDATE+1); 
        EXCEPTION WHEN OTHERS THEN
          fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'Wallet Location Not Found' );
          l_wallet_location := NULL;
          l_password := NULL;
        END;
        IF l_wallet_location IS NOT NULL THEN
          UTL_HTTP.SET_WALLET(l_wallet_location,l_password);
        END IF;
        -- Changes for SSL/TSL Upgrade End
      l_http_request  := UTL_HTTP.begin_request(sURL);
--      UTL_HTTP.set_transfer_timeout(300); -- this is in seconds.  default is 60
      l_http_response := UTL_HTTP.get_response(l_http_request);

      BEGIN
        LOOP
         UTL_HTTP.read_raw(l_http_response, l_raw, 32767);
         DBMS_LOB.writeappend (x_blob, UTL_RAW.length(l_raw), l_raw);
        END LOOP;
      EXCEPTION
        WHEN UTL_HTTP.end_of_body THEN
          UTL_HTTP.end_response(l_http_response);
      END;

      IF UTL_RAW.cast_to_varchar2(dbms_lob.substr(x_blob,5,1))<>'%PDF-' THEN -- verify PDF doc prefix
          DBMS_LOB.freetemporary(x_blob);
          DBMS_LOB.createtemporary(x_blob, FALSE); -- return empty blob because not valid pdf.
      ELSE
        BEGIN
          UPDATE XX_XDO_REQUEST_DOCS_WEB SET request_id=n_request_id, document_data=x_blob, creation_date=sysdate WHERE customer_trx_id=p_customer_trx_id;
          IF SQL%NOTFOUND THEN
            INSERT INTO XX_XDO_REQUEST_DOCS_WEB (customer_trx_id,request_id,document_data,creation_date) VALUES (p_customer_trx_id,n_request_id,x_blob,sysdate);
          END IF;
          COMMIT;
		  --Commented on 21-Nov-2016 defect#39482
          --DELETE FROM XX_XDO_REQUEST_DOCS_WEB WHERE creation_date<SYSDATE-7; -- purge;
          --COMMIT;
         EXCEPTION WHEN OTHERS THEN
          NULL; -- cache and purge are not critical so do not fail
        END;
      END IF;

      EXCEPTION WHEN OTHERS THEN
        PUT_ERR_LINE('Other exception in get_invoice: ' || SQLERRM,p_customer_trx_id,fnd_global.user_id,sURL);
        UTL_HTTP.end_response(l_http_response);
        DBMS_LOB.freetemporary(x_blob);
        RAISE;
      END;
    END IF;
  END;
END get_invoice;


-- +============================================================================================+
-- |  Name: get_invoice()  with 3 parameters CUSTOM                                             |
-- |  Description: Generates invoice and returns request_id without waiting for request to complete|
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_customer_trx_id      IN --  Customer transaction id                                   |
-- |                                                                                            |
-- |    x_url                  OUT -- URL to display PDF                                        |
-- |    x_request_id           OUT -- request_id of concurrent program called to get invoice    |
-- |    x_is_duplicate_creq    OUT -- Flag to return "Y" if  we try to submit duplicate request |
-- +============================================================================================+
PROCEDURE get_invoice
( p_customer_trx_id      IN   VARCHAR2,
  x_blob                 OUT  NOCOPY BLOB,
  x_request_id			 OUT  NUMBER,
  x_is_duplicate_creq    OUT  VARCHAR2  )
IS
BEGIN

	GC_OD_GET_INV_WAIT_FLAG := 'N';
	GN_OD_GET_INV_CONC_REQ_ID := NULL;
	GC_OD_IS_DUPLICATE_CONC_REQ := 'N';
	get_invoice( p_customer_trx_id => p_customer_trx_id,
					x_blob => x_blob);
	IF (GN_OD_GET_INV_CONC_REQ_ID IS NOT NULL and GN_OD_GET_INV_CONC_REQ_ID > -1 ) THEN
		x_request_id := GN_OD_GET_INV_CONC_REQ_ID;
		x_is_duplicate_creq := GC_OD_IS_DUPLICATE_CONC_REQ;
	END IF;
	
	GC_OD_GET_INV_WAIT_FLAG := NULL;
	GN_OD_GET_INV_CONC_REQ_ID := NULL;
	GC_OD_IS_DUPLICATE_CONC_REQ  := NULL;

END;


  -- COMMENT THIS BLOCK BEFORE DEPLOYING --
  -- in dev02, the apps context is not being set for some reason (all fnd_global values are -1)
  -- but does not seem to be an issue in the other EBS environments;  We could use a service account if necessary (will see values in xx_com_error_log)
--BEGIN
--   IF fnd_global.user_id<0 OR fnd_global.resp_id<0 OR fnd_global.resp_appl_id<0 THEN
--    FND_GLOBAL.apps_initialize(
--      user_id => 10443
--     ,resp_id => 50682
--     ,resp_appl_id => 222
--    );
--  END IF;

-- +============================================================================================+
-- |  Name: purge_xdo_requests_data                                                             |
-- |  Description: This program is to purge the xdo requests tables data                        |
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_no_of_days              IN -- number days                                             |
-- +============================================================================================+		
PROCEDURE purge_xdo_requests_data(
	p_error_buff  OUT  VARCHAR2,
	p_ret_code    OUT  NUMBER,
	p_no_of_days  IN   NUMBER
	)
IS
    CURSOR c_xdo_requests 
	IS
	SELECT XDO_REQUEST_ID
	FROM XX_XDO_REQUESTS
	WHERE creation_date < trunc(sysdate) - p_no_of_days;
	
	ln_xdo_request_docs_count   NUMBER := 0;
	ln_xdo_request_dests_count 	NUMBER := 0;
	ln_xdo_requests_count       NUMBER := 0;
BEGIN
	fnd_file.put_line(fnd_file.LOG,
					  'Deleting the records from XDO tables');
	FOR i IN c_xdo_requests
	LOOP
	    BEGIN
			DELETE FROM XX_XDO_REQUEST_DESTS
			WHERE xdo_request_id = i.xdo_request_id;

			ln_xdo_request_dests_count := ln_xdo_request_dests_count + SQL%ROWCOUNT;

			DELETE FROM XX_XDO_REQUEST_DOCS
			WHERE xdo_request_id = i.xdo_request_id;
		
			ln_xdo_request_docs_count := ln_xdo_request_docs_count + SQL%ROWCOUNT;
		
			DELETE FROM XX_XDO_REQUESTS
			WHERE xdo_request_id = i.xdo_request_id;
		
			ln_xdo_requests_count := ln_xdo_requests_count + SQL%ROWCOUNT;
		EXCEPTION WHEN OTHERS THEN
			fnd_file.put_line(fnd_file.LOG, 'Exception raised when deleting the xdo request id : '||i.xdo_request_id||' Error : '||SQLERRM);
		END;
	END LOOP;

	COMMIT;
	
	fnd_file.put_line(fnd_file.LOG, 'Number of records deleted from XX_XDO_REQUEST_DESTS : '||ln_xdo_request_dests_count);
	fnd_file.put_line(fnd_file.LOG, 'Number of records deleted from XX_XDO_REQUEST_DOCS : '||ln_xdo_request_docs_count);
	fnd_file.put_line(fnd_file.LOG, 'Number of records deleted from XX_XDO_REQUESTS : '||ln_xdo_requests_count);
	
	fnd_file.put_line(fnd_file.LOG,
					  'Deleting the records from XX_XDO_REQUEST_DOCS_WEB');
	BEGIN
	  DELETE FROM XX_XDO_REQUEST_DOCS_WEB
	  WHERE creation_date < trunc(sysdate) - p_no_of_days;
	
	  fnd_file.put_line(fnd_file.LOG, 'Number of records deleted from XX_XDO_REQUEST_DOCS_WEB : '||SQL%ROWCOUNT);
	END;

	COMMIT;
EXCEPTION
WHEN OTHERS THEN
	fnd_file.put_line(fnd_file.LOG, 'Purging History Table Failed   '||SQLERRM);
	ROLLBACK;
	p_ret_code := 1;
END purge_xdo_requests_data;

-- +============================================================================================+
-- |  Name: save_pdf_invoice_copy                                                               |
-- |  Description: This procedure saves the output of given request_id, of PDF Copy, into a table|
-- |                                                                                            |
-- |  Parameters:                                                                               |
-- |    p_customer_trx_id         IN -- Transaction Id of PDF Copy Invoice or Consolidated Invoice|
-- |    p_request_id              IN -- RequestId of Individual Invoice and Parent Request of Consolidated Invoice |
-- +============================================================================================+

PROCEDURE save_pdf_invoice_copy(
  x_error_buff  OUT  VARCHAR2,
  x_ret_code    OUT  NUMBER,
	p_customer_trx_id      IN   VARCHAR2,
	p_request_id           IN   NUMBER
) 
IS
	l_blob      BLOB;
	l_status_code VARCHAR2(1);
  l_phase_code VARCHAR2(1);
	l_url 		VARCHAR2(500);
	l_is_already_exist VARCHAR2(1) := 'Y';
	l_request_id NUMBER;
  
  v_tab FND_CONCURRENT.REQUESTS_TAB_TYPE;

  l_raw                  RAW(32767);
  l_http_request         UTL_HTTP.req;
  l_http_response        UTL_HTTP.resp;
  l_wallet_location     VARCHAR2(256)   := NULL;
  l_password            VARCHAR2(256)   := NULL;  
  


BEGIN

  x_ret_code := 1;
 /** SELECT document_data INTO l_blob FROM XX_XDO_REQUEST_DOCS_WEB WHERE customer_trx_id=p_customer_trx_id;
  x_ret_code := 0;
  EXCEPTION WHEN NO_DATA_FOUND THEN BEGIN
	l_is_already_exist := 'N';
  END;
**/l_is_already_exist := 'N';
  IF l_is_already_exist = 'N' THEN
  
	  IF p_customer_trx_id > 0 THEN
		l_request_id := p_request_id;
	  ELSE  -- Consolidated Invoice
		  v_tab := FND_CONCURRENT.get_sub_requests(p_request_id); -- Need output of child program

		  IF NOT v_tab.EXISTS(1) THEN
        x_error_buff := 'Child Request doesnt exist for Consolidated Invoice Parent Request '||p_request_id||' for trx id '||p_customer_trx_id;
			return;
		  ELSE
			l_request_id := v_tab(1).request_id;
		  END IF;
	  END IF;
  
	  SELECT phase_code, status_code INTO l_phase_code, l_status_code
	  FROM fnd_concurrent_requests
	  WHERE request_id = l_request_id; 
	  
	  l_url := null;
	  --IF (l_status_code <> 'NORMAL') THEN
	  IF (l_phase_code <> 'C' or l_status_code <> 'C') THEN
      -- RAISE_APPLICATION_ERROR( -20201, 'Concurrent Request completed, but had errors or warnings.' );
      x_error_buff := 'Child Request '||p_request_id||' does not completed successfully for trx id '||p_customer_trx_id;
      return;

	  ELSE
      l_url := FND_WEBFILE.GET_URL( FND_WEBFILE.REQUEST_OUT, l_request_id, null, null, 10, null, null, null, null );
  
      IF (NOT fnd_profile.defined('APPS_CGI_AGENT')) THEN -- external iRec server not accessible inside firewall; need to target internal server
        SELECT substr(V.profile_option_value, 1,  instr(V.profile_option_value, '/', 1, 3)-1) || substr(l_url, instr(l_url, '/', 1, 3))
        INTO l_url
        FROM FND_PROFILE_OPTIONS O JOIN FND_PROFILE_OPTION_VALUES V
        ON O.application_id=V.application_id
         AND O.profile_option_id=V.profile_option_id
         AND O.profile_option_name='APPS_WEB_AGENT'
        WHERE level_id=10001 AND level_value=0 AND rownum=1;
      END IF;
  
	  END IF;

    BEGIN
		  DBMS_LOB.createtemporary(l_blob, FALSE);

		  -- Changes for SSL/TSL Upgrade Start
			BEGIN
			  SELECT 
				 TARGET_VALUE1
				,TARGET_VALUE2
				into
				l_wallet_location
			   ,l_password
			  FROM XX_FIN_TRANSLATEVALUES     VAL,
				   XX_FIN_TRANSLATEDEFINITION DEF
			  WHERE 1=1
			  and   DEF.TRANSLATE_ID = VAL.TRANSLATE_ID
			  and   DEF.TRANSLATION_NAME='XX_FIN_IREC_TOKEN_PARAMS'
			  and   VAL.SOURCE_VALUE1 = 'WALLET_LOCATION'     
			  and   VAL.ENABLED_FLAG = 'Y'
			  and   SYSDATE between VAL.START_DATE_ACTIVE and nvl(VAL.END_DATE_ACTIVE, SYSDATE+1); 
			EXCEPTION WHEN OTHERS THEN
			  fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'Wallet Location Not Found' );
			  l_wallet_location := NULL;
			  l_password := NULL;
			END;

			IF l_wallet_location IS NOT NULL THEN
			  UTL_HTTP.SET_WALLET(l_wallet_location,l_password);
			END IF;
			-- Changes for SSL/TSL Upgrade End
		  l_http_request  := UTL_HTTP.begin_request(l_url);
	--      UTL_HTTP.set_transfer_timeout(300); -- this is in seconds.  default is 60
		  l_http_response := UTL_HTTP.get_response(l_http_request);

		  BEGIN
        LOOP
         UTL_HTTP.read_raw(l_http_response, l_raw, 32767);
         DBMS_LOB.writeappend (l_blob, UTL_RAW.length(l_raw), l_raw);
        END LOOP;
		  EXCEPTION
			WHEN UTL_HTTP.end_of_body THEN
			  UTL_HTTP.end_response(l_http_response);
		  END;

		  IF UTL_RAW.cast_to_varchar2(dbms_lob.substr(l_blob,5,1))<>'%PDF-' THEN -- verify PDF doc prefix
			  DBMS_LOB.freetemporary(l_blob);
			  DBMS_LOB.createtemporary(l_blob, FALSE); -- return empty blob because not valid pdf.
          x_ret_code := 1;
          x_error_buff := 'Output of '||l_request_id||' and '||p_customer_trx_id||' is not PDF ';
		  ELSE
        BEGIN
          UPDATE XX_XDO_REQUEST_DOCS_WEB SET request_id=l_request_id, document_data=l_blob, creation_date=sysdate WHERE customer_trx_id=p_customer_trx_id;
          IF SQL%NOTFOUND THEN
          INSERT INTO XX_XDO_REQUEST_DOCS_WEB (customer_trx_id,request_id,document_data,creation_date) VALUES (p_customer_trx_id,l_request_id,l_blob,sysdate);
          END IF;
          COMMIT;
          --Commented on 21-Nov-2016 defect#39482
          --DELETE FROM XX_XDO_REQUEST_DOCS_WEB WHERE creation_date<SYSDATE-7; -- purge;
          --COMMIT;
          x_ret_code := 0;
         EXCEPTION WHEN OTHERS THEN
          NULL; -- cache and purge are not critical so do not fail
        END;
		  END IF;
      
		  EXCEPTION WHEN OTHERS THEN
			PUT_ERR_LINE('Other exception in get_invoice: ' || SQLERRM,p_customer_trx_id,fnd_global.user_id,l_url);
			UTL_HTTP.end_response(l_http_response);
			DBMS_LOB.freetemporary(l_blob);
      x_ret_code := 1;
      x_error_buff := 'Exception for request_id '||l_request_id||' and '||p_customer_trx_id||' is '||SQLERRM;
			return;
		  END;
	END IF;
END save_pdf_invoice_copy;

END XX_ARI_INVOICE_COPY_PKG;
/
SHOW ERRORS;