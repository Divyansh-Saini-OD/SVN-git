create or replace
package body XX_CDH_SETUP_VERIFICATION
as
function GET_PROFILE_OPTION_VALUE (
                                   p_item_level        varchar2,
                                   p_item_level_value  varchar2,
                                   p_profile_name      varchar2
                                  )
return varchar2;

function GET_COLOR( 
                    p_required_value varchar2,
                    p_actual_value   varchar2
                  )
return varchar2;

function COMPARE ( 
                    p_required_value varchar2,
                    p_actual_value   varchar2
                  )
return varchar2;

procedure check_lookups;
procedure check_Value_Sets;
procedure check_flex_fields;
procedure check_DQM_Setups;
procedure check_extensibles;

  procedure main(
                  x_err_buf  OUT NOCOPY varchar2,
                  x_err_code OUT NOCOPY varchar2
                )
  as
  l_instance_name varchar2(100);
  l_program_run_time varchar2(50);
  begin
    select instance_name, 
           to_char(sysdate,'DD-MON-YYYY HH:MI:SS')
    into   l_instance_name,
           l_program_run_time
      from v$instance;
    fnd_file.put_line (fnd_file.output, '<html><title>CDH Setup Verification</title><body><font size="-1" face="Verdana, Arial, Helvetica"><h1>CDH Automated Setup Verification</h1><h2>');
    fnd_file.put_line (fnd_file.output, l_instance_name || '</h2><h3>');
    fnd_file.put_line (fnd_file.output, l_program_run_time || '</h3>');
    check_profiles ( x_err_buf , x_err_code );
    check_lookups ();
    check_Value_Sets ();
    check_flex_fields ();
    check_DQM_Setups();
    check_extensibles();
    fnd_file.put_line (fnd_file.output,'</font></body></html>');

  exception
    when others then
    fnd_file.put_line (fnd_file.log, 'Exception in main' || SQLERRM);
  end main;

  procedure check_profiles(
                  x_err_buf  OUT NOCOPY varchar2,
                  x_err_code OUT NOCOPY varchar2
                )
  as
    match boolean:= true;
    l_value varchar2(200) := null;
    l_color varchar2(15) := 'green';
    l_actual_value varchar2(1000);

    cursor c_items
    is
    select *
    from   xxcrm.xxod_cdh_setup_items;
    
  begin
    fnd_file.put_line (fnd_file.output,'<table border=1> <tr><td><a href="#Profile_Options"><b>Profile Options</b></a></td><td><a href="#Lookups"><b>Lookups</b></a></td><td><a href="#Value_Sets"><b>Value Sets</b></a></td><td><a href="#Flex_Fields"><b>Descriptive Flex Fields</b></a></td><td><a href="#DQM_Setups"><b>DQM Setups</b></a></td><td><a href="#Extensible_Attributes"><b>Extensible Attributes</b></a></td></tr>');
    fnd_file.put_line (fnd_file.output,'</table>');
  
    fnd_file.put_line (fnd_file.output,'<table border=1>');
    fnd_file.put_line (fnd_file.output,'<tr><td colspan=6  bgcolor=gray><b><a name="Profile_Options">Profile Options</a></b></td></tr>');
    fnd_file.put_line (fnd_file.output,'<tr><td bgcolor=YELLOW><b>Profile Name</b></td><td bgcolor=YELLOW><b>Level Scope</b></td><td bgcolor=YELLOW><b>level Value</b></td><td bgcolor=YELLOW><b>Required Value</b></td><td bgcolor=YELLOW><b>Actual Value</b></td><td bgcolor=YELLOW><b>Y/N</b></td></tr>');
   for i in c_items
   loop
     l_actual_value := GET_PROFILE_OPTION_VALUE (i.item_level, i.item_level_value, i.item_name);
     fnd_file.put_line (fnd_file.output,'<tr><td><font size="1">' || i.item_name || 
           '</font></td><td><font size="1">' || i.item_level_scope ||
           '</font></td><td><font size="1">' || i.item_level_value || '</font></td><td><font size="1">' || i.item_required_value ||
           '</font></td><td><font size="1">' || l_actual_value || '</font><font size="-1"></td><td bgcolor=' || GET_COLOR(i.item_required_value, l_actual_value ) || '><b>' || COMPARE(i.item_required_value, l_actual_value ) || '</b></td></tr>');
   end loop; 
    fnd_file.put_line (fnd_file.output,'</table>');
    
  exception
    when others then
    fnd_file.put_line (fnd_file.log, 'Exception in check_profiles' || SQLERRM);

  end check_profiles;
function GET_PROFILE_OPTION_VALUE (
                                   p_item_level        varchar2,
                                   p_item_level_value  varchar2,
                                   p_profile_name      varchar2
                                  )
return varchar2
is
  l_sql  varchar2(2000);
  l_value        varchar2(200) := ' ';

begin
  l_sql := null;
  --fnd_file.put_line (fnd_file.output,'p_item_level: ' || p_item_level);
  --fnd_file.put_line (fnd_file.output,'p_item_level_value: ' || p_item_level_value);
  --fnd_file.put_line (fnd_file.output,'p_profile_name: ' || p_profile_name);
  if ( p_item_level = 'Site') then

    l_sql := 'select v.profile_option_value from fnd_profile_option_values v,' || 
             'fnd_profile_options_vl p where ' ||
             'v.profile_option_id = p.profile_option_id and v.level_id = 10001 ' ||
             'and p.user_profile_option_name = :1';
    --fnd_file.put_line (fnd_file.output, 'l_sql: ' || l_sql);
    execute immediate l_sql into l_value using p_profile_name;
  elsif (p_item_level = 'Application') then

    l_sql := 'select v.profile_option_value from fnd_profile_option_values v,' || 
             'fnd_profile_options_vl p, fnd_application a where ' ||
             'v.profile_option_id = p.profile_option_id and (v.level_id = 10002 and a.application_id = v.level_value) ' ||
             'and v.level_value = :1' || 'and p.user_profile_option_name = :2';
    --fnd_file.put_line (fnd_file.output, 'l_sql: ' || l_sql);
    execute immediate l_sql into l_value using p_item_level_value, p_profile_name;
  elsif (p_item_level = 'Responsibility') then

    l_sql := 'select v.profile_option_value from fnd_profile_option_values v,' || 
             'fnd_profile_options_vl p, fnd_responsibility_vl r where ' ||
             'v.profile_option_id = p.profile_option_id and (v.level_id = 10003 and r.responsibility_id = v.level_value) ' ||
             'and v.level_value = :1' || 'and p.user_profile_option_name = :2';

    --fnd_file.put_line (fnd_file.output, 'l_sql: ' || l_sql);
    execute immediate l_sql into l_value using p_item_level_value, p_profile_name;

  elsif (p_item_level = 'User') then

    l_sql := 'select v.profile_option_value from fnd_profile_option_values v,' || 
             'fnd_profile_options_vl p, fnd_user u where ' ||
             'v.profile_option_id = p.profile_option_id and (v.level_id = 10004 and u.user_id = v.level_value) ' ||
             'and v.level_value = :1' || 'and p.user_profile_option_name = :2';
    --fnd_file.put_line (fnd_file.output, 'l_sql: ' || l_sql);
    execute immediate l_sql into l_value using p_item_level_value, p_profile_name;
  else

    l_sql := null;

  end if;
  if ( l_value is null) then
    l_value := ' ';
  end if;
  return l_value;

exception
  when others then   
    fnd_file.put_line (fnd_file.log,'Exception: ' || SQLERRM);
    fnd_file.put_line (fnd_file.log,'p_profile_name: ' || p_profile_name);
    fnd_file.put_line (fnd_file.log,'p_item_level_value: ' || p_item_level_value);
    fnd_file.put_line (fnd_file.log,'p_item_level: ' || p_item_level);
    fnd_file.put_line (fnd_file.log,'l_sql: ' || l_sql);
    return ' ';
end GET_PROFILE_OPTION_VALUE;
function GET_COLOR( 
                    p_required_value varchar2,
                    p_actual_value   varchar2
                  )
return varchar2
is
l_color varchar2(50);
begin
  if ( p_required_value = p_actual_value ) then
    l_color := 'GREEN';
  else
    l_color := 'RED';
  end if;
  return l_color;
end GET_COLOR;

function COMPARE ( 
                    p_required_value varchar2,
                    p_actual_value   varchar2
                  )
return varchar2
is
l_correct varchar2(50);
begin
  if ( p_required_value = p_actual_value ) then
    l_correct := 'Yes';
  else
    l_correct := 'No';
  end if;

  return l_correct;
end COMPARE;

procedure check_lookups
is
Cursor c_lookups
is
select lookup_type,
       lookup_code,
       meaning,
       description,
       enabled_flag,
       start_date_active,
       end_date_active
from ar_lookups
where lookup_type in (
'CUSTOMER_CATEGORY',
'ACCT_ROLE_TYPE',
'RESPONSIBILITY',
'HZ_URL_TYPES',
'PHONE_LINE_TYPE',
'CONTACT_TITLE',
'CONTACT_POINT_PURPOSE_WEB',
'CONTACT_POINT_PURPOSE',
'CONTACT_ROLE_TYPE',
'PARTY_SITE_USE_CODE',
'SALES_CHANNEL',
'SITE_USE_CODE',
'DEPARTMENT_TYPE',
'SFA_CUSTOMER_CATEGORY'
)
order by lookup_type,
         lookup_code;

begin
  fnd_file.put_line (fnd_file.output,'<table border=1> <tr><td><a href="#Profile_Options"><b>Profile Options</b></a></td><td><a href="#Lookups"><b>Lookups</b></a></td><td><a href="#Value_Sets"><b>Value Sets</b></a></td><td><a href="#Flex_Fields"><b>Descriptive Flex Fields</b></a></td><td><a href="#DQM_Setups"><b>DQM Setups</b></a></td><td><a href="#Extensible_Attributes"><b>Extensible Attributes</b></a></td></tr>');
  fnd_file.put_line (fnd_file.output,'</table>');
  fnd_file.put_line (fnd_file.output,'<table border=1>');
  fnd_file.put_line (fnd_file.output,'<tr><td colspan=6  bgcolor=gray><b><a name="Lookups">Lookups</a></b></td></tr>');
  fnd_file.put_line (fnd_file.output,'<tr><td bgcolor=YELLOW><b>Lookup Type</b></td><td bgcolor=YELLOW><b>Code</b></td><td bgcolor=YELLOW><b>Meaning</b></td><td bgcolor=YELLOW><b>Enabled Flag</b></td><td bgcolor=YELLOW><b>Start Date Active</b></td><td bgcolor=YELLOW><b>End Date Active</b></td></tr>');

  for i in c_lookups
    loop
    
      fnd_file.put_line (fnd_file.output,'<tr>' ||
                                             '<td>' || i.lookup_type        || '</td>' || 
                                             '<td>' || i.lookup_code        || '</td>' ||  
					     '<td>' || i.meaning            || '</td>' || 
					     '<td>' || i.enabled_flag       || '</td>' ||  
                                             '<td>' || i.start_date_active  || '</td>' ||  
					     '<td>' || i.end_date_active    || '</td>' ||  
					 '</tr>');
    end loop;
  fnd_file.put_line (fnd_file.output,'</table>');    
exception
  when others then
    fnd_file.put_line (fnd_file.log, 'Exception in check_lookups: ' || SQLERRM);
end check_lookups;

procedure check_Value_Sets 
is
cursor c_value_sets
is
select vs.flex_value_set_name,
       vv.flex_value,
       vv.flex_value_meaning,
       vv.description
from apps.fnd_flex_value_sets vs,
     apps.fnd_flex_values_vl vv
where vs.flex_value_set_id = vv.flex_value_set_id and
vs.flex_value_set_name in (
'XXOD_CUST_ACCTNG_FIELDS',
'XXOD_CUST_ACCTNG_FIELDS2',
'XXOD_CUST_AR_DOC_DELIVERY_BY',
'XXOD_CUST_BILLING_FREQ',
'XXOD_CUST_BILLING_LEVEL',
'XXOD_CUST_CA_ADDRESS_PROVINCE',
'XXOD_CUST_CA_MINORITY_OWNED_CLASSFN',
'XXOD_CUST_CA_REVENUE_BAND',
'XXOD_CUST_CONTACT_FREQUENCY',
'XXOD_CUST_CONSBILLING_ATTACH',
'XXOD_CUST_CUSTOMER_TYPE',
'XXOD_CUST_EUR_MINORITY_OWNED_CLASSFN',
'XXOD_CUST_EUR_REVENUE_BAND',
'XXOD_CUST_GB_MINORITY_OWNED_CLASSFN',
'XXOD_CUST_GB_REVENUE_BAND',
'XXOD_CUST_GEO_REACH',
'XXOD_CUST_IE_MINORITY_OWNED_CLASSFN',
'XXOD_CUST_IE_REVENUE_BAND',
'XXOD_CUST_IL_MINORITY_OWNED_CLASSFN',
'XXOD_CUST_IL_REVENUE_BAND',
'XXOD_CUST_INACTIVATE_REASON',
'XXOD_CUST_INCUMBENT_NAME',
'XXOD_CUST_INCUMBENT_PROD',
'XXOD_CUST_INV_DET_LEVEL',
'XXOD_CUST_INV_FILE_FORMATS',
'XXOD_CUST_INV_SORT_ORDER',
'XXOD_CUST_INV_SPECIAL_HANDLING',
'XXOD_CUST_INV_SUBTOT_LEVEL',
'XXOD_CUST_JP_MINORITY_OWNED_CLASSFN',
'XXOD_CUST_JP_REVENUE_BAND',
'XXOD_CUST_LOC_CATEGORY',
'XXOD_CUST_LOYALTY_LEVEL',
'XXOD_CUST_LOYALTY_PROGRAM',
'XXOD_CUST_LOYALTY_REG_SOURCE',
'XXOD_CUST_LOYALTY_VALUE_SYSTEM',
'XXOD_CUST_MARKET_SEGMENT',
'XXOD_CUST_NL_ADDRESS_PROVINCE',
'XXOD_CUST_NL_MINORITY_OWNED_CLASSFN',
'XXOD_CUST_NL_REVENUE_BAND',
'XXOD_CUST_NOTIFY_TYPE',
'XXOD_CUST_PRIORITY_LEVEL',
'XXOD_CUST_ROYALTY_FEES',
'XXOD_CUST_SIG_REQUIRED',
'XXOD_CUST_SRC_CREATION',
'XXOD_CUST_SPLIT_ORDERS_BY',
'XXOD_CUST_TAX_ENTITY_CODE',
'XXOD_CUST_US_MINORITY_OWNED_CLASSFN',
'XXOD_CUST_US_REVENUE_BAND',
'XXOD_CUST_YES_NO',
'XXOD_CUST_SFA_SITE_CATEGORY',
'XXOD_CDH_BILLDOCS_COMBO_TYPE',
'XXOD_CDH_BILLDOCS_DELIVERY_METHOD',
'XXOD_CDH_BILLDOCS_DOCUMENT_ID',
'XXOD_CDH_BILLDOCS_DOC_TYPE',
'XXOD_CUST_USGDOCS_DOC_TYPE',
'XXOD_CDH_SPC_CREDIT_CODE',
'XXOD_CDH_SPC_TENDER_CODE',
'XX_ASN_CUSTOMER_PROSPECT'
) and enabled_flag='Y' 
and end_date_active is null
order by vs.flex_value_set_id,
         vv.flex_value;
begin
  fnd_file.put_line (fnd_file.output,'<table border=1> <tr><td><a href="#Profile_Options"><b>Profile Options</b></a></td><td><a href="#Lookups"><b>Lookups</b></a></td><td><a href="#Value_Sets"><b>Value Sets</b></a></td><td><a href="#Flex_Fields"><b>Descriptive Flex Fields</b></a></td><td><a href="#DQM_Setups"><b>DQM Setups</b></a></td><td><a href="#Extensible_Attributes"><b>Extensible Attributes</b></a></td></tr>');
  fnd_file.put_line (fnd_file.output,'</table>');
  fnd_file.put_line (fnd_file.output,'<table border=1>');  
  fnd_file.put_line (fnd_file.output,'<tr><td colspan=4  bgcolor=gray><b><a name="Value_Sets">Value Sets</a></b></td></tr>');
  fnd_file.put_line (fnd_file.output,'<tr><td bgcolor=YELLOW><b>Value Set Name</b></td><td bgcolor=YELLOW><b>Value</b></td><td bgcolor=YELLOW><b>Meaning</b></td><td bgcolor=YELLOW><b>Description</b></td></tr>');

  for i in c_value_sets
    loop
      fnd_file.put_line (fnd_file.output,'<tr>' ||
                                             '<td><font size="1">' || i.flex_value_set_name   || '</font><font size="-1"></td>' || 
					     '<td>' || i.flex_value            || '</td>' ||  
                                             '<td>' || i.flex_value_meaning    || '</td>' ||  
					     '<td><font size="1">' || i.description           || '</font></td>' ||  
					 '</tr>');

    end loop;
  fnd_file.put_line (fnd_file.output,'</table>');    
exception
  when others then
    fnd_file.put_line (fnd_file.log, 'Exception in check_Value_Sets: ' || SQLERRM);
end check_Value_Sets;

procedure check_flex_fields
is
  cursor c_flex
  is
  select fv.title,
       fv.freeze_flex_definition_flag,
       fcv.end_user_column_name,
       fcv.application_column_name,
       fcv.required_flag,
       (select flex_value_set_name from fnd_flex_value_sets where flex_value_set_id=fcv.flex_value_set_id) value_set_name,
       fv.protected_flag,       
       fcv.enabled_flag,
       fv.context_synchronization_flag,
       fv.default_context_field_name       
  from FND_DESCRIPTIVE_FLEXS_VL fv,
       FND_DESCR_FLEX_COL_USAGE_VL fcv
  where fv.descriptive_flexfield_name=fcv.descriptive_flexfield_name and
        fv.application_id=222 and 
      (fv.application_table_name like 'HZ%' or 
       fv.application_table_name like 'RA%' or 
       fv.application_table_name like 'XX_CDH%') and 
        fv.title like '%Information'
        order by fv.title, fcv.end_user_column_name;
begin

  fnd_file.put_line (fnd_file.output,'<table border=1> <tr><td><a href="#Profile_Options"><b>Profile Options</b></a></td><td><a href="#Lookups"><b>Lookups</b></a></td><td><a href="#Value_Sets"><b>Value Sets</b></a></td><td><a href="#Flex_Fields"><b>Descriptive Flex Fields</b></a></td><td><a href="#DQM_Setups"><b>DQM Setups</b></a></td><td><a href="#Extensible_Attributes"><b>Extensible Attributes</b></a></td></tr>');
  fnd_file.put_line (fnd_file.output,'</table>');
  fnd_file.put_line (fnd_file.output,'<table border=1>');
  fnd_file.put_line (fnd_file.output,'<tr><td colspan=6  bgcolor=gray><b><a name="Flex_Fields">Descriptive Flex Fields</a></b></td></tr>');
  fnd_file.put_line (fnd_file.output,'<tr><td bgcolor=YELLOW><b>TITLE</b></td><td bgcolor=YELLOW><b>FROZEN?</b></td><td bgcolor=YELLOW><b>COLUMN NAME</b></td><td bgcolor=YELLOW><b>DB COLUMN NAME</b></td><td bgcolor=YELLOW><b>VALUE SET</b></td><td bgcolor=YELLOW><b>REQUIRED?</b></td></tr>');

  for i in c_flex
    loop
      fnd_file.put_line (fnd_file.output,'<tr>' ||
                                             '<td><font size="1">' || i.title               || '</font></td>' || 
					     '<td>' || i.freeze_flex_definition_flag       || '</td>' || 
					     '<td><font size="1">' || i.end_user_column_name || '</font></td>' ||  
					     '<td><font size="1">' || i.application_column_name || '</font></td>' ||  
                                             '<td><font size="1">' || i.value_set_name     || '</font><font size="-1"></td>' ||  
					     '<td>' || i.required_flag                     || '</td>' ||  
					 '</tr>');
    end loop;

  fnd_file.put_line (fnd_file.output,'</table>');

exception
  when others then
    fnd_file.put_line (fnd_file.log, 'Exception in check_flex_fields: ' || SQLERRM);

end check_flex_fields;

procedure check_DQM_Setups
is

cursor c_match_rules
is
SELECT rule_name,
  description,
  rule_purpose,
  match_all_flag,
  match_score,
  no_override_score,
  auto_merge_score,
  active_flag,
  compilation_flag
FROM apps.hz_match_rules_vl
WHERE nvl(match_rule_type,   'SINGLE') = 'SINGLE'
 AND(rule_name LIKE 'XXOD%')
 order by rule_name;

 cursor c_attribs_trans
 is
 select tab.attribute_name,
       tat.user_defined_attribute_name,
       tab.entity_name,
       tab.custom_attribute_procedure,
       tab.denorm_flag,
       tfv.transformation_name,
       tfv.procedure_name,
       tfv.description,
       tfv.active_flag,
       tfv.primary_flag,
       tfv.index_required_flag,
       tfv.staged_attribute_column
from apps.HZ_TRANS_FUNCTIONS_VL tfv,
     apps.HZ_TRANS_ATTRIBUTES_B tab,
     apps.HZ_TRANS_ATTRIBUTES_TL tat
where tfv.attribute_id = tab.attribute_id and
      tat.attribute_id = tab.attribute_id and
      tat.language = 'US'
      order by entity_name;

cursor c_match_rule_primary
is
select r.rule_name,
       ps.user_defined_attribute_name,
       ps.entity_name,
       tfv.transformation_name,       
       ps.display_order,
       tfv.procedure_name,
       tfv.description,
       tfv.staged_attribute_column,
       tfv.staged_flag,
       tfv.index_required_flag
from apps.hz_match_rules_vl r,
     apps.hz_attrib_primary_sec_v ps,
     apps.hz_primary_trans pt,
     apps.HZ_TRANS_FUNCTIONS_VL tfv
where r.match_rule_id = ps.match_rule_id and 
     r.rule_name like 'XXOD%' and
     ps.primary_attribute_id = pt.primary_attribute_id and
     pt.function_id = tfv.function_id and
     ps.primary_attribute_id <> -9999  
     order by r.rule_name, ps.display_order;

cursor c_match_rule_secondary
is

select r.rule_name,
       ps.user_defined_attribute_name,
       ps.entity_name,
       tfv.transformation_name,
       st.transformation_weight,
       st.similarity_cutoff,
       tfv.procedure_name,
       tfv.description,
       tfv.staged_attribute_column,
       tfv.staged_flag,
       tfv.index_required_flag,       
       ps.display_order
from apps.hz_match_rules_vl r,
     apps.hz_attrib_primary_sec_v ps,
     apps.hz_secondary_trans st,
     apps.HZ_TRANS_FUNCTIONS_VL tfv
where r.match_rule_id = ps.match_rule_id and 
     r.rule_name like 'XXOD%' and
     ps.secondary_attribute_id = st.secondary_attribute_id and
     st.function_id = tfv.function_id and
     ps.secondary_attribute_id <> -9999  
     order by r.rule_name, ps.display_order;

begin
  --Render Match Rule Details
  fnd_file.put_line (fnd_file.output,'<table border=1> <tr><td><a href="#Profile_Options"><b>Profile Options</b></a></td><td><a href="#Lookups"><b>Lookups</b></a></td><td><a href="#Value_Sets"><b>Value Sets</b></a></td><td><a href="#Flex_Fields"><b>Descriptive Flex Fields</b></a></td><td><a href="#DQM_Setups"><b>DQM Setups</b></a></td><td><a href="#Extensible_Attributes"><b>Extensible Attributes</b></a></td></tr>');
  fnd_file.put_line (fnd_file.output,'</table>');
  fnd_file.put_line (fnd_file.output,'<table border=1>');
  fnd_file.put_line (fnd_file.output,'<tr><td colspan=5  bgcolor=gray><b><a name="DQM_Setups">DQM Setups - Match Rule Information</a></b></td></tr>');
  fnd_file.put_line (fnd_file.output,'<tr><td bgcolor=YELLOW><b>RULE NAME</b></td><td bgcolor=YELLOW><b>DESCRIPTION</b></td><td bgcolor=YELLOW><b>MATCH ALL FLAG</b></td><td bgcolor=YELLOW><b>MATCH SCORE</b></td><td bgcolor=YELLOW><b>COMPILATION FLAG</b></td></tr>');

  for i in c_match_rules
    loop
      fnd_file.put_line (fnd_file.output,'<tr>' ||
                                             '<td>' || i.RULE_NAME         || '</td>' || 
					     '<td>' || i.DESCRIPTION       || '</td>' || 
					     '<td>' || i.MATCH_ALL_FLAG    || '</td>' ||  
                                             '<td>' || i.MATCH_SCORE       || '</td>' ||  
					     '<td>' || i.COMPILATION_FLAG  || '</td>' ||  
					 '</tr>');
    end loop;

  fnd_file.put_line (fnd_file.output,'</table>');

  --Render All Attributes and Transformations
  fnd_file.put_line (fnd_file.output,'<table border=1>');

  fnd_file.put_line (fnd_file.output,'<tr><td colspan=5  bgcolor=gray><b>DQM Setups - Attributes and Transformations</b></td></tr>');
  fnd_file.put_line (fnd_file.output,'<tr><td bgcolor=YELLOW><b>USER DEFINED ATTRIBUTE NAME</b></td><td bgcolor=YELLOW><b>ENTITY NAME</b></td><td bgcolor=YELLOW><b>CUSTOM ATTRIBUTE PROCEDURE</b></td><td bgcolor=YELLOW><b>DENORM</b></td><td bgcolor=YELLOW><b>TRANSFORMATION NAME</b></td></tr>');

    for j in c_attribs_trans
    loop
      fnd_file.put_line (fnd_file.output,'<tr>' ||
                                             '<td>' || j.USER_DEFINED_ATTRIBUTE_NAME || '</td>' ||  
                                             '<td>' || j.ENTITY_NAME                 || '</td>' ||  
					     '<td><font size="1">' || j.CUSTOM_ATTRIBUTE_PROCEDURE  || '</font><font size="-1"></td>' ||  
                                             '<td>' || j.DENORM_FLAG                 || '</td>' || 
					     '<td>' || j.TRANSFORMATION_NAME         || '</td>' ||
					 '</tr>');
    end loop;

  fnd_file.put_line (fnd_file.output,'</table>');

  --Render Primary Attributes

  fnd_file.put_line (fnd_file.output,'<table border=1>');

  fnd_file.put_line (fnd_file.output,'<tr><td colspan=6  bgcolor=gray><b>DQM Setups - Acquision Attributes and Transformations</b></td></tr>');
  fnd_file.put_line (fnd_file.output,'<tr><td bgcolor=YELLOW><b>RULE NAME</b></td><td bgcolor=YELLOW><b>USER DEFINED ATTRIBUTE NAME</b></td><td bgcolor=YELLOW><b>ENTITY NAME</b></td><td bgcolor=YELLOW><b>TRANSFORMATION NAME</b></td><td bgcolor=YELLOW><b>DISPLAY ORDER</b></td><td bgcolor=YELLOW><b>STAGED_FLAG</b></td></tr>');
    for k in c_match_rule_primary
    loop
      fnd_file.put_line (fnd_file.output,'<tr>' ||
                                             '<td><font size="1">' || k.RULE_NAME    || '</font><font size="-1"></td>' || 
					     '<td>' || k.USER_DEFINED_ATTRIBUTE_NAME || '</td>' ||  
                                             '<td>' || k.ENTITY_NAME                 || '</td>' ||  
					     '<td>' || k.TRANSFORMATION_NAME         || '</td>' ||  
                                             '<td>' || k.DISPLAY_ORDER               || '</td>' || 
					     '<td>' || k.STAGED_FLAG                 || '</td>' ||  
					 '</tr>');
    end loop;
  fnd_file.put_line (fnd_file.output,'</table>');
  
  --Render Secondary or scoring attributes
  fnd_file.put_line (fnd_file.output,'<table border=1>');
  fnd_file.put_line (fnd_file.output,'<tr><td colspan=7  bgcolor=gray><b>DQM Setups - Scoring Attributes and Transformations</b></td></tr>');
  fnd_file.put_line (fnd_file.output,'<tr><td bgcolor=YELLOW><b>RULE NAME</b></td><td bgcolor=YELLOW><b>USER DEFINED ATTRIBUTE NAME</b></td><td bgcolor=YELLOW><b>ENTITY NAME</b></td><td bgcolor=YELLOW><b>TRANSF. NAME</b></td><td bgcolor=YELLOW><b>TRANSF. WEIGHT</b></td><td bgcolor=YELLOW><b>STAGED FLAG</b></td><td bgcolor=YELLOW><b>DISPLAY ORDER</b></td></tr>');
    for l in c_match_rule_secondary
    loop
      fnd_file.put_line (fnd_file.output,'<tr>' ||
                                             '<td><font size="1">' || l.RULE_NAME    || '</font><font size="-1"></td>' || 
					     '<td>' || l.USER_DEFINED_ATTRIBUTE_NAME || '</td>' ||  
                                             '<td>' || l.ENTITY_NAME                 || '</td>' ||  
					     '<td>' || l.TRANSFORMATION_NAME         || '</td>' ||  
					     '<td>' || l.TRANSFORMATION_WEIGHT       || '</td>' ||
					     '<td>' || l.STAGED_FLAG                 || '</td>' ||  
					     '<td>' || l.DISPLAY_ORDER               || '</td>' ||  
					 '</tr>');
    end loop;
  fnd_file.put_line (fnd_file.output,'</table>');    
exception
  when others then
    fnd_file.put_line (fnd_file.log, 'Exception in check_DQM_Setups: ' || SQLERRM);

end check_DQM_Setups;

procedure check_extensibles
is
  cursor c_ext_groups
  is
  select attr_group_type,
         attr_group_name,
         attr_group_disp_name,
         description,
         multi_row_code,
         agv_name,
         business_event_flag,
         pre_business_event_flag
  from   EGO_ATTR_GROUPS_V       
  where application_id=222
  order by attr_group_type;
  cursor c_ext_items
  is
  select attr_group_type, 
         attr_group_name, 
         attr_name,
         attr_display_name,
         display_meaning,
         database_column,
         value_set_name,
         enabled_flag,
         required_flag
  from EGO_ATTRS_V 
  where application_id=222
  order by attr_group_type, 
         attr_group_name, 
         attr_name;
  begin
    fnd_file.put_line (fnd_file.output,'<table border=1> <tr><td><a href="#Profile_Options"><b>Profile Options</b></a></td><td><a href="#Lookups"><b>Lookups</b></a></td><td><a href="#Value_Sets"><b>Value Sets</b></a></td><td><a href="#Flex_Fields"><b>Descriptive Flex Fields</b></a></td><td><a href="#DQM_Setups"><b>DQM Setups</b></a></td><td><a href="#Extensible_Attributes"><b>Extensible Attributes</b></a></td></tr>');
    fnd_file.put_line (fnd_file.output,'</table>');
    fnd_file.put_line (fnd_file.output,'<table border=1>');  
    fnd_file.put_line (fnd_file.output,'<tr><td colspan=5  bgcolor=gray><b><a name="Extensible_Attributes">Extensible_Attributes - Attribute Groups</a></b></td></tr>');
    fnd_file.put_line (fnd_file.output,'<tr><td bgcolor=YELLOW><b>ATTR GROUP TYPE</b></td><td bgcolor=YELLOW><b>ATTR GROUP NAME</b></td><td bgcolor=YELLOW><b>MULTI ROW CODE</b></td><td bgcolor=YELLOW><b>VIEW NAME</b></td><td bgcolor=YELLOW><b>BUSINESS EVENT FLAG</b></td></tr>');

    for i in c_ext_groups
    loop
      fnd_file.put_line (fnd_file.output,'<tr>' ||
                                             '<td>' || i.attr_group_type             || '</td>' || 
					     '<td>' || i.attr_group_name             || '</td>' ||  
                                             '<td>' || i.multi_row_code              || '</td>' ||  
					     '<td>' || i.agv_name                    || '</td>' ||  
					     '<td>' || i.business_event_flag         || '</td>' ||  
					 '</tr>');
    end loop;  
    fnd_file.put_line (fnd_file.output,'</table>');    
    fnd_file.put_line (fnd_file.output,'<table border=1>');  

    fnd_file.put_line (fnd_file.output,'<tr><td colspan=7  bgcolor=gray><b>Extensible Attributes Setups - Attribute Group Attributes</b></td></tr>');
    fnd_file.put_line (fnd_file.output,'<tr><td bgcolor=YELLOW><font size="1"><b>ATTR GROUP TYPE</b></font></td><td bgcolor=YELLOW><font size="1"><b>ATTR GROUP NAME</b></font></td><td bgcolor=YELLOW><font size="1"><b>ATTRIBUTE NAME</b></font></td><td bgcolor=YELLOW><font size="1"><b>DATABASE COLUMN</b></font></td><td bgcolor=YELLOW><font size="1"><b>VALUESET NAME</b></font></td><td bgcolor=YELLOW><font size="1"><b>ENABLED FLAG</b></font></td><td bgcolor=YELLOW><font size="1"><b>REQUIRED FLAG</b></font></td></tr>');

    for j in c_ext_items
    loop
      fnd_file.put_line (fnd_file.output,'<tr>' ||
                                             '<td><font size="1">' || j.attr_group_type             || '</font></td>' || 
					     '<td><font size="1">' || j.attr_group_name             || '</font></td>' ||  
					     '<td><font size="1">' || j.attr_name                   || '</font></td>' ||                                              
                                             '<td><font size="1">' || j.database_column             || '</font></td>' ||  
					     '<td><font size="1">' || j.value_set_name              || '</font><font size="-1"></td>' ||  
					     '<td>' || j.enabled_flag                || '</td>' || 
					     '<td>' || j.required_flag               || '</td>' ||                                               
					 '</tr>');
    end loop;  
    fnd_file.put_line (fnd_file.output,'</table>');    
    fnd_file.put_line (fnd_file.output,'<table border=1> <tr><td><a href="#Profile_Options"><b>Profile Options</b></a></td><td><a href="#Lookups"><b>Lookups</b></a></td><td><a href="#Value_Sets"><b>Value Sets</b></a></td><td><a href="#Flex_Fields"><b>Descriptive Flex Fields</b></a></td><td><a href="#DQM_Setups"><b>DQM Setups</b></a></td><td><a href="#Extensible_Attributes"><b>Extensible Attributes</b></a></td></tr>');
    fnd_file.put_line (fnd_file.output,'</table>');
    
  exception
    when others then
      fnd_file.put_line (fnd_file.log, 'Exception in check_extensibles: ' || SQLERRM);    
end check_extensibles;
end XX_CDH_SETUP_VERIFICATION;
/
