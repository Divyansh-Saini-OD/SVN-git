create or replace PACKAGE BODY xx_ce_cc_preprocess_pkg
AS
  -- +=================================================================================+
  -- |                       Office Depot - Project Simplify                           |
  -- |                                                                                 |
  -- +=================================================================================+
  -- | Name       : xx_ce_ajb_preprocess_pkg.pkb                                       |
  -- | Description: E2077 OD: CE Pre-Process AJB Files                                 |
  -- |                                                                                 |
  -- |                                                                                 |
  -- |Change Record                                                                    |
  -- |==============                                                                   |
  -- |Version   Date         Authors            Remarks                                |
  -- |========  ===========  ===============    ============================           |
  -- |  1.0     2011-02-28   Joe Klein          New package copied from E1310 to       |
  -- |                                          create separate package for the        |
  -- |                                          pre-process procedure.                 |
  -- |                                          Make appropriate changes for E2077     |
  -- |                                          and SDR project.                       |
  -- |                                                                                 |
  -- |                                          Remove NOWAIT from FOR UPDATE          |
  -- |                                          statement in these cursors:            |
  -- |                                          c996_match_rct_ajb_cr                  |
  -- |                                          c996_unmatched                         |
  -- |                                          c996_match_rct_ajb_non_cr              |
  -- |                                          c996_no_cardtype                       |
  -- |                                          c998_match_rct_ajb_cr                  |
  -- |                                          c998_match_rct_ajb_non_cr              |
  -- |  1.1     2011-05-09   Joe Klein          For cursors against                    |
  -- |                                          xx_ar_order_receipt_dtl                |
  -- |                                          add join with xx_ce_recon_glact_hdr    |
  -- |                                          to get recon_header_id, similar to     |
  -- |                                          join logic in xx_ce_ajb_receipts_v.    |
  -- |  1.2     2011-05-25   Joe Klein          Add to where clause of cursors joining |
  -- |                                          xx_ce_ajb998, xx_ar_order_receipt_dtl  |
  -- |                                          to join on                             |
  -- |                                          dtl.payment_amount = ajb998.trx_amount.|
  -- |  1.3     2011-05-26   Joe Klein          Changed cursors that joined to         |
  -- |                                          xx_ce_ajb_receipts_v to select         |
  -- |                                          om_card_type_meaning(om_card_type)     |
  -- |                                          instead of ajb_card_type.  This follows|
  -- |                                          new processing rules for SDR project   |
  -- |                                          that selects om_card_type from         |
  -- |                                          xx_ar_order_receipt_dt.                |
  -- | 1.4     2011-06-16   Gaurav Agarwal      Hint added for UAT Defect -12095       |
  -- | 1.5     2011-09-29   Abdul Khan          Modified c998_match_rct_ord_cr_non_pos |
  -- |                                          for QC Defect # 13474                  |
  -- | 1.6     2011-11-30   Abdul Khan          Added logic for Zero Dollar Receipts   |
  -- |                                          QC Defect # 13263                      |
  -- | 1.7     2012-06-07   Abdul Khan          Added logic for identifying duplicate  |
  -- |                                          records in xx_ce_ajb998 for debit card |
  -- |                                          QC Defect # 18476                      |
  -- | 1.8     2013-02-08   Bapuji Nanapaneni   QC 22178, 22133 changes Added Provider |
  -- |                                          type PAYPAL for 998 and 996            |
  -- | 1.9     24-MAY-2013  Bapuji N            Fix for PCI compliance for IREC Tran's |
  -- |                                          DEFECT# 23640                          |
  -- | 2.0     02-OCT-2013  Sathish Danda       Fix for bank_rec_id for File names     |
  -- |                                  (PayPalWEB (or)PayPalPOS) as           |
  -- |                                          Identified by AJB Filename on 996,     |
  -- |                                          998 and 999 Files for                  |
  -- |                                          DEFECT# 25706                          |
  -- | 2.1     22-DEC-2014  Avinash Baddam      Defect#33066.E2077 Changes for Amazon MPL |
  -- | 2.2     29-MAY-2015  Ravi Palikala       Defect#33471.E2077 Changes for TELECHECK, PAYPAL |
  -- | 2.3     28-Oct-2015  Avinash Baddam      R12.2 Compliance changes               |
  -- | 2.4     21-Apr-2016  Rma Goyal           QC 37638, performance improvement      |
  -- | 2.5     21-Sep-2016  Rakesh Polepalli    QC 38437, Added AJB file name         |
  -- |               condition for the update statements  |
  -- | 2.6     02-SEP-2017  Uday Jadhav         Added Bizbox AR Matching logic for 996 and 998|
  -- | 2.7     13-OCT-2017  Uday Jadhav         Defect# 43424REMOVED FOR UPDATE FROM SELECT and COMMENTED Hin
  -- | 2.7.1   11-NOV-2017  M K Pramod Kumar    Defect# 43424 Code changes to default Status=NEW |
  -- | 2.8     21-MAY-2018  M K Pramod Kumar    Modified for processing External MarketPlaces NAIT-40753|
  -- | 2.9     21-MAY-2018  M K Pramod Kumar    Modified to derive Error Messages and derive ORDT information for External MPL- NAIT-74976|
  -- +=================================================================================+
  -- ----------------------------------------------
  -- Global Variables
  -- ----------------------------------------------
  gn_org_id  NUMBER := fnd_profile.VALUE ('ORG_ID');
  gn_user_id NUMBER := fnd_global.user_id;
FUNCTION get_recon_date(
    p_bank_rec_id IN xx_ce_ajb999.bank_rec_id%TYPE)
  RETURN DATE
IS
  l_recon_date DATE;
BEGIN
  SELECT TO_DATE (SUBSTR (p_bank_rec_id, 1, 8), 'YYYYMMDD')
  INTO l_recon_date
  FROM DUAL;
  RETURN l_recon_date;
EXCEPTION
WHEN OTHERS THEN
  RETURN NULL;
END get_recon_date;

/**********************************************************************************
* Procedure to derive EBS Order Information for partial processed files for EBAY,WALMART and RAKUTEN.
* This procedure is called by MAIN_MPL_SETTLEMENT_PROCESS.
***********************************************************************************/
PROCEDURE DERIVE_MPL_ORDER_INFO
IS
  CURSOR c998_derive_order_info
  IS
    SELECT ajb998.ROWID row_id ,
      ajb998.receipt_num ,
      ajb998.trx_type,
      ajb998.provider_type,
      ajb998.store_num
    FROM xx_ce_ajb998 ajb998
    WHERE 1                  = 1
    AND ajb998.org_id+0 = gn_org_id
    AND ajb998.status        = 'PREPROCESSED'
    AND ajb998.processor_id IN ('EBAY','RAKUTEN','WALMART')
	and store_num in ('010000','005910')
    AND NOT EXISTS
      (SELECT 1
      FROM xx_ce_999_interface
      WHERE bank_rec_id = ajb998.bank_rec_id
      AND processor_id  = ajb998.processor_id
      );
  CURSOR ordt_cur(p_order_id VARCHAR2,p_trx_type VARCHAR2,p_provider_type VARCHAR2)
  IS
    SELECT xordt.order_payment_id,
      xordt.store_number,
      xordt.orig_sys_document_ref
    FROM xx_ar_order_receipt_dtl xordt
    WHERE xordt.mpl_order_id  = p_order_id
    AND xordt.sale_type       = p_trx_type
    AND xordt.order_source   IN ('MPL')
    AND xordt.credit_card_code=p_provider_type;
type ordt
IS
  TABLE OF ordt_cur%rowtype INDEX BY pls_integer;
  l_ordt_tab ordt;
type tbl_c998_derive_order_info
IS
  TABLE OF c998_derive_order_info%rowtype INDEX BY pls_integer;
  lc_derive_order_info tbl_c998_derive_order_info;
  lc_batch_size       NUMBER     := 10000;
  lv_execute_proc_flg VARCHAR2(1):='N';
  lv_derive_order_date varchar2(15);
  Lc_def_store_number varchar2(10);
BEGIN

  BEGIN
    SELECT vals.target_value2,vals.target_value3
    INTO lv_derive_order_date,Lc_def_store_number
   FROM xx_fin_translatevalues vals,
      xx_fin_translatedefinition defn
    WHERE 1                   =1
    AND defn.translation_name = 'OD_EXT_MARKETPLACE_SETUPS'
    AND defn.translate_id     = vals.translate_id
    AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
    AND SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
    AND vals.enabled_flag                                               = 'Y'
    AND defn.enabled_flag                                               = 'Y'
    and rownum=1;
    IF lv_derive_order_date is null or TO_CHAR(to_date(lv_derive_order_date,'DD-MON-YYYY'),'DDMONYYYY') =TO_CHAR(to_Date(TRUNC(sysdate),'DD-MON-YY'),'DDMONYYYY') THEN
      lv_execute_proc_flg                                              :='Y';
    ELSE
      UPDATE xx_fin_translatevalues vals
      SET vals.target_value2  =TO_CHAR(to_Date(TRUNC(sysdate),'DD-MON-YY'),'DD-MON-YYYY')
      WHERE vals.translate_id IN
        (SELECT defn.translate_id
        FROM xx_fin_translatedefinition defn
        WHERE 1                   =1
        AND defn.translation_name = 'OD_EXT_MARKETPLACE_SETUPS'
        AND SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
        AND defn.enabled_flag = 'Y'
        )
      AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
      AND vals.enabled_flag = 'Y';
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    lv_execute_proc_flg:='Y';
	Lc_def_store_number:='005910';
  END;
  IF lv_execute_proc_flg='N' THEN
    OPEN c998_derive_order_info;
    LOOP
      FETCH c998_derive_order_info bulk collect
      INTO lc_derive_order_info limit lc_batch_size;
      EXIT
    WHEN lc_derive_order_info.count = 0;
      FOR indx IN lc_derive_order_info.first..lc_derive_order_info.last
      LOOP
        IF lc_derive_order_info(indx).store_num=Lc_def_store_number THEN
          OPEN ordt_cur(lc_derive_order_info(indx).receipt_num,lc_derive_order_info(indx).trx_type,lc_derive_order_info(indx).provider_type);
          FETCH ordt_cur bulk collect INTO l_ordt_tab;
          CLOSE ordt_cur;
          IF l_ordt_tab.count = 1 THEN
            UPDATE xx_ce_ajb998
            SET invoice_num    = l_ordt_tab(1).orig_sys_document_ref,
              store_num        = l_ordt_tab(1).store_number,
              last_update_date = SYSDATE ,
              last_updated_by  = gn_user_id
            WHERE ROWID        = lc_derive_order_info (indx).row_id;
          END IF;
        END IF;
      END LOOP;
    END LOOP;
    CLOSE c998_derive_order_info;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG, ' ');
  fnd_file.put_line(fnd_file.LOG,'Exception occured in DERIVE_MPL_ORDER_INFO START SQLCODE-'||SQLCODE||' SQLERRM-'||sqlerrm);
END DERIVE_MPL_ORDER_INFO;

PROCEDURE xx_ce_ajb_preprocess(
    x_errbuf OUT NOCOPY  VARCHAR2 ,
    x_retcode OUT NOCOPY NUMBER ,
    p_file_type     IN VARCHAR2 ,
    p_ajb_file_name IN VARCHAR2 ,
    p_batch_size    IN NUMBER )
IS
  /* Define Variables */
  v_bank_rec_id xx_ce_ajb996.bank_rec_id%TYPE;
  v_currency fnd_currencies.currency_code%TYPE;
  v_currency_code xx_ce_ajb996.currency_code%TYPE;
  v_country_code xx_ce_ajb996.country_code%TYPE;
  v_org_id hr_all_organization_units.organization_id%TYPE;
  v_recon_date xx_ce_ajb996.recon_date%TYPE;
  v_territory_code fnd_territories.territory_code%TYPE;
  ln_recon_header_id xx_ce_recon_glact_hdr.header_id%TYPE;
  lc_card_type xx_ce_recon_glact_hdr.ajb_card_type%TYPE;
  lc_card_num xx_ce_ajb996.card_num%TYPE;
  v_rows_updated  INTEGER;
  ln_ajb998_count NUMBER; -- Added for QC Defect # 18476
  ln_ordt_count   NUMBER; -- Added for QC Defect # 18476
  /* Cursor for preprocessing 996 country/org */
  CURSOR c996_org
  IS
    SELECT DISTINCT country_code
    FROM xx_ce_ajb996
    WHERE status      = 'PREPROCESSING'
    AND country_code IS NOT NULL
    AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name);
  --AND org_id = gn_org_id; -- Added for PROD Defect: 2046,1716
  /* Cursor for preprocessing 996 currency */
  CURSOR c996_currency
  IS
    SELECT DISTINCT currency_code
    FROM xx_ce_ajb996
    WHERE status       = 'PREPROCESSING'
    AND currency_code IS NOT NULL
    AND ajb_file_name  = NVL (p_ajb_file_name, ajb_file_name)
    AND org_id         = gn_org_id; -- Added for PROD Defect: 2046,1716
  /* Cursor for preprocessing 996 bank_rec_id */
  CURSOR c996_bank
  IS
    SELECT DISTINCT bank_rec_id
    FROM xx_ce_ajb996
    WHERE status      = 'PREPROCESSING'
    AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name)
    AND org_id        = gn_org_id; -- Added for PROD Defect: 2046,1716
TYPE all_99x_rec
IS
  RECORD
  (
    x99x_rowid ROWID ,
    cash_receipt_id NUMBER ,
    header_id       NUMBER ,
    processor_id xx_ce_ajb998.processor_id%TYPE ,
    om_card_type xx_ce_recon_glact_hdr.ajb_card_type%TYPE ,
    bank_rec_id xx_ce_ajb998.bank_rec_id%TYPE ,
    customer_id ar_cash_receipts_all.pay_from_customer%TYPE );
TYPE c99x_rec
IS
  RECORD
  (
    x99x_rowid ROWID ,
    cash_receipt_id NUMBER ,
    header_id       NUMBER ,
    processor_id xx_ce_ajb998.processor_id%TYPE ,
    om_card_type xx_ce_recon_glact_hdr.ajb_card_type%TYPE ,
    bank_rec_id xx_ce_ajb998.bank_rec_id%TYPE ,
    order_payment_id xx_ar_order_receipt_dtl.order_payment_id%TYPE ,
    customer_id xx_ar_order_receipt_dtl.customer_id%TYPE );
TYPE c998_rec
IS
  RECORD
  (
    x99x_rowid ROWID ,
    ord_rowid ROWID ,
    cash_receipt_id NUMBER ,
    header_id       NUMBER ,
    processor_id xx_ce_ajb998.processor_id%TYPE ,
    om_card_type xx_ce_recon_glact_hdr.ajb_card_type%TYPE ,
    bank_rec_id xx_ce_ajb998.bank_rec_id%TYPE ,
    order_payment_id xx_ar_order_receipt_dtl.order_payment_id%TYPE ,
    customer_id xx_ar_order_receipt_dtl.customer_id%TYPE );
  -- Added for QC Defect # 18476 -- Start
TYPE c998_rec_debit
IS
  RECORD
  (
    x99x_rowid ROWID ,
    ord_rowid ROWID ,
    cash_receipt_id NUMBER ,
    header_id       NUMBER ,
    processor_id xx_ce_ajb998.processor_id%TYPE ,
    om_card_type xx_ce_recon_glact_hdr.ajb_card_type%TYPE ,
    bank_rec_id xx_ce_ajb998.bank_rec_id%TYPE ,
    order_payment_id xx_ar_order_receipt_dtl.order_payment_id%TYPE ,
    customer_id xx_ar_order_receipt_dtl.customer_id%TYPE ,
    provider_type xx_ce_ajb998.provider_type%TYPE ,
    store_num xx_ce_ajb998.store_num%TYPE ,
    card_num xx_ce_ajb998.card_num%TYPE ,
    trx_type xx_ce_ajb998.trx_type%TYPE ,
    trx_date xx_ce_ajb998.trx_date%TYPE ,
    trx_amount xx_ce_ajb998.trx_amount%TYPE ,
    receipt_num xx_ce_ajb998.receipt_num%TYPE );
  -- Added for QC Defect # 18476 -- End
TYPE all_99x_unmatched_rec
IS
  RECORD
  (
    x99x_rowid ROWID ,
    processor_id xx_ce_ajb998.processor_id%TYPE ,
    bank_rec_id xx_ce_ajb998.bank_rec_id%TYPE ,
    ajb_file_name xx_ce_ajb998.ajb_file_name%TYPE ,
    card_num xx_ce_ajb998.card_num%TYPE ,
    provider_type xx_ce_ajb998.provider_type%TYPE );
TYPE all_99x_tab
IS
  TABLE OF all_99x_rec INDEX BY BINARY_INTEGER;
TYPE c99x_tab
IS
  TABLE OF c99x_rec INDEX BY BINARY_INTEGER;
TYPE c998_tab
IS
  TABLE OF c998_rec INDEX BY BINARY_INTEGER;
  -- Added for QC Defect # 18476 -- Start
TYPE c998_tab_debit
IS
  TABLE OF c998_rec_debit INDEX BY BINARY_INTEGER;
  -- Added for QC Defect # 18476 -- End
TYPE all_99x_unmatched_tab
IS
  TABLE OF all_99x_unmatched_rec INDEX BY BINARY_INTEGER;
  all_99x_data all_99x_tab;
  all_99x_null all_99x_tab;
  c99x_data c99x_tab;
  c99x_null c99x_tab;
  c998_data c998_tab;
  c998_data_debit c998_tab_debit; -- Added for QC Defect # 18476
  c998_null c998_tab;
  all_99x_unmatched_data all_99x_unmatched_tab;
  all_99x_unmatched_null all_99x_unmatched_tab;
  /* Cursor for preprocessing 996 data to attempt to match on invoice number against XX_AR_ORDER_RECEIPT_DTL table */
  CURSOR c996_match_inv_ord
  IS
    SELECT ajb996.ROWID row_id ,
      dtl.cash_receipt_id ,
      hdr.header_id ,
      ajb996.processor_id ,
      dtl.credit_card_code om_card_type ,
      ajb996.bank_rec_id ,
      dtl.order_payment_id ,
      dtl.customer_id
    FROM xx_ce_ajb996 ajb996 ,
      xx_ar_order_receipt_dtl dtl ,
      xx_ce_recon_glact_hdr hdr ,
      fnd_lookup_values lv
    WHERE 1                            = 1
    AND ajb996.org_id                  = gn_org_id
    AND ajb996.status                  = 'PREPROCESSED'
    AND ajb996.ajb_file_name           = NVL(p_ajb_file_name, ajb996.ajb_file_name)
    AND dtl.customer_receipt_reference = ajb996.invoice_num
    AND dtl.org_id                     = ajb996.org_id
    AND hdr.provider_code              = ajb996.processor_id
    AND hdr.org_id                     = ajb996.org_id
    AND lv.lookup_type                 = 'OD_PAYMENT_TYPES'
    AND lv.enabled_flag                = 'Y'
    AND lv.meaning                     = dtl.credit_card_code
    AND lv.lookup_code                 = hdr.om_card_type
    AND dtl.receipt_date BETWEEN lv.start_date_active    - 0 AND NVL(lv.end_date_active, dtl.receipt_date + 1)
    AND dtl.receipt_date BETWEEN hdr.effective_from_date - 0 AND NVL(hdr.effective_to_date, dtl.receipt_date + 1)
    AND NOT EXISTS
      (SELECT 1
      FROM xx_ce_999_interface
      WHERE bank_rec_id = ajb996.bank_rec_id
      AND processor_id  = ajb996.processor_id
      )
  UNION ALL /*-- Added for Bizbox*/
  SELECT ajb996.ROWID row_id ,
    dtl.cash_receipt_id ,
    hdr.header_id ,
    ajb996.processor_id ,
    dtl.credit_card_code om_card_type ,
    ajb996.bank_rec_id ,
    dtl.order_payment_id ,
    dtl.customer_id
  FROM xx_ce_ajb996 ajb996 ,
    xx_ar_order_receipt_dtl dtl ,
    xx_ce_recon_glact_hdr hdr ,
    fnd_lookup_values lv
  WHERE 1                  = 1
  AND ajb996.org_id        = gn_org_id
  AND ajb996.status        = 'PREPROCESSED'
  AND ajb996.ajb_file_name = NVL(p_ajb_file_name, ajb996.ajb_file_name)
  AND dtl.mpl_order_id     = ajb996.invoice_num
  AND dtl.order_source     ='BBOX'
  AND dtl.org_id           = ajb996.org_id
  AND hdr.provider_code    = ajb996.processor_id
  AND hdr.org_id           = ajb996.org_id
  AND lv.lookup_type       = 'OD_PAYMENT_TYPES'
  AND lv.enabled_flag      = 'Y'
  AND lv.meaning           = dtl.credit_card_code
  AND lv.lookup_code       = hdr.om_card_type
  AND dtl.receipt_date BETWEEN lv.start_date_active    - 0 AND NVL(lv.end_date_active, dtl.receipt_date + 1)
  AND dtl.receipt_date BETWEEN hdr.effective_from_date - 0 AND NVL(hdr.effective_to_date, dtl.receipt_date + 1)
  AND NOT EXISTS
    (SELECT 1
    FROM xx_ce_999_interface
    WHERE bank_rec_id = ajb996.bank_rec_id
    AND processor_id  = ajb996.processor_id
    ) ; --FOR UPDATE; commented for defect# 43424
  /* Cursor for preprocessing 996 data to attempt to match on invoice number against XX_CE_AJB_RECEIPTS_V view */
  CURSOR c996_match_inv_ajb
  IS
    /* Commented out by NB for IREC TRAN's AUTHCODE whihc come in INVOICE_NUM is TANGABLED ID and NOT TRAN NO OR RCPT NO */
    /*         SELECT     xca6.ROWID row_id
    , (SELECT cash_receipt_id
    FROM xx_ce_ajb_receipts_v xcarv
    WHERE ROWNUM = 1
    AND xca6.processor_id = xcarv.provider_code
    AND xca6.org_id = xcarv.org_id
    AND xca6.trx_date - 0 = xcarv.receipt_date - 0
    AND xca6.invoice_num = xcarv.customer_receipt_reference) cash_receipt_id
    , (SELECT header_id
    FROM xx_ce_ajb_receipts_v xcarv
    WHERE ROWNUM = 1
    AND xca6.processor_id = xcarv.provider_code
    AND xca6.org_id = xcarv.org_id
    AND xca6.trx_date - 0 = xcarv.receipt_date - 0
    AND xca6.invoice_num = xcarv.customer_receipt_reference) header_id
    , xca6.processor_id
    , (SELECT om_card_type_meaning
    FROM xx_ce_ajb_receipts_v xcarv
    WHERE ROWNUM = 1
    AND xca6.processor_id = xcarv.provider_code
    AND xca6.org_id = xcarv.org_id
    AND xca6.trx_date - 0 = xcarv.receipt_date - 0
    AND xca6.invoice_num = xcarv.customer_receipt_reference) om_card_type
    , xca6.bank_rec_id
    , (SELECT pay_from_customer
    FROM xx_ce_ajb_receipts_v xcarv
    WHERE ROWNUM = 1
    AND xca6.processor_id = xcarv.provider_code
    AND xca6.org_id = xcarv.org_id
    AND xca6.trx_date - 0 = xcarv.receipt_date - 0
    AND xca6.invoice_num = xcarv.customer_receipt_reference) customer_id
    FROM xx_ce_ajb996 xca6
    WHERE 1 = 1
    AND xca6.org_id = gn_org_id -- Added for PROD Defect: 2046,1716
    AND xca6.status = 'PREPROCESSED'
    AND xca6.ajb_file_name = NVL (p_ajb_file_name, xca6.ajb_file_name)
    AND NOT EXISTS (
    SELECT 1
    FROM xx_ce_999_interface
    WHERE bank_rec_id = xca6.bank_rec_id
    AND processor_id = xca6.processor_id)
    */
    SELECT xca6.ROWID row_id ,
      (SELECT cash_receipt_id
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM          = 1
      AND xca6.processor_id = xcarv.provider_code
      AND xca6.org_id       = xcarv.org_id
      AND xca6.trx_date - 0 = xcarv.receipt_date - 0
      AND xca6.invoice_num  = xcarv.customer_receipt_reference
    UNION
    SELECT xcarv.cash_receipt_id
    FROM xx_ce_ajb_receipts_v xcarv ,
      ar_cash_receipts_all acr
    WHERE ROWNUM              = 1
    AND xca6.processor_id     = xcarv.provider_code
    AND xca6.org_id           = xcarv.org_id
    AND xca6.trx_date - 0     = xcarv.receipt_date - 0
    AND xca6.invoice_num      = acr.payment_server_order_num
    AND xcarv.cash_receipt_id = acr.cash_receipt_id
      ) cash_receipt_id ,
      (SELECT header_id
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM          = 1
      AND xca6.processor_id = xcarv.provider_code
      AND xca6.org_id       = xcarv.org_id
      AND xca6.trx_date - 0 = xcarv.receipt_date - 0
      AND xca6.invoice_num  = xcarv.customer_receipt_reference
      UNION
      SELECT header_id
      FROM xx_ce_ajb_receipts_v xcarv ,
        ar_cash_receipts_all acr
      WHERE ROWNUM              = 1
      AND xca6.processor_id     = xcarv.provider_code
      AND xca6.org_id           = xcarv.org_id
      AND xca6.trx_date - 0     = xcarv.receipt_date - 0
      AND xca6.invoice_num      = acr.payment_server_order_num
      AND xcarv.cash_receipt_id = acr.cash_receipt_id
      ) header_id ,
      xca6.processor_id processor_id ,
      (SELECT om_card_type_meaning
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM          = 1
      AND xca6.processor_id = xcarv.provider_code
      AND xca6.org_id       = xcarv.org_id
      AND xca6.trx_date - 0 = xcarv.receipt_date - 0
      AND xca6.invoice_num  = xcarv.customer_receipt_reference
      UNION
      SELECT om_card_type_meaning
      FROM xx_ce_ajb_receipts_v xcarv ,
        ar_cash_receipts_all acr
      WHERE ROWNUM              = 1
      AND xca6.processor_id     = xcarv.provider_code
      AND xca6.org_id           = xcarv.org_id
      AND xca6.trx_date - 0     = xcarv.receipt_date - 0
      AND xca6.invoice_num      = acr.payment_server_order_num
      AND xcarv.cash_receipt_id = acr.cash_receipt_id
      ) om_card_type ,
      xca6.bank_rec_id bank_rec_id ,
      (SELECT pay_from_customer
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM          = 1
      AND xca6.processor_id = xcarv.provider_code
      AND xca6.org_id       = xcarv.org_id
      AND xca6.trx_date - 0 = xcarv.receipt_date - 0
      AND xca6.invoice_num  = xcarv.customer_receipt_reference
      UNION
      SELECT xcarv.pay_from_customer
      FROM xx_ce_ajb_receipts_v xcarv ,
        ar_cash_receipts_all acr
      WHERE ROWNUM              = 1
      AND xca6.processor_id     = xcarv.provider_code
      AND xca6.org_id           = xcarv.org_id
      AND xca6.trx_date - 0     = xcarv.receipt_date - 0
      AND xca6.invoice_num      = acr.payment_server_order_num
      AND xcarv.cash_receipt_id = acr.cash_receipt_id
      ) customer_id
    FROM xx_ce_ajb996 xca6
    WHERE 1                = 1
    AND xca6.org_id        = gn_org_id
    AND xca6.status        = 'PREPROCESSED'
    AND xca6.ajb_file_name = NVL (p_ajb_file_name, xca6.ajb_file_name)
    AND NOT EXISTS
      (SELECT 1
      FROM xx_ce_999_interface
      WHERE bank_rec_id = xca6.bank_rec_id
      AND processor_id  = xca6.processor_id
      ) ;--FOR UPDATE; commented for defect# 43424
    /* Cursor for 996 match attempt on receipt number against XX_AR_ORDER_RECEIPT_DTL table for credit POS transactions*/
    CURSOR c996_match_rct_ord_cr_pos
    IS
      SELECT ajb996.ROWID row_id ,
        dtl.cash_receipt_id ,
        hdr.header_id ,
        ajb996.processor_id ,
        dtl.credit_card_code om_card_type ,
        ajb996.bank_rec_id ,
        dtl.order_payment_id ,
        dtl.customer_id
      FROM xx_ce_ajb996 ajb996 ,
        xx_ar_order_receipt_dtl dtl ,
        xx_ce_recon_glact_hdr hdr ,
        fnd_lookup_values lv
      WHERE 1                            = 1
      AND ajb996.org_id                  = gn_org_id
      AND ajb996.status                  = 'PREPROCESSED'
      AND ajb996.ajb_file_name           = NVL(p_ajb_file_name, ajb996.ajb_file_name)
      AND ajb996.provider_type           = 'CREDIT'
      AND SUBSTR(ajb996.attribute21,1,2) = 'OM'
      AND dtl.order_payment_id           = ajb996.receipt_num -- QC 37638, Perf Fix, removing to_char dtl.order_payment_id
      AND dtl.org_id                     = ajb996.org_id
      AND hdr.provider_code              = ajb996.processor_id
      AND hdr.org_id                     = ajb996.org_id
      AND lv.lookup_type                 = 'OD_PAYMENT_TYPES'
      AND lv.enabled_flag                = 'Y'
      AND lv.meaning                     = dtl.credit_card_code
      AND lv.lookup_code                 = hdr.om_card_type
      AND dtl.receipt_date BETWEEN lv.start_date_active    - 0 AND NVL(lv.end_date_active, dtl.receipt_date + 1)
      AND dtl.receipt_date BETWEEN hdr.effective_from_date - 0 AND NVL(hdr.effective_to_date, dtl.receipt_date + 1)
      AND NOT EXISTS
        (SELECT 1
        FROM xx_ce_999_interface
        WHERE bank_rec_id = ajb996.bank_rec_id
        AND processor_id  = ajb996.processor_id
        ) ;--FOR UPDATE; commented for defect# 43424
    /* Cursor for 996 match attempt on receipt number against XX_AR_ORDER_RECEIPT_DTL table for credit non-POS transactions*/
    CURSOR c996_match_rct_ord_cr_non_pos
    IS
      SELECT ajb996.ROWID row_id ,
        dtl.cash_receipt_id ,
        hdr.header_id ,
        ajb996.processor_id ,
        dtl.credit_card_code om_card_type ,
        ajb996.bank_rec_id ,
        dtl.order_payment_id ,
        dtl.customer_id
      FROM xx_ce_ajb996 ajb996 ,
        xx_ar_order_receipt_dtl dtl ,
        xx_ce_recon_glact_hdr hdr ,
        fnd_lookup_values lv
      WHERE 1                             = 1
      AND ajb996.org_id                   = gn_org_id
      AND ajb996.status                   = 'PREPROCESSED'
      AND ajb996.ajb_file_name            = NVL(p_ajb_file_name, ajb996.ajb_file_name)
      AND ajb996.provider_type            = 'CREDIT'
      AND SUBSTR(ajb996.attribute21,1,2) != 'OM'
      AND dtl.receipt_number              = ajb996.receipt_num
      AND dtl.org_id                      = ajb996.org_id
      AND hdr.provider_code               = ajb996.processor_id
      AND hdr.org_id                      = ajb996.org_id
      AND lv.lookup_type                  = 'OD_PAYMENT_TYPES'
      AND lv.enabled_flag                 = 'Y'
      AND lv.meaning                      = dtl.credit_card_code
      AND lv.lookup_code                  = hdr.om_card_type
      AND dtl.receipt_date BETWEEN lv.start_date_active    - 0 AND NVL(lv.end_date_active, dtl.receipt_date + 1)
      AND dtl.receipt_date BETWEEN hdr.effective_from_date - 0 AND NVL(hdr.effective_to_date, dtl.receipt_date + 1)
      AND NOT EXISTS
        (SELECT 1
        FROM xx_ce_999_interface
        WHERE bank_rec_id = ajb996.bank_rec_id
        AND processor_id  = ajb996.processor_id
        ) ;--FOR UPDATE; commented for defect# 43424
    /* Cursor for 996 match attempt on receipt number against XX_AR_ORDER_RECEIPT_DTL table for non-credit transactions*/
    CURSOR c996_match_rct_ord_non_cr
    IS
      SELECT ajb996.ROWID row_id ,
        dtl.cash_receipt_id ,
        hdr.header_id ,
        ajb996.processor_id ,
        dtl.credit_card_code om_card_type ,
        ajb996.bank_rec_id ,
        dtl.order_payment_id ,
        dtl.customer_id
      FROM xx_ce_ajb996 ajb996 ,
        xx_ar_order_receipt_dtl dtl ,
        xx_ce_recon_glact_hdr hdr ,
        fnd_lookup_values lv
      WHERE 1                            = 1
      AND ajb996.org_id                  = gn_org_id
      AND ajb996.status                  = 'PREPROCESSED'
      AND ajb996.ajb_file_name           = NVL(p_ajb_file_name, ajb996.ajb_file_name)
      AND ajb996.provider_type          IN ('CHECK', 'DEBIT','PAYPAL') --Defect# 22178
      AND dtl.customer_receipt_reference = ajb996.receipt_num
      AND dtl.org_id                     = ajb996.org_id
      AND hdr.provider_code              = ajb996.processor_id
      AND hdr.org_id                     = ajb996.org_id
      AND lv.lookup_type                 = 'OD_PAYMENT_TYPES'
      AND lv.enabled_flag                = 'Y'
      AND lv.meaning                     = dtl.credit_card_code
      AND lv.lookup_code                 = hdr.om_card_type
      AND dtl.receipt_date BETWEEN lv.start_date_active    - 0 AND NVL(lv.end_date_active, dtl.receipt_date + 1)
      AND dtl.receipt_date BETWEEN hdr.effective_from_date - 0 AND NVL(hdr.effective_to_date, dtl.receipt_date + 1)
      AND NOT EXISTS
        (SELECT 1
        FROM xx_ce_999_interface
        WHERE bank_rec_id = ajb996.bank_rec_id
        AND processor_id  = ajb996.processor_id
        ) ;--FOR UPDATE; commented for defect# 43424
    /* Cursor for 996 match attempt on receipt number against XX_CE_AJB_RECEIPTS_V view for credit transactions*/
    CURSOR c996_match_rct_ajb_cr
    IS
      SELECT xca6.ROWID row_id ,
        (SELECT cash_receipt_id
        FROM xx_ce_ajb_receipts_v xcarv
        WHERE ROWNUM          = 1
        AND xca6.processor_id = xcarv.provider_code
        AND xca6.org_id       = xcarv.org_id
        AND xca6.trx_date - 0 = xcarv.receipt_date - 0
        AND xca6.receipt_num  = xcarv.receipt_number
        ) cash_receipt_id ,
      (SELECT header_id
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM          = 1
      AND xca6.processor_id = xcarv.provider_code
      AND xca6.org_id       = xcarv.org_id
      AND xca6.trx_date - 0 = xcarv.receipt_date - 0
      AND xca6.receipt_num  = xcarv.receipt_number
      ) header_id ,
      xca6.processor_id ,
      (SELECT om_card_type_meaning
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM          = 1
      AND xca6.processor_id = xcarv.provider_code
      AND xca6.org_id       = xcarv.org_id
      AND xca6.trx_date - 0 = xcarv.receipt_date - 0
      AND xca6.receipt_num  = xcarv.receipt_number
      ) om_card_type ,
      xca6.bank_rec_id ,
      (SELECT pay_from_customer
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM          = 1
      AND xca6.processor_id = xcarv.provider_code
      AND xca6.org_id       = xcarv.org_id
      AND xca6.trx_date - 0 = xcarv.receipt_date - 0
      AND xca6.receipt_num  = xcarv.receipt_number
      ) customer_id
    FROM xx_ce_ajb996 xca6
    WHERE 1                = 1
    AND xca6.org_id        = gn_org_id -- Added for PROD Defect: 2046,1716
    AND xca6.status        = 'PREPROCESSED'
    AND xca6.ajb_file_name = NVL (p_ajb_file_name, xca6.ajb_file_name)
    AND xca6.provider_type = 'CREDIT'
    AND NOT EXISTS
      (SELECT 1
      FROM xx_ce_999_interface
      WHERE bank_rec_id = xca6.bank_rec_id
      AND processor_id  = xca6.processor_id
      ) ;--FOR UPDATE; commented for defect# 43424
    /* Cursor for preprocessing 996 non-credit data */
    CURSOR c996_match_rct_ajb_non_cr
    IS
      SELECT xca6.ROWID row_id ,
        (SELECT cash_receipt_id
        FROM xx_ce_ajb_receipts_v xcarv
        WHERE ROWNUM           = 1
        AND xca6.processor_id  = xcarv.provider_code
        AND xca6.org_id        = xcarv.org_id
        AND xca6.receipt_num   = xcarv.customer_receipt_reference
        AND (xca6.trx_date - 0 = xcarv.receipt_date - 0
        OR xca6.trx_date   - 0 = xcarv.receipt_date + 1)
        ) cash_receipt_id ,
      (SELECT header_id
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM           = 1
      AND xca6.processor_id  = xcarv.provider_code
      AND xca6.org_id        = xcarv.org_id
      AND xca6.receipt_num   = xcarv.customer_receipt_reference
      AND (xca6.trx_date - 0 = xcarv.receipt_date - 0
      OR xca6.trx_date   - 0 = xcarv.receipt_date + 1)
      ) header_id ,
      xca6.processor_id ,
      (SELECT om_card_type_meaning
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM           = 1
      AND xca6.processor_id  = xcarv.provider_code
      AND xca6.org_id        = xcarv.org_id
      AND xca6.receipt_num   = xcarv.customer_receipt_reference
      AND (xca6.trx_date - 0 = xcarv.receipt_date - 0
      OR xca6.trx_date   - 0 = xcarv.receipt_date + 1)
      ) om_card_type ,
      xca6.bank_rec_id ,
      (SELECT pay_from_customer
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM           = 1
      AND xca6.processor_id  = xcarv.provider_code
      AND xca6.org_id        = xcarv.org_id
      AND xca6.receipt_num   = xcarv.customer_receipt_reference
      AND (xca6.trx_date - 0 = xcarv.receipt_date - 0
      OR xca6.trx_date   - 0 = xcarv.receipt_date + 1)
      ) customer_id
    FROM xx_ce_ajb996 xca6
    WHERE 1                 = 1
    AND xca6.org_id         = gn_org_id -- Added for PROD Defect: 2046,1716
    AND xca6.status         = 'PREPROCESSED'
    AND xca6.ajb_file_name  = NVL (p_ajb_file_name, xca6.ajb_file_name)
    AND xca6.provider_type IN ('CHECK', 'DEBIT','PAYPAL')--Defect# 22178
    AND NOT EXISTS
      (SELECT 1
      FROM xx_ce_999_interface
      WHERE bank_rec_id = xca6.bank_rec_id
      AND processor_id  = xca6.processor_id
      ) ;--FOR UPDATE; commented for defect# 43424
    /* Cursor for populating the recon_header_id for all unmatched 996 credit data */
    CURSOR c996_unmatched
    IS
      SELECT xca6.ROWID row_id ,
        xca6.processor_id ,
        xca6.bank_rec_id ,
        xca6.ajb_file_name ,
        xca6.card_num ,
        xca6.provider_type
      FROM xx_ce_ajb996 xca6
      WHERE 1                   = 1
      AND xca6.org_id           = gn_org_id -- Added for PROD Defect: 2046,1716
      AND xca6.status          IN ('PREPROCESSED' , 'PREPROCESSING', 'NOTMATCHED')
      AND xca6.ajb_file_name    = NVL (p_ajb_file_name, xca6.ajb_file_name)
      AND xca6.recon_header_id IS NULL
      AND NOT EXISTS
        (SELECT 1
        FROM xx_ce_999_interface
        WHERE bank_rec_id = xca6.bank_rec_id
        AND processor_id  = xca6.processor_id
        ) ;--FOR UPDATE; commented for defect# 43424
    /* Cursor for preprocessing 996 no cardtype data */
    CURSOR c996_no_cardtype
    IS
      SELECT xca6.ROWID row_id ,
        ar_cash_receipt_id cash_receipt_id ,
        recon_header_id header_id ,
        processor_id ,
        card_type ,
        bank_rec_id ,
        customer_id
      FROM xx_ce_ajb996 xca6
      WHERE 1                              = 1
      AND xca6.org_id                      = gn_org_id -- Added for PROD Defect: 2046,1716
      AND xca6.status                      = 'NOTMATCHED'
      AND xca6.processor_id                = 'NABCRD'
      AND xca6.ajb_file_name               = NVL (p_ajb_file_name, xca6.ajb_file_name)
      AND SUBSTR (bank_rec_id, -2, 2) NOT IN
        (SELECT '-'
          || SUBSTR (lv.meaning, 1, 1)
        FROM xx_ce_recon_glact_hdr xcrgh,
          fnd_lookup_values lv
        WHERE xca6.processor_id = xcrgh.provider_code
        AND lv.lookup_type      = 'OD_PAYMENT_TYPES'
        AND lv.enabled_flag     = 'Y'
        AND lv.lookup_code      = xcrgh.om_card_type
        )
    AND NOT EXISTS
      (SELECT 1
      FROM xx_ce_999_interface
      WHERE bank_rec_id = xca6.bank_rec_id
      AND processor_id  = xca6.processor_id
      ) ;--FOR UPDATE; commented for defect# 43424
    /* Cursor for preprocessing 998 country/org */
    CURSOR c998_org
    IS
      SELECT DISTINCT country_code
      FROM xx_ce_ajb998
      WHERE status      = 'PREPROCESSING'
      AND country_code IS NOT NULL
      AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name);
    --ANd org_id = gn_org_id; -- Added for PROD Defect: 2046,1716
    /* Cursor for preprocessing 998 currency */
    CURSOR c998_currency
    IS
      SELECT DISTINCT currency_code
      FROM xx_ce_ajb998
      WHERE status       = 'PREPROCESSING'
      AND currency_code IS NOT NULL
      AND ajb_file_name  = NVL (p_ajb_file_name, ajb_file_name)
      AND org_id         = gn_org_id; -- Added for PROD Defect: 2046,1716
    /* Cursor for preprocessing 998 bank_rec_id */
    CURSOR c998_bank
    IS
      SELECT DISTINCT bank_rec_id
      FROM xx_ce_ajb998
      WHERE status      = 'PREPROCESSING'
      AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name)
      AND org_id        = gn_org_id; -- Added for PROD Defect: 2046,1716
    /* Cursor for populating the recon_header_id for all unmatched 998 credit data */
    CURSOR c998_unmatched
    IS
      SELECT xca6.ROWID row_id ,
        xca6.processor_id ,
        xca6.bank_rec_id ,
        xca6.ajb_file_name ,
        xca6.card_num ,
        xca6.provider_type
      FROM xx_ce_ajb998 xca6
      WHERE 1                   = 1
      AND xca6.org_id           = gn_org_id -- Added for PROD Defect: 2046,1716
      AND xca6.status          IN ('PREPROCESSED' , 'PREPROCESSING', 'NOTMATCHED')
      AND xca6.ajb_file_name    = NVL (p_ajb_file_name, xca6.ajb_file_name)
      AND xca6.recon_header_id IS NULL
      AND NOT EXISTS
        (SELECT 1
        FROM xx_ce_999_interface
        WHERE bank_rec_id = xca6.bank_rec_id
        AND processor_id  = xca6.processor_id
        ) ;--FOR UPDATE; commented for defect# 43424
    /* Cursor for 998 match attempt on receipt number against XX_AR_ORDER_RECEIPT_DTL table for credit POS transactions*/
    CURSOR c998_match_rct_ord_cr_pos
    IS
      SELECT                --/*+ INDEX(AJB998 XX_CE_AJB998_N11) */ -Commented for defect# 43424
        ajb998.ROWID row_id -- Hint added for V1.4
        ,
        dtl.rowid ord_row_id ,
        dtl.cash_receipt_id ,
        hdr.header_id ,
        ajb998.processor_id ,
        dtl.credit_card_code om_card_type ,
        ajb998.bank_rec_id ,
        dtl.order_payment_id ,
        dtl.customer_id
      FROM xx_ce_ajb998 ajb998 ,
        xx_ar_order_receipt_dtl dtl ,
        xx_ce_recon_glact_hdr hdr ,
        fnd_lookup_values lv
      WHERE 1                            = 1
      AND ajb998.org_id                  = gn_org_id
      AND ajb998.status                  = 'PREPROCESSED'
      AND ajb998.ajb_file_name           = NVL(p_ajb_file_name, ajb998.ajb_file_name)
      AND ajb998.provider_type           = 'CREDIT'
      AND SUBSTR(ajb998.attribute21,1,2) = 'OM'
        --            AND TO_CHAR(dtl.order_payment_id) = ajb998.receipt_num    -- commented for V1.4
      AND DTL.ORDER_PAYMENT_ID = TO_NUMBER(AJB998.RECEIPT_NUM) -- added for V1.4
      AND dtl.org_id           = ajb998.org_id
      AND hdr.provider_code    = ajb998.processor_id
      AND hdr.org_id           = ajb998.org_id
      AND dtl.payment_amount   = ajb998.trx_amount
      AND lv.lookup_type       = 'OD_PAYMENT_TYPES'
      AND lv.enabled_flag      = 'Y'
      AND lv.meaning           = dtl.credit_card_code
      AND lv.lookup_code       = hdr.om_card_type
      AND dtl.receipt_date BETWEEN lv.start_date_active    - 0 AND NVL(lv.end_date_active, dtl.receipt_date + 1)
      AND dtl.receipt_date BETWEEN hdr.effective_from_date - 0 AND NVL(hdr.effective_to_date, dtl.receipt_date + 1)
      AND NOT EXISTS
        (SELECT 1
        FROM xx_ce_999_interface
        WHERE bank_rec_id = ajb998.bank_rec_id
        AND processor_id  = ajb998.processor_id
        ) ;--FOR UPDATE; commented for defect# 43424
    /* Cursor for 998 match attempt on receipt number against XX_AR_ORDER_RECEIPT_DTL table for credit non-POS transactions*/
    -- Modified for QC Defect # 13474 - iReceviable receipts not getting CLEARED in xx_ar_order_receipt_dtl table for MASTERCARD
    -- because of mismatch of credit card type value in xx_ar_order_receipt_dtl and OD_PAYMENT_TYPES lookup value
    CURSOR c998_match_rct_ord_cr_non_pos
    IS
      SELECT ajb998.ROWID row_id ,
        dtl.rowid ord_row_id ,
        dtl.cash_receipt_id ,
        hdr.header_id ,
        ajb998.processor_id
        --, dtl.credit_card_code om_card_type -- Commented for QC Defect # 13474
        ,
        DECODE(dtl.credit_card_code, 'MASTERCARD', 'MC', dtl.credit_card_code) om_card_type -- Added for QC Defect # 13474
        ,
        ajb998.bank_rec_id ,
        dtl.order_payment_id ,
        dtl.customer_id
      FROM xx_ce_ajb998 ajb998 ,
        xx_ar_order_receipt_dtl dtl ,
        xx_ce_recon_glact_hdr hdr ,
        fnd_lookup_values lv
      WHERE 1                             = 1
      AND ajb998.org_id                   = gn_org_id
      AND ajb998.status                   = 'PREPROCESSED'
      AND ajb998.ajb_file_name            = NVL(p_ajb_file_name, ajb998.ajb_file_name)
      AND ajb998.provider_type            = 'CREDIT'
      AND SUBSTR(ajb998.attribute21,1,2) != 'OM'
      AND dtl.receipt_number              = ajb998.receipt_num
      AND dtl.org_id                      = ajb998.org_id
      AND hdr.provider_code               = ajb998.processor_id
      AND hdr.org_id                      = ajb998.org_id
      AND dtl.payment_amount              = ajb998.trx_amount
      AND lv.lookup_type                  = 'OD_PAYMENT_TYPES'
      AND lv.enabled_flag                 = 'Y'
        -- AND lv.meaning = dtl.credit_card_code -- Commented for QC Defect # 13474
      AND lv.meaning     = DECODE(dtl.credit_card_code, 'MASTERCARD', 'MC', dtl.credit_card_code) -- Added for QC Defect # 13474
      AND lv.lookup_code = hdr.om_card_type
      AND dtl.receipt_date BETWEEN lv.start_date_active    - 0 AND NVL(lv.end_date_active, dtl.receipt_date + 1)
      AND dtl.receipt_date BETWEEN hdr.effective_from_date - 0 AND NVL(hdr.effective_to_date, dtl.receipt_date + 1)
      AND NOT EXISTS
        (SELECT 1
        FROM xx_ce_999_interface
        WHERE bank_rec_id = ajb998.bank_rec_id
        AND processor_id  = ajb998.processor_id
        ) ; -- FOR UPDATE; commented for defect# 43424
    /* Cursor for 998 match attempt on receipt number against XX_AR_ORDER_RECEIPT_DTL table for non-credit transactions*/
    CURSOR c998_match_rct_ord_non_cr
    IS
      SELECT ajb998.ROWID row_id ,
        dtl.rowid ord_row_id ,
        dtl.cash_receipt_id ,
        hdr.header_id ,
        ajb998.processor_id ,
        dtl.credit_card_code om_card_type ,
        ajb998.bank_rec_id ,
        dtl.order_payment_id ,
        dtl.customer_id
        -- Added for QC Defect # 18476 -- Start
        ,
        ajb998.provider_type ,
        ajb998.store_num ,
        ajb998.card_num ,
        ajb998.trx_type ,
        ajb998.trx_date ,
        ajb998.trx_amount ,
        ajb998.receipt_num
        -- Added for QC Defect # 18476 -- End
      FROM xx_ce_ajb998 ajb998 ,
        xx_ar_order_receipt_dtl dtl ,
        xx_ce_recon_glact_hdr hdr ,
        fnd_lookup_values lv
      WHERE 1                            = 1
      AND ajb998.org_id                  = gn_org_id
      AND ajb998.status                  = 'PREPROCESSED'
      AND ajb998.ajb_file_name           = NVL(p_ajb_file_name, ajb998.ajb_file_name)
      AND ajb998.provider_type          IN ('CHECK', 'DEBIT','PAYPAL') --Defect# 22133
      AND dtl.customer_receipt_reference = ajb998.receipt_num
      AND dtl.org_id                     = ajb998.org_id
      AND dtl.payment_amount             = ajb998.trx_amount
      AND hdr.provider_code              = ajb998.processor_id
      AND hdr.org_id                     = ajb998.org_id
      AND lv.lookup_type                 = 'OD_PAYMENT_TYPES'
      AND lv.enabled_flag                = 'Y'
      AND lv.meaning                     = dtl.credit_card_code
      AND lv.lookup_code                 = hdr.om_card_type
      AND dtl.receipt_date BETWEEN lv.start_date_active    - 0 AND NVL(lv.end_date_active, dtl.receipt_date + 1)
      AND dtl.receipt_date BETWEEN hdr.effective_from_date - 0 AND NVL(hdr.effective_to_date, dtl.receipt_date + 1)
      AND NOT EXISTS
        (SELECT 1
        FROM xx_ce_999_interface
        WHERE bank_rec_id = ajb998.bank_rec_id
        AND processor_id  = ajb998.processor_id
        ) ;--FOR UPDATE; commented for defect# 43424
    /* Cursor for 998 match attempt on receipt number against XX_CE_AJB_RECEIPTS_V view for credit transactions (old E1310)*/
    CURSOR c998_match_rct_ajb_cr
    IS
      SELECT xca8.ROWID row_id ,
        (SELECT cash_receipt_id
        FROM xx_ce_ajb_receipts_v xcarv
        WHERE ROWNUM          = 1
        AND xca8.processor_id = xcarv.provider_code
        AND xca8.org_id       = xcarv.org_id
        AND xca8.trx_date - 0 = xcarv.receipt_date - 0
        AND xca8.receipt_num  = xcarv.receipt_number
        AND ((xcarv.amount    = 0)
        OR (xcarv.amount     != 0
        AND xca8.trx_amount   = xcarv.amount ) )
        ) cash_receipt_id ,
      (SELECT header_id
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM          = 1
      AND xca8.processor_id = xcarv.provider_code
      AND xca8.org_id       = xcarv.org_id
      AND xca8.trx_date - 0 = xcarv.receipt_date - 0
      AND xca8.receipt_num  = xcarv.receipt_number
      AND ((xcarv.amount    = 0)
      OR (xcarv.amount     != 0
      AND xca8.trx_amount   = xcarv.amount ) )
      ) header_id ,
      xca8.processor_id ,
      (SELECT om_card_type_meaning
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM          = 1
      AND xca8.processor_id = xcarv.provider_code
      AND xca8.org_id       = xcarv.org_id
      AND xca8.trx_date - 0 = xcarv.receipt_date - 0
      AND xca8.receipt_num  = xcarv.receipt_number
      AND ((xcarv.amount    = 0)
      OR (xcarv.amount     != 0
      AND xca8.trx_amount   = xcarv.amount ) )
      ) om_card_type ,
      xca8.bank_rec_id ,
      (SELECT pay_from_customer
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM          = 1
      AND xca8.processor_id = xcarv.provider_code
      AND xca8.org_id       = xcarv.org_id
      AND xca8.trx_date - 0 = xcarv.receipt_date - 0
      AND xca8.receipt_num  = xcarv.receipt_number
      AND ((xcarv.amount    = 0)
      OR (xcarv.amount     != 0
      AND xca8.trx_amount   = xcarv.amount ) )
      ) customer_id
    FROM xx_ce_ajb998 xca8
    WHERE 1                   = 1
    AND xca8.org_id           = gn_org_id -- Added for PROD Defect: 2046,1716
    AND xca8.rej_reason_code IS NULL
    AND xca8.status           = 'PREPROCESSED'
    AND xca8.ajb_file_name    = NVL (p_ajb_file_name, xca8.ajb_file_name)
    AND xca8.provider_type    = 'CREDIT'
    AND NOT EXISTS
      (SELECT 1
      FROM xx_ce_999_interface
      WHERE bank_rec_id = xca8.bank_rec_id
      AND processor_id  = xca8.processor_id
      ) ;--FOR UPDATE; commented for defect# 43424
    /* Cursor for 998 match attempt on receipt number against XX_CE_AJB_RECEIPTS_V view for non-credit transactions (old E1310)*/
    CURSOR c998_match_rct_ajb_non_cr
    IS
      SELECT xca8.ROWID row_id ,
        (SELECT cash_receipt_id
        FROM xx_ce_ajb_receipts_v xcarv
        WHERE ROWNUM           = 1
        AND xca8.processor_id  = xcarv.provider_code
        AND xca8.org_id        = xcarv.org_id
        AND xca8.receipt_num   = xcarv.customer_receipt_reference
        AND (xca8.trx_date - 0 = xcarv.receipt_date - 0
        OR xca8.trx_date   - 0 = xcarv.receipt_date + 1)
        AND xcarv.amount      != 0 --Added for Defect 4721 by Jude
        AND xca8.trx_amount    = xcarv.amount
        )cash_receipt_id
      /*AND ((xcarv.amount = 0)  --Commented for Defect 4721 by Jude
      OR (xcarv.amount != 0
      AND xca8.trx_amount = xcarv.amount
      )
      )) cash_receipt_id*/
      ,
      (SELECT header_id
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM           = 1
      AND xca8.processor_id  = xcarv.provider_code
      AND xca8.org_id        = xcarv.org_id
      AND xca8.receipt_num   = xcarv.customer_receipt_reference
      AND (xca8.trx_date - 0 = xcarv.receipt_date - 0
      OR xca8.trx_date   - 0 = xcarv.receipt_date + 1)
      AND xcarv.amount      != 0 --Added for Defect 4721 by Jude
      AND xca8.trx_amount    = xcarv.amount
      ) header_id
      /*AND ((xcarv.amount = 0)  --Commented for Defect 4721 by Jude
      OR (xcarv.amount != 0
      AND xca8.trx_amount = xcarv.amount
      )
      )) header_id*/
      ,
      xca8.processor_id ,
      (SELECT om_card_type_meaning
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM           = 1
      AND xca8.processor_id  = xcarv.provider_code
      AND xca8.org_id        = xcarv.org_id
      AND xca8.receipt_num   = xcarv.customer_receipt_reference
      AND (xca8.trx_date - 0 = xcarv.receipt_date - 0
      OR xca8.trx_date   - 0 = xcarv.receipt_date + 1)
      AND xcarv.amount      != 0 --Added for Defect 4721 by Jude
      AND xca8.trx_amount    = xcarv.amount
      ) om_card_type
      /*AND ((xcarv.amount = 0)  --Commented for Defect 4721 by Jude
      OR (xcarv.amount != 0
      AND xca8.trx_amount = xcarv.amount
      )
      )) ajb_card_type*/
      ,
      xca8.bank_rec_id ,
      (SELECT pay_from_customer
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM           = 1
      AND xca8.processor_id  = xcarv.provider_code
      AND xca8.org_id        = xcarv.org_id
      AND xca8.receipt_num   = xcarv.customer_receipt_reference
      AND (xca8.trx_date - 0 = xcarv.receipt_date - 0
      OR xca8.trx_date   - 0 = xcarv.receipt_date + 1)
      AND xcarv.amount      != 0 --Added for Defect 4721 by Jude
      AND xca8.trx_amount    = xcarv.amount
      ) customer_id
      /*AND ((xcarv.amount = 0)  --Commented for Defect 4721 by Jude
      OR (xcarv.amount != 0
      AND xca8.trx_amount = xcarv.amount
      )
      )) ajb_card_type*/
    FROM xx_ce_ajb998 xca8
    WHERE 1                   = 1
    AND xca8.org_id           = gn_org_id -- Added for PROD Defect: 2046,1716
    AND xca8.status           = 'PREPROCESSED'
    AND xca8.ajb_file_name    = NVL (p_ajb_file_name, xca8.ajb_file_name)
    AND xca8.provider_type   IN ('CHECK', 'DEBIT','PAYPAL') --Defect# 22133
    AND xca8.rej_reason_code IS NULL
    AND NOT EXISTS
      (SELECT 1
      FROM xx_ce_999_interface
      WHERE bank_rec_id = xca8.bank_rec_id
      AND processor_id  = xca8.processor_id
      ) ;--FOR UPDATE; commented for defect# 43424
    /* Cursor for preprocessing 998 data to attempt to match on invoice number against XX_AR_ORDER_RECEIPT_DTL table */
    CURSOR c998_match_inv_ord
    IS
      SELECT ajb998.ROWID row_id ,
        dtl.rowid ord_row_id ,
        dtl.cash_receipt_id ,
        hdr.header_id ,
        ajb998.processor_id ,
        dtl.credit_card_code om_card_type ,
        ajb998.bank_rec_id ,
        dtl.order_payment_id ,
        dtl.customer_id
      FROM xx_ce_ajb998 ajb998 ,
        xx_ar_order_receipt_dtl dtl ,
        xx_ce_recon_glact_hdr hdr ,
        fnd_lookup_values lv
      WHERE 1                            = 1
      AND ajb998.org_id                  = gn_org_id
      AND ajb998.status                  = 'PREPROCESSED'
      AND ajb998.ajb_file_name           = NVL(p_ajb_file_name, ajb998.ajb_file_name)
      AND dtl.customer_receipt_reference = ajb998.invoice_num
      AND dtl.org_id                     = ajb998.org_id
      AND hdr.provider_code              = ajb998.processor_id
      AND hdr.org_id                     = ajb998.org_id
      AND dtl.payment_amount             = ajb998.trx_amount
      AND lv.lookup_type                 = 'OD_PAYMENT_TYPES'
      AND lv.enabled_flag                = 'Y'
      AND lv.meaning                     = dtl.credit_card_code
      AND lv.lookup_code                 = hdr.om_card_type
      AND dtl.receipt_date BETWEEN lv.start_date_active    - 0 AND NVL(lv.end_date_active, dtl.receipt_date + 1)
      AND dtl.receipt_date BETWEEN hdr.effective_from_date - 0 AND NVL(hdr.effective_to_date, dtl.receipt_date + 1)
      AND NOT EXISTS
        (SELECT 1
        FROM xx_ce_999_interface
        WHERE bank_rec_id = ajb998.bank_rec_id
        AND processor_id  = ajb998.processor_id
        )
    UNION ALL /*-- Added for Bizbox and for defect# 43424*/
    SELECT ajb998.ROWID row_id ,
      dtl.rowid ord_row_id ,
      dtl.cash_receipt_id ,
      hdr.header_id ,
      ajb998.processor_id ,
      dtl.credit_card_code om_card_type ,
      ajb998.bank_rec_id ,
      dtl.order_payment_id ,
      dtl.customer_id
    FROM xx_ce_ajb998 ajb998 ,
      xx_ar_order_receipt_dtl dtl ,
      xx_ce_recon_glact_hdr hdr ,
      fnd_lookup_values lv
    WHERE 1                  = 1
    AND ajb998.org_id        = gn_org_id
    AND ajb998.status        = 'PREPROCESSED'
    AND ajb998.ajb_file_name = NVL(p_ajb_file_name, ajb998.ajb_file_name)
    AND dtl.mpl_order_id     = ajb998.invoice_num
    AND dtl.order_source     ='BBOX'
    AND dtl.org_id           = ajb998.org_id
    AND hdr.provider_code    = ajb998.processor_id
    AND hdr.org_id           = ajb998.org_id
    AND dtl.payment_amount   = ajb998.trx_amount
    AND lv.lookup_type       = 'OD_PAYMENT_TYPES'
    AND lv.enabled_flag      = 'Y'
    AND lv.meaning           = dtl.credit_card_code
    AND lv.lookup_code       = hdr.om_card_type
    AND dtl.receipt_date BETWEEN lv.start_date_active    - 0 AND NVL(lv.end_date_active, dtl.receipt_date + 1)
    AND dtl.receipt_date BETWEEN hdr.effective_from_date - 0 AND NVL(hdr.effective_to_date, dtl.receipt_date + 1)
    AND NOT EXISTS
      (SELECT 1
      FROM xx_ce_999_interface
      WHERE bank_rec_id = ajb998.bank_rec_id
      AND processor_id  = ajb998.processor_id
      ) ;--FOR UPDATE; commented for Defect# 43424
    /* Cursor for preprocessing 998 data to attempt to match on invoice number against XX_CE_AJB_RECEIPTS_V view */
    CURSOR c998_match_inv_ajb
    IS
      /* Commented out by NB for IREC TRAN's AUTHCODE whihc come in INVOICE_NUM is TANGABLED ID and NOT TRAN NO OR RCPT NO */
      /*         SELECT     xca6.ROWID row_id
      , (SELECT cash_receipt_id
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM = 1
      AND xca6.processor_id = xcarv.provider_code
      AND xca6.org_id = xcarv.org_id
      AND xca6.trx_date - 0 = xcarv.receipt_date - 0
      AND xca6.invoice_num = xcarv.customer_receipt_reference) cash_receipt_id
      , (SELECT header_id
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM = 1
      AND xca6.processor_id = xcarv.provider_code
      AND xca6.org_id = xcarv.org_id
      AND xca6.trx_date - 0 = xcarv.receipt_date - 0
      AND xca6.invoice_num = xcarv.customer_receipt_reference) header_id
      , xca6.processor_id
      , (SELECT om_card_type_meaning
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM = 1
      AND xca6.processor_id = xcarv.provider_code
      AND xca6.org_id = xcarv.org_id
      AND xca6.trx_date - 0 = xcarv.receipt_date - 0
      AND xca6.invoice_num = xcarv.customer_receipt_reference) om_card_type
      , xca6.bank_rec_id
      , (SELECT pay_from_customer
      FROM xx_ce_ajb_receipts_v xcarv
      WHERE ROWNUM = 1
      AND xca6.processor_id = xcarv.provider_code
      AND xca6.org_id = xcarv.org_id
      AND xca6.trx_date - 0 = xcarv.receipt_date - 0
      AND xca6.invoice_num = xcarv.customer_receipt_reference) customer_id
      FROM xx_ce_ajb998 xca6
      WHERE 1 = 1
      AND xca6.org_id = gn_org_id -- Added for PROD Defect: 2046,1716
      AND xca6.status = 'PREPROCESSED'
      AND xca6.ajb_file_name = NVL (p_ajb_file_name, xca6.ajb_file_name)
      AND NOT EXISTS (
      SELECT 1
      FROM xx_ce_999_interface
      WHERE bank_rec_id = xca6.bank_rec_id
      AND processor_id = xca6.processor_id)
      */
      SELECT xca6.ROWID row_id ,
        (SELECT cash_receipt_id
        FROM xx_ce_ajb_receipts_v xcarv
        WHERE ROWNUM          = 1
        AND xca6.processor_id = xcarv.provider_code
        AND xca6.org_id       = xcarv.org_id
        AND xca6.trx_date - 0 = xcarv.receipt_date - 0
        AND xca6.invoice_num  = xcarv.customer_receipt_reference
      UNION
      SELECT xcarv.cash_receipt_id
      FROM xx_ce_ajb_receipts_v xcarv ,
        ar_cash_receipts_all acr
      WHERE ROWNUM              = 1
      AND xca6.processor_id     = xcarv.provider_code
      AND xca6.org_id           = xcarv.org_id
      AND xca6.trx_date - 0     = xcarv.receipt_date - 0
      AND xca6.invoice_num      = acr.payment_server_order_num
      AND xcarv.cash_receipt_id = acr.cash_receipt_id
        ) cash_receipt_id ,
        (SELECT header_id
        FROM xx_ce_ajb_receipts_v xcarv
        WHERE ROWNUM          = 1
        AND xca6.processor_id = xcarv.provider_code
        AND xca6.org_id       = xcarv.org_id
        AND xca6.trx_date - 0 = xcarv.receipt_date - 0
        AND xca6.invoice_num  = xcarv.customer_receipt_reference
        UNION
        SELECT header_id
        FROM xx_ce_ajb_receipts_v xcarv ,
          ar_cash_receipts_all acr
        WHERE ROWNUM              = 1
        AND xca6.processor_id     = xcarv.provider_code
        AND xca6.org_id           = xcarv.org_id
        AND xca6.trx_date - 0     = xcarv.receipt_date - 0
        AND xca6.invoice_num      = acr.payment_server_order_num
        AND xcarv.cash_receipt_id = acr.cash_receipt_id
        ) header_id ,
        xca6.processor_id processor_id ,
        (SELECT om_card_type_meaning
        FROM xx_ce_ajb_receipts_v xcarv
        WHERE ROWNUM          = 1
        AND xca6.processor_id = xcarv.provider_code
        AND xca6.org_id       = xcarv.org_id
        AND xca6.trx_date - 0 = xcarv.receipt_date - 0
        AND xca6.invoice_num  = xcarv.customer_receipt_reference
        UNION
        SELECT om_card_type_meaning
        FROM xx_ce_ajb_receipts_v xcarv ,
          ar_cash_receipts_all acr
        WHERE ROWNUM              = 1
        AND xca6.processor_id     = xcarv.provider_code
        AND xca6.org_id           = xcarv.org_id
        AND xca6.trx_date - 0     = xcarv.receipt_date - 0
        AND xca6.invoice_num      = acr.payment_server_order_num
        AND xcarv.cash_receipt_id = acr.cash_receipt_id
        ) om_card_type ,
        xca6.bank_rec_id bank_rec_id ,
        (SELECT pay_from_customer
        FROM xx_ce_ajb_receipts_v xcarv
        WHERE ROWNUM          = 1
        AND xca6.processor_id = xcarv.provider_code
        AND xca6.org_id       = xcarv.org_id
        AND xca6.trx_date - 0 = xcarv.receipt_date - 0
        AND xca6.invoice_num  = xcarv.customer_receipt_reference
        UNION
        SELECT xcarv.pay_from_customer
        FROM xx_ce_ajb_receipts_v xcarv ,
          ar_cash_receipts_all acr
        WHERE ROWNUM              = 1
        AND xca6.processor_id     = xcarv.provider_code
        AND xca6.org_id           = xcarv.org_id
        AND xca6.trx_date - 0     = xcarv.receipt_date - 0
        AND xca6.invoice_num      = acr.payment_server_order_num
        AND xcarv.cash_receipt_id = acr.cash_receipt_id
        ) customer_id
      FROM xx_ce_ajb998 xca6
      WHERE 1                = 1
      AND xca6.org_id        = gn_org_id
      AND xca6.status        = 'PREPROCESSED'
      AND xca6.ajb_file_name = NVL (p_ajb_file_name, xca6.ajb_file_name)
      AND NOT EXISTS
        (SELECT 1
        FROM xx_ce_999_interface
        WHERE bank_rec_id = xca6.bank_rec_id
        AND processor_id  = xca6.processor_id
        ) ;--FOR UPDATE; --commented for Defect# 43424
      /* Cursor for preprocessing 999 country/org */
      CURSOR c999_org
      IS
        SELECT DISTINCT country_code
        FROM xx_ce_ajb999
        WHERE status      = 'PREPROCESSING'
        AND country_code IS NOT NULL
        AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name);
      --AND org_id = gn_org_id; -- Added for PROD Defect: 2046,1716
      /* Cursor for preprocessing 999 currency */
      CURSOR c999_currency
      IS
        SELECT DISTINCT currency_code
        FROM xx_ce_ajb999
        WHERE status       = 'PREPROCESSING'
        AND currency_code IS NOT NULL
        AND ajb_file_name  = NVL (p_ajb_file_name, ajb_file_name)
        AND org_id         = gn_org_id; -- Added for PROD Defect: 2046,1716
      /* Cursor for preprocessing 999 bank_rec_id */
      CURSOR c999_bank
      IS
        SELECT DISTINCT bank_rec_id
        FROM xx_ce_ajb999
        WHERE status      = 'PREPROCESSING'
        AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name)
        AND org_id        = gn_org_id; -- Added for PROD Defect: 2046,1716
      /* Cursor for preprocessing unknown 999 cardtypes. */
      CURSOR c999_no_cardtype
      IS
        SELECT ROWID row_id,
          processor_id
        FROM xx_ce_ajb999
        WHERE org_id      = gn_org_id -- Added for PROD Defect: 2046,1716
        AND status        = 'PREPROCESSING'
        AND cardtype NOT IN
          (SELECT DISTINCT ajb_card_type FROM xx_ce_recon_glact_hdr
          );
      lc_default_cardtype xx_ce_recon_glact_hdr.ajb_card_type%TYPE;
      /* Cursor for 998 match attempt on receipt number against XX_AR_ORDER_RECEIPT_DTL table for Zero Dollar Receipts - QC Defect # 13263*/
      CURSOR c998_match_zero_dollar_rcpt
      IS
        SELECT --/*+ INDEX(AJB998 XX_CE_AJB998_N11) */ commented for Defect# 43424
          ajb998.ROWID row_id ,
          dtl.rowid ord_row_id ,
          dtl.cash_receipt_id ,
          hdr.header_id ,
          ajb998.processor_id ,
          dtl.credit_card_code om_card_type ,
          ajb998.bank_rec_id ,
          dtl.order_payment_id ,
          dtl.customer_id
        FROM xx_ce_ajb998 ajb998 ,
          xx_ar_order_receipt_dtl dtl ,
          xx_ce_recon_glact_hdr hdr ,
          fnd_lookup_values lv
        WHERE 1                  = 1
        AND ajb998.org_id        = gn_org_id
        AND ajb998.status        = 'PREPROCESSED'
        AND ajb998.ajb_file_name = NVL(p_ajb_file_name, ajb998.ajb_file_name)
        AND ajb998.provider_type = 'CREDIT'
        AND ajb998.trx_type      = 'REFUND'
        AND dtl.receipt_number   = ajb998.receipt_num
        AND dtl.org_id           = ajb998.org_id
        AND hdr.provider_code    = ajb998.processor_id
        AND hdr.org_id           = ajb998.org_id
        AND dtl.payment_amount   = 0 -- Zero Dollar Receipt in ORDT
        AND lv.lookup_type       = 'OD_PAYMENT_TYPES'
        AND lv.enabled_flag      = 'Y'
        AND lv.meaning           = dtl.credit_card_code
        AND lv.lookup_code       = hdr.om_card_type
        AND dtl.receipt_date BETWEEN lv.start_date_active    - 0 AND NVL(lv.end_date_active, dtl.receipt_date + 1)
        AND dtl.receipt_date BETWEEN hdr.effective_from_date - 0 AND NVL(hdr.effective_to_date, dtl.receipt_date + 1)
        AND NOT EXISTS
          (SELECT 1
          FROM xx_ce_999_interface
          WHERE bank_rec_id = ajb998.bank_rec_id
          AND processor_id  = ajb998.processor_id
          ) ;-- FOR UPDATE; commented for Defect# 43424
      -- Added for the defect 33471 Start
      CURSOR ajb_cur(cp_receipt_num VARCHAR2,cp_trx_amt NUMBER)
      IS
        SELECT DISTINCT AJB998.ROWID ROW_ID,
          AJB998.SEQUENCE_ID_998 ,
          AJB998.TRX_AMOUNT ,
          hdr.header_id ,
          dtl.credit_card_code om_card_type
        FROM xx_ce_ajb998 ajb998 ,
          xx_ar_order_receipt_dtl dtl ,
          xx_ce_recon_glact_hdr hdr ,
          fnd_lookup_values lv
        WHERE 1                            = 1
        AND AJB998.ORG_ID                  = gn_org_id
        AND AJB998.STATUS                  = 'PREPROCESSED'
        AND ajb998.ajb_file_name           = NVL(p_ajb_file_name, ajb998.ajb_file_name)
        AND AJB998.PROVIDER_TYPE          IN ('CHECK', 'DEBIT','PAYPAL')
        AND DTL.CUSTOMER_RECEIPT_REFERENCE = AJB998.RECEIPT_NUM
        AND AJB998.RECEIPT_NUM             = cp_receipt_num
        AND dtl.org_id                     = ajb998.org_id
        AND DTL.PAYMENT_AMOUNT             = AJB998.TRX_AMOUNT
        AND AJB998.TRX_AMOUNT              = cp_trx_amt
        AND hdr.provider_code              = ajb998.processor_id
        AND hdr.org_id                     = ajb998.org_id
        AND lv.lookup_type                 = 'OD_PAYMENT_TYPES'
        AND lv.enabled_flag                = 'Y'
        AND lv.meaning                     = dtl.credit_card_code
        AND lv.lookup_code                 = hdr.om_card_type
        AND DTL.RECEIPT_DATE BETWEEN LV.START_DATE_ACTIVE    - 0 AND NVL(LV.END_DATE_ACTIVE, DTL.RECEIPT_DATE + 1)
        AND DTL.RECEIPT_DATE BETWEEN HDR.EFFECTIVE_FROM_DATE - 0 AND NVL(HDR.EFFECTIVE_TO_DATE, DTL.RECEIPT_DATE + 1)
        ORDER BY AJB998.SEQUENCE_ID_998 DESC;
      --Added below cursor for V2.8
      CURSOR cr_998_bank_Rec_prov_type(p_cur_ajb_file xx_ce_ajb998.ajb_file_name%type, p_cur_org_id xx_ce_ajb998.org_id%type )
      IS
        SELECT DISTINCT provider_type,
          vals.target_value1 provider_short_name
        FROM xx_ce_ajb998 ajb998 ,
          xx_fin_translatevalues vals,
          xx_fin_translatedefinition defn
        WHERE status              = 'PREPROCESSING'
        AND org_id                = p_cur_org_id 
        AND ajb_file_name         = NVL (p_cur_ajb_file, ajb_file_name)
        AND defn.translate_id     = vals.translate_id
        AND defn.translation_name = 'OD_CE_BANK_REC_PROV_TYPE'
        AND vals.source_value1    =provider_type
        AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
        AND SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
        AND vals.enabled_flag = 'Y'
        AND defn.enabled_flag = 'Y';
      CURSOR cr_999_bank_Rec_prov_type(p_cur_ajb_file xx_ce_ajb999.ajb_file_name%type, p_cur_org_id xx_ce_ajb999.org_id%type )
      IS
        SELECT DISTINCT provider_type,
          vals.target_value1 provider_short_name
        FROM xx_ce_ajb999 ajb999 ,
          xx_fin_translatevalues vals,
          xx_fin_translatedefinition defn
        WHERE status              = 'PREPROCESSING'
        AND org_id                = p_cur_org_id -- Added for PROD Defect: 2046,1716
        AND ajb_file_name         = NVL (p_cur_ajb_file, ajb_file_name)
        AND defn.translate_id     = vals.translate_id
        AND defn.translation_name = 'OD_CE_BANK_REC_PROV_TYPE'
        AND vals.source_value1    =provider_type
        AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
        AND SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
        AND vals.enabled_flag = 'Y'
        AND defn.enabled_flag = 'Y';
      l_ord_pmt_id    NUMBER;
      l_cash_rcpt_id  NUMBER;
      l_om_card_type  VARCHAR2(100);
      l_pmt_count     NUMBER;
      l_exc_location  VARCHAR2(2000);
      l_exc_location2 VARCHAR2(2000);
    TYPE ordt_type
  IS
    TABLE OF NUMBER INDEX BY PLS_INTEGER;
    l_ordt_type ordt_type;
    XX_CE_AJB998_EX  EXCEPTION;
    XX_CE_AJB998_EX2 EXCEPTION;
    -- Added for the defect 33471  End
  BEGIN
    fnd_file.put_line (fnd_file.LOG,'Starting xx_ce_ajb_preprocess at ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    fnd_file.put_line (fnd_file.LOG, ' ');
    fnd_file.put_line (fnd_file.LOG, LPAD ('-', 100, '-'));
    /* Update all status */
    UPDATE xx_ce_ajb996
    SET status         = 'PREPROCESSING' ,
      last_update_date = SYSDATE ,
      last_updated_by  = gn_user_id
    WHERE status       ='NEW' --status IS NULL --modified for defect# 43424 v2.7.1
      -- AND org_id = gn_org_id -- Added for PROD Defect: 2046,1716
    AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name);
    /* Process the 996 p_file_type */
    IF NVL (UPPER (p_file_type), 'ALL') IN ('996', 'ALL') THEN
      fnd_file.put_line (fnd_file.LOG, 'Preprocessing 996 data...');
      /* Logic from xx_ce_ajb996_t and xx_ce_ajb996_v on xx_ce_ajb996 */
      /* Only open the c996_org if it is not already open */
      IF c996_org%ISOPEN THEN
        NULL;
      ELSE
        OPEN c996_org;
        fnd_file.put_line (fnd_file.LOG, 'Preprocessing 996 country/orgs.');
      END IF;
      LOOP
        /* Populate variables using cursor fetch.  No point using bulk collect as < 5 */
        FETCH c996_org
        INTO v_country_code;
        /* Keep fetching until no more records are found */
        EXIT
      WHEN NOT c996_org%FOUND;
        BEGIN
          /* Lookup the org_id for the country */
          SELECT xx_fin_country_defaults_pkg.f_org_id (territory_code) ,
            territory_code
          INTO v_org_id ,
            v_territory_code
          FROM fnd_territories
          WHERE iso_numeric_code = v_country_code;
        EXCEPTION
        WHEN OTHERS THEN
          v_org_id := NULL;
        END;
        fnd_file.put_line (fnd_file.LOG , '  Updating 996 country_code values of ' || v_country_code || ' with org_id of ' || v_org_id || ' and territory_code of ' || v_territory_code || '.' );
        /* Update org_id, territory_code */
        UPDATE xx_ce_ajb996
        SET org_id         = v_org_id ,
          territory_code   = v_territory_code ,
          last_update_date = SYSDATE ,
          last_updated_by  = gn_user_id
        WHERE status       = 'PREPROCESSING'
        AND country_code   = v_country_code;
      END LOOP;
      CLOSE c996_org;
      fnd_file.put_line(fnd_file.LOG,'Finished preprocessing 996 country/orgs.');
      fnd_file.put_line(fnd_file.LOG,'Updating 996 bank_rec_id values with -XX provider_type.');
      /* Update bank_rec_id */
      UPDATE xx_ce_ajb996
      SET bank_rec_id = bank_rec_id
        || '-'
        || SUBSTR (provider_type, 1, 2)
        ||DECODE(SUBSTR(AJB_FILE_NAME,7,9),'PayPalWEB','W','PayPalPOS','P',NULL)
        || '-'
        || territory_code ,
        last_update_date = SYSDATE ,
        last_updated_by  = gn_user_id
      WHERE status       = 'PREPROCESSING'
      AND org_id         = gn_org_id -- Added for PROD Defect: 2046,1716
      AND ajb_file_name  = NVL (p_ajb_file_name, ajb_file_name);
      fnd_file.put_line(fnd_file.LOG,'Finished preprocessing 996 bank_rec_id values with -XX provider_type.');
      /* Only open the c996_currency if it is not already open */
      IF c996_currency%ISOPEN THEN
        NULL;
      ELSE
        OPEN c996_currency;
        fnd_file.put_line (fnd_file.LOG, 'Preprocessing 996 currencies.');
      END IF;
      LOOP
        /* Populate variables using cursor fetch.  No point using bulk collect as < 5 */
        FETCH c996_currency
        INTO v_currency_code;
        /* Keep fetching until no more records are found */
        EXIT
      WHEN NOT c996_currency%FOUND;
        BEGIN
          /* Lookup the currency for the country */
          SELECT currency_code
          INTO v_currency
          FROM fnd_currencies
          WHERE attribute1 = v_currency_code;
        EXCEPTION
        WHEN OTHERS THEN
          v_currency := NULL;
        END;
        fnd_file.put_line (fnd_file.LOG , '  Updating 996 currency_code values of ' || v_currency_code || ' with currency of ' || v_currency || '.' );
        /* Update currency */
        UPDATE xx_ce_ajb996
        SET currency       = v_currency ,
          last_update_date = SYSDATE ,
          last_updated_by  = gn_user_id
        WHERE status       = 'PREPROCESSING'
        AND currency_code  = v_currency_code;
      END LOOP;
      CLOSE c996_currency;
      fnd_file.put_line (fnd_file.LOG,'Finished preprocessing 996 currencies.');
      /* Only open the c996_bank if it is not already open */
      IF c996_bank%ISOPEN THEN
        NULL;
      ELSE
        OPEN c996_bank;
        fnd_file.put_line (fnd_file.LOG, 'Preprocessing 996 bank_rec_ids.');
      END IF;
      LOOP
        /* Populate variables using cursor fetch */
        FETCH c996_bank
        INTO v_bank_rec_id;
        /* Keep fetching until no more records are found */
        EXIT
      WHEN NOT c996_bank%FOUND;
        BEGIN
          v_recon_date := get_recon_date (v_bank_rec_id);
        EXCEPTION
        WHEN OTHERS THEN
          BEGIN
            v_recon_date := TO_DATE (SUBSTR (v_bank_rec_id, 1, 8), 'YYYYMMDD');
          EXCEPTION
          WHEN OTHERS THEN
            v_recon_date := TRUNC (SYSDATE);
          END;
        END;
        fnd_file.put_line (fnd_file.LOG,'  Updating 996 bank_rec_id values of ' || v_bank_rec_id || ' with recon_date of ' || v_recon_date || '.');
        /* Update recon_date */
        UPDATE xx_ce_ajb996
        SET recon_date     = v_recon_date ,
          last_update_date = SYSDATE ,
          last_updated_by  = gn_user_id
        WHERE status       = 'PREPROCESSING'
        AND bank_rec_id    = v_bank_rec_id;
      END LOOP;
      CLOSE c996_bank;
      fnd_file.put_line (fnd_file.LOG,'  Updating 996 NULL recon_date values with ' || TRUNC (SYSDATE) || '.');
      /* Update recon date */
      UPDATE xx_ce_ajb996
      SET recon_date     = TRUNC (SYSDATE) ,
        last_update_date = SYSDATE ,
        last_updated_by  = gn_user_id
      WHERE status       = 'PREPROCESSING'
      AND org_id         = gn_org_id -- Added for PROD Defect: 2046,1716
      AND recon_date    IS NULL;
      fnd_file.put_line (fnd_file.LOG,'Finished preprocessing 996 bank_rec_ids.');
      fnd_file.put_line (fnd_file.LOG, 'Preprocessing 996 receipt_nums.');
      /* Update attribute21, receipt_num */
      UPDATE xx_ce_ajb996
      SET attribute21 = receipt_num ,
        receipt_num   =
        CASE
          WHEN SUBSTR(receipt_num,1,2) = 'OM'
          THEN SUBSTR(receipt_num,INSTR(receipt_num,'#',-1,1) +1) -- for POS trans, use 3rd segment (order payment id)
          WHEN SUBSTR(receipt_num,1,2) != 'OM'
          THEN SUBSTR(receipt_num
            || '#',1,INSTR(receipt_num
            || '#','#') -1) -- for all other trans, user 1st segment (AR receipt number)
        END ,
        last_update_date = SYSDATE ,
        last_updated_by  = gn_user_id
      WHERE status       = 'PREPROCESSING'
      AND org_id         = gn_org_id -- Added for PROD Defect: 2046,1716
      AND provider_type  = 'CREDIT'
      AND receipt_num   IS NOT NULL;
      fnd_file.put_line (fnd_file.LOG,'Finished preprocessing 996 country/orgs.');
      fnd_file.put_line (fnd_file.LOG,'Updating status of all 996 preprocessed records.');
      /* Update status */
      UPDATE xx_ce_ajb996
      SET status         = 'PREPROCESSED' ,
        last_update_date = SYSDATE ,
        last_updated_by  = gn_user_id
      WHERE status       = 'PREPROCESSING'
      AND org_id         = gn_org_id                             -- Added for PROD Defect: 2046,1716
      AND ajb_file_name  = NVL (p_ajb_file_name, ajb_file_name); --Added for QC 38437
      fnd_file.put_line(fnd_file.LOG,'Finished updating status of all 996 preprocessed records.');
      fnd_file.put_line (fnd_file.LOG, '996 data preprocessed!');
      /* End of logic from xx_ce_ajb996_t and xx_ce_ajb996_v on xx_ce_ajb996, commit */
      COMMIT;
      --Begin match attempts for 996 records
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,'c996_match_inv_ord START - 996 Match Attempt for invoice number against XX_AR_ORDER_RECEIPT_DTL.');
        c99x_data      := c99x_null;
        v_rows_updated := 0;
        OPEN c996_match_inv_ord;
        LOOP
          FETCH c996_match_inv_ord BULK COLLECT INTO c99x_data LIMIT p_batch_size;
          EXIT
        WHEN c99x_data.COUNT = 0;
          FOR idx IN c99x_data.FIRST .. c99x_data.LAST
          LOOP
            IF c99x_data (idx).cash_receipt_id IS NOT NULL
              --Defect 10048
              AND c99x_data (idx).header_id IS NOT NULL THEN
              UPDATE xx_ce_ajb996
              SET status           = 'MATCHED_AR' ,
                order_payment_id   = c99x_data (idx).order_payment_id ,
                ar_cash_receipt_id = c99x_data (idx).cash_receipt_id ,
                recon_header_id    = c99x_data (idx).header_id ,
                customer_id        = c99x_data (idx).customer_id ,
                card_type          = c99x_data (idx).om_card_type ,
                last_update_date   = SYSDATE ,
                last_updated_by    = gn_user_id
              WHERE ROWID          = c99x_data (idx).x99x_rowid;
              v_rows_updated      := v_rows_updated + SQL%ROWCOUNT;
              -- Split the Batch for NABCRD.
              -- Check if it was already split in an earlier run.
              IF c99x_data (idx).processor_id = 'NABCRD' AND SUBSTR (c99x_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR (c99x_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb996
                SET bank_rec_id = bank_rec_id
                  || '-'
                  || NVL(SUBSTR(c99x_data (idx).om_card_type,1,1),'V') ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = c99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, end of bank_rec_id NE -cardtype for 996 rowid ' || c99x_data (idx).x99x_rowid);
              END IF; -- If NABCRD
            ELSE
              IF c99x_data (idx).processor_id = 'NABCRD'
                --- Added for defect 14688
                AND SUBSTR (c99x_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR(c99x_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb996
                SET status         = 'NOTMATCHED' ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = c99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, cash_receipt_id or header_id is null, end of bank_rec_id NE -cardtype for 996 rowid ' || c99x_data (idx).x99x_rowid);
              END IF; --NABCRD
            END IF;   -- Cash_receipt_id is not null
          END LOOP;   -- 99x_data loop
        END LOOP;
        COMMIT;
        CLOSE c996_match_inv_ord;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 996 table updated to MATCHED_AR');
        fnd_file.put_line (fnd_file.LOG,'c996_match_inv_ord END   - 996 Match Attempt for invoice number against XX_AR_ORDER_RECEIPT_DTL.');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END;
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,'c996_match_inv_ajb START - 996 Match Attempt for invoice number against XX_CE_AJB_RECEIPTS_V view.');
        all_99x_data   := all_99x_null;
        v_rows_updated := 0;
        OPEN c996_match_inv_ajb;
        LOOP
          FETCH c996_match_inv_ajb BULK COLLECT INTO all_99x_data LIMIT p_batch_size;
          EXIT
        WHEN all_99x_data.COUNT = 0;
          FOR idx IN all_99x_data.FIRST .. all_99x_data.LAST
          LOOP
            -- If matching AR record and Recon Setup is found
            IF all_99x_data (idx).cash_receipt_id IS NOT NULL
              --Defect 10048
              AND all_99x_data (idx).header_id IS NOT NULL THEN
              UPDATE xx_ce_ajb996
              SET status           = 'MATCHED_AR' ,
                ar_cash_receipt_id = all_99x_data (idx).cash_receipt_id ,
                recon_header_id    = all_99x_data (idx).header_id ,
                customer_id        = all_99x_data (idx).customer_id ,
                card_type          = all_99x_data (idx).om_card_type ,
                last_update_date   = SYSDATE ,
                last_updated_by    = gn_user_id
              WHERE ROWID          = all_99x_data (idx).x99x_rowid;
              v_rows_updated      := v_rows_updated + SQL%ROWCOUNT;
              -- Split the Batch for NABCRD.
              -- Check if it was already split in an earlier run.
              IF all_99x_data (idx).processor_id = 'NABCRD' AND SUBSTR (all_99x_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR (all_99x_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb996
                SET bank_rec_id = bank_rec_id
                  || '-'
                  || NVL(SUBSTR(all_99x_data (idx).om_card_type,1,1),'V') ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = all_99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, end of bank_rec_id NE -cardtype for 996 rowid ' || all_99x_data (idx).x99x_rowid);
              END IF; -- If NABCRD
            ELSE
              IF all_99x_data (idx).processor_id = 'NABCRD'
                --- Added for defect 14688
                AND SUBSTR (all_99x_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR(all_99x_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb996
                SET status         = 'NOTMATCHED' ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = all_99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, cash_receipt_id or header_id is null, end of bank_rec_id NE -cardtype for 996 rowid ' || all_99x_data (idx).x99x_rowid);
              END IF; --NABCRD
            END IF;   -- Cash_receipt_id is not null
          END LOOP;   -- 99x_data loop
        END LOOP;
        COMMIT;
        CLOSE c996_match_inv_ajb;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 996 table updated to MATCHED_AR');
        fnd_file.put_line (fnd_file.LOG,'c996_match_inv_ajb END   - 996 Match Attempt for invoice number against XX_CE_AJB_RECEIPTS_V view.');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END;
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,'c996_match_rct_ord_cr_pos START - 996 Match Attempt for receipt num against XX_AR_ORDER_RECEIPT_DTL for credit POS transactions.');
        c99x_data      := c99x_null;
        v_rows_updated := 0;
        OPEN c996_match_rct_ord_cr_pos;
        LOOP
          FETCH c996_match_rct_ord_cr_pos BULK COLLECT
          INTO c99x_data LIMIT p_batch_size;
          EXIT
        WHEN c99x_data.COUNT = 0;
          FOR idx IN c99x_data.FIRST .. c99x_data.LAST
          LOOP
            IF c99x_data (idx).cash_receipt_id IS NOT NULL
              --Defect 10048
              AND c99x_data (idx).header_id IS NOT NULL THEN
              UPDATE xx_ce_ajb996
              SET status           = 'MATCHED_AR' ,
                order_payment_id   = c99x_data (idx).order_payment_id ,
                ar_cash_receipt_id = c99x_data (idx).cash_receipt_id ,
                recon_header_id    = c99x_data (idx).header_id ,
                customer_id        = c99x_data (idx).customer_id ,
                card_type          = c99x_data (idx).om_card_type ,
                last_update_date   = SYSDATE ,
                last_updated_by    = gn_user_id
              WHERE ROWID          = c99x_data (idx).x99x_rowid;
              v_rows_updated      := v_rows_updated + SQL%ROWCOUNT;
              -- Split the Batch for NABCRD.
              -- Check if it was already split in an earlier run.
              IF c99x_data (idx).processor_id = 'NABCRD' AND SUBSTR (c99x_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR (c99x_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb996
                SET bank_rec_id = bank_rec_id
                  || '-'
                  || NVL(SUBSTR(c99x_data (idx).om_card_type,1,1),'V') ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = c99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, end of bank_rec_id NE -cardtype for 996 rowid ' || c99x_data (idx).x99x_rowid);
              END IF; -- If NABCRD
            ELSE
              IF c99x_data (idx).processor_id = 'NABCRD'
                --- Added for defect 14688
                AND SUBSTR (c99x_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR(c99x_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb996
                SET status         = 'NOTMATCHED' ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = c99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, cash_receipt_id or header_id is null, end of bank_rec_id NE -cardtype for 996 rowid ' || c99x_data (idx).x99x_rowid);
              END IF; --NABCRD
            END IF;   -- Cash_receipt_id is not null
          END LOOP;   -- 99x_data loop
        END LOOP;
        COMMIT;
        CLOSE c996_match_rct_ord_cr_pos;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 996 table updated to MATCHED_AR');
        fnd_file.put_line (fnd_file.LOG,'c996_match_rct_ord_cr_pos END   - 996 Match Attempt for receipt num against XX_AR_ORDER_RECEIPT_DTL for credit POS transactions.');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END;
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,'c996_match_rct_ord_cr_non_pos START - 996 Match Attempt receipt num against XX_AR_ORDER_RECEIPT_DTL for credit non-POS transactions.');
        c99x_data      := c99x_null;
        v_rows_updated := 0;
        OPEN c996_match_rct_ord_cr_non_pos;
        LOOP
          FETCH c996_match_rct_ord_cr_non_pos BULK COLLECT
          INTO c99x_data LIMIT p_batch_size;
          EXIT
        WHEN c99x_data.COUNT = 0;
          FOR idx IN c99x_data.FIRST .. c99x_data.LAST
          LOOP
            IF c99x_data (idx).cash_receipt_id IS NOT NULL
              --Defect 10048
              AND c99x_data (idx).header_id IS NOT NULL THEN
              UPDATE xx_ce_ajb996
              SET status           = 'MATCHED_AR' ,
                order_payment_id   = c99x_data (idx).order_payment_id ,
                ar_cash_receipt_id = c99x_data (idx).cash_receipt_id ,
                recon_header_id    = c99x_data (idx).header_id ,
                customer_id        = c99x_data (idx).customer_id ,
                card_type          = c99x_data (idx).om_card_type ,
                last_update_date   = SYSDATE ,
                last_updated_by    = gn_user_id
              WHERE ROWID          = c99x_data (idx).x99x_rowid;
              v_rows_updated      := v_rows_updated + SQL%ROWCOUNT;
              -- Split the Batch for NABCRD.
              -- Check if it was already split in an earlier run.
              IF c99x_data (idx).processor_id = 'NABCRD' AND SUBSTR (c99x_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR (c99x_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb996
                SET bank_rec_id = bank_rec_id
                  || '-'
                  || NVL(SUBSTR(c99x_data (idx).om_card_type,1,1),'V') ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = c99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, end of bank_rec_id NE -cardtype for 996 rowid ' || c99x_data (idx).x99x_rowid);
              END IF; -- If NABCRD
            ELSE
              IF c99x_data (idx).processor_id = 'NABCRD'
                --- Added for defect 14688
                AND SUBSTR (c99x_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR(c99x_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb996
                SET status         = 'NOTMATCHED' ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = c99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, cash_receipt_id or header_id is null, end of bank_rec_id NE -cardtype for 996 rowid ' || c99x_data (idx).x99x_rowid);
              END IF; --NABCRD
            END IF;   -- Cash_receipt_id is not null
          END LOOP;   -- 99x_data loop
        END LOOP;
        COMMIT;
        CLOSE c996_match_rct_ord_cr_non_pos;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 996 table updated to MATCHED_AR');
        fnd_file.put_line (fnd_file.LOG,'c996_match_rct_ord_cr_non_pos END   - 996 Match Attempt receipt num against XX_AR_ORDER_RECEIPT_DTL for credit non-POS transactions.');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END;
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,'c996_match_rct_ord_non_cr START - 996 Match Attempt receipt num against XX_AR_ORDER_RECEIPT_DTL for non-credit transactions.');
        c99x_data      := c99x_null;
        v_rows_updated := 0;
        OPEN c996_match_rct_ord_non_cr;
        LOOP
          FETCH c996_match_rct_ord_non_cr BULK COLLECT
          INTO c99x_data LIMIT p_batch_size;
          EXIT
        WHEN c99x_data.COUNT = 0;
          FOR idx IN c99x_data.FIRST .. c99x_data.LAST
          LOOP
            IF c99x_data (idx).cash_receipt_id IS NOT NULL
              --Defect 10048
              AND c99x_data (idx).header_id IS NOT NULL THEN
              UPDATE xx_ce_ajb996
              SET status           = 'MATCHED_AR' ,
                order_payment_id   = c99x_data (idx).order_payment_id ,
                ar_cash_receipt_id = c99x_data (idx).cash_receipt_id ,
                recon_header_id    = c99x_data (idx).header_id ,
                customer_id        = c99x_data (idx).customer_id ,
                card_type          = c99x_data (idx).om_card_type ,
                last_update_date   = SYSDATE ,
                last_updated_by    = gn_user_id
              WHERE ROWID          = c99x_data (idx).x99x_rowid;
              v_rows_updated      := v_rows_updated + SQL%ROWCOUNT;
              -- Split the Batch for NABCRD.
              -- Check if it was already split in an earlier run.
              IF c99x_data (idx).processor_id = 'NABCRD' AND SUBSTR (c99x_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR (c99x_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb996
                SET bank_rec_id = bank_rec_id
                  || '-'
                  || NVL(SUBSTR(c99x_data (idx).om_card_type,1,1),'V') ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = c99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, end of bank_rec_id NE -cardtype for 996 rowid ' || c99x_data (idx).x99x_rowid);
              END IF; -- If NABCRD
            ELSE
              IF c99x_data (idx).processor_id = 'NABCRD'
                --- Added for defect 14688
                AND SUBSTR (c99x_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR(c99x_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb996
                SET status         = 'NOTMATCHED' ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = c99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, cash_receipt_id or header_id is null, end of bank_rec_id NE -cardtype for 996 rowid ' || c99x_data (idx).x99x_rowid);
              END IF; --NABCRD
            END IF;   -- Cash_receipt_id is not null
          END LOOP;   -- 99x_data loop
        END LOOP;
        COMMIT;
        CLOSE c996_match_rct_ord_non_cr;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 996 table updated to MATCHED_AR');
        fnd_file.put_line (fnd_file.LOG,'c996_match_rct_ord_non_cr END   - 996 Match Attempt receipt num against XX_AR_ORDER_RECEIPT_DTL for non-credit transactions.');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END;
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line(fnd_file.LOG,'c996_match_rct_ajb_cr START - 996 Match Attempt receipt num against XX_CE_AJB_RECEIPTS_V view for credit transactions ( old E1310).');
        all_99x_data   := all_99x_null;
        v_rows_updated := 0;
        OPEN c996_match_rct_ajb_cr;
        LOOP
          FETCH c996_match_rct_ajb_cr BULK COLLECT INTO all_99x_data LIMIT p_batch_size;
          EXIT
        WHEN all_99x_data.COUNT = 0;
          FOR idx IN all_99x_data.FIRST .. all_99x_data.LAST
          LOOP
            -- If matching AR record and Recon Setup is found
            IF all_99x_data (idx).cash_receipt_id IS NOT NULL
              --Defect 10048
              AND all_99x_data (idx).header_id IS NOT NULL THEN
              UPDATE xx_ce_ajb996
              SET status           = 'MATCHED_AR' ,
                ar_cash_receipt_id = all_99x_data (idx).cash_receipt_id ,
                recon_header_id    = all_99x_data (idx).header_id ,
                customer_id        = all_99x_data (idx).customer_id ,
                card_type          = all_99x_data (idx).om_card_type ,
                last_update_date   = SYSDATE ,
                last_updated_by    = gn_user_id
              WHERE ROWID          = all_99x_data (idx).x99x_rowid;
              v_rows_updated      := v_rows_updated + SQL%ROWCOUNT;
              -- Split the Batch for NABCRD.
              -- Check if it was already split in an earlier run.
              IF all_99x_data (idx).processor_id = 'NABCRD' AND SUBSTR (all_99x_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR (all_99x_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb996
                SET bank_rec_id = bank_rec_id
                  || '-'
                  || NVL(SUBSTR(all_99x_data (idx).om_card_type,1,1),'V') ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = all_99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, end of bank_rec_id NE -cardtype for 996 rowid ' || all_99x_data (idx).x99x_rowid);
              END IF; -- If NABCRD
            ELSE
              IF all_99x_data (idx).processor_id = 'NABCRD'
                --- Added for defect 14688
                AND SUBSTR (all_99x_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR(all_99x_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb996
                SET status         = 'NOTMATCHED' ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = all_99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, cash_receipt_id or header_id is null, end of bank_rec_id NE -cardtype for 996 rowid ' || all_99x_data (idx).x99x_rowid);
              END IF; --NABCRD
            END IF;   -- Cash_receipt_id is not null
          END LOOP;   -- 99x_data loop
        END LOOP;     --996_cr_cur
        COMMIT;
        CLOSE c996_match_rct_ajb_cr;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 996 table updated to MATCHED_AR');
        fnd_file.put_line(fnd_file.LOG,'c996_match_rct_ajb_cr END   - 996 Match Attempt receipt num against XX_CE_AJB_RECEIPTS_V view for credit transactions ( old E1310).');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END; --c996_match_rct_ajb_cr
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,'c996_match_rct_ajb_non_cr START - 996 Match Attempt receipt num against XX_CE_AJB_RECEIPTS_V view for non-credit transactions (old E1310).');
        all_99x_data   := all_99x_null;
        v_rows_updated := 0;
        OPEN c996_match_rct_ajb_non_cr;
        LOOP
          FETCH c996_match_rct_ajb_non_cr BULK COLLECT
          INTO all_99x_data LIMIT p_batch_size;
          EXIT
        WHEN all_99x_data.COUNT = 0;
          FOR idx IN all_99x_data.FIRST .. all_99x_data.LAST
          LOOP
            -- If matching AR record and Recon Setup is found
            IF all_99x_data (idx).cash_receipt_id IS NOT NULL
              --Defect 10048
              AND all_99x_data (idx).header_id IS NOT NULL THEN
              UPDATE xx_ce_ajb996
              SET status           = 'MATCHED_AR' ,
                ar_cash_receipt_id = all_99x_data (idx).cash_receipt_id ,
                recon_header_id    = all_99x_data (idx).header_id ,
                customer_id        = all_99x_data (idx).customer_id ,
                card_type          = all_99x_data (idx).om_card_type ,
                last_update_date   = SYSDATE ,
                last_updated_by    = gn_user_id
              WHERE ROWID          = all_99x_data (idx).x99x_rowid;
              v_rows_updated      := v_rows_updated + SQL%ROWCOUNT;
              -- Split the Batch for NABCRD.
              -- Check if it was already split in an earlier run.
              IF all_99x_data (idx).processor_id = 'NABCRD' AND SUBSTR (all_99x_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR(all_99x_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb996
                SET bank_rec_id = bank_rec_id
                  || '-'
                  || NVL(SUBSTR(all_99x_data (idx).om_card_type,1,1),'V') ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = all_99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, end of bank_rec_id NE -cardtype for 996 rowid ' || all_99x_data (idx).x99x_rowid);
              END IF; -- If NABCRD
            ELSE
              IF all_99x_data (idx).processor_id = 'NABCRD' THEN
                UPDATE xx_ce_ajb996
                SET status         = 'NOTMATCHED' ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = all_99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, cash_receipt_id or header_id is null, end of bank_rec_id NE -cardtype for 996 rowid ' || all_99x_data (idx).x99x_rowid);
              END IF;
            END IF; -- cash receipt is is not null
          END LOOP; -- 99x loop
        END LOOP;   --996_non_cr_cur loop
        COMMIT;
        CLOSE c996_match_rct_ajb_non_cr;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 996 table updated to MATCHED_AR');
        fnd_file.put_line (fnd_file.LOG,'c996_match_rct_ajb_non_cr END   - 996 Match Attempt receipt num against XX_CE_AJB_RECEIPTS_V view for non-credit transactions (old E1310).');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END; --c996_match_rct_ajb_non_cr
      --996 Existing non-matched logic from (E1310)
      --*********Added for defect 15775*************
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,'c996_unmatched START - Update the Recon Header Id for all the unmatched 996 records');
        all_99x_unmatched_data := all_99x_unmatched_null;
        v_rows_updated         := 0;
        OPEN c996_unmatched;
        LOOP
          FETCH c996_unmatched BULK COLLECT
          INTO all_99x_unmatched_data LIMIT p_batch_size;
          EXIT
        WHEN all_99x_unmatched_data.COUNT = 0;
          FOR idx IN all_99x_unmatched_data.FIRST .. all_99x_unmatched_data.LAST
          LOOP
            IF all_99x_unmatched_data (idx).processor_id = 'DCV3RN' THEN
              lc_card_type                              := 'DISCOVER';
            ELSE
              lc_card_num  := SUBSTR(all_99x_unmatched_data (idx).card_num,1,2);
              lc_card_type := XX_CM_TRACK_LOG_PKG.get_card_type(all_99x_unmatched_data (idx).processor_id ,all_99x_unmatched_data (idx).ajb_file_name ,all_99x_unmatched_data (idx).provider_type ,lc_card_num);
            END IF;
            fnd_file.put_line (fnd_file.LOG,'lc_card_type : '|| lc_card_type||'  '||'provider_type: '||all_99x_unmatched_data (idx).provider_type);
            IF lc_card_type IS NULL THEN
              fnd_file.put_line (fnd_file.LOG,'Card Type is NULL for the processor_id : '|| all_99x_unmatched_data (idx).processor_id);
            ELSE
              BEGIN
                SELECT header_id
                INTO ln_recon_header_id
                FROM xx_ce_recon_glact_hdr_v hdr,
                  fnd_lookup_values lv
                WHERE lv.meaning    = lc_card_type
                AND lv.lookup_type  = 'OD_PAYMENT_TYPES'
                AND lv.enabled_flag = 'Y'
                AND lv.lookup_code  = hdr.om_card_type
                AND provider_code   = all_99x_unmatched_data (idx).processor_id;
                fnd_file.put_line (fnd_file.LOG,'recon_header_id:'|| ln_recon_header_id);
              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                fnd_file.put_line (fnd_file.LOG , 'No recon header id found for the card type : ' ||lc_card_type ||' and for the processor_id : ' || all_99x_unmatched_data (idx).processor_id );
              WHEN OTHERS THEN
                xx_ce_cc_common_pkg.od_message ('M' , 'Error/Warning:' || SQLCODE || '-' || SQLERRM );
              END;
              UPDATE xx_ce_ajb996
              SET recon_header_id = ln_recon_header_id ,
                last_update_date  = SYSDATE ,
                last_updated_by   = gn_user_id
              WHERE ROWID         = all_99x_unmatched_data (idx).x99x_rowid;
              v_rows_updated     := v_rows_updated + SQL%ROWCOUNT;
            END IF;
          END LOOP;
        END LOOP;
        COMMIT;
        CLOSE c996_unmatched;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 996 table updated (recon_header_id)');
        fnd_file.put_line (fnd_file.LOG,'c996_unmatched END   - Update the Recon Header Id for all the unmatched 996 records');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END;
      --*****End of change for defect 15775**********
      --996 Existing non-matched logic from (E1310) END
      --996 Existing no-card-type logic from (E1310)
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line(fnd_file.LOG,'c996_no_cardtype START - Update BankRecID for Non-AR-Matched 996 Transactions for NABCRD with no card type.');
        all_99x_data   := all_99x_null;
        v_rows_updated := 0;
        OPEN c996_no_cardtype;
        LOOP
          FETCH c996_no_cardtype BULK COLLECT INTO all_99x_data LIMIT p_batch_size;
          EXIT
        WHEN all_99x_data.COUNT = 0;
          FOR idx IN all_99x_data.FIRST .. all_99x_data.LAST
          LOOP
            UPDATE xx_ce_ajb996
            SET status    = 'PREPROCESSED' ,
              bank_rec_id = bank_rec_id
              || '-V' ,
              last_update_date = SYSDATE ,
              last_updated_by  = gn_user_id
            WHERE ROWID        = all_99x_data (idx).x99x_rowid;
            v_rows_updated    := v_rows_updated + SQL%ROWCOUNT;
          END LOOP;
        END LOOP;
        COMMIT;
        CLOSE c996_no_cardtype;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 996 table updated (bank_rec_id) for invalid card type');
        fnd_file.put_line(fnd_file.LOG,'c996_no_cardtype END   - Update BankRecID for Non-AR-Matched 996 Transactions for NABCRD with no card type.');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END;
      --996 Existing no-card-type logic from (E1310) END
    END IF; -- NVL (p_file_type, 'ALL') IN ('996', ALL)
    fnd_file.put_line (fnd_file.LOG, ' ');
    fnd_file.put_line (fnd_file.LOG, LPAD ('-', 100, '-'));
    /* Process the 998 p_file_type */
    IF NVL (UPPER (p_file_type), 'ALL') IN ('998', 'ALL') THEN
      fnd_file.put_line (fnd_file.LOG, 'Preprocessing 998 data...');
      /* Update all status */
      UPDATE xx_ce_ajb998
      SET status         = 'PREPROCESSING' ,
        last_update_date = SYSDATE ,
        last_updated_by  = gn_user_id
      WHERE status       ='NEW' --status IS NULL --modified for defect# 43424 v2.7.1
        --AND org_id = gn_org_id -- Added for PROD Defect: 2046,1716
      AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name);
      /* Logic from xx_ce_ajb998_t and xx_ce_ajb998_v on xx_ce_ajb998 */
      /* Only open the c998_org if it is not already open */
      IF c998_org%ISOPEN THEN
        NULL;
      ELSE
        OPEN c998_org;
        fnd_file.put_line (fnd_file.LOG, 'Preprocessing 998 country/orgs.');
      END IF;
      LOOP
        /* Populate variables using cursor fetch.  No point using bulk collect as < 5 */
        FETCH c998_org
        INTO v_country_code;
        /* Keep fetching until no more records are found */
        EXIT
      WHEN NOT c998_org%FOUND;
        BEGIN
          /* Lookup the org_id for the country */
          SELECT xx_fin_country_defaults_pkg.f_org_id (territory_code) ,
            territory_code
          INTO v_org_id ,
            v_territory_code
          FROM fnd_territories
          WHERE iso_numeric_code = v_country_code;
        EXCEPTION
        WHEN OTHERS THEN
          v_org_id := NULL;
        END;
        fnd_file.put_line (fnd_file.LOG , '  Updating 998 country_code values of ' || v_country_code || ' with org_id of ' || v_org_id || ' and territory_code of ' || v_territory_code || '.' );
        /* Update org_id, territory_code */
        UPDATE xx_ce_ajb998
        SET org_id         = v_org_id ,
          territory_code   = v_territory_code ,
          last_update_date = SYSDATE ,
          last_updated_by  = gn_user_id
        WHERE status       = 'PREPROCESSING'
        AND country_code   = v_country_code;
      END LOOP;
      CLOSE c998_org;
      fnd_file.put_line(fnd_file.LOG,'Finished preprocessing 998 country/orgs.');
      fnd_file.put_line(fnd_file.LOG,'Updating 998 bank_rec_id values with -XX provider_type.');
      /* Update bank_rec_id */
      -- Modified query for V2.8
      UPDATE xx_ce_ajb998
      SET bank_rec_id = bank_rec_id
        || '-'
        || DECODE(provider_type,'AMAZON','MP',SUBSTR (provider_type, 1, 2))
        ||DECODE(SUBSTR(AJB_FILE_NAME,7,9),'PayPalWEB','W','PayPalPOS','P',NULL)
        || '-'
        || territory_code ,
        last_update_date = SYSDATE ,
        last_updated_by  = gn_user_id
      WHERE status       = 'PREPROCESSING'
      AND org_id         = gn_org_id -- Added for PROD Defect: 2046,1716
      AND ajb_file_name  = NVL (p_ajb_file_name, ajb_file_name)
      AND NOT EXISTS
        (SELECT 1
        FROM xx_fin_translatevalues vals,
          xx_fin_translatedefinition defn
        WHERE defn.translate_id   = vals.translate_id
        AND defn.translation_name = 'OD_CE_BANK_REC_PROV_TYPE'
        AND vals.source_value1    =provider_type
        AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
        AND SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
        AND vals.enabled_flag = 'Y'
        AND defn.enabled_flag = 'Y'
        );
      FOR rec IN cr_998_bank_Rec_prov_type(p_ajb_file_name,gn_org_id)
      LOOP
        UPDATE xx_ce_ajb998
        SET bank_rec_id = bank_rec_id
          || '-MP-'
          ||rec.provider_short_name
          || '-'
          || territory_code ,
          last_update_date = SYSDATE ,
          last_updated_by  = gn_user_id
        WHERE status       = 'PREPROCESSING'
        AND org_id         = gn_org_id -- Added for PROD Defect: 2046,1716
        AND ajb_file_name  = NVL (p_ajb_file_name, ajb_file_name)
        AND provider_type  =rec.provider_type;
      END LOOP;
      fnd_file.put_line(fnd_file.LOG,'Finished preprocessing 998 bank_rec_id values with -XX provider_type.');
      /* Only open the c998_currency if it is not already open */
      IF c998_currency%ISOPEN THEN
        NULL;
      ELSE
        OPEN c998_currency;
        fnd_file.put_line (fnd_file.LOG, 'Preprocessing 998 currencies.');
      END IF;
      LOOP
        /* Populate variables using cursor fetch.  No point using bulk collect as < 5 */
        FETCH c998_currency
        INTO v_currency_code;
        /* Keep fetching until no more records are found */
        EXIT
      WHEN NOT c998_currency%FOUND;
        BEGIN
          /* Lookup the currency for the country */
          SELECT currency_code
          INTO v_currency
          FROM fnd_currencies
          WHERE attribute1 = v_currency_code;
        EXCEPTION
        WHEN OTHERS THEN
          v_currency := NULL;
        END;
        fnd_file.put_line (fnd_file.LOG,'  Updating 998 currency_code values of ' || v_currency_code || ' with currency of ' || v_currency || '.');
        /* Update currency */
        UPDATE xx_ce_ajb998
        SET currency       = v_currency ,
          last_update_date = SYSDATE ,
          last_updated_by  = gn_user_id
        WHERE status       = 'PREPROCESSING'
        AND currency_code  = v_currency_code;
      END LOOP;
      CLOSE c998_currency;
      fnd_file.put_line (fnd_file.LOG,'Finished preprocessing 998 currencies.');
      /* Only open the c998_bank if it is not already open */
      IF c998_bank%ISOPEN THEN
        NULL;
      ELSE
        OPEN c998_bank;
        fnd_file.put_line (fnd_file.LOG, 'Preprocessing 998 bank_rec_ids.');
      END IF;
      LOOP
        /* Populate variables using cursor fetch */
        FETCH c998_bank
        INTO v_bank_rec_id;
        /* Keep fetching until no more records are found */
        EXIT
      WHEN NOT c998_bank%FOUND;
        BEGIN
          v_recon_date := get_recon_date (v_bank_rec_id);
        EXCEPTION
        WHEN OTHERS THEN
          BEGIN
            v_recon_date := TO_DATE (SUBSTR (v_bank_rec_id, 1, 8), 'YYYYMMDD');
          EXCEPTION
          WHEN OTHERS THEN
            v_recon_date := TRUNC (SYSDATE);
          END;
        END;
        fnd_file.put_line (fnd_file.LOG,'  Updating 998 bank_rec_id values of ' || v_bank_rec_id || ' with recon_date of ' || v_recon_date || '.');
        /* Update recon_date */
        UPDATE xx_ce_ajb998
        SET recon_date     = v_recon_date ,
          last_update_date = SYSDATE ,
          last_updated_by  = gn_user_id
        WHERE status       = 'PREPROCESSING'
        AND bank_rec_id    = v_bank_rec_id;
      END LOOP;
      CLOSE c998_bank;
      fnd_file.put_line (fnd_file.LOG,'  Updating 998 NULL recon_date values with ' || TRUNC (SYSDATE) || '.');
      /* Update recon_date */
      UPDATE xx_ce_ajb998
      SET recon_date     = TRUNC (SYSDATE) ,
        last_update_date = SYSDATE ,
        last_updated_by  = gn_user_id
      WHERE status       = 'PREPROCESSING'
      AND org_id         = gn_org_id -- Added for PROD Defect: 2046,1716
      AND recon_date    IS NULL;
      fnd_file.put_line (fnd_file.LOG,'Finished preprocessing 998 bank_rec_ids.');
      fnd_file.put_line (fnd_file.LOG, 'Preprocessing 998 receipt_nums.');
      /* Update attribute21, receipt_num */
      UPDATE xx_ce_ajb998
      SET attribute21 = receipt_num ,
        receipt_num   =
        CASE
          WHEN SUBSTR(receipt_num,1,2) = 'OM'
          THEN SUBSTR(receipt_num,INSTR(receipt_num,'#',-1,1) +1) -- for POS trans, use 3rd segment (order payment id)
          WHEN SUBSTR(receipt_num,1,2) != 'OM'
          THEN SUBSTR(receipt_num
            || '#',1,INSTR(receipt_num
            || '#','#') -1) -- for all other trans, user 1st segment (AR receipt number)
        END ,
        last_update_date = SYSDATE ,
        last_updated_by  = gn_user_id
      WHERE status       = 'PREPROCESSING'
      AND org_id         = gn_org_id -- Added for PROD Defect: 2046,1716
      AND provider_type  = 'CREDIT'
      AND receipt_num   IS NOT NULL;
      fnd_file.put_line (fnd_file.LOG,'Finished preprocessing 998 country/orgs.');
      fnd_file.put_line (fnd_file.LOG,'Updating status of all 998 preprocessed records.');
      /* Update status */
      UPDATE xx_ce_ajb998
      SET status         = 'PREPROCESSED' ,
        last_update_date = SYSDATE ,
        last_updated_by  = gn_user_id
      WHERE status       = 'PREPROCESSING'
      AND org_id         = gn_org_id                             -- Added for PROD Defect: 2046,1716
      AND ajb_file_name  = NVL (p_ajb_file_name, ajb_file_name); --Added for QC 38437
      fnd_file.put_line(fnd_file.LOG,'Finished updating status of all 998 preprocessed records.');
      fnd_file.put_line (fnd_file.LOG, '998 data preprocessed!');
      /* End of logic from xx_ce_ajb998_t and xx_ce_ajb998_v on xx_ce_ajb998, commit */
      COMMIT;
      --Begin match attempts for 998 records
      --Begin match attempts for 998 records for Zero Dollar Receipts - QC Defect # 13263
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,'c998_match_zero_dollar_rcpt START - 998 Match Attempt for receipt num against XX_AR_ORDER_RECEIPT_DTL for Zero Dollar Receipts.');
        c998_data      := c998_null;
        v_rows_updated := 0;
        OPEN c998_match_zero_dollar_rcpt;
        LOOP
          FETCH c998_match_zero_dollar_rcpt BULK COLLECT
          INTO c998_data LIMIT p_batch_size;
          EXIT
        WHEN c998_data.COUNT = 0;
          FOR idx IN c998_data.FIRST .. c998_data.LAST
          LOOP
            IF c998_data (idx).cash_receipt_id IS NOT NULL AND c998_data (idx).header_id IS NOT NULL THEN
              UPDATE xx_ce_ajb998
              SET status           = 'MATCHED_AR' ,
                order_payment_id   = c998_data (idx).order_payment_id ,
                ar_cash_receipt_id = c998_data (idx).cash_receipt_id ,
                recon_header_id    = c998_data (idx).header_id ,
                card_type          = c998_data (idx).om_card_type ,
                last_update_date   = SYSDATE ,
                last_updated_by    = gn_user_id
              WHERE ROWID          = c998_data (idx).x99x_rowid;
              v_rows_updated      := v_rows_updated + SQL%ROWCOUNT;
              UPDATE xx_ar_order_receipt_dtl
              SET matched = 'Y'
              WHERE ROWID = c998_data (idx).ord_rowid;
              -- Split the Batch for NABCRD.
              -- Check if it was already split in an earlier run.
              IF c998_data (idx).processor_id = 'NABCRD' AND SUBSTR (c998_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR (c998_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb998
                SET bank_rec_id = bank_rec_id
                  || '-'
                  || NVL(SUBSTR(c998_data (idx).om_card_type,1,1),'V') ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = c998_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, end of bank_rec_id NE -cardtype for 998 rowid ' || c998_data (idx).x99x_rowid);
              END IF; -- If NABCRD
            END IF;   -- Cash_receipt_id is not null
          END LOOP;   -- 99x_data loop
        END LOOP;
        COMMIT;
        CLOSE c998_match_zero_dollar_rcpt;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 998 table updated to MATCHED_AR');
        fnd_file.put_line (fnd_file.LOG,'c998_match_zero_dollar_rcpt END   - 998 Match Attempt for receipt num against XX_AR_ORDER_RECEIPT_DTL for Zero Dollar Receipts.');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END;
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,'c998_match_rct_ord_cr_pos START - 998 Match Attempt for receipt num against XX_AR_ORDER_RECEIPT_DTL for credit POS transactions.');
        c998_data      := c998_null;
        v_rows_updated := 0;
        OPEN c998_match_rct_ord_cr_pos;
        LOOP
          FETCH c998_match_rct_ord_cr_pos BULK COLLECT
          INTO c998_data LIMIT p_batch_size;
          EXIT
        WHEN c998_data.COUNT = 0;
          FOR idx IN c998_data.FIRST .. c998_data.LAST
          LOOP
            IF c998_data (idx).cash_receipt_id IS NOT NULL
              --Defect 10048
              AND c998_data (idx).header_id IS NOT NULL THEN
              UPDATE xx_ce_ajb998
              SET status           = 'MATCHED_AR' ,
                order_payment_id   = c998_data (idx).order_payment_id ,
                ar_cash_receipt_id = c998_data (idx).cash_receipt_id ,
                recon_header_id    = c998_data (idx).header_id ,
                card_type          = c998_data (idx).om_card_type ,
                last_update_date   = SYSDATE ,
                last_updated_by    = gn_user_id
              WHERE ROWID          = c998_data (idx).x99x_rowid;
              v_rows_updated      := v_rows_updated + SQL%ROWCOUNT;
              UPDATE xx_ar_order_receipt_dtl
              SET matched = 'Y'
              WHERE ROWID = c998_data (idx).ord_rowid;
              -- Split the Batch for NABCRD.
              -- Check if it was already split in an earlier run.
              IF c998_data (idx).processor_id = 'NABCRD' AND SUBSTR (c998_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR (c998_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb998
                SET bank_rec_id = bank_rec_id
                  || '-'
                  || NVL(SUBSTR(c998_data (idx).om_card_type,1,1),'V') ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = c998_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, end of bank_rec_id NE -cardtype for 998 rowid ' || c998_data (idx).x99x_rowid);
              END IF; -- If NABCRD
            END IF;   -- Cash_receipt_id is not null
          END LOOP;   -- 99x_data loop
        END LOOP;
        COMMIT;
        CLOSE c998_match_rct_ord_cr_pos;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 998 table updated to MATCHED_AR');
        fnd_file.put_line (fnd_file.LOG,'c998_match_rct_ord_cr_pos END   - 998 Match Attempt for receipt num against XX_AR_ORDER_RECEIPT_DTL for credit POS transactions.');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END;
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,'c998_match_rct_ord_cr_non_pos START - 998 Match Attempt receipt num against XX_AR_ORDER_RECEIPT_DTL for credit non-POS transactions.');
        c998_data      := c998_null;
        v_rows_updated := 0;
        OPEN c998_match_rct_ord_cr_non_pos;
        LOOP
          FETCH c998_match_rct_ord_cr_non_pos BULK COLLECT
          INTO c998_data LIMIT p_batch_size;
          EXIT
        WHEN c998_data.COUNT = 0;
          FOR idx IN c998_data.FIRST .. c998_data.LAST
          LOOP
            IF c998_data (idx).cash_receipt_id IS NOT NULL
              --Defect 10048
              AND c998_data (idx).header_id IS NOT NULL THEN
              UPDATE xx_ce_ajb998
              SET status           = 'MATCHED_AR' ,
                order_payment_id   = c998_data (idx).order_payment_id ,
                ar_cash_receipt_id = c998_data (idx).cash_receipt_id ,
                recon_header_id    = c998_data (idx).header_id ,
                card_type          = c998_data (idx).om_card_type ,
                last_update_date   = SYSDATE ,
                last_updated_by    = gn_user_id
              WHERE ROWID          = c998_data (idx).x99x_rowid;
              v_rows_updated      := v_rows_updated + SQL%ROWCOUNT;
              UPDATE xx_ar_order_receipt_dtl
              SET matched = 'Y'
              WHERE ROWID = c998_data (idx).ord_rowid;
              -- Split the Batch for NABCRD.
              -- Check if it was already split in an earlier run.
              IF c998_data (idx).processor_id = 'NABCRD' AND SUBSTR (c998_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR (c998_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb998
                SET bank_rec_id = bank_rec_id
                  || '-'
                  || NVL(SUBSTR(c998_data (idx).om_card_type,1,1),'V') ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = c998_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, end of bank_rec_id NE -cardtype for 998 rowid ' || c998_data (idx).x99x_rowid);
              END IF; -- If NABCRD
            END IF;   -- Cash_receipt_id is not null
          END LOOP;   -- 99x_data loop
        END LOOP;
        COMMIT;
        CLOSE c998_match_rct_ord_cr_non_pos;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 998 table updated to MATCHED_AR');
        fnd_file.put_line (fnd_file.LOG,'c998_match_rct_ord_cr_non_pos END   - 998 Match Attempt receipt num against XX_AR_ORDER_RECEIPT_DTL for credit non-POS transactions.');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END;
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,'c998_match_rct_ord_non_cr START - 998 Match Attempt receipt num against XX_AR_ORDER_RECEIPT_DTL for non-credit transactions.');
        c998_data      := c998_null;
        v_rows_updated := 0;
        OPEN c998_match_rct_ord_non_cr;
        LOOP
          FETCH c998_match_rct_ord_non_cr BULK COLLECT
          INTO c998_data_debit LIMIT p_batch_size;
          EXIT
        WHEN c998_data_debit.COUNT = 0;
          FOR idx IN c998_data_debit.FIRST .. c998_data_debit.LAST
          LOOP
            IF c998_data_debit (idx).cash_receipt_id IS NOT NULL
              --Defect 10048
              AND c998_data_debit (idx).header_id IS NOT NULL THEN
              -- Added for QC Defect # 18476 -- Start
              BEGIN -- BEGIN Added for Defect# 33471
                ln_ajb998_count                       := 0;
                ln_ordt_count                         := 0;
                IF c998_data_debit (idx).provider_type = 'DEBIT' THEN
                  SELECT COUNT (ajb998.receipt_num) rec_count
                  INTO ln_ajb998_count
                  FROM xx_ce_ajb998 ajb998
                  WHERE ajb998.provider_type = 'DEBIT'
                    --AND ajb998.trx_type      = 'SALE'
                  AND ajb998.processor_id = c998_data_debit (idx).processor_id
                  AND ajb998.bank_rec_id  = c998_data_debit (idx).bank_rec_id
                  AND ajb998.store_num    = c998_data_debit (idx).store_num
                  AND ajb998.trx_date     = c998_data_debit (idx).trx_date
                  AND ajb998.trx_amount   = c998_data_debit (idx).trx_amount
                  AND ajb998.card_num     = c998_data_debit (idx).card_num
                  AND ajb998.receipt_num  = c998_data_debit (idx).receipt_num
                  GROUP BY ajb998.bank_rec_id ,
                    ajb998.store_num ,
                    ajb998.trx_date ,
                    ajb998.trx_amount ,
                    ajb998.card_num ,
                    ajb998.receipt_num ;
                  SELECT COUNT (ordt.customer_receipt_reference) rec_count
                  INTO ln_ordt_count
                  FROM xx_ar_order_receipt_dtl ordt
                  WHERE 1 = 1
                    --AND ordt.sale_type      = 'SALE'
                  AND ordt.store_number               = c998_data_debit (idx).store_num
                  AND ordt.receipt_date               = c998_data_debit (idx).trx_date
                  AND ordt.payment_amount             = c998_data_debit (idx).trx_amount
                  AND ordt.customer_receipt_reference = c998_data_debit (idx).receipt_num
                  GROUP BY ordt.store_number ,
                    ordt.payment_amount ,
                    ordt.customer_receipt_reference ;
                ELSIF c998_data_debit (idx).provider_type IN ('CHECK', 'PAYPAL') THEN -- Included ELSIF condition CHECK and PAYPAL for the defect 33471
                  BEGIN
                    SELECT COUNT (ajb998.receipt_num) rec_count
                    INTO ln_ajb998_count
                    FROM xx_ce_ajb998 ajb998
                    WHERE ajb998.provider_type IN ('CHECK', 'PAYPAL')
                    AND ajb998.processor_id     = c998_data_debit (idx).processor_id
                    AND ajb998.bank_rec_id      = c998_data_debit (idx).bank_rec_id
                    AND ajb998.store_num        = c998_data_debit (idx).store_num
                    AND ajb998.trx_date         = c998_data_debit (idx).trx_date
                    AND ajb998.trx_amount       = c998_data_debit (idx).trx_amount
                    AND ajb998.card_num         = c998_data_debit (idx).card_num
                    AND ajb998.receipt_num      = c998_data_debit (idx).receipt_num
                    GROUP BY ajb998.bank_rec_id ,
                      ajb998.store_num ,
                      ajb998.trx_date ,
                      ajb998.trx_amount ,
                      ajb998.card_num ,
                      AJB998.RECEIPT_NUM ;
                  EXCEPTION
                  WHEN OTHERS THEN
                    l_exc_location := ' Querying  ln_ajb998_count in the ELSIF c998_data_debit (idx).provider_type in (CHECK, PAYPAL) '||SQLERRM;
                    RAISE XX_CE_AJB998_EX;
                  END;
                  BEGIN
                    SELECT COUNT (ordt.customer_receipt_reference) rec_count
                    INTO ln_ordt_count
                    FROM xx_ar_order_receipt_dtl ordt
                    WHERE 1                             = 1
                    AND ordt.store_number               = c998_data_debit (idx).store_num
                    AND ordt.payment_amount             = c998_data_debit (idx).trx_amount
                    AND ordt.customer_receipt_reference = c998_data_debit (idx).receipt_num
                    GROUP BY ordt.store_number ,
                      ordt.payment_amount ,
                      ordt.customer_receipt_reference;
                  EXCEPTION
                  WHEN OTHERS THEN
                    l_exc_location := ' Querying  ln_ordt_count in the ELSIF c998_data_debit (idx).provider_type in (CHECK, PAYPAL) '||SQLERRM;
                    RAISE XX_CE_AJB998_EX;
                  END;
                END IF;
                l_pmt_count        := ln_ordt_count ; -- Added for QC Defect # 33471
                IF (ln_ajb998_count > ln_ordt_count AND ln_ordt_count = 1) THEN
                  UPDATE xx_ce_ajb998
                  SET status           = 'MATCHED_AR' ,
                    order_payment_id   = c998_data_debit (idx).order_payment_id ,
                    ar_cash_receipt_id = c998_data_debit (idx).cash_receipt_id ,
                    recon_header_id    = c998_data_debit (idx).header_id ,
                    card_type          = c998_data_debit (idx).om_card_type ,
                    last_update_date   = SYSDATE ,
                    last_updated_by    = gn_user_id
                  WHERE ROWID          =
                    (SELECT MAX (ajb998.ROWID)
                    FROM xx_ce_ajb998 ajb998
                    WHERE ajb998.provider_type = 'DEBIT'
                      --AND ajb998.trx_type      = 'SALE'
                    AND ajb998.processor_id = c998_data_debit (idx).processor_id
                    AND ajb998.bank_rec_id  = c998_data_debit (idx).bank_rec_id
                    AND ajb998.store_num    = c998_data_debit (idx).store_num
                    AND ajb998.trx_date     = c998_data_debit (idx).trx_date
                    AND ajb998.trx_amount   = c998_data_debit (idx).trx_amount
                    AND ajb998.card_num     = c998_data_debit (idx).card_num
                    AND ajb998.receipt_num  = c998_data_debit (idx).receipt_num
                    ) ;
                  -- Added for QC Defect # 33471 -- Start
                ELSIF (ln_ordt_count = ln_ajb998_count AND ln_ordt_count > 1 AND c998_data_debit (idx).provider_type IN ('CHECK', 'DEBIT','PAYPAL')) THEN
                  fnd_file.put_line (fnd_file.LOG,' ln_ordt_count = ln_ajb998_count  AND ln_ordt_count > 1 AND c998_data_debit (idx).provider_type in (CHECK, PAYPAL)');
                  l_ord_pmt_id   := NULL;
                  l_cash_rcpt_id := NULL;
                  l_om_card_type := NULL;
                  BEGIN
                    SELECT DISTINCT order_payment_id BULK COLLECT
                    INTO l_ordt_type
                    FROM xx_ar_order_receipt_dtl -- Added for QC Defect # 33471
                    WHERE CUSTOMER_RECEIPT_REFERENCE = c998_data_debit (idx).receipt_num
                    AND payment_amount               = c998_data_debit (idx).trx_amount
                    ORDER BY order_payment_id DESC;
                  EXCEPTION
                  WHEN OTHERS THEN
                    l_exc_location := ' Querying  order_payment_id in the ELSIF (ln_ordt_count = ln_ajb998_count  AND ln_ordt_count > 1 AND c998_data_debit (idx).provider_type in (CHECK, DEBIT,PAYPAL)) '||SQLERRM;
                    RAISE XX_CE_AJB998_EX;
                  END;
                  FOR ajbrec IN ajb_cur(c998_data_debit (idx).receipt_num,c998_data_debit (idx).trx_amount)
                  LOOP
                    BEGIN
                      BEGIN
                        SELECT order_payment_id,
                          cash_receipt_id,
                          credit_card_code
                        INTO l_ord_pmt_id,
                          l_cash_rcpt_id,
                          l_om_card_type
                        FROM XX_AR_ORDER_RECEIPT_DTL
                        WHERE CUSTOMER_RECEIPT_REFERENCE = C998_DATA_DEBIT (IDX).RECEIPT_NUM
                        AND order_payment_id             = l_ordt_type(l_pmt_count);
                      EXCEPTION
                      WHEN OTHERS THEN
                        l_exc_location2 := ' Querying  l_ord_pmt_id,l_cash_rcpt_id,l_om_card_type in the ELSIF (ln_ordt_count = ln_ajb998_count  AND ln_ordt_count > 1 AND c998_data_debit (idx).provider_type in (CHECK, DEBIT,PAYPAL)) '||SQLERRM;
                        RAISE XX_CE_AJB998_EX2;
                      END;
                      BEGIN
                        UPDATE xx_ce_ajb998
                        SET status           = 'MATCHED_AR' ,
                          order_payment_id   = l_ord_pmt_id ,
                          ar_cash_receipt_id = l_cash_rcpt_id ,
                          recon_header_id    = ajbrec.header_id ,
                          card_type          = l_om_card_type ,
                          last_update_date   = SYSDATE ,
                          last_updated_by    = gn_user_id
                        WHERE ROWID          = ajbrec.ROW_ID;
                        l_pmt_count         := l_pmt_count - 1;
                      EXCEPTION
                      WHEN OTHERS THEN
                        l_exc_location2 := ' Updating  xx_ce_ajb998 in the ELSIF (ln_ordt_count = ln_ajb998_count  AND ln_ordt_count > 1 AND c998_data_debit (idx).provider_type in (CHECK, DEBIT,PAYPAL)) '||SQLERRM;
                        RAISE XX_CE_AJB998_EX2;
                      END;
                    EXCEPTION
                    WHEN XX_CE_AJB998_EX2 THEN
                      fnd_file.put_line (fnd_file.LOG,'Exception at '||l_exc_location2);
                      UPDATE xx_ce_ajb998
                      SET status           = 'MATCHED_AR' ,
                        order_payment_id   = c998_data_debit (idx).order_payment_id ,
                        ar_cash_receipt_id = c998_data_debit (idx).cash_receipt_id ,
                        recon_header_id    = c998_data_debit (idx).header_id ,
                        card_type          = c998_data_debit (idx).om_card_type ,
                        last_update_date   = SYSDATE ,
                        last_updated_by    = gn_user_id
                      WHERE ROWID          = c998_data_debit (idx).x99x_rowid;
                      l_pmt_count         := l_pmt_count - 1;
                    END;
                  END LOOP;
                  -- Added for QC Defect # 33471 -- End
                ELSE
                  -- Added for QC Defect # 18476 -- End
                  UPDATE xx_ce_ajb998
                  SET status           = 'MATCHED_AR' ,
                    order_payment_id   = c998_data_debit (idx).order_payment_id ,
                    ar_cash_receipt_id = c998_data_debit (idx).cash_receipt_id ,
                    recon_header_id    = c998_data_debit (idx).header_id ,
                    card_type          = c998_data_debit (idx).om_card_type ,
                    last_update_date   = SYSDATE ,
                    last_updated_by    = gn_user_id
                  WHERE ROWID          = c998_data_debit (idx).x99x_rowid;
                END IF; -- Added for QC Defect # 18476
              EXCEPTION
              WHEN XX_CE_AJB998_EX THEN -- EXCEPTION Added for Defect 33471
                fnd_file.put_line (fnd_file.LOG,'Exception at '||l_exc_location);
                UPDATE xx_ce_ajb998
                SET status           = 'MATCHED_AR' ,
                  order_payment_id   = c998_data_debit (idx).order_payment_id ,
                  ar_cash_receipt_id = c998_data_debit (idx).cash_receipt_id ,
                  recon_header_id    = c998_data_debit (idx).header_id ,
                  card_type          = c998_data_debit (idx).om_card_type ,
                  last_update_date   = SYSDATE ,
                  last_updated_by    = gn_user_id
                WHERE ROWID          = c998_data_debit (idx).x99x_rowid;
              END; -- END Added for Defect 33471
              v_rows_updated := v_rows_updated + SQL%ROWCOUNT;
              UPDATE xx_ar_order_receipt_dtl
              SET matched = 'Y'
              WHERE ROWID = c998_data_debit (idx).ord_rowid;
              -- Split the Batch for NABCRD.
              -- Check if it was already split in an earlier run.
              IF c998_data_debit (idx).processor_id = 'NABCRD' AND SUBSTR (c998_data_debit (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR (c998_data_debit (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb998
                SET bank_rec_id = bank_rec_id
                  || '-'
                  || NVL(SUBSTR(c998_data_debit (idx).om_card_type,1,1),'V') ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = c998_data_debit (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, end of bank_rec_id NE -cardtype for 998 rowid ' || c998_data_debit (idx).x99x_rowid);
              END IF; -- If NABCRD
            END IF;   -- Cash_receipt_id is not null
          END LOOP;   -- 99x_data loop
        END LOOP;
        COMMIT;
        CLOSE c998_match_rct_ord_non_cr;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 998 table updated to MATCHED_AR');
        fnd_file.put_line (fnd_file.LOG,'c998_match_rct_ord_non_cr END   - 998 Match Attempt receipt num against XX_AR_ORDER_RECEIPT_DTL for non-credit transactions.');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END;
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line(fnd_file.LOG,'c998_match_rct_ajb_cr START - 998 Match Attempt receipt num against XX_CE_AJB_RECEIPTS_V view for credit transactions (old E1310).');
        all_99x_data   := all_99x_null;
        v_rows_updated := 0;
        OPEN c998_match_rct_ajb_cr;
        LOOP
          FETCH c998_match_rct_ajb_cr BULK COLLECT INTO all_99x_data LIMIT p_batch_size;
          EXIT
        WHEN all_99x_data.COUNT = 0;
          FOR idx IN all_99x_data.FIRST .. all_99x_data.LAST
          LOOP
            -- If matching AR record and Recon Setup is found
            IF all_99x_data (idx).cash_receipt_id IS NOT NULL
              --Defect 10048
              AND all_99x_data (idx).header_id IS NOT NULL THEN
              UPDATE xx_ce_ajb998
              SET status           = 'MATCHED_AR' ,
                ar_cash_receipt_id = all_99x_data (idx).cash_receipt_id ,
                recon_header_id    = all_99x_data (idx).header_id ,
                card_type          = all_99x_data (idx).om_card_type ,
                last_update_date   = SYSDATE ,
                last_updated_by    = gn_user_id
              WHERE ROWID          = all_99x_data (idx).x99x_rowid;
              v_rows_updated      := v_rows_updated + SQL%ROWCOUNT;
              -- Split the Batch for NABCRD.
              IF all_99x_data (idx).processor_id = 'NABCRD' THEN
                UPDATE xx_ce_ajb998
                SET bank_rec_id = bank_rec_id
                  || '-'
                  || NVL(SUBSTR(all_99x_data (idx).om_card_type,1,1),'V') ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = all_99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, end of bank_rec_id NE -cardtype for 998 rowid ' || all_99x_data (idx).x99x_rowid);
              END IF;
            END IF; -- cash receipt id and recon header id is not null.
          END LOOP;
        END LOOP;
        COMMIT;
        CLOSE c998_match_rct_ajb_cr;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 998 table updated to MATCHED_AR');
        fnd_file.put_line(fnd_file.LOG,'c998_match_rct_ajb_cr END   - 998 Match Attempt receipt num against XX_CE_AJB_RECEIPTS_V view for credit transactions (old E1310).');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END; -- all_998_cur_cr
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line(fnd_file.LOG,'c998_match_rct_ajb_non_cr START - 998 Match Attempt receipt num against XX_CE_AJB_RECEIPTS_V view for non-credit transactions (old E1310).');
        all_99x_data   := all_99x_null;
        v_rows_updated := 0;
        OPEN c998_match_rct_ajb_non_cr;
        LOOP
          FETCH c998_match_rct_ajb_non_cr BULK COLLECT
          INTO all_99x_data LIMIT p_batch_size;
          EXIT
        WHEN all_99x_data.COUNT = 0;
          FOR idx IN all_99x_data.FIRST .. all_99x_data.LAST
          LOOP
            -- If matching AR record and Recon Setup is found
            IF all_99x_data (idx).cash_receipt_id IS NOT NULL
              --Defect 10048
              AND all_99x_data (idx).header_id IS NOT NULL THEN
              UPDATE xx_ce_ajb998
              SET status           = 'MATCHED_AR' ,
                ar_cash_receipt_id = all_99x_data (idx).cash_receipt_id ,
                recon_header_id    = all_99x_data (idx).header_id ,
                card_type          = all_99x_data (idx).om_card_type ,
                last_update_date   = SYSDATE ,
                last_updated_by    = gn_user_id
              WHERE ROWID          = all_99x_data (idx).x99x_rowid;
              v_rows_updated      := v_rows_updated + SQL%ROWCOUNT;
              -- Split the Batch for NABCRD.
              IF all_99x_data (idx).processor_id = 'NABCRD' THEN
                UPDATE xx_ce_ajb998
                SET bank_rec_id = bank_rec_id
                  || '-'
                  || NVL(SUBSTR(all_99x_data (idx).om_card_type,1,1),'V') ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = all_99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, end of bank_rec_id NE -cardtype for 998 rowid ' || all_99x_data (idx).x99x_rowid);
              END IF;
            END IF; -- cash receipt id and recon header id is not null.
          END LOOP;
        END LOOP;
        COMMIT;
        CLOSE c998_match_rct_ajb_non_cr;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 998 table updated to MATCHED_AR');
        fnd_file.put_line(fnd_file.LOG,'c998_match_rct_ajb_non_cr END   - 998 Match Attempt receipt num against XX_CE_AJB_RECEIPTS_V view for non-credit transactions (old E1310).');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END; -- all_998_cur_cr
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,'c998_match_inv_ord START - 998 Match Attempt for invoice number against XX_AR_ORDER_RECEIPT_DTL.');
        c998_data      := c998_null;
        v_rows_updated := 0;
        OPEN c998_match_inv_ord;
        LOOP
          FETCH c998_match_inv_ord BULK COLLECT INTO c998_data LIMIT p_batch_size;
          EXIT
        WHEN c998_data.COUNT = 0;
          FOR idx IN c998_data.FIRST .. c998_data.LAST
          LOOP
            IF c998_data (idx).cash_receipt_id IS NOT NULL
              --Defect 10048
              AND c998_data (idx).header_id IS NOT NULL THEN
              UPDATE xx_ce_ajb998
              SET status           = 'MATCHED_AR' ,
                order_payment_id   = c998_data (idx).order_payment_id ,
                ar_cash_receipt_id = c998_data (idx).cash_receipt_id ,
                recon_header_id    = c998_data (idx).header_id ,
                card_type          = c998_data (idx).om_card_type ,
                error_message      = NULL ,
                last_update_date   = SYSDATE ,
                last_updated_by    = gn_user_id
              WHERE ROWID          = c998_data (idx).x99x_rowid;
              v_rows_updated      := v_rows_updated + SQL%ROWCOUNT;
              UPDATE xx_ar_order_receipt_dtl
              SET matched = 'Y'
              WHERE ROWID = c998_data (idx).ord_rowid;
              -- Split the Batch for NABCRD.
              -- Check if it was already split in an earlier run.
              IF c998_data (idx).processor_id = 'NABCRD' AND SUBSTR (c998_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR (c998_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb998
                SET bank_rec_id = bank_rec_id
                  || '-'
                  || NVL(SUBSTR(c998_data (idx).om_card_type,1,1),'V') ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = c998_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, end of bank_rec_id NE -cardtype for 998 rowid ' || c998_data (idx).x99x_rowid);
              END IF; -- If NABCRD
            END IF;   -- Cash_receipt_id is not null
          END LOOP;   -- 99x_data loop
        END LOOP;
        COMMIT;
        CLOSE c998_match_inv_ord;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 998 table updated to MATCHED_AR');
        fnd_file.put_line (fnd_file.LOG,'c998_match_inv_ord END   - 998 Match Attempt for invoice number against XX_AR_ORDER_RECEIPT_DTL.');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END;
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,'c998_match_inv_ajb START - 998 Match Attempt for invoice number against XX_CE_AJB_RECEIPTS_V view.');
        all_99x_data   := all_99x_null;
        v_rows_updated := 0;
        OPEN c998_match_inv_ajb;
        LOOP
          FETCH c998_match_inv_ajb BULK COLLECT INTO all_99x_data LIMIT p_batch_size;
          EXIT
        WHEN all_99x_data.COUNT = 0;
          FOR idx IN all_99x_data.FIRST .. all_99x_data.LAST
          LOOP
            -- If matching AR record and Recon Setup is found
            IF all_99x_data (idx).cash_receipt_id IS NOT NULL
              --Defect 10048
              AND all_99x_data (idx).header_id IS NOT NULL THEN
              UPDATE xx_ce_ajb998
              SET status           = 'MATCHED_AR' ,
                ar_cash_receipt_id = all_99x_data (idx).cash_receipt_id ,
                recon_header_id    = all_99x_data (idx).header_id ,
                card_type          = all_99x_data (idx).om_card_type ,
                last_update_date   = SYSDATE ,
                last_updated_by    = gn_user_id
              WHERE ROWID          = all_99x_data (idx).x99x_rowid;
              v_rows_updated      := v_rows_updated + SQL%ROWCOUNT;
              -- Split the Batch for NABCRD.
              -- Check if it was already split in an earlier run.
              IF all_99x_data (idx).processor_id = 'NABCRD' AND SUBSTR (all_99x_data (idx).bank_rec_id, -2, 2) != '-' || NVL(SUBSTR (all_99x_data (idx).om_card_type,1,1),'V') THEN
                UPDATE xx_ce_ajb998
                SET bank_rec_id = bank_rec_id
                  || '-'
                  || NVL(SUBSTR(all_99x_data (idx).om_card_type,1,1),'V') ,
                  last_update_date = SYSDATE ,
                  last_updated_by  = gn_user_id
                WHERE ROWID        = all_99x_data (idx).x99x_rowid;
                fnd_file.put_line (fnd_file.LOG,'  NABCRD match, end of bank_rec_id NE -cardtype for 998 rowid ' || all_99x_data (idx).x99x_rowid);
              END IF; -- If NABCRD
            END IF;   -- Cash_receipt_id is not null
          END LOOP;   -- 99x_data loop
        END LOOP;
        COMMIT;
        CLOSE c998_match_inv_ajb;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 998 table updated to MATCHED_AR');
        fnd_file.put_line (fnd_file.LOG,'c998_match_inv_ajb END   - 998 Match Attempt for invoice number against XX_CE_AJB_RECEIPTS_V view.');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END;
      --always get header_id from xx_ce_recon_glact_hdr_v for unmatched records
      BEGIN
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,'c998_unmatched START - Update the Recon Header Id for all the 998 records');
        all_99x_unmatched_data := all_99x_unmatched_null;
        v_rows_updated         := 0;
        OPEN c998_unmatched;
        LOOP
          FETCH c998_unmatched BULK COLLECT
          INTO all_99x_unmatched_data LIMIT p_batch_size;
          EXIT
        WHEN all_99x_unmatched_data.COUNT = 0;
          FOR idx IN all_99x_unmatched_data.FIRST .. all_99x_unmatched_data.LAST
          LOOP
            IF all_99x_unmatched_data (idx).processor_id = 'DCV3RN' THEN
              lc_card_type                              := 'DISCOVER';
            ELSE
              lc_card_num  := SUBSTR(all_99x_unmatched_data (idx).card_num,1,2);
              lc_card_type := XX_CM_TRACK_LOG_PKG.get_card_type(all_99x_unmatched_data (idx).processor_id ,all_99x_unmatched_data (idx).ajb_file_name ,all_99x_unmatched_data (idx).provider_type ,lc_card_num);
            END IF;
            fnd_file.put_line (fnd_file.LOG,'lc_card_type : '|| lc_card_type||'  '||'provider_type: '||all_99x_unmatched_data (idx).provider_type);
            IF lc_card_type IS NULL THEN
              fnd_file.put_line (fnd_file.LOG,'Card Type is NULL for the processor_id : '|| all_99x_unmatched_data (idx).processor_id);
            ELSE
              BEGIN
                SELECT header_id
                INTO ln_recon_header_id
                FROM xx_ce_recon_glact_hdr_v hdr,
                  fnd_lookup_values lv
                WHERE lv.meaning    = lc_card_type
                AND lv.lookup_type  = 'OD_PAYMENT_TYPES'
                AND lv.enabled_flag = 'Y'
                AND lv.lookup_code  = hdr.om_card_type
                AND provider_code   = all_99x_unmatched_data (idx).processor_id;
                fnd_file.put_line (fnd_file.LOG,'recon_header_id:'|| ln_recon_header_id);
              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                fnd_file.put_line (fnd_file.LOG , 'No recon header id found for the card type : ' ||lc_card_type ||' and for the processor_id : ' || all_99x_unmatched_data (idx).processor_id );
              WHEN OTHERS THEN
                xx_ce_cc_common_pkg.od_message ('M' , 'Error/Warning:' || SQLCODE || '-' || SQLERRM );
              END;
              UPDATE xx_ce_ajb998
              SET recon_header_id = ln_recon_header_id ,
                last_update_date  = SYSDATE ,
                last_updated_by   = gn_user_id
              WHERE ROWID         = all_99x_unmatched_data (idx).x99x_rowid;
              v_rows_updated     := v_rows_updated + SQL%ROWCOUNT;
            END IF;
          END LOOP;
        END LOOP;
        COMMIT;
        CLOSE c998_unmatched;
        fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 998 table updated (recon_header_id)');
        fnd_file.put_line (fnd_file.LOG,'c998_unmatched END   - Update the Recon Header Id for all the 998 records');
        fnd_file.put_line (fnd_file.LOG, ' ');
      END;
	  BEGIN
	  fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG,'Derive Order Details of Partial processed Transactions for External Marketplaces-EBAY,WALMART,RAKUTEN');

	  DERIVE_MPL_ORDER_INFO; 

	  End;

      --Defect#33066 Update error_message for PREPROCESSED 998 records if the amount does not match
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG,'Update error message for preprocessed 998 records if the amount does not match');
      UPDATE xx_ce_ajb998 ajb998
      SET error_message  ='Transaction amount does not match with payment amount',
        last_update_date = SYSDATE,
        last_updated_by  = gn_user_id
      WHERE EXISTS
        (SELECT 'x'
        FROM xx_ar_order_receipt_dtl dtl ,
          xx_ce_recon_glact_hdr hdr ,
          fnd_lookup_values lv
        WHERE dtl.customer_receipt_reference = ajb998.invoice_num
        AND dtl.org_id                       = ajb998.org_id
        AND hdr.provider_code                = ajb998.processor_id
        AND hdr.org_id                       = ajb998.org_id
        AND (dtl.payment_amount             <> ajb998.trx_amount)
        AND lv.lookup_type                   = 'OD_PAYMENT_TYPES'
        AND lv.enabled_flag                  = 'Y'
        AND lv.meaning                       = dtl.credit_card_code
        AND lv.lookup_code                   = hdr.om_card_type
        AND dtl.receipt_date BETWEEN lv.start_date_active    - 0 AND NVL(lv.end_date_active, dtl.receipt_date + 1)
        AND dtl.receipt_date BETWEEN hdr.effective_from_date - 0 AND NVL(hdr.effective_to_date, dtl.receipt_date + 1)
        )
      AND ajb998.org_id        = gn_org_id
      AND ajb998.status        = 'PREPROCESSED'
      AND ajb998.processor_id  in ('AMAZON','EBAY','RAKUTEN','WALMART') --Modified for V2.9
      AND ajb998.ajb_file_name = NVL(p_ajb_file_name, ajb998.ajb_file_name)
      AND NOT EXISTS
        (SELECT 1
        FROM xx_ce_999_interface
        WHERE bank_rec_id = ajb998.bank_rec_id
        AND processor_id  = ajb998.processor_id
        );
      v_rows_updated := SQL%ROWCOUNT;
      fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 998 table updated (error_message - TrxAmt<>PmtAmt)');
      fnd_file.put_line (fnd_file.LOG, ' ');
      --Defect#33066 Update error_message for PREPROCESSED 998 records if transaction does not exists in ORDT
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG,'Update error message for preprocessed 998 records if transaction does not exists in ORDT');
      UPDATE xx_ce_ajb998 ajb998
      SET error_message  ='Invoice Number does not exist in ORDT',
        last_update_date = SYSDATE,
        last_updated_by  = gn_user_id
      WHERE NOT EXISTS
        (SELECT 'x'
        FROM xx_ar_order_receipt_dtl dtl ,
          xx_ce_recon_glact_hdr hdr ,
          fnd_lookup_values lv
        WHERE dtl.customer_receipt_reference = ajb998.invoice_num
        AND dtl.org_id                       = ajb998.org_id
        AND hdr.provider_code                = ajb998.processor_id
        AND hdr.org_id                       = ajb998.org_id
          --AND (dtl.payment_amount <> ajb998.trx_amount)
        AND lv.lookup_type  = 'OD_PAYMENT_TYPES'
        AND lv.enabled_flag = 'Y'
        AND lv.meaning      = dtl.credit_card_code
        AND lv.lookup_code  = hdr.om_card_type
        AND dtl.receipt_date BETWEEN lv.start_date_active    - 0 AND NVL(lv.end_date_active, dtl.receipt_date + 1)
        AND dtl.receipt_date BETWEEN hdr.effective_from_date - 0 AND NVL(hdr.effective_to_date, dtl.receipt_date + 1)
        )
      AND ajb998.org_id        = gn_org_id
      AND ajb998.status        = 'PREPROCESSED'
      AND ajb998.processor_id  in  ('AMAZON','EBAY','RAKUTEN','WALMART')--Modified for V2.9
      AND ajb998.ajb_file_name = NVL(p_ajb_file_name, ajb998.ajb_file_name)
      AND NOT EXISTS
        (SELECT 1
        FROM xx_ce_999_interface
        WHERE bank_rec_id = ajb998.bank_rec_id
        AND processor_id  = ajb998.processor_id
        );
      v_rows_updated := SQL%ROWCOUNT;
      fnd_file.put_line (fnd_file.LOG,'  ' || v_rows_updated || ' records in 998 table updated (error_message - TrxNotExists)');
      fnd_file.put_line (fnd_file.LOG, ' ');
	  commit;
    END IF; --NVL (p_file_type, 'ALL') IN ('998', 'ALL')
    fnd_file.put_line (fnd_file.LOG, ' ');
    fnd_file.put_line (fnd_file.LOG, LPAD ('-', 100, '-'));
    /* Process the 999 p_file_type */
    IF NVL (UPPER (p_file_type), 'ALL') IN ('999', 'ALL') THEN
      fnd_file.put_line (fnd_file.LOG, 'Preprocessing 999 data...');
      /* Update status */
      UPDATE xx_ce_ajb999
      SET status         = 'PREPROCESSING' ,
        last_update_date = SYSDATE ,
        last_updated_by  = gn_user_id
      WHERE status       ='NEW' --status IS NULL --modified for defect# 43424 v2.7.1
        -- AND org_id = gn_org_id -- Added for PROD Defect: 2046,1716
      AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name);
      /* Logic from xx_ce_ajb999_t and xx_ce_ajb999_v on xx_ce_ajb999 */
      /* Only open the c999_org if it is not already open */
      IF c999_org%ISOPEN THEN
        NULL;
      ELSE
        OPEN c999_org;
        fnd_file.put_line (fnd_file.LOG, 'Preprocessing 999 country/orgs.');
      END IF;
      LOOP
        /* Populate variables using cursor fetch.  No point using bulk collect as < 5 */
        FETCH c999_org
        INTO v_country_code;
        /* Keep fetching until no more records are found */
        EXIT
      WHEN NOT c999_org%FOUND;
        BEGIN
          /* Lookup the org_id for the country */
          SELECT xx_fin_country_defaults_pkg.f_org_id (territory_code) ,
            territory_code
          INTO v_org_id ,
            v_territory_code
          FROM fnd_territories
          WHERE iso_numeric_code = v_country_code;
        EXCEPTION
        WHEN OTHERS THEN
          v_org_id := NULL;
        END;
        fnd_file.put_line (fnd_file.LOG , '  Updating 999 country_code values of ' || v_country_code || ' with org_id of ' || v_org_id || ' and territory_code of ' || v_territory_code || '.' );
        /* Update org_id, territory_code */
        UPDATE xx_ce_ajb999
        SET org_id         = v_org_id ,
          territory_code   = v_territory_code ,
          last_update_date = SYSDATE ,
          last_updated_by  = gn_user_id
        WHERE status       = 'PREPROCESSING'
        AND country_code   = v_country_code;
      END LOOP;
      CLOSE c999_org;
      fnd_file.put_line(fnd_file.LOG,'Finished preprocessing 999 country/orgs.');
      fnd_file.put_line(fnd_file.LOG,'Updating 999 bank_rec_id values with -XX provider_type.');
      /* Update all bank_rec_ids */
      -- Only for NABCRD, split based on cardtype
      --Modified for V2.8
      UPDATE xx_ce_ajb999
      SET bank_rec_id = bank_rec_id
        || '-'
        || DECODE(provider_type,'AMAZON','MP',SUBSTR(provider_type,1,2))
        ||DECODE(SUBSTR(AJB_FILE_NAME,7,9),'PayPalWEB','W','PayPalPOS','P',NULL)
        || '-'
        || territory_code ,
        last_update_date = SYSDATE ,
        last_updated_by  = gn_user_id
      WHERE status       = 'PREPROCESSING'
      AND org_id         = gn_org_id -- Added for PROD Defect: 2046,1716
      AND processor_id  != 'NABCRD'
      AND ajb_file_name  = NVL (p_ajb_file_name, ajb_file_name)
      AND NOT EXISTS
        (SELECT 1
        FROM xx_fin_translatevalues vals,
          xx_fin_translatedefinition defn
        WHERE defn.translate_id   = vals.translate_id
        AND defn.translation_name = 'OD_CE_BANK_REC_PROV_TYPE'
        AND vals.source_value1    =provider_type
        AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
        AND SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
        AND vals.enabled_flag = 'Y'
        AND defn.enabled_flag = 'Y'
        );
      --Modified for V2.8
      UPDATE xx_ce_ajb999
      SET bank_rec_id = bank_rec_id
        || '-'
        || DECODE(provider_type,'AMAZON','MP',SUBSTR(provider_type,1,2))
        || '-'
        || territory_code
        || '-'
        || NVL(SUBSTR(cardtype,1,1),'V') ,
        last_update_date = SYSDATE ,
        last_updated_by  = gn_user_id
      WHERE status       = 'PREPROCESSING'
      AND org_id         = gn_org_id -- Added for PROD Defect: 2046,1716
      AND processor_id   = 'NABCRD'
      AND ajb_file_name  = NVL (p_ajb_file_name, ajb_file_name)
      AND NOT EXISTS
        (SELECT 1
        FROM xx_fin_translatevalues vals,
          xx_fin_translatedefinition defn
        WHERE defn.translate_id   = vals.translate_id
        AND defn.translation_name = 'OD_CE_BANK_REC_PROV_TYPE'
        AND vals.source_value1    =provider_type
        AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
        AND SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
        AND vals.enabled_flag = 'Y'
        AND defn.enabled_flag = 'Y'
        );
      --Modified for V2.8
      FOR rec IN cr_999_bank_Rec_prov_type(p_ajb_file_name,gn_org_id)
      LOOP
        UPDATE xx_ce_ajb999
        SET bank_rec_id = bank_rec_id
          || '-MP-'
          ||rec.provider_short_name
          || '-'
          || territory_code ,
          last_update_date = SYSDATE ,
          last_updated_by  = gn_user_id
        WHERE status       = 'PREPROCESSING'
        AND org_id         = gn_org_id
        AND ajb_file_name  = NVL (p_ajb_file_name, ajb_file_name)
        AND provider_type  =rec.provider_type;
      END LOOP;
      fnd_file.put_line(fnd_file.LOG,'Finished preprocessing 999 bank_rec_id values with -XX provider_type.');
      /* Only open the c999_currency if it is not already open */
      IF c999_currency%ISOPEN THEN
        NULL;
      ELSE
        OPEN c999_currency;
        fnd_file.put_line (fnd_file.LOG, 'Preprocessing 999 currencies.');
      END IF;
      LOOP
        /* Populate variables using cursor fetch.  No point using bulk collect as < 5 */
        FETCH c999_currency
        INTO v_currency_code;
        /* Keep fetching until no more records are found */
        EXIT
      WHEN NOT c999_currency%FOUND;
        BEGIN
          /* Lookup the currency for the country */
          SELECT currency_code
          INTO v_currency
          FROM fnd_currencies
          WHERE attribute1 = v_currency_code;
        EXCEPTION
        WHEN OTHERS THEN
          v_currency := NULL;
        END;
        fnd_file.put_line (fnd_file.LOG,'Updating 999 currency_code values of ' || v_currency_code || ' with currency of ' || v_currency || '.');
        /* Update the source value */
        UPDATE xx_ce_ajb999
        SET currency       = v_currency ,
          last_update_date = SYSDATE ,
          last_updated_by  = gn_user_id
        WHERE status       = 'PREPROCESSING'
        AND currency_code  = v_currency_code;
      END LOOP;
      CLOSE c999_currency;
      fnd_file.put_line (fnd_file.LOG,'Finished preprocessing 999 currencies.');
      /* Only open the c999_bank if it is not already open */
      IF c999_bank%ISOPEN THEN
        NULL;
      ELSE
        OPEN c999_bank;
        fnd_file.put_line (fnd_file.LOG, 'Preprocessing 999 bank_rec_ids.');
      END IF;
      LOOP
        /* Populate variables using cursor fetch */
        FETCH c999_bank
        INTO v_bank_rec_id;
        /* Keep fetching until no more records are found */
        EXIT
      WHEN NOT c999_bank%FOUND;
        BEGIN
          v_recon_date := get_recon_date (v_bank_rec_id);
        EXCEPTION
        WHEN OTHERS THEN
          BEGIN
            v_recon_date := TO_DATE(SUBSTR(v_bank_rec_id,1,8),'YYYYMMDD');
          EXCEPTION
          WHEN OTHERS THEN
            v_recon_date := TRUNC (SYSDATE);
          END;
        END;
        fnd_file.put_line (fnd_file.LOG,'Updating 999 bank_rec_id values of ' || v_bank_rec_id || ' with recon_date of ' || v_recon_date || '.');
        /* Update recon_date */
        UPDATE xx_ce_ajb999
        SET recon_date     = v_recon_date ,
          last_update_date = SYSDATE ,
          last_updated_by  = gn_user_id
        WHERE status       = 'PREPROCESSING'
        AND bank_rec_id    = v_bank_rec_id;
      END LOOP;
      CLOSE c999_bank;
      fnd_file.put_line (fnd_file.LOG,'Updating 999 NULL recon_date values with ' || TRUNC (SYSDATE) || '.' );
      /* Update recon_date */
      UPDATE xx_ce_ajb999
      SET recon_date     = TRUNC (SYSDATE) ,
        last_update_date = SYSDATE ,
        last_updated_by  = gn_user_id
      WHERE status       = 'PREPROCESSING'
      AND org_id         = gn_org_id -- Added for PROD Defect: 2046,1716
      AND recon_date    IS NULL;
      fnd_file.put_line(fnd_file.LOG,'Updating 999 invalid card types to provider defaults.');
      /* Update cardtype */
      UPDATE xx_ce_ajb999 a
      SET cardtype       = TRIM (cardtype) ,
        last_update_date = SYSDATE ,
        last_updated_by  = gn_user_id
      WHERE status       = 'PREPROCESSING'
      AND org_id         = gn_org_id -- Added for PROD Defect: 2046,1716
      AND cardtype      != TRIM (cardtype);
      BEGIN
        all_99x_data := all_99x_null;
        FOR bad_999_cardtypes_rec IN c999_no_cardtype
        LOOP
          lc_default_cardtype := xx_ce_cc_common_pkg.get_default_card_type (bad_999_cardtypes_rec.processor_id ,gn_org_id --Added for Defect #1061
          );
          UPDATE xx_ce_ajb999 a
          SET cardtype       = lc_default_cardtype ,
            last_update_date = SYSDATE ,
            last_updated_by  = gn_user_id
          WHERE ROWID        = bad_999_cardtypes_rec.row_id;
        END LOOP;
      END;
      fnd_file.put_line (fnd_file.LOG,'Updating status of all 999 preprocessed records.');
      /* Update all bank_rec_ids and status */
      UPDATE xx_ce_ajb999
      SET status         = 'PREPROCESSED' ,
        last_update_date = SYSDATE ,
        last_updated_by  = gn_user_id
      WHERE status       = 'PREPROCESSING'
      AND org_id         = gn_org_id                             -- Added for PROD Defect: 2046,1716
      AND ajb_file_name  = NVL (p_ajb_file_name, ajb_file_name); --Added for QC 38437
      fnd_file.put_line(fnd_file.LOG,'Finished updating status of all 999 preprocessed records.');
      fnd_file.put_line (fnd_file.LOG, '999 data preprocessed!');
      /* End of logic from xx_ce_ajb999_t and xx_ce_ajb999_v on xx_ce_ajb999, commit */
      COMMIT;
    END IF; -- NVL (p_file_type, 'ALL') IN ('999', ALL)
    fnd_file.put_line (fnd_file.LOG, ' ');
    fnd_file.put_line (fnd_file.LOG, LPAD ('-', 100, '-'));
    fnd_file.put_line (fnd_file.LOG,'Finishing xx_ce_ajb_inbound_preprocess at ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
  END XX_CE_AJB_PREPROCESS;
END xx_ce_cc_preprocess_pkg;
/
show errors;