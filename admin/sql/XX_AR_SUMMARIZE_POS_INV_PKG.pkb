
  CREATE OR REPLACE PACKAGE BODY XX_AR_SUMMARIZE_POS_INV_PKG AS
   -- +=====================================================================+
   -- | Name :                                                              |
   -- | Description :                                                       |
   -- |             Release 11.3 AR Sales Data Redesign - AR Track          |
   -- |             Package calling program: E80 called from                |
   -- |             OD: AR Summarize POS Sales                              |
   -- | Parameters                                                          |
   -- | Returns :                                                           |
   -- | Change Record:                                                      |
   -- |===============                                                      |
   -- |Version   Date              Author                  Remarks          |
   -- |======   ==========     =============     ===========================|
   -- |1.0      17-MAR-2011    P. Marco                                     |
   -- |1.1      05-SEP-2012    Adithya           For QC Defect#19820        |
   -- |1.2	05-JUL-2013    Manasa	         E0080 - R12 Upgrade        |
   -- |                                          Retrofit changes           |
   -- |1.3      16-SEP-2013    Manasa            E0080 - R12 Upgrade change |
   -- |                                          to set taxable_flag to 'N' |
   -- |2.0      18-NOV-2014    Sridevi K         ILM E0080 - Defect31661    |
   -- |2.1      27-OCT-2015    Vasu Raparla      Removed schema References  |
   -- |                                          for R12.2                  |
   -- |2.2      30-SEP-2016    Ray Strauss       added hint for R12.2.5     |
   -- |                                          /*+ leading(xri) */        |
   -- +=====================================================================+
   -- Global Variables
   gc_debug_flg                 VARCHAR2(1):= 'N';
   gd_process_date              DATE;
   gn_cust_id_low               xx_ar_intstorecust_otc.cust_account_id%TYPE;
   gn_cust_id_high              xx_ar_intstorecust_otc.cust_account_id%TYPE;
   gc_cust_account_low          xx_ar_intstorecust_otc.account_number%TYPE;
   gc_cust_account_high         xx_ar_intstorecust_otc.account_number%TYPE;

   gc_batch_source_name         xx_ra_int_lines_all.batch_source_name%TYPE;
   gc_bulk_limit                NUMBER;
   gc_display_log_details       VARCHAR2(1);
   gn_org_id                    xx_ra_int_lines_all.org_id%TYPE;
   gn_login_id                  NUMBER  := FND_PROFILE.VALUE('LOGIN_ID');
   gn_user_id                   NUMBER  := FND_PROFILE.VALUE('USER_ID');
   gn_sum_inv_line_rev_gt       NUMBER;
   gn_sum_inv_line_tax_gt       NUMBER;
   gn_sum_inv_line_rec_gt       NUMBER;
   gn_bulk_limit                NUMBER  :=5000;
   gn_request_id                NUMBER  := FND_GLOBAL.CONC_REQUEST_ID;
   gc_concat_email              VARCHAR2(500);
   gc_inv_not_sum_header        VARCHAR2(1) := 'Y';
   gc_ref_rec_not_inserted      VARCHAR2(1) := 'N';
   gc_out_of_balance_flag       VARCHAR2(1) := 'N';
   gn_create_summary_warning    NUMBER;

   gc_debug_loc                 VARCHAR2(250);
   gc_debug_stmt                VARCHAR2(250);
   gc_proc_name                 VARCHAR2(50);

   gb_print_option              BOOLEAN  := FALSE;
   gb_wait_for_requests         BOOLEAN  := FALSE;
   gn_conc_id                   fnd_concurrent_requests.request_id%TYPE := -1;
   gc_phase                     VARCHAR2(100) := NULL;
   gc_status                    VARCHAR2(100) := NULL;
   gc_dev_phase                 VARCHAR2(100) := NULL;
   gc_dev_status                VARCHAR2(100) := NULL;
   gc_wait_message              VARCHAR2(100) := NULL;
   gc_req_data                  VARCHAR2(240) := NULL;

   gn_xx_int_lines_del_sum_cnt  NUMBER := 0;
   gn_xx_int_dist_del_sum_cnt   NUMBER := 0;
   gn_xx_int_sales_del_sum_cnt  NUMBER := 0;
   gn_xx_int_lines_del_dtl_cnt  NUMBER := 0;
   gn_xx_int_dist_del_dtl_cnt   NUMBER := 0;
   gn_xx_int_sales_del_dtl_cnt  NUMBER := 0;

   gn_xx_sum_inv_inserted       NUMBER := 0;
   gn_xx_sum_lines_inserted     NUMBER := 0;
   gn_xx_sum_dists_inserted     NUMBER := 0;
   gn_xx_sum_sales_inserted     NUMBER := 0;
   gn_xx_detailed_inv_errors    NUMBER := 0;
   gn_xx_detailed_inv_linked    NUMBER := 0;

   G_ORDER_ENTRY                CONSTANT   xx_ra_int_lines_all.interface_line_context%TYPE    := 'ORDER ENTRY';
   G_POS_ORDER_ENTRY            CONSTANT   xx_ra_int_lines_all.interface_line_context%TYPE    := 'POS Order Entry';
   G_SUMMARY                    CONSTANT   xx_ra_int_lines_all.interface_line_attribute3%TYPE := 'SUMMARY';

   CHECK_IMPORT_STATUS_EXP      EXCEPTION;

   --------------------------------------
   --Added for R12 Retrofit for tax lines
   ---------------------------------------
   --US
   gc_tax_rate_code            zx_rates_b.tax_rate_code%TYPE     := 'SALES';
   gc_tax_rate_code1           zx_rates_b.tax_rate_code%TYPE     := 'SALES1';
   gc_tax_line1                zx_rates_b.tax%TYPE               := 'SALES_TAX1';
   gc_tax_line2                zx_rates_b.tax%TYPE               := 'SALES_TAX2';
   --CANADA
   gc_tax_rate_county          zx_rates_b.tax_rate_code%TYPE     := 'COUNTY';
   gc_tax_rate_state           zx_rates_b.tax_rate_code%TYPE     := 'STATE';
   gc_tax_regime_code_ca       zx_rates_b.tax_regime_code%TYPE   := 'OD_CA_SALES_TAX';
   --US
   gc_tax_regime_code_us       zx_rates_b.tax_regime_code%TYPE;
   gc_tax_status_code_us       zx_rates_b.tax_status_code%TYPE;
   gc_tax_regime_code_us1      zx_rates_b.tax_regime_code%TYPE;
   gc_tax_status_code_us1      zx_rates_b.tax_status_code%TYPE;
   gc_rate_percent             zx_rates_b.percentage_rate%TYPE;
   gc_rate_percent1            zx_rates_b.percentage_rate%TYPE;
   --CANADA
   gc_tax_status_code_ca       zx_rates_b.tax_status_code%TYPE;
   gc_tax_status_code_ca1      zx_rates_b.tax_status_code%TYPE;
   gc_tax_county               zx_rates_b.tax%TYPE;
   gc_tax_state                zx_rates_b.tax%TYPE;
   gc_rate_percent_state       zx_rates_b.percentage_rate%TYPE;
   gc_rate_percent_county      zx_rates_b.percentage_rate%TYPE;

   gc_line_type_TAX_hc         ra_interface_lines_all.line_type%TYPE := 'TAX';
   gc_line_type_LINE_hc        ra_interface_lines_all.line_type%TYPE := 'LINE';
   gc_tax_type_GST_hc          ra_interface_lines_all.interface_line_attribute9%TYPE := 'GST';
   gc_tax_type_PST_hc          ra_interface_lines_all.interface_line_attribute9%TYPE := 'PST';

   -- +=====================================================================+
   -- | Name : SEND_EMAIL                                                   |
   -- | Description : Procedure to send mails                               |
   -- | Parameters  p_email_address, p_subject, p_body                      |
   -- | Returns :                                                           |
   -- +=====================================================================+
   PROCEDURE SEND_EMAIL (p_email_address IN  VARCHAR2
                        ,p_subject       IN  VARCHAR2  DEFAULT NULL
                        ,p_body          IN  VARCHAR2  DEFAULT NULL)
   AS
      ln_conc_id           NUMBER;
   BEGIN
      ----------------------
      -- Sending error email
      ----------------------
      ln_conc_id := FND_REQUEST.SUBMIT_REQUEST (application => 'XXFIN'
                                               ,program     => 'XXODEMAILER'
                                               ,description => NULL
                                               ,start_time  => SYSDATE
                                               ,sub_request => FALSE
                                               ,argument1   => p_email_address
                                               ,argument2   => p_subject
                                               ,argument3   => p_body);
      COMMIT;
   END SEND_EMAIL;


   -- +=====================================================================+
   -- | Name : CHECK_CHILD_STATUS                                           |
   -- | Description : Procedure to check status of child program submitted  |
   -- |               used to set status of Master Program                  |
   -- | Parameters  p_request_id                                            |
   -- | Returns :                                                           |
   -- +=====================================================================+

   PROCEDURE GET_CHILD_STATUS (p_request_id  IN NUMBER )
   AS
      cnt_errors  NUMBER  := 0;
      cnt_warnings NUMBER  :=0;
      request_status BOOLEAN;

   BEGIN

       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ' );

       FOR child_request_rec IN (SELECT request_id, status_code
                                   FROM fnd_concurrent_requests
                                  WHERE parent_request_id = p_request_id)
       LOOP

                IF ( child_request_rec.status_code = 'G' OR child_request_rec.status_code = 'X'
                OR child_request_rec.status_code ='D' OR child_request_rec.status_code ='T' ) THEN

                      cnt_warnings := cnt_warnings + 1;
                      FND_FILE.PUT_LINE(FND_FILE.LOG, '     Child program ended in WARNING! '
                                        ||'please review concurrent request ' || child_request_rec.request_id);

                ELSIF ( child_request_rec.status_code = 'E' ) THEN

                      cnt_errors := cnt_errors + 1;
                      FND_FILE.PUT_LINE(FND_FILE.LOG, '     Child program ended in ERROR! '
                                        ||'please review concurrent request ' || child_request_rec.request_id);
                END IF;
        END LOOP;      -- FOR child_request_rec

        IF cnt_errors > 0 THEN
              dbms_output.put_line( 'Setting completion status to ERROR.');
              request_status := fnd_concurrent.set_completion_status('ERROR', '');

        ELSIF cnt_warnings > 0 THEN
              dbms_output.put_line( 'Setting completion status to WARNING.');
             request_status := fnd_concurrent.set_completion_status('WARNING', '');

        ELSE
              dbms_output.put_line( 'Setting completion status to NORMAL.');
              request_status := fnd_concurrent.set_completion_status('NORMAL', '');

        END IF;

   END GET_CHILD_STATUS;

   -- +=====================================================================+
   -- | Name : WRITE_OUTPUT                                                 |
   -- | Description : Procedure to write output file                        |
   -- | Parameters p_process_date, gn_org_id, p_batch_name, p_print_flg     |
   -- | Returns :                                                           |
   -- +=====================================================================+
   PROCEDURE WRITE_OUTPUT (p_print_flg     IN  VARCHAR2  DEFAULT NULL)
   AS
      lc_operating_unit        VARCHAR2(25);
      NO_OPERATING_UNIT_PRT    EXCEPTION;

   BEGIN

      IF p_print_flg = 'HEADER' THEN
         ------------------------------------
         -- Getting operating unit to display
         ------------------------------------
         BEGIN
            SELECT name
              INTO lc_operating_unit
              FROM hr_all_organization_units
             WHERE organization_id  = gn_org_id;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               RAISE NO_OPERATING_UNIT_PRT;

            WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                                   '     Getting operating unit to display '
                                          ||  SUBSTR(SQLERRM,1,249));
         END;

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------'
                                         ||'---------------------------------'
                                         ||'---------------------------------'
                                         ||'-----------------------------');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Office Depot                      '
                                         ||'                                 '
                                         ||'                                 '
                                         ||' Date: '|| TRUNC(SYSDATE));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Request ID: '|| gn_request_id
                                         ||'                                 '
                                         ||'                                 '
                                         || '                       Page: 1 ');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                       '
                                         ||'                                 '
                                         || 'OD: AR Summarize POS Sales');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Organization : '
                                         ||lc_operating_unit );
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Process Date : '
                                         || gd_process_date);

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');

      END IF;

      IF p_print_flg = 'INV_NOT_SUM' THEN

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Invoices NOT Summarized');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----------------------------');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   '||'Trans Date   '
                                                 ||'Store                               '
                                                 ||'Transaction Type             '
                                                 ||'Invoice Lines           '
                                                 ||'Invoice Amount          '
                           );
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   '||'----------'
                                                 ||'   ---------------------------------'
                                                 ||'   ---------------------------'
                                                 ||'  ----------------------'
                                                 ||'  ----------------------'
                          );
      END IF;

      IF p_print_flg = 'REFERENCE_STATUS_HEADER' THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Invoices Not Inserted in Reference tables');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'--------------------------------');

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   '||'Trans Date   '
                                                 ||'Transaction Type        '
                                                 ||'Invoice Lines           '
                                                 ||'Invoice Amount          '
                           );

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   '||'----------'
                                                 ||'   ---------------------'
                                                 ||'   ---------------------'
                                                 ||'   ---------------------'
                           );
      END IF;

   END WRITE_OUTPUT;

   -- +=====================================================================+
   -- | Name : WRITE_LOG                                                    |
   -- | Description : Prodecure to Write log file data                      |
   -- | Parameters    p_display_flg,p_proc ,p_location ,p_statement         |
   -- | Returns :                                                           |
   -- +=====================================================================+
   PROCEDURE WRITE_LOG (p_display_flg IN VARCHAR2
                       ,p_proc        IN VARCHAR2 DEFAULT NULL
                       ,p_location    IN VARCHAR2 DEFAULT NULL
                       ,p_statement   IN VARCHAR2 DEFAULT NULL
                       )

   AS
   BEGIN

      IF p_display_flg = 'Y' THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, ' '
                        || p_proc       ||': '
                        || p_location   ||': '
                        || ' '||p_statement);

      END IF;

   END WRITE_LOG;

   -- +=====================================================================+
   -- | Name : INV_DEFAULT_LOOKUPS                                          |
   -- | Description :  Procure to get default lookup values                 |
   -- | Parameters : gc_batch_source_name ,gn_org_id, lc_get_emails         |
   -- | Returns : p_return_code, lc_trans_flg ,lc_acct_catgry               |
   -- +=====================================================================+
   PROCEDURE INV_DEFAULT_LOOKUPS (p_return_code       OUT NUMBER
                                 ,lc_trans_flg        OUT VARCHAR2
                                 ,lc_acct_catgry      OUT VARCHAR2
                                 ,lc_get_emails       IN VARCHAR2 )
   AS
      lc_email_01          VARCHAR2(250);
      lc_email_02          VARCHAR2(250);
      lc_operating_unit    hr_all_organization_units.name%TYPE;

       NO_OPERATING_UNIT    EXCEPTION;

   BEGIN
      gc_proc_name   := '    INV_DEFAULT_LOOKUPS';
      p_return_code := 0;
      -------------------------
      -- Getting operating unit
      -------------------------
      gc_debug_loc := 'Getting operating unit';
      BEGIN

         SELECT name
           INTO lc_operating_unit
           FROM hr_all_organization_units
          WHERE organization_id = gn_org_id;

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            RAISE  NO_OPERATING_UNIT;

      END;


      IF lc_get_emails = 'Y'  THEN

         gc_debug_loc := 'Getting Mail addresses';

         SELECT tv.target_value4
               ,tv.target_value5
           INTO lc_email_01
               ,lc_email_02
           FROM xx_fin_translatedefinition  td
               ,xx_fin_translatevalues      tv
          WHERE translation_name = 'OD_AR_INVOICING_DEFAULTS'
            AND tv.translate_id  = td.translate_id
            AND tv.target_value1 = gc_batch_source_name
            AND tv.source_value1 = lc_operating_unit
            AND tv.target_value3 = 'Y'
            AND td.enabled_flag  = 'Y'
            AND tv.enabled_flag  = 'Y';

         gc_concat_email := lc_email_01 || '|'||lc_email_02;


      ELSE
         gc_debug_loc :=   'Account Category and Summary flag';

         SELECT tv.target_value3
               ,tv.target_value2
           INTO lc_trans_flg
               ,lc_acct_catgry
           FROM xx_fin_translatedefinition  td
               ,xx_fin_translatevalues      tv
          WHERE translation_name = 'OD_AR_INVOICING_DEFAULTS'
            AND tv.translate_id  = td.translate_id
            AND tv.target_value1 = gc_batch_source_name
            AND tv.source_value1 = lc_operating_unit
            AND tv.target_value3 = 'Y'
            AND td.enabled_flag  = 'Y'
            AND tv.enabled_flag  = 'Y';

      END IF;


   EXCEPTION

      WHEN NO_OPERATING_UNIT    THEN
         gc_debug_stmt := 'Operating unit not defined for ORG ID '
                           || gn_org_id
                           ||' on hr_all_organization_units table';

         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
         p_return_code := 2;

      WHEN NO_DATA_FOUND THEN

         gc_debug_loc  := 'Translation table OD_AR_INVOICING_DEFAULTS';
         gc_debug_stmt := 'Translation table OD_AR_INVOICING_DEFAULTS'
                           ||' missing values for gc_batch_source_name ='
                           || gc_batch_source_name
                           ||' lc_operating_unit ='||lc_operating_unit;
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
                    p_return_code := 1;

      WHEN OTHERS THEN

         gc_debug_loc  := 'Translation OD_AR_INVOICING_DEFAULTS Error';
         gc_debug_stmt :=  SUBSTR(SQLERRM,1,249);
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
                    p_return_code := 1;

   END INV_DEFAULT_LOOKUPS;

   -- +=====================================================================+
   -- | Name : SUBMIT_AUTOINV_MSTR                                          |
   -- | Description : Procedure to submit Auto invoice program              |
   -- | Parameters  p_autoinv_thread_count ,gc_batch_source_name ,gn_org_id |
   -- | Returns : p_return_code                                             |
   -- +=====================================================================+
   PROCEDURE SUBMIT_AUTOINV_MSTR (p_return_code           OUT  NUMBER
                                 ,p_autoinv_thread_count   IN  NUMBER
                                 ,p_cust_account_low       IN  VARCHAR2
                                 ,p_cust_account_high      IN  VARCHAR2)
   AS
      ln_batch_source_id   NUMBER;
      lc_phase             VARCHAR2(100);
      lc_status            VARCHAR2(100);
      lc_dev_phase         VARCHAR2(100);
      lc_dev_status        VARCHAR2(100);
      lc_message           VARCHAR2(100);
      lb_bool              BOOLEAN;
      ln_conc_id           NUMBER;
      ls_req_data          VARCHAR2(240);

   BEGIN
      gc_proc_name  := '    SUBMIT_AUTOINV_MSTR';
      gc_debug_loc  := '         Autoinvoice Import Program';
      gc_debug_stmt := 'Thread Count = '|| p_autoinv_thread_count;
      WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

      ----------------------
      -- Get Batch Source ID
      ----------------------
      SELECT batch_source_id
        INTO ln_batch_source_id
        FROM ra_batch_sources_all
       WHERE name   = gc_batch_source_name
         AND org_id = gn_org_id;

      gc_debug_loc  := '         Selected Batch Source ID from ra_batch_sources_all ';
      gc_debug_stmt := ' ln_batch_source_id = '|| ln_batch_source_id;
      WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

      gc_debug_loc  := '         Submitting Autoinvoice Master Program';
      gc_debug_stmt := 'Batch Source '||gc_batch_source_name;
      WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');


      gc_debug_loc := 'Setting Printer and Copies';
      gb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(printer     => NULL
                                                       ,copies      => 0);

      --Commented for R12 Retrofit
      /*ln_conc_id := FND_REQUEST.SUBMIT_REQUEST(
                                 application  => 'AR'
                                 ,program     => 'RAXMTR'
                                 ,description => ''
                                 ,start_time  => ''
                                 ,sub_request => FALSE
                                 ,argument1   => p_autoinv_thread_count
                                 ,argument2   => ln_batch_source_id
                                 ,argument3   => gc_batch_source_name
                                 ,argument4   => TO_CHAR(TRUNC(SYSDATE),'RRRR/MM/DD HH24:MI:SS')
                                 ,argument5   => ''
                                 ,argument6   => ''
                                 ,argument7   => ''
                                 ,argument8   => ''
                                 ,argument9   => ''
                                 ,argument10  => ''
                                 ,argument11  => ''
                                 ,argument12  => ''
                                 ,argument13  => ''
                                 ,argument14  => ''
                                 ,argument15  => ''
                                 ,argument16  => ''
                                 ,argument17  => ''
                                 ,argument18  => ''
                                 ,argument19  => ''
                                 ,argument20  => ''
                                 ,argument21  => p_cust_account_low
                                 ,argument22  => p_cust_account_high
                                 ,argument23  => ''
                                 ,argument24  => ''
                                 ,argument25  => 'Y'
                                 ,argument26  => ''
                                 ,argument27  => gn_org_id
                                 ,argument28  => CHR(0)
                                                     );*/

      --Changed for R12 Retrofit
      ln_conc_id := FND_REQUEST.SUBMIT_REQUEST(
                                 application  => 'AR'
                                 ,program     => 'RAXMTR'
                                 ,description => ''
                                 ,start_time  => ''
                                 ,sub_request => FALSE
                                 ,argument1   => p_autoinv_thread_count
                                 ,argument2   => gn_org_id
                                 ,argument3   => ln_batch_source_id
                                 ,argument4   => gc_batch_source_name
                                 ,argument5   => TO_CHAR(TRUNC(SYSDATE),'RRRR/MM/DD HH24:MI:SS')
                                 ,argument6   => ''
                                 ,argument7   => ''
                                 ,argument8   => ''
                                 ,argument9   => ''
                                 ,argument10  => ''
                                 ,argument11  => ''
                                 ,argument12  => ''
                                 ,argument13  => ''
                                 ,argument14  => ''
                                 ,argument15  => ''
                                 ,argument16  => ''
                                 ,argument17  => ''
                                 ,argument18  => ''
                                 ,argument19  => ''
                                 ,argument20  => ''
                                 ,argument21  => ''
                                 ,argument22  => p_cust_account_low
                                 ,argument23  => p_cust_account_high
                                 ,argument24  => ''
                                 ,argument25  => ''
                                 ,argument26  => 'Y'
                                 ,argument27  => ''
                                 ,argument28  => CHR(0)
                                                     );

      COMMIT;

      gc_debug_loc  := '         Concurrent Request '||ln_conc_id ||': Submitted Auto Invoice';
      WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, TO_CHAR(SYSDATE,'DD/MM/RRRR HH24:MI:SS'));

      lb_bool := FND_CONCURRENT.WAIT_FOR_REQUEST(ln_conc_id
                                                ,5
                                                ,200000
                                                ,lc_phase
                                                ,lc_status
                                                ,lc_dev_phase
                                                ,lc_dev_status
                                                ,lc_message);



      IF ((lc_dev_phase = 'COMPLETE') AND (lc_dev_status = 'NORMAL')) THEN
         gc_debug_loc  := '         Concurrent Request '||ln_conc_id ||': Successfully Completed';
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, TO_CHAR(SYSDATE,'DD/MM/RRRR HH24:MI:SS'));
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

         p_return_code := 0;

      ELSE

         gc_debug_loc  := '    Concurrent request '||ln_conc_id
                                                       ||' not successful ';
         gc_debug_stmt := 'Please check log!';
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt);

         p_return_code := 1;

      END IF;

      WRITE_LOG('Y','  Current System Time: ',
                    to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );


   EXCEPTION
      WHEN OTHERS THEN
         gc_debug_stmt :=  SUBSTR(SQLERRM,1,249);
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
         p_return_code := 1;

   END SUBMIT_AUTOINV_MSTR;

   -- +=====================================================================+
   -- | Name :INST_RA_INTR_TBLS                                             |
   -- | Description :Procedure to insert summarized records into            |
   -- |              interface tables                                       |
   -- | Parameters  gc_batch_source_name , gn_org_id                        |
   -- | Returns :  p_return_code                                            |
   -- +=====================================================================+
   PROCEDURE INST_RA_INTR_TBLS (p_return_code  OUT  NUMBER)
   AS
      ln_summary_dtl_rev   NUMBER;
      ln_summary_dtl_tax   NUMBER;
      ln_summary_dtl_rec   NUMBER;

      ln_conc_id           NUMBER;

      ln_inserted_ra_int_line_cnt   NUMBER := 0;
      ln_inserted_ra_int_dist_cnt   NUMBER := 0;
      ln_inserted_ra_int_sales_cnt  NUMBER := 0;

      SUMMARY_CHECK_ERR    EXCEPTION;

--      TYPE TrxsNumTable IS TABLE OF
--               XX_RA_INT_LINES_ALL.INTERFACE_LINE_ATTRIBUTE1%TYPE;

--      ObjectTable$ TrxsNumTable;

      --Added for R12 Retrofit to derive tax columns
      --This cursor is the driving cursor to derive the trx_number
      CURSOR lcu_get_dist_trx_num
      IS
         SELECT DISTINCT RILA.trx_number
           FROM ra_interface_lines_all     RILA
          WHERE RILA.orig_system_bill_customer_id BETWEEN gn_cust_id_low
                                                            AND gn_cust_id_high
            AND RILA.interface_line_attribute3    = G_SUMMARY
            AND RILA.interface_line_context       = G_POS_ORDER_ENTRY
            AND RILA.interface_status             IS NULL
            AND RILA.org_id                       = gn_org_id
            AND RILA.batch_source_name            = gc_batch_source_name
            AND RILA.line_type                    = gc_line_type_TAX_hc
          ORDER BY RILA.trx_number;


      --Added for R12 Retrofit
      --This cursor is used to derive the interface attribute cols to update tax colums
      CURSOR lcu_upd_tax_cols(p_trx_number IN VARCHAR2)
      IS
         SELECT RILA.interface_line_attribute9
               ,RILA.line_type
               ,RILA.line_number
               ,RILA.orig_system_bill_customer_id
               ,RILA.interface_line_id
               ,RILA.trx_number
               ,RILA.interface_line_attribute2
           FROM ra_interface_lines_all     RILA
          WHERE RILA.orig_system_bill_customer_id BETWEEN gn_cust_id_low
                                                            AND gn_cust_id_high
            AND RILA.interface_line_attribute3    = G_SUMMARY
            AND RILA.interface_line_context       = G_POS_ORDER_ENTRY
            AND RILA.interface_status             IS NULL
            AND RILA.org_id                       = gn_org_id
            AND RILA.batch_source_name            = gc_batch_source_name
            AND RILA.line_type                    = gc_line_type_TAX_hc
            AND RILA.trx_number                   = p_trx_number
          ORDER BY RILA.trx_number,ROWNUM;

         TYPE t_bulk_dist_trx IS TABLE OF lcu_get_dist_trx_num%ROWTYPE
              INDEX BY BINARY_INTEGER;

         rec_dist_trx t_bulk_dist_trx;

         ln_interface_PREV  VARCHAR2(1000);
         ln_interface_CURR  VARCHAR2(1000);

   BEGIN
      gc_proc_name  := '    INST_RA_INTR_TBLS';
      gc_debug_loc  := 'Executing INST_RA_INTR_TBLS:';
      gc_debug_stmt := 'Checking to copy data to RA interface tables ';

      WRITE_LOG(gc_debug_flg, gc_proc_name ,gc_debug_loc, gc_debug_stmt );

      SELECT NVL(SUM(DECODE(XRILA.line_type,'LINE',XRILA.amount)),0)  --SUMMARY_DTL_REV
            ,NVL(SUM(DECODE(XRILA.line_type,'TAX' ,XRILA.amount)),0)  --SUMMARY_DTL_TAX
            ,NVL(SUM(amount),0)                           --SUMMARY_DTL_REC
        INTO ln_summary_dtl_rev
            ,ln_summary_dtl_tax
            ,ln_summary_dtl_rec
        FROM xx_ra_int_lines_all     XRILA
       WHERE XRILA.batch_source_name      = gc_batch_source_name
         AND XRILA.org_id                 = gn_org_id
         AND XRILA.interface_line_context = G_ORDER_ENTRY
         AND XRILA.interface_status       IS NULL
         AND XRILA.orig_system_bill_customer_id BETWEEN gn_cust_id_low
                                                    AND gn_cust_id_high;

      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
      WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
      WRITE_LOG('Y',NULL ,'Step #4 - Verify ALL Summary Inv Equal Detailed Inv    ',NULL);
      WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
      WRITE_LOG('Y','  Current System Time: ',TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

      WRITE_LOG('Y',gc_proc_name ,'      Summary Invoice Total  - REV', gn_sum_inv_line_rev_gt);
      WRITE_LOG('Y',gc_proc_name ,'      Detailed Invoice Total - REV', ln_summary_dtl_rev);
      WRITE_LOG('Y',gc_proc_name ,'      Summary Invoice Total  - TAX', gn_sum_inv_line_tax_gt);
      WRITE_LOG('Y',gc_proc_name ,'      Detailed Invoice Total - TAX', ln_summary_dtl_tax);
      WRITE_LOG('Y',gc_proc_name ,'      Summary Invoice Total  - REC', gn_sum_inv_line_rec_gt);
      WRITE_LOG('Y',gc_proc_name ,'      Detailed Invoice Total - REC', ln_summary_dtl_rec);

      -------------------------------------------------------
      -- Confirming summary lines and detail line net to zero
      ------------------------------------------------------
      IF (gn_sum_inv_line_rev_gt - ln_summary_dtl_rev <> 0) OR
         (gn_sum_inv_line_tax_gt - ln_summary_dtl_tax <> 0) OR
         (gn_sum_inv_line_rec_gt - ln_summary_dtl_rec <> 0) THEN

         RAISE SUMMARY_CHECK_ERR;

      ELSE

         gc_debug_stmt := 'Copy the sum inv from custom interface tables '
                        ||'to Autoinvoice interface tables';

         WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

         --SELECT DISTINCT XRILA.orig_system_bill_customer_id BULK COLLECT
         --  INTO ObjectTable$
         --  FROM xx_ra_int_lines_all     XRILA
         -- WHERE XRILA.batch_source_name         = gc_batch_source_name
         --   AND XRILA.org_id                    = gn_org_id
         --   AND XRILA.interface_line_context    = G_POS_ORDER_ENTRY
         --   AND XRILA.interface_line_attribute3 = G_SUMMARY
         --   AND XRILA.interface_status          IS NULL
         --   AND XRILA.orig_system_bill_customer_id BETWEEN gn_cust_id_low
         --                                              AND gn_cust_id_high;

         ---------------------------------------
         --Inserting into ra_interface_lines_all
         ---------------------------------------
         BEGIN
--            FORALL x IN ObjectTable$.FIRST..ObjectTable$.LAST
               --Commented for R12 Retrofit
               /*INSERT INTO ra_interface_lines_all
                          (SELECT  *
                             FROM xx_ra_int_lines_all XRILA
--                            WHERE XRILA.orig_system_bill_customer_id = OBJECTTABLE$(X)
                            WHERE XRILA.orig_system_bill_customer_id BETWEEN gn_cust_id_low
                                                                         AND gn_cust_id_high
                              AND XRILA.interface_line_attribute3    = G_SUMMARY
                              AND XRILA.interface_line_context       = G_POS_ORDER_ENTRY
                              AND XRILA.interface_status             IS NULL
                              AND XRILA.org_id                       = gn_org_id
                              AND XRILA.batch_source_name            = gc_batch_source_name);*/

					--Changed for R12 Retrofit
					INSERT INTO RA_INTERFACE_LINES_ALL
							           (interface_line_id,
                                 interface_line_context,
                                 interface_line_attribute1,
                                 interface_line_attribute2,
                                 interface_line_attribute3,
                                 interface_line_attribute4,
                                 interface_line_attribute5,
                                 interface_line_attribute6,
                                 interface_line_attribute7,
                                 interface_line_attribute8,
                                 batch_source_name,
                                 set_of_books_id,
                                 line_type,
                                 description,
                                 currency_code,
                                 amount,
                                 cust_trx_type_name,
                                 cust_trx_type_id,
                                 term_name,
                                 term_id,
                                 orig_system_batch_name,
                                 orig_system_bill_customer_ref,
                                 orig_system_bill_customer_id,
                                 orig_system_bill_address_ref,
                                 orig_system_bill_address_id,
                                 orig_system_bill_contact_ref,
                                 orig_system_bill_contact_id,
                                 orig_system_ship_customer_ref,
                                 orig_system_ship_customer_id,
                                 orig_system_ship_address_ref,
                                 orig_system_ship_address_id,
                                 orig_system_ship_contact_ref,
                                 orig_system_ship_contact_id,
                                 orig_system_sold_customer_ref,
                                 orig_system_sold_customer_id,
                                 link_to_line_id,
                                 link_to_line_context,
                                 link_to_line_attribute1,
                                 link_to_line_attribute2,
                                 link_to_line_attribute3,
                                 link_to_line_attribute4,
                                 link_to_line_attribute5,
                                 link_to_line_attribute6,
                                 link_to_line_attribute7,
                                 receipt_method_name,
                                 receipt_method_id,
                                 conversion_type,
                                 conversion_date,
                                 conversion_rate,
                                 customer_trx_id,
                                 trx_date,
                                 gl_date,
                                 document_number,
                                 trx_number,
                                 line_number,
                                 quantity,
                                 quantity_ordered,
                                 unit_selling_price,
                                 unit_standard_price,
                                 printing_option,
                                 interface_status,
                                 request_id,
                                 related_batch_source_name,
                                 related_trx_number,
                                 related_customer_trx_id,
                                 previous_customer_trx_id,
                                 credit_method_for_acct_rule,
                                 credit_method_for_installments,
                                 reason_code,
                                 tax_rate,
                                 tax_code,
                                 tax_precedence,
                                 exception_id,
                                 exemption_id,
                                 ship_date_actual,
                                 fob_point,
                                 ship_via,
                                 waybill_number,
                                 invoicing_rule_name,
                                 invoicing_rule_id,
                                 accounting_rule_name,
                                 accounting_rule_id,
                                 accounting_rule_duration,
                                 rule_start_date,
                                 primary_salesrep_number,
                                 primary_salesrep_id,
                                 sales_order,
                                 sales_order_line,
                                 sales_order_date,
                                 sales_order_source,
                                 sales_order_revision,
                                 purchase_order,
                                 purchase_order_revision,
                                 purchase_order_date,
                                 agreement_name,
                                 agreement_id,
                                 memo_line_name,
                                 memo_line_id,
                                 inventory_item_id,
                                 mtl_system_items_seg1,
                                 mtl_system_items_seg2,
                                 mtl_system_items_seg3,
                                 mtl_system_items_seg4,
                                 mtl_system_items_seg5,
                                 mtl_system_items_seg6,
                                 mtl_system_items_seg7,
                                 mtl_system_items_seg8,
                                 mtl_system_items_seg9,
                                 mtl_system_items_seg10,
                                 mtl_system_items_seg11,
                                 mtl_system_items_seg12,
                                 mtl_system_items_seg13,
                                 mtl_system_items_seg14,
                                 mtl_system_items_seg15,
                                 mtl_system_items_seg16,
                                 mtl_system_items_seg17,
                                 mtl_system_items_seg18,
                                 mtl_system_items_seg19,
                                 mtl_system_items_seg20,
                                 reference_line_id,
                                 reference_line_context,
                                 reference_line_attribute1,
                                 reference_line_attribute2,
                                 reference_line_attribute3,
                                 reference_line_attribute4,
                                 reference_line_attribute5,
                                 reference_line_attribute6,
                                 reference_line_attribute7,
                                 territory_id,
                                 territory_segment1,
                                 territory_segment2,
                                 territory_segment3,
                                 territory_segment4,
                                 territory_segment5,
                                 territory_segment6,
                                 territory_segment7,
                                 territory_segment8,
                                 territory_segment9,
                                 territory_segment10,
                                 territory_segment11,
                                 territory_segment12,
                                 territory_segment13,
                                 territory_segment14,
                                 territory_segment15,
                                 territory_segment16,
                                 territory_segment17,
                                 territory_segment18,
                                 territory_segment19,
                                 territory_segment20,
                                 attribute_category,
                                 attribute1,
                                 attribute2,
                                 attribute3,
                                 attribute4,
                                 attribute5,
                                 attribute6,
                                 attribute7,
                                 attribute8,
                                 attribute9,
                                 attribute10,
                                 attribute11,
                                 attribute12,
                                 attribute13,
                                 attribute14,
                                 attribute15,
                                 header_attribute_category,
                                 header_attribute1,
                                 header_attribute2,
                                 header_attribute3,
                                 header_attribute4,
                                 header_attribute5,
                                 header_attribute6,
                                 header_attribute7,
                                 header_attribute8,
                                 header_attribute9,
                                 header_attribute10,
                                 header_attribute11,
                                 header_attribute12,
                                 header_attribute13,
                                 header_attribute14,
                                 header_attribute15,
                                 comments,
                                 internal_notes,
                                 initial_customer_trx_id,
                                 ussgl_transaction_code_context,
                                 ussgl_transaction_code,
                                 acctd_amount,
                                 customer_bank_account_id,
                                 customer_bank_account_name,
                                 uom_code,
                                 uom_name,
                                 document_number_sequence_id,
                                 link_to_line_attribute10,
                                 link_to_line_attribute11,
                                 link_to_line_attribute12,
                                 link_to_line_attribute13,
                                 link_to_line_attribute14,
                                 link_to_line_attribute15,
                                 link_to_line_attribute8,
                                 link_to_line_attribute9,
                                 reference_line_attribute10,
                                 reference_line_attribute11,
                                 reference_line_attribute12,
                                 reference_line_attribute13,
                                 reference_line_attribute14,
                                 reference_line_attribute15,
                                 reference_line_attribute8,
                                 reference_line_attribute9,
                                 interface_line_attribute10,
                                 interface_line_attribute11,
                                 interface_line_attribute12,
                                 interface_line_attribute13,
                                 interface_line_attribute14,
                                 interface_line_attribute15,
                                 interface_line_attribute9,
                                 vat_tax_id,
                                 reason_code_meaning,
                                 last_period_to_credit,
                                 paying_customer_id,
                                 paying_site_use_id,
                                 tax_exempt_flag,
                                 tax_exempt_reason_code,
                                 tax_exempt_reason_code_meaning,
                                 tax_exempt_number,
                                 sales_tax_id,
                                 created_by,
                                 creation_date,
                                 last_updated_by,
                                 last_update_date,
                                 last_update_login,
                                 location_segment_id,
                                 movement_id,
                                 org_id,
                                 amount_includes_tax_flag,
                                 header_gdf_attr_category,
                                 header_gdf_attribute1,
                                 header_gdf_attribute2,
                                 header_gdf_attribute3,
                                 header_gdf_attribute4,
                                 header_gdf_attribute5,
                                 header_gdf_attribute6,
                                 header_gdf_attribute7,
                                 header_gdf_attribute8,
                                 header_gdf_attribute9,
                                 header_gdf_attribute10,
                                 header_gdf_attribute11,
                                 header_gdf_attribute12,
                                 header_gdf_attribute13,
                                 header_gdf_attribute14,
                                 header_gdf_attribute15,
                                 header_gdf_attribute16,
                                 header_gdf_attribute17,
                                 header_gdf_attribute18,
                                 header_gdf_attribute19,
                                 header_gdf_attribute20,
                                 header_gdf_attribute21,
                                 header_gdf_attribute22,
                                 header_gdf_attribute23,
                                 header_gdf_attribute24,
                                 header_gdf_attribute25,
                                 header_gdf_attribute26,
                                 header_gdf_attribute27,
                                 header_gdf_attribute28,
                                 header_gdf_attribute29,
                                 header_gdf_attribute30,
                                 line_gdf_attr_category,
                                 line_gdf_attribute1,
                                 line_gdf_attribute2,
                                 line_gdf_attribute3,
                                 line_gdf_attribute4,
                                 line_gdf_attribute5,
                                 line_gdf_attribute6,
                                 line_gdf_attribute7,
                                 line_gdf_attribute8,
                                 line_gdf_attribute9,
                                 line_gdf_attribute10,
                                 line_gdf_attribute11,
                                 line_gdf_attribute12,
                                 line_gdf_attribute13,
                                 line_gdf_attribute14,
                                 line_gdf_attribute15,
                                 line_gdf_attribute16,
                                 line_gdf_attribute17,
                                 line_gdf_attribute18,
                                 line_gdf_attribute19,
                                 line_gdf_attribute20,
                                 reset_trx_date_flag,
                                 payment_server_order_num,
                                 approval_code,
                                 address_verification_code,
                                 warehouse_id,
                                 translated_description,
                                 cons_billing_number,
                                 promised_commitment_amount,
                                 payment_set_id,
                                 original_gl_date,
                                 contract_line_id,
                                 contract_id,
                                 source_data_key1,
                                 source_data_key2,
                                 source_data_key3,
                                 source_data_key4,
		                               source_data_key5,
        	                        invoiced_line_acctg_level,
                                 override_auto_accounting_flag,
                                 taxable_flag
                       			  )
               SELECT
                    	            interface_line_id,
                                 interface_line_context,
                                 interface_line_attribute1,
                                 interface_line_attribute2,
                                 interface_line_attribute3,
                                 interface_line_attribute4,
                                 interface_line_attribute5,
                                 interface_line_attribute6,
                                 interface_line_attribute7,
                                 interface_line_attribute8,
                                 batch_source_name,
		                           set_of_books_id,
				                     line_type,
                                 description,
                                 currency_code,
                                 amount,
                                 cust_trx_type_name,
                                 cust_trx_type_id,
                                 term_name,
                                 term_id,
                                 orig_system_batch_name,
                                 orig_system_bill_customer_ref,
                                 orig_system_bill_customer_id,
                                 orig_system_bill_address_ref,
                                 orig_system_bill_address_id,
                                 orig_system_bill_contact_ref,
                                 orig_system_bill_contact_id,
                                 orig_system_ship_customer_ref,
                                 orig_system_ship_customer_id,
                                 orig_system_ship_address_ref,
                                 orig_system_ship_address_id,
                                 orig_system_ship_contact_ref,
                                 orig_system_ship_contact_id,
                                 orig_system_sold_customer_ref,
                                 orig_system_sold_customer_id,
                                 link_to_line_id,
                                 link_to_line_context,
                                 link_to_line_attribute1,
                                 link_to_line_attribute2,
                                 link_to_line_attribute3,
                                 link_to_line_attribute4,
                                 link_to_line_attribute5,
                                 link_to_line_attribute6,
                                 link_to_line_attribute7,
                                 receipt_method_name,
                                 receipt_method_id,
                                 conversion_type,
                                 conversion_date,
                                 conversion_rate,
                                 customer_trx_id,
                                 trx_date,
                                 gl_date,
                                 document_number,
                                 trx_number,
                                 line_number,
                                 quantity,
                                 quantity_ordered,
                                 unit_selling_price,
                                 unit_standard_price,
                                 printing_option,
                                 interface_status,
                                 request_id,
                                 related_batch_source_name,
                                 related_trx_number,
                                 related_customer_trx_id,
                                 previous_customer_trx_id,
                                 credit_method_for_acct_rule,
                                 credit_method_for_installments,
                                 reason_code,
                                 tax_rate,
                                 tax_code,
                                 tax_precedence,
                                 exception_id,
                                 exemption_id,
                                 ship_date_actual,
                                 fob_point,
                                 ship_via,
                                 waybill_number,
                                 invoicing_rule_name,
                                 invoicing_rule_id,
                                 accounting_rule_name,
                                 accounting_rule_id,
                                 accounting_rule_duration,
                                 rule_start_date,
                                 primary_salesrep_number,
                                 primary_salesrep_id,
                                 sales_order,
                                 sales_order_line,
                                 sales_order_date,
                                 sales_order_source,
                                 sales_order_revision,
                                 purchase_order,
                                 purchase_order_revision,
                                 purchase_order_date,
                                 agreement_name,
                                 agreement_id,
                                 memo_line_name,
                                 memo_line_id,
                                 inventory_item_id,
                                 mtl_system_items_seg1,
                                 mtl_system_items_seg2,
                                 mtl_system_items_seg3,
                                 mtl_system_items_seg4,
                                 mtl_system_items_seg5,
                                 mtl_system_items_seg6,
                                 mtl_system_items_seg7,
                                 mtl_system_items_seg8,
                                 mtl_system_items_seg9,
                                 mtl_system_items_seg10,
                                 mtl_system_items_seg11,
                                 mtl_system_items_seg12,
                                 mtl_system_items_seg13,
                                 mtl_system_items_seg14,
                                 mtl_system_items_seg15,
                                 mtl_system_items_seg16,
                                 mtl_system_items_seg17,
                                 mtl_system_items_seg18,
                                 mtl_system_items_seg19,
                                 mtl_system_items_seg20,
                                 reference_line_id,
                                 reference_line_context,
                                 reference_line_attribute1,
                                 reference_line_attribute2,
                                 reference_line_attribute3,
                                 reference_line_attribute4,
                                 reference_line_attribute5,
                                 reference_line_attribute6,
                                 reference_line_attribute7,
                                 territory_id,
                                 territory_segment1,
                                 territory_segment2,
                                 territory_segment3,
                                 territory_segment4,
                                 territory_segment5,
                                 territory_segment6,
                                 territory_segment7,
                                 territory_segment8,
                                 territory_segment9,
                                 territory_segment10,
                                 territory_segment11,
                                 territory_segment12,
                                 territory_segment13,
                                 territory_segment14,
                                 territory_segment15,
                                 territory_segment16,
                                 territory_segment17,
                                 territory_segment18,
                                 territory_segment19,
                                 territory_segment20,
                                 attribute_category,
                                 attribute1,
                                 attribute2,
                                 attribute3,
                                 attribute4,
                                 attribute5,
                                 attribute6,
                                 attribute7,
                                 attribute8,
                                 attribute9,
                                 attribute10,
                                 attribute11,
                                 attribute12,
                                 attribute13,
                                 attribute14,
                                 attribute15,
                                 header_attribute_category,
                                 header_attribute1,
                                 header_attribute2,
                                 header_attribute3,
                                 header_attribute4,
                                 header_attribute5,
                                 header_attribute6,
                                 header_attribute7,
                                 header_attribute8,
                                 header_attribute9,
                                 header_attribute10,
                                 header_attribute11,
                                 header_attribute12,
                                 header_attribute13,
                                 header_attribute14,
                                 header_attribute15,
                                 comments,
                                 internal_notes,
                                 initial_customer_trx_id,
                                 ussgl_transaction_code_context,
                                 ussgl_transaction_code,
                                 acctd_amount,
                                 customer_bank_account_id,
                                 customer_bank_account_name,
                                 uom_code,
                                 uom_name,
                                 document_number_sequence_id,
                                 link_to_line_attribute10,
                                 link_to_line_attribute11,
                                 link_to_line_attribute12,
                                 link_to_line_attribute13,
                                 link_to_line_attribute14,
                                 link_to_line_attribute15,
                                 link_to_line_attribute8,
                                 link_to_line_attribute9,
                                 reference_line_attribute10,
                                 reference_line_attribute11,
                                 reference_line_attribute12,
                                 reference_line_attribute13,
                                 reference_line_attribute14,
                                 reference_line_attribute15,
                                 reference_line_attribute8,
                                 reference_line_attribute9,
                                 interface_line_attribute10,
                                 interface_line_attribute11,
                                 interface_line_attribute12,
                                 interface_line_attribute13,
                                 interface_line_attribute14,
                                 interface_line_attribute15,
                                 interface_line_attribute9,
                                 vat_tax_id,
                                 reason_code_meaning,
                                 last_period_to_credit,
                                 paying_customer_id,
                                 paying_site_use_id,
                                 tax_exempt_flag,
                                 tax_exempt_reason_code,
                                 tax_exempt_reason_code_meaning,
                                 tax_exempt_number,
                                 sales_tax_id,
                                 created_by,
                                 creation_date,
                                 last_updated_by,
                                 last_update_date,
                                 last_update_login,
                                 location_segment_id,
                                 movement_id,
                                 org_id,
                                 amount_includes_tax_flag,
                                 header_gdf_attr_category,
                                 header_gdf_attribute1,
                                 header_gdf_attribute2,
                                 header_gdf_attribute3,
                                 header_gdf_attribute4,
                                 header_gdf_attribute5,
                                 header_gdf_attribute6,
                                 header_gdf_attribute7,
                                 header_gdf_attribute8,
                                 header_gdf_attribute9,
                                 header_gdf_attribute10,
                                 header_gdf_attribute11,
                                 header_gdf_attribute12,
                                 header_gdf_attribute13,
                                 header_gdf_attribute14,
                                 header_gdf_attribute15,
                                 header_gdf_attribute16,
                                 header_gdf_attribute17,
                                 header_gdf_attribute18,
                                 header_gdf_attribute19,
                                 header_gdf_attribute20,
                                 header_gdf_attribute21,
                                 header_gdf_attribute22,
                                 header_gdf_attribute23,
                                 header_gdf_attribute24,
                                 header_gdf_attribute25,
                                 header_gdf_attribute26,
                                 header_gdf_attribute27,
                                 header_gdf_attribute28,
                                 header_gdf_attribute29,
                                 header_gdf_attribute30,
                                 line_gdf_attr_category,
                                 line_gdf_attribute1,
                                 line_gdf_attribute2,
                                 line_gdf_attribute3,
                                 line_gdf_attribute4,
                                 line_gdf_attribute5,
                                 line_gdf_attribute6,
                                 line_gdf_attribute7,
                                 line_gdf_attribute8,
                                 line_gdf_attribute9,
                                 line_gdf_attribute10,
                                 line_gdf_attribute11,
                                 line_gdf_attribute12,
                                 line_gdf_attribute13,
                                 line_gdf_attribute14,
                                 line_gdf_attribute15,
                                 line_gdf_attribute16,
                                 line_gdf_attribute17,
                                 line_gdf_attribute18,
                                 line_gdf_attribute19,
                                 line_gdf_attribute20,
                                 reset_trx_date_flag,
                                 payment_server_order_num,
                                 approval_code,
                                 address_verification_code,
                                 warehouse_id,
                                 translated_description,
                                 cons_billing_number,
          			               promised_commitment_amount,
                                 payment_set_id,
                                 original_gl_date,
                                 contract_line_id,
                                 contract_id,
                                 source_data_key1,
                                 source_data_key2,
                                 source_data_key3,
                                 source_data_key4,
                    				   source_data_key5,
                               	invoiced_line_acctg_level,
                                 override_auto_accounting_flag,
                                 decode(line_type,gc_line_type_LINE_hc,'N')
  				   FROM xx_ra_int_lines_all XRILA
--             WHERE XRILA.orig_system_bill_customer_id = OBJECTTABLE$(X)
               WHERE XRILA.orig_system_bill_customer_id BETWEEN gn_cust_id_low
                                                            AND gn_cust_id_high
               AND XRILA.interface_line_attribute3    = G_SUMMARY
               AND XRILA.interface_line_context       = G_POS_ORDER_ENTRY
               AND XRILA.interface_status             IS NULL
               AND XRILA.org_id                       = gn_org_id
               AND XRILA.batch_source_name            = gc_batch_source_name;


            ln_inserted_ra_int_line_cnt := SQL%ROWCOUNT;

            -------------------------------
            --Added for R12 Retrofit Starts
            -------------------------------
            --Open the distinct trx cursor

            OPEN lcu_get_dist_trx_num;
            LOOP
                FETCH lcu_get_dist_trx_num
                BULK COLLECT INTO rec_dist_trx LIMIT gn_bulk_limit;

            EXIT WHEN rec_dist_trx.count = 0;



            FOR ln_dist_trx IN 1..rec_dist_trx.COUNT
            LOOP

               ln_interface_PREV := NULL;
               ln_interface_CURR := NULL;


               WRITE_LOG(gc_debug_flg,' ' ,null,null );


               --Based on the above cursor trx number derive the other interface attributes

               FOR ln_disc_cnt IN lcu_upd_tax_cols(rec_dist_trx(ln_dist_trx).trx_number)
               LOOP

                  --Set the current value as interface line attribute2

                  ln_interface_CURR := ln_disc_cnt.interface_line_attribute2;

                  fnd_file.put_line(FND_FILE.LOG,'ln_interface_id_PREV ' || ln_interface_PREV);
                  fnd_file.put_line(FND_FILE.LOG,'ln_interface_id_CURR ' || ln_interface_CURR);

                  --If Check if interface line Attribute9 is TAX for US
                  IF ln_disc_cnt.interface_line_attribute9 = gc_line_type_TAX_hc
                  THEN

                        --Check if prev value is null, if yes this means it is the first line for that trx number
                        IF      ln_interface_PREV IS NULL
                        THEN

                           UPDATE ra_interface_lines_all
                              SET tax_regime_code  = gc_tax_regime_code_us,                        --Added for R12 Retrofit Changes
                                  tax              = gc_tax_line1,                                 --Added for R12 Retrofit Changes
                                  tax_status_code  = gc_tax_status_code_us,                        --Added for R12 Retrofit Changes
                                  tax_rate_code    = gc_tax_rate_code,                             --Added for R12 Retrofit Changes
                                  tax_rate         = gc_rate_percent
                           WHERE orig_system_bill_customer_id = ln_disc_cnt.orig_system_bill_customer_id
                           AND   interface_line_attribute3    = G_SUMMARY
                           AND   interface_line_context       = G_POS_ORDER_ENTRY
                           AND   org_id                       = gn_org_id
                           AND   batch_source_name            = gc_batch_source_name
                           AND   line_type                    = gc_line_type_TAX_hc
                           AND   interface_line_attribute2    = ln_disc_cnt.interface_line_attribute2
                           AND   trx_number                   = ln_disc_cnt.trx_number;

                       --Check if prev value is not equal to cur value. If yes then it means it is second line for that trx number
                        ELSIF ln_interface_PREV != ln_interface_CURR
                        THEN

                            UPDATE ra_interface_lines_all
                            SET tax_regime_code  = gc_tax_regime_code_us1,                          --Added for R12 Retrofit Changes
                                tax              = gc_tax_line2,                                    --Added for R12 Retrofit Changes
                                tax_status_code  = gc_tax_status_code_us1,                          --Added for R12 Retrofit Changes
                                tax_rate_code    = gc_tax_rate_code1,                               --Added for R12 Retrofit Changes
                                tax_rate         = gc_rate_percent1
                           WHERE orig_system_bill_customer_id = ln_disc_cnt.orig_system_bill_customer_id
                           AND   interface_line_attribute3    = G_SUMMARY
                           AND   interface_line_context       = G_POS_ORDER_ENTRY
                           AND   org_id                       = gn_org_id
                           AND   batch_source_name            = gc_batch_source_name
                           AND   line_type                    = gc_line_type_TAX_hc
                           AND   interface_line_attribute2    = ln_disc_cnt.interface_line_attribute2
                           AND   trx_number                   = ln_disc_cnt.trx_number;
                        END IF;

                    --If Check if interface line Attribute9 is GST for Canada State
                   ELSIF ln_disc_cnt.interface_line_attribute9 = gc_tax_type_GST_hc
                   THEN

                        UPDATE ra_interface_lines_all
                        SET tax_regime_code   = gc_tax_regime_code_ca,
                            tax               = gc_tax_state,
                            tax_status_code   = gc_tax_status_code_ca,
                            tax_rate_code     = gc_tax_rate_state,
                            tax_rate          = gc_rate_percent_state
                        WHERE orig_system_bill_customer_id = ln_disc_cnt.orig_system_bill_customer_id
                        AND   interface_line_attribute3    = G_SUMMARY
                        AND   interface_line_context       = G_POS_ORDER_ENTRY
                        AND   org_id                       = gn_org_id
                        AND   batch_source_name            = gc_batch_source_name
                        AND   line_type                    = gc_line_type_TAX_hc
                        AND   interface_line_attribute9    = gc_tax_type_GST_hc
                        AND   interface_line_attribute2    = ln_disc_cnt.interface_line_attribute2
                        AND   trx_number                   = ln_disc_cnt.trx_number;


                --If Check if interface line Attribute9 is PST for Canada State
                   ELSIF ln_disc_cnt.interface_line_attribute9 = gc_tax_type_PST_hc
                   THEN

                        UPDATE ra_interface_lines_all
                        SET tax_regime_code   = gc_tax_regime_code_ca,
                            tax               = gc_tax_county,
                            tax_status_code   = gc_tax_status_code_ca1,
                            tax_rate_code     = gc_tax_rate_county,
                            tax_rate          = gc_rate_percent_county
                        WHERE orig_system_bill_customer_id = ln_disc_cnt.orig_system_bill_customer_id
                        AND   interface_line_attribute3    = G_SUMMARY
                        AND   interface_line_context       = G_POS_ORDER_ENTRY
                        AND   org_id                       = gn_org_id
                        AND   batch_source_name            = gc_batch_source_name
                        AND   line_type                    = gc_line_type_TAX_hc
                        AND   interface_line_attribute9    = gc_tax_type_PST_hc
                        AND   interface_line_attribute2    = ln_disc_cnt.interface_line_attribute2
                        AND   trx_number                   = ln_disc_cnt.trx_number;
                        --AND   interface_line_ID            = ln_disc_cnt.interface_line_ID;
                  END IF;

                ln_interface_PREV := ln_disc_cnt.interface_line_attribute2;

                fnd_file.put_line(FND_FILE.LOG,'updated lines ' || SQL%ROWCOUNT);
                fnd_file.put_line(FND_FILE.LOG,'ln_interface_PREV ' || ln_interface_PREV);
                fnd_file.put_line(FND_FILE.LOG,'ln_interface_CURR ' || ln_interface_CURR);
            END LOOP;

         END LOOP;
         END LOOP;
         -------------------------------
         --Added for R12 Retrofit Ends
         -------------------------------
         END;

         -----------------------------------------------
         --Inserting into ra_interface_distributions_all
         -----------------------------------------------
         BEGIN
--            FORALL x IN ObjectTable$.FIRST..ObjectTable$.LAST
               INSERT INTO ra_interface_distributions_all
                           (SELECT -- Added column names for defect#32991, as additional global attribute columns added in the table RA_INTERFACE_DISTRIBUTIONS_ALL by the patch#19891654 				
							INTERFACE_DISTRIBUTION_ID,
							INTERFACE_LINE_ID,
							INTERFACE_LINE_CONTEXT,
							INTERFACE_LINE_ATTRIBUTE1,
							INTERFACE_LINE_ATTRIBUTE2,
							INTERFACE_LINE_ATTRIBUTE3,
							INTERFACE_LINE_ATTRIBUTE4,
							INTERFACE_LINE_ATTRIBUTE5,
							INTERFACE_LINE_ATTRIBUTE6,
							INTERFACE_LINE_ATTRIBUTE7,
							INTERFACE_LINE_ATTRIBUTE8,
							ACCOUNT_CLASS,
							AMOUNT,
							PERCENT,
							INTERFACE_STATUS,
							REQUEST_ID,
							CODE_COMBINATION_ID,
							SEGMENT1,
							SEGMENT2,
							SEGMENT3,
							SEGMENT4,
							SEGMENT5,
							SEGMENT6,
							SEGMENT7,
							SEGMENT8,
							SEGMENT9,
							SEGMENT10,
							SEGMENT11,
							SEGMENT12,
							SEGMENT13,
							SEGMENT14,
							SEGMENT15,
							SEGMENT16,
							SEGMENT17,
							SEGMENT18,
							SEGMENT19,
							SEGMENT20,
							SEGMENT21,
							SEGMENT22,
							SEGMENT23,
							SEGMENT24,
							SEGMENT25,
							SEGMENT26,
							SEGMENT27,
							SEGMENT28,
							SEGMENT29,
							SEGMENT30,
							COMMENTS,
							ATTRIBUTE_CATEGORY,
							ATTRIBUTE1,
							ATTRIBUTE2,
							ATTRIBUTE3,
							ATTRIBUTE4,
							ATTRIBUTE5,
							ATTRIBUTE6,
							ATTRIBUTE7,
							ATTRIBUTE8,
							ATTRIBUTE9,
							ATTRIBUTE10,
							ATTRIBUTE11,
							ATTRIBUTE12,
							ATTRIBUTE13,
							ATTRIBUTE14,
							ATTRIBUTE15,
							ACCTD_AMOUNT,
							INTERFACE_LINE_ATTRIBUTE10,
							INTERFACE_LINE_ATTRIBUTE11,
							INTERFACE_LINE_ATTRIBUTE12,
							INTERFACE_LINE_ATTRIBUTE13,
							INTERFACE_LINE_ATTRIBUTE14,
							INTERFACE_LINE_ATTRIBUTE15,
							INTERFACE_LINE_ATTRIBUTE9,
							CREATED_BY,
							CREATION_DATE,
							LAST_UPDATED_BY,
							LAST_UPDATE_DATE,
							LAST_UPDATE_LOGIN,
							ORG_ID,
							INTERIM_TAX_CCID,
							INTERIM_TAX_SEGMENT1,
							INTERIM_TAX_SEGMENT2,
							INTERIM_TAX_SEGMENT3,
							INTERIM_TAX_SEGMENT4,
							INTERIM_TAX_SEGMENT5,
							INTERIM_TAX_SEGMENT6,
							INTERIM_TAX_SEGMENT7,
							INTERIM_TAX_SEGMENT8,
							INTERIM_TAX_SEGMENT9,
							INTERIM_TAX_SEGMENT10,
							INTERIM_TAX_SEGMENT11,
							INTERIM_TAX_SEGMENT12,
							INTERIM_TAX_SEGMENT13,
							INTERIM_TAX_SEGMENT14,
							INTERIM_TAX_SEGMENT15,
							INTERIM_TAX_SEGMENT16,
							INTERIM_TAX_SEGMENT17,
							INTERIM_TAX_SEGMENT18,
							INTERIM_TAX_SEGMENT19,
							INTERIM_TAX_SEGMENT20,
							INTERIM_TAX_SEGMENT21,
							INTERIM_TAX_SEGMENT22,
							INTERIM_TAX_SEGMENT23,
							INTERIM_TAX_SEGMENT24,
							INTERIM_TAX_SEGMENT25,
							INTERIM_TAX_SEGMENT26,
							INTERIM_TAX_SEGMENT27,
							INTERIM_TAX_SEGMENT28,
							INTERIM_TAX_SEGMENT29,
							INTERIM_TAX_SEGMENT30,
							null,null,null,null,
							null,null,null,null,
							null,null,null,null,
							null,null,null,null,
							null,null,null,null,
							null,null,null,null,
							null,null,null,null,
							null,null,null
                              FROM xx_ra_int_distributions_all XRIDA
                             WHERE XRIDA.org_id = gn_org_id
                               AND XRIDA.interface_line_attribute3 = G_SUMMARY
                               AND EXISTS (SELECT 1
                                             FROM xx_ra_int_lines_all XRILA
--                                            WHERE XRILA.orig_system_bill_customer_id = OBJECTTABLE$(X)
                                            WHERE XRILA.orig_system_bill_customer_id BETWEEN gn_cust_id_low
                                                                                         AND gn_cust_id_high
                                              AND XRILA.interface_line_attribute3    = G_SUMMARY
                                              AND XRILA.interface_line_context       = G_POS_ORDER_ENTRY
                                              AND XRILA.interface_status             IS NULL
                                              AND XRILA.org_id                       = gn_org_id
                                              AND XRILA.batch_source_name            = gc_batch_source_name
                                              AND XRILA.interface_line_attribute1    = XRIDA.interface_line_attribute1
                                              AND XRILA.interface_line_attribute3    = XRIDA.interface_line_attribute3
                                              AND XRILA.interface_line_context       = XRIDA.interface_line_context));

            ln_inserted_ra_int_dist_cnt := SQL%ROWCOUNT;
         END;



	 --Start - Commented for Defect31661
	 ----------------------------------------------
         --Inserting into ra_interface_salescredits_all
         ----------------------------------------------
         /*
	 BEGIN
--            FORALL x IN ObjectTable$.FIRST..ObjectTable$.LAST
               INSERT INTO ra_interface_salescredits_all
                           (SELECT *
                              FROM xx_ra_int_salescredits_all XRISA
                             WHERE XRISA.org_id = gn_org_id
                               AND XRISA.interface_line_attribute3 = G_SUMMARY
                               AND EXISTS (SELECT 1
                                             FROM xx_ra_int_lines_all XRILA
--                                            WHERE XRILA.orig_system_bill_customer_id = OBJECTTABLE$(X)
                                            WHERE XRILA.orig_system_bill_customer_id BETWEEN gn_cust_id_low
                                                                                         AND gn_cust_id_high
                                              AND XRILA.interface_line_attribute3    = G_SUMMARY
                                              AND XRILA.interface_line_context       = G_POS_ORDER_ENTRY
                                              AND XRILA.interface_status             IS NULL
                                              AND XRILA.org_id                       = gn_org_id
                                              AND XRILA.batch_source_name            = gc_batch_source_name
                                              AND XRILA.interface_line_attribute1    = XRISA.interface_line_attribute1
                                              AND XRILA.interface_line_attribute3    = XRISA.interface_line_attribute3
                                              AND XRILA.interface_line_context       = XRISA.interface_line_context));

            ln_inserted_ra_int_sales_cnt := SQL%ROWCOUNT;
         END;
	 */
	  --End - Commented for Defect31661

      END IF;

      COMMIT;

      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
      WRITE_LOG('Y',gc_proc_name ,'      Summary Records Inserted into RA_INTERFACE_LINES_ALL        ', ln_inserted_ra_int_line_cnt);
      WRITE_LOG('Y',gc_proc_name ,'      Summary Records Inserted into RA_INTERFACE_DISTRIBUTIONS_ALL', ln_inserted_ra_int_dist_cnt);
  --  WRITE_LOG('Y',gc_proc_name ,'      Summary Records Inserted into RA_INTERFACE_SALESCREDITS_ALL ', ln_inserted_ra_int_sales_cnt);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

      EXCEPTION
         WHEN SUMMARY_CHECK_ERR  THEN

            gc_debug_loc  :='SUMMARY_CHECK_ERR';
            gc_debug_stmt := 'Error occured summarizing invoices '
                            ||'to detail invoices.'
                            ||' Details do not balance to summary trxs.'
                            ||' Should be investigated '
                            ||'and resolved before executing again. ';

            WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

            ----------------------
            -- Sending error email
            ----------------------
            SEND_EMAIL (  gc_concat_email, gc_debug_loc ,gc_debug_stmt );
            p_return_code := 2;

         WHEN OTHERS THEN
            gc_debug_stmt :=  SUBSTR(SQLERRM,1,249);
            WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

            ROLLBACK;
            p_return_code := 2;

   END INST_RA_INTR_TBLS;

   -- +=====================================================================+
   -- | Name :CHECK_MULTI_SUM_INV                                           |
   -- | Description :Procedure to check if detailed invoices have been      |
   -- |              summarized into multiple summary trx numbers           |
   -- | Parameters:  gn_org_id                                              |
   -- | Returns   :  p_return_code                                          |
   -- +=====================================================================+
   PROCEDURE CHECK_MULTI_SUM_INV (p_return_code  OUT   NUMBER)
   AS
      CURSOR lcu_multi_summary_trx
      IS
         SELECT COUNT(DISTINCT XRILA.related_trx_number)
               ,XRILA.interface_line_attribute1
           FROM xx_ra_int_lines_all     XRILA
          WHERE XRILA.interface_line_context    = G_ORDER_ENTRY
            AND XRILA.org_id                    = gn_org_id
            AND (XRILA.interface_status IS NULL OR XRILA.interface_status = 'E')
            AND XRILA.orig_system_bill_customer_id BETWEEN gn_cust_id_low
                                                       AND gn_cust_id_high
         HAVING COUNT(DISTINCT XRILA.related_trx_number) > 1
         GROUP BY XRILA.interface_line_attribute1;

      ln_multi_summary_trx_cnt  NUMBER := 0;

   BEGIN
      gc_proc_name  := '    CHECK_MULTI_SUM_INV';
      gc_debug_loc  := 'Executing CHK_MULTI_SUM_INV:';
      gc_debug_stmt := 'Checking if detailed inv summarized into multiple summary inv ';

      WRITE_LOG(gc_debug_flg, gc_proc_name ,gc_debug_loc, gc_debug_stmt );

      FOR lcr_multiple_inv IN lcu_multi_summary_trx
      LOOP
         IF lcr_multiple_inv.interface_line_attribute1 IS NOT NULL THEN
            ln_multi_summary_trx_cnt := ln_multi_summary_trx_cnt + 1;
            WRITE_LOG('Y',gc_proc_name ,'    Detailed Invoice: ', lcr_multiple_inv.interface_line_attribute1);
         END IF;

      END LOOP;

      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
      WRITE_LOG('Y',gc_proc_name ,'    Detailed Invoices Summarized Into Multiple Summary Invoices ', ln_multi_summary_trx_cnt);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

      IF ln_multi_summary_trx_cnt <> 0 THEN
         ROLLBACK;
         p_return_code := 2;
      ELSE
         p_return_code := 0;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         gc_debug_stmt :=  SUBSTR(SQLERRM,1,249);
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

         ROLLBACK;
         p_return_code := 2;

   END CHECK_MULTI_SUM_INV;

   -- +=====================================================================+
   -- | Name : RESTART_CLEANUP                                              |
   -- | Description : Procedure to delete records from xx and interface     |
   -- |                during clean up process                              |
   -- | Parameters    p_trx_number                                          |
   -- | Returns :                                                           |
   -- +=====================================================================+
   PROCEDURE  RESTART_CLEANUP (p_trx_number IN VARCHAR2 )
   AS
   BEGIN
      gc_proc_name := '    RESTART_CLEANUP';
      WRITE_LOG(gc_debug_flg,' ' ,null,null );
      WRITE_LOG(gc_debug_flg,'  Current System Time: ',
                             to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );

      gc_debug_loc  := '    Deleting summary invoices from: ';


       --Start - Commented for Defect31661
      /*
      gc_debug_stmt := 'XX_RA_INT_SALESCREDITS_ALL:trx_num=>'||p_trx_number;
      WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

      DELETE FROM xx_ra_int_salescredits_all XRISA
            WHERE XRISA.interface_line_attribute1 = p_trx_number
              AND XRISA.interface_line_context    = G_POS_ORDER_ENTRY
              AND XRISA.interface_line_attribute3 = G_SUMMARY
              AND XRISA.org_id                    = gn_org_id;
      */
       --End - Commented for Defect31661


      gc_debug_loc  :='   Deleting summary invoices from: ';
      gc_debug_stmt :='XX_RA_INT_DISTRIBUTIONS_ALL:trx_num=>'||p_trx_number;
      WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

      DELETE FROM xx_ra_int_distributions_all XRIDA
            WHERE XRIDA.interface_line_attribute1 = p_trx_number
              AND XRIDA.interface_line_context    = G_POS_ORDER_ENTRY
              AND XRIDA.interface_line_attribute3 = G_SUMMARY
              AND XRIDA.org_id                    = gn_org_id;

      gc_debug_loc  :='   Deleting summary invoices from: ';
      gc_debug_stmt :='XX_RA_INT_LINES_ALL:trx_num=>'||p_trx_number;
      WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

      DELETE FROM xx_ra_int_lines_all XRILA
            WHERE XRILA.interface_line_attribute1 = p_trx_number
              AND XRILA.interface_line_context    = G_POS_ORDER_ENTRY
              AND XRILA.interface_line_attribute3 = G_SUMMARY
              AND XRILA.org_id                    = gn_org_id;


      --Start - Commented for Defect31661
      /*
      gc_debug_loc  :='   Deleting summary invoices from: ';
      gc_debug_stmt :='RA_INTERFACE_SALECREDITS_ALL-trx_num=>'||p_trx_number;
      WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

      DELETE FROM ra_interface_salescredits_all RISA
            WHERE RISA.interface_line_attribute1 = p_trx_number
              AND RISA.interface_line_context    = G_POS_ORDER_ENTRY
              AND RISA.interface_line_attribute3 = G_SUMMARY
              AND RISA.org_id                    = gn_org_id;
      */

     --End - Commented for Defect31661

      gc_debug_loc  :='   Deleting summary invoices from: ';
      gc_debug_stmt :='RA_INTERFACE_DISTRIBUTIONS_ALL:trx_num=>'||p_trx_number;
      WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

      DELETE FROM ra_interface_distributions_all  RIDA
            WHERE RIDA.interface_line_attribute1 = p_trx_number
              AND RIDA.interface_line_context    = G_POS_ORDER_ENTRY
              AND RIDA.interface_line_attribute3 = G_SUMMARY
              AND RIDA.org_id                    = gn_org_id;

      gc_debug_loc  :='   Deleting summary invoices from: ';
      gc_debug_stmt :='RA_INTERFACE_LINES_ALL:trx_num=>'||p_trx_number;
      WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

      DELETE FROM ra_interface_lines_all  RILA
            WHERE RILA.interface_line_attribute1 = p_trx_number
              AND RILA.interface_line_context    = G_POS_ORDER_ENTRY
              AND RILA.interface_line_attribute3 = G_SUMMARY
              AND RILA.org_id                    = gn_org_id;

      gc_debug_loc  := '    Updating XX_RA_INT_LINES_ALL table: ';
      gc_debug_stmt := 'Remove summary invoice # from detailed invoices';
      WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

      UPDATE xx_ra_int_lines_all  XRILA
         SET XRILA.related_trx_number     = NULL
       WHERE XRILA.related_trx_number     = p_trx_number
         AND XRILA.interface_line_context = G_ORDER_ENTRY
         AND XRILA.org_id                 = gn_org_id;

      COMMIT;

      WRITE_LOG(gc_debug_flg,' ' ,null,null );
      WRITE_LOG(gc_debug_flg,'  Current System Time: ',
                           to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );
   EXCEPTION

      WHEN OTHERS THEN
         gc_debug_loc := ' Others Error: ';
         gc_debug_stmt :=  SUBSTR(SQLERRM,1,249);
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
         ROLLBACK;

   END RESTART_CLEANUP;

   -- +=====================================================================+
   -- | Name : DELETE_SUM_DETAIL_RECS                                       |
   -- | Description : Procedure to delete all summary and detail transaction|
   -- |               Successfully imported                                 |
   -- | Parameters  gc_batch_source_name ,gn_org_id ,p_cleanup_flg          |
   -- | Returns : p_ret_code                                                |
   -- +=====================================================================+
   PROCEDURE DELETE_SUM_DETAIL_RECS (p_return_code        OUT  NUMBER
                                    ,p_trx_number          IN VARCHAR2)
   AS
      ln_line_del_sum_cnt     NUMBER :=0;
      ln_dist_del_sum_cnt     NUMBER :=0;
      ln_sale_del_sum_cnt     NUMBER :=0;

      ln_line_del_dtl_cnt     NUMBER :=0;
      ln_dist_del_dtl_cnt     NUMBER :=0;
      ln_sale_del_dtl_cnt     NUMBER :=0;

   BEGIN
      gc_proc_name  := '    DELETE_SUM_DETAIL_RECS ';
      p_return_code :=0;

      --Start - Commented for Defect31661
      ---------------------------------------------
      -- Delete Sales Credits for Summary Invoices
      ---------------------------------------------
      /*
      DELETE xx_ra_int_salescredits_all XRISA
       WHERE EXISTS (SELECT 1
                       FROM xx_ra_int_lines_all XRI
                      WHERE XRI.interface_line_attribute1  = p_trx_number
                        AND (XRI.interface_line_attribute1 = XRISA.interface_line_attribute1)
                        AND XRI.interface_line_context     = G_POS_ORDER_ENTRY
                        AND XRI.interface_line_attribute3  = G_SUMMARY
                        AND XRI.org_id = gn_org_id)
         AND XRISA.org_id = gn_org_id;

      ln_sale_del_sum_cnt := SQL%ROWCOUNT;
      gn_xx_int_sales_del_sum_cnt := gn_xx_int_sales_del_sum_cnt + ln_sale_del_sum_cnt;

      gc_debug_loc  := '    Rows deleted  from: ';
      gc_debug_stmt := 'XX_RA_INT_SALESCREDITS_ALL: = '||ln_sale_del_sum_cnt;
      WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );
      */
      --End - Commented for Defect31661

      ---------------------------------------------
      -- Delete Distributions for Summary Invoices
      ---------------------------------------------
      DELETE /*+ leading(xri) */ xx_ra_int_distributions_all XRIDA
       WHERE EXISTS (SELECT 1
                       FROM xx_ra_int_lines_all XRI
                      WHERE XRI.interface_line_attribute1  = p_trx_number
                        AND (XRI.interface_line_attribute1 = XRIDA.interface_line_attribute1)
                        AND XRI.interface_line_context     = G_POS_ORDER_ENTRY
                        AND XRI.org_id                     = gn_org_id)
         AND XRIDA.org_id = gn_org_id;

      ln_dist_del_sum_cnt := SQL%ROWCOUNT;
      gn_xx_int_dist_del_sum_cnt := gn_xx_int_dist_del_sum_cnt + ln_dist_del_sum_cnt;

      gc_debug_loc  := '    Rows deleted  from: ';
      gc_debug_stmt := 'XX_RA_INT_DISTRIBUTIONS_ALL: = '||ln_dist_del_sum_cnt;
      WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

      ---------------------------------------------
      -- Delete Distributions for Detailed Invoices
      ---------------------------------------------
      DELETE /*+ leading(xri) */ xx_ra_int_distributions_all XRIDA
       WHERE EXISTS (SELECT 1
                       FROM xx_ra_int_lines_all XRI
                      WHERE XRI.related_trx_number         = p_trx_number
                        AND (XRI.interface_line_attribute1 = XRIDA.interface_line_attribute1)
                        AND XRI.interface_line_context     = G_ORDER_ENTRY
                        AND XRI.org_id                     = gn_org_id)
         AND XRIDA.org_id = gn_org_id;

      ln_dist_del_dtl_cnt := SQL%ROWCOUNT;
      gn_xx_int_dist_del_dtl_cnt := gn_xx_int_dist_del_dtl_cnt + ln_dist_del_dtl_cnt;

      gc_debug_loc  := '    Rows deleted  from: ';
      gc_debug_stmt := 'XX_RA_INT_DISTRIBUTIONS_ALL: = '||ln_dist_del_dtl_cnt;
      WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

      ---------------------------------------------
      -- Delete Lines for Summary Invoices
      ---------------------------------------------
      DELETE xx_ra_int_lines_all XRILA
       WHERE XRILA.interface_line_attribute1 = p_trx_number
         AND XRILA.interface_line_context    = G_POS_ORDER_ENTRY
         AND XRILA.interface_line_attribute3 = G_SUMMARY
         AND XRILA.org_id                    = gn_org_id;

      ln_line_del_sum_cnt := SQL%ROWCOUNT;
      gn_xx_int_lines_del_sum_cnt := gn_xx_int_lines_del_sum_cnt + ln_line_del_sum_cnt;

      gc_debug_loc  := '    Rows deleted  from: ';
      gc_debug_stmt := 'XX_RA_INT_LINES_ALL: = '||ln_line_del_sum_cnt;
      WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

      ---------------------------------------------
      -- Delete Lines for Detailed Invoices
      ---------------------------------------------
      DELETE xx_ra_int_lines_all XRILA
       WHERE XRILA.related_trx_number     = p_trx_number
         AND XRILA.interface_line_context = G_ORDER_ENTRY
         AND XRILA.org_id                 = gn_org_id;

      ln_line_del_dtl_cnt := SQL%ROWCOUNT;
      gn_xx_int_lines_del_dtl_cnt := gn_xx_int_lines_del_dtl_cnt + ln_line_del_dtl_cnt;

      gc_debug_loc  := '    Rows deleted  from: ';
      gc_debug_stmt := 'XX_RA_INT_LINES_ALL: = '||ln_line_del_dtl_cnt;
      WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

   EXCEPTION
      WHEN OTHERS THEN
         gc_debug_stmt :=  SUBSTR(SQLERRM,1,249);
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
         p_return_code := 2;

   END DELETE_SUM_DETAIL_RECS;

   -- +=====================================================================+
   -- | Name : OUTPUT_PRE_IMPORT_STATUS                                     |
   -- | Description : Writes output for pre-summarization                   |
   -- | Parameters                                                          |
   -- | Returns :                                                           |
   -- +=====================================================================+
   PROCEDURE OUTPUT_PRE_IMPORT_STATUS
   AS

      -- Cursor to select pre-sum totals
      CURSOR lcu_select_pre_sum_totals
      IS
         SELECT XRILA.trx_date
               ,XRILA.batch_source_name
               ,XRILA.interface_line_attribute2
               ,NVL(SUM(XRILA.amount),0)          AMOUNT
               ,COUNT(1)                          TRANS_CNT
           FROM xx_ra_int_lines_all    XRILA
          WHERE XRILA.batch_source_name = gc_batch_source_name
            AND XRILA.org_id            = gn_org_id
            AND XRILA.interface_line_attribute3 <> G_SUMMARY
            AND (XRILA.interface_status = 'E' OR XRILA.interface_status IS NULL)
         GROUP BY XRILA.trx_date
                 ,XRILA.batch_source_name
                 ,XRILA.interface_line_attribute2
         ORDER BY XRILA.trx_date;

      lrec_pre_sum_total     lcu_select_pre_sum_totals%ROWTYPE;

   BEGIN
      gc_proc_name := '    OUTPUT_PRE_IMPORT_STATUS';

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Pre-Summarization');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----------------------------');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   '||'Trans Date   '
                                              ||'Batch Source Name                   '
                                              ||'Transaction Type             '
                                              ||'Invoice Lines           '
                                              ||'Invoice Amount          '
                        );

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   '||'----------'
                                              ||'   ---------------------------------'
                                              ||'   ---------------------------'
                                              ||'  ----------------------'
                                              ||'  ----------------------'
                       );

      --------------------------------------------------------------------------
      -- Write-out Pre-Summarization
      --------------------------------------------------------------------------
      gc_debug_loc := 'Retrieving Pre-Summarization Information';
      OPEN lcu_select_pre_sum_totals;
      LOOP
         FETCH lcu_select_pre_sum_totals INTO lrec_pre_sum_total;

          EXIT WHEN lcu_select_pre_sum_totals%NOTFOUND;

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                     '   '||to_char(lrec_pre_sum_total.trx_date, 'mm/dd/yyyy')
                          ||'   '||SUBSTR(RPAD(lrec_pre_sum_total.batch_source_name,35),1,36)
                          ||' '||SUBSTR(RPAD(lrec_pre_sum_total.interface_line_attribute2,35),1,25)
                          ||' '||SUBSTR(RPAD(TO_CHAR(lrec_pre_sum_total.trans_cnt,'9,999,999,999'),35),1,20)
                          ||' '||SUBSTR(RPAD(TO_CHAR(lrec_pre_sum_total.amount,'$9,999,999,999.00'),35),1,30)
                           );
      END LOOP;
      CLOSE lcu_select_pre_sum_totals;

   END OUTPUT_PRE_IMPORT_STATUS;

   -- +=====================================================================+
   -- | Name : OUTPUT_IMPORT_STATUS                                         |
   -- | Description : Procedure Comfirms what was imported successfully and |
   -- |               writes output                                         |
   -- | Parameters                                                          |
   -- | Returns : p_ret_code                                                |
   -- +=====================================================================+
   PROCEDURE OUTPUT_IMPORT_STATUS
   AS
      lc_store_name           hz_cust_accounts.account_name%TYPE;

      -- Invoices not summarized (interface_status = 'E')
      CURSOR lcu_error_invoices
      IS
         SELECT XRILA.trx_date
               ,XRILA.orig_system_bill_customer_id
               ,RCTA.name
               ,COUNT(1)                            LINES
               ,SUM(XRILA.amount)                   AMOUNT
           FROM xx_ra_int_lines_all    XRILA
               ,ra_cust_trx_types_all  RCTA
          WHERE XRILA.batch_source_name       = gc_batch_source_name
            AND XRILA.org_id                  = gn_org_id
            AND XRILA.interface_line_context  = G_ORDER_ENTRY
            AND XRILA.interface_status        = 'E'
            AND XRILA.cust_trx_type_id        = RCTA.cust_trx_type_id
        GROUP BY XRILA.trx_date
                ,XRILA.orig_system_bill_customer_id
                ,RCTA.name;

      lrec_error_invoices     lcu_error_invoices%ROWTYPE;

      -- Invoices Imported into AR
      CURSOR lcu_check_import_status_prt
      IS
         SELECT COUNT(RCTLA.customer_trx_line_id)  LINE_COUNT
               ,SUM(extended_amount)               TOTAL_AMOUNT
               ,RCT.trx_date
               ,RCTA.name
           FROM fnd_concurrent_requests    FCR
               ,fnd_concurrent_programs    FCP
               ,fnd_concurrent_requests    FCR2
               ,fnd_concurrent_programs    FCP2
               ,fnd_concurrent_requests    FCR3
               ,fnd_concurrent_programs    FCP3
               ,ra_customer_trx_lines_all  RCTLA
               ,ra_customer_trx_all        RCT
               ,ra_cust_trx_types_all      RCTA
          WHERE FCR.parent_request_id        = gn_request_id
            AND FCR.program_application_id   = FCP.application_id
            AND FCP.concurrent_program_id    = FCR.concurrent_program_id
            AND FCR.request_id               = FCR2.parent_request_id
            AND FCR2.program_application_id  = FCP2.application_id
            AND FCP2.concurrent_program_id   = FCR2.concurrent_program_id
            AND FCP2.concurrent_program_name = 'RAXMTR'
            AND FCP2.application_id          = 222
            AND FCR2.request_id              = FCR3.parent_request_id
            AND FCR3.program_application_id  = FCP3.application_id
            AND FCP3.concurrent_program_id   = FCR3.concurrent_program_id
            AND FCP3.concurrent_program_name = 'RAXTRX'
            AND FCP3.application_id          = 222
            AND FCR3.request_id              = RCTLA.request_id
            AND RCTLA.customer_trx_id        = RCT.customer_trx_id
            AND RCT.cust_trx_type_id         = RCTA.cust_trx_type_id
          GROUP BY RCTA.name
                  ,RCT.trx_date;

      lrec_imported_invoices   lcu_check_import_status_prt%ROWTYPE;

      -- Invoices Not Imported (in ra_interface_lines_all)
      CURSOR lcu_check_not_imported
      IS
         SELECT COUNT(1)          LINE_COUNT
               ,SUM(RILA.amount)  TOTAL_AMOUNT
               ,RILA.trx_date
               ,RCTA.name
           FROM fnd_concurrent_requests    FCR
               ,fnd_concurrent_programs    FCP
               ,fnd_concurrent_requests    FCR2
               ,fnd_concurrent_programs    FCP2
               ,fnd_concurrent_requests    FCR3
               ,fnd_concurrent_programs    FCP3
               ,ra_interface_lines_all          RILA
               ,ra_cust_trx_types_all           RCTA
          WHERE FCR.parent_request_id        = gn_request_id
            AND FCR.program_application_id   = FCP.application_id
            AND FCP.concurrent_program_id    = FCR.concurrent_program_id
            AND FCR.request_id               = FCR2.parent_request_id
            AND FCR2.program_application_id  = FCP2.application_id
            AND FCP2.concurrent_program_id   = FCR2.concurrent_program_id
            AND FCP2.concurrent_program_name = 'RAXMTR'
            AND FCP2.application_id          = 222
            AND FCR2.request_id              = FCR3.parent_request_id
            AND FCR3.program_application_id  = FCP3.application_id
            AND FCP3.concurrent_program_id   = FCR3.concurrent_program_id
            AND FCP3.concurrent_program_name = 'RAXTRX'
            AND FCP3.application_id          = 222
            AND FCR3.request_id              = RILA.request_id
            AND RILA.cust_trx_type_id        = RCTA.cust_trx_type_id
          GROUP BY RCTA.name
                  ,RILA.trx_date;

      lrec_not_imported_invoices   lcu_check_not_imported%ROWTYPE;

   BEGIN
      gc_proc_name := '    OUTPUT_IMPORT_STATUS ';

      --------------------------------------------------------------------------
      -- Write-out Invoices Not Summarized (interface_status = E)
      --------------------------------------------------------------------------
      BEGIN
         WRITE_OUTPUT ('INV_NOT_SUM');

         gc_debug_loc := 'Retrieving Invoices Not Summarized';
         OPEN lcu_error_invoices;
         LOOP
            FETCH lcu_error_invoices INTO lrec_error_invoices;
            EXIT WHEN lcu_error_invoices%NOTFOUND;

            SELECT NVL(account_name,'N/A')
              INTO lc_store_name
              FROM hz_cust_accounts
             WHERE cust_account_id = lrec_error_invoices.orig_system_bill_customer_id;

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                               '   '||to_char(lrec_error_invoices.trx_date, 'mm/dd/yyyy')
                             ||'   '||SUBSTR(RPAD(lc_store_name,35),1,36)
                             ||' '||SUBSTR(RPAD(lrec_error_invoices.name,35),1,25)
                             ||' '||SUBSTR(RPAD(to_char(lrec_error_invoices.lines,'9,999,999,999'),35),1,20)
                             ||' '||SUBSTR(RPAD(to_char(lrec_error_invoices.amount,'$9,999,999,999.00'),35),1,30)
                            );

         END LOOP;
         CLOSE lcu_error_invoices;

      END;

      --------------------------------------------------------------------------
      -- Write-out Invoices Imported
      --------------------------------------------------------------------------
      BEGIN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Summary Invoices Imported Status');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'--------------------------------');

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   '||'Trans Date   '
                                                 ||'Transaction Type        '
                                                 ||'Import Status           '
                                                 ||'Invoice Lines           '
                                                 ||'Invoice Amount          '
                           );

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   '||'----------'
                                                 ||'   ---------------------'
                                                 ||'   ---------------------'
                                                 ||'   ---------------------'
                                                 ||'   ---------------------'
                           );



         OPEN lcu_check_import_status_prt;
         LOOP
            FETCH lcu_check_import_status_prt INTO lrec_imported_invoices;
            EXIT WHEN lcu_check_import_status_prt%NOTFOUND;

            gc_debug_loc  := 'total amt and record count from XX table';
            gc_debug_stmt := 'ln_xx_ra_cnt =  '||lrec_imported_invoices.line_count
                             ||' ln_xx_tot_amt =  '||lrec_imported_invoices.total_amount;

            WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   '
                     ||to_char(lrec_imported_invoices.trx_date, 'mm/dd/yyyy')
                     ||'   '||SUBSTR(RPAD(lrec_imported_invoices.name,25),1,25)
                     ||' '||SUBSTR(RPAD('Yes',20),1,10)
                     ||'           '||SUBSTR(RPAD(to_char(lrec_imported_invoices.line_count ,'9,999,999,999'),40),1,20)
                     ||'      '||SUBSTR(RPAD(to_char(lrec_imported_invoices.total_amount,'$9,999,999,999.00'),35),1,30) );

         END LOOP;
         CLOSE lcu_check_import_status_prt;
      END;

      --------------------------------------------------------------------------
      -- Write-out Invoices NOT IMPORTED
      --------------------------------------------------------------------------
      BEGIN
         gc_debug_loc := 'Retrieving Invoices Not Imported';
         OPEN lcu_check_not_imported;
         LOOP
            FETCH lcu_check_not_imported INTO lrec_not_imported_invoices;
            EXIT WHEN lcu_check_not_imported%NOTFOUND;

            gc_debug_loc  := 'total amt and record count from XX table';
            gc_debug_stmt := 'ln_xx_ra_cnt =  '||lrec_not_imported_invoices.line_count
                             ||' ln_xx_tot_amt =  '||lrec_not_imported_invoices.total_amount;

            WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   '
                     ||to_char(lrec_not_imported_invoices.trx_date, 'mm/dd/yyyy')
                     ||'   '||SUBSTR(RPAD(lrec_not_imported_invoices.name,25),1,25)
                     ||' '||SUBSTR(RPAD('No',20),1,10)
                     ||'           '||SUBSTR(RPAD(TO_CHAR(lrec_not_imported_invoices.line_count ,'9,999,999,999'),40),1,20)
                     ||'      '||SUBSTR(RPAD(TO_CHAR(lrec_not_imported_invoices.total_amount,'$9,999,999,999.00'),35),1,30) );

         END LOOP;
         CLOSE lcu_check_not_imported;
      END;

      --------------------------------------------
      -- Write Reference Insert status to output
      --------------------------------------------
      -- this is a place holder for adding references not inserted in the future.

   EXCEPTION
      WHEN OTHERS THEN
         gc_proc_name  := '    OUTPUT_IMPORT_STATUS ';
         gc_debug_stmt :=  SUBSTR(SQLERRM,1,249);
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

   END OUTPUT_IMPORT_STATUS;

   -- +=====================================================================+
   -- | Name : OUTPUT_REF_INS_STATUS                                        |
   -- | Description : Write details to output for reference not inserted    |
   -- |               writes output                                         |
   -- | Parameters                                                          |
   -- | Returns : p_ret_code                                                |
   -- +=====================================================================+
   PROCEDURE OUTPUT_REF_INS_STATUS
   AS
      ln_trx_type_id          NUMBER;
      lc_trx_type_name        ra_cust_trx_types_all.name%type;
      ld_trx_date             xx_ra_int_lines_all.trx_date%type;

      ln_ref_cnt              NUMBER;
      ln_ref_tot_amt          NUMBER;

      ln_ret_code2            NUMBER := 0;


      -----------------------------------------------------------
      -- Cursor to determine if reference not inserted correctly
      -----------------------------------------------------------
      CURSOR lcu_check_ref_inst_status
      IS
         SELECT XRILA.trx_date
               ,RCTA.name                                    -- AR_TRANSACTION_NAME
               ,XRILA.cust_trx_type_id
               ,NVL(COUNT(1),0)                              -- REC_COUNT
               ,NVL(SUM(XRILA.amount),0)                       -- TOT_AMOUNT
           FROM xx_ra_int_lines_all     XRILA
               ,ra_cust_trx_types_all   RCTA
          WHERE XRILA.batch_source_name      = gc_batch_source_name
            AND XRILA.ORG_ID                 = gn_org_id
            AND XRILA.interface_line_context = G_ORDER_ENTRY
            AND XRILA.cust_trx_type_id       = RCTA.cust_trx_type_id
            AND XRILA.interface_status       = 'R'
            AND XRILA.orig_system_bill_customer_id BETWEEN gn_cust_id_low
                                                       AND gn_cust_id_high
         GROUP BY XRILA.trx_date
                 ,RCTA.name
                 ,XRILA.cust_trx_type_id
         ORDER BY XRILA.trx_date
                 ,RCTA.name;

   BEGIN
      gc_proc_name := '    OUTPUT_REF_INS_STATUS ';
      --------------------------------------------
      -- Write Reference Insert status to output
      --------------------------------------------
      WRITE_OUTPUT ('REFERENCE_STATUS_HEADER');

      OPEN lcu_check_ref_inst_status;
      LOOP
         FETCH lcu_check_ref_inst_status INTO ld_trx_date,
                                              lc_trx_type_name,            -- AR_TRANSACTION_NAME
                                              ln_trx_type_id,
                                              ln_ref_cnt,
                                               ln_ref_tot_amt;

         EXIT WHEN lcu_check_ref_inst_status%NOTFOUND;

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   '
                      ||to_char(ld_trx_date, 'mm/dd/yyyy')
                      ||'   '||SUBSTR(RPAD(lc_trx_type_name,25),1,25)
                      ||' '||SUBSTR(RPAD(to_char(ln_ref_cnt ,'9,999,999,999'),35),1,20)
                      ||' '||SUBSTR(RPAD(to_char(ln_ref_tot_amt,'$9,999,999,999.00'),35),1,30)
                       );
      END LOOP;

   EXCEPTION
      WHEN OTHERS THEN
         gc_debug_stmt :=  SUBSTR(SQLERRM,1,249);
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

   END OUTPUT_REF_INS_STATUS;

   -- +=====================================================================+
   -- | Name : CHECK_IMPORT_STATUS                                          |
   -- | Description : Procedure to check if tranaction were imported        |
   -- | Parameters  gc_batch_source_name ,gn_org_id ,p_cleanup_flg          |
   -- | Returns : p_ret_code                                                |
   -- +=====================================================================+
   PROCEDURE CHECK_IMPORT_STATUS (p_ret_code      OUT  NUMBER
                                 ,p_cleanup_flg    IN  VARCHAR2 DEFAULT 'N') --Add new proc to MD-70
   AS

      PROCESS_ERROR               EXCEPTION;

      ln_ar_rec_cnt               NUMBER;
      lc_rec_found_flg            VARCHAR2(1);
      lc_write_header             VARCHAR2(1) := 'Y';
      lc_write_header_log         VARCHAR2(1) := 'Y';

      lc_old_trx_date             xx_ra_int_lines_all.trx_date%type := '01-MAR-1111';
      lc_old_trx_name             RA_CUST_TRX_TYPES_ALL.NAME%type :=0;
      lc_new_trx_name             RA_CUST_TRX_TYPES_ALL.NAME%type;

      lc_dis_trx_date_import      xx_ra_int_lines_all.trx_date%type;
      lc_dis_trx_type_import      xx_ra_int_lines_all.interface_line_attribute2%type;
      lc_dis_trx_date_not_import  xx_ra_int_lines_all.trx_date%type;
      lc_dis_trx_type_not_import  xx_ra_int_lines_all.interface_line_attribute2%type;

      ln_dis_tot_cnt_import      NUMBER;
      ln_dis_tot_amt_import      NUMBER;
      ln_dis_tot_cnt_not_import  NUMBER;
      ln_dis_tot_amt_not_import  NUMBER;
      ln_ar_import_total         NUMBER;

      ln_xx_ra_cnt               NUMBER;
      ln_xx_tot_amt              NUMBER;
      ln_ar_diff_tot             NUMBER;
      ln_ar_diff_cnt             NUMBER;
      lc_trx_number              xx_ra_int_lines_all.trx_number%TYPE;

      ln_ret_code2               NUMBER;
      ln_ret_code3               NUMBER;

      ln_ref_rows_insert         NUMBER;
      ln_ref_rows_insert_gt      NUMBER := 0;

      ln_out_of_balance_inv_cnt  NUMBER := 0;
      ln_out_of_bal_updated      NUMBER := 0;
      ln_out_of_bal_updated_gt   NUMBER := 0;

      ln_no_refs_insert_inv_cnt  NUMBER := 0;
      ln_no_refs_updated_recs    NUMBER := 0;
      ln_no_refs_updated_recs_gt NUMBER := 0;

      lc_max_trx_date            xx_ra_int_lines_all.trx_date%type;

      CURSOR lcu_check_import_status
      IS
         SELECT XRILA.trx_date
               ,XRILA.trx_number
               ,RCTA.name                                    -- AR_TRANSACTION_NAME
               ,XRILA.cust_trx_type_id
               ,NVL(COUNT(1),0)           REC_XX_COUNT
               ,NVL(SUM(XRILA.amount),0)  TOT_XX_AMOUNT
           FROM xx_ra_int_lines_all     XRILA
               ,ra_cust_trx_types_all   RCTA
          WHERE XRILA.batch_source_name            = gc_batch_source_name
            AND XRILA.ORG_ID                       = gn_org_id
            AND XRILA.interface_line_context       = G_POS_ORDER_ENTRY
            AND XRILA.interface_line_attribute3    = G_SUMMARY
            AND XRILA.cust_trx_type_id             = RCTA.cust_trx_type_id
            AND XRILA.interface_status             IS NULL
            AND XRILA.orig_system_bill_customer_id BETWEEN gn_cust_id_low
                                                       AND gn_cust_id_high
         GROUP BY XRILA.trx_date
                 ,XRILA.trx_number
                 ,RCTA.name
                 ,XRILA.cust_trx_type_id
         ORDER BY XRILA.trx_date
                 ,RCTA.name
                 ,XRILA.trx_number;

         TYPE t_bulk_sum_tab IS TABLE OF lcu_check_import_status%ROWTYPE
              INDEX BY BINARY_INTEGER;

         rec_tab t_bulk_sum_tab;

   BEGIN
      gc_proc_name            := '    CHECK_IMPORT_STATUS';
      lc_rec_found_flg        := 'N';
      gc_ref_rec_not_inserted := 'N';
      gc_out_of_balance_flag  := 'N';

      WRITE_LOG(gc_debug_flg,' ' ,null,null );
      WRITE_LOG(gc_debug_flg,'  Current System Time: ',
                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );

      gc_debug_loc  := '        Select from XX_RA_INT_LINES_ALL';
      gc_debug_stmt := 'Checking if Summary Invoices exist';
      WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

      lc_write_header := 'Y';
      -----------------------------------
      -- Counters for Tracking DML Stats
      -----------------------------------
      gn_xx_int_lines_del_sum_cnt := 0;
      gn_xx_int_dist_del_sum_cnt  := 0;
      gn_xx_int_sales_del_sum_cnt := 0;
      gn_xx_int_lines_del_dtl_cnt := 0;
      gn_xx_int_dist_del_dtl_cnt  := 0;
      gn_xx_int_sales_del_dtl_cnt := 0;

      OPEN lcu_check_import_status;
      LOOP
         FETCH lcu_check_import_status
              BULK COLLECT INTO rec_tab LIMIT gn_bulk_limit;

         EXIT WHEN rec_tab.count = 0;

         lc_rec_found_flg := 'Y';

         WRITE_LOG(gc_debug_flg,' ' ,null,null );

         FOR ln_disc_cnt IN 1.. rec_tab.count
         LOOP

            --lc_new_trx_date := TRUNC(rec_tab(ln_disc_cnt).trx_date);
            lc_new_trx_name := rec_tab(ln_disc_cnt).NAME;
            lc_trx_number   := rec_tab(ln_disc_cnt).trx_number;

            ln_ar_rec_cnt := 0;
            --------------------------------------------------------
            -- Select from RA_CUSTOMER_TRX_ALL: Checking if Summary
            -- Invoices exist
            --------------------------------------------------------
            BEGIN
               SELECT NVL(COUNT(1),0)
                     ,NVL(SUM(RCTL.extended_amount),0)                               -- added NVL for defect 12289
                 INTO ln_ar_rec_cnt
                     ,ln_ar_import_total
                 FROM ra_customer_trx_all       RCT
                     ,ra_customer_trx_lines_all RCTL
                WHERE trx_number                      = rec_tab(ln_disc_cnt).trx_number
                  AND RCTL.customer_trx_id            = RCT.customer_trx_id
                  AND RCT.cust_trx_type_id            = rec_tab(ln_disc_cnt).cust_trx_type_id
                  AND RCT.interface_header_attribute3 = G_SUMMARY
                  AND RCT.interface_header_context    = G_POS_ORDER_ENTRY
                  AND RCT.org_id                      = gn_org_id;

            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  ln_ar_rec_cnt := 0;
                  ln_ar_import_total := 0;

               WHEN OTHERS THEN
                  ln_ar_rec_cnt := 0;
                  ln_ar_import_total := 0;
            END;

            --------------------------------------------
            -- Check for record imported Records imported
            --------------------------------------------
            IF rec_tab(ln_disc_cnt).REC_XX_COUNT      = ln_ar_rec_cnt
               AND rec_tab(ln_disc_cnt).tot_xx_amount = ln_ar_import_total
               AND rec_tab(ln_disc_cnt).REC_XX_COUNT <> 0 THEN

               WRITE_LOG(gc_debug_flg ,'     Summary invoices exists in AR '
                                        ||'for TRX_NUMBER : '
                                          ,rec_tab(ln_disc_cnt).trx_number );

               ---------------------------------------------------
               -- If records found call reference insert procedure
               ---------------------------------------------------
               gc_debug_loc  := 'Reference info being inserted ';
               gc_debug_stmt := 'into _inv_order_ref table'
                                || 'for trx_num: ' || rec_tab(ln_disc_cnt).trx_number ;
               WRITE_LOG(gc_debug_flg, gc_proc_name ,gc_debug_loc, gc_debug_stmt );

               BEGIN
                  ln_ref_rows_insert := 0;

                  BEGIN
                     INSERT INTO xx_ar_pos_inv_order_ref
                         SELECT DISTINCT
                                XRILA.related_trx_number
                               ,RCT.customer_trx_id
                               ,XRILA.header_attribute14
                               ,XRILA.sales_order
                               ,XRILA.trx_date
                               ,gd_process_date
                               ,XRILA.org_id
                               ,gn_user_id
                               ,SYSDATE
                               ,gn_user_id
                               ,SYSDATE
                               ,gn_login_id
                               ,gn_request_id
                          FROM xx_ra_int_lines_all     XRILA
                              ,ra_customer_trx_all     RCT
                         WHERE RCT.trx_number                     = XRILA.related_trx_number
                           AND XRILA.related_trx_number           = rec_tab(ln_disc_cnt).trx_number
                           AND XRILA.cust_trx_type_id             = RCT.cust_trx_type_id
                           AND RCT.interface_header_attribute3    = G_SUMMARY
                           AND RCT.interface_header_context       = G_POS_ORDER_ENTRY
                           AND XRILA.org_id                       = gn_org_id
                           AND XRILA.org_id                       = RCT.org_id
                           AND XRILA.header_attribute14           IS NOT NULL
                           AND XRILA.orig_system_bill_customer_id BETWEEN gn_cust_id_low
                                                                      AND gn_cust_id_high;


                  EXCEPTION
                     WHEN OTHERS THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'When Other Location1');
                        gc_debug_loc  := '    Insert When Others Errors: ';
                        gc_debug_stmt :=  SUBSTR(SQLERRM,1,249);
                        WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

                        gc_debug_loc  := '    Rows Inserted into: ';
                        gc_debug_stmt := '_inv_order_ref = '|| SQL%ROWCOUNT
                                          ||' for Trx_number ='||rec_tab(ln_disc_cnt).trx_number ;

                        WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

                        ---------------------------------------
                        --  Set flag to print output details
                        ---------------------------------------
                        gc_ref_rec_not_inserted := 'Y';

                        RAISE PROCESS_ERROR;
                  END;

                  ln_ref_rows_insert    := SQL%ROWCOUNT;
                  ln_ref_rows_insert_gt := ln_ref_rows_insert_gt + ln_ref_rows_insert;

                  IF ln_ref_rows_insert = 0  THEN

                     gc_debug_loc  := 'Error: Zero Rows Inserted into: ';
                     gc_debug_stmt := '_inv_order_ref '
                                     ||' for Trx_number ='||rec_tab(ln_disc_cnt).trx_number ;
                     WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

                     ---------------------------------------
                     --  Set flag to print output details
                     ---------------------------------------
                     gc_ref_rec_not_inserted := 'Y';

                     RAISE PROCESS_ERROR;

                  END IF;

                  gc_debug_loc  := 'Calling DELETE_SUM_DETAIL_RECS ';
                  gc_debug_stmt := ' ';

                  WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );
                  ---------------------------------------------
                  --  Delete Summary and Details from XX tables
                  ---------------------------------------------
                  DELETE_SUM_DETAIL_RECS (ln_ret_code2
                                         ,rec_tab(ln_disc_cnt).trx_number);

                  IF ln_ret_code2  <> 0 THEN

                     gc_debug_loc := 'Error occured Deleting summary '
                                      ||' and Details invoices from: ';
                     gc_debug_stmt := 'trx_number= ' ||rec_tab(ln_disc_cnt).trx_number
                                      ||' Transaction may exist in xx tables? ';
                     WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

                     p_ret_code := 2;

                     RAISE PROCESS_ERROR;

                  ELSE
                     COMMIT;

                  END IF;

               EXCEPTION
                  WHEN PROCESS_ERROR THEN
                     ROLLBACK;

                     gc_debug_loc  := '    PROCESS_ERROR: Exception ';
                     gc_debug_stmt := 'ROLLBACK executed  for TRX_NUMBER'
                                      ||rec_tab(ln_disc_cnt).trx_number;
                     WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
                     ------------------------------------------------
                     -- Updating detail records with rejection error
                     ------------------------------------------------
                     UPDATE xx_ra_int_lines_all  XRILA
                        SET XRILA.interface_status = 'R'
                      WHERE XRILA.related_trx_number     = rec_tab(ln_disc_cnt).trx_number
                        AND XRILA.org_id                 = gn_org_id
                        AND XRILA.interface_line_context = G_ORDER_ENTRY;

                     ln_no_refs_updated_recs    := SQL%ROWCOUNT;
                     ln_no_refs_updated_recs_gt := ln_no_refs_updated_recs_gt + ln_no_refs_updated_recs;

                     -- increment counter for imported invoices where references not inserted
                     ln_no_refs_insert_inv_cnt  := ln_no_refs_insert_inv_cnt + 1;

                     COMMIT;
                     p_ret_code := 2;

               END;

            ---------------------------------------
            -- Records not imported successfully
            ---------------------------------------
            ELSIF (ln_ar_rec_cnt = 0 AND ln_ar_import_total = 0) THEN

               IF p_cleanup_flg = 'Y'  THEN
                  ------------------------------------------------
                  -- No records found CUST table cleanup procedure
                  ------------------------------------------------
                  RESTART_CLEANUP (rec_tab(ln_disc_cnt).trx_number );

               END IF;

            ELSE
               gc_out_of_balance_flag := 'Y';

               gc_debug_loc := 'Summary invoice not fully imported ';
               gc_debug_stmt := 'trx_number= ' ||rec_tab(ln_disc_cnt).trx_number;
               WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
               ------------------------------------------------
               -- Summary invoice not fully imported
               ------------------------------------------------
               UPDATE xx_ra_int_lines_all XRILA
                  SET XRILA.interface_status = 'O'
                WHERE XRILA.related_trx_number     = rec_tab(ln_disc_cnt).trx_number    -- details
                  AND XRILA.org_id                 = gn_org_id
                  AND XRILA.interface_line_context = G_ORDER_ENTRY;

               ln_out_of_bal_updated     := SQL%ROWCOUNT;
               ln_out_of_bal_updated_gt  := ln_out_of_bal_updated_gt + ln_out_of_bal_updated;

               UPDATE xx_ra_int_lines_all XRILA
                  SET XRILA.interface_status = 'O'
                WHERE XRILA.trx_number                = rec_tab(ln_disc_cnt).trx_number            -- summary
                  AND XRILA.org_id                    = gn_org_id
                  AND XRILA.interface_line_context    = G_POS_ORDER_ENTRY
                  AND XRILA.interface_line_attribute3 = G_SUMMARY;

               ln_out_of_bal_updated     := SQL%ROWCOUNT;
               ln_out_of_bal_updated_gt  := ln_out_of_bal_updated_gt + ln_out_of_bal_updated;

               -- increment counter for imported invoices out-of-balance
               ln_out_of_balance_inv_cnt := ln_out_of_balance_inv_cnt + 1;

               COMMIT;

               FND_FILE.PUT_LINE(FND_FILE.LOG,'Values from XX tables ');
               FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_COUNT ='||rec_tab(ln_disc_cnt).REC_XX_COUNT );
               FND_FILE.PUT_LINE(FND_FILE.LOG,'tot_amount ='||rec_tab(ln_disc_cnt).tot_xx_amount );

               FND_FILE.PUT_LINE(FND_FILE.LOG,'Values from RA tables');
               FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_ra_rec_cnt ='||ln_ar_rec_cnt );
               FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_ar_import_total ='||ln_ar_import_total );

               gc_debug_loc  := ' !!!!!!!!!!!SUMMARY INVOICES EXIST ON THE INTERFACE TABLE';
               gc_debug_stmt := ' Autoinvoice did not FULLY import invoice lines for TRX_NUMBER : '
                                     ||rec_tab(ln_disc_cnt).trx_number
                                     ||'Custom Trx Type ID:' || rec_tab(ln_disc_cnt).cust_trx_type_id
                                     ||' !!!!!!!!!!!'  ||' Review Concurrent request: '||gn_request_id;

               WRITE_LOG('Y','    WARNING!' ,gc_debug_loc, gc_debug_stmt );

               p_ret_code := 1;

            END IF;

         END LOOP;

      END LOOP;
      CLOSE lcu_check_import_status;

      IF lc_rec_found_flg = 'N' THEN
         gc_debug_loc  :='    No Sum recs exists in RA_CUSTOMER_TRX_ALL';
         gc_debug_stmt :='RESTART_CLEANUP not Called';
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
      END IF;

      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
      WRITE_LOG('Y',gc_proc_name ,'    Imported Summary TRX - Post-Autoinvoice Processing not completed for summary inv', ln_no_refs_insert_inv_cnt);
      WRITE_LOG('Y',gc_proc_name ,'    Imported Summary TRX - Detailed records updated (interface_status=R)            ', ln_no_refs_updated_recs_gt);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
      WRITE_LOG('Y',gc_proc_name ,'    Imported Summary TRX - PARTIALLY IMPORTED INVOICES MANUAL INTERVENTION REQUIRED ', ln_out_of_balance_inv_cnt);
      WRITE_LOG('Y',gc_proc_name ,'    Imported Summary TRX - DETAILED AND SUMMARY RECORDS UPDATED (interface_status=O)', ln_out_of_bal_updated_gt);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
      WRITE_LOG('Y',gc_proc_name ,'    Imported Summary TRX - Unique References Inserted (summary trx and header id)   ', ln_ref_rows_insert_gt);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
      WRITE_LOG('Y',gc_proc_name ,'    Imported Summary TRX - Summary  records deleted from xx_ra_int_lines_all        ', gn_xx_int_lines_del_sum_cnt);
      WRITE_LOG('Y',gc_proc_name ,'    Imported Summary TRX - Summary  records deleted from xx_ra_int_distributions_all', gn_xx_int_dist_del_sum_cnt);
      --WRITE_LOG('Y',gc_proc_name ,'    Imported Summary TRX - Summary  records deleted from xx_ra_int_salescredits_all ', gn_xx_int_sales_del_sum_cnt);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
      WRITE_LOG('Y',gc_proc_name ,'    Imported Summary TRX - Detailed records deleted from xx_ra_int_lines_all        ', gn_xx_int_lines_del_dtl_cnt);
      WRITE_LOG('Y',gc_proc_name ,'    Imported Summary TRX - Detailed records deleted from xx_ra_int_distributions_all', gn_xx_int_dist_del_dtl_cnt);
      --WRITE_LOG('Y',gc_proc_name ,'    Imported Summary TRX - Detailed records deleted from xx_ra_int_salescredits_all ', gn_xx_int_sales_del_dtl_cnt);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

   EXCEPTION
      WHEN OTHERS THEN
         gc_proc_name  := '    CHECK_IMPORT_STATUS';
         gc_debug_loc  :=  'When Other Location End';
         gc_debug_stmt :=  SUBSTR(SQLERRM,1,249);
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
         p_ret_code := 2;
         ROLLBACK;
   END CHECK_IMPORT_STATUS;

   -- +=====================================================================+
   -- | Name : SET_TAX_ATTR_LINKS                                           |
   -- | Description :                                                       |
   -- | Returns :                                                           |
   -- +=====================================================================+
   PROCEDURE SET_TAX_ATTR_LINKS (gc_batch_source_name  IN  VARCHAR2
                                ,gn_org_id             IN  NUMBER
                                ,p_transaction_type    IN  VARCHAR2
                                ,p_cust_trx_type_id    IN  NUMBER
                                ,p_trx_date            IN  DATE
                                ,p_org_bill_cus_id     IN  VARCHAR2
                                ,p_org_bill_add_id     IN  VARCHAR2
                                ,p_org_ship_cus_id     IN  VARCHAR2
                                ,p_org_ship_add_id     IN  VARCHAR2
                                ,p_org_sold_cus_id     IN  VARCHAR2
                                ,x_tax_attr1          OUT  VARCHAR2
                                ,x_tax_attr2          OUT  VARCHAR2
                                ,x_tax_attr3          OUT  VARCHAR2
                                ,x_tax_attr4          OUT  VARCHAR2
                                ,x_tax_attr5          OUT  VARCHAR2
                                ,x_tax_attr6          OUT  VARCHAR2
                                ,x_tax_attr7          OUT  VARCHAR2
                                ,x_tax_attr8          OUT  VARCHAR2
                                ,x_tax_attr9          OUT  VARCHAR2
                                ,x_tax_attr10         OUT  VARCHAR2
                                ,x_tax_attr11         OUT  VARCHAR2
                                ,x_tax_attr12         OUT  VARCHAR2
                                ,x_tax_attr13         OUT  VARCHAR2
                                ,x_tax_attr14         OUT  VARCHAR2
                                ,x_tax_attr15         OUT  VARCHAR2
                                ,x_ret_code           OUT  NUMBER)
   AS
      ln_tax_total     NUMBER;

      TYPE AttributeRecType is record
            (tax_attr1     xx_ra_int_lines_all.interface_line_attribute1%TYPE,
             tax_attr2     xx_ra_int_lines_all.interface_line_attribute2%TYPE,
             tax_attr3     xx_ra_int_lines_all.interface_line_attribute3%TYPE,
             tax_attr4     xx_ra_int_lines_all.interface_line_attribute4%TYPE,
             tax_attr5     xx_ra_int_lines_all.interface_line_attribute5%TYPE,
             tax_attr6     xx_ra_int_lines_all.interface_line_attribute6%TYPE,
             tax_attr7     xx_ra_int_lines_all.interface_line_attribute7%TYPE,
             tax_attr8     xx_ra_int_lines_all.interface_line_attribute8%TYPE,
             tax_attr9     xx_ra_int_lines_all.interface_line_attribute9%TYPE,
             tax_attr10    xx_ra_int_lines_all.interface_line_attribute10%TYPE,
             tax_attr11    xx_ra_int_lines_all.interface_line_attribute11%TYPE,
             tax_attr12    xx_ra_int_lines_all.interface_line_attribute12%TYPE,
             tax_attr13    xx_ra_int_lines_all.interface_line_attribute13%TYPE,
             tax_attr14    xx_ra_int_lines_all.interface_line_attribute14%TYPE,
             tax_attr15    xx_ra_int_lines_all.interface_line_attribute15%TYPE);

      att_record AttributeRecType;

   BEGIN
      gc_proc_name := '    SET_TAX_ATTR_LINKS';
      gc_debug_loc := '   Setting tax line attributes: ';
      WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );
      x_ret_code := 0;

      SELECT NVL(SUM(XRILA.amount),0)
        INTO ln_tax_total
        FROM xx_ra_int_lines_all         XRILA
       WHERE XRILA.batch_source_name             = gc_batch_source_name
         AND XRILA.org_id                        = gn_org_id
         AND XRILA.cust_trx_type_id              = p_cust_trx_type_id
         AND XRILA.trx_date                      = p_trx_date
         AND XRILA.orig_system_bill_customer_id  = p_org_bill_cus_id
         AND XRILA.orig_system_bill_address_id   = p_org_bill_add_id
         AND XRILA.orig_system_ship_customer_id  = p_org_ship_cus_id
         AND XRILA.orig_system_ship_address_id   = p_org_ship_add_id
         AND XRILA.orig_system_sold_customer_id  = p_org_sold_cus_id
         AND XRILA.interface_line_context        = G_ORDER_ENTRY
         AND XRILA.interface_status              IS NULL
         AND XRILA.line_type                     = 'TAX';

      gc_debug_loc  := '   Total tax total = '||ln_tax_total;
      gc_debug_stmt := SUBSTR(' for '||gc_batch_source_name||gn_org_id
                            ||p_transaction_type||':'|| p_cust_trx_type_id
                            ||':'|| p_trx_date||':'||p_org_bill_cus_id ||':'
                            ||p_org_bill_add_id||':'||p_org_ship_cus_id
                            ||':'||p_org_ship_add_id||':'
                            ||p_org_sold_cus_id,1,249);

      WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

      IF ln_tax_total >= 0  THEN
         gc_debug_loc  := '   Selecting first (+) REV line ';
         gc_debug_stmt := ' ';
         WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt);

         ---------------------------------------------------------------
         -- Sum total is positive amount select atrribute values from
         -- from first positive REV line
         ---------------------------------------------------------------
         SELECT interface_line_attribute1
               ,interface_line_attribute2
               ,interface_line_attribute3
               ,interface_line_attribute4
               ,interface_line_attribute5
               ,interface_line_attribute6
               ,interface_line_attribute7
               ,interface_line_attribute8
               ,interface_line_attribute9
               ,interface_line_attribute10
               ,interface_line_attribute11
               ,interface_line_attribute12
               ,interface_line_attribute13
               ,interface_line_attribute14
               ,interface_line_attribute15
           INTO att_record
           FROM (SELECT interface_line_attribute1
                       ,interface_line_attribute2
                       ,interface_line_attribute3
                       ,interface_line_attribute4
                       ,interface_line_attribute5
                       ,interface_line_attribute6
                       ,interface_line_attribute7
                       ,interface_line_attribute8
                       ,interface_line_attribute9
                       ,interface_line_attribute10
                       ,interface_line_attribute11
                       ,interface_line_attribute12
                       ,interface_line_attribute13
                       ,interface_line_attribute14
                       ,interface_line_attribute15
                   FROM xx_ra_int_lines_all         XRIL
                  WHERE XRIL.batch_source_name             = gc_batch_source_name
                    AND XRIL.org_id                        = gn_org_id
                    AND XRIL.cust_trx_type_id              = p_cust_trx_type_id
                    AND XRIL.trx_date                      = p_trx_date
                    AND XRIL.orig_system_bill_customer_id  = p_org_bill_cus_id
                    AND XRIL.orig_system_bill_address_id   = p_org_bill_add_id
                    AND XRIL.orig_system_ship_customer_id  = p_org_ship_cus_id
                    AND XRIL.orig_system_ship_address_id   = p_org_ship_add_id
                    AND XRIL.orig_system_sold_customer_id  = p_org_sold_cus_id
                    AND XRIL.interface_line_context        = G_POS_ORDER_ENTRY
                    AND XRIL.interface_line_attribute3     = G_SUMMARY
                    AND XRIL.interface_status              IS NULL
                    AND XRIL.interface_line_attribute11    = 'N'               -- discount
                    AND XRIL.amount                       >= 0
                    AND XRIL.line_type                     = 'LINE'
                 GROUP BY interface_line_attribute1
                         ,interface_line_attribute2
                         ,interface_line_attribute3
                         ,interface_line_attribute4
                         ,interface_line_attribute5
                         ,interface_line_attribute6
                         ,interface_line_attribute7
                         ,interface_line_attribute8
                         ,interface_line_attribute9
                         ,interface_line_attribute10
                         ,interface_line_attribute11
                         ,interface_line_attribute12
                         ,interface_line_attribute13
                         ,interface_line_attribute14
                          ,interface_line_attribute15
                 ORDER BY TO_NUMBER(interface_line_attribute6) ASC)
                 WHERE ROWNUM < 2;

                 WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt);

      ELSE
         gc_debug_loc  := '   Selecting first (-) REV line ';
         gc_debug_stmt := ' ';
         WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt);

         ---------------------------------------------------------------
         -- Sum total is negative amount select atrribute values from
         -- from first positive REV line
         ---------------------------------------------------------------
         SELECT interface_line_attribute1
               ,interface_line_attribute2
               ,interface_line_attribute3
               ,interface_line_attribute4
               ,interface_line_attribute5
               ,interface_line_attribute6
               ,interface_line_attribute7
               ,interface_line_attribute8
               ,interface_line_attribute9
               ,interface_line_attribute10
               ,interface_line_attribute11
               ,interface_line_attribute12
               ,interface_line_attribute13
               ,interface_line_attribute14
               ,interface_line_attribute15
           INTO att_record
           FROM (SELECT interface_line_attribute1
                       ,interface_line_attribute2
                       ,interface_line_attribute3
                       ,interface_line_attribute4
                       ,interface_line_attribute5
                       ,interface_line_attribute6
                       ,interface_line_attribute7
                       ,interface_line_attribute8
                       ,interface_line_attribute9
                       ,interface_line_attribute10
                       ,interface_line_attribute11
                       ,interface_line_attribute12
                       ,interface_line_attribute13
                       ,interface_line_attribute14
                       ,interface_line_attribute15
                   FROM xx_ra_int_lines_all         XRIL
                  WHERE XRIL.batch_source_name             = gc_batch_source_name
                    AND XRIL.org_id                        = gn_org_id
                    AND XRIL.cust_trx_type_id              = p_cust_trx_type_id
                    AND XRIL.trx_date                      = p_trx_date
                    AND XRIL.orig_system_bill_customer_id  = p_org_bill_cus_id
                    AND XRIL.orig_system_bill_address_id   = p_org_bill_add_id
                    AND XRIL.orig_system_ship_customer_id  = p_org_ship_cus_id
                    AND XRIL.orig_system_ship_address_id   = p_org_ship_add_id
                    AND XRIL.orig_system_sold_customer_id  = p_org_sold_cus_id
                    AND XRIL.interface_line_context        = G_POS_ORDER_ENTRY
                    AND XRIL.interface_line_attribute3     = G_SUMMARY
                    AND XRIL.interface_status              IS NULL
                    AND XRIL.interface_line_attribute11    = 'N'                -- discount flag
                    AND XRIL.amount                       <= 0
                    AND XRIL.line_type                     = 'LINE'
                 GROUP BY interface_line_attribute1
                         ,interface_line_attribute2
                         ,interface_line_attribute3
                         ,interface_line_attribute4
                         ,interface_line_attribute5
                         ,interface_line_attribute6
                         ,interface_line_attribute7
                         ,interface_line_attribute8
                         ,interface_line_attribute9
                         ,interface_line_attribute10
                         ,interface_line_attribute11
                         ,interface_line_attribute12
                         ,interface_line_attribute13
                         ,interface_line_attribute14
                         ,interface_line_attribute15
                   ORDER BY TO_NUMBER(interface_line_attribute6) asc)
                 WHERE ROWNUM < 2;


      END IF;

      x_tax_attr1  := att_record.tax_attr1;
      x_tax_attr2  := att_record.tax_attr2;
      x_tax_attr3  := att_record.tax_attr3;
      x_tax_attr4  := att_record.tax_attr4;
      x_tax_attr5  := att_record.tax_attr5;
      x_tax_attr6  := att_record.tax_attr6;
      x_tax_attr7  := att_record.tax_attr7;
      x_tax_attr8  := att_record.tax_attr8;
      x_tax_attr9  := att_record.tax_attr9;
      x_tax_attr10 := att_record.tax_attr10;
      x_tax_attr11 := att_record.tax_attr11;
      x_tax_attr12 := att_record.tax_attr12;
      x_tax_attr13 := att_record.tax_attr13;
      x_tax_attr14 := att_record.tax_attr14;
      x_tax_attr15 := att_record.tax_attr15;

   EXCEPTION
      WHEN OTHERS THEN
         gc_proc_name  := '    SET_TAX_ATTR_LINKS';
         gc_debug_loc  := ': When other Error';
         gc_debug_stmt :=  SUBSTR(SQLERRM,1,249);

         WRITE_LOG('Y',NULL,NULL,'batch_source_name  = '||gc_batch_source_name);
         WRITE_LOG('Y',NULL,NULL,'org_id    = ' ||gn_org_id);
         WRITE_LOG('Y',NULL,NULL,'cust_trx_type_id   = ' ||p_cust_trx_type_id);
         WRITE_LOG('Y',NULL,NULL,'trx_date  = ' || p_trx_date );
         WRITE_LOG('Y',NULL,NULL,'orig_system_bill_customer_id =' ||p_org_bill_cus_id);
         WRITE_LOG('Y',NULL,NULL,'orig_system_bill_address_id = ' || p_org_bill_add_id);

         WRITE_LOG('Y',NULL,'Attribute2 1-15',     att_record.tax_attr1
                                              ||':'||att_record.tax_attr2
                                              ||':'||att_record.tax_attr3
                                              ||':'||att_record.tax_attr4
                                              ||':'||att_record.tax_attr5
                                              ||':'||att_record.tax_attr6
                                              ||':'||att_record.tax_attr7
                                              ||':'||att_record.tax_attr8
                                              ||':'||att_record.tax_attr9
                                              ||':'||att_record.tax_attr10
                                              ||':'||att_record.tax_attr11
                                              ||':'||att_record.tax_attr12
                                              ||':'||att_record.tax_attr13
                                              ||':'||att_record.tax_attr14
                                              ||':'||att_record.tax_attr15 );

      x_ret_code := 1;

   END SET_TAX_ATTR_LINKS;

   -- +=====================================================================+
   -- | Name : CREATE_SUMMARY_INV                                           |
   -- | Description :                                                       |
   -- |  Step #3 � Create A Summarized Invoice for Every Combination of     |
   -- |             Internal Store Customer, Date, and Transaction Type.    |
   -- | Parameters   see below                                              |
   -- | Returns :                                                           |
   -- +=====================================================================+
   PROCEDURE CREATE_SUMMARY_INV (x_ret_code            OUT  NUMBER
                                ,gc_batch_source_name   IN  VARCHAR2
                                ,p_sob                  IN  NUMBER
                                ,gn_org_id              IN  NUMBER
                                ,p_transaction_type     IN  VARCHAR2
                                ,p_cust_trx_type_id     IN  NUMBER
                                ,p_trx_date             IN  DATE
                                ,p_org_bill_cus_id      IN  NUMBER
                                ,p_org_bill_add_id      IN  NUMBER
                                ,p_org_ship_cus_id      IN  NUMBER
                                ,p_org_ship_add_id      IN  NUMBER
                                ,p_org_sold_cus_id      IN  NUMBER
                                ,p_summary_rev          IN  NUMBER
                                ,p_summary_tax          IN  NUMBER
                                ,p_summary_rec          IN  NUMBER
                                ,p_acct_catgry          IN  VARCHAR2)
   AS
      lc_trans_flg             VARCHAR2(1);
      ln_trx_number            NUMBER;
      ln_summary_inv_line_rev  NUMBER := 0;
      ln_summary_inv_line_tax  NUMBER := 0;
      ln_summary_inv_line_rec  NUMBER := 0;
      lc_sum_tot_err_found     VARCHAR2(1);
      ln_conc_id               NUMBER;

      lc_orig_sys_cus_id       NUMBER;
      ln_amount_display        NUMBER;

      ln_line_tran_seq         NUMBER;
      lc_tax_line_discount     xx_ra_int_lines_all.link_to_line_attribute11%TYPE;
      lc_tax_line_reason_code  xx_ra_int_lines_all.reason_code%TYPE;               -- added for defect 12289

      lc_tax_attr1         xx_ra_int_lines_all.link_to_line_attribute6%TYPE;
      lc_tax_attr2         xx_ra_int_lines_all.link_to_line_attribute2%TYPE;
      lc_tax_attr3         xx_ra_int_lines_all.link_to_line_attribute6%TYPE;
      lc_tax_attr4         xx_ra_int_lines_all.link_to_line_attribute2%TYPE;
      lc_tax_attr5         xx_ra_int_lines_all.link_to_line_attribute6%TYPE;
      lc_tax_attr6         xx_ra_int_lines_all.link_to_line_attribute2%TYPE;
      lc_tax_attr7         xx_ra_int_lines_all.link_to_line_attribute6%TYPE;
      lc_tax_attr8         xx_ra_int_lines_all.link_to_line_attribute2%TYPE;
      lc_tax_attr9         xx_ra_int_lines_all.link_to_line_attribute6%TYPE;
      lc_tax_attr10        xx_ra_int_lines_all.link_to_line_attribute2%TYPE;
      lc_tax_attr11        xx_ra_int_lines_all.link_to_line_attribute6%TYPE;
      lc_tax_attr12        xx_ra_int_lines_all.link_to_line_attribute2%TYPE;
      lc_tax_attr13        xx_ra_int_lines_all.link_to_line_attribute6%TYPE;
      lc_tax_attr14        xx_ra_int_lines_all.link_to_line_attribute2%TYPE;
      lc_tax_attr15        xx_ra_int_lines_all.link_to_line_attribute6%TYPE;

      ln_rec_single_line_cnt  NUMBER;

      lc_line1_attribute2     xx_ra_int_lines_all.interface_line_attribute2%TYPE;

      lc_store_name           hz_cust_accounts.account_name%TYPE;
      ln_ret_code1            NUMBER;

      lc_tax_attr_updte_err   VARCHAR2(1);

      ln_xx_sum_lines_inserted      NUMBER := 0;
      ln_xx_sum_dists_inserted      NUMBER := 0;
      ln_xx_sum_sales_inserted      NUMBER := 0;
      ln_xx_detailed_inv_errors     NUMBER := 0;
      ln_xx_detailed_inv_linked     NUMBER := 0;

      INVALID_BATCH_SOURCE    EXCEPTION;

      ----------------------------------------------------------
      -- Cursor to select pos invoices that need to be summarized
      ----------------------------------------------------------
      CURSOR lcu_create_pos_sum_inv
      IS
         SELECT XRIL.batch_source_name
               ,DECODE(XRID.account_class,'REC', NULL,XRIL.interface_line_attribute2) OM_TRANSACTION_TYPE
               ,XRIL.cust_trx_type_id
               ,TRUNC(XRIL.trx_date)                                    TRX_DATE
               ,XRIL.line_type
               ,XRID.account_class
               ,XRIL.set_of_books_id
               ,XRIL.org_id
               ,XRIL.orig_system_bill_customer_id
               ,XRIL.orig_system_bill_address_id
               ,XRIL.orig_system_ship_customer_id
               ,XRIL.orig_system_ship_address_id
               ,XRIL.orig_system_sold_customer_id
               ,DECODE(XRID.account_class,'REC',NULL,SUM(XRIL.amount))    AMOUNT
               ,DECODE(XRID.account_class,'REC',NULL,SUM(XRIL.quantity)) QUANTITY
               ,DECODE(XRID.account_class,'REC',NULL,
                TO_CHAR((SUM(XRIL.quantity * TO_NUMBER(XRID.attribute9)) /
                               SUM(XRIL.quantity)),9999999999.99999999)) AVG_NET_COST
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.uom_code)     UOM_CODE
               ,XRID.percent
               ,DECODE(XRID.account_class,'REC','N'
--              ,DECODE(XRIL.interface_line_attribute11,'0','N','Y'))                  DISCOUNT    --Changed for defect 12169
               ,DECODE(XRIL.interface_line_attribute11,'0','N','Y'))                  DISCOUNT
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.currency_code)                CURRENCY_CODE
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.conversion_type)              CONVERSION_TYPE
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.conversion_rate)              CONVERSION_RATE
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.description)                  DESCRIPTION
               ,DECODE(XRID.account_class,'REC',NULL,'TAX',NULL,XRIL.inventory_item_id) INVENTORY_ITEM_ID
             -- ,DECODE(XRID.account_class,'REC',NULL,XRIL.interface_line_attribute10) WAREHOUSE    --Change for defect 12169
               ,XRIL.interface_line_attribute10                                         WAREHOUSE
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.ship_date_actual)             SHIP_DATE_ACTUAL
               ,DECODE(XRID.account_class,'REC',NULL,'TAX',NULL,XRIL.term_id)           TERM_ID
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.waybill_number)               WAYBILL_NUMBER
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.primary_salesrep_id)          PRIMARY_SALESREP_ID
               ,DECODE(XRID.account_class,'REC',NULL,'TAX',NULL,XRIL.reason_code)       REASON_CODE  -- modified for defect 12289
--               ,DECODE(XRID.account_class,'REC',NULL,XRIL.reason_code)                REASON_CODE  -- removed for defect 12289
               ,XRIL.interface_line_attribute3
               ,XRIL.interface_line_attribute4
               ,XRIL.interface_line_attribute5
               ,XRIL.interface_line_attribute7
               ,XRIL.interface_line_attribute8
               ,XRIL.interface_line_attribute12
               ,XRIL.interface_line_attribute13
               ,XRIL.interface_line_attribute14
               ,XRIL.interface_line_attribute15
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.tax_code)     TAX_CODE
       --       ,DECODE(XRID.account_class,'REC',NULL, XRIL.interface_line_attribute9)                    TAX_TYPE_FLAG
               , XRIL.interface_line_attribute9                   TAX_TYPE_FLAG             --Change for defect 12169
               ,DECODE(XRID.account_class,'REC',NULL,'S') TAX_EXEMPT_FLAG
               ,XRIL.line_gdf_attr_category
               ,XRIL.line_gdf_attribute1
               ,XRIL.link_to_line_attribute2
               ,XRIL.link_to_line_attribute3
               ,XRIL.link_to_line_attribute4
               ,XRIL.link_to_line_attribute5
               ,XRIL.link_to_line_attribute7
               ,XRIL.link_to_line_attribute8
               ,XRIL.link_to_line_attribute9
               ,XRIL.link_to_line_attribute10
               ,XRIL.link_to_line_attribute12
               ,XRIL.link_to_line_attribute13
               ,XRIL.link_to_line_attribute14
               ,XRIL.link_to_line_attribute15
               ,XRID.code_combination_id
               ,XRID.segment1
               ,XRID.segment2
               ,XRID.segment3
               ,XRID.segment4
               ,XRID.segment5
               ,XRID.segment6
               ,XRID.segment7
               ,XRID.attribute6                                        COGS_FLAG
               ,XRID.attribute7                                        COGS_ACCT
               ,XRID.attribute8                               COGS_INV_LIAB_ACCT
               ,XRID.attribute10                               COGS_CONSIGN_ACCT
               ,XRID.attribute11                                SALES_ATTRIBUTES
           FROM xx_ra_int_lines_all         XRIL
               ,xx_ra_int_distributions_all XRID
          WHERE XRIL.batch_source_name               = gc_batch_source_name
            AND XRIL.org_id                          = gn_org_id
            AND XRIL.cust_trx_type_id                = p_cust_trx_type_id
            AND XRIL.trx_date                        = p_trx_date
            AND XRIL.orig_system_bill_customer_id    = p_org_bill_cus_id
            AND XRIL.orig_system_bill_address_id     = p_org_bill_add_id
            AND XRIL.orig_system_ship_customer_id    = p_org_ship_cus_id
            AND XRIL.orig_system_ship_address_id     = p_org_ship_add_id
            AND XRIL.orig_system_sold_customer_id    = p_org_sold_cus_id
            AND XRIL.interface_line_attribute6       = XRID.interface_line_attribute6
            AND XRIL.interface_line_attribute1       = XRID.interface_line_attribute1
            AND XRIL.interface_line_attribute11      = XRID.interface_line_attribute11
            AND XRIL.interface_line_attribute9       = XRID.interface_line_attribute9
            AND XRIL.interface_status                IS NULL
            AND XRIL.interface_line_context          = G_ORDER_ENTRY
            AND (
                  (XRIL.line_type ='LINE' AND XRID.account_class = 'REV')
               OR (XRIL.line_type ='TAX'  AND XRID.account_class = 'TAX')
               OR (XRIL.line_type ='LINE' AND XRID.account_class = 'REC')
               )
            AND XRIL.orig_system_bill_customer_id BETWEEN gn_cust_id_low
                                                      AND gn_cust_id_high
            --AND TRX_NUMBER = '1990004'
      GROUP BY XRIL.batch_source_name
               ,DECODE(XRID.account_class,'REC',NULL, XRIL.interface_line_attribute2)
               ,XRIL.cust_trx_type_id
               ,TRUNC(XRIL.trx_date)
               ,XRIL.line_type
               ,XRID.account_class
               ,XRIL.set_of_books_id
               ,XRIL.org_id
               ,XRIL.orig_system_bill_customer_id
               ,XRIL.orig_system_bill_address_id
               ,XRIL.orig_system_ship_customer_id
               ,XRIL.orig_system_ship_address_id
               ,XRIL.orig_system_sold_customer_id
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.uom_code)
               ,XRID.percent
               ,DECODE(XRID.account_class,'REC','N',DECODE(XRIL.interface_line_attribute11,'0','N','Y'))
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.currency_code)
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.conversion_type)
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.conversion_rate)
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.description)
               ,DECODE(XRID.account_class,'REC',NULL,'TAX',NULL,XRIL.inventory_item_id)
              -- ,DECODE(XRID.account_class,'REC',NULL,XRIL.interface_line_attribute10)
               ,XRIL.interface_line_attribute10
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.ship_date_actual)
               ,DECODE(XRID.account_class,'REC',NULL,'TAX',NULL,XRIL.term_id)
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.waybill_number)
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.primary_salesrep_id)
--               ,DECODE(XRID.account_class,'REC',NULL,XRIL.reason_code)                      -- removed for defect 12289
               ,DECODE(XRID.account_class,'REC',NULL,'TAX',NULL,XRIL.reason_code)             -- modified for defect 12289
               ,XRIL.interface_line_attribute3
               ,XRIL.interface_line_attribute4
               ,XRIL.interface_line_attribute5
               ,XRIL.interface_line_attribute7
               ,XRIL.interface_line_attribute8
               ,XRIL.interface_line_attribute12
               ,XRIL.interface_line_attribute13
               ,XRIL.interface_line_attribute14
               ,XRIL.interface_line_attribute15
               ,DECODE(XRID.account_class,'REC',NULL,XRIL.tax_code)
           --    ,DECODE(XRID.account_class,'REC',NULL,XRIL.interface_line_attribute9)
               ,XRIL.interface_line_attribute9
               ,DECODE(XRID.account_class,'REC',NULL,'S')
               ,XRIL.line_gdf_attr_category
               ,XRIL.line_gdf_attribute1
               ,XRIL.link_to_line_context
               ,XRIL.link_to_line_attribute2
               ,XRIL.link_to_line_attribute3
               ,XRIL.link_to_line_attribute4
               ,XRIL.link_to_line_attribute5
               ,XRIL.link_to_line_attribute7
               ,XRIL.link_to_line_attribute8
               ,XRIL.link_to_line_attribute9
               ,XRIL.link_to_line_attribute10
               ,XRIL.link_to_line_attribute12
               ,XRIL.link_to_line_attribute13
               ,XRIL.link_to_line_attribute14
               ,XRIL.link_to_line_attribute15
               ,XRID.code_combination_id
               ,XRID.segment1
               ,XRID.segment2
               ,XRID.segment3
               ,XRID.segment4
               ,XRID.segment5
               ,XRID.segment6
               ,XRID.segment7
               ,XRID.attribute6
               ,XRID.attribute7
               ,XRID.attribute8
               ,XRID.attribute10
               ,XRID.attribute11
      ORDER BY XRIL.orig_system_bill_customer_id
              ,TRUNC(XRIL.trx_date)
              ,XRIL.cust_trx_type_id
              ,DECODE(XRID.account_class,'REV',1,'TAX',2,'REC',3
                     ,XRID.account_class);

      TYPE t_bulk_create_pos_sum_tab IS TABLE OF lcu_create_pos_sum_inv%ROWTYPE
                INDEX BY BINARY_INTEGER;

      rec_tab t_bulk_create_pos_sum_tab;

   BEGIN
      gc_proc_name := '    CREATE_SUMMARY_INV';
      x_ret_code   := 0;

      ln_summary_inv_line_rev := 0;
      ln_summary_inv_line_tax := 0;
      ln_summary_inv_line_rec := 0;

      ------------------------------------------------------
      --  Get Next Trans Number for Summary Invoice from seq.
      ------------------------------------------------------
      BEGIN

         SELECT XX_AR_SUMMARY_TRANS_NUM_S.nextval
           INTO ln_trx_number
           FROM dual;

         gc_debug_loc  := 'Next Trans Number from ';
         gc_debug_stmt := 'XX_AR_SUMMARY_TRANS_NUM_S = '|| ln_trx_number;

         WRITE_LOG(gc_debug_flg, gc_proc_name ,gc_debug_loc,gc_debug_stmt);

      EXCEPTION
         WHEN OTHERS THEN
            gc_debug_loc  := 'Error occured getting nextval '
                                  ||'XX_AR_SUMMARY_TRANS_NUM_S ';

            gc_debug_stmt :=  SUBSTR(SQLERRM,1,249);
            WRITE_LOG('Y',gc_proc_name,gc_debug_loc,gc_debug_stmt);
            x_ret_code := 1;

      END;



      gc_debug_loc  := 'Open lcu_create_pos_sum_inv Cursor ';
      gc_debug_stmt := NULL;
      lc_tax_line_discount  := NULL;
      lc_tax_attr_updte_err := 'N';

      ln_rec_single_line_cnt := 0;  -- counter for only one REC line to exist
      ln_line_tran_seq       := 1;

      ----------------------------------------
      -- select to create POS invoice summary
      ----------------------------------------
      OPEN lcu_create_pos_sum_inv;
      LOOP
         FETCH lcu_create_pos_sum_inv
         BULK COLLECT INTO rec_tab LIMIT gn_bulk_limit;
         EXIT WHEN rec_tab.count = 0;

         FOR ln_disc_cnt IN 1.. rec_tab.count
         LOOP

            -------------------------------------------------------------
            -- capture discount flag and the OM transaction
            -- type for REC invoices distributions and reason code for tax
            -------------------------------------------------------------
            IF ln_line_tran_seq  = 1 then

               -- Capture REC variables
               lc_tax_line_discount    := rec_tab(ln_disc_cnt).discount;
               lc_line1_attribute2     := rec_tab(ln_disc_cnt).OM_TRANSACTION_TYPE;

               -- Capture TAX variables
               lc_tax_line_reason_code := rec_tab(ln_disc_cnt).reason_code;          -- added for defect 12289

            END IF;

            -------------------
            -- Sum total amounts
            ---------------------
            IF (rec_tab(ln_disc_cnt).line_type = 'LINE' AND
                rec_tab(ln_disc_cnt).account_class = 'REV') THEN
               -----------------------------------
               -- Adding to running totals for REV
               -----------------------------------
               ln_summary_inv_line_rev := ln_summary_inv_line_rev
                                        + rec_tab(ln_disc_cnt).amount;
            END IF;

            IF (rec_tab(ln_disc_cnt).line_type = 'TAX' AND
                rec_tab(ln_disc_cnt).account_class = 'TAX') THEN
               -----------------------------------
               -- Adding to running totals for TAX
               -----------------------------------
               ln_summary_inv_line_tax := ln_summary_inv_line_tax
                                        + rec_tab(ln_disc_cnt).amount;


               SET_TAX_ATTR_LINKS (gc_batch_source_name
                                  ,gn_org_id
                                  ,p_transaction_type
                                  ,p_cust_trx_type_id
                                  ,p_trx_date
                                  ,p_org_bill_cus_id
                                  ,p_org_bill_add_id
                                  ,p_org_ship_cus_id
                                  ,p_org_ship_add_id
                                  ,p_org_sold_cus_id
                                  ,lc_tax_attr1
                                  ,lc_tax_attr2
                                  ,lc_tax_attr3
                                  ,lc_tax_attr4
                                  ,lc_tax_attr5
                                  ,lc_tax_attr6
                                  ,lc_tax_attr7
                                  ,lc_tax_attr8
                                  ,lc_tax_attr9
                                  ,lc_tax_attr10
                                  ,lc_tax_attr11
                                  ,lc_tax_attr12
                                  ,lc_tax_attr13
                                  ,lc_tax_attr14
                                  ,lc_tax_attr15
                                  ,ln_ret_code1);


                  WRITE_LOG(gc_debug_flg, gc_proc_name ,'ln_ret_code1 =',ln_ret_code1);

                  IF ln_ret_code1 <> 0 THEN
                     lc_tax_attr_updte_err  := 'Y';
                  END IF;
            END IF;

            gc_proc_name := '    CREATE_SUMMARY_INV';

            ---------------------------------------
            -- Summing amout totals for Receivables
            ---------------------------------------
            ln_summary_inv_line_rec := ln_summary_inv_line_rev
                                     + ln_summary_inv_line_tax;

            ----------------------------------------
            --Creating Invoice Lines REVENUE OR TAX
            ----------------------------------------
            IF (rec_tab(ln_disc_cnt).line_type = 'LINE' AND
                rec_tab(ln_disc_cnt).account_class = 'REV')
                OR
               (rec_tab(ln_disc_cnt).line_type = 'TAX' AND
                rec_tab(ln_disc_cnt).account_class = 'TAX') THEN

               INSERT INTO XX_RA_INT_LINES_ALL
                           (interface_line_context,
                            interface_line_attribute1,
                            interface_line_attribute2,
                            interface_line_attribute3,
                            interface_line_attribute4,
                            interface_line_attribute5,
                            interface_line_attribute6,
                            interface_line_attribute7,
                            interface_line_attribute8,
                            interface_line_attribute9,
                            interface_line_attribute10,
                            interface_line_attribute11,
                            interface_line_attribute12,
                            interface_line_attribute13,
                            interface_line_attribute14,
                            interface_line_attribute15,
                            batch_source_name,
                            set_of_books_id,
                            line_type,
                            description,
                            currency_code,
                            cust_trx_type_id,
                            term_id,
                            orig_system_bill_customer_id,
                            orig_system_bill_address_id,
                            orig_system_ship_customer_id,
                            orig_system_ship_address_id,
                            orig_system_sold_customer_id,
                            conversion_type,
                            conversion_rate,
                            trx_date,
                            trx_number,
                            amount,
                            quantity,
                            quantity_ordered,
                            reason_code,
                            tax_code,
                            ship_date_actual,
                            waybill_number,
                            primary_salesrep_id,
                            inventory_item_id,
                            attribute_category,
                            header_attribute_category,
                            uom_code,
                            link_to_line_context,
                            link_to_line_attribute1,
                            link_to_line_attribute2,
                            link_to_line_attribute3,
                            link_to_line_attribute4,
                            link_to_line_attribute5,
                            link_to_line_attribute6,
                            link_to_line_attribute7,
                            link_to_line_attribute8,
                            link_to_line_attribute9,
                            link_to_line_attribute10,
                            link_to_line_attribute11,
                            link_to_line_attribute12,
                            link_to_line_attribute13,
                            link_to_line_attribute14,
                            link_to_line_attribute15,
                            tax_exempt_flag,
                            created_by,
                            creation_date,
                            last_updated_by,
                            last_update_date,
                            last_update_login,
                            org_id,
                            line_gdf_attr_category,
                            line_gdf_attribute1,
                            warehouse_id
                            ,amount_includes_tax_flag
                            )
                            VALUES
                            (
                            G_POS_ORDER_ENTRY,
                            ln_trx_number,
                            rec_tab(ln_disc_cnt).OM_TRANSACTION_TYPE,
                            G_SUMMARY,
                            rec_tab(ln_disc_cnt).interface_line_attribute4,
                            rec_tab(ln_disc_cnt).interface_line_attribute5,
                            decode(rec_tab(ln_disc_cnt).account_class,
                                         'REV',ln_line_tran_seq,1),             -- interface_line_attribute6,
                            rec_tab(ln_disc_cnt).interface_line_attribute7,
                            rec_tab(ln_disc_cnt).interface_line_attribute8,
                            rec_tab(ln_disc_cnt).tax_type_flag,
                            rec_tab(ln_disc_cnt).warehouse,
                            rec_tab(ln_disc_cnt).discount,
                            rec_tab(ln_disc_cnt).interface_line_attribute12,
                            rec_tab(ln_disc_cnt).interface_line_attribute13,
                            rec_tab(ln_disc_cnt).interface_line_attribute14,
                            rec_tab(ln_disc_cnt).interface_line_attribute15,
                            rec_tab(ln_disc_cnt).batch_source_name,
                            rec_tab(ln_disc_cnt).set_of_books_id,
                            rec_tab(ln_disc_cnt).line_type,
                            rec_tab(ln_disc_cnt).description,
                            rec_tab(ln_disc_cnt).currency_code,
                            rec_tab(ln_disc_cnt).cust_trx_type_id,
                            rec_tab(ln_disc_cnt).term_id,
                            rec_tab(ln_disc_cnt).orig_system_bill_customer_id,
                            rec_tab(ln_disc_cnt).orig_system_bill_address_id,
                            rec_tab(ln_disc_cnt).orig_system_ship_customer_id,
                            rec_tab(ln_disc_cnt).orig_system_ship_address_id,
                            rec_tab(ln_disc_cnt).orig_system_sold_customer_id,
                            rec_tab(ln_disc_cnt).conversion_type,
                            rec_tab(ln_disc_cnt).conversion_rate,
                            rec_tab(ln_disc_cnt).trx_date,
                            ln_trx_number,
                            rec_tab(ln_disc_cnt).amount,
                            rec_tab(ln_disc_cnt).quantity,
                            rec_tab(ln_disc_cnt).quantity,
--                            rec_tab(ln_disc_cnt).reason_code,                       -- removed for defect 12289
                            DECODE(rec_tab(ln_disc_cnt).account_class
                                           ,'TAX',lc_tax_line_reason_code
                                                 ,rec_tab(ln_disc_cnt).reason_code),  -- modified for defect 12289
                            rec_tab(ln_disc_cnt).tax_code,
                            rec_tab(ln_disc_cnt).ship_date_actual,
                            rec_tab(ln_disc_cnt).waybill_number,
                            rec_tab(ln_disc_cnt).primary_salesrep_id,
                            rec_tab(ln_disc_cnt).inventory_item_id,
                            p_acct_catgry,
                            p_acct_catgry,
                            rec_tab(ln_disc_cnt).uom_code,
                            decode(rec_tab(ln_disc_cnt).account_class
                                           ,'TAX',G_POS_ORDER_ENTRY,NULL),      --link_to_line_context
                             decode(rec_tab(ln_disc_cnt).account_class
                                             ,'TAX',lc_tax_attr1,NULL),         --link_to_line_attribute1
                             decode(rec_tab(ln_disc_cnt).account_class
                                    ,'TAX',lc_tax_attr2, NULL),                 --link_to_line_attribute2
                             decode(rec_tab(ln_disc_cnt).account_class
                                                     ,'TAX',G_SUMMARY,NULL),    --link_to_linr_attirbute3
                             decode(rec_tab(ln_disc_cnt).account_class
                                    ,'TAX',lc_tax_attr4,
                                 rec_tab(ln_disc_cnt).link_to_line_attribute4),
                             decode(rec_tab(ln_disc_cnt).account_class
                                    ,'TAX',lc_tax_attr5,
                                 rec_tab(ln_disc_cnt).link_to_line_attribute5),
                             decode(rec_tab(ln_disc_cnt).account_class,'TAX'
                                                          ,lc_tax_attr6 ,NULL),   --link_to_line_attribute6,
                             decode(rec_tab(ln_disc_cnt).account_class
                                    ,'TAX',lc_tax_attr7,
                                 rec_tab(ln_disc_cnt).link_to_line_attribute7),
                             decode(rec_tab(ln_disc_cnt).account_class
                                    ,'TAX',lc_tax_attr8,
                                 rec_tab(ln_disc_cnt).link_to_line_attribute8),
                             decode(rec_tab(ln_disc_cnt).account_class
                                    ,'TAX',lc_tax_attr9,
                                 rec_tab(ln_disc_cnt).link_to_line_attribute9),
                             decode(rec_tab(ln_disc_cnt).account_class
                                    ,'TAX',lc_tax_attr10,
                                 rec_tab(ln_disc_cnt).link_to_line_attribute10),--link_to_line_attribute10
                            decode(rec_tab(ln_disc_cnt).account_class
                                    ,'TAX',lc_tax_attr11, NULL),                --link_to_line_attribute11
                             decode(rec_tab(ln_disc_cnt).account_class
                                    ,'TAX',lc_tax_attr12,
                                 rec_tab(ln_disc_cnt).link_to_line_attribute12), --link_to_line_attribute12
                             decode(rec_tab(ln_disc_cnt).account_class
                                    ,'TAX',lc_tax_attr13,
                                 rec_tab(ln_disc_cnt).link_to_line_attribute13), --link_to_line_attribute13
                             decode(rec_tab(ln_disc_cnt).account_class
                                    ,'TAX',lc_tax_attr14,
                                 rec_tab(ln_disc_cnt).link_to_line_attribute14), --link_to_line_attribute14
                             decode(rec_tab(ln_disc_cnt).account_class
                                    ,'TAX',lc_tax_attr15,
                                 rec_tab(ln_disc_cnt).link_to_line_attribute15), --link_to_line_attribute15
                             rec_tab(ln_disc_cnt).tax_exempt_flag,
                            gn_user_id,                                         --Created_by
                            sysdate,                                            --Creation_date
                            gn_user_id,                                         --last_updated_by
                            sysdate,                                            --last_update_date
                            gn_login_id,                                        --last_update_login
                            rec_tab(ln_disc_cnt).org_id,
                            rec_tab(ln_disc_cnt).line_gdf_attr_category,
                            rec_tab(ln_disc_cnt).line_gdf_attribute1,
                            rec_tab(ln_disc_cnt).warehouse
                          ,decode(rec_tab(ln_disc_cnt).account_class
                                  ,'TAX','N',NULL)
                           );

                            ln_xx_sum_lines_inserted := SQL%ROWCOUNT;
                            gn_xx_sum_lines_inserted := gn_xx_sum_lines_inserted + ln_xx_sum_lines_inserted;

                            gc_debug_loc  := ' Inserting into'
                                           ||' XX_RA_INT_LINES_ALL'
                                           ||' Account class=> '
                                           ||rec_tab(ln_disc_cnt).account_class;

                            gc_debug_stmt := 'orig_system_bill_customer_id=> '
                                    ||rec_tab(ln_disc_cnt).orig_system_bill_customer_id
                                    ||'Sum Amt=> '||rec_tab(ln_disc_cnt).amount
                                    ||' Trx_number = '|| ln_trx_number;

                            WRITE_LOG(gc_debug_flg, gc_proc_name ,gc_debug_loc
                                     ,gc_debug_stmt);


               -----------------------------------------------------
               -- Create Distributions for REVENUE and TAX
               -----------------------------------------------------
               INSERT INTO xx_ra_int_distributions_all
                          (
                          interface_line_context,
                          interface_line_attribute1,
                          interface_line_attribute2,
                          interface_line_attribute3,
                          interface_line_attribute4,
                          interface_line_attribute5,
                          interface_line_attribute6,
                          interface_line_attribute7,
                          interface_line_attribute8,
                          interface_line_attribute9,
                          interface_line_attribute10,
                          interface_line_attribute11,
                          interface_line_attribute12,
                          interface_line_attribute13,
                          interface_line_attribute14,
                          interface_line_attribute15,
                          account_class,
                          amount,
                          percent,
                          code_combination_id,
                          segment1,
                          segment2,
                          segment3,
                          segment4,
                          segment5,
                          segment6,
                          segment7,
                          ATTRIBUTE_CATEGORY,
                          attribute6,
                          attribute7,
                          attribute8,
                          attribute9,
                          attribute10,
                          attribute11,
                          org_id,
                          created_by,
                          creation_date,
                          last_updated_by,
                          last_update_date,
                          last_update_login
                          )
                          VALUES
                          (
                          G_POS_ORDER_ENTRY,
                          ln_trx_number,
                          rec_tab(ln_disc_cnt).OM_TRANSACTION_TYPE,
                          G_SUMMARY,
                          rec_tab(ln_disc_cnt).interface_line_attribute4,
                          rec_tab(ln_disc_cnt).interface_line_attribute5,
                          decode(rec_tab(ln_disc_cnt).account_class,
                                     'REV',ln_line_tran_seq,1),                 --interface_line_attribute6
                          rec_tab(ln_disc_cnt).interface_line_attribute7,
                          rec_tab(ln_disc_cnt).interface_line_attribute8,
                          rec_tab(ln_disc_cnt).tax_type_flag,
                          rec_tab(ln_disc_cnt).warehouse,
                          rec_tab(ln_disc_cnt).discount,
                          rec_tab(ln_disc_cnt).interface_line_attribute12,
                          rec_tab(ln_disc_cnt).interface_line_attribute13,
                          rec_tab(ln_disc_cnt).interface_line_attribute14,
                          rec_tab(ln_disc_cnt).interface_line_attribute15,
                          rec_tab(ln_disc_cnt).account_class,
                          rec_tab(ln_disc_cnt).amount,
                          rec_tab(ln_disc_cnt).percent,
                          rec_tab(ln_disc_cnt).code_combination_id,
                          rec_tab(ln_disc_cnt).segment1,
                          rec_tab(ln_disc_cnt).segment2,
                          rec_tab(ln_disc_cnt).segment3,
                          rec_tab(ln_disc_cnt).segment4,
                          rec_tab(ln_disc_cnt).segment5,
                          rec_tab(ln_disc_cnt).segment6,
                          rec_tab(ln_disc_cnt).segment7,
                          DECODE(rec_tab(ln_disc_cnt).account_class
                                 ,'REC',NULL,p_acct_catgry),                    --Change for defect 12169 added decode
                          rec_tab(ln_disc_cnt).cogs_flag,
                          rec_tab(ln_disc_cnt).cogs_acct,
                          rec_tab(ln_disc_cnt).cogs_inv_liab_acct,
                          rec_tab(ln_disc_cnt).avg_net_cost,
                          rec_tab(ln_disc_cnt).cogs_consign_acct,
                          rec_tab(ln_disc_cnt).sales_attributes,
                          rec_tab(ln_disc_cnt).org_id,
                          gn_user_id,                                           --Created_by
                          SYSDATE,                                              --Creation_date
                          gn_user_id,                                           --last_updated_by
                          SYSDATE,                                              --last_update_date
                          gn_login_id                                           --last_update_login
                          );

                          ln_xx_sum_dists_inserted := SQL%ROWCOUNT;
                          gn_xx_sum_dists_inserted := gn_xx_sum_dists_inserted + ln_xx_sum_dists_inserted;

                          gc_debug_loc  := ' Inserting into'
                                           ||' xx_ra_int_distributions_all'
                                           ||' Account class=> '
                                           ||rec_tab(ln_disc_cnt).account_class;

                          gc_debug_stmt := 'orig_system_bill_customer_id=> '
                                    ||rec_tab(ln_disc_cnt).orig_system_bill_customer_id
                                    ||'Sum Amt=> '||rec_tab(ln_disc_cnt).amount
                                    ||' Trx_number = '|| ln_trx_number;

                          WRITE_LOG(gc_debug_flg, gc_proc_name ,gc_debug_loc
                                     ,gc_debug_stmt);

            END IF;

            ------------------------------------------
            -- Create Distributions for RECEIVABLE
            ------------------------------------------
            IF (rec_tab(ln_disc_cnt).line_type = 'LINE' AND
                rec_tab(ln_disc_cnt).account_class = 'REC')  THEN

               ln_rec_single_line_cnt := ln_rec_single_line_cnt + 1;

               IF ln_rec_single_line_cnt = 1 THEN

                  INSERT INTO xx_ra_int_distributions_all
                                    (
                                    interface_line_context,
                                    interface_line_attribute1,
                                    interface_line_attribute2,
                                    interface_line_attribute3,
                                    interface_line_attribute4,
                                    interface_line_attribute5,
                                    interface_line_attribute6,
                                    interface_line_attribute7,
                                    interface_line_attribute8,
                                    interface_line_attribute9,
                                    interface_line_attribute10,
                                    interface_line_attribute11,
                                    interface_line_attribute12,
                                    interface_line_attribute13,
                                    interface_line_attribute14,
                                    interface_line_attribute15,
                                    account_class,
                                    amount,
                                    percent,
                                    code_combination_id,
                                    segment1,
                                    segment2,
                                    segment3,
                                    segment4,
                                    segment5,
                                    segment6,
                                    segment7,
                                    ATTRIBUTE_CATEGORY,
                                    attribute6,
                                    attribute7,
                                    attribute8,
                                    attribute9,
                                    attribute10,
                                    attribute11,
                                    org_id,
                                    created_by,
                                    creation_date,
                                    last_updated_by,
                                    last_update_date,
                                    last_update_login
                                    )
                                    VALUES
                                    (
                                    G_POS_ORDER_ENTRY,
                                    ln_trx_number,
                                    lc_line1_attribute2,                        -- value from first REV line retrieved
                                    G_SUMMARY,
                                    rec_tab(ln_disc_cnt).interface_line_attribute4,
                                    rec_tab(ln_disc_cnt).interface_line_attribute5,
                                    decode(rec_tab(ln_disc_cnt).account_class,
                                               'REV',ln_line_tran_seq,1),                 --interface_line_attribute6
                                    rec_tab(ln_disc_cnt).interface_line_attribute7,
                                    rec_tab(ln_disc_cnt).interface_line_attribute8,
                                    rec_tab(ln_disc_cnt).tax_type_flag,
                                    rec_tab(ln_disc_cnt).warehouse,
                                    lc_tax_line_discount,                        -- value from first REV line retrieved
                                    rec_tab(ln_disc_cnt).interface_line_attribute12,
                                    rec_tab(ln_disc_cnt).interface_line_attribute13,
                                    rec_tab(ln_disc_cnt).interface_line_attribute14,
                                    rec_tab(ln_disc_cnt).interface_line_attribute15,
                                    rec_tab(ln_disc_cnt).account_class,
                                    rec_tab(ln_disc_cnt).amount,
                                    rec_tab(ln_disc_cnt).percent,
                                    rec_tab(ln_disc_cnt).code_combination_id,
                                    rec_tab(ln_disc_cnt).segment1,
                                    rec_tab(ln_disc_cnt).segment2,
                                    rec_tab(ln_disc_cnt).segment3,
                                    rec_tab(ln_disc_cnt).segment4,
                                    rec_tab(ln_disc_cnt).segment5,
                                    rec_tab(ln_disc_cnt).segment6,
                                    rec_tab(ln_disc_cnt).segment7,
                                    DECODE(rec_tab(ln_disc_cnt).account_class
                                           ,'REC',NULL,p_acct_catgry),                    --Change for defect 12169 added decode
                                    rec_tab(ln_disc_cnt).cogs_flag,
                                    rec_tab(ln_disc_cnt).cogs_acct,
                                    rec_tab(ln_disc_cnt).cogs_inv_liab_acct,
                                    rec_tab(ln_disc_cnt).avg_net_cost,
                                    rec_tab(ln_disc_cnt).cogs_consign_acct,
                                    rec_tab(ln_disc_cnt).sales_attributes,
                                    rec_tab(ln_disc_cnt).org_id,
                                    gn_user_id,                                           --Created_by
                                    sysdate,                                              --Creation_date
                                    gn_user_id,                                           --last_updated_by
                                    sysdate,                                              --last_update_date
                                    gn_login_id                                           --last_update_login
                                    );

                          ln_xx_sum_dists_inserted := SQL%ROWCOUNT;
                          gn_xx_sum_dists_inserted := gn_xx_sum_dists_inserted + ln_xx_sum_dists_inserted;

                          gc_debug_loc  := ' Inserting into'
                                           ||' xx_ra_int_distributions_all'
                                           ||' Account class=> '
                                           ||rec_tab(ln_disc_cnt).account_class;

                          gc_debug_stmt := 'orig_system_bill_customer_id=> '
                                    ||rec_tab(ln_disc_cnt).orig_system_bill_customer_id
                                    ||'Sum Amt=> '||rec_tab(ln_disc_cnt).amount
                                    ||' Trx_number = '|| ln_trx_number;

                          WRITE_LOG(gc_debug_flg, gc_proc_name ,gc_debug_loc
                                     ,gc_debug_stmt);

               END IF;

            END IF;


            --Start - Commented for Defect31661
            ------------------------------------
            -- CREATE SALES CREDIT (FOR REVENUE)
            ------------------------------------
	    /*
            IF (rec_tab(ln_disc_cnt).line_type = 'LINE' AND
                rec_tab(ln_disc_cnt).account_class = 'REV') THEN

               INSERT INTO xx_ra_int_salescredits_all
                             (
                              interface_line_context,
                              interface_line_attribute1,
                              interface_line_attribute2,
                              interface_line_attribute3,
                              interface_line_attribute4,
                              interface_line_attribute5,
                              interface_line_attribute6,                        --
                              interface_line_attribute7,
                              interface_line_attribute8,
                              interface_line_attribute9,
                              interface_line_attribute10,
                              interface_line_attribute11,
                              interface_line_attribute12,
                              interface_line_attribute13,
                              interface_line_attribute14,
                              interface_line_attribute15,
                              org_id,
                              salesrep_id,
                              sales_credit_type_id,
                              sales_credit_percent_split,
                              created_by,
                              creation_date,
                              last_updated_by,
                              last_update_date,
                              last_update_login
                              )
                             VALUES
                             (
                              G_POS_ORDER_ENTRY,
                              ln_trx_number,
                              rec_tab(ln_disc_cnt).OM_TRANSACTION_TYPE,
                              G_SUMMARY,
                              rec_tab(ln_disc_cnt).interface_line_attribute4,
                              rec_tab(ln_disc_cnt).interface_line_attribute5,
                              ln_line_tran_seq,                                 --interface_line_attribute6
                              rec_tab(ln_disc_cnt).interface_line_attribute7,
                              rec_tab(ln_disc_cnt).interface_line_attribute8,
                              rec_tab(ln_disc_cnt).tax_type_flag,
                              rec_tab(ln_disc_cnt).warehouse,
                              rec_tab(ln_disc_cnt).discount,
                              rec_tab(ln_disc_cnt).interface_line_attribute12,
                              rec_tab(ln_disc_cnt).interface_line_attribute13,
                              rec_tab(ln_disc_cnt).interface_line_attribute14,
                              rec_tab(ln_disc_cnt).interface_line_attribute15,
                              rec_tab(ln_disc_cnt).org_id,
                              rec_tab(ln_disc_cnt).primary_salesrep_id,
                              '1',
                              '100',
                              gn_user_id,                                           --Created_by
                              SYSDATE,                                              --Creation_date
                              gn_user_id,                                           --last_updated_by
                              SYSDATE,                                              --last_update_date
                              gn_login_id                                          --last_update_login
                             );

                            ln_xx_sum_sales_inserted := SQL%ROWCOUNT;
                            gn_xx_sum_sales_inserted := gn_xx_sum_sales_inserted + ln_xx_sum_sales_inserted;

                            gc_debug_loc  := '  Inserting into'
                                           ||' xx_ra_int_salescredits_all'
                                           ||' Account class=> '
                                           ||rec_tab(ln_disc_cnt).account_class;

                            gc_debug_stmt := 'orig_system_bill_customer_id=> '
                                    ||rec_tab(ln_disc_cnt).orig_system_bill_customer_id
                                    ||'Sum Amt=> '||rec_tab(ln_disc_cnt).amount
                                    ||' Trx_number = '|| ln_trx_number;

                            WRITE_LOG(gc_debug_flg, gc_proc_name ,gc_debug_loc
                                     ,gc_debug_stmt);
            END IF;
	    */
	    --End - Commented for Defect31661

            ln_line_tran_seq := ln_line_tran_seq +1;
            -------------------------------------------
            -- Assign value to error messeage variables
            -------------------------------------------
            lc_orig_sys_cus_id := rec_tab(ln_disc_cnt).orig_system_bill_customer_id;
            ln_amount_display  := rec_tab(ln_disc_cnt).amount;
         END LOOP;

         lc_sum_tot_err_found := 'N';

         --------------------------------------------------------
         --Verify Summarized Lines Amts Equal Summarized Inv Amts
         --------------------------------------------------------
         IF (p_summary_rev - ln_summary_inv_line_rev <> 0) THEN

            lc_sum_tot_err_found := 'Y';

            gc_debug_loc  := 'Error Revenues Summarized Lines '||
                             'Amts not equal Sum Inv Amts for';

            gc_debug_stmt := 'orig_system_bill_customer_id=> '
                             ||lc_orig_sys_cus_id||'Sum Amt=> '||ln_amount_display;

            WRITE_LOG('Y',gc_proc_name,gc_debug_loc,gc_debug_stmt);

         END IF;

         IF (p_summary_tax - ln_summary_inv_line_tax <> 0) THEN

            lc_sum_tot_err_found := 'Y';

            gc_debug_loc  := 'Error TAX Summarized Lines '||
                             'Amts not equal Sum Inv Amts for';

            gc_debug_stmt := 'orig_system_bill_customer_id=> '
                            ||lc_orig_sys_cus_id||'Sum Amt=> '||ln_amount_display;

            WRITE_LOG('Y',gc_proc_name,gc_debug_loc,gc_debug_stmt);

         END IF;

         IF (p_summary_rec - (ln_summary_inv_line_tax
                               + ln_summary_inv_line_rev ) <> 0) THEN

            lc_sum_tot_err_found := 'Y';

            gc_debug_loc  := 'Error Receivable summarized Lines '
                                      ||'Amts not equal Sum Inv Amts ';

            gc_debug_stmt := 'orig_system_bill_customer_id=> '
                             ||lc_orig_sys_cus_id
                             ||'Sum Amt=> '||ln_amount_display;

            WRITE_LOG('Y',gc_proc_name,gc_debug_loc,gc_debug_stmt);

         END IF;

         IF lc_sum_tot_err_found  = 'Y' OR
            lc_tax_attr_updte_err = 'Y' OR
            ln_rec_single_line_cnt <> 1 THEN

            -------------------------------------------------------
            -- Print Output header record for invoice not summarized
            -------------------------------------------------------
            IF gc_inv_not_sum_header = 'Y'  THEN
               WRITE_OUTPUT ('INV_NOT_SUM');
               gc_inv_not_sum_header := 'N';
            END IF;

            ---------------------------------------------
            -- Get Store detail info
            ---------------------------------------------
            BEGIN

               SELECT NVL(account_name,'N/A')
                 INTO lc_store_name
                 FROM hz_cust_accounts
                WHERE cust_account_id = p_org_bill_cus_id;

            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  gc_debug_loc := '    No data found for Store detail info!!! '
                                   ||'cust_account_id = '||p_org_bill_cus_id;
                  FND_FILE.PUT_LINE(FND_FILE.LOG,gc_debug_loc);

               WHEN OTHERS THEN
                  gc_debug_loc := '   Other: Error getting Store detail info!!! '
                                  ||'cust_account_id = '||p_org_bill_cus_id;

                  FND_FILE.PUT_LINE(FND_FILE.LOG,gc_debug_loc ||SUBSTR(SQLERRM,1,150));
            END;

            -------------------------------------------------
            -- Write error output for records not summarized
            -------------------------------------------------
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                               '   '||to_char(p_trx_date, 'mm/dd/yyyy')
                               ||'   '||SUBSTR(RPAD(lc_store_name,35),1,36)
                               ||' '||SUBSTR(RPAD(p_transaction_type,35),1,25)
                               ||' '||SUBSTR(RPAD(to_char(ln_line_tran_seq,'9,999,999,999'),35),1,20)
                               ||' '||SUBSTR(RPAD(to_char( ln_summary_inv_line_tax + ln_summary_inv_line_rev
                                             ,'$9,999,999,999.00'),35),1,30)
                              );


            ----------------------------------
            -- Writing detail info to log file
            ----------------------------------
            WRITE_LOG('Y',NULL,NULL,'batch_source_name            = ' ||gc_batch_source_name);
            WRITE_LOG('Y',NULL,NULL,'org_id                       = ' ||gn_org_id);
            WRITE_LOG('Y',NULL,NULL,'cust_trx_type_id             = ' ||p_cust_trx_type_id);
            WRITE_LOG('Y',NULL,NULL,'trx_date                     = ' || p_trx_date );
            WRITE_LOG('Y',NULL,NULL,'orig_system_bill_customer_id = ' ||p_org_bill_cus_id);
            WRITE_LOG('Y',NULL,NULL,'orig_system_bill_address_id  = ' || p_org_bill_add_id);

            ----------------------------------------------------
            -- Writing error log file for records not summarized
            ----------------------------------------------------
            IF lc_sum_tot_err_found = 'Y' THEN
               gc_debug_loc  := 'Error: Summary Total did not match! ';

               gc_debug_stmt := ' Trx_number = '|| ln_trx_number
                                          || 'Transaction will be rolled back!';
               WRITE_LOG('Y',gc_proc_name,gc_debug_loc,gc_debug_stmt);

            END IF;

            ----------------------------------------
            -- Zero-REC lines found writing log file
            ----------------------------------------
            IF ln_rec_single_line_cnt  = 0  THEN

               gc_debug_loc  := 'Error: Summary REC line  '
                                ||'does not exist for:  ';

               gc_debug_stmt := ' Trx_number = '|| ln_trx_number
                                || 'Transaction will be rolled back!';
               WRITE_LOG('Y',gc_proc_name,gc_debug_loc,gc_debug_stmt);

            END IF;

            ---------------------------------------
            -- Multi-REC lines found writing log file
            ---------------------------------------
            IF ln_rec_single_line_cnt  > 1  THEN

               gc_debug_loc  := ' Error: Multiple Summary REC line';
               gc_debug_stmt :=  ' Multiple REC records found!';
               WRITE_LOG('Y',gc_proc_name,gc_debug_loc,gc_debug_stmt);

            END IF;

            --------------------------------------
            -- Writing Tax Attribute update error
            --------------------------------------
            IF lc_tax_attr_updte_err = 'Y'  THEN

               gc_debug_loc  := 'Error: While setting tax attributes ';

               gc_debug_stmt := ' Trx_number = '|| ln_trx_number
                                          || ' will be rolled back!';
               WRITE_LOG('Y',gc_proc_name,gc_debug_loc,gc_debug_stmt);

            END IF;

            x_ret_code := 1;

            ROLLBACK;

            ------------------------------------------------
            -- Update the INTERFACE_STATUS column to 'ERROR'
            ------------------------------------------------
            UPDATE xx_ra_int_lines_all  XRILA
               SET XRILA.interface_status             = 'E'
             WHERE XRILA.batch_source_name            = gc_batch_source_name
               AND XRILA.org_id                       = gn_org_id
               AND XRILA.cust_trx_type_id             = p_cust_trx_type_id
               AND XRILA.trx_date                     = TRUNC(p_trx_date)
               AND XRILA.orig_system_bill_customer_id = p_org_bill_cus_id
               AND XRILA.orig_system_bill_address_id  = p_org_bill_add_id
               AND XRILA.orig_system_ship_customer_id = p_org_ship_cus_id
               AND XRILA.orig_system_ship_address_id  = p_org_ship_add_id
               AND XRILA.orig_system_sold_customer_id = p_org_sold_cus_id
               AND XRILA.interface_line_context       = G_ORDER_ENTRY
               AND XRILA.interface_status             IS NULL;

            ln_xx_detailed_inv_errors := SQL%ROWCOUNT;
            gn_xx_detailed_inv_errors := gn_xx_detailed_inv_errors + ln_xx_detailed_inv_errors;

            COMMIT;

         ELSE

            -----------------------------------------
            -- Summary trx where successfully created
            -----------------------------------------
            -------------------------
            -- Adding to Grand totals
            -------------------------
            gn_sum_inv_line_rev_gt := gn_sum_inv_line_rev_gt
                                      + ln_summary_inv_line_rev;

            gn_sum_inv_line_tax_gt := gn_sum_inv_line_tax_gt
                                      + ln_summary_inv_line_tax;

            gn_sum_inv_line_rec_gt := gn_sum_inv_line_rec_gt
                                      + ln_summary_inv_line_rec;

            -----------------------------------------------------
            -- Update detailed invs with SUMMARY transaction num
            -----------------------------------------------------
            gc_debug_loc  := 'Updating xx_ra_int_lines_all  ';
            gc_debug_stmt := 'detail invoice related_trx_number '||
                                     'with SUMMARY trx_number  ';

            WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt );

            UPDATE xx_ra_int_lines_all   XRILA
               SET XRILA.related_trx_number           = ln_trx_number
             WHERE XRILA.batch_source_name            = gc_batch_source_name
               AND XRILA.org_id                       = gn_org_id
               AND XRILA.cust_trx_type_id             = p_cust_trx_type_id
               AND XRILA.trx_date                     = TRUNC(p_trx_date)
               AND XRILA.orig_system_bill_customer_id = p_org_bill_cus_id
               AND XRILA.orig_system_bill_address_id  = p_org_bill_add_id
               AND XRILA.orig_system_ship_customer_id = p_org_ship_cus_id
               AND XRILA.orig_system_ship_address_id  = p_org_ship_add_id
               AND XRILA.orig_system_sold_customer_id = p_org_sold_cus_id
               AND XRILA.interface_line_context       = G_ORDER_ENTRY
               AND XRILA.interface_status             IS NULL;

            ln_xx_detailed_inv_linked := SQL%ROWCOUNT;
            gn_xx_detailed_inv_linked := gn_xx_detailed_inv_linked + ln_xx_detailed_inv_linked;

            gn_xx_sum_inv_inserted := gn_xx_sum_inv_inserted + 1;
            COMMIT;

         END IF ;

         -------------------------------------------
         -- Reset summary count for next transaction
         -------------------------------------------
         ln_summary_inv_line_rev := 0;
         ln_summary_inv_line_tax := 0;
         ln_summary_inv_line_rec := 0;

      END LOOP;
      CLOSE lcu_create_pos_sum_inv;

   EXCEPTION
      WHEN OTHERS THEN
         gc_proc_name  := '    CREATE_SUMMARY_INV';
         gc_debug_stmt :=  SUBSTR(SQLERRM,1,249);
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
         x_ret_code := 2;

   END CREATE_SUMMARY_INV;

   -- +=====================================================================+
   -- | Name : SELECT_SUMMARY_INV                                           |
   -- | Description :  Procedure to select transaction that will be         |
   -- |                summarized                                           |
   -- | Parameters   ,gc_batch_source_name  ,gn_org_id                      |
   -- | Returns :  x_ret_code                                               |
   -- +=====================================================================+
   PROCEDURE SELECT_SUMMARY_INV (x_ret_code  OUT  NUMBER)
   AS
      lc_trans_flg   VARCHAR2(1);
      lc_acct_catgry xx_fin_translatevalues.target_value2%type;
      lc_operating_unit  hr_all_organization_units.name%type;

      ln_sum_rev_gt         NUMBER;
      ln_sum_tax_gt         NUMBER;
      ln_sum_rec_gt         NUMBER;
      ln_candidate_inv_cnt  NUMBER := 0;

      ln_warn_err           NUMBER;
      lc_rec_found_flg      VARCHAR2(1);

      INVALID_BATCH_SOURCE  EXCEPTION;
      NO_RECORDS_EXIST      EXCEPTION;

      ----------------------------------------------------------
      --Cursor to select pos invoices that need to be summarized
      ----------------------------------------------------------
      CURSOR lcu_select_pos_sum_inv
      IS
          SELECT XCUST.batch_source_name
                ,XCUST.set_of_books_id
                ,XCUST.org_id
                ,XCUST.description                               AR_TRANSACTION_TYPE
                ,XCUST.cust_trx_type_id
                ,XCUST.trx_date
                ,XCUST.orig_system_bill_customer_id
                ,XCUST.orig_system_bill_address_id
                ,XCUST.orig_system_ship_customer_id
                ,XCUST.orig_system_ship_address_id
                ,XCUST.orig_system_sold_customer_id
                ,NVL(SUM(XCUST.SUMMARY_INV_REV),0)       SUMMARY_REV
                ,NVL(SUM(XCUST.SUMMARY_INV_TAX),0)       SUMMARY_TAX
                ,NVL(SUM(XCUST.SUMMARY_INV_REC),0)       SUMMARY_REC
           FROM (SELECT XRILA.batch_source_name
                       ,XRILA.set_of_books_id
                       ,XRILA.org_id
                       ,RCTA.description
                       ,XRILA.cust_trx_type_id
                       ,TRUNC(XRILA.trx_date)                  TRX_DATE
                       ,XRILA.orig_system_bill_customer_id
                       ,XRILA.orig_system_bill_address_id
                       ,XRILA.orig_system_ship_customer_id
                       ,XRILA.orig_system_ship_address_id
                       ,XRILA.orig_system_sold_customer_id
                       ,DECODE(XRILA.line_type,'LINE',XRILA.amount)  SUMMARY_INV_REV
                       ,DECODE(XRILA.line_type,'TAX' ,XRILA.amount)  SUMMARY_INV_TAX
                       ,XRILA.amount                                SUMMARY_INV_REC
                   FROM xx_ra_int_lines_all     XRILA
                       ,ra_cust_trx_types_all   RCTA
                  WHERE XRILA.batch_source_name            = gc_batch_source_name
                    AND XRILA.org_id                       = gn_org_id
                    AND XRILA.interface_line_context       = G_ORDER_ENTRY
                    AND XRILA.orig_system_bill_customer_id BETWEEN gn_cust_id_low
                                                               AND gn_cust_id_high
                    AND XRILA.cust_trx_type_id             = RCTA.cust_trx_type_id
                    AND XRILA.interface_status             IS NULL
                    ) XCUST
              GROUP BY XCUST.batch_source_name
                      ,XCUST.set_of_books_id
                      ,XCUST.org_id
                      ,XCUST.description
                      ,XCUST.cust_trx_type_id
                      ,XCUST.trx_date
                      ,XCUST.orig_system_bill_customer_id
                      ,XCUST.orig_system_bill_address_id
                      ,XCUST.orig_system_ship_customer_id
                      ,XCUST.orig_system_ship_address_id
                      ,XCUST.orig_system_sold_customer_id
              ORDER BY XCUST.orig_system_bill_customer_id
                      ,XCUST.trx_date
                      ,XCUST.description DESC;

         TYPE t_bulk_select_pos_sum_tab IS TABLE OF lcu_select_pos_sum_inv%ROWTYPE
                INDEX BY BINARY_INTEGER;

         rec_tab t_bulk_select_pos_sum_tab;

   BEGIN
      gc_proc_name := '    SELECT_SUMMARY_INV ';
      x_ret_code  := 0;
      ln_warn_err := 0;
      lc_rec_found_flg := 'N';

      WRITE_LOG(gc_debug_flg, NULL ,'  Getting translation values gc_batch_source_name = '
                               ||gc_batch_source_name,NULL);

      INV_DEFAULT_LOOKUPS (x_ret_code
                         ,lc_trans_flg
                         ,lc_acct_catgry
                         ,'N');

      IF x_ret_code <> 0 THEN

         RAISE  INVALID_BATCH_SOURCE;

      END IF;

      ----------------------------------------------------------
      -- Main select of POS invoices that need to be summarized
      ----------------------------------------------------------
      OPEN lcu_select_pos_sum_inv;
      LOOP
         FETCH lcu_select_pos_sum_inv
         BULK COLLECT INTO rec_tab LIMIT gn_bulk_limit;
         EXIT WHEN rec_tab.count = 0;

         lc_rec_found_flg := 'Y';

         FOR ln_disc_cnt IN 1.. rec_tab.count
         LOOP
            ln_candidate_inv_cnt := ln_candidate_inv_cnt + 1;

            ------------------------------------------------------
            -- Get translation val if gc_batch_source_name is null
            ------------------------------------------------------
            IF gc_batch_source_name IS NULL THEN

               INV_DEFAULT_LOOKUPS (x_ret_code
                                   ,lc_trans_flg
                                   ,lc_acct_catgry
                                   ,'N');

               IF x_ret_code <> 0 THEN
                  RAISE  INVALID_BATCH_SOURCE;
               END IF;
            END IF;

            gc_debug_loc  := '   summary invoices have been identified and';
            gc_debug_stmt :=' starting summary invoice creation';
            WRITE_LOG(gc_debug_flg,gc_proc_name ,gc_debug_loc, gc_debug_stmt);

            CREATE_SUMMARY_INV (ln_warn_err
                               ,rec_tab(ln_disc_cnt).batch_source_name
                               ,rec_tab(ln_disc_cnt).set_of_books_id
                               ,rec_tab(ln_disc_cnt).org_id
                               ,rec_tab(ln_disc_cnt).AR_TRANSACTION_TYPE
                               ,rec_tab(ln_disc_cnt).cust_trx_type_id
                               ,rec_tab(ln_disc_cnt).trx_date
                               ,rec_tab(ln_disc_cnt).orig_system_bill_customer_id
                               ,rec_tab(ln_disc_cnt).orig_system_bill_address_id
                               ,rec_tab(ln_disc_cnt).orig_system_ship_customer_id
                               ,rec_tab(ln_disc_cnt).orig_system_ship_address_id
                               ,rec_tab(ln_disc_cnt).orig_system_sold_customer_id
                               ,rec_tab(ln_disc_cnt).SUMMARY_REV
                               ,rec_tab(ln_disc_cnt).SUMMARY_TAX
                               ,rec_tab(ln_disc_cnt).SUMMARY_REC
                               ,lc_acct_catgry);

            IF ln_warn_err > 0 THEN

               IF ln_warn_err  = 1  THEN
                  gn_create_summary_warning :=  ln_warn_err;
               ELSE
                  x_ret_code := ln_warn_err;
               END IF;
            END IF;

         END LOOP;

      END LOOP;
      CLOSE lcu_select_pos_sum_inv;

      IF x_ret_code  > 0  THEN
         gc_debug_stmt :=  gc_debug_loc
                           ||'Please review output of concurrent program '
                           || 'Request ID: '|| gn_request_id ;
         gc_debug_loc  := 'AR POS DATA SUMMARIZATION:ERROR';
         ----------------
         -- Sending email
         ----------------
         SEND_EMAIL(gc_concat_email, gc_debug_loc ,gc_debug_stmt);

      END IF;

      IF lc_rec_found_flg = 'N' THEN

         gc_debug_loc  := '    Warning: No Records found ';
         gc_debug_stmt := ' to be summarized, Exiting procedure ';

         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt);
         x_ret_code := 1;

      END IF;

      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
      WRITE_LOG('Y',gc_proc_name ,'    Candidate Summary Invoices Available for Summarization      ',ln_candidate_inv_cnt);
      WRITE_LOG('Y',gc_proc_name ,'    Summary Invoices Created                                    ',gn_xx_sum_inv_inserted);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
      WRITE_LOG('Y',gc_proc_name ,'    Summary Invoices - Lines Created                            ',gn_xx_sum_lines_inserted);
      WRITE_LOG('Y',gc_proc_name ,'    Summary Invoices - Distributions Created                    ',gn_xx_sum_dists_inserted);
      WRITE_LOG('Y',gc_proc_name ,'    Summary Invoices - Sales Credits Created                    ',gn_xx_sum_sales_inserted);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
      WRITE_LOG('Y',gc_proc_name ,'    Detailed Invoice Lines Updated/Linked to Summary Invoices   ',gn_xx_detailed_inv_linked);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
      WRITE_LOG('Y',gc_proc_name ,'    Detailed Invoice Lines Updated to Error (interface_status=E)',gn_xx_detailed_inv_errors);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

   EXCEPTION
      WHEN INVALID_BATCH_SOURCE THEN
         gc_proc_name := '    SELECT_SUMMARY_INV ';
         gc_debug_stmt := 'gc_batch_source_name ='
                           || gc_batch_source_name
                           ||' mising values in translation table'
                           ||' OD_AR_INVOICING_DEFAULTS';
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
         x_ret_code := 2;

      WHEN OTHERS THEN
         gc_proc_name := '    SELECT_SUMMARY_INV ';
         gc_debug_stmt :=  SUBSTR(SQLERRM,1,249);
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
         x_ret_code := 1;

   END SELECT_SUMMARY_INV;

   -- +=====================================================================+
   -- | NAME       : SUMMARIZE_STORES                                       |
   -- |                                                                     |
   -- | DESCRIPTION: Release 11.3 AR Sales Data Redesign - AR Track         |
   -- |              Main calling program: E80 called from OD: AR Summarize |
   -- |              POS Sales                                              |
   -- |                                                                     |
   -- | PARAMETERS :                                                        |
   -- |                                                                     |
   -- | RETURNS    :                                                        |
   -- |                                                                     |
   -- |                                                                     |
   -- +=====================================================================+
   PROCEDURE SUMMARIZE_STORES (x_err_buff             OUT  VARCHAR2
                              ,x_ret_code             OUT  NUMBER
                              ,p_process_date          IN  VARCHAR2
                              ,p_batch_source_name     IN  VARCHAR2
                              ,p_org_id                IN  NUMBER
                              ,p_autoinv_thread_count  IN  NUMBER
                              ,p_email_address         IN  VARCHAR2
                              ,p_cust_id_low           IN  NUMBER
                              ,p_cust_id_high          IN  NUMBER
                              ,p_wave_number           IN  NUMBER
                              ,p_display_log_details   IN  VARCHAR2
                              ,p_bulk_limit            IN  NUMBER)

   AS
      ln_ret_code                NUMBER;
      lc_dummy_val               VARCHAR2(1);
      lc_dummy_val2              VARCHAR2(1);
      lc_ai_return_code          NUMBER      := 0;
      ln_del_ret_code            NUMBER      := 0;

      INVALID_BATCH_SOURCE       EXCEPTION;
      SELECT_SUMMARY_WARNING     EXCEPTION;
      CREATE_SUMMARY_WARNING     EXCEPTION;
      INST_RA_TABLES_ERROR       EXCEPTION;
      MULTI_SUMMARY_TRX_ERROR    EXCEPTION;
      EX_CUST_ACCT_RANGE         EXCEPTION;

   BEGIN
      ----------------------------
      -- Intializing Variables
      ----------------------------
      gc_proc_name           := '    SUMMARIZE_STORES';
      gn_org_id              := p_org_id;
      gc_debug_flg           := p_display_log_details;
      gd_process_date        := FND_DATE.CANONICAL_TO_DATE(p_process_date);
      gc_concat_email        := p_email_address;
      gn_bulk_limit          := p_bulk_limit;
      gn_cust_id_low         := p_cust_id_low;
      gn_cust_id_high        := p_cust_id_high;
      gc_batch_source_name   := p_batch_source_name;
      gc_display_log_details := p_display_log_details;
      gn_sum_inv_line_rev_gt := 0;
      gn_sum_inv_line_tax_gt := 0;
      gn_sum_inv_line_rec_gt := 0;

      gc_debug_loc := '=> Input Parameters: ';
      WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, NULL );
      WRITE_LOG('Y',NULL,'--------------------------------------------', NULL);
      WRITE_LOG('Y',NULL ,'p_process_date         =',TO_CHAR(gd_process_date,'DD-MON-YYYY') );
      WRITE_LOG('Y',NULL ,'p_batch_source_name    =',gc_batch_source_name );
      WRITE_LOG('Y',NULL ,'p_org_id               =',gn_org_id);
      WRITE_LOG('Y',NULL ,'p_autoinv_thread_count =',p_autoinv_thread_count);
      WRITE_LOG('Y',NULL ,'p_email_address        =',p_email_address);
      WRITE_LOG('Y',NULL ,'p_cust_id_low          =',p_cust_id_low);
      WRITE_LOG('Y',NULL ,'p_cust_id_high         =',p_cust_id_high);
      WRITE_LOG('Y',NULL ,'p_wave_number          =',p_wave_number);
      WRITE_LOG('Y',NULL ,'p_display_log_details  =',p_display_log_details);
      WRITE_LOG('Y',NULL ,'p_bulk_limit           =',gc_bulk_limit);
      WRITE_LOG('Y',NULL ,'-------------------------------------------',NULL);
      WRITE_LOG('Y',NULL ,'Request ID             =',gn_request_id );

      --------------------------------------------------------------------------
      -- Step #1 - Retrieve High and Low Customer Account Numbers
      --------------------------------------------------------------------------
      BEGIN
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
         WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
         WRITE_LOG('Y',NULL ,'Step #1 - Retrieve High and Low Customer Acct Numbers  ',NULL);
         WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
         WRITE_LOG('Y','  Current System Time: ',TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

         gc_debug_loc := 'Retrieve Range of Customer Account Numbers from IDs';
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
         BEGIN
            SELECT account_number
              INTO gc_cust_account_low
              FROM xx_ar_intstorecust_otc
             WHERE cust_account_id = p_cust_id_low;

            SELECT account_number
              INTO gc_cust_account_high
              FROM xx_ar_intstorecust_otc
             WHERE cust_account_id = p_cust_id_high;

             WRITE_LOG('Y',gc_proc_name, '      Cust ID Low           '||p_cust_id_low,NULL);
             WRITE_LOG('Y',gc_proc_name, '      Cust ID High          '||p_cust_id_high,NULL);
             WRITE_LOG('Y',gc_proc_name, '      Cust Acct Low         '||gc_cust_account_low,NULL);
             WRITE_LOG('Y',gc_proc_name, '      Cust Acct High        '||gc_cust_account_high,NULL);

         EXCEPTION
           WHEN NO_DATA_FOUND THEN
              RAISE EX_CUST_ACCT_RANGE;
         END;
      END;

      --------------------------------------------------------------------------
      -- Step #2 - Call Clean-up Summary Inv from Previous Run
      --------------------------------------------------------------------------
      BEGIN
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
         WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
         WRITE_LOG('Y',NULL ,'Step #2 - Call Clean-up Summary Inv from Previous Run  ',NULL);
         WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
         WRITE_LOG('Y','  Current System Time: ',TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

         gc_debug_loc  := 'Executing CHECK_IMPORT_STATUS';
         CHECK_IMPORT_STATUS (p_ret_code    => ln_ret_code
                             ,p_cleanup_flg => 'Y');

          IF ln_ret_code = 2 THEN
             gc_debug_loc  := 'Error found during CHECK_IMPORT_STATUS';
             gc_debug_stmt := ': Restart flag = Y';
             WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

             RAISE CHECK_IMPORT_STATUS_EXP;
          END IF;
      END;

      --------------------------------------------------------------------------
      -- Step #3 - Getting email values is email parameter null
      --------------------------------------------------------------------------
      BEGIN
         WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
         WRITE_LOG('Y',NULL ,'Step #3 - Getting email values is email parameter null ',NULL);
         WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
         WRITE_LOG('Y','  Current System Time: ',TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

         IF gc_concat_email IS NULL THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

            gc_debug_loc  := 'Executing INV_DEFAULT_LOOKUPS';
            INV_DEFAULT_LOOKUPS (x_ret_code
                                ,lc_dummy_val
                                ,lc_dummy_val2
                                ,'Y');

            IF x_ret_code  <> 0 THEN
               WRITE_LOG('Y',NULL ,'Unable to set email addresses');
            END IF;

         END IF;
      END;

      --------------------------------------------------------------------------
      -- Step #3.1 - Derive R12 Tax columns
      --------------------------------------------------------------------------
      BEGIN
         WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
         WRITE_LOG('Y',NULL ,'Step #3.1 - Derive R12 Tax columns ',NULL);
         WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
         WRITE_LOG('Y','  Current System Time: ',TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

         ------------------------------------------------
         -- Added for R12 Retrofit to derive tax columns
         ------------------------------------------------
         BEGIN

                  --Retrive Tax regime code, tax_status_code for US FOR LINE1
                  SELECT zrb.tax_status_code,
                         zrb.tax_regime_code,
                         zrb.percentage_rate
                  INTO   gc_tax_status_code_us,
                         gc_tax_regime_code_us,
                         gc_rate_percent
                  FROM   zx_rates_b zrb
                  WHERE  zrb.tax_rate_code = gc_tax_rate_code
                  AND    zrb.tax           = gc_tax_line1
                  AND    zrb.active_flag   = 'Y'
                  AND    TRUNC(SYSDATE) BETWEEN zrb.effective_from AND NVL(zrb.effective_to,TRUNC(SYSDATE));

                  FND_FILE.PUT_LINE(FND_FILE.LOG,' Derived Tax rate code and Tax Regime code - ' || gc_tax_regime_code_us || ' - ' || gc_tax_status_code_us );

                  --Retrive Tax regime code, tax_status_code for US FOR LINE2
                  SELECT zrb.tax_status_code,
                         zrb.tax_regime_code,
                         zrb.percentage_rate
                  INTO   gc_tax_status_code_us1,
                         gc_tax_regime_code_us1,
                         gc_rate_percent1
                  FROM   zx_rates_b zrb
                  WHERE  zrb.tax_rate_code = gc_tax_rate_code1
                  AND    zrb.tax           = gc_tax_line2
                  AND    zrb.active_flag   = 'Y'
                  AND    TRUNC(SYSDATE) BETWEEN zrb.effective_from AND NVL(zrb.effective_to,TRUNC(SYSDATE));

                  FND_FILE.PUT_LINE(FND_FILE.LOG,' Derived Tax rate code and Tax Regime code for line2 - ' || gc_tax_regime_code_us1 || ' - ' || gc_tax_status_code_us1 );



                  --Retrive tax, tax_status_code for CA for COUNTY
                  SELECT  zrb.tax_status_code,
                          zrb.tax,
                          zrb.percentage_rate
                  INTO    gc_tax_status_code_ca1,
                          gc_tax_county,
                          gc_rate_percent_county
                  FROM    zx_rates_b zrb
                  WHERE   tax_rate_code   = gc_tax_rate_county
                  AND     tax_regime_code = gc_tax_regime_code_ca
                  AND     zrb.active_flag = 'Y'
                  AND     TRUNC(SYSDATE) BETWEEN zrb.effective_from AND NVL(zrb.effective_to,TRUNC(SYSDATE));

                  FND_FILE.PUT_LINE(FND_FILE.LOG,' Derived Tax rate code and Tax Regime code county - ' || gc_tax_status_code_ca1 || ' - ' || gc_tax_rate_county );

                  --Retrive tax, tax_status_code for CA for STATE
                  SELECT  zrb.tax_status_code,
                          zrb.tax,
                          zrb.percentage_rate
                  INTO    gc_tax_status_code_ca,
                          gc_tax_state,
                          gc_rate_percent_state
                  FROM    zx_rates_b zrb
                  WHERE   zrb.tax_rate_code   = gc_tax_rate_state
                  AND     zrb.tax_regime_code = gc_tax_regime_code_ca
                  AND     zrb.active_flag     = 'Y'
                  AND     TRUNC(SYSDATE) BETWEEN zrb.effective_from AND NVL(zrb.effective_to,TRUNC(SYSDATE));

                  FND_FILE.PUT_LINE(FND_FILE.LOG,' Derived Tax rate code and Tax Regime code state - ' || gc_tax_status_code_ca || ' - ' || gc_tax_rate_state );


         EXCEPTION
            WHEN NO_DATA_FOUND THEN

                     FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND: '||SQLERRM);

            WHEN TOO_MANY_ROWS THEN


                     FND_FILE.PUT_LINE(FND_FILE.LOG,'TOO_MANY_ROWS: '||SQLERRM );


            WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Other EXCEPTION: UNABLE TO DERIVE TAX COLUMNS FOR COUNTRY '
                                                    || ' - ' || SQLERRM );

         END;

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The List of Processed/Unprocessed Order Transaction Lines');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------------------------------');

      END;

      --------------------------------------------------------------------------
      -- Step #4 and 5 - Identify and Create Summary Invoices
      --------------------------------------------------------------------------
      BEGIN
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
         WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
         WRITE_LOG('Y',NULL ,'Step #4 and 5 - Identify and Create Summary Invoices   ',NULL);
         WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
         WRITE_LOG('Y','  Current System Time: ',TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

         gc_debug_loc := 'Calling SELECT_SUMMARY_INV Procedure';
         SELECT_SUMMARY_INV(ln_ret_code);

         IF ln_ret_code = 2 THEN
            RAISE INVALID_BATCH_SOURCE;
         END IF;

         IF ln_ret_code <> 0  THEN
            RAISE SELECT_SUMMARY_WARNING;
         END IF;
      END;

      --------------------------------------------------------------------------
      -- Step #6 - Check Detailed Invoice Belong to One Summ Inv
      --------------------------------------------------------------------------
      BEGIN
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
         WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
         WRITE_LOG('Y',NULL ,'Step #6 - Check Detailed Invoice Belong to One Summ Inv',NULL);
         WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
         WRITE_LOG('Y','  Current System Time: ',TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

         gc_debug_loc := '     Verifying Detailed Invoices Have ONE Summary Invoice';
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

         CHECK_MULTI_SUM_INV (ln_ret_code);

         IF ln_ret_code <> 0 THEN

            RAISE MULTI_SUMMARY_TRX_ERROR;
         END IF;
      END;

      --------------------------------------------------------------------------
      -- Step #7 - Insert Standard RA Interface Tables
      --------------------------------------------------------------------------
      BEGIN
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
         WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
         WRITE_LOG('Y',NULL ,'Step #7 - Insert Standard RA Interface Tables          ',NULL);
         WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
         WRITE_LOG('Y','  Current System Time: ',TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

         gc_debug_loc := 'Calling INST_RA_INTR_TBLS Procedure';
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

         INST_RA_INTR_TBLS(ln_ret_code);

         IF ln_ret_code <> 0  THEN

            RAISE INST_RA_TABLES_ERROR;

         END IF;
      END;

      --------------------------------------------------------------------------
      --	Step #8 � Import Summary Invoices and Populate Detailed References
      --------------------------------------------------------------------------
      BEGIN
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
         WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
         WRITE_LOG('Y',NULL ,'Step #8 - Import Summary Invoices and Insert References',NULL);
         WRITE_LOG('Y',NULL ,'-------------------------------------------------------',NULL);
         WRITE_LOG('Y','  Current System Time: ',TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

         gc_debug_loc := 'Calling SUBMIT_AUTOINV_MSTR Procedure';
         gc_debug_stmt := NULL;
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

         SUBMIT_AUTOINV_MSTR (p_return_code          => ln_ret_code
                             ,p_autoinv_thread_count => p_autoinv_thread_count
                             ,p_cust_account_low     => gc_cust_account_low
                             ,p_cust_account_high    => gc_cust_account_high);

         lc_ai_return_code  := ln_ret_code;

         ----------------------------------------
         -- Execute Check_import_status post AI
         ----------------------------------------
         gc_debug_loc := '        Calling CHECK_IMPORT_STATUS Procedure';
         gc_debug_stmt := NULL;
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

         CHECK_IMPORT_STATUS (p_ret_code    => ln_ret_code
                             ,p_cleanup_flg => 'N');

         x_ret_code := ln_ret_code;

      END;

      --------------------------------------------------------------------------
      --	Step #9 � Checking Warning and Error Conditions
      --------------------------------------------------------------------------
      IF gc_ref_rec_not_inserted = 'Y' THEN
         -------------------------------------------------------------------
         -- Writing output for references not inserted correctly
         -------------------------------------------------------------------
         OUTPUT_REF_INS_STATUS;
         x_ret_code := 2;

      ELSIF x_ret_code = 2 THEN
         -------------------------------------------------------------------
         -- Setting return code to error if Check Import ERROR
         -------------------------------------------------------------------
         gc_debug_loc  := 'Error occured during  CHECK_IMPORT_STATUS ';
         WRITE_LOG('Y',' ' ,null,null );
         WRITE_LOG('Y',NULL ,gc_debug_loc, NULL);

         SEND_EMAIL (gc_concat_email, gc_debug_loc ,gc_debug_stmt );
         RAISE CHECK_IMPORT_STATUS_EXP;

      ELSIF lc_ai_return_code = 2  THEN
         -------------------------------------------------------------------
         -- Setting return code to error if AI failed
         -------------------------------------------------------------------
         gc_debug_loc := 'Error occured during  Auto Invoice Import ';
         WRITE_LOG('Y',' ' ,null,null );
         WRITE_LOG('Y',NULL ,gc_debug_loc, NULL);
         x_ret_code := 2;

      ELSIF gc_out_of_balance_flag = 'Y' THEN
         -------------------------------------------------------------------
         -- Setting return code to warning if out-of-balance encounterd
         -------------------------------------------------------------------
         gc_debug_loc := 'Out of Balance Encountered (Imported Summary TRX'||
                         'not equal to Summary TRX in XX_RA tables)';
         WRITE_LOG('Y',' ' ,null,null );
         WRITE_LOG('Y',NULL ,gc_debug_loc, NULL);
         x_ret_code := 1;

      ELSIF gn_create_summary_warning = 1 THEN
         -------------------------------------------------------------------
         -- Raise exception if any candidate transactions not summarized
         -------------------------------------------------------------------
         RAISE CREATE_SUMMARY_WARNING;

      ELSE
         -------------------------------------------------------------------
         -- Setting return code to success
         -------------------------------------------------------------------
         gc_debug_loc  := '************    End of Report ********** ';
         WRITE_LOG('Y',NULL ,gc_debug_loc, NULL);
         x_ret_code := 0;

      END IF;

   EXCEPTION
      WHEN EX_CUST_ACCT_RANGE THEN
         gc_proc_name  := '    SUMMARIZE_STORES';
         gc_debug_loc  := ' EX_CUST_ACCT_RANGE : ';
         gc_debug_stmt := 'ERROR - Unable to retrieve customer account numbers'
                          ||' for submitting Autoinvoice Master Program.'
                          ||' Please review Concurrent request: '|| gn_request_id;
         SEND_EMAIL (gc_concat_email, gc_debug_loc ,gc_debug_stmt );
         WRITE_LOG('Y','   Error!' ,gc_debug_loc, gc_debug_stmt );

         x_ret_code := 2;

      WHEN MULTI_SUMMARY_TRX_ERROR THEN
         gc_proc_name  := '    SUMMARIZE_STORES';
         gc_debug_loc  := ' MULTI_SUMMARY_TRX_ERROR : ';
         gc_debug_stmt := 'ERROR - Detailed invoices have been summarized into'
                          ||' multiple summary invoices.  Summary invoices'
                          ||' were not copied to RA interface tables.'
                          ||' Please review Concurrent request: '|| gn_request_id;
         SEND_EMAIL (gc_concat_email, gc_debug_loc ,gc_debug_stmt );
         WRITE_LOG('Y','   Error!' ,gc_debug_loc, gc_debug_stmt );

         x_ret_code := 2;

      WHEN INST_RA_TABLES_ERROR THEN
         gc_proc_name  := '    SUMMARIZE_STORES';
         gc_debug_loc  := ' INST_RA_TABLES_ERROR : ';
         gc_debug_stmt := 'SUMMARY INVOICES could not be inserted into'
                           ||' RA interface table'
                           ||' Please review Concurrent request: '|| gn_request_id;

         WRITE_LOG('Y','   Error!' ,gc_debug_loc, gc_debug_stmt );

         x_ret_code := 2;

      WHEN CHECK_IMPORT_STATUS_EXP THEN
         gc_proc_name  := '    SUMMARIZE_STORES';
         gc_debug_loc  := ' CHECK_IMPORT_STATUS_EXP : Error';
         gc_debug_stmt := 'SUMMARY INVOICES EXIST ON THE INTERFACE TABLE'
                           ||' Autoinvoice did not import invoice(s) or'
                           ||' reprocessing for previously imported invoices'
                           ||' could not be completed.'
                           ||' Please review Concurrent request: '|| gn_request_id;

         WRITE_LOG('Y','    WARNING!' ,gc_debug_loc, gc_debug_stmt );

         x_ret_code := 2;

      WHEN CREATE_SUMMARY_WARNING THEN
         x_ret_code   := gn_create_summary_warning;

         gc_proc_name := '    SUMMARIZE_STORES';
         gc_debug_loc := 'Warning CREATE_SUMMARY_INV:'
                          ||' Not all transaction where summarized'
                          ||' Please see output file!';

         gc_debug_stmt := x_ret_code || ' Ending Program ';

         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

         x_ret_code := 1;

      WHEN SELECT_SUMMARY_WARNING THEN
         gc_proc_name  := '    SUMMARIZE_STORES';
         gc_debug_loc  := 'Return code from SELECT_SUMMARY_INV was';
         gc_debug_stmt := x_ret_code|| ' Ending Program ';
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

         x_ret_code := ln_ret_code;

      WHEN INVALID_BATCH_SOURCE THEN
         gc_proc_name  := '    SUMMARIZE_STORES';
         gc_debug_stmt := 'gc_batch_source_name ='
                           || gc_batch_source_name
                           ||' not found in translation table'
                           ||' OD_AR_INVOICING_DEFAULTS';
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

         x_ret_code := 2;

      WHEN OTHERS THEN
         gc_proc_name  := '    SUMMARIZE_STORES';
         gc_debug_stmt :=  SUBSTR(SQLERRM,1,249);
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
         x_ret_code := 2;

   END SUMMARIZE_STORES;

   -- +=====================================================================+
   -- | NAME       : MAIN                                                   |
   -- |                                                                     |
   -- | DESCRIPTION: Program is used for submitting multiple child invoice  |
   -- |              summarization programs (OD: AR Summarize POS Sales)    |
   -- |                                                                     |
   -- | PARAMETERS :                                                        |
   -- |                                                                     |
   -- | RETURNS    :                                                        |
   -- |                                                                     |
   -- +=====================================================================+
   PROCEDURE MAIN (x_err_buff              OUT  VARCHAR2
                  ,x_ret_code              OUT  NUMBER
                  ,p_process_date           IN  VARCHAR2
                  ,p_batch_source_name      IN  VARCHAR2  DEFAULT NULL
                  ,p_child_threads          IN  NUMBER
                  ,p_autoinv_thread_count   IN  NUMBER
                  ,p_email_address          IN  VARCHAR2  DEFAULT NULL
                  ,p_org_id                 IN  NUMBER
                  ,p_wave_number            IN  NUMBER
                  ,p_display_log_details    IN  VARCHAR2
                  ,p_bulk_limit             IN  NUMBER
                  )
   IS
      lc_err_buff           VARCHAR2(2000);
      ln_ret_code           NUMBER;

      ln_reprocess_upd_cnt  NUMBER := 0;
      ln_thread_counter     NUMBER := 0;

      CURSOR lcu_cust_accts
      IS
         SELECT MIN(X.orig_system_bill_customer_id)  MIN_CUST_ID
               ,MAX(X.orig_system_bill_customer_id)  MAX_CUST_ID
               ,MIN(X.account_number)                MIN_ACCT_ID
               ,MAX(X.account_number)                MAX_ACCT_ID
               ,COUNT(1)
               ,LENGTH(X.account_number)
               ,thread_num
          FROM (SELECT XRILA.orig_system_bill_customer_id, OTC.account_number
                      ,NTILE(p_child_threads-1) OVER(ORDER BY XRILA.orig_system_bill_customer_id) thread_num
                  FROM xx_ra_int_lines_all    XRILA
                      ,xx_ar_intstorecust_otc OTC
                 WHERE OTC.cust_account_id = XRILA.orig_system_bill_customer_id
                GROUP BY XRILA.orig_system_bill_customer_id ,OTC.account_number) X
         GROUP BY LENGTH(X.account_number),thread_num
         ORDER BY LENGTH(X.account_number),thread_num;

      lrec_cust               lcu_cust_accts%ROWTYPE;

   BEGIN
      gc_proc_name           := '    MAIN';

      ----------------------------
      -- Intializing Variables
      ----------------------------
      gn_org_id              := p_org_id;
      gc_debug_flg           := p_display_log_details;
      gd_process_date        := FND_DATE.CANONICAL_TO_DATE(p_process_date);
      gc_concat_email        := p_email_address;
      gc_batch_source_name   := p_batch_source_name;
      gc_display_log_details := p_display_log_details;
      gc_req_data            := FND_CONC_GLOBAL.REQUEST_DATA;

      IF gc_req_data IS NULL THEN
         -- This is NOT a restart

         gc_debug_loc := 'Write Out Header Information';
         WRITE_OUTPUT ('HEADER');

         -----------------------------------------------------------------------
         -- PRE-SUMMARY #1 - Clean-up Summary invoices from prior run
         -----------------------------------------------------------------------
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
         WRITE_LOG('Y',NULL ,'--------------------------------------------------------------',NULL);
         WRITE_LOG('Y',NULL ,'PRE-SUMMARY #1 - Call Clean-up Summary Inv from Previous Run  ',NULL);
         WRITE_LOG('Y',NULL ,'--------------------------------------------------------------',NULL);
         WRITE_LOG('Y','  Current System Time: ',TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );
         FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

         BEGIN
            gc_debug_loc  := '    Updating XX_RA_INT_LINES_ALL             ';
            gc_debug_stmt := 'Setting interface_status to null'
                                   || ' for summary detail reprocessing.'   ;
            WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );

            UPDATE xx_ra_int_lines_all XRILA
               SET XRILA.interface_status = NULL
            WHERE XRILA.interface_line_context     = G_ORDER_ENTRY
               AND XRILA.interface_line_attribute3 <> G_SUMMARY
               AND XRILA.interface_status           = 'E'
               AND XRILA.org_id                     = gn_org_id
               AND XRILA.orig_system_bill_customer_id BETWEEN gn_cust_id_low
                                                          AND gn_cust_id_high;

            ln_reprocess_upd_cnt := SQL%ROWCOUNT;

            COMMIT;
            WRITE_LOG('Y',gc_proc_name ,'    Records Updated for Reprocessing         ',ln_reprocess_upd_cnt );
         END;

         -----------------------------------------------------------------------
         -- PRE-SUMMARY #2 - Write-out Pre-summarization Amounts
         -----------------------------------------------------------------------
         BEGIN
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
            WRITE_LOG('Y',NULL ,'--------------------------------------------------------------',NULL);
            WRITE_LOG('Y',NULL ,'PRE-SUMMARY #2 - Write-out Pre-summarization Amounts          ',NULL);
            WRITE_LOG('Y',NULL ,'--------------------------------------------------------------',NULL);
            WRITE_LOG('Y','  Current System Time: ',TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

            gc_debug_loc := 'Write Out Pre-summarization Information';
            OUTPUT_PRE_IMPORT_STATUS;
         END;

         -----------------------------------------------------------------------
         -- PRE-SUMMARY #3 - Submit Child Summarization Programs
         -----------------------------------------------------------------------
         BEGIN
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
            WRITE_LOG('Y',NULL ,'--------------------------------------------------------------',NULL);
            WRITE_LOG('Y',NULL ,'PRE-SUMMARY #3 - Submit Child Summarization Programs          ',NULL);
            WRITE_LOG('Y',NULL ,'--------------------------------------------------------------',NULL);
            WRITE_LOG('Y','  Current System Time: ',TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

            gc_proc_name := '    MAIN';
            WRITE_LOG('Y',gc_proc_name ,'      Summarization programs to submit ',p_child_threads);

            gc_debug_loc := 'Retrieve customer ID ranges and submit summarization child programs';
            OPEN lcu_cust_accts;
            LOOP
               FETCH lcu_cust_accts INTO lrec_cust;
               EXIT WHEN lcu_cust_accts%NOTFOUND;

               ln_thread_counter := ln_thread_counter + 1;

               WRITE_LOG('Y',gc_proc_name, '      Thread Number         '||ln_thread_counter,NULL);
               WRITE_LOG('Y',gc_proc_name, '      Cust ID Low           '||lrec_cust.min_cust_id,NULL);
               WRITE_LOG('Y',gc_proc_name, '      Cust ID High          '||lrec_cust.max_cust_id,NULL);

               gc_debug_loc := 'Setting Printer and Copies';
               gb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(printer => NULL
                                                               ,copies  => 0);

               gc_debug_loc := 'Submit summarization programs';
               gn_conc_id := FND_REQUEST.SUBMIT_REQUEST(
                                            application => 'XXFIN'
                                           ,program     => 'XX_AR_SUMMARIZE_POS_INV_CHILD'
                                           ,description => ''
                                           ,start_time  => ''
                                           ,sub_request => TRUE
                                           ,argument1   => p_process_date
                                           ,argument2   => p_batch_source_name
                                           ,argument3   => p_org_id
                                           ,argument4   => p_autoinv_thread_count
                                           ,argument5   => p_email_address
                                           ,argument6   => lrec_cust.min_cust_id
                                           ,argument7   => lrec_cust.max_cust_id
                                           ,argument8   => p_wave_number
                                           ,argument9   => p_display_log_details
                                           ,argument10  => p_bulk_limit);

               COMMIT;

               WRITE_LOG('Y',gc_proc_name ,'      Submitted Request ID '||gn_conc_id,NULL);
               WRITE_LOG('Y',gc_proc_name, '  ',NULL);
            END LOOP;
            CLOSE lcu_cust_accts;

            gc_debug_loc := 'Set Request Data';
			--Start modification by Adithya for QC#19820
			IF ln_thread_counter>0 THEN
			--End modification by Adithya for QC#19820
            FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status  => 'PAUSED',
                                            request_data => 'POS_SUM_CHILD_THREADS_COMPLETED');
			--Start modification by Adithya for QC#19820
            ELSE
			FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
			WRITE_LOG('Y',NULL ,'--------------------------------------------------------------',NULL);
            WRITE_LOG('Y',NULL ,'No Child requests submitted as there is no data in interface table(xx_ra_int_lines_all) to process!!!',NULL);
            --End modification by Adithya for QC#19820
            END IF;

         END;

      ELSIF gc_req_data = 'POS_SUM_CHILD_THREADS_COMPLETED'  THEN

         -- Program is restarting after child threads have completed

         -----------------------------------------------------------------------
         -- POST-SUMMARY - Write-out Import Status
         -----------------------------------------------------------------------
         BEGIN
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
            WRITE_LOG('Y',NULL ,'--------------------------------------------------------------',NULL);
            WRITE_LOG('Y',NULL ,'POST-SUMMARY - Write-out Import Status                        ',NULL);
            WRITE_LOG('Y',NULL ,'--------------------------------------------------------------',NULL);
            WRITE_LOG('Y','  Current System Time: ',TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), NULL );
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

            gc_debug_loc := 'Write Out import Status';
            OUTPUT_IMPORT_STATUS;
         END;
         --------------------------------------------------------
         -- Calling procedure to Get child threads status and set
         -- Master programs status
         --------------------------------------------------------
         GET_CHILD_STATUS (gn_request_id);

      END IF;




   EXCEPTION
      WHEN OTHERS THEN
         gc_proc_name           := '    MAIN';
         gc_debug_stmt :=  SUBSTR(SQLERRM,1,249);
         WRITE_LOG('Y',gc_proc_name ,gc_debug_loc, gc_debug_stmt );
         x_ret_code := 2;

   END MAIN;

END XX_AR_SUMMARIZE_POS_INV_PKG;
/
