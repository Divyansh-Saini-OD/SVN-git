SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
create or replace PACKAGE BODY  XX_AR_IREC_TOKEN_ERR_EMAIL_PKG 
AS
---+============================================================================================+
---|                              Office Depot                                                  |
---+============================================================================================+
---|    Application     : AR                                                                    |
---|                                                                                            |
---|    Name            : XX_AR_IREC_TOKEN_ERR_EMAIL_PKG.pkb                                    |
---|                                                                                            |
---|    Description     :                                                                       |
---|                                                                                            |
---|    Rice ID         : E1294                                                                 |
---|    Change Record                                                                           |
---|    --------------------------------------------------------------------------              |
---|    Version         DATE              AUTHOR             DESCRIPTION                        |
---|    ------------    ----------------- ---------------    ---------------------              |
---|    1.0             10-Nov-2015       Vasu Raparla      Initial Version                     |
---|    1.1              7-Oct-2016       Madhan Sanjeevi   Modified for Defect# 39534          |
---+============================================================================================+
 -- +====================================================================+
 -- | Name       : get_translations                                      |
 -- | Description: Procedure to derive Translation values                |
 -- |                                                                    |
 -- +====================================================================+
   PROCEDURE get_translations( p_translation_name IN VARCHAR2,
                               p_source_value1    IN VARCHAR2,
                               x_target_value1    IN OUT NOCOPY VARCHAR2,
                               x_target_value2    IN OUT NOCOPY VARCHAR2,
                               x_target_value3    IN OUT NOCOPY VARCHAR2,
                               x_target_value4    IN OUT NOCOPY VARCHAR2,
                               x_target_value5    IN OUT NOCOPY VARCHAR2,
                               x_target_value6    IN OUT NOCOPY VARCHAR2,
                               x_target_value7    IN OUT NOCOPY VARCHAR2
                              )
    IS
      l_target_value7  VARCHAR2(240);
      l_target_value8  VARCHAR2(240);
      l_target_value9  VARCHAR2(240);
      l_target_value10 VARCHAR2(240);
      l_target_value11 VARCHAR2(240);
      l_target_value12 VARCHAR2(240);
      l_target_value13 VARCHAR2(240);
      l_target_value14 VARCHAR2(240);
      l_target_value15 VARCHAR2(240);
      l_target_value16 VARCHAR2(240);
      l_target_value17 VARCHAR2(240);
      l_target_value18 VARCHAR2(240);
      l_target_value19 VARCHAR2(240);
      l_target_value20 VARCHAR2(240);
      l_error_message  VARCHAR2(240);
    BEGIN
        xx_fin_translate_pkg.xx_fin_translatevalue_proc(
        p_translation_name => p_translation_name,
        p_source_value1    => p_source_value1,
        x_target_value1    => x_target_value1,
        x_target_value2    => x_target_value2,
        x_target_value3    => x_target_value3,
        x_target_value4    => x_target_value4,
        x_target_value5    => x_target_value5,
        x_target_value6    => x_target_value6,
        x_target_value7    => x_target_value7,
        x_target_value8    => l_target_value8,
        x_target_value9    => l_target_value9,
        x_target_value10   => l_target_value10,
        x_target_value11   => l_target_value11,
        x_target_value12   => l_target_value12,
        x_target_value13   => l_target_value13,
        x_target_value14   => l_target_value14,
        x_target_value15   => l_target_value15,
        x_target_value16   => l_target_value16,
        x_target_value17   => l_target_value17,
        x_target_value18   => l_target_value18,
        x_target_value19   => l_target_value19,
        x_target_value20   => l_target_value20,
        x_error_message    => l_error_message
         );
      EXCEPTION 
      WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error in get_translations :'||SQLERRM);
    END;		   
 -- +====================================================================+
 -- | Name       : generate_email                                        |
 -- | Description: Procedure to Generate Email                           |
 -- |                                                                    |
 -- +====================================================================+ 
   Procedure generate_email (p_message   IN  VARCHAR2,
                             p_cust_id   IN  NUMBER  ,
                             p_procedure IN VARCHAR2) 
     IS
     l_conn             utl_smtp.connection;
     l_smtp_svr         VARCHAR2(240) ;-- := 'USCHEBSSMTPD01.NA.ODCORP.NET';
     l_from_name        VARCHAR2(240) ;
     l_smtp_server_port PLS_INTEGER   ;-- := 25;
     l_subject          VARCHAR2(240) ;
     l_message          VARCHAR2(500) ;
     l_add_msg          VARCHAR2(500) ;
     l_recepient        VARCHAR2(240) ;
     l_instance         VARCHAR2(20):=null;
     l_acct_num         HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE:=null;
     
     BEGIN
      get_translations('XX_FIN_IREC_TOKEN_PARAMS','SEND_EMAIL',l_smtp_svr, l_smtp_server_port, l_from_name,l_recepient, l_subject, l_message,l_add_msg);
     /* Deriving Instance Name*/
      BEGIN
       SELECT instance_name 
         INTO l_instance 
         FROM V$INSTANCE;
      EXCEPTION
         WHEN OTHERS THEN
          fnd_log.STRING (fnd_log.level_statement, 'XX_AR_IREC_TOKEN_ERR_EMAIL_PKG.GENERATE_EMAIL', 'Error Fetching Instance name :' || SQLERRM);    
      END;
      /* Deriving Customer Account Number*/
      BEGIN
       SELECT account_number
         INTO l_acct_num 
         FROM hz_cust_accounts
        WHERE cust_account_id =nvl(p_cust_id,-99999999);
      EXCEPTION
         WHEN OTHERS THEN
          fnd_log.STRING (fnd_log.level_statement, 'XX_AR_IREC_TOKEN_ERR_EMAIL_PKG.GENERATE_EMAIL', 'Error Fetching Account Number for Cust_account_id :'||p_cust_id ||':- ' || SQLERRM);    
      END;     
          
      l_conn := utl_smtp.Open_Connection(l_smtp_svr, l_smtp_server_port);
      utl_smtp.Helo(l_conn, l_smtp_svr);
      utl_smtp.Mail(l_conn, l_from_name);
      utl_smtp.Rcpt(l_conn, l_recepient);
      utl_smtp.Data(l_conn,
                    'Date: '   || to_char(sysdate, 'Dy, DD Mon YYYY hh24:mi:ss') || utl_tcp.CRLF  ||
                    'From: '   || l_from_name || utl_tcp.crlf  ||
                    'Subject: '||l_instance||' '|| l_subject || utl_tcp.crlf  ||
                    'To: '     || l_recepient || utl_tcp.crlf  ||utl_tcp.crlf  ||
                    l_message  ||' '||p_procedure ||' '|| l_add_msg||
                    ' for  Customer :'|| l_acct_num ||' on :'||to_char(SYSDATE,'DD-MON-YYYY HH24:MI:SS') || utl_tcp.crlf  ||utl_tcp.crlf  ||	-- Message body
                    p_message|| utl_tcp.crlf        -- Message body
                    );
               utl_smtp.Quit(l_conn);
     EXCEPTION
        WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
          utl_smtp.quit( l_conn );
          fnd_log.STRING (fnd_log.level_statement, 'XX_AR_IREC_TOKEN_ERR_EMAIL_PKG.GENERATE_EMAIL', 'UTL_SMTP Transient or Permanent Error');
           xx_com_error_log_pub.log_error
                   (p_program_type                => 'PROCEDURE',
                    p_attribute15                 => 'XX_AR_IREC_TOKEN_ERR_EMAIL_PKG',
                    p_module_name                 => 'XXFIN',
                    p_error_location              => 'GENERATE_EMAIL',
                    p_error_message_count         => 1,
                    p_error_message               => 'Error Generating Email :' || 'UTL_SMTP Transient or Permanent Error',
                    p_notify_flag                 => 'N'
                   );
        WHEN OTHERS THEN
          utl_smtp.quit( l_conn );
          fnd_log.STRING (fnd_log.level_statement, 'XX_AR_IREC_TOKEN_ERR_EMAIL_PKG.GENERATE_EMAIL', 'Error Generating Email :'||sqlerrm); 
           xx_com_error_log_pub.log_error
                   (p_program_type                => 'PROCEDURE',
                    p_attribute15                 => 'XX_AR_IREC_TOKEN_ERR_EMAIL_PKG',
                    p_module_name                 => 'XXFIN',
                    p_error_location              => 'GENERATE_EMAIL',
                    p_error_message_count         => 1,
                    p_error_message               => 'Error Generating Email :' || substr(sqlerrm,1,150),
                    p_notify_flag                 => 'N'
                   );
     END;
 -- +====================================================================+
 -- | Name       : send_email                                            |
 -- | Description: Function called from Business Event to send Email     |
 -- |              to AMS Team when get_token fails in                   |
 -- |              XX_AR_IREC_PAYMENTS  package                          |
 -- +====================================================================+ 

     Function send_email (  p_subscription_guid   IN     RAW,
                            p_event               IN OUT WF_EVENT_T    
                         ) 
                          RETURN  VARCHAR2
     IS
     l_event_name	VARCHAR2(100);
     l_status	    VARCHAR2(100)	:= 'SUCCESS';
     l_message    VARCHAR2(1000):=NULL;
     l_procedure  varchar2(100):=null;
     l_cust_id    hz_cust_accounts.cust_account_id%type;
     BEGIN
     l_event_name	:= p_event.geteventname();
        IF (l_event_name = 'od.oracle.apps.xxfin.tokenization_error')
		      THEN 
            l_message:=p_event.getvalueforparameter('p_err_msg');
            l_cust_id:=p_event.getvalueforparameter('p_cust_id');
            l_procedure:=p_event.getvalueforparameter('p_procedure');
			      generate_email(l_message,l_cust_id,l_procedure);	
		     END IF;
       RETURN (l_status);
     EXCEPTION
      WHEN OTHERS THEN
      l_status:='ERROR';
      fnd_log.STRING (fnd_log.level_statement, 'XX_AR_IREC_TOKEN_ERR_EMAIL_PKG.SEND_EMAIL', 'Error Sending Email :' || sqlerrm );
      xx_com_error_log_pub.log_error
                   (p_program_type                => 'PROCEDURE',
                    p_attribute15                 => 'XX_AR_IREC_TOKEN_ERR_EMAIL_PKG',
                    p_module_name                 => 'XXFIN',
                    p_error_location              => 'SEND_EMAIL',
                    p_error_message_count         => 1,
                    p_error_message               => 'Error in call to Business Event :'||'od.oracle.apps.xxfin.tokenization_error-' || substr(sqlerrm,1,150),
                    p_notify_flag                 => 'N'
                   );
      RETURN (l_status);
    END;
 -- +====================================================================+
 -- | Name       : raise_business_event                                  |
 -- | Description: Function to raise Business Event. Called from         |
 -- |               xx_ar_irec_payments when AJB exception or ACH payment|
 -- |               failure occurs                                       |
 -- +====================================================================+ 
    
    Procedure raise_business_event(p_procedure     IN VARCHAR2,
                                   p_message       IN VARCHAR2,
                                   p_cust_accnt_id IN NUMBER)
    IS
    l_event_parameter_list         wf_parameter_list_t := wf_parameter_list_t (); 
	PRAGMA AUTONOMOUS_TRANSACTION; -- Added for Defect# 39534
    Begin
    wf_event.addparametertolist (p_name              =>'p_err_msg',
                                 p_value             => p_message ,
                                 p_parameterlist     => l_event_parameter_list
                               );
    wf_event.addparametertolist (p_name              =>'p_cust_id',
                                 p_value             => p_cust_accnt_id ,
                                 p_parameterlist     => l_event_parameter_list
                               ); 
     wf_event.addparametertolist (p_name              =>'p_procedure',
                                 p_value             => p_procedure ,
                                 p_parameterlist     => l_event_parameter_list
                               );                          
                               
    wf_event.RAISE (p_event_name => 'od.oracle.apps.xxfin.tokenization_error', 
                    p_event_key => SYS_GUID (),
                    p_parameters => l_event_parameter_list
                             );
        commit;
    l_event_parameter_list.DELETE;
    EXCEPTION
      WHEN OTHERS THEN
       fnd_log.STRING (fnd_log.level_statement, 'XX_AR_IREC_TOKEN_ERR_EMAIL_PKG.RAISE_BUSINESS_EVENT', 'Error Raising Business Event :' || sqlerrm );
       xx_com_error_log_pub.log_error
                   (p_program_type                => 'PROCEDURE',
                    p_attribute15                 => 'XX_AR_IREC_TOKEN_ERR_EMAIL_PKG',
                    p_module_name                 => 'XXFIN',
                    p_error_location              => 'RAISE_BUSINESS_EVENT',
                    p_error_message_count         => 1,
                    p_error_message               => 'Error Raising Business Event :' ||'od.oracle.apps.xxfin.tokenization_error -'|| substr(sqlerrm,1,150),
                    p_notify_flag                 => 'N'
                   );
    END;
    
END XX_AR_IREC_TOKEN_ERR_EMAIL_PKG;
/
SHOW ERRORS;