/*=======================================================================+
 |  Copyright (c) 1999 Oracle Corporation Redwood Shores, California, USA|
 |                          All rights reserved.                         |
 +=======================================================================+
 | FILENAME                                                              |
 |   ARHLWRPB.pls                                                        |
 |                                                                       |
 | DESCRIPTION                                                           |
 |                                                                       |
 | NOTES                                                                 |
 |                                                                       |
 | MODIFICATION HISTORY                                                  |
 |      14-MAY-2002       Tasman Tang        Created                     |
 |      19-DEC-2003       Ramesh Ch.        Commented out the g_debug   |
 |       and modified calls to hz_utility_pub's           |
 |       debug & debug_return_messages as part of         |
 |       Common Logging Infrastructure uptake.            |
 |      19-JAN-2004  Srikanth Modified                                   |
 |                   Bug#3385993.                                        |
 |                   HZ_IMP_LOAD_BATCH_COUNTS_PKG.post_import_counts     |
 |                   singnature change incorporated.                     |
 |      21-SEP-2004  Kate Shan Modified                                  |
 |                   bug 3849232                                         |
 |                   add policy functions unconditionally as long as     |
 |                   the content_src_type is not USER_ENTERED and        |
 |                   policy not exist                                    |
 |      19-JAN-2005  V.Ravichandran Modified.                            |
 |                   bug 4079902                                         |
 |                   Modified code for SSM-SST integration project.      |
 |                   Commented the code which added the policy functions |
 |                   for other entities. Added the code for inserting    |
 |                   errors into HZ_IMP_ERRORS table when third party    |
 |                   data( for address and contact points) is updated by |
 |                   some other source system.                           |
 |      27-JAN-2005  Sravanthi  Bug 3932987: Passed to_char(d_sysdate) to|
 |                   calls to submit_request for submitting stage2 and   |
 |         stage3 programs.                                    |
 |      01-MAR-2005  V.Ravichandran Modified.                            |
 |                   bug 4156586.                                        |
 |                   Modified the procedure generate_errors to throw     |
 |                   error when a contact is created such that the       |
 |                   subject and the object are the same entity. Also    |
 |                   removed the redundant procedure get_content_src_type|    
 |      30-MAY-2005  V.Ravichandran Modified                             |
 |                   bug 4398179. Create a one-off for bug 4374278 over  |   
 |                   HZ.N.                                               |   
 |      28-OCT-2005  ACHUNG                                              |
 |                   Bug 4709096/4671360 : add alias to run_number       |
 |      14-MAR-2006  V.Ravichandran Modified                             |
 |                   bug 5091668.                                        |   
 |      23-MAY-2006  V.Ravichandran Modified.                            |
 |                   bug 5201686.                                        |
 |                   Added the procedure cleanup_dup_osr to avoid        |
 |                   multiple active SST profiles in the table           |
 |                   HZ_ORGANIZATION_PROFILES.                           |
 |      12-JUN-2005  V.Ravichandran Modified                             |
 |                   Bug 5276809.                                        |
 |                   Added error messages for invalid values of gender   |
 |                   and person_iden_type while loading person parties.  |
 |      19-Jul-2006  A Chung                                             |
 |                   Bug 5264069 - cleanup SSm to syn up party_id between|
 |                   party and party site/contatc points                 |
 |      05-OCT-2006  V.Ravichandran Modified                             |
 |                   Bug 5576932.                                        |
 |                   Modified the data_load procedure to call the        |
 |                   HZ_IMP_LOAD_BATCH_COUNTS_PKG.post_import_counts     |
 |                   procedure correctly.                                |
 |      27-OCT-2006  V.Ravichandran Modified                             |
 |                   Bug 5439622.                                        |
 |                   Modified the data_load procedure to call the        |
 |                   such that the error limit behvaes correctly.        |
 |      12-DEC-2006  A Chung Bug 5606900.                                |
 |                   Modified procedure cleanup_dup_osr to mark child    |
 |                   entities with interface_status = 'D'                |
 |                   Remove profile update version check when calling    |
 |                   cleanup_dup_osr                                     |
 |                   Modified procedure ident_dup_within_int not checking|
 |                   records in hz_imp_classifics_int.interface_status='D'|
 *=======================================================================*/

REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE HZ_NINEI_CHECK &un_apps &pw_apps  sqlplus &phase=plb

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY HZ_IMP_LOAD_WRAPPER AS
/*$Header: ARHLWRPB.pls 115.52.115104.15 2006/12/22 21:46:57 achung noship $*/

WORK_UNIT_CAP_SIZE NUMBER := 200000;

-- Bug 5264069
TYPE cleanup_ssm_pid_csr_type  IS REF CURSOR;
TYPE ROWID            IS TABLE OF VARCHAR2(50);
TYPE OWNER_TABLE_ID   IS TABLE OF HZ_ORIG_SYS_REFERENCES.OWNER_TABLE_ID%TYPE;
l_row_id                ROWID;
l_party_owner_table_id  OWNER_TABLE_ID;
l_rows                  NUMBER := 1000;
l_last_fetch            BOOLEAN;

/*  bug fix 3849232 */
PROCEDURE add_policy 
IS

     l_ar_schema          VARCHAR2(30);
     l_apps_schema        VARCHAR2(30);
     l_aol_schema         VARCHAR2(30);
     l_apps_mls_schema    VARCHAR2(30);

     l_status             VARCHAR2(30);
     l_industry           VARCHAR2(30);
     l_return_value       BOOLEAN;

     -- Bug 4079902.
     l_result             BOOLEAN;

BEGIN

  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:add_policy()+',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
  END IF;

     --Get ar and apps schema name
     l_return_value := fnd_installation.get_app_info(
           'AR', l_status, l_industry, l_ar_schema);

     IF NOT l_return_value THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
     END IF;

     l_return_value := fnd_installation.get_app_info(
           'FND', l_status, l_industry, l_aol_schema);

     IF NOT l_return_value THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
     END IF;

     system.ad_apps_private.get_apps_schema_name(
          1, l_aol_schema, l_apps_schema, l_apps_mls_schema);

     --Add policy functions
     /*
     FND_ACCESS_CONTROL_UTIL.ADD_POLICY(l_ar_schema, 'HZ_ORGANIZATION_PROFILES', 'content_source_type_sec', l_apps_schema, 'hz_common_pub.content_source_type_security');
     FND_ACCESS_CONTROL_UTIL.ADD_POLICY(l_ar_schema, 'HZ_PERSON_PROFILES', 'content_source_type_sec', l_apps_schema, 'hz_common_pub.content_source_type_security');
     */

     -- Bug 4079902
     DBMS_RLS.ADD_POLICY(l_ar_schema, 'HZ_ORGANIZATION_PROFILES', 'content_source_type_sec', l_apps_schema, 'hz_common_pub.content_source_type_security');
     DBMS_RLS.ADD_POLICY(l_ar_schema, 'HZ_PERSON_PROFILES', 'content_source_type_sec', l_apps_schema, 'hz_common_pub.content_source_type_security');
    

    /* Commented code for bug 4079902 */   

    /*
    FND_ACCESS_CONTROL_UTIL.ADD_POLICY(l_ar_schema, 'HZ_RELATIONSHIPS', 'content_source_type_sec', l_apps_schema, 'hz_common_pub.content_source_type_security');
     FND_ACCESS_CONTROL_UTIL.ADD_POLICY(l_ar_schema, 'HZ_LOCATIONS', 'content_source_type_sec', l_apps_schema, 'hz_common_pub.content_source_type_security');
     FND_ACCESS_CONTROL_UTIL.ADD_POLICY(l_ar_schema, 'HZ_CONTACT_POINTS', 'content_source_type_sec', l_apps_schema, 'hz_common_pub.content_source_type_security');
     FND_ACCESS_CONTROL_UTIL.ADD_POLICY(l_ar_schema, 'HZ_CREDIT_RATINGS', 'content_source_type_sec', l_apps_schema, 'hz_common_pub.content_source_type_security');
     FND_ACCESS_CONTROL_UTIL.ADD_POLICY(l_ar_schema, 'HZ_FINANCIAL_REPORTS', 'content_source_type_sec', l_apps_schema, 'hz_common_pub.content_source_type_security');
     FND_ACCESS_CONTROL_UTIL.ADD_POLICY(l_ar_schema, 'HZ_FINANCIAL_NUMBERS', 'content_source_type_sec', l_apps_schema, 'hz_common_pub.content_source_type_security');
     FND_ACCESS_CONTROL_UTIL.ADD_POLICY(l_ar_schema, 'HZ_CODE_ASSIGNMENTS', 'content_source_type_sec', l_apps_schema, 'hz_common_pub.content_source_type_security');
     FND_ACCESS_CONTROL_UTIL.ADD_POLICY(l_ar_schema, 'HZ_ORGANIZATION_INDICATORS', 'content_source_type_sec', l_apps_schema, 'hz_common_pub.content_source_type_security');
     FND_ACCESS_CONTROL_UTIL.ADD_POLICY(l_ar_schema, 'HZ_PARTY_SITES', 'content_source_type_sec', l_apps_schema, 'hz_common_pub.content_source_type_security');
     */


  -- Code added for Bug 4079902. 

  l_result := FND_PROFILE.SAVE('HZ_DNB_POLICY_EXIST','Y','SITE');
  
  IF NOT l_result THEN
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
  END IF;


  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:add_policy()-',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
    END IF;

END add_policy;



/********************************************************************************
 *
 * ident_dup_within_int:
 * 1. Identify dup relationships within relationship interface and contacts
 *    interface tables
 * 2. Identify dup address uses with addr uses interface table
 * 3. Identify dup code assignments
 *
 ********************************************************************************/

PROCEDURE ident_dup_within_int (
  P_BATCH_ID                   IN       NUMBER
  ,P_OS                        IN       VARCHAR2
  ,P_BATCH_MODE_FLAG        IN       VARCHAR2
  ,P_REQUEST_ID             IN       NUMBER
  ,P_SYSDATE             IN       DATE
  ,P_USER_ID             IN       NUMBER
  ,P_LAST_UPDATE_LOGIN         IN       NUMBER
  ,P_PROGRAM_APP_ID         IN       NUMBER
  ,P_PROGRAM_ID             IN       NUMBER
) IS

l_int_row_id T_ROWID;
l_err T_ERROR;
l_err_id T_ERROR_ID;
l_table_name T_TABLE_NAME;
--l_debug_prefix  VARCHAR2(30):= '';

CURSOR dup_rel (p_batch_id NUMBER, p_batch_mode_flag VARCHAR2) IS
 select int_row_id, table_name, hz_imp_errors_s.nextval
   from (
       select /*+ ordered  parallel(r) use_hash(r) */
            table_name, int_row_id, lead(sd,1) over (partition by
            decode(t.direction_code, 'C', obj_id, sub_id),
            decode(t.direction_code, 'C', sub_id, obj_id),
            decode(t.direction_code, 'C', t.backward_rel_code, rc),
                t.subject_type, t.object_type  /* Fix 3931139 */
            order by sd, ed) lsd, sub_id, obj_id, rc, sd, ed,
            t.subject_type, t.object_type
       from hz_relationship_types t,
       (
            select /*+ parallel(s) */ sub_id, obj_id, int_row_id,
                   nvl(start_date, sysdate) sd, nvl(end_date,
                   to_date('31-12-4712 00:00:01', 'DD-MM-YYYY HH24:MI:SS'))
                   ed, relationship_code rc, relationship_type rt,
                   'HZ_IMP_RELSHIPS_INT' table_name
            from hz_imp_relships_sg s
         where batch_id = p_batch_id
            and batch_mode_flag = p_batch_mode_flag
            and action_flag = 'I'
            union all
            select /*+ parallel(s) */ sub_id, obj_id, int_row_id,
                  nvl(start_date, sysdate) sd, nvl(end_date,
                  to_date('31-12-4712 00:00:01', 'DD-MM-YYYY HH24:MI:SS'))
                  ed, relationship_code rc, relationship_type rt,
                  'HZ_IMP_CONTACTS_INT' table_name
            from hz_imp_contacts_sg s
         where batch_id = p_batch_id
            and batch_mode_flag = p_batch_mode_flag
            and action_flag = 'I'
       ) r
       where t.forward_rel_code = r.rc
       and t.relationship_type = r.rt)
   where lsd < ed
   and exists (
       select /*+ index(p, HZ_PARTIES_U1) */ 1
         from hz_parties p
        where subject_type = p.party_type
          and sub_id = p.party_id)
   and exists (
       select /*+ index(p, HZ_PARTIES_U1) */ 1
         from hz_parties p
        where object_type = p.party_type
          and obj_id = p.party_id);

/* Combination of party_site_id and site_use_type is unique.
   Order by 's.primary_flag desc' such that primary address uses will not
   be marked as duplicate and leave a non-primary one there */
CURSOR dup_addr_uses (p_batch_id NUMBER, p_batch_mode_flag VARCHAR2) IS
  select int_row_id, hz_imp_errors_s.NextVal from (
    select /*+ parallel(s) */ party_site_use_id suid, party_site_id sid,
      site_use_type sut, int_row_id, lead(party_site_id, 1) over(
      partition by site_use_type order by primary_flag desc) n_sid
      from hz_imp_addressuses_sg s
      where s.batch_id = p_batch_id
      and s.batch_mode_flag = p_batch_mode_flag
      and s.action_flag = 'I'
  ) r
  where sid = n_sid;


/* There should not be overlapping assignment for the same
party and same classification (class category / class code)
within the same content source type */
CURSOR dup_code_assignments (p_batch_id NUMBER, p_batch_mode_flag VARCHAR2) IS
  select int_row_id, decode(allow_multi_assign_flag, 'N', 'M', 'E'), hz_imp_errors_s.NextVal from (
       select /*+ parallel(s) */
              s.int_row_id, s.party_id, s.party_orig_system_reference,
              s.primary_flag, s.start_date_active, s.end_date_active,
              lead(s.start_date_active, 1) over(partition by s.party_id,
              s.class_category, s.class_code order by s.start_date_active,
              s.end_date_active nulls last, s.primary_flag desc) lsd1,
              lead(s.start_date_active, 1) over(partition by s.party_id,
              s.class_category order by s.start_date_active,
              s.end_date_active nulls last, s.primary_flag desc) lsd2,
              c_cat.allow_multi_assign_flag
         from hz_imp_classifics_sg s,
              hz_class_categories c_cat,
              hz_imp_classifics_int c_int
        where s.batch_id = p_batch_id
          and s.batch_mode_flag = p_batch_mode_flag
          and s.action_flag = 'I'
          and c_cat.class_category = s.class_category
        and ( c_int.INTERFACE_STATUS is null  OR
               (c_int.INTERFACE_STATUS is not null AND c_int.INTERFACE_STATUS <> 'D')
              )
        and c_int.rowid = s.int_row_id )
 where decode(allow_multi_assign_flag, 'N', lsd2, lsd1) < nvl(end_date_active,
       to_date('31-12-4712 00:00:01', 'DD-MM-YYYY HH24:MI:SS'));



BEGIN

  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:ident_dup_within_int()+',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
  END IF;

  /* Check dup relationships */
  OPEN dup_rel(P_BATCH_ID, P_BATCH_MODE_FLAG);
  FETCH dup_rel BULK COLLECT INTO l_int_row_id, l_table_name, l_err_id;

  forall j in 1..l_table_name.count
    insert into hz_imp_tmp_errors
    (
   request_id,
   batch_id,
   int_row_id,
   interface_table_name,
   error_id,
   creation_date,
   created_by,
   last_update_date,
   last_updated_by,
   last_update_login,
   program_application_id,
   program_id,
   program_update_date,
   e1_flag,e2_flag,e3_flag,e4_flag,e5_flag,
   e6_flag,e7_flag,e8_flag,e9_flag,e10_flag,
   e11_flag,e12_flag,e13_flag,e14_flag,e15_flag,e16_flag,
   ACTION_MISMATCH_FLAG,
   e38_flag  -- HZ_IMP_DUP_REL_IN_INT_ERROR
    )
    values
    (
      P_REQUEST_ID,
   P_BATCH_ID,
   l_int_row_id(j),
   l_table_name(j),
   l_err_id(j),
   P_SYSDATE,
   P_USER_ID,
   P_SYSDATE,
   P_USER_ID,
   P_LAST_UPDATE_LOGIN,
   P_PROGRAM_APP_ID,
   P_PROGRAM_ID,
   P_SYSDATE,
   'Y','Y','Y','Y','Y',
   'Y','Y','Y','Y','Y',
   'Y','Y','Y','Y','Y','Y',
   'Y',
   'E'
    );


  /* Dup rel may come from HZ_IMP_RELSHIPS_INT or HZ_IMP_CONTACTS_INT.
     So update both tables. Update interface_status to 'E' so that
     these records will not be picked up during V+DML. Error_id column
     in interface table will be updated later when records are
     copied from tmp error table to error table. */
  ForAll j in 1..l_int_row_id.count
    update HZ_IMP_RELSHIPS_INT
    set interface_status = 'E', error_id = l_err_id(j)
    where rowid = l_int_row_id(j)
    and l_table_name(j) = 'HZ_IMP_RELSHIPS_INT';

  ForAll j in 1..l_int_row_id.count
    update HZ_IMP_CONTACTS_INT
    set interface_status = 'E', error_id = l_err_id(j)
    where rowid = l_int_row_id(j)
    and l_table_name(j) = 'HZ_IMP_CONTACTS_INT';

  CLOSE dup_rel;


  /* Check dup address uses */
  OPEN dup_addr_uses(P_BATCH_ID, P_BATCH_MODE_FLAG);
  FETCH dup_addr_uses BULK COLLECT INTO l_int_row_id, l_err_id;

  ForAll j in 1..l_int_row_id.count
    insert into hz_imp_tmp_errors
    (
   request_id,
   batch_id,
   int_row_id,
   interface_table_name,
   error_id,
   creation_date,
   created_by,
   last_update_date,
   last_updated_by,
   last_update_login,
   program_application_id,
   program_id,
   program_update_date,
   e1_flag,e2_flag,e3_flag,ACTION_MISMATCH_FLAG,MISSING_PARENT_FLAG,
   e38_flag  -- HZ_IMP_DUP_ADDRUSE_IN_INT
    )
    values
    (
      P_REQUEST_ID,
   P_BATCH_ID,
   l_int_row_id(j),
   'HZ_IMP_ADDRESSUSES_INT',
   l_err_id(j),
   P_SYSDATE,
   P_USER_ID,
   P_SYSDATE,
   P_USER_ID,
   P_LAST_UPDATE_LOGIN,
   P_PROGRAM_APP_ID,
   P_PROGRAM_ID,
   P_SYSDATE,
   'Y','Y','Y','Y','Y',
   'E'
    );

  ForAll j in 1..l_int_row_id.count
    update HZ_IMP_ADDRESSUSES_INT
    set interface_status = 'E', error_id = l_err_id(j)
    where rowid = l_int_row_id(j);

  CLOSE dup_addr_uses;

  /* Check dup code assignments */
  OPEN dup_code_assignments(P_BATCH_ID, P_BATCH_MODE_FLAG);
  FETCH dup_code_assignments BULK COLLECT INTO l_int_row_id, l_err, l_err_id;

  ForAll j in 1..l_int_row_id.count
    insert into hz_imp_tmp_errors
    (
   request_id,
   batch_id,
   int_row_id,
   interface_table_name,
   error_id,
   creation_date,
   created_by,
   last_update_date,
   last_updated_by,
   last_update_login,
   program_application_id,
   program_id,
   program_update_date,
   e2_flag,e3_flag,e4_flag,e5_flag,
   e6_flag,e7_flag,e8_flag,e9_flag,ACTION_MISMATCH_FLAG,
   e38_flag  -- HZ_IMP_DUP_CLASSIFIC_IN_INT
    )
    values
    (
      P_REQUEST_ID,
   P_BATCH_ID,
   l_int_row_id(j),
   'HZ_IMP_CLASSIFICS_INT',
   l_err_id(j),
   P_SYSDATE,
   P_USER_ID,
   P_SYSDATE,
   P_USER_ID,
   P_LAST_UPDATE_LOGIN,
   P_PROGRAM_APP_ID,
   P_PROGRAM_ID,
   P_SYSDATE,
   'Y','Y','Y','Y',
   'Y','Y','Y','Y','Y',
   l_err(j)
    );

  ForAll j in 1..l_int_row_id.count
    update HZ_IMP_CLASSIFICS_INT
    set interface_status = 'E', error_id = l_err_id(j)
    where rowid = l_int_row_id(j);

  CLOSE dup_code_assignments;
  
  IF P_OS = 'DNB' THEN
  insert into hz_imp_tmp_rel_end_date(batch_id, sub_orig_system_reference, relationship_id, directional_flag, int_row_id,
                 creation_date, created_by, last_update_date, last_updated_by)
  SELECT     /*+ parallel(rs) parallel(r) full(rs) leading(rs) use_nl(r) */
           P_BATCH_ID, rs.sub_orig_system_reference, r.relationship_id,
           r.directional_flag,  rs.int_row_id int_row_id,
           P_SYSDATE, P_USER_ID, P_SYSDATE, P_USER_ID
  FROM hz_imp_relships_sg rs,
       hz_relationships r
  WHERE rs.batch_id=P_BATCH_ID
  AND rs.sub_orig_system = P_OS
  AND rs.batch_mode_flag = P_BATCH_MODE_FLAG
  AND rs.action_flag = 'I'
  AND rs.relationship_type in ('HEADQUARTERS/DIVISION', 'PARENT/SUBSIDIARY','DOMESTIC_ULTIMATE','GLOBAL_ULTIMATE')
  AND r.relationship_type in ('HEADQUARTERS/DIVISION', 'PARENT/SUBSIDIARY','DOMESTIC_ULTIMATE','GLOBAL_ULTIMATE')
  AND rs.obj_id=r.object_id
  AND decode(r.relationship_type,'PARENT/SUBSIDIARY','HEADQUARTERS/DIVISION',r.relationship_type)
     =decode(rs.relationship_type,'PARENT/SUBSIDIARY','HEADQUARTERS/DIVISION',rs.relationship_type)
  AND decode(r.relationship_code,'PARENT_OF','HEADQUARTERS_OF',r.relationship_code)
     =decode(rs.relationship_code,'PARENT_OF','HEADQUARTERS_OF',rs.relationship_code)
  AND r.subject_table_name='HZ_PARTIES'
  AND r.object_table_name='HZ_PARTIES'
  AND r.object_type='ORGANIZATION'
  AND r.status='A'
  AND P_SYSDATE > r.start_date
  AND P_SYSDATE <= nvl(r.end_date, TO_DATE('31-12-4712 00:00:01', 'DD-MM-YYYY HH24:MI:SS'))
  AND r.actual_content_source='DNB';

  insert into hz_imp_tmp_rel_end_date(batch_id, sub_orig_system_reference, relationship_id, directional_flag, int_row_id,
                        creation_date, created_by, last_update_date, last_updated_by)
  SELECT batch_id, sub_orig_system_reference, relationship_id, decode(directional_flag,'B','F','F','B'), int_row_id,
         creation_date, created_by, last_update_date, last_updated_by
  FROM hz_imp_tmp_rel_end_date WHERE batch_id=P_BATCH_ID;
  END IF;

  /* Records in hz_tmp_errors for global validations will be ignored when
     copy from tmp error to permanent error table. Insert into tmp errors table
     for keeping error count. */
  insert into hz_imp_errors (
    error_id, batch_id, request_id, interface_table_name, message_name
  )
  select error_id, batch_id, request_id, interface_table_name,
    decode(interface_table_name, 'HZ_IMP_RELSHIPS_INT', 'HZ_IMP_DUP_REL_IN_INT_ERROR',
    'HZ_IMP_CONTACTS_INT', 'HZ_IMP_DUP_REL_IN_INT_ERROR',
    'HZ_IMP_ADDRESSUSES_INT', 'HZ_IMP_DUP_ADDRUSE_IN_INT',
    'HZ_IMP_CLASSIFICS_INT', decode(e38_flag, 'M', 'HZ_API_ALLOW_MUL_ASSIGN_FG',
    'HZ_IMP_DUP_CLASSIFIC_IN_INT')
    )
  from hz_imp_tmp_errors
  where batch_id = P_BATCH_ID
  and request_id = P_REQUEST_ID
  and interface_table_name in ('HZ_IMP_RELSHIPS_INT', 'HZ_IMP_CONTACTS_INT',
    'HZ_IMP_ADDRESSUSES_INT', 'HZ_IMP_CLASSIFICS_INT');

  COMMIT;
  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:ident_dup_within_int()-',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
  END IF;

END ident_dup_within_int;


PROCEDURE update_import_status(
  P_BATCH_ID   IN NUMBER,
  P_STATUS  IN VARCHAR2
) IS
  l_detail_import_status VARCHAR2(30);
  l_batch_import_status VARCHAR2(30);
BEGIN


  IF P_STATUS = 'COMPL_ERRORS2' THEN
    l_detail_import_status := 'COMPLETED';
    l_batch_import_status := 'COMPL_ERRORS';
  ELSE
    l_detail_import_status := P_STATUS;
    l_batch_import_status := P_STATUS;
  END IF;

  update hz_imp_batch_summary
  set import_status = l_batch_import_status,
      import_req_id = hz_utility_v2pub.request_id
  where batch_id = P_BATCH_ID;

  update hz_imp_batch_details
  set import_status = l_detail_import_status,
      import_req_id = hz_utility_v2pub.request_id
  where batch_id = P_BATCH_ID
  and run_number = (select max(run_number)
                  from hz_imp_batch_details
          where batch_id = P_BATCH_ID);

  COMMIT;

END update_import_status;


PROCEDURE ALTER_SEQUENCES(
  P_OPERATION     IN VARCHAR2,  /* I - increase, R - restore */
  P_BATCH_MODE_FLAG     IN      VARCHAR2
) IS
l_running_dl_wrapper VARCHAR2(1);
CURSOR c_running_dl_wrapper IS
  select 'Y' from fnd_conc_req_summary_v
  where program_short_name like 'ARHLWRPB'
  and phase_code <> 'C'
  and rownum = 1;

l_bool BOOLEAN;
l_status VARCHAR2(255);
l_schema VARCHAR2(255);
l_tmp    VARCHAR2(2000);
--l_debug_prefix  VARCHAR2(30) := '';
BEGIN


  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:ALTER_SEQUENCES()+',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
  END IF;

  l_bool := fnd_installation.GET_APP_INFO('AR',l_status,l_tmp,l_schema);

  IF P_OPERATION = 'I' THEN
    /* Increase increment for muti-table insert for parties */
    execute immediate 'alter sequence ' || l_schema || '.hz_organization_profiles_s increment by 3';
    execute immediate 'alter sequence ' || l_schema || '.hz_person_profiles_s increment by 3';
    execute immediate 'alter sequence ' || l_schema || '.hz_location_profiles_s increment by 2';

    /* Alter sequence only for batch mode */
    /* Wallace: remove alter cache size to be compilant with standard.
                alter cache size before run instead
    IF P_BATCH_MODE_FLAG = 'Y' THEN
   execute immediate 'alter sequence ' || l_schema || '.hz_code_assignments_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_contact_numbers_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_contact_points_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_credit_ratings_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_financial_numbers_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_financial_reports_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_imp_errors_s cache 20000';
   execute immediate 'alter sequence hr.hr_locations_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_location_profiles_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_organization_profiles_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_org_contacts_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_org_contact_roles_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_orig_system_ref_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_parties_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_party_number_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_party_sites_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_party_site_number_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_party_site_uses_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_person_profiles_s cache 20000';
   execute immediate 'alter sequence ' || l_schema || '.hz_relationships_s cache 20000';
    END IF;
    */
  ELSE

    /* Check if any outstanding data load concurrent req. If so, do not reset */
    open c_running_dl_wrapper;
    fetch c_running_dl_wrapper into l_running_dl_wrapper;
    IF l_running_dl_wrapper is null THEN
   execute immediate 'alter sequence ' || l_schema || '.hz_organization_profiles_s increment by 1';
   execute immediate 'alter sequence ' || l_schema || '.hz_person_profiles_s increment by 1';
   execute immediate 'alter sequence ' || l_schema || '.hz_location_profiles_s increment by 1';
    END IF;
    close c_running_dl_wrapper;

    /*
    IF P_BATCH_MODE_FLAG = 'Y' THEN
   execute immediate 'alter sequence ' || l_schema || '.hz_code_assignments_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_contact_numbers_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_contact_points_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_credit_ratings_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_financial_numbers_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_financial_reports_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_imp_errors_s cache 20';
   execute immediate 'alter sequence hr.hr_locations_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_location_profiles_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_organization_profiles_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_org_contacts_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_org_contact_roles_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_orig_system_ref_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_parties_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_party_number_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_party_sites_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_party_site_number_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_party_site_uses_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_person_profiles_s cache 20';
   execute immediate 'alter sequence ' || l_schema || '.hz_relationships_s cache 20';
    END IF;
    */
  END IF;
  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:ALTER_SEQUENCES()-',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
  END IF;

END ALTER_SEQUENCES;


/* Clean up staging. Delete for online, truncate for batch */
/* Also chean up the following tables:  */
/*     hz_imp_osr_change                */
/*     HZ_IMP_INT_DEDUP_RESULTS         */
/*     HZ_IMP_TMP_REL_END_DATE          */
PROCEDURE CLEANUP_STAGING(
  P_BATCH_ID         IN NUMBER,
  P_BATCH_MODE_FLAG  IN VARCHAR2
) IS
l_bool BOOLEAN;
l_status VARCHAR2(255);
l_schema VARCHAR2(255);
l_tmp    VARCHAR2(2000);
--l_debug_prefix  VARCHAR2(30) := '';
BEGIN

  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:CLEANUP_STAGING()+',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
  END IF;

  l_bool := fnd_installation.GET_APP_INFO('AR',l_status,l_tmp,l_schema);

  IF P_BATCH_MODE_FLAG = 'Y' THEN
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_PARTIES_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_ADDRESSES_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_CONTACTPTS_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_CREDITRTNGS_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_CLASSIFICS_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_FINREPORTS_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_FINNUMBERS_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_RELSHIPS_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_CONTACTS_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_CONTACTROLES_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_ADDRESSUSES_SG TRUNCATE PARTITION batchpar DROP STORAGE';

  ELSE
    DELETE HZ_IMP_PARTIES_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_ADDRESSES_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_CONTACTPTS_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_CREDITRTNGS_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_CLASSIFICS_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_FINREPORTS_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_FINNUMBERS_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_RELSHIPS_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_CONTACTS_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_CONTACTROLES_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_ADDRESSUSES_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;

  END IF;

  DELETE hz_imp_osr_change WHERE batch_id = P_BATCH_ID;
  --DELETE HZ_IMP_INT_DEDUP_RESULTS WHERE batch_id = P_BATCH_ID;
  DELETE HZ_IMP_TMP_REL_END_DATE WHERE batch_id = P_BATCH_ID;
  
  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:CLEANUP_STAGING()-',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
  END IF;

END CLEANUP_STAGING;


/* Fix bug 4398179: Clean up the SSM table to remove any active duplicate 
   records that have the same OS+OSR. Duplicates are created as the fix for
   4398179 will allow multiple rows in party interface with same OS+OSR but
   different party_id to be imported. In parties loading, since we'll check
   for existence of OS+OSR in SSM table to decide if we'll insert new records,
   if it's new DNB purchase for two existing parties, duplicate SSM records 
   can be created */
PROCEDURE CLEANUP_SSM(
  P_CONTENT_SRC_TYPE  IN VARCHAR2,
  P_BATCH_ID          IN NUMBER,
  P_BATCH_MODE_FLAG   IN VARCHAR2,
  P_ORIG_SYSTEM       IN VARCHAR2,
  P_REQUEST_ID        IN NUMBER
) IS  

    l_cleanup_ssm_site_qry VARCHAR2(4000) :=
    ' SELECT psosr.rowid,posr.owner_table_id
      FROM HZ_IMP_ADDRESSES_SG  site_sg,
           HZ_ORIG_SYS_REFERENCES posr,
           HZ_ORIG_SYS_REFERENCES psosr
      WHERE site_sg.batch_id = :CP_BATCH_ID
      AND site_sg.batch_mode_flag = :CP_BATCH_MODE_FLAG
      AND site_sg.party_orig_system = :CP_OS
      AND posr.orig_system  = site_sg.party_orig_system
      AND posr.orig_system_reference = site_sg.party_orig_system_reference
      AND posr.status  = ''A''
      AND posr.owner_table_name  = ''HZ_PARTIES''
      AND psosr.orig_system  = site_sg.site_orig_system
      AND psosr.orig_system_reference = site_sg.site_orig_system_reference
      AND psosr.status  = ''A''
      AND psosr.owner_table_name  = ''HZ_PARTY_SITES''
      AND psosr.owner_table_id = site_sg.party_site_id
      AND psosr.party_id <> posr.owner_table_id
      AND NOT EXISTS
          (SELECT 1 FROM HZ_IMP_TMP_ERRORS err
           WHERE err.batch_id = :CP_BATCH_ID
           AND err.request_id = :REQ_ID
           AND err.interface_table_name = ''HZ_IMP_ADDRESSES_INT''
           AND err.int_row_id = site_sg.int_row_id)
      ';

    l_cleanup_ssm_cpt_qry VARCHAR2(4000) :=
    ' SELECT cposr.rowid,posr.owner_table_id
      FROM HZ_IMP_CONTACTPTS_SG  cpt_sg,HZ_IMP_CONTACTPTS_INT cpi,
           HZ_ORIG_SYS_REFERENCES posr,
           HZ_ORIG_SYS_REFERENCES cposr
      WHERE cpt_sg.batch_id = :CP_BATCH_ID
      AND cpt_sg.batch_mode_flag = :CP_BATCH_MODE_FLAG
      AND cpt_sg.party_orig_system = :CP_OS
      AND posr.orig_system  = cpt_sg.party_orig_system
      AND posr.orig_system_reference = cpt_sg.party_orig_system_reference
      AND posr.status  = ''A''
      AND posr.owner_table_name  = ''HZ_PARTIES''
      AND cposr.orig_system  = cpi.cp_orig_system
      AND cposr.orig_system_reference = cpi.cp_orig_system_reference
      AND cposr.status  = ''A''
      AND cposr.owner_table_name  = ''HZ_CONTACT_POINTS''
      AND cposr.party_id <> posr.owner_table_id
      AND cpi.rowid = cpt_sg.int_row_id
      AND NOT EXISTS
          (SELECT 1 FROM HZ_IMP_TMP_ERRORS err
           WHERE err.batch_id = :CP_BATCH_ID
           AND err.request_id = :REQ_ID
           AND err.interface_table_name = ''HZ_IMP_CONTACTPTS_INT''
           AND err.int_row_id = cpt_sg.int_row_id)
      ';
    
    c_cleanup_ssm_pid  cleanup_ssm_pid_csr_type;
 
BEGIN
    update hz_orig_sys_references set status = 'I', end_date_active = sysdate
    where rowid in ( 
    select row_id from (
      select /*+ parallel(osr 8) */ rowid row_id, orig_system_ref_id osrid, orig_system_reference osr,
      owner_table_name, rank() over 
      (partition by orig_system_reference, owner_table_name order by last_update_date desc, orig_system_ref_id desc) rn
      from hz_orig_sys_references osr
      where osr.orig_system = P_CONTENT_SRC_TYPE 
      and osr.status = 'A'
      and osr.end_date_active is null
    ) r
    where rn > 1);    

      -- Set the HZ_ORIG_SYS_REFERENCES.party_id of party site to be the current
      -- active party in SSM
      l_last_fetch := FALSE;

      OPEN c_cleanup_ssm_pid FOR l_cleanup_ssm_site_qry
      USING P_batch_id,P_batch_mode_flag, P_ORIG_SYSTEM,P_batch_id,P_REQUEST_ID ;
      LOOP 
        FETCH c_cleanup_ssm_pid BULK COLLECT INTO l_row_id ,l_party_owner_table_id LIMIT l_rows;
        IF c_cleanup_ssm_pid%NOTFOUND THEN
          l_last_fetch := TRUE;
        END IF;
        IF l_row_id.COUNT = 0 AND l_last_fetch THEN
          EXIT;
        END IF;
  
        FORALL j IN  l_row_id.FIRST.. l_row_id.LAST
          UPDATE HZ_ORIG_SYS_REFERENCES
            SET party_id = l_party_owner_table_id(j)
            WHERE rowid = l_row_id(j);
     
        IF l_last_fetch = TRUE THEN
          EXIT;
        END IF;
      END LOOP;  
      CLOSE c_cleanup_ssm_pid;

      -- Set the HZ_ORIG_SYS_REFERENCES.party_id of contact point to be the current
      -- active party in SSM
      l_last_fetch := FALSE;
      OPEN c_cleanup_ssm_pid FOR l_cleanup_ssm_cpt_qry
      USING P_batch_id,P_batch_mode_flag, P_ORIG_SYSTEM,P_batch_id,P_REQUEST_ID  ;

      LOOP 
        FETCH c_cleanup_ssm_pid BULK COLLECT INTO l_row_id ,l_party_owner_table_id LIMIT l_rows;
        IF c_cleanup_ssm_pid%NOTFOUND THEN
          l_last_fetch := TRUE;
        END IF;
        IF l_row_id.COUNT = 0 AND l_last_fetch THEN
          EXIT;
        END IF;
  
        FORALL j IN  l_row_id.FIRST.. l_row_id.LAST
          UPDATE HZ_ORIG_SYS_REFERENCES
           SET party_id = l_party_owner_table_id(j)
           WHERE rowid = l_row_id(j);
     
        IF l_last_fetch = TRUE THEN
          EXIT;
        END IF;
      END LOOP;  
      CLOSE c_cleanup_ssm_pid;
    
END CLEANUP_SSM;


PROCEDURE CLEANUP_DUP_OSR(
  P_BATCH_ID IN NUMBER,
  P_BATCH_MODE_FLAG IN VARCHAR2,
  P_ENTITY IN VARCHAR2,
  P_PARTY_OS IN VARCHAR2)
IS

 TYPE L_ROWIDList IS TABLE OF HZ_IMP_PARTIES_SG.INT_ROW_ID%TYPE;
 TYPE L_PIDList IS TABLE OF HZ_IMP_PARTIES_SG.PARTY_ID%TYPE;
 TYPE L_POSList IS TABLE OF HZ_IMP_PARTIES_SG.PARTY_ORIG_SYSTEM%TYPE;
 TYPE L_POSRList IS TABLE OF HZ_IMP_PARTIES_SG.PARTY_ORIG_SYSTEM_REFERENCE%TYPE;

       l_rowid       L_ROWIDList;
       l_pid       L_PIDList;
       l_pos         L_POSList;
       l_posr        L_POSRList;    
      
 TYPE L_PSOSList IS TABLE OF hz_imp_addresses_sg.SITE_ORIG_SYSTEM%TYPE;
 TYPE L_PSOSRList IS TABLE OF hz_imp_addresses_sg.SITE_ORIG_SYSTEM_REFERENCE%TYPE;
       l_psos         L_PSOSList;
       l_psosr        L_PSOSRList;    
         

 rows NUMBER;
 l_last_fetch BOOLEAN;
 I NUMBER;

 CURSOR c_parties IS 
 SELECT ROW_ID,party_id,party_os, party_osr
 FROM
 (  SELECT int_row_id row_id,party_id,PARTY_ORIG_SYSTEM party_os,PARTY_ORIG_SYSTEM_REFERENCE party_osr
    ,row_number() over (partition by party_id order by int_row_id) rn
    from hz_imp_parties_sg
    where batch_id=P_BATCH_ID
    and batch_mode_flag=P_BATCH_MODE_FLAG
    and party_orig_system = P_PARTY_OS
    and action_flag='U' 
 )
 WHERE rn>1;

 CURSOR c_parties_d IS 
  SELECT pint.party_orig_system, pint.party_orig_system_reference,psg.party_id
  FROM hz_imp_parties_int pint, hz_imp_parties_sg psg
  WHERE pint.batch_id=P_BATCH_ID
  AND pint.party_orig_system=P_PARTY_OS  
  AND pint.interface_status='D'
  AND Pint.rowid=psg.int_row_id
  AND pint.party_orig_system=psg.party_orig_system
  AND pint.party_orig_system_reference=psg.party_orig_system_reference
  AND psg.batch_mode_flag=P_BATCH_MODE_FLAG
  AND psg.action_flag='U' 
  ;
 
 CURSOR c_addresses IS 
 SELECT ROW_ID,site_os, site_osr
 FROM
 (  SELECT int_row_id row_id,SITE_ORIG_SYSTEM site_os,SITE_ORIG_SYSTEM_REFERENCE site_osr
    ,row_number() over 
    (partition by party_site_id order by int_row_id) rn
    from hz_imp_addresses_sg
    where batch_id=P_BATCH_ID
    and party_orig_system = P_PARTY_OS
    and action_flag = 'U'
 )
 WHERE rn>1;

BEGIN

  rows := 10000;
  l_last_fetch:= FALSE;

  IF P_ENTITY='PARTY'
  THEN
    OPEN c_parties;
       LOOP
       FETCH c_parties BULK COLLECT INTO
             l_rowid, l_pid, l_pos, l_posr
       LIMIT rows;

       IF c_parties%NOTFOUND THEN
          l_last_fetch := TRUE ;
       END IF;

       IF l_rowid.COUNT = 0 AND l_last_fetch = TRUE THEN
          EXIT;
       END IF;

       FORALL i in l_rowid.FIRST..l_rowid.LAST
       UPDATE HZ_IMP_PARTIES_INT party
       SET INTERFACE_STATUS = 'D'
       WHERE rowid=l_rowid(i) ;
       
       IF l_last_fetch = TRUE THEN
          EXIT;
       END IF;

       END LOOP;
    CLOSE c_parties;
  ELSIF P_ENTITY='ADDRESS'
  THEN
    OPEN c_addresses;
       LOOP
       FETCH c_addresses BULK COLLECT INTO
             l_rowid, l_psos, l_psosr
       LIMIT rows;
  

       IF c_addresses%NOTFOUND THEN
          l_last_fetch := TRUE ;
       END IF;

       IF l_rowid.COUNT = 0 AND l_last_fetch = TRUE THEN
          EXIT;
       END IF;

       FORALL i in l_rowid.FIRST..l_rowid.LAST
       UPDATE HZ_IMP_ADDRESSES_INT party
       SET INTERFACE_STATUS = 'D'
       WHERE rowid=l_rowid(i);

       --Update child entities
       --Update site uses
       FORALL i in l_psosr.FIRST..l_psosr.LAST
               UPDATE HZ_IMP_ADDRESSUSES_INT
               SET interface_status = 'D'
               WHERE batch_id = p_batch_id
               AND site_orig_system = l_psos(i)
               AND site_orig_system_reference = l_psosr(i);
       
       IF l_last_fetch = TRUE THEN
          EXIT;
       END IF;

       END LOOP;
       CLOSE c_addresses;

     OPEN c_parties_d;
       LOOP
       FETCH c_parties_d BULK COLLECT INTO
             l_pos, l_posr, l_pid
       LIMIT rows;

       IF c_parties_d%NOTFOUND THEN
          l_last_fetch := TRUE ;
       END IF;

       IF l_pid.COUNT = 0 AND l_last_fetch = TRUE THEN
          EXIT;
       END IF;

       -- Update child entities
       --Update contact records
       FORALL i in l_posr.FIRST..l_posr.LAST
               UPDATE HZ_IMP_CONTACTS_INT
               SET interface_status = 'D'
               WHERE batch_id = p_batch_id 
               AND ((sub_orig_system = l_pos(i)
                    AND sub_orig_system_reference = l_posr(i))
          OR
          (obj_orig_system = l_pos(i)
           AND obj_orig_system_reference = l_posr(i))
         );
       --Update contact roles
       FORALL i in l_posr.FIRST..l_posr.LAST
              UPDATE HZ_IMP_CONTACTROLES_INT
              SET interface_status = 'D'
              WHERE batch_id = p_batch_id
              AND sub_orig_system = l_pos(i)
              AND sub_orig_system_reference = l_posr(i);
         
       -- Update contact point records
       FORALL i in l_posr.FIRST..l_posr.LAST
               UPDATE HZ_IMP_CONTACTPTS_INT
               SET interface_status = 'D'
               WHERE batch_id = p_batch_id AND Nvl(party_id,l_pid(i)) = l_pid(i)
               AND party_orig_system = l_pos(i)
               AND party_orig_system_reference = l_posr(i);

       -- Update relationship records
       FORALL i in l_posr.FIRST..l_posr.LAST
               UPDATE HZ_IMP_RELSHIPS_INT
               SET interface_status = 'D'
               WHERE batch_id = p_batch_id
               AND ((sub_orig_system = l_pos(i)
                    AND sub_orig_system_reference = l_posr(i))
          OR
          (obj_orig_system = l_pos(i)
           AND obj_orig_system_reference = l_posr(i)
          AND Nvl(obj_id,l_pid(i)) = l_pid(i))
         );

       --Update Classifications
       FORALL i in l_posr.FIRST..l_posr.LAST
               UPDATE HZ_IMP_CLASSIFICS_INT
               SET interface_status = 'D'
               WHERE batch_id = p_batch_id AND Nvl(party_id,l_pid(i)) = l_pid(i)
               AND party_orig_system = l_pos(i)
               AND party_orig_system_reference = l_posr(i);

       --Update Credit Ratings
       FORALL i in l_posr.FIRST..l_posr.LAST
               UPDATE HZ_IMP_CREDITRTNGS_INT
               SET interface_status = 'D' 
               WHERE batch_id = p_batch_id AND Nvl(party_id,l_pid(i)) = l_pid(i)
               AND party_orig_system = l_pos(i)
               AND party_orig_system_reference = l_posr(i);

       --Update Financial Numbers
       FORALL i in l_posr.FIRST..l_posr.LAST
               UPDATE HZ_IMP_FINNUMBERS_INT
               SET interface_status = 'D'
               WHERE batch_id = p_batch_id AND Nvl(party_id,l_pid(i)) = l_pid(i)
               AND party_orig_system = l_pos(i)
               AND party_orig_system_reference = l_posr(i);

       --Update Financial Reports
       FORALL i in l_posr.FIRST..l_posr.LAST
               UPDATE HZ_IMP_FINREPORTS_INT
               SET interface_status = 'D'
               WHERE batch_id = p_batch_id AND Nvl(party_id,l_pid(i)) = l_pid(i)
               AND party_orig_system = l_pos(i)
               AND party_orig_system_reference = l_posr(i);

       IF l_last_fetch = TRUE THEN
          EXIT;
       END IF;
     END LOOP;
     CLOSE c_parties_d;   
   END IF;
END CLEANUP_DUP_OSR; 


PROCEDURE UPDATE_DISPLAYED_DUNS_PID(
  P_BATCH_ID                      IN NUMBER,
  P_BATCH_MODE_FLAG               IN VARCHAR2
) IS
l_party_id T_ENTITY_ID;
l_displayed_duns_party_id T_ENTITY_ID;

CURSOR c_displayed_duns(p_batch_id number, p_batch_mode_flag varchar2) IS
  select /*+ parallel(pi) leading (pi) use_nl(ps) use_nl(osr) */
        ps.party_id, osr.owner_table_id displayed_duns_party_id
  from hz_orig_sys_references osr,
        hz_imp_parties_int pi,
        hz_imp_parties_sg ps
  where osr.owner_table_name = 'HZ_PARTIES'
    and osr.orig_system = 'DNB'
    and osr.orig_system_reference = pi.displayed_duns
    and pi.batch_id = p_batch_id
    and pi.party_orig_system = 'DNB'
    and pi.rowid = ps.int_row_id
    and ps.batch_mode_flag = p_batch_mode_flag
    and pi.batch_id = ps.batch_id
    and pi.party_orig_system = ps.party_orig_system
    and pi.party_orig_system_reference = ps.party_orig_system_reference
    and pi.party_orig_system_reference <> pi.displayed_duns;

 --l_debug_prefix    VARCHAR2(30) := '';
BEGIN

  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:UPDATE_DISPLAYED_DUNS_PID()+',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
  END IF;

  hz_common_pub.disable_cont_source_security;

  OPEN c_displayed_duns(P_BATCH_ID, P_BATCH_MODE_FLAG);
  FETCH c_displayed_duns BULK COLLECT INTO
  l_party_id, l_displayed_duns_party_id;

  ForAll j in 1..l_party_id.count
    update hz_organization_profiles
    set displayed_duns_party_id = l_displayed_duns_party_id(j)
    where party_id = l_party_id(j)
    and effective_end_date is null
    and actual_content_source = 'DNB';

  CLOSE c_displayed_duns;

  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:UPDATE_DISPLAYED_DUNS_PID()-',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
  END IF;

END UPDATE_DISPLAYED_DUNS_PID;


PROCEDURE GENERATE_ERRORS (
  P_BATCH_ID                      IN NUMBER,
  P_REQUEST_ID                    IN NUMBER,
  P_ORIG_SYSTEM                   IN VARCHAR2,
  P_RERUN_FLAG                    IN VARCHAR2,
  P_END_OF_DL_FLAG                IN VARCHAR2
) IS

  CURSOR c_err(p_batch_id number, p_request_id number) IS
    select int_row_id, interface_table_name, error_id
    from hz_imp_tmp_errors
    where batch_id = p_batch_id
    and request_id = p_request_id;

  l_row_id T_ROWID;
  l_error_id T_ERROR_ID;
  l_table_name T_TABLE_NAME;

  -- Bug 3871136
  l_dss_person_err VARCHAR2(2000) := hz_dss_util_pub.get_display_name(null,'PERSON');
  l_dss_org_err    VARCHAR2(2000) := hz_dss_util_pub.get_display_name(null,'ORGANIZATION');
  l_dss_others_err VARCHAR2(2000) := hz_dss_util_pub.get_display_name('HZ_PARTIES',null);
  l_dss_rel_err    VARCHAR2(2000) := hz_dss_util_pub.get_display_name('HZ_RELATIONSHIPS',null);
  l_dss_ca_err     VARCHAR2(2000) := hz_dss_util_pub.get_display_name('HZ_CODE_ASSIGNMENTS',null);
  l_dss_cp_err     VARCHAR2(2000) := hz_dss_util_pub.get_display_name(null,'PARTY_CONTACT_POINTS');
  l_dss_ps_err     VARCHAR2(2000) := hz_dss_util_pub.get_display_name(null,'PARTY_SITE_CONTACT_POINTS');

  --l_debug_prefix  VARCHAR2(30) := '';
BEGIN
  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:GENERATE_ERRORS()+',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
  END IF;

  /* If not a new batch, clear all 'C' interface_status */
  IF P_RERUN_FLAG <> 'N' THEN

    IF P_END_OF_DL_FLAG = 'Y' THEN

      update HZ_IMP_PARTIES_INT
      set error_id = null,
          interface_status = null
      where BATCH_ID = P_BATCH_ID
      and PARTY_ORIG_SYSTEM = P_ORIG_SYSTEM
      and INTERFACE_STATUS = 'C';

      update HZ_IMP_ADDRESSES_INT
      set error_id = null,
          interface_status = null
      where BATCH_ID = P_BATCH_ID
      and PARTY_ORIG_SYSTEM = P_ORIG_SYSTEM
      and INTERFACE_STATUS = 'C';

      update HZ_IMP_CONTACTPTS_INT
      set error_id = null,
          interface_status = null
      where BATCH_ID = P_BATCH_ID
      and PARTY_ORIG_SYSTEM = P_ORIG_SYSTEM
      and INTERFACE_STATUS = 'C';

      update HZ_IMP_CREDITRTNGS_INT
      set error_id = null,
          interface_status = null
      where BATCH_ID = P_BATCH_ID
      and PARTY_ORIG_SYSTEM = P_ORIG_SYSTEM
      and INTERFACE_STATUS = 'C';

      update HZ_IMP_CLASSIFICS_INT
      set error_id = null,
          interface_status = null
      where BATCH_ID = P_BATCH_ID
      and PARTY_ORIG_SYSTEM = P_ORIG_SYSTEM
      and INTERFACE_STATUS = 'C';

      update HZ_IMP_FINREPORTS_INT
      set error_id = null,
          interface_status = null
      where BATCH_ID = P_BATCH_ID
      and PARTY_ORIG_SYSTEM = P_ORIG_SYSTEM
      and INTERFACE_STATUS = 'C';

      update HZ_IMP_FINNUMBERS_INT
      set error_id = null,
          interface_status = null
      where BATCH_ID = P_BATCH_ID
      and PARTY_ORIG_SYSTEM = P_ORIG_SYSTEM
      and INTERFACE_STATUS = 'C';

      update HZ_IMP_RELSHIPS_INT
      set error_id = null,
          interface_status = null
      where BATCH_ID = P_BATCH_ID
      and SUB_ORIG_SYSTEM = P_ORIG_SYSTEM
      and INTERFACE_STATUS = 'C';

      update HZ_IMP_CONTACTS_INT
      set error_id = null,
          interface_status = null
      where BATCH_ID = P_BATCH_ID
      and SUB_ORIG_SYSTEM = P_ORIG_SYSTEM
      and INTERFACE_STATUS = 'C';

      update HZ_IMP_CONTACTROLES_INT
      set error_id = null,
          interface_status = null
      where BATCH_ID = P_BATCH_ID
      and SUB_ORIG_SYSTEM = P_ORIG_SYSTEM
      and INTERFACE_STATUS = 'C';

      update HZ_IMP_ADDRESSUSES_INT
      set error_id = null,
          interface_status = null
      where BATCH_ID = P_BATCH_ID
      and PARTY_ORIG_SYSTEM = P_ORIG_SYSTEM
      and INTERFACE_STATUS = 'C';

    ELSE

      /* Parties are loaded in stage 2. So if work unit is
         completed for either stage 2 or stage 3, it means the
         parties should have been loaded. For other entities,
         only need to check stage 3. */
      update HZ_IMP_PARTIES_INT
      set error_id = null, interface_status = null
      where batch_id = P_BATCH_ID
      and party_orig_system = P_ORIG_SYSTEM
      and interface_status = 'C'
      and exists (
        select 1 from
        hz_imp_work_units
        where party_orig_system_reference
        between from_orig_system_ref and to_orig_system_ref
        and batch_id = P_BATCH_ID
        and stage in (2, 3)
        and status = 'C');

      update HZ_IMP_ADDRESSES_INT
      set error_id = null, interface_status = null
      where batch_id = P_BATCH_ID
      and party_orig_system = P_ORIG_SYSTEM
      and interface_status = 'C'
      and exists (
        select 1 from
        hz_imp_work_units
        where party_orig_system_reference
        between from_orig_system_ref and to_orig_system_ref
        and batch_id = P_BATCH_ID
        and stage = 3
        and status = 'C');

      update HZ_IMP_CONTACTPTS_INT
      set error_id = null, interface_status = null
      where batch_id = P_BATCH_ID
      and party_orig_system = P_ORIG_SYSTEM
      and interface_status = 'C'
      and exists (
        select 1 from
        hz_imp_work_units
        where party_orig_system_reference
        between from_orig_system_ref and to_orig_system_ref
        and batch_id = P_BATCH_ID
        and stage = 3
        and status = 'C');

      update HZ_IMP_CREDITRTNGS_INT
      set error_id = null, interface_status = null
      where batch_id = P_BATCH_ID
      and party_orig_system = P_ORIG_SYSTEM
      and interface_status = 'C'
      and exists (
        select 1 from
        hz_imp_work_units
        where party_orig_system_reference
        between from_orig_system_ref and to_orig_system_ref
        and batch_id = P_BATCH_ID
        and stage = 3
        and status = 'C');

      update HZ_IMP_CLASSIFICS_INT
      set error_id = null, interface_status = null
      where batch_id = P_BATCH_ID
      and party_orig_system = P_ORIG_SYSTEM
      and interface_status = 'C'
      and exists (
        select 1 from
        hz_imp_work_units
        where party_orig_system_reference
        between from_orig_system_ref and to_orig_system_ref
        and batch_id = P_BATCH_ID
        and stage = 3
        and status = 'C');

      update HZ_IMP_FINREPORTS_INT
      set error_id = null, interface_status = null
      where batch_id = P_BATCH_ID
      and party_orig_system = P_ORIG_SYSTEM
      and interface_status = 'C'
      and exists (
        select 1 from
        hz_imp_work_units
        where party_orig_system_reference
        between from_orig_system_ref and to_orig_system_ref
        and batch_id = P_BATCH_ID
        and stage = 3
        and status = 'C');

      update HZ_IMP_FINNUMBERS_INT
      set error_id = null, interface_status = null
      where batch_id = P_BATCH_ID
      and party_orig_system = P_ORIG_SYSTEM
      and interface_status = 'C'
      and exists (
        select 1 from
        hz_imp_work_units
        where party_orig_system_reference
        between from_orig_system_ref and to_orig_system_ref
        and batch_id = P_BATCH_ID
        and stage = 3
        and status = 'C');

      update HZ_IMP_RELSHIPS_INT
      set error_id = null, interface_status = null
      where batch_id = P_BATCH_ID
      and sub_orig_system = P_ORIG_SYSTEM
      and interface_status = 'C'
      and exists (
        select 1 from
        hz_imp_work_units
        where sub_orig_system_reference
        between from_orig_system_ref and to_orig_system_ref
        and batch_id = P_BATCH_ID
        and stage = 3
        and status = 'C');

      update HZ_IMP_CONTACTS_INT
      set error_id = null, interface_status = null
      where batch_id = P_BATCH_ID
      and sub_orig_system = P_ORIG_SYSTEM
      and interface_status = 'C'
      and exists (
        select 1 from
        hz_imp_work_units
        where sub_orig_system_reference
        between from_orig_system_ref and to_orig_system_ref
        and batch_id = P_BATCH_ID
        and stage = 3
        and status = 'C');

      update HZ_IMP_CONTACTROLES_INT
      set error_id = null, interface_status = null
      where batch_id = P_BATCH_ID
      and sub_orig_system = P_ORIG_SYSTEM
      and interface_status = 'C'
      and exists (
        select 1 from
        hz_imp_work_units
        where sub_orig_system_reference
        between from_orig_system_ref and to_orig_system_ref
        and batch_id = P_BATCH_ID
        and stage = 3
        and status = 'C');

      update HZ_IMP_ADDRESSUSES_INT
      set error_id = null, interface_status = null
      where batch_id = P_BATCH_ID
      and party_orig_system = P_ORIG_SYSTEM
      and interface_status = 'C'
      and exists (
        select 1 from
        hz_imp_work_units
        where party_orig_system_reference
        between from_orig_system_ref and to_orig_system_ref
        and batch_id = P_BATCH_ID
        and stage = 3
        and status = 'C');

    END IF; /* P_END_OF_DL_FLAG = 'Y' */

  END IF; /* P_RERUN_FLAG <> 'N' */

/* Populate permanent errors tables from tmp errors table */
insert all
  when (E1_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSES_INT',
       'HZ_IMP_INVALD_ADDR_ASSIGN')
  when (E2_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSES_INT',
       'HZ_API_MISSING_COLUMN', 'COLUMN', 'ADDRESS1')
  when (E3_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSES_INT',
       'HZ_API_MISSING_COLUMN', 'COLUMN', 'COUNTRY')
  when (E4_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value, token3_name,
       token3_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSES_INT',
       'HZ_API_INVALID_FK', 'FK', 'LANGUAGE', 'COLUMN', 'LANGUAGE_CODE',
       'TABLE', 'FND_LANGUAGES')
  when (E5_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value, token3_name,
       token3_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSES_INT',
       'HZ_API_INVALID_FK', 'FK', 'TIMEZONE_CODE', 'COLUMN',
       'TIMEZONE_CODE', 'TABLE', 'FND_TIMEZONES_B')
  when (E6_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSES_INT',
       'AR_RAPI_DESC_FLEX_INVALID', 'DEF_NAME', 'HZ_LOCATIONS')
  when (E7_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSES_INT',
       'HZ_IMP_ADDR_NO_CORRECTION')
  when (E8_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value, token3_name,
       token3_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSES_INT',
       'HZ_DSS_SECURITY_FAIL', 'USER_NAME', USER_NAME,
       'OPER_NAME', 'UPDATE', 'OBJECT_NAME', 'HZ_PARTY_SITES')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'A') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name,
token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSES_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_PARTY_SITES_U1', 'ENTITY',
       'HZ_PARTY_SITES')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'B') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSES_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_PARTY_SITES_U2', 'ENTITY',
       'HZ_PARTY_SITES')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'C') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSES_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_LOCATIONS_U1', 'ENTITY', 'HZ_LOCATIONS')
  when (ACTION_MISMATCH_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSES_INT',
       'HZ_IMP_ACTION_MISMATCH')
  when (MISSING_PARENT_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSES_INT',
       'HZ_IMP_PARENT_PARTY_NOT_FOUND')
 when (E9_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSES_INT',
       'HZ_NOTALLOW_UPDATE_THIRD_PARTY')
  when (E10_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSES_INT',
       'HZ_IMP_PARENT_PARTY_NOT_FOUND')
select creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, E1_FLAG, E2_FLAG,
       E3_FLAG, E4_FLAG, E5_FLAG, E6_FLAG, E7_FLAG, E8_FLAG, E9_FLAG, E10_FLAG, DUP_VAL_IDX_EXCEP_FLAG,
       ACTION_MISMATCH_FLAG, MISSING_PARENT_FLAG, FND_GLOBAL.USER_NAME
  from hz_imp_tmp_errors e
 where e.batch_id = P_BATCH_ID
   and e.request_id = P_REQUEST_ID
   and e.interface_table_name = 'HZ_IMP_ADDRESSES_INT';

insert all
  when (E1_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_API_DATE_GREATER', 'DATE2', 'REPORT_END_DATE', 'DATE1',
       'REPORT_START_DATE')
  when (E2_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'AUDIT_IND', 'LOOKUP_TYPE', 'YES/NO')
  when (E3_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'CONSOLIDATED_IND',
       'LOOKUP_TYPE', 'YES/NO')
  when (E4_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'ESTIMATED_IND', 'LOOKUP_TYPE',
       'YES/NO')
  when (E5_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FINAL_IND', 'LOOKUP_TYPE', 'YES/NO')
  when (E6_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FISCAL_IND', 'LOOKUP_TYPE', 'YES/NO')
  when (E7_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FORECAST_IND', 'LOOKUP_TYPE',
       'YES/NO')
  when (E8_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'OPENING_IND', 'LOOKUP_TYPE',
       'YES/NO')
  when (E9_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'PROFORMA_IND', 'LOOKUP_TYPE',
       'YES/NO')
  when (E10_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'QUALIFIED_IND', 'LOOKUP_TYPE',
       'YES/NO')
  when (E11_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'RESTATED_IND', 'LOOKUP_TYPE',
       'YES/NO')
  when (E12_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'SIGNED_BY_PRINCIPALS_IND',
       'LOOKUP_TYPE', 'YES/NO')
  when (E13_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'TRIAL_BALANCE_IND',
       'LOOKUP_TYPE', 'YES/NO')

  when (E14_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'UNBALANCED_IND', 'LOOKUP_TYPE',
       'YES/NO')
  when (E15_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_API_INVALID_COMBINATION2', 'COLUMN1', 'issued_period', 'COLUMN2',
       'report_start_date')
  when (E16_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_API_INVALID_COMBINATION3', 'COLUMN1', 'report_start_date', 'COLUMN2',
       'report_end_date')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'A') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_FINANCIAL_REPORTS_U1', 'ENTITY',
       'HZ_FINANCIAL_REPORTS')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'B') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_FINANCIAL_REPORTS_U2', 'ENTITY',
       'HZ_FINANCIAL_REPORTS')
  when (ACTION_MISMATCH_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_IMP_ACTION_MISMATCH')
  when (MISSING_PARENT_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINREPORTS_INT',
       'HZ_IMP_PARENT_PARTY_NOT_FOUND')
select /*+ leading(e) use_nl(int) rowid(int) */ e.creation_date, e.created_by, e.last_update_date, e.last_updated_by, e.last_update_login, e.program_application_id, 
 e.program_id, e.program_update_date, e.error_id, e.batch_id, e.request_id, e.interface_table_name, E1_FLAG, E2_FLAG,
       E3_FLAG, E4_FLAG, E5_FLAG, E6_FLAG, E7_FLAG, E8_FLAG, E9_FLAG,
       E10_FLAG, E11_FLAG, E12_FLAG, E13_FLAG, E14_FLAG, E15_FLAG, E16_FLAG,
       DUP_VAL_IDX_EXCEP_FLAG, ACTION_MISMATCH_FLAG, MISSING_PARENT_FLAG,
       INT.REPORT_START_DATE, INT.REPORT_END_DATE
  from hz_imp_tmp_errors e,
       HZ_IMP_FINREPORTS_INT int
 where e.batch_id = P_BATCH_ID
   and e.request_id = P_REQUEST_ID
   and e.int_row_id = int.rowid
   and e.interface_table_name = 'HZ_IMP_FINREPORTS_INT';

insert all
  when (E1_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINNUMBERS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FINANCIAL_NUMBER_NAME',
       'LOOKUP_TYPE', 'FIN_NUM_NAME')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'A') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINNUMBERS_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_FINANCIAL_NUMBERS_U1', 'ENTITY',
       'HZ_FINANCIAL_NUMBERS')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'B') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINNUMBERS_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_FINANCIAL_NUMBERS_U2', 'ENTITY',
       'HZ_FINANCIAL_NUMBERS')
  when (ACTION_MISMATCH_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINNUMBERS_INT',
       'HZ_IMP_ACTION_MISMATCH')
  when (MISSING_PARENT_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_FINNUMBERS_INT',
       'HZ_IMP_FINREPORT_NOT_FOUND')
select creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, E1_FLAG,
       DUP_VAL_IDX_EXCEP_FLAG, ACTION_MISMATCH_FLAG, MISSING_PARENT_FLAG
  from hz_imp_tmp_errors e
 where e.batch_id = P_BATCH_ID
   and e.request_id = P_REQUEST_ID
   and e.interface_table_name = 'HZ_IMP_FINNUMBERS_INT';

insert all
  when (E1_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FISCAL_YEAREND_MONTH',
       'LOOKUP_TYPE', 'MONTH')
  when (E2_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'LEGAL_STATUS', 'LOOKUP_TYPE',
       'LEGAL_STATUS')
  when (E3_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'LOCAL_BUS_IDEN_TYPE',
       'LOOKUP_TYPE', 'LOCAL_BUS_IDEN_TYPE')
  when (E4_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'REGISTRATION_TYPE',
       'LOOKUP_TYPE', 'REGISTRATION_TYPE')
  when (E5_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'HQ_BRANCH_IND', 'LOOKUP_TYPE',
       'HQ_BRANCH_IND')
  when (E6_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'MINORITY_OWNED_IND',
       'LOOKUP_TYPE', 'YES/NO')
  when (E7_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'GSA_INDICATOR_FLAG', 'LOOKUP_TYPE',
       'YES/NO')
  when (E8_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'IMPORT_IND', 'LOOKUP_TYPE', 'YES/NO')
  when (E9_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'EXPORT_IND', 'LOOKUP_TYPE', 'YES/NO')
  when (E10_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'BRANCH_FLAG', 'LOOKUP_TYPE',
       'YES/NO')
  when (E11_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'DISADV_8A_IND', 'LOOKUP_TYPE',
       'YES/NO')
  when (E12_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'LABOR_SURPLUS_IND',
       'LOOKUP_TYPE', 'YES/NO')
  when (E13_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'OOB_IND', 'LOOKUP_TYPE', 'YES/NO')
  when (E14_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'PARENT_SUB_IND', 'LOOKUP_TYPE',
       'YES/NO')
  when (E15_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'PUBLIC_PRIVATE_OWNERSHIP_FLAG',
       'LOOKUP_TYPE', 'YES/NO')
  when (E16_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'SMALL_BUS_IND', 'LOOKUP_TYPE',
       'YES/NO')
  when (E17_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'TOTAL_EMP_EST_IND',
       'LOOKUP_TYPE', 'TOTAL_EMP_EST_IND')
  when (E18_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'TOTAL_EMP_MIN_IND',
       'LOOKUP_TYPE', 'TOTAL_EMP_MIN_IND')
  when (E19_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'TOTAL_EMPLOYEES_IND', 'LOOKUP_TYPE',
       'TOTAL_EMPLOYEES_INDICATOR')
  when (E20_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'WOMAN_OWNED_IND', 'LOOKUP_TYPE',
       'YES/NO')
  when (E21_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'EMP_AT_PRIMARY_ADR_EST_IND',
       'LOOKUP_TYPE', 'EMP_AT_PRIMARY_ADR_EST_IND')
  when (E22_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'EMP_AT_PRIMARY_ADR_MIN_IND',
       'LOOKUP_TYPE', 'EMP_AT_PRIMARY_ADR_MIN_IND')
  when (E23_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'MARITAL_STATUS', 'LOOKUP_TYPE',
       'MARITAL_STATUS')
  when (E24_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'PERSON_PRE_NAME_ADJUNCT',
       'LOOKUP_TYPE', 'CONTACT_TITLE')
  when (E25_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_IMP_DECEASED_FLAG_ERROR')
  when (E26_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'HEAD_OF_HOUSEHOLD_FLAG',
       'LOOKUP_TYPE', 'YES/NO')
  when (E27_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_DATE_GREATER', 'DATE2', 'SYSDATE', 'DATE1', 'DATE_OF_BIRTH')
  when (E28_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_DATE_GREATER', 'DATE2', 'SYSDATE', 'DATE1', 'DATE_OF_DEATH')
  when (E29_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_DATE_GREATER', 'DATE2', 'DATE_OF_DEATH', 'DATE1', 'DATE_OF_BIRTH')
  when (E30_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_IMP_PARTY_TYPE_ERROR')
  when (E31_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'RENT_OWN_IND', 'LOOKUP_TYPE',
       'OWN_RENT_IND')
  when (E32_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'AR_RAPI_DESC_FLEX_INVALID', 'DFF_NAME', 'HZ_PARTIES')
  when (E33_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_IMP_PARTY_NAME_ERROR')
  when (E34_FLAG='P') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_DSS_NO_UPDATE_PRIVILEGE', 'ENTITY_NAME', l_dss_person_err)
  when (E34_FLAG='O') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_DSS_NO_UPDATE_PRIVILEGE', 'ENTITY_NAME', l_dss_org_err)
  when (E34_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_DSS_NO_UPDATE_PRIVILEGE', 'ENTITY_NAME', l_dss_others_err)
  when (E35_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_NO_RECORD', 'RECORD', 'PARTY', 'VALUE', ' ')
  -- Bug 5276809
  when (E36_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'GENDER', 'LOOKUP_TYPE',
       'HZ_GENDER')
  when (E37_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'PERSON_IDEN_TYPE', 'LOOKUP_TYPE',
       'HZ_PERSON_IDEN_TYPE')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'A') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_PARTIES_U1', 'ENTITY', 'HZ_PARTIES')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'B') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_PARTIES_U2', 'ENTITY', 'HZ_PARTIES')
  when (ACTION_MISMATCH_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_PARTIES_INT',
       'HZ_IMP_ACTION_MISMATCH')
select  /*+ leading(e) use_nl(int) rowid(int) */ e.creation_date, e.created_by, e.last_update_date, e.last_updated_by, e.last_update_login, e.program_application_id, 
       e.program_id, e.program_update_date, e.error_id, e.batch_id, e.request_id, e.interface_table_name, E1_FLAG, E2_FLAG,
       E3_FLAG, E4_FLAG, E5_FLAG, E6_FLAG, E7_FLAG, E8_FLAG, E9_FLAG,
       E10_FLAG, E11_FLAG, E12_FLAG, E13_FLAG, E14_FLAG, E15_FLAG,
       E16_FLAG, E17_FLAG, E18_FLAG, E19_FLAG, E20_FLAG, E21_FLAG,
       E22_FLAG, E23_FLAG, E24_FLAG, E25_FLAG, E26_FLAG, E27_FLAG,
       E28_FLAG, E29_FLAG, E30_FLAG, E31_FLAG, E32_FLAG, E33_FLAG,
       E34_FLAG, E35_FLAG,  E36_FLAG, E37_FLAG, 
       DUP_VAL_IDX_EXCEP_FLAG, ACTION_MISMATCH_FLAG,
       INT.DATE_OF_BIRTH, INT.DATE_OF_DEATH, FND_GLOBAL.USER_NAME
  from hz_imp_tmp_errors e,
       HZ_IMP_PARTIES_INT int
 where e.batch_id = P_BATCH_ID
   and e.request_id = P_REQUEST_ID
   and e.int_row_id = int.rowid
   and e.interface_table_name = 'HZ_IMP_PARTIES_INT';

insert all
  when (E1_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_RELSHIPS_INT',
       'HZ_IMP_REL_SUBJ_OBJ_ERROR', 'SUB_OR_OBJ', 'SUBJECT')
  when (E2_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_RELSHIPS_INT',
       'HZ_IMP_REL_SUBJ_OBJ_ERROR', 'SUB_OR_OBJ', 'OBJECT')
  when (E3_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_RELSHIPS_INT',
       'HZ_IMP_REL_TYPE_ERROR')
  when (E4_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_RELSHIPS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'RELATIONSHIP_CODE',
       'LOOKUP_TYPE', 'PARTY_RELATIONS_TYPE')
  when (E5_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_RELSHIPS_INT',
       'HZ_API_DATE_GREATER', 'DATE2', 'END_DATE', 'DATE1', 'START_DATE')
  when (E6_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_RELSHIPS_INT',
       'HZ_IMP_HIERARCHICAL_FLAG_ERROR')
  when (E7_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_RELSHIPS_INT',
       'HZ_API_SUBJECT_OBJECT_IDS')
  when (E8_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_RELSHIPS_INT',
       'HZ_RELATIONSHIP_DATE_OVERLAP')
  when (E9_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_RELSHIPS_INT',
       'AR_RAPI_DESC_FLEX_INVALID', 'DFF_NAME', 'HZ_RELATIONSHIPS')
  when (E10_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_RELSHIPS_INT',
       'HZ_DSS_NO_UPDATE_PRIVILEGE', 'ENTITY_NAME', l_dss_rel_err)
  when (DUP_VAL_IDX_EXCEP_FLAG = 'A') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_RELSHIPS_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_RELATIONSHIPS_U1', 'ENTITY',
       'HZ_RELATIONSHIPS')
  when (ACTION_MISMATCH_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_RELSHIPS_INT',
       'HZ_IMP_ACTION_MISMATCH')
select  /*+ leading(e) use_nl(int) rowid(int) */ e.creation_date, e.created_by, e.last_update_date, e.last_updated_by, e.last_update_login, e.program_application_id, 
  e.program_id, e.program_update_date, e.error_id, e.batch_id, e.request_id, e.interface_table_name, E1_FLAG, E2_FLAG,
       E3_FLAG, E4_FLAG, E5_FLAG, E6_FLAG, E7_FLAG, E8_FLAG, E9_FLAG,
       E10_FLAG, DUP_VAL_IDX_EXCEP_FLAG, ACTION_MISMATCH_FLAG,
       FND_GLOBAL.USER_NAME, INT.START_DATE, INT.END_DATE
  from hz_imp_tmp_errors e,
       HZ_IMP_RELSHIPS_INT int
 where e.batch_id = P_BATCH_ID
   and e.request_id = P_REQUEST_ID
   and e.int_row_id = int.rowid
   and e.interface_table_name = 'HZ_IMP_RELSHIPS_INT';

insert all
  when (E1_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'HZ_IMP_REL_SUBJ_OBJ_ERROR', 'SUB_OR_OBJ', 'SUBJECT')
  when (E2_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'HZ_IMP_REL_SUBJ_OBJ_ERROR', 'SUB_OR_OBJ', 'OBJECT')
  when (E3_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'HZ_API_PARTY_NOT_PERSON', 'TABLE_NAME', 'HZ_IMP_CONTACTS_INT',
       'PARTY_ID_COL', SUB_ORIG_SYSTEM_REFERENCE)
  when (E4_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'HZ_API_PARTY_NOT_ORG', 'TABLE_NAME', 'HZ_IMP_CONTACTS_INT',
       'PARTY_ID_COL', OBJ_ORIG_SYSTEM_REFERENCE)
  when (E5_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'RELATIONSHIP_CODE',
       'LOOKUP_TYPE', 'PARTY_RELATIONS_TYPE')
  when (E6_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'DEPARTMENT_CODE', 'LOOKUP_TYPE',
       'DEPARTMENT_CODE')
  when (E7_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'TITLE', 'LOOKUP_TYPE',
       'CONTACT_TITLE')
  when (E8_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'JOB_TITLE_CODE', 'LOOKUP_TYPE',
       'RESPONSIBILITY')
  when (E9_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'DECISION_MAKER_FLAG',
       'LOOKUP_TYPE', 'YES/NO')
  when (E10_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'REFERENCE_USE_FLAG',
       'LOOKUP_TYPE', 'YES/NO')
  when (E11_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'HZ_API_DATE_GREATER', 'DATE2', 'END_DATE', 'DATE1', 'START_DATE')
  when (E12_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'AR_RAPI_DESC_FLEX_INVALID', 'DFF_NAME', 'HZ_RELATIONSHIPS')
  when (E13_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'HZ_IMP_HIERARCHICAL_FLAG_ERROR')
  when (E14_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT', 'HZ_IMP_DUP_REL_IN_INT_ERROR')
  when (E15_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'HZ_DSS_NO_UPDATE_PRIVILEGE', 'ENTITY_NAME', l_dss_rel_err)
  when (E16_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'HZ_API_NONUPDATEABLE_TO_NULL', 'COLUMN', 'START_DATE')
 -- Bug 4156586
 when (E17_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT', 'HZ_API_SUBJECT_OBJECT_IDS')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'A') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_ORG_CONTACTS_U1', 'ENTITY',
       'HZ_ORG_CONTACTS')
  when (ACTION_MISMATCH_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTS_INT',
       'HZ_IMP_ACTION_MISMATCH')
select /*+ leading(e) use_nl(int) rowid(int) */ e.creation_date, e.created_by, e.last_update_date, e.last_updated_by, e.last_update_login, e.program_application_id, 
       e.program_id, e.program_update_date, e.error_id, e.batch_id, e.request_id, e.interface_table_name, E1_FLAG, E2_FLAG,
       E3_FLAG, E4_FLAG, E5_FLAG, E6_FLAG, E7_FLAG, E8_FLAG, E9_FLAG,
       E10_FLAG, E11_FLAG, E12_FLAG, E13_FLAG, E14_FLAG, E15_FLAG,
       E16_FLAG, E17_FLAG , /* Bug 4156586 */DUP_VAL_IDX_EXCEP_FLAG, ACTION_MISMATCH_FLAG,
       FND_GLOBAL.USER_NAME, INT.SUB_ORIG_SYSTEM_REFERENCE,
       INT.OBJ_ORIG_SYSTEM_REFERENCE, INT.END_DATE, INT.START_DATE
  from hz_imp_tmp_errors e,
       HZ_IMP_CONTACTS_INT int
 where e.batch_id = P_BATCH_ID
   and e.request_id = P_REQUEST_ID
   and e.int_row_id = int.rowid
   and e.interface_table_name = 'HZ_IMP_CONTACTS_INT';

insert all
  when (E2_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value, token3_name,
       token3_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CLASSIFICS_INT',
       'HZ_API_INVALID_FK', 'FK', 'CLASS_CATEGORY', 'COLUMN',
       'CLASS_CATEGORY', 'TABLE', 'HZ_CLASS_CATEGORIES')
  when (E3_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CLASSIFICS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'CLASS_CODE', 'LOOKUP_TYPE',
       'HZ_IMP_CLASSIFICS_INT.CLASS_CATEGORY')
  when (E4_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CLASSIFICS_INT',
       'HZ_API_DATE_GREATER', 'DATE2', 'END_DATE_ACTIVE', 'DATE1',
       'START_DATE_ACTIVE')
  when (E5_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CLASSIFICS_INT',
       'HZ_IMP_CODE_ASSG_DATE_OVERLAP')
  when (E6_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CLASSIFICS_INT',
       'HZ_API_ALLOW_MUL_ASSIGN_FG')
  when (E7_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CLASSIFICS_INT',
       'HZ_API_LEAFNODE_FLAG')
  when (E8_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CLASSIFICS_INT',
       'HZ_API_NONUPDATEABLE_TO_NULL', 'COLUMN', 'START_DATE')
  when (E9_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CLASSIFICS_INT',
       'HZ_DSS_NO_UPDATE_PRIVILEGE', 'ENTITY_NAME', l_dss_ca_err)
  when (DUP_VAL_IDX_EXCEP_FLAG = 'A') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CLASSIFICS_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_CODE_ASSIGNMENTS_U1', 'ENTITY',
       'HZ_CODE_ASSIGNMENTS')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'B') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CLASSIFICS_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_CODE_ASSIGNMENTS_U2', 'ENTITY',
       'HZ_CODE_ASSIGNMENTS')
  when (ACTION_MISMATCH_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CLASSIFICS_INT',
       'HZ_IMP_ACTION_MISMATCH')
  when (MISSING_PARENT_FLAG is null) then -- Bug 4403736
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CLASSIFICS_INT',
       'HZ_IMP_PARENT_PARTY_NOT_FOUND') 
select /*+ leading(e) use_nl(int) rowid(int) */ e.creation_date, e.created_by, e.last_update_date, e.last_updated_by, e.last_update_login, e.program_application_id, 
       e.program_id, e.program_update_date, e.error_id, e.batch_id, e.request_id, e.interface_table_name, E2_FLAG, E3_FLAG,
       E4_FLAG, E5_FLAG, E6_FLAG, E7_FLAG, E8_FLAG, E9_FLAG,
       DUP_VAL_IDX_EXCEP_FLAG, ACTION_MISMATCH_FLAG, MISSING_PARENT_FLAG, FND_GLOBAL.USER_NAME,
       INT.END_DATE_ACTIVE, INT.START_DATE_ACTIVE
  from hz_imp_tmp_errors e,
       HZ_IMP_CLASSIFICS_INT int
 where e.batch_id = P_BATCH_ID
   and e.request_id = P_REQUEST_ID
   and e.int_row_id = int.rowid
   and e.interface_table_name = 'HZ_IMP_CLASSIFICS_INT';

insert all
  when (E1_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'BANKRUPTCY_IND', 'LOOKUP_TYPE',
       'YES/NO')
  when (E2_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'SUIT_IND', 'LOOKUP_TYPE', 'YES/NO')
  when (E4_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'DEBARMENT_IND', 'LOOKUP_TYPE',
       'YES/NO')
  when (E5_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name,
token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FINCL_EMBT_IND', 'LOOKUP_TYPE',
       'YES/NO')
  when (E6_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'NO_TRADE_IND', 'LOOKUP_TYPE',
       'YES/NO')
  when (E7_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'JUDGEMENT_IND', 'LOOKUP_TYPE',
       'YES/NO')
  when (E8_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'LIEN_IND', 'LOOKUP_TYPE', 'YES/NO')
  when (E9_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'CREDIT_SCORE_OVERRIDE_CODE',
       'LOOKUP_TYPE', 'FAILURE_SCORE_OVERRIDE_CODE')
  when (E10_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FAILURE_SCORE_COMMENTARY',
       'LOOKUP_TYPE', 'FAILURE_SCORE_COMMENTARY')
  when (E11_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FAILURE_SCORE_COMMENTARY2',
       'LOOKUP_TYPE', 'FAILURE_SCORE_COMMENTARY')
  when (E12_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FAILURE_SCORE_COMMENTARY3',
       'LOOKUP_TYPE', 'FAILURE_SCORE_COMMENTARY')
  when (E13_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FAILURE_SCORE_COMMENTARY4',
       'LOOKUP_TYPE', 'FAILURE_SCORE_COMMENTARY')
  when (E14_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FAILURE_SCORE_COMMENTARY5',
       'LOOKUP_TYPE', 'FAILURE_SCORE_COMMENTARY')
  when (E15_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FAILURE_SCORE_COMMENTARY6',
       'LOOKUP_TYPE', 'FAILURE_SCORE_COMMENTARY')
  when (E16_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FAILURE_SCORE_COMMENTARY7',
       'LOOKUP_TYPE', 'FAILURE_SCORE_COMMENTARY')
  when (E17_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FAILURE_SCORE_COMMENTARY8',
       'LOOKUP_TYPE', 'FAILURE_SCORE_COMMENTARY')
  when (E18_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FAILURE_SCORE_COMMENTARY9',
       'LOOKUP_TYPE', 'FAILURE_SCORE_COMMENTARY')
  when (E19_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FAILURE_SCORE_COMMENTARY10',
       'LOOKUP_TYPE', 'FAILURE_SCORE_COMMENTARY')
  when (E20_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'FAILURE_SCORE_OVERRIDE_CODE',
       'LOOKUP_TYPE', 'FAILURE_SCORE_OVERRIDE_CODE')
  when (E21_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'CREDIT_SCORE_COMMENTARY',
       'LOOKUP_TYPE', 'CREDIT_SCORE_COMMENTARY')
  when (E22_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'CREDIT_SCORE_COMMENTARY2',
       'LOOKUP_TYPE', 'CREDIT_SCORE_COMMENTARY')
  when (E23_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'CREDIT_SCORE_COMMENTARY3',
       'LOOKUP_TYPE', 'CREDIT_SCORE_COMMENTARY')
  when (E24_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'CREDIT_SCORE_COMMENTARY4',
       'LOOKUP_TYPE', 'CREDIT_SCORE_COMMENTARY')
  when (E25_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'CREDIT_SCORE_COMMENTARY5',
       'LOOKUP_TYPE', 'CREDIT_SCORE_COMMENTARY')
  when (E26_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'CREDIT_SCORE_COMMENTARY6',
       'LOOKUP_TYPE', 'CREDIT_SCORE_COMMENTARY')
  when (E27_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'CREDIT_SCORE_COMMENTARY7',
       'LOOKUP_TYPE', 'CREDIT_SCORE_COMMENTARY')
  when (E28_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'CREDIT_SCORE_COMMENTARY8',
       'LOOKUP_TYPE', 'CREDIT_SCORE_COMMENTARY')
  when (E29_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'CREDIT_SCORE_COMMENTARY9',
       'LOOKUP_TYPE', 'CREDIT_SCORE_COMMENTARY')
  when (E30_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'CREDIT_SCORE_COMMENTARY10',
       'LOOKUP_TYPE', 'CREDIT_SCORE_COMMENTARY')
  when (E31_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'PRNT_HQ_BKCY_IND',
       'LOOKUP_TYPE', 'PRNT_HQ_IND')
  when (E32_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value, token3_name,
       token3_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_API_INVALID_FK', 'FK', 'CURRENCY_CODE', 'COLUMN',
       'MAXIMUM_CREDIT_CURRENCY_CODE', 'TABLE', 'FND_CURRENCIES')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'A') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_CREDIT_RATINGS_U1', 'ENTITY',
       'HZ_CREDIT_RATINGS')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'B') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_CREDIT_RATINGS_U2', 'ENTITY',
       'HZ_CREDIT_RATINGS')
  when (ACTION_MISMATCH_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_IMP_ACTION_MISMATCH')
  when (MISSING_PARENT_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CREDITRTNGS_INT',
       'HZ_IMP_PARENT_PARTY_NOT_FOUND')
select creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, E1_FLAG, E2_FLAG,

       E4_FLAG, E5_FLAG, E6_FLAG, E7_FLAG, E8_FLAG, E9_FLAG, E10_FLAG,
       E11_FLAG, E12_FLAG, E13_FLAG, E14_FLAG, E15_FLAG, E16_FLAG,
       E17_FLAG, E18_FLAG, E19_FLAG, E20_FLAG, E21_FLAG, E22_FLAG,
       E23_FLAG, E24_FLAG, E25_FLAG, E26_FLAG, E27_FLAG, E28_FLAG,
       E29_FLAG, E30_FLAG, E31_FLAG, E32_FLAG, 
       DUP_VAL_IDX_EXCEP_FLAG,
       ACTION_MISMATCH_FLAG, MISSING_PARENT_FLAG
  from hz_imp_tmp_errors e
 where e.batch_id = P_BATCH_ID
   and e.request_id = P_REQUEST_ID
   and e.interface_table_name = 'HZ_IMP_CREDITRTNGS_INT';


insert all
  when (E1_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSUSES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'SITE_USE_TYPE', 'LOOKUP_TYPE',
       'PARTY_SITE_USE_CODE')
  when (E2_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSUSES_INT',
       'HZ_API_UNIQUE_SITE_USE_TYPE')
  when (E3_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSUSES_INT',
       'HZ_IMP_ADDRUSE_OSR_MISMATCH')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'A') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSUSES_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_PARTY_SITE_USES_U1', 'ENTITY',
       'HZ_PARTY_SITE_USES')
  when (ACTION_MISMATCH_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSUSES_INT',
       'HZ_IMP_ACTION_MISMATCH')
  when (MISSING_PARENT_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_ADDRESSUSES_INT',
       'HZ_IMP_ADDR_NOT_FOUND')
select creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, E1_FLAG, E2_FLAG, E3_FLAG,
       DUP_VAL_IDX_EXCEP_FLAG, ACTION_MISMATCH_FLAG, MISSING_PARENT_FLAG
  from hz_imp_tmp_errors e
 where e.batch_id = P_BATCH_ID
   and e.request_id = P_REQUEST_ID
   and e.interface_table_name = 'HZ_IMP_ADDRESSUSES_INT';


insert all
  when (E1_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTROLES_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'ROLE_TYPE', 'LOOKUP_TYPE',
       'CONTACT_ROLE_TYPE')
  when (E2_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTROLES_INT',
       'HZ_IMP_CONTROLE_OSR_MISMATCH')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'A') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTROLES_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_ORG_CONTACT_ROLES_U1', 'ENTITY',
       'HZ_ORG_CONTACT_ROLES')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'B') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTROLES_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_ORG_CONTACT_ROLES_U2', 'ENTITY',
       'HZ_ORG_CONTACT_ROLES')
  when (ACTION_MISMATCH_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTROLES_INT',
       'HZ_IMP_ACTION_MISMATCH')
  when (MISSING_PARENT_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTROLES_INT',
       'HZ_IMP_CONTACT_NOT_FOUND')
select creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, E1_FLAG, E2_FLAG,
       DUP_VAL_IDX_EXCEP_FLAG, ACTION_MISMATCH_FLAG, MISSING_PARENT_FLAG
  from hz_imp_tmp_errors
 where batch_id = P_BATCH_ID
   and request_id = P_REQUEST_ID
   and interface_table_name = 'HZ_IMP_CONTACTROLES_INT';



insert all
  when (E1_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'CONTACT_POINT_TYPE',
       'LOOKUP_TYPE', 'CONTACT_POINT_TYPE')
  when (E2_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'CONTACT_POINT_PURPOSE',
       'LOOKUP_TYPE', 'CONTACT_POINT_PURPOSE')
  when (E3_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_API_MISSING_COLUMN', 'COLUMN', 'EDI_ID_NUMBER')
  when (E4_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_API_MISSING_COLUMN', 'COLUMN', 'EMAIL_ADDRESS')
  when (E5_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'EMAIL_FORMAT', 'LOOKUP_TYPE',
       'EMAIL_FORMAT')
  when (E6_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value, token3_name,
       token3_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_API_INVALID_FK', 'FK', 'PHONE_COUNTRY_CODE', 'COLUMN',
       'PHONE_COUNTRY_CODE', 'TABLE', 'HZ_PHONE_COUNTRY_CODES')
  when (E7_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_API_INVALID_LOOKUP', 'PHONE_LINE_TYPE', 'LOOKUP_TYPE',
       'PHONE_LINE_TYPE')
  when (E8_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_INVALID_PHONE_PARAMETER')
  when (E9_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_API_MISSING_COLUMN', 'COLUMN', 'TELEX_NUMBER')
  when (E10_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value, token3_name,
       token3_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_API_INVALID_FK', 'FK', 'TIMEZONE_CODE', 'COLUMN',
       'TIMEZONE_CODE', 'TABLE', 'FND_TIMEZONES_B')
  when (E11_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_API_MISSING_COLUMN', 'COLUMN', 'URL')
  when (E12_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_API_MISSING_COLUMN', 'COLUMN', 'WEB_TYPE')
  when (E13_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'AR_RAPI_DESC_FLEX_INVALID', 'DFF_NAME', 'HZ_CONTACT_POINTS')
  when (E15_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_API_MISSING_COLUMN', 'COLUMN', 'CONTACT_POINT_TYPE')
  when (E16_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_IMP_CPT_ADDR_OSR_MISMATCH')
  when (E17_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_API_NONUPDATEABLE_COLUMN', 'COLUMN', 'CONTACT_POINT_TYPE')
  when (E18_FLAG='P') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_DSS_NO_UPDATE_PRIVILEGE', 'ENTITY_NAME', l_dss_cp_err)
  when (E18_FLAG='S') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_DSS_NO_UPDATE_PRIVILEGE', 'ENTITY_NAME', l_dss_ps_err)
  when (E19_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_API_INVALID_LOOKUP', 'COLUMN', 'CONTACT_POINT_PURPOSE',
       'LOOKUP_TYPE', 'CONTACT_POINT_PURPOSE_WEB')
  when (DUP_VAL_IDX_EXCEP_FLAG = 'A') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name,
       token1_name, token1_value, token2_name, token2_value)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_IMP_DUP_VAL', 'INDEX', 'HZ_CONTACT_POINTS_U1', 'ENTITY',
       'HZ_CONTACT_POINTS')
  when (ACTION_MISMATCH_FLAG is null) then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_IMP_ACTION_MISMATCH')
  when (MISSING_PARENT_FLAG = 'P') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_IMP_PARENT_PARTY_NOT_FOUND')
  when (MISSING_PARENT_FLAG = 'A') then
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_IMP_PARENT_ADDR_NOT_FOUND')
  when (E20_FLAG IS NULL) then /* Bug 4079902 */
  into hz_imp_errors (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, message_name)
values (
       creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, 'HZ_IMP_CONTACTPTS_INT',
       'HZ_NOTALLOW_UPDATE_THIRD_PARTY')
select creation_date, created_by, last_update_date, last_updated_by, last_update_login, program_application_id, program_id, program_update_date, error_id, batch_id, request_id, interface_table_name, E1_FLAG, E2_FLAG,
       E3_FLAG, E4_FLAG, E5_FLAG, E6_FLAG, E7_FLAG, E8_FLAG, E9_FLAG,
       E10_FLAG, E11_FLAG, E12_FLAG, E13_FLAG,  E15_FLAG,
       E16_FLAG, E17_FLAG, E18_FLAG, E19_FLAG, E20_FLAG /* Bug 4079902 */,DUP_VAL_IDX_EXCEP_FLAG,
       ACTION_MISMATCH_FLAG, MISSING_PARENT_FLAG
  from hz_imp_tmp_errors e
 where e.batch_id = P_BATCH_ID
   and request_id = P_REQUEST_ID
   and e.interface_table_name = 'HZ_IMP_CONTACTPTS_INT';

  /* Update interface status of errored records to 'E' */
  OPEN c_err(P_BATCH_ID, P_REQUEST_ID);
  FETCH  c_err BULK COLLECT INTO l_row_id, l_table_name, l_error_id;
  CLOSE c_err;

ForAll i in 1..l_row_id.count
  update hz_imp_parties_int
     set interface_status = 'E',
         error_id = l_error_id(i)
   where rowid = l_row_id(i)
     and l_table_name(i) = 'HZ_IMP_PARTIES_INT';

ForAll i in 1..l_row_id.count
  update hz_imp_addresses_int
     set interface_status = 'E',
         error_id = l_error_id(i)
   where rowid = l_row_id(i)
     and l_table_name(i) = 'HZ_IMP_ADDRESSES_INT';

ForAll i in 1..l_row_id.count
  update hz_imp_contactpts_int
     set interface_status = 'E',
         error_id = l_error_id(i)
   where rowid = l_row_id(i)
     and l_table_name(i) = 'HZ_IMP_CONTACTPTS_INT';

ForAll i in 1..l_row_id.count
  update hz_imp_contacts_int
     set interface_status = 'E',
         error_id = l_error_id(i)
   where rowid = l_row_id(i)
     and l_table_name(i) = 'HZ_IMP_CONTACTS_INT';

ForAll i in 1..l_row_id.count
  update hz_imp_contactroles_int
     set interface_status = 'E',
         error_id = l_error_id(i)
   where rowid = l_row_id(i)
     and l_table_name(i) = 'HZ_IMP_CONTACTROLES_INT';

ForAll i in 1..l_row_id.count
  update hz_imp_addressuses_int
     set interface_status = 'E',
         error_id = l_error_id(i)
   where rowid = l_row_id(i)
     and l_table_name(i) = 'HZ_IMP_ADDRESSUSES_INT';

ForAll i in 1..l_row_id.count
  update hz_imp_finreports_int
     set interface_status = 'E',
         error_id = l_error_id(i)
   where rowid = l_row_id(i)
     and l_table_name(i) = 'HZ_IMP_FINREPORTS_INT';

ForAll i in 1..l_row_id.count
  update hz_imp_finnumbers_int
     set interface_status = 'E',
         error_id = l_error_id(i)
   where rowid = l_row_id(i)
     and l_table_name(i) = 'HZ_IMP_FINNUMBERS_INT';

ForAll i in 1..l_row_id.count
  update hz_imp_creditrtngs_int
     set interface_status = 'E',
         error_id = l_error_id(i)
   where rowid = l_row_id(i)
     and l_table_name(i) = 'HZ_IMP_CREDITRTNGS_INT';

ForAll i in 1..l_row_id.count
  update hz_imp_classifics_int
     set interface_status = 'E',
         error_id = l_error_id(i)
   where rowid = l_row_id(i)
     and l_table_name(i) = 'HZ_IMP_CLASSIFICS_INT';

ForAll i in 1..l_row_id.count
  update hz_imp_relships_int
     set interface_status = 'E',
         error_id = l_error_id(i)
   where rowid = l_row_id(i)
     and l_table_name(i) = 'HZ_IMP_RELSHIPS_INT';

COMMIT;

  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:GENERATE_ERRORS()-',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
  END IF;

END GENERATE_ERRORS;


PROCEDURE DATA_LOAD_PREPROCESSING(
  P_BATCH_ID                      IN NUMBER,
  P_ORIG_SYSTEM                   IN VARCHAR2,
  P_WHAT_IF_ANALYSIS              IN VARCHAR2,
  P_RERUN_FLAG                    OUT NOCOPY VARCHAR2
) IS
  l_batch_status     VARCHAR2(150);
  l_phase_code       VARCHAR2(1);
  l_rerun        VARCHAR2(1);
  l_wu_exists        VARCHAR2(1);

  CURSOR c_batch_status(p_batch_id number) IS
    select bs.import_status, r.phase_code
    from hz_imp_batch_details bs, FND_CONCURRENT_REQUESTS r
    where bs.batch_id = p_batch_id
    and bs.import_req_id = r.request_id(+)
    and bs.run_number = (select max(bd.run_number)-1
                      from hz_imp_batch_details bd
                    where bd.batch_id = p_batch_id);

  CURSOR c_wu(p_batch_id number) IS
    SELECT 'Y'
    FROM hz_imp_work_units
    WHERE batch_id = p_batch_id
    AND rownum = 1;
  --l_debug_prefix  VARCHAR2(30) := '';
BEGIN
  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:DATA_LOAD_PREPROCESSING()+',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
  END IF;

  /* Get latest batch details status */
  OPEN c_batch_status(P_BATCH_ID);
  FETCH  c_batch_status INTO l_batch_status, l_phase_code;
  CLOSE c_batch_status;

  if l_batch_status in ('COMPLETED', 'COMPL_ERRORS') then
    l_rerun := 'E';  /* For a COMPLETED status in batch details, it may mean the batch
               run is ok but there're still errors in the batch. So we also
               set rerun flag to 'E'. The import wrapper will filter out any
               batch that has a COMPLETED batch status. */
  elsif l_batch_status is null then
    l_rerun := 'N';  -- New

  elsif l_batch_status = 'COMPL_ERROR_LIMIT' then
    l_rerun := 'L';

  elsif l_batch_status = 'ERROR' then
    l_rerun := 'U';

  elsif l_batch_status = 'PROCESSING' then
    if l_phase_code <> 'C' then
      l_rerun := 'D';  -- Duplicate run of a running request
    else
      l_rerun := 'U';  -- unexpected error. Concurrent process completed but
                            -- batch status is still 'PROCESSING'
    end if;

  elsif l_batch_status = 'ACTION_REQUIRED' then -- what-if analysis pause
    if P_WHAT_IF_ANALYSIS = 'R' then
      l_rerun := 'R';  -- Resume
    else
      l_rerun := 'N';  -- New
    end if;
  end if;

  P_RERUN_FLAG := l_rerun;
  OPEN c_wu(P_BATCH_ID);
  FETCH  c_wu INTO l_wu_exists;
  CLOSE c_wu;

  /* Generate work units */
  IF l_rerun = 'N' OR l_rerun = 'E' THEN

    IF l_wu_exists = 'Y' THEN
      delete hz_imp_work_units
      where batch_id = P_BATCH_ID;
    END IF;

    GENERATE_ENTITIES_WORK_UNITS(P_BATCH_ID, P_ORIG_SYSTEM);

  END IF;

  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:DATA_LOAD_PREPROCESSING()-',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
  END IF;

END DATA_LOAD_PREPROCESSING;


/* Clean up postprocessing status in work units table if previous
   run did not complete successfully */
PROCEDURE RESET_PP_WU(
  P_BATCH_ID                   IN NUMBER
) IS
CURSOR c_unfinished_pp(p_batch_id number) IS
  select 'Y' from hz_imp_work_units
  where batch_id = p_batch_id
  and (postprocess_status is null or postprocess_status <> 'C')
  and rownum = 1;
l_unfinished_pp_exists VARCHAR2(1);

BEGIN

  OPEN c_unfinished_pp(P_BATCH_ID);
  FETCH  c_unfinished_pp INTO l_unfinished_pp_exists;
  IF c_unfinished_pp%NOTFOUND
  THEN
    l_unfinished_pp_exists := 'N';
  END IF;
  CLOSE c_unfinished_pp;
  
  IF l_unfinished_pp_exists = 'N' THEN
    /* If all WUs were processed successfully in previous run,
       update postprocess_status to NULL so that PP will be
       done for the current request_id */
    update hz_imp_work_units
    set postprocess_status = NULL
    where batch_id = P_BATCH_ID;
  ELSE
    /* For WUs with NULL postprocess_status, they were not processed
       at all in previous run. Update postprocess_status to 'U'
       so that PP will be done for the current request_id and all
       previous request_ids 
       
       For WUs with 'U' postprocess_status, they will be left as is
       because they were not processed in some previous runs and 
       also had errors in the last run. PP will be done for the 
       current request_id and all previous request_ids*/    
    update hz_imp_work_units
    set postprocess_status = 'U'
    where batch_id = P_BATCH_ID
    and (postprocess_status is NULL or postprocess_status <> 'C');  

    /* For WUs with 'C' postprocess_status, they were processed
       successfully in previous run. Update postprocess_status to NULL
       so that PP will be done for the current request_id */
    update hz_imp_work_units
    set postprocess_status = NULL
    where batch_id = P_BATCH_ID
    and postprocess_status = 'C';
  END IF;
  
END RESET_PP_WU;


-- Wrapper for running batch data load.
PROCEDURE BATCH_DATA_LOAD (
  Errbuf                      OUT NOCOPY     VARCHAR2,
  Retcode                     OUT NOCOPY     VARCHAR2,
  P_BATCH_ID                  IN             NUMBER,
  P_ORIG_SYSTEM               IN             VARCHAR2,
  P_WHAT_IF_ANALYSIS          IN             VARCHAR2,
  P_REGISTRY_DEDUP         IN      VARCHAR2,
  P_REGISTRY_DEDUP_MATCH_RULE_ID    IN   NUMBER,
  P_SYSDATE                   IN             VARCHAR2,
  P_NUM_OF_WORKERS         IN             NUMBER,
  P_ERROR_LIMIT            IN             NUMBER,
  P_RERUN_FLAG          IN             VARCHAR2,
  P_REQUEST_ID          IN      NUMBER,
  P_PROGRAM_APPLICATION_ID    IN      NUMBER,
  P_PROGRAM_ID          IN      NUMBER
) IS

BEGIN

  DATA_LOAD (
  Errbuf  ,
  Retcode ,
  P_BATCH_ID ,
  P_ORIG_SYSTEM ,
  P_WHAT_IF_ANALYSIS ,
  P_REGISTRY_DEDUP,
  P_REGISTRY_DEDUP_MATCH_RULE_ID ,
  P_SYSDATE  ,
  'Y',
  P_NUM_OF_WORKERS,
  P_ERROR_LIMIT,
  P_RERUN_FLAG,
  P_REQUEST_ID,
  P_PROGRAM_APPLICATION_ID,
  P_PROGRAM_ID
  );

END BATCH_DATA_LOAD;


-- Wrapper for running online data load. Call DATA_LOAD.
PROCEDURE ONLINE_DATA_LOAD (
  Errbuf                      OUT NOCOPY     VARCHAR2,
  Retcode                     OUT NOCOPY     VARCHAR2,
  P_BATCH_ID                  IN             NUMBER,
  P_ORIG_SYSTEM               IN             VARCHAR2,
  P_WHAT_IF_ANALYSIS          IN             VARCHAR2,
  P_REGISTRY_DEDUP         IN      VARCHAR2,
  P_REGISTRY_DEDUP_MATCH_RULE_ID    IN   NUMBER,
  P_SYSDATE                   IN             VARCHAR2,
  P_ERROR_LIMIT            IN             NUMBER,
  P_RERUN_FLAG          IN             VARCHAR2,
  P_REQUEST_ID          IN      NUMBER,
  P_PROGRAM_APPLICATION_ID    IN      NUMBER,
  P_PROGRAM_ID          IN      NUMBER
) IS
BEGIN

  DATA_LOAD (
  Errbuf  ,
  Retcode ,
  P_BATCH_ID ,
  P_ORIG_SYSTEM ,
  P_WHAT_IF_ANALYSIS ,
  P_REGISTRY_DEDUP,
  P_REGISTRY_DEDUP_MATCH_RULE_ID ,
  P_SYSDATE  ,
  'N',
  1,
  P_ERROR_LIMIT,
  P_RERUN_FLAG,
  P_REQUEST_ID,
  P_PROGRAM_APPLICATION_ID,
  P_PROGRAM_ID
  );

END ONLINE_DATA_LOAD;

FUNCTION GET_COUNTS(p_batch_id IN NUMBER)
RETURN VARCHAR2 IS
   l_chk_cnts_flag                VARCHAR2(1);

    CURSOR c_check_counts IS
    SELECT 'Y' 
    FROM HZ_IMP_WORK_UNITS
    WHERE batch_id=p_batch_id
    AND 
       ((stage>=2
         AND status='C')
        OR 
        (stage=3
         AND status='P')
       )
    AND rownum=1;

BEGIN 
  OPEN c_check_counts;
  FETCH c_check_counts INTO l_chk_cnts_flag;
  IF c_check_counts%NOTFOUND
  THEN
  l_chk_cnts_flag := 'N';
  END IF;
  CLOSE c_check_counts;
  RETURN l_chk_cnts_flag;
END GET_COUNTS;
  

PROCEDURE DATA_LOAD (
  Errbuf                      OUT NOCOPY     VARCHAR2,
  Retcode                     OUT NOCOPY     VARCHAR2,
  P_BATCH_ID                  IN             NUMBER,
  P_ORIG_SYSTEM               IN             VARCHAR2,
  P_WHAT_IF_ANALYSIS          IN             VARCHAR2,
  P_REGISTRY_DEDUP         IN      VARCHAR2,
  P_REGISTRY_DEDUP_MATCH_RULE_ID    IN   NUMBER,
  P_SYSDATE                   IN             VARCHAR2,
  P_BATCH_MODE_FLAG           IN             VARCHAR2,
  P_NUM_OF_WORKERS            IN             NUMBER,
  P_ERROR_LIMIT            IN             NUMBER,
  P_RERUN_FLAG          IN             VARCHAR2,
  P_REQUEST_ID          IN      NUMBER,
  P_PROGRAM_APPLICATION_ID    IN      NUMBER,
  P_PROGRAM_ID          IN      NUMBER
) IS

  TOTAL_NUM_STAGES   NUMBER := 3;  -- total number of stages with multiple workers
  --i                  NUMBER := 1;
  l_request_id       NUMBER;-- := 0;
  program_name       VARCHAR2(30); -- program name for current stage
  stage              NUMBER;       -- current stage
  req_data           VARCHAR2(10); -- request data
  l_content_src_type VARCHAR2(30); -- content source type, equivalent to OS if
                                   -- matched in lookup, 'USER_ENTERED' otherwise
  l_error_message    fnd_new_messages.message_text%TYPE;
  l_batch_status     VARCHAR2(150);
  l_what_if_flag     VARCHAR2(1);
  l_phase_code       VARCHAR2(1);
  l_hr_data_exists   VARCHAR2(1);
  l_wu_exists        VARCHAR2(1);
  l_err_exists      VARCHAR2(1);
  l_num_invalid_pid  NUMBER;

  l_user_id NUMBER;
  l_resp_appl_id NUMBER;
  l_last_update_login NUMBER;
  l_program_update_date DATE;
  l_g_miss_num NUMBER;
  l_g_miss_char VARCHAR2(240);
  l_g_miss_date DATE;
  l_flex_validation_prof VARCHAR2(1);
  l_dss_security_prof VARCHAR2(1);
  l_allow_disabled_lookup_prof VARCHAR2(1);
  l_profile_version_prof VARCHAR2(30);
  l_update_str_addr_prof VARCHAR2(1);
  l_maintain_loc_hist_prof VARCHAR2(1);
  l_allow_addr_corr_prof VARCHAR2(1);
  l_total_records_imported NUMBER;
  l_start_error_id   NUMBER;
  l_current_error_id NUMBER;

  l_sst_flag     VARCHAR2(1);
  
  D_SYSDATE DATE;

  CURSOR c_hr_data(p_batch_id number) IS
    SELECT 'Y'
    FROM hz_imp_parties_int
    WHERE batch_id = p_batch_id
    AND party_orig_system = 'DEFAULT'
    AND interface_status is null
    AND party_orig_system_reference like 'PER%'
    AND rownum = 1;

  CURSOR c_error(p_batch_id number, p_main_req_id number) IS
    SELECT 'Y'
    FROM hz_imp_tmp_errors
    WHERE batch_id = p_batch_id
    and request_id = p_main_req_id
    AND rownum = 1;

  CURSOR c_batch_error(p_batch_id number) IS
    SELECT decode(nvl(total_errors, 0), 0, 'N', 'Y')
    FROM HZ_IMP_BATCH_SUMMARY
    WHERE batch_id = p_batch_id;

  CURSOR c_sg_data(p_batch_id number) IS
    SELECT 'Y'
    FROM hz_imp_parties_sg
    WHERE batch_id = p_batch_id
    AND rownum = 1;

  CURSOR c_wu(p_batch_id number) IS
    SELECT 'Y'
    FROM hz_imp_work_units
    WHERE batch_id = p_batch_id
    AND rownum = 1;
    
  CURSOR c_invalid_pid(p_batch_id number) IS
    SELECT COUNT(*) 
    FROM hz_imp_parties_int pi
    WHERE pi.batch_id = p_batch_id
    AND pi.party_id is not null
    AND not exists (SELECT 'Y' 
                    FROM hz_parties p
                    WHERE p.party_id = pi.party_id);
  
   --l_debug_prefix VARCHAR2(30) := '';
BEGIN
  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:DATA_LOAD()+',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
  END IF;

  OPEN c_wu(P_BATCH_ID);
  FETCH  c_wu INTO l_wu_exists;
  CLOSE c_wu;

  /* Exit if the batch is completed or is a duplicate run of a running request */
  IF P_RERUN_FLAG = 'C' THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Completed batch cannot be run again.');
    return;
  ELSIF P_RERUN_FLAG = 'D' THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Same batch cannot be run at the same time.');
    return;
  END IF;

  /*
   Import stages
   '1' - Matching of Parties
   '2' - Matching of other entities, DQM, V+DML of Parties
   '3' - Dup check within rel/contacts, addr uses, and code assignments
   '4' - Dup check of relationships and address uses within interface
       - V+DML of other entities, PP-Wait
  */

  /* Get batch summary status */
  select bs.import_status, bs.what_if_flag, r.phase_code
  into l_batch_status, l_what_if_flag, l_phase_code
  from hz_imp_batch_summary bs, FND_CONCURRENT_REQUESTS r
  where bs.batch_id = P_BATCH_ID
  and bs.import_req_id = r.request_id(+);

  req_data := fnd_conc_global.request_data;
  stage := 0;
  IF (req_data is not null) THEN
    stage := to_number(req_data);
  END IF;

  /* bug 4079902 */
  -- bug 4398179. Moved the fix here because the CLEANUP_SSM requires l_content_src_type
  SELECT SST_FLAG into l_sst_flag
  FROM HZ_ORIG_SYSTEMS_B
  WHERE ORIG_SYSTEM=P_ORIG_SYSTEM
  AND STATUS='A';
  
  IF l_sst_flag='Y'
  THEN
   l_content_src_type := P_ORIG_SYSTEM; 
  ELSE
   l_content_src_type := 'USER_ENTERED';
  END IF; 

  IF stage = 2 THEN 
    /* delete duplicate record in sg with same int_row_id. This would happen
       when party loading for 1 worker finishes before the relationship matching 
       another worker. Therefore when the latter worker is matching the object party
       it finds multiple active entries in the SSM table. Therefore due to the outer 
       joins which are used in SSM matching, it results in muliple duplicate rows 
       in relationship staging table. 
    */

    delete /*+ ROWID(SG) push_subq */ from hz_imp_relships_sg SG
    where batch_id = P_BATCH_ID
    and rowid in (
      select /*+ no_merge  */ rowid
      from (
        select /*+ parallel(SG) */ rowid,
               rank() over (partition by int_row_id order by relationship_id desc) rn
        from hz_imp_relships_sg SG
        where batch_id = P_BATCH_ID
        )
      where rn > 1
      );

    IF l_content_src_type = 'DNB' THEN
  /* 
    Fix bug 4175285: Remove potential duplicates in hz_imp_relships_sg after
    matching for DNB. Since parties with same OS+OSR but different party_id
    can exist in a batch, when we do matching, duplicate records may be
    created. E.g.
    There are 3 parties in a DNB batch:
    OSR     PID
    -----------------
    123     1001
    456     1002
    456     1003
     
    456 is the HQ, domestic and global ultimate of 123. When we do 
    relationship matching, we'll create duplicate rows in rel staging: 
    rel code          sub OSR    obj OSR    sub id    obj id
    --------------------------------------------------------
    HEADQUARTERS_OF   456        123        1002      1001
    HEADQUARTERS_OF   456        123        1003      1001
     
    It is a problem only for DNB OS because we build the DNB hierarchy
    in post-processing. It will cause problem if a party has two HQs.
    For other OS, we'll allow duplicate relationships to be created 
    because the 2nd and 3rd parties are duplicates and so creating 
    relationships to both should not be a problem. Confirmed this with Indrajit.
  */  
  
    delete /*+ ROWID(SG) push_subq */ from hz_imp_relships_sg SG
    where batch_id = P_BATCH_ID
    and sub_orig_system = 'DNB' /* hardcode DNB as it only happens to DNB data */
    and rowid in (
      select /*+ no_merge  */ rowid
      from (
        select /*+ parallel(SG) */ rowid,
               rank() over (partition by relationship_type, relationship_code, sub_orig_system_reference, obj_id
                      order by sub_id desc) rn
        from hz_imp_relships_sg SG
        where batch_id = P_BATCH_ID
        and sub_orig_system = 'DNB'
        )
      where rn > 1
      );
    END IF; 
  END IF;
 
  l_profile_version_prof := NVL(FND_PROFILE.value('HZ_PROFILE_VERSION'), 'ONE_DAY_VERSION');

  /* If it's after stage 1 then
       if batch status = ACTION_REQUIRED, this run is for
         what-if analysis and is done, exit.
       if batch status = COMPL_ERROR_LIMIT, error limit
         is reached, exit.
     These two status can only be set in stage 2 and 3. */
  if stage > 1 AND
    (l_batch_status = 'ACTION_REQUIRED'
     OR l_batch_status = 'COMPL_ERROR_LIMIT') then
      retcode := 0;
      IF l_batch_status = 'ACTION_REQUIRED' 
      THEN
         CLEANUP_DUP_OSR(P_BATCH_ID,P_BATCH_MODE_FLAG,'ADDRESS',P_ORIG_SYSTEM);
      ELSIF l_batch_status = 'COMPL_ERROR_LIMIT' THEN
        /*FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error limit reached: Clean up staging tables.');
         CLEANUP_STAGING(P_BATCH_ID, P_BATCH_MODE_FLAG); */
        CLEANUP_SSM(l_content_src_type,P_BATCH_ID,P_BATCH_MODE_FLAG,P_ORIG_SYSTEM,P_REQUEST_ID);
        GENERATE_ERRORS(P_BATCH_ID, P_REQUEST_ID, P_ORIG_SYSTEM, P_RERUN_FLAG, 'N');
               
        IF stage>=2 AND 
           ( P_WHAT_IF_ANALYSIS is null 
           OR (P_WHAT_IF_ANALYSIS is not null AND P_WHAT_IF_ANALYSIS<>'A'))
         AND GET_COUNTS(P_BATCH_ID)='Y'
        THEN
           HZ_IMP_LOAD_BATCH_COUNTS_PKG.post_import_counts(P_BATCH_ID, P_ORIG_SYSTEM,
                               P_BATCH_MODE_FLAG,P_REQUEST_ID,  P_RERUN_FLAG);
        END IF;
        
      END IF;
      RETURN;
  end if;

  /* If it's after stage 0 and batch status is not PROCESSING,
     some exceptions occur from some later stage and hence exit.
     Error may occur in any of the 3 stages. */
  if stage > 0 and l_batch_status <> 'PROCESSING' then
           
    CLEANUP_SSM(l_content_src_type,P_BATCH_ID,P_BATCH_MODE_FLAG,P_ORIG_SYSTEM,P_REQUEST_ID);
    GENERATE_ERRORS(P_BATCH_ID, P_REQUEST_ID, P_ORIG_SYSTEM, P_RERUN_FLAG, 'N');
           
        IF stage>=2 AND 
           ( P_WHAT_IF_ANALYSIS is null 
           OR (P_WHAT_IF_ANALYSIS is not null AND P_WHAT_IF_ANALYSIS<>'A'))
         AND GET_COUNTS(P_BATCH_ID)='Y'
        THEN
           HZ_IMP_LOAD_BATCH_COUNTS_PKG.post_import_counts(P_BATCH_ID, P_ORIG_SYSTEM,
                               P_BATCH_MODE_FLAG,P_REQUEST_ID,  P_RERUN_FLAG);
        END IF;

    retcode := 2;
    RETURN;
  end if;

  /* Save who column values in variables for performance */
  l_user_id := NVL(FND_GLOBAL.user_id,-1);
  l_resp_appl_id := hz_utility_v2pub.application_id;
  l_last_update_login := hz_utility_v2pub.last_update_login;
  l_g_miss_num := NVL(FND_PROFILE.value('HZ_IMP_G_MISS_NUM'), -9999);
  l_g_miss_char := NVL(FND_PROFILE.value('HZ_IMP_G_MISS_CHAR'), '!');
  l_g_miss_date := NVL(to_date(FND_PROFILE.value('HZ_IMP_G_MISS_DATE'), 'DD/MM/YYYY'),
                       to_date('01/01/4000', 'DD/MM/YYYY'));
  l_flex_validation_prof := NVL(FND_PROFILE.value('HZ_IMP_FLEX_VALIDATION'), 'N');
  l_dss_security_prof := NVL(FND_PROFILE.value('HZ_IMP_DSS_SECURITY'), 'N');
  l_allow_disabled_lookup_prof := NVL(FND_PROFILE.value('HZ_IMP_ALLOW_DISABLED_LOOKUP'), 'Y');
  --l_profile_version_prof := NVL(FND_PROFILE.value('HZ_PROFILE_VERSION'), 'ONE_DAY_VERSION');
  l_update_str_addr_prof := NVL(FND_PROFILE.value('HZ_UPDATE_STD_ADDRESS'), 'N');
  l_maintain_loc_hist_prof := NVL(FND_PROFILE.value('HZ_MAINTAIN_LOC_HISTORY'), 'Y');
  l_allow_addr_corr_prof := NVL(FND_PROFILE.value('HZ_IMP_ALLOW_ADDR_CORRECTION'), 'Y');

  /* Hardcode date format mask as P_SYSDATE is passed from main
     wrapper and it hardcodes with this date format */
  D_SYSDATE := TO_DATE(P_SYSDATE,'DD-MM-YY HH24:MI:SS');

  /* Check if 3rd party data */
--  l_content_src_type := GET_CONTENT_SRC_TYPE(P_ORIG_SYSTEM);

  IF stage = 0 THEN
    IF P_RERUN_FLAG <> 'R' THEN   -- Regular process if not resume
      

      /* Add policy function if not exists */
      
      IF l_content_src_type <> 'USER_ENTERED' AND
        NVL(fnd_profile.value('HZ_DNB_POLICY_EXIST'), 'N') = 'N' THEN

        /* bug fix 3849232 - add policy  functions unconditionally  */
        add_policy();
      END IF;
      
 
      /* Check HR security */
      IF NVL(FND_PROFILE.value('HZ_IMP_HR_SECURITY'), 'N') = 'Y' THEN
        -- ARH2RGVB.pls
        /*
          check in the Parties Interface Table if there are any records
          with OS='DEFAULT' and OSR = 'PER%' (because that's how HR data
          is migrated to SSM model). If there are such records, exit
          the process with Error.
        */

        OPEN c_hr_data(P_BATCH_ID);
        FETCH  c_hr_data INTO l_hr_data_exists;
        CLOSE c_hr_data;

        IF l_hr_data_exists = 'Y' THEN
          FND_MESSAGE.SET_NAME('AR', 'HZ_IMP_NO_HR_DATALOAD');
          l_error_message := FND_MESSAGE.get;

          FND_FILE.PUT_LINE(FND_FILE.LOG, 'log:' || l_error_message);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, l_error_message);
          update_import_status(P_BATCH_ID, 'ERROR');

          errbuf  := l_error_message;
          retcode := 2;
          RETURN;
        END IF;

      END IF;  -- HR security

      /* Cleanup staging */
      /* CLEANUP_STAGING(P_BATCH_ID, P_BATCH_MODE_FLAG); */
    END IF; -- P_RERUN_FLAG <> 'R'
  END IF; -- stage = 0

  stage := stage + 1; -- proceed to next stage
  IF (stage=1) THEN

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'WRP:Stage 1, P_RERUN_FLAG: ' || P_RERUN_FLAG,
                   p_prefix =>'',
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    /* Update batch summary status to PROCESSING */
    update_import_status(P_BATCH_ID, 'PROCESSING');
    /* Increase sequence number cache size */
    ALTER_SEQUENCES('I', P_BATCH_MODE_FLAG);
  
    OPEN c_invalid_pid(P_BATCH_ID);
    FETCH c_invalid_pid INTO l_num_invalid_pid;
    CLOSE c_invalid_pid;
    
    IF l_num_invalid_pid > 0 THEN
      l_error_message := 'Invalid party_id(s) is found in hz_imp_parties_int that does not exist in hz_parties. Please correct the party_id and resubmit the batch for import.';
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'log:' || l_error_message);
      update_import_status(P_BATCH_ID, 'ERROR');
  
      errbuf  := l_error_message;
      retcode := 2;    
      RETURN;
    END IF;

    IF P_BATCH_MODE_FLAG = 'Y' AND P_RERUN_FLAG = 'N' THEN 
    --  Analyze interface tables 
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Analyze all interface tables ' ||  
       to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS')); 
              
      -- OFFICE DEPOT CHANGES 
      -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_PARTIES_INT'); 
      -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_ADDRESSES_INT'); 
      -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_ADDRESSUSES_INT'); 
      -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_CLASSIFICS_INT'); 
      -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_CONTACTPTS_INT'); 
      -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_CONTACTROLES_INT'); 
      -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_CONTACTS_INT'); 
      -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_CREDITRTNGS_INT'); 
      -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_FINNUMBERS_INT'); 
      -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_FINREPORTS_INT'); 
      -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_RELSHIPS_INT'); 
    END IF;   
 
    /* Stage 1 preprocess before calling parties matching */
    IF P_RERUN_FLAG = 'U' OR P_RERUN_FLAG = 'L' THEN

      /* Clean up any processing work units */
      UPDATE hz_imp_work_units
      SET status = 'C', stage = stage - 1
      WHERE batch_id = P_BATCH_ID
      and status = 'P';

      /* Keep track of the high water mark stage such that when we do V+DML,
         the appropriate records are picked up. Stage 2 workers check if stage <
         hwm stage, if so it will pick up the corrected records ("C" interface status).
         Else it will pick up the null interface status records. */
      UPDATE hz_imp_work_units
      SET hwm_stage = case when nvl(hwm_stage, 0) > stage
       then hwm_stage else stage end
      WHERE batch_id = P_BATCH_ID;

      /* Reset all stage to 0 to redo all matching because the staging tables are
         always cleaned up except for resume of what-if */
      UPDATE hz_imp_work_units
      SET stage = 0
      WHERE batch_id = P_BATCH_ID;

      /* If previous run is not successful, reset the postprocessing status
         of work units to prepare for processing in the current run */
      IF P_RERUN_FLAG = 'U' THEN
        RESET_PP_WU(P_BATCH_ID);
      END IF;

      /* Clean up staging if old data from previous run exists. If error
         happens in stage 3 and by the time the batch is resubmitted, all the
         staging data from previous runs are there, we may get unique index 
         failure when we redo matching for some of the failed work units since
         we'll insert the exact same row into staging tables. */
      CLEANUP_STAGING(P_BATCH_ID, P_BATCH_MODE_FLAG);
      
    ELSIF P_RERUN_FLAG = 'R' THEN
      /* Check if data present in staging. If so,
         go to stage 2. Reset the stage so that WUs
         will be worked on by the appropriate workers.
         Else go to stage 1 to redo matching.
      */
      IF STAGING_DATA_EXISTS(P_BATCH_ID, P_BATCH_MODE_FLAG, 1) = 'Y' THEN

        UPDATE hz_imp_work_units
        SET stage = 1, status = 'C'
        WHERE batch_id = P_BATCH_ID;

        stage := 2; /* Skip stage 1 matching */
      ELSE

        UPDATE hz_imp_work_units
        SET stage = 0, status = 'C'
        WHERE batch_id = P_BATCH_ID;

   /* If this is batch mode, clean up staging tables to handle the case of:
      Run what-if for batch 1
      Run what-if for batch 2
      Resume batch 1, but batch 2 staging data is still there */
   IF P_BATCH_MODE_FLAG = 'Y' THEN
     CLEANUP_STAGING(P_BATCH_ID, 'Y');
   END IF;

      END IF;
    END IF;

  
  elsif (stage=2) then
    FND_FILE.PUT_LINE(FND_FILE.LOG, '****** Finished processing stage 1 ');

    CLEANUP_DUP_OSR(P_BATCH_ID,P_BATCH_MODE_FLAG,'PARTY',P_ORIG_SYSTEM);

    /*  Matching of other entities, DQM, V+DML of Parties */
      IF P_BATCH_MODE_FLAG = 'Y' THEN 
       --  Analyze parties staging after matching 
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Analyze party staging table ' ||  
           to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS')); 
        -- OFFICE DEPOT CHANGES    
        -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_PARTIES_SG', percent=>10, degree=>4); 
       END IF; 

  elsif (stage=3) then
      FND_FILE.PUT_LINE(FND_FILE.LOG, '****** Finished processing stage 2 ');
      -- Bug 5264069
      CLEANUP_DUP_OSR(P_BATCH_ID,P_BATCH_MODE_FLAG,'ADDRESS',P_ORIG_SYSTEM);

      IF P_BATCH_MODE_FLAG = 'Y' THEN 
       --  Analyze staging table after matching 
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Analyze other entity staging tables ' ||  
           to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS')); 
        -- OFFICE DEPOT CHANGES  
        -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_ADDRESSES_SG', percent=>5, degree=>4); 
        -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_ADDRESSUSES_SG', percent=>5, degree=>4); 
        -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_CLASSIFICS_SG', percent=>5, degree=>4); 
        -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_CONTACTPTS_SG', percent=>5, degree=>4); 
        -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_CONTACTROLES_SG', percent=>5, degree=>4); 
        -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_CONTACTS_SG', percent=>5, degree=>4); 
        -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_CREDITRTNGS_SG', percent=>5, degree=>4); 
        -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_FINNUMBERS_SG', percent=>5, degree=>4); 
        -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_FINREPORTS_SG', percent=>5, degree=>4); 
        -- fnd_stats.gather_table_stats('AR', 'HZ_IMP_RELSHIPS_SG', percent=>5, degree=>4); 
        -- fnd_stats.gather_table_stats('AR', 'HZ_ORIG_SYS_REFERENCES', percent=>5, degree=>4); 
       END IF; 
    
    -- get the start error_id sequence number
    SELECT hz_imp_errors_s.NEXTVAL INTO l_start_error_id FROM dual;
 
  /* Dup check of relationships and address uses within interface, 
     V+DML of other entities, PP-Wait */
    ident_dup_within_int(P_BATCH_ID, P_ORIG_SYSTEM, P_BATCH_MODE_FLAG, P_REQUEST_ID,
             D_SYSDATE, l_user_id, l_last_update_login,
             P_PROGRAM_APPLICATION_ID, P_PROGRAM_ID);   
             
    SELECT hz_imp_errors_s.CURRVAL INTO l_current_error_id FROM dual;

    -- if error is greater than error limit
    IF l_current_error_id - l_start_error_id > 
       NVL(P_ERROR_LIMIT, NVL(FND_PROFILE.value('HZ_IMP_ERROR_LIMIT'), 10000)) THEN

      -- update batch summary table and detail table
      -- set status as complete with reaching error limit

      update hz_imp_batch_summary
      set IMPORT_STATUS = 'COMPL_ERROR_LIMIT'
      where BATCH_ID = P_BATCH_ID;

      UPDATE hz_imp_batch_details
      SET import_status = 'COMPL_ERROR_LIMIT'
      WHERE batch_id = P_BATCH_ID
      AND run_number = (SELECT max(run_number)
                 FROM hz_imp_batch_details
                 WHERE batch_id = P_BATCH_ID);
      COMMIT;
      
      retcode := 2;
        IF P_WHAT_IF_ANALYSIS is null 
           OR (P_WHAT_IF_ANALYSIS is not null AND P_WHAT_IF_ANALYSIS<>'A')
           AND GET_COUNTS(P_BATCH_ID)='Y'
        THEN
           HZ_IMP_LOAD_BATCH_COUNTS_PKG.post_import_counts(P_BATCH_ID, P_ORIG_SYSTEM,
                               P_BATCH_MODE_FLAG,P_REQUEST_ID,  P_RERUN_FLAG);
        END IF;

      /*FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error limit reached: Clean up staging tables.');
       CLEANUP_STAGING(P_BATCH_ID, P_BATCH_MODE_FLAG); */
      GENERATE_ERRORS(P_BATCH_ID, P_REQUEST_ID, P_ORIG_SYSTEM, P_RERUN_FLAG, 'N');
      RETURN;
      
    END IF;

    elsif (stage>TOTAL_NUM_STAGES) then
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'WRP:All stages done: Start Postprocessing Wait',
                   p_prefix =>'',
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    /* Update displayed duns party id. Originally done in PP-Wait */
    IF P_ORIG_SYSTEM = 'DNB' THEN
      UPDATE_DISPLAYED_DUNS_PID(P_BATCH_ID, P_BATCH_MODE_FLAG);
    END IF;

    /* Populate error tables with data from temp error table */
    GENERATE_ERRORS(P_BATCH_ID, P_REQUEST_ID, P_ORIG_SYSTEM, P_RERUN_FLAG, 'Y');

    /* Clean up Staging table */
    /* CLEANUP_STAGING(P_BATCH_ID, P_BATCH_MODE_FLAG); */

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'WRP:Staging table cleaned up',
                   p_prefix =>'',
                   p_msg_level=>fnd_log.level_statement);
    END IF;
    /* Delete Work Unit */
    /* delete hz_imp_work_units where batch_id = P_BATCH_ID;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'WRP:work united deleted',
                   p_prefix =>'',
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    /* Update import status */
    /* Check if any error in current run. If so, update import_status in
       both batch summary and details to COMPL_ERRORS. */
    OPEN c_error(P_BATCH_ID, P_REQUEST_ID);
    FETCH  c_error INTO l_err_exists;
    CLOSE c_error;
    if l_err_exists = 'Y' then
      update_import_status(P_BATCH_ID, 'COMPL_ERRORS');
    else
      /* If no error in current run, check if there is any error records in
         all the interface tables. If so, set batch_summary import_status to
         COMPL_ERRORS and batch_details import_status to COMPLETED.
         Else set both import_status in batch_summary and batch_details
         to COMPLETED */
      OPEN c_batch_error(P_BATCH_ID);
      FETCH  c_batch_error INTO l_err_exists;
      CLOSE c_batch_error;

      if l_err_exists = 'Y' then
        update_import_status(P_BATCH_ID, 'COMPL_ERRORS2');
      else
        update_import_status(P_BATCH_ID, 'COMPLETED');
      end if;
    end if;
    /* Reset sequence number cache size to 20 */
    ALTER_SEQUENCES('R', P_BATCH_MODE_FLAG);

    CLEANUP_SSM(l_content_src_type,P_BATCH_ID,P_BATCH_MODE_FLAG,P_ORIG_SYSTEM,P_REQUEST_ID);

    /* Update counts in batch summary */

    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:post_import_counts()+',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
    END IF;

    HZ_IMP_LOAD_BATCH_COUNTS_PKG.post_import_counts(P_BATCH_ID, P_ORIG_SYSTEM,
                               P_BATCH_MODE_FLAG,P_REQUEST_ID,  P_RERUN_FLAG);

    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:post_import_counts()-',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
    END IF;

    /* Give warning if no records are imported. Need to check only
       for a new batch because if it is a rerun, total_records_imported is
       greater than 0 */
    IF P_RERUN_FLAG = 'N' THEN
      select nvl(total_records_imported, 0)
      into l_total_records_imported
      from hz_imp_batch_summary
      where batch_id = P_BATCH_ID;

      IF l_total_records_imported <= 0 THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Warning: No data is imported by the batch.');
      END IF;
    END IF;

    -- all stages have finished
    errbuf  := 'All stages of Data Import have finished.';
    retcode := 0;
    RETURN;
  end if;
  -- kick off all concurrent workers
  FOR i IN 1..P_NUM_OF_WORKERS LOOP

    -- submit request for each worker process
    IF (stage=1) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, '****** Submitted stage 1 for worker no. '||to_char(i));
      l_request_id := FND_REQUEST.SUBMIT_REQUEST(
                        'AR', 'ARHLSG1W',
                        'Worker '||i,
                        SYSDATE,
                        TRUE,
                        P_BATCH_ID,
                        l_content_src_type,
                        P_RERUN_FLAG,
                        P_BATCH_MODE_FLAG
                      );


    ELSIF (stage=2) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, '****** Submitted stage 2 for worker no. '||to_char(i));
      l_request_id := FND_REQUEST.SUBMIT_REQUEST(
                        'AR', 'ARHLSG2W',
                        'Worker '||i,
                        SYSDATE,
                        TRUE,
                        P_BATCH_ID,
                        l_content_src_type,
                        P_RERUN_FLAG,
                        NVL(P_ERROR_LIMIT, NVL(FND_PROFILE.value('HZ_IMP_ERROR_LIMIT'), 10000)),
                        P_BATCH_MODE_FLAG,
                        l_user_id,
         --bug 3932987
         --D_SYSDATE,
         to_char(D_SYSDATE,'DD-MM-YY HH24:MI:SS'),
         l_last_update_login,
         P_PROGRAM_ID,
         P_PROGRAM_APPLICATION_ID,
         P_REQUEST_ID,
                     l_resp_appl_id,
                     l_g_miss_char,
                     l_g_miss_num,
                     l_g_miss_date,
         l_flex_validation_prof,
         l_dss_security_prof,
         l_allow_disabled_lookup_prof,
         l_profile_version_prof,
         P_WHAT_IF_ANALYSIS,
         P_REGISTRY_DEDUP,
         P_REGISTRY_DEDUP_MATCH_RULE_ID
                      );


    ELSIF (stage=3) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, '****** Submitted stage 3 for worker no. '||to_char(i));
      l_request_id := FND_REQUEST.SUBMIT_REQUEST(
                        'AR', 'ARHLSG3W',
                        'Worker '||i,
                        SYSDATE,
                        TRUE,
                        P_BATCH_ID,
                        l_content_src_type,
                        P_RERUN_FLAG,
                        NVL(P_ERROR_LIMIT, NVL(FND_PROFILE.value('HZ_IMP_ERROR_LIMIT'), 10000)),
                        P_BATCH_MODE_FLAG,
                        l_user_id,
         --bug 3932987
         --D_SYSDATE,
         to_char(D_SYSDATE,'DD-MM-YY HH24:MI:SS'),
         l_last_update_login,
         P_PROGRAM_ID,
         P_PROGRAM_APPLICATION_ID,
         P_REQUEST_ID,
                     l_resp_appl_id,
                     l_g_miss_char,
                     l_g_miss_num,
                     l_g_miss_date,
         l_flex_validation_prof,
         l_dss_security_prof,
         l_allow_disabled_lookup_prof,
         l_profile_version_prof,
         l_update_str_addr_prof,
         l_maintain_loc_hist_prof,
         l_allow_addr_corr_prof
                      );
    END IF;
    if (l_request_id is null or l_request_id=0) then
       l_error_message := FND_MESSAGE.get;
       errbuf  := l_error_message;
       retcode := 2;
       RETURN;
    end if;
  END LOOP; -- submitting workers
  -- set main program to pause mode
  fnd_conc_global.set_req_globals(conc_status  => 'PAUSED',
                                  request_data => TO_CHAR(stage)) ;

  errbuf  := 'Concurrent Workers submitted.';
  retcode := 0;
  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'WRP:DATA_LOAD()-',
                          p_prefix=>'',
                p_msg_level=>fnd_log.level_procedure);
  END IF;
  RETURN;
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE between -1899 and -1800 THEN
      FND_MESSAGE.SET_NAME('AR', 'HZ_IMP_INVALID_DATE_FORMAT');
    ELSE
      FND_MESSAGE.SET_NAME('AR', 'HZ_API_OTHERS_EXCEP');
      FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
    END IF;
    l_error_message := FND_MESSAGE.get;
    errbuf  := l_error_message;
    retcode := 2;
  FND_FILE.PUT_LINE(FND_FILE.LOG, '******* Unexpected Error occured in stage '||to_char(stage)||' if worker submitted. Else it may have occured before submitting stage '||to_char(stage)||' in the main wrapper');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '******* Unexpected error: ' || SQLERRM);
  FND_FILE.PUT_LINE(FND_FILE.LOG, '******* Other errors: '|| l_error_message);
         
    IF stage>=2 AND 
        ( P_WHAT_IF_ANALYSIS is null 
         OR (P_WHAT_IF_ANALYSIS is not null AND P_WHAT_IF_ANALYSIS<>'A'))
         AND GET_COUNTS(P_BATCH_ID)='Y'
        THEN
           HZ_IMP_LOAD_BATCH_COUNTS_PKG.post_import_counts(P_BATCH_ID, P_ORIG_SYSTEM,
                               P_BATCH_MODE_FLAG,P_REQUEST_ID,  P_RERUN_FLAG);
    END IF;

END DATA_LOAD;

PROCEDURE RETRIEVE_WORK_UNIT(
  P_BATCH_ID                   IN NUMBER,
  P_STAGE                      IN NUMBER,
  P_OS                         IN OUT NOCOPY VARCHAR2,
  P_FROM_OSR                   IN OUT NOCOPY VARCHAR2,
  P_TO_OSR                     IN OUT NOCOPY VARCHAR2,
  P_HWM_STAGE                  OUT NOCOPY NUMBER,
  P_PP_STATUS                  OUT NOCOPY VARCHAR2
) IS
BEGIN
  UPDATE HZ_IMP_WORK_UNITS
    SET STATUS = 'P',
        STAGE = P_STAGE
  WHERE STATUS = 'C'
    AND BATCH_ID = P_BATCH_ID
    AND STAGE = P_STAGE - 1
    AND ROWNUM = 1
  RETURNING ORIG_SYSTEM,
            FROM_ORIG_SYSTEM_REF,
            TO_ORIG_SYSTEM_REF,
            HWM_STAGE,
            POSTPROCESS_STATUS
  INTO P_OS, P_FROM_OSR, P_TO_OSR, P_HWM_STAGE, P_PP_STATUS;
  COMMIT;
END RETRIEVE_WORK_UNIT;

/* Retrieve work units that have completed stage 2 or 3 successfully
   for postprocessing */
PROCEDURE RETRIEVE_PP_WORK_UNIT(
  P_BATCH_ID                   IN NUMBER,
  P_PP_STATUS                  IN VARCHAR2,
  P_OS                         IN OUT NOCOPY VARCHAR2,
  P_FROM_OSR                   IN OUT NOCOPY VARCHAR2,
  P_TO_OSR                     IN OUT NOCOPY VARCHAR2
) IS
BEGIN
  UPDATE HZ_IMP_WORK_UNITS
    SET POSTPROCESS_STATUS = 'P'
  WHERE STATUS = 'C'
    AND BATCH_ID = P_BATCH_ID
    AND STAGE IN (2, 3)
    AND ROWNUM = 1
    AND NVL(POSTPROCESS_STATUS, 'X') = NVL(P_PP_STATUS, 'X')
  RETURNING ORIG_SYSTEM,
            FROM_ORIG_SYSTEM_REF,
            TO_ORIG_SYSTEM_REF
  INTO P_OS, P_FROM_OSR, P_TO_OSR;  
  COMMIT;
END RETRIEVE_PP_WORK_UNIT;

PROCEDURE GENERATE_ENTITIES_WORK_UNITS(
  P_BATCH_ID                      IN NUMBER,
  P_ORIG_SYSTEM                   IN VARCHAR2
) IS

  ENTITIES_WORK_UNIT_H_DML VARCHAR2(32767) :=
 'begin INSERT into hz_imp_work_units
  ( batch_id,
    orig_system,
    from_orig_system_ref,
    to_orig_system_ref,
    status,
    stage
  )
  ( select :1,
           :2,
           min(party_orig_system_reference),
           max(party_orig_system_reference),
           ''C'',
           0
    from
    ( select party_orig_system_reference,
             floor(sum(count(*)) over
               ( order by
                   party_orig_system_reference
                 rows unbounded preceding
               )/:3
             ) wu
      from
      ( -- Party
        select /*+ index_ffs(a,hz_imp_parties_int_u1) parallel_index(a)*/
              party_orig_system_reference
         from hz_imp_parties_int a
        where party_orig_system = :2
          and batch_id=:1
        union all -- Party Site
       select /*+ index_ffs(a,hz_imp_addresses_int_n1) parallel_index(a)*/
              party_orig_system_reference
         from hz_imp_addresses_int a
        where party_orig_system = :2
          and batch_id=:1
        union all -- Contact Points
       select /*+ index_ffs(a,hz_imp_contactpts_int_n1) parallel_index(a)*/
              party_orig_system_reference
         from hz_imp_contactpts_int a
        where party_orig_system = :2
          and batch_id=:1
        union all -- Credit Ratings
       select /*+ index_ffs(a,hz_imp_creditrtngs_int_n1) parallel_index(a)*/
              party_orig_system_reference
         from hz_imp_creditrtngs_int a
        where party_orig_system = :2
          and batch_id=:1
        union all -- Financial Reports
       select /*+ index_ffs(a,hz_imp_finreports_int_n1) parallel_index(a)*/
              party_orig_system_reference
         from hz_imp_finreports_int a
        where party_orig_system = :2
          and batch_id=:1
        union all -- Financial Numbers
       select /*+ index_ffs(a,hz_imp_finnumbers_int_n1) parallel_index(a)*/
              party_orig_system_reference
         from hz_imp_finnumbers_int a
        where party_orig_system = :2
          and batch_id=:1
        union all -- Code Assignments
       select /*+ index_ffs(a,hz_imp_classifics_int_n1) parallel_index(a)*/
              party_orig_system_reference
         from hz_imp_classifics_int a
        where party_orig_system = :2
          and batch_id=:1
        union all -- Relationships
       select /*+ index_ffs(a,hz_imp_relships_int_n1) parallel_index(a)*/
              sub_orig_system_reference party_orig_system_reference
         from hz_imp_relships_int a
        where sub_orig_system = :2
          and batch_id=:1
        union all -- Contacts
       select /*+ index_ffs(a,hz_imp_contacts_int_n1) parallel_index(a)*/
              sub_orig_system_reference party_orig_system_reference
         from hz_imp_contacts_int a
        where sub_orig_system = :2
          and batch_id=:1
        union all -- Contact Roles
       select /*+ index_ffs(a,hz_imp_contactroles_int_n1)
parallel_index(a)*/
              sub_orig_system_reference party_orig_system_reference
         from hz_imp_contactroles_int a
        where sub_orig_system = :2
          and batch_id=:1
        union all -- Address Uses
       select /*+ index_ffs(a,hz_imp_addressuses_int_n1) parallel_index(a)*/
              party_orig_system_reference
         from hz_imp_addressuses_int a
        where party_orig_system = :2
          and batch_id=:1
      )
      group by party_orig_system_reference
    )
    group by wu
  ); end;';

  ENTITIES_WORK_UNIT_L_DML VARCHAR2(32767) :=
 'begin INSERT into hz_imp_work_units
  ( batch_id,
    orig_system,
    from_orig_system_ref,
    to_orig_system_ref,
    status,
    stage
  )
  ( select :1,
           :2,
           min(party_orig_system_reference),
           max(party_orig_system_reference),
           ''C'',
           0
    from
    ( select party_orig_system_reference,
             floor(sum(count(*)) over
               ( order by
                   party_orig_system_reference
                 rows unbounded preceding
               )/:3
             ) wu
      from
      ( -- Party
        select /*+ index(a,hz_imp_parties_int_u1) */
              party_orig_system_reference
         from hz_imp_parties_int a
        where party_orig_system = :2
          and batch_id=:1
        union all -- Party Site
       select /*+ index(a,hz_imp_addresses_int_n1) */
              party_orig_system_reference
         from hz_imp_addresses_int a
        where party_orig_system = :2
          and batch_id=:1
        union all -- Contact Points
       select /*+ index(a,hz_imp_contactpts_int_n1) */
              party_orig_system_reference
         from hz_imp_contactpts_int a
        where party_orig_system = :2
          and batch_id=:1
        union all -- Credit Ratings
       select /*+ index(a,hz_imp_creditrtngs_int_n1) */
              party_orig_system_reference
         from hz_imp_creditrtngs_int a
        where party_orig_system = :2
          and batch_id=:1
        union all -- Financial Reports
       select /*+ index(a,hz_imp_finreports_int_n1) */
              party_orig_system_reference
         from hz_imp_finreports_int a
        where party_orig_system = :2
          and batch_id=:1
        union all -- Financial Numbers
       select /*+ index(a,hz_imp_finnumbers_int_n1) */
              party_orig_system_reference
         from hz_imp_finnumbers_int a
        where party_orig_system = :2
          and batch_id=:1
        union all -- Code Assignments
       select /*+ index(a,hz_imp_classifics_int_n1) */
              party_orig_system_reference
         from hz_imp_classifics_int a
        where party_orig_system = :2
          and batch_id=:1
        union all -- Relationships
       select /*+ index(a,hz_imp_relships_int_n1) */
              sub_orig_system_reference party_orig_system_reference
         from hz_imp_relships_int a
        where sub_orig_system = :2
          and batch_id=:1
        union all -- Contacts
       select /*+ index(a,hz_imp_contacts_int_n1) */
              sub_orig_system_reference party_orig_system_reference
         from hz_imp_contacts_int a
        where sub_orig_system = :2
          and batch_id=:1
        union all -- Contact Roles
       select /*+ index(a,hz_imp_contactroles_int_n1) */
              sub_orig_system_reference party_orig_system_reference
         from hz_imp_contactroles_int a
        where sub_orig_system = :2
          and batch_id=:1
        union all -- Address Uses
       select /*+ index(a,hz_imp_addressuses_int_n1) */
              party_orig_system_reference
         from hz_imp_addressuses_int a
        where party_orig_system = :2
          and batch_id=:1
      )
      group by party_orig_system_reference
    )
    group by wu
  ); end;';

  P_VOLUME_FLAG                VARCHAR2(1) := 'H'; -- 'H' High Volume, 'L' Low Volume
  WORK_UNIT_DML                VARCHAR2(32767) := ENTITIES_WORK_UNIT_H_DML;
  profile_unit_size            VARCHAR2(10);
  unit_size NUMBER;
  est_count NUMBER;
  party_count NUMBER;
  l_bool BOOLEAN;
  l_status VARCHAR2(255);
  l_schema VARCHAR2(255);
  l_tmp    VARCHAR2(2000);

BEGIN

  -- retrieve profile option of work unit size
  profile_unit_size := NVL(FND_PROFILE.value('HZ_IMP_WORK_UNIT_SIZE'),
                           to_char(WORK_UNIT_CAP_SIZE));
  unit_size := to_number(profile_unit_size);
  if(unit_size>WORK_UNIT_CAP_SIZE or
     unit_size<=0) then
    unit_size := WORK_UNIT_CAP_SIZE;
  end if;

  --dbms_output.put_line('unit size:'||unit_size);

  -- compute volume flag
  begin
    select est_no_of_records into est_count
    from HZ_IMP_BATCH_SUMMARY where batch_id = P_BATCH_ID;
  exception
    when others then
      est_count := null;
  end;

  l_bool := fnd_installation.GET_APP_INFO('AR',l_status,l_tmp,l_schema);

  select num_rows into party_count
  from sys.dba_tables where upper(table_name) = 'HZ_IMP_PARTIES_INT'
  and owner = l_schema;

  if(est_count is not null and party_count is not null) then
    if party_count>(est_count*0.15) and party_count>50000 then
      P_VOLUME_FLAG := 'H';
    else
      P_VOLUME_FLAG := 'L';
    end if;
  end if;

  if(P_VOLUME_FLAG='L') then
    WORK_UNIT_DML := ENTITIES_WORK_UNIT_L_DML;
  end if;
  EXECUTE IMMEDIATE WORK_UNIT_DML USING P_BATCH_ID,
                                        P_ORIG_SYSTEM,
                                        unit_size;
  COMMIT;

END GENERATE_ENTITIES_WORK_UNITS;


FUNCTION STAGING_DATA_EXISTS(
  P_BATCH_ID         IN NUMBER,
  P_BATCH_MODE_FLAG  IN VARCHAR2,
  P_STAGE            IN NUMBER
) RETURN VARCHAR2 IS

  CURSOR c_what_if_sg_data(p_batch_id number, p_batch_mode_flag varchar2) IS
    SELECT 'Y'
    FROM dual
    WHERE EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_PARTIES_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_ADDRESSES_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_CONTACTPTS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_CREDITRTNGS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_FINREPORTS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_FINNUMBERS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_CLASSIFICS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_RELSHIPS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_CONTACTROLES_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_CONTACTS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_ADDRESSUSES_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1);

  CURSOR c_what_if_sg_data2(p_batch_id number, p_batch_mode_flag varchar2) IS

    SELECT 'Y'
    FROM dual
    WHERE EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_ADDRESSES_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_CONTACTPTS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_CREDITRTNGS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_FINREPORTS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_FINNUMBERS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_CLASSIFICS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_RELSHIPS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_CONTACTROLES_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_CONTACTS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_ADDRESSUSES_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1);

  l_what_if_sg_data_exists VARCHAR2(1);

BEGIN

  IF P_STAGE <= 1 THEN
    OPEN c_what_if_sg_data(P_BATCH_ID, P_BATCH_MODE_FLAG);
    FETCH c_what_if_sg_data INTO l_what_if_sg_data_exists;
    CLOSE c_what_if_sg_data;
  ELSE
    OPEN c_what_if_sg_data2(P_BATCH_ID, P_BATCH_MODE_FLAG);
    FETCH c_what_if_sg_data2 INTO l_what_if_sg_data_exists;
    CLOSE c_what_if_sg_data2;
  END IF;

  RETURN NVL(l_what_if_sg_data_exists, 'N');
END STAGING_DATA_EXISTS;

END HZ_IMP_LOAD_WRAPPER;
/
COMMIT;
EXIT;
