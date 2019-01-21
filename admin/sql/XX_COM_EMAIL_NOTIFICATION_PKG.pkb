create or replace PACKAGE BODY XX_COM_EMAIL_NOTIFICATION_PKG
AS
-- +===================================================================================+
-- |                              Office Depot Inc.                                    |
-- +===================================================================================+
-- | Name             :  XX_COM_EMAIL_NOTIFICATION_PKG                                 |
-- | Description      :  This process handles emailing notifications to concerned teams| 
-- |                     when there is a object failure                                |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date         Author           Remarks                                    |
-- |=======   ==========   =============    ======================                     |
-- | 1.0      28-APR-2016  Manikant Kasu    Initial Version                            |
-- +===================================================================================+

g_proc              VARCHAR2(80) := NULL;
g_debug             VARCHAR2(1)  := 'N';

-- +======================================================================+
-- |                          Office Depot Inc.                           |
-- +======================================================================+
-- | Name             : log_debug_msg                                     |
-- | Description      :                                                   |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      28-APR-2016  Manikant Kasu    Initial Version               |
-- +======================================================================+

-- Public types
TYPE t_split_array IS TABLE OF VARCHAR2(4000);

FUNCTION split_text (p_text       IN  CLOB,
                     p_delimeter  IN  VARCHAR2 DEFAULT ',')
  RETURN t_split_array;

PROCEDURE print_clob (p_clob  IN  CLOB);
PROCEDURE print_clob_old (p_clob  IN  CLOB);

PROCEDURE print_clob_htp (p_clob  IN  CLOB);
PROCEDURE print_clob_htp_old (p_clob  IN  CLOB);

-- ----------------------------------------------------------------------------
FUNCTION split_text (p_text       IN  CLOB,
                     p_delimeter  IN  VARCHAR2 DEFAULT ',')
  RETURN t_split_array IS
-- ----------------------------------------------------------------------------
  l_array  t_split_array   := t_split_array();
  l_text   CLOB := p_text;
  l_idx    NUMBER;
BEGIN
  l_array.delete;

  IF l_text IS NULL THEN
    RAISE_APPLICATION_ERROR(-20000, 'P_TEXT parameter cannot be NULL');
  END IF;

  WHILE l_text IS NOT NULL LOOP
    l_idx := INSTR(l_text, p_delimeter);
    l_array.extend;
    IF l_idx > 0 THEN
      l_array(l_array.last) := SUBSTR(l_text, 1, l_idx - 1);
      l_text := SUBSTR(l_text, l_idx + 1);
    ELSE
      l_array(l_array.last) := l_text;
      l_text := NULL;
    END IF;
  END LOOP;
  RETURN l_array;
END split_text;
-- ----------------------------------------------------------------------------



-- ----------------------------------------------------------------------------
PROCEDURE print_clob (p_clob IN CLOB) IS
-- ----------------------------------------------------------------------------
  l_offset NUMBER := 1;
  l_chunk  NUMBER := 255;
BEGIN
  LOOP
    EXIT WHEN l_offset > LENGTH(p_clob);
    DBMS_OUTPUT.put_line(SUBSTR(p_clob, l_chunk, l_offset));
    l_offset := l_offset + l_chunk;
  END LOOP;
END print_clob;
-- ----------------------------------------------------------------------------



-- ----------------------------------------------------------------------------
PROCEDURE print_clob_old (p_clob IN CLOB) IS
-- ----------------------------------------------------------------------------
  l_offset NUMBER := 1;
  l_chunk  NUMBER := 255;
BEGIN
  LOOP
    EXIT WHEN l_offset > DBMS_LOB.getlength(p_clob);
    DBMS_OUTPUT.put_line(DBMS_LOB.substr(p_clob, l_chunk, l_offset));
    l_offset := l_offset + l_chunk;
  END LOOP;
END print_clob_old;
-- ----------------------------------------------------------------------------



-- ----------------------------------------------------------------------------
PROCEDURE print_clob_htp (p_clob IN CLOB) IS
-- ----------------------------------------------------------------------------
  l_offset NUMBER := 1;
  l_chunk  NUMBER := 32767;
BEGIN
  LOOP
    EXIT WHEN l_offset > LENGTH(p_clob);
    HTP.prn(SUBSTR(p_clob, l_chunk, l_offset));
    l_offset := l_offset + l_chunk;
  END LOOP;
END print_clob_htp;
-- ----------------------------------------------------------------------------



-- ----------------------------------------------------------------------------
PROCEDURE print_clob_htp_old (p_clob IN CLOB) IS
-- ----------------------------------------------------------------------------
  l_offset NUMBER := 1;
  l_chunk  NUMBER := 32767;
BEGIN
  LOOP
    EXIT WHEN l_offset > DBMS_LOB.getlength(p_clob);
    HTP.prn(DBMS_LOB.substr(p_clob, l_chunk, l_offset));
    l_offset := l_offset + l_chunk;
  END LOOP;
END print_clob_htp_old;
-- ----------------------------------------------------------------------------

PROCEDURE log_debug_msg ( p_debug_msg          IN  VARCHAR2 )
IS
 ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.Login_Id;
 ln_user_id           FND_USER.USER_ID%TYPE  := FND_GLOBAL.User_Id;
 lc_user_name         FND_USER.USER_NAME%TYPE  := FND_GLOBAL.user_name;

BEGIN
  
  IF (g_debug = 'Y') THEN
    XX_COM_ERROR_LOG_PUB.log_error
      (
         p_return_code             => FND_API.G_RET_STS_SUCCESS
        ,p_msg_count               => 1
        ,p_application_name        => 'XXOD'
        ,p_program_type            => 'LOG'             
        ,p_attribute15             => 'XX_OD_EBS_EMAIL_NTFICTNS_PKG'      
        ,p_attribute16             => g_proc
        ,p_program_id              => 0                    
        ,p_module_name             => 'XXCOMN'      
        ,p_error_message           => p_debug_msg
        ,p_error_message_severity  => 'LOG'
        ,p_error_status            => 'ACTIVE'
        ,p_created_by              => ln_user_id
        ,p_last_updated_by         => ln_user_id
        ,p_last_update_login       => ln_login
     );
    FND_FILE.PUT_LINE(FND_FILE.log, p_debug_msg);
  END IF;
END log_debug_msg;

-- +======================================================================+
-- |                          Office Depot Inc.                           |
-- +======================================================================+
-- | Name             : log_error                                         |
-- | Description      :                                                   |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      28-APR-2016  Manikant Kasu    Initial Version               |
-- +======================================================================+

PROCEDURE log_error ( p_error_msg          IN  VARCHAR2 )
IS
 ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.Login_Id;
 ln_user_id           FND_USER.USER_ID%TYPE  := FND_GLOBAL.User_Id;
 lc_user_name         FND_USER.USER_NAME%TYPE  := FND_GLOBAL.user_name;
 
BEGIN
  
  XX_COM_ERROR_LOG_PUB.log_error
      (
         p_return_code             => FND_API.G_RET_STS_SUCCESS
        ,p_msg_count               => 1
        ,p_application_name        => 'XXOD'
        ,p_program_type            => 'ERROR'             
        ,p_attribute15             => 'XX_COM_EMAIL_NOTIFICATION_PKG'      
        ,p_attribute16             => g_proc
        ,p_program_id              => 0                    
        ,p_module_name             => 'XXCOMN'      
        ,p_error_message           => p_error_msg
        ,p_error_message_severity  => 'MAJOR'
        ,p_error_status            => 'ACTIVE'
        ,p_created_by              => ln_user_id
        ,p_last_updated_by         => ln_user_id
        ,p_last_update_login       => ln_login
      );
  FND_FILE.PUT_LINE(FND_FILE.LOG, p_error_msg);    

END log_error;


-- +======================================================================+
-- |                          Office Depot Inc.                           |
-- +======================================================================+
-- | Name             : get_translations                                  |
-- | Description      :                                                   |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      28-APR-2016  Manikant Kasu    Initial Version               |
-- +======================================================================+

PROCEDURE get_translations( p_translation_name IN VARCHAR2,
                            p_source_value1    IN VARCHAR2 DEFAULT NULL,
                            p_source_value2    IN VARCHAR2 DEFAULT NULL,
                            p_source_value3    IN VARCHAR2 DEFAULT NULL,
                            p_source_value4    IN VARCHAR2 DEFAULT NULL,
                            p_source_value5    IN VARCHAR2 DEFAULT NULL,
                            p_source_value6    IN VARCHAR2 DEFAULT NULL,
                            p_source_value7    IN VARCHAR2 DEFAULT NULL,
                            p_source_value8    IN VARCHAR2 DEFAULT NULL,
                            p_source_value9    IN VARCHAR2 DEFAULT NULL,
                            p_source_value10   IN VARCHAR2 DEFAULT NULL,
                            x_target_value1    IN OUT NOCOPY VARCHAR2,
                            x_target_value2    IN OUT NOCOPY VARCHAR2,
                            x_target_value3    IN OUT NOCOPY VARCHAR2,
                            x_target_value4    IN OUT NOCOPY VARCHAR2,
                            x_target_value5    IN OUT NOCOPY VARCHAR2,
                            x_target_value6    IN OUT NOCOPY VARCHAR2,
                            x_target_value7    IN OUT NOCOPY VARCHAR2,
                            x_target_value8    IN OUT NOCOPY VARCHAR2,
                            x_target_value9    IN OUT NOCOPY VARCHAR2,
                            x_target_value10   IN OUT NOCOPY VARCHAR2,
                            x_target_value11   IN OUT NOCOPY VARCHAR2,
                            x_target_value12   IN OUT NOCOPY VARCHAR2,
                            x_target_value13   IN OUT NOCOPY VARCHAR2,
                            x_target_value14   IN OUT NOCOPY VARCHAR2,
                            x_target_value15   IN OUT NOCOPY VARCHAR2,
                            x_target_value16   IN OUT NOCOPY VARCHAR2,
                            x_target_value17   IN OUT NOCOPY VARCHAR2,
                            x_target_value18   IN OUT NOCOPY VARCHAR2,
                            x_target_value19   IN OUT NOCOPY VARCHAR2,
                            x_target_value20   IN OUT NOCOPY VARCHAR2,
                            x_error_message    IN OUT NOCOPY VARCHAR2
                          )
IS
  l_target_value1  VARCHAR2(240);
  l_target_value2  VARCHAR2(240);
  l_target_value3  VARCHAR2(240);
  l_target_value4  VARCHAR2(240);
  l_target_value5  VARCHAR2(240);
  l_target_value6  VARCHAR2(240);
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
                                                       p_translation_name => p_translation_name
                                                      ,p_source_value1    => p_source_value1
                                                      ,p_source_value2    => p_source_value2
                                                      ,p_source_value3    => p_source_value3
                                                      ,p_source_value4    => p_source_value4
                                                      ,p_source_value5    => p_source_value5
                                                      ,p_source_value6    => p_source_value6
                                                      ,p_source_value7    => p_source_value7
                                                      ,p_source_value8    => p_source_value8
                                                      ,p_source_value9    => p_source_value9
                                                      ,p_source_value10   => p_source_value10
                                                      ,x_target_value1    => x_target_value1
                                                      ,x_target_value2    => x_target_value2
                                                      ,x_target_value3    => x_target_value3
                                                      ,x_target_value4    => x_target_value4
                                                      ,x_target_value5    => x_target_value5
                                                      ,x_target_value6    => x_target_value6
                                                      ,x_target_value7    => x_target_value7
                                                      ,x_target_value8    => x_target_value8
                                                      ,x_target_value9    => x_target_value9
                                                      ,x_target_value10   => x_target_value10
                                                      ,x_target_value11   => l_target_value11
                                                      ,x_target_value12   => l_target_value12
                                                      ,x_target_value13   => l_target_value13
                                                      ,x_target_value14   => l_target_value14
                                                      ,x_target_value15   => l_target_value15
                                                      ,x_target_value16   => l_target_value16
                                                      ,x_target_value17   => l_target_value17
                                                      ,x_target_value18   => l_target_value18
                                                      ,x_target_value19   => l_target_value19
                                                      ,x_target_value20   => l_target_value20
                                                      ,x_error_message    => l_error_message
                                                  );
  EXCEPTION 
    WHEN OTHERS THEN
      xx_com_error_log_pub.log_error
              (p_program_type                => 'PROCEDURE',
               p_attribute15                 => 'XX_COM_EMAIL_NOTIFICATION_PKG',
               p_module_name                 => 'XXFIN',
               p_error_location              => 'GET_TRANSLATIONS',
               p_error_message_count         => 1,
               p_error_message               => 'Error in get_translations :' || substr(sqlerrm,1,150),
               p_notify_flag                 => 'N'
              );    
END get_translations;	

-- +======================================================================+
-- |                          Office Depot Inc.                           |
-- +======================================================================+
-- | Name             : SEND_NOTIFICATIONS                                |
-- | Description      :                                                   |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      28-APR-2016  Manikant Kasu    Initial Version               |
-- +======================================================================+

PROCEDURE process_recipients(p_mail_conn IN OUT UTL_SMTP.connection,
                             p_list      IN     VARCHAR2)
AS
  l_tab t_split_array;
BEGIN
  IF TRIM(p_list) IS NOT NULL THEN
    l_tab := split_text(p_list);
    FOR i IN 1 .. l_tab.COUNT LOOP
      UTL_SMTP.rcpt(p_mail_conn, TRIM(l_tab(i)));
    END LOOP;
  END IF;
END;
  
PROCEDURE SEND_NOTIFICATIONS(
                               p_email_identifier  IN VARCHAR2
                              ,p_from              IN VARCHAR2 default null
                              ,p_to                IN VARCHAR2 default null
                              ,p_cc                IN VARCHAR2 default null
                              ,p_bcc               IN VARCHAR2 default null
                              ,p_subject           IN VARCHAR2 default null
                              ,p_body              IN VARCHAR2 default null
                            )
IS

     l_conn             UTL_SMTP.connection;
     l_severity         XX_FIN_TRANSLATEVALUES.TARGET_VALUE1%TYPE;
     l_from_name        XX_FIN_TRANSLATEVALUES.TARGET_VALUE2%TYPE;
     l_recepients       XX_FIN_TRANSLATEVALUES.TARGET_VALUE3%TYPE;
     l_cc               XX_FIN_TRANSLATEVALUES.TARGET_VALUE4%TYPE;
     l_bcc              XX_FIN_TRANSLATEVALUES.TARGET_VALUE5%TYPE;
     l_subject_prefix   XX_FIN_TRANSLATEVALUES.TARGET_VALUE6%TYPE;
     l_subject          XX_FIN_TRANSLATEVALUES.TARGET_VALUE7%TYPE;
     l_body             XX_FIN_TRANSLATEVALUES.TARGET_VALUE8%TYPE;
     l_smtp_server      XX_FIN_TRANSLATEVALUES.TARGET_VALUE9%TYPE;
     l_smtp_server_port PLS_INTEGER;
     l_instance         VARCHAR2(60);
     l_message          VARCHAR2(32767);
     
     lv_addr            VARCHAR2 (1000);
     l_len              NUMBER        := 1;
     
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

     get_translations(
                        p_translation_name => 'EBS_NOTIFICATIONS'
                       ,p_source_value1    => p_email_identifier
                       ,x_target_value1    => l_severity
                       ,x_target_value2    => l_from_name
                       ,x_target_value3    => l_recepients
                       ,x_target_value4    => l_cc
                       ,x_target_value5    => l_bcc
                       ,x_target_value6    => l_subject_prefix
                       ,x_target_value7    => l_subject
                       ,x_target_value8    => l_body
                       ,x_target_value9    => l_smtp_server
                       ,x_target_value10   => l_smtp_server_port
                       ,x_target_value11   => l_target_value11
                       ,x_target_value12   => l_target_value12
                       ,x_target_value13   => l_target_value13
                       ,x_target_value14   => l_target_value14
                       ,x_target_value15   => l_target_value15
                       ,x_target_value16   => l_target_value16
                       ,x_target_value17   => l_target_value17
                       ,x_target_value18   => l_target_value18
                       ,x_target_value19   => l_target_value19
                       ,x_target_value20   => l_target_value20
                       ,x_error_message    => l_error_message                       
                     );
     l_smtp_server := nvl(l_smtp_server, FND_PROFILE.VALUE('XX_COMN_SMTP_MAIL_SERVER'));
     l_smtp_server_port := nvl(l_smtp_server_port, 25);
     
     /* Deriving Instance Name*/
      BEGIN
       SELECT instance_name 
         INTO l_instance 
         FROM V$INSTANCE;
      EXCEPTION
         WHEN OTHERS THEN
             fnd_log.STRING (fnd_log.level_statement, 'XX_COM_EMAIL_NOTIFICATION_PKG.SEND_NOTIFICATIONS', 'Error Fetching Instance name :' || SQLERRM);    
      END;
      
      
      l_conn := UTL_SMTP.Open_Connection(l_smtp_server, l_smtp_server_port);
      
      if (p_body is null) then
        l_message := l_body;
      else
        l_message := substr(p_body,1,32767);
      end if;
      
      if (p_from is not null) then
        l_from_name := p_from;
      end if;
      
      if (p_to is not null) then
        l_recepients := p_to;
      end if;    

      if (p_cc is not null) then
        l_cc := p_cc;
      end if;  
      
      if (p_bcc is not null) then
        l_bcc := p_bcc;
      end if;     

      if (p_subject is not null) then
        l_subject := p_subject;
      end if;       
     
      if ( (nvl(l_from_name,'ZZZ')<>'ZZZ') and (nvl(l_recepients,'ZZZ')<>'ZZZ' or nvl(l_cc,'ZZZ')<>'ZZZ' or nvl(l_bcc,'ZZZ')<>'ZZZ' ) )
      then 
      UTL_SMTP.Helo(l_conn, l_smtp_server);
      UTL_SMTP.Mail(l_conn, l_from_name);
      process_recipients(l_conn, l_recepients);  
      process_recipients(l_conn, l_cc);
      process_recipients(l_conn, l_bcc);
      
      
      UTL_SMTP.open_data(l_conn);
      
      UTL_SMTP.write_data(l_conn, 'To: ' || l_recepients || UTL_TCP.crlf);
      IF TRIM(p_cc) IS NOT NULL THEN
        UTL_SMTP.write_data(l_conn, 'CC: ' || REPLACE(l_cc, ',', ';') || UTL_TCP.crlf);
      END IF;
      IF TRIM(p_bcc) IS NOT NULL THEN
        UTL_SMTP.write_data(l_conn, 'BCC: ' || REPLACE(l_bcc, ',', ';') || UTL_TCP.crlf);
      END IF;
      UTL_SMTP.write_data(l_conn, 'From: ' || l_from_name || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_conn, 'Subject: ' || l_subject_prefix || ' ' || l_instance || ' - ' || l_subject  || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_conn, UTL_TCP.crlf);
      UTL_SMTP.write_data(l_conn, l_message || UTL_TCP.crlf || UTL_TCP.crlf);
      UTL_SMTP.close_data(l_conn);
      end if;
      UTL_SMTP.quit(l_conn);      
      
     EXCEPTION
        WHEN UTL_SMTP.transient_error OR UTL_SMTP.permanent_error THEN
          UTL_SMTP.quit( l_conn );
          fnd_log.STRING (fnd_log.level_statement, 'XX_COM_EMAIL_NOTIFICATION_PKG.SEND_NOTIFICATIONS', 'UTL_SMTP Transient or Permanent Error');
           xx_com_error_log_pub.log_error
                   (p_program_type                => 'PROCEDURE',
                    p_attribute15                 => 'XX_COM_EMAIL_NOTIFICATION_PKG',
                    p_module_name                 => 'XXFIN',
                    p_error_location              => 'SEND_NOTIFICATIONS',
                    p_error_message_count         => 1,
                    p_error_message               => 'Error Generating Email :' || 'UTL_SMTP Transient or Permanent Error',
                    p_notify_flag                 => 'N'
                   );
        WHEN OTHERS THEN
          UTL_SMTP.quit( l_conn );
          fnd_log.STRING (fnd_log.level_statement, 'XX_COM_EMAIL_NOTIFICATION_PKG.SEND_NOTIFICATIONS', 'Error Generating Email :'||sqlerrm); 
           xx_com_error_log_pub.log_error
                   (p_program_type                => 'PROCEDURE',
                    p_attribute15                 => 'XX_COM_EMAIL_NOTIFICATION_PKG',
                    p_module_name                 => 'XXFIN',
                    p_error_location              => 'SEND_NOTIFICATIONS',
                    p_error_message_count         => 1,
                    p_error_message               => 'Error Generating Email :' || substr(sqlerrm,1,150),
                    p_notify_flag                 => 'N'
                   );

END SEND_NOTIFICATIONS;


END XX_COM_EMAIL_NOTIFICATION_PKG;
/

SHOW ERRORS;