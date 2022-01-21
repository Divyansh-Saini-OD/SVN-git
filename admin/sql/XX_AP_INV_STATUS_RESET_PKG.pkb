CREATE OR REPLACE
PACKAGE BODY APPS.XX_AP_INV_STATUS_RESET_PKG
  -- +============================================================================================+
  -- |       Office Depot - Project Simplify                                         |
  -- +============================================================================================+
  -- |  Name    :  XX_AP_INV_STATUS_RESET_PKG                                                |
  -- |  Description :  PLSQL Package to reset event_status_code to 'U' for AP Trade Invoices    |
  -- |  RICE ID:    E3522                                                                        |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         19/APR/2017  M K Pramod Kumar Initial version                                  |
  -- | 1.1         19/APR/2017  M K Pramod Kumar Modified to remove Invoice ID Date Parameters    |
  -- | 1.2         23/APR/2017  M K Pramod Kumar Modified to use AP_Holds_all LastUpdateDate for Selection
  -- +============================================================================================+
AS
  gc_debug VARCHAR2(1) := 'N';
  /*********************************************************************
  * Procedure used to log based on gb_debug value or if p_force is TRUE.
  * Will log to dbms_output if request id is not set,
  * else will log to concurrent program log file.  Will prepend
  * timestamp to each message logged.  This is useful for determining
  * elapse times.
  *********************************************************************/
PROCEDURE print_debug_msg(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT FALSE)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  IF (gc_debug  = 'Y' OR p_force) THEN
    lc_Message := P_Message;
    fnd_file.put_line (fnd_file.log, lc_Message);
    IF ( fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
      dbms_output.put_line (lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  dbms_output.put_line ('Error in Procedure print_debug_msg.SQLERRM-' ||sqlerrm);
END print_debug_msg;
/*********************************************************************
* Procedure used to out the text to the concurrent program.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program output file.
*********************************************************************/
PROCEDURE print_out_msg(
    p_message IN VARCHAR2)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  lc_message := p_message;
  fnd_file.put_line (fnd_file.output, lc_message);
  IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
    dbms_output.put_line (lc_message);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.output, 'Error in Procedure print_out_msg.SQLERRM-' ||sqlerrm);
END print_out_msg;
-- +======================================================================+
-- | Name        :  invoice_event_status_reset                            |
-- | Description :  This procedure will be called from the concurrent prog|
-- |                " "          |          |
-- |                                                                      |
-- | Parameters  :                                                        |
-- |                                                                      |
-- | Returns     :  x_errbuf, x_retcode                                   |
-- |                                                                      |
-- +======================================================================+
PROCEDURE INVOICE_EVENT_STATUS_RESET(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2 
	 )
AS
  CURSOR cur_validated_unacct_inv
  IS
    SELECT  /*+ LEADING (h) */
      aia.invoice_id,
      aia.invoice_num,
      aia.org_id,
                xte.application_id,
      xte.entity_id,
      xte.legal_entity_id,
      xte.ledger_id,
      xte.transaction_number,
      xte.entity_code,
      xe.event_date,
      xe.event_id,
      xe.event_type_code,
      xe.event_status_code
    FROM xla_events xe,
      xla_transaction_entities xte,
              ap_invoices_all aia,
              (SELECT /*+ INDEX(aph XX_AP_HOLDS_N2) */   
              distinct aph.invoice_id           
          FROM ap_holds_all aph           
         WHERE 1=1 
         AND aph.last_update_date BETWEEN sysdate-2 AND SYSDATE                           
         AND aph.release_lookup_code IS NOT NULL
        ) h           
    WHERE 1=1
      AND aia.invoice_id=h.invoice_id   
      AND aia.invoice_type_lookup_code IN ('STANDARD','DEBIT','CREDIT')
      AND EXISTS
      (SELECT 'x'
      FROM xx_fin_translatevalues tv ,
        xx_fin_translatedefinition td
      WHERE td.TRANSLATION_NAME ='XX_AP_TR_MATCH_INVOICES'
      AND tv.TRANSLATE_ID       =td.TRANSLATE_ID
      AND tv.enabled_flag       ='Y'
      AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
      AND tv.target_value1 =aia.source
      )
AND NOT EXISTS
    (SELECT 'x'
    FROM AP_HOLDS_ALL
    WHERE INVOICE_ID         =aia.invoice_id
    AND RELEASE_LOOKUP_CODE IS NULL
    )
    AND xte.source_id_int_1=aia.invoice_id
    AND xte.application_id   =200
    AND XTE.ENTITY_CODE      = 'AP_INVOICES'
    AND xe.entity_id         =xte.entity_id
    AND xe.application_id    =xte.application_id
    AND xe.event_status_code ='I'
    AND AP_INVOICES_PKG.GET_APPROVAL_STATUS(aia.invoice_id, aia.invoice_amount, aia.payment_status_flag, aia.invoice_type_lookup_code ) IN ('APPROVED','CANCELLED');
                               
	
TYPE cur_val_unacct_inv_type
IS
  TABLE OF cur_validated_unacct_inv%ROWTYPE;
  lv_val_unacct_inv_tab cur_val_unacct_inv_type;
  ld_date							DATE;
   p_event_source_info xla_events_pub_pkg.t_event_source_info;
     lv_event_class_Code xla_event_types_b.event_class_Code%type;
BEGIN
  print_debug_msg('Program Start Time Stamp: '||TO_CHAR(sysdate,'DD-MON-RR HH24:MI:SS'),TRUE);
  
  xla_security_pkg.set_security_context(602);
 

  OPEN cur_validated_unacct_inv;
  FETCH cur_validated_unacct_inv BULK COLLECT INTO lv_val_unacct_inv_tab;
  CLOSE cur_validated_unacct_inv;
  print_debug_msg('Invoices Selected in Main Cursor :'||lv_val_unacct_inv_tab.COUNT,TRUE);
  IF lv_val_unacct_inv_tab.COUNT>0 THEN

    FOR i IN 1.. lv_val_unacct_inv_tab.COUNT
    LOOP
	
	BEGIN
      SELECT event_class_Code
      INTO lv_event_class_Code
      FROM xla_event_types_b
      WHERE event_type_code=lv_val_unacct_inv_tab(i).event_type_code
      AND application_id   =lv_val_unacct_inv_tab(i).application_id
      AND enabled_flag     ='Y';
    EXCEPTION
    WHEN OTHERS THEN
      lv_event_class_Code:='INVOICES';
    END;
    BEGIN
      p_event_source_info.source_application_id := NULL;
      p_event_source_info.application_id        := lv_val_unacct_inv_tab(i).application_id;
      p_event_source_info.legal_entity_id       := lv_val_unacct_inv_tab(i).legal_entity_id;
      p_event_source_info.ledger_id             := lv_val_unacct_inv_tab(i).ledger_id;
      p_event_source_info.entity_type_code      := lv_val_unacct_inv_tab(i).entity_code;
      p_event_source_info.transaction_number    := lv_val_unacct_inv_tab(i).transaction_number;
      p_event_source_info.source_id_int_1       := lv_val_unacct_inv_tab(i).invoice_id;
      p_event_source_info.source_id_int_2       := NULL;
      p_event_source_info.source_id_int_3       := NULL;
      p_event_source_info.source_id_int_4       := NULL;
      p_event_source_info.source_id_char_1      := NULL;
      p_event_source_info.source_id_char_2      := NULL;
      p_event_source_info.source_id_char_3      := NULL;
      p_event_source_info.source_id_char_4      := NULL;
      xla_events_pub_pkg.update_event_status (p_event_source_info => p_event_source_info, p_event_class_code => lv_event_class_Code, p_event_type_code => lv_val_unacct_inv_tab(i).event_type_code, p_event_date => TRUNC(lv_val_unacct_inv_tab(i).event_date), p_event_status_code => 'U', -- un processed
      p_valuation_method => NULL, p_security_context => NULL );
      print_debug_msg('Event Status Code reset successfully for Invoice Id-'||lv_val_unacct_inv_tab(i).INVOICE_ID,TRUE);
    EXCEPTION
    WHEN OTHERS THEN
      print_debug_msg('Error during API Call to reset Event Status for Invoice Id-'||lv_val_unacct_inv_tab(i).INVOICE_ID||'.SQLERRM-'||sqlerrm,TRUE);
    END;	
	     
    END LOOP;
  END IF;
  commit;
  print_debug_msg('Program End Time Stamp: '||TO_CHAR(sysdate,'DD-MON-RR HH24:MI:SS'),TRUE);
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.LOG,SQLCODE||SQLERRM);
END invoice_event_status_reset;
END XX_AP_INV_STATUS_RESET_PKG;
/