SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_PO_PUNCHOUT_CONF_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_PO_PUNCHOUT_CONF_PKG AS
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
  -- | 2.0         06-NOV-2017  Suresh Naragam    Changes for Buy From Ourselves                  |
  -- |                                            Phase 2 jan/san                                 |
  -- +============================================================================================+
  /* $Header: XX_PO_PUNCHOUT_CONF_PKG.pls $ */
  /*#
   * This custom PL/SQL package can be used to stage data from punchout to Oracle using Web Services.  
   * @rep:scope public
   * @rep:product PO
   * @rep:displayname ODPOPUNCHOUTCONF
   * @rep:category BUSINESS_ENTITY po_punchout_interface
   */
  PROCEDURE LOAD_ORDER_CONFIRMATON(
        CONF_PAYLOAD     IN  VARCHAR2,
        OUT              OUT VARCHAR2)
  /*# 
   * Use this procedure to insert data into Custom PO staging table. 
   * @param CONF_PAYLOAD  Confirmation Payload 
   * @param OUT Contains Payloadvalue
   * @rep:displayname LOAD_ORDER_CONFERMATION
   * @rep:category BUSINESS_ENTITY po_punchout_interface
   * @rep:scope public 
   * @rep:lifecycle active 
   */;

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
                                          pi_status  IN xx_po_punch_header_info.record_status%TYPE);
                                          
  -- +===============================================================================================+
  -- | Name  : purge_punchout_data                                                                   |
  -- | Description     : This procedure used to purge the Punchout Data based on parameter           |
  -- |                   no_of_days, it will keep the no_of_days data and purge the old data.        |
  -- |                   This will be triggered from Concurrent Program and will be scheduled in ESP |
  -- |    p_status                  IN -- Status of Punchout data                                    |
  -- |    p_no_of_days              IN -- number days                                                |
  -- +================================================================================================+
  PROCEDURE purge_punchout_data( po_errbuff     OUT  VARCHAR2,
                                 po_retcode     OUT  NUMBER,
                                 pi_no_of_days  IN   NUMBER);

  -- +===============================================================================================+
  -- | Name  : log_msg                                                                               |
  -- | Description     : This procedure used to log the messages in concurrent program log           |
  -- |    pi_log_flag            IN -- Debug Flag                                                    |
  -- |    pi_string              IN -- Message as String                                             |
  -- +================================================================================================+
  PROCEDURE log_msg( pi_log_flag IN BOOLEAN DEFAULT FALSE,
                     pi_string   IN VARCHAR2);
                     

  -- +===============================================================================================+
  -- | Name  : get_translation_info                                                                  |
  -- | Description     : This Function used to get the translation values                            |
  -- |    pi_translation_name            IN  -- Translation Name                                     |
  -- |    pi_source_record               IN  -- Source Value1 of translation value                   |
  -- |    po_translation_info            OUT -- Translation values                                   |
  -- |    po_error_msg                   OUT -- Error Message                                        |
  -- +================================================================================================+
  FUNCTION get_translation_info( pi_translation_name   IN  xx_fin_translatedefinition.translation_name%TYPE,
                                 pi_source_record      IN  xx_fin_translatevalues.source_value1%TYPE, 
                                 po_translation_info   OUT xx_fin_translatevalues%ROWTYPE,
                                 po_error_msg          OUT VARCHAR2)
  RETURN VARCHAR2;

  -- +===============================================================================================+
  -- | Name  : get_translation_info                                                                  |
  -- | Description     : This Function used to get the translation values                            |
  -- |    pi_translation_name            IN  -- Translation Name                                     |
  -- |    pi_source_record               IN  -- Source Value1 of translation value                   |
  -- |    pi_target_record               IN  -- Target Value1 of translation value                   |
  -- |    po_translation_info            OUT -- Translation values                                   |
  -- |    po_error_msg                   OUT -- Error Message                                        |
  -- +================================================================================================+
  FUNCTION get_translation_info( pi_translation_name   IN  xx_fin_translatedefinition.translation_name%TYPE,
                                 pi_source_record      IN  xx_fin_translatevalues.source_value1%TYPE, 
                                 pi_target_record      IN  xx_fin_translatevalues.target_value1%TYPE, 
                                 po_translation_info   OUT xx_fin_translatevalues%ROWTYPE,
                                 po_error_msg          OUT VARCHAR2)
  RETURN VARCHAR2;

  -- +===============================================================================================+
  -- | Name  : set_context                                                                           |
  -- | Description     : This procedure used to initialize and set the org_context in pl/sql block   |
  -- |    pi_translation_info            IN  -- user_name, responsiblity values from translations    |
  -- |    po_error_msg                   OUT -- Return Error message                                 |
  -- +================================================================================================+
  PROCEDURE set_context( pi_translation_info   IN xx_fin_translatevalues%ROWTYPE,
                         po_error_msg          OUT VARCHAR2);
                         
  -- +===============================================================================================+
  -- | Name  : send_mail                                                                             |
  -- | Description     : This Procedure used to send mail                                            |
  -- |    pi_translation_rec            IN  -- Translation Values                                    |
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
                      po_return_msg         OUT    VARCHAR2);
                      
  -- +===============================================================================================+
  -- | Name  : cancel_po_line                                                                        |
  -- | Description     : This Procedure used to Cancel the PO Lines                                  |
  -- |    pi_po_number                   IN   -- PO Number                                           |
  -- |    pi_po_line_num                 IN   -- PO Line Number                                      |
  -- |    po_return_status               OUT  -- PO Retrun Status                                    |
  -- |    po_error_msg                   OUT  -- Error Message                                       |
  -- +================================================================================================+
  PROCEDURE cancel_po_line( pi_po_number       IN      po_headers_all.segment1%TYPE,
                            pi_po_line_num     IN      po_lines_all.line_num%TYPE,
                            po_return_status   OUT     VARCHAR2,
                            po_error_msg       OUT     VARCHAR2);
  
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
  PROCEDURE update_po_line( pi_po_number       IN      po_headers_all.segment1%TYPE,
                            pi_po_line_num     IN      po_lines_all.line_num%TYPE,
                            pi_confirmed_qty   IN      po_lines_all.quantity%TYPE,
                            pi_new_price       IN      po_lines_all.unit_price%TYPE,
                            po_return_status   OUT     VARCHAR2,
                            po_error_msg       OUT     VARCHAR2);

  -- +===============================================================================================+
  -- | Name  : log_error                                                                             |
  -- | Description     : This procedure used to write the Error message in Common Error Log Table    |
  -- |    pi_object_id            IN  -- Object Id                                                   |
  -- |    po_error_msg            OUT -- Return Error message                                        |
  -- +================================================================================================+
  PROCEDURE log_error (pi_object_id     IN VARCHAR2,
                       pi_error_msg     IN VARCHAR2);

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
                             po_error_msg        OUT VARCHAR2);

  -- +===============================================================================================+
  -- | Name  : cancel_req_lines                                                                      |
  -- | Description     : This Procedure used to Cancel the Requisition Lines                         |
  -- |    pi_po_number                   IN   -- PO Number                                           |
  -- |    pi_po_line_num                 IN   -- PO Line Number                                      |
  -- |    po_return_status               OUT  -- Return Status                                       |
  -- |    po_error_msg                   OUT  -- Error Message                                       |
  -- +================================================================================================+
  PROCEDURE cancel_po_req_lines(pi_po_number      IN  po_headers_all.segment1%TYPE,
                                pi_po_line_num    IN  po_lines_all.line_num%TYPE,
                                po_return_status  OUT VARCHAR2,
                                po_error_msg      OUT VARCHAR2);
								
-- +=================================================================================================+
-- | Name  : get_req_hdr_record                                                                      |
-- | Description     : This function returns the Requisition Header Record                           |
-- |    pi_po_number                   IN   -- PO Number                                             |
-- |    po_req_hdr_rec                 OUT  -- PO Header Record                                      |
-- |    po_error_msg                   OUT  -- Return Status                                         |
-- +=================================================================================================+

  FUNCTION get_req_hdr_record(pi_po_number     IN  po_headers_all.segment1%TYPE,
                              po_req_hdr_rec   OUT po_requisition_headers_all%ROWTYPE,
                              po_error_msg     OUT VARCHAR2)
  RETURN VARCHAR2;
  
  -- +===============================================================================================+
  -- | Name  : get_req_line_record                                                                   |
  -- | Description     : This function returns the Requisition Line Record                           |
  -- |    pi_po_number                   IN   -- PO Number                                           |
  -- |    pi_po_line_num                 IN   -- PO Line Number                                      |
  -- |    po_req_line_rec                OUT  -- PO Line Record                                      |
  -- |    po_error_msg                   OUT  -- Return Status                                       |
  -- +===============================================================================================+
  FUNCTION get_req_line_record(pi_po_number       IN  po_headers_all.segment1%TYPE,
                               pi_po_line_num     IN  po_lines_all.line_num%TYPE,
                               po_req_line_rec    OUT po_requisition_lines_all%ROWTYPE,
                               po_error_msg       OUT VARCHAR2)
  RETURN VARCHAR2;
 
  -- +================================================================================================+
  -- | Name  : submit_req_import                                                                      |
  -- | Description     : This Procedure used to Submit Requisition Import Program                     |
  -- | Parameters      : p_translation_rec, p_batch_id, p_debug_flag, x_error_message, x_return_status| 
  -- +================================================================================================+
  PROCEDURE submit_req_import ( p_batch_id         IN   NUMBER,
                                p_debug_flag       IN   BOOLEAN,
                                x_error_message    OUT  VARCHAR2,
                                x_return_status    OUT  VARCHAR2);

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
                             pi_translation_info   IN xx_fin_translatevalues%ROWTYPE);
                            
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
  RETURN VARCHAR2;
						  
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
                             pi_error_message        IN  po_interface_errors.error_message%TYPE);
							 
  -- +========================================================================================+
  -- | Name  : get_legacy_cc                                                                  |
  -- | Description     : This Procedure used to get the Legacy Cost Center Number             |
  -- | Parameters      : pi_distributions_id, po_cost_center                                  |
  -- +========================================================================================+
  PROCEDURE get_legacy_cc( pi_po_number       IN  po_headers_all.segment1%TYPE,
                           po_cost_center     OUT gl_code_combinations.segment2%TYPE);
						   
  -- +========================================================================================+
  -- | Name  : get_requestor_info                                                             |
  -- | Description     : Function to return the requestor Info                                |
  -- | Parameters      : pi_preparer_id, xx_requestor_info, xx_error_message                  |
  -- +========================================================================================+
  FUNCTION get_requestor_info (pi_preparer_id          IN  per_people_v7.person_id%TYPE,
                               xx_requestor_info       OUT per_people_v7%ROWTYPE,
                               xx_error_message        OUT VARCHAR2)
  RETURN VARCHAR2;
							
END XX_PO_PUNCHOUT_CONF_PKG; 
/

SHOW ERR
