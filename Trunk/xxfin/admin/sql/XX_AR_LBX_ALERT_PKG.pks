CREATE OR REPLACE 
PACKAGE xx_ar_lbx_alert_pkg AS

-- +=====================================================================================================+
-- |                                Office Depot - Project Simplify                                      |
-- |                                     Oracle AMS Support                                              |
-- +=====================================================================================================+
-- |  Name:  XX_AR_LBX_ALERT_PKG (RICE ID : R7017)                                                       |
-- |                                                                                                     |
-- |  Description:  This package will be used for Lockbox Performance Monitoring Alert                   |
-- |                                                                                                     |
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
-- +=====================================================================================================+


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
                                       );
   
   
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
                                       );
                                       

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
                                       );
                                       

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
                                       );
                                       

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
                                       );
                                                                              

END xx_ar_lbx_alert_pkg;

/

SHOW ERROR