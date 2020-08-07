CREATE OR REPLACE PACKAGE BODY XX_OM_HVOP_ALERT_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XXOMHVOPINTERRORPKG.PKB                                   |
-- | Description      : Package Specification                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   06-AUG-2009   Bala             Initial draft version    |
-- |V 1.0      22-MAR-2011   Bala             Added TDS Alert Procedure|
-- |V 1.1      03-JUN-2013   Shruthi Vasisht  Modified for R12 Upgrade |
-- |                                          retrofit                 |
-- |  1.2      09-NOV-2015   Shubashree R     R12.2  Compliance changes|
-- |                                          Defect# 36354            |
-- |  1.3      24-MAY-2016   Havish Kasina    Removed Schema References|
-- |                                          for R12.2                |
-- +===================================================================+
Procedure  hvop_error_count( errbuf             OUT VARCHAR2
                          , retcode             OUT NUMBER
                          , p_email_list        IN VARCHAR2
                          , p_trigger_file_name IN VARCHAR2
                          , p_process_date      IN VARCHAR2
                          ) IS
ln_om_hold_order_count     NUMBER := 0;
ln_om_int_order_count      NUMBER := 0;
ln_sas_order_count         NUMBER := 0;
ln_om_entered_count        NUMBER := 0;
ln_om_booked_count         NUMBER := 0;
ln_om_inv_hold_count       NUMBER := 0;
ln_pend_dep_order_count    NUMBER := 0;
lc_message                 VARCHAR2(50);
lc_email_page              VARCHAR2(1):='N';
lc_mail_status             VARCHAR2(1);
lc_error_message           VARCHAR2(1000);
p_status                   VARCHAR2(10);
--ln_lookup_exist Number;
lc_message_create          VARCHAR2(200);
lc_message_subject         VARCHAR2(200);
lc_message_body                CLOB;
lc_wave               VARCHAR2(10);
ln_op_unit               NUMBER :=0;
crlf                       VARCHAR2(10) := chr(13) || chr(10);
lc_instance               VARCHAR2(100);
ln_threshold_val           NUMBER :=0;
ld_process_date           DATE;
-- Cursor to check how many orders are on what status
CURSOR om_order_count_cur IS
SELECT COUNT(*) ord_status_count
               , flow_status_code
       FROM oe_order_headers_all oif
         , xx_om_header_attributes_all xif
         , xx_om_sacct_file_history fh
         , fnd_concurrent_requests cr
         , fnd_concurrent_requests cr1
         , fnd_concurrent_programs_tl cp
  WHERE oif.Header_id = xif.Header_id
    AND xif.imp_file_name = fh.file_name
    AND oif.order_type_id NOT IN (1002,1005)
    AND fh.process_date = ld_process_Date --'23-JUL-2009'
    AND fh.request_id = cr1.request_id
    AND cp.user_concurrent_program_name = 'OD: SAS Trigger HVOP'
    AND cp.concurrent_program_id = cr.concurrent_program_id
    AND cr.argument1 = p_trigger_file_name
    AND cr.request_id = cr1.parent_request_id
GROUP BY flow_status_code;
BEGIN

ld_process_date := TO_DATE(p_process_date,'YYYY/MM/DD HH24:MI:SS');

FND_FILE.PUT_LINE(FND_FILE.LOG,
                    'Process Date : '|| ld_process_date);
                    
FND_FILE.PUT_LINE(FND_FILE.LOG,
                    'File Name: '|| p_trigger_file_name);
                    
--  commented and added by shruthi for R12 Upgrade Retrofit

/*SELECT
     DECODE(SUBSTR(p_trigger_file_name,9,1),1,'WAVE 1',2,'WAVE 2',3,'WAVE 3',5,'WAVE 4')
    ,DECODE(SUBSTR(p_trigger_file_name,4,2),'US',404,'CA',403)
   INTO lc_wave,ln_op_unit FROM dual;*/
   
   SELECT
     DECODE(SUBSTR(p_trigger_file_name,10,1),1,'WAVE 1',2,'WAVE 2',3,'WAVE 3',5,'WAVE 4')
    ,DECODE(SUBSTR(p_trigger_file_name,4,2),'US',404,'CA',403)
   INTO lc_wave,ln_op_unit FROM dual;
   
   -- end of addition
   
   
   FND_FILE.PUT_LINE(FND_FILE.LOG,
                    'Wave is : '|| lc_wave);
                    
   FND_FILE.PUT_LINE(FND_FILE.LOG,
                    'Operating Unit is : '|| ln_op_unit);

SELECT nvl(parameter_value,0) into ln_threshold_val
    FROM oe_sys_parameters_all
  WHERE parameter_code = 'HVOP_ERROR_THRESHOLD'
  AND org_id = ln_op_unit;
  
  FND_FILE.PUT_LINE(FND_FILE.LOG,
                    'Threshold Value is : '|| ln_threshold_val);

SELECT
  instance_name
INTO lc_instance FROM v$instance;

 FND_FILE.PUT_LINE(FND_FILE.LOG,
                    'Instance is : '|| lc_instance);

lc_message_body  :=lc_message_body  || '<B><font color="FF0000">********************  HVOP ALERT  ******************</FONT></B>'||'<BR>';
lc_message_body  :=lc_message_body  || '<font color="#0000ff">Message from Hvop Alert system on <B>' || lc_wave ||','|| SUBSTR(p_trigger_file_name,4,2) ||'</B> for process date <B>' || p_process_date || '</B></FONT>'||'<BR>';
-- Get SAS Order Count
  SELECT COUNT(legacy_header_count)
         INTO  ln_sas_order_count
     FROM
         xx_om_headers_attr_iface_all xif
        , xx_om_sacct_file_history fh
        , fnd_concurrent_requests cr
        , fnd_concurrent_requests cr1
        , fnd_concurrent_programs_tl cp
    WHERE xif.imp_file_name = fh.file_name
      AND fh.process_date = ld_process_date
      AND fh.request_id = cr1.request_id
      AND cp.user_concurrent_program_name = 'OD: SAS Trigger HVOP'
      AND cp.concurrent_program_id = cr.concurrent_program_id
      AND cr.argument1 = p_trigger_file_name
      AND cr.request_id = cr1.parent_request_id
      group by process_Date ;
      
      -- Get Order count stuck in Interface table
  SELECT COUNT(*)
     INTO ln_om_int_order_count
     FROM oe_headers_iface_all oif
        , xx_om_headers_attr_iface_all xif
        , xx_om_sacct_file_history fh
        , fnd_concurrent_requests cr
        , fnd_concurrent_requests cr1
        , fnd_concurrent_programs_tl cp
    WHERE oif.orig_sys_document_ref = xif.orig_sys_document_ref
      AND oif.order_type_id NOT IN (1002,1005)
      AND xif.imp_file_name = fh.file_name
      AND fh.process_date = ld_process_date
      AND fh.request_id = cr1.request_id
      AND cp.user_concurrent_program_name = 'OD: SAS Trigger HVOP'
      AND cp.concurrent_program_id = cr.concurrent_program_id
      AND cr.argument1 = p_trigger_file_name
      AND cr.request_id = cr1.parent_request_id;
   -- AND oif.error_flag = 'Y';
-- Get the count of orders on Hold
  SELECT COUNT(*)
    INTO ln_om_hold_order_count
    FROM oe_order_headers_all h
       , xx_om_sacct_file_history fh
       , xx_om_header_attributes_all xh
       , oe_order_holds_all oh
       , oe_hold_sources_all hs
       , oe_hold_definitions hd
       , fnd_concurrent_requests cr
       , fnd_concurrent_requests cr1
       , fnd_concurrent_programs_tl cp
   WHERE h.header_id = oh.header_id
     AND h.header_id = xh.header_id
     AND oh.hold_source_id = hs.hold_source_id
     AND hs.hold_id = hd.hold_id
     AND oh.hold_release_id IS NULL
     AND hd.hold_id != 1005
     AND h.order_type_id NOT IN (1002,1005)
     AND fh.file_name = xh.imp_file_name
     AND fh.process_date = ld_process_date
     AND fh.request_id = cr1.request_id
     AND cp.user_concurrent_program_name = 'OD: SAS Trigger HVOP'
     AND cp.concurrent_program_id = cr.concurrent_program_id
     AND cr.argument1 = p_trigger_file_name
     AND cr.request_id = cr1.parent_request_id;
-- Get the pending deposit hold Count

    SELECT COUNT(*)
    INTO ln_pend_dep_order_count
    FROM oe_order_headers_all h
       , xx_om_sacct_file_history fh
       , xx_om_header_attributes_all xh
       , oe_order_holds_all oh
       , oe_hold_sources_all hs
       , oe_hold_definitions hd
       , fnd_concurrent_requests cr
       , fnd_concurrent_requests cr1
       , fnd_concurrent_programs_tl cp
   WHERE h.header_id = oh.header_id
     AND h.header_id = xh.header_id
     AND oh.hold_source_id = hs.hold_source_id
     AND hs.hold_id = hd.hold_id
     AND oh.hold_release_id IS NULL
     AND hd.hold_id = 1005
     AND h.order_type_id NOT IN (1002,1005)
     AND fh.file_name = xh.imp_file_name
     AND fh.process_date = ld_process_date
     AND fh.request_id = cr1.request_id
     AND cp.user_concurrent_program_name = 'OD: SAS Trigger HVOP'
     AND cp.concurrent_program_id = cr.concurrent_program_id
     AND cr.argument1 = p_trigger_file_name
     AND cr.request_id = cr1.parent_request_id;

-- Order Count from the Headers table with Status
    FOR om_order_cur_rec in om_order_count_cur LOOP
    

    FND_FILE.PUT_LINE(FND_FILE.LOG,
                    'Inside for loop');        
                    
                            
        IF om_order_cur_rec.flow_status_code = 'ENTERED' THEN
            ln_om_entered_count := om_order_cur_rec.ord_status_count;
        ELSIF om_order_cur_rec.flow_status_code = 'BOOKED' THEN
            ln_om_booked_count := om_order_cur_rec.ord_status_count;
        ELSIF om_order_cur_rec.flow_status_code = 'INVOICE_HOLD' THEN
           ln_om_inv_hold_count := om_order_cur_rec.ord_status_count;
        END IF;
        
    END LOOP;
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,
                    'SAS Count' || ln_sas_order_count );
                    
    FND_FILE.PUT_LINE(FND_FILE.LOG,
                    'Entered count ' || ln_om_entered_count);
                    
    FND_FILE.PUT_LINE(FND_FILE.LOG,
                    'Booked Count'|| ln_om_booked_count );
                    
    FND_FILE.PUT_LINE(FND_FILE.LOG,
                    'Hold Count' || ln_om_inv_hold_count );
                    
    FND_FILE.PUT_LINE(FND_FILE.LOG,
                    'Pending Deposit Holds ' || ln_pend_dep_order_count);
                    
    FND_FILE.PUT_LINE(FND_FILE.LOG,
                    'Total number of other Holds '|| ln_om_hold_order_count );
                    
    FND_FILE.PUT_LINE(FND_FILE.LOG,
                    'Total number of orders stuck in Interface table' || ln_om_int_order_count );
                    
        lc_message_body := lc_message_body || '<BR><BR>Total Number of SAS Orders : <B>'|| ln_sas_order_count || '</B><BR>';
        lc_message_body := lc_message_body || 'Total number of orders in ENTERED Status : <B>'|| ln_om_entered_count || '</B><bR>';
        lc_message_body := lc_message_body || 'Total number of orders in BOOKED Status : <B>' || ln_om_booked_count || '</B><BR>' ;
        lc_message_body := lc_message_body || 'Total number of orders in INVOICE HOLD Status : <B>' || ln_om_inv_hold_count || '</B><BR>';
        lc_message_body := lc_message_body || 'Total number of Pending Deposit Holds : <B>'|| ln_pend_dep_order_count ||'</B><BR>';
           lc_message_body := lc_message_body || 'Total number of other Holds : <B>'|| ln_om_hold_order_count ||'</B><BR>';
      lc_message_body := lc_message_body || 'Total number of orders stuck in Interface table : <B>'|| ln_om_int_order_count ||'</B><BR>';
        lc_message_body := lc_message_body || '<BR><B><font color="FF0000">ISSUE(S):</FONT></B><BR>';
       lc_message_subject:= 'HVOP ALERT -' || lc_instance;
      
        IF ln_om_entered_count > ln_sas_order_count * ln_threshold_val/100  THEN
            lc_message_subject:= 'HVOP ALERT ***page*** -' ||lc_instance;
            lc_message_body := lc_message_body ||'<B>** Number of orders in ENTERED status breached the threshold value. </B><BR>';
            lc_email_page := 'Y';
        END IF;
        IF ln_om_booked_count > ln_sas_order_count * ln_threshold_val/100  THEN

            lc_message_subject:= 'HVOP ALERT ***page*** -' ||lc_instance;
            lc_message_body := lc_message_body ||'<B>** Number of orders in BOOKED status breached the threshold value. </B><BR>' ;
            lc_email_page := 'Y';
        END IF;
        IF ln_om_inv_hold_count > ln_sas_order_count * ln_threshold_val/100  THEN

            lc_message_subject:= 'HVOP ALERT ***page*** -' ||lc_instance;
            lc_message_body := lc_message_body ||'<B>** Number of orders in INVOICE HOLD status breached the threshold value. </B><BR>';
            lc_email_page := 'Y';
        END IF;
        IF ln_om_hold_order_count > ln_sas_order_count * ln_threshold_val/100 THEN

            lc_message_subject:= 'HVOP ALERT ***page*** -' ||lc_instance;
            lc_message_body := lc_message_body || '<B>** Number of orders in HOLD status breached the threshold value. </B><BR>';
            lc_email_page := 'Y';
        END IF;
        IF ln_om_int_order_count > ln_sas_order_count * ln_threshold_val/100 THEN

        lc_message_subject:= 'HVOP ALERT ***page*** -' ||lc_instance;
            lc_message_body := lc_message_body || '<B>** Number of orders in Interface table breached the threshold value. </B><BR>';
            lc_email_page := 'Y';
        END IF;
      If lc_email_page = 'N' THEN
       lc_message_body := lc_message_body ||'No issues noticed.Job ran normally. </BR><br>';
      END IF;
    --IF lc_email_page = 'Y' THEN

       fnd_file.put_line (fnd_file.LOG, 'Email Page ***'||lc_email_page);
       fnd_file.put_line (fnd_file.LOG, 'Email List ***'||p_email_list);
       fnd_file.put_line (fnd_file.LOG, 'Email Subject ***'||lc_message_subject);
       fnd_file.put_line (fnd_file.LOG, 'Email Body ***'||lc_message_body);

       XX_OM_EMAIL_HANDLER_OUT.mime_mail(  sender => 'OM_HVOP',
                                            recipients => p_email_list,
                                            subject => lc_message_subject,
                                            mime_type => 'text/html',
                                            message => lc_message_body);
    --END IF;
EXCEPTION
    WHEN No_data_found THEN
        lc_error_message := 'No Data Found';
         p_status := 'N';
          
    WHEN OTHERS THEN
        lc_error_message := 'Unknown Error Occured';
        p_status := 'N';
         
End hvop_error_count;


-- **** Added SR_EXCEPTION_COUNT PROCEDURE ON 22-MAR-2011 ************************



PROCEDURE  sr_exception_count( errbuf             OUT VARCHAR2
                             , retcode             OUT NUMBER
                             , p_email_list        IN VARCHAR2
                             ) IS

ln_exception_count        NUMBER :=0;
lc_message                 VARCHAR2(50);
lc_email_page              VARCHAR2(1):='N';
lc_mail_status             VARCHAR2(1);
lc_error_message           VARCHAR2(1000);
p_status                   VARCHAR2(10);
lc_message_create          VARCHAR2(200);
lc_message_subject         VARCHAR2(200);
lc_message_body            CLOB;
ln_op_unit                 NUMBER :=0;
crlf                       VARCHAR2(10) := chr(13) || chr(10);
ln_instance                NUMBER;
lc_instance                VARCHAR2(100);
lc_email_list              VARCHAR2(10000) := p_email_list ;

BEGIN

-- Getting the Instance Name
    SELECT INSTR(UPPER(instance_name),'PR'),instance_name
      INTO ln_instance,lc_instance
      FROM v$instance;
      fnd_file.put_line (fnd_file.LOG, 'Instance Name '||lc_instance);
-- Check how many Exceptions Logged in Exceptions Table in last 1 hr
    SELECT count(*)
      INTO ln_exception_count
      FROM xx_om_sr_exceptions
     WHERE notify_flag = 'Y'
       AND  ROUND(TO_NUMBER(SYSDATE-creation_date)*1440) < 60;

--If count is more than zero
    IF ln_exception_count > 5 THEN
        lc_message_body  :=lc_message_body  || '<B><font color="FF0000">********************  SR EXCEPTION ALERT  ******************</FONT></B>'||'<BR>';
        lc_message_body  :=lc_message_body  || '<font color="#0000ff">Message from SR Exception Alert system</FONT>'||'<BR>';
        lc_message_body := lc_message_body  || '<BR><B>Total number of Exceptions in last 60 mins are : <B>'|| ln_exception_count ||'</B></BR>';

      IF ln_instance > 0 THEN
            lc_email_page := 'Y';
        lc_message_subject := 'TDS EXCEPTIONS ALERT ***PAGE***-' || lc_instance;
    ELSE
        lc_email_page := 'N';
        lc_message_subject := 'TDS EXCEPTIONS ALERT-' || lc_instance;
    END IF ;

    --IF lc_email_page = 'Y' THEN
       fnd_file.put_line (fnd_file.LOG, 'Email Page ***'||lc_email_page);
       fnd_file.put_line (fnd_file.LOG, 'Email List ***'||p_email_list);
       fnd_file.put_line (fnd_file.LOG, 'Email Subject ***'||lc_message_subject);
       fnd_file.put_line (fnd_file.LOG, 'Email Body ***'||lc_message_body);

       BEGIN
           XX_OM_EMAIL_HANDLER_OUT.mime_mail( sender     => 'TDS_EXCEPTIONS_ALET'
                                            , recipients => lc_email_list
                                            , subject    => lc_message_subject
                                            , mime_type  => 'text/html'
                                            , message    => lc_message_body
                                            );
       EXCEPTION
           WHEN OTHERS THEN
               lc_error_message := 'Unknown Error Occured';
               p_status := 'N';
       END ;

    END IF;
    --END IF;
EXCEPTION
    WHEN No_data_found THEN
        lc_error_message := 'No Data Found';
         p_status := 'N';
    WHEN OTHERS THEN
        lc_error_message := 'Unknown Error Occured';
        p_status := 'N';
End sr_exception_count;

END ;
/
show errors;