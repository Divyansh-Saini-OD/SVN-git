create or replace package xx_crm_phil_prospect as

function report_svn_info return varchar2;

procedure set_apps_env (p_message_level                in  number,
                        p_apps_user_name               in  varchar2, 
                        p_apps_resp_name               in  varchar2, 
                        p_user_id                      out number,
                        p_resp_id                      out number,
                        p_resp_appl_id                 out number,
                        p_sales_application_id         out number,
                        p_ps_ext_demo_attr_group_id    out number,
                        p_ps_ext_contact_attr_group_id out number,
                        p_msg                          out varchar2); 

procedure create_org_party (p_org_name     in  varchar2,
                            p_party_id     out number,
                            p_party_number out varchar2,
                            p_profile_id   out number,
                            p_msg          out varchar2);

procedure create_party_site (p_party_id          in  number,
                             p_address_line1     in  varchar2,
                             p_address_line2     in  varchar2 default null,
                             p_city              in  varchar2,
                             p_state             in  varchar2,
                             p_postal_code       in  varchar2,
                             p_primary_addr_flag in  varchar2, 
                             p_num_wcw_od        in  number,
                             p_rep_resource_id   in  number,
                             p_rep_role_id       in  number,
                             p_rep_group_id      in  number,
                             p_location_id       out number,
                             p_party_site_id     out number,
                             p_party_site_number out varchar2,
                             p_msg               out varchar2);

procedure create_contact (p_org_party_id           in  number,
                          p_org_party_site_id      in  number,
                          p_person_title           in  varchar2,
                          p_first_name             in  varchar2,
                          p_middle_name            in  varchar2  default null,
                          p_last_name              in  varchar2,
                          p_phone                  in  varchar2,
                          p_fax                    in  varchar2,
                          p_email_addr             in  varchar2,
                          p_person_party_id        out number,   -- person
                          p_person_party_number    out varchar2, -- person
                          p_person_profile_id      out number,   -- person
                          p_phone_contact_point_id out number,   -- contact point
                          p_fax_contact_point_id   out number,   -- contact point
                          p_email_contact_point_id out number,   -- contact point
                          p_web_contact_point_id   out number,   -- contact point
                          p_contact_id             out number,   -- contact relationship
                          p_party_relationship_id  out number,   -- contact relationship
                          p_contact_party_id       out number,   -- contact relationship
                          p_contact_party_number   out number,   -- contact relationship
                          p_msg                    out varchar2);

procedure create_contact_points (p_party_id               in  number,
                                 p_phone_number           in  varchar2,
                                 p_fax_number             in  varchar2,
                                 p_email_addr             in  varchar2,
                                 p_url                    in  varchar2,
                                 p_phone_contact_point_id out number,
                                 p_fax_contact_point_id   out number,
                                 p_email_contact_point_id out number,
                                 p_web_contact_point_id   out number,
                                 p_msg                    out varchar2);

procedure get_sales_rep_info (p_rep_resource_num in  varchar2,
                              p_resource_id      out number,
                              p_role_id          out number,
                              p_group_id         out number,
                              p_rep_name         out varchar2,
                              p_job_title        out varchar2,
                              p_group_name       out varchar2,
                              p_legacy_rep_id    out varchar2,
                              p_msg              out varchar2);

procedure create_acct_setup_request_rec (p_org_party_id          in  number,
                                         p_shipto_party_site_id  in  number,
                                         p_billto_party_site_id  in  number,
                                         p_ap_org_contact_id     in  number,
                                         p_sales_org_contact_id  in  number,
                                         p_request_id            out number,
                                         p_msg                   out varchar2);

procedure raise_business_event (p_ready_to_transmit_count out number,
                                p_msg                     out varchar2);


MSG_NONE        constant number := 0;  -- dont print any messages 
MSG_LOW         constant number := 1; 
MSG_MED         constant number := 2; 
MSG_HIGH        constant number := 3;  -- print most detailed messages - probably a lot of output 

end xx_crm_phil_prospect;
/

show errors


CREATE OR REPLACE PACKAGE BODY XX_CRM_PHIL_PROSPECT

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  xx_crm_phil_PROSPECT.pkb                                   |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                          |
-- |                                                                          |
-- | Description :                                                            |
-- |                                                                          |
-- | *** This package is intended for testing purposes only ***               |
-- |                                                                          |
-- | Create a prospect and AP / Sales contacts, then send an Account Setup    |
-- | request to AOPS.                                                         |
-- |                                                                          |
-- | Contact records are placed in Ebiz staging table from salesforce.com by  |
-- | a SOA process.  This program reads all contacts not yet imported into    |
-- | Ebiz where a prospect has been converted into a customer.                |
-- |                                                                          |
-- | Import each contact found if the corresponding corresponding Party       |
-- | is a customer.  Contacts are typically selected for import shortly after |
-- | their corresponding party site changes status from a prospect to         |
-- | a customer.                                                              |
-- |                                                                          |
-- | Parameters  :                                                            |
-- |                                                                          |
-- |   p_timeout_days                                                         |
-- |       Dont process records in xx_xrm_sfdc_contacts with                  |
-- |       last_updated_date < (sysdate - p_timeout_days).                    |
-- |       If p_timeout_days is <= 0 all records in xx_xrm_sfdc_contacts will |
-- |       be processed.                                                      |
-- |                                                                          |
-- |   p_purge_days                                                           |
-- |       Delete records from xx_xrm_sfdc_contacts with                      |
-- |       last_updated_date < (sysdate - p_purge_days) AND import_status in  |
-- |       (NEW, ERROR). If p_purge_days <= 0 no records will be deleted.     |
-- |       The purge process is performed last.  Records eligible for purge   |
-- |       will be processeed instead of purged if they are imported during   |
-- |       the current execution of the program (results in changing          |
-- |       last_updated_date to sysdate).                                     |
-- |                                                                          |
-- |   p_reprocess_errors                                                     |
-- |       Y = Process records with import_status = ERROR in addition to      |
-- |           normal processing. Old records with ERROR status will not be   |
-- |           re-processed if they don't meet the p_timeout_days test.       |
-- |                                                                          |
-- |           Any other value causes records with import_status = ERROR to   |
-- |           be ignored.                                                    |
-- |                                                                          |
-- | Notes:                                                                   |
-- |                                                                          |
-- | Since the AP and eBill contacts are created in salesforce.com only for   |
-- | the purpose of sending them to Ebiz they will be deleted from salesforce |
-- | shortly after tey are sent.  As a result, no contact OSR info will be    |
-- | received from salesforce.                                                |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author             Remarks                         |
-- |========  ===========  =================  ================================|
-- |1.0       25-JUL-2011  Phil Price         Initial version                 |
-- |                                                                          |
-- +==========================================================================+

AS

-- ============================================================================
-- Global Constants
-- ============================================================================

G_PACKAGE CONSTANT VARCHAR2(30) := 'xx_crm_phil_PROSPECT'; 

--
-- Subversion keywords
--
G_SVN_HEAD_URL constant varchar2(500) := '$HeadURL$';
G_SVN_REVISION constant varchar2(100) := '$Rev$';
G_SVN_DATE     constant varchar2(100) := '$Date$';

--
-- Debug levels
--
DBG_OFF   constant number := 0;
DBG_LOW   constant number := 1;
DBG_MED   constant number := 2;
DBG_HI    constant number := 3;

--
--  Log message levels
--
LOG_INFO  constant varchar2(1) := 'I';
LOG_WARN  constant varchar2(1) := 'W';
LOG_ERR   constant varchar2(1) := 'E';

--
--  "who" info
--
ANONYMOUS_APPS_USER constant number := -1; 

--
-- Misc constants
--
SQ constant varchar2(1) := chr(39); -- single quote
LF constant varchar2(1) := chr(10); -- line feed

OUR_MODULE_NAME constant varchar2(10) := 'PHIL';

--
-- Global variables
--
g_commit           boolean;
g_warning_ct       number := 0;
g_debug_level      number := DBG_OFF;

g_org_id            number;
g_user_id           number;
g_last_update_login number;

g_message_level        number := MSG_NONE; 
g_sales_application_id number;
g_ps_ext_contact_attr_group_id number;  -- party site contacts
g_ps_ext_demo_attr_group_id    number;  -- party site ext site demographics
-- ============================================================================


-------------------------------------------------------------------------------
function dti return varchar2 is
-------------------------------------------------------------------------------
begin
    return (to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') || ': ');
end dti;
-- ============================================================================


-------------------------------------------------------------------------------
function getval (p_val in varchar2) return varchar2 is
-------------------------------------------------------------------------------

begin
  if (p_val is null) then return '<null>';
    elsif (p_val = fnd_api.g_miss_char) then return '<missing>';
    else return p_val;
  end if;
end getval;
-- ===========================================================================


-------------------------------------------------------------------------------
function getval (p_val in number) return varchar2 is
-------------------------------------------------------------------------------

begin
  if (p_val is null) then return '<null>';
    elsif (p_val = fnd_api.g_miss_num) then return '<missing>';
    else return to_char(p_val);
  end if;
end getval;
-- ===========================================================================

  
-------------------------------------------------------------------------------
function getval (p_val in date) return varchar2 is
-------------------------------------------------------------------------------

begin
  if (p_val is null) then return '<null>';
    elsif (p_val = fnd_api.g_miss_date) then return '<missing>';
    else return to_char(p_val,'DD-MON-YYYY HH24:MI:SS');
  end if;
end getval;
-- ===========================================================================


-------------------------------------------------------------------------------
function getval (p_val in boolean) return varchar2 is
-------------------------------------------------------------------------------

begin
  if (p_val is null) then return '<null>';
    elsif (p_val = TRUE)  then return '<TRUE>';
    elsif (p_val = FALSE) then return '<FALSE>';
    else return '<???>';
  end if;
end getval;
-- ===========================================================================


-------------------------------------------------------------------------------
function compare_values_vc (val1 in varchar2, val2 in varchar2) return boolean is
-------------------------------------------------------------------------------
begin
  if ((val1 = val2) OR ((val1 is null) AND (val2 is null))) then
    return true;
  else
    return false;
  end if;
end compare_values_vc;
-- ============================================================================


-------------------------------------------------------------------------------
function compare_values_num (val1 in number, val2 in number) return boolean is
-------------------------------------------------------------------------------
begin
  if ((val1 = val2) OR ((val1 is null) AND (val2 is null))) then
    return true;
  else
    return false;
  end if;
end compare_values_num;
-- ============================================================================


-------------------------------------------------------------------------------
function compare_values_dt (val1 in date, val2 in date) return boolean is
-------------------------------------------------------------------------------
begin
  if ((val1 = val2) OR ((val1 is null) AND (val2 is null))) then
    return true;
  else
    return false;
  end if;
end compare_values_dt;
-- ============================================================================


-------------------------------------------------------------------------------
procedure wrtdbg (p_debug_level in  number,
                  p_buff        in varchar2) is
-------------------------------------------------------------------------------

begin
  if (g_debug_level >= p_debug_level) then

    if (p_buff = chr(10)) then
      dbms_output.put_line ('DBG: ');

      else
        dbms_output.put_line ('DBG: ' || dti || p_buff);
     end if;
  end if;
end wrtdbg;
-- ============================================================================


-------------------------------------------------------------------------------
procedure wrtlog (p_buff in varchar2) is
-------------------------------------------------------------------------------

begin
  if (p_buff = chr(10)) then
    dbms_output.put_line ('LOG: ');

  else
    dbms_output.put_line ('LOG: ' || p_buff);
  end if;
end wrtlog;
-- ============================================================================


-------------------------------------------------------------------------------
procedure wrtlog (p_level in varchar2,
                  p_buff  in varchar2) is
-------------------------------------------------------------------------------

begin
  wrtlog (dti || p_level || ': ' || p_buff);
end wrtlog;
-- ============================================================================


-------------------------------------------------------------------------------
procedure wrtout (p_buff in varchar2) is
-------------------------------------------------------------------------------

begin
  if (p_buff = chr(10)) then
    dbms_output.put_line ('OUT: ');

  else
    dbms_output.put_line ('OUT: ' || p_buff);
  end if;
end wrtout;
-- ============================================================================


-------------------------------------------------------------------------------
procedure wrtall (p_buff in varchar2) is
-------------------------------------------------------------------------------

begin
    wrtlog (p_buff);
    wrtout (p_buff);
end wrtall;
-- ============================================================================


------------------------------------------------------------------------------- 
FUNCTION report_svn_info
    return varchar2 IS 
------------------------------------------------------------------------------- 
 
lc_svn_file_name varchar2(200); 
 
begin 
  lc_svn_file_name := regexp_replace(G_SVN_HEAD_URL, '(.*/)([^/]*)( \$)','\2'); 
  return (lc_svn_file_name || ' ' || rtrim(G_SVN_REVISION,'$') || G_SVN_DATE);
END report_svn_info; 
-- ============================================================================ 
 
 
-------------------------------------------------------------------------------
procedure set_apps_env (p_message_level                in  number,
                        p_apps_user_name               in  varchar2, 
                        p_apps_resp_name               in  varchar2, 
                        p_user_id                      out number,
                        p_resp_id                      out number,
                        p_resp_appl_id                 out number,
                        p_sales_application_id         out number,
                        p_ps_ext_demo_attr_group_id    out number,
                        p_ps_ext_contact_attr_group_id out number,
                        p_msg                          out varchar2) is
-------------------------------------------------------------------------------
 
  l_proc varchar2(80)   := 'set_apps_env'; 
  l_ctx  varchar2(2000) := null; 
 
  l_user_id           number; 
  l_resp_id           number; 
  l_resp_appl_id      number; 
 
begin 

  g_message_level := p_message_level; 

  l_ctx := 'select from fnd_user - p_apps_user_name=' || p_apps_user_name; 
  select user_id 
    into l_user_id 
    from fnd_user 
   where user_name = p_apps_user_name; 
 
  l_ctx := 'select from fnd_responsibility_vl - p_apps_resp_name=' || p_apps_resp_name; 
  select responsibility_id, 
         application_id 
    into l_resp_id, 
         l_resp_appl_id 
    from fnd_responsibility_vl 
   where responsibility_name = p_apps_resp_name; 
 
  l_ctx := 'FND_GLOBAL.APPS_INITIALIZE l_user_id=' || l_user_id || 
                                     ' l_resp_id=' || l_resp_id || 
                                     ' l_resp_appl_id=' || l_resp_appl_id; 
 
  FND_GLOBAL.APPS_INITIALIZE (USER_ID      => l_user_id, 
                              RESP_ID      => l_resp_id, 
                              RESP_APPL_ID => l_resp_appl_id); 
 
  g_org_id            := FND_PROFILE.VALUE('org_id');
  g_user_id           := FND_GLOBAL.USER_ID;
  g_last_update_login := FND_GLOBAL.LOGIN_ID;

  l_ctx := 'select from fnd_application_vl';
  select application_id
    into g_sales_application_id
    from apps.fnd_application_vl
   where application_name = 'Sales';

  l_ctx := 'select site demographics attr_group_id';
  select attr_group_id
    into g_ps_ext_demo_attr_group_id
    from apps.ego_attr_groups_v eag 
   where eag.attr_group_type = 'HZ_PARTY_SITES_GROUP'
     and eag.attr_group_name = 'SITE_DEMOGRAPHICS';

  l_ctx := 'select site contacts attr_group_id';
  select attr_group_id
    into g_ps_ext_contact_attr_group_id
    from apps.ego_attr_groups_v eag 
   where eag.attr_group_type = 'HZ_PARTY_SITES_GROUP'
     and eag.attr_group_name = 'SITE_CONTACTS';
 
  p_user_id                      := l_user_id;
  p_resp_id                      := l_resp_id;
  p_resp_appl_id                 := l_resp_id;
  p_sales_application_id         := g_sales_application_id;
  p_ps_ext_demo_attr_group_id    := g_ps_ext_demo_attr_group_id;
  p_ps_ext_contact_attr_group_id := g_ps_ext_contact_attr_group_id;
exception 
  when others then 
    p_msg := l_proc || ' ctx:' || l_ctx || 
             ' SQLCODE=' || SQLCODE || ' SQLERRM=' || SQLERRM; 
end set_apps_env; 
-- ============================================================================


-------------------------------------------------------------------------------
procedure decode_api_error (p_proc          in  varchar2, 
                            p_call          in  varchar2, 
                            p_return_status in  varchar2, 
                            p_msg_count     in  number, 
                            p_msg_data      in  varchar2, 
                            p_addtl_info    in  varchar2,
                            p_msg           out varchar2) is 
-------------------------------------------------------------------------------
 
  l_proc varchar2(80)   := 'decode_api_error'; 
  l_ctx  varchar2(2000) := null; 

  l_err_str  varchar2(2000); 
  l_next_msg varchar2(2000);

begin 
  l_err_str := l_proc || ' p_proc=' || p_proc || '(' || p_call || ') FAILED with x_return_status=' || p_return_status;

  if ((p_addtl_info is not null) and (length(p_addtl_info) > 0)) then
    l_err_str := l_err_str || ' - addtl info: '|| p_addtl_info;
  end if;

  if (p_msg_count = 1) then 
    l_err_str := l_err_str || LF || 'Error: ' || p_msg_data;
  else 
    for I in 1..p_msg_count loop 
      l_next_msg := fnd_msg_pub.get(p_encoded   => fnd_api.g_false,
                                    p_msg_index => I);

      l_err_str := substr(l_err_str || LF || l_next_msg, 1, 2000);
    end loop; 
  end if; 

  p_msg := l_err_str;
 
exception 
  when others then 
    raise_application_error (-20001,'l_proc=' || l_proc || 
                                    ' SQLCODE=' || SQLCODE || ' SQLERRM=' || SQLERRM); 
end decode_api_error; 
-- =========================================================================== 


-------------------------------------------------------------------------------
procedure create_contact_points (p_party_id               in  number,
                                 p_phone_number           in  varchar2,
                                 p_fax_number             in  varchar2,
                                 p_email_addr             in  varchar2,
                                 p_url                    in  varchar2,
                                 p_phone_contact_point_id out number,
                                 p_fax_contact_point_id   out number,
                                 p_email_contact_point_id out number,
                                 p_web_contact_point_id   out number,
                                 p_msg                    out varchar2) is
-------------------------------------------------------------------------------

  l_proc varchar2(80)   := 'create_contact_points'; 
  l_ctx  varchar2(2000) := null; 

  contact_point_rec  hz_contact_point_v2pub.contact_point_rec_type; 
  edi_rec            hz_contact_point_v2pub.edi_rec_type; 
  email_rec          hz_contact_point_v2pub.email_rec_type; 
  phone_rec          hz_contact_point_v2pub.phone_rec_type; 
  telex_rec          hz_contact_point_v2pub.telex_rec_type; 
  web_rec            hz_contact_point_v2pub.web_rec_type; 
 
  x_contact_point_id  number;

  x_return_status      varchar2(2000); 
  x_msg_count          number; 
  x_msg_data           varchar2(2000); 
 
  l_phone_number       varchar2(50); 
  l_fax_number         varchar2(50); 
  l_contact_pt_exists  boolean; 

begin

  p_phone_contact_point_id := null; 
  p_email_contact_point_id := null; 
  p_web_contact_point_id   := null; 

  contact_point_rec      := null; 
  edi_rec                := null; 
  email_rec              := null; 
  phone_rec              := null; 
  telex_rec              := null; 
  web_rec                := null; 

  contact_point_rec.created_by_module     := OUR_MODULE_NAME; 
  contact_point_rec.owner_table_name      := 'HZ_PARTIES';  -- could also be HZ_PARTY_SITES 
  contact_point_rec.owner_table_id        := p_party_id;    -- FK of owner_table_name 

  -- 
  -- Create PHONE contact point 
  -- 
  if (p_phone_number is not null) then 

    contact_point_rec.contact_point_purpose := 'BUSINESS'; -- value from ar_lookups, lookup_type = CONTACT_POINT_PURPOSE 
    contact_point_rec.contact_point_type    := 'PHONE';    -- value from ar_lookups, lookup_type = COMMUNICATION_TYPE 

    l_phone_number := translate (p_phone_number,'x()- ','x'); 

    phone_rec.phone_area_code       := substr(l_phone_number,1,3); 
    phone_rec.phone_country_code    := '1'; 
    phone_rec.phone_number          := substr(l_phone_number,4,3) || '-' || substr(l_phone_number,7,4); 
    phone_rec.phone_extension       := substr(l_phone_number,11); 
    phone_rec.phone_line_type       := 'GEN';   -- validated against AR lookup type PHONE_LINE_TYPE 

    hz_contact_point_v2pub.create_phone_contact_point 
                                      (p_init_msg_list     => FND_API.G_TRUE,
                                       p_contact_point_rec => contact_point_rec, 
                                       p_phone_rec         => phone_rec, 
                                       x_contact_point_id  => x_contact_point_id, 
                                       x_return_status     => x_return_status, 
                                       x_msg_count         => x_msg_count, 
                                       x_msg_data          => x_msg_data); 

    if (x_return_status = fnd_api.g_ret_sts_success) then 
      p_phone_contact_point_id := x_contact_point_id; 

    else 

      decode_api_error (p_proc          => l_proc, 
                        p_call          => 'hz_contact_point_v2pub.create_phone_contact_point(GEN)', 
                        p_return_status => x_return_status, 
                        p_msg_count     => x_msg_count, 
                        p_msg_data      => x_msg_data, 
                        p_addtl_info    => 'PHONE: p_party_id=' || p_party_id || ' phone=' || p_phone_number,
                        p_msg           => p_msg); 
      return;
    end if; 
  end if; 


  -- 
  -- Create FAX contact point 
  -- 
  if (p_fax_number is not null) then 
 
    contact_point_rec.contact_point_purpose := 'BUSINESS'; -- value from ar_lookups, lookup_type = CONTACT_POINT_PURPOSE 
    contact_point_rec.contact_point_type    := 'PHONE';    -- value from ar_lookups, lookup_type = COMMUNICATION_TYPE 

    l_fax_number := translate (p_fax_number,'x()- ','x'); 

    phone_rec.phone_area_code       := substr(l_fax_number,1,3); 
    phone_rec.phone_country_code    := '1'; 
    phone_rec.phone_number          := substr(l_fax_number,4,3) || '-' || substr(l_phone_number,7,4); 
    phone_rec.phone_extension       := substr(l_fax_number,11); 
    phone_rec.phone_line_type       := 'FAX';   -- validated against AR lookup type PHONE_LINE_TYPE 

    hz_contact_point_v2pub.create_phone_contact_point 
                                      (p_init_msg_list     => FND_API.G_TRUE,
                                       p_contact_point_rec => contact_point_rec, 
                                       p_phone_rec         => phone_rec, 
                                       x_contact_point_id  => x_contact_point_id, 
                                       x_return_status     => x_return_status, 
                                       x_msg_count         => x_msg_count, 
                                       x_msg_data          => x_msg_data); 

    if (x_return_status = fnd_api.g_ret_sts_success) then 
      p_fax_contact_point_id := x_contact_point_id; 

    else 

      decode_api_error (p_proc          => l_proc, 
                        p_call          => 'hz_contact_point_v2pub.create_phone_contact_point(FAX)', 
                        p_return_status => x_return_status, 
                        p_msg_count     => x_msg_count, 
                        p_msg_data      => x_msg_data, 
                        p_addtl_info    => 'PHONE: p_party_id=' || p_party_id || ' phone=' || p_phone_number,
                        p_msg           => p_msg); 
      return;
    end if; 
  end if; 

  -- 
  -- Create EMAIL contact point 
  -- 
  if (p_email_addr is not null) then 
    contact_point_rec.contact_point_purpose := 'BUSINESS';  -- value from ar_lookups, lookup_type = CONTACT_POINT_PURPOSE 
    contact_point_rec.contact_point_type    := 'EMAIL';     -- value from ar_lookups, lookup_type = COMMUNICATION_TYPE 

    email_rec.email_format  := 'MAILHTML';  -- value from ar_lookups, lookup_type = EMAIL_FORMAT 
    email_rec.email_address := p_email_addr; 

    hz_contact_point_v2pub.create_email_contact_point 
                                      (p_init_msg_list     => FND_API.G_TRUE, 
                                       p_contact_point_rec => contact_point_rec, 
                                       p_email_rec         => email_rec, 
                                       x_contact_point_id  => x_contact_point_id, 
                                       x_return_status     => x_return_status, 
                                       x_msg_count         => x_msg_count, 
                                       x_msg_data          => x_msg_data); 

    if (x_return_status = fnd_api.g_ret_sts_success) then 

      p_email_contact_point_id := x_contact_point_id; 

    else 
      decode_api_error (p_proc          => l_proc, 
                        p_call          => 'hz_contact_point_v2pub.create_email_contact_point', 
                        p_return_status => x_return_status, 
                        p_msg_count     => x_msg_count, 
                        p_msg_data      => x_msg_data, 
                        p_addtl_info    => 'EMAIL: p_party_id=' || p_party_id || ' email=' || p_email_addr,
                        p_msg           => p_msg); 
      return;
    end if; 
  end if; 


  -- 
  -- Create WEB contact point 
  -- 
  if (p_url is not null) then 
    -- 
    -- value from ar_lookups, lookup_type = CONTACT_POINT_PURPOSE_WEB (info from an error I got) 
    -- 
    contact_point_rec.contact_point_purpose := 'HOMEPAGE';   
    contact_point_rec.contact_point_type    := 'WEB';     -- value from ar_lookups, lookup_type = COMMUNICATION_TYPE 

    web_rec.web_type := 'WEB'; -- value from entry in ar_phones_v created using the form.  API doesnt say what to put here 
    web_rec.url      := p_url; 

    hz_contact_point_v2pub.create_web_contact_point 
                                      (p_init_msg_list     => FND_API.G_TRUE, 
                                       p_contact_point_rec => contact_point_rec, 
                                       p_web_rec           => web_rec, 
                                       x_contact_point_id  => x_contact_point_id, 
                                       x_return_status     => x_return_status, 
                                       x_msg_count         => x_msg_count, 
                                       x_msg_data          => x_msg_data); 

    if (x_return_status = fnd_api.g_ret_sts_success) then 
      p_web_contact_point_id := x_contact_point_id; 

    else 

      decode_api_error (p_proc          => l_proc, 
                        p_call          => 'hz_contact_point_v2pub.create_web_contact_point', 
                        p_return_status => x_return_status, 
                        p_msg_count     => x_msg_count, 
                        p_msg_data      => x_msg_data, 
                        p_addtl_info    => 'WEB: p_party_id=' || p_party_id || ' url=' || p_url,
                        p_msg           => p_msg); 
      return;
    end if; 
  end if; 
 

exception 
  when others then 
    raise_application_error (-20001,'l_proc=' || l_proc || 
                                    ' SQLCODE=' || SQLCODE || ' SQLERRM=' || SQLERRM); 
end create_contact_points;
 -- =========================================================================== 


-------------------------------------------------------------------------------
procedure create_org_party (p_org_name     in  varchar2,
                            p_party_id     out number,
                            p_party_number out varchar2,
                            p_profile_id   out number,
                            p_msg          out varchar2) is
-------------------------------------------------------------------------------

  l_proc varchar2(80)   := 'create_org_party'; 
  l_ctx  varchar2(2000) := null; 

  x_return_status varchar2(1);
  x_msg_count     number;
  x_msg_data      varchar2(2000);
  x_party_id      number;
  x_party_number  apps.hz_parties.party_number %type;
  x_profile_id    number;

  org_rec hz_party_v2pub.organization_rec_type;

begin
  org_rec.organization_name := p_org_name;

  org_rec.created_by_module := OUR_MODULE_NAME;
  org_rec.application_id    := g_sales_application_id;

  org_rec.party_rec.attribute_category := 'US';
  org_rec.party_rec.attribute13        := 'PROSPECT';
  org_rec.party_rec.attribute24        := 'STANDARD';  -- use STANDARD contract template

--.. need to verify country, address1, etc get filled in when i create first (primary) address.
--... same with primary_phone_contact_pt_id, primary_phone_purpose, primary_phone_line_type, primary_phone_country_code and number

  hz_party_v2pub.create_organization (p_init_msg_list    => FND_API.G_TRUE,
                                      p_organization_rec => org_rec,
                                      x_return_status    => x_return_status,
                                      x_msg_count        => x_msg_count,
                                      x_msg_data         => x_msg_data,
                                      x_party_id         => x_party_id,
                                      x_party_number     => x_party_number,
                                      x_profile_id       => x_profile_id);

    if (x_return_status = fnd_api.g_ret_sts_success) then 
      p_party_id     := x_party_id;
      p_party_number := x_party_number;
      p_profile_id   := x_profile_id;

    else

      decode_api_error (p_proc          => l_proc, 
                        p_call          => 'hz_party_v2pub.create_organization',
                        p_return_status => x_return_status, 
                        p_msg_count     => x_msg_count, 
                        p_msg_data      => x_msg_data, 
                        p_addtl_info    => '',
                        p_msg           => p_msg); 
    end if;

exception 
  when others then 
    p_msg := l_proc || ' ctx:' || l_ctx || 
             ' SQLCODE=' || SQLCODE || ' SQLERRM=' || SQLERRM; 
end create_org_party; 
-- ============================================================================


-------------------------------------------------------------------------------
procedure create_location (p_address_line1 in  varchar2,
                           p_address_line2 in  varchar2 default null,
                           p_city          in  varchar2,
                           p_state         in  varchar2,
                           p_postal_code   in  varchar2,
                           p_location_id   out number,
                           p_msg           out varchar2) is
-------------------------------------------------------------------------------

  l_proc varchar2(80)   := 'create_location'; 
  l_ctx  varchar2(2000) := null; 

  x_return_status varchar2(1);
  x_msg_count     number;
  x_msg_data      varchar2(2000);

  x_location_id   number;

  loc_rec hz_location_v2pub.location_rec_type;

begin

  loc_rec.created_by_module := OUR_MODULE_NAME; 
 
  loc_rec.address1       := p_address_line1; 
  loc_rec.address2       := p_address_line2; 
  loc_rec.city           := p_city; 
  loc_rec.state          := p_state; 
  loc_rec.postal_code    := p_postal_code; 
  loc_rec.country        := 'US';
  loc_rec.address_style  := 'AS_DEFAULT';
  loc_rec.application_id := g_sales_application_id;

  hz_location_v2pub.create_location (p_init_msg_list => FND_API.G_TRUE, 
                                     p_location_rec  => loc_rec, 
                                     x_location_id   => x_location_id, 
                                     x_return_status => x_return_status, 
                                     x_msg_count     => x_msg_count, 
                                     x_msg_data      => x_msg_data); 

  if (x_return_status = fnd_api.g_ret_sts_success) then 
    p_location_id := x_location_id;

  else

    decode_api_error (p_proc          => l_proc, 
                      p_call          => 'hz_location_v2pub.create_location',
                      p_return_status => x_return_status, 
                      p_msg_count     => x_msg_count, 
                      p_msg_data      => x_msg_data, 
                      p_addtl_info    => '',
                      p_msg           => p_msg); 
  end if;

exception 
  when others then 
    p_msg := l_proc || ' ctx:' || l_ctx || 
             ' SQLCODE=' || SQLCODE || ' SQLERRM=' || SQLERRM; 
end create_location;
-- ============================================================================


-------------------------------------------------------------------------------
procedure create_site_ext_demographic
                            (p_party_site_id     in  number,
                             p_num_wcw_od        in  number,
                             p_msg               out varchar2) is
-------------------------------------------------------------------------------

  l_proc varchar2(80)   := 'create_site_ext_demographic'; 
  l_ctx  varchar2(2000) := null; 

  x_return_status varchar2(1);
  x_msg_count     number;
  x_msg_data      varchar2(2000);
  x_errorcode     number;

  x_failed_row_id_list  varchar2(2000);  -- Comma delimited list of ROW_IDENTIFIERs that errored
  indx                  number := 0;
  l_attr_row_identifier constant number := 1;

  attr_row_tbl   ego_user_attr_row_table  := ego_user_attr_row_table();
  attr_row_empty ego_user_attr_row_obj    := ego_user_attr_row_obj (null, null, null, null, null, null, null, null, null);

  attr_data_tbl   ego_user_attr_data_table := ego_user_attr_data_table();
  attr_data_empty ego_user_attr_data_obj   := ego_user_attr_data_obj (null, null, null, null, null, null, null, null);

begin
  l_ctx := 'attr_row_tbl-1';
  attr_row_tbl.EXTEND;
  attr_row_tbl(1)                  := attr_row_empty;
  attr_row_tbl(1).row_identifier   := l_attr_row_identifier;  -- arbitrary value that must match row_identifier in attr_data_tbl
  attr_row_tbl(1).attr_group_id    := g_ps_ext_demo_attr_group_id;
  attr_row_tbl(1).transaction_type := EGO_USER_ATTRS_DATA_PVT.G_SYNC_MODE;

  --
  -- Start can-cross-sell
  --
  indx:= indx + 1;

  l_ctx := 'attr_data_tbl-' || indx;
  attr_data_tbl.EXTEND;
  attr_data_tbl(indx)                     := attr_data_empty;
  attr_data_tbl(indx).row_identifier      := l_attr_row_identifier;
  attr_data_tbl(indx).attr_name           := 'SITEDEMO_CANCROSS';
  attr_data_tbl(indx).attr_value_str      := 'N';
  attr_data_tbl(indx).user_row_identifier := 7777;  -- arbitrary number to check for errors in mtl_interface_errors.transaction_id
  --
  -- End can-cross-sell
  --


  --
  -- Start OD WCW count
  --
  indx := indx + 1;

  l_ctx := 'attr_data_tbl-' || indx;
  attr_data_tbl.EXTEND;
  attr_data_tbl(indx)                     := attr_data_empty;
  attr_data_tbl(indx).row_identifier      := l_attr_row_identifier;
  attr_data_tbl(indx).attr_name           := 'SITEDEMO_OD_WCW';
  attr_data_tbl(indx).attr_value_num      := p_num_wcw_od;
  attr_data_tbl(indx).user_row_identifier := 7777;  -- arbitrary number to check for errors in mtl_interface_errors.transaction_id
  --
  -- End OD WCW count
  --

  l_ctx := 'process_partysite_record';
  hz_extensibility_pub.process_partysite_record (p_init_fnd_msg_list       => FND_API.G_TRUE,
                                                 p_init_error_handler      => FND_API.G_TRUE,
                                                 p_add_errors_to_fnd_stack => FND_API.G_TRUE,
                                                 p_api_version             => 1.0,
                                                 p_debug_level             => 0,
                                                 p_party_site_id           => p_party_site_id,
                                                 p_commit                  => FND_API.G_FALSE,
                                                 p_attributes_row_table    => attr_row_tbl,
                                                 p_attributes_data_table   => attr_data_tbl,
                                                 x_failed_row_id_list      => x_failed_row_id_list,
                                                 x_return_status           => x_return_status,
                                                 x_errorcode               => x_errorcode,
                                                 x_msg_count               => x_msg_count,
                                                 x_msg_data                => x_msg_data);

  if (x_return_status = fnd_api.g_ret_sts_success) then 
    null;

  else

    decode_api_error (p_proc          => l_proc, 
                      p_call          => 'hz_extensibility_pub.process_partysite_record',
                      p_return_status => x_return_status, 
                      p_msg_count     => x_msg_count, 
                      p_msg_data      => x_msg_data, 
                      p_addtl_info    => 'x_failed_row_id_list="' || x_failed_row_id_list || '"',
                      p_msg           => p_msg); 
  end if;

exception 
  when others then 
    p_msg := l_proc || ' ctx:' || l_ctx || 
             ' SQLCODE=' || SQLCODE || ' SQLERRM=' || SQLERRM; 
end create_site_ext_demographic;
-- ============================================================================


-------------------------------------------------------------------------------
procedure create_site_ext_contact
                            (p_party_site_id         in  number,
                             p_party_relationship_id in  number,
                             p_msg                   out varchar2) is
-------------------------------------------------------------------------------

  l_proc varchar2(80)   := 'create_site_ext_contact'; 
  l_ctx  varchar2(2000) := null; 

  x_return_status varchar2(1);
  x_msg_count     number;
  x_msg_data      varchar2(2000);
  x_errorcode     number;

  x_failed_row_id_list varchar2(2000);  -- Comma delimited list of ROW_IDENTIFIERs that errored
  indx                 number := 0;
  l_attr_row_identifier constant number := 1;

  attr_row_tbl   ego_user_attr_row_table  := ego_user_attr_row_table();
  attr_row_empty ego_user_attr_row_obj    := ego_user_attr_row_obj (null, null, null, null, null, null, null, null, null);

  attr_data_tbl   ego_user_attr_data_table := ego_user_attr_data_table();
  attr_data_empty ego_user_attr_data_obj   := ego_user_attr_data_obj (null, null, null, null, null, null, null, null);

begin
  l_ctx := 'attr_row_tbl-1';
  attr_row_tbl.EXTEND;
  attr_row_tbl(1)                  := attr_row_empty;
  attr_row_tbl(1).row_identifier   := l_attr_row_identifier;  -- arbitrary value that must match row_identifier in attr_data_tbl
  attr_row_tbl(1).attr_group_id    := g_ps_ext_contact_attr_group_id;
  attr_row_tbl(1).transaction_type := EGO_USER_ATTRS_DATA_PVT.G_SYNC_MODE;

  --
  -- Start party_relationship_id - this value must be first because it is required in the extensions table.
  --
  indx := indx + 1;

  l_ctx := 'attr_data_tbl-' || indx;
  attr_data_tbl.EXTEND;
  attr_data_tbl(indx)                     := attr_data_empty;
  attr_data_tbl(indx).row_identifier      := l_attr_row_identifier;
  attr_data_tbl(indx).attr_name           := 'SITECNTCT_RELATIONSHIP_ID';
  attr_data_tbl(indx).attr_value_num      := p_party_relationship_id;
  attr_data_tbl(indx).user_row_identifier := 7777;  -- arbitrary number to check for errors in mtl_interface_errors.transaction_id
  --
  -- End party_relationship_id
  --


  --
  -- Start status
  --
  indx := indx + 1;

  l_ctx := 'attr_data_tbl-' || indx;
  attr_data_tbl.EXTEND;
  attr_data_tbl(indx)                     := attr_data_empty;
  attr_data_tbl(indx).row_identifier      := l_attr_row_identifier;
  attr_data_tbl(indx).attr_name           := 'SITECNTCT_STATUS';
  attr_data_tbl(indx).attr_value_str      := 'A';
  attr_data_tbl(indx).user_row_identifier := 7777;  -- arbitrary number to check for errors in mtl_interface_errors.transaction_id
  --
  -- End status
  --


  --
  -- Start start_date
  --
  indx := indx + 1;

  l_ctx := 'attr_data_tbl-' || indx;
  attr_data_tbl.EXTEND;
  attr_data_tbl(indx)                     := attr_data_empty;
  attr_data_tbl(indx).row_identifier      := l_attr_row_identifier;
  attr_data_tbl(indx).attr_name           := 'SITECNTCT_START_DT';
  attr_data_tbl(indx).attr_value_date     := sysdate;
  attr_data_tbl(indx).user_row_identifier := 7777;  -- arbitrary number to check for errors in mtl_interface_errors.transaction_id
  --
  -- End start_date
  --

  l_ctx := 'process_partysite_record';
  hz_extensibility_pub.process_partysite_record (p_init_fnd_msg_list       => FND_API.G_TRUE,
                                                 p_init_error_handler      => FND_API.G_TRUE,
                                                 p_add_errors_to_fnd_stack => FND_API.G_TRUE,
                                                 p_api_version             => 1.0,
                                                 p_debug_level             => 0,
                                                 p_party_site_id           => p_party_site_id,
                                                 p_commit                  => FND_API.G_FALSE,
                                                 p_attributes_row_table    => attr_row_tbl,
                                                 p_attributes_data_table   => attr_data_tbl,
                                                 x_failed_row_id_list      => x_failed_row_id_list,
                                                 x_return_status           => x_return_status,
                                                 x_errorcode               => x_errorcode,
                                                 x_msg_count               => x_msg_count,
                                                 x_msg_data                => x_msg_data);

  if (x_return_status = fnd_api.g_ret_sts_success) then 
    null;

  else

    decode_api_error (p_proc          => l_proc, 
                      p_call          => 'hz_extensibility_pub.process_partysite_record',
                      p_return_status => x_return_status, 
                      p_msg_count     => x_msg_count, 
                      p_msg_data      => x_msg_data, 
                      p_addtl_info    => 'x_failed_row_id_list="' || x_failed_row_id_list || '"',
                      p_msg           => p_msg); 
  end if;

exception 
  when others then 
    p_msg := l_proc || ' ctx:' || l_ctx || 
             ' SQLCODE=' || SQLCODE || ' SQLERRM=' || SQLERRM; 
end create_site_ext_contact;
-- ============================================================================


-------------------------------------------------------------------------------
procedure get_sales_rep_info (p_rep_resource_num in  varchar2,
                              p_resource_id      out number,
                              p_role_id          out number,
                              p_group_id         out number,
                              p_rep_name         out varchar2,
                              p_job_title        out varchar2,
                              p_group_name       out varchar2,
                              p_legacy_rep_id    out varchar2,
                              p_msg              out varchar2) is
-------------------------------------------------------------------------------

  l_proc varchar2(80)   := 'get_sales_rep_info'; 
  l_ctx  varchar2(2000) := null; 

  l_resource_id    number;
  l_resource_name  jtf_rs_resource_extns_vl.source_name %type;
  l_job_title      jtf_rs_resource_extns_vl.source_job_title %type;
  l_legacy_rep_id  jtf_rs_role_relations.attribute15 %type;

  l_role_relate_id  number;
  l_role_id         number;

  l_group_id    number;
  l_group_name  apps.jtf_rs_groups_vl.group_name %type;

begin
  -- Execute separate queries instead of one big one so we know which one fails if there is an error.

  l_ctx := 'select from jtf_rs_resource_extns - p_rep_resource_num=' || p_rep_resource_num;
  select resource_id,
         source_name,
         source_job_title
    into l_resource_id,
         l_resource_name,
         l_job_title
    from apps.jtf_rs_resource_extns_vl
   where resource_number = p_rep_resource_num
     and category        = 'EMPLOYEE'
     and trunc(sysdate)  between start_date_active and nvl(end_date_active, sysdate +1);

  l_ctx := 'select from jtf_rs_role_relations - l_resource_id=' || l_resource_id;
  select role_relate_id,
         role_id,
         attribute15
    into l_role_relate_id,
         l_role_id,
         l_legacy_rep_id
    from apps.jtf_rs_role_relations
   where role_resource_id   = l_resource_id
     and role_resource_type = 'RS_INDIVIDUAL'
     and delete_flag        = 'N'
     and trunc(sysdate)     between start_date_active and nvl(end_date_active, sysdate +1);

  l_ctx := 'select from jtf_rs_group_members_vl';
  select grp.group_id,
         grp.group_name
    into l_group_id,
         l_group_name
    from apps.jtf_rs_group_members mem,
         apps.jtf_rs_groups_vl     grp
   where mem.group_id    = grp.group_id
     and mem.resource_id = l_resource_id
     and mem.delete_flag = 'N'
     and trunc(sysdate)  between grp.start_date_active and nvl(grp.end_date_active, sysdate +1);

  -- If we are here, above queries were successful.

  p_resource_id   := l_resource_id;
  p_role_id       := l_role_id;
  p_group_id      := l_group_id;
  p_rep_name      := l_resource_name;
  p_job_title     := l_job_title;
  p_group_name    := l_group_name;
  p_legacy_rep_id := l_legacy_rep_id;

exception 
  when others then 
    p_msg := l_proc || ' ctx:' || l_ctx || 
             ' SQLCODE=' || SQLCODE || ' SQLERRM=' || SQLERRM; 
end get_sales_rep_info;
-- ============================================================================


-------------------------------------------------------------------------------
procedure assign_rep_to_party_site (p_party_site_id   in  number,
                                    p_rep_resource_id in  number,
                                    p_rep_role_id     in  number,
                                    p_rep_group_id    in  number,
                                    p_msg             out varchar2) is
-------------------------------------------------------------------------------

  l_proc varchar2(80)   := 'assign_rep_to_party_site'; 
  l_ctx  varchar2(2000) := null; 

  -- value must exist in fnd_lookup_values_vl.lookup_code where lookup_type = 'XX_SFA_TERR_ASGNMNT_SOURCE'
  l_terr_assignment_source varchar2(30) := 'TERR_OVERRIDE';

  x_return_status  varchar2(1); 
  x_error_message  varchar2(2000);

begin
  l_ctx := 'xx_jtf_rs_named_acc_terr_pub.create_territory - p_rep_resource_id=' || p_rep_resource_id ||
                   ' p_rep_role_id=' || p_rep_role_id || ' p_rep_group_id=' || p_rep_group_id;

  xx_jtf_rs_named_acc_terr_pub.create_territory
                (p_api_version_number       => 1.0
                 ,p_named_acct_terr_id      => NULL
                 ,p_named_acct_terr_name    => NULL
                 ,p_named_acct_terr_desc    => NULL
                 ,p_status                  => 'A'
                 ,p_start_date_active       => SYSDATE
                 ,p_end_date_active         => NULL
                 ,p_full_access_flag        => 'Y'
                 ,p_source_terr_id          => null
                 ,p_resource_id             => p_rep_resource_id
                 ,p_role_id                 => p_rep_role_id
                 ,p_group_id                => p_rep_group_id
                 ,p_entity_type             => 'PARTY_SITE'
                 ,p_entity_id               => p_party_site_id
                 ,p_source_entity_id        => NULL
                 ,p_source_system           => NULL
                 ,p_allow_inactive_resource => 'N'
                 ,p_set_extracted_status    => 'N'
                 ,p_terr_asgnmnt_source     => l_terr_assignment_source
                 ,p_commit                  => FALSE
                 ,x_error_code              => x_return_status
                 ,x_error_message           => x_error_message);

  if (x_return_status != FND_API.G_RET_STS_SUCCESS) then
    p_msg := l_proc || ' ctx:' || l_ctx || ' x_return_status=' || x_return_status || ' x_error_message=' || x_error_message;
  end if;

exception 
  when others then 
    p_msg := l_proc || ' ctx:' || l_ctx || 
             ' SQLCODE=' || SQLCODE || ' SQLERRM=' || SQLERRM; 
end assign_rep_to_party_site;
-- ============================================================================


-------------------------------------------------------------------------------
procedure create_party_site (p_party_id          in  number,
                             p_address_line1     in  varchar2,
                             p_address_line2     in  varchar2 default null,
                             p_city              in  varchar2,
                             p_state             in  varchar2,
                             p_postal_code       in  varchar2,
                             p_primary_addr_flag in  varchar2, 
                             p_num_wcw_od        in  number,
                             p_rep_resource_id   in  number,
                             p_rep_role_id       in  number,
                             p_rep_group_id      in  number,
                             p_location_id       out number,
                             p_party_site_id     out number,
                             p_party_site_number out varchar2,
                             p_msg               out varchar2) is
-------------------------------------------------------------------------------

  l_proc varchar2(80)   := 'create_party_site'; 
  l_ctx  varchar2(2000) := null; 

  l_location_id   number;

  x_return_status varchar2(1);
  x_msg_count     number;
  x_msg_data      varchar2(2000);

  x_party_site_id       number; 
  x_party_site_number   apps.hz_party_sites.party_site_number %type;

  ps_rec hz_party_site_v2pub.party_site_rec_type;

begin

  create_location (p_address_line1 => p_address_line1,
                   p_address_line2 => p_address_line2,
                   p_city          => p_city,
                   p_state         => p_state,
                   p_postal_code   => p_postal_code,
                   p_location_id   => l_location_id,
                   p_msg           => p_msg);

  if (p_msg is not null) then
    return;
  end if;

  ps_rec.created_by_module := OUR_MODULE_NAME; 

  ps_rec.party_id                 := p_party_id; 
  ps_rec.location_id              := l_location_id; 
  ps_rec.identifying_address_flag := p_primary_addr_flag;
  ps_rec.application_id           := g_sales_application_id;

  if (nvl(p_primary_addr_flag,'N') != 'Y') then
    ps_rec.attribute1  := 'Y';  -- Has Elevator
    ps_rec.attribute2  := 'Y';  -- Inside City Limits
    ps_rec.attribute12 := 'N';  -- Named Account Flag
  end if;
 
  hz_party_site_v2pub.create_party_site (p_init_msg_list     => FND_API.G_TRUE,
                                         p_party_site_rec    => ps_rec, 
                                         x_party_site_id     => x_party_site_id, 
                                         x_party_site_number => x_party_site_number, 
                                         x_return_status     => x_return_status, 
                                         x_msg_count         => x_msg_count, 
                                         x_msg_data          => x_msg_data); 

  if (x_return_status = fnd_api.g_ret_sts_success) then 
    p_location_id       := l_location_id;
    p_party_site_id     := x_party_site_id;
    p_party_site_number := x_party_site_number;

  else

    decode_api_error (p_proc          => l_proc, 
                      p_call          => 'hz_party_site_v2pub.create_party_site',
                      p_return_status => x_return_status, 
                      p_msg_count     => x_msg_count, 
                      p_msg_data      => x_msg_data, 
                      p_addtl_info    => '',
                      p_msg           => p_msg); 
    return;
  end if;

  create_site_ext_demographic (p_party_site_id => x_party_site_id,
                               p_num_wcw_od    => p_num_wcw_od,
                               p_msg           => p_msg);

  if (p_msg is not null) then
    return;
  end if;

  if (p_rep_resource_id is not null) and (p_rep_role_id is not null) and (p_rep_group_id is not null) then

    assign_rep_to_party_site (p_party_site_id   => x_party_site_id,
                              p_rep_resource_id => p_rep_resource_id,
                              p_rep_role_id     => p_rep_role_id,
                              p_rep_group_id    => p_rep_group_id,
                              p_msg              => p_msg);
  end if;

exception 
  when others then 
    p_msg := l_proc || ' ctx:' || l_ctx || 
             ' SQLCODE=' || SQLCODE || ' SQLERRM=' || SQLERRM; 
end create_party_site; 
-- ============================================================================


-------------------------------------------------------------------------------
procedure create_contact (p_org_party_id           in  number,
                          p_org_party_site_id      in  number,
                          p_person_title           in  varchar2,
                          p_first_name             in  varchar2,
                          p_middle_name            in  varchar2  default null,
                          p_last_name              in  varchar2,
                          p_phone                  in  varchar2,
                          p_fax                    in  varchar2,
                          p_email_addr             in  varchar2,
                          p_person_party_id        out number,   -- person
                          p_person_party_number    out varchar2, -- person
                          p_person_profile_id      out number,   -- person
                          p_phone_contact_point_id out number,   -- contact point
                          p_fax_contact_point_id   out number,   -- contact point
                          p_email_contact_point_id out number,   -- contact point
                          p_web_contact_point_id   out number,   -- contact point
                          p_contact_id             out number,   -- contact relationship
                          p_party_relationship_id  out number,   -- contact relationship
                          p_contact_party_id       out number,   -- contact relationship
                          p_contact_party_number   out number,   -- contact relationship
                          p_msg                    out varchar2) is
-------------------------------------------------------------------------------

  l_proc varchar2(80)   := 'create_contact'; 
  l_ctx  varchar2(2000) := null; 

  x_return_status varchar2(1);
  x_msg_count     number;
  x_msg_data      varchar2(2000);

  x_person_party_id      number;
  x_person_party_number  apps.hz_parties.party_number %type; 
  x_person_profile_id    number;

  l_phone_contact_point_id  number;
  l_fax_contact_point_id    number;
  l_email_contact_point_id  number;
  l_web_contact_point_id    number;

  x_contact_id               number;
  x_party_relationship_id    number;
  x_contact_party_id     number;
  x_contact_party_number apps.hz_parties.party_number %type;

  person_rec      hz_party_v2pub.person_rec_type; 
  org_contact_rec hz_party_contact_v2pub.org_contact_rec_type; 

begin

  person_rec.created_by_module     := OUR_MODULE_NAME; 
 
  person_rec.person_title          := p_person_title; 
  person_rec.person_first_name     := p_first_name; 
  person_rec.person_middle_name    := p_middle_name; 
  person_rec.person_last_name      := p_last_name; 
 
  l_ctx := 'create_person';
  hz_party_v2pub.create_person (p_init_msg_list   => FND_API.G_TRUE, 
                                p_person_rec      => person_rec, 
                                x_party_id        => x_person_party_id, 
                                x_party_number    => x_person_party_number, 
                                x_profile_id      => x_person_profile_id, 
                                x_return_status   => x_return_status, 
                                x_msg_count       => x_msg_count, 
                                x_msg_data        => x_msg_data); 
 
  if (x_return_status = fnd_api.g_ret_sts_success) then 
    p_person_party_id     := x_person_party_id; 
    p_person_party_number := x_person_party_number;
    p_person_profile_id   := x_person_profile_id;

  else
    decode_api_error (p_proc          => l_proc, 
                      p_call          => 'hz_party_v2pub.create_person',
                      p_return_status => x_return_status, 
                      p_msg_count     => x_msg_count, 
                      p_msg_data      => x_msg_data, 
                      p_addtl_info    => '',
                      p_msg           => p_msg); 
    return;
  end if;

  --
  -- Associate the new person party (contact) with the organization party
  --
  org_contact_rec.created_by_module := OUR_MODULE_NAME; 
  org_contact_rec.job_title         := null;  -- placeholder in case we want to add a job title for the contact

  org_contact_rec.party_rel_rec.subject_id         := p_person_party_id; 
  org_contact_rec.party_rel_rec.subject_type       := 'PERSON'; 
  org_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES'; 
  org_contact_rec.party_rel_rec.object_id          := p_org_party_id; 
  org_contact_rec.party_rel_rec.object_type        := 'ORGANIZATION'; 
  org_contact_rec.party_rel_rec.object_table_name  := 'HZ_PARTIES'; 
  org_contact_rec.party_rel_rec.relationship_code  := 'CONTACT_OF'; 
  org_contact_rec.party_rel_rec.relationship_type  := 'CONTACT'; 
  org_contact_rec.party_rel_rec.start_date         := trunc(SYSDATE); 
  org_contact_rec.party_rel_rec.status             := 'A';
  org_contact_rec.party_rel_rec.created_by_module  := OUR_MODULE_NAME;
  org_contact_rec.party_rel_rec.attribute20        := null;  -- Ebiz has a value here;  need to figure out what it is.  It's not a registered DFF.

  hz_party_contact_v2pub.create_org_contact (p_init_msg_list   => FND_API.G_TRUE,
                                             p_org_contact_rec => org_contact_rec, 
                                             x_org_contact_id  => x_contact_id, 
                                             x_party_rel_id    => x_party_relationship_id, 
                                             x_party_id        => x_contact_party_id, 
                                             x_party_number    => x_contact_party_number, 
                                             x_return_status   => x_return_status, 
                                             x_msg_count       => x_msg_count, 
                                             x_msg_data        => x_msg_data); 
 
  if (x_return_status = fnd_api.g_ret_sts_success) then 
    p_contact_id            := x_contact_id; 
    p_party_relationship_id := x_party_relationship_id; 
    p_contact_party_id      := x_contact_party_id; 
    p_contact_party_number  := x_contact_party_number; 
    
  else
    decode_api_error (p_proc          => l_proc, 
                      p_call          => 'hz_party_contact_v2pub.create_org_contact',
                      p_return_status => x_return_status, 
                      p_msg_count     => x_msg_count, 
                      p_msg_data      => x_msg_data, 
                      p_addtl_info    => '',
                      p_msg           => p_msg); 
    return;
  end if;

  --
  -- Create the contact points for the relationship party, not the person party.
  -- This is because the contact person doesn't own the phone # and email addr.
  -- The contat person has these contact points only because of their relationship
  -- with the organization party.
  --
  -- Note: x_contact_party_id: this is the party with the name org-person with party_type = "PARTY_RELATIONSHIP
  --
  create_contact_points (p_party_id               => x_contact_party_id,
                         p_phone_number           => p_phone,
                         p_fax_number             => p_fax,
                         p_email_addr             => p_email_addr,
                         p_url                    => null,
                         p_phone_contact_point_id => l_phone_contact_point_id,
                         p_fax_contact_point_id   => l_fax_contact_point_id,
                         p_email_contact_point_id => l_email_contact_point_id,
                         p_web_contact_point_id   => l_web_contact_point_id,
                         p_msg                    => p_msg);

  if (p_msg is not null) then
    return;
  end if;

  p_phone_contact_point_id := l_phone_contact_point_id;
  p_fax_contact_point_id   := l_fax_contact_point_id;
  p_email_contact_point_id := l_email_contact_point_id;
  p_web_contact_point_id   := l_web_contact_point_id;

  --
  -- Associate the contact with the party site
  --
  create_site_ext_contact (p_party_site_id         => p_org_party_site_id,
                           p_party_relationship_id => x_party_relationship_id,
                           p_msg                   => p_msg);

  if (p_msg is not null) then
    return;
  end if;

exception 
  when others then 
    p_msg := l_proc || ' ctx:' || l_ctx || 
             ' SQLCODE=' || SQLCODE || ' SQLERRM=' || SQLERRM; 
end create_contact; 
-- ============================================================================


-------------------------------------------------------------------------------
procedure create_acct_setup_request_rec (p_org_party_id          in  number,
                                         p_shipto_party_site_id  in  number,
                                         p_billto_party_site_id  in  number,
                                         p_ap_org_contact_id     in  number,
                                         p_sales_org_contact_id  in  number,
                                         p_request_id            out number,
                                         p_msg                   out varchar2) is
-------------------------------------------------------------------------------

  l_proc varchar2(80)   := 'create_acct_setup_request_rec'; 
  l_ctx  varchar2(2000) := null; 

  l_request_id  number;
  l_curr_date   date := sysdate;

  l_acct_setup_status      constant varchar2(10) := 'Submitted';
  l_contract_template_name varchar2(50);
  l_db_name                varchar2(20);

  cursor c_contract_template (c_contract_template_name varchar2) is
    select ct.contract_template_id,
           ct.off_contract_percent,
           ct.off_wholesale_percent,
           ct.gp_floor_percent,
           ct.freight_charge,
           ct.off_contract_code,
           ct.off_wholesale_code,
           flv1.meaning  off_contract_desc,
           flv2.meaning  off_wholesale_desc
      from apps.xx_cdh_contract_template ct,
           apps.fnd_lookup_values        flv1,
           apps.fnd_lookup_values        flv2
     where ct.off_contract_code  = flv1.lookup_code
       and ct.off_wholesale_code = flv2.lookup_code
       and flv1.lookup_type      = 'XXOD_ASN_ACCT_SETUP_UPOFF'
       and flv2.lookup_type      = 'XXOD_ASN_ACCT_SETUP_UPOFF'
       and template_name         = c_contract_template_name;

  ct_rec       c_contract_template %rowtype;
  ct_rec_dummy c_contract_template %rowtype;

begin
  l_ctx := 'get db name';
  select distinct name
   into l_db_name
   from v$database;

  if (upper(l_db_name)in ('GSISIT01','GSISIT02')) then
    l_contract_template_name := 'Standard Core Template';
  else
    l_contract_template_name := 'Standard Template';
  end if;

  l_ctx := 'open c_contract_template - l_contract_template_name=' || l_contract_template_name;
  open c_contract_template (l_contract_template_name);

  fetch c_contract_template into ct_rec;

  if (c_contract_template %notfound) then
    close c_contract_template;
    p_msg := 'ERROR: contract template "' || l_contract_template_name || '" not found in xx_cdh_contract_template';
    return;
  end if;

  fetch c_contract_template into ct_rec_dummy;

  if (c_contract_template %found) then
    close c_contract_template;
    p_msg := 'ERROR: contract template "' || l_contract_template_name || '" has multiple records in xx_cdh_contract_template';
    return;
  end if;

  l_ctx := 'close c_contract_template';
  close c_contract_template;

  l_ctx := 'select xx_cdh_account_setup_req_s.nextval';
  select apps.xx_cdh_account_setup_req_s.nextval
    into l_request_id
    from dual;

  l_ctx := 'insert xx_cdh_account_setup_req';
  insert into apps.xx_cdh_account_setup_req (request_id,
                                             status,
                                             status_transition_date,
                                             account_creation_system,
                                             bill_to_site_id,
                                             ship_to_site_id,
                                             created_by,
                                             creation_date,
                                             last_updated_by,
                                             last_update_date,
                                             last_update_login,
                                             party_id,
                                             off_contract_percentage,
                                             wholesale_percentage,
                                             gp_floor_percentage,
                                             price_plan,
                                             po_validated,
                                             release_validated,
                                             department_validated,
                                             desktop_validated,
                                             afax,
                                             freight_charge,
                                             fax_order,
                                             substitutions,
                                             back_orders,
                                             delivery_document_type,
                                             print_invoice,
                                             display_back_order,
                                             rename_packing_list,
                                             display_purchase_order,
                                             display_payment_method,
                                             display_prices,
                                             payment_method,
                                             ap_contact,
                                             delete_flag,
                                             attribute5,    -- contract_template_id
                                             attribute13,   -- sales contact
                                             attribute14,   -- segmentation
                                             off_contract_code,
                                             off_wholesale_code,
                                             contract_template_id)
          values (l_request_id,                      -- request_id
                  l_acct_setup_status,               -- status
                  l_curr_date,                       -- status_transition_date
                  'AOPS',                            -- account_creation_system
                  p_billto_party_site_id,            -- bill_to_site_id
                  p_shipto_party_site_id,            -- ship_to_site_id
                  g_user_id,                         -- created_by
                  l_curr_date,                       -- creation_date
                  g_user_id,                         -- last_updated_by
                  l_curr_date,                       -- last_update_date
                  g_last_update_login,               -- last_update_login
                  p_org_party_id,                    -- party_id
                  ct_rec.off_contract_percent,       -- off_contract_percentage
                  ct_rec.off_wholesale_percent,      -- wholesale_percentage
                  ct_rec.gp_floor_percent,           -- gp_floor_percentage
                  '720135',                          -- price_plan
                  'H',                               -- po_validated
                  'H',                               -- release_validated
                  'H',                               -- department_validated
                  'H',                               -- desktop_validated
                  'Y',                               -- afax
                  ct_rec.freight_charge,             -- freight_charge
                  'N',                               -- fax_order
                  'Y',                               -- substitutions
                  'Y',                               -- back_orders
                  'INV',                             -- delivery_document_type
                  'Y',                               -- print_invoice
                  'Y',                               -- display_back_order
                  'Y',                               -- rename_packing_list
                  'Y',                               -- display_purchase_order
                  'N',                               -- display_payment_method
                  'N',                               -- display_prices
                  'AB',                              -- payment_method
                  p_ap_org_contact_id,               -- ap_contact
                  'N',                               -- delete_flag
                  ct_rec.contract_template_id,       -- attribute5
                  p_sales_org_contact_id,            -- attribute13    -- sales contact
                  'Medium (100-250 WCW) - Private',  -- attribute14    -- segmentation
                  ct_rec.off_contract_desc,          -- off_contract_code
                  ct_rec.off_wholesale_desc,         -- off_wholesale_code
                  ct_rec.contract_template_id);      -- contract_template_id

  p_request_id := l_request_id;

exception 
  when others then 
    p_msg := l_proc || ' ctx:' || l_ctx || 
             ' SQLCODE=' || SQLCODE || ' SQLERRM=' || SQLERRM; 
end create_acct_setup_request_rec;
-- ============================================================================


-------------------------------------------------------------------------------
procedure raise_business_event (p_ready_to_transmit_count out number,
                                p_msg                     out varchar2) is
-------------------------------------------------------------------------------

  l_proc varchar2(80)   := 'raise_business_event';
  l_ctx  varchar2(2000) := null; 

  l_count  number;

begin
  --
  -- This code copied from XX_ASN_ACCTBUSEVT_PKG.
  --

  l_ctx := 'select count from xx_cdh_account_setup_req';
  select count(request_id)
    into l_count
    from apps.xx_cdh_account_setup_req
   where status in (select flv.meaning
                      from fnd_lookup_values flv
                     where flv.lookup_type = 'XX_CDH_BPELPROCESS_REQ_STATUS'
                       and flv.enabled_flag = 'Y'
                       and trunc(sysdate) between trunc(nvl(flv.start_date_active,sysdate))
                                              and trunc(nvl(flv.end_date_active,sysdate)));

  if (l_count > 0) then
    WF_EVENT.RAISE(p_event_name  => 'od.oracle.apps.ar.hz.AccountCreationRequestBatch.create'
                  ,p_event_key   => null
                  ,p_parameters  => null);
  end if;

  p_ready_to_transmit_count := l_count;

exception 
  when others then 
    p_msg := l_proc || ' ctx:' || l_ctx || 
             ' SQLCODE=' || SQLCODE || ' SQLERRM=' || SQLERRM; 
end raise_business_event;
-- ============================================================================

end xx_crm_phil_prospect;
/

show errors

prompt Grant access to APPS_RO...
grant execute on apps.XX_CRM_PHIL_PROSPECT to apps_ro;

--prompt Drop package with old name...
--drop package apps.xxcrm_phil_prospect;

