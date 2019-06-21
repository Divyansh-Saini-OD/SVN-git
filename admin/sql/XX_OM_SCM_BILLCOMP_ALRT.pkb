CREATE OR REPLACE PACKAGE BODY APPS.XX_OM_SCM_BILLCOMP_ALRT
AS
-- +======================================================================+
-- |                  Office Depot - Project Simplify                     |
-- |                                                                      |
-- +======================================================================+
-- | Name             : XXEBSSCMBILLCOMPALRT.PKB                          |
-- | Description      : Package Body                                      |
-- |                                                                      |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version    Date          Author           Remarks                     | 
-- |=======    ==========    =============    ============================|
-- |DRAFT 1A   09-03-2019    Arun Gannarapu   pending bill complete orders|
-- |                                                                      |
-- +======================================================================+
-- procedure extract all pending order for bill complete
  PROCEDURE extract_pending_bc_orders (retcode        OUT   NUMBER,
                                     errbuf         OUT   VARCHAR2
    )
   IS
   l_email_list        VARCHAR2(2000)  := 'arun.gannarapu@officedepot.com';
   lc_mail_from        varchar2 (100)  := 'noreply@officedepot.com';
   lc_instance         varchar2 (100);
   l_text              varchar2(2000)  := null;
   l_message           VARCHAR2(2000)  := 'Orders shipped but not in Bill signal table';
   lc_date             VARCHAR2 (200) := TO_CHAR (SYSDATE, 'MM/DD/YYYY');

   v_filename          VARCHAR2(2000);
   v_filehandle        UTL_FILE.FILE_TYPE;
   lc_records_exists   boolean := FALSE;
    
   CURSOR order_stuck
   IS
   SELECT a.parent_order_num,
          TO_CHAR (B.ORDER_NUMBER) CHILD_ODR,
          a.bill_comp_flag,
          TO_CHAR (a.creation_date, 'dd-mon-rrrr hh24:mi:ss') ord_creation_date,
          hp.party_name,
          substr(hca.orig_system_reference,1,8) account_number
   FROM   xx_om_header_attributes_all a,
          oe_order_headers_all b,
          hz_cust_accounts hca,
          hz_parties hp
   WHERE a.header_id = b.header_id
     AND hca.party_id = hp.party_id
     AND hca.cust_account_id = b.sold_to_org_id
     AND a.bill_comp_flag IN ('Y', 'B')
     AND b.last_update_date >= SYSDATE - 60
     AND NOT EXISTS
            (SELECT 1
             FROM XX_SCM_BILL_SIGNAL
              WHERE CHILD_ORDER_NUMBER = B.ORDER_NUMBER);
     
   vl_hdr_message   varchar2(2000);
   vl_line_message  varchar2(32000);
   lc_conn          UTL_SMTP.connection;
   lc_dirpath        VARCHAR2 (2000) := 'XX_UTL_FILE_OUT_DIR';
   lc_mode           VARCHAR2 (1)    := 'W';
   ln_max_linesize   BINARY_INTEGER  := 32767;
   v_translation_info xx_fin_translatevalues%ROWTYPE := NULL;
             
 BEGIN
 --xx_ar_rcc_extract
 
   SELECT instance_name
   INTO  lc_instance
   FROM v$instance;
   
   BEGIN
     SELECT xftv.*
     INTO v_translation_info
     FROM xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
     WHERE xftv.translate_id = xftd.translate_id
       AND xftd.translation_name = 'XXOM_BILLSIGNAL_ALERT'
       AND xftv.source_value1 = 'BILLSIGNAL'
       AND SYSDATE BETWEEN xftv.start_date_active
                       AND NVL (xftv.end_date_active, SYSDATE + 1)
       AND SYSDATE BETWEEN xftd.start_date_active
                       AND NVL (xftd.end_date_active, SYSDATE + 1)
       AND xftv.enabled_flag = 'Y'
       AND xftd.enabled_flag = 'Y';

      fnd_file.put_line(fnd_file.log, 'TO Email:' || v_translation_info.target_value1);
      fnd_file.put_line(fnd_file.log, 'From Email:' || v_translation_info.target_value2);

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         fnd_file.put_line (fnd_file.LOG, 'NO Data found in the translation');
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Unable to get record'||SQLERRM);
   END; 
   
   
   v_filehandle    := UTL_FILE.FOPEN(lc_dirpath, v_filename, lc_mode,ln_max_linesize);
   
   vl_hdr_message  := 'Parent_order_number'||'|'||
                       'Child_order_number'||'|'||
                       'Bill_complete_flag'||'|'||
                       'Creation date'||'|'||
                       'PARTY NAME'||'|'||
                       'Account Number';
 
   UTL_FILE.PUT_LINE(v_filehandle, vl_hdr_message);
  
   FOR bc_order_rec IN order_stuck
   LOOP
     vl_line_message := bc_order_rec.parent_order_num||'|'||
                        bc_order_rec.child_odr||'|'||
                        bc_order_rec.bill_Comp_flag||'|'||
                        bc_order_rec.ord_creation_date||'|'||
                        bc_order_rec.party_name||'|'||
                        bc_order_rec.account_number;
     UTL_FILE.PUT_LINE (v_filehandle, vl_line_message);
     UTL_FILE.FFLUSH(v_filehandle);
     lc_records_exists := TRUE;
   END LOOP;

   UTL_FILE.FCLOSE (v_filehandle);

   IF lc_instance = 'GSIPRDGB'
   THEN
     l_text := 'Bill Complete pending order';
   ELSE
     L_TEXT :='Please Ignore this email: bill compelte reports ';
   END IF;
      
   IF lc_records_exists
   THEN
     fnd_file.put_line(fnd_file.log,'Before sending mail');
     lc_conn :=  xx_pa_pb_mail.begin_mail
                         (sender             => v_translation_info.target_value2,
                          recipients         => v_translation_info.target_value1,
                          cc_recipients      => NULL,
                          subject            => lc_instance||': '||'EBS BILL SIGNAL ALERT :'|| ' '|| lc_date,
                          mime_type          => xx_pa_pb_mail.multipart_mime_type
                          );
            xx_pa_pb_mail.xx_attach_excel (lc_conn, v_filename);
            xx_pa_pb_mail.end_attachment (conn => lc_conn);
            xx_pa_pb_mail.attach_text (conn => lc_conn, DATA => l_message);
            xx_pa_pb_mail.end_mail (conn => lc_conn);
     fnd_file.put_line(fnd_file.log,' After calling Email Notification ' );
    END IF;
    retcode := 0;
    --errbuf := 'Y';
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,'Unknown Error occured'||SQLERRM);
   END;
END XX_OM_SCM_BILLCOMP_ALRT;
/
