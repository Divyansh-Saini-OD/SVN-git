CREATE or REPLACE PACKAGE BODY XX_PO_PUNCHOUT_CLOSE_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_PO_PUNCHOUT_CONF_PKG                                                            |
  -- |                                                                                            |
  -- |  Description:  This package is used to close the Punch out PO's, for which the line        |
  -- | status as "Closed For Receiving"                                                           |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         08-NOV-2017  Nagendra C        Initial version                                 |
  -- +============================================================================================+
   
   --/**************************************************************
  --* This function returns the current time
  --***************************************************************/
  FUNCTION time_now
          RETURN VARCHAR2
  IS
   lc_time_string VARCHAR2(40);
  BEGIN
    SELECT TO_CHAR(SYSDATE, 'DD-MON-RRRR HH24:MI:SS')
    INTO   lc_time_string
    FROM   DUAL;

    RETURN(lc_time_string);
  END time_now; 
  
  -- +===============================================================================================+
  -- | Name  : log_msg                                                                               |
  -- | Description     : This procedure used to log the messages in concurrent program log           |
  -- |    pi_log_flag            IN -- Debug Flag                                                    |
  -- |    pi_string              IN -- Message as String                                             |
  -- +================================================================================================+
  PROCEDURE log_msg(
                    pi_log_flag IN BOOLEAN DEFAULT FALSE,
                    pi_string   IN VARCHAR2
                    )
  IS
  BEGIN
    IF (pi_log_flag)
    THEN
      fnd_file.put_line(fnd_file.LOG, time_now || ' : ' || pi_string);  
      dbms_output.put_line(time_now || ' : ' || pi_string);
    END IF;
  END log_msg;
  
  -- +===============================================================================================+
-- | Name  : get_translation_info                                                                  |
-- | Description     : This function returns the transaltion info                                  |
-- |                                                                                               |
-- |                                                                    |
-- | Parameters      :                                                  |
-- +================================================================================================+

  FUNCTION get_translation_info(pi_translation_name   IN  xx_fin_translatedefinition.translation_name%TYPE,
                                pi_source_record      IN  xx_fin_translatevalues.source_value1%TYPE,
                                po_translation_info   OUT xx_fin_translatevalues%ROWTYPE,
                                po_error_msg          OUT VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    po_error_msg        := NULL;
    po_translation_info := NULL;

    SELECT xftv.*
    INTO po_translation_info
    FROM xx_fin_translatedefinition xft,
         xx_fin_translatevalues xftv
    WHERE xft.translate_id    = xftv.translate_id
    AND xft.enabled_flag      = 'Y'
    AND xftv.enabled_flag     = 'Y'
    AND xft.translation_name  = pi_translation_name
    AND xftv.source_value1    = pi_source_record; --'CONFIG_DETAILS';

    RETURN 'Success';
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       po_error_msg := 'No Translation info found for '||pi_translation_name;
       log_msg(TRUE, po_error_msg);
       RETURN 'Failure';
     WHEN OTHERS
     THEN
       po_error_msg := 'Error while getting the trans info '|| substr(SQLERRM,1,2000);
       log_msg(TRUE, po_error_msg);
       RETURN 'Failure';
  END get_translation_info;
  
   -- +===============================================================================================+
  -- | Name  : log_error                                                                             |
  -- | Description     : This procedure used to write the Error message in Common Error Log Table    |
  -- |    pi_object_id            IN  -- Object Id                                                   |
  -- |    po_error_msg            OUT -- Return Error message                                        |
  -- +================================================================================================+
  PROCEDURE log_error (pi_object_id     IN VARCHAR2,
                       pi_error_msg     IN VARCHAR2)
   IS
   BEGIN
      xx_com_error_log_pub.log_error (p_return_code                 => fnd_api.g_ret_sts_error
                                    , p_msg_count                   => 1
                                    , p_application_name            => 'XX_PO'
                                    , p_program_type                => 'ERROR'
                                    , p_program_name                => 'XX_PO_PUNCHOUT_CLOSE_PKG'
                                    , p_attribute15                 => 'XX_PO_PUNCHOUT_CLOSE_PKG'          --------index exists on attribute15
                                    , p_program_id                  => NULL
                                    , p_object_id                   => pi_object_id
                                    , p_module_name                 => 'PUNCHOUT'
                                    , p_error_location              => NULL --p_error_location
                                    , p_error_message_code          => NULL --p_error_message_code
                                    , p_error_message               => pi_error_msg
                                    , p_error_message_severity      => 'MAJOR'
                                    , p_error_status                => 'ACTIVE'
                                    , p_created_by                  => fnd_global.user_id  --gn_user_id
                                    , p_last_updated_by             => fnd_global.user_id  --gn_user_id
                                    , p_last_update_login           => NULL --g_login_id
                                     );
   END log_error;
  
  -- +===============================================================================================+
  -- | Name  : set_context                                                                           |
  -- | Description     : This procedure used to initialize and set the org_context in pl/sql block   |
  -- |    pi_translation_info            IN  -- user_name, responsiblity values from translations    |
  -- |    po_error_msg                   OUT -- Return Error message                                 |
  -- +================================================================================================+

  PROCEDURE set_context( 
                        pi_translation_info   IN   xx_fin_translatevalues%ROWTYPE,
                        po_error_msg          OUT  VARCHAR2
                        )
  IS

   ln_responsibility_id      fnd_responsibility_tl.responsibility_id%TYPE;
   ln_user_id                fnd_user.user_id%TYPE;
   ln_application_id         fnd_responsibility_tl.application_id%TYPE;
   
  BEGIN
    
    SELECT frt.responsibility_id,
           fu.user_id,
           frt.application_id
    INTO   ln_responsibility_id,
           ln_user_id,
           ln_application_id           
    FROM   fnd_user fu,
           fnd_user_resp_groups_all furga,
           fnd_responsibility_tl frt
    WHERE   frt.LANGUAGE            = USERENV('LANG')
    AND    frt.responsibility_id    = furga.responsibility_id
    AND    (furga.start_date <= SYSDATE OR furga.start_date IS NULL)
    AND    (furga.end_date >= SYSDATE OR furga.end_date IS NULL)
    AND    furga.user_id            = fu.user_id
    AND    (fu.start_date <= SYSDATE OR fu.start_date IS NULL)
    AND    (fu.end_date >= SYSDATE OR fu.end_date IS NULL)
    AND    fu.user_name                =  pi_translation_info.target_value1  -- username
    AND    frt.responsibility_name     =  pi_translation_info.target_value2;  -- Resp Name

    fnd_global.apps_initialize(ln_user_id,ln_responsibility_id,ln_application_id);
    
  EXCEPTION
    WHEN OTHERS
    THEN
      po_error_msg:= 'unable to set the context ..'|| SUBSTR(SQLERRM, 1, 2000);
      log_msg(TRUE,po_error_msg);
  END set_context;
  
  -- +===============================================================================================+
  -- | Name  : CLOSE_PO                                                                                |
  -- | Description     : This procedure used to Close the PO                                           |
  -- |                                                                                                 |
  -- +================================================================================================+
  
  PROCEDURE CLOSE_PO(p_po_header_id    IN   NUMBER,
                     p_po_number       IN   VARCHAR2,
                     p_po_doc_type     IN   VARCHAR2,
                     p_po_doc_sub_type IN   VARCHAR2,
                     po_error_msg      OUT  VARCHAR2
                     )
  IS
        lc_action           constant varchar2(20) := 'CLOSE';
        lc_calling_mode     constant varchar2(2) := 'PO';
        lc_conc_flag        constant varchar2(1) := 'N';
        lc_return_code_h    varchar2(100);
        lc_auto_close       constant varchar2(1) := 'N';
        lc_returned         boolean;
  BEGIN
   
   lc_returned :=po_actions.close_po( 
                                    p_docid         =>     p_po_header_id,
                                    p_doctyp        =>     p_po_doc_type,
                                    p_docsubtyp     =>     p_po_doc_sub_type,
                                    p_lineid        =>     NULL,
                                    p_shipid        =>     NULL,
                                    p_action        =>     lc_action,
                                    p_reason        =>     NULL,
                                    p_calling_mode  =>     lc_calling_mode,
                                    p_conc_flag     =>     lc_conc_flag,
                                    p_return_code   =>     lc_return_code_h,
                                    p_auto_close    =>     lc_auto_close,
                                    p_action_date   =>     SYSDATE,
                                    p_origin_doc_id =>     NULL
                                   );
        
    IF NVL(lc_returned,FALSE) = TRUE THEN
        log_msg(TRUE,'Purchase Order Closed is'||p_po_number);
        COMMIT; 
     ELSE  
        -- Get any messages returned by the Cancel API
        FOR i IN 1..FND_MSG_PUB.count_msg
        LOOP
          po_error_msg := FND_MSG_PUB.Get(p_msg_index => i,
                                          p_encoded => 'F');
        END LOOP;
        
         log_msg(TRUE,po_error_msg);
        
    END IF;
    
  EXCEPTION
    WHEN OTHERS
    THEN
      po_error_msg := 'Error while closing the PO: '||p_po_number ||' '||SUBSTR(sqlerrm,1,200);
      log_msg(TRUE, po_error_msg);           
      
  END CLOSE_PO;
  
    -- +===============================================================================================+
  -- | Name  : main                                                                                |
  -- | Description     : This procedure used to Close the PO                                           |
  -- |                                                                                                 |
  -- +================================================================================================+
   
    PROCEDURE main(errbuf        OUT  VARCHAR2,
                   retcode       OUT  VARCHAR2,
                   pi_no_of_days IN   NUMBER
                   )
    IS
     
     lc_error_message       VARCHAR2(2000):= NULL;
     lc_translation_info    xx_fin_translatevalues%ROWTYPE;
     lc_trans_name          xx_fin_translatedefinition.translation_name%TYPE := 'XXPO_PUNCHOUT_CONFIG';
     lc_return_status       VARCHAR2(100);
     lc_debug_flag          BOOLEAN;
     l_po_count             NUMBER:=0;
     e_process_exception    EXCEPTION;
      
     CURSOR c_po_details IS
        SELECT
            DISTINCT pha.po_header_id,
            pha.org_id,
            pha.segment1,
            pha.agent_id,
            pdt.document_subtype,
            pdt.document_type_code,
            pha.closed_code,
            pha.closed_date
        FROM 
            rcv_transactions rt,
            po_headers_all pha,
            po_lines_all pla,
            po_distributions_all pda,
            po_req_distributions_all prda,
            po_requisition_lines_all prla,
            po_document_types_all pdt
        WHERE pha.type_lookup_code = pdt.document_subtype
            AND pha.org_id = pdt.org_id
            AND pdt.document_type_code = 'PO'
            AND pha.authorization_status = 'APPROVED'
            AND pha.closed_code <> 'CLOSED'
            AND rt.po_header_id = pha.po_header_id
            AND rt.po_line_id = pla.po_line_id
            AND rt.po_distribution_id = pda.po_distribution_id
            AND pda.req_distribution_id = prda.distribution_id
            AND prda.requisition_line_id = prla.requisition_line_id
            AND prla.supplier_duns in (SELECT xftv.target_value1
                                       FROM xx_fin_translatedefinition xft,
                                            xx_fin_translatevalues xftv
                                       WHERE xft.translate_id    = xftv.translate_id
                                       AND xft.enabled_flag      = 'Y'
                                       AND xftv.enabled_flag     = 'Y'
                                       AND xft.translation_name  = 'XXPO_PUNCHOUT_CONFIG'
                                       AND xftv.source_value1    = 'SUPPLIER_DUNS'
                                      )
           AND rt.transaction_type = 'RECEIVE'
           AND trunc(rt.transaction_date) >= trunc(sysdate)-pi_no_of_days 
           AND NOT EXISTS(
                        SELECT 'Y' 
                        FROM po_line_locations_all plla
                        WHERE plla.po_header_id=pha.po_header_id
                              AND NVL(plla.closed_code,'xx') NOT IN ('CLOSED FOR RECEIVING','CLOSED')
                        );
    
     BEGIN
        
        log_msg(true, 'calling main procedure..'); 
               
        log_msg(true, 'Getting the Translation Values ..'); 
        
        lc_return_status := get_translation_info(pi_translation_name => lc_trans_name,
                                                 pi_source_record    => 'CONFIG_DETAILS',
                                                 po_translation_info => lc_translation_info,
                                                 po_error_msg        => lc_error_message);
                                                                                                 
                                                 
        IF lc_error_message IS NOT NULL
        THEN          
          RAISE e_process_exception ;
        END IF;
        
        IF lc_translation_info.target_value7 = 'Y'
        THEN 
           lc_debug_flag := TRUE;
        END IF;
        
        log_msg(lc_debug_flag, 'Setting the Org context');
        
        set_context( pi_translation_info =>  lc_translation_info,
                     po_error_msg        =>  lc_error_message
                    );
                    
        IF lc_error_message IS NOT NULL
        THEN
            RAISE e_process_exception ;
        END IF;            
                        
          mo_global.init ('PO');
          
          mo_global.set_policy_context ('S',g_org_id);
          
         FOR c_po_hdr_rec in c_po_details
         LOOP         
         
               BEGIN
                    log_msg(lc_debug_flag,'Calling po_actions.close_po api for closing PO =>' ||c_po_hdr_rec.segment1);
                    
                    CLOSE_PO(p_po_header_id     => c_po_hdr_rec.po_header_id,
                             p_po_number        => c_po_hdr_rec.segment1,
                             p_po_doc_type      => c_po_hdr_rec.document_type_code,
                             p_po_doc_sub_type  => c_po_hdr_rec.document_subtype,
                             po_error_msg       => lc_error_message
                             );
        
                    IF lc_error_message IS NOT NULL 
                    THEN 
                      RAISE e_process_exception ;
                    ELSE
                      l_po_count:=l_po_count+1;
                    END IF;
                    
                EXCEPTION
                WHEN OTHERS THEN
                  log_msg(lc_debug_flag,'Exception while closing the PO:'||c_po_hdr_rec.segment1||' is '||lc_error_message);
                  log_error(null,lc_error_message);
                END;
            
         END LOOP;
         
         log_msg(lc_debug_flag,'Total Number of Purchase Orders closed is:'||l_po_count);
         
    EXCEPTION
    WHEN e_process_exception 
    THEN
      log_msg(TRUE,lc_error_message);
      log_error(null,lc_error_message);
    WHEN OTHERS THEN
      log_msg(TRUE,'Exception in Main procedure'||SUBSTR(SQLERRM,1,200));
    END main;

END XX_PO_PUNCHOUT_CLOSE_PKG;
/