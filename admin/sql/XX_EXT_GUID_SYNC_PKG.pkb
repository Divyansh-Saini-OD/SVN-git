SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_EXT_GUID_SYNC_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                                                                   |
-- +===================================================================+
-- | Name        :  XX_EXT_GUID_SYNC_PKG.pkb                           |
-- | Description :  CDH External User GUID sync Package Body           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1   11-OCT-2014 Sreedhar Mohan     Initial draft version     |
-- |                                                                   |
-- +===================================================================+
AS
  --Procedure for out
  PROCEDURE out ( 
                  p_msg          IN  VARCHAR2 
                )
  IS
  BEGIN
      fnd_file.put_line(fnd_file.output, p_msg);
  END out;
  --Procedure for logging debug log
  PROCEDURE log ( 
                  p_debug              IN  VARCHAR2 DEFAULT 'N'
                 ,p_debug_msg          IN  VARCHAR2 
                )
  IS
  
    ln_login             PLS_INTEGER  := FND_GLOBAL.Login_Id;
    ln_user_id           PLS_INTEGER  := FND_GLOBAL.User_Id;
  
  BEGIN
    if( p_debug = 'Y') then
      XX_COM_ERROR_LOG_PUB.log_error
        (
         p_return_code             => FND_API.G_RET_STS_SUCCESS
        ,p_msg_count               => 1
        ,p_application_name        => 'XXCRM'
        ,p_program_type            => 'DEBUG'              --------index exists on program_type
        ,p_attribute15             => 'XX_EXT_GUID_SYNC_PKG'          --------index exists on attribute15
        ,p_program_id              => 0                    
        ,p_module_name             => 'CDH'                --------index exists on module_name
        ,p_error_message           => p_debug_msg
        ,p_error_message_severity  => 'LOG'
        ,p_error_status            => 'ACTIVE'
        ,p_created_by              => ln_user_id
        ,p_last_updated_by         => ln_user_id
        ,p_last_update_login       => ln_login
        );
      fnd_file.put_line(fnd_file.log, p_debug_msg);
    end if;
  END log;

  procedure sync_guid (
                        x_errbuf              OUT VARCHAR2
                       ,x_retcode             OUT VARCHAR2
                      )
  IS
    P_USER_NAME VARCHAR2(200);
    X_USER_GUID RAW(200);
    X_PASSWORD VARCHAR2(200);
    X_RESULT BINARY_INTEGER;

    X_USER_NAME VARCHAR2(200);
    X_OWNER VARCHAR2(200);
    X_UNENCRYPTED_PASSWORD VARCHAR2(200);
    X_SESSION_NUMBER NUMBER;
    X_START_DATE DATE;
    X_END_DATE DATE;
    X_LAST_LOGON_DATE DATE;
    X_DESCRIPTION VARCHAR2(200);
    X_PASSWORD_DATE DATE;
    X_PASSWORD_ACCESSES_LEFT NUMBER;
    X_PASSWORD_LIFESPAN_ACCESSES NUMBER;
    X_PASSWORD_LIFESPAN_DAYS NUMBER;
    X_EMPLOYEE_ID NUMBER;
    X_EMAIL_ADDRESS VARCHAR2(200);
    X_FAX VARCHAR2(200);
    X_CUSTOMER_ID NUMBER;
    X_SUPPLIER_ID NUMBER;
    X_OLD_PASSWORD VARCHAR2(200);
    X_CHANGE_SOURCE NUMBER;
    lr_guid RAW(200);
        
    CURSOR C1
    IS
    SELECT   exusr.fnd_user_name
           , exusr.email
           , exusr.party_id
    from     XXCOMN.XX_EXTERNAL_USERS_QUEUE queue
           , XXCOMN.XX_EXTERNAL_USERS       exusr
    where  queue.fnd_user_name          = exusr.fnd_user_name
    and    queue.GUID_UPDATED_FLAG      = 'N';

  begin
    log('Y', 'XX_EXT_GUID_SYNC_PKG.sync_guid(+)');

    X_USER_NAME := NULL;
    X_OWNER := NULL;
    X_UNENCRYPTED_PASSWORD := NULL;
    X_SESSION_NUMBER := NULL;
    X_START_DATE := NULL;
    X_END_DATE := NULL;
    X_LAST_LOGON_DATE := NULL;
    X_DESCRIPTION := NULL;
    X_PASSWORD_DATE := NULL;
    X_PASSWORD_ACCESSES_LEFT := NULL;
    X_PASSWORD_LIFESPAN_ACCESSES := NULL;
    X_PASSWORD_LIFESPAN_DAYS := NULL;
    X_EMPLOYEE_ID := NULL;
    X_EMAIL_ADDRESS := NULL;
    X_FAX := NULL;
    X_CUSTOMER_ID := NULL;
    X_SUPPLIER_ID := NULL;
    X_OLD_PASSWORD := NULL;
    X_USER_GUID := NULL;
    X_CHANGE_SOURCE := NULL;
    lr_guid := NULL;
    
    for i_rec in C1
    loop
    
      --P_USER_NAME := '10010000000005521723';
      
      FND_LDAP_USER.LINK_USER(
        P_USER_NAME => i_rec.FND_USER_NAME,
        X_USER_GUID => X_USER_GUID,
        X_PASSWORD => X_PASSWORD,
        X_RESULT => X_RESULT
      );
      
      log('Y', 'After call to FND_LDAP_USER.LINK_USER, X_USER_GUID: ' || X_USER_GUID || ', X_RESULT: ' || X_RESULT);
      log('Y', 'Before call to FND_USER_PKG.UPDATEUSER');
      
      FND_USER_PKG.UPDATEUSER(
        X_USER_NAME => i_rec.FND_USER_NAME,
        X_OWNER => 'CUST',
        X_UNENCRYPTED_PASSWORD => X_UNENCRYPTED_PASSWORD,
        X_SESSION_NUMBER => X_SESSION_NUMBER,
        X_START_DATE => X_START_DATE,
        X_END_DATE => X_END_DATE,
        X_LAST_LOGON_DATE => X_LAST_LOGON_DATE,
        X_DESCRIPTION => X_DESCRIPTION,
        X_PASSWORD_DATE => X_PASSWORD_DATE,
        X_PASSWORD_ACCESSES_LEFT => X_PASSWORD_ACCESSES_LEFT,
        X_PASSWORD_LIFESPAN_ACCESSES => X_PASSWORD_LIFESPAN_ACCESSES,
        X_PASSWORD_LIFESPAN_DAYS => X_PASSWORD_LIFESPAN_DAYS,
        X_EMPLOYEE_ID => X_EMPLOYEE_ID,
        X_EMAIL_ADDRESS => i_rec.email,
        X_FAX => X_FAX,
        X_CUSTOMER_ID => i_rec.party_id,
        X_SUPPLIER_ID => X_SUPPLIER_ID,
        X_OLD_PASSWORD => X_OLD_PASSWORD,
        X_USER_GUID => X_USER_GUID,
        X_CHANGE_SOURCE => X_CHANGE_SOURCE
      );
      log('Y', 'Before call to FND_USER_PKG.UPDATEUSER');
      
      select user_guid
      into   lr_guid
      from   fnd_user
      where  user_name = i_rec.fnd_user_name;
      
      if lr_guid is not null then
      
        delete from xxcomn.xx_external_users_queue
        where  fnd_user_name = i_rec.fnd_user_name;        
        
      end if;
    
    end loop;
    
    log('Y', 'XX_EXT_GUID_SYNC_PKG.sync_guid(-)');
  exception
    when others then
      log('Y', 'Exception in XX_EXT_GUID_SYNC_PKG.sync_guid: ' || SQLERRM);
      x_errbuf := 'Error when submitting request - '||fnd_message.get;
      x_retcode := 2;      
  end sync_guid;   

END XX_EXT_GUID_SYNC_PKG;
/
