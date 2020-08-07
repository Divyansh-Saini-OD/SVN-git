CREATE OR REPLACE 
PACKAGE BODY xx_ar_lbx_alert_pkg AS

-- +=====================================================================================================+
-- |                                Office Depot - Project Simplify                                      |
-- |                                     Oracle AMS Support                                              |
-- +=====================================================================================================+
-- |  Name:  XX_AR_LBX_ALERT_PKG (RICE ID : R7017)                                                       |
-- |                                                                                                     |
-- |  Description:  This package will be used for Lockbox Performance Monitoring Alert                   |
-- |                                                                                                     |
-- |    PUT_LOG_LINE                 This procedure will print log messages - Local Procedure            |
-- |    GET_TRANSLATIONS             This procedure will get the translation values - Local Procedure    |
-- |    FETCH_TRANSLATION_VALUES     This procedure will fetch and set the translation values            |
-- |    CHECK_LBX_SYSTEM_STATS       This procedure will check lockbox system statistics                 |
-- |    PREPARE_AND_SEND_EMAIL       This procedure will prepare and send email notification             |
-- |    LOCKBOX_ALERT_MAIN_PROC      This procedure will be called from concurrent program               |
-- |                                 XXARLBXALERT - OD: AR Lockbox Alert - File Split                    |
-- |    EXECUTION_TIME_MAIN_PROC     This procedure will be called from concurrent program               |
-- |                                 XXARLBXALERT_ETC - OD: AR Lockbox Alert - Execution Time Check      |
-- |                                                                                                     |
-- |  Change Record:                                                                                     |
-- +=====================================================================================================+
-- | Version     Date         Author               Remarks                                               |
-- | =========   ===========  =============        ======================================================|
-- | 1.0         03-Dec-2012  Abdul Khan           Initial version - QC Defect # 21270                   |
-- | 1.1         26-Oct-2015  Vasu Raparla         Removed Schema references for R12.2                   |
-- +=====================================================================================================+


    gc_source_field1    VARCHAR2(240)   :=  NULL;
    gc_target_field1    VARCHAR2(240)   :=  NULL;
    gc_target_field2    VARCHAR2(240)   :=  NULL;
    gc_target_field3    VARCHAR2(240)   :=  NULL;
    gc_target_field4    VARCHAR2(240)   :=  NULL;
    gc_target_field5    VARCHAR2(240)   :=  NULL;
    gc_target_field6    VARCHAR2(240)   :=  NULL;
    gc_target_field7    VARCHAR2(240)   :=  NULL;
    gc_target_field8    VARCHAR2(240)   :=  NULL;
    gc_target_field9    VARCHAR2(240)   :=  NULL;
    gc_target_field10   VARCHAR2(240)   :=  NULL;
    gc_target_field11   VARCHAR2(240)   :=  NULL;
    gc_target_field12   VARCHAR2(240)   :=  NULL;
    gc_target_field13   VARCHAR2(240)   :=  NULL;
    gc_target_field14   VARCHAR2(240)   :=  NULL;
    gc_target_field15   VARCHAR2(240)   :=  NULL;
    gc_source_value1    VARCHAR2(240)   :=  NULL;
    gc_target_value1    VARCHAR2(240)   :=  NULL;
    gc_target_value2    VARCHAR2(240)   :=  NULL;
    gc_target_value3    VARCHAR2(240)   :=  NULL;
    gc_target_value4    VARCHAR2(240)   :=  NULL;
    gc_target_value5    VARCHAR2(240)   :=  NULL;
    gc_target_value6    VARCHAR2(240)   :=  NULL;
    gc_target_value7    VARCHAR2(240)   :=  NULL;
    gc_target_value8    VARCHAR2(240)   :=  NULL;
    gc_target_value9    VARCHAR2(240)   :=  NULL;
    gc_target_value10   VARCHAR2(240)   :=  NULL;
    gc_target_value11   VARCHAR2(240)   :=  NULL;
    gc_target_value12   VARCHAR2(240)   :=  NULL;
    gc_target_value13   VARCHAR2(240)   :=  NULL;
    gc_target_value14   VARCHAR2(240)   :=  NULL;
    gc_target_value15   VARCHAR2(240)   :=  NULL;

    gc_short_name       VARCHAR2(30)    :=  NULL;
    gc_program_name     VARCHAR2(80)    :=  NULL;
    gc_customer_num     VARCHAR2(30)    :=  NULL;
    gc_customer_name    VARCHAR2(100)   :=  NULL;
    gc_user_name        VARCHAR2(100)   :=  NULL;
    gc_mainp_status     VARCHAR2(15)    :=  NULL;
    gn_org_id           NUMBER          :=  0;
    gn_customer_id      NUMBER          :=  0;
    gn_conc_req_id      NUMBER          :=  0;
    gn_user_id          NUMBER          :=  0;    
    gn_interim_count    NUMBER          :=  0;
    gn_nodes_count      NUMBER          :=  0;
    gn_query_tim_diff   NUMBER          :=  0;
    gd_exec_start_time  DATE            :=  NULL;
    
    
    -- +============================================================================+
    -- | Name             : PUT_LOG_LINE                                            |
    -- |                                                                            |
    -- | Description      : This procedure will print log messages                  |
    -- |                                                                            |
    -- | Parameters       : p_debug  IN  VARCHAR2 -- Debug Flag - Default N         |
    -- |                  : p_force  IN  VARCHAR2 -- Default Log - Default N        |
    -- |                  : p_buffer IN  VARCHAR2 -- Log Message                    |
    -- |                                                                            |
    -- | Change Record:                                                             |
    -- | ==============                                                             |
    -- | Version  Date         Author          Remarks                              |
    -- | =======  ===========  =============   ===================================  |
    -- | 1.0      03-Dec-2012  Abdul Khan      Initial version - QC Defect # 21270  |
    -- +============================================================================+        
    PROCEDURE put_log_line ( p_debug_flag   IN   VARCHAR2 DEFAULT 'N',
                             p_force        IN   VARCHAR2 DEFAULT 'N',
                             p_buffer       IN   VARCHAR2 DEFAULT ' '
                           ) 
    AS
    
    BEGIN
       IF (p_debug_flag = 'Y' OR p_force = 'Y')
       THEN
          -- IF called from a concurrent program THEN print into log file
          IF (fnd_global.conc_request_id > 0)
          THEN
             fnd_file.put_line (fnd_file.LOG, NVL (p_buffer, ' '));
          -- ELSE print on console
          ELSE
             DBMS_OUTPUT.put_line (SUBSTR (NVL (p_buffer, ' '), 1, 300));
          END IF;
       END IF;
    END put_log_line;

      
    -- +============================================================================+
    -- | Name             : GET_TRANSLATIONS                                        |
    -- |                                                                            |
    -- | Description      : This procedure will get the translation values          |
    -- |                                                                            |
    -- | Parameters       : p_translation_name  IN  VARCHAR2 -- Translation Name    |
    -- |                  : p_source_value1     IN  VARCHAR2 -- Source Value1       |
    -- |                  : p_debug_flag        IN  VARCHAR2 -- Debug Flag          |
    -- |                                                                            |
    -- | Change Record:                                                             |
    -- | ==============                                                             |
    -- | Version  Date         Author          Remarks                              |
    -- | =======  ===========  =============   ===================================  |
    -- | 1.0      03-Dec-2012  Abdul Khan      Initial version - QC Defect # 21270  |
    -- +============================================================================+        
    PROCEDURE get_translations ( p_debug_flag       IN  VARCHAR2,
                                 p_translation_name IN  VARCHAR2,
                                 p_source_field1    IN  VARCHAR2 
                               )
    AS
   
    BEGIN

        SELECT def.source_field1,
               def.target_field1,
               def.target_field2,
               def.target_field3,
               def.target_field4,
               def.target_field5,
               def.target_field6,
               def.target_field7,
               def.target_field8,
               def.target_field9,
               def.target_field10,
               def.target_field11,
               def.target_field12,
               def.target_field13,
               def.target_field14,
               def.target_field15,
               val.source_value1,
               val.target_value1,
               val.target_value2,
               val.target_value3,
               val.target_value4,
               val.target_value5,
               val.target_value6,
               val.target_value7,
               val.target_value8,
               val.target_value9,
               val.target_value10,
               val.target_value11,
               val.target_value12,
               val.target_value13,
               val.target_value14,
               val.target_value15
          INTO gc_source_field1,
               gc_target_field1,
               gc_target_field2,
               gc_target_field3,
               gc_target_field4,
               gc_target_field5,
               gc_target_field6,
               gc_target_field7,
               gc_target_field8,
               gc_target_field9,
               gc_target_field10,
               gc_target_field11,
               gc_target_field12,
               gc_target_field13,
               gc_target_field14,
               gc_target_field15,
               gc_source_value1,
               gc_target_value1,
               gc_target_value2,
               gc_target_value3,
               gc_target_value4,
               gc_target_value5,
               gc_target_value6,
               gc_target_value7,
               gc_target_value8,
               gc_target_value9,
               gc_target_value10,
               gc_target_value11,
               gc_target_value12,
               gc_target_value13,
               gc_target_value14,
               gc_target_value15    
          FROM xx_fin_translatedefinition def,
               xx_fin_translatevalues val
         WHERE def.translate_id     = val.translate_id
           AND def.translation_name = p_translation_name
           AND def.source_field1    = p_source_field1
           AND def.enabled_flag     = 'Y'
           AND val.enabled_flag     = 'Y'
           AND SYSDATE BETWEEN def.start_date_active AND NVL (def.end_date_active, SYSDATE + 1)
           AND SYSDATE BETWEEN val.start_date_active AND NVL (val.end_date_active, SYSDATE + 1);
      
    END get_translations;
    

    -- +============================================================================+
    -- | Name             : FETCH_TRANSLATION_VALUES                                |
    -- |                                                                            |
    -- | Description      : This procedure will fetch and set the translation values|
    -- |                                                                            |
    -- | Parameters       : p_return_status OUT VARCHAR2 -- SUCCESS OR FAILURE      |
    -- |                  : p_debug_flag    IN  VARCHAR2 -- Debug Flag              |
    -- |                                                                            |
    -- | Change Record:                                                             |
    -- | ==============                                                             |
    -- | Version  Date         Author          Remarks                              |
    -- | =======  ===========  =============   ===================================  |
    -- | 1.0      03-Dec-2012  Abdul Khan      Initial version - QC Defect # 21270  |
    -- +============================================================================+   
    PROCEDURE fetch_translation_values ( p_debug_flag    IN  VARCHAR2,
                                         p_return_status OUT VARCHAR2 
                                       )
    AS
    
        lc_translation_name     VARCHAR2(100)   :=  NULL;
        lc_source_field1        VARCHAR2(100)   :=  NULL;
        
    BEGIN
    
        lc_translation_name :=  'XX_AR_LOCKBOX_ALERT';
        lc_source_field1    :=  'Alert Email Setup';
        
        put_log_line (p_debug_flag, 'Y', ' ');
        put_log_line (p_debug_flag, 'N', 'PROCEDURE fetch_translation_values - Begin');
        put_log_line (p_debug_flag, 'Y', 'Translation Setup Details');
        put_log_line (p_debug_flag, 'Y', 'Translation Name     - '|| lc_translation_name);
        put_log_line (p_debug_flag, 'Y', 'Translation Values   ');
        
        --This procedure will fetch and set the translation values
        get_translations ( p_debug_flag        => p_debug_flag,
                           p_translation_name  => lc_translation_name, 
                           p_source_field1     => lc_source_field1
                         );
        
        put_log_line (p_debug_flag, 'Y', RPAD(gc_source_field1, 20, ' ')  || ' - ' || gc_source_value1);
        put_log_line (p_debug_flag, 'Y', RPAD(gc_target_field1, 20, ' ')  || ' - ' || gc_target_value1);
        put_log_line (p_debug_flag, 'Y', RPAD(gc_target_field2, 20, ' ')  || ' - ' || gc_target_value2);
        put_log_line (p_debug_flag, 'Y', RPAD(gc_target_field3, 20, ' ')  || ' - ' || gc_target_value3);
        put_log_line (p_debug_flag, 'Y', RPAD(gc_target_field4, 20, ' ')  || ' - ' || gc_target_value4);
        put_log_line (p_debug_flag, 'Y', RPAD(gc_target_field5, 20, ' ')  || ' - ' || gc_target_value5);
        put_log_line (p_debug_flag, 'Y', RPAD(gc_target_field6, 20, ' ')  || ' - ' || gc_target_value6);        
        put_log_line (p_debug_flag, 'N', RPAD(gc_target_field7, 20, ' ')  || ' - ' || gc_target_value7);
        put_log_line (p_debug_flag, 'N', RPAD(gc_target_field8, 20, ' ')  || ' - ' || gc_target_value8);
        put_log_line (p_debug_flag, 'N', RPAD(gc_target_field9, 20, ' ')  || ' - ' || gc_target_value9);
        put_log_line (p_debug_flag, 'N', RPAD(gc_target_field10, 20, ' ') || ' - ' || gc_target_value10);
        put_log_line (p_debug_flag, 'N', RPAD(gc_target_field11, 20, ' ') || ' - ' || gc_target_value11);
        put_log_line (p_debug_flag, 'N', RPAD(gc_target_field12, 20, ' ') || ' - ' || gc_target_value12);
        put_log_line (p_debug_flag, 'N', RPAD(gc_target_field13, 20, ' ') || ' - ' || gc_target_value13);
        put_log_line (p_debug_flag, 'N', RPAD(gc_target_field14, 20, ' ') || ' - ' || gc_target_value14);
        put_log_line (p_debug_flag, 'N', RPAD(gc_target_field15, 20, ' ') || ' - ' || gc_target_value15);
        
        p_return_status := 'SUCCESS';
        gc_mainp_status := 'SUCCESS';
        
    EXCEPTION
        WHEN OTHERS THEN
            put_log_line (p_debug_flag, 'Y', 'Exception at PROCEDURE fetch_translation_values : ' || SQLERRM);
            p_return_status := 'FAILURE';
            gc_mainp_status := 'FAILURE';
           
            xx_com_error_log_pub.log_error
                        (p_program_type                => 'CONCURRENT PROGRAM',
                         p_program_name                => gc_program_name,
                         p_module_name                 => gc_short_name,
                         p_error_location              => 'PROCEDURE fetch_translation_values',
                         p_error_message_count         => 1,
                         p_error_message_code          => 'E',
                         p_error_message               => 'Error : ' || SUBSTR(SQLERRM, 1, 80),
                         p_error_message_severity      => 'Major',
                         p_notify_flag                 => 'N',
                         p_object_type                 => 'PACKAGE BODY xx_ar_lbx_alert_pkg');
    
    END fetch_translation_values;
    
    
    -- +============================================================================+
    -- | Name             : CHECK_LBX_SYSTEM_STATS                                  |
    -- |                                                                            |
    -- | Description      : This procedure will check lockbox system statistics     |
    -- |                                                                            |
    -- | Parameters       : p_return_status OUT VARCHAR2 -- SUCCESS OR FAILURE      |
    -- |                  : p_debug_flag    IN  VARCHAR2 -- Debug Flag              |
    -- |                                                                            |
    -- | Change Record:                                                             |
    -- | ==============                                                             |
    -- | Version  Date         Author          Remarks                              |
    -- | =======  ===========  =============   ===================================  |
    -- | 1.0      03-Dec-2012  Abdul Khan      Initial version - QC Defect # 21270  |
    -- +============================================================================+   
    PROCEDURE check_lbx_system_stats   ( p_debug_flag    IN  VARCHAR2,
                                         p_return_status OUT VARCHAR2 
                                       )
    AS
    
        lc_trx_number   VARCHAR2(30)    :=  NULL;
        lc_inv_currency VARCHAR2(30)    :=  NULL;
        lc_start_time   VARCHAR2(25)    :=  NULL;
        lc_end_time     VARCHAR2(25)    :=  NULL;
        lc_phase        VARCHAR2(25)    :=  NULL;
        lc_status       VARCHAR2(25)    :=  NULL;
        lc_dev_phase    VARCHAR2(25)    :=  NULL;
        lc_dev_status   VARCHAR2(25)    :=  NULL;
        lc_message      VARCHAR2(25)    :=  NULL;
        lc_trx_date     DATE            :=  NULL;
        ln_amt_due_rem  NUMBER          :=  0;
        ln_request_id   NUMBER          :=  0;
        lb_req_status   BOOLEAN         :=  TRUE;
        
    BEGIN
    
        gn_interim_count    :=  NULL;
        gn_nodes_count      :=  NULL;
        
        put_log_line (p_debug_flag, 'Y', ' ');
        put_log_line (p_debug_flag, 'N', 'PROCEDURE check_lbx_system_stats - Begin');
        put_log_line (p_debug_flag, 'Y', 'Check Lockbox System Statistics');
        
        --This query will give you the current count of records in interim table  
        SELECT COUNT(parent_id)
          INTO gn_interim_count
          FROM xx_hz_hierarchy_nodes_interim;
          
        put_log_line (p_debug_flag, 'Y', RPAD('Current Count', 20, ' ') || ' - ' || gn_interim_count);  
    
        --Query to get the approx. count of records which are going to be inserted in the interim table after truncation.
        SELECT COUNT(parent_id)
          INTO gn_nodes_count
          FROM hz_hierarchy_nodes
         WHERE hierarchy_type = 'OD_FIN_PAY_WITHIN'
           AND effective_end_date > SYSDATE - fnd_profile.value('OD_PAYING_RELATIONSHIPS_END_DATED_DAYS');
        
        put_log_line (p_debug_flag, 'Y', RPAD('Expected Count', 20, ' ') || ' - ' || gn_nodes_count);
        
        --Query to get customer details
        SELECT account_name, 
               account_number,
               cust_account_id 
          INTO gc_customer_name,
               gc_customer_num,
               gn_customer_id
          FROM hz_cust_accounts
         WHERE account_number = gc_target_value5
           AND status         = 'A'
           AND rownum         = 1;   
        
        put_log_line (p_debug_flag, 'N', RPAD('Customer Number', 20, ' ') || ' - ' || gc_customer_num);
        put_log_line (p_debug_flag, 'Y', RPAD('Customer Name', 20, ' ') || ' - ' || gc_customer_name);
        
        INSERT INTO xx_ar_lockbox_alert
              (alert_request_id,
                alert_start_time,
                interim_count,
                nodes_count,
                customer_num,
                last_updated_by,
                last_update_date,
                last_update_login,
                created_by,
                creation_date
              ) VALUES
              ( gn_conc_req_id,
                gd_exec_start_time,
                gn_interim_count,
                gn_nodes_count,
                gc_customer_num,
                gn_user_id,
                gd_exec_start_time,
                USERENV ('SESSIONID'),
                gn_user_id,
                gd_exec_start_time
              );
              
        COMMIT;      
        
        lc_start_time := TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS');
        
        --Submit XXARLBXALERT_ETC - OD: AR Lockbox Alert - Execution Time Check 
        ln_request_id := FND_REQUEST.SUBMIT_REQUEST ( application   => 'XXFIN',
                                                      program       => 'XXARLBXALERT_ETC',
                                                      description   => '',
                                                      start_time    => '',
                                                      sub_request   => FALSE,
                                                      argument1     => gc_customer_num,
                                                      argument2     => p_debug_flag
                                                    );
                                                    
        COMMIT;
        
        put_log_line (p_debug_flag, 'Y', RPAD('Request ID Submitted', 20, ' ') || ' - ' || ln_request_id); 
               
        IF ln_request_id <> 0 THEN            
            
            UPDATE xx_ar_lockbox_alert
               SET child_request_id    = ln_request_id,
                   child_start_time    = SYSDATE,
                   query_name1         = gc_target_field4,
                   query_threshold1    = TO_NUMBER (gc_target_value4)
             WHERE alert_request_id    = FND_GLOBAL.CONC_REQUEST_ID;
        
            COMMIT;
            
            lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST ( request_id => ln_request_id,
                                                               interval   => 1,
                                                               max_wait   => TO_NUMBER (gc_target_value4),
                                                               phase      => lc_phase,
                                                               status     => lc_status,
                                                               dev_phase  => lc_dev_phase,
                                                               dev_status => lc_dev_status,
                                                               message    => lc_message
                                                             );                                            
        
        END IF;
        
        lc_end_time         := TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS');
        gn_query_tim_diff   := ROUND((TO_DATE(lc_end_time,'DD-MON-YYYY HH24:MI:SS') - TO_DATE(lc_start_time,'DD-MON-YYYY HH24:MI:SS')) * 24 * 60 * 60);
        
        put_log_line (p_debug_flag, 'Y', RPAD('Request Status', 20, ' ') || ' - ' || NVL(lc_dev_phase, lc_phase));
        put_log_line (p_debug_flag, 'N', RPAD('Query Start Time', 20, ' ') || ' - ' || lc_start_time);
        
        IF (lc_dev_phase = 'COMPLETE' OR lc_phase = 'Completed') THEN
            put_log_line (p_debug_flag, 'N', RPAD('Query End Time', 20, ' ') || ' - ' || lc_end_time);
            put_log_line (p_debug_flag, 'Y', RPAD('Query Exec Time', 20, ' ') || ' - ' || gn_query_tim_diff || ' seconds');
        ELSE
            put_log_line (p_debug_flag, 'N', RPAD('Query End Time', 20, ' ') || ' - Query is still running');
            put_log_line (p_debug_flag, 'Y', RPAD('Query Exec Time', 20, ' ') || ' - Running beyond threshold value (' || gc_target_value4 || ' seconds)');
            gn_query_tim_diff := TO_NUMBER (gc_target_value4) + 1;
        END IF;
        
        p_return_status := 'SUCCESS';
        gc_mainp_status := 'SUCCESS';
        
    EXCEPTION
        WHEN OTHERS THEN
            put_log_line (p_debug_flag, 'Y', 'Exception at PROCEDURE check_lbx_system_stats : ' || SQLERRM);
            p_return_status := 'FAILURE';
            gc_mainp_status := 'FAILURE';
            
            xx_com_error_log_pub.log_error
                        (p_program_type                => 'CONCURRENT PROGRAM',
                         p_program_name                => gc_program_name,
                         p_module_name                 => gc_short_name,
                         p_error_location              => 'PROCEDURE check_lbx_system_stats',
                         p_error_message_count         => 2,
                         p_error_message_code          => 'E',
                         p_error_message               => 'Error : ' || SUBSTR(SQLERRM, 1, 80),
                         p_error_message_severity      => 'Major',
                         p_notify_flag                 => 'N',
                         p_object_type                 => 'PACKAGE BODY xx_ar_lbx_alert_pkg');
    
    END check_lbx_system_stats;


    -- +============================================================================+
    -- | Name             : PREPARE_AND_SEND_EMAIL                                  |
    -- |                                                                            |
    -- | Description      : This procedure will prepare and send email notification |
    -- |                                                                            |
    -- | Parameters       : p_return_status OUT VARCHAR2 -- SUCCESS OR FAILURE      |
    -- |                  : p_debug_flag    IN  VARCHAR2 -- Debug Flag              |
    -- |                  : p_from          IN  VARCHAR2                            |
    -- |                  : p_recipient     IN  VARCHAR2                            |
    -- |                  : p_mail_host     IN  VARCHAR2                            |
    -- |                  : p_subject       IN  VARCHAR2                            |
    -- |                  : p_title_html    IN  VARCHAR2                            |
    -- |                  : p_body_hdr_html IN  VARCHAR2                            |
    -- |                  : p_body_dtl_html IN  VARCHAR2                            |
    -- |                                                                            |
    -- | Change Record:                                                             |
    -- | ==============                                                             |
    -- | Version  Date         Author          Remarks                              |
    -- | =======  ===========  =============   ===================================  |
    -- | 1.0      03-Dec-2012  Abdul Khan      Initial version - QC Defect # 21270  |
    -- +============================================================================+   
    PROCEDURE prepare_and_send_email   ( p_debug_flag    IN  VARCHAR2,
                                         p_from          IN  VARCHAR2,
                                         p_recipient     IN  VARCHAR2,
                                         p_mail_host     IN  VARCHAR2,
                                         p_subject       IN  VARCHAR2,
                                         p_title_html    IN  VARCHAR2,
                                         p_body_hdr_html IN  VARCHAR2,
                                         p_body_dtl_html IN  VARCHAR2,
                                         p_return_status OUT VARCHAR2 
                                       )
    AS

        v_from              VARCHAR2(80)    := NULL;
        v_recipient         VARCHAR2(80)    := NULL;
        v_mail_host         VARCHAR2(30)    := NULL;
        v_subject           VARCHAR2(80)    := NULL;
        lc_title_html       VARCHAR2(100)   := NULL;
        lc_body_hdr_html    VARCHAR2(4000)  := NULL;
        lc_body_dtl_html    VARCHAR2(4000)  := NULL;
    
        lc_instance         VARCHAR2(100)   := NULL;
        lc_host_name        VARCHAR2(100)   := NULL;
        crlf                VARCHAR2(2)     := chr(13) || chr(10);
        v_mail_conn         utl_smtp.connection;

    BEGIN

        v_from              := p_from;
        v_recipient         := p_recipient;
        v_mail_host         := p_mail_host;
        v_subject           := p_subject;
        lc_title_html       := p_title_html;
        lc_body_hdr_html    := p_body_hdr_html;
        lc_body_dtl_html    := p_body_dtl_html;
    
        put_log_line (p_debug_flag, 'Y', ' ');
        put_log_line (p_debug_flag, 'N', 'PROCEDURE prepare_and_send_email - Begin');
        put_log_line (p_debug_flag, 'Y', 'Prepare and Send Email Notification');
        put_log_line (p_debug_flag, 'Y', RPAD('From', 20, ' ') || ' - ' || v_from);
        put_log_line (p_debug_flag, 'Y', RPAD('To', 20, ' ') || ' - ' || v_recipient);
        put_log_line (p_debug_flag, 'Y', RPAD('Subject', 20, ' ') || ' - ' || v_subject);
        put_log_line (p_debug_flag, 'Y', RPAD('Email Server', 20, ' ') || ' - ' || v_mail_host);

        SELECT instance_name, host_name
          INTO lc_instance, lc_host_name
          FROM v$instance;
      
        BEGIN

            v_mail_conn := utl_smtp.open_connection(v_mail_host,25);
            utl_smtp.helo(v_mail_conn,v_mail_host);
            utl_smtp.mail(v_mail_conn,v_from);
            utl_smtp.rcpt(v_mail_conn,v_recipient);

            utl_smtp.data(v_mail_conn,'Return-Path: ' || v_from || utl_tcp.crlf || 
                'Sent: ' || TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS') || utl_tcp.crlf || 
                'From: ' || v_from || utl_tcp.crlf || 
                'Subject: ' || v_subject || ' | ' || lc_instance ||utl_tcp.crlf || 
                'To: ' || v_recipient || utl_tcp.crlf ||
                'Content-Type: multipart/mixed; boundary="MIME.Bound"' ||utl_tcp.crlf || utl_tcp.crlf || '--MIME.Bound' || utl_tcp.crlf ||
                'Content-Type: multipart/alternative; boundary="MIME.Bound2"' || utl_tcp.crlf || utl_tcp.crlf || '--MIME.Bound2' || utl_tcp.crlf ||
                'Content-Type: text/html; ' || utl_tcp.crlf ||
                'Content-Transfer_Encoding: 7bit' || utl_tcp.crlf ||utl_tcp.crlf ||
                
                utl_tcp.crlf ||'<html><head><title>'||lc_title_html||'</title></head>
                <body> <font face = "verdana" size = "2" color="#336699">'||lc_body_hdr_html||'<br><br>
                '||lc_body_dtl_html||'
                <br><br>
                <b> Note </b> - ' || gc_target_value14 || '
                <br><hr>
                RICE ID - R7017 | Instance Name - ' || lc_instance || '  |  Host Name - ' || lc_host_name || '  |  Request ID - ' || gn_conc_req_id  || '
                </font></body></html>' ||
                utl_tcp.crlf || '--MIME.Bound2--' || utl_tcp.crlf || utl_tcp.crlf);
                  
            utl_smtp.quit(v_mail_conn);

            p_return_status := 'SUCCESS';
            gc_mainp_status := 'SUCCESS';

        EXCEPTION 
            WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
            lc_body_hdr_html := lc_body_hdr_html ||
                '<br> <b> ' || gc_target_value15 || ' </b> 
                <br> Error Details : ' || SQLERRM;
        
            put_log_line (p_debug_flag, 'Y', 'Exception at PROCEDURE prepare_and_send_email : ' || SQLERRM);
            p_return_status := 'FAILURE';
            gc_mainp_status := 'FAILURE';
        
        END;

    EXCEPTION
        WHEN OTHERS THEN
            put_log_line (p_debug_flag, 'Y', 'Exception at PROCEDURE prepare_and_send_email : ' || SQLERRM);
            p_return_status := 'FAILURE';
            gc_mainp_status := 'FAILURE';
            --raise_application_error(-20000, 'Unable to Send Mail : ' || SQLERRM);
            
            xx_com_error_log_pub.log_error
                        (p_program_type                => 'CONCURRENT PROGRAM',
                         p_program_name                => gc_program_name,
                         p_module_name                 => gc_short_name,
                         p_error_location              => 'PROCEDURE prepare_and_send_email',
                         p_error_message_count         => 3,
                         p_error_message_code          => 'E',
                         p_error_message               => 'Error : ' || SUBSTR(SQLERRM, 1, 80),
                         p_error_message_severity      => 'Major',
                         p_notify_flag                 => 'N',
                         p_object_type                 => 'PACKAGE BODY xx_ar_lbx_alert_pkg');

    END prepare_and_send_email;


    -- +============================================================================+
    -- | Name             : LOCKBOX_ALERT_MAIN_PROC                                 |
    -- |                                                                            |
    -- | Description      : This procedure will be called from concurrent program   |
    -- |                  : XXARLBXALERT - OD: AR Lockbox Alert - File Split        |
    -- |                                                                            |
    -- | Parameters       : retcode         OUT NOCOPY NUMBER                       |
    -- |                  : errbuf          OUT NOCOPY VARCHAR2                     |
    -- |                  : p_recipient     IN  VARCHAR2                            |
    -- |                  : p_mail_host     IN  VARCHAR2                            |
    -- |                  : p_debug_flag    IN  VARCHAR2 -- Debug Flag              |
    -- |                                                                            |
    -- | Change Record:                                                             |
    -- | ==============                                                             |
    -- | Version  Date         Author          Remarks                              |
    -- | =======  ===========  =============   ===================================  |
    -- | 1.0      03-Dec-2012  Abdul Khan      Initial version - QC Defect # 21270  |
    -- +============================================================================+   
    PROCEDURE lockbox_alert_main_proc  ( errbuf          OUT NOCOPY VARCHAR2,
                                         retcode         OUT NOCOPY NUMBER, 
                                         p_recipient     IN         VARCHAR2,
                                         p_mail_host     IN         VARCHAR2,
                                         p_debug_flag    IN         VARCHAR2 DEFAULT 'N'
                                       ) 
    AS
    
        lc_recipient        VARCHAR2(80)    :=  NULL;
        lc_mail_host        VARCHAR2(30)    :=  NULL;
        lc_from             VARCHAR2(80)    :=  NULL; -- gc_target_value6
        lc_subject          VARCHAR2(80)    :=  NULL; -- gc_target_value7
        lc_title_html       VARCHAR2(100)   :=  NULL; -- gc_target_value8
        lc_body_hdr_html    VARCHAR2(4000)  :=  NULL; -- gc_target_value9
        lc_body_dtl_html    VARCHAR2(4000)  :=  NULL;
        lc_trans_status     VARCHAR2(15)    :=  NULL;
        lc_stats_status     VARCHAR2(15)    :=  NULL;
        lc_email_status     VARCHAR2(15)    :=  NULL;
        lc_source_field1    VARCHAR2(30)    :=  NULL;
        lc_source_value1    VARCHAR2(80)    :=  NULL;
        
    BEGIN
    
        put_log_line (p_debug_flag, 'Y', ' ');
        put_log_line (p_debug_flag, 'N', 'PROCEDURE lockbox_alert_main_proc - Begin');
        put_log_line (p_debug_flag, 'N', ' ');
        put_log_line (p_debug_flag, 'Y', 'Lockbox Alert Main Procedure - Start Time : ' || TO_CHAR(SYSDATE, 'DD-Mon-YYYY HH24:MI:SS'));
        put_log_line (p_debug_flag, 'Y', ' ');
        put_log_line (p_debug_flag, 'Y', RPAD('Parameters', 20, ' '));
        put_log_line (p_debug_flag, 'Y', RPAD('Email Recipient', 20, ' ') || ' - ' || p_recipient);
        put_log_line (p_debug_flag, 'Y', RPAD('Email Host', 20, ' ') || ' - ' || p_mail_host);
        put_log_line (p_debug_flag, 'Y', RPAD('Debug Flag', 20, ' ') || ' - ' || p_debug_flag);
        
        
        BEGIN
        
            gn_org_id := FND_GLOBAL.ORG_ID;
            dbms_application_info.set_client_info(gn_org_id);
            
            gd_exec_start_time := SYSDATE;
            
            SELECT request_id,
                   program_short_name, 
                   program,
                   requested_by, 
                   requestor
              INTO gn_conc_req_id,
                   gc_short_name,
                   gc_program_name,
                   gn_user_id,
                   gc_user_name
              FROM fnd_conc_req_summary_v
             WHERE request_id = FND_GLOBAL.CONC_REQUEST_ID;
                             
            put_log_line (p_debug_flag, 'N', ' ');
            put_log_line (p_debug_flag, 'N', RPAD('Org ID', 20, ' ') || ' - ' || gn_org_id);   
            put_log_line (p_debug_flag, 'N', RPAD('Requestor', 20, ' ') || ' - ' || gc_user_name);
                
            SELECT def.target_field1,
                   val.target_value1
              INTO lc_source_field1,
                   lc_source_value1
              FROM xx_fin_translatedefinition def, 
                   xx_fin_translatevalues val
             WHERE def.translate_id     = val.translate_id
               AND def.translation_name = 'AR_EBL_EMAIL_CONFIG'
               AND def.target_field1    = 'SMTP_SERVER'
               AND def.enabled_flag     = 'Y'
               AND val.enabled_flag     = 'Y'
               AND SYSDATE BETWEEN def.start_date_active AND NVL (def.end_date_active, SYSDATE + 1)
               AND SYSDATE BETWEEN val.start_date_active AND NVL (val.end_date_active, SYSDATE + 1);
               
            put_log_line (p_debug_flag, 'Y', ' ');
            put_log_line (p_debug_flag, 'Y', 'Translation Name     - AR_EBL_EMAIL_CONFIG');
            put_log_line (p_debug_flag, 'Y', RPAD(lc_source_field1, 20, ' ') || ' - ' || lc_source_value1);
             
            lc_mail_host   :=  lc_source_value1;
            
            --This procedure will fetch and set the translation values 
            fetch_translation_values ( p_debug_flag    => p_debug_flag,
                                       p_return_status => lc_trans_status 
                                     );
            put_log_line (p_debug_flag, 'N', 'PROCEDURE fetch_translation_values - Return Status : ' || lc_trans_status);
        
            IF lc_trans_status = 'SUCCESS' THEN
                --This procedure will check lockbox system statistics  
                check_lbx_system_stats   ( p_debug_flag    => p_debug_flag,
                                           p_return_status => lc_stats_status  
                                         );
                put_log_line (p_debug_flag, 'N', 'PROCEDURE check_lbx_system_stats   - Return Status : ' || lc_stats_status);  
                
                IF lc_stats_status  = 'SUCCESS' THEN
                
                    lc_from             :=  gc_target_value6;
                    lc_subject          :=  gc_target_value7;
                    lc_title_html       :=  gc_target_value8;
                    lc_body_hdr_html    :=  gc_target_value9;
                
                    IF gc_user_name = 'SVC_ESP_FIN' THEN
                        
                        lc_recipient     :=  NVL(p_recipient, gc_target_value1);
                    
                    ELSE
                    
                        IF p_recipient IS NOT NULL THEN
                        
                            lc_recipient     :=  p_recipient;
                        
                        ELSE
                        
                            SELECT DISTINCT LOWER(ppf.email_address)
                              INTO lc_recipient
                              FROM fnd_user fndu,
                                   per_all_people_f ppf
                             WHERE ppf.person_id             = fndu.employee_id
                               AND ppf.current_employee_flag = 'Y'
                               AND fndu.user_id              = gn_user_id;

                            lc_recipient     :=  NVL(lc_recipient, gc_target_value1);  
                        
                        END IF;
                         
                    
                    END IF;
                    
                    lc_mail_host     :=  NVL(p_mail_host, lc_mail_host);
                    
                    --If query execution  time is greater than the threshold defined in translation
                    IF gn_query_tim_diff > TO_NUMBER(gc_target_value4) THEN
                    
                        lc_subject       := lc_subject || ' (Action Required)';
                    
                        lc_body_hdr_html := '<font face = "verdana" size = "3" color="#990000"> <p align = "CENTER"> <b> <u>'
                                            || lc_body_hdr_html || ' - Action Required (File Split) for Cycle Date ' || TO_CHAR(SYSDATE, 'MM/DD') || '
                                            </u></b></p></font>';

                        lc_body_dtl_html := '<font color="#990000"><b>' || gc_target_value10 || ' at ' || TO_CHAR(SYSDATE, 'DD-Mon-YYYY HH:MI:SS AM') || ' - ' || gn_interim_count || ' </b> <br><br>
                                            <b>' || gc_target_value11 || ' - ' || gn_nodes_count || ' </b> <br><br>
                                            <b>' || gc_target_value12 || ' - Running beyond threshold value (' || gc_target_value4 || ' seconds) </b> <br><br><br>
                                            <b><u>' || gc_target_value13 || '</u></b> <br><br></font>';                     
                                                
                    ELSE
                    
                        lc_subject       := lc_subject || ' (No Action Required)';
                        
                        lc_body_hdr_html := '<font face = "verdana" size = "3" color="#336899"> <p align = "CENTER"> <b> <u>'
                                            || lc_body_hdr_html || ' - No Action Required for Cycle Date ' || TO_CHAR(SYSDATE, 'MM/DD') || '
                                            </u></b></p></font>';
                                            
                        lc_body_dtl_html := '<b>' || gc_target_value10 || ' at ' || TO_CHAR(SYSDATE, 'DD-Mon-YYYY HH:MI:SS AM') || ' - ' || gn_interim_count || ' </b> <br><br>
                                            <b>' || gc_target_value11 || ' - ' || gn_nodes_count || ' </b> <br><br>
                                            <b>' || gc_target_value12 || ' - ' || gn_query_tim_diff  || ' </b> <br><br>'; 
                    
                    END IF;
                                   
                    --This procedure will prepare and send email notification
                    prepare_and_send_email   ( p_debug_flag    => p_debug_flag,
                                               p_from          => lc_from,
                                               p_recipient     => lc_recipient,
                                               p_mail_host     => lc_mail_host,
                                               p_subject       => lc_subject,
                                               p_title_html    => lc_title_html,
                                               p_body_hdr_html => lc_body_hdr_html,
                                               p_body_dtl_html => lc_body_dtl_html,
                                               p_return_status => lc_email_status 
                                             );
                    put_log_line (p_debug_flag, 'N', 'PROCEDURE prepare_and_send_email   - Return Status : ' || lc_email_status);
                
                    IF lc_email_status = 'SUCCESS' THEN
                        put_log_line (p_debug_flag, 'Y', ' ');
                        put_log_line (p_debug_flag, 'Y', 'Email Notification Successfully Sent.');
                        gc_mainp_status := 'SUCCESS';   
                    ELSE
                        put_log_line (p_debug_flag, 'Y', ' ');
                        put_log_line (p_debug_flag, 'Y', 'Email Notification Not Sent.'); 
                        gc_mainp_status := 'FAILURE';
                    END IF;
                
                END IF;
                
            END IF;
        
        EXCEPTION
            WHEN OTHERS THEN
                put_log_line (p_debug_flag, 'Y', ' ');
                put_log_line (p_debug_flag, 'Y', 'Exception at PROCEDURE lockbox_alert_main_proc : ' || SQLERRM);
                put_log_line (p_debug_flag, 'N', ' ');
                put_log_line (p_debug_flag, 'N', 'PROCEDURE lockbox_alert_main_proc  - Return Status : FAILURE');
                gc_mainp_status := 'FAILURE';
                
                UPDATE xx_ar_lockbox_alert
                   SET alert_end_time       = SYSDATE,
                       alert_status         = gc_mainp_status,
                       last_updated_by      = gn_user_id,
                       last_update_date     = SYSDATE
                 WHERE alert_request_id     = gn_conc_req_id;
         
                COMMIT; 
         
        END;
        
        put_log_line (p_debug_flag, 'Y', ' ');
        put_log_line (p_debug_flag, 'Y', 'Lockbox Alert Main Procedure - End Time   : ' || TO_CHAR(SYSDATE, 'DD-Mon-YYYY HH24:MI:SS'));
        put_log_line (p_debug_flag, 'Y', ' ');
        put_log_line (p_debug_flag, 'N', 'PROCEDURE lockbox_alert_main_proc  - Return Status : ' || gc_mainp_status); 
        put_log_line (p_debug_flag, 'N', ' ');
        
        IF gc_mainp_status = 'FAILURE' THEN
            retcode   := 2;
            errbuf    := '**Exception at procedure lockbox_alert_main_proc. Refer log file for details.';
        END IF;
        
        UPDATE xx_ar_lockbox_alert
           SET alert_end_time       = SYSDATE,
               alert_status         = gc_mainp_status,
               last_updated_by      = gn_user_id,
               last_update_date     = SYSDATE
         WHERE alert_request_id     = gn_conc_req_id;
         
        COMMIT; 
        
    EXCEPTION
        WHEN OTHERS THEN
            put_log_line (p_debug_flag, 'Y', 'Exception at PROCEDURE lockbox_alert_main_proc : ' || SQLERRM);
            put_log_line (p_debug_flag, 'Y', ' ');
            put_log_line (p_debug_flag, 'Y', 'Lockbox Alert Main Procedure - End Time   : ' || TO_CHAR(SYSDATE, 'DD-Mon-YYYY HH24:MI:SS'));
            put_log_line (p_debug_flag, 'Y', ' ');
            put_log_line (p_debug_flag, 'N', 'PROCEDURE lockbox_alert_main_proc  - Return Status : FAILURE');
            put_log_line (p_debug_flag, 'N', ' ');
            gc_mainp_status := 'FAILURE';
            
            retcode   := 2;
            errbuf    := '**Exception at procedure lockbox_alert_main_proc. Refer log file for details.';
        
            xx_com_error_log_pub.log_error
                        (p_program_type                => 'CONCURRENT PROGRAM',
                         p_program_name                => gc_program_name,
                         p_module_name                 => gc_short_name,
                         p_error_location              => 'PROCEDURE lockbox_alert_main_proc',
                         p_error_message_count         => 0,
                         p_error_message_code          => 'E',
                         p_error_message               => 'Error : ' || SUBSTR(SQLERRM, 1, 80),
                         p_error_message_severity      => 'Major',
                         p_notify_flag                 => 'N',
                         p_object_type                 => 'PACKAGE BODY xx_ar_lbx_alert_pkg');
    
            UPDATE xx_ar_lockbox_alert
               SET alert_end_time       = SYSDATE,
                   alert_status         = gc_mainp_status,
                   last_updated_by      = gn_user_id,
                   last_update_date     = SYSDATE
             WHERE alert_request_id     = gn_conc_req_id;
            
            COMMIT; 

    END lockbox_alert_main_proc;
    
    
-----------------------------------------------------------------------------------------------       
    
    
    -- +============================================================================+
    -- | Name             : EXECUTION_TIME_MAIN_PROC                                |
    -- |                                                                            |
    -- | Description      : This procedure will be called from concurrent program   |
    -- |                  : OD: AR Lockbox Alert - Execution Time Check             |
    -- |                                                                            |
    -- | Parameters       : retcode         OUT NOCOPY NUMBER                       |
    -- |                  : errbuf          OUT NOCOPY VARCHAR2                     |
    -- |                  : p_cust_num      IN  VARCHAR2                            |
    -- |                  : p_debug_flag    IN  VARCHAR2 -- Debug Flag              |
    -- |                                                                            |
    -- | Change Record:                                                             |
    -- | ==============                                                             |
    -- | Version  Date         Author          Remarks                              |
    -- | =======  ===========  =============   ===================================  |
    -- | 1.0      03-Dec-2012  Abdul Khan      Initial version - QC Defect # 21270  |
    -- +============================================================================+   
    PROCEDURE execution_time_main_proc ( errbuf          OUT NOCOPY VARCHAR2,
                                         retcode         OUT NOCOPY NUMBER,  
                                         p_cust_num      IN         VARCHAR2,
                                         p_debug_flag    IN         VARCHAR2 DEFAULT 'N'
                                       ) 
    AS
    
        lc_short_name       VARCHAR2(30)    :=  NULL;
        lc_program_name     VARCHAR2(80)    :=  NULL;
        lc_customer_num     VARCHAR2(30)    :=  NULL;
        lc_customer_name    VARCHAR2(100)   :=  NULL;
        lc_trx_number       VARCHAR2(30)    :=  NULL;
        lc_inv_currency     VARCHAR2(30)    :=  NULL;
        lc_start_time       VARCHAR2(25)    :=  NULL;
        lc_end_time         VARCHAR2(25)    :=  NULL;
        lc_mainp_status     VARCHAR2(15)    :=  NULL;
        lc_trx_date         DATE            :=  NULL;
        ln_customer_id      NUMBER          :=  0;
        ln_org_id           NUMBER          :=  0;
        ln_conc_req_id      NUMBER          :=  0;    
        ln_query_tim_diff   NUMBER          :=  0;
        ln_amt_due_rem      NUMBER          :=  0;
        
    BEGIN
    
        put_log_line (p_debug_flag, 'Y', ' ');
        put_log_line (p_debug_flag, 'N', 'PROCEDURE execution_time_main_proc - Begin');
        put_log_line (p_debug_flag, 'N', ' ');
        put_log_line (p_debug_flag, 'Y', 'Query Execution Time Check - Start Time : ' || TO_CHAR(SYSDATE, 'DD-Mon-YYYY HH24:MI:SS'));
        put_log_line (p_debug_flag, 'Y', ' ');
        put_log_line (p_debug_flag, 'Y', RPAD('Parameters', 20, ' '));
        put_log_line (p_debug_flag, 'Y', RPAD('Customer Number', 20, ' ') || ' - ' || p_cust_num);
        put_log_line (p_debug_flag, 'Y', RPAD('Debug Flag', 20, ' ') || ' - ' || p_debug_flag);
        put_log_line (p_debug_flag, 'Y', ' ');
        
        
        BEGIN
        
            ln_org_id := FND_GLOBAL.ORG_ID;
            dbms_application_info.set_client_info(ln_org_id);              
             
            --Query to fetch open invoice details for given customer
            SELECT ract.trx_number, 
                   ract.trx_date,
                   hzca.cust_account_id,
                   hzca.account_number,
                   hzca.account_name
              INTO lc_trx_number,
                   lc_trx_date,
                   ln_customer_id,
                   lc_customer_num,
                   lc_customer_name
              FROM ra_customer_trx_all ract, 
                   ar_payment_schedules_all apsa,
                   hz_cust_accounts hzca
             WHERE apsa.customer_trx_id             = ract.customer_trx_id
               AND hzca.cust_account_id             = ract.bill_to_customer_id
               AND hzca.status                      = 'A'
               AND apsa.status                      = 'OP'
               AND ract.attribute_category          = 'SALES_ACCT'
               AND ract.interface_header_attribute2 = 'SA US Standard'
               AND hzca.account_number              = p_cust_num
               AND ract.trx_date                    > SYSDATE - 7
               AND ract.org_id                      = ln_org_id
               AND ROWNUM                           = 1;  
        
            put_log_line (p_debug_flag, 'Y', RPAD('Customer Number', 20, ' ') || ' - ' || lc_customer_num);
            put_log_line (p_debug_flag, 'Y', RPAD('Customer Name', 20, ' ') || ' - ' || lc_customer_name);
            put_log_line (p_debug_flag, 'Y', RPAD('Trx Number', 20, ' ') || ' - ' || lc_trx_number);
            put_log_line (p_debug_flag, 'Y', RPAD('Trx Date', 20, ' ') || ' - ' || lc_trx_date);
        
            lc_start_time := TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS');
        
            --Query using ar_paying_relationships_v view - Performance Check
            SELECT invoice_currency_code, 
                   amount_due_remaining
              INTO lc_inv_currency,
                   ln_amt_due_rem     
              FROM ar_payment_schedules ps, 
                   ra_cust_trx_types tt
             WHERE ps.trx_number = lc_trx_number
               AND ps.status = DECODE (tt.allow_overapplication_flag, 'N', 'OP', ps.status)
               AND ps.CLASS NOT IN ('PMT', 'GUAR')
               AND ps.payment_schedule_id =
                      (SELECT MIN (ps.payment_schedule_id)
                         FROM ar_payment_schedules ps, 
                              ra_cust_trx_types tt
                        WHERE ps.trx_number = lc_trx_number
                          AND ps.trx_date = lc_trx_date
                          AND (   ps.customer_id IN (
                                     SELECT ln_customer_id
                                       FROM DUAL
                                     UNION
                                     SELECT related_cust_account_id
                                       FROM hz_cust_acct_relate rel
                                      WHERE rel.cust_account_id = ln_customer_id
                                        AND rel.status = 'A'
                                        AND rel.bill_to_flag = 'Y'
                                     UNION
                                     SELECT rel.related_cust_account_id
                                       FROM ar_paying_relationships_v rel,
                                            hz_cust_accounts acc
                                      WHERE rel.party_id = acc.party_id
                                        AND acc.cust_account_id = ln_customer_id
                                        AND SYSDATE BETWEEN effective_start_date AND effective_end_date)
                               OR 'N' = 'Y'
                              )
                          AND ps.cust_trx_type_id = tt.cust_trx_type_id
                          AND ps.CLASS NOT IN ('PMT', 'GUAR')
                          AND ps.status = DECODE (tt.allow_overapplication_flag, 'N', 'OP', ps.status )
                       )
               AND (   ps.customer_id IN (
                          SELECT ln_customer_id
                            FROM DUAL
                          UNION
                          SELECT related_cust_account_id
                            FROM hz_cust_acct_relate rel
                           WHERE rel.cust_account_id = ln_customer_id
                             AND rel.status = 'A'
                             AND rel.bill_to_flag = 'Y'
                          UNION
                          SELECT rel.related_cust_account_id
                            FROM ar_paying_relationships_v rel,
                                 hz_cust_accounts acc
                           WHERE rel.party_id = acc.party_id
                             AND acc.cust_account_id = ln_customer_id
                             AND SYSDATE BETWEEN effective_start_date AND effective_end_date)
                    OR 'N' = 'Y'
                   )
               AND ps.cust_trx_type_id = tt.cust_trx_type_id;
           
            lc_end_time         := TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS');
            ln_query_tim_diff   := ROUND((TO_DATE(lc_end_time,'DD-MON-YYYY HH24:MI:SS') - TO_DATE(lc_start_time,'DD-MON-YYYY HH24:MI:SS')) * 24 * 60 * 60);
        
            put_log_line (p_debug_flag, 'N', RPAD('Trx Currency Code', 20, ' ') || ' - ' || lc_inv_currency);
            put_log_line (p_debug_flag, 'N', RPAD('Amt Due Remaining', 20, ' ') || ' - ' || ln_amt_due_rem);
            put_log_line (p_debug_flag, 'N', RPAD('Query Start Time', 20, ' ') || ' - ' || lc_start_time);
            put_log_line (p_debug_flag, 'N', RPAD('Query End Time', 20, ' ') || ' - ' || lc_end_time);
            put_log_line (p_debug_flag, 'Y', RPAD('Query Exec Time', 20, ' ') || ' - ' || ln_query_tim_diff || ' Seconds');
            
            lc_mainp_status := 'SUCCESS';
            
            UPDATE xx_ar_lockbox_alert
               SET child_end_time       = SYSDATE,
                   child_status         = lc_mainp_status,
                   query_start_time1    = TO_DATE(lc_start_time,'DD-MON-YYYY HH24:MI:SS'),
                   query_end_time1      = TO_DATE(lc_end_time,'DD-MON-YYYY HH24:MI:SS'),
                   query_exec_time_sec1 = ln_query_tim_diff,
                   last_update_date     = SYSDATE
             WHERE child_request_id     = FND_GLOBAL.CONC_REQUEST_ID;
        
            COMMIT;
        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                retcode         := 1;
                errbuf          := '**Exception at procedure execution_time_main_proc. Refer log file for details.';
                lc_mainp_status := 'FAILURE';
                put_log_line (p_debug_flag, 'Y', ' ');
                put_log_line (p_debug_flag, 'Y', 'Exception at PROCEDURE execution_time_main_proc : ' || SQLERRM);
                
            UPDATE xx_ar_lockbox_alert
               SET child_end_time       = SYSDATE,
                   child_status         = lc_mainp_status,
                   last_update_date     = SYSDATE
             WHERE child_request_id     = FND_GLOBAL.CONC_REQUEST_ID;
        
            COMMIT;
                 
        END;
        
        put_log_line (p_debug_flag, 'Y', ' ');
        put_log_line (p_debug_flag, 'Y', 'Query Execution Time Check - End Time   : ' || TO_CHAR(SYSDATE, 'DD-Mon-YYYY HH24:MI:SS'));
        put_log_line (p_debug_flag, 'Y', ' ');
        put_log_line (p_debug_flag, 'N', 'PROCEDURE execution_time_main_proc  - Return Status : ' || lc_mainp_status); 
        put_log_line (p_debug_flag, 'N', ' ');
        
    EXCEPTION
        WHEN OTHERS THEN
        
            SELECT request_id,
                   program_short_name, 
                   program
              INTO ln_conc_req_id,
                   lc_short_name,
                   lc_program_name
              FROM fnd_conc_req_summary_v
             WHERE request_id = FND_GLOBAL.CONC_REQUEST_ID;
             
            put_log_line (p_debug_flag, 'Y', 'Exception at PROCEDURE execution_time_main_proc : ' || SQLERRM);
            put_log_line (p_debug_flag, 'Y', ' ');
            put_log_line (p_debug_flag, 'Y', 'Query Execution Time Check - End Time   : ' || TO_CHAR(SYSDATE, 'DD-Mon-YYYY HH24:MI:SS'));
            put_log_line (p_debug_flag, 'Y', ' ');
            put_log_line (p_debug_flag, 'N', 'PROCEDURE execution_time_main_proc  - Return Status : FAILURE');
            put_log_line (p_debug_flag, 'N', ' ');
            
            retcode   := 2;
            errbuf    := '**Exception at procedure execution_time_main_proc. Refer log file for details.';
        
            xx_com_error_log_pub.log_error
                        (p_program_type                => 'CONCURRENT PROGRAM',
                         p_program_name                => lc_program_name,
                         p_module_name                 => lc_short_name,
                         p_error_location              => 'PROCEDURE execution_time_main_proc',
                         p_error_message_count         => 0,
                         p_error_message_code          => 'E',
                         p_error_message               => 'Error : ' || SUBSTR(SQLERRM, 1, 80),
                         p_error_message_severity      => 'Major',
                         p_notify_flag                 => 'N',
                         p_object_type                 => 'PACKAGE BODY xx_ar_lbx_alert_pkg');

            UPDATE xx_ar_lockbox_alert
               SET child_end_time       = SYSDATE,
                   child_status         = lc_mainp_status,
                   last_update_date     = SYSDATE
             WHERE child_request_id     = FND_GLOBAL.CONC_REQUEST_ID;
        
            COMMIT;
    
    END execution_time_main_proc;    
    

END xx_ar_lbx_alert_pkg;

/

SHOW ERROR