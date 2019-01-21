CREATE OR REPLACE PACKAGE BODY XX_TM_ASSIGN_RESOURCE_TO_TERR AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name        :  XX_TM_ASSIGN_RESOURCE_TO_TERR.pkb                         |
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
-- | This stored procedure assigns sales reps to territories.                 |
-- |                                                                          |
-- | A resource is assigned to each child territory that doesn't already have |
-- | one assigned.  Use the following rules:                                  |
-- |                                                                          |
-- | - Look for child territories only in the territory hierarchy within the  |
-- |   region specified at run time.                                          |
-- |                                                                          |
-- | - Skip all child territories that already have a resource.               |
-- |                                                                          |
-- | - The child territory name is the sales rep id.  Use it to find the      |
-- |   resource_id to assign to the territory.                                |
-- |                                                                          |
-- | - The resource assignment performs the same operation as selecting the   |
-- |   Resource tab in the Territory Details Ebiz screen for a territory,     |
-- |   and then entering a resource name.                                     |
-- |                                                                          |
-- | Parameters :                                                             |
-- |                                                                          |
-- | p_region_name                                                            |
-- |     No default.                                                          |
-- |     Specify a valid value from the value set XX_TM_REGION_TAG.           |
-- |     Examples: OD_NORTH_AMERICA, OD_EUROPE.                               |
-- |     The TAG column for the associated lookup value must be valid.        |
-- |                                                                          |
-- | p_verbose_mode                                                           |
-- |     Default = N                                                          |
-- |     Y = Output info for all child territories, even if no assignment     |
-- |         was created.                                                     |
-- |     N = Output info only when an assignment was created.                 |
-- |                                                                          |
-- | p_simulate_mode                                                          |
-- |     Default = N                                                          |
-- |     Y = Program runs normally and displays usual output but no changes   |
-- |         are made.                                                        |
-- |     N = Program runs normally.  Assignments are created.                 |
-- |                                                                          |
-- | p_commit_flag                                                            |
-- |     Default = Y                                                          |
-- |     Y = program performs a commit or rollback when finished.             |
-- |     N = program does not perform any commits or rollbacks.               |
-- |                                                                          |
-- | p_debug_level                                                            |
-- |     Default = 0                                                          |
-- |     Allowed values are 0, 1, 2, 3.                                       |
-- |       0 = Debug off                                                      |
-- |       1 = Minimal debug messages generated                               |
-- |       2 = Medium amount of debug messages generated                      |
-- |       3 = High amount of debug messages generated                        |
-- |           - May impact performance and generate a large amount of output.|
-- |                                                                          |
-- | p_sql_trace                                                              |
-- |     Default = N                                                          |
-- |     Y = enable SQL trace. (may impact performace)                        |
-- |     N = do not enable SQL trace.                                         |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date        Author              Remarks                         |
-- |========  =========== ==================  ================================|
-- |1.0       14-APR-2009  Phil Price         Initial version                 |
-- |1.1       29-SEP-2009  Phil Price         Add role and group to territory |
-- |                                          assignments.                    |
-- |                                          Delete territory assignment if  |
-- |                                          matching xref entry not found   |
-- |                                          or xref doesnt point to active  |
-- |                                          resource + role + group.        |
-- +==========================================================================+


G_PACKAGE CONSTANT VARCHAR2(30) := 'XX_TM_ASSIGN_RESOURCE_TO_TERR';

--
-- Subversion keywords
--
GC_SVN_HEAD_URL constant varchar2(500) := '$HeadURL$';
GC_SVN_REVISION constant varchar2(100) := '$Rev$';
GC_SVN_DATE     constant varchar2(100) := '$Date$';

--
-- Debug levels
--
DBG_OFF   constant number := 0;
DBG_LOW   constant number := 1;
DBG_MED   constant number := 2;
DBG_HI    constant number := 3;

--
--  Status after checking if a resource is assigned to a territory
--
RSC_STS_ERROR             constant number := 1;
RSC_STS_NOT_ASSIGNED      constant number := 2;
RSC_STS_ONE_ASSIGNED      constant number := 3;
RSC_STS_MULTIPLE_ASSIGNED constant number := 4;

--
-- Status after looking for resource in xref, jtf_rs_% and related tables.
--
XREF_STS_ERROR              constant number := 1;
XREF_STS_NOT_IN_XREF_TBL    constant number := 2;
XREF_STS_NO_RSC_REQUESTED   constant number := 3;
XREF_STS_RSC_NOT_FOUND      constant number := 4;
XREF_STS_ROLE_IS_NOT_MEMBER constant number := 5;
XREF_STS_RSC_INACTIVE       constant number := 6;
XREF_STS_RSC_TOO_MANY_RRG   constant number := 7;
XREF_STS_RSC_FOUND          constant number := 8;
XREF_STS_IN_PROGRESS        constant number := 9;


ACTION_MSG_INFO  constant varchar2(1) := 'I';
ACTION_MSG_WARN  constant varchar2(1) := 'W';
ACTION_MSG_ERROR constant varchar2(1) := 'E';

ASG_SKIPPED_CT            constant number := 1;
ASG_CREATED_CT            constant number := 2;  -- Resource was assigned to a territory with no prior assignment
ASG_CHANGED_CT            constant number := 3;  -- Resource assiged to territory was changed
ASG_DELETED_CT            constant number := 4;  -- Resource assignment was removed from territory
ASG_DELETED_ERR_CT        constant number := 5;  -- Resource assignment was removed from territory because an error occurred
ASG_NOT_IN_XREF_CT        constant number := 6;  -- Territory could not be processed because territory not found in xref table
ASG_RSC_NOT_FOUND_CT      constant number := 7;  -- Resource from xref table could not be found
ASG_ROLE_IS_NOT_MEMBER_CT constant number := 8;  -- Resource + role + group found, but Member flag is not set for this role
ASG_RSC_TOO_MANY_CT       constant number := 9;  -- Resource from xref table points to multiple active rsc, rol, group records
ASG_RSC_INACTIVE_CT       constant number := 10; -- Resource from xref table points to an inactive rsc, role, group record
ASG_MULT_RSC_CT           constant number := 11; -- Territory could not be processed because multiple resources assigned
ASG_ERROR_CT              constant number := 12; -- Error getting resource info or assignming resource a to a territory
ASG_CT_MAX_INDX           constant number := 12;

--
-- Concurrent Manager completion statuses
--
CONC_STATUS_OK      constant number := '0';
CONC_STATUS_WARNING constant number := '1';
CONC_STATUS_ERROR   constant number := '2';

ANONYMOUS_APPS_USER    constant number := -1;

WHO_CONC_REQUEST_ID    constant number := 1;
WHO_PROG_APPL_ID       constant number := 2;
WHO_CONC_PROGRAM_ID    constant number := 3;
WHO_USER_ID            constant number := 4;
WHO_CONC_LOGIN_ID      constant number := 5;

TYPE WhoArray   IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
g_who_values    WhoArray;

SQ                     constant varchar2(1) := chr(39); -- single quote

TYPE num_arr_type  is table of number index by binary_integer;

g_conc_mgr_env     boolean;
g_commit           boolean;
g_warning_ct       number := 0;
g_debug_level      number := DBG_OFF;
g_simulate_mode    boolean := TRUE;

  cursor c_territories (c_region_code varchar) is
    select level,
           terr.terr_id,
           terr.name,
           terr.rank,
           terr.parent_territory_id,
           terr_p.name   parent_terr_name,
           terr.org_id,
           (select count(*)
              from apps.jtf_terr terr2
             where terr2.parent_territory_id = terr.terr_id) child_terr_ct,
           (select count(*)
              from jtf_terr_qualifiers_v  qual,
                   jtf_terr_values_desc_v val
             where qual.terr_qual_id  = val.terr_qual_id
               and val.terr_id         = qual.terr_id
               and qual.qualifier_name = 'Postal Code'
               and qual.terr_id        = terr.terr_id) postal_code_ct
      from apps.jtf_terr      terr,
           apps.jtf_terr      terr_p,
           apps.jtf_terr_usgs usg,
           apps.jtf_sources   src
     where terr_p.terr_id      = terr.parent_territory_id
       and terr.terr_id        = usg.terr_id
       and terr.org_id         = usg.org_id
       and usg.source_id       = src.source_id
       and src.lookup_code     = 'SALES'
       and terr_p.enabled_flag = 'Y'
       and terr.enabled_flag   = 'Y'
       and src.enabled_flag    = 'Y'
       and trunc(sysdate) between nvl(trunc(terr.start_date_active), sysdate-1)
                              and nvl(trunc(terr.end_date_active),   sysdate+1)
       and trunc(sysdate) between nvl(trunc(terr_p.start_date_active), sysdate-1) 
                              and nvl(trunc(terr_p.end_date_active),   sysdate+1) 
       and trunc(sysdate) between nvl(trunc(src.start_date_active), sysdate-1)
                              and nvl(trunc(src.end_date_active),   sysdate+1)
     start with terr.attribute12 = c_region_code
   connect by prior terr.terr_id = terr.parent_territory_id
     order siblings by terr.name, terr.terr_id;
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
procedure wrtdbg (p_debug_level in  number,
                  p_buff        in varchar2) is
-------------------------------------------------------------------------------

begin
  if (g_debug_level >= p_debug_level) then

    if (g_conc_mgr_env = TRUE) then

        if (p_buff = chr(10)) then
            fnd_file.put_line (FND_FILE.LOG, 'DBG: ');

        else
            fnd_file.put_line (FND_FILE.LOG, 'DBG: ' || dti || p_buff);
        end if;

    else
        if (p_buff = chr(10)) then
            dbms_output.put_line ('DBG: ');

        else
            dbms_output.put_line ('DBG: ' || dti || p_buff);
        end if;
    end if;
  end if;
end wrtdbg;
-- ============================================================================


-------------------------------------------------------------------------------
procedure wrtlog (p_buff in varchar2) is
-------------------------------------------------------------------------------

begin
    if (g_conc_mgr_env = TRUE) then

        if (p_buff = chr(10)) then
            fnd_file.put_line (FND_FILE.LOG, ' ');

        else
            fnd_file.put_line (FND_FILE.LOG, p_buff);
        end if;

    else
        if (p_buff = chr(10)) then
            dbms_output.put_line ('LOG: ');

        else
            dbms_output.put_line ('LOG: ' || p_buff);
        end if;
    end if;
end wrtlog;
-- ============================================================================


-------------------------------------------------------------------------------
procedure wrtlog (p_level in varchar2,
                  p_buff  in varchar2) is
-------------------------------------------------------------------------------

begin
  wrtlog (dti || p_level || ' ' || p_buff);
end wrtlog;
-- ============================================================================


-------------------------------------------------------------------------------
procedure wrtout (p_buff in varchar2) is
-------------------------------------------------------------------------------

begin
    if (g_conc_mgr_env = TRUE) then

        if (p_buff = chr(10)) then
            fnd_file.put_line (FND_FILE.OUTPUT, ' ');

        else
            fnd_file.put_line (FND_FILE.OUTPUT, p_buff);
        end if;

    else
        if (p_buff = chr(10)) then
            dbms_output.put_line ('OUT: ');

        else
            dbms_output.put_line ('OUT: ' || p_buff);
        end if;
    end if;
end wrtout;
-- ============================================================================


-------------------------------------------------------------------------------
procedure wrtall (p_buff in varchar2) is
-------------------------------------------------------------------------------
begin
    if (g_conc_mgr_env = TRUE) then
      wrtlog (p_buff);
      wrtout (p_buff);

    else
      wrtlog (p_buff);
    end if;
end wrtall;
-- ============================================================================


-------------------------------------------------------------------------------
PROCEDURE report_svn_info IS
-------------------------------------------------------------------------------

lc_svn_file_name varchar2(200);

begin
  lc_svn_file_name := regexp_replace(GC_SVN_HEAD_URL, '(.*/)([^/]*)( \$)','\2');

  wrtlog (lc_svn_file_name || ' ' || rtrim(GC_SVN_REVISION,'$') || GC_SVN_DATE);
  wrtlog (' ');
END report_svn_info;
-- ============================================================================


-------------------------------------------------------------------------------
procedure initialize (p_commit_flag     in  varchar2,
                      p_debug_level     in  number,
                      p_sql_trace       in  varchar2,
                      p_msg             out varchar2) is
-------------------------------------------------------------------------------

  l_proc       varchar2(80)   := 'INITIALIZE';
  l_ctx        varchar2(200)  := null;

begin
  g_debug_level := p_debug_level;

  g_warning_ct := 0;

  if (p_sql_trace = 'Y') then
    l_ctx := 'Setting SQL trace ON';
    wrtlog (dti || 'Setting SQL trace ON');

    l_ctx := 'alter session max_dump_file_size';
    execute immediate 'ALTER SESSION SET max_dump_file_size = unlimited';

    l_ctx := 'alter session tracefile_identifier';
    execute immediate 'ALTER SESSION SET tracefile_identifier = ' || SQ || G_PACKAGE || SQ;

    l_ctx := 'alter session timed_statistics';
    execute immediate 'ALTER SESSION SET timed_statistics = true';

    l_ctx := 'alter session events 10046';
    execute immediate 'ALTER SESSION SET EVENTS ''10046 trace name context forever, level 12''';
  end if;

  if (p_commit_flag = 'Y') then
    g_commit := TRUE;
  else
    g_commit := FALSE;
  end if;

  l_ctx := 'get "who" values';
  g_who_values(WHO_USER_ID)         := fnd_global.user_id;

  if (g_who_values(WHO_USER_ID) = ANONYMOUS_APPS_USER) then
      g_who_values(WHO_CONC_REQUEST_ID) := null;
      g_who_values(WHO_PROG_APPL_ID)    := null;
      g_who_values(WHO_CONC_PROGRAM_ID) := null;
      g_who_values(WHO_CONC_LOGIN_ID)   := null;
      g_conc_mgr_env := FALSE;
      dbms_output.enable (NULL);  -- NULL = unlimited size
      wrtlog (dti || 'NOT executing in concurrent manager environment');
  else
      g_who_values(WHO_CONC_REQUEST_ID) := fnd_global.conc_request_id;
      g_who_values(WHO_PROG_APPL_ID)    := fnd_global.prog_appl_id;
      g_who_values(WHO_CONC_PROGRAM_ID) := fnd_global.conc_program_id;
      g_who_values(WHO_CONC_LOGIN_ID)   := fnd_global.conc_login_id;
      g_conc_mgr_env := TRUE;
      wrtlog (dti || 'Executing in concurrent manager environment');
  end if;

  report_svn_info;

  wrtdbg(DBG_LOW, '"who" values: ' ||
                   ' USER_ID=' || g_who_values(WHO_USER_ID) ||
                   ' CONC_REQUEST_ID=' || g_who_values(WHO_CONC_REQUEST_ID) ||
                   ' APPLICATION_ID=' || g_who_values(WHO_PROG_APPL_ID) ||
                   ' CONC_PROGRAM_ID=' || g_who_values(WHO_CONC_PROGRAM_ID) ||
                   ' CONC_LOGIN_ID=' || g_who_values(WHO_CONC_LOGIN_ID));

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end initialize;
-- ============================================================================


-------------------------------------------------------------------------------
function get_region_code (p_region_name in  varchar2,
                          p_msg         out varchar2)
    return varchar2 is
-------------------------------------------------------------------------------

  l_proc       varchar2(80)   := 'get_region_code';
  l_ctx        varchar2(200)  := null;

  l_region_code fnd_lookup_values_vl.lookup_code %type;

begin
  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  l_ctx := 'select from fnd_lookup_values_vl - p_region_name=' || p_region_name;

  select distinct flv.tag
    into l_region_code
    from apps.fnd_flex_value_sets fvs,
         apps.fnd_flex_values_vl  fv,
         apps.fnd_lookup_values   flv
   where fvs.flex_value_set_id   = fv.flex_value_set_id
     and fv.flex_value           = flv.lookup_type
     and fv.enabled_flag         = 'Y'
     and flv.enabled_flag        = 'Y'
     and fvs.flex_value_set_name = 'XX_TM_REGION_TAG'
     and fv.flex_value           = p_region_name
     and trunc(sysdate) between nvl(trunc(fv.start_date_active), sysdate -1)
                            and nvl(trunc(fv.end_date_active),   sysdate +1)
     and trunc(sysdate) between nvl(trunc(flv.start_date_active), sysdate-1)
                            and nvl(trunc(flv.end_date_active),   sysdate+1);

  wrtdbg (DBG_MED, 'Exit ' || l_proc || ' l_region_code=' || l_region_code);

  return (l_region_code);

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
    return null;
end get_region_code;
-- ============================================================================


-------------------------------------------------------------------------------
procedure get_resource_info (p_region_name      in  varchar2,
                             p_terr_name        in  varchar2,
                             p_xref_status      out number,
                             p_sales_rep_id     out varchar2,
                             p_resource_emp_num out varchar2,
                             p_resource_id      out number,
                             p_resource_name    out varchar2,
                             p_resource_type    out varchar2,
                             p_group_id         out number,
                             p_group_name       out varchar2,
                             p_role_id          out number,
                             p_role_code        out varchar2,
                             p_role_name        out varchar2,
                             p_role_member_flag out varchar2,
                             p_msg              out varchar2) is
-------------------------------------------------------------------------------

  l_proc       varchar2(80)   := 'get_resource_info';
  l_ctx        varchar2(200)  := null;

  l_rsc_rol_grp_ct  number;

begin
  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  p_sales_rep_id     := null;
  p_resource_id      := null;
  p_resource_name    := null;
  p_resource_emp_num := null;
  p_resource_type    := null;
  p_group_id         := null;
  p_group_name       := null;
  p_role_id          := null;
  p_role_code        := null;
  p_role_name        := null;
  p_role_member_flag := null;
  p_xref_status      := XREF_STS_IN_PROGRESS;

  begin
    l_ctx := 'select from xx_jtf_terr_resource_xref - p_region_name=' || getval(p_region_name) ||
             ' p_terr_name=' || getval(p_terr_name);
    select rep_id
      into p_sales_rep_id
      from xx_jtf_terr_resource_xref
     where region_name    = p_region_name
       and territory_name = p_terr_name;

    wrtdbg (DBG_HI, '  Fetched rep_id=' || nvl(p_sales_rep_id,'<null>') || ' for territory ' || p_terr_name);

    if (p_sales_rep_id is null) then
      p_xref_status := XREF_STS_NO_RSC_REQUESTED;
    end if;

  exception
    when no_data_found then
      p_xref_status := XREF_STS_NOT_IN_XREF_TBL;
      wrtdbg (DBG_HI, '  EXCEPTION: no_data_found.  l_ctx=' || getval(l_ctx));
  end;

  if (p_xref_status = XREF_STS_IN_PROGRESS) then
    begin
      l_ctx := 'select from jtf resource tables(1) - p_sales_rep_id=' || p_sales_rep_id;
      --
      -- Use jtf_rs_resourcees_vl because we need resource_type column.
      -- Update: jtf_rs_resourcees_vl is too slow.  The resource_type is always
      --         "RS_" + res.category.  Build the string in the query below instead
      --         querting jtf_rs_resources_vl.
      --
      select res.resource_id,
             res.resource_name,
             res.source_number,  -- employee_number
             'RS_' || res.category,
             grp.group_id,
             grp.group_name,
             rol.role_id,
             rol.role_code,
             rol.role_name,
             nvl(rol.member_flag,'N') member_flag
        into p_resource_id,
             p_resource_name,
             p_resource_emp_num,
             p_resource_type,
             p_group_id,
             p_group_name,
             p_role_id,
             p_role_code,
             p_role_name,
             p_role_member_flag
        from apps.jtf_rs_role_relations    rrel,
             apps.jtf_rs_group_members     grpm,
             apps.jtf_rs_groups_vl         grp,
             apps.jtf_rs_resource_extns_vl res,
             apps.jtf_rs_roles_vl          rol
     where rrel.role_resource_id   = grpm.group_member_id
       and grpm.group_id           = grp.group_id
       and grpm.resource_id        = res.resource_id
       and rrel.role_id            = rol.role_id
       and rrel.role_resource_type = 'RS_GROUP_MEMBER'
       and rrel.delete_flag        = 'N'
       and grpm.delete_flag        = 'N'
       and rrel.attribute15        = p_sales_rep_id
       and trunc(sysdate)     between nvl(rrel.start_date_active, sysdate-1)
                                  and nvl(rrel.end_date_active,   sysdate+1)
       and trunc(sysdate)     between nvl(grp.start_date_active, sysdate-1)
                                  and nvl(grp.end_date_active,   sysdate+1)
       and trunc(sysdate)     between nvl(res.start_date_active, sysdate-1)
                                  and nvl(res.end_date_active,   sysdate+1);

      wrtdbg (DBG_HI, '  Select stmt completed-1.');
      wrtdbg (DBG_HI, '         p_resource_id = ' || p_resource_id);
      wrtdbg (DBG_HI, '       p_resource_name = ' || p_resource_name);
      wrtdbg (DBG_HI, '       p_resource_type = ' || p_resource_type);
      wrtdbg (DBG_HI, '            p_group_id = ' || p_group_id);
      wrtdbg (DBG_HI, '          p_group_name = ' || p_group_name);
      wrtdbg (DBG_HI, '             p_role_id = ' || p_role_id);
      wrtdbg (DBG_HI, '           p_role_code = ' || p_role_code);
      wrtdbg (DBG_HI, '           p_role_name = ' || p_role_name);
      wrtdbg (DBG_HI, '    p_role_member_flag = ' || p_role_member_flag);

      --
      -- Only Member roles are allowed
      --
      if (p_role_member_flag = 'Y') then
        p_xref_status := XREF_STS_RSC_FOUND;

      else
        p_xref_status := XREF_STS_ROLE_IS_NOT_MEMBER;
      end if;

    exception
      when no_data_found then
        p_xref_status := XREF_STS_RSC_NOT_FOUND;
        wrtdbg (DBG_HI, '  EXCEPTION: no_data_found.  l_ctx=' || getval(l_ctx));

      when too_many_rows then
        p_xref_status := XREF_STS_RSC_TOO_MANY_RRG;
        wrtdbg (DBG_HI, '  EXCEPTION: too_many_rows.  l_ctx=' || getval(l_ctx));
    end;

    if (p_xref_status = XREF_STS_RSC_NOT_FOUND) then
      --
      -- Change status to XREF_STS_RSC_INACTIVE if we find at least one end-dated record.
      --
      l_ctx := 'select from jtf resource tables(2) - p_sales_rep_id=' || p_sales_rep_id;
      select count(*)
        into l_rsc_rol_grp_ct
        from apps.jtf_rs_role_relations    rrel,
             apps.jtf_rs_group_members     grpm,
             apps.jtf_rs_groups_vl         grp,
             apps.jtf_rs_resource_extns_vl res,
             --apps.jtf_rs_resources_vl      res2,
             apps.jtf_rs_roles_vl          rol
       where rrel.role_resource_id   = grpm.group_member_id
         and grpm.group_id           = grp.group_id
         and grpm.resource_id        = res.resource_id
         --and res.resource_id         = res2.resource_id
         and rrel.role_id            = rol.role_id
         and rrel.role_resource_type = 'RS_GROUP_MEMBER'
         and rrel.attribute15        = p_sales_rep_id;

      wrtdbg (DBG_HI, '  Select stmt completed-2.');
      wrtdbg (DBG_HI, '    l_rrg_ct=' || getval(l_rsc_rol_grp_ct));

      if (nvl(l_rsc_rol_grp_ct,0) > 0) then
        p_xref_status := XREF_STS_RSC_INACTIVE;
      end if;
    end if;
  end if;

  wrtdbg (DBG_MED, 'Exit ' || l_proc || ' - p_xref_status=' || getval(p_xref_status));

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end get_resource_info;
-- ============================================================================


-------------------------------------------------------------------------------
procedure delete_resource_from_terr (p_terr_rsc_id   in  number,
                                     p_msg           out varchar2) is
-------------------------------------------------------------------------------

  l_proc       varchar2(80)   := 'delete_resource_from_terr';
  l_ctx        varchar2(200)  := null;

  l_concat_msg             varchar2(2000);
  l_one_msg                varchar2(2000);
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_terr_rsc_ct            number;

begin
  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  if (g_simulate_mode) then
    return;
  end if;

  l_ctx := 'jtf_territory_pub.Delete_TerrResource - p_terr_rsc_id=' || p_terr_rsc_id;

  jtf_territory_pub.Delete_TerrResource (p_api_version_number => 1.0,
                                         p_init_msg_list      => fnd_api.G_TRUE,
                                         p_commit             => fnd_api.G_FALSE,
                                         x_return_status      => l_return_status,
                                         x_msg_count          => l_msg_count,
                                         x_msg_data           => l_msg_data,
                                         p_terrrsc_id         => p_terr_rsc_id);

  --
  -- Tests show that this API always sets x_return_status to null.
  --
  -- When the API succeeds, there will be 5 messages.  They are:
  --   1) Delete_TerrResource
  --   2) TERR_RESOURCE_DELETED
  --   3) Delete_TerrResource
  --   4) Delete_Terr_Resource
  --   5) Delete_TerrResource
  --
  -- When the API fails, there will be 3 messages.  They are:
  --   1) Delete_TerrResource
  --   2) 0
  --   3) Delete_TerrResource
  --
  -- As a result of the above info, when x_return_status is null we will consider the call to
  -- the API a success after confirming the resource is no longer assigned to the territory.
  --

  l_ctx := 'select from jtf_terr_rsc - terr_rsc_id=' || getval(p_terr_rsc_id);
  select count(*)
    into l_terr_rsc_ct
    from apps.jtf_terr_rsc
   where terr_rsc_id = p_terr_rsc_id;

  wrtdbg (DBG_MED, '  After call to jtf_territory_pub.Delete_TerrResource l_return_status=' || getval(l_return_status) ||
                   ' l_msg_count=' || getval(l_msg_count) || ' l_terr_rsc_ct=' || getval(l_terr_rsc_ct));

  if (nvl(l_terr_rsc_ct,0) != 0) then
    -- We have an error

    p_msg := 'jtf_territory_pub.Delete_TerrResource FAILED - p_terr_rsc_id=' || getval(p_terr_rsc_id) ||
             ' l_return_status=' || getval(l_return_status) ||
             ' l_msg_count=' || getval(l_msg_count) ||
             ' l_terr_rsc_ct(should be 0)=' || getval(l_terr_rsc_ct) ||
             ' l_concat_msg=';

    for l_indx in 1..l_msg_count loop
      l_one_msg := fnd_msg_pub.Get (p_encoded   => fnd_api.G_FALSE,
                                    p_msg_index => l_indx);

      wrtdbg (DBG_MED, '  fnd_msg_pub.Get l_indx=' || getval(l_indx) || ' l_one_msg=' || getval(l_one_msg));

      p_msg := substr(p_msg || ' ' || l_indx || ') ' || l_one_msg,1,2000);
    end loop;
  end if;

  wrtdbg (DBG_MED, 'Exit ' || l_proc);

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end delete_resource_from_terr;
-- ============================================================================


-------------------------------------------------------------------------------
procedure add_resource_to_terr (p_terr_id           in  number,
                                p_org_id            in  number,
                                p_old_terr_rsc_id   in  number,
                                p_new_resource_type in  varchar2,
                                p_new_resource_id   in  number,
                                p_new_role_code     in  varchar2,
                                p_new_role_name     in  varchar2,
                                p_new_group_id      in  number,
                                p_msg               out varchar2) is
-------------------------------------------------------------------------------

  l_proc       varchar2(80)   := 'add_resource_to_terr';
  l_ctx        varchar2(200)  := null;

  l_current_date           date;
  l_msg                    varchar2(2000);
  l_one_msg                varchar2(2000);
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_terrrsc_tbl            jtf_territory_pub.terrresource_tbl_type;
  l_terrrsc_access_tbl     jtf_territory_pub.terrrsc_access_tbl_type;
  x_terrrsc_out_tbl        jtf_territory_pub.terrresource_out_tbl_type;
  x_terrrsc_access_out_tbl jtf_territory_pub.terrrsc_access_out_tbl_type;

begin
  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  if (g_simulate_mode) then
    return;
  end if;

  l_current_date := sysdate;

  if (p_old_terr_rsc_id is not null) then
    --
    -- We need to delete the current resource assignment so we can
    -- assign to a different resource below.
    --
    delete_resource_from_terr (p_terr_rsc_id => p_old_terr_rsc_id,
                               p_msg         => p_msg);

    if (p_msg is not null) then
      return;
    end if;
  end if;

  l_terrrsc_tbl        := jtf_territory_pub.G_MISS_TERRRESOURCE_TBL;
  l_terrrsc_access_tbl := jtf_territory_pub.G_MISS_TERRRSC_ACCESS_TBL;

  l_terrrsc_tbl(1).terr_id           := p_terr_id;
  l_terrrsc_tbl(1).org_id            := p_org_id;
  l_terrrsc_tbl(1).resource_type     := p_new_resource_type;
  l_terrrsc_tbl(1).resource_id       := p_new_resource_id;
  l_terrrsc_tbl(1).role              := p_new_role_code;  -- role_name is displayed in UI but role_code is used here
  l_terrrsc_tbl(1).group_id          := p_new_group_id;
  l_terrrsc_tbl(1).creation_date     := l_current_date;
  l_terrrsc_tbl(1).last_update_date  := l_current_date;
  l_terrrsc_tbl(1).created_by        := g_who_values(WHO_USER_ID);
  l_terrrsc_tbl(1).last_updated_by   := g_who_values(WHO_USER_ID);
  l_terrrsc_tbl(1).last_update_login := nvl(g_who_values(WHO_CONC_LOGIN_ID),-1);  -- null creates a validation error
  l_terrrsc_tbl(1).start_date_active := trunc(l_current_date);

  --
  -- Create an Access Type record of "Account" for l_terrrsc_tbl(1).
  --
  l_terrrsc_access_tbl(1).qualifier_tbl_index := 1;
  l_terrrsc_access_tbl(1).access_type         := 'ACCOUNT';
  l_terrrsc_access_tbl(1).creation_date       := l_current_date;
  l_terrrsc_access_tbl(1).last_update_date    := l_current_date;
  l_terrrsc_access_tbl(1).created_by          := g_who_values(WHO_USER_ID);
  l_terrrsc_access_tbl(1).last_updated_by     := g_who_values(WHO_USER_ID);
  l_terrrsc_access_tbl(1).last_update_login   := nvl(g_who_values(WHO_CONC_LOGIN_ID),-1);  -- null creates a validation error
  l_terrrsc_access_tbl(1).org_id              := p_org_id;

  l_ctx := 'jtf_territory_pub.Create_TerrResource - p_terr_id=' || p_terr_id ||
           ' p_new_resource_id=' || p_new_resource_id || ' p_new_resource_type=' || p_new_resource_type;

  jtf_territory_pub.Create_TerrResource (p_api_version_number     => 1.0,
                                         p_init_msg_list          => fnd_api.G_TRUE,
                                         p_commit                 => fnd_api.G_FALSE,
                                         x_return_status          => l_return_status,
                                         x_msg_count              => l_msg_count,
                                         x_msg_data               => l_msg_data,
                                         p_terrrsc_tbl            => l_terrrsc_tbl,
                                         p_terrrsc_access_tbl     => l_terrrsc_access_tbl,
                                         x_terrrsc_out_tbl        => x_terrrsc_out_tbl,
                                         x_terrrsc_access_out_tbl => x_terrrsc_access_out_tbl);


  if (l_return_status != fnd_api.G_RET_STS_SUCCESS) then

    wrtdbg (DBG_MED, '  jtf_territory_pub.Create_TerrResource FAILED.  l_return_status=' || l_return_status ||
                     ' l_msg_count=' || l_msg_count);
    wrtdbg (DBG_MED, '  jtf_territory_pub.Create_TerrResource raw l_msg_data=' || l_msg_data);
    l_msg := l_ctx || ' l_return_status=' || l_return_status;

    for l_indx in 1..l_msg_count loop
      l_one_msg := fnd_msg_pub.Get (p_encoded   => fnd_api.G_FALSE,
                                    p_msg_index => l_indx);

      wrtdbg (DBG_MED, '  fnd_msg_pub.Get l_indx=' || l_indx || ' l_one_msg=' || l_one_msg);
      l_msg := substr(l_msg || ' | ' || l_one_msg,1,2000);
    end loop;

    p_msg := 'Attempt to assign resource_id=' || p_new_resource_id ||
             ' to terr_id=' || p_terr_id || ': ' || l_msg;
  end if;

  wrtdbg (DBG_MED, 'Exit ' || l_proc);

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end add_resource_to_terr;
-- ============================================================================


-------------------------------------------------------------------------------
procedure get_resource_assigned_to_terr (p_terr_id          in  number,
                                         p_org_id           in  number,
                                         p_terr_rsc_id      out number,
                                         p_resource_id      out number,
                                         p_role_code        out varchar2,
                                         p_group_id         out number,
                                         p_group_name       out varchar2,
                                         p_resource_name    out varchar2,
                                         p_resource_emp_num out varchar2,
                                         p_active_flag      out varchar2,
                                         p_status           out number,
                                         p_msg              out varchar2) is
-------------------------------------------------------------------------------

  l_proc       varchar2(80)   := 'get_resource_assigned_to_terr';
  l_ctx        varchar2(200)  := null;

  l_done              boolean;
  l_terr_rsc_id       number;
  l_resource_id       number;
  l_role_code         jtf_rs_roles_vl.role_code %type;
  l_group_id          number;
  l_group_name        jtf_rs_groups_vl.group_name %type;
  l_active_flag       varchar2(1);
  l_resource_name     jtf_rs_resource_extns_vl.resource_name %type;
  l_resource_emp_num  jtf_rs_resource_extns_vl.source_number %type;

  l_terr_rsc_id2      number;
  l_resource_id2      number;
  l_role_code2        jtf_rs_roles_vl.role_code %type;
  l_group_id2         number;
  l_group_name2       jtf_rs_groups_vl.group_name %type;
  l_active_flag2      varchar2(1);
  l_resource_name2    jtf_rs_resource_extns_vl.resource_name %type;
  l_resource_emp_num2 jtf_rs_resource_extns_vl.source_number %type;

  cursor c_rsc_assigned_to_terr (c_terr_id number, c_org_id number) is
    select jtr.terr_rsc_id,
           jtr.resource_id,
           jtr.role         role_code,
           jtr.group_id,
           grp.group_name,
           rsc.resource_name,
           rsc.source_number,
           (case when trunc(sysdate) between nvl(rsc.start_date_active, sysdate-1)
                                         and nvl(rsc.end_date_active,   sysdate+1) then 'A'
                 else 'I'
            end) active_flag
      from apps.jtf_terr_rsc             jtr,
           apps.jtf_rs_resource_extns_vl rsc,
           (select group_id, group_name
              from apps.jtf_rs_groups_vl
             where trunc(sysdate) between trunc(nvl(start_date_active, sysdate-1))
                                      and trunc(nvl(end_date_active,   sysdate+1))) grp
     where jtr.resource_id = rsc.resource_id
       and jtr.group_id    = grp.group_id (+)
       and jtr.terr_id     = c_terr_id
       and jtr.org_id      = c_org_id
       and trunc(sysdate) between trunc(nvl(jtr.start_date_active, sysdate-1))
                              and trunc(nvl(jtr.end_date_active,   sysdate+1))
     order by terr_rsc_id;

begin
  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  p_status           := RSC_STS_ERROR;
  p_terr_rsc_id      := null;
  p_resource_id      := null;
  p_role_code        := null;
  p_group_id         := null;
  p_group_name       := null;
  p_resource_name    := null;
  p_resource_emp_num := null;
  p_active_flag      := null;
  l_done             := FALSE;

  l_ctx := 'open c_rsc_assigned_to_terr - p_terr_id=' || p_terr_id || ' p_org_id=' || p_org_id;
  open c_rsc_assigned_to_terr (p_terr_id, p_org_id);

  fetch c_rsc_assigned_to_terr into l_terr_rsc_id,   l_resource_id, l_role_code,
                                    l_group_id,      l_group_name,
                                    l_resource_name, l_resource_emp_num, l_active_flag;

  if (c_rsc_assigned_to_terr%notfound) then
    p_status := RSC_STS_NOT_ASSIGNED;
    l_done   := TRUE;
  end if;

  if (l_done = FALSE) then
    fetch c_rsc_assigned_to_terr into l_terr_rsc_id2,   l_resource_id2, l_role_code2,
                                      l_group_id2,      l_group_name2,
                                      l_resource_name2, l_resource_emp_num2, l_active_flag2;

    if (c_rsc_assigned_to_terr%notfound) then
      p_status           := RSC_STS_ONE_ASSIGNED;
      p_terr_rsc_id      := l_terr_rsc_id;
      p_resource_id      := l_resource_id;
      p_role_code        := l_role_code;
      p_group_id         := l_group_id;
      p_group_name       := l_group_name;
      p_resource_name    := l_resource_name;
      p_resource_emp_num := l_resource_emp_num;
      p_active_flag      := l_active_flag;
      l_done   := TRUE;

    else
      p_status := RSC_STS_MULTIPLE_ASSIGNED;
      l_done   := TRUE;
    end if;
  end if;

  l_ctx := 'close c_rsc_assigned_to_terr';
  close c_rsc_assigned_to_terr;

  wrtdbg (DBG_MED, 'Exit ' || l_proc || ' - p_status=' || p_status || ' p_terr_rsc_id=' || p_terr_rsc_id);

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end get_resource_assigned_to_terr;
-- ============================================================================


-------------------------------------------------------------------------------
function get_message (p_message_name  in varchar2,
                      p_token_1_name  in varchar2 default null,
                      p_token_1_value in varchar2 default null,
                      p_token_2_name  in varchar2 default null,
                      p_token_2_value in varchar2 default null,
                      p_token_3_name  in varchar2 default null,
                      p_token_3_value in varchar2 default null,
                      p_token_4_name  in varchar2 default null,
                      p_token_4_value in varchar2 default null,
                      p_token_5_name  in varchar2 default null,
                      p_token_5_value in varchar2 default null)
  return varchar2 is
-------------------------------------------------------------------------------

l_message varchar2(2000);

begin
  fnd_message.set_name ('XXCRM',p_message_name);

  if (p_token_1_name is not null) then
    fnd_message.set_token (p_token_1_name, p_token_1_value);
  end if;

  if (p_token_2_name is not null) then
    fnd_message.set_token (p_token_2_name, p_token_2_value);
  end if;

  if (p_token_3_name is not null) then
    fnd_message.set_token (p_token_3_name, p_token_3_value);
  end if;

  if (p_token_4_name is not null) then
    fnd_message.set_token (p_token_4_name, p_token_4_value);
  end if;

  if (p_token_5_name is not null) then
    fnd_message.set_token (p_token_5_name, p_token_5_value);
  end if;

  l_message := fnd_message.get;

  if (l_message is null) then
    l_message := '<ERROR: Unable to fetch message from dictionary>';
  end if;

  return (l_message);
end get_message;
-- ============================================================================


-------------------------------------------------------------------------------
procedure process_child_territory (p_terr_id          in  number,
                                   p_org_id           in  number,
                                   p_region_name      in  varchar2,
                                   p_terr_name        in  varchar2,
                                   p_terr_level       in  number,
                                   p_parent_terr_name in  varchar2,
                                   p_verbose_mode     in  varchar2,
                                   asg_ct             in out nocopy num_arr_type,
                                   p_msg              out varchar2) is
-------------------------------------------------------------------------------

  l_proc       varchar2(80)   := 'process_child_territory';
  l_ctx        varchar2(200)  := null;

  l_action_msg_type        varchar2(1);
  l_action_msg             varchar2(500);
  l_action_msg2            varchar2(500);
  l_rsc_assignment_changed boolean := FALSE;

  l_resource_name    jtf_rs_resource_extns_vl.resource_name %type;
  l_resource_emp_num jtf_rs_resource_extns_vl.source_number %type;
  l_resource_type    jtf_rs_resources_vl.resource_type %type;

  l_assigned_resource_id      number;
  l_assigned_terr_rsc_id      number;
  l_assigned_role_code        jtf_rs_roles_vl.role_code %type;
  l_assigned_group_id         number;
  l_assigned_group_name       jtf_rs_groups_vl.group_name %type;
  l_assigned_resource_name    jtf_rs_resource_extns_vl.resource_name %type;
  l_assigned_resource_emp_num jtf_rs_resource_extns_vl.source_number %type;
  l_active_flag               varchar2(1);
  l_sales_rep_id              xx_jtf_terr_resource_xref.rep_id %type;

  l_rsc_asg_status    number;
  l_delete_assignment boolean;

  l_xref_status      number;
  l_resource_id      number;
  l_group_id         number;
  l_group_name       jtf_rs_groups_vl.group_name %type;
  l_role_id          number;
  l_role_code        jtf_rs_roles_vl.role_code   %type;
  l_role_name        jtf_rs_roles_vl.role_name   %type;
  l_role_member_flag jtf_rs_roles_vl.member_flag %type;
  l_verbose_msg      varchar2(1);

begin
  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  l_delete_assignment := FALSE;

  --
  -- Get the resource assigned to this territory if there is one
  --
  get_resource_assigned_to_terr (p_terr_id          => p_terr_id,
                                 p_org_id           => p_org_id,
                                 p_terr_rsc_id      => l_assigned_terr_rsc_id,
                                 p_resource_id      => l_assigned_resource_id,
                                 p_role_code        => l_assigned_role_code,
                                 p_group_id         => l_assigned_group_id,
                                 p_group_name       => l_assigned_group_name,
                                 p_resource_name    => l_assigned_resource_name,
                                 p_resource_emp_num => l_assigned_resource_emp_num,
                                 p_active_flag      => l_active_flag,
                                 p_status           => l_rsc_asg_status,
                                 p_msg              => p_msg);
  if (p_msg is not null) then
    return;
  end if;

  if (l_rsc_asg_status = RSC_STS_MULTIPLE_ASSIGNED) then
    asg_ct(ASG_MULT_RSC_CT) := asg_ct(ASG_MULT_RSC_CT) + 1;
    l_action_msg := get_message ('XX_TM_0279_TOO_MANY_RESOURCES'); -- More than one resource assigned to this territory.  Skipping.
    l_action_msg_type := ACTION_MSG_WARN;

  elsif ((l_rsc_asg_status = RSC_STS_ONE_ASSIGNED) or (l_rsc_asg_status = RSC_STS_NOT_ASSIGNED)) then

    l_ctx := 'get_resource_info - p_terr_name=' || p_terr_name;
    get_resource_info (p_region_name      => p_region_name,
                       p_terr_name        => p_terr_name,
                       p_xref_status      => l_xref_status,
                       p_sales_rep_id     => l_sales_rep_id,
                       p_resource_emp_num => l_resource_emp_num,
                       p_resource_id      => l_resource_id,
                       p_resource_name    => l_resource_name,
                       p_resource_type    => l_resource_type,
                       p_group_id         => l_group_id,
                       p_group_name       => l_group_name,
                       p_role_id          => l_role_id,
                       p_role_code        => l_role_code,
                       p_role_name        => l_role_name,
                       p_role_member_flag => l_role_member_flag,
                       p_msg              => p_msg);

    if (p_msg is not null) then
      return;
    end if;

    if (l_xref_status = XREF_STS_ERROR) then
      asg_ct(ASG_ERROR_CT) := asg_ct(ASG_ERROR_CT) + 1;
      l_action_msg         := get_message('XX_TM_0280_INTERNAL_ERROR');  -- Internal error getting xref info.  (this error no longer used)
      l_action_msg_type    := ACTION_MSG_WARN;

    elsif (l_xref_status = XREF_STS_NOT_IN_XREF_TBL) then
      asg_ct(ASG_NOT_IN_XREF_CT) := asg_ct(ASG_NOT_IN_XREF_CT) + 1;
      l_delete_assignment        := TRUE;
      l_action_msg               := get_message('XX_TM_0281_TERR_NOT_IN_XREF');  -- Territory not found in xref table.
      l_action_msg_type          := ACTION_MSG_WARN;

    elsif (l_xref_status = XREF_STS_RSC_NOT_FOUND) then
      asg_ct(ASG_RSC_NOT_FOUND_CT) := asg_ct(ASG_RSC_NOT_FOUND_CT) + 1;
      l_delete_assignment          := TRUE;
      l_action_msg                 := get_message('XX_TM_0282_NO_RSC_ROLE_GRP','REP',l_sales_rep_id);  -- Resource, role, and group not found for sales rep REP
      l_action_msg_type            := ACTION_MSG_WARN;

    elsif (l_xref_status = XREF_STS_ROLE_IS_NOT_MEMBER) then
      asg_ct(ASG_ROLE_IS_NOT_MEMBER_CT) := asg_ct(ASG_ROLE_IS_NOT_MEMBER_CT) + 1;
      l_delete_assignment               := TRUE;
      l_action_msg                      := get_message('XX_TM_0290_NOT_A_MEMBER_ROLE','REP',l_sales_rep_id,'ROLE',l_role_name);
      l_action_msg_type                 := ACTION_MSG_WARN;

    elsif (l_xref_status = XREF_STS_RSC_TOO_MANY_RRG) then
      asg_ct(ASG_RSC_TOO_MANY_CT) := asg_ct(ASG_RSC_TOO_MANY_CT) + 1;
      l_delete_assignment         := TRUE;
      l_action_msg                := get_message('XX_TM_0289_RSC_TOO_MANY','REP',l_sales_rep_id);  -- Multiple resource, role, and group records exist for sales rep REP.
      l_action_msg_type           := ACTION_MSG_WARN;

    elsif (l_xref_status = XREF_STS_RSC_INACTIVE) then
      asg_ct(ASG_RSC_INACTIVE_CT) := asg_ct(ASG_RSC_INACTIVE_CT) + 1;
      l_delete_assignment         := TRUE;
      l_action_msg                := get_message('XX_TM_0288_RSC_INACTIVE','REP',l_sales_rep_id);  -- Resource, role, and group not found for sales rep REP
      l_action_msg_type           := ACTION_MSG_WARN;

    elsif (l_xref_status not in (XREF_STS_NO_RSC_REQUESTED, XREF_STS_RSC_FOUND)) then
      p_msg := 'Unknown l_xref_status=' || l_xref_status || ' returned by get_resource_info for p_terr_name=' || p_terr_name;
      return;
    end if;

    if (l_action_msg_type is null) then

      if (l_rsc_asg_status = RSC_STS_ONE_ASSIGNED) then

        if (l_xref_status = XREF_STS_NO_RSC_REQUESTED) then

          --
          -- We no longer want a resource assigned to this territory
          --
          delete_resource_from_terr (p_terr_rsc_id => l_assigned_terr_rsc_id,
                                     p_msg         => p_msg);

          if (p_msg is not null) then
            return;
          end if;

            l_action_msg             := get_message('XX_TM_0283_DELETED_ASSIGNMENT');  -- Deleted assignment.
            l_action_msg_type        := ACTION_MSG_INFO;
            asg_ct(ASG_DELETED_CT)   := asg_ct(ASG_DELETED_CT) + 1;
            l_rsc_assignment_changed := TRUE;

        elsif (l_xref_status = XREF_STS_RSC_FOUND) then

          if (    (nvl(l_assigned_resource_id, -9999)  = l_resource_id) 
              and (nvl(l_assigned_role_code, 'xztaaa') = l_role_code)
              and (nvl(l_assigned_group_id,  -9999)    = l_group_id)) then
            -- Already assigned to resource RESOURCE, ROLE and GROUP.  No action needed.
            l_action_msg := get_message('XX_TM_0284_TERR_ALREADY_ASSIGN',
                                        'RESOURCE',l_assigned_resource_name || ' (' || l_assigned_resource_emp_num || ')',
                                        'ROLE',    l_role_name,  -- UI displayes role_name
                                        'GROUP',   l_assigned_group_name);
            l_action_msg_type      := ACTION_MSG_INFO;
            asg_ct(ASG_SKIPPED_CT) := asg_ct(ASG_SKIPPED_CT) + 1;

          else
            --
            -- If we are here, a resource is currently assigned to the territory but
            -- a different resource assignment has been requested in the xref table.
            --
            add_resource_to_terr (p_terr_id           => p_terr_id,
                                  p_org_id            => p_org_id,
                                  p_old_terr_rsc_id   => l_assigned_terr_rsc_id,
                                  p_new_resource_type => l_resource_type,
                                  p_new_resource_id   => l_resource_id,
                                  p_new_role_code     => l_role_code,
                                  p_new_role_name     => l_role_name,
                                  p_new_group_id      => l_group_id,
                                  p_msg               => p_msg);

            if (p_msg is not null) then
              return;
            end if;
            -- Changed assignment.  Resource set to RESOURCE, ROLE and GROUP.
            l_action_msg             := get_message('XX_TM_0285_TERR_ASG_UPDATED',
                                                    'RESOURCE',l_resource_name || ' (' || l_resource_emp_num || ')',
                                                    'ROLE',    l_role_name,  -- UI displayes role_name
                                                    'GROUP',   l_group_name);

            l_action_msg_type        := ACTION_MSG_INFO;
            asg_ct(ASG_CHANGED_CT)   := asg_ct(ASG_CHANGED_CT) + 1;
            l_rsc_assignment_changed := TRUE;
          end if;

        else
          p_msg := 'Internal error.  l_xref_status has unknown value = ' || l_xref_status;
          return;
        end if;

      elsif (l_rsc_asg_status = RSC_STS_NOT_ASSIGNED) then

        if (l_xref_status = XREF_STS_NO_RSC_REQUESTED) then

          l_action_msg           := get_message('XX_TM_0286_TERR_ASG_NO_CHANGE');  -- Already unassigned.  No action needed.
          l_action_msg_type      := ACTION_MSG_INFO;
          asg_ct(ASG_SKIPPED_CT) := asg_ct(ASG_SKIPPED_CT) + 1;

        elsif (l_xref_status = XREF_STS_RSC_FOUND) then

          --
          -- If we are here, a resource is not currently assigned to the territory but
          -- the xref table requests an assignment to be created.
          --
          add_resource_to_terr (p_terr_id           => p_terr_id,
                                p_org_id            => p_org_id,
                                p_old_terr_rsc_id   => null,
                                p_new_resource_type => l_resource_type,
                                p_new_resource_id   => l_resource_id,
                                p_new_role_code     => l_role_code,
                                p_new_role_name     => l_role_name,
                                p_new_group_id      => l_group_id,
                                p_msg               => p_msg);

          if (p_msg is not null) then
            return;
          end if;
          -- Created assignment.   Resource set to RESOURCE, ROLE and GROUP.
          l_action_msg             := get_message('XX_TM_0287_TERR_ASG_CREATED',
                                                  'RESOURCE',l_resource_name || ' (' || l_resource_emp_num || ')',
                                                  'ROLE',    l_role_name,  -- UI displayes role_name
                                                  'GROUP',   l_group_name);

          l_action_msg_type        := ACTION_MSG_INFO;
          asg_ct(ASG_CREATED_CT)   := asg_ct(ASG_CREATED_CT) + 1;
          l_rsc_assignment_changed := TRUE;

        else
          p_msg := 'Internal error.  l_xref_status has unknown value = ' || l_xref_status;
        end if;
      else
        p_msg := 'Internal error.  l_rsc_asg_status has unknown value = ' || l_rsc_asg_status;
        return;
      end if;

    else  -- if l_action_msg_type is null

      if ((l_delete_assignment = TRUE) and (l_rsc_asg_status = RSC_STS_ONE_ASSIGNED)) then
        
        --
        -- An error occrred that triggers the deletion of the resource assigned to the territory.
        --
        delete_resource_from_terr (p_terr_rsc_id => l_assigned_terr_rsc_id,
                                   p_msg         => p_msg);

        if (p_msg is not null) then
          return;
        end if;

        asg_ct(ASG_DELETED_ERR_CT) := asg_ct(ASG_DELETED_ERR_CT) + 1;

        --
        -- Append to the current message so users know we just deleted the current assignment.
        --
        l_action_msg2 := get_message('XX_TM_0283_DELETED_ASSIGNMENT');
        l_action_msg := l_action_msg || ' ' || l_action_msg2;
        
      end if;
    end if;  -- if l_action_msg_type is null

  else
    p_msg := 'Internal error.  l_rsc_asg_status has unknown value = ' || l_rsc_asg_status;
    return;
  end if;

  --
  -- Display a message if a resource was assigned to a territory or the resouce assignment changed.
  -- Also, display a message if no change occurred if we are in verbose mode.
  --
  if (l_action_msg_type     = ACTION_MSG_WARN or
      p_verbose_mode        = 'Y' or
      l_rsc_assignment_changed = TRUE) then

    wrtout (rpad(p_parent_terr_name, greatest(40, length(p_parent_terr_name))) || '  ' ||
            rpad(p_terr_name,        greatest(20, length(p_terr_name)))        || '  ' ||
            l_action_msg_type || '     ' || l_action_msg);
  end if;

  if (l_action_msg_type = ACTION_MSG_WARN) then
    g_warning_ct         := g_warning_ct + 1;
  end if;

  wrtdbg (DBG_MED, 'Exit ' || l_proc);

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end process_child_territory;
-- ============================================================================


-------------------------------------------------------------------------------
procedure write_simulation_mode_msg is
-------------------------------------------------------------------------------

begin
  wrtall ('***');
  wrtall ('***  Program is running in SIMULATION MODE.  No changes will be made.');
  wrtall ('***');
  wrtall ('');
end write_simulation_mode_msg;
-- ============================================================================


-------------------------------------------------------------------------------
procedure write_report_header (p_region_name in  varchar2,
                               p_msg         out varchar2) is
-------------------------------------------------------------------------------

  l_proc       varchar2(80)   := 'write_report_header';
  l_ctx        varchar2(200)  := null;

  ld_sysdate   date := sysdate;
begin
  wrtout ('----------------------------------------------------------------------------------------------------------------------');
  wrtout ('');
  wrtout ('OFFICE DEPOT                                                                                   Date: ' || 
             to_char(ld_sysdate,'DD-MON-YYYY hh24:mi'));
  wrtout ('');
  wrtout ('                                          OD: TM Assign Resources to Territories');
  wrtout ('');
  wrtout ('                                          Region: ' || p_region_name);
  wrtout ('----------------------------------------------------------------------------------------------------------------------');
  wrtout ('');
  wrtout ('Message Types:');
  wrtout ('  I = Information message');
  wrtout ('  W = Warning message');
  --wrtout ('  E = Error message');
  wrtout ('');
  wrtout ('                                                                Msg');
  wrtout ('Parent Territory Name                     Territory Name        Type  Message');
  wrtout ('----------------------------------------  --------------------  ----  ------------------------------------------------------------');
exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end write_report_header;
-- ============================================================================


-------------------------------------------------------------------------------
procedure process_territories (p_region_name   in  varchar2,
                               p_verbose_mode  in  varchar2,
                               p_msg           out varchar2) is
-------------------------------------------------------------------------------

  l_proc       varchar2(80)   := 'process_territories';
  l_ctx        varchar2(200)  := null;

  l_region_code       fnd_lookup_values_vl.lookup_code %type;
  l_prior_level       number := 0;
  l_child_terr_ct     number := 0;  -- # child territories found
  asg_ct              num_arr_type;

  l_fetch_ct          number := 0;
  l_asg_skip_ct       number := 0;  -- terr already assigned to the correct resource
  l_asg_added_ct      number := 0;  -- terr had a resource assginment creaded and no assignment already existed
  l_asg_changed_ct    number := 0;  -- terr had a change of resource assignment
  l_asg_err_ct        number := 0;  -- terr had an error

  l_region_code_ct    number := 0;

  terr_rec  c_territories %rowtype;

begin
  wrtlog ('');
  wrtlog ('Start ' || l_proc);

  for I in 1..ASG_CT_MAX_INDX loop
    asg_ct(I) := 0;
  end loop;

  l_region_code := get_region_code (p_region_name => p_region_name,
                                    p_msg         => p_msg);

  if (p_msg is null) then
    wrtlog ('Region code for top level territory = ' || l_region_code);
    wrtlog (' ');

    write_report_header (p_region_name => p_region_name,
                         p_msg         => p_msg);
  end if;

  
  if (p_msg is null) then
    --
    -- Verify region code exists in exactly one sales territory record.
    --
    select count(*)
      into l_region_code_ct
      from apps.jtf_terr      terr,
           apps.jtf_terr_usgs usg,
           apps.jtf_sources   src
     where terr.terr_id        = usg.terr_id
         and terr.org_id       = usg.org_id
         and usg.source_id     = src.source_id
         and terr.attribute12  = l_region_code
         and src.lookup_code   = 'SALES'
         and terr.enabled_flag = 'Y'
         and src.enabled_flag  = 'Y'
         and trunc(sysdate) between nvl(trunc(terr.start_date_active), sysdate-1)
                                and nvl(trunc(terr.end_date_active),   sysdate+1)
         and trunc(sysdate) between nvl(trunc(src.start_date_active), sysdate-1)
                                and nvl(trunc(src.end_date_active),   sysdate+1);

    if (nvl(l_region_code_ct,0) != 1) then
      p_msg := 'Expecting 1 top level parent territory record with region code ' ||
                getval(l_region_code) || ' but the count is ' || getval(l_region_code_ct);
    end if;
  end if;

  if (p_msg is null) then
    l_ctx := 'open c_territories - l_region_code=' || l_region_code;
    open c_territories (l_region_code);

    loop
      fetch c_territories into terr_rec;
      exit when c_territories %notfound;

      l_fetch_ct := l_fetch_ct + 1;

      wrtdbg (DBG_MED,' ');
      wrtdbg (DBG_MED,'Fetched c_territories(' || getval(l_fetch_ct) || '):');
      wrtdbg (DBG_MED,'                  level = ' || getval(terr_rec.level));
      wrtdbg (DBG_MED,'                terr_id = ' || getval(terr_rec.terr_id));
      wrtdbg (DBG_MED,'                   name = ' || getval(terr_rec.name));
      wrtdbg (DBG_MED,'                   rank = ' || getval(terr_rec.rank));
      wrtdbg (DBG_MED,'    parent_territory_id = ' || getval(terr_rec.parent_territory_id));
      wrtdbg (DBG_MED,'       parent_terr_name = ' || getval(terr_rec.parent_terr_name));
      wrtdbg (DBG_MED,'                 org_id = ' || getval(terr_rec.org_id));
      wrtdbg (DBG_MED,'          child_terr_ct = ' || getval(terr_rec.child_terr_ct));
      wrtdbg (DBG_MED,'         postal_code_ct = ' || getval(terr_rec.postal_code_ct));

      --
      -- If this is a child territory, attempt to assign a resource if not already assigned
      --
      if (terr_rec.child_terr_ct = 0 and terr_rec.postal_code_ct > 0) then

        --
        -- Process the child territory.
        --
        l_child_terr_ct := l_child_terr_ct + 1;

        process_child_territory (p_terr_id          => terr_rec.terr_id,
                                 p_org_id           => terr_rec.org_id,
                                 p_region_name      => p_region_name,
                                 p_terr_name        => terr_rec.name,
                                 p_terr_level       => terr_rec.level,
                                 p_parent_terr_name => terr_rec.parent_terr_name,
                                 p_verbose_mode     => p_verbose_mode,
                                 asg_ct             => asg_ct,
                                 p_msg              => p_msg);

        if (p_msg is not null) then
          exit;
        end if;
      end if;

    end loop;

    l_ctx := 'close c_territories';
    close c_territories;
  end if;

  wrtall (' ');
  wrtall (to_char(l_child_terr_ct,'999,990') || ' child territories found.');
  wrtall ('--------');
  wrtall (to_char(asg_ct(ASG_SKIPPED_CT),           '999,990') || ' territories already assigned to the correct resource.');
  wrtall (to_char(asg_ct(ASG_CREATED_CT),           '999,990') || ' territories had a resource assignment created.');
  wrtall (to_char(asg_ct(ASG_CHANGED_CT),           '999,990') || ' territories had a resource assignment changed.');
  wrtall (to_char(asg_ct(ASG_DELETED_CT),           '999,990') || ' territories had a resource assignment deleted.');
  wrtall (to_char(asg_ct(ASG_NOT_IN_XREF_CT),       '999,990') || ' territories could not be processed because territory name not in xref table.');
  wrtall (to_char(asg_ct(ASG_RSC_INACTIVE_CT),      '999,990') || ' territories could not be processed because sales rep assigned to inactive resource, role, group.');
  wrtall (to_char(asg_ct(ASG_RSC_TOO_MANY_CT),      '999,990') || ' territories could not be processed because sales rep assigned to multiple resource, role, groups.');
  wrtall (to_char(asg_ct(ASG_ROLE_IS_NOT_MEMBER_CT),'999,990') || ' territories could not be processed because sales rep assigned to non-Member role.');
  wrtall (to_char(asg_ct(ASG_RSC_NOT_FOUND_CT),     '999,990') || ' territories could not be processed because resource info could not be found.');
  wrtall (to_char(asg_ct(ASG_MULT_RSC_CT),          '999,990') || ' territories could not be processed because more than one resource already assigned.');
  wrtall (to_char(asg_ct(ASG_ERROR_CT),             '999,990') || ' territories could not be processed due to other errors.');
  wrtall ('--------');
  wrtall (to_char(asg_ct(ASG_DELETED_ERR_CT),       '999,990') || ' territories had a resource assignment deleted because an error occurred.');
  wrtall (' ');

  wrtlog (dti || 'End ' || l_proc);

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end process_territories;
-- ============================================================================


-------------------------------------------------------------------------------
procedure do_main (errbuf           out varchar2,
                   retcode          out number,
                   p_region_name    in  varchar2,
                   p_verbose_mode   in  varchar2  default 'N',
                   p_simulate_mode  in  varchar2  default 'N',
                   p_commit_flag    in  varchar2  default 'Y',
                   p_debug_level    in  number    default 0,
                   p_sql_trace      in  varchar2  default 'N') is
-------------------------------------------------------------------------------

  l_proc       varchar2(80)   := 'do_main';
  l_ctx        varchar2(200)  := null;
  l_error_msg  varchar2(2000) := null;

  l_msg        varchar2(2000);

  l_fnd_rtn    boolean;

begin
--  dbms_profiler.start_profiler (G_PACKAGE); -- DEBUG ONLY ////////
fnd_msg_pub.G_msg_level_threshold := 1;
  initialize (p_commit_flag     => p_commit_flag,
              p_debug_level     => p_debug_level,
              p_sql_trace       => p_sql_trace,
              p_msg             => l_msg);

  --
  -- This must be after "initialize" so we know whether wrtlog
  -- goes to stdout or the concurrent log.
  --

  wrtlog ('.');
  wrtlog (dti || 'Parameters for package ' || G_PACKAGE || ':');
  wrtlog (dti || '      p_region_name = ' || p_region_name);
  wrtlog (dti || '     p_verbose_mode = ' || p_verbose_mode);
  wrtlog (dti || '    p_simulate_mode = ' || p_simulate_mode);
  wrtlog (dti || '      p_commit_flag = ' || p_commit_flag);
  wrtlog (dti || '      p_debug_level = ' || p_debug_level);
  wrtlog (dti || '        p_sql_trace = ' || p_sql_trace);
  wrtlog ('.');

  wrtdbg (DBG_LOW, dti || 'Enter ' || l_proc);

  if (p_simulate_mode not in ('Y', 'N')) then
    l_msg := 'Valid values for p_simulate_mode are: Y or N';
  end if;

  if (p_verbose_mode not in ('Y', 'N')) then
    l_msg := 'Valid values for p_verbose_mode are: Y or N';
  end if;

  if (p_simulate_mode = 'N') then
    g_simulate_mode := FALSE;
  else
    g_simulate_mode := TRUE;
    write_simulation_mode_msg;
  end if;

  if (l_msg is null) then
    process_territories (p_region_name   => p_region_name,
                         p_verbose_mode  => p_verbose_mode,
                         p_msg           => l_msg);
  end if;

  if (l_msg is not null) then
      l_error_msg := 'ERROR: ' || l_msg;
      wrtlog (l_error_msg);
      retcode := CONC_STATUS_ERROR;
      errbuf  := 'Check log for Error information.';

      if (g_commit) then
        l_ctx := 'rollback';
        rollback;
      end if;
  else

    wrtlog (' ');
    wrtlog (g_warning_ct || ' warnings generated.');
    wrtlog (' ');

    if (g_warning_ct = 0) then
      retcode := CONC_STATUS_OK;
      errbuf    := null;

    else
      retcode := CONC_STATUS_WARNING;
      errbuf  := 'Check log for Warning information.';
      --
      -- When the completion code is WARNING, ORacle does not populate
      -- the Completion Text in the Concurrent Requests "View Details"
      -- screen unless we call fnd_concurrent.set_completion_status.
      -- This info is accurate as of release 11.5.5.
      --
      l_fnd_rtn := fnd_concurrent.set_completion_status ('WARNING',errbuf);
    end if;

    if (l_msg is null) and (g_commit) then
      l_ctx := 'commit';
      commit;
    end if;
  end if;

  if (p_sql_trace = 'Y') then
    l_ctx := 'Setting SQL trace OFF';
    wrtlog (dti || 'Setting SQL trace OFF');

    l_ctx := 'alter session - trace off';
    execute immediate 'alter session set events ''10046 trace name context off''';
  end if;

--  dbms_profiler.stop_profiler;  --  DEBUG ONLY  //////

  wrtdbg (DBG_LOW, dti || 'Exit ' || l_proc || ' - retocde=' || retcode || ' errbuf=' || errbuf);

exception
  when others then
    l_error_msg := l_proc || ': ' || l_ctx || ' - SQLERRM=' || SQLERRM;
    raise_application_error (-20001, l_error_msg);
end do_main;

-- ============================================================================

end xx_tm_assign_resource_to_terr;
/

show errors
