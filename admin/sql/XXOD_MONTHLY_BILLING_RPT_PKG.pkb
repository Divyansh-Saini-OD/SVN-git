create or replace
PACKAGE BODY XXOD_MONTHLY_BILLING_RPT_PKG
/* $Header: XXOD_MONTHLY_BILLING_RPT_PKG.plb 110.1 11/10/04 16:49:23  Saikumar Reddy$ */
/*==========================================================================+
|   Copyright (c) 1993 Oracle Corporation Belmont, California, USA          |
|                          All rights reserved.                             |
+===========================================================================+
|                                                                           |
| File Name    : XXOD_MONTHLY_BILLING_RPT_PKG.plb                           |
| DESCRIPTION  : This package contains procedures used to get the All       |
|         Office Depot Monthly Billing Report details                       |
|                                                                           |
|                                                                           |
| Parameters   : From Date and To Date                                      |
|                                                                           |
|                                                                           |
| History:                                                                  |
|                                                                           |
|    Created By      Saikumar Reddy                                         |
|    creation date   10-Feb-2012                                            |
|    Defect#         13644                                                  |
|                                                                           |
|Version  Date         Author                Remarks                        |
|=======  ===========  =============         ============================== |      
| 1       10-Feb-2012  Saikumar Reddy        First release                  |
| 1.1     31-Jul-2013  Ankit Arora           Added Hint to improve the      |
|                                            performance of report          |
|                                            QC Defect - 24718                |                                   
+==========================================================================*/
AS
      l_email_address   fnd_concurrent_requests.argument1%TYPE   := NULL;
      TYPE rec_type1 IS RECORD(account_number hz_cust_accounts.account_number%TYPE,
      inv_count    NUMBER,
      inv_amount ra_customer_trx_lines_all.extended_amount%TYPE,
      actual_bill_date DATE,
      delivery_method xx_ar_invoice_freq_history.doc_delivery_method%TYPE,
      direct_indirect xx_cdh_cust_acct_ext_b.c_ext_attr7%TYPE,
      document_id xx_ar_invoice_freq_history.document_id%TYPE,
      customer_doc_id xx_ar_invoice_freq_history.customer_document_id%TYPE,
      paydoc_infodoc VARCHAR2(10),
      frequency ra_terms_vl.attribute1%TYPE,
      payment_term ra_terms_vl.attribute2%TYPE,
      payment_term_name ra_terms_vl.name%TYPE,
      account_name VARCHAR2(720)
      );
    temp_rec rec_type1;
      TYPE table_type1 IS TABLE OF temp_rec%TYPE;
      TYPE rec_type2 IS RECORD(account_number hz_cust_accounts.account_number%TYPE,
      cons_inv_id ar_cons_inv_all.cons_inv_id%TYPE,
      inv_count    NUMBER,
      inv_amount ra_customer_trx_lines_all.extended_amount%TYPE,
      actual_bill_date DATE,
      delivery_method xx_ar_invoice_freq_history.doc_delivery_method%TYPE,
      direct_indirect xx_cdh_cust_acct_ext_b.c_ext_attr7%TYPE,
      document_id xx_ar_invoice_freq_history.document_id%TYPE,
      customer_doc_id xx_ar_invoice_freq_history.customer_document_id%TYPE,
      paydoc_infodoc VARCHAR2(10),
      frequency ra_terms_vl.attribute1%TYPE,
      payment_term ra_terms_vl.attribute2%TYPE,
      payment_term_name ra_terms_vl.name%TYPE,
      account_name VARCHAR2(720)
      );
    temp_rec1 rec_type2;
    TYPE table_type2 IS TABLE OF temp_rec1%TYPE;
    lc_file_handle       UTL_FILE.file_type;
    p_file_name          VARCHAR2(100);      
    lv_col_title1        VARCHAR2(6000);
    p_file_path          VARCHAR2(200); 
    lv_col_title         VARCHAR2(1000);
    lc_errormsg          VARCHAR2(1000);    
   PROCEDURE get_email_address
   IS
      CURSOR c_main
      IS
         SELECT flv.meaning
           FROM fnd_lookup_values_vl flv
          WHERE flv.lookup_type = 'XXOD_AR_MONTHLY_BILLING'
            AND flv.enabled_flag = 'Y'
            AND SYSDATE BETWEEN flv.start_date_active
                            AND NVL (flv.end_date_active, SYSDATE + 1);
   BEGIN
      IF l_email_address IS NULL
      THEN
         FOR i_main IN c_main
         LOOP
            IF l_email_address IS NULL
            THEN
               l_email_address := i_main.meaning;
            ELSE
               l_email_address := l_email_address || ', ' || i_main.meaning;
            END IF;
         END LOOP;
      END IF;
   END get_email_address;
/**
Added the code to copy the output to XXFIN_OUT directory
**/
PROCEDURE XXOD_COMMON_FILE_COPY(
                                   p_errbuf     IN OUT VARCHAR2,
                                   p_retcode     IN OUT NUMBER,
                                   V_REQUEST_ID     NUMBER,
                                   V_FILENAME         VARCHAR2
                                   )
   IS
   ln_copy_request_id           NUMBER;
   ln_outfile                 VARCHAR2(255);
   lc_dba_dir_path          VARCHAR2(255);
   lc_wait                  BOOLEAN;   
   lc_conc_phase            VARCHAR2(50);
   lc_conc_status           VARCHAR2(50);
   lc_dev_phase             VARCHAR2(50);
   lc_dev_status            VARCHAR2(50);
   lc_conc_message          VARCHAR2(50);   
   ln_outpath               VARCHAR2(255);
   BEGIN
   
    BEGIN
          SELECT outfile_name 
          INTO ln_outfile
          FROM FND_CONCURRENT_REQUESTS
          where request_id = V_REQUEST_ID;        
      EXCEPTION
         WHEN OTHERS
         THEN
            ln_outfile := NULL;
    END;
   
    BEGIN
         SELECT directory_path
           INTO lc_dba_dir_path
           FROM dba_directories
          WHERE directory_name = 'XXFIN_OUT';
      EXCEPTION
         WHEN OTHERS
         THEN
            lc_dba_dir_path := NULL;
    END;
    IF ln_outfile IS NOT NULL THEN
     --ln_outpath := '/home/u595997/o'||V_REQUEST_ID||'.out';
     ln_outpath := lc_dba_dir_path||'/'||V_FILENAME||'_o'||V_REQUEST_ID||'.out';     
     ln_copy_request_id :=fnd_request.submit_request(application => 'XXFIN',
                                       program     => 'XXCOMFILCOPY',
                                       description => 'OD: Common File Copy',
                                       start_time  => to_char(SYSDATE,
                                                              'DD-MON-YY HH24:MI:SS'),
                                       sub_request => FALSE,
                                       argument1   => ln_outfile,
                                       argument2   => ln_outpath);
         COMMIT;

         IF ln_copy_request_id IS NULL OR ln_copy_request_id = 0
         THEN
            fnd_file.put_line
                      (fnd_file.LOG,
                       'Failed to submit the Standard Common File Copy Program'
                      );
         ELSE              
            lc_wait := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id  => ln_copy_request_id
                                                       ,interval   => '2'
                                                       ,max_wait   => NULL
                                                       ,phase      => lc_conc_phase
                                                       ,status     => lc_conc_status
                                                       ,dev_phase  => lc_dev_phase
                                                       ,dev_status => lc_dev_status
                                                       ,message    => lc_conc_message
                                                       );                                               
         END IF;
            fnd_file.put_line
                      (fnd_file.LOG,
                       'Request Outfile Path'||ln_outfile);                                                       
            fnd_file.put_line
                      (fnd_file.LOG,
                       'Copied to location'||ln_outpath);    
         IF TRIM(UPPER((lc_conc_status))) = 'ERROR'
         THEN
            p_retcode := 2;
            p_errbuf :=
                  'File Copy program Failed : '
               || V_FILENAME
               || ': Please check the Log file for Request ID : '
               || V_REQUEST_ID;
            fnd_file.put_line (fnd_file.LOG,
                               p_errbuf || ' : ' || SQLCODE || ' : '
                               || SQLERRM
                              );
         ELSE
            fnd_file.put_line
                      (fnd_file.LOG,
                       'Request Outfile Path'||ln_outfile);                                                       
            fnd_file.put_line
                      (fnd_file.LOG,
                       'Copied to location'||ln_outpath);         
         END IF;
         
     END IF;         
   
   END XXOD_COMMON_FILE_COPY;
   
   PROCEDURE xxod_drop_tables_program (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   VARCHAR2,
      p_table_name  IN       VARCHAR2
   )
   IS
   BEGIN
   
     EXECUTE IMMEDIATE 'DROP TABLE '|| p_table_name;
     
     EXCEPTION
     WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Table '||p_table_name||' Does not Exist');     
   END xxod_drop_tables_program;
   PROCEDURE xxod_create_tables_program (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   VARCHAR2,
      p_from_date   IN       VARCHAR2,
      p_to_date     IN       VARCHAR2,
      p_short_code  IN       VARCHAR2 
   )
   IS
   l_temp  VARCHAR2(30000);
   l_from_date  DATE;
   l_to_date    DATE;
   BEGIN
                    
    l_from_date := fnd_date.canonical_to_date(p_from_date);
    l_to_date := fnd_date.canonical_to_date(p_to_date);
       l_to_date := l_to_date+1;
    fnd_file.put_line(fnd_file.LOG,'moified_Date for a change'||l_to_date);-- Ankit
    
    --xxod_drop_tables_program(p_errbuf,p_retcode,'xx_xaifh_nov11');    
        
/*    l_temp := 'CREATE TABLE xx_xaifh_nov11 PARALLEL
                AS
                SELECT /*+ PARALLEL(xaifh) */  /*
                *FROM xx_ar_invoice_freq_history xaifh
                WHERE actual_print_date BETWEEN '''||l_from_date||''' AND '''||l_to_date||'''';
*/                
    --EXECUTE IMMEDIATE l_temp;
    IF p_short_code = 'XXOD_CONS_DTL_US_PAYDOC' OR  p_short_code = 'XXOD_CONS_DTL_CA_PAYDOC' THEN
    xxod_drop_tables_program(p_errbuf,p_retcode,'xx_cons_pd_us_ca_int');      /* Defect -24718 | Hint Added to improve performance for the table xx_cons_pd_us_ca_int creation - Suggested by ERP Engineering team*/
    l_temp := 'CREATE TABLE xx_cons_pd_us_ca_int
AS
SELECT /*+ LEADING(ARCI) parallel(arci) index(rcta RA_CUSTOMER_TRX_U1) FULL(XCCAEB) PARALLEL(XCCAEB) */ 
    HCA.account_number account# ,arci.ORG_ID ,
    ARCI.cons_inv_id cons_inv_id ,
    RCTA.trx_number invoice# ,
    RCTA.customer_trx_id r_customer_trx_id, RCTTA.type r_type, RCTA.attribute14 r_attribute14, 0 amount,
    /*(
    (SELECT NVL(SUM(RCTL.extended_amount),0)
    FROM apps.ra_customer_trx_lines_all RCTL
    WHERE RCTL.customer_trx_id = RCTA.customer_trx_id
    ) - DECODE(RCTTA.type,''INV'',
    (SELECT NVL(SUM(OP.payment_amount),0)
    FROM apps.oe_payments OP
    WHERE RCTA.attribute14 = OP.header_id
    ) ,''CM'',
    (SELECT NVL(SUM(XORTA.credit_amount),0)
    FROM apps.xx_om_return_tenders_all XORTA
    WHERE XORTA.header_id = RCTA.attribute14
    ) ,0)) amount ,*/
    TO_DATE(ARCI.attribute1)-1 actual_bill_date ,
    NVL2(XCCAEB.c_ext_attr4,''SPECIAL HANDLING'' ,DECODE(XCCAEB.c_ext_attr3,''PRINT'',''Certegy'' ,''ELEC'',''Ebill'' ,''ePDF'', ''ePDF'' ,''eXLS'', ''eXLS'') ) delivery_method ,
    DECODE(XCCAEB.c_ext_attr7,''Y'',''DIRECT'' ,''N'',''INDIRECT'') direct_indirect ,
    XCCAEB.n_ext_attr1 document_id ,
    XCCAEB.n_ext_attr2 customer_doc_id ,
    DECODE(XCCAEB.c_ext_attr2,''Y'',''PAYDOC'' ,''N'',''INFODOC'') paydoc_infodoc ,
    RT.attribute1 frequency ,
    RT.attribute2 payment_term ,
    RT.name payment_term_name ,
    HCA.account_name account_name
  FROM apps.ar_cons_inv_trx_all ACITA ,
    apps.ar_cons_inv_all ARCI ,
    apps.ra_customer_trx_all RCTA ,
    apps.hz_cust_accounts HCA ,
    apps.xx_cdh_cust_acct_ext_b XCCAEB ,
    apps.ra_terms RT ,
    apps.ra_cust_trx_types_all RCTTA
  WHERE ACITA.cons_inv_id         = ARCI.cons_inv_id
  AND ARCI.customer_id            = HCA.cust_account_id
  AND HCA.cust_account_id         = RCTA.bill_to_customer_id
  AND RCTA.bill_to_customer_id    = XCCAEB.cust_account_id
  AND ACITA.customer_trx_id       = RCTA.customer_trx_id
  AND RT.name                     = XCCAEB.c_ext_attr14
  AND RCTTA.cust_trx_type_id      = RCTA.cust_trx_type_id
  AND ((ARCI.attribute2          IS NOT NULL )
  OR(ARCI.attribute4             IS NOT NULL)
  OR (ARCI.attribute10           IS NOT NULL)
  OR (ARCI.attribute15           IS NOT NULL))
  --AND ARCI.org_id                 =403
  AND ACITA.transaction_type     IN (''INVOICE'',''CREDIT_MEMO'')
  AND HCA.status                  = ''A''
  AND XCCAEB.ATTR_GROUP_ID        = 166
  AND XCCAEB.c_ext_attr2          = ''Y''
  AND XCCAEB.c_ext_attr1          = ''Consolidated Bill''
  --AND ARCI.concurrent_request_id IN(SELECT DISTINCT concurrent_request_id
  -- FROM apps.ar_cons_inv_all
  --WHERE 
  and arci.creation_date >= '''||l_from_date||''' AND  arci.creation_date < '''||l_to_date||'''
 --AND arci.ORG_ID       = 403
 AND arci.ATTRIBUTE13 IS NOT NULL
 --) 
    -- Please give the Request_IDs from Sub-Query SubQuery5_Req_ID given below
  AND ARCI.attribute1     >= d_ext_attr1
  AND (XCCAEB.d_ext_attr2 IS NULL
  OR ARCI.attribute1      <= XCCAEB.d_ext_attr2)';
   EXECUTE IMMEDIATE l_temp;
   l_temp := 'DECLARE
            CURSOR c_inv_cm
            is
            select rowid row_id,r_type,r_customer_trx_id,r_attribute14 from xx_cons_pd_us_ca_int
            where r_type is not null;
            ln_amount number :=0;
            BEGIN
            for lr_rec in c_inv_cm
            loop
            select ( 
                (SELECT NVL(SUM(RCTL.extended_amount),0) 
                FROM apps.ra_customer_trx_lines_all RCTL 
                WHERE RCTL.customer_trx_id = lr_rec.r_customer_trx_id 
                ) - DECODE(lr_rec.r_type,''INV'', 
                (SELECT NVL(SUM(OP.payment_amount),0) 
                FROM apps.oe_payments OP 
                WHERE lr_rec.r_attribute14 = OP.header_id 
                ) ,''CM'', 
                (SELECT NVL(SUM(XORTA.credit_amount),0) 
                FROM apps.xx_om_return_tenders_all XORTA 
                WHERE XORTA.header_id = lr_rec.r_attribute14 
                ) ,0))
                into ln_amount
                from dual;
                update xx_cons_pd_us_ca_int
                set amount = ln_amount
                where rowid  = lr_rec.row_id;
                ln_amount := 0;
            end loop;
            commit;
            END;';
    EXECUTE IMMEDIATE l_temp;
    IF p_short_code = 'XXOD_CONS_DTL_US_PAYDOC'    THEN
   xxod_drop_tables_program(p_errbuf,p_retcode,'xx_con_pd_us');
    l_temp := 'CREATE TABLE xx_con_pd_us
                AS
                SELECT account# ,
                  cons_inv_id ,
                  COUNT(invoice#) invoice_count ,
                  SUM(amount) amount ,
                  actual_bill_date ,
                  delivery_method ,
                  direct_indirect ,
                  document_id ,
                  customer_doc_id ,
                  paydoc_infodoc ,
                  frequency ,
                  payment_term ,
                  payment_term_name ,
                  TRANSLATE(account_name,'',''
                  ||''&'','' ''
                  ||'' '') account_name
                FROM
                  (
                SELECT
                ACCOUNT#
                ,CONS_INV_ID
                ,INVOICE#
                ,AMOUNT
                ,ACTUAL_BILL_DATE
                ,DELIVERY_METHOD
                ,DIRECT_INDIRECT
                ,DOCUMENT_ID
                ,CUSTOMER_DOC_ID
                ,PAYDOC_INFODOC
                ,FREQUENCY
                ,PAYMENT_TERM
                ,PAYMENT_TERM_NAME
                ,ACCOUNT_NAME
                FROM xx_cons_pd_us_ca_int 
                WHERE org_id = 404
                )
                GROUP BY account# ,
                  cons_inv_id ,
                  actual_bill_date ,
                  delivery_method ,
                  direct_indirect ,
                  document_id ,
                  customer_doc_id ,
                  paydoc_infodoc ,
                  frequency ,
                  payment_term ,
                  payment_term_name ,
                  account_name';
        EXECUTE IMMEDIATE l_temp;
        END IF;
        IF p_short_code = 'XXOD_CONS_DTL_CA_PAYDOC' THEN
    xxod_drop_tables_program(p_errbuf,p_retcode,'xx_con_pd_ca');    
        l_temp := 'CREATE TABLE xx_con_pd_ca
                    AS
                    SELECT account# ,
                      cons_inv_id ,
                      COUNT(invoice#) invoice_count ,
                      SUM(amount) amount ,
                      actual_bill_date ,
                      delivery_method ,
                      direct_indirect ,
                      document_id ,
                      customer_doc_id ,
                      paydoc_infodoc ,
                      frequency ,
                      payment_term ,
                      payment_term_name ,
                      TRANSLATE(account_name,'',''
                      ||''&'','' ''
                      ||'' '') account_name
                    FROM
                      (
                    SELECT
                    ACCOUNT#
                    ,CONS_INV_ID
                    ,INVOICE#
                    ,AMOUNT
                    ,ACTUAL_BILL_DATE
                    ,DELIVERY_METHOD
                    ,DIRECT_INDIRECT
                    ,DOCUMENT_ID
                    ,CUSTOMER_DOC_ID
                    ,PAYDOC_INFODOC
                    ,FREQUENCY
                    ,PAYMENT_TERM
                    ,PAYMENT_TERM_NAME
                    ,ACCOUNT_NAME
                    FROM xx_cons_pd_us_ca_int 
                    WHERE org_id = 403
                    )
                    GROUP BY account# ,
                      cons_inv_id ,
                      actual_bill_date ,
                      delivery_method ,
                      direct_indirect ,
                      document_id ,
                      customer_doc_id ,
                      paydoc_infodoc ,
                      frequency ,
                      payment_term ,
                      payment_term_name ,
                      account_name';
            EXECUTE IMMEDIATE l_temp;            
        END IF;
    END IF;
    
    IF p_short_code = 'XXOD_CONS_DTL_US_INFODOC' THEN
        xxod_drop_tables_program(p_errbuf,p_retcode,'xx_cons_ic_us_int');
        xxod_drop_tables_program(p_errbuf,p_retcode,'xx_con_ic_us');        

        
        l_temp := 'CREATE TABLE xx_cons_ic_us_int
        AS
        SELECT HCA.account_number account# ,
            XACBHA.cons_inv_id cons_inv_id ,
            RCTA.trx_number invoice# ,
            RCTA.customer_trx_id r_customer_trx_id, RCTTA.type r_type, RCTA.attribute14 r_attribute14, 0 amount, 
            XACBHA.print_date actual_bill_date ,
            ''Certegy'' delivery_method ,
            DECODE(XCCAEB.c_ext_attr7,''Y'',''DIRECT'' ,''N'',''INDIRECT'') direct_indirect ,
            XACBHA.document_id document_id ,
            XACBHA.cust_doc_id customer_doc_id ,
            DECODE(XCCAEB.c_ext_attr2,''Y'',''PAYDOC'' ,''N'',''INFODOC'') paydoc_infodoc ,
            RT.attribute1 frequency ,
            RT.attribute2 payment_term ,
            RT.name payment_term_name ,
            HCA.account_name account_name
          FROM apps.xx_ar_cons_bills_history_all XACBHA ,
            apps.ra_customer_trx_all RCTA ,
            apps.hz_cust_accounts HCA ,
            apps.xx_cdh_cust_acct_ext_b XCCAEB ,
            apps.ra_terms RT ,
            apps.ra_cust_trx_types_all RCTTA
          WHERE XACBHA.customer_id     = HCA.cust_account_id
          AND HCA.cust_account_id      = RCTA.bill_to_customer_id
          AND RCTA.bill_to_customer_id = XCCAEB.cust_account_id
          AND RCTA.customer_trx_id     = XACBHA.attribute1
          AND RT.name                  = XCCAEB.c_ext_attr14
          AND RCTTA.cust_trx_type_id   = RCTA.cust_trx_type_id
          AND XACBHA.cust_doc_id       = XCCAEB.n_ext_attr2
          AND XACBHA.process_flag      =''Y''
          AND HCA.status               = ''A''
          AND XCCAEB.ATTR_GROUP_ID     = 166
          AND XCCAEB.c_ext_attr2       = ''N''
          AND XACBHA.paydoc            =''N''
          AND XCCAEB.c_ext_attr1       = ''Consolidated Bill''
          AND XACBHA.attribute8        = ''INV_IC''
          AND XACBHA.org_id            =404
          AND XACBHA.print_date >= '''||l_from_date||''' AND XACBHA.print_date < '''||l_to_date||'''
          UNION ALL
          SELECT HCA.account_number account# ,
            XACBHA.cons_inv_id cons_inv_id ,
            RCTA.trx_number invoice# ,
            RCTA.customer_trx_id r_customer_trx_id, RCTTA.type r_type, RCTA.attribute14 r_attribute14, 0 amount, 
            XACBHA.print_date actual_bill_date ,
            ''Certegy'' delivery_method ,
            DECODE(XCCAEB.c_ext_attr7,''Y'',''DIRECT'' ,''N'',''INDIRECT'') direct_indirect ,
            XACBHA.document_id document_id ,
            XACBHA.cust_doc_id customer_doc_id ,
            DECODE(XCCAEB.c_ext_attr2,''Y'',''PAYDOC'' ,''N'',''INFODOC'') paydoc_infodoc ,
            RT.attribute1 frequency ,
            RT.attribute2 payment_term ,
            RT.name payment_term_name ,
            HCA.account_name account_name
          FROM apps.xx_ar_cons_bills_history_all XACBHA ,
            apps.ra_customer_trx_all RCTA ,
            apps.hz_cust_accounts HCA ,
            apps.xx_cdh_cust_acct_ext_b XCCAEB ,
            apps.ra_terms RT ,
            apps.xx_ar_cbi_trx_history xacth ,
            apps.ra_cust_trx_types_all RCTTA
          WHERE XACBHA.customer_id     = HCA.cust_account_id
          AND HCA.cust_account_id      = RCTA.bill_to_customer_id
          AND RCTA.bill_to_customer_id = XCCAEB.cust_account_id
          AND XACBHA.thread_id         = xacth.request_id
          AND XACBHA.cons_inv_id       = xacth.cons_inv_id
          AND RCTA.customer_trx_id     = xacth.customer_trx_id
          AND RT.name                  = XCCAEB.c_ext_attr14
          AND RCTTA.cust_trx_type_id   = RCTA.cust_trx_type_id
          AND XACBHA.cust_doc_id       = XCCAEB.n_ext_attr2
          AND XACBHA.process_flag      =''Y''
          AND HCA.status               = ''A''
          AND XCCAEB.ATTR_GROUP_ID     = 166
          AND XCCAEB.c_ext_attr2       = ''N''
          AND XACBHA.paydoc            =''N''
          AND XCCAEB.c_ext_attr1       = ''Consolidated Bill''
          AND XACBHA.attribute8        = ''PAYDOC_IC''
          AND xacth.inv_type NOT      IN (''SOFTHDR_TOTALS'' ,''BILLTO_TOTALS'' ,''GRAND_TOTAL'')
          AND xacth.attribute1         = ''PAYDOC_IC''
          AND XACBHA.org_id            =404
          AND XACBHA.print_date >= '''||l_from_date||''' AND XACBHA.print_date < '''||l_to_date||''' 
          UNION ALL
          SELECT HCA.account_number account# ,
            XAGBLA.cons_inv_id cons_inv_id ,
            RCTA.trx_number invoice# ,
            RCTA.customer_trx_id r_customer_trx_id, RCTTA.type r_type, RCTA.attribute14 r_attribute14, 0 amount, 
            XAGBLA.cut_off_date-1 actual_bill_date ,
            ''Ebill'' delivery_method ,
            DECODE(XCCAEB.c_ext_attr7,''Y'',''DIRECT'' ,''N'',''INDIRECT'') direct_indirect ,
            XCCAEB.n_ext_attr1 document_id ,
            XCCAEB.n_ext_attr2 customer_doc_id ,
            DECODE(XCCAEB.c_ext_attr2,''Y'',''PAYDOC'' ,''N'',''INFODOC'') paydoc_infodoc ,
            RT.attribute1 frequency ,
            RT.attribute2 payment_term ,
            RT.name payment_term_name ,
            HCA.account_name account_name
          FROM apps.xx_ar_gen_bill_lines_all XAGBLA ,
            apps.ra_customer_trx_all RCTA ,
            apps.hz_cust_accounts HCA ,
            apps.xx_cdh_cust_acct_ext_b XCCAEB ,
            apps.ra_terms RT ,
            apps.ra_cust_trx_types_all RCTTA
          WHERE XAGBLA.customer_id     = HCA.cust_account_id
          AND HCA.cust_account_id      = RCTA.bill_to_customer_id
          AND RCTA.bill_to_customer_id = XCCAEB.cust_account_id
          AND RCTA.customer_trx_id     = XAGBLA.customer_trx_id
          AND RT.name                  = XCCAEB.c_ext_attr14
          AND RCTTA.cust_trx_type_id   = RCTA.cust_trx_type_id
          AND XAGBLA.processed_flag    =''Y''
          AND HCA.status               = ''A''
          AND XCCAEB.ATTR_GROUP_ID     = 166
          AND XCCAEB.c_ext_attr2       = ''N''
          AND XCCAEB.c_ext_attr1       = ''Consolidated Bill''
          AND XCCAEB.c_ext_attr3       = ''ELEC''
          AND XAGBLA.org_id            = 404
          AND XAGBLA.n_ext_attr1       = XCCAEB.n_ext_attr2 
          AND XAGBLA.creation_date >= '''||l_from_date||''' AND XAGBLA.creation_date < '''||l_to_date||'''
          UNION ALL
          SELECT XAECHH.oracle_account_number account# ,
            XAECHH.cons_inv_id cons_inv_id ,
            XAECHH.invoice_number invoice# ,
            0 r_customer_trx_id, '''' r_type, '''' r_attribute14, (XAECHH.original_invoice_amount - total_gift_card_amount) amount ,
            XAECHH.invoice_bill_date actual_bill_date ,
            XAECHH.billdocs_delivery_method delivery_method ,
            DECODE(XAECHH.direct_flag,''D'',''DIRECT'' ,''I'',''INDIRECT'') direct_indirect ,
            XAECHH.mbs_doc_id document_id ,
            XAECHH.cust_doc_id customer_doc_id ,
            DECODE(XAECHH.document_type,''Paydoc'',''PAYDOC'' ,''Infocopy'',''INFODOC'') paydoc_infodoc ,
            XAECHH.payment_term_frequency frequency ,
            XAECHH.payment_term_report_day payment_term ,
            XAECHH.payment_term_string payment_term_name ,
            XAECHH.customer_name account_name
          FROM apps.xx_ar_ebl_cons_hdr_hist XAECHH
          WHERE XAECHH.document_type = ''Infocopy''
          AND XAECHH.org_id      = 404
          AND XAECHH.creation_date >= '''||l_from_date||''' AND XAECHH.creation_date < '''||l_to_date||''''; 
                      
        EXECUTE IMMEDIATE l_temp;

        
        l_temp := 'DECLARE
                    CURSOR c_inv_cm
                    is
                    select rowid row_id,r_type,r_customer_trx_id,r_attribute14 from xx_cons_ic_us_int
                    where r_type is not null;
                    ln_amount number :=0;
                    BEGIN
                    for lr_rec in c_inv_cm
                    loop
                    select ( 
                        (SELECT NVL(SUM(RCTL.extended_amount),0) 
                        FROM apps.ra_customer_trx_lines_all RCTL 
                        WHERE RCTL.customer_trx_id = lr_rec.r_customer_trx_id 
                        ) - DECODE(lr_rec.r_type,''INV'', 
                        (SELECT NVL(SUM(OP.payment_amount),0) 
                        FROM apps.oe_payments OP 
                        WHERE lr_rec.r_attribute14 = OP.header_id 
                        ) ,''CM'', 
                        (SELECT NVL(SUM(XORTA.credit_amount),0) 
                        FROM apps.xx_om_return_tenders_all XORTA 
                        WHERE XORTA.header_id = lr_rec.r_attribute14 
                        ) ,0))
                        into ln_amount
                        from dual;
                        update xx_cons_ic_us_int
                        set amount = ln_amount
                        where rowid  = lr_rec.row_id;
                        ln_amount := 0;
                    end loop;
                    commit;
                    END;';

        EXECUTE IMMEDIATE l_temp;

        
        l_temp := 'CREATE TABLE xx_con_ic_us
                    AS
                    SELECT account# ,
                      cons_inv_id ,
                      COUNT(invoice#) invoice_count ,
                      SUM(amount) amount ,
                      actual_bill_date ,
                      delivery_method ,
                      direct_indirect ,
                      document_id ,
                      customer_doc_id ,
                      paydoc_infodoc ,
                      frequency ,
                      payment_term ,
                      payment_term_name ,
                      TRANSLATE(account_name,'',''
                      ||''&'','' ''
                      ||'' '') account_name
                    FROM
                      (
                    SELECT
                    ACCOUNT#
                    ,CONS_INV_ID
                    ,INVOICE#
                    ,AMOUNT
                    ,ACTUAL_BILL_DATE
                    ,DELIVERY_METHOD
                    ,DIRECT_INDIRECT
                    ,DOCUMENT_ID
                    ,CUSTOMER_DOC_ID
                    ,PAYDOC_INFODOC
                    ,FREQUENCY
                    ,PAYMENT_TERM
                    ,PAYMENT_TERM_NAME
                    ,ACCOUNT_NAME
                    FROM xx_cons_ic_us_int 
                    )
                    GROUP BY account# ,
                      cons_inv_id ,
                      actual_bill_date ,
                      delivery_method ,
                      direct_indirect ,
                      document_id ,
                      customer_doc_id ,
                      paydoc_infodoc ,
                      frequency ,
                      payment_term ,
                      payment_term_name ,
                      account_name';
                      
            EXECUTE IMMEDIATE l_temp;
        END IF;
        IF p_short_code = 'XXOD_STAND_US_PAYDOC' THEN
            xxod_drop_tables_program(p_errbuf,p_retcode,'xx_std_pd_us');            
            l_temp := 'CREATE TABLE xx_std_pd_us
                        AS
                        SELECT  account#
                               ,COUNT(invoice#) inv_count
                               ,SUM(amount) inv_amount
                               ,actual_bill_date
                               ,delivery_method
                               ,direct_indirect
                               ,document_id
                               ,customer_doc_id
                               ,paydoc_infodoc
                               ,frequency         
                               ,payment_term      
                               ,payment_term_name 
                               ,TRANSLATE(account_name,'',''||''&'','' ''||'' '')     account_name
                        FROM(
                        SELECT /* use_nl(XCCAEB XAIFH) */ HCA.account_number                                       account#
                              ,RCTA.trx_number                                          invoice#
                              ,((SELECT NVL(SUM(RCTL.extended_amount),0)
                                 FROM apps.ra_customer_trx_lines_all RCTL 
                                 WHERE RCTL.customer_trx_id = RCTA.customer_trx_id)
                                 -  NVL(to_number(XAIFH.attribute4),0))                 amount
                              ,XAIFH.actual_print_date                                  actual_bill_date
                        --      ,XAIFH.doc_delivery_method                                delivery_method check if the below decode is a better option to display delivery methods.
                              ,DECODE(XAIFH.doc_delivery_method, ''PRINT'',NVL2(XAIFH.BILLDOCS_SPECIAL_HANDLING,''SPECIAL HANDLING'',''CERTEGY'')
                                           , ''EDI'', ''EDI''
                                           , ''ELEC'' , ''EBILL''
                                           , ''ePDF'', ''ePDF''
                                           , ''eXLS'', ''eXLS''
                                           ,  NULL)                                     delivery_method
                              ,DECODE(XCCAEB.c_ext_attr7,''Y'',''DIRECT''
                                                        ,''N'',''INDIRECT'')                direct_indirect
                              ,XAIFH.document_id                                        document_id
                              ,XAIFH.customer_document_id                               customer_doc_id
                              ,DECODE(XAIFH.PAYDOC_FLAG,''Y'',''PAYDOC''
                                                  ,''N'',''INFODOC'')                   paydoc_infodoc                              
                              ,RT.attribute1                                            frequency
                              ,RT.attribute2                                            payment_term
                              ,RT.name                                                  payment_term_name
                              ,HCA.account_name                                         account_name
                        FROM  (SELECT /*+ PARALLEL(xaifh) */ * 
                                FROM xx_ar_invoice_freq_history xaifh
                                WHERE actual_print_date >= '''||l_from_date||''' AND actual_print_date < '''||l_to_date||''') XAIFH
                             ,APPS.ra_customer_trx_all RCTA
                             ,APPS.xx_cdh_cust_acct_ext_b XCCAEB
                             ,APPS.hz_cust_accounts HCA
                             ,APPS.ra_terms_vl RT
                        WHERE XAIFH.invoice_id         = RCTA.customer_trx_id  
                        AND RCTA.bill_to_customer_id   = XCCAEB.cust_account_id 
                        AND XCCAEB.cust_account_id     = HCA.cust_account_id
                        AND RCTA.bill_to_customer_id  = HCA.cust_account_id
                        AND RT.name                   = XCCAEB.c_ext_attr14
                        AND XAIFH.customer_document_id = XCCAEB.n_ext_attr2
                        AND XAIFH.paydoc_flag = ''Y''
                        AND XAIFH.org_id=404
                        AND HCA.status = ''A''
                        AND XCCAEB.ATTR_GROUP_ID = 166)
                        GROUP BY account#
                               ,actual_bill_date
                               ,delivery_method
                               ,direct_indirect
                               ,document_id
                               ,customer_doc_id
                               ,paydoc_infodoc
                               ,frequency
                               ,payment_term
                               ,payment_term_name
                               ,account_name';    

                EXECUTE IMMEDIATE l_temp;
        END IF;
        IF p_short_code = 'XXOD_STAND_CA_PAYDOC' THEN
            xxod_drop_tables_program(p_errbuf,p_retcode,'xx_std_pd_ca');
                l_temp := 'CREATE TABLE xx_std_pd_ca
                        AS
                        SELECT  account#
                               ,COUNT(invoice#) inv_count
                               ,SUM(amount) inv_amount
                               ,actual_bill_date
                               ,delivery_method
                               ,direct_indirect
                               ,document_id
                               ,customer_doc_id
                               ,paydoc_infodoc
                               ,frequency         
                               ,payment_term      
                               ,payment_term_name 
                               ,TRANSLATE(account_name,'',''||''&'','' ''||'' '')  account_name
                        FROM(
                        SELECT HCA.account_number                                       account#
                              ,RCTA.trx_number                                          invoice#
                              ,((SELECT NVL(SUM(RCTL.extended_amount),0)
                                 FROM apps.ra_customer_trx_lines_all RCTL 
                                 WHERE RCTL.customer_trx_id = RCTA.customer_trx_id)
                                 -  NVL(to_number(XAIFH.attribute4),0))                 amount
                              ,XAIFH.actual_print_date                                  actual_bill_date
                        --      ,XAIFH.doc_delivery_method                                delivery_method if the below decode is a better option to display delivery methods.
                              ,DECODE(XAIFH.doc_delivery_method, ''PRINT'',NVL2(XAIFH.BILLDOCS_SPECIAL_HANDLING,''SPECIAL HANDLING'',''CERTEGY'')
                                           , ''EDI'', ''EDI''
                                           , ''ELEC'' , ''EBILL''
                                           , ''ePDF'', ''ePDF''
                                           , ''eXLS'', ''eXLS''
                                           ,  NULL)                                     delivery_method
                              ,DECODE(XCCAEB.c_ext_attr7,''Y'',''DIRECT''
                                                        ,''N'',''INDIRECT'')                direct_indirect
                              ,XAIFH.document_id                                        document_id
                              ,XAIFH.customer_document_id                               customer_doc_id
                              ,DECODE(XAIFH.PAYDOC_FLAG,''Y'',''PAYDOC''
                                                  ,''N'',''INFODOC'')                       paydoc_infodoc
                              ,RT.attribute1                                            frequency
                              ,RT.attribute2                                            payment_term
                              ,RT.name                                                  payment_term_name
                              ,HCA.account_name                                         account_name
                        FROM  (SELECT /*+ PARALLEL(xaifh) */ * 
                                FROM xx_ar_invoice_freq_history xaifh
                                WHERE actual_print_date >= '''||l_from_date||''' AND  actual_print_date < '''||l_to_date||''') XAIFH 
                             ,APPS.ra_customer_trx_all RCTA
                             ,APPS.xx_cdh_cust_acct_ext_b XCCAEB     
                             ,APPS.hz_cust_accounts HCA
                             ,APPS.ra_terms_vl RT
                        WHERE XAIFH.invoice_id         = RCTA.customer_trx_id  
                        AND RCTA.bill_to_customer_id   = XCCAEB.cust_account_id 
                        AND XCCAEB.cust_account_id     = HCA.cust_account_id
                        AND  RCTA.bill_to_customer_id  = HCA.cust_account_id
                        AND RT.name                   = XCCAEB.c_ext_attr14
                        AND XAIFH.customer_document_id = XCCAEB.n_ext_attr2
                        AND XAIFH.paydoc_flag = ''Y''
                        AND XAIFH.org_id=403
                        AND HCA.status = ''A''
                        AND XCCAEB.ATTR_GROUP_ID = 166)
                        GROUP BY account#
                               ,actual_bill_date
                               ,delivery_method
                               ,direct_indirect
                               ,document_id
                               ,customer_doc_id
                               ,paydoc_infodoc
                               ,frequency
                               ,payment_term
                               ,payment_term_name
                               ,account_name';

                EXECUTE IMMEDIATE l_temp;

        END IF;
        IF p_short_code = 'XXOD_STAND_US_INFODOC' THEN    
            xxod_drop_tables_program(p_errbuf,p_retcode,'xx_std_ic_us');    
                l_temp := 'CREATE TABLE xx_std_ic_us
                            AS
                            SELECT  account#
                                   ,COUNT(invoice#) inv_count
                                   ,SUM(amount) inv_amount
                                   ,actual_bill_date
                                   ,delivery_method
                                   ,direct_indirect
                                   ,document_id
                                   ,customer_doc_id
                                   ,paydoc_infodoc
                                   ,frequency         
                                   ,payment_term      
                                   ,payment_term_name 
                                   ,TRANSLATE(account_name,'',''||''&'','' ''||'' '')     account_name
                            FROM(
                            SELECT HCA.account_number                                       account#
                                  ,RCTA.trx_number                                          invoice#
                                  ,((SELECT NVL(SUM(RCTL.extended_amount),0)
                                     FROM apps.ra_customer_trx_lines_all RCTL 
                                     WHERE RCTL.customer_trx_id = RCTA.customer_trx_id)
                                     -  NVL(to_number(XAIFH.attribute4),0))                 amount
                                  ,XAIFH.actual_print_date                                  actual_bill_date
                            --      ,XAIFH.doc_delivery_method                                delivery_method if the below decode is a better option to display delivery methods.
                                  ,DECODE(XAIFH.doc_delivery_method, ''PRINT'',NVL2(XAIFH.BILLDOCS_SPECIAL_HANDLING,''SPECIAL HANDLING'',''CERTEGY'')
                                               , ''EDI'', ''EDI''
                                               , ''ELEC'' , ''EBILL''
                                               , ''ePDF'', ''ePDF''
                                               , ''eXLS'', ''eXLS''
                                               ,  NULL)                                     delivery_method
                                  ,DECODE(XCCAEB.c_ext_attr7,''Y'',''DIRECT''
                                                            ,''N'',''INDIRECT'')                direct_indirect
                                  ,XAIFH.document_id                                        document_id
                                  ,XAIFH.customer_document_id                               customer_doc_id
                                  ,DECODE(XAIFH.PAYDOC_FLAG,''Y'',''PAYDOC''
                                                      ,''N'',''INFODOC'')                       paydoc_infodoc
                                  ,RT.attribute1                                            frequency
                                  ,RT.attribute2                                            payment_term
                                  ,RT.name                                                  payment_term_name
                                  ,HCA.account_name                                         account_name
                            FROM  (SELECT /*+ PARALLEL(xaifh) */ * 
                                FROM xx_ar_invoice_freq_history xaifh
                                WHERE actual_print_date >= '''||l_from_date||''' AND actual_print_date < '''||l_to_date||''') XAIFH
                                 ,APPS.ra_customer_trx_all RCTA
                                 ,APPS.xx_cdh_cust_acct_ext_b XCCAEB     
                                 ,APPS.hz_cust_accounts HCA
                                 ,APPS.ra_terms_vl RT
                            WHERE XAIFH.invoice_id         = RCTA.customer_trx_id  
                            AND RCTA.bill_to_customer_id   = XCCAEB.cust_account_id 
                            AND XCCAEB.cust_account_id     = HCA.cust_account_id
                            AND RCTA.bill_to_customer_id  = HCA.cust_account_id
                            AND RT.name                   = XCCAEB.c_ext_attr14
                            AND XAIFH.customer_document_id = XCCAEB.n_ext_attr2
                            AND XAIFH.paydoc_flag = ''N''
                            AND XAIFH.org_id=404
                            AND HCA.status = ''A''
                            AND XCCAEB.ATTR_GROUP_ID = 166)
                            GROUP BY account#
                                   ,actual_bill_date
                                   ,delivery_method
                                   ,direct_indirect
                                   ,document_id
                                   ,customer_doc_id
                                   ,paydoc_infodoc
                                   ,frequency
                                   ,payment_term
                                   ,payment_term_name
                                   ,account_name';

                EXECUTE IMMEDIATE l_temp;
        END IF;
        IF p_short_code = 'XXOD_STAND_CA_INFODOC' THEN    
            xxod_drop_tables_program(p_errbuf,p_retcode,'xx_std_ic_ca');
                l_temp := 'CREATE TABLE xx_std_ic_ca
                        AS
                        SELECT  account#
                               ,COUNT(invoice#) ar_count
                               ,SUM(amount) ar_sum
                               ,actual_bill_date
                               ,delivery_method
                               ,direct_indirect
                               ,document_id
                               ,customer_doc_id
                               ,paydoc_infodoc
                               ,frequency         
                               ,payment_term      
                               ,payment_term_name 
                               ,TRANSLATE(account_name,'',''||''&'','' ''||'' '')  account_name
                        FROM(
                        SELECT HCA.account_number                                       account#
                              ,RCTA.trx_number                                          invoice#
                              ,((SELECT NVL(SUM(RCTL.extended_amount),0)
                                 FROM apps.ra_customer_trx_lines_all RCTL 
                                 WHERE RCTL.customer_trx_id = RCTA.customer_trx_id)
                             -  NVL(to_number(XAIFH.attribute4),0))                 amount
                              ,XAIFH.actual_print_date                                  actual_bill_date
                        --      ,XAIFH.doc_delivery_method                                delivery_method if the below decode is a better option to display delivery methods.
                              ,DECODE(XAIFH.doc_delivery_method, ''PRINT'',NVL2(XAIFH.BILLDOCS_SPECIAL_HANDLING,''SPECIAL HANDLING'',''CERTEGY'')
                                           , ''EDI'', ''EDI''
                                           , ''ELEC'' , ''EBILL''
                                           , ''ePDF'', ''ePDF''
                                           , ''eXLS'', ''eXLS''
                                           ,  NULL)                                     delivery_method
                              ,DECODE(XCCAEB.c_ext_attr7,''Y'',''DIRECT''
                                                        ,''N'',''INDIRECT'')                direct_indirect
                              ,XAIFH.document_id                                        document_id
                              ,XAIFH.customer_document_id                               customer_doc_id
                              ,DECODE(XAIFH.PAYDOC_FLAG,''Y'',''PAYDOC''
                                                  ,''N'',''INFODOC'')                       paydoc_infodoc
                              ,RT.attribute1                                            frequency
                              ,RT.attribute2                                            payment_term
                              ,RT.name                                                  payment_term_name
                              ,HCA.account_name                                         account_name
                        FROM  (SELECT /*+ PARALLEL(xaifh) */ * 
                                FROM xx_ar_invoice_freq_history xaifh
                                WHERE actual_print_date >= '''||l_from_date||''' AND actual_print_date < '''||l_to_date||''') XAIFH 
                             ,APPS.ra_customer_trx_all RCTA
                             ,APPS.xx_cdh_cust_acct_ext_b XCCAEB     
                             ,APPS.hz_cust_accounts HCA
                             ,APPS.ra_terms_vl RT
                        WHERE XAIFH.invoice_id         = RCTA.customer_trx_id  
                        AND RCTA.bill_to_customer_id   = XCCAEB.cust_account_id 
                        AND XCCAEB.cust_account_id     = HCA.cust_account_id
                        AND  RCTA.bill_to_customer_id  = HCA.cust_account_id
                        AND RT.name                   = XCCAEB.c_ext_attr14
                        AND XAIFH.customer_document_id = XCCAEB.n_ext_attr2
                        AND XAIFH.actual_print_date >= '''||l_from_date||''' and XAIFH.actual_print_date < '''||l_to_date||''' 
                        AND XAIFH.paydoc_flag = ''N''
                        AND XAIFH.org_id=403
                        AND HCA.status = ''A''
                        AND XCCAEB.ATTR_GROUP_ID = 166)
                        GROUP BY account#
                               ,actual_bill_date
                               ,delivery_method
                               ,direct_indirect
                               ,document_id
                               ,customer_doc_id
                               ,paydoc_infodoc
                               ,frequency
                               ,payment_term
                               ,payment_term_name
                               ,account_name';
                
                EXECUTE IMMEDIATE l_temp;                
        END IF;
        IF p_short_code = 'XXOD_CONS_DTL_CA_INFODOC' THEN            
                xxod_drop_tables_program(p_errbuf,p_retcode,'xx_con_ic_ca');
                l_temp := 'CREATE TABLE xx_con_ic_ca
                        AS
                        SELECT account# ,
                          cons_inv_id ,
                          COUNT(invoice#) invoice_count ,
                          SUM(amount) amount ,
                          actual_bill_date ,
                          delivery_method ,
                          direct_indirect ,
                          document_id ,
                          customer_doc_id ,
                          paydoc_infodoc ,
                          frequency ,
                          payment_term ,
                          payment_term_name ,
                          TRANSLATE(account_name,'',''
                          ||''&'','' ''
                          ||'' '') account_name
                        FROM
                          (SELECT HCA.account_number account# ,
                            XACBHA.cons_inv_id cons_inv_id ,
                            RCTA.trx_number invoice# ,
                            (
                            (SELECT NVL(SUM(RCTL.extended_amount),0)
                            FROM apps.ra_customer_trx_lines_all RCTL
                            WHERE RCTL.customer_trx_id = RCTA.customer_trx_id
                            ) - DECODE(RCTTA.type,''INV'',
                            (SELECT NVL(SUM(OP.payment_amount),0)
                            FROM apps.oe_payments OP
                            WHERE RCTA.attribute14 = OP.header_id
                            ) ,''CM'',
                            (SELECT NVL(SUM(XORTA.credit_amount),0)
                            FROM apps.xx_om_return_tenders_all XORTA
                            WHERE XORTA.header_id = RCTA.attribute14
                            ) ,0)) amount --Added on 23-FEB-10
                            ,
                            XACBHA.print_date actual_bill_date ,
                            ''Certegy'' delivery_method ,
                            DECODE(XCCAEB.c_ext_attr7,''Y'',''DIRECT'' ,''N'',''INDIRECT'') direct_indirect ,
                            XACBHA.document_id document_id ,
                            XACBHA.cust_doc_id customer_doc_id ,
                            DECODE(XCCAEB.c_ext_attr2,''Y'',''PAYDOC'' ,''N'',''INFODOC'') paydoc_infodoc ,
                            RT.attribute1 frequency ,
                            RT.attribute2 payment_term ,
                            RT.name payment_term_name ,
                            HCA.account_name account_name
                          FROM apps.xx_ar_cons_bills_history_all XACBHA ,
                            apps.ra_customer_trx_all RCTA ,
                            apps.hz_cust_accounts HCA ,
                            apps.xx_cdh_cust_acct_ext_b XCCAEB ,
                            apps.ra_terms RT ,
                            apps.ra_cust_trx_types_all RCTTA
                          WHERE XACBHA.customer_id     = HCA.cust_account_id
                          AND HCA.cust_account_id      = RCTA.bill_to_customer_id
                          AND RCTA.bill_to_customer_id = XCCAEB.cust_account_id
                          AND RCTA.customer_trx_id     = XACBHA.attribute1
                          AND RT.name                  = XCCAEB.c_ext_attr14
                          AND RCTTA.cust_trx_type_id   = RCTA.cust_trx_type_id
                          AND XACBHA.cust_doc_id       = XCCAEB.n_ext_attr2
                          AND XACBHA.process_flag      =''Y''
                          AND HCA.status               = ''A''
                          AND XCCAEB.ATTR_GROUP_ID     = 166
                          AND XCCAEB.c_ext_attr2       = ''N''
                          AND XACBHA.paydoc            =''N''
                          AND XCCAEB.c_ext_attr1       = ''Consolidated Bill''
                          AND XACBHA.attribute8        = ''INV_IC''
                          AND XACBHA.org_id            =403
                          AND XACBHA.print_date >= '''||l_from_date||''' AND XACBHA.print_date < '''||l_to_date||'''

                              /* OD (CA) AR Batch Jobs */
                             -- Sub-Query to get request IDs
                          UNION ALL
                          SELECT HCA.account_number account# ,
                            XACBHA.cons_inv_id cons_inv_id ,
                            RCTA.trx_number invoice# ,
                            (
                            (SELECT NVL(SUM(RCTL.extended_amount),0)
                            FROM apps.ra_customer_trx_lines_all RCTL
                            WHERE RCTL.customer_trx_id = RCTA.customer_trx_id
                            ) - DECODE(RCTTA.type,''INV'',
                            (SELECT NVL(SUM(OP.payment_amount),0)
                            FROM apps.oe_payments OP
                            WHERE RCTA.attribute14 = OP.header_id
                            ) ,''CM'',
                            (SELECT NVL(SUM(XORTA.credit_amount),0)
                            FROM apps.xx_om_return_tenders_all XORTA
                            WHERE XORTA.header_id = RCTA.attribute14
                            ) ,0)) amount ,
                            XACBHA.print_date actual_bill_date ,
                            ''Certegy'' delivery_method ,
                            DECODE(XCCAEB.c_ext_attr7,''Y'',''DIRECT'' ,''N'',''INDIRECT'') direct_indirect ,
                            XACBHA.document_id document_id ,
                            XACBHA.cust_doc_id customer_doc_id ,
                            DECODE(XCCAEB.c_ext_attr2,''Y'',''PAYDOC'' ,''N'',''INFODOC'') paydoc_infodoc ,
                            RT.attribute1 frequency ,
                            RT.attribute2 payment_term ,
                            RT.name payment_term_name ,
                            HCA.account_name account_name
                          FROM apps.xx_ar_cons_bills_history_all XACBHA ,
                            apps.ra_customer_trx_all RCTA ,
                            apps.hz_cust_accounts HCA ,
                            apps.xx_cdh_cust_acct_ext_b XCCAEB ,
                            apps.ra_terms RT ,
                            apps.xx_ar_cbi_trx_history xacth ,
                            apps.ra_cust_trx_types_all RCTTA
                          WHERE XACBHA.customer_id     = HCA.cust_account_id
                          AND HCA.cust_account_id      = RCTA.bill_to_customer_id
                          AND RCTA.bill_to_customer_id = XCCAEB.cust_account_id
                          AND XACBHA.thread_id         = xacth.request_id
                          AND XACBHA.cons_inv_id       = xacth.cons_inv_id
                          AND RCTA.customer_trx_id     = xacth.customer_trx_id
                          AND RT.name                  = XCCAEB.c_ext_attr14
                          AND RCTTA.cust_trx_type_id   = RCTA.cust_trx_type_id
                          AND XACBHA.cust_doc_id       = XCCAEB.n_ext_attr2
                          AND XACBHA.process_flag      =''Y''
                          AND HCA.status               = ''A''
                          AND XCCAEB.ATTR_GROUP_ID     = 166
                          AND XCCAEB.c_ext_attr2       = ''N''
                          AND XACBHA.paydoc            =''N''
                          AND XCCAEB.c_ext_attr1       = ''Consolidated Bill''
                          AND XACBHA.attribute8        = ''PAYDOC_IC''
                          AND xacth.inv_type NOT      IN (''SOFTHDR_TOTALS'' ,''BILLTO_TOTALS'' ,''GRAND_TOTAL'')
                          AND xacth.attribute1         = ''PAYDOC_IC''
                          AND XACBHA.org_id            =403
                          AND XACBHA.print_date >= '''||l_from_date||''' and  XACBHA.print_date < '''||l_to_date||''' -- Sub-Query to get request IDs
                          UNION ALL
                          SELECT HCA.account_number account# ,
                            XAGBLA.cons_inv_id cons_inv_id ,
                            RCTA.trx_number invoice# ,
                            (
                            (SELECT NVL(SUM(RCTL.extended_amount),0)
                            FROM apps.ra_customer_trx_lines_all RCTL
                            WHERE RCTL.customer_trx_id = RCTA.customer_trx_id
                            ) - DECODE(RCTTA.type,''INV'',
                            (SELECT NVL(SUM(OP.payment_amount),0)
                            FROM apps.oe_payments OP
                            WHERE RCTA.attribute14 = OP.header_id
                            ) ,''CM'',
                            (SELECT NVL(SUM(XORTA.credit_amount),0)
                            FROM apps.xx_om_return_tenders_all XORTA
                            WHERE XORTA.header_id = RCTA.attribute14
                            ) ,0)) amount ,
                            XAGBLA.cut_off_date-1 actual_bill_date ,
                            ''Ebill'' delivery_method ,
                            DECODE(XCCAEB.c_ext_attr7,''Y'',''DIRECT'' ,''N'',''INDIRECT'') direct_indirect ,
                            XCCAEB.n_ext_attr1 document_id ,
                            XCCAEB.n_ext_attr2 customer_doc_id ,
                            DECODE(XCCAEB.c_ext_attr2,''Y'',''PAYDOC'' ,''N'',''INFODOC'') paydoc_infodoc ,
                            RT.attribute1 frequency ,
                            RT.attribute2 payment_term ,
                            RT.name payment_term_name ,
                            HCA.account_name account_name
                          FROM apps.xx_ar_gen_bill_lines_all XAGBLA ,
                            apps.ra_customer_trx_all RCTA ,
                            apps.hz_cust_accounts HCA ,
                            apps.xx_cdh_cust_acct_ext_b XCCAEB ,
                            apps.ra_terms RT ,
                            apps.ra_cust_trx_types_all RCTTA
                          WHERE XAGBLA.customer_id     = HCA.cust_account_id
                          AND HCA.cust_account_id      = RCTA.bill_to_customer_id
                          AND RCTA.bill_to_customer_id = XCCAEB.cust_account_id
                          AND RCTA.customer_trx_id     = XAGBLA.customer_trx_id
                          AND RT.name                  = XCCAEB.c_ext_attr14
                          AND RCTTA.cust_trx_type_id   = RCTA.cust_trx_type_id
                          AND XAGBLA.processed_flag    =''Y''
                          AND HCA.status               = ''A''
                          AND XCCAEB.ATTR_GROUP_ID     = 166
                          AND XCCAEB.c_ext_attr2       = ''N''
                          AND XCCAEB.c_ext_attr1       = ''Consolidated Bill''
                          AND XCCAEB.c_ext_attr3       = ''ELEC''
                          AND XAGBLA.org_id            = 403
                          AND XAGBLA.n_ext_attr1       = XCCAEB.n_ext_attr2 --Added for Defect #8451
                          AND XAGBLA.creation_date >= '''||l_from_date||''' and XAGBLA.creation_date < '''||l_to_date||''' -- Sub-Query to get request IDs
                          UNION ALL
                          SELECT XAECHH.oracle_account_number account# ,
                            XAECHH.cons_inv_id cons_inv_id ,
                            XAECHH.invoice_number invoice# ,
                            (XAECHH.original_invoice_amount - total_gift_card_amount) amount ,
                            XAECHH.invoice_bill_date actual_bill_date ,
                            XAECHH.billdocs_delivery_method delivery_method ,
                            DECODE(XAECHH.direct_flag,''D'',''DIRECT'' ,''I'',''INDIRECT'') direct_indirect ,
                            XAECHH.mbs_doc_id document_id ,
                            XAECHH.cust_doc_id customer_doc_id ,
                            DECODE(XAECHH.document_type,''Paydoc'',''PAYDOC'' ,''Infocopy'',''INFODOC'') paydoc_infodoc ,
                            XAECHH.payment_term_frequency frequency ,
                            XAECHH.payment_term_report_day payment_term ,
                            XAECHH.payment_term_string payment_term_name ,
                            XAECHH.customer_name account_name
                          FROM apps.xx_ar_ebl_cons_hdr_hist XAECHH
                          WHERE XAECHH.document_type = ''Infocopy''
                            --AND XAECHH.processed_flag=''Y'' --we dont have such flags for this table
                          AND XAECHH.org_id      = 403
                          AND XAECHH.creation_date >= '''||l_from_date||''' and XAECHH.creation_date < '''||l_to_date||''' -- Sub-Query to get request IDs
                          )
                        GROUP BY account# ,
                          cons_inv_id ,
                          actual_bill_date ,
                          delivery_method ,
                          direct_indirect ,
                          document_id ,
                          customer_doc_id ,
                          paydoc_infodoc ,
                          frequency ,
                          payment_term ,
                          payment_term_name ,
                          account_name';    

              EXECUTE IMMEDIATE l_temp;
        END IF;    

   EXCEPTION
   WHEN OTHERS THEN
       fnd_file.put_line (fnd_file.LOG, ' Creation Tables Errored :- '|| SQLERRM || SQLCODE);   
   END xxod_create_tables_program;    

   PROCEDURE xxod_stand_us_paydoc (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   VARCHAR2,
      p_from_date   IN       VARCHAR2,
      p_to_date     IN       VARCHAR2
   )
   IS


      lv_line_count1       NUMBER;
      ln_mail_request_id   NUMBER;
     STANDALONE_USPD        table_type1;      
     TYPE ref_cur IS REF CURSOR;
      l_temp_rec ref_cur;
   BEGIN
        
    xxod_create_tables_program (p_errbuf,
                                p_retcode,
                                  p_from_date,
                                p_to_date,
                                'XXOD_STAND_US_PAYDOC');

      lv_line_count1 := 0;

      OPEN l_temp_rec FOR 'SELECT  * from xx_std_pd_us';
      FETCH l_temp_rec BULK COLLECT INTO STANDALONE_USPD;
      CLOSE l_temp_rec;
      IF STANDALONE_USPD.COUNT > 0 THEN
      FOR l_rec1 IN STANDALONE_USPD.FIRST..STANDALONE_USPD.LAST
      LOOP 
         lv_line_count1 := lv_line_count1 + 1;
          UTL_FILE.put_line(lc_file_handle,  STANDALONE_USPD(l_rec1).account_number|| '||'||
                                            STANDALONE_USPD(l_rec1).INV_COUNT|| '|'||
                                            STANDALONE_USPD(l_rec1).INV_AMOUNT|| '|'||
                                            STANDALONE_USPD(l_rec1).ACTUAL_BILL_DATE|| '|'||
                                            STANDALONE_USPD(l_rec1).DELIVERY_METHOD|| '|'||
                                            STANDALONE_USPD(l_rec1).DIRECT_INDIRECT|| '|'||
                                            STANDALONE_USPD(l_rec1).DOCUMENT_ID|| '|'||
                                            STANDALONE_USPD(l_rec1).CUSTOMER_DOC_ID|| '|'||
                                            STANDALONE_USPD(l_rec1).PAYDOC_INFODOC|| '|'||
                                            STANDALONE_USPD(l_rec1).FREQUENCY|| '|'||
                                            STANDALONE_USPD(l_rec1).PAYMENT_TERM|| '|'||
                                            STANDALONE_USPD(l_rec1).PAYMENT_TERM_NAME|| '|'||
                                            STANDALONE_USPD(l_rec1).ACCOUNT_NAME|| '|'||
                                            'US'|| '|'||
                                            fnd_date.canonical_to_date(p_from_date)|| '|'||
                                            fnd_date.canonical_to_date(p_to_date));
      END LOOP;        
      END IF;
    EXCEPTION
      WHEN UTL_FILE.access_denied
      THEN
         lc_errormsg :=
            (   'Standalone US Paydoc Report Generation Errored :- '
             || ' access_denied :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.delete_failed
      THEN
         lc_errormsg :=
            (   ' Standalone US Paydoc Report Generation Errored :- '
             || ' delete_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.file_open
      THEN
         lc_errormsg :=
            (   ' Standalone US Paydoc Report Generation Errored :- '
             || ' file_open :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.internal_error
      THEN
         lc_errormsg :=
            (   ' Standalone US Paydoc Report Generation Errored :- '
             || ' internal_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filehandle
      THEN
         lc_errormsg :=
            (   ' Standalone US Paydoc Report Generation Errored :- '
             || ' invalid_filehandle :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filename
      THEN
         lc_errormsg :=
            (   ' Standalone US Paydoc Report Generation Errored :- '
             || ' invalid_filename :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_maxlinesize
      THEN
         lc_errormsg :=
            (   ' Standalone US Paydoc Report Generation Errored :- '
             || ' invalid_maxlinesize :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_mode
      THEN
         lc_errormsg :=
            (   ' Standalone US Paydoc Report Generation Errored :- '
             || ' invalid_mode :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_offset
      THEN
         lc_errormsg :=
            (   ' Standalone US Paydoc Report Generation Errored :- '
             || ' invalid_offset :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_operation
      THEN
         lc_errormsg :=
            (   ' Standalone US Paydoc Report Generation Errored :- '
             || ' invalid_operation :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_path
      THEN
         lc_errormsg :=
            (   ' Standalone US Paydoc Report Generation Errored :- '
             || ' invalid_path :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.read_error
      THEN
         lc_errormsg :=
            (   ' Standalone US Paydoc Report Generation Errored :- '
             || ' read_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.rename_failed
      THEN
         lc_errormsg :=
            (   ' Standalone US Paydoc Report Generation Errored :- '
             || ' rename_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.write_error
      THEN
         lc_errormsg :=
            (   ' Standalone US Paydoc Report Generation Errored :- '
             || ' write_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);


      WHEN OTHERS
      THEN
         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := SQLCODE;
         fnd_file.put_line (fnd_file.output, 'Error Package ');
         raise_application_error (-20001, 'Error ' || p_errbuf);
         
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
         RAISE;
   END;

   PROCEDURE xxod_stand_ca_paydoc (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   VARCHAR2,
      p_from_date   IN       VARCHAR2,
      p_to_date     IN       VARCHAR2
   )
   IS

      lv_line_count2       NUMBER;
      ln_mail_request_id   NUMBER;
      STANDALONE_CAPD        table_type1;
      TYPE ref_cur IS REF CURSOR;
      l_temp_rec ref_cur;      
   BEGIN
        
    xxod_create_tables_program (p_errbuf,
                                p_retcode,
                                  p_from_date,
                                p_to_date,
                                'XXOD_STAND_CA_PAYDOC');        
                                
      
      lv_line_count2 := 0;

      --FOR l_rec2 IN lc_proc2
      OPEN l_temp_rec FOR 'SELECT * FROM xx_std_pd_ca';
      FETCH l_temp_rec BULK COLLECT INTO STANDALONE_CAPD;
      CLOSE l_temp_rec;
      IF STANDALONE_CAPD.COUNT > 0 THEN        
          FOR l_rec2 IN STANDALONE_CAPD.FIRST..STANDALONE_CAPD.LAST
          LOOP 

             lv_line_count2 := lv_line_count2 + 1;         
              UTL_FILE.put_line(lc_file_handle,STANDALONE_CAPD(l_rec2).account_number
                                                   || '||'||STANDALONE_CAPD(l_rec2).inv_count
                                                   || '|'||STANDALONE_CAPD(l_rec2).inv_amount
                                                   || '|'||STANDALONE_CAPD(l_rec2).actual_bill_date
                                                   || '|'||STANDALONE_CAPD(l_rec2).delivery_method
                                                   || '|'||STANDALONE_CAPD(l_rec2).direct_indirect
                                                   || '|'||STANDALONE_CAPD(l_rec2).document_id
                                                   || '|'||STANDALONE_CAPD(l_rec2).customer_doc_id
                                                   || '|'||STANDALONE_CAPD(l_rec2).paydoc_infodoc
                                                   || '|'||STANDALONE_CAPD(l_rec2).frequency         
                                                   || '|'||STANDALONE_CAPD(l_rec2).payment_term      
                                                   || '|'||STANDALONE_CAPD(l_rec2).payment_term_name 
                                                   || '|'||STANDALONE_CAPD(l_rec2).account_name
                                                   || '|'||'CA'
                                                   || '|'||fnd_date.canonical_to_date(p_from_date)
                                                   || '|'||fnd_date.canonical_to_date(p_to_date));
          END LOOP;
      END IF;
    EXCEPTION
      WHEN UTL_FILE.access_denied
      THEN
         lc_errormsg :=
            (   'Standalone CA Paydoc Report Generation Errored :- '
             || ' access_denied :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.delete_failed
      THEN
         lc_errormsg :=
            (   ' Standalone CA Paydoc Report Generation Errored :- '
             || ' delete_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.file_open
      THEN
         lc_errormsg :=
            (   ' Standalone CA Paydoc Report Generation Errored :- '
             || ' file_open :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.internal_error
      THEN
         lc_errormsg :=
            (   ' Standalone CA Paydoc Report Generation Errored :- '
             || ' internal_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filehandle
      THEN
         lc_errormsg :=
            (   ' Standalone CA Paydoc Report Generation Errored :- '
             || ' invalid_filehandle :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filename
      THEN
         lc_errormsg :=
            (   ' Standalone CA Paydoc Report Generation Errored :- '
             || ' invalid_filename :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_maxlinesize
      THEN
         lc_errormsg :=
            (   ' Standalone CA Paydoc Report Generation Errored :- '
             || ' invalid_maxlinesize :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_mode
      THEN
         lc_errormsg :=
            (   ' Standalone CA Paydoc Report Generation Errored :- '
             || ' invalid_mode :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_offset
      THEN
         lc_errormsg :=
            (   ' Standalone CA Paydoc Report Generation Errored :- '
             || ' invalid_offset :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_operation
      THEN
         lc_errormsg :=
            (   ' Standalone CA Paydoc Report Generation Errored :- '
             || ' invalid_operation :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_path
      THEN
         lc_errormsg :=
            (   ' Standalone CA Paydoc Report Generation Errored :- '
             || ' invalid_path :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.read_error
      THEN
         lc_errormsg :=
            (   ' Standalone CA Paydoc Report Generation Errored :- '
             || ' read_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.rename_failed
      THEN
         lc_errormsg :=
            (   ' Standalone CA Paydoc Report Generation Errored :- '
             || ' rename_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.write_error
      THEN
         lc_errormsg :=
            (   ' Standalone CA Paydoc Report Generation Errored :- '
             || ' write_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);


      WHEN OTHERS
      THEN
         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := SQLCODE;
         fnd_file.put_line (fnd_file.output, 'Error Package ');
         raise_application_error (-20001, 'Error ' || p_errbuf);
         
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
         RAISE;
   END;

   PROCEDURE xxod_stand_us_infodoc (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   VARCHAR2,
      p_from_date   IN       VARCHAR2,
      p_to_date     IN       VARCHAR2
   )
   IS

      lv_line_count3       NUMBER;
      ln_mail_request_id   NUMBER;
      STANDALONE_USID        table_type1;
      TYPE ref_cur IS REF CURSOR;
      l_temp_rec ref_cur;
   BEGIN
      xxod_create_tables_program (p_errbuf,
                                p_retcode,
                                  p_from_date,
                                p_to_date,
                                'XXOD_STAND_US_INFODOC');                                    
      
      lv_line_count3 := 0;

      OPEN l_temp_rec FOR 'SELECT * FROM xx_std_ic_us';

      FETCH l_temp_rec BULK COLLECT INTO STANDALONE_USID;

      CLOSE l_temp_rec;

      IF STANDALONE_USID.COUNT > 0 THEN
      FOR l_rec3 IN STANDALONE_USID.FIRST..STANDALONE_USID.LAST
      LOOP

         lv_line_count3 := lv_line_count3 + 1;
          UTL_FILE.put_line(lc_file_handle, STANDALONE_USID(l_rec3).account_number|| '||'||
                            STANDALONE_USID(l_rec3).inv_count|| '|'||
                            STANDALONE_USID(l_rec3).inv_amount|| '|'||
                            STANDALONE_USID(l_rec3).actual_bill_date|| '|'||
                            STANDALONE_USID(l_rec3).delivery_method|| '|'||
                            STANDALONE_USID(l_rec3).direct_indirect|| '|'||
                            STANDALONE_USID(l_rec3).document_id|| '|'||
                            STANDALONE_USID(l_rec3).customer_doc_id|| '|'||
                            STANDALONE_USID(l_rec3).paydoc_infodoc|| '|'||
                            STANDALONE_USID(l_rec3).frequency|| '|'||
                            STANDALONE_USID(l_rec3).payment_term|| '|'||
                            STANDALONE_USID(l_rec3).payment_term_name|| '|'||
                            STANDALONE_USID(l_rec3).account_name|| '|'||
                            'US'|| '|'||
                            fnd_date.canonical_to_date(p_from_date)|| '|'||
                            fnd_date.canonical_to_date(p_to_date));
      END LOOP;
      END IF;
   EXCEPTION
      WHEN UTL_FILE.access_denied
      THEN
         lc_errormsg :=
            (   'Standalone US Infodoc Report Generation Errored :- '
             || ' access_denied :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.delete_failed
      THEN
         lc_errormsg :=
            (   ' Standalone US Infodoc Report Generation Errored :- '
             || ' delete_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.file_open
      THEN
         lc_errormsg :=
            (   ' Standalone US Infodoc Report Generation Errored :- '
             || ' file_open :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.internal_error
      THEN
         lc_errormsg :=
            (   ' Standalone US Infodoc Report Generation Errored :- '
             || ' internal_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filehandle
      THEN
         lc_errormsg :=
            (   ' Standalone US Infodoc Report Generation Errored :- '
             || ' invalid_filehandle :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filename
      THEN
         lc_errormsg :=
            (   ' Standalone US Infodoc Report Generation Errored :- '
             || ' invalid_filename :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_maxlinesize
      THEN
         lc_errormsg :=
            (   ' Standalone US Infodoc Report Generation Errored :- '
             || ' invalid_maxlinesize :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_mode
      THEN
         lc_errormsg :=
            (   ' Standalone US Infodoc Report Generation Errored :- '
             || ' invalid_mode :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_offset
      THEN
         lc_errormsg :=
            (   ' Standalone US Infodoc Report Generation Errored :- '
             || ' invalid_offset :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_operation
      THEN
         lc_errormsg :=
            (   ' Standalone US Infodoc Report Generation Errored :- '
             || ' invalid_operation :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_path
      THEN
         lc_errormsg :=
            (   ' Standalone US Infodoc Report Generation Errored :- '
             || ' invalid_path :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.read_error
      THEN
         lc_errormsg :=
            (   ' Standalone US Infodoc Report Generation Errored :- '
             || ' read_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.rename_failed
      THEN
         lc_errormsg :=
            (   ' Standalone US Infodoc Report Generation Errored :- '
             || ' rename_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.write_error
      THEN
         lc_errormsg :=
            (   ' Standalone US Infodoc Report Generation Errored :- '
             || ' write_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);


      WHEN OTHERS
      THEN
         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := SQLCODE;
         fnd_file.put_line (fnd_file.output, 'Error Package ');
         raise_application_error (-20001, 'Error ' || p_errbuf);
         
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
         RAISE;
   END;

   PROCEDURE xxod_stand_ca_infodoc (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   VARCHAR2,
      p_from_date   IN       VARCHAR2,
      p_to_date     IN       VARCHAR2
   )
   IS

      lv_line_count4       NUMBER;
      ln_mail_request_id   NUMBER;
      STANDALONE_CAID table_type1;
      TYPE ref_cur IS REF CURSOR;
      l_temp_rec ref_cur;
   BEGIN
      xxod_create_tables_program (p_errbuf,
                                p_retcode,
                                  p_from_date,
                                p_to_date,
                                'XXOD_STAND_CA_INFODOC');          

      lv_line_count4 := 0;
      OPEN l_temp_rec FOR 'SELECT * FROM xx_std_ic_ca';
      FETCH l_temp_rec BULK COLLECT INTO STANDALONE_CAID;
      CLOSE l_temp_rec;    
      IF STANDALONE_CAID.COUNT > 0 THEN
      FOR l_rec4 IN STANDALONE_CAID.FIRST..STANDALONE_CAID.LAST
      LOOP
         lv_line_count4 := lv_line_count4 + 1;
         UTL_FILE.put_line(lc_file_handle, STANDALONE_CAID(l_rec4).account_number|| '||'||
                                             STANDALONE_CAID(l_rec4).inv_count|| '|'||
                                             STANDALONE_CAID(l_rec4).inv_amount|| '|'||
                                             STANDALONE_CAID(l_rec4).actual_bill_date|| '|'||
                                             STANDALONE_CAID(l_rec4).delivery_method|| '|'||
                                             STANDALONE_CAID(l_rec4).direct_indirect|| '|'||
                                             STANDALONE_CAID(l_rec4).document_id|| '|'||
                                             STANDALONE_CAID(l_rec4).customer_doc_id|| '|'||
                                             STANDALONE_CAID(l_rec4).paydoc_infodoc|| '|'||
                                             STANDALONE_CAID(l_rec4).frequency|| '|'||
                                             STANDALONE_CAID(l_rec4).payment_term|| '|'||
                                             STANDALONE_CAID(l_rec4).payment_term_name|| '|'||
                                             STANDALONE_CAID(l_rec4).account_name|| '|'||
                                            'CA'|| '|'||
                                            fnd_date.canonical_to_date(p_from_date)|| '|'||
                                            fnd_date.canonical_to_date(p_to_date));
      END LOOP;
      END IF;
   EXCEPTION
    WHEN UTL_FILE.access_denied
      THEN
         lc_errormsg :=
            (   'Standalone CA Infodoc Report Generation Errored :- '
             || ' access_denied :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.delete_failed
      THEN
         lc_errormsg :=
            (   ' Standalone CA Infodoc Report Generation Errored :- '
             || ' delete_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.file_open
      THEN
         lc_errormsg :=
            (   ' Standalone CA Infodoc Report Generation Errored :- '
             || ' file_open :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.internal_error
      THEN
         lc_errormsg :=
            (   ' Standalone CA Infodoc Report Generation Errored :- '
             || ' internal_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filehandle
      THEN
         lc_errormsg :=
            (   ' Standalone CA Infodoc Report Generation Errored :- '
             || ' invalid_filehandle :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filename
      THEN
         lc_errormsg :=
            (   ' Standalone CA Infodoc Report Generation Errored :- '
             || ' invalid_filename :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_maxlinesize
      THEN
         lc_errormsg :=
            (   ' Standalone CA Infodoc Report Generation Errored :- '
             || ' invalid_maxlinesize :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_mode
      THEN
         lc_errormsg :=
            (   ' Standalone CA Infodoc Report Generation Errored :- '
             || ' invalid_mode :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_offset
      THEN
         lc_errormsg :=
            (   ' Standalone CA Infodoc Report Generation Errored :- '
             || ' invalid_offset :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_operation
      THEN
         lc_errormsg :=
            (   ' Standalone CA Infodoc Report Generation Errored :- '
             || ' invalid_operation :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_path
      THEN
         lc_errormsg :=
            (   ' Standalone CA Infodoc Report Generation Errored :- '
             || ' invalid_path :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.read_error
      THEN
         lc_errormsg :=
            (   ' Standalone CA Infodoc Report Generation Errored :- '
             || ' read_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.rename_failed
      THEN
         lc_errormsg :=
            (   ' Standalone CA Infodoc Report Generation Errored :- '
             || ' rename_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.write_error
      THEN
         lc_errormsg :=
            (   ' Standalone CA Infodoc Report Generation Errored :- '
             || ' write_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);


      WHEN OTHERS
      THEN
         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := SQLCODE;
         fnd_file.put_line (fnd_file.output, 'Error Package ');
         raise_application_error (-20001, 'Error ' || p_errbuf);
         
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
         RAISE;
   END xxod_stand_ca_infodoc;

   PROCEDURE xxod_cons_dtl_us_paydoc (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   VARCHAR2,
      p_from_date   IN       VARCHAR2,
      p_to_date     IN       VARCHAR2
   )
   IS

      lv_line_count5       NUMBER;
      ln_mail_request_id   NUMBER;
      CONSDTD_USPD table_type2;
      TYPE ref_cur IS REF CURSOR;
      l_temp_rec ref_cur;
   BEGIN
      
      xxod_create_tables_program (p_errbuf,
                                p_retcode,
                                  p_from_date,
                                p_to_date,
                                'XXOD_CONS_DTL_US_PAYDOC');       

                                
      
      lv_line_count5 := 0;
      OPEN l_temp_rec FOR 'SELECT   * FROM xx_con_pd_us';

      FETCH l_temp_rec BULK COLLECT INTO CONSDTD_USPD;

      CLOSE l_temp_rec;
      IF CONSDTD_USPD.COUNT > 0 THEN
      FOR l_rec5 IN CONSDTD_USPD.FIRST..CONSDTD_USPD.LAST
      LOOP


         lv_line_count5 := lv_line_count5 + 1;
         UTL_FILE.put_line(lc_file_handle,   CONSDTD_USPD(l_rec5).account_number ||'|'||
                                              CONSDTD_USPD(l_rec5).cons_inv_id ||'|'||
                                              CONSDTD_USPD(l_rec5).inv_count ||'|'||
                                              CONSDTD_USPD(l_rec5).inv_amount ||'|'||
                                              CONSDTD_USPD(l_rec5).actual_bill_date ||'|'||
                                              CONSDTD_USPD(l_rec5).delivery_method ||'|'||
                                              CONSDTD_USPD(l_rec5).direct_indirect ||'|'||
                                              CONSDTD_USPD(l_rec5).document_id ||'|'||
                                              CONSDTD_USPD(l_rec5).customer_doc_id ||'|'||
                                              CONSDTD_USPD(l_rec5).paydoc_infodoc ||'|'||
                                              CONSDTD_USPD(l_rec5).frequency ||'|'||
                                              CONSDTD_USPD(l_rec5).payment_term ||'|'||
                                              CONSDTD_USPD(l_rec5).payment_term_name ||'|'||
                                              CONSDTD_USPD(l_rec5).account_name|| '|'||
                                              'US'|| '|'||
                                              fnd_date.canonical_to_date(p_from_date)|| '|'||
                                              fnd_date.canonical_to_date(p_to_date));
      END LOOP;
      END IF;

   EXCEPTION
WHEN UTL_FILE.access_denied
      THEN
         lc_errormsg :=
            (   'Consolidated US Paydoc Report Generation Errored :- '
             || ' access_denied :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.delete_failed
      THEN
         lc_errormsg :=
            (   ' Consolidated US Paydoc Report Generation Errored :- '
             || ' delete_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.file_open
      THEN
         lc_errormsg :=
            (   ' Consolidated US Paydoc Report Generation Errored :- '
             || ' file_open :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.internal_error
      THEN
         lc_errormsg :=
            (   ' Consolidated US Paydoc Report Generation Errored :- '
             || ' internal_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filehandle
      THEN
         lc_errormsg :=
            (   ' Consolidated US Paydoc Report Generation Errored :- '
             || ' invalid_filehandle :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filename
      THEN
         lc_errormsg :=
            (   ' Consolidated US Paydoc Report Generation Errored :- '
             || ' invalid_filename :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_maxlinesize
      THEN
         lc_errormsg :=
            (   ' Consolidated US Paydoc Report Generation Errored :- '
             || ' invalid_maxlinesize :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_mode
      THEN
         lc_errormsg :=
            (   ' Consolidated US Paydoc Report Generation Errored :- '
             || ' invalid_mode :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_offset
      THEN
         lc_errormsg :=
            (   ' Consolidated US Paydoc Report Generation Errored :- '
             || ' invalid_offset :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_operation
      THEN
         lc_errormsg :=
            (   ' Consolidated US Paydoc Report Generation Errored :- '
             || ' invalid_operation :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_path
      THEN
         lc_errormsg :=
            (   ' Consolidated US Paydoc Report Generation Errored :- '
             || ' invalid_path :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.read_error
      THEN
         lc_errormsg :=
            (   ' Consolidated US Paydoc Report Generation Errored :- '
             || ' read_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.rename_failed
      THEN
         lc_errormsg :=
            (   ' Consolidated US Paydoc Report Generation Errored :- '
             || ' rename_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.write_error
      THEN
         lc_errormsg :=
            (   ' Consolidated US Paydoc Report Generation Errored :- '
             || ' write_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);


      WHEN OTHERS
      THEN
         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := SQLCODE;
         fnd_file.put_line (fnd_file.output, 'Error Package ');
         raise_application_error (-20001, 'Error ' || p_errbuf);
         
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
         RAISE;
   END;

   PROCEDURE xxod_cons_dtl_ca_paydoc (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   VARCHAR2,
      p_from_date   IN       VARCHAR2,
      p_to_date     IN       VARCHAR2
   )
   IS

      lv_output6           VARCHAR2 (6000);
      lv_line_count6       NUMBER;
      ln_mail_request_id   NUMBER;
      CONSDTD_CAPD        table_type2;      
      TYPE ref_cur IS REF CURSOR;
      l_temp_rec ref_cur;      
   BEGIN
      xxod_create_tables_program (p_errbuf,
                                p_retcode,
                                  p_from_date,
                                p_to_date,
                                'XXOD_CONS_DTL_CA_PAYDOC');        
      
      lv_line_count6 := 0;
      OPEN l_temp_rec FOR 'SELECT  * FROM xx_con_pd_ca';
      FETCH l_temp_rec BULK COLLECT INTO CONSDTD_CAPD;
      CLOSE l_temp_rec;
      IF CONSDTD_CAPD.COUNT > 0 THEN
      FOR l_rec6 IN CONSDTD_CAPD.FIRST..CONSDTD_CAPD.LAST
      LOOP


         lv_line_count6 := lv_line_count6 + 1;
         UTL_FILE.put_line(lc_file_handle,CONSDTD_CAPD(l_rec6).account_number|| '|'||
                                              CONSDTD_CAPD(l_rec6).cons_inv_id|| '|'||
                                              CONSDTD_CAPD(l_rec6).inv_count|| '|'||
                                              CONSDTD_CAPD(l_rec6).inv_amount|| '|'||
                                              CONSDTD_CAPD(l_rec6).actual_bill_date|| '|'||
                                              CONSDTD_CAPD(l_rec6).delivery_method|| '|'||
                                              CONSDTD_CAPD(l_rec6).direct_indirect|| '|'||
                                              CONSDTD_CAPD(l_rec6).document_id|| '|'||
                                              CONSDTD_CAPD(l_rec6).customer_doc_id|| '|'||
                                              CONSDTD_CAPD(l_rec6).paydoc_infodoc|| '|'||
                                              CONSDTD_CAPD(l_rec6).frequency|| '|'||
                                              CONSDTD_CAPD(l_rec6).payment_term|| '|'||
                                              CONSDTD_CAPD(l_rec6).payment_term_name|| '|'||
                                              CONSDTD_CAPD(l_rec6).account_name|| '|'||
                                              'CA'|| '|'||
                                              fnd_date.canonical_to_date(p_from_date)|| '|'||
                                              fnd_date.canonical_to_date(p_to_date));
      END LOOP;

      END IF;
   EXCEPTION
      WHEN UTL_FILE.access_denied
      THEN
         lc_errormsg :=
            (   'Consolidated CA Paydoc Report Generation Errored :- '
             || ' access_denied :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.delete_failed
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Paydoc Report Generation Errored :- '
             || ' delete_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.file_open
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Paydoc Report Generation Errored :- '
             || ' file_open :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.internal_error
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Paydoc Report Generation Errored :- '
             || ' internal_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filehandle
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Paydoc Report Generation Errored :- '
             || ' invalid_filehandle :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filename
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Paydoc Report Generation Errored :- '
             || ' invalid_filename :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_maxlinesize
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Paydoc Report Generation Errored :- '
             || ' invalid_maxlinesize :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_mode
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Paydoc Report Generation Errored :- '
             || ' invalid_mode :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_offset
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Paydoc Report Generation Errored :- '
             || ' invalid_offset :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_operation
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Paydoc Report Generation Errored :- '
             || ' invalid_operation :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_path
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Paydoc Report Generation Errored :- '
             || ' invalid_path :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.read_error
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Paydoc Report Generation Errored :- '
             || ' read_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.rename_failed
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Paydoc Report Generation Errored :- '
             || ' rename_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.write_error
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Paydoc Report Generation Errored :- '
             || ' write_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);


      WHEN OTHERS
      THEN
         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := SQLCODE;
         fnd_file.put_line (fnd_file.output, 'Error Package ');
         raise_application_error (-20001, 'Error ' || p_errbuf);
         
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
         RAISE;
   END;

   PROCEDURE xxod_cons_dtl_us_infodoc (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   VARCHAR2,
      p_from_date   IN       VARCHAR2,
      p_to_date     IN       VARCHAR2
   )
   IS

      lv_line_count7       NUMBER;
      ln_mail_request_id   NUMBER;
      CONSDTD_USID table_type2;
      TYPE ref_cur IS REF CURSOR;
      l_temp_rec ref_cur;      
   BEGIN
      xxod_create_tables_program (p_errbuf,
                                p_retcode,
                                  p_from_date,
                                p_to_date,
                                'XXOD_CONS_DTL_US_INFODOC');
      
      
      lv_line_count7 := 0;
      OPEN l_temp_rec FOR 'SELECT  * FROM xx_con_ic_us';
      FETCH l_temp_rec BULK COLLECT INTO CONSDTD_USID;
      CLOSE l_temp_rec;
      IF CONSDTD_USID.COUNT > 0 THEN
      FOR l_rec7 IN CONSDTD_USID.FIRST..CONSDTD_USID.LAST
      LOOP

         lv_line_count7 := lv_line_count7 + 1;
         UTL_FILE.put_line(lc_file_handle, CONSDTD_USID(l_rec7).account_number||'|'||
                                          CONSDTD_USID(l_rec7).cons_inv_id||'|'||
                                          CONSDTD_USID(l_rec7).inv_count||'|'||
                                          CONSDTD_USID(l_rec7).inv_amount||'|'||
                                          CONSDTD_USID(l_rec7).actual_bill_date||'|'||
                                          CONSDTD_USID(l_rec7).delivery_method||'|'||
                                          CONSDTD_USID(l_rec7).direct_indirect||'|'||
                                          CONSDTD_USID(l_rec7).document_id||'|'||
                                          CONSDTD_USID(l_rec7).customer_doc_id||'|'||
                                          CONSDTD_USID(l_rec7).paydoc_infodoc||'|'||
                                          CONSDTD_USID(l_rec7).frequency||'|'||
                                          CONSDTD_USID(l_rec7).payment_term||'|'||
                                          CONSDTD_USID(l_rec7).payment_term_name||'|'||
                                          CONSDTD_USID(l_rec7).account_name|| '|'||
                                          'US'|| '|'||
                                          fnd_date.canonical_to_date(p_from_date)|| '|'||
                                          fnd_date.canonical_to_date(p_to_date));
      END LOOP;

      END IF;
   EXCEPTION
      WHEN UTL_FILE.access_denied
      THEN
         lc_errormsg :=
            (   'Consolidated US Infodoc Report Generation Errored :- '
             || ' access_denied :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.delete_failed
      THEN
         lc_errormsg :=
            (   ' Consolidated US Infodoc Report Generation Errored :- '
             || ' delete_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.file_open
      THEN
         lc_errormsg :=
            (   ' Consolidated US Infodoc Report Generation Errored :- '
             || ' file_open :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.internal_error
      THEN
         lc_errormsg :=
            (   ' Consolidated US Infodoc Report Generation Errored :- '
             || ' internal_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filehandle
      THEN
         lc_errormsg :=
            (   ' Consolidated US Infodoc Report Generation Errored :- '
             || ' invalid_filehandle :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filename
      THEN
         lc_errormsg :=
            (   ' Consolidated US Infodoc Report Generation Errored :- '
             || ' invalid_filename :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_maxlinesize
      THEN
         lc_errormsg :=
            (   ' Consolidated US Infodoc Report Generation Errored :- '
             || ' invalid_maxlinesize :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_mode
      THEN
         lc_errormsg :=
            (   ' Consolidated US Infodoc Report Generation Errored :- '
             || ' invalid_mode :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_offset
      THEN
         lc_errormsg :=
            (   ' Consolidated US Infodoc Report Generation Errored :- '
             || ' invalid_offset :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_operation
      THEN
         lc_errormsg :=
            (   ' Consolidated US Infodoc Report Generation Errored :- '
             || ' invalid_operation :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_path
      THEN
         lc_errormsg :=
            (   ' Consolidated US Infodoc Report Generation Errored :- '
             || ' invalid_path :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.read_error
      THEN
         lc_errormsg :=
            (   ' Consolidated US Infodoc Report Generation Errored :- '
             || ' read_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.rename_failed
      THEN
         lc_errormsg :=
            (   ' Consolidated US Infodoc Report Generation Errored :- '
             || ' rename_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.write_error
      THEN
         lc_errormsg :=
            (   ' Consolidated US Infodoc Report Generation Errored :- '
             || ' write_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);


      WHEN OTHERS
      THEN
         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := SQLCODE;
         fnd_file.put_line (fnd_file.output, 'Error Package ');
         raise_application_error (-20001, 'Error ' || p_errbuf);
         
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
         RAISE;
   END;

   PROCEDURE xxod_cons_dtl_ca_infodoc (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   VARCHAR2,
      p_from_date   IN       VARCHAR2,
      p_to_date     IN       VARCHAR2
   )
   IS

      lv_line_count8       NUMBER;
      ln_mail_request_id   NUMBER;        
      CONSDTD_CAID            table_type2;
      TYPE ref_cur IS REF CURSOR;
      l_temp_rec ref_cur;      
   BEGIN
      xxod_create_tables_program (p_errbuf,
                                  p_retcode,
                                    p_from_date,
                                  p_to_date,
                                  'XXOD_CONS_DTL_CA_INFODOC');
      
      
      lv_line_count8 := 0;
      OPEN l_temp_rec FOR 'SELECT  * FROM xx_con_ic_ca';
      FETCH l_temp_rec BULK COLLECT INTO CONSDTD_CAID;
      CLOSE l_temp_rec;
      IF CONSDTD_CAID.COUNT > 0 THEN
      FOR l_rec8 IN CONSDTD_CAID.FIRST..CONSDTD_CAID.LAST
      LOOP
        
         lv_line_count8 := lv_line_count8 + 1;
         UTL_FILE.put_line(lc_file_handle, CONSDTD_CAID(l_rec8).account_number|| '|'||
                                              CONSDTD_CAID(l_rec8).cons_inv_id|| '|'||
                                              CONSDTD_CAID(l_rec8).inv_count|| '|'||
                                              CONSDTD_CAID(l_rec8).inv_amount|| '|'||
                                              CONSDTD_CAID(l_rec8).actual_bill_date|| '|'||
                                              CONSDTD_CAID(l_rec8).delivery_method|| '|'||
                                              CONSDTD_CAID(l_rec8).direct_indirect|| '|'||
                                              CONSDTD_CAID(l_rec8).document_id|| '|'||
                                              CONSDTD_CAID(l_rec8).customer_doc_id|| '|'||
                                              CONSDTD_CAID(l_rec8).paydoc_infodoc|| '|'||
                                              CONSDTD_CAID(l_rec8).frequency|| '|'||
                                              CONSDTD_CAID(l_rec8).payment_term|| '|'||
                                              CONSDTD_CAID(l_rec8).payment_term_name|| '|'||
                                              CONSDTD_CAID(l_rec8).account_name|| '|'||
                                              'CA'|| '|'||
                                              fnd_date.canonical_to_date(p_from_date)|| '|'||
                                              fnd_date.canonical_to_date(p_to_date));
      END LOOP;
      
      END IF;
      
   EXCEPTION
      WHEN UTL_FILE.access_denied
      THEN
         lc_errormsg :=
            (   'Consolidated CA Infodoc Report Generation Errored :- '
             || ' access_denied :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.delete_failed
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Infodoc Report Generation Errored :- '
             || ' delete_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.file_open
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Infodoc Report Generation Errored :- '
             || ' file_open :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.internal_error
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Infodoc Report Generation Errored :- '
             || ' internal_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filehandle
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Infodoc Report Generation Errored :- '
             || ' invalid_filehandle :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filename
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Infodoc Report Generation Errored :- '
             || ' invalid_filename :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_maxlinesize
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Infodoc Report Generation Errored :- '
             || ' invalid_maxlinesize :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_mode
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Infodoc Report Generation Errored :- '
             || ' invalid_mode :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_offset
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Infodoc Report Generation Errored :- '
             || ' invalid_offset :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_operation
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Infodoc Report Generation Errored :- '
             || ' invalid_operation :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_path
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Infodoc Report Generation Errored :- '
             || ' invalid_path :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.read_error
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Infodoc Report Generation Errored :- '
             || ' read_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.rename_failed
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Infodoc Report Generation Errored :- '
             || ' rename_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.write_error
      THEN
         lc_errormsg :=
            (   ' Consolidated CA Infodoc Report Generation Errored :- '
             || ' write_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);


      WHEN OTHERS
      THEN
         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := SQLCODE;
         fnd_file.put_line (fnd_file.output, 'Error Package ');
         raise_application_error (-20001, 'Error ' || p_errbuf);
         
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
         RAISE;
   END;  

   PROCEDURE sumbit_conc_program (
      p_conc_program              IN   VARCHAR2,
      p_conc_program_short_name   IN   VARCHAR2,
      p_application               IN   VARCHAR2,
      p_from_date                 IN   VARCHAR2,
      p_to_date                   IN   VARCHAR2
   )
   IS
      l_request_id         NUMBER;

   BEGIN
      l_request_id :=
         apps.fnd_request.submit_request
                              (application      => p_application,
                               program          => p_conc_program_short_name,
                               description      => '',
                               start_time       => TO_CHAR
                                                       (SYSDATE,
                                                        'DD-MON-YY HH24:MI:SS'
                                                       ),
                               sub_request      => TRUE,
                               argument1        => p_from_date,
                               argument2        => p_to_date
                              );
         COMMIT;                              

      IF l_request_id = 0
      THEN
         fnd_file.put_line
            (fnd_file.output,
             '+----------------------------------------------------------------+'
            );
         fnd_file.put_line
            (fnd_file.output,
             '                                                                  '
            );
         fnd_file.put_line (fnd_file.output,
                               'Concurrent Program '
                            || p_conc_program
                            || ' is not invoked'
                           );
      ELSE
      NULL;
      END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                     p_conc_program
                                  || ' Wait_for_request, failed to invoke'
                                 );               
   END sumbit_conc_program;

   PROCEDURE xxod_us_mon_bill_mains (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   VARCHAR2,
      p_from_date   IN       VARCHAR2,
      p_to_date     IN       VARCHAR2
   )
   IS

   BEGIN

      XXOD_STAND_US_PAYDOC(p_errbuf,
      p_retcode,
      p_from_date,
      p_to_date
      );
      XXOD_STAND_US_INFODOC(p_errbuf,
      p_retcode,
      p_from_date,
      p_to_date
      );
      XXOD_CONS_DTL_US_PAYDOC(p_errbuf,
      p_retcode,
      p_from_date,
      p_to_date
      );      
      XXOD_CONS_DTL_US_INFODOC(p_errbuf,
      p_retcode,
      p_from_date,
      p_to_date
      );      
      

    EXCEPTION
    WHEN OTHERS THEN
         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := SQLCODE;
         RAISE;        
   END xxod_us_mon_bill_mains;

   PROCEDURE xxod_ca_mon_bill_mains (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   VARCHAR2,
      p_from_date   IN       VARCHAR2,
      p_to_date     IN       VARCHAR2
   )
   IS

   BEGIN
      XXOD_STAND_CA_PAYDOC(p_errbuf,
      p_retcode,
      p_from_date,
      p_to_date
      );
      XXOD_STAND_CA_INFODOC(p_errbuf,
      p_retcode,
      p_from_date,
      p_to_date
      );
      XXOD_CONS_DTL_CA_PAYDOC(p_errbuf,
      p_retcode,
      p_from_date,
      p_to_date
      );      
      XXOD_CONS_DTL_CA_INFODOC(p_errbuf,
      p_retcode,
      p_from_date,
      p_to_date
      );       
      
    EXCEPTION
    WHEN OTHERS THEN
         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := SQLCODE;    
         RAISE;
   END xxod_ca_mon_bill_mains;
   PROCEDURE xxod_mon_bill_mains(p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   VARCHAR2,
      p_from_date   IN       VARCHAR2,
      p_to_date     IN       VARCHAR2,
        p_dest_path   IN       VARCHAR2)
    
    IS
    
    ln_request_id          NUMBER;
    lc_phase       VARCHAR2(1000);
    lc_status      VARCHAR2(1000);
    lc_dev_phase   VARCHAR2(1000);
    lc_dev_status  VARCHAR2(1000);
    lc_messages    VARCHAR2(1000);
    lb_wait        BOOLEAN;
    
    BEGIN
               fnd_file.put_line
                      (fnd_file.LOG,
                       'From date '||fnd_date.canonical_to_date(p_from_date)); 
            fnd_file.put_line
                      (fnd_file.LOG,
                       'To date '||fnd_date.canonical_to_date(p_to_date));
        BEGIN
         SELECT directory_path
           INTO p_file_path
           FROM dba_directories
          WHERE directory_name = 'XXFIN_OUTBOUND';
        EXCEPTION
         WHEN OTHERS
         THEN
            p_file_path := NULL;
        END;
    p_file_name :=
               'XX_AR_MONTHLY_BILLING_'
            || TO_CHAR(SYSDATE, 'DDMONYYYYHH24MISS')
            ||'_'                --Added for Defect 12435
            || fnd_global.conc_request_id     --Added for Defect 12435
            || '.txt';
    lc_file_handle := UTL_FILE.fopen('XXFIN_OUTBOUND', p_file_name, 'W', 32767);    
    fnd_file.put_line (fnd_file.output, 'Filename is :' || p_file_name);
    fnd_file.put_line (fnd_file.LOG,'File Name : '||p_file_name);      
    fnd_file.put_line (fnd_file.output, 'Unix File Path is :' || p_file_path);
    fnd_file.put_line (fnd_file.output, 'Windows File Path is :' || '\\USCHNFSCIFS11\msbilling$\pstgb\ebills'); -- HardCoding the value for $XXFIN_DATA/ebills
    fnd_file.put_line (fnd_file.LOG,'File Path: '||p_file_path);    
    lv_col_title :=
            'account#'
         || '|'||
         'Cons_Invoice_Id'
         || '|'||         
         'COUNT(invoice#)'         
         || '|'||
         'SUM(amount)'
         || '|'||
         'actual_bill_date'
         || '|'||
         'delivery_method'
         || '|'||
         'direct_indirect'
         || '|'||
         'document_id'
         || '|'||
         'customer_doc_id'
         || '|'||
         'paydoc_infodoc'
         || '|'||
         'frequency'
         || '|'||
         'payment_term'
         || '|'||
         'payment_term_name'
         || '|'||
         'account_name'
         || '|'||
         'Operating_unit'
         || '|'||
         'Period_start'
         || '|'||
         'Period_end';    
      UTL_FILE.put_line(lc_file_handle,lv_col_title);
      xxod_us_mon_bill_mains(p_errbuf,
      p_retcode,
      p_from_date,
      p_to_date);
      
      xxod_ca_mon_bill_mains(p_errbuf,
      p_retcode,
      p_from_date,
      p_to_date);     
      
     fnd_file.put_line (fnd_file.LOG, ' Starting the file Copy to location ' || p_dest_path ); 
      
     ln_request_id := FND_REQUEST.SUBMIT_REQUEST ('XXFIN'
                                                             ,'XXCOMFILCOPY'
                                                             ,NULL
                                                             ,NULL
                                                             ,FALSE
                                                             ,p_file_path||'/'||p_file_name
                                                             ,p_dest_path||'/'||p_file_name
                                                             );
     
     COMMIT;
                
     lb_wait := fnd_concurrent.wait_for_request ( ln_request_id
                                                             ,10
                                                             ,NULL
                                                             ,lc_phase
                                                             ,lc_status
                                                             ,lc_dev_phase
                                                             ,lc_dev_status
                                                             ,lc_messages
                                                             ); 
     
     fnd_file.put_line (fnd_file.LOG, ' File has been copied to the location ' || p_dest_path ); 
      
      UTL_FILE.fclose(lc_file_handle);      
      EXCEPTION
        WHEN UTL_FILE.access_denied THEN
         lc_errormsg :=
            (   'AR Monthly Billing Report Generation Errored :- '
             || ' access_denied :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.delete_failed THEN
         lc_errormsg :=
            (   ' AR Monthly Billing Report Generation Errored :- '
             || ' delete_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.file_open THEN
         lc_errormsg :=
            (   ' AR Monthly Billing Report Generation Errored :- '
             || ' file_open :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.internal_error THEN
         lc_errormsg :=
            (   ' AR Monthly Billing Report Generation Errored :- '
             || ' internal_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filehandle THEN
         lc_errormsg :=
            (   ' AR Monthly Billing Report Generation Errored :- '
             || ' invalid_filehandle :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
      WHEN UTL_FILE.invalid_filename THEN
         lc_errormsg :=
            (   ' AR Monthly Billing Report Generation Errored :- '
             || ' invalid_filename :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_maxlinesize THEN
         lc_errormsg :=
            (   ' AR Monthly Billing Report Generation Errored :- '
             || ' invalid_maxlinesize :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_mode  THEN
         lc_errormsg :=
            (   ' AR Monthly Billing Report Generation Errored :- '
             || ' invalid_mode :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_offset
      THEN
         lc_errormsg :=
            (   ' AR Monthly Billing Report Generation Errored :- '
             || ' invalid_offset :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_operation
      THEN
         lc_errormsg :=
            (   ' AR Monthly Billing Report Generation Errored :- '
             || ' invalid_operation :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.invalid_path
      THEN
         lc_errormsg :=
            (   ' AR Monthly Billing Report Generation Errored :- '
             || ' invalid_path :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.read_error
      THEN
         lc_errormsg :=
            (   ' AR Monthly Billing Report Generation Errored :- '
             || ' read_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.rename_failed
      THEN
         lc_errormsg :=
            (   ' AR Monthly Billing Report Generation Errored :- '
             || ' rename_failed :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

      WHEN UTL_FILE.write_error
      THEN
         lc_errormsg :=
            (   ' AR Monthly Billing Report Generation Errored :- '
             || ' write_error :: '
             || SQLERRM
             || SQLCODE
            );

         fnd_file.put_line (fnd_file.LOG, lc_errormsg);

         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);


      WHEN OTHERS
      THEN
         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := SQLCODE;
         fnd_file.put_line (fnd_file.output, 'Error Package ');
         raise_application_error (-20001, 'Error ' || p_errbuf);
         
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);
         RAISE;
    
         
    END xxod_mon_bill_mains;    
END XXOD_MONTHLY_BILLING_RPT_PKG;
/