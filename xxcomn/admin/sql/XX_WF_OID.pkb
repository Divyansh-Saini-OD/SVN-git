create or replace
package body WF_OID as
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                                                                   |
-- +===================================================================+
-- | Name        :  XX_WF_OID.pkb                                      |
-- | Description :  Customized WF_OID package for setting up           |
-- |                configurable apps_initialize session               |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1   27-OCT-2014 Sreedhar Mohan     Initial draft version     |
-- |1.1       27-MAY-2015 Manikant Kasu      Made code changes to      |
-- |                                         capture error logs as per |
-- |                                         Defect # 33463            |
-- |1.2       23-Aug-2016 Vasu Raparla       Retrofitted for 12.2.5    |
-- |                                          upgrade                  | 
-- +===================================================================+
/* $Header: WFOIDB.pls 120.3 2006/08/09 14:18:40 rsantis noship $ */
--
-- Start of Package Globals
--
G_MODULE_SOURCE  constant varchar2(80) := 'fnd.plsql.oid.wf_oid.';
  pending_sub_add_event     LDAP_EVENT := NULL;
  key_guid                  varchar2(8):= NULL;
--
-- End of Package Globals
--
-------------------------------------------------------------------------------
g_debug  VARCHAR2(1) := 'N';

--Procedure for logging debug log
PROCEDURE log_debug_msg ( 
                          p_debug_pkg          IN  VARCHAR2
                         ,p_event_type         IN  VARCHAR2 
                         ,p_debug_msg          IN  VARCHAR2 )
IS
 ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.Login_Id;
 ln_user_id           FND_USER.USER_ID%TYPE  := FND_GLOBAL.User_Id;
 lc_user_name         FND_USER.USER_NAME%TYPE  := FND_GLOBAL.user_name;

BEGIN
  g_debug := get_oid_debug_flag;
  
  IF (g_debug = 'Y') THEN
    XX_COM_OID_ERROR_LOG_PKG.log_error
      (
       p_module_name             => 'XXOID'    
      ,p_attribute15             => p_debug_pkg         
      ,p_event_type              => p_event_type
      ,p_error_message           => p_debug_msg
      ,p_fnd_user_name           => lc_user_name
      ,p_creation_date           => sysdate
      ,p_created_by              => ln_user_id
      ,p_last_update_date        => sysdate
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      );
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, p_debug_msg);
  END IF;
END log_debug_msg;

--Procedure for logging Errors/Exceptions
PROCEDURE log_error ( 
                      p_error_pkg          IN  VARCHAR2
                     ,p_event_type         IN  VARCHAR2 
                     ,p_error_msg          IN  VARCHAR2 )
IS
 ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.Login_Id;
 ln_user_id           FND_USER.USER_ID%TYPE  := FND_GLOBAL.User_Id;
 lc_user_name         FND_USER.USER_NAME%TYPE  := FND_GLOBAL.user_name;
 
BEGIN
  g_debug := get_oid_debug_flag;
  
  IF (g_debug = 'Y') THEN
      XX_COM_OID_ERROR_LOG_PKG.log_error
      (
       p_module_name             => 'XXOID'
      ,p_attribute15             => p_error_pkg         
      ,p_event_type              => p_event_type   
      ,p_error_message           => p_error_msg
      ,p_fnd_user_name           => lc_user_name
      ,p_creation_date           => sysdate
      ,p_created_by              => ln_user_id
      ,p_last_update_date        => sysdate
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      );
    FND_FILE.PUT_LINE(FND_FILE.LOG, p_error_msg);    
  END IF;
END log_error;

FUNCTION get_oid_debug_flag return varchar2 is

lc_oid_debug_level    varchar2(10) := null;
lc_od_oid_user_name   fnd_user.user_name%type := NULL;
 
begin

  lc_oid_debug_level  := fnd_profile.value('XXCOM_OID_DEBUG_LOG_LEVEL');
  lc_od_oid_user_name := fnd_global.user_name; 
    
    IF lc_oid_debug_level = 'EXTERNAL'
  then
    IF substr(lc_od_oid_user_name,1,6) = '100100' AND LENGTH(lc_od_oid_user_name) = 20
    THEN 
        return 'Y';
    end if;
  ELSIF lc_oid_debug_level = 'INTERNAL'
  then
    IF substr(lc_od_oid_user_name,1,6) = '100100' AND LENGTH(lc_od_oid_user_name) <> 20
    then
        return 'Y';
    end if;
  ELSIF lc_oid_debug_level = 'BOTH'
  then
        return 'Y';
  ELSIF lc_oid_debug_level = 'NONE'
  then
        return 'N';
  ELSE 
    -- WHEN NONE 
    Return 'N';
  END IF;
  
  exception 
     when others then
     log_error('XX_WF_OID',NULL, 'Exception in WHEN OTHERS GET_OID_DEBUG_FLAG: ' || SQLERRM);   
     wf_core.context('WF_OID', 'get_oid_debug_flag',
                    'Error code: '||to_char(sqlcode),
                    'Error Message: '||substr(sqlerrm, 1, 238));
     Return 'N';
end;

FUNCTION get_od_oid_user_id return number is

  lc_od_oid_user_name   fnd_user.user_name%type := NULL;
  ln_od_oid_user_id     fnd_user.user_id%type := 0;
  
begin

  lc_od_oid_user_name := nvl(fnd_profile.value('XXOD_OD_OID_USER_NAME'),0);
  
  begin
    select user_id
    into   ln_od_oid_user_id
    from   fnd_user
    where  user_name = lc_od_oid_user_name;

    return ln_od_oid_user_id;
  
  exception
    when no_data_found then
      ln_od_oid_user_id := 0;
      return ln_od_oid_user_id;
  end;  
exception
  when others then
    wf_core.context('WF_OID', 'get_od_oid_user_id',
                    'Error code: '||to_char(sqlcode),
                    'Error Message: '||substr(sqlerrm, 1, 238));
    ln_od_oid_user_id := 0;
    return ln_od_oid_user_id;
end;

FUNCTION get_oid_session return dbms_ldap.session is

  retval      pls_integer;
  my_host     varchar2(256);
  my_port     varchar2(256);
  my_user     varchar2(256);
  my_pwd      varchar2(256);
  my_session  dbms_ldap.session;

begin
  retval := -1;

  dbms_ldap.use_exception := TRUE;

  my_host := fnd_preference.get('#INTERNAL', 'LDAP_SYNCH', 'HOST');
  my_port := fnd_preference.get('#INTERNAL', 'LDAP_SYNCH', 'PORT');
  my_user := fnd_preference.get('#INTERNAL', 'LDAP_SYNCH', 'USERNAME');
  my_pwd  := fnd_preference.eget('#INTERNAL','LDAP_SYNCH', 'EPWD', 'LDAP_PWD');
  my_session := DBMS_LDAP.init(my_host, my_port);

  retval := dbms_ldap.simple_bind_s(my_session, my_user, my_pwd);

  return my_session;

exception
  when others then
    wf_core.context('WF_OID', 'get_oid_session',
                    'Error code: '||to_char(sqlcode),
                    'Error Message: '||substr(sqlerrm, 1, 238));
    wf_core.raise('ICX_PREF_DESC');
end;
--
-------------------------------------------------------------------------------
PROCEDURE unbind(p_session in out nocopy dbms_ldap.session)
is
  retval pls_integer;
begin
  retval := -1;
  retval := DBMS_LDAP.unbind_s(p_session);
exception
  when others then null;
end;
--
-------------------------------------------------------------------------------
procedure PutOIDEvent(
    event         in          ldap_event
  , event_status  out nocopy  ldap_event_status) is

  l_module_source    varchar2(256);
  l_null_event_exp   exception;
  l_user_profiles    fnd_oid_util.apps_sso_user_profiles_type;
  
  ln_od_oid_user_id  fnd_user.user_id%type := 0;
  
  l_ldap_event_str   varchar2(4000) := NULL;

begin
  l_module_source := G_MODULE_SOURCE || 'PutOIDEvent: ';

  l_ldap_event_str := fnd_oid_util.get_ldap_event_str(event);                                  --return string
  log_debug_msg('XX_WF_OID.PutOIDEvent',l_module_source,'User_Name: ' || event.object_name || '-' || l_ldap_event_str);

  ln_od_oid_user_id := get_od_oid_user_id;    
  fnd_global.apps_initialize(ln_od_oid_user_id, -1, -1);
  
    if (fnd_log.LEVEL_STATEMENT >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
  then
    fnd_log.string(fnd_log.LEVEL_STATEMENT, l_module_source, 'Begin');
    fnd_log.string(fnd_log.LEVEL_STATEMENT, l_module_source
      , 'event = ' || fnd_oid_util.GET_LDAP_EVENT_STR(event));
  end if;
  
  if (event is null)
  then
    log_debug_msg('XX_WF_OID.PutOIDEvent',NULL,'User_Name: ' || event.object_name || '-' || 'Raising NULL EVENT Exception');
    raise l_null_event_exp;
  end if;

 if (event.event_type = wf_oid.IDENTITY_ADD)
  then
    log_debug_msg('XX_WF_OID.PutOIDEvent',event.event_type,'User_Name:' ||event.object_name ||', and guid :'||event.object_guid || ', calling fnd_oid_util.process_identity_add(event)');
    fnd_oid_util.process_identity_add(event);
  elsif (event.event_type = wf_oid.IDENTITY_MODIFY)
  then
    log_debug_msg('XX_WF_OID.PutOIDEvent',event.event_type,'User_Name:' ||event.object_name ||', and guid :'||event.object_guid || ', calling fnd_oid_util.process_identity_modify(event)');
    fnd_oid_util.process_identity_modify(event);
  elsif (event.event_type = wf_oid.IDENTITY_DELETE)
  then
    log_debug_msg('XX_WF_OID.PutOIDEvent',event.event_type,'User_Name:' ||event.object_name ||', and guid :'||event.object_guid || ', calling fnd_oid_util.process_identity_delete(event)');
    fnd_oid_util.process_identity_delete(event);
  elsif (event.event_type = wf_oid.SUBSCRIPTION_ADD)
  then
    log_debug_msg('XX_WF_OID.PutOIDEvent',event.event_type,'User_Name:' ||event.object_name ||', and guid :'||event.object_guid || ', calling fnd_oid_util.process_subscription_add(event)');
    fnd_oid_util.process_subscription_add(event);
  elsif (event.event_type = wf_oid.SUBSCRIPTION_DELETE)
  then
    log_debug_msg('XX_WF_OID.PutOIDEvent',event.event_type,'User_Name:' ||event.object_name ||', and guid :'||event.object_guid || ', calling fnd_oid_util.process_subscription_delete(event)');
    fnd_oid_util.process_subscription_delete(event);
  else
    --fnd_oid_util.process_event_resend(event_status);
    log_debug_msg('XX_WF_OID.PutOIDEvent','wf_entity_mgr.put_attribute_value','Calling WF Entity Manager to update the changes to event for further process for User_Name:
                  ' ||event.object_name ||', and guid :'||event.object_guid); 
    wf_entity_mgr.put_attribute_value(fnd_oid_util.G_USER, event.object_name,
      fnd_oid_util.G_ORCLGUID, event.object_guid);

    fnd_oid_util.SAVE_TO_CACHE(
        p_ldap_attr_list    => event.attr_list
      , p_entity_type       => fnd_oid_util.G_USER
      , p_entity_key_value  => event.object_name);
    
    wf_entity_mgr.process_changes(fnd_oid_util.G_USER, event.object_name,
      fnd_oid_util.G_OID);

  end if;
  
  event_status := ldap_event_status(event.event_id, null,
    0, null, wf_oid.EVENT_SUCCESS);

  if (fnd_log.LEVEL_STATEMENT >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
  then
    fnd_log.string(fnd_log.LEVEL_STATEMENT, l_module_source, 'End');
  end if;

  log_debug_msg('XX_WF_OID.PutOIDEvent',NULL,event.event_type ||'-  Successful for User_Name :' ||event.object_name ||', and guid :'||event.object_guid);

exception
  when l_null_event_exp then
    event_status := LDAP_EVENT_STATUS(null, null, 0,
      'Received Null Event', wf_oid.EVENT_RESEND);
    log_error('XX_WF_OID.PutOIDEvent',event.event_type,
              'NULL EVENT EXCEPTION for User_Name :' ||event.object_name ||', and guid :'||event.object_guid ||', Error code: '||to_char(sqlcode) ||', ERROR: '||SQLERRM);
    if (fnd_log.LEVEL_EXCEPTION >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
    then
      fnd_log.string(fnd_log.LEVEL_EXCEPTION, l_module_source,
        'Receiced Null Event. Sending wf_oid.EVENT_RESEND');
    end if;

  when others then
    event_status := LDAP_EVENT_STATUS(event.event_id, null, to_char(sqlcode),
      sqlerrm, wf_oid.EVENT_ERROR);      
    log_error('XX_WF_OID.PutOIDEvent',event.event_type,
              'EXCEPTION: ' || sqlerrm || ', in WHEN OTHERS for USER:' ||event.object_name ||', and guid :'||event.object_guid || ', for event: ' || event.event_type);
    if (fnd_log.LEVEL_UNEXPECTED >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
    then
      fnd_log.string(fnd_log.LEVEL_UNEXPECTED, l_module_source, sqlerrm);
    end if;
end PutOIDEvent;
--
-------------------------------------------------------------------------------
function GetAppEvent(event out nocopy ldap_event)
  return number is

  l_module_source       varchar2(256);
  l_entity_changes_rec  fnd_oid_util.wf_entity_changes_rec_type;
  l_ldap_key            fnd_oid_util.ldap_key_type;
  l_ldap_attr_list      ldap_attr_list;
  l_entity_id           number;
   my_temp_id           number;  -- for extra sub_add event --
  l_local_login         varchar2(30);
  l_allow_sync          varchar2(1);
  l_profile_defined     boolean;
  l_copy_event          ldap_event;
  l_apps_username_key   fnd_oid_util.apps_user_key_type;
  
  ln_od_oid_user_id     fnd_user.user_id%type := 0;
  
begin
  l_module_source := G_MODULE_SOURCE || 'GetAppEvent: ';
  
  ln_od_oid_user_id := get_od_oid_user_id;    
  fnd_global.apps_initialize(ln_od_oid_user_id, -1, -1);

  if (fnd_log.LEVEL_PROCEDURE >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
  then
    fnd_log.string(fnd_log.LEVEL_PROCEDURE, l_module_source, 'Begin');
  end if;
  fnd_ldap_mapper.map_entity_changes_rec(l_entity_changes_rec);
  if (fnd_log.LEVEL_STATEMENT >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
  then
    fnd_log.string(fnd_log.LEVEL_STATEMENT, l_module_source,
      'l_entity_changes_rec = ' ||
      fnd_oid_util.GET_ENTITY_CHANGES_REC_STR(l_entity_changes_rec));
  end if;
  l_apps_username_key := fnd_oid_util.get_fnd_user(p_user_name => l_entity_changes_rec.entity_key_value);
  fnd_profile.get_specific(
    name_z       => 'APPS_SSO_LOCAL_LOGIN',
    user_id_z    => l_apps_username_key.user_id,
    val_z        => l_local_login,
    defined_z    => l_profile_defined);

  if (not l_profile_defined or l_local_login = fnd_oid_util.G_LOCAL) then
     if (fnd_log.LEVEL_STATEMENT >= fnd_log.G_CURRENT_RUNTIME_LEVEL) then
       fnd_log.string(fnd_log.LEVEL_STATEMENT, l_module_source,
        'We don''t sync users with profile APPS_SSO_LOCAL_LOGIN=LOCAL: '
         || l_entity_changes_rec.entity_key_value);
      end if;
      --Remove from wf_entity_changes to fix bug 4233358
      delete from wf_entity_changes
       where entity_key_value = l_entity_changes_rec.entity_key_value
       and entity_type = l_entity_changes_rec.entity_type;
      raise fnd_oid_util.event_not_found_exp;
  end if;

  fnd_ldap_mapper.map_ldap_attr_list(
    l_entity_changes_rec.entity_type
  , l_entity_changes_rec.entity_key_value
  , l_ldap_key
  , l_ldap_attr_list);
  l_copy_event := event;

  fnd_ldap_mapper.map_oid_event(l_ldap_key, l_entity_changes_rec
    , l_ldap_attr_list, event);

  if (event.event_type = wf_oid.IDENTITY_MODIFY) then
   --APPS_SSO_LDAP_SYNC profile is considered for MODIFY events only
   fnd_profile.get_specific(
    name_z       => 'APPS_SSO_LDAP_SYNC',
    user_id_z    => l_apps_username_key.user_id,
    val_z        => l_allow_sync,
    defined_z    => l_profile_defined);
    if (not l_profile_defined or l_allow_sync = fnd_oid_util.G_N) then
      if (fnd_log.LEVEL_STATEMENT >= fnd_log.G_CURRENT_RUNTIME_LEVEL) then
       fnd_log.string(fnd_log.LEVEL_STATEMENT, l_module_source,
        'We don''t modify users with profile APPS_SSO_LDAP_SYNC=N: '
         || l_entity_changes_rec.entity_key_value);
      end if;
      event := l_copy_event;
      delete from wf_entity_changes
       where entity_key_value = l_entity_changes_rec.entity_key_value
       and entity_type = l_entity_changes_rec.entity_type;
      raise fnd_oid_util.event_not_found_exp;
    end if;
  end if;

  if (fnd_log.LEVEL_STATEMENT >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
  then
    fnd_log.string(fnd_log.LEVEL_STATEMENT, l_module_source
      , fnd_oid_util.get_ldap_event_str(event));
  end if;

  l_ldap_attr_list.delete;

  if (fnd_log.LEVEL_PROCEDURE >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
  then
    fnd_log.string(fnd_log.LEVEL_PROCEDURE, l_module_source, 'End');
  end if;

  return wf_oid.EVENT_FOUND;

exception
  when fnd_oid_util.event_not_found_exp then
    if (fnd_log.LEVEL_PROCEDURE >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
    then
      fnd_log.string(fnd_log.LEVEL_PROCEDURE, l_module_source
        , 'No more events to send.Sending wf_oid.EVENT_NOT_FOUND');
    end if;

    return wf_oid.EVENT_NOT_FOUND;

  when others then
    if (fnd_log.LEVEL_UNEXPECTED >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
    then
      fnd_log.string(fnd_log.LEVEL_UNEXPECTED, l_module_source, sqlerrm);
    end if;

    return wf_oid.EVENT_NOT_FOUND;
end GetAppEvent;
--
-------------------------------------------------------------------------------
procedure PutAppEventStatus(event_status in ldap_event_status) is

  l_module_source       varchar2(256);
  l_login_profile       varchar2(30);
  l_profile_defined     boolean;
  l_profiles            fnd_oid_util.apps_sso_user_profiles_type;
  l_entity_key_value    wf_entity_changes.entity_key_value%type;
  null_event_status_exp exception;

begin
  l_module_source := G_MODULE_SOURCE || 'PutAppEventStatus: ';

  if (fnd_log.LEVEL_PROCEDURE >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
  then
    fnd_log.string(fnd_log.LEVEL_PROCEDURE, l_module_source, 'Begin');
    if (fnd_log.LEVEL_STATEMENT>= fnd_log.G_CURRENT_RUNTIME_LEVEL)
      then
            fnd_log.string(fnd_log.LEVEL_STATEMENT, l_module_source
              , 'event_status = ' || fnd_oid_util.get_ldap_event_status_str(event_status));
    end if;
  end if;

  if (event_status is null)
  then
    raise null_event_status_exp;
  end if;

  fnd_oid_util.get_entity_key_value(event_status.event_id, l_entity_key_value);

  if (fnd_log.LEVEL_STATEMENT >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
  then
    fnd_log.string(fnd_log.LEVEL_STATEMENT, l_module_source,
      'l_entity_key_value = ' || l_entity_key_value);
  end if;


  if (event_status.error_disposition = wf_oid.EVENT_SUCCESS)
  then
    -- OID sometimes sends dummy event with user_name=guid
    if l_entity_key_value <> '' || event_status.orclguid then
      update fnd_user
       set user_guid = event_status.orclguid
      where user_name = l_entity_key_value;
    else
      return;
   end if;
   if (fnd_log.LEVEL_STATEMENT >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
    then
      fnd_log.string(fnd_log.LEVEL_STATEMENT, l_module_source
        , 'Update FND_USER where user_name = ' ||  l_entity_key_value ||
        ' with user_guid = ' || event_status.orclguid);
   end if;

   l_profiles := fnd_ldap_mapper.MAP_SSO_USER_PROFILES(l_entity_key_value);

   if (l_profiles.local_login = 'SSO')
    then
      update fnd_user
        set encrypted_user_password = fnd_oid_util.G_EXTERNAL
       where user_name = l_entity_key_value;
   end if;

   delete from wf_entity_changes
     where entity_id = event_status.event_id;

   if (fnd_log.LEVEL_STATEMENT >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
    then
      fnd_log.string(fnd_log.LEVEL_STATEMENT, l_module_source
        , 'Deleted WF_ENTITY_CHANGES where entity_id = ' ||
        event_status.event_id);
   end if;
  else
    -- RDESPOTO, 09/02/2004, if not success
    fnd_oid_util.process_no_success_event(event_status);

  end if;


  if (fnd_log.LEVEL_PROCEDURE >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
  then
    fnd_log.string(fnd_log.LEVEL_PROCEDURE, l_module_source, 'End');
  end if;

exception
    -- FIXME: Review the behavior with OID team
  when null_event_status_exp then
    if (fnd_log.LEVEL_EXCEPTION >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
    then
      fnd_log.string(fnd_log.LEVEL_EXCEPTION, l_module_source,
        'Received null_event_status_exp from OiD');
    end if;
  when no_data_found then
    -- FIXME: Review the behavior with OID team
    if (fnd_log.LEVEL_EXCEPTION >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
    then
      fnd_log.string(fnd_log.LEVEL_EXCEPTION, l_module_source,
        'No Data Found');
    end if;
    --RDESPOTO, 09/23/2004
     if(fnd_log.LEVEL_UNEXPECTED >=
	    fnd_log.G_CURRENT_RUNTIME_LEVEL) then
  	  fnd_message.SET_NAME('FND', 'FND_SSO_EVENT_ERROR');
  	  fnd_message.SET_TOKEN('USER_NAME', l_entity_key_value);
  	  fnd_message.SET_TOKEN('ENTITY_ID', event_status.event_id);
      fnd_message.SET_TOKEN('ORCLGUID', event_status.orclguid);
  	  fnd_log.MESSAGE(fnd_log.LEVEL_UNEXPECTED,
     							l_module_source, TRUE);
      fnd_log.string(fnd_log.LEVEL_UNEXPECTED, l_module_source,
        'Synchronization of user definiton between E-Business Suite'||
        ' and Oracle Internet Directory has failed for user:' || l_entity_key_value ||
        ', event id:' || event_status.event_id || ', guid:' || event_status.orclguid);
     end if;
  when others then
    if (fnd_log.LEVEL_EXCEPTION >= fnd_log.G_CURRENT_RUNTIME_LEVEL)
    then
      fnd_log.string(fnd_log.LEVEL_EXCEPTION, l_module_source, sqlerrm);
    end if;
    --RDESPOTO, 09/23/2004
     if(fnd_log.LEVEL_UNEXPECTED >=
	    fnd_log.G_CURRENT_RUNTIME_LEVEL) then
  	  fnd_message.SET_NAME('FND', 'FND_SSO_EVENT_ERROR');
  	  fnd_message.SET_TOKEN('USER_NAME', l_entity_key_value);
  	  fnd_message.SET_TOKEN('ENTITY_ID', event_status.event_id);
      fnd_message.SET_TOKEN('ORCLGUID', event_status.orclguid);
  	  fnd_log.MESSAGE(fnd_log.LEVEL_UNEXPECTED,
     							l_module_source, TRUE);
      fnd_log.string(fnd_log.LEVEL_UNEXPECTED, l_module_source,
        'Synchronization of user definiton between E-Business Suite'||
        ' and Oracle Internet Directory has failed for user:' || l_entity_key_value ||
        ', event id:' || event_status.event_id || ', guid:' || event_status.orclguid);
     end if;
end PutAppEventStatus;
--
-------------------------------------------------------------------------------
FUNCTION user_change(p_subscription_guid in            raw,
                     p_event             in out nocopy wf_event_t)
return varchar2 is

begin
  -- No point re-processing our own changes --
  if (p_event.GetValueForParameter('CHANGE_SOURCE') = 'OID') then
    return 'SUCCESS';
  end if;

  fnd_oid_util.entity_changes(p_event.getEventKey());
  return wf_rule.default_rule(p_subscription_guid, p_event);
end;
--
-------------------------------------------------------------------------------
PROCEDURE future_callback(p_parameters in wf_parameter_list_t default null) is
begin
  fnd_oid_util.entity_changes(
    wf_event.GetValueForParameter('USER_NAME', p_parameters));
end;

------------------------------------------------------------------------------
Procedure Purge_Data(P_Aging_Days In NUMBER)
Is
    L_Module_Name              Constant Varchar2(40)     := '.purge_data';
    L_Row_Count                Number                    := 0;
    
Begin 
    
    log_debug_msg('XX_WF_OID.'||L_Module_Name,'Purge_Data','==> START purging records from the error log table ');
           
    Delete From xx_com_oid_error_log
    Where Last_Update_Date < Sysdate - P_Aging_Days
    ;
  
    L_ROW_COUNT := sql%ROWCOUNT;   
    log_debug_msg('XX_WF_OID.'||L_Module_Name,'Purge_Data','Number of rows deleted from error log table is: ' || L_Row_Count);  
    commit;
    log_debug_msg('XX_WF_OID.'||L_Module_Name,'Purge_Data','<== END purging records from the error log table');
    
    Exception
    When Others Then
        LOG_ERROR('XX_WF_OID.'||L_MODULE_NAME,'Purge_Data','*** Undefined ERROR.');    
        LOG_ERROR('XX_WF_OID.'||L_MODULE_NAME,'Purge_Data','ERROR Code: '||SQLCODE||'; ERROR Msg: '||SQLERRM);  
        log_error('XX_WF_OID.'||L_Module_Name,'Purge_Data','<== END ');     

End Purge_Data;

------------------------------------------------------------------------------
end WF_OID;
--SHOW ERROR
/