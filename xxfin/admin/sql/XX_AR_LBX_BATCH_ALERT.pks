create or replace
PACKAGE XX_AR_LBX_BATCH_ALERT
AS

  -- +====================================================================================================================================+
  -- |                                Office Depot - Project Simplify                                                                     |
  -- |                                     Oracle AMS Support                                                                             |
  -- +====================================================================================================================================+
  -- |  Name:  XX_AR_LBX_BATCH_ALERT (RICE ID : E0000)                                                                                    |
  -- |                                                                                                                                    |
  -- |  Description:  This package will be used for automating the lockbox Batch Monitoring Activities                                    |
  -- |    GET_LBX_STATS           This procedure will fetch lockbox details and send email alert to AMS batch team                        |
  -- |    GET_TRANSLATIONS        This procedure will fetch translation values for a given translation name and source                    |
  -- |    GET_LB_FILE_DATA        This procedure will fetch details of lockbox files received and for a given cycle date expected         |
  -- |    GET_RECORD_COUNT        This procedure will fetch record counts for lockbox files of a given date and send the data to business |
  -- |    PREPARE_AND_SEND_EMAIL  This procedure will send html email alerts to appropriate teams                                         |
  -- |                                                                                                                                    |
  -- |  Change Record:                                                                                                                    |
  -- +====================================================================================================================================+
  -- | Version     Date         Author               Remarks                                                                              |
  -- | =========   ===========  =============        =====================================================================================|
  -- | 1.0         17-Apr-2012  Archana N.           Initial version - QC Defect # 20100                                                  |
  -- +====================================================================================================================================+

TYPE t_recipient
IS
  TABLE OF VARCHAR2(240);
  l_to_tbl t_recipient := t_recipient();
  l_cc_tbl t_recipient := t_recipient();
  
  -- +============================================================================+
  -- | Name             : GET_LBX_STATS                                           |
  -- |                                                                            |
  -- | Description      : This procedure will fetch lockbox details and send email|
  -- |                    alert to AMS batch team.                                |
  -- |                                                                            |
  -- | Parameters       : x_err_buf OUT VARCHAR2                                  |
  -- |                  : x_ret_code    OUT  VARCHAR2                             |
  -- |                  : p_cycle_date IN VARCHAR2 --Cycle Date                   |
  -- |                                                                            |
  -- | Change Record:                                                             |
  -- | ==============                                                             |
  -- | Version  Date         Author          Remarks                              |
  -- | =======  ===========  =============   ===================================  |
  -- | 1.0      17-Apr-2012  Archana N.      Initial version - QC Defect # 20100  |
  -- +============================================================================+

PROCEDURE get_lbx_stats(
    x_err_buf OUT VARCHAR2,
    x_ret_code OUT VARCHAR2,
    p_cycle_date IN VARCHAR2);
    
  -- +============================================================================+
  -- | Name             : GET_TRANSLATIONS                                        |
  -- |                                                                            |
  -- | Description      : This procedure will fetch translation values for a given|
  -- |                    translation name and source                             |
  -- |                                                                            |
  -- | Parameters       : p_debug_flag       IN  VARCHAR2                         |
  -- |                  : p_translation_name IN  VARCHAR2                         |
  -- |                  : p_source_field1    IN  VARCHAR2                         |
  -- |                                                                            |
  -- | Change Record:                                                             |
  -- | ==============                                                             |
  -- | Version  Date         Author          Remarks                              |
  -- | =======  ===========  =============   ===================================  |
  -- | 1.0      17-Apr-2012  Archana N.      Initial version - QC Defect # 20100  |
  -- +============================================================================+

PROCEDURE get_translations(
    p_debug_flag       IN VARCHAR2,
    p_translation_name IN VARCHAR2,
    p_source_field1    IN VARCHAR2 );
    
  -- +============================================================================+
  -- | Name             : GET_LB_FILE_DATA                                        |
  -- |                                                                            |
  -- | Description      : This procedure will fetch details of lockbox files      |
  -- |                    received and for a given cycle date expected            |
  -- |                                                                            |
  -- | Parameters       : lc_cdate IN DATE                                        |
  -- |                                                                            |
  -- | Change Record:                                                             |
  -- | ==============                                                             |
  -- | Version  Date         Author          Remarks                              |
  -- | =======  ===========  =============   ===================================  |
  -- | 1.0      17-Apr-2012  Archana N.      Initial version - QC Defect # 20100  |
  -- +============================================================================+

PROCEDURE get_lb_file_data(
    lc_cdate IN DATE);
    
  -- +============================================================================+
  -- | Name             : GET_RECORD_COUNT                                        |
  -- |                                                                            |
  -- | Description      : This procedure will fetch record counts for lockbox     |
  -- |                    files of a given date and send the data to business.    |
  -- |                                                                            |
  -- | Parameters       : x_err_buf OUT VARCHAR2                                  |
  -- |                  : x_ret_code    OUT  VARCHAR2                             |
  -- |                  : p_cycle_date IN VARCHAR2 --Cycle Date                   |
  -- |                  : p_send_mail IN VARCHAR2                                 |
  -- |                                                                            |
  -- | Change Record:                                                             |
  -- | ==============                                                             |
  -- | Version  Date         Author          Remarks                              |
  -- | =======  ===========  =============   ===================================  |
  -- | 1.0      17-Apr-2012  Archana N.      Initial version - QC Defect # 20100  |
  -- +============================================================================+

PROCEDURE get_record_count(
    x_err_buf OUT VARCHAR2,
    x_ret_code OUT VARCHAR2,
    p_cycle_date IN VARCHAR2,
    p_send_mail  IN VARCHAR2);
    
  -- +============================================================================+
  -- | Name             : PREPARE_AND_SEND_EMAIL                                  |
  -- |                                                                            |
  -- | Description      : This procedure will send html email alerts to           |
  -- |                    appropriate teams                                       |
  -- |                                                                            |
  -- | Parameters       : p_debug_flag    IN  VARCHAR2                            |
  -- |                  : p_from          IN  VARCHAR2                            |
  -- |                  : p_to_tbl     IN  t_recipient                            |
  -- |                  : p_cc_tbl     IN  t_recipient                            |
  -- |                  : p_mail_host     IN  VARCHAR2                            |
  -- |                  : p_subject       IN  VARCHAR2                            |
  -- |                  : p_title_html    IN  VARCHAR2                            |
  -- |                  : p_body_hdr_html IN  VARCHAR2                            |
  -- |                  : p_body_dtl_html IN  VARCHAR2                            |
  -- |                  : p_return_status OUT VARCHAR2                            |
  -- |                                                                            |
  -- | Change Record:                                                             |
  -- | ==============                                                             |
  -- | Version  Date         Author          Remarks                              |
  -- | =======  ===========  =============   ===================================  |
  -- | 1.0      17-Apr-2012  Archana N.      Initial version - QC Defect # 20100  |
  -- +============================================================================+

PROCEDURE prepare_and_send_email(
    p_debug_flag      IN VARCHAR2,
    p_from            IN VARCHAR2,
    p_to_tbl          IN t_recipient,
    p_cc_tbl          IN t_recipient,
    p_mail_host       IN VARCHAR2,
    p_subject         IN VARCHAR2,
    p_title_html      IN VARCHAR2,
    p_body_hdr_html   IN VARCHAR2,
    p_body_dtl_html   IN VARCHAR2,
    p_return_status OUT VARCHAR2 );
    
END XX_AR_LBX_BATCH_ALERT;
/
