create or replace
package body WF_MAIL as
/* $Header: wfmlrb.pls 115.208 2007/07/03 21:07:14 vshanmug ship $ */

--
-- Constants
--

chr_indent     varchar2(8) := '        ';  -- 8 spaces (virtual tab)
chr_indentsize pls_integer := 8;  -- Number of char spaces in a tab
-- 3432204 The LOBLineBreak algorithm as been altered. The line wrapping
-- has been increased to allow for the horizontal line in text/plain
-- notifications
-- wf_linelen pls_integer := 72; -- Max line length for word wrap
wf_linelen pls_integer := 73; -- Max line length for word wrap

FND_WFNTF_DETAILS NUMBER := 1014409;

g_timezoneName varchar2(80) := '';

g_direct_response boolean := FALSE;
g_send_accesskey boolean := TRUE;
g_autoclose_fyi boolean := TRUE;
g_template varchar2(30);  -- internal name for a message
g_fyi boolean := FALSE;

-- CLOB Processing Variables
--g_text_message CLOB; -- LOB locator for text body message
--g_html_message CLOB; -- LOB locator for HTML body message
--g_attachment CLOB;   -- LOB locator for attachments



-- Indexes for CLOB from the pool
g_LOBTable wf_temp_lob.wf_temp_lob_table_type;

g_text_messageIdx pls_integer;
g_html_messageIdx pls_integer;
g_attachmentIdx   pls_integer;

g_text_chunk   pls_integer;
g_html_chunk   pls_integer;

-- More Info feature
g_moreinfo varchar2(3) := NULL;
g_to_role   varchar2(320);

-- GLOBAL Package level varaibles that contain static data.
g_ntfHistory varchar2(30);
g_ntfActionHistory varchar2(50);
g_tab varchar2(1) := wf_core.tab;
g_moreInfoAPrompt varchar2(200);
g_moreInfoAnswer varchar2(200);
g_moreInfoQPrompt varchar2(200);
g_moreInfoSubject varchar2(200);
g_moreInfoSubmit varchar2(200);
g_moreInfoQuestion varchar2(200);
g_moreInfoFrom varchar2(200);
g_moreInfoRequested varchar2(200);
g_moreInfoRequestee varchar2(4000);
g_webAgent varchar2(200) := wf_core.translate('WF_WEB_AGENT');
g_wfmonId varchar2(60);
g_to varchar2(60);
g_from varchar2(60);
g_beginDate varchar2(100);
g_dueDate2 varchar2(60);
g_notificationId varchar2(60);
g_priority varchar2(60);
g_dueDate varchar2(60);
g_invalidRemarks varchar2(400);
g_forExample varchar2(200);
g_soOn varchar2(60);
g_none varchar2(200);
g_truncate varchar2(200);
g_noResult varchar2(200);
g_install varchar2(60) := wf_core.translate('WF_INSTALL');
g_ntfDocText varchar2(30) := wf_notification.doc_text;
g_ntfDocHtml varchar2(30) := wf_notification.doc_html;
g_Id varchar2(30);
g_isFwkNtf boolean;
g_sig_required varchar2(1);
g_fwk_flavor   varchar2(255);
g_email_flavor varchar2(255);
g_render       varchar2(255);

-- response_quote VARCHAR2(1) := '"';
g_open_text_delimiter VARCHAR2(8) := '"';
g_close_text_delimiter VARCHAR2(8) := '"';
g_open_html_delimiter VARCHAR2(8) := '''';
g_close_html_delimiter VARCHAR2(8) := '''';


-- Generic mailer globals
g_Alert_Nodename varchar2(30) := 'ALR';

--
-- HTML Table defaults
--
table_width  varchar2(8) := '100%';
table_border varchar2(2) := '0';
table_cellpadding varchar2(2) := '0';
table_cellspacing varchar2(2) := '0';
table_bgcolor varchar2(7) := 'white';
th_bgcolor varchar2(7) := '#ffffff';
th_fontcolor varchar2(7) := '#000000';
th_fontface varchar2(80) := 'Arial, Helvetica, Geneva, sans-serif';
th_fontsize varchar2(2) := '2';
td_bgcolor varchar2(7) := '#ffffff';
td_fontcolor varchar2(7) := 'black';
td_fontface varchar2(80) := 'Arial, Helvetica, Geneva, sans-serif';
td_fontsize varchar2(2) := '2';


-- UpdateStatus
--   Update mail status and close any notification with no response.
--   Handle error.
-- IN
--   notification id
--   status
--   error name (null if error is in WF_CORE)
procedure UpdateStatus(
    nid        in number,
    status     in varchar2,
    error_name in varchar2)
is
  l_autoclose VARCHAR(1);
begin
   if wf_mail.autoclose_fyi then
      l_autoclose := 'Y';
   else
      l_autoclose := 'N';
   end if;
   wf_mail.UpdateStatus2(nid => UpdateStatus.nid,
                         status => UpdateStatus.status,
                         autoclose => l_autoclose,
                         error_name => UpdateStatus.error_name,
                         external_error => null);
exception
  when others then
    wf_core.context('WF_MAIL', 'UpdateStatus', to_char(nid),
                    UpdateStatus.status, UpdateStatus.error_name);
    raise;

end UpdateStatus;

-- UpdateStatus2
--   Update mail status and close any notification with no response.
--   Handle error.
-- IN
--   nid notification id
--   status Status to set the notification
--   autoclose Flag to specify whether the notification should be closed
--             automitically
--   error name (null if error is in WF_CORE)
--   external_error Any error message that can not be reflected or captured
--                  through the wf_core.context facilty ie Java.
procedure UpdateStatus2(
    nid        in number,
    status     in varchar2,
    autoclose  in varchar2,
    error_name in varchar2,
    external_error in varchar2)
is
  l_mType VARCHAR2(8);
  l_currState VARCHAR2(8);
  updateState boolean;
  l_role varchar2(320);

  parameterList wf_parameter_list_t;
begin
    select message_type, mail_status, recipient_role
    into l_mType, l_currState, l_role
    from wf_notifications
    where notification_id = nid;

    -- If the prevsious state was FAILED, then preserve this state.
    -- A new status of null means that a null message was sent.
    -- This does not cover the case for a pref deliberately set to
    -- query or to summary (even from summary).
    if l_currState = 'FAILED' and (status is null or status = '') then
       updateState := false;
    else
       updateState := true;
    end if;

    if updateState then
       -- This notification had already locked by wfmail() in the mailer
       update WF_NOTIFICATIONS
       set    MAIL_STATUS = UpdateStatus2.status
       where  NOTIFICATION_ID = nid;
    end if;


    if (UpdateStatus2.status = 'ERROR') then
      WF_MAIL.HandleSendError(nid => UpdateStatus2.nid,
                              status => UpdateStatus2.status,
                              error_name => UpdateStatus2.error_name,
                              external_error => UpdateStatus2.external_error);
    elsif (UpdateStatus2.status = 'FAILED') then
       -- Here we only raise an event and leave the message as is.
       -- oracle.apps.wf.notification.send.failure
       parameterlist := wf_parameter_list_t();

       wf_event.AddParameterToList('NOTIFICATION_ID',nid,parameterlist);
       wf_event.AddParameterToList('ROLE',l_role,parameterlist);
       wf_event.AddParameterToList('STATUS',status,parameterlist);
       wf_event.AddParameterToList('ERROR_NAME',error_name,
                                   parameterlist);
       wf_event.AddParameterToList('EXTERNAL_ERROR',external_error,
                                   parameterlist);
       wf_event.addParameterToList('Q_CORRELATION_ID', l_mType, parameterlist);

       --Raise the event
       wf_event.Raise(p_event_name => 'oracle.apps.wf.notification.send.failure',
                      p_event_key  => l_role,
                      p_parameters => parameterlist);

    elsif UpdateStatus2.status = 'UNAVAIL' then
       -- 4031628 The UNAVAIL mail_status has never been used, even
       -- in the C mailer. It only happens when there is a match on
       -- the pattern/actions. Here we can start to raise an event
       -- that indicates that a recipient is not available to respond
       -- to the notification.
       parameterlist := wf_parameter_list_t();

       wf_event.AddParameterToList('NOTIFICATION_ID', UpdateStatus2.nid, parameterlist);
       wf_event.AddParameterToList('STATUS', UpdateStatus2.status, parameterlist);
       wf_event.addParameterToList('Q_CORRELATION_ID', l_mType, parameterlist);

     --Raise the event
     wf_event.Raise(p_event_name=>'oracle.apps.wf.notification.receive.unavail',
                    p_event_key  => to_char(nid),
                    p_parameters => parameterlist);

    elsif (UpdateStatus2.status = 'SENT') then
      -- The default behaviour is to leave the notification open
      -- unless there is a routing rule to tell otherwise.
      -- This is contrary to the behaviour of previous releases
      -- and will be readdressed a little later on.

      -- close this notification if there is no response
      update WF_NOTIFICATIONS N
      set    N.STATUS = 'CLOSED',
             N.END_DATE = sysdate
      where  N.NOTIFICATION_ID = nid
      and not exists (select NULL
                  from WF_MESSAGE_ATTRIBUTES MA
                  where MA.MESSAGE_TYPE = N.MESSAGE_TYPE
                  and   MA.MESSAGE_NAME = N.MESSAGE_NAME
                  and   MA.SUBTYPE = 'RESPOND')
      and (UpdateStatus2.autoclose = 'Y'
         and not exists (select null
                 from wf_routing_rules r
                 where (r.message_type = n.message_type
                   or r.message_type = '*')
                   and (r.message_name = n.message_name
                   or  r.message_name = '*')
                   and r.action = 'FYIOPEN'
                   and r.role = n.recipient_role
                   and sysdate between nvl(begin_date, sysdate -1)
                   and nvl(end_date, sysdate + 1)));
    end if;
exception
  when others then
    wf_core.context('WF_MAIL', 'UpdateStatus2', to_char(nid),
                    UpdateStatus2.status, UpdateStatus2.autoclose,
                    UpdateStatus2.error_name);
    raise;

end UpdateStatus2;

-- ResetFailed
--   Update mail status from FAILED to MAIL for open notifications.
-- IN
--   Queue number on which to process
procedure ResetFailed(p_queue varchar2)
is
   l_nid number;
   l_recipient WF_NOTIFICATIONS.RECIPIENT_ROLE%TYPE;
   l_status varchar2 (8);
   l_timeout boolean;
   l_error_result varchar2(2000);

begin

    -- Dequeue from the exception queue
    -- and re-enqueue the message.
    l_timeout := FALSE;
    wf_xml.setFirstMessage('TRUE');
    while not l_timeout loop
       wf_xml.GetExceptionMessage(p_queue, l_nid, l_recipient, l_status,
                                  l_timeout, l_error_result);
       if ( not l_timeout ) then
          update WF_NOTIFICATIONS N
          set    N.MAIL_STATUS = 'MAIL'
          where  N.NOTIFICATION_ID = l_nid;
          -- wf_xml.EnqueueNotification(l_nid);
       end if;
   end loop;
   commit;

exception
  when others then
    wf_core.context('WF_MAIL', 'ResetFailed', p_queue);
    raise;

end ResetFailed;

-- HandleSendError (PRIVATE)
--   Call any callback in error mode if error occurs in sending mail.
-- IN
--   notification id
--   mailer send status
--   error name (null if error is in WF_CORE)
--   external_error Any error message that can not be reflected or captured
--                  through the wf_core.context facilty ie Java.
procedure HandleSendError(
    nid        in number,
    status     in varchar2,
    error_name in varchar2,
    external_error in varchar2)
is
    cb varchar2(240);
    ctx varchar2(2000);
    role varchar2(320);

    -- Dynamic sql stuff
    sqlbuf varchar2(120);
    tvalue varchar2(4000) := '';
    nvalue number := '';
    dvalue date := '';
    l_dummy varchar2(1);
begin
    -- Get the callback function.
    select CALLBACK, CONTEXT, RECIPIENT_ROLE
    into   cb, ctx, role
    from   WF_NOTIFICATIONS
    where  NOTIFICATION_ID = nid;

    -- If there is no callback, just clear any error and return.
    if (cb is null) then
        wf_core.clear;
        return;
    end if;

    -- Put supplied error message on stack, if any
    if (error_name is not null) then
        begin
            wf_core.token('NID', to_char(nid));
            wf_core.token('STATUS', status);
            wf_core.token('ROLE', role);
            if external_error is not null then
               wf_core.token('EXTERNAL_ERROR', external_error);
            end if;
            wf_core.raise(error_name);
        exception
            when others then null;
        end;
    end if;

    -- Put default error message on stack, if none exists
    if (wf_core.error_name is null) then
        begin
            wf_core.token('NID', to_char(nid));
            if external_error is not null then
               wf_core.token('EXTERNAL_ERROR', external_error);
            end if;
            wf_core.raise('WFMAIL_GENERIC');
        exception
            when others then null;
        end;
    end if;

    -- Call the CB in error mode
    -- ### cb is from table
    -- BINDVAR_SCAN_IGNORE
    sqlbuf := 'begin '||cb||
              '(:p1, :p2, :p3, :p4, :p5, :p6, :p7); end;';
    execute immediate sqlbuf using
      in 'ERROR',
      in ctx,
      in l_dummy,
      in l_dummy,
      in out tvalue,
      in out nvalue,
      in out dvalue;

    -- Clear the error from the stack.
    wf_core.clear;

exception
    when others then
        null;
end HandleSendError;

-- Disable_Recipient_Ntf_pref
--    Updates the recipient of a notification to DISABLED where
--    there has been a failure to deliver to their email address.
--    This function is triggered by the oracle.apps.wf.notification.send.failure
--    event.
function Disable_Recipient_Ntf_Pref(p_subscription_guid in raw,
                     p_event in out NOCOPY WF_EVENT_T) return varchar2
is

  role varchar2(320);
  recipient varchar2(320);
  pref varchar2(8);
  email_address varchar2(320);
  recipientAddress varchar2(320);
  params wf_parameter_list_t;
  errorName varchar2(320);
  externError varchar2(4000);
  nid number;

  delim pls_integer;

  errMessage varchar2(4000);
  errStack varchar2(32000);

  tokens wf_mail_util.parserStack_t;
  tk pls_integer;
  dummy varchar2(2000);
  dummyNumber number;

  orig_system varchar2(30);
  orig_system_id number;

  paramList wf_parameter_list_t;

  invalidRoleList varchar2(32000);
  reasonList varchar2(32000);
  invalidRoleCount pls_integer := 0;
  alertNid number;

  recipient_disabled boolean;
  errorReport varchar2(32000);

  cursor c_roles(parent in varchar2)
  is
  select name, email_address
  from wf_roles r, wf_user_roles ur
  where ur.role_name = parent
    and r.name = ur.user_name;

begin

   if (wf_log_pkg.level_procedure >= fnd_log.g_current_runtime_level) then
      wf_log_pkg.string(WF_LOG_PKG.level_procedure,
                      'wf.plsql.WF_MAIL.Disable_Recipient_Ntf_Pref',
                      'BEGIN');
   end if;
   role := p_event.getEventKey();
   params := p_event.getParameterList();
   errorName := wf_event.getValueForParameter('ERROR_NAME', params);
   externError := wf_event.getValueForParameter('EXTERNAL_ERROR', params);
   nid := to_number(wf_event.getValueForParameter('NOTIFICATION_ID', params));

   if errorName = 'WFMLRSND_FAILED_UNDELIVERABLE' or
      errorName = 'WFMLRSND_FAILED_DELIVERY' then

      -- Where the notification was at all undeliverable, then there
      -- will be a comma sperated list of recipients. Each one of these
      -- recipients will have to be disabled.
      -- The format of the list is {{role}{role}...{role}}.

      -- FAILED_UNDELIVERABLE means that the message was not able to be
      --                      dispatched
      -- FAILED_DELIVERY means that it was dispatched but failed to be
      --                 delivered at the receiving end. For this, there is
      --                 only the nid for which it is associated.
      if errorName = 'WFMLRSND_FAILED_DELIVERY' then
         -- Make up the invalid role list from the recipient_role of the
         -- undeliverable notification.
         begin

            delim := instrb(externError, ':');

            if delim = 0 then
               -- If the details are in the wrong format, don't
               -- bother to do anything.
               return 'SUCCESS';
            end if;

            nid := to_number(substrb(externError, 1, delim -1));
            recipientAddress := substrb(externError, delim+1);

            if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
                wf_log_pkg.string(WF_LOG_PKG.level_statement,
                      'wf.plsql.WF_MAIL.Disable_Recipient_Ntf_Pref',
                      'NID ['||to_char(nid)||
                      '] RESPONDER ['||recipientAddress||']');
            end if;

            select recipient_role
               into recipient
               from wf_notifications
               where notification_id = nid;

         exception
            when no_data_found then
               -- If there is no notification, then don't do anything
               return 'SUCCESS';
            when others then
               wf_core.context('WF_MAIL','Disable_Recipient_Ntf_Pref',
                               errorName, externError, sqlerrm);
               raise;
         end;

          Wf_Directory.GetRoleInfoMail(role => recipient,
                                       display_name => dummy,
                                       email_address => email_address,
                                       notification_preference => pref,
                                       language => dummy,
                                       territory => dummy,
                                       orig_system => orig_system,
                                       orig_system_id => orig_system_id,
                                       installed_flag => dummy);

         if email_address is not null then
            -- Expected case for normal recipients
            externError := '{'||recipient||'}';
         else
            -- Case for recipients that are members of roles
            externError := '';
            for recip in c_roles(recipient) loop
              if lower(recip.email_address) = lower(recipientAddress) then
                 externError := externError||'{'||recip.name||'}';
              end if;
            end loop;
         end if;
      end if;

      tokens := wf_mail_util.strParser(externError, '{}');
      paramList := wf_parameter_list_t(null);

      invalidRoleList := '';
      reasonList := '';
      invalidRoleCount := 0;
      recipient_disabled := false;
      errorReport := wf_core.translate('WFMLR_RECIPIENT_ROLE')||'   -   '||
                     wf_core.translate('WFMLR_NOTIFICATION_PREFERENCE')||
                     wf_core.newline||
                     '=================================================='||
                     wf_core.newline;
      for tk in 1..tokens.COUNT loop
         if tokens(tk) is not null and tokens(tk) <> ',' then

             if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
                wf_log_pkg.string(WF_LOG_PKG.level_statement,
                      'wf.plsql.WF_MAIL.Disable_Recipient_Ntf_Pref',
                      'TOKEN ['||tokens(tk)||']');
             end if;
             Wf_Directory.GetRoleInfoMail(role => tokens(tk),
                                          display_name => dummy,
                                          email_address => dummy,
                                          notification_preference => pref,
                                          language => dummy,
                                          territory => dummy,
                                          orig_system => orig_system,
                                          orig_system_id => orig_system_id,
                                          installed_flag => dummy);

             if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
                wf_log_pkg.string(WF_LOG_PKG.level_statement,
                      'wf.plsql.WF_MAIL.Disable_Recipient_Ntf_Pref',
                      'PREFERENCE ['||pref||']');
             end if;

            if pref is not null and
               pref not in ('DISABLED', 'QUERY', 'SUMMARY', 'SUMHTML') then

                -- 4717488 Take note of the exsiting notification
                -- preference. This will go in the notification to the
                -- SYSADMIN to inform them that this recipient was disabled.
                -- For a group of recipient, only one notification should be
                -- sent.

                errorReport := errorReport || tokens(tk)||'   -   '||pref||
                               wf_core.newLine;
                recipient_disabled := true;

               if orig_system in ('FND_USR', 'PER') then
                 FND_PREFERENCE.put(p_user_name => tokens(tk),
	                            p_module_name => 'WF',
	                            p_pref_name => 'MAILTYPE',
	                            p_pref_value => 'DISABLED');
               else

                 paramList.DELETE;

                 wf_event.AddParameterToList('USER_NAME', tokens(tk),
                                             paramList);
                 wf_event.AddParameterToList('ORCLWORKFLOWNOTIFICATIONPREF',
                                           'DISABLED', paramList);

                 wf_event.AddParameterToList('RAISEERRORS',
                                           'TRUE', paramList);
                 begin
                    wf_local_synch.propagate_user(p_orig_system => orig_system,
                                           p_orig_system_id => orig_system_id,
                                           p_attributes => paramList);
                 exception
                   when others then
                      -- Should the propagate fail, then save the
                      -- role to be used to update the ErrorStack with
                      -- the failed role and the reason.

                      wf_core.get_error(err_name => errorName,
                                        err_message => errMessage,
                                        err_stack => errStack);

                      invalidRoleList := invalidRoleList||'{'||tokens(tk)||
                                         ', '||errMessage||'}';
                      invalidRoleCount := invalidRoleCount + 1;
                 end;

               end if;

            else
               if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
                  wf_log_pkg.string(WF_LOG_PKG.level_statement,
                      'wf.plsql.WF_MAIL.Disable_Recipient_Ntf_Pref',
                      'Unable to update notification preference for email ['||
                      tokens(tk)||']. Check for duplicates');
               end if;
            end if;
         end if;
      end loop;

      -- 4717488 If there as a disable action, then send an error
      -- message by calling the API. The error report
      -- can only have 2000 characters! If larger, then it must be
      -- truncated.
      --
      -- This will result in the WFMLRSND_FAILED_UNDELIVERABLE error
      -- and the WFMLRSND_FAILED_DELIVERY error being raised.
      --
      -- The email for Notification NID was undeliverable. The \
      -- following roles will be disabled DISABLE_REPORT
      if (recipient_disabled) then
         if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
            wf_log_pkg.string(WF_LOG_PKG.level_statement,
                              'wf.plsql.WF_MAIL.Disable_Recipient_Ntf_Pref',
                              'One or more users have been disabled. Sending a notification to SYSADMIN');
         end if;
         if length(errorReport) > 2000 then
            errorReport := substrb(errorReport, 1, 1900);
            errorReport := errorReport||wf_core.translate('WFMLR_REPORT_TRUNC');
         end if;

         -- Note, can not call HandleSendError here since that will result
         -- in the notification activity going into error. That is too
         -- drastic for this case. This becomes a FYI to the SYSADMIN
         -- to inform them of the update to the user notification preference.

         -- Hardcoding the recipient as SYSADMIN. The WFERROR process
         -- notifications all have the same, hardcoded value for their
         -- recipients.
         alertNid := WF_NOTIFICATION.send(role =>  'SYSADMIN',
                                          msg_type => 'WFMAIL',
                                          msg_name => 'USER_PREF_UPDATE_REPORT');

         -- Set the attributes for the report. The message won't be dispatched
         -- until the commit is performed by the calling process.
         WF_NOTIFICATION.setAttrText(nid => alertNid,
                                     aname => 'NOTIFICATION_ID',
                                     avalue => to_char(nid));
         WF_NOTIFICATION.setAttrText(nid => alertNid,
                                     aname => 'ROLE',
                                     avalue => role);
         WF_NOTIFICATION.setAttrText(nid => alertNid,
                                     aname => 'UPDATED_USER_REPORT',
                                     avalue =>  errorReport);

         -- Ensure that the subject is correctly populated.
         WF_NOTIFICATION.Denormalize_Notification(alertNid);

      end if;

   end if;

   if invalidRoleCount > 0 then
      if (wf_log_pkg.level_procedure >= fnd_log.g_current_runtime_level) then
         wf_log_pkg.string(WF_LOG_PKG.level_procedure,
                         'wf.plsql.WF_MAIL.Disable_Recipient_Ntf_Pref',
                         'END WARNING');
      end if;

      p_event.setErrorMessage(wf_core.translate('WFMLR_ROLE_UPDATE_FAILURE'));
      p_event.setErrorStack(substrb(invalidRoleList, 1, 4000));
      return 'WARNING';
   else
      if (wf_log_pkg.level_procedure >= fnd_log.g_current_runtime_level) then
         wf_log_pkg.string(WF_LOG_PKG.level_procedure,
                         'wf.plsql.WF_MAIL.Disable_Recipient_Ntf_Pref',
                         'END SUCCESS');
      end if;
      return 'SUCCESS';
   end if;

exception
   when others then
      wf_core.context('WF_MAIL','Disable_Recipient_Ntf_Pref',
                      role, pref);
      raise;
end Disable_Recipient_Ntf_Pref;

-- GetLovList (PRIVATE)
--   Get Text Lov List
-- Inputs:
--      lk_type - lookup type, which lookup from table.
-- Output:
--      A list of valid lookup meanings, in the form
--              <tab> meaning
-- Example: LOOKUP_TYPE: YES_NO
-- Returns:
--      No
--      Yes
function GetLovList(
        lk_type in varchar2)
return varchar2 is
  cursor c is
    select MEANING
    from WF_LOOKUPS
    where LOOKUP_TYPE = lk_type
    order by MEANING;

  buffer varchar2(32000);
begin

  buffer := '';
  --
  -- Loop through selecting all lookups
  --
  for curs in c loop
    -- Add lookup to end of buffer string.
    buffer := buffer||chr_indent||curs.meaning||g_newLine;
  end loop;

  return(buffer);
exception
  when others then
    wf_core.context('WF_MAIL', 'GetLovList', lk_type);
    raise;
end GetLovList;


-- Bug# 2301881
-- FormatErrorMessage (PRIVATE)
--           Gets the error message for an Invalid
--           response and returns it formatted
-- IN
--   error message for name WFMLR_INVALID_LOOKUP
--
-- OUT
--   lookup type
--   remarks with expected values

procedure FormatErrorMessage(lk_type in  varchar2,
                             remarks out NOCOPY varchar2)
is
    exp_values  varchar2(1000);
    l_vstart    number;
    l_vend      number;
    l_value1    varchar2(100);
    l_value2    varchar2(100);
begin

    remarks := g_invalidRemarks;

    -- get the values for the lookup type
    exp_values := GetLovList(lk_type);

    -- get the first two values for the lookup type
    l_vstart := instr(exp_values, g_newLine, 1);
    l_vend := instr(exp_values, g_newLine, l_vstart+1);
    l_value1 := trim(substr(exp_values, 1, l_vstart-1));
    l_value2 := trim(substr(exp_values, l_vstart+1, l_vend-l_vstart-1));

    remarks := remarks || ' (' || g_forExample || ' "'
                       || l_value1 || '", "' || l_value2
                       || '", ' || g_soOn || ')';
exception
    when others then
       remarks := g_invalidRemarks;
end FormatErrorMessage;


-- HandleResponseError (PRIVATE) handle exception in response
--
--   Sets the MAIL_ERROR error message attribute, then sets the
--   notification status to INVALID.
--
-- IN
--   notification id
--   lookup type
--   value found

procedure HandleResponseError(nid in number,
                              lk_type in varchar2,
                              lk_meaning in varchar2,
                              error_result in out NOCOPY varchar2)
is
    errname   varchar2(30);
    errmsg    varchar2(2000);
    errstack  varchar2(4000);
    no_program_unit exception;
    pragma exception_init(no_program_unit, -6508);

    -- Bug# 2301881 variables to handle new error message format
    value_found varchar2(1000);
    remarks     varchar2(1000);

    parameterlist  wf_parameter_list_t := wf_parameter_list_t();

    role varchar2(320);
    group_id number;
    mType varchar2(8);

begin
    if (wf_log_pkg.level_procedure >= fnd_log.g_current_runtime_level) then
       wf_log_pkg.string(WF_LOG_PKG.level_procedure,
                      'wf.plsql.WF_MAIL.HandleResponseError',
                      'BEGIN');
    end if;

    g_invalidRemarks :=  wf_core.translate('WFMLR_INVALID_REMARKS');
    g_forExample := wf_core.translate('WFMLR_FOR_EXAMPLE');
    g_soOn :=  wf_core.translate('WFMLR_SO_ON');
    g_none :=  wf_core.translate('WFMLR_NONE');

    -- First look for a wf_core error.
    wf_core.get_error(errname, errmsg, errstack);

    -- If no wf_core error look for a sql error.
    if (errname is null) then
        errmsg := sqlerrm;
    end if;

    -- Bug# 2301881 Format the error message
    if (lk_meaning is not null) then
       value_found := lk_meaning;
    else
       value_found := g_none;
    end if;
    if (lk_type is not null) then
       FormatErrorMessage(lk_type, remarks);
    else
       remarks := g_none;
    end if;


    error_result := errmsg;

    -- Set MAIL_ERROR_NAME attribute
    begin
        Wf_Notification.SetAttrText(nid, 'MAIL_ERROR_NAME', errname);
    exception
        when no_program_unit then
            raise;
        when others then
            if (wf_core.error_name = 'WFNTF_ATTR') then
                Wf_Core.Clear;
                Wf_Notification.AddAttr(nid, 'MAIL_ERROR_NAME');
                Wf_Notification.SetAttrText(nid, 'MAIL_ERROR_NAME', errname);
            end if;
    end;

    -- Bug# 2301881 setting the values for message attributes
    -- Set MAIL_ERROR_MESSAGE attribute
    begin
        Wf_Notification.SetAttrText(nid, 'MAIL_ERROR_MESSAGE', errmsg);
    exception
        when no_program_unit then
            raise;
        when others then
            if (wf_core.error_name = 'WFNTF_ATTR') then
                Wf_Core.Clear;
                Wf_Notification.AddAttr(nid, 'MAIL_ERROR_MESSAGE');
                Wf_Notification.SetAttrText(nid, 'MAIL_ERROR_MESSAGE', errmsg);
            end if;
    end;

    -- Set MAIL_VALUE_FOUND attribute
    begin
        Wf_Notification.SetAttrText(nid, 'MAIL_VALUE_FOUND', value_found);
    exception
        when no_program_unit then
            raise;
        when others then
            if (wf_core.error_name = 'WFNTF_ATTR') then
                Wf_Core.Clear;
                Wf_Notification.AddAttr(nid, 'MAIL_VALUE_FOUND');
                Wf_Notification.SetAttrText(nid, 'MAIL_VALUE_FOUND', value_found);
            end if;
    end;

    -- Set MAIL_EXP_VALUES attribute
    begin
        Wf_Notification.SetAttrText(nid, 'MAIL_EXP_VALUES', remarks);
    exception
        when no_program_unit then
            raise;
        when others then
            if (wf_core.error_name = 'WFNTF_ATTR') then
                Wf_Core.Clear;
                Wf_Notification.AddAttr(nid, 'MAIL_EXP_VALUES');
                Wf_Notification.SetAttrText(nid, 'MAIL_EXP_VALUES', remarks);
            end if;
    end;

    -- End Bug# 2301881

    -- Set MAIL_ERROR_STACK attribute
    if (errstack is null) then
       errstack := ' ';
    end if;

    begin
        Wf_Notification.SetAttrText(nid, 'MAIL_ERROR_STACK', errstack);
    exception
        when no_program_unit then
            raise;
        when others then
            if (wf_core.error_name = 'WFNTF_ATTR') then
                Wf_Core.Clear;
                Wf_Notification.AddAttr(nid, 'MAIL_ERROR_STACK');
                Wf_Notification.SetAttrText(nid, 'MAIL_ERROR_STACK', errstack);
            end if;
    end;

    -- Set the mail_status to INVALID (mailer will pick this up)
    update WF_NOTIFICATIONS
    set    MAIL_STATUS = 'INVALID'
    where  NOTIFICATION_ID = nid;
    -- wf_xml.enqueueNotification(nid);

    select recipient_role, group_id, message_type
    into role, group_id, mType
    from wf_notifications
    where notification_id = nid;

    wf_event.AddParameterToList('NOTIFICATION_ID',nid,parameterlist);
    wf_event.AddParameterToList('ROLE',role,parameterlist);
    wf_event.AddParameterToList('GROUP_ID',nvl(group_id,nid),parameterlist);
    wf_event.addParameterToList('Q_CORRELATION_ID', mType, parameterlist);

    if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
       wf_log_pkg.string(WF_LOG_PKG.level_statement,
                      'wf.plsql.WF_MAIL.HandleResponseError',
                      'Raising the Send event');
    end if;

  --Raise the event
  wf_event.Raise(p_event_name => 'oracle.apps.wf.notification.send',
                 p_event_key  => to_char(nid),
                 p_parameters => parameterlist);

exception
    when others then
        if (wf_log_pkg.level_exception >= fnd_log.g_current_runtime_level) then
           wf_log_pkg.string(WF_LOG_PKG.level_exception,
                          'wf.plsql.WF_MAIL.HandleResponseError',
                          'Error Msg '|| sqlerrm);
        end if;

        wf_core.context('WF_MAIL', 'HandleResponseError', nid);
        raise;
end HandleResponseError;


-- WordWrap (PRIVATE)
--   Insert newlines to word wrap a line buffer.
-- Inputs:
--   text - text buffer
--   indent - number of tabs to indent each line by
-- Returns:
--   buffer contents with newlines and tabs embedded
function WordWrap(
  text in varchar2,
  indent in number)
return varchar2 is
  buf        varchar2(32000); -- Text buffer
  textlen    pls_integer;     -- Length of original 'text' argument
  newpos     pls_integer;     -- Current position in text
  space      pls_integer;     -- Position of space char to use for line break
  tabs       varchar2(80);    -- Tab string to prepend each line with
  maxlinelen pls_integer;     -- Max line length allowed
begin
  -- Ignore empty string
  if (text is null) then
    return('');
  end if;

  buf := '';
  newpos := 1;
  textlen := length(text);

  -- Build the indentation string.  This is a string to pre-pend to every
  -- line, containing the requested number of tabs.
  -- (No, lpad/rpad won't work because initial string is null.)
  tabs := '';
  for i in 1 .. indent loop
    tabs := substr(tabs||chr_indent, 1, 80);
  end loop;
  -- Adjust line length to account for indentation
  maxlinelen := wf_linelen - (chr_indentsize * indent);

  loop
    -- Exit when all remaining text fits on one line.
    exit when (textlen - newpos <= maxlinelen);

    -- If next newline is before maxlinelen, then the line is already
    -- short enough.  Use the newline as the linebreak.
    space := instr(text, g_newLine, newpos, 1);

    if ((space = 0) or (space > (newpos + maxlinelen))) then
      -- Either no newlines, or next newline is beyond maxlinelen.
      -- Find the last space before maxlinelen.
      space := instr(text, ' ', -(textlen - newpos - maxlinelen), 1);

      if ((space = 0) or (space < newpos)) then
        -- No spaces on this line.
        -- Wrap at the next space or newline available.
        space := instr(replace(text, g_newLine, ' '),
                       ' ', newpos + maxlinelen, 1);

        if (space = 0) then
          -- No spaces or newlines left at all, so no more wrapping
          -- can be done.  Exit now and append any remaining text unaltered.
          exit;
        end if;
      end if;
    end if;

    -- Append the new line to the buffer followed by a newline,
    -- indented by requested number of tabs.
    buf := substrb(buf||tabs||rtrim(substr(text, newpos, space - newpos))||
                  g_newLine, 1, 32000);

    -- Start again after last space.
    newpos := space + 1;
  end loop;

  -- Append last partial line.
  buf := substrb(buf||tabs||rtrim(substr(text, newpos)), 1, 32000);

  return(buf);
exception
  when others then
    wf_core.context('WF_MAIL', 'WordWrap', text, to_char(indent));
    raise;
end WordWrap;


-- GetLovMeaning (PRIVATE)
--   Return the displayed meaning of a lookup
-- Inputs:
--   lk_type - lookup type
--   lk_code - lookup code
-- Returns:
--   lookup meaning
function GetLovMeaning(
  lk_type in varchar2,
  lk_code in varchar2)
return varchar2 is
  buf varchar2(80);
begin
  -- Allow null values
  if (lk_code is null) then
    return(null);
  end if;

  begin
    select MEANING
    into   buf
    from   WF_LOOKUPS
    where  LOOKUP_TYPE = lk_type and LOOKUP_CODE = lk_code;
  exception
    when no_data_found then
      wf_core.token('TYPE', lk_type);
      wf_core.token('CODE', lk_code);
      wf_core.raise('WFSQL_LOOKUP_CODE');
  end;

  return(buf);
exception
  when others then
    wf_core.context('WF_MAIL', 'GetLovMeaning', lk_type, lk_code);
    raise;
end GetLovMeaning;


-- GetLovCode (PRIVATE) Return the hidden code of a lookup
--
-- IN
--   lookup type
--   lookup meaning
-- RETURN
--   lookup code
function GetLovCode(
    lk_type    in varchar2,
    lk_meaning in varchar2)
return varchar2 is
    buf varchar2(30);
begin
    -- Allow null values
    if (lk_meaning is null) then
        wf_core.raise('WFMLR_INVALID_LOOKUP');
    end if;

    -- Exact match
    begin
        select LOOKUP_CODE
        into   buf
        from   WF_LOOKUPS
        where  LOOKUP_TYPE = lk_type
        and    MEANING = lk_meaning;

        return buf;
    exception
        when no_data_found then
            null;
    end;

    -- Case-insensitive match
    begin
        select LOOKUP_CODE
        into   buf
        from   WF_LOOKUPS
        where  LOOKUP_TYPE = lk_type
        and    upper(MEANING) = upper(lk_meaning);
    exception
        when no_data_found then
            wf_core.raise('WFMLR_INVALID_LOOKUP');
    end;

    return buf;
exception
    when others then
        wf_core.context('WF_MAIL', 'GetLovCode', lk_type, lk_meaning);
        raise;
end GetLovCode;


-- GetLovListInternal (PRIVATE)
--   Get Text Lov List (Internal Name)
-- Inputs:
--      lk_type - lookup type, which lookup from table.
-- Output:
--      A list of valid lookup meanings, in the form
--              <tab> meaning
-- Example: LOOKUP_TYPE: YES_NO
-- Returns:
--      No
--      Yes
function GetLovListInternal(
        lk_type in varchar2)
return varchar2 is
  cursor c is
    select LOOKUP_CODE
    from WF_LOOKUPS
    where LOOKUP_TYPE = lk_type
    order by LOOKUP_CODE;

  buffer varchar2(32000);
begin

  buffer := '';
  --
  -- Loop through selecting all lookups
  --
  for curs in c loop
    -- Add lookup to end of buffer string.
    buffer := buffer||curs.lookup_code||g_newLine;
  end loop;

  return(buffer);
exception
  when others then
    wf_core.context('WF_MAIL', 'GetLovListInternal', lk_type);
    raise;
end GetLovListInternal;

-- GetDirectAnswer (PRIVATE)
--   Get Answer for direct response
-- Inputs:
--      mail body.
-- Output:
--      Answer
procedure GetDirectAnswer(body   in out NOCOPY varchar2,
                          one_answer out NOCOPY varchar2) is
  answer varchar2(4000);
  newline_pos pls_integer;
  close_doublequote_pos pls_integer;
  answer_syntax_error exception;
begin

  -- Striping leading spaces and tabs
  while (substr(body, 1, 1) = ' ' or
         substr(body, 1, 1) = g_tab) loop
    body := substr(body, 2, length(body) - 1);
  end loop;

  if (substr(body, 1, 1) <> '"') then
    -- Answer not quoted in ""
    newline_pos := instr(body, g_newLine, 1);
    if (newline_pos = 0) then
         answer := substrb(body,1,4000);
    else
      if (newline_pos <> 1) then
        answer := substr(body, 1, newline_pos-1);
      else
        answer := null;
      end if;
      body := substr(body, newline_pos + 1, length(body) - newline_pos);
    end if;
    -- Striping trailing spaces, \r or \tab
    while ((substr(answer, length(answer), 1) = ' ') or
           (substr(answer, length(answer), 1) = g_newLine) or
           (substr(answer, length(answer), 1) = g_tab)) loop
      answer := substr(answer, 1, length(answer) - 1);
    end loop;

  else
    close_doublequote_pos := instr(body, '"', 2);
    if close_doublequote_pos > 4001 then
       answer := substr(body, 2, 3998);
    else
       answer := substr(body, 2, close_doublequote_pos -2);
    end if;

    if (substr(body, close_doublequote_pos + 1, 1) <> g_newLine) then
         raise answer_syntax_error;
    end if;
    body := substr(body, close_doublequote_pos + 2,
                                        length(body) - close_doublequote_pos - 1);
  end if;

  one_answer := answer;

exception
  when answer_syntax_error then
    wf_core.context('WF_MAIL', 'GetDirectAnswer');
    raise;
  when others then
    wf_core.context('WF_MAIL', 'GetDirectAnswer');
    raise;
end GetDirectAnswer;


-- GetEmailResponse (PRIVATE) - Get Email Response Section
-- IN
--   notification id
-- RETURN
--   response template
function GetEmailResponse(nid in number) return varchar2
is
    cursor c1 is
    select WMA.DISPLAY_NAME, WMA.DESCRIPTION, WMA.TYPE, WMA.FORMAT,
           decode(WMA.TYPE,
             'VARCHAR2', decode(WMA.FORMAT,
                           '', WNA.TEXT_VALUE,
                           substr(WNA.TEXT_VALUE, 1, to_number(WMA.FORMAT))),
             'NUMBER', decode(WMA.FORMAT,
                         '', to_char(WNA.NUMBER_VALUE),
                         to_char(WNA.NUMBER_VALUE, WMA.FORMAT)),
             'DATE', decode(WMA.FORMAT,
                       '', to_char(WNA.DATE_VALUE),
                       to_char(WNA.DATE_VALUE, WMA.FORMAT)),
             'LOOKUP', WNA.TEXT_VALUE,
             WNA.TEXT_VALUE) VALUE
    from   WF_NOTIFICATION_ATTRIBUTES WNA,
           WF_NOTIFICATIONS WN,
           WF_MESSAGE_ATTRIBUTES_VL WMA
    where  WNA.NOTIFICATION_ID = nid
    and    WN.NOTIFICATION_ID = WNA.NOTIFICATION_ID
    and    WN.MESSAGE_TYPE = WMA.MESSAGE_TYPE
    and    WN.MESSAGE_NAME = WMA.MESSAGE_NAME
    and    WMA.NAME = WNA.NAME
    and    WMA.SUBTYPE = 'RESPOND'
    and    WMA.TYPE not in ('FORM', 'URL')
    order  by WMA.SEQUENCE;

    buffer varchar2(32000);
begin
    -- for each response variable
    for rec in c1 loop
        -- Print description
        buffer := buffer||WordWrap(rec.description, 0);
        if (rec.description is not null) then
            buffer := buffer||g_newLine;
        end if;

        -- Print prompt
        buffer := buffer||'    '||rec.display_name||': '||
                  wf_mail.g_open_text_delimiter;

        -- Print field
        if (rec.type = 'LOOKUP') then
            -- LOOKUPs: show displayed meaning, list of choices
            buffer := buffer || GetLovMeaning(rec.format, rec.value) ||
                          wf_mail.g_close_text_delimiter || g_newLine ||
                          GetLovList(rec.format);
        else
            -- VARCHAR2, NUMBER, or DATE: use value directly.
            buffer := buffer || rec.value || wf_mail.g_close_text_delimiter ||
                      g_newLine;
        end if;

        buffer := buffer || g_newLine;
    end loop;

    return buffer;

exception
    when others then
        wf_core.context('WF_MAIL', 'GetEmailResponse', to_char(nid));
        raise;
end GetEmailResponse;


-- GetEmailDirectResponse (PRIVATE) - Get Email Response Section
-- IN
--   notification id
-- RETURN
--   response template
function GetEmailDirectResponse(nid in number) return varchar2
is
    cursor c1 is
    select WMA.DISPLAY_NAME, WMA.DESCRIPTION, WMA.TYPE, WMA.FORMAT,
           decode(WMA.TYPE,
             'VARCHAR2', decode(WMA.FORMAT,
                           '', WNA.TEXT_VALUE,
                           substr(WNA.TEXT_VALUE, 1, to_number(WMA.FORMAT))),
             'NUMBER', decode(WMA.FORMAT,
                         '', to_char(WNA.NUMBER_VALUE),
                         to_char(WNA.NUMBER_VALUE, WMA.FORMAT)),
             'DATE', decode(WMA.FORMAT,
                       '', to_char(WNA.DATE_VALUE),
                       to_char(WNA.DATE_VALUE, WMA.FORMAT)),
             'LOOKUP', WNA.TEXT_VALUE,
             WNA.TEXT_VALUE) VALUE
    from   WF_NOTIFICATION_ATTRIBUTES WNA,
           WF_NOTIFICATIONS WN,
           WF_MESSAGE_ATTRIBUTES_VL WMA
    where  WNA.NOTIFICATION_ID = nid
    and    WN.NOTIFICATION_ID = WNA.NOTIFICATION_ID
    and    WN.MESSAGE_TYPE = WMA.MESSAGE_TYPE
    and    WN.MESSAGE_NAME = WMA.MESSAGE_NAME
    and    WMA.NAME = WNA.NAME
    and    WMA.SUBTYPE = 'RESPOND'
    and    WMA.TYPE not in ('FORM', 'URL')
    order  by WMA.SEQUENCE;

    buffer varchar2(32000) := '';
    seq pls_integer := 1;

begin

    -- for each response variable
    for rec in c1 loop
        -- Construct response instruction:
        wf_core.token('DISPLAY_NAME', rec.display_name);
        wf_core.token('SEQ', seq);
        wf_core.token('DESCRIPTION', rec.description);

        -- Enter the <display_name> on line <#seq> <description>
        buffer := buffer||
                wf_core.substitute('WFMLR', 'WFMLR_DIRECT_ENTER');

        if (rec.value is not null) then
          if (rec.type = 'LOOKUP') then
            wf_core.token('DEFAULT_VALUE',GetLovMeaning(rec.format,rec.value));
          else
            wf_core.token('DEFAULT_VALUE', rec.value);
          end if;
        end if;
        if (rec.format is not null) then
          wf_core.token('FORMAT', rec.format);
        elsif (rec.type = 'VARCHAR2') then
          wf_core.token('FORMAT', '2000');
        end if;

        buffer := buffer||g_newLine;

        -- Handle LOOKUP specially because of printing the LOV list
        if (rec.type = 'LOOKUP') then
            if (rec.value is not null) then
              buffer := buffer||
                wf_core.substitute('WFMLR', 'WFMLR_DIRECT_LOOKUP_DEFAULT');
            else
              buffer := buffer||
                wf_core.substitute('WFMLR', 'WFMLR_DIRECT_LOOKUP');
            end if;
            buffer := WordWrap(buffer, 0);
            buffer := buffer || g_newLine || GetLovList(rec.format);
        else

          -- Value must be ........
          if (rec.type = 'DATE') then
              -- DATE: show date format
              if (rec.format is not null) then
                Buffer := buffer ||
                  wf_core.substitute('WFMLR', 'WFMLR_DIRECT_DATE_FORMAT');
              else
                buffer := buffer ||
                  wf_core.substitute('WFMLR', 'WFMLR_DIRECT_DATE');
              end if;
          elsif (rec.type = 'NUMBER') then
              -- NUMBER: show number format
              if (rec.format is not null) then
                buffer := buffer ||
                  wf_core.substitute('WFMLR','WFMLR_DIRECT_NUMBER_FORMAT');
              else
                buffer := buffer||
                  wf_core.substitute('WFMLR', 'WFMLR_DIRECT_NUMBER');
              end if;

          elsif (rec.type = 'VARCHAR2') then
              -- VARCHAR2: show varchar2 format
              buffer := buffer||
                wf_core.substitute('WFMLR', 'WFMLR_DIRECT_VARCHAR2_FORMAT');
          end if;

          if ((rec.value is not null) and (rec.type <> 'LOOKUP')) then
            wf_core.token('DEFAULT_VALUE', rec.value);
            buffer := buffer||g_newLine||
               wf_core.substitute('WFMLR', 'WFMLR_DIRECT_DEFAULT');
          end if;

          buffer := WordWrap(buffer, 0);

        end if;

        buffer := buffer || g_newLine || g_newLine;
        seq := seq + 1;
    end loop;

    return buffer;

exception
    when others then
        wf_core.context('WF_MAIL', 'GetEmailDirectResponse', to_char(nid));
        raise;
end GetEmailDirectResponse;


-- UrlEncode (PRIVATE)
-- Inputs:
--      input string
-- Output:
--      encoded string
function UrlEncode(in_string varchar2) return varchar2
is
    encoded_string varchar2(32000);
begin

    encoded_string := in_string;

    encoded_string := replace(encoded_string, '%', '%25' );
    encoded_string := replace(encoded_string, ' ', '%20' );
    encoded_string := replace(encoded_string, '!', '%21' );
    encoded_string := replace(encoded_string, '"', '%22' );
    encoded_string := replace(encoded_string, '#', '%23' );
    encoded_string := replace(encoded_string, '$', '%24' );
    encoded_string := replace(encoded_string, '&', '%26' );
    encoded_string := replace(encoded_string, '''', '%27' );
    encoded_string := replace(encoded_string, '(', '%28' );
    encoded_string := replace(encoded_string, ')', '%29' );
    encoded_string := replace(encoded_string, '*', '%2a' );
    encoded_string := replace(encoded_string, '+', '%2b' );
    encoded_string := replace(encoded_string, ',', '%2c' );
    encoded_string := replace(encoded_string, '-', '%2d' );
    encoded_string := replace(encoded_string, '.', '%2e' );
    encoded_string := replace(encoded_string, '/', '%2f' );
    encoded_string := replace(encoded_string, ';', '%3b' );
    encoded_string := replace(encoded_string, '<', '%3c' );
    encoded_string := replace(encoded_string, '=', '%3d' );
    encoded_string := replace(encoded_string, '>', '%3e' );
    encoded_string := replace(encoded_string, '?', '%3f' );
    encoded_string := replace(encoded_string, '@', '%40' );
    encoded_string := replace(encoded_string, '[', '%5b' );
    encoded_string := replace(encoded_string, '\', '%5c' );
    encoded_string := replace(encoded_string, ']', '%5d' );
    encoded_string := replace(encoded_string, '^', '%5e' );
    encoded_string := replace(encoded_string, '_', '%5f' );
    encoded_string := replace(encoded_string, '`', '%60' );
    encoded_string := replace(encoded_string, '{', '%7b' );
    encoded_string := replace(encoded_string, '|', '%7c' );
    encoded_string := replace(encoded_string, '}', '%7d' );
    encoded_string := replace(encoded_string, '~', '%7e' );
    encoded_string := replace(encoded_string, g_newLine,'%0D%0A');

    return(encoded_string);

end UrlEncode;

-- GetMoreInfoLOV (PRIVATE) - bug 2282139
--   Return a list of WF participants (PRIVATE)
-- IN
--   notification id
--   current_role - role/user to whom the ntf is addresses
-- RETURN list of roles whom have participated in the workflow

function GetMoreInfoLOV(nid NUMBER, current_role in VARCHAR2)
return varchar2
is
   itemType   VARCHAR2(8);
   itemKey    VARCHAR2(200);
   context    VARCHAR2(2000);
   orig_sys   varchar2(30);
   orig_sysid number;
   pos        number;
   buffer     varchar2(32000);

   -- Cursor to find all users/roles associated with the notification
   -- other than the ones associated to recipient_role
   cursor c is
   select distinct role user_name from
   (select begin_date, role from
    (select wi.begin_date begin_date, owner_role role
     from   wf_items wi
     where  wi.item_type = itemType
     and    wi.item_key = itemKey
     and    owner_role is not null
     union all
     select ntf.begin_date begin_date, ntf.recipient_role role
     from (select notification_id
           from   wf_item_activity_statuses ias
           where  ias.item_type = itemType
           and    ias.item_key = itemKey
           union all
           select notification_id
           from   wf_item_activity_statuses_h ias
           where  ias.item_type = itemType
           and    ias.item_key = itemKey) intf, wf_notifications ntf
     where intf.notification_id = ntf.group_id)
    where role <> current_role
    and role not in (select wur.role_name
                     from wf_user_roles wur
                     where wur.user_name = current_role
                     and wur.user_orig_system = orig_sys
                     and wur.user_orig_system_id = orig_sysid)
   -- sacsharm bug 2887904 latest participant first
    order by begin_date desc);

begin
   select  context
   into    context
   from    wf_notifications
   where   notification_id = nid;

   -- get item type and item key from the context
   pos := instr(context, ':', 1, 1);
   itemType := substr(context, 1, pos-1);
   pos := pos+1;
   itemKey := substr(context, pos, instr(context, ':', pos, 1) - pos);
   buffer := '';

   -- get role's orig sys and orig sys id from the role name
   pos := instr(current_role, ':', 1, 1);
   if (pos > 0) then
      orig_sys := substr(current_role, 1, pos-1);
      orig_sysid := substr(current_role, pos+1);
   else
      Wf_Directory.GetRoleOrigSysInfo(current_role, orig_sys, orig_sysid);
   end if;

   for curs in c loop
     -- sacsharm bug 2887904 if one particpant, no linefeed needed
     -- buffer := buffer || curs.user_name || g_newLine;
     if c%ROWCOUNT = 1 then
         buffer := curs.user_name;

         -- sacsharm bug 2887904 only latest particpant should be returned
         -- NOTE following exit should be removed later one issue of how to
         -- display participant roles in email is resolved. This is done
         -- so that currently this function only returns latest participant
         exit;

     elsif c%ROWCOUNT > 1 then
         buffer := buffer || g_newLine || curs.user_name;
     end if;
   end loop;
   return buffer;
exception
   when others then
      WF_CORE.Context('WF_MAIL','GetMoreInfoLOV', to_char(nid));
      raise;
end GetMoreInfoLOV;

--
-- GetMoreInfoMailTo (PRIVATE) - bug 2282139
-- IN
--   nid      - Notification id
--   n_tag    - NID string
--   reply_to - Reply to email id
--   subject  - Email subject
-- OUT
--   mail to html tag for more info request or submission
function GetMoreInfoMailTo(nid      in number,
                           n_tag    in varchar2,
                           reply_to in varchar2,
                           subject  in varchar2) return varchar2
is
  buffer       varchar2(32000);
  body         varchar2(32000);
  encoded_tag  varchar2(240);
  question     varchar2(4000);
  l_requestee  varchar2(32000);

  cursor c_questions is
  select user_comment
  from   wf_comments
  where  notification_id = nid
  and    action = 'QUESTION'
  order by comment_date desc ;
begin
  -- this gives mailto tag for the OPEN_MOREINFO template to submit
  -- requested information
  if (g_moreinfo = 'SUB') then
     -- Encode any special characters
     encoded_tag := UrlEncode(n_tag||'[4]');
     -- sacsharm, too much space
     -- body := body || g_newLine;
     body := body || g_moreInfoQPrompt;

     open c_questions;
     fetch c_questions into question;
     close c_questions;

     -- provide response delimiters based on the content of the question
     if (instr(question, '''', 1) > 0 and instr(question, '"', 1) > 0 and
        (instr(question, '[', 1) > 0 or instr(question, ']', 1) > 0)) then
        -- all delimiters are used in the question, escape one and enclose
        -- within the escaped one
        question := replace(question, '''', '\\''');
        body := body || ': '''||question||'''';
     elsif (instr(question, '''', 1) > 0 and instr(question, '"', 1) > 0) then
        body := body || ': ['||question||']';
     elsif (instr(question, '''', 1) > 0) then
        body := body || ': "'||question||'"';
     else
        body := body || ' :'''||question||'''';
     end if;

     body := body || g_newLine;
     body := body || g_moreInfoAPrompt;

     -- ankung (removing <)
     -- body := body || ': ''<';
     body := body || ': '||wf_mail.g_open_html_delimiter;

     body := body || g_moreInfoAnswer;

     -- ankung (removing >)
     -- body := body || '>''';
     body := body || wf_mail.g_close_html_delimiter;

     body := body || g_newLine;
     body := UrlEncode(body);
     buffer := buffer ||'&'||'nbsp;'||'&'||'nbsp;'||
               '<A class="OraLink" HREF="mailto:'||reply_to||'?subject=%20'||
               g_moreInfoSubject||': '||
               UrlEncode(subject)||'&'||'body=%20'||body||
               '%0D%0A%0D%0A'||encoded_tag||'">'||
               '<FONT size=+1><B>'||g_moreInfoSubmit||
               '</FONT></B>'||'</A>';

  -- this gives the additional link along with the response links to
  -- request for more information from a user/role.
  elsif (g_moreinfo = 'REQ') then
    -- Encode any special characters
     encoded_tag := UrlEncode(n_tag||'[3]');

     -- ankung (placing role between the '')
     -- body := body || g_moreInfoFrom ||': ''''';
     -- body := body || g_newLine;
     body := body || g_moreInfoFrom;
     body := body || ': '||wf_mail.g_open_html_delimiter;

     l_requestee := GetMoreInfoLOV(nid, g_to_role);
     if (l_requestee is null) then
       l_requestee := g_moreInfoRequestee;
     end if;
     body := body || wf_notification.SubstituteSpecialChars(l_requestee);
     -- body := body || GetMoreInfoLOV(nid, g_to_role);

     -- ankung (continuation of above)
     body := body || wf_mail.g_close_html_delimiter;

     -- sacsharm commented out, too much space
     -- body := body || g_newLine;
     body := body || g_newLine;
     body := body || g_moreInfoQPrompt;

     -- ankung (removing <)
     -- body := body || ': ''<';
     body := body || ': '||wf_mail.g_open_html_delimiter;

     body := body || g_moreInfoQuestion;

     -- ankung (removing >)
     -- body := body || '>''';
     body := body || wf_mail.g_close_html_delimiter;

     -- sacsharm commented out, too much space
     -- body := body || g_newLine;
     body := body || g_newLine;
     body := UrlEncode(body);
     buffer := buffer ||'&'||'nbsp;'||'&'||'nbsp;'||
               '<A class="OraLink" HREF="mailto:'||reply_to||'?subject=%20'||
               g_moreInfoRequested||': '||
               UrlEncode(subject)||'&'||'body=%20'||body||
               '%0D%0A%0D%0A'||encoded_tag||'">'||
               '<FONT size=+1><B>'||g_moreInfoSubject||
               '</FONT></B>'||'</A>';
  end if;
  return buffer;
exception
  when others then
    wf_core.context('Wf_Mail', 'GetMoreInfoMailTo', to_char(nid));
    raise;
end GetMoreInfoMailTo;


-- GetMailToBody (PRIVATE) - Construct the mailto body part.
-- IN
--   notification id
--   One of the Action(Result) attribute answer
-- RETURN
--   mailto html tag with the subject and body
function GetMailToBody(nid in number,
                       result_answer in varchar2) return varchar2
is
    cursor c1 is
    select WMA.NAME, WMA.DISPLAY_NAME, WMA.DESCRIPTION, WMA.TYPE, WMA.FORMAT,
           decode(WMA.TYPE,
             'VARCHAR2', decode(WMA.FORMAT,
                           '', WNA.TEXT_VALUE,
                           substr(WNA.TEXT_VALUE, 1, to_number(WMA.FORMAT))),
             'NUMBER', decode(WMA.FORMAT,
                         '', to_char(WNA.NUMBER_VALUE),
                         to_char(WNA.NUMBER_VALUE, WMA.FORMAT)),
             'DATE', decode(WMA.FORMAT,
                       '', to_char(WNA.DATE_VALUE),
                       to_char(WNA.DATE_VALUE, WMA.FORMAT)),
             'LOOKUP', WNA.TEXT_VALUE,
             WNA.TEXT_VALUE) VALUE
    from   WF_NOTIFICATION_ATTRIBUTES WNA,
           WF_NOTIFICATIONS WN,
           WF_MESSAGE_ATTRIBUTES_VL WMA
    where  WNA.NOTIFICATION_ID = nid
    and    WN.NOTIFICATION_ID = WNA.NOTIFICATION_ID
    and    WN.MESSAGE_TYPE = WMA.MESSAGE_TYPE
    and    WN.MESSAGE_NAME = WMA.MESSAGE_NAME
    and    WMA.NAME = WNA.NAME
    and    WMA.SUBTYPE = 'RESPOND'
    and    WMA.TYPE not in ('FORM', 'URL')
    order  by decode(WMA.NAME, 'RESULT', -100, WMA.SEQUENCE);

    buffer varchar2(32000);
begin

    -- for each response variable
    for rec in c1 loop
        -- Print description
        if ((rec.name <> 'RESULT') or (result_answer = 'Respond')) then
            if (rec.description is not null) then
                buffer := buffer||WordWrap(rec.description, 0);
                buffer := buffer||g_newLine;
            end if;
        end if;

        -- Print prompt
        buffer := buffer||rec.display_name||': '||wf_mail.g_open_html_delimiter;

        -- Preseed the answer so that recipient does not have to type in manually.
        if ((rec.name = 'RESULT') and (result_answer <> 'Respond')) then
            rec.value := result_answer;
        end if;

        -- Print field
        if (rec.type = 'LOOKUP') then
            -- LOOKUPs: show displayed meaning, list of choices
            buffer := buffer || GetLovMeaning(rec.format, rec.value) ||
                      wf_mail.g_close_html_delimiter|| g_newLine;
            if (rec.name <> 'RESULT' )  then
                buffer := buffer || GetLovList(rec.format);
            end if;
        else
            -- VARCHAR2, NUMBER, or DATE: use value directly.
            buffer := buffer || rec.value ||wf_mail.g_close_html_delimiter||
                      g_newLine;
        end if;

        buffer := buffer || g_newLine;
    end loop;

    buffer := UrlEncode(buffer);

    return buffer;

exception
    when others then
        wf_core.context('WF_MAIL', 'GetMailToBody', to_char(nid));
        raise;
end GetMailToBody;

-- GetMailToBody (PRIVATE) - Construct the mailto body part.
-- IN
--   notification id
--   One of the Action(Result) attribute answer
-- RETURN
--   mailto html tag with the subject and body
procedure GetMailToBody(nid in number,
                       result_answer in varchar2,
                       doc in out NOCOPY CLOB)
is
    cursor c1 is
    select WMA.NAME, WMA.DISPLAY_NAME, WMA.DESCRIPTION, WMA.TYPE, WMA.FORMAT,
           decode(WMA.TYPE,
             'VARCHAR2', decode(WMA.FORMAT,
                           '', WNA.TEXT_VALUE,
                           substr(WNA.TEXT_VALUE, 1, to_number(WMA.FORMAT))),
             'NUMBER', decode(WMA.FORMAT,
                         '', to_char(WNA.NUMBER_VALUE),
                         to_char(WNA.NUMBER_VALUE, WMA.FORMAT)),
             'DATE', decode(WMA.FORMAT,
                       '', to_char(WNA.DATE_VALUE),
                       to_char(WNA.DATE_VALUE, WMA.FORMAT)),
             'LOOKUP', WNA.TEXT_VALUE,
             WNA.TEXT_VALUE) VALUE
    from   WF_NOTIFICATION_ATTRIBUTES WNA,
           WF_NOTIFICATIONS WN,
           WF_MESSAGE_ATTRIBUTES_VL WMA
    where  WNA.NOTIFICATION_ID = nid
    and    WN.NOTIFICATION_ID = WNA.NOTIFICATION_ID
    and    WN.MESSAGE_TYPE = WMA.MESSAGE_TYPE
    and    WN.MESSAGE_NAME = WMA.MESSAGE_NAME
    and    WMA.NAME = WNA.NAME
    and    WMA.SUBTYPE = 'RESPOND'
    and    WMA.TYPE not in ('FORM', 'URL')
    order  by decode(WMA.NAME, 'RESULT', -100, WMA.SEQUENCE);

    str_buffer varchar2(32000);
    --buffer CLOB;
    -- bufferIdx pls_integer;

begin
    -- bufferIdx := wf_temp_lob.getLob(g_LOBTable);

    -- for each response variable
    for rec in c1 loop
        -- Print description
        if ((rec.name <> 'RESULT') or (result_answer = 'Respond')) then
            if (rec.description is not null) then
                str_buffer := str_buffer||WordWrap(rec.description, 0);
                str_buffer := str_buffer||g_newLine;
            end if;
        end if;

        -- Print prompt
        str_buffer := str_buffer||rec.display_name||': '||
                      wf_mail.g_open_html_delimiter;

       -- Preseed the answer so that recipient does not have
       -- to type in manually.

       if ((rec.name = 'RESULT') and (result_answer <> 'Respond')) then
           rec.value := result_answer;
       end if;

        -- Print field
        if (rec.type = 'LOOKUP') then
            -- LOOKUPs: show displayed meaning, list of choices
            str_buffer := str_buffer || GetLovMeaning(rec.format, rec.value) ||
                          wf_mail.g_close_html_delimiter|| g_newLine;
            if (rec.name <> 'RESULT' )  then
                str_buffer := str_buffer || GetLovList(rec.format);
            end if;
        else
            -- VARCHAR2, NUMBER, or DATE: use value directly.
            str_buffer := str_buffer || rec.value ||
                          wf_mail.g_close_html_delimiter||g_newLine;
        end if;

        str_buffer := str_buffer || g_newLine;

        if(length(str_buffer) > 24000) then
           str_buffer := UrlEncode(str_buffer);
           DBMS_LOB.writeAppend(lob_loc => doc,
                                amount => length(str_buffer),
                                buffer => str_buffer);
           str_buffer := '';
        end if;

        -- DBMS_LOB.writeAppend(g_LOBTable(bufferIdx).temp_lob,
        --                      length(str_buffer),
        --                      str_buffer);
        -- str_buffer := '';

    end loop;
    if(length(str_buffer) > 0) then
       str_buffer := UrlEncode(str_buffer);
       DBMS_LOB.writeAppend(lob_loc => doc,
                            amount => length(str_buffer),
                            buffer => str_buffer);
       str_buffer := '';
    end if;
    -- DBMS_LOB.Append(doc, g_LOBTable(bufferIdx).temp_lob);
    -- wf_temp_lob.releaseLob(g_LOBTable, bufferIdx);

exception
    when others then
        -- wf_temp_lob.releaseLob(g_LOBTable, bufferIdx);
        wf_core.context('WF_MAIL', 'GetMailToBody', to_char(nid));
        raise;
end GetMailToBody;

-- GetMailTo - Construct MailTo Section (PRIVATE)
-- IN
--   notification id
--   notification tag
--   notification reply to
--   notification subject
-- RETURN
--   mailto html tag with the subject and body
function GetMailTo(nid in number,
                   n_tag in varchar2,
                   reply_to in varchar2,
                   subject in varchar2) return varchar2
is
    -- SQL Statement for fetching URL RESPONSE attributes.
    cursor c1 is
    select WMA.NAME, WMA.DISPLAY_NAME, WNA.TEXT_VALUE, WMA.DESCRIPTION
    from   WF_NOTIFICATION_ATTRIBUTES WNA,
           WF_NOTIFICATIONS WN,
           WF_MESSAGE_ATTRIBUTES_VL WMA
    where  WNA.NOTIFICATION_ID = nid
    and    WN.NOTIFICATION_ID = WNA.NOTIFICATION_ID
    and    WN.MESSAGE_TYPE = WMA.MESSAGE_TYPE
    and    WN.MESSAGE_NAME = WMA.MESSAGE_NAME
    and    WMA.NAME = WNA.NAME
    and    WMA.SUBTYPE = 'RESPOND'
    and    WMA.TYPE = 'URL'
    order  by WMA.SEQUENCE;

    lov varchar2(64);
    lov_list varchar2(240);
    buffer varchar2(32000);
    auto_answer varchar2(64);
    newline_pos number;
    disp_name varchar2(80);
    attr_type varchar2(8);
    attr_format varchar2(240);
    attr_value varchar2(32000);
    attr_desc varchar2(240);
    encoded_tag varchar2(240);

begin

    -- Clear buffer
    buffer := '';

    -- URL RESPONSE attributes overrides the normal RESULT attributes.
    -- So, my goal here is to check for this case.
    -- URL RESPONSE attributes is going to appear as a anchor and don't have
    -- to construct the MAILTO html tag stuff that we do for the normal
    -- RESULT attribute.

    -- NOTE: Please do know that I don't want to destablize the existing code
    -- for the normal RESULT attribute MAILTO handleing so that I am coding
    -- these two cases seperately.
    -- for each response variable
    for rec in c1 loop
        buffer := buffer||'<P>';
        if (rec.description is not null) then
            buffer := buffer||rec.description||'<P>';
        end if;
        buffer := buffer|| '<A class="OraLink" HREF="'||wf_notification.geturltext(rec.text_value, nid)||'" target="_top">';
        buffer := buffer||'<FONT size=+1> <B>'||rec.display_name;
        buffer := buffer||'</B></FONT>'||'</A>';
        buffer := buffer||g_newLine;
    end loop;

    if (buffer is not null) then
        return(buffer);
    end if;

    --
    -- Normal RESULT attribute handling
    --
    begin
    select WMA.DISPLAY_NAME, WMA.TYPE, WMA.FORMAT,
           decode(WMA.TYPE,
             'VARCHAR2', decode(WMA.FORMAT,
                           '', WNA.TEXT_VALUE,
                           substr(WNA.TEXT_VALUE, 1, to_number(WMA.FORMAT))),
             'NUMBER', decode(WMA.FORMAT,
                         '', to_char(WNA.NUMBER_VALUE),
                         to_char(WNA.NUMBER_VALUE, WMA.FORMAT)),
             'DATE', decode(WMA.FORMAT,
                       '', to_char(WNA.DATE_VALUE),
                       to_char(WNA.DATE_VALUE, WMA.FORMAT)),
             'LOOKUP', WNA.TEXT_VALUE,
             WNA.TEXT_VALUE), WMA.DESCRIPTION
    into   disp_name, attr_type, attr_format, attr_value, attr_desc
    from   WF_NOTIFICATION_ATTRIBUTES WNA,
           WF_NOTIFICATIONS WN,
           WF_MESSAGE_ATTRIBUTES_VL WMA
    where  WNA.NOTIFICATION_ID = nid
    and    WN.NOTIFICATION_ID = WNA.NOTIFICATION_ID
    and    WN.MESSAGE_TYPE = WMA.MESSAGE_TYPE
    and    WN.MESSAGE_NAME = WMA.MESSAGE_NAME
    and    WMA.NAME = WNA.NAME
    and    WMA.SUBTYPE = 'RESPOND'
    and    WMA.NAME = 'RESULT'
    and    WMA.TYPE not in ('FORM', 'URL');

    -- We can only construct answer button or mailto link if is lookup
    if (attr_type <> 'LOOKUP') then
        auto_answer := 'Respond';
    else
        -- If is LOOKUP RESULT attribute, we need to show the description here.
        if (attr_desc is not null) then
            buffer := buffer||'<P>'||attr_desc;
        end if;
        auto_answer :=  attr_format;
    end if;

    exception
    when no_data_found then
        auto_answer := 'Respond';
    end;

    -- Encode any special characters
    encoded_tag := UrlEncode(n_tag);

    -- Construct mailto syntax
    buffer := buffer||'<P>'||disp_name||': <A class="OraLink" HREF="mailto:'||reply_to||
              '?subject=%20'||
              UrlEncode(subject)||'&'||'body=%20';

    if (auto_answer = 'Respond') then
      buffer := buffer||GetMailToBody(nid, auto_answer)||
                '%0D%0A%0D%0A'||encoded_tag||'">'||'<FONT size=+1><B>'||
                 g_noResult||'</B></FONT>'||'</A>';
    else
        lov_list := GetLovListInternal(auto_answer);
        lov_list := substr(lov_list, 1, length(lov_list)-1);

        while (lov_list is not null) loop
            newline_pos := instr(lov_list, g_newLine);

            if (newline_pos = 0) then
                lov := lov_list;
            else
                lov := substr(lov_list, 1, newline_pos - 1);
            end if;

            buffer := buffer||GetMailToBody(nid, lov);
            buffer :=buffer||'%0D%0A%0D%0A'||encoded_tag||'">'||
                     '<FONT size=+1><B>'||GetLovMeaning(attr_format, lov)||
                     '</FONT></B>'||'</A>';
            if (newline_pos = 0) then
                lov_list := null;
                if (g_moreinfo = 'REQ') then
                   buffer := buffer || GetMoreInfoMailTo(nid, n_tag,
                                            reply_to, subject);
                end if;
            else
                lov_list := substr(lov_list, newline_pos+1,
                                   length(lov_list) - newline_pos);
                buffer := buffer||g_newLine;
                buffer := buffer||'&'||'nbsp;'||'&'||'nbsp;'||
                          '<A class="OraLink" HREF="mailto:'||reply_to||
                          '?subject=%20'||UrlEncode(subject)||'&'||'body=%20';
            end if;
        end loop;

    end if;

    return(buffer);

exception
    when others then
      wf_core.context('WF_MAIL', 'GetMailTo', nid);
      raise;

end GetMailTo;


-- Substitute - replaces standard tokens in mail text
function Substitute(
    txt           in  varchar2,
    n_nid         in  number,
    n_code        in  varchar2,
    n_status      in  varchar2,
    n_to_role     in  varchar2,
    r_dname       in  varchar2,
    r_email       in  varchar2,
    n_start_date  in  date,
    n_due_date    in  date,
    n_end_date    in  date,
    n_from_user   in  varchar2,
    n_priority    in  number,
    n_comment     in  varchar2,
    m_subject     in  varchar2,
    m_header      in  varchar2,
    m_body        in  varchar2,
    err_name      in  varchar2,
    err_message   in  varchar2,
    err_invalid   in  varchar2,
    err_expected  in varchar2,
    n_timezone    in  varchar2) return varchar2
as
    stxt          varchar2(32000);
    n_due_date_text varchar2(50);
    n_start_date_text varchar2(50);
    n_priority_text varchar2(240);

begin
    -- BLAF recommends displaying date with the TIME element
    n_due_date_text := to_char(n_due_date, Wf_Notification.g_nls_date_mask);
    n_start_date_text := to_char(n_start_date, Wf_Notification.g_nls_date_mask);

    if (n_priority > 66) then
      --Bug 2774891 fix - sacsharm
      --n_priority_text := wf_core.substitute('WFTKN', 'HIGH');
      n_priority_text := wf_core.substitute('WFTKN', 'LOW');
    elsif (n_priority > 33) then
      n_priority_text := wf_core.substitute('WFTKN', 'NORMAL');
    else
      --Bug 2774891 fix - sacsharm
      --n_priority_text := wf_core.substitute('WFTKN', 'LOW');
      n_priority_text := wf_core.substitute('WFTKN', 'HIGH');
    end if;

    stxt := substrb(txt, 1, 32000);
    stxt := substrb(replace(stxt, '&'||'NOTIFICATION_ID', to_char(n_nid)), 1,
                            32000);
    stxt := substrb(replace(stxt, '&'||'NOTIFICATION', n_code), 1, 32000);
    stxt := substrb(replace(stxt, '&'||'STATUS', n_status), 1, 32000);
    stxt := substrb(replace(stxt, '&'||'TO_DNAME', r_dname), 1, 32000);
    stxt := substrb(replace(stxt, '&'||'TO_EMAIL', r_email), 1, 32000);
    stxt := substrb(replace(stxt, '&'||'TO', n_to_role), 1, 32000);
    stxt := substrb(replace(stxt, '&'||'PRIORITY', n_priority_text), 1, 32000);
    stxt := substrb(replace(stxt, '&'||'START_DATE', n_start_date_text), 1, 32000);
    stxt := substrb(replace(stxt, '&'||'DUE_DATE', n_due_date_text), 1, 32000);
    stxt := substrb(replace(stxt, '&'||'END_DATE', n_end_date), 1, 32000);
    -- Bug 2094159 substituting sender in email notification for From label
    stxt := substrb(replace(stxt, '&'||'SENDER', n_from_user), 1, 32000);
    stxt := substrb(replace(stxt, '&'||'COMMENT', n_comment), 1, 32000);
    stxt := substrb(replace(stxt, '&'||'TIMEZONE', n_timezone), 1, 32000);
    stxt := substrb(replace(stxt, '&'||'SUBJECT', m_subject), 1, 32000);
    stxt := substrb(replace(stxt, '&'||'HEADER', m_header), 1, 32000);
    stxt := substrb(replace(stxt, '&'||'BODY', m_body), 1, 32000);
    stxt := substrb(replace(stxt, '&'||'MAIL_ERROR_NAME', err_name), 1, 32000);
    stxt := substrb(replace(stxt, '&'||'MAIL_ERROR_MESSAGE', err_message),
        1, 32000);
    stxt := substrb(replace(stxt, '&'||'MAIL_VALUE_FOUND', err_invalid), 1, 32000);
    stxt := substrb(replace(stxt, '&'||'MAIL_EXP_VALUES', err_expected), 1, 32000);

    return stxt;
end;

-- GetWarning - get warning messages
--
-- IN
--   Template
--   unsolicited from
--   unsolicited subject
--   unsolicited body
-- OUT
--   message subject
--   message body (text)
--   message body (html)
procedure GetWarning(
    template  in  varchar2,
    ufrom     in  varchar2,
    usubject  in  varchar2,
    ubody     in varchar2,
    subject   out NOCOPY varchar2,
    text_body_text out NOCOPY varchar2,
    html_body_text out NOCOPY varchar2)
as
    t_subject     varchar2(240);
    t_text_body   varchar2(32000);
    t_html_body   varchar2(32000);
    l_pos integer;
    l_templ_val varchar2(1000);
    itemType varchar2(8);
    messageName varchar2(30);

begin

    l_pos := instrb(template, ':', 1);
    if l_pos > 0 then
       itemType := substrb(template, 1, l_pos-1);
       messageName := substrb(template, l_pos+1);
    else
       itemType := 'WFMAIL';
       messageName := 'WARNING';
    end if;

    -- Get template 'WARNING'
    begin
      select SUBJECT, BODY, HTML_BODY
      into   t_subject, t_text_body, t_html_body
      from   WF_MESSAGES_VL
      where  NAME = messageName
      and    TYPE = itemType;
    exception
      when no_data_found then
        wf_core.token('NAME', messageName);
        wf_core.token('TYPE', itemType);
        wf_core.raise('WFNTF_MESSAGE');
    end;

    -- Substitute USER_NAME with role display name
    t_text_body := substrb(replace(t_text_body, '&'||'UFROM', ufrom), 1, 32000);
    t_text_body := substrb(replace(t_text_body, '&'||'USUBJECT',
                             nvl(usubject, ' ')), 1, 32000);
    t_text_body := substrb(replace(t_text_body, '&'||'UBODY',
                             nvl(ubody, ' ')), 1, 32000);

    -- Substitute USER_NAME with role display name
    t_html_body := substrb(replace(t_html_body, '&'||'UFROM', ufrom), 1, 32000);
    t_html_body := substrb(replace(t_html_body, '&'||'USUBJECT',
                             nvl(usubject, ' ')), 1, 32000);
    t_html_body := substrb(replace(t_html_body, '&'||'UBODY',
                             nvl(ubody, ' ')), 1, 32000);

    subject   := t_subject;
    text_body_text := t_text_body;
    html_body_text := t_html_body;

exception
  when others then
    wf_core.context('WF_MAIL', 'GetWarning', ufrom, usubject, ubody);
    raise;
end GetWarning;



-- GetWarning - get warning messages
--
-- IN
--   unsolicited from
--   unsolicited subject
--   unsolicited body
-- OUT
--   message subject
--   message body (text)
--   message body (html)
procedure GetWarning(
    ufrom     in  varchar2,
    usubject  in  varchar2,
    ubody     in varchar2,
    subject   out NOCOPY varchar2,
    text_body_text out NOCOPY varchar2,
    html_body_text out NOCOPY varchar2)
as
begin
   wf_mail.GetWarning('WFMAIL:WARNING', ufrom, usubject, ubody, subject,
                      text_body_text, html_body_text);
end GetWarning;

-- GetTemplateName - Get the template type and name based on the
--                   status of the notification and whether, or not,
--                   the name has been overridden in the configuration
--                   parameters or on the message definition itself.
--
-- IN
--    Notification ID
--    Notification status
--    Notification Mail status
-- OUT
--    Item type for template
--    Message name for template
procedure getTemplateName(nid in number, n_status in varchar2,
                          n_mstatus in varchar2, t_type out NOCOPY varchar2,
                          t_name out NOCOPY varchar2)
is

   colPos number;
   altTempl varchar2(100);
   fyi pls_integer;
   mType varchar2(8);
   mName varchar2(30);
   validTemplate pls_integer;
   inAttr varchar2(1);

begin
    t_type := 'WFMAIL'; -- Set the default type;
    wf_mail.Set_FYI_Flag(FALSE);

    -- Get template name
    if (n_status = 'OPEN') then
        t_name := 'OPEN_'||n_mstatus;
    else
        t_name := n_status;
    end if;

    if (g_moreinfo = 'SUB' and n_mstatus in ('MAIL','INVALID')) then
       if (n_mstatus = 'MAIL') then
          t_name := 'OPEN_MORE_INFO';
       elsif(n_mstatus = 'INVALID') then
          t_name := 'OPEN_INVALID_MORE_INFO';
       end if;
    end if;

    -- Check if this is FYI type of message
    if (t_name = 'OPEN_MAIL') then
      begin
        select 1 into fyi
        from dual
        where not exists (select NULL
                  from WF_MESSAGE_ATTRIBUTES MA,
                       WF_NOTIFICATIONS N
                  where N.NOTIFICATION_ID = nid
                  and   MA.MESSAGE_TYPE = N.MESSAGE_TYPE
                  and   MA.MESSAGE_NAME = N.MESSAGE_NAME
                  and   MA.SUBTYPE = 'RESPOND');
        -- Set the template name to FYI
        t_name :=  t_name||'_FYI';
        wf_mail.Set_FYI_Flag(TRUE);

        exception
          when NO_DATA_FOUND then
             -- If a different mail template name is specified, it took
             -- precedence over direct response.
             if (g_template is not null) then
                t_name := g_template;

             -- This is a response required notification.
             -- Qualify if DIRECT_RESPONSE=Y
             elsif wf_mail.direct_response then
                t_name := t_name || '_DIRECT';
             end if;
        end;
    end if;

    select message_type, message_name
    into mType, mName
    from wf_notifications
    where notification_id = nid;

    -- Now that the template name has been derrived, see
    -- if the default value has been overridden.
    altTempl := WF_MAILER_PARAMETER.getValueForCorr(nid, mType || ':'|| mName, t_name, inAttr);
    colPos := instrb(altTempl, ':', 1);
    if colPos > 0 then
       t_type := substrb(altTempl, 1, colPos -1);
       t_name := substrb(altTempl, colPos + 1, length(altTempl)-colPos);
       -- 3438107 Validate the template name incase the value from the
       -- message attribute if used contains a typo
       begin
          select 1
          into validTemplate
          from WF_MESSAGES_VL
          where  NAME = t_name
            and TYPE = t_type;
       exception
          when NO_DATA_FOUND then
             wf_core.context('WF_MAIL','getTemplateName',
                             'nid => '||to_char(nid),
                             'n_status => '||n_status,
                             'n_mstatus => '||n_mStatus,
                             't_type => '||t_type,
                             't_name => '||t_name);
             wf_core.token('TYPE', t_type);
             wf_core.token('NAME', t_name);
             wf_core.raise('WFMLR_NOTEMPLATE');
       end;
    end if;

exception
   when others then
      WF_CORE.Context('WF_MAIL','getTemplateName',to_char(nid), n_status,
                      n_mstatus, t_type, t_name);
      raise;
end getTemplateName;

-- ProcessSignaturePolicy (PRIVATE) Bug 2375920
--   Processes mail message based on the signature policy requirement
--   for the notification if the notification requires a response
-- IN
--   notification id
--   signature policy for the notification
--   notification status
--   notification mail mstatus
--   access key
--   node
-- OUT
--   template name
--   template type
--   NID string
procedure ProcessSignaturePolicy(
     nid               in  number,
     n_sig_policy      in  varchar2,
     n_status          in  varchar2,
     n_mstatus         in  varchar2,
     n_key             in  varchar2,
     node              in  varchar2,
     t_type            out NOCOPY varchar2,
     t_name            out NOCOPY varchar2,
     n_nid_str         out NOCOPY varchar2)
as
  l_sec_policy   varchar2(100);
begin
   -- signature policy is DEFAULT or NULL means no password is required
   -- to respond to the notification
   t_type := 'WFMAIL';

   -- If the content is secure, just dont send anything pertaining to the notification
   -- other than the nid.
   Wf_Mail.ProcessSecurityPolicy(nid, l_sec_policy, t_name);
   if (t_name is not null) then
      n_nid_str := 'NID '||to_char(nid);
      return;
   end if;

   Wf_Notification.GetSignatureRequired(n_sig_policy, nid, g_sig_required,
                                        g_fwk_flavor, g_email_flavor, g_render);

   -- No signature required for this notification
   if (g_sig_required = 'N') then
      getTemplateName(nid, n_status, n_mstatus, t_type, t_name);

      if (g_moreinfo = 'SUB' and n_mstatus in ('MAIL','INVALID')) then
         n_nid_str := 'NID['||to_char(nid)||'/'||n_key||'@'||node||']'||'[4]';
         return;
      end if;


      -- construct the NID string for the notification
      if (wf_mail.direct_response) then
         n_nid_str := 'NID['||to_char(nid)||'/'||n_key||'@'||node||']'||'[2]';
      else
         n_nid_str := 'NID['||to_char(nid)||'/'||n_key||'@'||node||']';
      end if;
   elsif (g_sig_required = 'Y') then
      -- OPEN_SIGN is for warning that email response will not be processed
      -- for notifications requiring password signature
      if (n_status = 'OPEN') then
         if (n_mstatus = 'INVALID') then
            t_name := 'OPEN_SIGN';
         else
            -- Template to inform the user that the ntf requires a signature
            -- ** not sure if signing through email will be supported in future **
            t_name := 'OPEN_MAIL_SIGNATURE';
         end if;
     else
         t_name := n_status;
     end if;
     n_nid_str := 'NID ' || to_char(nid);
   else
     wf_core.token('NID', to_char(nid));
     wf_core.token('POLICY', n_sig_policy);
     wf_core.raise('WFMLR_INVALID_SIG_POLICY');
   end if;

exception
  when others then
    wf_core.context('WF_MAIL', 'ProcessSignaturePolicy', to_char(nid));
    raise;
end ProcessSignaturePolicy;

-- Returns TRUE if the language is Bi directional
-- Provided as a function to centralise the management of determining
-- the direction for the text.
function isBiDi(lang in varchar2) return boolean
is
begin
   if upper(lang) in ('ARABIC','HEBREW') then
       return true;
   else
       return false;
   end if;
end isBiDi;

-- Gets the table of header attributes to be
-- displayed before the body
-- Introduced with BUG 2659681
-- IN
-- nid - Notification ID
-- notification_pref The document type to be displayed
procedure GetHeaderTable(document_id in varchar2,
                         display_type in varchar2,
                         document in out NOCOPY varchar2,
                         document_type in out NOCOPY varchar2)
is
   cursor headers(nid in Number) is
   select WMA.NAME
   from WF_MESSAGE_ATTRIBUTES_VL WMA,
        WF_NOTIFICATION_ATTRIBUTES WNA,
        WF_NOTIFICATIONS WN
   where WNA.NOTIFICATION_ID = nid
     and WN.NOTIFICATION_ID = WNA.NOTIFICATION_ID
     and WN.MESSAGE_TYPE = WMA.MESSAGE_TYPE
     and WN.MESSAGE_NAME = WMA.MESSAGE_NAME
     and WMA.NAME = WNA.NAME
     and WMA.NAME like '#HDR%'
     and (WNA.TEXT_VALUE is not null OR
          WNA.NUMBER_VALUE is not null OR
          WNA.DATE_VALUE is not null)
   order by WMA.SEQUENCE;

   nid number;
   attrList varchar2(4000);
   cells wf_notification.tdType;
   j pls_integer;
   pos pls_integer;
   language varchar2(30);
   headerTable varchar2(32000);
   l_dir varchar2(2);
   l_dirAttr varchar2(10);

   l_due_date  date;
   l_from_user varchar2(360);
begin

   pos := instrb(document_id, ':',1);
   language := substrb(document_id, 1, pos-1);
   nid := to_number(substrb(document_id, pos+1));
   if isBiDi(language) then
      l_dir := 'R';
      l_dirAttr := 'dir="RTL"';
   else
      l_dir := 'L';
      l_dirAttr := NULL;
   end if;

   begin
     SELECT due_date, from_user
     INTO   l_due_date, l_from_user
     FROM   wf_notifications
     WHERE  notification_id = nid;
   exception
     when no_data_found then
        wf_core.token('NID', to_char(nid));
        wf_core.raise('WFNTF_NID');
   end;

   -- Cache the values of the product notification headers.
   attrList := '';
   for header in headers(nid) loop
      attrList := attrList || header.name || ',';
   end loop;
   if length(attrList) > 0 then
      attrList := substrb(attrList,1, length(attrList)-1);
   end if;

   document := '';
   if display_type = g_ntfDocText then
      if length(attrList) > 0 then
         document := wf_notification.wf_msg_attr(nid, attrList, display_type);
      end if;
   elsif display_type = g_ntfDocHtml then
      document := '<TABLE width=100% valign="top" cellpadding="0" cellspacing="0" border="0" '||l_dirAttr||'>'||g_newLine;
      document := document || '<TR valign="top"><TD width=30%>';
      j := 1;
      if (l_from_user is not null) then
         cells(j) :=  'E:'||g_from;
         j := j + 1;
         cells(j) := 'S12:';
         j := j + 1;
         cells(j) := 'S:'||'&'||'SENDER';
         j := j + 1;
      end if;

      cells(j) :=  'E:'||g_to;
      j := j + 1;
      cells(j) := 'S12:';
      j := j + 1;
      -- sacsharm bug 2897428 fix
      -- cells(j) := 'S:'||'&'||'TO';
      cells(j) := 'S:'||'&'||'TO_DNAME';
      j := j + 1;

      cells(j) :=  'E:'||g_beginDate;
      j := j + 1;
      cells(j) := 'S12:';
      j := j + 1;
      cells(j) := 'S:'||'&'||'START_DATE';
      j := j + 1;

      if (l_due_date is not null) then
         cells(j) :=  'E:'||g_dueDate2;
         j := j + 1;
         cells(j) := 'S12:';
         j := j + 1;
         cells(j) := 'S:'||'&'||'DUE_DATE';
         j := j + 1;
      end if;

      cells(j) :=  'E:'||g_Id;
      j := j + 1;
      cells(j) := 'S12:';
      j := j + 1;
      cells(j) := 'S:'||'&'||'NOTIFICATION_ID';
      wf_notification.NTF_Table(cells => cells, col => 3, type => 'N'||l_dir,
                                rs => headerTable);

     document := document || headerTable || g_newLine;
     document := document || '</TD><TD>' || g_newLine;
      if length(attrList) > 0 then
         wf_notification.set_ntf_table_type('N');
         wf_notification.set_ntf_table_direction(l_dir);
         document := document||wf_notification.wf_msg_attr(nid, attrList, display_type);
         wf_notification.set_ntf_table_type('V');
      end if;
      document := document || '</TD></TR></TABLE>'||g_newLine;
   else
      document := '';
   end if;
   document_type := display_type;

exception
   when others then
      wf_core.context('WF_MAIL','GetHeaderTable',document_id, display_type);
      raise;
end GetHeaderTable;


-- GetMessage - get email message data
--
-- IN
--   notification id
--   mailer node name
--   web agent path
-- OUT
--   message subject
--   message body (text)
--   message body (html)
-- NOTE
-- This API was used by the C mailer which is now obsolete. This
-- procedure is now considered deprecated.
procedure GetMessage(
    nid       in  number,
    node      in  varchar2,
    agent     in  varchar2,
    replyto   in  varchar2,
    subject   out NOCOPY varchar2,
    text_body out NOCOPY varchar2,
    html_body out NOCOPY varchar2,
    body_atth out NOCOPY varchar2,
    error_result in out NOCOPY varchar2)
as
    n_status      varchar2(8);
    n_mstatus     varchar2(8);
    n_key         varchar2(80);
    n_to_role     varchar2(320);
    n_from_user   varchar2(320);  -- Bug 2094159
    n_due_date    date;
    n_start_date  date;
    n_end_date    date;
    n_priority    number;
    n_comment     varchar2(4000);
    n_subject     varchar2(2000);
    n_response    varchar2(32000);
    n_text_body   varchar2(32000);
    n_html_body   varchar2(32000);
    n_direct      varchar2(3);
    n_click_here  varchar2(4000);
    n_disp_click  varchar2(240);
    r_dname       varchar2(360);
    r_email       varchar2(2000);
    r_language    varchar2(4000);
    r_territory   varchar2(4000);
    r_ntf_pref    varchar2(240);
    t_type        varchar2(100);
    t_name        varchar2(100);
    t_subject     varchar2(240);
    t_text_body   varchar2(4000);
    t_html_body   varchar2(4000);
    t_headerText  varchar2(32000);
    n_headerText  varchar2(32000);
    n_timezone    varchar2(230);
    t_headerHTML  varchar2(32000);
    n_headerHTML  varchar2(32000);
    m_html        varchar2(32000);
    err_name      varchar2(30);
    err_message   varchar2(2000);
    err_stack     varchar2(4000);
    fyi           pls_integer;
    body_start    pls_integer;
    body_end      pls_integer;
    tag_pos       pls_integer;
    dir_pos       pls_integer;
    start_cnt     pls_integer;
    end_cnt       pls_integer;
    crpos         pls_integer;
    str_length    pls_integer;
    lnsize        pls_integer;
    temp          varchar2(32000);
    line          varchar2(32000);
    buffer        varchar2(32000);
    no_program_unit exception;
    pragma exception_init(no_program_unit, -6508);
    dummy         varchar2(4000);
    -- Bug# 2301881 variables to handle invalid response error message
    err_invalid   varchar2(1000);
    err_expected  varchar2(1000);
    -- Bug 2395898 variable to check if response attr exists
    n_response_exists varchar2(1);
    -- Bug 2375920 variables to process message based on signature
    n_sig_policy     varchar2(100);
    n_nid_str        varchar2(200);
    -- bug 2282139 more info feature
    n_more_info_role varchar2(320);
    n_mailto         varchar2(10000);
    n_html_history   varchar2(32000);
    n_text_history   varchar2(32000);
    n_last_ques      varchar2(4000);
    n_dir            varchar2(16);

begin
    -- Get notification information
    -- Bug 2094159 get from_user from wf_notifications
    begin
      select STATUS, MAIL_STATUS, ACCESS_KEY,
             RECIPIENT_ROLE, PRIORITY, USER_COMMENT,
             BEGIN_DATE, END_DATE, DUE_DATE, FROM_USER,
             MORE_INFO_ROLE
      into   n_status, n_mstatus, n_key,
             n_to_role, n_priority, n_comment,
             n_start_date, n_end_date, n_due_date, n_from_user,
             n_more_info_role
      from   WF_NOTIFICATIONS
      where  NOTIFICATION_ID = nid;
    exception
      when no_data_found then
        wf_core.token('NID', to_char(nid));
        wf_core.raise('WFNTF_NID');
    end;

    -- More information processing - bug 2282139
    g_moreinfo := NULL;

    if (wf_mail.test_flag = TRUE) then
       n_mstatus := 'MAIL';
       if (n_status not in ('OPEN','CANCELED','CLOSED')) then
          n_status := 'OPEN';
       end if;
    end if;

    -- g_to_role global variable is to identify to whom the email is addressed
    -- when contructing the More Info MAILTO, so that the role name is not displayed
    -- among the participants
    -- Timezone will not be supported in this version of the GetMessage
    -- API.
    n_timezone := '';

    if (wf_notification.HideMoreInfo(nid) = 'N') then
       if(n_more_info_role is not null) then
          n_to_role := n_more_info_role;
          g_to_role := n_more_info_role;
          g_moreinfo := 'SUB';
       else
          g_to_role := n_to_role;
          g_moreinfo := 'REQ';
       end if;
    end if;

    -- Get Recipient information
    Wf_Directory.GetRoleInfo(n_to_role, r_dname, r_email, r_ntf_pref,
                             r_language, r_territory);
    r_ntf_pref := nvl(r_ntf_pref, 'QUERY');

    wf_notification.GetComments(nid, g_ntfDocText,
                                n_text_history, n_last_ques);
    wf_notification.GetComments(nid, g_ntfDocHtml,
                                n_html_history, n_last_ques);
    if n_text_history is not null or n_text_history <> '' then
       if isBiDi(r_language) then
          n_text_history := n_text_history||' '|| g_ntfHistory;
       else
          n_text_history := g_ntfHistory||' '|| n_text_history;
       end if;
    end if;
    if n_html_history is not null or n_html_history <> '' then
       if isBiDi(r_language) then
          n_dir := 'dir="rtl" ';
       else
          n_dir := '';
       end if;

       n_html_history := '<table '||n_dir||
                         'bgcolor="'||table_bgcolor||'" width="'||
                         table_width||'" cellpadding="'||
                         table_cellpadding||'" cellspacing="'||
                         table_cellspacing||'" >'||
                         '<tr valign="top"><td width="10%">'||
                         '<font face="'||
                         td_fontface||'" size="'||td_fontsize||'" >'||
                         g_ntfHistory||
                         '</font></td><td>'|| n_html_history ||
                         '</td></tr></table>'||g_newLine;
    end if;

    -- Bug 2375920 get signature policy for the notification
    Wf_Mail.GetSignaturePolicy(nid, n_sig_policy);

    n_subject := WF_NOTIFICATION.GetSubject(nid, 'text/plain');

    -- We will always fetch plain text version of the message because
    -- Because for sendmail MAILATTH case, we need to send out html message
    -- body as attachment and then the plain text message as the body.
    -- For MAPI MAILATTH and MAILHTML cases, same thing.
    if isBiDi(r_language) then
       WF_NOTIFICATION.Set_NTF_Table_Direction('R');
    else
       WF_NOTIFICATION.Set_NTF_Table_Direction('L');
    end if;

    n_text_body := WF_NOTIFICATION.GetBody(nid, g_ntfDocText);

    GetHeaderTable(r_language||':'||to_char(nid), g_ntfDocText,
                   t_headerText, dummy);

    if r_ntf_pref in ('MAILHTML', 'MAILATTH', 'MAILHTML2') then
        n_html_body := WF_NOTIFICATION.GetBody(nid, g_ntfDocHtml);
        GetHeaderTable(r_language||':'||to_char(nid),
                        g_ntfDocHtml, t_headerHTML, dummy);

        -- Extracts content between <BODY> and </BODY> if there is body tag
        -- This is to deal with people import the whole html file to the
        -- html message body through the builder.
        -- The logic here is that if we don't see <BODY> and </BODY>, then
        -- this is already just a html <BODY> portion. Otherwise, extract
        -- the content in between <BODY> and </BODY>.
        body_start := 0;
        body_start := instr(upper(n_html_body), '<BODY>');
        if (body_start <> 0) then
            body_start := body_start + length('<BODY>');
            body_end := instr(upper(n_html_body), '</BODY>');
            if (body_end = 0) then
                body_end := length(n_html_body);
            else
                body_end := body_end - 1;
            end if;
            n_html_body := substr(n_html_body, body_start, body_end);
        end if;
        --
        -- For every 900 character, we insert a newline just in case
        -- Because this whole message body may go out to the Unix SMTP gateway
        -- which does not like a line longer than 1000 characters.
        -- We do it 900 here just for safty.
        -- 2001/03/23 Changed algorithm to start at 900 point and then
        -- move to the nearest whitespace.
        --
        lnsize := 900;
        start_cnt := 1;
        end_cnt := lnsize;
        temp := '';
        str_length := length(n_html_body);
        while start_cnt < str_length loop
           -- use the existing newlines as a natural break
           crpos := instr(n_html_body, g_newLine, start_cnt+1, 1) -
                        start_cnt;
           if crpos > 0 and crpos < end_cnt then
              end_cnt := crpos;
           else

              -- Move forward to the next white space.
              while (start_cnt + end_cnt < str_length) and
                    substr(n_html_body, start_cnt + end_cnt, 1) not in
                    (' ', g_newLine, g_tab)
                    and end_cnt < 999 loop
                 end_cnt := end_cnt + 1;
              end loop;

              -- We need to understand the full conditions underwhich
              -- the previous loop exited. All characters must be preserved
              -- and the line, no matter what can not exceed 900 characters.

              if end_cnt >= (999) then
                end_cnt := lnsize;
                while (start_cnt + end_cnt > start_cnt) and
                    substr(n_html_body, start_cnt + end_cnt, 1) not in
                          (' ', g_newLine, g_tab)
                    and end_cnt > 0 loop
                   end_cnt := end_cnt - 1;
                end loop;
                -- If we can not locate a white space, then use the default
                if end_cnt <= 0 then
                   end_cnt := lnsize;
                end if;
              end if;
           end if;

           -- Ensure the last characters are not lost.
           if start_cnt + end_cnt >= str_length then
              line := substr(n_html_body, start_cnt);
           else
              line := substr(n_html_body, start_cnt, end_cnt);
           end if;

           temp := temp || line;

           -- If there is a newline at this point,
           -- then do not bother with another.
           if substr(n_html_body, start_cnt + end_cnt, 1) <>
                     g_newLIne then
              temp := temp||g_newLine;
           end if;

           -- We do not want to start the new line with the space.
           if substr(n_html_body, start_cnt + end_cnt, 1) = ' ' then
              start_cnt := start_cnt + end_cnt + 1;
           else
              start_cnt := start_cnt + end_cnt;
           end if;
           end_cnt := lnsize;
        end loop;

        n_html_body := temp;

    end if;

    -- Bug 2375920 Process the email message based on the signature policy
    ProcessSignaturePolicy(nid, n_sig_policy, n_status, n_mstatus,
                           n_key, node, t_type, t_name, n_nid_str);

    -- Get template
    begin
      select SUBJECT, BODY, HTML_BODY
      into   t_subject, t_text_body, t_html_body
      from   WF_MESSAGES_VL
      where  NAME = t_name and TYPE = t_type;
    exception
      when no_data_found then
        wf_core.token('NAME', t_name);
        wf_core.token('TYPE', t_type);
        wf_core.raise('WFNTF_MESSAGE');
    end;

    -- Get Click here Response display value
    begin
      select DESCRIPTION
        into n_disp_click
        from WF_MESSAGE_ATTRIBUTES_TL
       where MESSAGE_TYPE = t_type
         and MESSAGE_NAME = t_name
         and NAME = 'CLICK_HERE_RESPONSE'
         and LANGUAGE = userenv('LANG');
    exception
      when NO_DATA_FOUND then
        -- ignore if this attribute does not exist
        null;
    end;

    -- Retrieve errror attributes for INVALID message
    if (t_name = 'OPEN_INVALID') then
      begin
        err_name := Wf_Notification.GetAttrText(nid, 'MAIL_ERROR_NAME');
        err_message := Wf_Notification.GetAttrText(nid, 'MAIL_ERROR_MESSAGE');
        err_invalid := Wf_Notification.GetAttrText(nid, 'MAIL_VALUE_FOUND');
        err_expected := Wf_Notification.GetAttrText(nid, 'MAIL_EXP_VALUES');
      exception
        when others then null;
      end;
    end if;

    -- If there is no html template available, use the plain text one.
    if (t_html_body is null) then
      t_html_body := replace(t_text_body, g_newLine,
                             '<BR>'||g_newLine);
      -- Ensure the direction of the text is correct for the language
      if isBiDi(r_language) then
         t_html_body := '<HTML DIR="RTL"><BODY>'||t_html_body;
      else
         t_html_body := '<HTML><BODY>'||t_html_body;
      end if;
    else
      -- Ensure that the direction of the text is correctly specified.
      if isBiDi(r_language) then
         tag_pos := instrb(upper(t_html_body), '<HTML', 1);
         if tag_pos > 0 then
           dir_pos := instrb(upper(t_html_body), ' DIR="', 1);
           if dir_pos = 0 then
              buffer := substrb(t_html_body, 1, 5);
              buffer := buffer||' DIR="RTL" '||substrb(t_html_body, tag_pos+5);
              t_html_body := buffer;
           end if;
         end if;
      end if;
    end if;

    -- Substitute
    if wf_mail.direct_response then
       n_direct := '[2]';
    else
       n_direct := NULL;
    end if;

    -- Bug# 2301881 replacing err_stack with err_invalid and err_expected
    -- to make the WARNING message to the responder more user-friendly
    n_subject := Substitute(t_subject, nid, n_nid_str,
                            n_status, n_to_role, r_dname, r_email,
                            n_start_date, n_due_date, n_end_date, n_from_user,
                            n_priority, n_comment, n_subject, dummy,
                            dummy, err_name, err_message, err_invalid,
                            err_expected, n_timezone);
    n_headerText := Substitute(t_headerText, nid, n_nid_str,
                            n_status, n_to_role, r_dname, r_email,
                            n_start_date, n_due_date, n_end_date, n_from_user,
                            n_priority, n_comment, n_subject, dummy,
                            dummy, err_name, err_message, err_invalid,
                            err_expected, n_timezone);
    n_headerHTML := Substitute(t_headerText, nid, n_nid_str,
                            n_status, n_to_role, r_dname, r_email,
                            n_start_date, n_due_date, n_end_date, n_from_user,
                            n_priority, n_comment, n_subject, dummy,
                            dummy, err_name, err_message, err_invalid,
                            err_expected, n_timezone);
    n_text_body    := Substitute(t_text_body, nid, n_nid_str,
                            n_status, n_to_role, r_dname, r_email,
                            n_start_date, n_due_date, n_end_date, n_from_user,
                            n_priority, n_comment, n_subject, n_headerText,
                            n_text_body, err_name, err_message, err_invalid,
                            err_expected, n_timezone);
    n_html_body    := Substitute(t_html_body, nid, n_nid_str,
                            n_status, n_to_role, r_dname, r_email,
                            n_start_date, n_due_date, n_end_date, n_from_user,
                            n_priority, n_comment,
                            UrlEncode(n_subject), n_headerHTML, n_html_body,
                            err_name, err_message, err_invalid,
                            err_expected, n_timezone);

    -- Wrap the body into nice pretty lines.
    if (r_ntf_pref in ('MAILTEXT', 'MAILATTH')) then
        n_text_body := WordWrap(n_text_body, 0);
    end if;

    if (g_moreinfo = 'SUB') then
       n_response := g_moreInfoAPrompt || ': "<' ||
                     g_moreInfoAnswer ||'>"';
       n_response := n_response || g_newLine;
    else
       if wf_mail.direct_response then
          n_response :=  GetEmailDirectResponse(nid);
       else
          n_response :=  GetEmailResponse(nid);
       end if;
    end if;

    -- make sure total length will not exceed 32K
    -- if it does truncate the body, leaving room for truncation string
    if (length(n_text_body) + length(n_response)) > 32000 then
      n_text_body := substr(n_text_body, 1, 31900  - length(n_response))
                ||g_newLine|| g_truncate;
    end if;


    -- Add email response section
    if instr(n_text_body,'&'||'RESPONSE')> 0 then
       n_text_body := substrb(replace(n_text_body, '&'||'RESPONSE', n_response),
                     1, 32000);
    else
      --  Fix for bug 2395898 - do not append the response when no token
      --  Check to see if the response is included in the template
          begin
              select 'Y'
              into n_response_exists
              from WF_MESSAGES_VL
              where NAME = t_name and TYPE = 'WFMAIL'
              and instr(body,'&'||'RESPONSE')<>0;
           exception
              when no_data_found then
                 n_response_exists := 'N';
           end;

       -- we must have truncated the token, so just append the response
        if (n_response_exists = 'Y') then
              n_text_body := n_text_body||n_response;
        end if;
      end if;

    -- repeat for html body
    if (length(n_html_body) + length(n_response)) > 32000 then
      n_html_body := substr(n_html_body, 1, 31900  - length(n_response))
                ||g_newLine||
                g_truncate;
    end if;

    -- Add email response section
    if instr(n_html_body,'&'||'RESPONSE')> 0 then
       n_html_body := substrb(replace(n_html_body, '&'||'RESPONSE', n_response),
                     1, 32000);
    end if;

    -- More Information processing - adding history of questions and answers
    -- to outbound notifications
    if instr(n_html_body,'&'||'QUESTION')> 0 then
       n_html_body := substrb(replace(n_html_body, '&'||'QUESTION', n_last_ques),
                     1, 32000);
    end if;
    if instr(n_text_body,'&'||'QUESTION')> 0 then
       n_text_body := substrb(replace(n_text_body, '&'||'QUESTION', n_last_ques),
                     1, 32000);
    end if;
    if instr(n_html_body,'&'||'HISTORY')> 0 then
       n_html_body := substrb(replace(n_html_body, '&'||'HISTORY', n_html_history),
                     1, 32000);
    end if;
    if instr(n_text_body,'&'||'HISTORY')> 0 then
       n_text_body := substrb(replace(n_text_body, '&'||'HISTORY', n_text_history),
                     1, 32000);
    end if;

    -- Add mailto section
    -- when template used is OPEN_MOREINFO, providing a template to submit
    -- more information
    if (g_moreinfo = 'SUB') then
       n_mailto := GetMoreInfoMailTo(nid, 'NID['||to_char(nid)||'/'||n_key
                                    ||'@'||node||']',replyto, n_subject);
    else
       n_mailto := GetMailTo(nid, 'NID['||to_char(nid)||'/'||n_key||'@'||node||']',
                             replyto, n_subject);
    end if;
    n_html_body := substrb(replace(n_html_body, '&'||'MAILTO', n_mailto), 1, 32000);

    -- Add click_here_response section
    n_click_here := '<A class="OraLink" HREF="';
    if (agent is null) then
       if wf_mail.send_accesskey then
          n_click_here := n_click_here||g_webAgent
                          ||'/WFA_HTML.DetailLink?nid='||to_char(nid)
                          ||'&'||'nkey='||n_key
                          ||'&'||'agent='||g_webAgent;
       else
          n_click_here := n_click_here||g_webAgent
                          ||'/'||wfa_sec.DirectLogin(nid);
       end if;
    else
       if wf_mail.send_accesskey then
          n_click_here := n_click_here||agent
                          ||'/WFA_HTML.DetailLink?nid='||to_char(nid)
                          ||'&'||'nkey='||n_key
                          ||'&'||'agent='||agent;
       else
          n_click_here := n_click_here||agent
                          ||'/'||wfa_sec.DirectLogin(nid);
       end if;
    end if;
    n_click_here := n_click_here||'">'||n_disp_click||'</A>';

    n_html_body := substrb(replace(n_html_body, '&'||'CLICK_HERE_RESPONSE',
                            n_click_here), 1, 32000);

    -- Get HTML attachment
    if (agent is null) then
       m_html := substrb(WFA_HTML.Detail2(nid, n_key, g_webAgent), 1, 32000);
    else
         m_html := substrb(WFA_HTML.Detail2(nid, n_key, agent), 1, 32000);
    end if;

     if isBiDi(r_language) then
        tag_pos := instrb(upper(m_html), '<HTML', 1);
        if tag_pos > 0 then
          dir_pos := instrb(upper(m_html), ' DIR="', 1);
          if dir_pos = 0 then
             buffer := substrb(m_html, 1, 5);
             buffer := buffer||' DIR="RTL" '||substrb(m_html, tag_pos+5);
             m_html := buffer;
          end if;
        end if;
     end if;

     -- Close of the HTML Body only where this is none
     if instr(n_html_body, '</BODY>') = 0 then
        n_html_body := n_html_body || '</BODY></HTML>';
     end if;


    subject   := n_subject;
    text_body := n_text_body;
    html_body := n_html_body;
    -- this is for the little attachment to the detail frame
    body_atth := m_html;

exception
  when no_program_unit then
    wf_core.context('WF_MAIL', 'GetMessage', to_char(nid), node);
    raise;
  when others then
    -- First look for a wf_core error.
    wf_core.get_error(err_name, err_message, err_stack);

    -- If no wf_core error look for a sql error.
    if (err_name is null) then
        err_message := sqlerrm;
    end if;

    error_result := err_message||g_newLine||err_stack;
    wf_core.context('WF_MAIL', 'GetMessage', to_char(nid), node, error_result);

end GetMessage;

-- LOBReplace
-- To replace the given token in message with the token value
-- IN
-- message The CLOB message containing the tokens
-- token   The varchar token, complete with '&' prefix
-- tokenValue The varchar value to substitute for the token
-- append The boolean flag to say if the token was NOT found, then
--        append the tokenValue regardless
--
procedure LOBReplace(message IN OUT NOCOPY CLOB,
                     token IN VARCHAR2,
                     tokenValue IN VARCHAR2,
                     append IN BOOLEAN)
is
  -- temp CLOB;
  tempIdx pls_integer;
  pos NUMBER;
  msgLen NUMBER;
  amount  NUMBER;

  continue boolean;
  offset number;
  sourcePos number;
  targetPos number;
  tokenLen pls_integer;

  nextChar varchar2(10);
  validToken boolean;
  xSet varchar2(100) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'||
                        '0123456789_';
  tokenFound boolean;

begin

   -- DBMS_LOB.CreateTemporary(temp, TRUE, DBMS_LOB.CALL);
   tempIdx := -1;

   offset := 1;
   sourcePos := 1;
   targetPos := 1;
   continue := TRUE;
   msgLen := DBMS_LOB.GetLength(message);
   tokenLen := length(token);
   tokenFound := FALSE;

   while continue
   loop

      pos := DBMS_LOB.Instr(message, token, offset, 1);
      if (pos <> 0) then
         if (pos + tokenLen <= msgLen) then
            nextChar := upper(dbms_lob.substr(message, 1, pos + tokenLen));
            if (instr(xSet, nextChar,1,1) > 0) then
               validToken := false;
            else
               validToken := true;
            end if;
         else
            validToken := true;
         end if;
      else
         validToken := false;
         continue := FALSE;
      end if;

      if continue then
         if validToken then
            -- Only request a LOB if it is necessary and only if one
            -- has not already been requested.
            if tempIdx = -1 then
               tempIdx := wf_temp_lob.getLob(g_LOBTable);
            end if;
            amount := pos - sourcePos;
            DBMS_LOB.Copy(dest_lob => g_LOBTable(tempIdx).temp_lob,
                          src_lob => message,
                          amount => amount,
                          dest_offset => targetPos,
                          src_offset => sourcePos);
            if (tokenValue <> '' or tokenValue is not null) then
               DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob,
                                    length(tokenValue), tokenValue);
            end if;
            sourcePos := pos + tokenLen;
            targetPos := DBMS_LOB.GetLength(g_LOBTable(tempIdx).temp_lob) + 1;
            tokenFound := TRUE;
         end if;
         offset := pos + tokenLen;
      else
         amount := msgLen - sourcePos +1;
         if (amount > 0)then
            if tempIdx = -1 then
               tempIdx := wf_temp_lob.getLob(g_LOBTable);
            end if;
            DBMS_LOB.Copy(g_LOBTable(tempIdx).temp_lob, message, amount,
                          targetPos, sourcePos);
         end if;

         if (append and tokenFound = FALSE and msgLen > 0) then
            if (tokenValue <> '' or tokenValue is not null) then
               if tempIdx = -1 then
                  tempIdx := wf_temp_lob.getLob(g_LOBTable);
               end if;
               DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob,
                                    length(tokenValue), tokenValue);
            end if;
         end if;
      end if; -- CONTINUE

   end loop;

   if tokenFound = TRUE then
      msgLen := DBMS_LOB.GetLength(g_LOBTable(tempIdx).temp_lob);
      DBMS_LOB.Trim(message, 0);
      DBMS_LOB.Copy(message, g_LOBTable(tempIdx).temp_lob, msgLen);
   end if;
   if tempIdx = -1 then
      wf_temp_lob.releaseLob(g_LOBTable, tempIdx);
   end if;

exception
   when others then
      wf_temp_lob.releaseLob(g_LOBTable, tempIdx);
      WF_CORE.Context('WF_MAIL','LOBReplace',token,
                      tokenValue);
      raise;

end LOBReplace;

-- LOBReplace
-- To replace the given token in message with the token value
-- IN
-- message The CLOB message containing the tokens
-- token   The varchar token, complete with '&' prefix
-- tokenValue The CLOB value to substitute for the token
-- append The boolean flag to say if the token was NOT found, then
--        append the tokenValue regardless
--
procedure LOBReplace(message IN OUT NOCOPY CLOB,
                     token IN VARCHAR2,
                     tokenValue IN OUT NOCOPY CLOB,
                     append IN BOOLEAN)
is
  -- temp CLOB;
  tempIdx pls_integer;
  pos NUMBER;
  msgLen NUMBER;
  amount NUMBER;
  tokenValueLen number;

  continue boolean;
  offset number;
  sourcePos number;
  targetPos number;
  tokenLen pls_integer;

  nextChar varchar2(10);
  validToken boolean;
  xSet varchar2(100) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'||
                        '0123456789_';
  tokenFound boolean;

begin
   -- DBMS_LOB.CreateTemporary(temp, FALSE, DBMS_LOB.CALL);
   tempIdx := wf_temp_lob.getLob(g_LOBTable);

   offset := 1;
   sourcePos := 1;
   targetPos := 1;
   continue := TRUE;
   msgLen := DBMS_LOB.GetLength(message);
   tokenLen := length(token);
   tokenFound := FALSE;

   while continue
   loop
      pos := DBMS_LOB.Instr(message, token, offset, 1);

      if pos <> 0 then
         if (pos + tokenLen <= msgLen) then
            nextChar := upper(dbms_lob.substr(message, 1, pos + tokenLen));
            if (instr(xSet, nextChar,1,1) > 0) then
               validToken := false;
            else
               validToken := true;
            end if;
         else
            validToken := true;
         end if;
      else
         validToken := false;
         continue := FALSE;
      end if;

      if continue then
         if validToken then
            amount := pos - sourcePos;
            DBMS_LOB.Copy(g_LOBTable(tempIdx).temp_lob, message, amount,
                          targetPos, sourcePos);
            tokenValueLen := DBMS_LOB.GetLength(tokenValue);
            if (tokenValueLen > 0) then
               DBMS_LOB.Append(g_LOBTable(tempIdx).temp_lob, tokenValue);
            end if;
            sourcePos := pos + tokenLen;
            targetPos := DBMS_LOB.GetLength(g_LOBTable(tempIdx).temp_lob) + 1;
            tokenFound := TRUE;
         end if;
         offset := pos + tokenLen;
      else
         amount := msgLen - sourcePos + 1;
         if (amount > 0) then
            DBMS_LOB.Copy(g_LOBTable(tempIdx).temp_lob, message, amount,
                          targetPos, sourcePos);
         end if;

         if (append and tokenFound = FALSE and msgLen > 0) then
            tokenValueLen := DBMS_LOB.GetLength(tokenValue);
            if tokenValueLen <> 0 then
               DBMS_LOB.Append(g_LOBTable(tempIdx).temp_lob, tokenValue);
            end if;
         end if;
      end if;
   end loop;

   if tokenFound then
      msgLen := DBMS_LOB.GetLength(g_LOBTable(tempIdx).temp_lob);
      DBMS_LOB.Trim(message, 0);
      DBMS_LOB.Copy(message, g_LOBTable(tempIdx).temp_lob, msgLen);
   end if;
   wf_temp_lob.releaseLob(g_LOBTable, tempIdx);

exception
   when others then
      wf_temp_lob.releaseLob(g_LOBTable, tempIdx);
      WF_CORE.Context('WF_MAIL','LOBReplace',token, 'LOB');
      raise;

end LOBReplace;

-- LOBSubstitute
--   Template contains a max length of 4000 only. We require only a varchar2.
-- IN
-- template IN OUT NOCOPY VARCHAR2,
-- n_nid IN NUMBER,
-- n_code IN VARCHAR2,
-- n_status IN VARCHAR2,
-- n_to_role IN VARCHAR2,
-- r_dName IN VARCHAR2,
-- r_email IN VARCHAR2,
-- n_start_Date IN DATE,
-- n_due_Date IN DATE,
-- n_end_Date IN DATE,
-- n_from_user IN VARCHAR2,
-- n_priority IN VARCHAR2,
-- n_comment IN VARCHAR2,
-- m_subject IN VARCHAR2,
-- m_body IN OUT NOCOPY CLOB,
-- err_Name IN OUT NOCOPY VARCHAR2,
-- err_Message IN OUT NOCOPY VARCHAR2,
-- err_Stack IN OUT NOCOPY VARCHAR2,
-- n_timezone IN VARCHAR2)
procedure LOBSubstitute(template IN OUT NOCOPY VARCHAR2,
                        n_nid IN NUMBER,
                        n_code IN VARCHAR2,
                        n_status IN VARCHAR2,
                        n_to_role IN VARCHAR2,
                        r_dName IN VARCHAR2,
                        r_email IN VARCHAR2,
                        n_start_Date IN DATE,
                        n_due_Date IN DATE,
                        n_end_Date IN DATE,
                        n_from_user IN VARCHAR2,
                        n_priority IN VARCHAR2,
                        n_comment IN VARCHAR2,
                        m_subject IN VARCHAR2,
                        m_header IN VARCHAR2,
                        m_body IN OUT NOCOPY CLOB,
                        err_Name IN OUT NOCOPY VARCHAR2,
                        err_Message IN OUT NOCOPY VARCHAR2,
                        err_Invalid IN OUT NOCOPY VARCHAR2,
                        err_Expected IN OUT NOCOPY VARCHAR2,
                        n_timezone IN VARCHAR2)
is
    -- temp          CLOB;
    tempIdx       pls_integer;
    tempPos       NUMBER := 0;
    pos           NUMBER := 0;
    amper         NUMBER := 0;

    msgLen        NUMBER := 0;
    tknSize       NUMBER := 0;

    tokenName     VARCHAR2(60);
    tokenMatch    BOOLEAN;

    n_due_date_text varchar2(50);
    n_start_date_text varchar2(50);
    n_priority_text varchar2(240);
    n_nidStr varchar2(50);

    eot NUMBER;

begin

    -- BLAF requriement to display the date with TIME elelment
    n_due_date_text := to_char(n_due_date, Wf_Notification.g_nls_date_mask);
    n_start_date_text := to_char(n_start_date, Wf_Notification.g_nls_date_mask);

    if (n_priority > 66) then
      --Bug 2774891 fix - sacsharm
      --n_priority_text := wf_core.substitute('WFTKN', 'HIGH');
      n_priority_text := wf_core.substitute('WFTKN', 'LOW');
    elsif (n_priority > 33) then
      n_priority_text := wf_core.substitute('WFTKN', 'NORMAL');
    else
      --Bug 2774891 fix - sacsharm
      --n_priority_text := wf_core.substitute('WFTKN', 'LOW');
      n_priority_text := wf_core.substitute('WFTKN', 'HIGH');
    end if;

    -- DBMS_LOB.CreateTemporary(temp, TRUE, DBMS_LOB.SESSION);
    -- DBMS_LOB.Open(temp, DBMS_LOB.LOB_READWRITE);
    tempIdx := wf_temp_lob.getLob(g_LOBTable);

    pos := 1;
    tempPos := 1;
    msgLen := length(template);
    while pos < msgLen loop
       -- Locate each instance of an ampersand and assume it is
       -- a token reference.
       amper := instr(template, '&', pos, 1);

       if amper = 0 then
          -- No ampers left. so write the rest of the CLOB
          if pos < msgLen then
             -- DBMS_LOB.Copy(temp, template, (msgLen - pos)+1, tempPos, pos);
             DBMS_LOB.Write(g_LOBTable(tempIdx).temp_lob, (msgLen - pos)+1, tempPos,
                               substr(template, pos, (msgLen - pos)+1));
          end if;
          EXIT;
       end if;

       -- Now we have the position of the amper, workout what
       -- token it is, if any.

       -- write from the last pos to the new token.
       if amper > pos then
          -- DBMS_LOB.Copy(temp, template, (amper - pos), tempPos, pos);
          DBMS_LOB.Write(g_LOBTable(tempIdx).temp_lob, (amper - pos), tempPos,
                             substr(template, pos, (amper - pos)));
          tempPos := tempPos + ((amper - pos));
       end if;
       pos := amper + 1;

       eot := amper;
       while ((eot <= msgLen) and
          (substr(template, eot, 1) not in (' ', g_newLine, g_tab))) loop
          eot := eot +1;
       end loop;

       tknSize := (eot - amper) - 1;
       tokenName := substr(template, amper+1, tknSize);

       tokenMatch := FALSE;
       if instr(tokenName,'NOTIFICATION_ID',1,1)=1 then
          n_nidStr := to_char(n_nid);
          if n_nidStr is not null then
             -- DBMS_LOB.WriteAppend(temp, length(n_nidStr), n_nidStr);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, length(n_nidStr),
                                  n_nidStr);
             tempPos := tempPos + length(n_nidStr);
          end if;
          pos := amper + length('NOTIFICATION_ID') + 1;
          tokenMatch := TRUE;
       end if;
       if instr(tokenName,'NOTIFICATION',1,1)=1 then
          if n_code is not null then
             -- DBMS_LOB.WriteAppend(temp, length(n_code), n_code);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, length(n_code),
                                  n_code);
             tempPos := tempPos + length(n_code);
          end if;
          pos := amper + length('NOTIFICATION') + 1;
          tokenMatch := TRUE;
       end if;
       if instr(tokenName,'STATUS',1,1)=1 then
          if n_status is not null then
             -- DBMS_LOB.WriteAppend(temp, length(n_status), n_status);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, length(n_status), n_status);
             tempPos := tempPos + length(n_status);
          end if;
          pos := amper + length('STATUS') + 1;
          tokenMatch := TRUE;
       end if;
       if instr(tokenName, 'TO_DNAME', 1, 1)=1 then
          if r_dname is not null then
             -- DBMS_LOB.WriteAppend(temp, length(r_dname), r_dname);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, length(r_dname), r_dname);
             tempPos := tempPos + length(r_dname);
          end if;
          pos := amper + length('TO_DNAME') + 1;
          tokenMatch := TRUE;
       end if;
       if instr(tokenName, 'TO_EMAIL', 1, 1)=1 then
          if r_email is not null then
             -- DBMS_LOB.WriteAppend(temp, length(r_email), r_email);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, length(r_email), r_email);
             tempPos := tempPos + length(r_email);
          end if;
          pos := amper + length('TO_EMAIL') + 1;
          tokenMatch := TRUE;
       end if;
       if instr(tokenName,'TO',1,1)=1 then
          if n_to_role is not null then
             -- DBMS_LOB.WriteAppend(temp, length(n_to_role), n_to_role);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, length(n_to_role), n_to_role);
             tempPos := tempPos + length(n_to_role);
          end if;
          pos := amper + length('TO') + 1;
          tokenMatch := TRUE;
       end if;
       if instr(tokenName, 'PRIORITY', 1, 1)=1 then
          if n_priority_text is not null then
             -- DBMS_LOB.WriteAppend(temp, length(n_priority_text), n_priority_text);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, length(n_priority_text),
                                  n_priority_text);
             tempPos := tempPos + length(n_priority_text);
          end if;
          pos := amper + length('PRIORITY') + 1;
          tokenMatch := TRUE;
       end if;
       if instr(tokenName, 'START_DATE', 1, 1)=1 then
          if n_start_date is not null then
             -- DBMS_LOB.WriteAppend(temp, length(n_start_date), n_start_date);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob,
                                  length(n_start_date_text), n_start_date_text);
             tempPos := tempPos + length(n_start_date_text);
          end if;
          pos := amper + length('START_DATE') + 1;
          tokenMatch := TRUE;
       end if;
       if instr(tokenName, 'DUE_DATE', 1, 1)=1 then
          if n_due_date is not null then
             -- DBMS_LOB.WriteAppend(temp, length(n_due_date_text), n_due_date_text);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, length(n_due_date_text),
                                  n_due_date_text);
             tempPos := tempPos + length(n_due_date_text);
          end if;
          pos := amper + length('DUE_DATE') + 1;
          tokenMatch := TRUE;
       end if;
       if instr(tokenName, 'END_DATE', 1, 1)=1 then
          if n_end_date is not null then
             -- DBMS_LOB.WriteAppend(temp, length(n_end_date), n_end_date);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, length(n_end_date),
                                  n_end_date);
             tempPos := tempPos + length(n_end_date);
          end if;
          pos := amper + length('END_DATE') + 1;
          tokenMatch := TRUE;
       end if;
       if instr(tokenName, 'SENDER', 1, 1)=1 then
          if n_from_user is not null then
             -- DBMS_LOB.WriteAppend(temp, length(n_from_user), n_from_user);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, length(n_from_user),
                                  n_from_user);
             tempPos := tempPos + length(n_from_user);
          end if;
          pos := amper + length('SENDER') + 1;
          tokenMatch := TRUE;
       end if;
       if instr(tokenName, 'COMMENT', 1, 1)=1 then
         if n_comment is not null then
            -- DBMS_LOB.WriteAppend(temp, length(n_comment), n_comment);
            DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob,
                                length(n_comment), n_comment);
            tempPos := tempPos + length(n_comment);
         end if;
         pos := amper + length('COMMENT') + 1;
         tokenMatch := TRUE;
       end if;
       if instr(tokenName, 'TIMEZONE', 1, 1)=1 then
          if n_timezone is not null then
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob,
                                  length(n_timezone), n_timezone);
             tempPos := tempPos + length(n_timezone);
          end if;
          pos := amper + length('TIMEZONE') + 1;
          tokenMatch := TRUE;
       end if;
       if instr(tokenName, 'SUBJECT', 1, 1)=1 then
          if m_subject is not null then
             -- DBMS_LOB.WriteAppend(temp, length(m_subject), m_subject);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, length(m_subject), m_subject);
             tempPos := tempPos + length(m_subject);
          end if;
          pos := amper + length('SUBJECT') + 1;
          tokenMatch := TRUE;
       end if;
       if instr(tokenName, 'HEADER', 1, 1)=1 then
          if m_header is not null then
             --DBMS_LOB.WriteAppend(temp, length(m_header), m_header);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, length(m_header), m_header);
             tempPos := tempPos + length(m_header);
          end if;
          pos := amper + length('HEADER') + 1;
          tokenMatch := TRUE;
       end if;
       if instr(tokenName, 'BODY', 1, 1)=1 then
          if (m_body is not null and dbms_lob.getLength(m_body) > 0) or not g_isFwkNtf then
             DBMS_LOB.Append(g_LOBTable(tempIdx).temp_lob, m_body);
             tempPos := tempPos + DBMS_LOB.GetLength(m_body);
             pos := amper + length('BODY') + 1;
             tokenMatch := TRUE;
          else
             tokenMatch := FALSE;
          end if;
       end if;
       if instr(tokenName, 'MAIL_ERROR_NAME', 1, 1)=1 then
          if err_name is not null then
             -- DBMS_LOB.WriteAppend(temp, length(err_name), err_name);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, length(err_name), err_name);
             tempPos := tempPos + length(err_name);
          end if;
          pos := amper + length('MAIL_ERROR_NAME') + 1;
          tokenMatch := TRUE;
       end if;
       if instr(tokenName, 'MAIL_ERROR_MESSAGE', 1, 1)=1 then
          if err_message is not null then
             -- DBMS_LOB.WriteAppend(temp, length(err_message), err_message);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, length(err_message),
                                  err_message);
             tempPos := tempPos + length(err_message);
          end if;
          pos := amper + length('MAIL_ERROR_MESSAGE') + 1;
          tokenMatch := TRUE;
       end if;

       -- Bug# 2301881 Replacing error stack with invalid value
       --              found and the original response values
       --              to go with the WARNING message

       if instr(tokenName, 'MAIL_VALUE_FOUND', 1, 1)=1 then
          if err_invalid is not null then
             -- DBMS_LOB.WriteAppend(temp, length(err_invalid), err_invalid);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, length(err_invalid),
                                  err_invalid);
             tempPos := tempPos + length(err_invalid);
          end if;
          pos := amper + length('MAIL_VALUE_FOUND') + 1;
          tokenMatch := TRUE;
       end if;

       if instr(tokenName, 'MAIL_EXP_VALUES', 1, 1)=1 then
          if err_expected is not null then
             -- DBMS_LOB.WriteAppend(temp, length(err_expected), err_expected);
             DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, length(err_expected),
                                  err_expected);
             tempPos := tempPos + length(err_expected);
          end if;
          pos := amper + length('MAIL_EXP_VALUES') + 1;
          tokenMatch := TRUE;
       end if;

       if not tokenMatch and amper > 0 then
          -- DBMS_LOB.WriteAppend(temp, 1, '&');
          DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, 1, '&');
          tempPos := tempPos + 1;
       end if;

    end loop;

    -- msgLen := DBMS_LOB.GetLength(temp);
    msgLen := DBMS_LOB.GetLength(g_LOBTable(tempIdx).temp_lob);
    if msgLen > 0 then
       DBMS_LOB.Trim(m_body, 0);
       -- DBMS_LOB.Copy(m_body, temp, msgLen);
       DBMS_LOB.Copy(m_body, g_LOBTable(tempIdx).temp_lob, msgLen);
    end if;

    -- DBMS_LOB.Close(temp);
    -- DBMS_LOB.FreeTemporary(temp);
    wf_temp_lob.releaseLob(g_LOBTable, tempIdx);

exception
   when others then
      wf_temp_lob.releaseLob(g_LOBTable, tempIdx);
      WF_CORE.Context('WF_MAIL','LOBSubstitute',tokenName,
         to_char(msgLen)||':'||to_char(pos)||':'||to_char(tempPos));
      raise;
end LOBSubstitute;

-- OBSOLETELOBLineBreak - To add a new line every 900 characters
-- or the nearst white space
-- IN
--    message
--    line size default 900
procedure OBSOLETELOBLineBreak(message IN OUT NOCOPY CLOB,
                       lineSize in INTEGER,
                       maxLineSize INTEGER)
is
   lnsize NUMBER;
   start_cnt NUMBER;
   end_cnt NUMBER;
   crpos NUMBER;
   tempOffset NUMBER;
   str_length NUMBER;

   -- temp CLOB;
   -- line CLOB;
   tempIdx  pls_integer;
   lineIdx  pls_integer;

begin

   --
   -- For every 900 character, we insert a newline just in case
   -- Because this whole message body may go out to the Unix SMTP gateway
   -- which does not like a line longer than 1000 characters.
   -- We do it 900 here just for safty.
   -- 2001/03/23 Changed algorithm to start at 900 point and then
   -- move to the nearest whitespace.
   --
   lnsize := lineSize;
   start_cnt := 1;
   end_cnt := lnsize;
   str_length := DBMS_LOB.GetLength(message);
   if str_length = 0 then
      return;
   end if;

   -- DBMS_LOB.CreateTemporary(temp, TRUE, DBMS_LOB.CALL);
   -- DBMS_LOB.CreateTemporary(line, TRUE, DBMS_LOB.CALL);
   -- DBMS_LOB.Open(temp, DBMS_LOB.LOB_READWRITE);
   -- DBMS_LOB.Open(line, DBMS_LOB.LOB_READWRITE);
   tempIdx := wf_temp_lob.getLob(g_LOBTable);
   lineIdx := wf_temp_lob.getLob(g_LOBTable);

   while start_cnt < str_length loop
      -- use the existing newlines as a natural break
      crpos := DBMS_LOB.instr(message, g_newLine, start_cnt+1, 1) - start_cnt;


      if crpos > 0 and crpos < end_cnt then
         -- If there was a line bread and it is positioned less than the
         -- maximum allowed, then use that instead.
         end_cnt := crpos;
      else
         if crpos < 0 and (str_length - start_cnt) < end_cnt then
            end_cnt := str_length - start_cnt;
         end if;

         -- Move forward to the next white space.
         while (start_cnt + end_cnt < str_length) and
               DBMS_LOB.substr(message, 1, start_cnt + end_cnt)
                         not in (' ', g_newLine, g_tab)
               and end_cnt < maxLineSize loop
            end_cnt := end_cnt + 1;
         end loop;

         -- We need to understand the full conditions underwhich
         -- the previous loop exited. All characters must be preserved
         -- and the line, no matter what can not exceed 900 characters.

         if end_cnt >= (maxLineSize) then
           end_cnt := lnsize;
           while (start_cnt + end_cnt > start_cnt) and
               DBMS_LOB.substr(message, 1, start_cnt + end_cnt)
                         not in (' ', g_newLine, g_tab)
               and end_cnt > 0 loop
              end_cnt := end_cnt - 1;
           end loop;
           -- If we can not locate a white space, then use the default
           if end_cnt <= 0 then
              end_cnt := lnsize;
           end if;
         end if;
      end if;

      -- Ensure the last characters are not lost.
      -- DBMS_LOB.Trim(line, 0);
      DBMS_LOB.Trim(g_LOBTable(lineIdx).temp_lob, 0);
      tempOffset := dbms_lob.getLength(g_LOBTable(tempIdx).temp_lob) +1;
      if start_cnt + end_cnt >= str_length then
         -- line := DBMS_LOB.substr(message, start_cnt);
         -- DBMS_LOB.Copy(line, message,
         --              DBMS_LOB.GetLength(message) - start_cnt +1 , 1,
         --              start_cnt);
         -- DBMS_LOB.Copy(g_LOBTable(lineIdx).temp_lob, message,
         --               DBMS_LOB.GetLength(message) - start_cnt +1 , 1,
         --               start_cnt);
         DBMS_LOB.Copy(dest_lob => g_LOBTable(tempIdx).temp_lob,
                       src_lob => message,
                       amount => DBMS_LOB.GetLength(message) - start_cnt +1 ,
                       dest_offset => tempOffset,
                       src_offset => start_cnt);

      else
         -- line := DBMS_LOB.substr(message, start_cnt, end_cnt);
         -- DBMS_LOB.Copy(line, message, end_cnt, 1, start_cnt);
         -- DBMS_LOB.Copy(g_LOBTable(lineIdx).temp_lob, message, end_cnt, 1,
         --               start_cnt);
         DBMS_LOB.Copy(dest_lob => g_LOBTable(tempIdx).temp_lob,
                       src_lob => message,
                       amount => end_cnt,
                       dest_offset => tempOffset,
                       src_offset => start_cnt);
      end if;

      -- temp := temp || line;
      -- DBMS_LOB.Append(temp, line);
      -- DBMS_LOB.Append(g_LOBTable(tempIdx).temp_lob,
      --                 g_LOBTable(lineIdx).temp_lob);

      -- If there is a newline at this point,
      -- then do not bother with another.
      if DBMS_LOB.substr(message, 1, start_cnt + end_cnt) <>
                g_newLine then
         -- DBMS_LOB.WriteAppend(temp, 1, g_newLine);
         DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, 1, g_newLine);
      end if;

      -- We do not want to start the new line with the space.
      if DBMS_LOB.substr(message, 1, start_cnt + end_cnt) = ' ' then
         start_cnt := start_cnt + end_cnt + 1;
      else
         start_cnt := start_cnt + end_cnt;
      end if;
      end_cnt := lnsize;
   end loop;
   DBMS_LOB.Trim(message, 0);
   -- DBMS_LOB.Copy(message, temp, DBMS_LOB.GetLength(temp), 1, 1);
   DBMS_LOB.Copy(message, g_LOBTable(tempIdx).temp_lob,
                 DBMS_LOB.GetLength(g_LOBTable(tempIdx).temp_lob), 1, 1);


   -- if DBMS_LOB.IsOpen(temp)=1 then
   --   DBMS_LOB.Close(temp);
   --   DBMS_LOB.FreeTemporary(temp);
   -- end if;
   -- if DBMS_LOB.IsOpen(line)=1 then
   --   DBMS_LOB.Close(line);
   --   DBMS_LOB.FreeTemporary(line);
   -- end if;
   wf_temp_lob.releaseLob(g_LOBTable, lineIdx);
   wf_temp_lob.releaseLob(g_LOBTable, tempIdx);

end OBSOLETELOBLineBreak;

-- OBSOLETE2LOBLineBreak
-- To wrap the text at textWidth but no line can exceed maLineSize
-- NOTE:
-- In order to be performant, the textWidth is given
-- as a guide. If not natural break appears, then the nearest
-- whitespace after textWidth will be used.
procedure OBSOLETE2LOBLineBreak(message IN OUT NOCOPY CLOB,
                       textWidth in INTEGER,
                       maxLineSize INTEGER)
is

   lnsize NUMBER;
   bfr_start NUMBER;
   chk_start NUMBER;
   line_size NUMBER;
   crpos NUMBER;
   wsLoc NUMBER;
   doc_length NUMBER;
   tempOffset NUMBER;
   insertNewLine boolean;
   whitespace boolean;

   tempIdx  pls_integer;
   lineBuffer varchar2(32000);

begin

   lnsize := textWidth;
   bfr_start := 1;
   chk_start := 1;
   line_size := lnsize;
   doc_length := DBMS_LOB.GetLength(message);
   if doc_length = 0 or doc_length < line_size then
      return;
   end if;

   tempIdx := wf_temp_lob.getLob(g_LOBTable);

   -- While the block start counter is less than the length of the
   -- document, then start scanning to make sure that the document
   -- conforms to the requirements of the parameters.
   while chk_start < doc_length loop

      wsLoc := -1;
      insertNewLine := false;

      -- use the existing newlines as a natural break. If found
      -- crpos will be the relative position from chk_start.
      crpos := DBMS_LOB.instr(lob_loc => message,
                              pattern => g_newLine,
                              offset => chk_start,
                              nth => 1) - chk_start;

      -- If the position of crpos makes the respective line less than
      -- the required linesize, then use that. Otherwise, go looking for
      -- some whitespace to insert a new line.

      if crpos > -1 and crpos < line_size then
         line_size := crpos +1;
         insertNewLine := false;
      else
         -- Move forward to the next white space.

         wsLoc := DBMS_LOB.instr(lob_loc => message,
                                 pattern => ' ',
                                 offset => (chk_start + line_size),
                                 nth => 1) - chk_start;

         crpos := DBMS_LOB.instr(lob_loc => message,
                                 pattern => g_newline,
                                 offset => (chk_start + line_size),
                                 nth => 1) - chk_start;

         if(crpos > -1 and crpos < wsLoc and crpos < maxLineSize) then
            line_size := crpos +1;
            insertNewLine := false;
         elsif (wsLoc > -1 and wsLoc < maxLineSize) then
            line_size := wsLoc;
            insertNewLine := true;
            whitespace := true;
         else

            wsLoc := DBMS_LOB.instr(lob_loc => message,
                                    pattern => g_newLine,
                                    offset => chk_start + line_size,
                                    nth => 1) - chk_start;

            if (wsLoc > -1 and wsLoc < maxLineSize) then
               line_size := wsLoc;
               wsLoc := 0;
               insertNewLine := false;
               whitespace := true;
            else

               wsLoc := DBMS_LOB.instr(lob_loc => message,
                                       pattern => g_tab,
                                       offset => chk_start + line_size,
                                       nth => 1) - chk_start;

               if (wsLoc > -1 and wsLoc < maxLineSize) then
                  line_size := wsLoc;
                  insertNewLine := true;
                  whitespace := true;
               else
                  line_size := maxLineSize;
                  insertNewLine := true;
                  whitespace := true;
               end if;
            end if;
         end if;
      end if;

      -- Ensure the last characters are not lost.
      if chk_start + line_size >= doc_length then
         -- copy from the chk_start to the end of the document.
         tempOffset := dbms_lob.getLength(g_LOBTable(tempIdx).temp_lob) +1;

         DBMS_LOB.Copy(dest_lob => g_LOBTable(tempIdx).temp_lob,
                       src_lob => message,
                       amount => doc_length - bfr_start +1 ,
                       dest_offset => tempOffset,
                       src_offset => bfr_start);
      elsif insertNewLine then
         -- Copy partial and make note of the current position
         -- This is to minimise the number of calls to dbms_lob.copy.
         tempOffset := dbms_lob.getLength(g_LOBTable(tempIdx).temp_lob) +1;
         DBMS_LOB.Copy(dest_lob => g_LOBTable(tempIdx).temp_lob,
                       src_lob => message,
                       amount => (chk_start - bfr_start) + line_size,
                       dest_offset => tempOffset,
                       src_offset => bfr_start);
         DBMS_LOB.WriteAppend(g_LOBTable(tempIdx).temp_lob, 1, g_newLine);
         bfr_start := chk_start + line_size +1;
      end if;

      if wsLoc > 0 then
         chk_start := chk_start + line_size + 1;
      else
         chk_start := chk_start + line_size;
      end if;
      line_size := lnsize;
   end loop;

   DBMS_LOB.Trim(message, 0);
   DBMS_LOB.Copy(message, g_LOBTable(tempIdx).temp_lob,
                 DBMS_LOB.GetLength(g_LOBTable(tempIdx).temp_lob), 1, 1);

   DBMS_LOB.Trim(g_LOBTable(tempIdx).temp_lob, 0);
   wf_temp_lob.releaseLob(g_LOBTable, tempIdx);

end OBSOLETE2LOBLineBreak;


-- LOBLineBreak
-- To wrap the text at textWidth but no line can exceed maLineSize
-- NOTE:
-- In order to be performant, the textWidth is given
-- as a guide. If not natural break appears, then the nearest
-- whitespace after textWidth will be used.
-- Re-written for bug 4510044
procedure LOBLineBreak(message IN OUT NOCOPY CLOB,
                       textWidth in INTEGER,
                       maxLineSize INTEGER)
is

   l_amount number := 0;
   l_offset number := 1;
   l_bufferSize number := 0;
   l_forcedBreak boolean := false;
   l_strBuffer varchar2(32000);

   l_linesize number := textWidth;

   l_lastCR number;
   l_lastWS number;

   l_tempIdx pls_integer;

begin

   l_tempIdx := wf_temp_lob.getLob(g_LOBTable);

   l_amount := dbms_lob.getLength(message);
   l_offset := 1;
   l_bufferSize := l_lineSize;
   l_forcedBreak := false;

   if(l_amount > 0) then
      loop
         l_lastCR := 0;
         l_forcedBreak := false;
         if(l_amount > l_lineSize) then
            dbms_lob.read(lob_loc => message, amount => l_lineSize,
                          offset => l_offSet, buffer => l_strBuffer);

            l_lastCR := instr(l_strBuffer, wf_core.newline, -1);
            l_lastWS := instr(l_strBuffer, ' ', -1);

            if(l_lastCR > 1) then
               l_bufferSize := l_lastCR;
            elsif(l_lastWS > 1) then
               l_bufferSize := l_lastWS;
               l_forcedBreak := true;
            else
               l_bufferSize := l_lineSize;
            end if;

            l_amount := l_amount - l_bufferSize;
            l_offset := l_offset + l_bufferSize;

            if (l_forcedBreak) then
               l_strBuffer := substr(l_strBuffer, 1, l_bufferSize - 1)||
                                     wf_core.newline;
               -- Recalculate the buffer size incase newline is not the
               -- same size as the space that was removed
               l_bufferSize := length(l_strBuffer);
            end if;

            DBMS_LOB.writeAppend(lob_loc => g_LOBTable(l_tempIdx).temp_lob,
                                 amount => l_bufferSize,
                                 buffer => l_strBuffer);

            l_strBuffer := '';
         else

            l_amount := (dbms_lob.getLength(message) - l_offset) + 1;
            dbms_lob.read(lob_loc => message, amount => l_amount,
                          offset => l_offset, buffer => l_strBuffer);

            dbms_lob.writeAppend(lob_loc => g_LOBTable(l_tempIdx).temp_lob,
                                 amount => l_amount,
                                 buffer => l_strBuffer);

            exit;
         end if;
      end loop;
      DBMS_LOB.Trim(message, 0);
      DBMS_LOB.Copy(message, g_LOBTable(l_tempIdx).temp_lob,
                    DBMS_LOB.GetLength(g_LOBTable(l_tempIdx).temp_lob), 1, 1);

      DBMS_LOB.Trim(g_LOBTable(l_tempIdx).temp_lob, 0);
      wf_temp_lob.releaseLob(g_LOBTable, l_tempIdx);
   end if;

-- exception
   -- when others then
   -- wf_core.context('WF_MAIL', 'LOBLineBreak',  to_char(textWidth));
   -- raise;
end LOBLineBreak;


-- GetMailTo - Construct MailTo Section (PRIVATE)
-- IN
--   notification id
--   notification tag
--   notification reply to
--   notification subject
-- RETURN
--   mailto html tag with the subject and body
procedure GetMailTo(nid in number,
                   n_tag in varchar2,
                   reply_to in varchar2,
                   subject in varchar2,
                   doc in out nocopy CLOB)
is
    -- SQL Statement for fetching URL RESPONSE attributes.
    cursor c1 is
    select WMA.NAME, WMA.DISPLAY_NAME, WNA.TEXT_VALUE, WMA.DESCRIPTION
    from   WF_NOTIFICATION_ATTRIBUTES WNA,
           WF_NOTIFICATIONS WN,
           WF_MESSAGE_ATTRIBUTES_VL WMA
    where  WNA.NOTIFICATION_ID = nid
    and    WN.NOTIFICATION_ID = WNA.NOTIFICATION_ID
    and    WN.MESSAGE_TYPE = WMA.MESSAGE_TYPE
    and    WN.MESSAGE_NAME = WMA.MESSAGE_NAME
    and    WMA.NAME = WNA.NAME
    and    WMA.SUBTYPE = 'RESPOND'
    and    WMA.TYPE = 'URL'
    order  by WMA.SEQUENCE;

    lov varchar2(64);
    lov_list varchar2(240);
    str_buffer varchar2(32000);
    -- buffer CLOB;
    bufferIdx  pls_integer;
    auto_answer varchar2(64);
    newline_pos number;
    disp_name varchar2(80);
    attr_type varchar2(8);
    attr_format varchar2(240);
    attr_value varchar2(32000);
    attr_desc varchar2(240);
    encoded_tag varchar2(240);

begin

    -- Clear buffer
    str_buffer := '';
    -- DBMS_LOB.createTemporary(buffer, FALSE, dbms_lob.call);
    bufferIdx := wf_temp_lob.getLob(g_LOBTable);

    -- URL RESPONSE attributes overrides the normal RESULT attributes.
    -- So, my goal here is to check for this case.
    -- URL RESPONSE attributes is going to appear as a anchor and don't have
    -- to construct the MAILTO html tag stuff that we do for the normal
    -- RESULT attribute.

    -- NOTE: Please do know that I don't want to destablize the existing code
    -- for the normal RESULT attribute MAILTO handling so that I am coding
    -- these two cases seperately.
    -- for each response variable
    for rec in c1 loop
        str_buffer := str_buffer||'<P>';
        if (rec.description is not null) then
            str_buffer := str_buffer||rec.description||'<P>';
        end if;
        str_buffer := str_buffer|| '<A class="OraLink" HREF="'||
                      wf_notification.geturltext(rec.text_value, nid)||
                      '" target="_top">';
        str_buffer := str_buffer||'<FONT size=+1> <B>'||rec.display_name;
        str_buffer := str_buffer||'</B></FONT>'||'</A>';
        str_buffer := str_buffer||g_newLine;
        -- DBMS_LOB.writeAppend(buffer, length(str_buffer), str_buffer);
        DBMS_LOB.writeAppend(g_LOBTable(bufferIdx).temp_lob, length(str_buffer), str_buffer);
        str_buffer := '';
    end loop;

    -- if (dbms_lob.GetLength(buffer) > 0) then
    if (dbms_lob.GetLength(g_LOBTable(bufferIdx).temp_lob) > 0) then
        -- LOBReplace(doc, '&'||'MAILTO', buffer, FALSE);
        LOBReplace(doc, '&'||'MAILTO', g_LOBTable(bufferIdx).temp_lob, FALSE);
        RETURN;
    end if;

    --
    -- Normal RESULT attribute handling
    --
    begin
    select WMA.DISPLAY_NAME, WMA.TYPE, WMA.FORMAT,
           decode(WMA.TYPE,
             'VARCHAR2', decode(WMA.FORMAT,
                           '', WNA.TEXT_VALUE,
                           substr(WNA.TEXT_VALUE, 1, to_number(WMA.FORMAT))),

             'NUMBER', decode(WMA.FORMAT,
                         '', to_char(WNA.NUMBER_VALUE),
                         to_char(WNA.NUMBER_VALUE, WMA.FORMAT)),
             'DATE', decode(WMA.FORMAT,
                       '', to_char(WNA.DATE_VALUE),
                       to_char(WNA.DATE_VALUE, WMA.FORMAT)),
             'LOOKUP', WNA.TEXT_VALUE,
             WNA.TEXT_VALUE), WMA.DESCRIPTION
    into   disp_name, attr_type, attr_format, attr_value, attr_desc
    from   WF_NOTIFICATION_ATTRIBUTES WNA,
           WF_NOTIFICATIONS WN,
           WF_MESSAGE_ATTRIBUTES_VL WMA
    where  WNA.NOTIFICATION_ID = nid
    and    WN.NOTIFICATION_ID = WNA.NOTIFICATION_ID
    and    WN.MESSAGE_TYPE = WMA.MESSAGE_TYPE
    and    WN.MESSAGE_NAME = WMA.MESSAGE_NAME
    and    WMA.NAME = WNA.NAME
    and    WMA.SUBTYPE = 'RESPOND'
    and    WMA.NAME = 'RESULT'
    and    WMA.TYPE not in ('FORM', 'URL');

    -- We can only construct answer button or mailto link if is lookup
    if (attr_type <> 'LOOKUP') then
        auto_answer := 'Respond';
    else
        -- If is LOOKUP RESULT attribute, we need to show the description here.
        if (attr_desc is not null) then
            str_buffer := str_buffer||'<P>'||attr_desc;
        end if;
        auto_answer :=  attr_format;
    end if;

    exception
    when no_data_found then
        auto_answer := 'Respond';
    end;

    -- Encode any special characters
    encoded_tag := UrlEncode(n_tag);

    -- Construct mailto syntax
    str_buffer := str_buffer||'<P>'||disp_name||': <A class="OraLink" HREF="mailto:'||reply_to||
              '?subject=%20'||
              UrlEncode(subject)||'&'||'body=%20';
    -- DBMS_LOB.WriteAppend(buffer, length(str_buffer), str_buffer);
    DBMS_LOB.WriteAppend(g_LOBTable(bufferIdx).temp_lob, length(str_buffer), str_buffer);
    str_buffer := '';
    if (auto_answer = 'Respond') then
      -- GetMailToBody(nid, auto_answer, buffer);
      GetMailToBody(nid, auto_answer, g_LOBTable(bufferIdx).temp_lob);
      str_buffer := '%0D%0A%0D%0A'||encoded_tag||'">'||'<FONT size=+1><B>'||
                 g_noResult||'</B></FONT>'||'</A>';
       -- DBMS_LOB.WriteAppend(buffer, length(str_buffer), str_buffer);
       DBMS_LOB.WriteAppend(g_LOBTable(bufferIdx).temp_lob, length(str_buffer), str_buffer);
       str_buffer := '';
    else
        lov_list := GetLovListInternal(auto_answer);
        lov_list := substr(lov_list, 1, length(lov_list)-1);

        while (lov_list is not null) loop
            newline_pos := instr(lov_list, g_newLine);

            if (newline_pos = 0) then
                lov := lov_list;
            else
                lov := substr(lov_list, 1, newline_pos - 1);
            end if;

            -- GetMailToBody(nid, lov, buffer);
            GetMailToBody(nid, lov, g_LOBTable(bufferIdx).temp_lob);
            str_buffer :=str_buffer||'%0D%0A%0D%0A'||encoded_tag||'">'||
                     '<FONT size=+1><B>'||GetLovMeaning(attr_format, lov)||
                     '</FONT></B>'||'</A>';
            if (newline_pos = 0) then
                lov_list := null;
                if (g_moreinfo = 'REQ') then
                   str_buffer := str_buffer || GetMoreInfoMailTo(nid, n_tag, reply_to, subject);
                end if;
            else
                lov_list := substr(lov_list, newline_pos+1,
                                   length(lov_list) - newline_pos);
                str_buffer := str_buffer||g_newLine;
                str_buffer := str_buffer||'&'||'nbsp;'||'&'||'nbsp;'||
                          '<A class="OraLink" HREF="mailto:'||reply_to||
                          '?subject=%20'||UrlEncode(subject)||'&'||'body=%20';
            end if;
            -- DBMS_LOB.WriteAppend(buffer, length(str_buffer), str_buffer);
            DBMS_LOB.WriteAppend(g_LOBTable(bufferIdx).temp_lob, length(str_buffer), str_buffer);
            str_buffer := '';
        end loop;

    end if;

    -- LOBReplace(doc, '&'||'MAILTO', buffer, FALSE);
    LOBReplace(doc, '&'||'MAILTO', g_LOBTable(bufferIdx).temp_lob, FALSE);
    wf_temp_lob.releaseLob(g_LOBTable, bufferIdx);

exception
    when others then
      wf_temp_lob.releaseLob(g_LOBTable, bufferIdx);
      wf_core.context('WF_MAIL', 'GetMailTo', nid);
      raise;

end GetMailTo;

--
-- Validate_JSP_Agent
--  Function to parse the given URL to check if it is a valid JSP agent.
--  If the agent is from the old mailer config with /pls/wf/ or from
--  APPS_FRAMEWORK_AGENT profile option without /OA_HTML/ or /pls/wf/ this
--  function will return in format http://hostname.domain:port/OA_HTML/
--  (The logic is based on fnd_run_function.get_jsp_agent)
--
function Validate_JSP_Agent(p_web_agent in varchar2)
return varchar2
is
   l_web_agent varchar2(2000);
   l_pos1      pls_integer;
   l_pos2      pls_integer;
begin
   l_web_agent := trim(p_web_agent);

   if (l_web_agent is not null) then
     -- Add a trailing slash if not available
     if (substr(l_web_agent, -1, 1) <> '/') then
       l_web_agent := l_web_agent||'/';
     end if;

     -- http://
     l_pos1 := instrb(l_web_agent, '//', 1) + 2;
     -- http://hostname.domain:port/
     l_pos2 := instrb(l_web_agent, '/', l_pos1);

     l_web_agent := substrb(l_web_agent, 1, l_pos2)||'OA_HTML/';

     if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
        wf_log_pkg.string(wf_log_pkg.level_statement,
                       'wf.plsql.wf_mail.Validate_JSP_Agent',
                       'Validated JSP Agent -> '||l_web_agent);
     end if;
   end if;

   return l_web_agent;

exception
   when others then
     if (wf_log_pkg.level_error >= fnd_log.g_current_runtime_level) then
       wf_log_pkg.string(wf_log_pkg.level_error,
                        'wf.plsql.wf_mail.Validate_JSP_Agent',
                        'Error validating JSP Agent -> '||sqlerrm);
     end if;
     return p_web_agent;
end Validate_JSP_Agent;

-- Returns the Applications Framework function URL
function Get_Ntf_Function_URL(nid              in number,
                              n_key            in varchar2,
                              n_sig_policy     in varchar2,
                              n_override_agent in varchar2)
return varchar2
is
   url varchar2(4000);
   validateAccess varchar2(1);
   params varchar2(240);
   functionName varchar2(240);
   functionId number;

   sig_required varchar2(1);
   fwk_flavor varchar2(255);
   email_flavor varchar2(255);
   render varchar2(255);
begin

      validateAccess := FND_PROFILE.value('WF_VALIDATE_NTF_ACCESS');

      Wf_Notification.GetSignatureRequired(p_sig_policy => n_sig_policy,
                                           p_nid => nid,
                                           p_sig_required => sig_required,
                                           p_fwk_sig_flavor => fwk_flavor,
                                           p_email_sig_flavor => email_flavor,
                                           p_render_hint => render);

      if sig_required = 'Y' then
         -- TODO set the correct name for hte PSIG function.
         functionName := 'FND_WFNTF_DETAILS';
      else
         functionName := 'FND_WFNTF_DETAILS';
      end if;

      functionId := fnd_function.get_function_id (functionName);

      -- The default set of parameters for all functions.
      params := 'wfMailer=Y&'||'NtfId='||to_char(nid);

      if validateAccess = 'Y' then
         -- Add on the access key only when requried.
         params := params||'&'||'wfnkey='||n_key;
      end if;

      -- Moreinfo will be globally set from the calling procedure
      if g_moreinfo = 'SUB' then
         params := params||'&'||'wfMoreinfo=Y';
      else  -- moreinfo REQ or NULL
         params := params||'&'||'wfMoreinfo=N';
      end if;

      if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
         wf_log_pkg.string(WF_LOG_PKG.level_statement,
                           'wf.plsql.WF_MAIL.Get_Ntf_Function_url',
                           'params: {'||params||'} override agent: {'
                           ||n_override_agent||'}');
      end if;

      url := fnd_run_function.get_run_function_url(
                    p_function_id => functionId,
                    p_resp_appl_id => -1,
                    p_resp_id => -1,
                    p_security_group_id => null,
                    p_parameters => params,
                    p_override_agent => Validate_JSP_Agent(n_override_agent));

      return url;

end get_Ntf_Function_url;

-- PRIVATE function to return the CLICK_HERE_TO_RESPOND value
function getClickHereResponse(nid in number, n_key in varchar2,
                              agent in varchar2, n_disp_click in varchar2,
                              n_sig_policy in varchar2)
         return varchar2
is

   n_click_here varchar2(4000);
   l_function_id number;
   params varchar2(240);
   url varchar2(4000);
   validateAccess varchar2(1);

begin
   n_click_here := '<A class="OraLink" HREF="';

   if g_install = 'EMBEDDED' then
      url := get_Ntf_Function_URL(nid => nid,
                                  n_key => n_key,
                                  n_sig_policy => n_sig_policy,
                                  n_override_agent => agent);

      n_click_here := n_click_here || url;

   else
      if (agent is null) then
         if wf_mail.send_accesskey then
            n_click_here := n_click_here||g_webAgent
                          ||'/WFA_HTML.DetailLink?nid='||to_char(nid)
                          ||'&'||'nkey='||n_key
                          ||'&'||'agent='||g_webAgent;
         else
            n_click_here := n_click_here||g_webAgent
                             ||'/'|| wfa_sec.DirectLogin(nid);
         end if;
      else
         if wf_mail.send_accesskey then
            n_click_here := n_click_here||agent
                             ||'/WFA_HTML.DetailLink?nid='||to_char(nid)
                             ||'&'||'nkey='||n_key
                             ||'&'||'agent='||agent;
         else
            n_click_here := n_click_here||agent
                             ||'/'|| wfa_sec.DirectLogin(nid);
         end if;
      end if;
   end if;

   n_click_here := n_click_here||'">'||n_disp_click||'</A>';

   if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
      wf_log_pkg.string(WF_LOG_PKG.level_statement,'wf.plsql.WF_MAIL.newLOBTag',
                          'URL: {'||n_click_here||'}');
   end if;


   return n_click_here;

end getClickHereResponse;

--
-- setContext (PRIVATE)
--   Set the context by executing the selector function
-- IN
--   nid - Notification id
--
procedure setContext(nid NUMBER)
is
   context VARCHAR2(2000);        /* Bug 2312742 */
   callback VARCHAR2(100);
   tvalue varchar2(4000);
   nvalue number;
   dvalue date;

   sqlbuf varchar2(4000);
   l_dummy varchar2(1);
begin

   SELECT context, callback
      into context, callback
   FROM wf_notifications
   where notification_id = nid;

   wf_engine.preserved_context := FALSE;
   if (callback is not null) then
      -- ### callback is from table
      -- BINDVAR_SCAN_IGNORE
      sqlbuf := 'begin '||callback||
                '(:p1, :p2, :p3, :p4, :p5, :p6, :p7); end;';
      execute immediate sqlbuf using
         in 'TESTCTX',
         in context,
         in l_dummy,
         in l_dummy,
         in out tvalue,
         in out nvalue,
         in out dvalue;

      if (tvalue in ('FALSE', 'NOTSET')) then
         execute immediate sqlbuf using
            in 'SETCTX',
            in context,
            in l_dummy,
            in l_dummy,
            in out tvalue,
            in out nvalue,
            in out dvalue;
      end if;
   end if;

exception
   when others then
      WF_CORE.Context('WF_MAIL','SetContext',to_char(nid));
      raise;
end setContext;

-- Get_Last_Question (Private)
-- Retrieves the last More Information question
-- If no question exists, then it is blank.
-- IN
--   p_nid - Notification ID
-- OUT
--   p_last_ques - Returned last question
procedure Get_Last_Question(p_nid in number,
                            p_last_ques out nocopy varchar2)
is

  CURSOR c_ques IS
  SELECT user_comment
  FROM   wf_comments
  WHERE  notification_id = p_nid
  AND    action = 'QUESTION'
  ORDER BY comment_date desc;

begin

  -- Fetch the last question asked
  open c_ques;
  fetch c_ques into p_last_ques;
  if (c_ques%notfound) then
    p_last_ques := '';
  end if;
  close c_ques;

end Get_Last_Question;


-- Get_Action_History (Private)
--   Scans the notifications message definition and determines if Action History
--   should be displayed
-- IN
--   p_nid  - Notification Id
--   p_lang - User Language
-- OUT
--   p_html_history - Action History in HTML
--   p_text_history - Action History in Text
--   p_last_ques    - Last Question Asked if More Infor Requested
procedure Get_Action_History(p_nid          in  number,
                             p_lang         in  varchar2,
                             p_html_history out nocopy varchar2,
                             p_text_history out nocopy varchar2,
                             p_last_ques    out nocopy varchar2)
is
  l_text_body    varchar2(4000);
  l_html_body    varchar2(4000);
  l_comm_cnt     pls_integer;
  l_text_history varchar2(32000);
  l_html_history varchar2(32000);
  l_get_html     boolean;
  l_get_text     boolean;

  CURSOR c_comm IS
  SELECT count(1)
  FROM   wf_comments
  WHERE  action_type in ('REASSIGN', 'QA')
  AND    notification_id = p_nid;

begin

  -- Fetch the last question asked
  Get_Last_Question(Get_Action_History.p_nid,
                    Get_Action_History.p_last_ques);

  l_get_html := false;
  l_get_text := false;

  SELECT wm.body, wm.html_body
  INTO   l_text_body, l_html_body
  FROM   wf_notifications n, wf_messages_vl wm
  WHERE  n.notification_id = p_nid
  AND    n.message_name = wm.name
  AND    n.message_type = wm.type;

  -- FYI notification
  if (wf_mail.Get_FYI_Flag) then
    open c_comm;
    fetch c_comm into l_comm_cnt;
    if (c_comm%notfound) then
      l_comm_cnt := 0;
    end if;

    -- If HISTORY macro is defined, Action History would appear anyways. If the FYI notification
    -- was reassigned at least once, include the Action History if even macro is not defined
    if (l_comm_cnt > 0) then
      if (instrb(l_text_body, 'WF_NOTIFICATION(HISTORY)') = 0) then
         l_get_text := true;
      end if;
      if (instrb(l_html_body, 'WF_NOTIFICATION(HISTORY)') = 0) then
         l_get_html := true;
      end if;
    end if;
    close c_comm;

   -- Response Required notification
   else
     -- If HISTORY macro is defined, Action History would appear anyways. Otherwise
     -- display it in the e-mail
     if (instrb(l_text_body, 'WF_NOTIFICATION(HISTORY)') = 0) then
        l_get_text := true;
     end if;
     if (instrb(l_html_body, 'WF_NOTIFICATION(HISTORY)') = 0) then
        l_get_html := true;
     end if;
   end if;

   -- Call the GetComments2 procedure to get the Action History
   if (l_get_text) then
      Wf_Notification.GetComments2(p_nid => Get_Action_History.p_nid,
                                   p_display_type => wf_notification.doc_text,
                                   p_hide_reassign => 'N',
                                   p_hide_requestinfo => 'N',
                                   p_action_history => l_text_history);
   end if;
   if (l_get_html)then
      Wf_Notification.GetComments2(p_nid => Get_Action_History.p_nid,
                                   p_display_type => wf_notification.doc_html,
                                   p_hide_reassign => 'N',
                                   p_hide_requestinfo => 'N',
                                   p_action_history => l_html_history);
   end if;

   p_text_history := l_text_history;
   p_html_history := l_html_history;

exception
  when others then
    if (wf_log_pkg.level_exception >= fnd_log.g_current_runtime_level) then
       wf_log_pkg.string(WF_LOG_PKG.level_exception,
                         'wf.plsql.wf_mail.Get_Action_History',
                         'Get_Action_History failed. Error: ' || sqlerrm);
    end if;
    p_text_history := '';
    p_html_history := '';
end Get_Action_History;

-- GetLOBMessage3 - get email message data as a LOB
--
-- IN
--   notification id
--   mailer node name
--   web agent path
--   reply to
--   recipient role
--   lanague
--   territory
--   notification preference
--   dsiplay name
--   Render BODY token flag
-- OUT
--   message subject
--   message body (text)
--   message body (html)
procedure GetLOBMessage3(
    nid       in  number,
    node      in  varchar2,
    agent     in  varchar2,
    replyto   in  varchar2,
    recipient in varchar2,
    language  in varchar2,
    territory in varchar2,
    ntf_pref  in varchar2,
    email     in varchar2,
    dname     in varchar2,
    renderBody in varchar2,
    subject   out NOCOPY varchar2,
    body_atth out NOCOPY varchar2,
    error_result in out NOCOPY varchar2,
    bodyToken in out NOCOPY varchar2 )
as
    n_status      varchar2(8);
    n_mstatus     varchar2(8);
    n_key         varchar2(80);
    n_to_role     varchar2(320);
    n_from_user   varchar2(320); -- Bug# 2094159
    n_due_date    date;
    n_start_date  date;
    n_end_date    date;
    n_priority    number;
    n_comment     varchar2(4000);
    n_subject     varchar2(2000);
    n_response    varchar2(32000);
    n_direct      varchar2(3);
    n_click_here  varchar2(4000);
    n_disp_click  varchar2(240);
    n_text_timezone varchar2(240);
    n_html_timezone varchar2(240);
    r_dname       varchar2(360);
    r_email       varchar2(2000);
    r_ntf_pref    varchar2(240);
    r_language    varchar2(4000);
    r_territory   varchar2(4000);
    t_type        varchar2(100);
    t_name        varchar2(100);
    t_subject     varchar2(240);
    t_text_body   varchar2(4000);
    t_html_body   varchar2(4000);
    t_hdrRequired boolean;
    m_html        varchar2(32000);
    mailTo        VARCHAR2(32000);
    t_headerText   varchar2(32000);
    n_headerText   varchar2(32000);
    t_headerHTML   varchar2(32000);
    n_headerHTML   varchar2(32000);
    err_name      varchar2(30);
    err_message   varchar2(2000);
    err_stack     varchar2(4000);
    str_dummy     varchar2(4000) := NULL;
    fyi           pls_integer;
    body_start    pls_integer;
    body_end      pls_integer;
    tmp_start     pls_integer;
    tmp_end       pls_integer;
    tag_pos       pls_integer;
    dir_pos       pls_integer;
    start_cnt     pls_integer;
    end_cnt       pls_integer;
    str_length    pls_integer;
    end_of_message boolean;
    buffer        VARCHAR2(32000);

    no_program_unit exception;
    pragma exception_init(no_program_unit, -6508);
    dummy         varchar2(4000);
    -- Bug# 2301881 variables to handle invalid response error message
    err_invalid   varchar2(2000);
    err_expected  varchar2(2000);
    n_sig_policy     varchar2(100);
    n_nid_str        varchar2(200);
    -- More Info feature bug 2282139
    n_more_info_role varchar2(320);
    n_mailto         varchar2(10000);
    n_text_history   varchar2(32000);
    n_html_history   varchar2(32000);
    n_last_ques      varchar2(4000);
    n_dir            varchar2(16);

    step             varchar2(200);
    textForHtml      boolean;


    htmlBodyPos pls_integer;
    textBodyPos pls_integer;

begin
   -- 3532615 Moved these from being initialized at the session level
   -- back to the notification level.
   g_ntfHistory := wf_core.translate('WFNTF_HISTORY');
   g_ntfActionHistory := wf_core.translate('WFNTF_ACTION_HISTORY');
   g_moreInfoAPrompt := wf_core.translate('WFNTF_MOREINFO_APROMPT');
   g_moreInfoAnswer := wf_core.translate('WFNTF_MOREINFO_ANSWER');
   g_moreInfoQPrompt := wf_core.translate('WFNTF_MOREINFO_QPROMPT');
   g_moreInfoSubject := wf_core.translate('WFNTF_MOREINFO');
   g_moreInfoSubmit := wf_core.translate('WFNTF_MOREINFO_SUBMIT');
   g_moreInfoQuestion := wf_core.translate('WFNTF_MOREINFO_QUESTION');
   g_moreInfoFrom := wf_core.translate('WFNTF_MOREINFO_FROM');
   g_moreInfoRequested := wf_core.translate('WFNTF_MOREINFO_REQUESTED');
   g_moreInfoRequestee := wf_core.translate('WFNTF_MOREINFO_REQUESTEE');
   g_wfmonId := wf_core.translate('WFMON_ID');
   g_to := wf_core.translate('TO');
   g_from := wf_core.translate('FROM');
   g_beginDate := wf_core.translate('BEGIN_DATE');
   g_dueDate2 := wf_core.translate('DUE_DATE');
   g_notificationId := wf_core.translate('NOTIFICATION_ID');
   g_priority := wf_core.translate('PRIORITY');
   g_dueDate := wf_core.translate('WFMON_DUE_DATE');
   g_invalidRemarks :=  wf_core.translate('WFMLR_INVALID_REMARKS');
   g_forExample := wf_core.translate('WFMLR_FOR_EXAMPLE');
   g_soOn :=  wf_core.translate('WFMLR_SO_ON');
   g_none :=  wf_core.translate('WFMLR_NONE');
   g_truncate :=  wf_core.translate('WFNTF_TRUNCATE');
   g_noResult :=  wf_core.translate('WFNTF_NO_RESULT');
   g_Id := wf_core.translate('ID');

    step := 'Getting notification information';
    -- Get notification information
    begin
      select STATUS, MAIL_STATUS, ACCESS_KEY,
             PRIORITY, USER_COMMENT,
             BEGIN_DATE, END_DATE, DUE_DATE, FROM_USER,
             MORE_INFO_ROLE
      into   n_status, n_mstatus, n_key,
             n_priority, n_comment,
             n_start_date, n_end_date, n_due_date, n_from_user,
             n_more_info_role
      from   WF_NOTIFICATIONS
      where  NOTIFICATION_ID = nid;
    exception
      when no_data_found then
        wf_core.token('NID', to_char(nid));
        wf_core.raise('WFNTF_NID');
    end;

    n_to_role := recipient;
    r_language := language;
    r_territory := territory;
    r_ntf_pref := ntf_pref;
    r_email := email;
    r_dname := dname;

    if (wf_mail.test_flag = TRUE) then
        n_mstatus := 'MAIL';
        if (n_status not in ('OPEN','CANCELED','CLOSED')) then
           n_status := 'OPEN';
        end if;
     end if;

    -- More information processing
    g_moreinfo := NULL;
    if (wf_notification.HideMoreInfo(nid) = 'N') then
       if(n_more_info_role is not null) then
          n_to_role := n_more_info_role;
          g_to_role := n_more_info_role;
          -- Flags that template for More Info submission needs to be used
          g_moreinfo := 'SUB';
       else
          -- Flags that template for More Info request needs to be used
          g_to_role := n_to_role;
          g_moreinfo := 'REQ';
       end if;
    end if;

    r_ntf_pref := nvl(r_ntf_pref, 'QUERY');

    step := 'Getting Signature policy';
    -- Bug 2375920 get signature policy for the notification
    Wf_Mail.GetSignaturePolicy(nid, n_sig_policy);

    -- Bug 2375920 Process the email message based on the signature policy
    ProcessSignaturePolicy(nid, n_sig_policy, n_status, n_mstatus,
                           n_key, node, t_type, t_name, n_nid_str);

    if isBiDi(r_language) then
       WF_NOTIFICATION.Set_NTF_Table_Direction('R');
    else
       WF_NOTIFICATION.Set_NTF_Table_Direction('L');
    end if;

    -- PLSQL Action History for the notification will not be explicitly processed by the
    -- mailer now. The notification sub-system would handle this as part of GetFullBody.

    -- if (renderBody = 'Y') then
    --   step := 'Getting action history';
    --   Get_Action_History(nid, r_language, n_html_history, n_text_history,
    --                      n_last_ques);
    -- else
    Get_Last_Question(nid, n_last_ques);
    n_html_history := '';
    n_text_history := '';
    -- end if;

    step := 'Getting template';
    -- Get template
    begin
      select SUBJECT, BODY, HTML_BODY
      into   t_subject, t_text_body, t_html_body
      from   WF_MESSAGES_VL
      where  NAME = t_name and TYPE = t_type;
    exception
      when no_data_found then
        wf_core.token('NAME', t_name);
        wf_core.token('TYPE', t_type);
        wf_core.raise('WFNTF_MESSAGE');
    end;

    g_isFwkNtf := true;
    if (t_name in ('VIEW_FROMUI', 'VIEW_FROMUI_FYI')) then
       t_hdrRequired := TRUE;
    elsif renderBody = 'Y' then
       t_hdrRequired := TRUE;
       g_isFwkNtf := false;
    else
       t_hdrRequired := FALSE;
       g_isFwkNtf := true;
    end if;

    step := 'Getting timezone details';
    n_text_timezone := wf_mail_util.getTimezone(g_ntfDocText);
    n_html_timezone := wf_mail_util.getTimezone(g_ntfDocHtml);

    step := 'Getting subject';
    n_subject := WF_NOTIFICATION.GetSubject(nid, 'text/plain');

    -- We will always fetch plain text version of the message because
    -- Because for sendmail MAILATTH case, we need to send out html message
    -- body as attachment and then the plain text message as the body.
    -- For MAPI MAILATTH and MAILHTML cases, same thing.

    -- we will request a temp LOB from the pool only if necessary
    -- we donot need the text message if the ntf pref is MAILHTML
    -- this will reduce the time spent in unecessarily processing
    -- the text LOB Message
    t_headerText := '';
    t_headerHTML := '';
    step := 'Getting body';
    if (r_ntf_pref in ('MAILTEXT', 'MAILATTH')) then
       g_text_messageIdx := wf_temp_lob.getLob(g_LOBTable);
       if (renderbody = 'Y') then
          end_of_message := FALSE;
          step := 'Getting text/plain body';
          begin
             while not (end_of_message) loop
                WF_NOTIFICATION.GetFullBody(nid, buffer, end_of_message,
                                            g_ntfDocText);
                if buffer is not null and length(buffer) > 0 then
                   DBMS_LOB.WriteAppend(g_LOBTable(g_text_messageIdx).temp_lob,
                                        length(buffer), buffer);
                end if;
             end loop;
          exception
             when others then
                wf_core.context('WF_MAIL','GetLOBMessage3',
                                'nid => '||to_char(nid),
                                'r_ntf_pref => '||r_ntf_pref);
                wf_core.token('ERROR',sqlerrm);
                wf_core.raise('WFMLR_NTFERR');
          end;
          -- Get the table of header attributes. Use a PL/SQL document
          -- API format.
       end if; -- RENDERBODY
       if (t_hdrRequired = TRUE) then
          GetHeaderTable(r_language||':'||to_char(nid),
                         g_ntfDocText, t_headerText, str_dummy);
       end if;
    end if;

    if (r_ntf_pref in ('MAILHTML', 'MAILATTH', 'MAILHTM2')) then
       g_html_messageIdx := wf_temp_lob.getLob(g_LOBTable);
       if (renderbody = 'Y') then
          end_of_message := FALSE;
          step := 'Getting text/html body';
          begin
             while not (end_of_message) loop
                WF_NOTIFICATION.GetFullBody(nid, buffer, end_of_message,
                                            g_ntfDocHtml);
                if buffer is not null and length(buffer) > 0 then
                   DBMS_LOB.WriteAppend(g_LOBTable(g_html_messageIdx).temp_lob,
                                        length(buffer), buffer);
                end if;
             end loop;
           exception
              when others then
                 wf_core.context('WF_MAIL','GetLOBMessage3',
                                 'nid => '||to_char(nid),
                                 'r_ntf_pref => '||r_ntf_pref);
                 wf_core.token('ERROR',sqlerrm);
                 wf_core.raise('WFMLR_NTFERR');
           end;

       end if; -- RENDERBODY
       if (t_hdrRequired = TRUE) then
          GetHeaderTable(r_language||':'||to_char(nid),
                         g_ntfDocHtml, t_headerHTML, str_dummy);
       end if;
    end if;


    step := 'Getting click-here section';
    -- Get Click here Response display value
    begin
      select DESCRIPTION
        into n_disp_click
        from WF_MESSAGE_ATTRIBUTES_TL
       where MESSAGE_TYPE = t_type
         and MESSAGE_NAME = t_name
         and NAME = 'CLICK_HERE_RESPONSE'
         and LANGUAGE = userenv('LANG');
    exception
      when NO_DATA_FOUND then
        -- ignore if this attribute does not exist
        null;
    end;

    step := 'Getting error information for invalid response';
    -- Retrieve error attributes for INVALID message
    -- Bug# 2301881 Replacing err_stack with err_invalid and err_expected
    --              to make the WARNING message to the responder more
    --              user-friendly
    if (t_name in ('OPEN_INVALID', 'OPEN_INVALID_MORE_INFO')) then
      begin
        err_name := Wf_Notification.GetAttrText(nid, 'MAIL_ERROR_NAME');
        err_message := Wf_Notification.GetAttrText(nid, 'MAIL_ERROR_MESSAGE');
        err_invalid := Wf_Notification.GetAttrText(nid, 'MAIL_VALUE_FOUND');
        err_expected := Wf_Notification.GetAttrText(nid, 'MAIL_EXP_VALUES');
      exception
        when others then null;
      end;
    end if;

    -- If there is no html template available, use the plain text one.
    step := 'Setting content to the template';
    if (t_html_body is null) then
      t_html_body := replace(t_text_body, g_newLine,
                             '<BR>'||g_newLine);
      -- Ensure the direction of the text is correct for the language
      textForHtml := true;
      if isBiDi(r_language) then
         t_html_body := '<HTML DIR="RTL"><BODY>'||t_html_body;
      else
         t_html_body := '<HTML><BODY>'||t_html_body;
      end if;
    else
      -- Ensure that the direction of the text is correctly specified.
      if isBiDi(r_language) then
         tag_pos := instrb(upper(t_html_body), '<HTML', 1);
         if tag_pos > 0 then
           dir_pos := instrb(upper(t_html_body), ' DIR="', 1);
           if dir_pos = 0 then
              buffer := substrb(t_html_body, 1, tag_pos+4);
              buffer := buffer||' DIR="RTL" '||substrb(t_html_body, tag_pos+5);
              t_html_body := buffer;
           end if;
         end if;
      end if;
    end if;
    -- DBMS_LOB.Write(template_html, length(t_html_body), 1, t_html_body);

    if wf_mail.direct_response then
       n_direct := '[2]';
    else
       n_direct := NULL;
    end if;

    -- More info feature
    if (g_moreinfo = 'SUB') then
       n_response := g_moreInfoAPrompt || ': '||wf_mail.g_open_text_delimiter||
                     '<' ||
                     g_moreInfoAnswer ||'>'||wf_mail.g_close_text_delimiter;
       n_response := n_response || g_newLine;
    else
       if wf_mail.direct_response then
          n_response :=  GetEmailDirectResponse(nid);
       else
          n_response :=  GetEmailResponse(nid);
       end if;
    end if;

    -- Substitute

    htmlBodyPos := instrb(t_html_body, '&'||'BODY',1, 1);
    textBodyPos := instrb(t_text_body, '&'||'BODY',1, 1);

    if (htmlBodyPos > 0 or textBodyPos > 0) then
       bodyToken := 'Y';
    else
       bodyToken := 'N';
    end if;

    step := 'Performing token substitution';
    n_subject := Substitute(t_subject, nid, n_nid_str,
                            n_status, n_to_role, r_dname, r_email,
                            n_start_date, n_due_date, n_end_date, n_from_user,
                            n_priority, n_comment, n_subject, str_dummy,
                            str_dummy, err_name, err_message, err_invalid,
                            err_expected, n_text_timezone);

    if (r_ntf_pref in ('MAILTEXT', 'MAILATTH')) then

       n_headerText := Substitute(t_headerText, nid, n_nid_str,
                            n_status, n_to_role, r_dname, r_email,
                            n_start_date, n_due_date, n_end_date, n_from_user,
                            n_priority, n_comment, n_subject, str_dummy,
                            str_dummy, err_name, err_message, err_invalid,
                            err_expected, n_text_timezone);
       LOBSubstitute(t_text_body, nid, n_nid_str,
                            n_status, n_to_role, r_dname, r_email,
                            n_start_date, n_due_date, n_end_date, n_from_user,
                            n_priority, n_comment, n_subject, n_headerText,
                            g_LOBTable(g_text_messageIdx).temp_lob,
                            err_name, err_message, err_invalid,
                            err_expected, n_text_timezone);

       -- Wrap the body into nice pretty lines.
       LOBLineBreak(g_LOBTable(g_text_messageIdx).temp_lob, wf_linelen, 999);

       -- Add email response section
       LOBReplace(g_LOBTable(g_text_messageIdx).temp_lob,
                  '&'||'RESPONSE', n_response, FALSE);

       -- More Information Processing - Bug 2282139
       LOBReplace(g_LOBTable(g_text_messageIdx).temp_lob,
                             '&'||'HISTORY', n_text_history, FALSE);
       LOBReplace(g_LOBTable(g_text_messageIdx).temp_lob,
                  '&'||'QUESTION', n_last_ques, FALSE);
    end if;

    if (r_ntf_pref in ('MAILHTML', 'MAILATTH', 'MAILHTM2')) then

       n_headerHTML := Substitute(t_headerHTML, nid, n_nid_str,
                            n_status, n_to_role, r_dname, r_email,
                            n_start_date, n_due_date, n_end_date, n_from_user,
                            n_priority, n_comment, n_subject, str_dummy,
                            str_dummy, err_name, err_message, err_invalid,
                            err_expected, n_html_timezone);

       LOBSubstitute(t_html_body, nid, n_nid_str,
                            n_status, n_to_role, r_dname, r_email,
                            n_start_date, n_due_date, n_end_date,
                            n_from_user, n_priority, n_comment,
                            UrlEncode(n_subject), n_headerHTML,
                            g_LOBTable(g_html_messageIdx).temp_lob,
                            err_name, err_message, err_invalid,
                            err_expected, n_html_timezone);

       -- Add the local stylesheet references.
       LOBReplace(g_LOBTable(g_html_messageIdx).temp_lob,
                             '&'||'TEMPLATE_STYLE', g_template_style, FALSE);

       -- Add email response section
       LOBReplace(g_LOBTable(g_html_messageIdx).temp_lob,
                             '&'||'RESPONSE', n_response, FALSE);

       -- More Information processing
       LOBReplace(g_LOBTable(g_html_messageIdx).temp_lob,
                             '&'||'HISTORY', n_html_history, FALSE);
       LOBReplace(g_LOBTable(g_html_messageIdx).temp_lob,
                             '&'||'QUESTION', n_last_ques, FALSE);

       -- Add mailto section
       if (g_moreinfo = 'SUB') then
          n_mailto := GetMoreInfoMailTo(nid, 'NID['||to_char(nid)||'/'
                                 ||n_key||'@'||node||']', replyTo, n_subject);
          LOBReplace(g_LOBTable(g_html_messageIdx).temp_lob,
                                '&'||'MAILTO', n_mailto, FALSE);
       else
          GetMailTo(nid, 'NID['||to_char(nid)||'/'||n_key||'@'||
                    node||']', replyTo, n_subject,
                    g_LOBTable(g_html_messageIdx).temp_lob);
       end if;

       -- If GUEST access is enabled and signature is required for response,
       -- no click here reponse link is provided to discourage signing under
       -- GUEST login
       if (g_sig_required = 'Y' and wf_mail.Send_AccessKey) then
         n_click_here := '';
       else
         n_click_here := getClickHereResponse(nid => nid, n_key => n_key,
                                              agent => agent,
                                              n_disp_click => n_disp_click,
                                              n_sig_policy => n_sig_policy);
       end if;

       LOBReplace(g_LOBTable(g_html_messageIdx).temp_lob,
                   '&'||'CLICK_HERE_RESPONSE', n_click_here, FALSE);

        -- Close of the HTML Body only where this is none
        -- This is only done for those tempaltes that the html/body tag
        -- was added. Otherwise there is a clash where there is nested
        -- HTML. Since this is rendered in a LOB, there should be no
        -- cause for the exising end /body tag should drop off the end
        -- like what would happen in the varchar2 version.
        if textForHtml then
           DBMS_LOB.WriteAppend(g_LOBTable(g_html_messageIdx).temp_lob,
                                length('</BODY></HTML>'), '</BODY></HTML>');
        end if;

    end if;

    step := 'Getting HTML attachment';
     -- Get HTML attachment
     m_html := substrb(WFA_HTML.Detail2(nid, n_key, agent), 1, 32000);
     if isBiDi(r_language) then
        tag_pos := instrb(upper(m_html), '<HTML', 1);
        if tag_pos > 0 then
          dir_pos := instrb(upper(m_html), ' DIR="', 1);
          if dir_pos = 0 then
             buffer := substrb(m_html, 1, 5);
             buffer := buffer||' DIR="RTL" '||substrb(m_html, tag_pos+5);
             m_html := buffer;
          end if;
        end if;
     end if;

    subject   := n_subject;
    -- text_body := n_text_body;
    -- html_body := n_html_body;
    -- this is for the little attachment to the detail frame
    body_atth := m_html;

    -- if (DBMS_LOB.IsOpen(template_text)=1) then
    --   DBMS_LOB.Close(template_text);
    --   DBMS_LOB.FreeTemporary(template_text);
    -- end if;
    -- if (DBMS_LOB.IsOpen(template_html)=1) then
    --    DBMS_LOB.Close(template_html);
    --    DBMS_LOB.FreeTemporary(template_html);
    -- end if;
exception
  when no_program_unit then
    wf_core.context('WF_MAIL', 'GetLOBMessage3', to_char(nid), node,
                    'step -> '||step);
    raise;
  when others then
    -- First look for a wf_core error.
    wf_core.get_error(err_name, err_message, err_stack);

    -- If no wf_core error look for a sql error.
    if (err_name is null) then
        err_message := sqlerrm;
    end if;

    error_result := err_message||g_newLine||err_stack;
    wf_core.context('WF_MAIL', 'GetLOBMessage3', to_char(nid), node,
                    error_result, 'Step -> '||step);
end GetLOBMessage3;


-- GetLOBMessage2 - get email message data as a LOB
--
-- IN
--   notification id
--   mailer node name
--   web agent path
--   reply to
--   recipient role
--   lanague
--   territory
--   notification preference
--   dsiplay name
-- OUT
--   message subject
--   message body (text)
--   message body (html)
procedure GetLOBMessage2(
    nid       in  number,
    node      in  varchar2,
    agent     in  varchar2,
    replyto   in  varchar2,
    recipient in varchar2,
    language  in varchar2,
    territory in varchar2,
    ntf_pref  in varchar2,
    email     in varchar2,
    dname     in varchar2,
    subject   out NOCOPY varchar2,
    body_atth out NOCOPY varchar2,
    error_result in out NOCOPY varchar2)
as

    err_name      varchar2(30);
    err_message   varchar2(2000);
    err_stack     varchar2(4000);

    bodyToken varchar2(1);

    no_program_unit exception;
    pragma exception_init(no_program_unit, -6508);

begin

   wf_mail.getLobMessage3(nid, node, agent, replyto, recipient, language,
                          territory, ntf_pref, email, dname, 'Y',
                          subject, body_atth, error_result, bodyToken);

exception
  when no_program_unit then
    wf_core.context('WF_MAIL', 'GetLOBMessage2', to_char(nid), node);
    raise;
  when others then
    -- First look for a wf_core error.
    wf_core.get_error(err_name, err_message, err_stack);

    -- If no wf_core error look for a sql error.
    if (err_name is null) then
        err_message := sqlerrm;
    end if;

    error_result := err_message||g_newLine||err_stack;
    wf_core.context('WF_MAIL', 'GetLOBMessage2', to_char(nid), node,
                    error_result);

end getLOBMessage2;


-- GetLOBMessage - get email message data as a LOB
--
-- IN
--   notification id
--   mailer node name
--   web agent path
-- OUT
--   message subject
--   message body (text)
--   message body (html)
procedure GetLOBMessage(
    nid       in  number,
    node      in  varchar2,
    agent     in  varchar2,
    replyto   in  varchar2,
    subject   out NOCOPY varchar2,
    body_atth out NOCOPY varchar2,
    error_result in out NOCOPY varchar2)
as
    n_to_role     varchar2(320);
    r_dname       varchar2(360);
    r_email       varchar2(2000);
    r_ntf_pref    varchar2(240);
    r_language    varchar2(30);
    r_territory   varchar2(30);
    r_orig_system varchar2(30);
    r_orig_system_id number;
    r_installed   varchar2(1);
    err_name      varchar2(30);
    err_message   varchar2(2000);
    err_stack     varchar2(4000);

    no_program_unit exception;
    pragma exception_init(no_program_unit, -6508);

begin
    -- Get notification information
    begin
      select RECIPIENT_ROLE
      into   n_to_role
      from   WF_NOTIFICATIONS
      where  NOTIFICATION_ID = nid;
    exception
      when no_data_found then
        wf_core.token('NID', to_char(nid));
        wf_core.raise('WFNTF_NID');
    end;

    -- Get Recipient information
    Wf_Directory.GetRoleInfoMail(n_to_role, r_dname, r_email, r_ntf_pref,
                                 r_language, r_territory, r_orig_system,
                                 r_orig_system_id, r_installed);

   if r_installed = 'N' then
      r_language := 'AMERICAN';
      r_territory := 'AMERICA';
   end if;

   wf_mail.getLobMessage2(nid, node, agent, replyto, n_to_role, r_language,
                          r_territory, r_ntf_pref, r_email, r_dname,
                          subject, body_atth, error_result);

exception
  when no_program_unit then
    wf_core.context('WF_MAIL', 'GetLOBMessage', to_char(nid), node);
    raise;
  when others then
    -- First look for a wf_core error.
    wf_core.get_error(err_name, err_message, err_stack);

    -- If no wf_core error look for a sql error.
    if (err_name is null) then
        err_message := sqlerrm;
    end if;

    error_result := err_message||g_newLine||err_stack;
    wf_core.context('WF_MAIL', 'GetLOBMessage', to_char(nid), node,
                    error_result);
end GetLOBMessage;

-- GetSummary - get summary messages for one role
--              ( with LOB support )
-- IN
--   role name
--   display role name
--   mailer node name
-- OUT
--   message subject
--   message body (text)
--   message body (html)
procedure GetSummary(
    role      in  varchar2,
    dname     in  varchar2,
    node      in  varchar2,
    subject   out NOCOPY varchar2,
    body_text out NOCOPY varchar2)
as
    lob varchar2(1);
begin
    GetSummary(role, dname, node, subject, body_text,lob);
    if lob = 'Y' then
       wf_core.context('WF_MAIL', 'GetSummary', role, node);
       wf_core.raise('WFMLR_SUMMARY_TOOBIG');
    end if;
exception
  when others then
    wf_core.context('WF_MAIL', 'GetSummary', role, node);
    raise;
end GetSummary;

-- GetSummary2 - get summary messages for one role
-- Support the render flag for Applications Framework.
-- If set, no body will be rendered as it will be
-- deferred to the middle tier.
-- IN
--   role name
--   display role name
--   mailer node name
--   content type
-- OUT
--   message subject
--   message body (text)
--   message body (html)
--   lob (Y or N)
procedure GetSummary2(
    role      in  varchar2,
    dname     in  varchar2,
    node      in  varchar2,
    renderBody in varchar2,
    contType  in  varchar2,
    subject   out NOCOPY varchar2,
    body_text out NOCOPY varchar2,
    lob       out NOCOPY varchar2)
as
    n_key         varchar2(80);
    n_subject     varchar2(240);
    n_summ        varchar2(32000);
    n_buf         varchar2(32000);
    templateName  varchar2(30);
    altTempl      varchar2(40);
    templateType  varchar2(8) := 'WFMAIL';
    t_subject     varchar2(240);
    t_body        varchar2(32000);
    t_timezone    varchar2(240);
    t_html_body   varchar2(32000);
    n_timezone    varchar2(240);
    nid           pls_integer;
    to_name       varchar2(320);
    colon         pls_integer;
    rorig_system  varchar2(30);
    rorig_system_id number;
    priority_text varchar2(240);

    ntf_pref      varchar2(240);
    dummyStr      varchar2(2000);
    r_language    varchar2(30);
    r_displayName varchar2(360);
    tag_pos       pls_integer;
    dir_pos       pls_integer;
    buffer        varchar2(32000);


    lob_init      boolean := FALSE;
    -- temp_text     CLOB;
    temp_textIdx  pls_integer;

    -- Bug 1753464 included sort order for the query
    -- Bug 2439529 Altered query to use UNION instead of OR.
    cursor c1 is
      select NOTIFICATION_ID, RECIPIENT_ROLE, ACCESS_KEY, PRIORITY, DUE_DATE
      from WF_NOTIFICATIONS
      where STATUS = 'OPEN'
        and RECIPIENT_ROLE IN
             (select role from dual
              union
              select UR.ROLE_NAME
              from WF_USER_ROLES UR
              where UR.USER_ORIG_SYSTEM = rorig_system
                and UR.USER_ORIG_SYSTEM_ID = rorig_system_id
                and UR.USER_NAME = role)
      order by PRIORITY desc, DUE_DATE asc, NOTIFICATION_ID asc ;

begin
    g_wfmonId := wf_core.translate('WFMON_ID');
    g_to := wf_core.translate('TO');
    g_priority := wf_core.translate('PRIORITY');
    g_dueDate := wf_core.translate('WFMON_DUE_DATE');

    -- Bug# 2358498 - flag to indicate if the sumamry is LOB
    lob := 'N';

    if (renderBody = 'Y') then
       templateName := 'SUMMARY';
    else
       templateName := 'SUMHTML';
    end if;

    -- We have the basic template name. Now check to see if has been
    -- redirected using a mailer configuration parameter of the same name.
    altTempl := WF_MAILER_PARAMETER.GetValueForCorr('WFMAIL', templateName);
    colon := instrb(altTempl, ':', 1);
    if colon > 0 then
       templateType := substrb(altTempl, 1, colon -1);
       templateName := substrb(altTempl, colon + 1, length(altTempl)-colon);
    end if;

    -- Get notification information

    -- Get template 'SUMMARY'
    begin
      select SUBJECT, BODY, HTML_BODY
      into   t_subject, t_body, t_html_body
      from   WF_MESSAGES_VL
      where  NAME = templateName
      and    TYPE = templateType;
    exception
      when no_data_found then
        wf_core.token('NAME', templateName);
        wf_core.token('TYPE', templateType);
        wf_core.raise('WFNTF_MESSAGE');
    end;

    -- Retrieve role orig_system ids for index access
    Wf_Directory.GetRoleInfoMail(role, r_displayName, dummyStr, ntf_pref,
                                 r_language, dummyStr, rorig_system,
                                 rorig_system_id, dummyStr);

    t_subject := substrb(replace(t_subject, '&'||'USER_NAME',
                         r_displayName), 1, 240);

    if (rorig_system is null or rorig_system = '') then
      wf_core.token('ROLE', role);
      wf_core.raise('WFNTF_ROLE');
    end if;

    if contType = g_ntfDocHtml then
       if (t_html_body is null) then
         t_html_body := replace(t_body, g_newLine,
                                '<BR>'||g_newLine);
         -- Ensure the direction of the text is correct for the language
         if isBiDi(r_language) then
            t_html_body := '<HTML DIR="RTL"><BODY>'||t_html_body;
         else
            t_html_body := '<HTML><BODY>'||t_html_body;
         end if;
       else
         -- Ensure that the direction of the text is correctly specified.
         if isBiDi(r_language) then
            tag_pos := instrb(upper(t_html_body), '<HTML', 1);
            if tag_pos > 0 then
              dir_pos := instrb(upper(t_html_body), ' DIR="', 1);
              if dir_pos = 0 then
                 buffer := substrb(t_html_body, tag_pos, 5);
                 buffer := buffer||' DIR="RTL" '||
                           substrb(t_html_body, tag_pos+5);
                 t_html_body := buffer;
              end if;
            end if;
         end if;
       end if;
    end if;


    -- Substitute USER_NAME with role display name
    t_timezone := wf_mail_util.getTimezone(contType);

    if contType = g_ntfDocText then
       t_body := substrb(replace(t_body, '&'||'USER_NAME', dname), 1, 32000);
       t_body := substrb(replace(t_body, '&'||'TIMEZONE', t_timezone), 1, 32000);
    else
       t_html_body := substrb(replace(t_html_body, '&'||'TEMPLATE_STYLE',
                              g_template_style), 1, 32000);
       t_html_body := substrb(replace(t_html_body, '&'||'USER_NAME', dname),
                              1, 32000);
       t_html_body := substrb(replace(t_html_body, '&'||'TIMEZONE',
                              t_timezone), 1, 32000);
    end if;

    if (renderBody = 'Y') then
       -- Prepare summary header
       if contType = g_ntfDocText then
          n_summ := g_newLine;
          n_summ := n_summ||rpad(g_wfmonId, 7)||' ';
          n_summ := n_summ||rpad(g_to, 42)||' ';
          n_summ := n_summ||rpad(g_priority, 12)||' ';
          n_summ := n_summ||rpad(g_dueDate, 12)||
                            g_newLine;
          n_summ := n_summ||'------- ------------------------------------------ ';
          n_summ := n_summ||'------------ ------------'||g_newLine;

          n_buf  := '';
       end if;


       for rec in c1 loop

         nid := rec.notification_id;
         n_key := rec.access_key;
         to_name := rec.recipient_role;

         -- Get and token subsitute subject
         n_subject := WF_NOTIFICATION.GetSubject(nid, 'text/plain');

         if contType = g_ntfDocText then
            n_buf := lpad(to_char(nid), 7, ' ')||' '||
                     rpad(substr(dname, 1, 42), 42, ' ')||' ';
            if (rec.priority > 66) then
              --Bug 2774891 fix - sacsharm
              --priority_text := wf_core.substitute('WFTKN', 'HIGH');
              priority_text := wf_core.substitute('WFTKN', 'LOW');
            elsif (rec.priority > 33) then
              priority_text := wf_core.substitute('WFTKN', 'NORMAL');
            else
              --Bug 2774891 fix - sacsharm
              --priority_text := wf_core.substitute('WFTKN', 'LOW');
              priority_text := wf_core.substitute('WFTKN', 'HIGH');
            end if;

            n_buf := n_buf||lpad(priority_text, 12, ' ');
            n_buf := n_buf||' '||to_char(rec.due_date)||g_newLine;
            n_buf := n_buf||WordWrap(n_subject, 1);

            n_summ := n_summ||n_buf||g_newLine||g_newLine;
         end if;

         -- Bug 2358498 write content to LOB if there is a possibility
         -- that the size might go beyond 32K
         if length(n_summ) > 30000 then
           lob := 'Y';
           if NOT lob_init then
             lob_init := TRUE;
             -- DBMS_LOB.CreateTemporary(g_text_message, TRUE, DBMS_LOB.SESSION);
             -- DBMS_LOB.Open(g_text_message, DBMS_LOB.LOB_READWRITE);
             g_text_messageIdx := wf_temp_lob.getLob(g_LOBTable);
             if contType = g_ntfDocText then
                DBMS_LOB.WriteAppend(g_LOBTable(g_text_messageIdx).temp_lob,
                                     length(t_body), t_body);
             else
                DBMS_LOB.WriteAppend(g_LOBTable(g_text_messageIdx).temp_lob,
                                     length(t_html_body), t_html_body);
             end if;

             -- DBMS_LOB.CreateTemporary(temp_text, FALSE, DBMS_LOB.CALL);
             temp_textIdx := wf_temp_lob.getLob(g_LOBTable);
           end if;
           DBMS_LOB.WriteAppend(g_LOBTable(temp_textIdx).temp_lob,
                                length(n_summ), n_summ);
           n_summ := '';
         end if;
       end loop;
       if lob = 'Y' then
          t_body := '';
          t_html_body := '';
          DBMS_LOB.WriteAppend(g_LOBTable(temp_textIdx).temp_lob,
                               length(n_summ), n_summ);
          LOBReplace(g_LOBTable(g_text_messageIdx).temp_lob, '&'||'SUMMARY',
                     g_LOBTable(temp_textIdx).temp_lob, FALSE);
       else
          t_body := replace(t_body, '&'||'SUMMARY', n_summ);
       end if;
    end if; -- RENDERBODY

    subject   := t_subject;
    if contType = g_ntfDocText then
       body_text := t_body;
    else
       body_text := t_html_body;
    end if;

exception
  when others then
    wf_core.context('WF_MAIL', 'GetSummary2', role, node, contType);
    raise;
end GetSummary2;

-- GetSummary - get summary messages for one role
--              ( with LOB support )
-- IN
--   role name
--   display role name
--   mailer node name
-- OUT
--   message subject
--   message body (text)
--   message body (html)
--   lob (Y or N)
procedure GetSummary(
    role      in  varchar2,
    dname     in  varchar2,
    node      in  varchar2,
    subject   out NOCOPY varchar2,
    body_text out NOCOPY varchar2,
    lob       out NOCOPY varchar2)
as

begin
   GetSummary2(role, dname, node, 'Y', 'text/plain', subject, body_text, lob);
exception
  when others then
    wf_core.context('WF_MAIL', 'GetSummary', role, node);
    raise;
end GetSummary;


-- initFetchLOB
--
-- IN
-- Document type (TEXT or HTML)
--
procedure InitFetchLOB(doc_type VARCHAR2,
                       doc_length OUT NOCOPY NUMBER)
is
begin
   if doc_type = g_ntfDocHtml then
      g_html_chunk := 0;
      -- doc_length := DBMS_LOB.GetLength(g_html_message);
      doc_length := DBMS_LOB.GetLength(g_LOBTable(g_html_messageIdx).temp_lob);
   else
      -- Always assume that the caller wants the TEXT
      g_text_chunk := 0;
      -- doc_length := DBMS_LOB.GetLength(g_text_message);
      doc_length := DBMS_LOB.GetLength(g_LOBTable(g_text_messageIdx).temp_lob);
   end if;
end InitFetchLOB;


-- FetchLOBContent
--
-- IN
-- type of document to fetch TEXT/HTML
-- End of LOB marker
-- OUT
-- 32K chunk of the LOB
--
-- Use the API in the following manner
-- WF_MAIL.InitFetchLob(g_ntfDocText)
-- while not clob_end loop
--    WF_MAIL.FetchLobContent(cBuf, g_ntfDocText, clob_end);
--    ...
-- end loop;
--
procedure FetchLOBContent(buffer OUT NOCOPY VARCHAR2,
                          doc_type IN VARCHAR2,
                          end_of_clob IN OUT NOCOPY NUMBER)
is
   pos NUMBER;
   buffer_length pls_integer := 16000;
begin
   if doc_type = g_ntfDocHtml then
      pos := (buffer_length * nvl(g_html_chunk,0))+1;
      -- DBMS_LOB.Read(g_html_message, buffer_length, pos, buffer);
      DBMS_LOB.Read(g_LOBTable(g_html_messageIdx).temp_lob, buffer_length, pos, buffer);
      if pos+buffer_length > DBMS_LOB.GetLength(g_LOBTable(g_html_messageIdx).temp_lob) then
         end_of_clob := 1;
         g_html_chunk := 0;
      else
         g_html_chunk := g_html_chunk + 1;
      end if;
   else
      -- Always assume that the caller wants the TEXT
      pos := (buffer_length * nvl(g_text_chunk,0))+1;
      -- DBMS_LOB.Read(g_text_message, buffer_length, pos, buffer);
      DBMS_LOB.Read(g_LOBTable(g_text_messageIdx).temp_lob, buffer_length, pos, buffer);
      if pos+buffer_length > DBMS_LOB.GetLength(g_LOBTable(g_text_messageIdx).temp_lob) then
         end_of_clob := 1;
         g_text_chunk := 0;
      else
         g_text_chunk := g_text_chunk + 1;
      end if;
   end if;
exception
  when others then
      WF_CORE.Context('WF_MAIL','FetchLOBContent',doc_type,
                      to_char(pos)||':'||buffer);
      raise;
end FetchLOBContent;

-- CloseLOB - Close the message LOBs ready for use again later
--
procedure CloseLOB(doc_type in VARCHAR2)
is
begin
   if doc_type = g_ntfDocHtml then
      -- DBMS_LOB.close(g_html_message);
      -- DBMS_LOB.FreeTemporary(g_html_message);
      wf_temp_lob.releaseLob(g_LOBTable, g_html_messageIdx);
   else
      -- DBMS_LOB.close(g_text_message);
      -- DBMS_LOB.FreeTemporary(g_text_message);
      wf_temp_lob.releaseLob(g_LOBTable, g_text_messageIdx);
   end if;
exception
   when others then
      WF_CORE.Context('WF_MAIL','CloseLOB', doc_type);
      raise;
end;

-- CloseLOB - Close the message LOBs ready for use again later
--
procedure CloseLOB
is
begin
   WF_MAIL.CloseLOB(g_ntfDocText);
   WF_MAIL.CloseLOB(g_ntfDocHtml);
exception
   when others then
      WF_CORE.Context('WF_MAIL','CloseLOB');
      raise;
end;


-- FetchUrlContent - Fetched the content from the global buffer which
--                   populated by GetUrlContent().
--
-- IN
--   piece_count - the index to the url_content_array.
-- OUT
--   piece_value - the data stored in the global content_array table.
function FetchUrlContent(piece_count in number,
                         error_result in out NOCOPY varchar2) return varchar2 as
begin
    return(wf_mail.content_array(piece_count));

exception
  when NO_DATA_FOUND then
    return('NO_DATA_FOUND');

  when others then
    error_result := sqlerrm;
    wf_core.context('WF_MAIL', 'FetchUrlContent', piece_count);

end FetchUrlContent;


-- GetUrlContent - get URL content
--
-- IN
--   url address id
-- OUT
--   piece_count
--   error result
procedure GetUrlContent(
    url          in  varchar2,
    piece_count  out NOCOPY number,
    error_result in out NOCOPY varchar2)

as
    no_program_unit exception;
    pragma exception_init(no_program_unit, -6508);

    url_pieces utl_http.html_pieces;
    err_name      varchar2(30);
    err_message   varchar2(2000);
    err_stack     varchar2(4000);
    content_array url_content_array;

begin

    url_pieces := utl_http.request_pieces(url);

    for l_rec_num in 1..url_pieces.count loop
        wf_mail.content_array(l_rec_num) := url_pieces(l_rec_num);
        piece_count := l_rec_num;
    end loop;

exception

  when utl_http.init_failed then
    error_result := 'UTL_HTTP.INIT_FAILED';
    error_result := error_result || sqlerrm;
    wf_core.context('WF_MAIL', 'GetUrlContent', url);

  when utl_http.request_failed then
    error_result := 'UTL_HTTP.REQUEST_FAILED';
    error_result := error_result || sqlerrm;
    wf_core.context('WF_MAIL', 'GetUrlContent', url);

  when no_program_unit then
    wf_core.context('WF_MAIL', 'GetUrlContent', url);
    raise;
  when others then
    error_result := sqlerrm;
    wf_core.context('WF_MAIL', 'GetUrlContent', url);

end GetUrlContent;

-- GetDocContent - get Document content
--
-- IN
--   notification id
--   document attribute name
--   display type
-- OUT
--   document content
--   error result
procedure GetDocContent(
    nid          in  number,
    docattrname  in  varchar2,
    disptype     in  varchar2,
    doccontent   out NOCOPY varchar2,
    error_result in out NOCOPY varchar2)

as
    no_program_unit exception;
    pragma exception_init(no_program_unit, -6508);

    err_name      varchar2(30);
    err_message   varchar2(2000);
    err_stack     varchar2(4000);
begin

    doccontent := Wf_Notification.GetAttrDoc(nid, docattrname, disptype);

exception
  when no_program_unit then
    wf_core.context('WF_MAIL', 'GetDocContent', docattrname);
    raise;
  when others then
    -- First look for a wf_core error.
    wf_core.get_error(err_name, err_message, err_stack);

    -- If no wf_core error look for a sql error.
    if (err_name is null) then
        err_message := sqlerrm;
    end if;

    error_result := err_message;
    wf_core.context('WF_MAIL', 'GetDocContent', docattrname);

end GetDocContent;

-- GetLOBDocContent - get Document content
--   Returns the document type of the PLSQLCLOB document
--
-- IN
--   notification id
--   document attribute name
--   display type
-- OUT
--   document content
--   error result
procedure GetLOBDocContent(
    nid          in  number,
    docattrname  in  varchar2,
    disptype     in  varchar2,
    error_result in out NOCOPY varchar2)
as
  doctype varchar2(500);
  no_program_unit exception;
  pragma exception_init(no_program_unit, -6508);
  err_name      varchar2(30);
  err_message   varchar2(2000);
  err_stack     varchar2(4000);
begin

  Wf_Mail.GetLOBDocContent(nid, docattrname, disptype, doctype, error_result);

exception
  when no_program_unit then
    wf_core.context('WF_MAIL', 'oldGetLOBDocContent', docattrname);
    raise;
  when others then
    -- First look for a wf_core error.
    wf_core.get_error(err_name, err_message, err_stack);

    -- If no wf_core error look for a sql error.
    if (err_name is null) then
        err_message := sqlerrm;
    end if;

    error_result := err_message;
    wf_core.context('WF_MAIL', 'oldGetDocLOBContent', docattrname);
end GetLOBDocContent;

-- GetLOBDocContent - get Document content
--
-- IN
--   notification id
--   document attribute name
--   display type
-- OUT
--   document type
--   document content
--   error result
procedure GetLOBDocContent(
    nid          in  number,
    docattrname  in  varchar2,
    disptype     in  varchar2,
    doctype      out NOCOPY varchar2,
    error_result in  out NOCOPY varchar2)

as
    no_program_unit exception;
    pragma exception_init(no_program_unit, -6508);

    doc varchar(32000) := '';

    aname         varchar2(30);
    err_name      varchar2(30);
    err_message   varchar2(2000);
    err_stack     varchar2(4000);
begin
    -- There is a difference betwen PLSQL: and PLSQLCLOB: documents
    -- First go for the PLSQL: if that returns the name of the
    -- attribute, then try the PLSQLCLOB:
    doc := WF_NOTIFICATION.GetAttrDoc(nid, docattrname, disptype);
    if disptype = g_ntfDocHtml then
       -- DBMS_LOB.CreateTemporary(g_html_message, true, dbms_lob.SESSION);
       -- DBMS_LOB.Open(g_html_message, DBMS_LOB.LOB_READWRITE);
       g_html_messageIdx := wf_temp_lob.getLob(g_LOBTable);
       if doc = '&'||docattrname then
          Wf_Notification.GetAttrCLOB(nid, docattrname, disptype,
                                      g_LOBTable(g_html_messageIdx).temp_lob, doctype, aname);
       else
          DBMS_LOB.Write(g_LOBTable(g_html_messageIdx).temp_lob, length(doc), 1, doc);
       end if;
    else
       -- DBMS_LOB.CreateTemporary(g_text_message, true, dbms_lob.SESSION);
       -- DBMS_LOB.Open(g_text_message, DBMS_LOB.LOB_READWRITE);
       g_text_messageIdx := wf_temp_lob.getLob(g_LOBTable);
       if doc = '&'||docattrname then
          Wf_Notification.GetAttrCLOB(nid, docattrname, disptype,
                                      g_LOBTable(g_text_messageIdx).temp_lob, doctype,  aname);
       else
          DBMS_LOB.Write(g_LOBTable(g_text_messageIdx).temp_lob, length(doc), 1, doc);
       end if;
    end if;


exception
  when no_program_unit then
    wf_core.context('WF_MAIL', 'GetLOBDocContent', docattrname);
    raise;
  when others then
    -- First look for a wf_core error.
    wf_core.get_error(err_name, err_message, err_stack);

    -- If no wf_core error look for a sql error.
    if (err_name is null) then
        err_message := sqlerrm;
    end if;

    error_result := err_message;
    wf_core.context('WF_MAIL', 'GetDocLOBContent', docattrname);

end GetLOBDocContent;

-- RemoveSpace (PRIVATE)
--   Removes white spaces between response prompt and colon, from colon
--   to the quote.
-- IN
--   body       - Email response body
--   resp_attrs - Response attribtue info for the current notification
-- OUT
--   body - Email body with the white spaces removed wherever required

function RemoveSpace(body       in varchar2,
                     resp_attrs in resp_attrs_t)
return varchar2
is
  colonPos pls_integer;
  quotePos pls_integer;
  prompPos  pls_integer;
  prompt    varchar2(80);
  tmpStr   varchar2(32000);
  tmpBody  varchar2(32000);

begin

  tmpBody := body;

  -- remove spaces from the response prompt till the following colon
  for i in 1..resp_attrs.COUNT loop
     prompt := resp_attrs(i).attr_prompt;
     prompPos := instrb(tmpBody, prompt, 1);
     while (prompPos > 0) loop
        prompPos := prompPos + length(prompt) - 1;
        colonPos := instrb(tmpBody, ':', prompPos);
        tmpStr := substrb(tmpBody, prompPos + 1, (colonPos - prompPos) - 1);
        tmpStr := replace(tmpStr, g_tab);
        tmpStr := replace(tmpStr, g_newLine);
        if (ltrim(rtrim(tmpStr)) is NULL and colonPos > 0) then
           tmpBody := substrb(tmpBody, 1, prompPos) || substrb(tmpBody, colonPos);
        end if;
        prompPos := instrb(tmpBody, prompt, prompPos);
     end loop;
  end loop;

  -- first occurence of a colon
  colonPos := instrb(tmpBody, ':', 1);
  -- loop until there is a colon
  while colonPos > 0 loop
    -- first occurence of a double quote after the colon
    quotePos := instrb(tmpBody, '"', colonPos);
    if (quotePos > 0) then
       -- examine the string between the colon the following double quote
       -- and replace tab and newline
       tmpStr := substrb(tmpBody, colonPos+1, (quotePos-colonPos)-1);
       tmpStr := replace(tmpStr, g_tab);
       tmpStr := replace(tmpStr, g_newLine);
       -- if trim results in NULL, the string need not exist within the email
       if (ltrim(rtrim(tmpStr)) IS NULL) then
          tmpBody := substrb(tmpBody, 1, colonPos) || substrb(tmpBody, quotePos);
       end if;
    end if;

    -- first occurence of a single quote after the colon
    quotePos := instrb(tmpBody, '''', colonPos);
    if (quotePos > 0) then
       -- examine the string between the colon the following single quote
       -- and replace tab and newline
       tmpStr := substrb(tmpBody, colonPos+1, (quotePos-colonPos)-1);
       tmpStr := replace(tmpStr, g_tab);
       tmpStr := replace(tmpStr, g_newLine);
       -- if trim results in NULL, the string need not exist within the email
       if (ltrim(rtrim(tmpStr)) IS NULL) then
          tmpBody := substrb(tmpBody, 1, colonPos) || substrb(tmpBody, quotePos);
       end if;
    end if;
    colonPos := instrb(tmpBody, ':', colonPos+1);
  end loop;
  return tmpBody;
exception
  when others then
    wf_core.context('WF_MAIL', 'RemoveSpace');
    raise;
end RemoveSpace;

-- PutMessage
--   Reply processor.  Read body of a notification reply, set any
--   response attributes, and complete response.
--   Used by the notification mail response processor.
-- IN
--   notification id
--   mailer node name
--   response body text
--   email 'from' address
procedure PutMessage(
    nid       in  number,
    node      in  varchar2,
    resp_body in  varchar2,
    from_addr in  varchar2,
    error_result in out NOCOPY varchar2)
as
    TYPE stack_t IS TABLE OF
      varchar2(32000) INDEX BY BINARY_INTEGER;

    stack stack_t;
    contentStack stack_t;
    resp_attrs resp_attrs_t;

    value   varchar2(4000);
    prompt  varchar2(2000);
    buffer  varchar2(32000);
    tmpbuf  varchar2(32000);
    token   varchar2(32000);
    loc     pls_integer;
    stk     pls_integer;
    i       pls_integer;
    j       pls_integer;
    k       pls_integer;
    l       pls_integer;
    prompPos pls_integer;
    nextPos  pls_integer := 0;
    tmpPos   pls_integer;
    dleft   number;
    dright  number;
    sleft   number;
    sright  number;
    left    number;
    right   number;
    msg_name varchar2(30);
    msg_type varchar2(8);
    stat     varchar2(8);
    response boolean := FALSE;
    lk_type  varchar2(100);
    lk_meaning varchar2(100);
    n_sig_policy varchar2(100);

    -- Select msg response attrs.
    -- Order-by is to insure longest prompts are processed first to prevent
    -- problems where one prompt is a substring of another prompt.
    cursor c1 is
      select NAME, DISPLAY_NAME, TYPE, FORMAT
      from   WF_MESSAGE_ATTRIBUTES_VL
      where  MESSAGE_NAME = msg_name
      and    MESSAGE_TYPE = msg_type
      and    SUBTYPE = 'RESPOND'
      and    TYPE not in ('FORM', 'URL')
      order by length(DISPLAY_NAME) desc;

    no_program_unit exception;
    pragma exception_init(no_program_unit, -6508);

begin
    -- Get notification message and status
    begin
      select MESSAGE_NAME, MESSAGE_TYPE, STATUS
      into   msg_name, msg_type, stat
      from   WF_NOTIFICATIONS
      where  NOTIFICATION_ID = nid;
    exception
      when no_data_found then
        wf_core.token('NID', to_char(nid));
        wf_core.raise('WFNTF_NID');
    end;
    i := 1;
    -- collect all the response attributes and their details
    -- for the notification
    for rec in c1 loop
      resp_attrs(i).attr_prompt := rec.display_name;
      resp_attrs(i).attr_type := rec.type;
      resp_attrs(i).attr_name := rec.name;
      resp_attrs(i).attr_format := rec.format;
      i := i + 1;
    end loop;

    -- Bug 2375920 get the signature policy for the notification and
    -- raise error is the policy is invalid
    Wf_Mail.GetSignaturePolicy(nid, n_sig_policy);
    if (n_sig_policy is not NULL and upper(n_sig_policy) <> 'DEFAULT') then
      if(upper(n_sig_policy) = 'PSIG_ONLY') then
         wf_core.context('WF_MAIL', 'PutMessage', to_char(nid), node, from_addr);
         wf_core.token('NID', to_char(nid));
         wf_core.raise('WFRSPR_PWD_SIGNATURE');
      else
         wf_core.context('WF_MAIL', 'PutMessage', to_char(nid), node, from_addr);
         wf_core.token('NID', to_char(nid));
         wf_core.token('POLICY', n_sig_policy);
         wf_core.raise('WFMLR_INVALID_SIG_POLICY');
      end if;
    end if;

    -- all database-friendly RemoveSpace
    buffer := RemoveSpace(resp_body, resp_attrs);

    if (buffer is not null or buffer <> '') then
      -- separate the mail content into tokens based on Content-Type
      -- to eliminate v-card interference.
      stk := 1;
      i := 1;
      loc := 1;
      token := '';
      while (i <= length(buffer)) loop
        -- check if we are at the beginning of a Content-Type
        prompt := substrb(buffer, i, length('Content-Type'));
        if (upper(prompt) = 'CONTENT-TYPE') then
          if (token is not null or token <> '') then
            -- push the buffer to the stack and start again
            contentStack(stk) := token;
            stk := stk + 1;
            token := '';
            loc := i;
          end if;
        end if;
        token := substrb(buffer, loc, (i - loc) + 1);
        i := i + 1;
      end loop;
      if (token is not null or token <> '') then
        contentStack(stk) := token;
      end if;

      -- now look for response attributes within tokens based on
      -- Content-Type. Only the body will contain the response though.
      stk := 1;
      for k in 1..contentStack.count loop
         for i in 1..resp_attrs.count loop
            prompPos := instrb(contentStack(k), resp_attrs(i).attr_prompt||':', 1);
            nextPos := 0;
            -- get the position of the next nearest prompt
            for j in 1..resp_attrs.count loop
               tmpPos := instrb(contentStack(k), resp_attrs(j).attr_prompt||':', prompPos + 1);
               if (tmpPos > prompPos + 1) then
                  if (nextPos = 0) then
                     nextPos := tmpPos;
                  elsif (tmpPos <> 0 and tmpPos < nextPos) then
                     nextPos := tmpPos;
                  end if;
               end if;
            end loop;
            -- if nextPos is 0, then we are at the last or only response prompt
            -- push to stack only if there was a prompt found within the body
            -- hoping to avoid v-card here
            if (prompPos > 0) then
               if (nextPos = 0) then
                  if (resp_attrs(i).attr_type in ('LOOKUP', 'NUMBER')) then
                     stack(stk) := substrb(contentStack(k), prompPos,
                                          length(resp_attrs(i).attr_prompt) + 40);
                  else
                     stack(stk) := substrb(contentStack(k), prompPos,
                                          length(resp_attrs(i).attr_prompt) + 2000);
                  end if;
               else
                  stack(stk) := substrb(contentStack(k), prompPos, (nextPos - prompPos) - 1);
               end if;
               stk := stk + 1;
            end if;
         end loop;
      end loop;
    end if;

    -- process the response values from the stack
    for i in 1..stack.count loop
      for j in 1..resp_attrs.count loop
        -- check if we are at the beginning of a response prompt
        prompt := substrb(stack(i), 1, length(resp_attrs(j).attr_prompt));
        if (upper(prompt) = upper(resp_attrs(j).attr_prompt)) then
          -- remove all the following occurences of the prompt
          -- within the stack
          for k in i..stack.count loop
            stack(k) := replace(stack(k), resp_attrs(j).attr_prompt||':');
          end loop;
          -- check for double quotes from both ends
          dleft := instrb(stack(i), '"', 1, 1);
          dright := instrb(stack(i), '"', -1, 1);

          -- check for single quotes from both ends
          sleft := instrb(stack(i), '''', 1, 1);
          sright := instrb(stack(i), '''', -1, 1);

          if (dleft <> 0 and (sleft = 0 or dleft < sleft)) then
            left := dleft;
          else
            left := sleft;
          end if;
          if (dright > sright) then
            right := dright;
          else
            right := sright;
          end if;
          if ((right - left) > 1) then
            value := substrb(stack(i), left+1, (right - left)-1);
            if (resp_attrs(j).attr_type = 'LOOKUP') then
              lk_type := resp_attrs(j).attr_format;
              lk_meaning := value;
              value := GetLovCode(resp_attrs(j).attr_format, value);
            end if;

            --  Process this notification only if it has a status of 'OPEN'
            --  otherwise do nothing. Fix for bug 2202392.
            if (stat = 'OPEN') then
              -- Save the new attribute value for nid.
              Wf_Notification.SetAttrText(nid, resp_attrs(j).attr_name, value);
            end if;
            response := TRUE;
          end if;
        end if;
      end loop;
   end loop;

   -- Do not need to preserve context
   wf_engine.preserved_context := FALSE;

   -- Complete the response.
   if response then
     Wf_Notification.Respond(nid, NULL, 'email:'||from_addr);
   else
     wf_core.context('WF_MAIL', 'PutMessage', to_char(nid), node, from_addr);
     wf_core.raise('WFRSPR_NORESPONSE');
   end if;

exception
   when no_program_unit then
     wf_core.context('WF_MAIL','PutMessage', to_char(nid));
     raise;
   when OTHERS then
     wf_core.context('WF_MAIL','PutMessage', to_char(nid));
     -- Save error message and set status to INVALID so mailer will
     -- bounce an "invalid reply" message to sender.
     HandleResponseError(nid, lk_type, lk_meaning, error_result);
end PutMessage;

-- PutDirectMessage
--   Direct reply processor.  Read body of a notification reply, set any
--   response attributes, and complete response.
--   Used by the notification mail response processor.
-- IN
--   notification id
--   mailer node name
--   response body text
--   email 'from' address
procedure PutDirectMessage(
    nid       in  number,
    node      in  varchar2,
    resp_body in  varchar2,
    from_addr in  varchar2,
    error_result in out NOCOPY varchar2)
as
    buffer   varchar2(32000);
    msg_name varchar2(30);
    msg_type varchar2(8);
    stat     varchar2(8);
    use_default boolean;
    first_blank_line boolean := true;
    response boolean;

    -- Select msg response attrs.
    -- Order-by is to insure longest prompts are processed first to prevent
    -- problems where one prompt is a substring of another prompt.
    cursor c1 is
    select WMA.NAME, WMA.TYPE, WMA.FORMAT,
           decode(WMA.TYPE,
             'VARCHAR2', decode(WMA.FORMAT,
                           '', WNA.TEXT_VALUE,
                           substr(WNA.TEXT_VALUE, 1, to_number(WMA.FORMAT))),
             'NUMBER', decode(WMA.FORMAT,
                         '', to_char(WNA.NUMBER_VALUE),
                         to_char(WNA.NUMBER_VALUE, WMA.FORMAT)),
             'DATE', decode(WMA.FORMAT,
                       '', to_char(WNA.DATE_VALUE),
                       to_char(WNA.DATE_VALUE, WMA.FORMAT)),
             'LOOKUP', WNA.TEXT_VALUE,
             WNA.TEXT_VALUE) VALUE
    from   WF_NOTIFICATION_ATTRIBUTES WNA,
           WF_NOTIFICATIONS WN,
           WF_MESSAGE_ATTRIBUTES_VL WMA
    where  WNA.NOTIFICATION_ID = nid
    and    WN.NOTIFICATION_ID = WNA.NOTIFICATION_ID
    and    WN.MESSAGE_TYPE = WMA.MESSAGE_TYPE
    and    WN.MESSAGE_NAME = WMA.MESSAGE_NAME
    and    WMA.NAME = WNA.NAME
    and    WMA.SUBTYPE = 'RESPOND'
    and    WMA.TYPE not in ('FORM', 'URL')
    order  by WMA.SEQUENCE;

    new_value varchar2(4000);
    new_start pls_integer;
    new_end pls_integer;
    no_program_unit exception;
    pragma exception_init(no_program_unit, -6508);
    -- Bug# 2301881
    lk_type varchar2(30);
    lk_meaning varchar2(80);
    -- Bug 2375920
    n_sig_policy varchar2(100);
begin
    buffer := resp_body;
    response := false;

    -- Get notification message and status
    begin
      select MESSAGE_NAME, MESSAGE_TYPE, STATUS
      into   msg_name, msg_type, stat
      from   WF_NOTIFICATIONS
      where  NOTIFICATION_ID = nid;
    exception
      when no_data_found then
        wf_core.token('NID', to_char(nid));
        wf_core.raise('WFNTF_NID');
    end;

    -- Bug 2375920 get the signature policy for the notification and
    -- raise error is the policy is invalid
    Wf_Mail.GetSignaturePolicy(nid, n_sig_policy);
    if (n_sig_policy is not NULL and upper(n_sig_policy) <> 'DEFAULT') then
      if(upper(n_sig_policy) = 'PSIG_ONLY') then
         wf_core.context('WF_MAIL', 'PutDirectMessage', to_char(nid), node, from_addr);
         wf_core.token('NID', to_char(nid));
         wf_core.raise('WFRSPR_PWD_SIGNATURE');
      else
         wf_core.context('WF_MAIL', 'PutDirectMessage', to_char(nid), node, from_addr);
         wf_core.token('NID', to_char(nid));
         wf_core.token('POLICY', n_sig_policy);
         wf_core.raise('WFMLR_INVALID_SIG_POLICY');
      end if;
    end if;

    -- Process all Response attributes.
    -- The first line in the mail body should be the answer for the first
    -- response attribute. And the second line should be for the second
    -- response attribute....
    -- Blank line means take the default value.
    -- The mailer is assuming that blank line will be inserted by user
    -- when they want to take the default value.
    -- When an answer is too long, double quote should be enclosed at both
    -- beginning and the end of the answer.
    for rec in c1 loop

      -- Bug# 2301881 These values are needed in HandleResponseError
      -- and FormatErrorMessage to bounce invalid response mail
      lk_type := rec.format;
      lk_meaning := g_none;

      -- GetDirectAnswer() will take the next line from the mail body.
      -- GetDirectAnswer() takes care multiple lines answer.(answer enclosed
      --                    by double quote
      use_default := false;
      GetDirectAnswer(buffer, new_value);

      if (new_value is null) then
        -- check if is leading blank line
        if (not(first_blank_line)) then
          new_value := rec.value;
          use_default := true;
        else
          while (new_value is null) loop
            GetDirectAnswer(buffer, new_value);
          end loop;
          first_blank_line := false;
        end if;
      else
        first_blank_line := false;
      end if;

      -- Bug# 2301881
      lk_meaning := new_value;
      -- If this is a lookup, replace displayed meaning with code.
      if (rec.type = 'LOOKUP' AND use_default = false) then
        new_value := GetLovCode(rec.format, new_value);
      end if;

      --  Process this notification only if it has a status of 'OPEN'
      --  otherwise do nothing. Fix for bug 2202392.

      if (stat = 'OPEN') then
      -- Save the new attribute value for nid.
         Wf_Notification.SetAttrText(nid, rec.name, new_value);
      end if;
      response := TRUE;
    end loop;

    -- Do not need to preserve context
    wf_engine.preserved_context := FALSE;

    -- Complete the response.
    if response then
       Wf_Notification.Respond(nid, NULL, 'email:'||from_addr);
    else
       wf_core.context('WF_MAIL', 'PutDirectMessage', to_char(nid),
                       node, from_addr);
       wf_core.raise('WFRSPR_NORESPONSE');
    end if;
exception
    when no_program_unit then
        wf_core.context('WF_MAIL','PutDirectMessage', to_char(nid));
        raise;
    when OTHERS then
        wf_core.context('WF_MAIL','PutDirectMessage', to_char(nid));
      -- Save error message and set status to INVALID so mailer will
      -- bounce an "invalid reply" message to sender.
      HandleResponseError(nid, lk_type, lk_meaning, error_result);
end PutDirectMessage;

-- PutMoreInfoRequest
--   Reply processor.  Read body of a request for more information
--   parse the body for the role to send the request to.
--   Used by the notification mail response processor.
-- IN
--   notification id
--   mailer node name
--   response body text
--   email 'from' address
procedure PutMoreInfoRequest(
    nid       in  number,
    node      in  varchar2,
    resp_body in  varchar2,
    from_addr in  varchar2,
    error_result in out nocopy varchar2)
as
    buffer   varchar2(32000);
    start_pos number;
    end_pos number;
    prompt varchar2(200);
    comment varchar2(200);
    to_user varchar2(320);
    dummy varchar2(200);
    no_program_unit exception;
    pragma exception_init(no_program_unit, -6508);
begin
    buffer := resp_body;
    -- Remove line feeds incase there
    -- has been a line wrap on the response
    buffer := replace(buffer, g_newLine, '');

    -- Locate who the response is to.
    prompt := g_moreInfoFrom||': ''';
    start_pos := instr(buffer, prompt, 1, 1);
    if start_pos <> 0 then
       start_pos := start_pos + length(prompt);
       end_pos := instr(buffer, '''',  start_pos, 1);
       to_user := substr(buffer, start_pos, end_pos - start_pos);
    else
       to_user := '';
    end if;

    -- More info request can come only from a HTML mail in which
    -- a template is provided with single quotes
    prompt := '';
    start_pos := 0;
    end_pos := 0;
    prompt := g_moreInfoQPrompt||': ''';

    -- checking only for single quote, as the template is generated by the
    -- mailer with a single quote on clicking on the link
    start_pos := instr(buffer, prompt, 1, 1);
    if start_pos <> 0 then
       start_pos := start_pos + length(prompt);
       end_pos := instr(buffer, '''', start_pos, 1);
       if end_pos <> 0 then
          comment := substr(buffer, start_pos, end_pos - start_pos);
          if comment = g_moreInfoQuestion and
             length(comment) =
                 length(g_moreInfoQuestion) then
             comment := '';
          end if;

       end if;
    else
       comment := 'NULL';
    end if;
    -- validate the role before calling updateinfo

    -- update wf_notifications and wf_comments in QUESTION mode
    if (length(to_user) > 0  and length(comment) > 0) then
       wf_notification.UpdateInfo2(nid, to_user, from_addr, comment);
    end if;
exception
    when no_program_unit then
      wf_core.context('WF_MAIL','PutMoreInfoRequest', to_char(nid));
      raise;
    when OTHERS then
      wf_core.context('WF_MAIL','PutMoreInfoRequest', to_char(nid));
      -- Save error message and set status to INVALID so mailer will
      -- bounce an "invalid reply" message to sender.
      HandleResponseError(nid, dummy, dummy, error_result);
end PutMoreInfoRequest;

-- PutMoreInfoMessage
--   Reply processor.  Read body of a reply for more information
--   request, parse the body for the comments from the user and
--   update wf_notification and wf_comments apropriately
--   Used by the notification mail response processor.
-- IN
--   notification id
--   mailer node name
--   response body text
--   email 'from' address
procedure PutMoreInfoMessage(
    nid       in  number,
    node      in  varchar2,
    resp_body in  varchar2,
    from_addr in  varchar2,
    error_result in out nocopy varchar2)
as
    buffer   varchar2(32000);
    start_pos number;
    end_pos number;
    prompt varchar2(200);
    comment varchar2(200);
    to_user varchar2(320);
    dummy varchar2(200);
    no_program_unit exception;
    pragma exception_init(no_program_unit, -6508);
begin
    buffer := resp_body;
    -- Remove line feeds incase there
    -- has been a line wrap on the response
    buffer := replace(buffer, g_newLine, '');

    prompt := '';
    start_pos := 0;
    end_pos := 0;
    prompt := g_moreInfoAPrompt||': ''';

    start_pos := instr(buffer, prompt, 1, 1);
    if start_pos <> 0 then
       start_pos := start_pos + length(prompt);
       end_pos := instr(buffer, '''', start_pos, 1);
       if end_pos <> 0 then
          comment := substr(buffer, start_pos, end_pos - start_pos);
          if comment = g_moreInfoAnswer and
             length(comment) =
                 length(g_moreInfoAnswer) then
             comment := '';
          end if;

       end if;
    else
       prompt := '';
       start_pos := 0;
       end_pos := 0;
       prompt := g_moreInfoAPrompt||': "';
       start_pos := instr(buffer, prompt, 1, 1);
       if (start_pos <> 0) then
          start_pos := start_pos + length(prompt);
          end_pos := instr(buffer, '''', start_pos, 1);
          if (end_pos <> 0) then
             comment := substr(buffer, start_pos, end_pos - start_pos);
             if ((comment = g_moreInfoAnswer) and
                  (length(comment) =
                      length(g_moreInfoAnswer))) then
                comment := '';
             end if;
          end if;
       end if;
    end if;
    -- update wf_notifications and wf_comments in ANSWER mode
    to_user := NULL;
    wf_notification.UpdateInfo2(nid, to_user, from_addr, comment);
exception
    when no_program_unit then
      wf_core.context('WF_MAIL','PutMoreInfoMessage', to_char(nid));
      raise;
    when OTHERS then
      wf_core.context('WF_MAIL','PutMoreInfoMessage', to_char(nid));
      -- Save error message and set status to INVALID so mailer will
      -- bounce an "invalid reply" message to sender.
      HandleResponseError(nid, dummy, dummy, error_result);
end PutMoreInfoMessage;

-- GetURLAttachment - Return the attached URLS as a list on an attachment
-- IN
--    NID Notificaiton ID
-- OUT
--   BUFFER containing the attachment body
--   ERROR_RESULT - Errorstack if requried
procedure GetUrlAttachment (nid in number,
                            buffer out NOCOPY varchar2,
                            error_result out NOCOPY varchar2)
is
    l_subject     varchar2(2000);
    l_html_body   varchar2(32000);
    l_url         varchar2(2000);
    l_urllist     varchar2(32000);
    l_urlcount    integer;

    err_name      varchar2(30);
    err_message   varchar2(2000);
    err_stack     varchar2(4000);

    cursor ntf is
    select WMA.TYPE, WMA.DISPLAY_NAME,
       decode(WMA.TYPE, 'URL', WF_NOTIFICATION.GetUrlText(WNA.TEXT_VALUE,
              GetURLAttachment.nid), WNA.TEXT_VALUE) URL,
       WNA.NAME
       from WF_NOTIFICATION_ATTRIBUTES WNA, WF_NOTIFICATIONS WN,
            WF_MESSAGE_ATTRIBUTES_VL WMA
       where WNA.NOTIFICATION_ID = GetURLAttachment.nid
         and WN.NOTIFICATION_ID = WNA.NOTIFICATION_ID
         and WN.MESSAGE_TYPE = WMA.MESSAGE_TYPE
         and WN.MESSAGE_NAME = WMA.MESSAGE_NAME
         and (WMA.TYPE = 'URL')
         and WMA.ATTACH = 'Y'
         and WMA.NAME = WNA.NAME;


    no_program_unit exception;
    pragma exception_init(no_program_unit, -6508);

begin

   -- Get the template.
   begin
     select SUBJECT, HTML_BODY
     into   l_subject, l_html_body
     from   WF_MESSAGES_VL
     where  NAME = 'ATTACHED_URLS' and TYPE = 'WFMAIL';
   exception
     when no_data_found then
       -- If the template has not been installed, then construct a
       -- default, minimem template.
       l_html_body := '<HTML><BODY><B><FONT SIZE=+1>'||
                      'Notificaiton References</FONT></B>'||
                      '<BR>Default Template<BR>'||
                      '&'||'URLLIST</BODY><HTML>';

   end;

   -- Build the list of URLs
   l_urlcount := 0;
   l_urllist := '<BR>';
   for urlattr in ntf loop
      l_url := wf_notification.SetFrameworkAgent(urlattr.url);
      l_urllist := l_urllist || '<A class="OraLink" HREF="' || l_url || '">' ||
                   urlattr.display_name || '</A><BR>'||g_newLine;
      l_urlcount := l_urlcount + 1;
   end loop;


   -- Substitute the list
   if l_urlcount > 0 then
      buffer := substrb(replace(l_html_body, '&'||'URLLIST', l_urllist), 1, 32000);
    else
       buffer := '';
    end if;
exception
  when no_program_unit then
    wf_core.context('WF_MAIL', 'GetURLAttachment', to_char(nid));
    raise;
  when others then
    -- First look for a wf_core error.
    wf_core.get_error(err_name, err_message, err_stack);

    -- If no wf_core error look for a sql error.
    if (err_name is null) then
      err_message := sqlerrm;
    end if;

    error_result := err_message;
    wf_core.context('WF_MAIL', 'GetURLAttachment', to_char(nid));

end;



-- Direct_Response - Return the value of the direct response flag
--
-- OUT
--   Direct Response as [TRUE|FALSE]
function Direct_Response return boolean
is
begin
   return g_direct_response;
end;

-- Send_Accesskey - Return the value of the send access key flag
--
-- OUT
--   Direct Response as [TRUE|FALSE]
function Send_Accesskey return boolean
is
   enabled varchar2(1);
   flag boolean;
begin
   if g_install = 'EMBEDDED' then
      enabled := FND_PROFILE.Value('WF_VALIDATE_NTF_ACCESS');
      if enabled = 'Y' then
         flag := TRUE;
      else
         flag := FALSE;
      end if;
   else
      flag := g_send_accesskey;
   end if;

   return flag;

end;

-- autoclose_fyi - Return the value of the autoclose fyi flag
--
-- OUT
--   AUTOCLOSE_FYI as [TRUE|FALSE]
function Autoclose_FYI return boolean
is
begin
   return g_autoclose_fyi;
end;

-- Direct_Response_On - Set the value of the direct response flag to TRUE
--
procedure Direct_Response_On
is
begin
   g_direct_response := TRUE;
end;

-- Direct_Response_Off - Set the value of the direct response flag to FALSE
--
procedure Direct_Response_off
is
begin
   g_direct_response := FALSE;
end;

-- send_accesskey_on - Set the value of the send acces key flag to TRUE
--
procedure Send_Access_Key_On
is
begin
   g_send_accesskey := TRUE;
end;

-- Send_Accesskey_oOf - Set the value of the send acces key flag to FALSE
--
procedure Send_Access_Key_Off
is
begin
   g_send_accesskey := FALSE;
end;

-- Autoclose_FYI_On - Set the value of the autoclose FYI flag to TRUE
--
procedure Autoclose_FYI_On
is
begin
   g_autoclose_fyi := TRUE;
end;

-- Autoclose_FYI_Off - Set the value of the autoclose FYI flag to FALSE
--
procedure Autoclose_FYI_Off
is
begin
   g_autoclose_fyi := FALSE;
end;

-- set_template - Set the mail template
-- if nothing is specify, it will clear the mail template value.
procedure set_template(name in varchar2)
is
begin
   g_template := substr(name, 1, 30);
end set_template;

--
-- GetCharset (PRIVATE)
--   Get the character set base of the language and territory info.
-- NOTE
--   We may do more in the future to find the character set.
--
procedure GetCharset(lang in varchar2,
                     terr in varchar2,
                     charset out NOCOPY varchar2)
is
begin
  begin
    if (terr is null) then
      raise NO_DATA_FOUND;
    end if;
    select NLS_CODESET
      into charset
      from WF_LANGUAGES
     where NLS_LANGUAGE = lang
       and NLS_TERRITORY = terr;
  exception
    when NO_DATA_FOUND then
      -- try to find the character set base on language alone
      select NLS_CODESET
        into charset
        from WF_LANGUAGES
       where NLS_LANGUAGE = lang
         and rownum < 2;
  end;
exception
  when OTHERS then
    wf_core.context('WF_MAIL', 'GetCharset', lang, terr);
    raise;
end GetCharset;

-- GetSessionLanguage
-- Get the session language and territory for the
-- current session
--
-- OUT
-- Language
-- Territory
-- codeset
procedure GetSessionLanguage(lang out NOCOPY varchar2,
                             terr out NOCOPY varchar2,
                             codeset out NOCOPY varchar2)
is
   nls_str varchar2(1000);
   underscore integer;
   dot integer;
begin

   select userenv('LANGUAGE')
   into nls_str
   from sys.dual;

   underscore := instr(nls_str,'_',1,1);
   dot := instr(nls_str, '.',1,1);

   lang := substr(nls_str, 1, underscore-1);
   terr := substr(nls_str, underscore+1, dot - underscore -1);
   codeset := substr(nls_str, dot+1);

exception
  when others then
    wf_core.context('WF_MAIL', 'GetSessionLanguage');
    raise;
end GetSessionLanguage;

-- Bug 2375920
-- GetSignaturePolicy (PUBLIC)
--    Get the signature policy for the notification from
--    the notification attribute
-- IN
--   nid  -  Notification id
-- OUT
--   sig_policy  - Signature policy

procedure GetSignaturePolicy(nid        in  number,
                             sig_policy out NOCOPY varchar2)
is
begin
  -- Get value for signature policy for the notification from
  -- notification attribute
  sig_policy := Wf_Notification.GetAttrText(nid, '#WF_SIG_POLICY');

exception
  when others then
    if (wf_core.error_name = 'WFNTF_ATTR') then
      wf_core.clear;
      sig_policy := 'DEFAULT';
    else
      raise;
    end if;
end GetSignaturePolicy;

-- gets the size of the current LOB table
function getLobTableSize return number
is
begin
   return g_LOBTable.COUNT;
end;

--
-- GetSecurityPolicy
--
procedure GetSecurityPolicy(p_nid        in  number,
                            p_sec_policy out NOCOPY varchar2)
is
begin
  -- Get security policy for the notification
  p_sec_policy := Wf_Notification.GetAttrText(p_nid, '#WF_SECURITY_POLICY');
  if (p_sec_policy is null) then
     p_sec_policy := 'DEFAULT';
  end if;
exception
  when others then
    if (wf_core.error_name = 'WFNTF_ATTR') then
      wf_core.clear;
      p_sec_policy := 'DEFAULT';
    else
      raise;
    end if;
end GetSecurityPolicy;

--
-- ProcessSecurityPolicy
--
procedure ProcessSecurityPolicy(p_nid          in  number,
                                p_email        out NOCOPY varchar2,
                                p_message_name out NOCOPY varchar2)
is
  l_sec_policy    varchar2(100);
  l_email_allowed varchar2(1);
begin
  -- Get security policy for the notification
  Wf_Mail.GetSecurityPolicy(p_nid, l_sec_policy);

  -- If the policy is not seeded, default it to Y to allow email
  begin
    SELECT email_allowed
    INTO   l_email_allowed
    FROM   wf_ntf_security_policies
    WHERE  policy_name = l_sec_policy;
  exception
    when others then
      Wf_Core.Token('NID', to_char(p_nid));
      Wf_Core.Token('POLICY', l_sec_policy);
      Wf_Core.Raise('WFMLR_INVALID_SEC_POLICY');
  end;

  -- There should be a way to avoid hard-coding the values !!!
  p_email := l_email_allowed;

  -- Policy is either EMAIL_OK or DEFAULT
  if (l_email_allowed = 'Y') then
     p_message_name := null;

  -- Policy NO_EMAIL, the notification is not to be sent by e-mail
  elsif (l_email_allowed = 'N') then
     p_message_name := 'OPEN_MAIL_SECURE';

  -- Policy is ENC_EMAIL_ONLY. Requires the notification to be encrypted. Currently not
  -- supported, so inform the user to access the online notification
  elsif (l_email_allowed = 'E') then
     p_message_name := 'OPEN_MAIL_SECURE';
  end if;

exception
  when others then
    Wf_Core.Context('Wf_Mail', 'ProcessSecurityPolicy', to_char(p_nid));
    raise;
end ProcessSecurityPolicy;

-- Set_FYI_Flag (Private)
--   Sets a global flag to identify if the current e-mail being processed is a
--   FYI notification
-- IN
--   p_fyi  boolean
procedure Set_FYI_Flag(p_fyi in boolean)
is
begin
  g_fyi := p_fyi;
end Set_FYI_Flag;

-- Get_FYI_Flag (Private)
--   Returns a global flag to identify if the current e-mail being processed is
--   a FYI notification
-- OUT
--   Boolean value
function Get_FYI_Flag return boolean
is
begin
  return g_fyi;
end Get_FYI_Flag;

-- Get_Ntf_Language (PRIVATE)
--   Overrides the language and territory setting for the notification based
--   on the #WFM_LANGUAGE and #WFM_TERRITORY attributes. If neither user's
--   preference nor the notification level setting are valid, the base NLS
--   setting is used
-- IN
--   p_nid - Notification Id
-- IN OUT
--   p_language   - NLS Language
--   p_territory  - NLS Territory
--   p_codeset    - NLS Codeset
procedure Get_Ntf_Language(p_nid       in            number,
                           p_language  in out nocopy varchar2,
                           p_territory in out nocopy varchar2,
                           p_codeset   in out nocopy varchar2)
is
  l_lang      varchar2(30);
  l_terr      varchar2(30);
  l_install   varchar2(1);
  l_codeset   varchar2(30);
  l_base_lang varchar2(30);
  l_base_terr varchar2(30);
  l_base_codeset varchar2(30);
begin
  if (wf_log_pkg.level_procedure >= fnd_log.g_current_runtime_level) then
    wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_mail.Get_Ntf_Language.BEGIN',
                      'User preferences. LANG {'||p_language||'} TERR {'||p_territory||'}');
  end if;

  -- Get notification's language preference
  begin
    l_lang := upper(Wf_Notification.GetAttrText(p_nid, '#WFM_LANGUAGE'));
  exception
    when others then
      if (wf_core.error_name = 'WFNTF_ATTR') then
        wf_core.clear();
        l_lang := null;
      else
        raise;
      end if;
  end;

  l_install := 'N';
  if (l_lang is not null) then
    -- Check for validity of notification's language
    begin
      select nls_codeset, installed_flag
      into   l_codeset, l_install
      from   wf_languages
      where  nls_language = l_lang;
    exception
      when others then
        l_install := 'N';
        l_lang := null;
        l_codeset := null;
    end;
  end if;

  -- Notification level language is installed and valid
  if (l_install = 'Y') then
    p_language := l_lang;
    p_codeset := l_codeset;
  else
    -- Notification level language is not installed, use user's preference
    begin
      select nls_codeset, installed_flag
      into   p_codeset, l_install
      from   wf_languages
      where  nls_language = p_language;
    exception
      when others then
        l_install := 'N';
    end;

    -- If neither notification level nor user's preferences are installed,
    -- use default
    if (l_install = 'N') then
      p_language := null;
      p_codeset := null;
    end if;
  end if;

  -- Get notification's territory preference
  begin
    l_terr := upper(Wf_Notification.GetAttrText(p_nid, '#WFM_TERRITORY'));
  exception
    when others then
      if (wf_core.error_name = 'WFNTF_ATTR') then
        wf_core.clear();
        l_terr := null;
      else
        raise;
      end if;
  end;

  l_install := 'N';
  if (l_terr is not null) then
    begin
      select 'Y'
      into   l_install
      from   wf_languages
      where  nls_territory = l_terr;
      -- Notification level territory is valid
      p_territory := l_terr;
    exception
      when others then
        l_install := 'N';
    end;
  end if;

  -- Use user's territory preference if it is valid
  if (l_install = 'N') then
    begin
      select 'Y'
      into   l_install
      from   wf_languages
      where  nls_territory = p_territory;
    exception
      when others then
        -- Neither notification level nor user's territory preference is
        -- valid, use default
        p_territory := null;
    end;
  end if;

  -- If at least one of the value is null, use the base NLS setting
  if (p_language is null or p_territory is null) then
    if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
      wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_mail.Get_Ntf_Language.NULL',
                      'Using base NLS setting because p_language is {'||p_language||
                      '} and p_territory is {'||p_territory||'}');
    end if;
    WF_MAIL.GetSessionLanguage(l_base_lang, l_base_terr, l_base_codeset);
    if (p_language is null) then
      p_language := l_base_lang;
      p_codeset := l_base_codeset;
    end if;
    p_territory := nvl(p_territory, l_base_terr);
  end if;

  if (wf_log_pkg.level_procedure >= fnd_log.g_current_runtime_level) then
     wf_log_pkg.string(wf_log_pkg.level_procedure, 'wf.plsql.wf_mail.Get_Ntf_Language.END',
                      'Email Notification LANG {'||p_language||'} TERR {'||p_territory||'}'||
                      ' CODESET {'||p_codeset||'}');
  end if;

exception
  when others then
    Wf_Core.Context('Wf_Mail', 'Get_Ntf_Language', to_char(p_nid), p_language, p_territory);
    raise;
end Get_Ntf_Language;

--
-- Generic mailer routines
--

-- Send
--   Sends a e-mail notification to the specified list of recipients.
--   This API unlike wf_notification.send does not require workflow
--   message or workflow roles to send a notification.

procedure send(p_subject        in varchar2,
               p_message        in out nocopy clob,
               p_recipient_list in wf_recipient_list_t,
               p_module         in varchar2,
               p_idstring       in varchar2,
               p_from           in varchar2,
               p_replyto        in varchar2,
               p_language       in varchar2,
               p_territory      in varchar2,
               p_codeset        in varchar2,
               p_content_type   in varchar2,
               p_callback_event in varchar2,
               p_event_key      in varchar2,
               p_fyi_flag       in varchar2)
is
  l_module varchar2(10);
  l_str  varchar2(4000);
  l_attrlist wf_xml.wf_xml_attr_table_type;
  l_pos  integer;
  l_amt  number;

  l_msg_doc    clob;
  l_event      wf_event_t;
  l_agent      wf_agent_t;
  l_parameter_list wf_parameter_list_t;
  l_event_name varchar2(240);
  l_event_key  varchar2(240);
  l_recp_type  varchar2(10);
  l_name       varchar2(360);
  l_email      varchar2(240);
  l_replyto    varchar2(240);
  l_subject    varchar2(2000);
  l_from       varchar2(360);
  l_nodename   varchar2(240);
  l_idstr      varchar2(240);
  l_idsize     integer;

  l_recp_clob  clob;
  l_recp       clob;
  l_recp_tmp   varchar2(32000);
  l_recp_txt   varchar2(32000);
  l_recp_pos   integer;
  l_recp_is_lob boolean;
  l_recp_len   integer;
  l_hdr_tmp    varchar2(32000);
  l_hdr_pos    integer;
  l_occurance  integer := 1;
  i            integer;


  l_messageIdx pls_integer;
  l_start_cdata VARCHAR2(10) := '<![CDATA[';
  l_end_cdata VARCHAR2(4) := ']]>';
  l_fyi_flag boolean;

begin

  -- Test the FYI flag. If set, then treat this message as FYI
  -- i.e. No ID string to be appended. Same is true if the ID string is
  -- null irresepective of the p_fyi_flag.
  if (p_fyi_flag is not null and upper(p_fyi_flag) = 'Y')
    or p_idstring is null then
     l_fyi_flag := true;
  else
     l_fyi_flag := false;
  end if;

  -- Recipients required
  if (p_recipient_list is null) then
    wf_core.raise('WFMLR_NO_RECIPIENTS');
  end if;

  -- At least subject or body is required
  if (p_subject is null and (p_message is null or dbms_lob.GetLength(p_message)=0)) then
    wf_core.raise('WFMLR_MSG_INCOMPLETE');
  end if;

  -- For all e-mails, respone or FYI, module name is required
  if (p_module is null) then
    wf_core.raise('WFMLR_NO_MODULE');
  end if;

  dbms_lob.createTemporary(l_msg_doc, TRUE, dbms_lob.call);
  l_str := '<?xml version="1.0" ?>';
  l_pos := length(l_str);
  dbms_lob.write(l_msg_doc, l_pos, 1, l_str);

  -- <NOTIFICATIONGROUP> begin
  wf_xml.AddElementAttribute('maxcount', '1', l_attrlist);
  l_pos := wf_xml.NewLOBTag(l_msg_doc, l_pos, 'NOTIFICATIONGROUP', '', l_attrlist);
  l_attrlist.DELETE;

  l_nodename := WF_MAILER_PARAMETER.GetValueForCorr(p_module, 'NODENAME');

  -- Id string required for response required alerts.
  -- We assume that a null id string constitutes a FYI message
  if (p_idstring is not null and l_fyi_flag = false) then
     if (trim(p_module) <> g_Alert_Nodename) then
        l_module := '#X_'||trim(p_module);
     else
        l_module := p_module;
     end if;
     l_idstr := l_module||'['||p_idstring||'/0000@'||l_nodename||']';
  else
    l_idstr := null;
  end if;

  -- <NOTIFICATION> begin
  wf_xml.AddElementAttribute('nid', '0', l_attrlist);
  wf_xml.AddElementAttribute('nidstr', l_idstr, l_attrlist);
  wf_xml.AddElementAttribute('language', p_language, l_attrlist);
  wf_xml.AddElementAttribute('territory', p_territory, l_attrlist);
  wf_xml.AddElementAttribute('codeset', p_codeset, l_attrlist);
  wf_xml.AddElementAttribute('priority', '50', l_attrlist);
  wf_xml.AddElementAttribute('accesskey', '0', l_attrlist);
  wf_xml.AddElementAttribute('node', l_nodename, l_attrlist);
  wf_xml.AddElementAttribute('item_type', 'NULL', l_attrlist);
  wf_xml.AddElementAttribute('message_name', 'NULL', l_attrlist);
  wf_xml.AddElementAttribute('full-document', 'Y', l_attrlist);

  if (p_callback_event is not null) then
    wf_xml.AddElementAttribute('callback', p_callback_event, l_attrlist);
  end if;

  l_pos := wf_xml.NewLOBTag(l_msg_doc, l_pos, 'NOTIFICATION', '', l_attrlist);
  l_attrlist.DELETE;

  dbms_lob.createTemporary(l_recp_clob, TRUE, dbms_lob.call);

  l_recp_pos := 0;
  l_recp_tmp := '';

  i := p_recipient_list.first;
  while (i is not null) loop
    l_name := replace(p_recipient_list(i).name, g_newline);
    l_recp_type := p_recipient_list(i).recipient_type;

    -- <RECIPIENT> begin
    wf_xml.AddElementAttribute('name', l_name, l_attrlist);
    wf_xml.AddElementAttribute('type', l_recp_type, l_attrlist);
    l_recp_pos := wf_xml.NewTag(l_recp_tmp, l_recp_pos, 'RECIPIENT', '', l_attrlist);
    l_attrlist.DELETE;

    -- <NAME>
    l_recp_pos := wf_xml.NewTag(l_recp_tmp, l_recp_pos, 'NAME', l_name, l_attrlist);
    l_recp_pos := wf_xml.SkipTag(l_recp_tmp, 'NAME', l_recp_pos, l_occurance);

    -- <ADDRESS>
    l_email := '<![CDATA['||replace(p_recipient_list(i).address, g_newline)||']]>';
    l_recp_pos := wf_xml.NewTag(l_recp_tmp, l_recp_pos, 'ADDRESS', l_email, l_attrlist);
    l_recp_pos := wf_xml.SkipTag(l_recp_tmp, 'ADDRESS', l_recp_pos, l_occurance);

    -- <RECIPIENT> end
    l_recp_pos := wf_xml.SkipTag(l_recp_tmp, 'RECIPIENT', l_recp_pos, l_occurance);
    l_attrlist.DELETE;

    i := p_recipient_list.next(i);

    l_recp_len := length(l_recp_tmp);
    if (l_recp_len > 30000) then
      dbms_lob.WriteAppend(l_recp_clob, l_recp_len, l_recp_tmp);
      l_recp_tmp := '';
      l_recp_pos := 0;
      l_recp_is_lob := true;
    end if;
  end loop;

  l_recp_len := length(l_recp_tmp);
  if(l_recp_len > 0 and l_recp_is_lob) then
    dbms_lob.WriteAppend(l_recp_clob, l_recp_len, l_recp_tmp);
  end if;

  -- <RECIPIENTLIST> start
  l_recp_pos := 0;
  if (l_recp_is_lob) then
    dbms_lob.createTemporary(l_recp, TRUE, dbms_lob.call);
    l_recp_pos := wf_xml.NewLOBTag(l_recp, l_recp_pos, 'RECIPIENTLIST', l_recp_clob, l_attrlist);
    l_recp_pos := wf_xml.SkipLOBTag(l_recp, 'RECIPIENTLIST', l_recp_pos, l_occurance);
  else
    l_recp_pos := wf_xml.NewTag(l_recp_txt, l_recp_pos, 'RECIPIENTLIST', l_recp_tmp, l_attrlist);
    l_recp_pos := wf_xml.SkipTag(l_recp_txt, 'RECIPIENTLIST', l_recp_pos, l_occurance);
  end if;

  l_hdr_pos := 0;
  l_hdr_tmp := '';

  if (p_from is not null or p_replyto is not null) then
     -- <FROM> start
     l_hdr_pos := wf_xml.NewTag(l_hdr_tmp, l_hdr_pos, 'FROM', '', l_attrlist);

     -- <NAME>
     if (p_from is not null) then
       l_from := replace(p_from, g_newLine);
       l_hdr_pos := wf_xml.NewTag(l_hdr_tmp, l_hdr_pos, 'NAME', l_from, l_attrlist);
       l_hdr_pos := wf_xml.SkipTag(l_hdr_tmp, 'NAME', l_hdr_pos, l_occurance);
     end if;

     -- <ADDRESS>
     if (p_replyto is not null) then
       l_replyto := replace(p_replyto, g_newLine);
       l_replyto := '<![CDATA['||l_replyto||']]>';
       l_hdr_pos := wf_xml.NewTag(l_hdr_tmp, l_hdr_pos, 'ADDRESS', l_replyto, l_attrlist);
       l_hdr_pos := wf_xml.SkipTag(l_hdr_tmp, 'ADDRESS', l_hdr_pos, l_occurance);
     end if;

     -- <FROM> end
     l_hdr_pos := wf_xml.SkipTag(l_hdr_tmp, 'FROM', l_hdr_pos, l_occurance);
  end if;

  l_subject := replace(p_subject, g_newLine);
  l_subject := '<![CDATA['||l_subject||']]>';
  l_hdr_pos := wf_xml.NewTag(l_hdr_tmp, l_hdr_pos, 'SUBJECT', l_subject, l_attrlist);
  l_hdr_pos := wf_xml.SkipTag(l_hdr_tmp, 'SUBJECT', l_hdr_pos, l_occurance);

  if (l_recp_is_lob) then
    dbms_lob.WriteAppend(l_recp, length(l_hdr_tmp), l_hdr_tmp);
    l_pos := wf_xml.NewLOBTag(l_msg_doc, l_pos, 'HEADER', l_recp, l_attrlist);
  else
    l_hdr_tmp := l_recp_txt || l_hdr_tmp;
    l_pos := wf_xml.NewLOBTag(l_msg_doc, l_pos, 'HEADER', l_hdr_tmp, l_attrlist);
  end if;
  l_pos := wf_xml.SkipLOBTag(l_msg_doc, 'HEADER', l_pos, l_occurance);
  l_attrlist.DELETE;

  -- <CONTENT> start
  wf_xml.AddElementAttribute('content-type', 'multipart/mixed', l_attrlist);
  l_pos := wf_xml.NewLOBTag(l_msg_doc, l_pos, 'CONTENT', '', l_attrlist);
  l_attrlist.DELETE;

  -- <BODYPART> start
  wf_xml.AddElementAttribute('content-type', p_content_type, l_attrlist);
  l_pos := wf_xml.NewLOBTag(l_msg_doc, l_pos, 'BODYPART', '', l_attrlist);

  -- <MESSAGE>

  l_messageIdx := wf_temp_lob.getLOB(g_LOBTable);

  dbms_lob.trim(g_LOBTable(l_messageIdx).temp_lob,0);

  dbms_lob.writeAppend(g_LOBTable(l_messageIdx).temp_lob,
                                    length(l_start_cdata), l_start_cdata);

  dbms_lob.append(dest_lob => g_LOBTable(l_messageIdx).temp_lob,
                  src_lob => p_message);

  if l_idstr is not null and l_fyi_flag = false then
     l_idstr := wf_core.newline||l_idstr;
     l_idsize := length(l_idstr);
     dbms_lob.writeAppend(lob_loc => g_LOBTable(l_messageIdx).temp_lob,
                          amount => l_idsize,
                          buffer => l_idstr);
  end if;

  dbms_lob.writeAppend(g_LOBTable(l_messageIdx).temp_lob,
                                    length(l_end_cdata), l_end_cdata);

  l_pos := wf_xml.NewLOBTag(l_msg_doc, l_pos, 'MESSAGE',
                            g_LOBTable(l_messageIdx).temp_lob, l_attrlist);
  l_pos := wf_xml.SkipLOBTag(l_msg_doc, 'MESSAGE', l_pos, l_occurance);
  l_attrlist.DELETE;

  -- <BODYPART> end
  l_pos := wf_xml.SkipLOBTag(l_msg_doc, 'BODYPART', l_pos, l_occurance);

  -- <CONTENT> end
  l_pos := wf_xml.SkipLOBTag(l_msg_doc, 'CONTENT', l_pos, l_occurance);

  -- <NOTIFICATION> end
  l_pos := wf_xml.SkipLOBTag(l_msg_doc, 'NOTIFICATION', l_pos, l_occurance);

  -- <NOTIFICATIONGROUP> end
  l_pos := wf_xml.SkipLOBTag(l_msg_doc, 'NOTIFICATIONGROUP', l_pos, l_occurance);

  wf_event_t.Initialize(l_event);

  l_event.event_name := wf_xml.WF_NTF_SEND_MESSAGE;

  -- Create an event key based firstly on the parameter. If that does not
  -- exist, then base it on the ID string. If that too is null (FYI for
  -- instance) then create a default, non unique key.
  if p_event_key is not null then
     l_event.event_key := p_event_key;
  elsif p_idstring is not null then
     l_event.event_key := p_idstring;
  else
     l_event.event_key := p_module||':FYI';
  end if;

  l_event.SetEventData(l_msg_doc);

  l_agent := wf_agent_t('WF_NOTIFICATION_OUT', wf_event.local_system_name);
  l_event.SetFromAgent(l_agent);
  l_event.addParameterToList('Q_CORRELATION_ID', send.p_module);
  l_event.addParameterToList('NOTIFICATION_ID', '0');

  wf_event.send(l_event);

exception
  when others then
    wf_core.context('Wf_Mail', 'Send', p_idstring, p_subject);
    raise;
end Send;

-- SetNtfEventsSubStatus
--   This procedure sets the status of seeded subscription to the event group
--   oracle.apps.wf.notification.send.group. This subscription is responsible
--   for notification XML message generation and presenting it to the mailer for
--   e-mail dispatch. Disabling this subscription causes e-mails not to be sent.
--
--    ENABLED  - E-mails are sent
--    DISABLED - E-mails are not sent
-- IN
--   p_status - Subscription status (Either ENABLED or DISABLED)
procedure SetNtfEventsSubStatus(p_status in varchar2)
is
begin

  if (p_status in ('ENABLED', 'DISABLED')) then
    -- Update the notification send event group subscription
    -- with the specified status
    UPDATE wf_event_subscriptions
    SET    status = p_status
    WHERE  rule_data = 'MESSAGE'
    AND    owner_name = 'Oracle Workflow'
    AND    owner_tag = 'FND'
    AND    event_filter_guid
       IN (SELECT guid
           FROM   wf_events
           WHERE  name = 'oracle.apps.wf.notification.send.group'
           AND    type = 'GROUP')
    AND    out_agent_guid
       IN (SELECT guid
           FROM   wf_agents
           WHERE  name = 'WF_NOTIFICATION_OUT'
           AND    system_guid = hextoraw(wf_core.translate('WF_SYSTEM_GUID')))
    AND    customization_level = 'L';

    -- Inform BES cache manager that BES meta-data state has changed
    wf_bes_cache.SetMetaDataUploaded;
  end if;

end SetNtfEventsSubStatus;


-- SetResponseDelimiters
-- Sets the package level variables with one procedure call. The
-- response delimiters are used to determine the free form text
-- values in email notification responses.
--
-- IN
-- open_text - Opening text/plain delimiter
-- close_text - Closing text/plain delimiter
-- open_html - Opening text/html delimiter
-- close_html - Closing text/html delimiter
procedure SetResponseDelimiters(open_text in varchar2,
                                close_text in varchar2,
                                open_html in varchar2,
                                close_html in varchar2)
is
begin
   if open_text is null then
      wf_mail.g_open_text_delimiter := '"';
   else
      wf_mail.g_open_text_delimiter := open_text;
   end if;

   if close_text is null then
      wf_mail.g_close_text_delimiter := '"';
   else
      wf_mail.g_close_text_delimiter := close_text;
   end if;

   if open_html is null then
      wf_mail.g_open_html_delimiter := '''';
   else
      wf_mail.g_open_html_delimiter := open_html;
   end if;

   if open_html is null then
      wf_mail.g_close_html_delimiter := '''';
   else
      wf_mail.g_close_html_delimiter := close_html;
   end if;

end SetResponseDelimiters;


end WF_MAIL;
