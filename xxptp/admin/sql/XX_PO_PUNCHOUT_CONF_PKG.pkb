SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_PO_PUNCHOUT_CONF_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY      XX_PO_PUNCHOUT_CONF_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_PO_PUNCHOUT_CONF_PKG                                                            |
  -- |                                                                                            |
  -- |  Description:  This package is used by WEB services to load Punchout confirmation          |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         13-JUN-2017  Arun Gannarapu    Initial version                                 |
  -- | 2.0         29-JUN-2017  suresh Naragam    Added xx_process_confirm_details Procedure to   |
  -- |                                            process Confirmed PO cXML Data                  |
  -- | 3.0         06-NOV-2017  Suresh Naragam    Changes for Buy From Ourselves                  |
  -- |                                            Phase 2 jan/san                                 |
  -- | 4.0         02-FEB-2018  Suresh Naragam    Added exception for header level rejections     |
  -- +============================================================================================+

   lc_debug_flag          BOOLEAN := FALSE;  
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
    pi_string   IN VARCHAR2)
  IS
  BEGIN
    IF (pi_log_flag)
    THEN
      fnd_file.put_line(fnd_file.LOG, time_now || ' : ' || pi_string);
    END IF;
  END log_msg;


-- +===============================================================================================+
-- | Name  : get_translation_info                                                                  |
-- | Description     : This function returns the transaltion info                                  |
-- | Parameters      : pi_translation_name, pi_source_record, po_translation_info, po_error_msg    |
-- +===============================================================================================+

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
    AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
    AND xft.translation_name  = pi_translation_name
    AND xftv.source_value1    = pi_source_record;

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

-- +=================================================================================================================+
-- | Name  : get_translation_info                                                                                    |
-- | Description     : This function returns the transaltion info                                                    |
-- | Parameters      : pi_translation_name, pi_source_record, pi_target_record, po_translation_info, po_error_msg    |
-- +=================================================================================================================+

  FUNCTION get_translation_info(pi_translation_name   IN  xx_fin_translatedefinition.translation_name%TYPE,
                                pi_source_record      IN  xx_fin_translatevalues.source_value1%TYPE,
                                pi_target_record      IN  xx_fin_translatevalues.target_value1%TYPE,
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
    AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
    AND xft.translation_name  = pi_translation_name
    AND xftv.source_value1    = pi_source_record 
    AND xftv.target_value1    = pi_target_record;

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
-- | Name  : get_req_hdr_record                                                                      |
-- | Description     : This function returns the Requisition Header Record                           |
-- | Parameters      : pi_po_number, po_req_hdr_rec, po_error_msg                                    |
-- +=================================================================================================+

  FUNCTION get_req_hdr_record(pi_po_number     IN  po_headers_all.segment1%TYPE,
                              po_req_hdr_rec   OUT po_requisition_headers_all%ROWTYPE,
                              po_error_msg     OUT VARCHAR2)
  RETURN VARCHAR2
  IS
    ln_po_header_id                 po_headers_all.po_header_id%TYPE;
    ln_requisition_header_id        po_requisition_headers_all.requisition_header_id%TYPE;
  BEGIN
    
    po_error_msg        := NULL;
    po_req_hdr_rec := NULL;
	
    SELECT po_header_id
    INTO ln_po_header_id
    FROM po_headers_all
    WHERE segment1 = pi_po_number;
    log_msg(lc_debug_flag, 'PO Header Id : '||ln_po_header_id); 
	
    SELECT distinct requisition_header_id
    INTO ln_requisition_header_id
    FROM po_distributions_v
    WHERE po_header_id = ln_po_header_id
    AND requisition_header_id IS NOT NULL;
    log_msg(lc_debug_flag, 'Requisition Header Id: '||ln_requisition_header_id);

    SELECT prha.*
    INTO po_req_hdr_rec
    FROM po_requisition_headers_all prha
    WHERE requisition_header_id = ln_requisition_header_id;

    RETURN 'Success';
	
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       po_error_msg := 'No Requisition Data found for the PO '||pi_po_number;
       log_msg(TRUE, po_error_msg);
       RETURN 'Failure';
     WHEN OTHERS
     THEN
       po_error_msg := 'Error while getting the Requisition Record '|| substr(SQLERRM,1,2000);
       log_msg(TRUE, po_error_msg);
       RETURN 'Failure';
  END get_req_hdr_record;
  
-- +=================================================================================================+
-- | Name  : get_req_line_record                                                                     |
-- | Description     : This function returns the Requisition Line Record                             |
-- | Parameters      : pi_po_number, pi_po_line_num, po_req_line_rec, po_error_msg                   |
-- +=================================================================================================+

  FUNCTION get_req_line_record(pi_po_number       IN  po_headers_all.segment1%TYPE,
                               pi_po_line_num     IN  po_lines_all.line_num%TYPE,
                               po_req_line_rec    OUT po_requisition_lines_all%ROWTYPE,
                               po_error_msg       OUT VARCHAR2)
  RETURN VARCHAR2
  IS
    ln_requisition_header_id	po_requisition_headers_all.requisition_header_id%TYPE;
    ln_requisition_line_id      po_requisition_lines_all.requisition_line_id%TYPE;
    ln_po_header_id             po_headers_all.po_header_id%TYPE;
    ln_po_line_id               po_lines_all.po_line_id%TYPE;
  BEGIN

    po_error_msg        := NULL;
    po_req_line_rec := NULL;
	
    SELECT po_header_id
    INTO ln_po_header_id
    FROM po_headers_all
    WHERE segment1 = pi_po_number;
    log_msg(lc_debug_flag, 'PO Header Id : '||ln_po_header_id); 
	
    SELECT po_line_id
    INTO ln_po_line_id
    FROM po_lines_all
    WHERE po_header_id = ln_po_header_id
    AND line_num = pi_po_line_num;
    log_msg(lc_debug_flag, 'PO Line Id : '||ln_po_line_id);
	
    SELECT requisition_header_id,
           requisition_line_id
    INTO ln_requisition_header_id,
         ln_requisition_line_id
    FROM po_distributions_v
    WHERE po_header_id = ln_po_header_id
    AND po_line_id = ln_po_line_id;
    log_msg(lc_debug_flag, 'Requisition Header Id: '||ln_requisition_header_id||' - '||'Requisition Line Id: '||ln_requisition_line_id);

    SELECT prla.*
    INTO po_req_line_rec
    FROM po_requisition_lines_all prla
    WHERE requisition_header_id = ln_requisition_header_id
    AND requisition_line_id = ln_requisition_line_id;
	
    RETURN 'Success';
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       po_error_msg := 'No Requisition Data found for the PO '||pi_po_number||' Line Num: '||pi_po_line_num;
       log_msg(TRUE, po_error_msg);
       RETURN 'Failure';
     WHEN OTHERS
     THEN
       po_error_msg := 'Error while getting the Requisition Line Record '|| substr(SQLERRM,1,2000);
       log_msg(TRUE, po_error_msg);
       RETURN 'Failure';
   END get_req_line_record;
  
  -- +===============================================================================================+
  -- | Name  : set_context                                                                           |
  -- | Description     : This procedure used to initialize and set the org_context in pl/sql block   |
  -- |    pi_translation_info            IN  -- user_name, responsiblity values from translations    |
  -- |    po_error_msg                   OUT -- Return Error message                                 |
  -- +================================================================================================+

  PROCEDURE set_context( pi_translation_info   IN xx_fin_translatevalues%ROWTYPE,
                         po_error_msg          OUT VARCHAR2)
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
    mo_global.init('PO'); -- need for R12
  EXCEPTION
    WHEN OTHERS
    THEN
      po_error_msg:= 'unable to set the context ..'|| SUBSTR(SQLERRM, 1, 2000);
      log_msg(TRUE, po_error_msg);
  END set_context;

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
                                    , p_program_name                => 'XX_PO_PUNCHOUT_CONF_PKG'
                                    , p_attribute15                 => 'XX_PO_PUNCHOUT_CONF_PKG'          --------index exists on attribute15
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
  -- | Name  : insert_row                                                                            |
  -- | Description     : Inserts the Rows into staging table from Payload                            |
  -- |    p_conf_payload            IN -- PO Payload Data                                            |
  -- |    p_out                     IN -- Output Message                                             |
  -- +================================================================================================+
  PROCEDURE insert_row(
    P_CONF_PAYLOAD      IN  VARCHAR2,
    P_OUT               OUT VARCHAR2
   )
  IS
  BEGIN
    INSERT
    INTO XX_PO_PUNCHOUT_CONFIRMATION
      (RECORD_ID,
       CONFIRM_PAYLOAD,
       CREATION_DATE,
       CREATED_BY,
       LAST_UPDATE_DATE,
       LAST_UPDATED_BY,
       RECORD_STATUS)
      VALUES
      ( XX_PO_PUNCHOUT_RECORD_ID_S.NEXTVAL,
        P_CONF_PAYLOAD,    
        SYSDATE,
        fnd_global.user_id,
        SYSDATE,
        fnd_global.user_id,
        'NEW'
      );
      p_out := 'Record Inserted Successfully';
    COMMIT;
  EXCEPTION
    WHEN OTHERS
    THEN
      ROLLBACK;
      p_out:= 'Unexpected error inserting into staging table'||SUBSTR(sqlerrm,1,200);
      log_msg(TRUE, p_out);
  END INSERT_ROW;

  -- +===============================================================================================+
  -- | Name  : update_po_header                                                                      |
  -- | Description     : updates PO Header with Internal order details                               |
  -- |    pi_po_number                  IN  -- PO Number                                             |
  -- |    pi_internal_order             IN  -- AOPS Number                                           |
  -- |    po_error_msg                  OUT -- Error Message                                         |
  -- +================================================================================================+

  PROCEDURE update_po_header(
      pi_po_number       IN   po_headers_all.segment1%TYPE,
      pi_internal_order  IN   po_headers_all.attribute1%TYPE,
      po_error_msg       OUT  VARCHAR2
     )
  IS
  BEGIN

    UPDATE po_headers_all
    SET attribute3 = pi_internal_order,
        attribute_category = 'Non-Trade',
        last_update_date = sysdate,
        last_updated_by = fnd_global.user_id
    WHERE segment1 = pi_po_number
    AND org_id = fnd_global.org_id;
	
    UPDATE po_headers_archive_all
    SET attribute3 = pi_internal_order,
        attribute_category = 'Non-Trade',
        last_update_date = sysdate,
        last_updated_by = fnd_global.user_id
    WHERE segment1 = pi_po_number
    AND latest_external_flag = 'Y'
    AND org_id = fnd_global.org_id;
 
  EXCEPTION
    WHEN OTHERS
    THEN
      po_error_msg := 'Error while Updating the PO: '|| pi_po_number ||' '||SUBSTR(sqlerrm,1,200);
      log_msg(TRUE, po_error_msg);
  END update_po_header;

  -- +===============================================================================================+
  -- | Name  : update_header_rec_status                                                              |
  -- | Description     : Updates Header staging table with record status                             |
  -- |    pi_po_number                  IN  -- PO Number                                             |
  -- |    pi_record_id                  IN  -- Record Id                                             |
  -- |    pi_rec_status                 IN  -- Record Status                                         |
  -- |    po_error_msg                  OUT -- Error Message                                         |
  -- +================================================================================================+
  PROCEDURE update_header_rec_status(
      pi_po_number       IN      po_headers_all.segment1%TYPE,
      pi_record_id       IN      xx_po_punch_lines_info.record_id%TYPE,
      pi_rec_status      IN      xx_po_punch_header_info.record_status%TYPE,
      pio_error_msg      IN OUT  VARCHAR2
     )
  IS
  BEGIN

    UPDATE xx_po_punch_header_info
    SET record_status = pi_rec_status,
        error_message = pio_error_msg,
        last_update_date = sysdate,
        last_updated_by = fnd_global.user_id
    WHERE record_id = pi_record_id
    AND po_number = pi_po_number;
 
  EXCEPTION
    WHEN OTHERS
    THEN
      pio_error_msg := 'Error while Updating the header status for: '|| pi_po_number ||' '||SUBSTR(sqlerrm,1,200);
      log_msg(TRUE, pio_error_msg);
  END update_header_rec_status;

  -- +===============================================================================================+
  -- | Name  : update_line_rec_status                                                                |
  -- | Description     : Updates Header staging table with record status                             |
  -- |    pi_po_number                  IN  -- PO Number                                             |
  -- |    pi_po_line_num                IN  -- PO Line Number                                        |
  -- |    pi_record_id                  IN  -- Record Id                                             |
  -- |    pi_rec_status                 IN  -- Record Status                                         |
  -- |    po_error_msg                  OUT -- Error Message                                         |
  -- +================================================================================================+

  PROCEDURE update_line_rec_status(
      pi_po_number       IN      po_headers_all.segment1%TYPE,
      pi_po_line_num     IN      po_lines_all.line_num%TYPE,
      pi_record_id       IN      xx_po_punch_lines_info.record_id%TYPE,
      pi_rec_status      IN      xx_po_punch_header_info.record_status%TYPE,
      pio_error_msg      IN  OUT     VARCHAR2
     )
  IS
  BEGIN

    UPDATE xx_po_punch_lines_info
    SET record_status = pi_rec_status,
        error_message = pio_error_msg,
        last_update_date = sysdate,
        last_updated_by = fnd_global.user_id
    WHERE record_id  = pi_record_id
    AND po_number = pi_po_number
    AND po_line_Num = pi_po_line_num;
 
  EXCEPTION
    WHEN OTHERS
    THEN
      pio_error_msg := 'Error while Updating the line status for PO line number: '|| pi_po_line_num ||' '||SUBSTR(sqlerrm,1,200);
      log_msg(TRUE, pio_error_msg);
  END update_line_rec_status;

  -- +===============================================================================================+
  -- | Name  : update_po_punchout_rec_status                                                         |
  -- | Description     : Updates PO Punchout Confirmation Table Status                               |
  -- |    pi_record_id                  IN  -- Record Id                                             |
  -- |    pi_rec_status                 IN  -- Record Status                                         |
  -- |    po_error_msg                  OUT -- Error Message                                         |
  -- +================================================================================================+
  --**************************************************************************/
  --* Description: Updates PO Punchout Confirmation Table Status
  --**************************************************************************/

  PROCEDURE update_po_punchout_rec_status(
      pi_record_id       IN      xx_po_punch_header_info.record_id%TYPE,
      pi_rec_status      IN      xx_po_punch_header_info.record_status%TYPE,
      pio_error_msg      IN  OUT VARCHAR2
     )
  IS
  BEGIN
    
    UPDATE XX_PO_PUNCHOUT_CONFIRMATION
    SET record_status = pi_rec_status,
        error_message = pio_error_msg,
        last_update_date = sysdate,
        last_updated_by = fnd_global.user_id
    WHERE record_id  = pi_record_id;
 
  EXCEPTION
    WHEN OTHERS
    THEN
      pio_error_msg := 'Error while Updating the status '||substr(sqlerrm,1,2000);
      log_msg(TRUE, pio_error_msg);
  END update_po_punchout_rec_status;

  -- +===============================================================================================+
  -- | Name  : cancel_po_line                                                                        |
  -- | Description     : Call Standard API to cancel the PO Line for all the Rejected lines          |
  -- |    pi_po_number                   IN   -- PO Number                                           |
  -- |    pi_po_line_num                 IN   -- PO Line Number                                      |
  -- |    po_return_status               OUT  -- PO Retrun Status                                    |
  -- |    po_error_msg                   OUT  -- Error Message                                       |
  -- +================================================================================================+
  PROCEDURE cancel_po_line(
      pi_po_number       IN      po_headers_all.segment1%TYPE,
      pi_po_line_num     IN      po_lines_all.line_num%TYPE,
      po_return_status   OUT     VARCHAR2,
      po_error_msg       OUT     VARCHAR2
     )
  IS
  BEGIN
    --call the Cancel API for PO
    po_document_control_pub.control_document (p_api_version        =>   1.0, -- p_api_version
                                              p_init_msg_list      =>   FND_API.G_TRUE, -- p_init_msg_list
                                              p_commit             =>   FND_API.G_TRUE, -- p_commit
                                              x_return_status      =>   po_return_status,-- x_return_status
                                              p_doc_type           =>   'PO', -- p_doc_type
                                              p_doc_subtype        =>   'STANDARD', -- p_doc_subtype
                                              p_doc_id             =>   null, -- p_doc_id
                                              p_doc_num            =>   pi_po_number, -- p_doc_num
                                              p_release_id         =>   null, -- p_release_id
                                              p_release_num        =>   null, -- p_release_num
                                              p_doc_line_id        =>   null, -- p_doc_line_id
                                              p_doc_line_num       =>   pi_po_line_num, -- p_doc_line_num
                                              p_doc_line_loc_id    =>   null, -- p_doc_line_loc_id
                                              p_doc_shipment_num   =>   null, -- p_doc_shipment_num
                                              p_action             =>  'CANCEL', -- p_action
                                              p_action_date        =>  SYSDATE, -- p_action_date
                                              p_cancel_reason      =>  null, -- p_cancel_reason
                                              p_cancel_reqs_flag   =>  'N', -- p_cancel_reqs_flag
                                              p_print_flag         =>  null, -- p_print_flag
                                              p_note_to_vendor     =>  null,  -- p_note_to_vendor
                                              p_org_id             =>  fnd_global.org_id
                                              );

    -- Get any messages returned by the Cancel API
    
    FOR i IN 1..FND_MSG_PUB.count_msg
    LOOP
      po_error_msg := FND_MSG_PUB.Get(p_msg_index => i,
                                      p_encoded => 'F');
    END LOOP;
  EXCEPTION
    WHEN OTHERS
    THEN
      IF po_error_msg IS NULL 
      THEN
        po_error_msg := 'Error while cancelling the PO Line number: '|| pi_po_line_num ||' '||SUBSTR(sqlerrm,1,200);
      END IF;
      log_msg(TRUE, SUBSTR(po_error_msg,1,2000));
  END cancel_po_line;

  -- +===============================================================================================+
  -- | Name  : cancel_req_line                                                                        |
  -- | Description     : Call Standard API to cancel the PO Requistion Line for all the Rejected lines|
  -- |    pi_pr_header_id                IN   -- Requisition Header Id                                |
  -- |    pi_pr_line_id                  IN   -- Requisition Line Id                                  |
  -- |    po_return_status               OUT  -- PO Retrun Status                                     |
  -- |    po_error_msg                   OUT  -- Error Message                                        |
  -- +================================================================================================+
  PROCEDURE cancel_req_line(
      pi_pr_header_id    IN      po_requisition_headers_all.requisition_header_id%TYPE,
      pi_pr_line_id      IN      po_requisition_lines_all.requisition_line_id%TYPE,
      po_return_status   OUT     VARCHAR2,
      po_error_msg       OUT     VARCHAR2
     )
  IS
    ln_msg_count NUMBER;
    lc_msg_data VARCHAR2 (1000);
  BEGIN
    --call the Cancel API for PO Requisition
    po_req_document_cancel_grp.cancel_requisition (p_api_version    => 1.0,
                                                   p_req_header_id  => po_tbl_number(pi_pr_header_id),
                                                   p_req_line_id    => po_tbl_number(pi_pr_line_id),
                                                   p_cancel_date    => SYSDATE,
                                                   p_cancel_reason  => 'Cancelled Requisition',
                                                   p_source         => 'REQUISITION',
                                                   x_return_status  => po_return_status,
                                                   x_msg_count      => ln_msg_count,
                                                   x_msg_data       => lc_msg_data);
    -- Get any messages returned by the Cancel API
    FOR i IN 1..FND_MSG_PUB.count_msg
    LOOP
      po_error_msg := FND_MSG_PUB.Get(p_msg_index => i,
                                      p_encoded => 'F');
    END LOOP;
  EXCEPTION
    WHEN OTHERS
    THEN
      IF po_error_msg IS NULL 
      THEN
        po_error_msg := 'Error while cancelling the PO Requsition Line number: '||' '||SUBSTR(sqlerrm,1,200);
      END IF;
      log_msg(TRUE, SUBSTR(po_error_msg,1,2000));
  END cancel_req_line;

  -- +===============================================================================================+
  -- | Name  : cancel_po_req_lines                                                                    |
  -- | Description     : Call Standard API to cancel the PO Requistion Line for all the Rejected lines|
  -- |    pi_po_number                   IN   -- PO Number                                            |
  -- |    pi_po_line_num                 IN   -- PO Line Number                                       |
  -- |    po_return_status               OUT  -- PO Retrun Status                                     |
  -- |    po_error_msg                   OUT  -- Error Message                                        |
  -- +================================================================================================+
  PROCEDURE cancel_po_req_lines(
      pi_po_number       IN      po_headers_all.segment1%TYPE,
      pi_po_line_num     IN      po_lines_all.line_num%TYPE,
      po_return_status   OUT     VARCHAR2,
      po_error_msg       OUT     VARCHAR2
     )
  IS
    ln_po_header_id          po_headers_all.po_header_id%TYPE;
    ln_po_line_id            po_lines_all.po_line_id%TYPE;
    lc_error_message         VARCHAR2(2000);
    lc_return_status         VARCHAR2(2000);
    ln_curr_po_line_id       po_lines_all.po_line_id%TYPE;
    ln_prev_po_line_id       po_lines_all.po_line_id%TYPE;
  BEGIN

    ln_po_header_id := NULL;
    ln_po_line_id := NULL; 
    lc_error_message := NULL;
    lc_return_status := NULL; 
    po_error_msg := NULL;
    ln_curr_po_line_id := NULL;
    ln_prev_po_line_id := NULL;  

    log_msg(lc_debug_flag, 'Getting PO Header Id'); 
    SELECT po_header_id
    INTO ln_po_header_id
    FROM po_headers_all
    WHERE segment1 = pi_po_number;
    log_msg(lc_debug_flag, 'PO Header Id : '||ln_po_header_id); 
               
    log_msg(lc_debug_flag, 'Getting PO Line Id');
    SELECT po_line_id
    INTO ln_po_line_id
    FROM po_lines_all
    WHERE po_header_id = ln_po_header_id
    AND line_num = pi_po_line_num;
    log_msg(lc_debug_flag, 'PO Line Id : '||ln_po_line_id);

    FOR req_data IN (SELECT requisition_header_id,
                            requisition_line_id,
                            line_num,
                            segment1,
                            po_header_id,
                            po_line_id
                     FROM po_distributions_v
                     WHERE po_header_id = ln_po_header_id
                     AND po_line_id = ln_po_line_id)
    LOOP

      ln_curr_po_line_id := req_data.po_line_id;

      log_msg(lc_debug_flag, 'ln_curr_po_line_id : '||ln_curr_po_line_id||' ,ln_prev_po_line_id: '||ln_prev_po_line_id);
      IF ln_curr_po_line_id <> nvl(ln_prev_po_line_id,0) 
      THEN      
        log_msg(lc_debug_flag, 'Cancelling the PO: '||pi_po_number||' Line: '||pi_po_line_num);
        cancel_po_line(pi_po_number       => pi_po_number,
                       pi_po_line_num     => pi_po_line_num,
                       po_return_status   => lc_return_status,
                       po_error_msg       => lc_error_message);

        IF lc_error_message IS NOT NULL
        THEN 
          po_error_msg := po_error_msg || lc_error_message; 
        END IF;
      END IF;

      log_msg(lc_debug_flag, 'PO Requistion Number is '||req_data.segment1||' ,Line Number '||req_data.line_num||' ,Requisition Header Id '||req_data.requisition_header_id||' ,Requisition Line Id : '||req_data.requisition_line_id);
      --call the Cancel API for PO Requisition
      cancel_req_line(pi_pr_header_id    => req_data.requisition_header_id,
                      pi_pr_line_id      => req_data.requisition_line_id,
                      po_return_status   => lc_return_status,
                      po_error_msg       => lc_error_message);

      IF lc_error_message IS NOT NULL 
      THEN
        po_error_msg := po_error_msg || lc_error_message;
      ELSE
        log_msg(lc_debug_flag, 'PO Requistion Number is '||req_data.segment1||' ,Line Number '||req_data.line_num||' got cancelled ');
      END IF;

      ln_prev_po_line_id := req_data.po_line_id;

    END LOOP;
  EXCEPTION
    WHEN OTHERS
    THEN
      IF po_error_msg IS NULL 
      THEN
        po_error_msg := 'Error while cancelling the PO Requsition Line number: '||' '||SUBSTR(sqlerrm,1,200);
      END IF;
      log_msg(TRUE, SUBSTR(po_error_msg,1,2000));
  END cancel_po_req_lines;
  
  -- +===============================================================================================+
  -- | Name  : update_po_line                                                                        |
  -- | Description     : This Procedure used to Update PO Line Quantity and Price                    |
  -- |    pi_po_number                   IN   -- PO Number                                           |
  -- |    pi_po_line_num                 IN   -- PO Line Number                                      |
  -- |    pi_confirmed_qty               IN   -- PO Confirmed Quantity                               |
  -- |    pi_new_price                   IN   -- PO New Price                                        |
  -- |    po_return_status               OUT  -- PO Retrun Status                                    |
  -- |    po_error_msg                   OUT  -- Error Message                                       |
  -- +================================================================================================+

  PROCEDURE update_po_line(
      pi_po_number       IN      po_headers_all.segment1%TYPE,
      pi_po_line_num     IN      po_lines_all.line_num%TYPE,
      pi_confirmed_qty   IN      po_lines_all.quantity%TYPE,
      pi_new_price       IN      po_lines_all.unit_price%TYPE,
      po_return_status   OUT     VARCHAR2,
      po_error_msg       OUT     VARCHAR2
     )
  IS
    ln_result          NUMBER;
    lr_api_errors      PO_API_ERRORS_REC_TYPE;
    ln_revision_num    NUMBER;
  BEGIN
  
  log_msg(lc_debug_flag, 'inside update_po_line ');
  log_msg(lc_debug_flag, 'pi_po_line_num : '||pi_po_line_num);
  log_msg(lc_debug_flag, 'pi_confirmed_qty :'||pi_confirmed_qty);
  log_msg(lc_debug_flag, 'pi_new_price :'||pi_new_price);
  
  
    --call the Update Quantity API
    select revision_num
    into ln_revision_num
    from po_headers_all
    where segment1 = pi_po_number
    and org_id = fnd_global.org_id;    
    
    log_msg(lc_debug_flag, 'ln_revision_num: '||ln_revision_num);

    ln_result := po_change_api1_s.update_po ( X_PO_NUMBER => pi_po_number,
                                             X_RELEASE_NUMBER => Null,
                                             X_REVISION_NUMBER => ln_revision_num, --rev_num,
                                             X_LINE_NUMBER => pi_po_line_num,
                                             X_SHIPMENT_NUMBER => NULL, --shipment_num,
                                             NEW_QUANTITY => pi_confirmed_qty,
                                             NEW_PRICE => pi_new_price,
                                             NEW_PROMISED_DATE => NULL, --TO_DATE(TO_CHAR('30-Mar-2010'),'DD-MON-YYYY'),
                                             NEW_NEED_BY_DATE => Null,
                                             LAUNCH_APPROVALS_FLAG => 'Y',
                                             UPDATE_SOURCE => 'API',
                                             VERSION => '1.0',
                                             X_OVERRIDE_DATE => Null,
                                             X_API_ERRORS => lr_api_errors,
                                             p_BUYER_NAME => Null,
                                             p_secondary_quantity => Null,
                                             p_preferred_grade => Null,
                                             p_org_id => fnd_global.org_id);

    IF (ln_result <> 1) THEN
       -- Display the errors
      FOR i IN 1..lr_api_errors.message_text.COUNT LOOP
         log_msg(TRUE, 'Error while updating the Quantity ' ||lr_api_errors.message_text(i));
         po_error_msg := po_error_msg||' '||lr_api_errors.message_text(i);
      END LOOP;
    END IF;

  EXCEPTION
    WHEN OTHERS
    THEN
      po_error_msg := 'Error while updating the po line quantity: '|| pi_po_line_num ||' '||SUBSTR(sqlerrm,1,200);
      log_msg(TRUE, po_error_msg);
  END update_po_line;

  -- +===============================================================================================+
  -- | Name  : send_mail                                                                             |
  -- | Description     : Send EMAIL to Buisness for each PO with the current status                  |
  -- |                      i:e accept or reject in AOPS.                                            |
  -- |    pi_po_number                  IN  -- PO Number                                             |
  -- |    pi_aops_number                IN  -- AOPS Number                                           |
  -- |    pi_mail_body                  IN  -- Mail Body                                             |
  -- |    po_error_msg                  OUT -- Error Message                                         |
  -- +================================================================================================+

  PROCEDURE send_mail(pi_mail_subject       IN     VARCHAR2,
                      pi_mail_body          IN     VARCHAR2,
                      pi_mail_sender        IN     VARCHAR2,
                      pi_mail_recipient     IN     VARCHAR2,
                      pi_mail_cc_recipient  IN     VARCHAR2,
                      po_return_msg         OUT    VARCHAR2)
  IS
    lc_error_msg              VARCHAR2 (4000);
    lc_conn                   UTL_SMTP.connection;
    lc_mail                   VARCHAR2 (2000) := NULL;
    lc_instance_name          VARCHAR2 (10) := NULL;
    lc_mime_type              VARCHAR2 (1000) := NULL;
    l_boundary                VARCHAR2 (50) := '----=*#abc1234321cba#*=';

    BEGIN
      lc_error_msg    := NULL;
      log_msg(TRUE, 'In Send_Mail ');

      BEGIN
        SELECT instance_name
        INTO  lc_instance_name
        FROM v$instance;
      EXCEPTION
        WHEN OTHERS
        THEN 
          lc_instance_name := NULL;
          log_msg(TRUE, 'Error While Getting the Instance Name :'||substr(sqlerrm,1,2000));
      END;

      log_msg(TRUE,'Sender :'||pi_mail_sender||chr(10)
                 ||'Recipient :'||pi_mail_recipient||chr(10)
                 ||'cc Recipient :'||pi_mail_cc_recipient||chr(10)
                 ||'Subject :'||pi_mail_subject);

      -- Calling xx_pa_pb_mail procedure to mail

      lc_mime_type := 'MIME-Version: 1.0' || UTL_TCP.CRLF;
      lc_mime_type := lc_mime_type ||'Content-Type: multipart/alternative; boundary="' || l_boundary || '"' || UTL_TCP.CRLF|| UTL_TCP.CRLF;

      lc_conn := xx_pa_pb_mail.begin_mail (sender          => pi_mail_sender,
                                           recipients      => pi_mail_recipient,
                                           cc_recipients   => pi_mail_cc_recipient,
                                           subject         => lc_instance_name||' : '||pi_mail_subject,
                                           mime_type       => lc_mime_type
                                          );
       -- Code to send the mail in html format
       xx_pa_pb_mail.write_text (conn      => lc_conn,
                                 message   => '--' || l_boundary || UTL_TCP.CRLF);
       xx_pa_pb_mail.write_text (conn      => lc_conn,
                                 message   => 'Content-Type: text/html; charset="iso-8859-1"' || UTL_TCP.CRLF || UTL_TCP.CRLF);
       --Mail Body                                             
       xx_pa_pb_mail.write_text (conn   => lc_conn,
                                 message   => pi_mail_body);
       --End of mail                                    
       xx_pa_pb_mail.end_mail (conn => lc_conn);
       log_msg(TRUE,'End of Send_Mail Program'); 
  EXCEPTION
    WHEN OTHERS
    THEN
      lc_error_msg := 'Error while sending the mail' || substr(SQLERRM,1,2000);
      po_return_msg   := lc_error_msg;
      log_msg(TRUE, lc_error_msg);
  END send_mail;

  -- +===============================================================================================+
  -- | Name  : get_line_details                                                                      |
  -- | Description     : This Procedure used to get the PO Line Details                              |
  -- |    pi_po_number                   IN   -- PO Number                                           |
  -- |    pi_po_line_num                 IN   -- PO Line Number                                      |
  -- |    po_item_num                    OUT  -- PO Item Number                                      |
  -- |    po_requested_qty               OUT  -- PO Requested Quantity                               |
  -- |    po_dest_location               IN   -- PO Destination Location                             |
  -- |    po_error_msg                   OUT  -- Error Message                                       |
  -- +================================================================================================+
  PROCEDURE get_line_details(pi_po_number        IN  VARCHAR2,
                             pi_po_line_num      IN  VARCHAR2,
                             po_item_num         OUT VARCHAR2,
                             po_item_description OUT VARCHAR2,
                             po_requested_qty    OUT NUMBER,
                             po_dest_location    OUT VARCHAR2,
                             po_error_msg        OUT VARCHAR2)
  IS
  BEGIN
    po_error_msg        := NULL;
    po_item_num         := NULL;
    po_requested_qty    := NULL;
    po_dest_location    := NULL;

    SELECT pol.vendor_product_num,
           pol.quantity,
           hl.location_code,
           pol.item_description
    INTO po_item_num,
         po_requested_qty,
         po_dest_location,
         po_item_description
    FROM po_lines_all pol,
         po_headers_all poh,
         po_line_locations_all pll,
         hr_locations_all hl
    WHERE pol.po_header_id = poh.po_header_id
    AND pol.po_line_id = pll.po_line_id
    AND pll.ship_to_location_id = hl.location_id
    AND poh.segment1 = pi_po_number
    AND poh.org_id = fnd_global.org_id
    AND pol.line_num = pi_po_line_num;

   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       po_error_msg := 'No Item,Requested Qty, Dest Location found for the PO '||pi_po_number||' Line: '||pi_po_line_num;
       log_msg(TRUE, po_error_msg);
     WHEN OTHERS
     THEN
       po_error_msg := 'Error while getting the PO Line Details '|| substr(SQLERRM,1,2000);
       log_msg(TRUE, po_error_msg);
  END get_line_details;
  
  -- +===============================================================================================+
  -- | Name  : LOAD_ORDER_CONFIRMATON                                                                |
  -- | Description     : Load the PO confirmation PAYLOAD from B2B                                   |
  -- |    p_conf_payload            IN -- PO Payload Data                                            |
  -- |    p_out                     IN -- Output Message                                             |
  -- +================================================================================================+
 
  PROCEDURE LOAD_ORDER_CONFIRMATON(
        CONF_PAYLOAD     IN  VARCHAR2,
        OUT              OUT VARCHAR2)
  IS
    BEGIN 
      XX_PO_PUNCHOUT_CONF_PKG.INSERT_ROW(P_CONF_PAYLOAD      =>  CONF_PAYLOAD,
                                         P_out               =>  out);
    EXCEPTION
      WHEN OTHERS

      THEN
        log_msg(TRUE, 'Exception when calling Punchout Insert Row Procedure.');
    END LOAD_ORDER_CONFIRMATON;

  -- +===============================================================================================+
  -- | Name  : insert_po_header_info                                                                 |
  -- | Description     : This Procedure used to Load the PO Header Information                       |
  -- |    p_record_id                  IN  -- Record Id                                              |
  -- |    p_po_num                     IN  -- PO Number                                              |
  -- |    p_order_num                  IN  -- AOPS Order Number                                      |
  -- |    p_record_status              IN  -- Record Status                                          |
  -- |    p_insert_status              OUT  -- Insert Status                                         |
  -- |    p_insert_err_msg             OUT  -- Error Message                                         |
  -- +================================================================================================+

  PROCEDURE insert_po_header_info ( 
         p_record_id      IN NUMBER,
         p_po_num         IN VARCHAR2,
         p_order_num      IN VARCHAR2,
         p_record_status  IN VARCHAR2,
		 p_po_status      IN VARCHAR2,
         p_insert_status  OUT VARCHAR2,
         p_insert_err_msg OUT VARCHAR2)
  IS
  BEGIN
    INSERT INTO XX_PO_PUNCH_HEADER_INFO
      (RECORD_ID,
       PO_NUMBER,
       ORDER_NUM,
       RECORD_STATUS,
       PO_STATUS,
       ERROR_MESSAGE,
       CREATED_BY,
       CREATION_DATE,
       LAST_UPDATED_BY,
       LAST_UPDATE_DATE,
       LAST_UPDATE_LOGIN)
    VALUES 
      (p_record_id,
       p_po_num,
       p_order_num,
       p_record_status,
       p_po_status,
       NULL,
       fnd_global.user_id,
       sysdate,
       fnd_global.user_id,
       sysdate,
       fnd_global.user_id);
           
       p_insert_status := 'S';
       p_insert_err_msg := NULL;
      
    EXCEPTION WHEN OTHERS THEN
      p_insert_status := 'E';
      p_insert_err_msg := substr(sqlerrm,1,2000);
      log_msg(TRUE, p_insert_err_msg);
    END insert_po_header_info;

  -- +===============================================================================================+
  -- | Name  : insert_po_lines_info                                                                  |
  -- | Description     : This Procedure used to Load the PO Lines Information                        |
  -- |    p_record_id                  IN  -- Record Id                                              |
  -- |    p_po_num                     IN  -- PO Number                                              |
  -- |    p_po_line_num                IN  -- PO Line NUmber                                         |
  -- |    p_line_status                IN  -- Line Status                                            |
  -- |    p_confirmed_qty              IN  -- Confirmed Quantity                                     |
  -- |    p_record_status              IN  -- Record Status                                          |
  -- |    p_insert_status              OUT  -- Insert Status                                         |
  -- |    p_insert_err_msg             OUT  -- Error Message                                         |
  -- +================================================================================================+

    PROCEDURE insert_po_lines_info ( 
           p_record_id      IN NUMBER,
           p_po_num         IN VARCHAR2,
           p_po_line_num    IN NUMBER,
           p_line_status    IN VARCHAR2,
           p_confirmed_qty  IN NUMBER,
           p_record_status  IN VARCHAR2,
           p_insert_status  OUT VARCHAR2,
           p_insert_err_msg OUT VARCHAR2)
    
    IS
      
    BEGIN
        
      INSERT INTO XX_PO_PUNCH_LINES_INFO
        (RECORD_ID,
         PO_NUMBER,
         PO_LINE_NUM,
         LINE_STATUS,
         CONFIRMED_QTY,
         RECORD_STATUS,
         ERROR_MESSAGE,
         CREATED_BY,
         CREATION_DATE,
         LAST_UPDATED_BY,
         LAST_UPDATE_DATE,
         LAST_UPDATE_LOGIN)
       VALUES (
         p_record_id,
         p_po_num,
         p_po_line_num,
         p_line_status,
         p_confirmed_qty,
         'NEW',
         NULL,
         fnd_global.user_id,
         sysdate,
         fnd_global.user_id,
         sysdate,
         fnd_global.user_id);
        
       p_insert_status := 'S';
       p_insert_err_msg := NULL;

     EXCEPTION WHEN OTHERS THEN
       p_insert_status := 'E';
       p_insert_err_msg := substr(sqlerrm,1,2000);
       log_msg(TRUE, p_insert_err_msg);
     END INSERT_PO_LINES_INFO;

  -- +===============================================================================================+
  -- | Name  : process_confirm_details                                                               |
  -- | Description     : This Procedure used to Extract the cXML Payload and get the PO Information  |
  -- |    p_return_status         OUT  -- Return Status                                              |
  -- |    p_error_msg             OUT  -- Error Message                                              |
  -- +================================================================================================+

    PROCEDURE process_confirm_details (pi_status       IN  xx_po_punchout_confirmation.record_status%TYPE,
	                               p_return_status OUT VARCHAR2
                                      ,p_error_msg     OUT VARCHAR2)
    IS 
      CURSOR c_get_payload_data
      IS
        SELECT record_id
              ,confirm_payload
        FROM XX_PO_PUNCHOUT_CONFIRMATION
        WHERE record_status = NVL(pi_status, record_status)
        AND record_status != 'PROCESSED'
        ORDER BY record_id;
    
    lxml_payload_data        xmltype;
    lp_parser                XMLPARSER.PARSER;
    lc_xml                   VARCHAR2(32000);
    ldom_retcode             XMLDOM.DOMDOCUMENT;
    ldom_root_node           XMLDOM.DOMELEMENT;
    lc_nspace                VARCHAR2(50);
    ldom_elemnt_nodes        XMLDOM.DOMNODELIST;
    ln_length                NUMBER;
    ldom_node                XMLDOM.DOMNODE;
    ldom_node_element        xmldom.domelement;
    ldom_nodelist            xmldom.domnodelist;
    ln_len1                  NUMBER;
    ln_len2                  NUMBER;
    ldom_first_child         xmldom.domnode;
    ldom_node1               xmldom.domnode;
    ldom_node2               xmldom.domnode;
    ln_inv_lines_count       NUMBER := 0;
    ldom_node_ele1           xmldom.domelement;
    ldom_nodelist1           xmldom.domnodelist;
    lc_po_num                VARCHAR2(30);
    lc_order_num             VARCHAR2(30);
    lc_po_status             VARCHAR2(30);
    ln_po_line_num           NUMBER;
    lc_line_status           VARCHAR2(30);
    ln_quantity              NUMBER;
    lc_hdr_insert_status         VARCHAR2(1) := NULL;
    lc_hdr_insert_err_msg        VARCHAR2(4000);
    lc_line_insert_status         VARCHAR2(1) := NULL;
    lc_line_insert_err_msg        VARCHAR2(4000);
    e_process_hdr_exception       EXCEPTION;
    e_process_line_exception      EXCEPTION;
    lc_error_message              VARCHAR2(4000);
    
    BEGIN
      FOR payload_rec IN c_get_payload_data
      LOOP
      BEGIN
        log_msg(TRUE,' Processing Record Id : '||payload_rec.record_id);

        ln_inv_lines_count := 0;
        lxml_payload_data := NULL;
        lc_po_num := NULL;
        lc_order_num := NULL;

        IF payload_rec.confirm_payload IS NOT NULL THEN
          lxml_payload_data := xmltype(payload_rec.confirm_payload);
        ELSE 
          log_msg(TRUE,'PayLoad Id is Null... ');
          RAISE e_process_hdr_exception;
        END IF;

        --Getting the Header Information (PO Number, Order Number) from Payload
        BEGIN
          SELECT extractvalue(lxml_payload_data,'/cXML/Request/ConfirmationRequest/OrderReference/@orderID')
                ,extractvalue(lxml_payload_data,'/cXML/Request/ConfirmationRequest/ConfirmationHeader/@invoiceID')
                ,extractvalue(lxml_payload_data,'/cXML/Request/ConfirmationRequest/ConfirmationHeader/@type') 
          INTO lc_po_num
              ,lc_order_num
              ,lc_po_status
          FROM DUAL;

          lc_po_num := substr(lc_po_num,1,instr(lc_po_num,':',1)-1);

        EXCEPTION WHEN OTHERS THEN
          lc_po_num := NULL;
          lc_order_num := NULL;
          lc_po_status := NULL;
        END;

        lc_hdr_insert_status := NULL;
        lc_hdr_insert_err_msg := NULL;
        log_msg(TRUE,' Inserting the PO Punchout Header Data from cXML Payload : '||payload_rec.record_id);

        --Inserting the PO Punchout Header Data
        --log_msg(TRUE,'Inserting the PO Punchout Header Data... ');
        insert_po_header_info( p_record_id => payload_rec.record_id,
                               p_po_num => lc_po_num,
                               p_order_num => lc_order_num,
                               p_record_status => 'NEW',
							   p_po_status => lc_po_status,
                               p_insert_status => lc_hdr_insert_status, 
                               p_insert_err_msg => lc_hdr_insert_err_msg);
        IF lc_hdr_insert_status <> 'S' THEN
          log_msg(TRUE,'Error While Inserting the Record Id : '||payload_rec.record_id||' for the PO '||
                         lc_po_num||' Header Data, Error :'||lc_hdr_insert_err_msg);
          RAISE e_process_hdr_exception;
        END IF;

    lp_parser := xmlparser.newparser;
    lc_xml := lxml_payload_data.GETSTRINGVAL();
    xmlparser.parsebuffer(lp_parser, lc_xml);
    ldom_retcode := xmlparser.getdocument(lp_parser);
    xmlparser.freeparser(lp_parser);
    ldom_root_node := xmldom.getdocumentelement(ldom_retcode);
    lc_nspace := xmldom.getnamespace(ldom_root_node);
    ldom_elemnt_nodes := xmldom.getchildrenbytagname(ldom_root_node, '*', lc_nspace);
    ln_length := XMLDOM.GETLENGTH(ldom_elemnt_nodes);

    FOR i IN 0 .. ln_length - 1 LOOP
      ldom_node := xmldom.item(ldom_elemnt_nodes, i);
      IF xmldom.getnodename(ldom_node) = 'Request' THEN
        ldom_node_element := xmldom.makeelement(ldom_node);
        ldom_nodelist := xmldom.getchildrenbytagname(ldom_node_element,'ConfirmationRequest',lc_nspace);
        ln_len1 := xmldom.getlength(ldom_nodelist);
           FOR j IN 0 .. ln_len1 - 1 LOOP
             ldom_node1     := xmldom.item(ldom_nodelist, j);
             ldom_node_ele1 := xmldom.makeelement(ldom_node1);
             ldom_nodelist1 := xmldom.getelementsbytagname(ldom_node_ele1, '*', lc_nspace);
             ln_len2      := xmldom.getlength(ldom_nodelist1);
           END LOOP;
           FOR k IN 0 .. ln_len2 - 1 LOOP
             ldom_first_child := NULL;
             ldom_node2       := xmldom.item(ldom_nodelist1, k);
             IF xmldom.getnodename(ldom_node2) = 'ConfirmationItem' THEN
               ln_inv_lines_count := ln_inv_lines_count + 1;
             END IF;
           END LOOP;
       END IF;
     END LOOP;
        
    --Getting the Line Information (Line Status, Quantity) from Payload
    log_msg(TRUE, 'Lines Count is : ' || ln_inv_lines_count);
    FOR i IN 1 .. ln_inv_lines_count 
    LOOP
           
          ln_po_line_num := NULL;
          lc_line_status := NULL;
          ln_quantity := 0;

          SELECT 
            EXTRACTVALUE(lxml_payload_data,'/cXML/Request/ConfirmationRequest/ConfirmationItem[@lineNumber='||i||']/@lineNumber') po_line_Num,
            EXTRACTVALUE(lxml_payload_data,'/cXML/Request/ConfirmationRequest/ConfirmationItem[@lineNumber='||i||']/ConfirmationStatus/@type') line_Status, EXTRACTVALUE(lxml_payload_data,'/cXML/Request/ConfirmationRequest/ConfirmationItem[@lineNumber='||i||']/ConfirmationStatus/@quantity') Quantity
          INTO ln_po_line_num,
             lc_line_status,
             ln_quantity
          FROM DUAL;

          lc_line_insert_status := NULL;
          lc_line_insert_err_msg := NULL;
          
      log_msg(TRUE,' Inserting the PO Punchout Lines Data from cXML Payload : '||payload_rec.record_id);
      --Inserting the PO Punchout Lines Data
      insert_po_lines_info( p_record_id => payload_rec.record_id,
                            p_po_num => lc_po_num,
                            p_po_line_num => ln_po_line_num,
                            p_line_status => lc_line_status,
                            p_confirmed_qty => ln_quantity,
                            p_record_status => 'NEW',
                            p_insert_status => lc_line_insert_status, 
                            p_insert_err_msg => lc_line_insert_err_msg);
                                
           IF lc_line_insert_status <> 'S' THEN
             log_msg(TRUE,'Error While Inserting the Record Id : '||payload_rec.record_id||' for the PO '||
                      lc_po_num||' Line '||ln_po_line_num||' Data, Error :'||lc_line_insert_err_msg);
             RAISE e_process_line_exception;
           END IF;
        END LOOP;
       IF lc_hdr_insert_status = 'S' AND NVL(lc_line_insert_status,'S') = 'S' THEN
          log_msg(TRUE, 'Updating Status in Punchout Conf Table with PROCESSED status for the Record Id: '||payload_rec.record_id);
          update_po_punchout_rec_status(pi_record_id       => payload_rec.record_id,
                                        pi_rec_status      => 'PROCESSED',
                                        pio_error_msg      => lc_error_message);
       ELSE
          log_msg(TRUE, 'Updating Status in Punchout Conf Table with ERROR Status for the Record Id: '||payload_rec.record_id);
          update_po_punchout_rec_status(pi_record_id       => payload_rec.record_id,
                                        pi_rec_status      => 'ERROR',
                                        pio_error_msg      => lc_error_message);
          
       END IF;
    EXCEPTION WHEN e_process_hdr_exception THEN
      ROLLBACK;
      p_error_msg := lc_hdr_insert_err_msg;
      log_msg(TRUE, 'HDR Exception : ' || p_error_msg);
      update_po_punchout_rec_status(pi_record_id       => payload_rec.record_id,
                                    pi_rec_status      => 'ERROR',
                                    pio_error_msg      => p_error_msg);
    WHEN e_process_line_exception THEN
      ROLLBACK;
      p_error_msg := lc_line_insert_err_msg;
      log_msg(TRUE, 'Line Exception : ' || p_error_msg); 
      update_po_punchout_rec_status(pi_record_id       => payload_rec.record_id,
                                    pi_rec_status      => 'ERROR',
                                    pio_error_msg      => p_error_msg);
    WHEN OTHERS THEN
      ROLLBACK;
      p_error_msg := substr(sqlerrm,1,2000);
      log_msg(TRUE, p_error_msg); 
      update_po_punchout_rec_status(pi_record_id       => payload_rec.record_id,
                                    pi_rec_status      => 'ERROR',
                                    pio_error_msg      => p_error_msg);
    END;
	COMMIT; 
    END LOOP;
    p_return_status := 'S';
    p_error_msg := NULL;
  EXCEPTION 
  WHEN OTHERS THEN 
    ROLLBACK;
    p_return_status := 'E';
    p_error_msg := NVL(lc_error_message,substr(sqlerrm,1,2000));
    log_msg(TRUE, 'Exception in Main:' || p_error_msg);
  END process_confirm_details;
  
  -- +===============================================================================+
  -- | Name  : submit_req_import                                                     |
  -- | Description     : This Procedure used to Submit Requisition Import Program    |
  -- | Parameters      : p_batch_id, p_debug_flag, x_error_message, x_return_status  | 
  -- +===============================================================================+

  PROCEDURE submit_req_import ( p_batch_id         IN   NUMBER,
                                p_debug_flag       IN   BOOLEAN,
                                x_error_message    OUT  VARCHAR2,
                                x_return_status    OUT  VARCHAR2)
  IS
   ln_conc_request_id        fnd_concurrent_requests.request_id%TYPE;
  BEGIN

     MO_GLOBAL.init('PO');
     mo_global.set_policy_context('S',fnd_global.org_id);
     FND_REQUEST.SET_ORG_ID((fnd_global.org_id));

     log_msg (p_debug_flag, 'Submitting Requisition Import for batch id.....' || p_batch_id);

     ln_conc_request_id := fnd_request.submit_request (application => 'PO'       --Application, 
                                                      ,program     => 'REQIMPORT'    --Program, 
                                                      ,argument1   => NULL        --Interface Source code, 
                                                      ,argument2   => p_batch_id   --Batch ID, 
                                                      ,argument3   => 'ALL'        --Group By, BUYER 
                                                      ,argument4   => NULL           --Last Req Number, 
                                                      ,argument5   => 'Y'          --Multi Distributions, 
                                                      ,argument6   => 'N'  --Initiate Approval after ReqImport 
                                                      );
													   
    log_msg(p_debug_flag, 'Concurrent request id Submitted for the Requisition Import: '||ln_conc_request_id);

    COMMIT;

  EXCEPTION
    WHEN OTHERS
    THEN
      IF x_error_message IS NULL
      THEN
        x_error_message := SUBSTR('Error while submitting the Requisition import concurrent program' || SQLERRM , 1, 2000) ;
      END IF;
      x_return_status     := 'F';
  END submit_req_import;
  
  -- +============================================================================================+
  -- | Name  : get_mailing_info                                                                   |
  -- | Description     : This Procedure used to get the Email Subject and Body                    |
  -- | Parameters      : pi_template, pi_requisition_number, pi_po_number, pi_aops_number,        |
  -- |                   po_mail_subject, po_mail_body_hdr, po_mail_body_trl, pi_translation_info |
  -- +============================================================================================+
  PROCEDURE get_mailing_info(pi_template           IN VARCHAR2,
                             pi_requisition_number IN VARCHAR2,
                             pi_po_number          IN VARCHAR2,
                             pi_aops_number        IN VARCHAR2,
                             po_mail_subject       OUT VARCHAR2,
                             po_mail_body_hdr      OUT VARCHAR2,
                             po_mail_body_trl      OUT VARCHAR2,
                             pi_translation_info   IN xx_fin_translatevalues%ROWTYPE)
  IS
  BEGIN

    po_mail_subject := NULL;
    po_mail_body_hdr := NULL;
    po_mail_body_trl := NULL;
	
    IF pi_template = 'TEMPLATE4' THEN

      po_mail_subject := pi_translation_info.target_value16||' : '||pi_requisition_number;
      po_mail_body_hdr := '<html> <body> <font face = "Arial" size = "2">
                              Please note the replacement requisition creation failed for Buy from Ourselves canceled punch-out requisition: '||pi_requisition_number||'
                           <br>
                              Please contact requestor to create a new requisition for this purchase.
                           <br>
                           <br>
                           <table cellpadding=2 cellspacing=2>
                             <tr>
                               <td width="15%" align="left"><font face="Arial" size="2" color="BLACK">Req #</font></td>
                               <td width="15%" align="left"><font face="Arial" size="2" color="BLACK">Requestor</font></td>
                               <td width="15%" align="left"><font face="Arial" size="2" color="BLACK">Line #</font></td>
                               <td width="15%" align="left"><font face="Arial" size="2" color="BLACK">Item #</font></td>
                               <td width="40%" align="left"><font face="Arial" size="2" color="BLACK">Item Description</font></td>
                               <td width="15%" align="left"><font face="Arial" size="2" color="BLACK">Qty ordered</font></td>
                               <td width="15%" align="left"><font face="Arial" size="2" color="BLACK">Deliver To</font></td>
                             </tr>';
      po_mail_body_trl := '</table></body></html>';

    ELSIF pi_template = 'TEMPLATE3' THEN

      po_mail_subject := pi_translation_info.target_value16||' : '||pi_requisition_number;
      po_mail_body_hdr := '<html> <body> <font face = "Arial" size = "2">
                              Please note the replacement requisition creation failed for Buy from Ourselves canceled punch-out requisition: '||pi_requisition_number||'
                           <br>
                              Please see the below errors and inform to requestor if any issues related to setups.
                           <br>
                           <br>
                           <table cellpadding=2 cellspacing=2>
                             <tr>
                               <td width="15%" align="left"><font face="Arial" size="2" color="BLACK">Req #</font></td>
                               <td width="15%" align="left"><font face="Arial" size="2" color="BLACK">Requestor</font></td>
                               <td width="15%" align="left"><font face="Arial" size="2" color="BLACK">Line #</font></td>
                               <td width="15%" align="left"><font face="Arial" size="2" color="BLACK">Item #</font></td>
                               <td width="40%" align="left"><font face="Arial" size="2" color="BLACK">Error Message</font></td>
                             </tr>';
      po_mail_body_trl := '</table></body></html>';

    ELSIF pi_template = 'TEMPLATE2' THEN

      po_mail_subject := '**Action Required** Requisition '||pi_requisition_number||' not shipped in full.';
      po_mail_body_hdr := '<html> <body> <font face = "Arial" size = "2">The requisition above was unable to ship in full due to item(s) being temporarily unavailable.  Please review the item(s) and quantities below.  A new requisition will need to be submitted through the Jan/San punchout in iProcurement for the item(s) below.
                          <br>
                          <br>
                          <table cellpadding=2 cellspacing=2>
                            <tr>
                              <td width="20%" align="left"><font face="Arial" size="2" color="BLACK">Sku</font></td>
							  <td width="40%" align="left"><font face="Arial" size="2" color="BLACK">Item Description</font></td>
                              <td width="20%" align="left"><font face="Arial" size="2" color="BLACK">Quantity Ordered</font></td>
                              <td width="20%" align="left"><font face="Arial" size="2" color="BLACK">Quantity Shipped</font></td>
							  <td width="40%" align="left"><font face="Arial" size="2" color="BLACK">Deliver To</font></td>
                            </tr>';
      po_mail_body_trl := '</table> 
                           <br>
                           <br>
                             <b>For Stores</b> - If your location is completely out of this item, store use a comparable item.  Any items that are store used must be documented properly.  Refer to SOP 2.45 for inventory adjustment instructions.
						   <br>
                           <br>
						     <b>For Warehouses</b> - If your location is completely out of the unavailable item, pull a comparable product from the D and D area. These item(s) must be processed as '||'"'||'Store Use Adjustment'||'"'||' in the Store Inventory (WebCom) and an APMA adjustment with Reason Code '||'"'||'SU'||'"'||' in WMS. Do not process as '||'"'||'DNC'||'"'||'; refer to ICW08.01 Destroy Merchandise Workflow Instruction.  If your location is completely out of this item, use the purchase card to purchase a comparable item.
                           <br>
                           <br>
                             <b>For BSD Offices and Corporate</b> - If your location is completely out of the unavailable item, use the purchase card to purchase a comparable item or email iosupplyorders@officedepot.com with the requisition, item number and quantity needed and Procurement will assist with purchasing.
                           </body></html>';

    ELSIF pi_template = 'TEMPLATE1' THEN

	  po_mail_subject := pi_translation_info.target_value6 ||' Purchase Order :'||pi_po_number||' AOPS Order Number :'||pi_aops_number ||pi_translation_info.target_value9 ;
	  po_mail_body_hdr := '<html> <body> <font face = "Arial" size = "2">
                                Following PO Lines have been Cancelled /Rejected :
                               <br>
                               <br>
                               <table cellpadding=2 cellspacing=2>
                               <tr>
                                 <td width="15%" align="left"><font face="Arial" size="2" color="BLACK">Line Number</font></td>
                                 <td width="20%" align="left"><font face="Arial" size="2" color="BLACK">Supplier Item</font></td>
                                 <td width="20%" align="left"><font face="Arial" size="2" color="BLACK">Requested Qty</font></td>
                                 <td width="20%" align="left"><font face="Arial" size="2" color="BLACK">Confirmed Qty</font></td>
                                 <td width="25%" align="left"><font face="Arial" size="2" color="BLACK">Dest Location</font></td>
                              </tr>';
          po_mail_body_trl := '</table></body></html>';
     END IF;
	
  END;

  -- +=====================================================================================+
  -- | Name  : get_mail_body                                                               |
  -- | Description     : This Procedure used to get the Email Body with data               |
  -- | Parameters      : pi_template, pi_requisition_number, pi_requestor, pi_req_line_num,|
  -- |                   pi_vendor_product_num, pi_item_description, pi_quantity,          |
  -- |                   pi_location, pi_error_message, pi_quantity_confirmed              |
  -- +=====================================================================================+
  FUNCTION get_mail_body( pi_template           IN VARCHAR2,
                          pi_requisition_number IN VARCHAR2,
                          pi_requestor          IN VARCHAR2,
                          pi_req_line_num       IN VARCHAR2,
                          pi_vendor_product_num IN VARCHAR2,
                          pi_item_description   IN VARCHAR2,
                          pi_quantity           IN VARCHAR2,
                          pi_location           IN VARCHAR2,
                          pi_error_message      IN VARCHAR2,
                          pi_quantity_confirmed IN VARCHAR2)
  RETURN VARCHAR2
  IS
    lc_mail_body  VARCHAR2(32000);
  BEGIN
    lc_mail_body := NULL;

    IF pi_template = 'TEMPLATE4' THEN
      lc_mail_body := lc_mail_body ||'<tr>';
      lc_mail_body := lc_mail_body ||'<td width="15%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_requisition_number||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="15%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_requestor||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="15%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_req_line_num||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="15%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_vendor_product_num||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="40%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_item_description||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="40%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_quantity||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="40%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_location||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'</tr>' || CHR (10);
    ELSIF pi_template = 'TEMPLATE3' THEN
      lc_mail_body := lc_mail_body ||'<tr>';
      lc_mail_body := lc_mail_body ||'<td width="15%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_requisition_number||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="15%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_requestor||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="15%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_req_line_num||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="15%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_vendor_product_num||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="40%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_error_message||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'</tr>' || CHR (10);
    ELSIF pi_template = 'TEMPLATE2' THEN
      lc_mail_body := lc_mail_body ||'<tr>';
      lc_mail_body := lc_mail_body ||'<td width="20%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_vendor_product_num||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="40%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_item_description||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="20%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_quantity||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="20%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_quantity_confirmed||'</font></td>'||CHR(10);
	  lc_mail_body := lc_mail_body ||'<td width="40%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_location||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'</tr>' || CHR (10);
    ELSIF pi_template = 'TEMPLATE1' THEN
      lc_mail_body := lc_mail_body ||'<tr>';
      lc_mail_body := lc_mail_body ||'<td width="15%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_req_line_num||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="15%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_vendor_product_num||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="40%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_quantity||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="40%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_quantity_confirmed||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'<td width="40%" align="left"><font face="Arial" size="2" color="BLACK">'||pi_location||'</font></td>'||CHR(10);
      lc_mail_body := lc_mail_body ||'</tr>' || CHR (10);
    END IF;
      RETURN lc_mail_body;
  END;
  
  -- +===============================================================================================+
  -- | Name  : get_requestor_info                                                                    |
  -- | Description     : This function returns the Requisition requestor info                        |
  -- | Parameters      : p_preparer_id, xx_requestor_info, xx_error_message                          |
  -- +================================================================================================+

  FUNCTION get_requestor_info (pi_preparer_id          IN  per_people_v7.person_id%TYPE,
                               xx_requestor_info       OUT per_people_v7%ROWTYPE,
                               xx_error_message        OUT VARCHAR2)
  RETURN VARCHAR2
  IS
    lc_return_status     VARCHAR2(20) := NULL;

  BEGIN
    BEGIN
      xx_error_message     := NULL;
      xx_requestor_info         := NULL;

      SELEcT *
      INTO xx_requestor_info
      FROM per_people_v7
      WHERE person_id = pi_preparer_id
      AND (effective_end_date > sysdate or effective_end_date is null);

      lc_return_status  := 'TRUE';

    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        xx_error_message  := ' Requestor Information not found ';
        lc_return_status  := 'FALSE';
      WHEN OTHERS
      THEN
        xx_error_message  :=
          SUBSTR('Error while getting the Requestor Information ' ||SQLERRM,1,2000);
        lc_return_status  := 'FALSE';
    END;

    RETURN lc_return_status;

  END get_requestor_info;
  
  -- +========================================================================================+
  -- | Name  : get_location_name                                                              |
  -- | Description     : Function to return the Location Name                                 |
  -- | Parameters      : pi_deliver_to_location_id                                            |
  -- +========================================================================================+
  FUNCTION get_location_name ( pi_deliver_to_location_id IN NUMBER)
  RETURN VARCHAR2
  IS
    lc_location_name VARCHAR2(100);
  BEGIN
    lc_location_name := NULL;
    
    SELECT description
    INTO lc_location_name
    FROM hr_locations_all
    WHERE location_id = pi_deliver_to_location_id;
	
    RETURN lc_location_name;

  EXCEPTION WHEN OTHERS THEN  
    RETURN lc_location_name;
  END;
  
  -- +========================================================================================+
  -- | Name  : mail_error_info                                                                |
  -- | Description     : This Procedure used to send the email to requestor and Internal Team |
  -- | Parameters      : pi_req_header_rec, pi_req_line_detail_tab, pi_translation_info,      |
  -- |                   pi_po_number, pi_aops_number, pi_error_message                       |
  -- +========================================================================================+
  
  PROCEDURE mail_error_info( pi_req_header_rec       IN  xx_po_create_punchout_req_pkg.xx_po_req_hdr_rec%TYPE,
                             pi_req_line_detail_tab  IN  xx_po_create_punchout_req_pkg.xx_po_req_line_tbl%TYPE,
                             pi_translation_info     IN  xx_fin_translatevalues%ROWTYPE,
                             pi_po_number            IN  po_headers_all.segment1%TYPE,
                             pi_aops_number          IN  VARCHAR2,
                             pi_error_message        IN  po_interface_errors.error_message%TYPE)
  IS
    lc_int_mail_subject VARCHAR2(32000);
    lc_int_body_hdr     VARCHAR2(32000);
    lc_int_body_trl     VARCHAR2(32000);
    lc_req_mail_subject VARCHAR2(32000);
    lc_req_body_hdr     VARCHAR2(32000);
    lc_req_body_trl     VARCHAR2(32000);
    lr_lines_rec        po_requisition_lines_all%ROWTYPE;
    lc_req_mail_body    VARCHAR2(32000) := NULL;
    lc_int_mail_body    VARCHAR2(32000) := NULL;
    lc_error_message    VARCHAR2(4000);
    l_req_info          per_people_v7%ROWTYPE;
    e_mail_error        EXCEPTION;
    lc_status           VARCHAR2(100) := NULL;
  BEGIN
    lc_req_mail_subject := NULL;
    lc_req_body_hdr := NULL;
    lc_req_body_trl := NULL;
	
	log_msg(TRUE, 'Getting the Mail Subject and Body for Requestor');
    -- Getting Mail Subject and body for Requestor.
    get_mailing_info(pi_template           => pi_translation_info.target_value21,
                     pi_requisition_number => pi_req_header_rec.segment1,
                     pi_po_number          => pi_po_number,
                     pi_aops_number        => pi_aops_number,
                     po_mail_subject       => lc_req_mail_subject,
                     po_mail_body_hdr      => lc_req_body_hdr,
                     po_mail_body_trl      => lc_req_body_trl,
                     pi_translation_info   => pi_translation_info);
	
    lc_int_mail_subject := NULL;
    lc_int_body_hdr := NULL;
    lc_int_body_trl := NULL;

    log_msg(TRUE, 'Getting the Mail Subject and Body for Internal Team');
    -- Getting Mail Subject and body for Internal Team.	
    get_mailing_info(pi_template           => pi_translation_info.target_value20,
                     pi_requisition_number => pi_req_header_rec.segment1,
                     pi_po_number          => pi_po_number,
                     pi_aops_number        => pi_aops_number,
                     po_mail_subject       => lc_int_mail_subject,
                     po_mail_body_hdr      => lc_int_body_hdr,
                     po_mail_body_trl      => lc_int_body_trl,
                     pi_translation_info   => pi_translation_info);
					 
    log_msg(TRUE, 'Getting the Requestor Info, Requestor Name, Requestor Email ');
	lc_status := get_requestor_info (pi_preparer_id     => pi_req_header_rec.preparer_id ,
                                     xx_requestor_info  => l_req_info,
                                     xx_error_message   => lc_error_message);

    IF lc_error_message IS NOT NULL
    THEN
      RAISE e_mail_error;
    END IF;			

    FOR i in pi_req_line_detail_tab.first..pi_req_line_detail_tab.last
    LOOP
      BEGIN
        lr_lines_rec := pi_req_line_detail_tab(i);
		
        lc_req_mail_body := lc_req_mail_body||get_mail_body (pi_translation_info.target_value21,
                                                             pi_req_header_rec.segment1,
                                                             l_req_info.first_name||' '||l_req_info.last_name,  -- requestor Name
                                                             lr_lines_rec.line_num,
                                                             lr_lines_rec.suggested_vendor_product_code,
                                                             lr_lines_rec.item_description,
                                                             lr_lines_rec.quantity,
                                                             get_location_name(lr_lines_rec.deliver_to_location_id),
                                                             NULL,
                                                             NULL);

        lc_int_mail_body := lc_int_mail_body||get_mail_body (pi_translation_info.target_value20,
                                                             pi_req_header_rec.segment1,
                                                             l_req_info.first_name||' '||l_req_info.last_name,  -- requestor Name
                                                             lr_lines_rec.line_num,
                                                             lr_lines_rec.suggested_vendor_product_code,
                                                             lr_lines_rec.item_description,
                                                             lr_lines_rec.quantity,
                                                             get_location_name(lr_lines_rec.deliver_to_location_id),
                                                             pi_error_message,
                                                             NULL);
      END;
    END LOOP;
	
    log_msg(TRUE, 'Sending the Mail to Requestor..');
    send_mail(pi_mail_subject         =>  lc_req_mail_subject,
              pi_mail_body          =>  lc_req_body_hdr||lc_req_mail_body||lc_req_body_trl,
              pi_mail_sender        =>  pi_translation_info.target_value3,
              pi_mail_recipient     =>  l_req_info.email_address,  --pi_translation_info.target_value17,   
			                                                       -- Change to sent the mail to requestor
              pi_mail_cc_recipient  =>  NULL,--pi_translation_info.target_value18,
              po_return_msg         =>  lc_error_message);
	  
    log_msg(TRUE, 'Sending the Mail to Internal Team/AMS..');		   
    send_mail(pi_mail_subject       =>  lc_int_mail_subject,
              pi_mail_body          =>  lc_int_body_hdr||lc_int_mail_body||lc_int_body_trl,
              pi_mail_sender        =>  pi_translation_info.target_value3,
              pi_mail_recipient     =>  pi_translation_info.target_value4,
              pi_mail_cc_recipient  =>  pi_translation_info.target_value5,
              po_return_msg         =>  lc_error_message);
  EXCEPTION WHEN OTHERS THEN
    IF lc_error_message IS NULL THEN
	  lc_error_message := substr(SQLERRM,2000);
    END IF;
    log_msg(TRUE, 'Error While Mailing the Errors Information to Internal Team/Requestor '||lc_error_message);
  END;

-- +===============================================================================================+
-- | Name  : process_pending_confirmations                                                         |
-- | Description     : This is the main process it process all the pending confirmations           |
-- |                   and update the PO , PO line status and finally sends an email to            |
-- |                   business with all all the details.                                          |
-- |                   This will be triggered from Concurrent Program and will run for every       |
-- |                   30 minutes as scheduled in ESP.                                             |
-- | Parameters      :                                                                             |
-- +================================================================================================+

      
  PROCEDURE process_pending_confirmations(errbuf     OUT VARCHAR2,
                                          retcode    OUT VARCHAR2,
                                          pi_status IN xx_po_punch_header_info.record_status%TYPE)
  IS
    CURSOR cur_header( pi_status xx_po_punch_header_info.record_status%TYPE)
    IS 
    SELECT *
    FROM xx_po_punch_header_info
    WHERE record_status = NVL(pi_status, record_status)
    AND record_status != 'PROCESSED';

    CURSOR cur_lines(pi_record_id xx_po_punch_lines_info.record_id%TYPE,
                     pi_po_number xx_po_punch_lines_info.po_number%TYPE)
    IS 
    SELECT *
    FROM xx_po_punch_lines_info
    WHERE record_id = pi_record_id
    AND PO_number = pi_po_number
    AND line_status = 'reject';

    CURSOR cur_po_lines(pi_po_number xx_po_punch_lines_info.po_number%TYPE)
    IS 
    SELECT pol.line_num,
           pol.vendor_product_num item_number,
           pol.item_description,
           pol.quantity,
           hl.location_code
    FROM po_lines_all pol,
         po_headers_all poh,
         po_line_locations_all pll,
         hr_locations_all hl
    WHERE pol.po_header_id = poh.po_header_id
    AND pol.po_line_id = pll.po_line_id
    AND pll.ship_to_location_id = hl.location_id
    AND poh.segment1 = pi_po_number
    AND poh.org_id = fnd_global.org_id;
	
    lc_translation_info    xx_fin_translatevalues%ROWTYPE;
    lc_trans_name          xx_fin_translatedefinition.translation_name%TYPE := 'XXPO_PUNCHOUT_CONFIG';
    lc_error_message       VARCHAR2(2000) := NULL;
    lc_return_status       VARCHAR2(2000) := NULL;
    lc_mail_body           VARCHAR2(32000) := NULL;
    lc_body_hdr            VARCHAR2(32000) := NULL;
    lc_body_trl            VARCHAR2(32000) := NULL;
    lc_mail_subject        VARCHAR2 (4000) := NULL;

    e_process_exception      EXCEPTION;
	e_hdr_process_exception  EXCEPTION;

    lc_item_num            po_lines_all.vendor_product_num%TYPE;
    lc_item_description    po_lines_all.item_description%TYPE;
    ln_requested_qty       po_lines_all.quantity%TYPE;
    ln_confirmed_qty       po_lines_all.quantity%TYPE;
    lc_dest_location       hr_locations.location_code%TYPE;
    lc_send_mail           VARCHAR2(1);
    
    ln_requisition_header_id  po_requisition_headers_all.requisition_header_id%TYPE;
    ln_requisition_line_id    po_requisition_lines_all.requisition_line_id%TYPE;
    ln_pr_num                 po_requisition_headers_all.segment1%TYPE;
    ln_pr_line_num            po_requisition_lines_all.line_num%TYPE;
    ln_po_header_id           po_headers_all.po_header_id%TYPE;
	
    --lr_req_hdr_rec             po_requisition_headers_all%ROWTYPE;
    lr_req_line_rec            po_requisition_lines_all%ROWTYPE;
    indx                       NUMBER; 
    lr_po_req_hdr_rec          xx_po_create_punchout_req_pkg.xx_po_req_hdr_rec%TYPE;
    lt_po_req_line_tbl         xx_po_create_punchout_req_pkg.xx_po_req_line_tbl%TYPE;
    lc_submit_req_import       VARCHAR2(1) := 'N';
    ln_batch_id                NUMBER := NULL;
    lc_translation_rec         xx_fin_translatevalues%ROWTYPE;
    lc_supplier_duns           po_requisition_lines_all.supplier_duns%TYPE;
	l_req_info                 per_people_v7%ROWTYPE;
    lc_cancel_fail             VARCHAR2(1);

    BEGIN 
      log_msg(TRUE, 'pi_Status: ' || pi_status);
      log_msg(TRUE, 'calling Process confirmation details ..');

      log_msg(lc_debug_flag, 'Getting the Translation Values for Config Details..');
      
      lc_return_status := get_translation_info( pi_translation_name => lc_trans_name,
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

      --process_confirmation_details;
      process_confirm_details(pi_status   => pi_status,
                              p_return_status => lc_return_status,
                              p_error_msg => lc_error_message);

      IF lc_error_message IS NOT NULL
      THEN
        log_msg(lc_debug_flag, 'Error While Processing Confirm Details Data ..'||lc_error_message);
        RAISE e_process_exception ;
      END IF;
      COMMIT; -- Commit the Confirmation Details.

      -- Setting the Org Context ..
      log_msg(lc_debug_flag, 'Setting the Org Context');
      
      set_context(pi_translation_info => lc_translation_info,
                  po_error_msg        => lc_error_message);

      IF lc_error_message IS NOT NULL
      THEN
        RAISE e_process_exception ;
      END IF;

      log_msg(lc_debug_flag, 'Processing the PO Punch Out Records Data ..');
      FOR cur_header_rec IN cur_header (pi_status)
      LOOP
        BEGIN 
          
          ln_batch_id      := fnd_global.session_id;
          lc_error_message := NULL;
          lc_mail_body     := NULL;
          lc_send_mail     := 'N';
          ln_po_header_id          := NULL;
          ln_requisition_header_id := NULL;
          ln_pr_num                := NULL;
          indx                     := 1;
          lc_translation_rec       := NULL; 
          lr_po_req_hdr_rec        := NULL;
          lt_po_req_line_tbl.DELETE;
		  lc_cancel_fail           := 'N';
		  
          -- Update the PO header with Internal Order Number 
          Update_PO_header(pi_po_number       => cur_header_rec.po_number,
                           pi_internal_order  => cur_header_rec.order_num,
                           po_error_msg       => lc_error_message);
         
          IF lc_error_message IS NOT NULL
          THEN
            RAISE e_process_exception ;
          END IF;
          
          log_msg(lc_debug_flag, 'Processing the Data for PO: '||cur_header_rec.po_number);
		  
          -- Get the Requisition Header Record 
          lc_return_status := get_req_hdr_record(pi_po_number    => cur_header_rec.po_number,
                                                 po_req_hdr_rec  => lr_po_req_hdr_rec,
                                                 po_error_msg    => lc_error_message);
										 
          IF lc_error_message IS NOT NULL
          THEN
            RAISE e_process_exception; 
          END IF;
		  
          IF cur_header_rec.po_status = 'reject' THEN   -- Cancel All the PO Lines
            BEGIN
              
			  log_msg(lc_debug_flag, 'Getting PO Header Id');
              SELECT po_header_id
              INTO ln_po_header_id
              FROM po_headers_all
              WHERE segment1 = cur_header_rec.po_number;
              log_msg(lc_debug_flag, 'PO Header Id is: '||ln_po_header_id);

              log_msg(lc_debug_flag, 'Getting Requisition Number and Header Id');
              --Getting the PO Requistion details to cancel the Requisition Line
              SELECT DISTINCT requisition_header_id,
                     SEGMENT1
              INTO ln_requisition_header_id,
                   ln_pr_num
              FROM po_distributions_v
              WHERE po_header_id = ln_po_header_id
              AND requisition_header_id IS NOT NULL;
              log_msg(lc_debug_flag, 'Requisition Header Id is: '||ln_requisition_header_id||' , Requisition Number is: '||ln_pr_num);
			  
              FOR req_lines IN (SELECT * FROM po_requisition_lines_all WHERE requisition_header_id = ln_requisition_header_id)
              LOOP
                lt_po_req_line_tbl(indx) := req_lines;
                indx := indx+1;
              END LOOP;
			  
              SELECT distinct supplier_duns
              INTO lc_supplier_duns
              FROM po_requisition_lines_all
              WHERE requisition_header_id = ln_requisition_header_id;
			  
              log_msg(lc_debug_flag, 'Getting Translations for the Supplier Duns '||lc_supplier_duns);
              lc_return_status := get_translation_info( pi_translation_name => lc_trans_name,
                                                        pi_source_record    => 'SUPPLIER_DUNS',
                                                        pi_target_record    => lc_supplier_duns,
                                                        po_translation_info => lc_translation_rec,
                                                        po_error_msg        => lc_error_message);

              FOR cur_po_lines_rec IN cur_po_lines (cur_header_rec.po_number)
              LOOP
                lc_mail_body := lc_mail_body||get_mail_body (lc_translation_rec.target_value19,
                                                             NULL,
                                                             NULL,
                                                             cur_po_lines_rec.line_num,
                                                             cur_po_lines_rec.item_number,
                                                             cur_po_lines_rec.item_description,
                                                             cur_po_lines_rec.quantity,
                                                             cur_po_lines_rec.location_code,
                                                             NULL,
                                                             0);
              END LOOP;
		  
              log_msg(lc_debug_flag, 'Cancelling the PO : '||cur_header_rec.po_number||' Header ');
              cancel_po_line(pi_po_number       => cur_header_rec.po_number,
                             pi_po_line_num     => NULL,
                             po_return_status   => lc_return_status,
                             po_error_msg       => lc_error_message);

              IF lc_error_message IS NOT NULL
              THEN
                lc_cancel_fail := 'Y';			  
                RAISE e_hdr_process_exception; 
              END IF;

              log_msg(lc_debug_flag, 'Cancelling the PO Requsition Lines: '||ln_pr_num);
              cancel_req_line(pi_pr_header_id       => ln_requisition_header_id,
                              pi_pr_line_id         => NULL,
                              po_return_status      => lc_return_status,
                              po_error_msg          => lc_error_message);

              IF lc_error_message IS NOT NULL
              THEN
                lc_cancel_fail := 'Y';			  
                RAISE e_hdr_process_exception; 
              END IF;
              log_msg(lc_debug_flag, 'Updating Header Record Status with PROCESSED, PO: '||cur_header_rec.po_number);
              update_header_rec_status(pi_po_number       => cur_header_rec.po_number,
                                       pi_record_id       => cur_header_rec.record_id,
                                       pi_rec_status      => 'PROCESSED',
                                       pio_error_msg      => lc_error_message);
              lc_send_mail := 'Y';
            EXCEPTION WHEN e_hdr_process_exception THEN
              log_msg(TRUE, lc_error_message);
              log_msg(lc_debug_flag, 'Updating Header Record Status with ERROR, PO: '||cur_header_rec.po_number);
              update_header_rec_status(pi_po_number       => cur_header_rec.po_number,
                                       pi_record_id       => cur_header_rec.record_id,
                                       pi_rec_status      => 'ERROR',
                                       pio_error_msg      => lc_error_message);
			  RAISE e_process_exception;
            WHEN OTHERS THEN
              IF lc_error_message IS NULL 
              THEN
                lc_error_message := 'Error while Getting PO Requisition Details for: '|| cur_header_rec.po_number ||' '||SUBSTR(sqlerrm,1,200);
              END IF;
              log_msg(TRUE, lc_error_message);
              RAISE e_process_exception;
            END;       
          END IF;

          FOR cur_lines_rec IN cur_lines(pi_record_id => cur_header_rec.record_id, pi_po_number => cur_header_rec.po_number)
          LOOP
            BEGIN
              lc_item_num        := NULL;
              lc_item_description:= NULL;
              ln_requested_qty   := NULL;
              lc_dest_location   := NULL;
              lc_error_message   := NULL;
              lr_req_line_rec    := NULL;
              ln_confirmed_qty   := NULL;

              -- Get Line details ..
              log_msg(lc_debug_flag, 'Getting the Line Details for the PO: '||cur_header_rec.po_number||' Line: '||cur_lines_rec.po_line_num);
              get_line_details(pi_po_number      => cur_header_rec.po_number,
                               pi_po_line_num    => cur_lines_rec.po_line_num,
                               po_item_num       => lc_item_num,
                               po_item_description => lc_item_description,
                               po_requested_qty  => ln_requested_qty,
                               po_dest_location  => lc_dest_location,
                               po_error_msg      => lc_error_message);

              IF lc_error_message IS NOT NULL
              THEN
                RAISE e_process_exception ;
              END IF;
			  
              ln_confirmed_qty := cur_lines_rec.confirmed_qty;
			  
              lc_return_status := get_req_line_record(pi_po_number    => cur_header_rec.po_number,
                                                      pi_po_line_num  => cur_lines_rec.po_line_num,
                                                      po_req_line_rec => lr_req_line_rec,
                                                      po_error_msg    => lc_error_message);

			  
              IF ln_requested_qty = ln_confirmed_qty
              THEN 
                -- Get the Requisition Line Record 
              /*  lc_return_status := get_req_line_record(pi_po_number    => cur_header_rec.po_number,
                                                        pi_po_line_num  => cur_lines_rec.po_line_num,
                                                        po_req_line_rec => lr_req_line_rec,
                                                        po_error_msg    => lc_error_message);
				*/		
                lt_po_req_line_tbl(indx) := lr_req_line_rec;
                indx := indx+1;
										 
                IF lc_error_message IS NOT NULL
                THEN 
                  RAISE e_process_exception; 
                END IF;

                -- Call the API to cancel the PO and Requisition lines .
                log_msg(lc_debug_flag, 'Cancelling PO Lines and Requsition Lines for the PO: '||cur_header_rec.po_number||' ,Line: '||cur_lines_rec.po_line_num);
                cancel_po_req_lines(pi_po_number      => cur_header_rec.po_number,
                                    pi_po_line_num    => cur_lines_rec.po_line_num,
                                    po_return_status  => lc_return_status,
                                    po_error_msg      => lc_error_message);
                       
                IF lc_error_message IS NOT NULL
                THEN
                  lc_cancel_fail := 'Y';				
                  RAISE e_process_exception; 
                END IF;
			    
                -- PO Line is Cancelled. So the Confirmed quantity setting to zero for email notification
                ln_confirmed_qty := 0;

             ELSIF ln_requested_qty != ln_confirmed_qty
             THEN
               -- Update the PO Line qty
               log_msg(lc_debug_flag, 'Updating the PO: '||cur_header_rec.po_number||' Line: '||cur_lines_rec.po_line_num||' with Quantity: '||ln_confirmed_qty);
               Update_po_line( pi_po_number       => cur_header_rec.po_number,
                               pi_po_line_num     => cur_lines_rec.po_line_num,
                               pi_confirmed_qty   => ln_confirmed_qty,
                               pi_new_price       => NULL,
                               po_return_status   => lc_return_status,
                               po_error_msg       => lc_error_message);

               IF lc_error_message IS NOT NULL
               THEN 
                 RAISE e_process_exception; 
               END IF;
               
               --Partial Quantity Confirmation, We need to create new requisition for remaining quantity.
               lr_req_line_rec.quantity := ln_requested_qty - ln_confirmed_qty;
               lt_po_req_line_tbl(indx) := lr_req_line_rec;
               indx := indx+1;
             END IF;

             --fnd_file.put_line(fnd_file.log,'Preparing Mail Body '||cur_lines_rec.po_line_num||' - '||lc_item_num||' - '||ln_requested_qty||' - '||lc_dest_location||' - '||ln_confirmed_qty);
             --fnd_file.Put_line(fnd_file.log,'Supplier Duns Number is '||lr_req_line_rec.supplier_duns);
			 log_msg(lc_debug_flag, 'Supplier Duns Number is '||lr_req_line_rec.supplier_duns);
             
             lc_return_status := get_translation_info( pi_translation_name => lc_trans_name,
                                                       pi_source_record    => 'SUPPLIER_DUNS',
                                                       pi_target_record    => lr_req_line_rec.supplier_duns,
                                                       po_translation_info => lc_translation_rec,
                                                       po_error_msg        => lc_error_message);
      
              IF lc_error_message IS NOT NULL
              THEN
                RAISE e_process_exception ;
              END IF;
			 
              lc_mail_body := lc_mail_body||get_mail_body (lc_translation_rec.target_value19,
                                                           NULL,
                                                           NULL,
                                                           cur_lines_rec.po_line_num,
                                                           lc_item_num,
                                                           lc_item_description,
                                                           ln_requested_qty,
                                                           lc_dest_location,
                                                           NULL,
                                                           ln_confirmed_qty);
              
             log_msg(lc_debug_flag, 'Updating Line Record Status, PO :'||cur_header_rec.po_number||' ,Line :'||cur_lines_rec.po_line_num||' ,Record Id: '||cur_lines_rec.record_id);
             update_line_rec_status(pi_po_number       => cur_header_rec.po_number,
                                     pi_po_line_num     => cur_lines_rec.po_line_num,
                                     pi_record_id       => cur_lines_rec.record_id,
                                     pi_rec_status      => 'PROCESSED',
                                     pio_error_msg      => lc_error_message);
             IF lc_error_message IS NOT NULL
             THEN
               RAISE e_process_exception ;
             END IF;
             lc_send_mail := 'Y';
            EXCEPTION 
              WHEN OTHERS
              THEN
                ROLLBACK;
                log_msg(lc_debug_flag, 'Exception While processing the Line Record of PO: '||cur_header_rec.po_number||' Line: '||cur_lines_rec.po_line_num||' : '||' Record Id : '||cur_lines_rec.record_id||' '||lc_error_message);
                log_error(null,lc_error_message);
                update_line_rec_status( pi_po_number       => cur_header_rec.po_number,
                                        pi_po_line_num     => cur_lines_rec.po_line_num,
                                        pi_record_id       => cur_lines_rec.record_id,
                                        pi_rec_status      => 'ERROR',
                                        pio_error_msg      => lc_error_message);
            END;
            COMMIT;  -- Commiting the Line Changes
          END LOOP;  -- Lines
 
          IF lc_error_message IS NULL THEN
            log_msg(lc_debug_flag, 'Updating Header Record Status, PO: '||cur_header_rec.po_number);
            update_header_rec_status(pi_po_number       => cur_header_rec.po_number,
                                     pi_record_id       => cur_header_rec.record_id,
                                     pi_rec_status      => 'PROCESSED',
                                     pio_error_msg      => lc_error_message);
          ELSE
            log_msg(lc_debug_flag, 'Updating Header Record Status, PO: '||cur_header_rec.po_number);
            update_header_rec_status(pi_po_number       => cur_header_rec.po_number,
                                     pi_record_id       => cur_header_rec.record_id,
                                     pi_rec_status      => 'ERROR',
                                     pio_error_msg      => lc_error_message);

          END IF;

          IF nvl(lc_translation_rec.target_value8,'N') = 'Y' THEN 
            IF lc_send_mail = 'Y' AND lc_error_message IS NULL THEN
              log_msg(lc_debug_flag, 'Sending the Mail with Cancellation Details..');
			    lc_mail_subject := NULL;
                lc_body_hdr     := NULL;
                lc_body_trl     := NULL;
                -- Getting Mail Body Header
                get_mailing_info(pi_template           => lc_translation_rec.target_value19,
                                 pi_requisition_number => lr_po_req_hdr_rec.segment1,
                                 pi_po_number          => cur_header_rec.po_number,
                                 pi_aops_number        => cur_header_rec.order_num,
                                 po_mail_subject       => lc_mail_subject,
                                 po_mail_body_hdr      => lc_body_hdr,
                                 po_mail_body_trl      => lc_body_trl,
                                 pi_translation_info   => lc_translation_rec);
				
                IF NVL(lc_translation_rec.target_value17,'N') = 'Y' THEN   -- Send Mail to Requestor Flag
                  log_msg(TRUE, 'Getting the Requestor Info, Requestor Name, Requestor Email ');
                  l_req_info := NULL;
	              lc_return_status := xx_po_punchout_conf_pkg.get_requestor_info (pi_preparer_id     => lr_po_req_hdr_rec.preparer_id ,
                                                                           xx_requestor_info  => l_req_info,
                                                                           xx_error_message   => lc_error_message);

                  IF lc_error_message IS NOT NULL
                  THEN
                    RAISE e_process_exception;
                  END IF;
                  IF l_req_info.email_address IS NOT NULL 
                  THEN
                    send_mail(pi_mail_subject       =>  lc_mail_subject,
                              pi_mail_body          =>  lc_body_hdr||lc_mail_body||lc_body_trl,
                              pi_mail_sender        =>  lc_translation_rec.target_value3,
                              pi_mail_recipient     =>  l_req_info.email_address,
                              pi_mail_cc_recipient  =>  NULL,
                              po_return_msg         =>  lc_error_message);
                    IF lc_error_message IS NOT NULL
                    THEN
                      RAISE e_process_exception ;
                    END IF;
                  END IF;
				ELSIF lc_translation_rec.target_value4 IS NOT NULL 
                THEN				
			      send_mail(pi_mail_subject       =>  lc_mail_subject,
                            pi_mail_body          =>  lc_body_hdr||lc_mail_body||lc_body_trl,
                            pi_mail_sender        =>  lc_translation_rec.target_value3,
                            pi_mail_recipient     =>  lc_translation_rec.target_value4,
                            pi_mail_cc_recipient  =>  lc_translation_rec.target_value5,
                            po_return_msg         =>  lc_error_message);
                  IF lc_error_message IS NOT NULL
                  THEN
                    RAISE e_process_exception ;
                  END IF;
				END IF;
             END IF;
           END IF;
         EXCEPTION WHEN OTHERS 
         THEN 
           ROLLBACK;
           --log_msg(TRUE, lc_error_message);
           log_error(null,lc_error_message);
           update_header_rec_status(pi_po_number       => cur_header_rec.po_number,
                                    pi_record_id       => cur_header_rec.record_id,
                                    pi_rec_status      => 'ERROR',
                                    pio_error_msg      => lc_error_message);		  
       END;
       COMMIT;  -- Commiting the Changes
       log_msg(TRUE, 'Commiting the Changes');

       -- Calling Create Requisition. Not creating requisition if the cancellation of po/requisition fails
       IF NVL(lc_translation_rec.target_value13,'N') = 'Y' AND NVL(lc_cancel_fail,'N') = 'N'  
       THEN
           log_msg(lc_debug_flag, 'Calling Create Purchase Requisition Procedure ');
           xx_po_create_punchout_req_pkg.create_purchase_requisition( 
                                po_req_return_status      => lc_return_status,
                                po_req_return_message     => lc_error_message,
                                po_submit_req_import      => lc_submit_req_import,
                                pi_debug_flag             => lc_debug_flag,
                                pi_batch_id               => ln_batch_id,
                                pi_req_header_rec         => lr_po_req_hdr_rec,
                                pi_req_line_detail_tab    => lt_po_req_line_tbl,
                                pi_translation_info       => lc_translation_rec);

           IF lc_error_message IS NOT NULL
           THEN
             log_msg(lc_debug_flag, 'Error While Creating Purchase Requisition: '||lc_error_message);
               mail_error_info( pi_translation_info       => lc_translation_rec,
                                pi_req_header_rec         => lr_po_req_hdr_rec,
                                pi_req_line_detail_tab    => lt_po_req_line_tbl,
                                pi_po_number              => cur_header_rec.po_number,
                                pi_aops_number            => cur_header_rec.order_num,
                                pi_error_message          => lc_error_message
                               );
             --RAISE e_process_exception ;
           END IF;

       END IF;
	   -- End Calling the Create Requistion
      END LOOP; -- Header 
	  
      -- Calling the Requisition Import
      IF NVL(lc_submit_req_import,'N') = 'Y'
      THEN
        log_msg(TRUE, 'Submitting PO import process for Batch id '|| ln_batch_id );
        submit_req_import(p_batch_id         =>  ln_batch_id,
                          p_debug_flag       =>  lc_debug_flag,
                          x_error_message    =>  lc_error_message,
                          x_return_status    =>  lc_return_status);
        IF NVL(lc_return_status,'S') != 'S'
        THEN
          RAISE e_process_exception;
        END IF;
      END IF;
	  
    EXCEPTION WHEN e_process_exception THEN
      ROLLBACK;
      log_msg(TRUE, 'Exception, Executed Rollback');
      log_msg(TRUE, nvl(lc_error_message,substr(sqlerrm,1,2000)));
      log_error(null,nvl(lc_error_message,substr(sqlerrm,1,2000)));
      --retcode := 1;
    WHEN OTHERS THEN
      ROLLBACK;
      log_msg(TRUE, 'Exception, Executed Rollback');
      log_msg(TRUE, 'Commting the Changes');
      log_msg(TRUE, nvl(lc_error_message,substr(sqlerrm,1,2000)));
      log_error(null,nvl(lc_error_message,substr(sqlerrm,1,2000)));
      --retcode := 1;
    END process_pending_confirmations;

  -- +=======================================================================================================+
  -- | Name  : purge_punchout_data                                                                           |
  -- | Description     : This Procedure will purge the Punchout tables history data                          |
  -- | Parameters      : po_errbuff,  po_retcode,  pi_no_of_days                                             |
  -- +=======================================================================================================+

  PROCEDURE purge_punchout_data(
    po_errbuff     OUT  VARCHAR2,
    po_retcode     OUT  NUMBER,
    pi_no_of_days  IN   NUMBER
    )
  IS
    CURSOR c_po_punchout_confirm_data
    IS
    SELECT record_id
    FROM XX_PO_PUNCHOUT_CONFIRMATION
    WHERE creation_date < trunc(sysdate) - pi_no_of_days
    AND record_status = 'PROCESSED';
	
	CURSOR c_po_punchout_lines_info(p_record_id IN NUMBER)
	IS
	SELECT po_number, po_line_num
	FROM XX_PO_PUNCH_LINES_INFO
	WHERE record_id = p_record_id;
	
	CURSOR c_po_punchout_ship_info
    IS
	SELECT substr(po_number,1,instr(po_number,':',1)-1) po_number, po_line_Num 
	FROM XX_PO_SHIPMENT_DETAILS
    WHERE creation_date < trunc(sysdate) - pi_no_of_days
    AND record_status = 'PROCESSED';
     
    ln_punchout_confirm_count    NUMBER := 0;
    ln_punchout_hdr_info_count   NUMBER := 0;
    ln_punchout_lines_info_count NUMBER := 0;
    ln_punchout_shipment_rec_count NUMBER := 0;
  BEGIN
    log_msg(TRUE, 'Deleting the PO Punchout records data.');
    
    FOR i IN c_po_punchout_confirm_data
    LOOP
	  -- Added to write the PO datails in concurrent log.
      BEGIN
	    FOR po_data IN c_po_punchout_lines_info(i.record_id)
		LOOP
		  log_msg(TRUE, 'Purging the Confirmation PO: '||po_data.po_number||' Line: '||po_data.po_line_num);
		END LOOP;
	  END;
	  
      BEGIN
        DELETE FROM XX_PO_PUNCH_LINES_INFO
        WHERE record_id = i.record_id;

        ln_punchout_lines_info_count := ln_punchout_lines_info_count + SQL%ROWCOUNT;

		DELETE FROM XX_PO_PUNCH_HEADER_INFO
        WHERE record_id = i.record_id;

        ln_punchout_hdr_info_count := ln_punchout_hdr_info_count + SQL%ROWCOUNT;

        DELETE FROM XX_PO_PUNCHOUT_CONFIRMATION
        WHERE record_id = i.record_id;

        ln_punchout_confirm_count := ln_punchout_confirm_count + SQL%ROWCOUNT;

      EXCEPTION WHEN OTHERS THEN
        rollback;
        log_msg(TRUE, 'Exception when deleting the data for the Record Id :'||i.record_id||' Error: '||sqlerrm);
      END;

    END LOOP;
	
      log_msg(TRUE, 'Total PO Punchout Confirmation Records deleted : '||ln_punchout_confirm_count);
      log_msg(TRUE, 'Total PO Punchout Header Info Records deleted : '||ln_punchout_hdr_info_count);
      log_msg(TRUE, 'Total PO Punchout Lines Info Records deleted : '||ln_punchout_lines_info_count);
	
      -- Added to write the PO datails in concurrent log.
      BEGIN
	    FOR shipment_data IN c_po_punchout_ship_info
	    LOOP
		  log_msg(TRUE, 'Deleting the Punchout Shipment Data for PO: '||shipment_data.po_number||' Line: '||shipment_data.po_line_num);
	    END LOOP;
	  END;
	  
      DELETE FROM XX_PO_SHIPMENT_DETAILS
      WHERE creation_date < trunc(sysdate) - pi_no_of_days
      AND record_status = 'PROCESSED';

      ln_punchout_shipment_rec_count := SQL%ROWCOUNT;
	
      log_msg(TRUE, 'Total PO Punchout Shipment Records deleted : '||ln_punchout_shipment_rec_count);
	
    COMMIT;

  EXCEPTION
  WHEN OTHERS THEN
    log_msg(TRUE, 'Purging the PO Punchout Data Failed with Error :   '||sqlerrm);
    rollback;
    po_retcode := 1;
  end PURGE_PUNCHOUT_DATA;
  
  -- +========================================================================================+
  -- | Name  : get_legacy_cc                                                                  |
  -- | Description     : This Procedure used to get the Legacy Cost Center Number             |
  -- | Parameters      : pi_distribution_id, po_cost_center                                   |
  -- +========================================================================================+
  PROCEDURE get_legacy_cc( pi_po_number       IN  po_headers_all.segment1%TYPE,
                           po_cost_center     OUT gl_code_combinations.segment2%TYPE)
  AS
    ln_po_header_id        po_headers_all.po_header_id%TYPE;
    ln_po_distribution_id  po_distributions_all.po_distribution_id%TYPE;
  BEGIN
    log_error('PUNCHOUT','PO Number is :'|| pi_po_number);
	
    SELECT po_header_id
    INTO ln_po_header_id
    FROM po_headers_all
    WHERE segment1 = pi_po_number;
	log_error('PUNCHOUT','PO Header Id is :'|| ln_po_header_id);
	
    SELECT po_distribution_id
    INTO ln_po_distribution_id
    FROM po_distributions_all
    WHERE po_header_id = ln_po_header_id
    AND rownum = 1;
	log_error('PUNCHOUT','PO Distribution Id is :'|| ln_po_distribution_id);
	
	SELECT xftv.target_value1
    INTO po_cost_center
    FROM xx_fin_translatedefinition xft,
         xx_fin_translatevalues xftv,
         gl_code_combinations gcc,
         po_distributions_all pda
    WHERE xft.translate_id    = xftv.translate_id
    AND xft.enabled_flag      = 'Y'
    AND xftv.enabled_flag     = 'Y'
    AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
    AND xft.translation_name  = 'BFO_COST_CENTER_MAPPING'
    AND xftv.source_value1    = gcc.segment4
    AND xftv.source_value2    = gcc.segment2
    AND gcc.code_combination_id = pda.code_combination_id
	AND pda.po_distribution_id = ln_po_distribution_id;
	log_error('PUNCHOUT','Cost Center (Target Value1) Value is :'|| po_cost_center);
	
  EXCEPTION 
  WHEN OTHERS 
  THEN
    log_error('PUNCHOUT','In the Exception :'|| SQLERRM);  
    po_cost_center := fnd_profile.value('OD_PO_BFS_DEFAULT_CC');
    log_error('PUNCHOUT','Profile OD PO Default Cost Center for BFS is: '|| po_cost_center);
    IF po_cost_center IS NULL 
    THEN
      log_error('PUNCHOUT','Cost Center Value Defaulting to 0000000');
      po_cost_center:= '000000';
    END IF;
  END;
  
end XX_PO_PUNCHOUT_CONF_PKG;
/