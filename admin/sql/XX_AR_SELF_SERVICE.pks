create or replace package XX_AR_SELF_SERVICE as

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AR_SELF_SERVICE.pks                                    |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- | Description :                                                            |
-- |                                                                          |
-- | Table hanfler for xx_crm_sfdc_contacts.                                  |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author             Remarks                         |
-- |========  ===========  =================  ================================|
-- |1.0       01-Oct-2020  Divyansh Saini     Initial version                 |
-- |                                                                          |
-- +==========================================================================+
--Bursting report variables
    P_TYPE          VARCHAR2(100);
    P_AS_OF_DATE    VARCHAR2(100);
    P_MAIL_TO       VARCHAR2(100);
    P_SMTP_SERVER   VARCHAR2(100);
    P_MAIL_FROM     VARCHAR2(100);
-- Global variables
    g_package_name  VARCHAR2(100) ;
    g_debug_profile BOOLEAN := False;
    g_max_log_size  NUMBER ;
    g_conc_req_id   NUMBER   := fnd_global.conc_request_id;
    G_SMTP_SERVER   VARCHAR2(100);
    G_MAIL_FROM     VARCHAR2(100);
    g_process_id    NUMBER;

--Function Check_If_Direct (p_AOPS_account_number IN VARCHAR2) return VARCHAR2;
/*********************************************************************
* Function to check if customer exists, and if direct billing or not.
* and update intrim table
*********************************************************************/
Procedure Check_If_Direct (p_process_id IN NUMBER);

/*********************************************************************
* procedure to update email address, for external applications
*********************************************************************/
 PROCEDURE update_email_address(p_aops_number   IN  VARCHAR2
                               ,p_email_address IN  VARCHAR2
                               ,p_ret_status    OUT VARCHAR2
                               ,p_ret_msg       OUT VARCHAR2);
/*********************************************************************
* Function to get customer account number
*********************************************************************/
FUNCTION get_account_number(p_AOPS_account_number IN VARCHAR2) return VARCHAR2 ;
/*********************************************************************
* procedure to insert data into intrim table
*********************************************************************/
Procedure insert_data(p_directory    IN VARCHAR2,
                      p_file_name IN VARCHAR2,
                      p_process_id IN NUMBER,
                      p_delimeter IN VARCHAR2,
                      x_error_status OUT VARCHAR2,
                      x_error_msg OUT VARCHAR2);
/*********************************************************************
* Procedure to process bad address data
*********************************************************************/
procedure process_bad_address(p_err_buf OUT VARCHAR2,
                          p_ret_code OUT VARCHAR2);
/*********************************************************************
* Procedure to process bad email data
*********************************************************************/
procedure process_bad_email(p_err_buf OUT VARCHAR2,
                          p_ret_code OUT VARCHAR2);


/*********************************************************************
* Procedure to process bad contcat data
*********************************************************************/
procedure process_bad_contact(p_err_buf OUT VARCHAR2,
                              p_ret_code OUT VARCHAR2);
/*********************************************************************
* After report trigger for self service
*********************************************************************/
--procedure xx_incorrect_info_main(p_err_buf  OUT VARCHAR2,
--                                 p_ret_code OUT VARCHAR2,
--                                 p_type     IN  VARCHAR2);
FUNCTION afterreport RETURN BOOLEAN;
END XX_AR_SELF_SERVICE;
/