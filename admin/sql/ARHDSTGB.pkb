/*=======================================================================+
 |  Copyright (c) 1995 Oracle Corporation Redwood Shores, California, USA|
 |                            All rights reserved.                       |
 +=======================================================================+
 | FILENAME
 |   ARHDSTGB.pls
 |  Arguments:                                                           
 |       1 - userid =  ar                                                
 |
 | DESCRIPTION
 |   PL/SQL body for package HZ_PARTY_STAGE
 |
 | NOTES
 |   MODIFICATION HISTORY 
 |    Srinivasa Rangan 16-APR-01  Created
 |    Jyoti Pandey      25-JUN_2002 Bug:2395186 Modified alter index to use  
 |                                  Ctx_Ddl.Sync_Index  by calling ar.hz_dqm_sync_index
 |    Srinivasa Rangan  28-JUN-2002 Fixed bug 2435335. Make insert_xxx_rec ignore
 |                                  unique index violations
 |    Srinivasa Rangan	14-AUG-2002 Rewrite of major portions of code to improve performance. 
 |                                  - Additional Procedures being generated in HZ_STAGE_MAP_TRANSFORM
 |                                    for bulk fetch and insert during staging.
 |                                  - Modified Stage_worker procedure to use the new generated 
 |                                    procedures. 
 |                                  - Modified continue option for being able to continue precisely
 |                                    and also for restart of index creation if it failed. Uses
 |                                    table HZ_DQM_STAGE_LOG 
 |                                  - Additional parameters to stagin program 
 |                                    1. For specifying if index is to be created in serial or parallel. 
 |                                    2. Specifying which tablespace to create indexes
 |    Anupam Bordia     11-SEP-2002  Bug#2393963.  Adding private procedure gather_stats to gather statistics
 |                                      for all four staged tables to help CBO run efficient queries.
 |    Anupam Bordia     27-SEP-2002  Bug#2453572.  Adding private procedure get_size(), modifying
 |                                     code in procedure stage, to utilize ESTIMATE_SIZE option from
 |                                     concurrent program.  sizing_factor needs to be refined further.
 |    Anupam Bordia     22-OCT-2002  Bug#2636144.  Moving call for method gather_stats.
 |    Srinivasa Rangan  06-Jan-2003  Use field_section_groups instead of zone if
 |                                   number of indexed attributes < 64. These
 |                                   perform better than zone sections
 |    Srinivasa Rangan  07-FEB-2003  HZ.K Changes
 |                                   1. Denormalize transformations to HZ_STAGED_PARTIES
 |                                   2. Generate user_datastore procedures for DQM indexes
 |                                   3. Index by Attribute ID sections, instead of Transformation 
 |                                      staged column
 |                                   4. Always generate section groups
 |    P.Suresh          06-MAY-2003  Bug No : 2943458. Added CTXSYS schema name
 |                                   before the datastore in the create_pref
 |                                   procedure.
 |    Srini Rangan      14-OCT-2003  Fixes for 24/7 support suring stage new. 
 |    Ramesh Ch		    09-SEP-2004  Bug No :3839889.Fixed the GSCC errors.
 |    Ramesh Ch		    23-SEP-2004  Bug No :3907584.Updated the STAGE_FLAG in HZ_TRANS_FUNCTIONS_B
 |				                     to 'N' while running staging program.This will control the realtime
 |				                     sync program.
 |    Pranav   		    25-NOV-2004  Bug No :4813809.Fixed the GSCC errors,
 |				                     by changing NOLOGGING to LOGGING.
 |	  Ravi Epuri        08-DEC-2005  Fix for bug 4778420. (One-off on HZ.N).
 |                                   DQM STAGING PROGRAM ERRORS WITH PL/SQL VALUE ERROR ORA-06512
 |                                   Fixed by wrapping the code pertaining to 'l_denorm' variable
 |                                   value assignment into a begin-exception block and setting
 |                                   the denorm value to 'SYNC' if error of sqlcode-6502 occurs.
 |
 |
 |    Rajamahendran         23-AUG-2006  Bug 5374880:Modified procedure generate_contact_pt_query_proc 
 |                                       to select raw_phone_number insted of country code+area code+phone number.                                           
 |			     
 *=======================================================================*/

REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile:~PROD:~PATH:~FILE


SET VERIFY OFF
whenever sqlerror exit failure rollback;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE BODY HZ_PARTY_STAGE AS
/*$Header: ARHDSTGB.pls 115.74.115104.4 2006/08/23 11:58:59 rarajend noship $ */

g_batch_size NUMBER := 10000;
g_num_stage_steps NUMBER := 3;
g_num_stage_new_steps NUMBER := 6;
g_schema_name VARCHAR2(30) ;

PROCEDURE l(str VARCHAR2) IS
BEGIN
  HZ_GEN_PLSQL.add_line(str);
END;

PROCEDURE verify_all_procs;

PROCEDURE create_btree_indexes (p_entity VARCHAR2);

PROCEDURE log(
   message      IN      VARCHAR2,
   newline      IN      BOOLEAN DEFAULT TRUE);

PROCEDURE outandlog(
   message      IN      VARCHAR2,
   newline      IN      BOOLEAN DEFAULT TRUE);

FUNCTION logerror(SQLERRM VARCHAR2 DEFAULT NULL)
         RETURN VARCHAR2;

PROCEDURE generate_map_proc (
   p_entity             IN      VARCHAR2,
   p_proc_name          IN      VARCHAR2,
   p_command            IN      VARCHAR2
);

PROCEDURE gather_stats (
   table_owner          IN      VARCHAR2,
   table_name           IN      VARCHAR2
);

PROCEDURE generate_party_query_proc;
PROCEDURE generate_party_query_upd(x_rebuild_party_idx OUT NOCOPY BOOLEAN);
PROCEDURE generate_declarations;
PROCEDURE generate_ds_proc;
PROCEDURE generate_contact_query_proc;
PROCEDURE generate_contact_query_upd(x_rebuild_contact_idx OUT NOCOPY BOOLEAN);
PROCEDURE generate_contact_pt_query_proc;
PROCEDURE generate_contact_pt_query_upd(x_rebuild_cpt_idx OUT NOCOPY BOOLEAN);
PROCEDURE generate_party_site_query_proc;
PROCEDURE generate_party_site_query_upd(x_rebuild_psite_idx OUT NOCOPY BOOLEAN);

FUNCTION wait_for_request(
    p_request_id NUMBER) RETURN VARCHAR2;

FUNCTION has_trx_context(proc VARCHAR2) RETURN BOOLEAN;
FUNCTION has_context(proc VARCHAR2) RETURN BOOLEAN;
FUNCTION get_size(p_table_name VARCHAR2) RETURN  NUMBER;

procedure create_pref (
        p_ds_name       VARCHAR2,
        p_columns       VARCHAR2) IS
BEGIN
  log ('-----------------------------------------------------------');
  log( 'In create_pref '); -- VJN ADDED
  log ('length of p_columns is ' || length(p_columns) ); -- VJN ADDED
  BEGIN
    ad_ctx_ddl.drop_preference(p_ds_name);
  EXCEPTION
    WHEN OTHERS THEN
      log('exception thrown while dropping preference for ' || p_ds_name );
      null;
  END;
  -- Create preference only if there are any columns to be associated to the preference
  IF length(p_columns) > 0 THEN
    ad_ctx_ddl.create_preference(p_ds_name, 'MULTI_COLUMN_DATASTORE');
    ad_ctx_ddl.set_attribute(p_ds_name,'columns',p_columns);
    log('Preference successfully created for ' || p_ds_name );
  ELSE
    log('Preference ' || p_ds_name || ' not created since there are no associated columns');
  END IF ;

END;

-- THIS WILL CREATE PREFERENCES FOR ALL THE DENORM ATTRIBUTES
-- AT THE DETAIL LEVEL ( PARTY SITES, CONTACTS, CONTACT POINTS )
-- AT EACH LEVEL, THE PREFERENCE WOULD BE USED TO STORE THE CONCATENATION
-- OF THE STAGING COLUMNS OF ALL ACTIVE TRANSFORMATIONS OF A DENORM ATTRIBUTE

PROCEDURE create_denorm_attribute_pref ( p_entity varchar2)
IS
concat_trfn varchar2(2000);
row_count number := 0 ;
BEGIN
log ('--------------------------------------');
log(' Calling create_denorm_attribute_pref for ' || p_entity);
IF p_entity = 'PARTY_SITES'
THEN
        -- SET PREFERENCE FOR PARTY SITE DENORM ATTRIBUTES
        FOR col_cur in
        (
        -- will get all staged attribute columns corresponding to active transformations
        -- that are defined on party site denorm attributes
        SELECT  b.staged_attribute_column as attrib_column
        from HZ_TRANS_ATTRIBUTES_VL a, hz_trans_functions_vl b
        where  a.entity_name = 'PARTY_SITES'
               and nvl(a.denorm_flag,'N') = 'Y'
               and a.attribute_id = b.attribute_id
               and nvl( b.active_flag, 'Y') = 'Y'
               and b.staged_attribute_table = 'HZ_STAGED_PARTY_SITES'
        )
        LOOP
               row_count := row_count + 1 ;
               IF row_count > 1
               THEN
                  concat_trfn := concat_trfn || ' ' || col_cur.attrib_column ;
               ELSE
                  concat_trfn := col_cur.attrib_column ;
               END IF;

END LOOP ;

              create_pref('DENORM_PS', concat_trfn);
ELSIF p_entity = 'CONTACTS'
THEN

            -- SET PREFERENCE FOR CONTACTS DENORM ATTRIBUTES
            FOR col_cur in
            (
            -- will get all staged attribute columns corresponding to active transformations
            -- that are defined on contact denorm attributes
            SELECT  b.staged_attribute_column as attrib_column
            from HZ_TRANS_ATTRIBUTES_VL a, hz_trans_functions_vl b
            where  a.entity_name = 'CONTACTS'
                   and nvl(a.denorm_flag,'N') = 'Y'
                   and a.attribute_id = b.attribute_id
                   and nvl( b.active_flag, 'Y') = 'Y'
                   and b.staged_attribute_table = 'HZ_STAGED_CONTACTS'
            )
            LOOP
                   row_count := row_count + 1 ;
                   IF row_count > 1
                   THEN
                      concat_trfn := concat_trfn || ' ' || col_cur.attrib_column ;
                   ELSE
                      concat_trfn := col_cur.attrib_column ;
                   END IF;

            END LOOP ;

            create_pref('DENORM_CT', concat_trfn);

ELSIF p_entity = 'CONTACT_POINTS'
THEN

              -- SET PREFERENCE FOR CONTACT POINT DENORM ATTRIBUTES
              FOR col_cur in
              (
              -- will get all staged attribute columns corresponding to active transformations
              -- that are defined on contact point denorm attributes
              SELECT  b.staged_attribute_column as attrib_column
              from HZ_TRANS_ATTRIBUTES_VL a, hz_trans_functions_vl b
              where  a.entity_name = 'CONTACT_POINTS'
                     and nvl(a.denorm_flag,'N') = 'Y'
                     and a.attribute_id = b.attribute_id
                     and nvl( b.active_flag, 'Y') = 'Y'
                     and b.staged_attribute_table = 'HZ_STAGED_CONTACT_POINTS'
              )
              LOOP
                     row_count := row_count + 1 ;
                     IF row_count > 1
                     THEN
                        concat_trfn := concat_trfn || ' ' || col_cur.attrib_column ;
                     ELSE
                        concat_trfn := col_cur.attrib_column ;
                     END IF;

              END LOOP ;
              create_pref('DENORM_CPT', concat_trfn);
END IF;

END;

-- WILL RETURN THE STAGING COLUMNS CORRESPONDING TO ALL ACTIVE DENORM ATTRIBUTES
-- THAT ARE NOT IN THE PREFERENCE, BY CONCATENATING THEM WITH A HARCODED || IN BETWEEN
FUNCTION get_missing_denorm_attrib_cols( p_entity varchar2)
RETURN VARCHAR2
IS
cols varchar2(2000);
concat_pref_cols varchar2(2000);
row_count number := 0 ;
BEGIN
log ('--------------------------------------');
IF p_entity = 'PARTY_SITES'
THEN
        BEGIN
        select prv_value into concat_pref_cols
        from ctx_preference_values c
        where prv_preference = 'DENORM_PS'
        and prv_attribute = 'COLUMNS' ;

        EXCEPTION WHEN OTHERS
        THEN
         log('Data not found for DENORM_PS in get_missing_denorm_attrib_cols');
         concat_pref_cols := null ;
        END ;


        FOR col_cur in
        (
        SELECT  b.staged_attribute_column as attrib_column
        from HZ_TRANS_ATTRIBUTES_VL a, hz_trans_functions_vl b
        where  a.entity_name = 'PARTY_SITES'
               and nvl(a.denorm_flag,'N') = 'Y'
               and a.attribute_id = b.attribute_id
               and nvl( b.active_flag, 'Y') = 'Y'
               and b.staged_attribute_table = 'HZ_STAGED_PARTY_SITES'

        )
        LOOP
                -- if any attribute columns do not exist in the preference
                IF instr(concat_pref_cols || ' ', col_cur.attrib_column || ' ') = 0
                THEN
                         row_count := row_count + 1 ;
                         IF row_count > 1
                         THEN
                            cols := cols || '||'' ''||' || col_cur.attrib_column ;
                         ELSE
                            cols := col_cur.attrib_column ;
                         END IF;
                END IF ;
        END LOOP ;
        log('Missing denorm columns after concatenation for' || p_entity || '--' || cols );
        RETURN cols ;
ELSIF p_entity = 'CONTACTS'
THEN
       BEGIN
        select prv_value into concat_pref_cols
        from ctx_preference_values c
        where prv_preference = 'DENORM_CT'
        and prv_attribute = 'COLUMNS' ;

        EXCEPTION WHEN OTHERS
        THEN
         log('Data not found for DENORM_CT in get_missing_denorm_attrib_cols');
         concat_pref_cols := null ;
       END ;


        FOR col_cur in
        (
        SELECT  b.staged_attribute_column as attrib_column
        from HZ_TRANS_ATTRIBUTES_VL a, hz_trans_functions_vl b
        where  a.entity_name = 'CONTACTS'
               and nvl(a.denorm_flag,'N') = 'Y'
               and a.attribute_id = b.attribute_id
               and nvl( b.active_flag, 'Y') = 'Y'
               and b.staged_attribute_table = 'HZ_STAGED_CONTACTS'

        )
        LOOP
                 -- if any attribute columns do not exist in the preference
                IF instr(concat_pref_cols || ' ', col_cur.attrib_column || ' ') = 0
                THEN
                         row_count := row_count + 1 ;
                         IF row_count > 1
                         THEN
                            cols := cols || '||'' ''||' || col_cur.attrib_column ;
                         ELSE
                            cols := col_cur.attrib_column ;
                         END IF;
                END IF ;
        END LOOP ;
        log('Missing denorm columns after concatenation for' || p_entity || '--' || cols );
        RETURN cols ;

ELSIF p_entity = 'CONTACT_POINTS'
THEN
        BEGIN
        select prv_value into concat_pref_cols
        from ctx_preference_values c
        where prv_preference = 'DENORM_CPT'
        and prv_attribute = 'COLUMNS' ;

        EXCEPTION WHEN OTHERS
        THEN
         log('Data not found for DENORM_CPT in get_missing_denorm_attrib_cols');
         concat_pref_cols := null ;
        END ;

        FOR col_cur in
        (
        SELECT  b.staged_attribute_column as attrib_column
        from HZ_TRANS_ATTRIBUTES_VL a, hz_trans_functions_vl b
        where  a.entity_name = 'CONTACT_POINTS'
               and nvl(a.denorm_flag,'N') = 'Y'
               and a.attribute_id = b.attribute_id
               and nvl( b.active_flag, 'Y') = 'Y'
               and b.staged_attribute_table = 'HZ_STAGED_CONTACT_POINTS'

        )
        LOOP
                 -- if any attribute columns do not exist in the preference
                IF instr(concat_pref_cols || ' ', col_cur.attrib_column || ' ') = 0
                THEN
                         row_count := row_count + 1 ;
                         IF row_count > 1
                         THEN
                            cols := cols || '||'' ''||' || col_cur.attrib_column ;
                         ELSE
                            cols := col_cur.attrib_column ;
                         END IF;
                END IF ;
        END LOOP ;
        log('Missing denorm columns after concatenation for' || p_entity || '--' || cols );
        RETURN cols ;
END IF ;

END;

FUNCTION new_transformations_exist (p_entity varchar2)
RETURN BOOLEAN
IS
  l_count NUMBER := 0;
BEGIN
  log ('--------------------------------------');
  SELECT count(1) into l_count
    from hz_trans_attributes_vl a
    where a.entity_name = p_entity
    and exists (
      SELECT 1 from hz_trans_functions_vl f
      where a.attribute_id = f.attribute_id
      and nvl(f.ACTIVE_FLAG,'Y') = 'Y'
      and primary_flag = 'Y'
      AND NVL(STAGED_FLAG,'N') ='N');
  IF l_count > 0
  THEN
    log('There are new transformations that have been created for ' || p_entity );
    RETURN TRUE ;
  ELSE
    log('No new transformations have been created for ' || p_entity );
    RETURN FALSE ;
  END IF ;
END;


PROCEDURE delete_existing_data IS

l_owner VARCHAR2(255);
l_status VARCHAR2(255);
l_owner1 VARCHAR2(255);
l_temp VARCHAR2(255);
BEGIN
   IF (fnd_installation.GET_APP_INFO('AR',l_status,l_temp,l_owner1)) THEN
    select owner into l_owner from sys.all_objects
    where object_name = 'HZ_STAGED_PARTIES' and OBJECT_TYPE = 'TABLE' and owner = l_owner1;
   END IF;
    log('Deleting existing staged data');
    log('Truncating HZ_STAGED_PARTIES .. ', FALSE);
    EXECUTE IMMEDIATE 'TRUNCATE TABLE '||l_owner||'.HZ_STAGED_PARTIES';
    log('Done');

    log('Truncating HZ_STAGED_PARTY_SITES .. ', FALSE);
    EXECUTE IMMEDIATE 'TRUNCATE TABLE '||l_owner||'.HZ_STAGED_PARTY_SITES';
    log('Done');

    log('Truncating HZ_STAGED_CONTACTS .. ', FALSE);
    EXECUTE IMMEDIATE 'TRUNCATE TABLE '||l_owner||'.HZ_STAGED_CONTACTS';
    log('Done');

    log('Truncating HZ_STAGED_CONTACT_POINTS .. ', FALSE);
    EXECUTE IMMEDIATE 'TRUNCATE TABLE '||l_owner||'.HZ_STAGED_CONTACT_POINTS';
    log('Done');

    log('Attempting to truncate HZ_DQM_SYNC_INTERFACE ..',FALSE);
    BEGIN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE '||l_owner||'.hz_dqm_sync_interface';
      log('Done Successfully');
    EXCEPTION
      WHEN OTHERS THEN
        log('Lock on table. Unable to truncate');
    END;

END;

PROCEDURE generate_map_pkg_nolog IS
BEGIN
    HZ_GEN_PLSQL.new('HZ_STAGE_MAP_TRANSFORM', 'PACKAGE BODY');
    l('CREATE OR REPLACE PACKAGE BODY HZ_STAGE_MAP_TRANSFORM AS');

    generate_declarations;
    generate_ds_proc;
    generate_party_query_proc;
    generate_contact_query_proc;
    generate_contact_pt_query_proc;
    generate_party_site_query_proc;

    l('END;');

    HZ_GEN_PLSQL.compile_code;
END;

PROCEDURE get_datastore_cols (
   entity IN VARCHAR2,
   pref_cols OUT NOCOPY VARCHAR2,
   proc_cols OUT NOCOPY VARCHAR2,
   fetch_cols OUT NOCOPY VARCHAR2) IS

FUNCSF BOOLEAN := FALSE;
EXTRAF BOOLEAN := TRUE;
PREFF BOOLEAN := TRUE;

prefattrs VARCHAR2(2000);
prefcols VARCHAR2(500);
extracols VARCHAR2(2000);
fetchcols VARCHAR2(2000);

limit NUMBER := 450;

CURSOR check_ds_misc_tx(p_stg_col varchar2) IS
    select 1 from ctx_preference_values
    where prv_preference =
       decode(entity,'PARTY','HZ_PARTY_DS',
                       'PARTY_SITES','HZ_PARTY_SITE_DS',
                       'CONTACTS','HZ_CONTACT_DS',
                       'CONTACT_POINTS','HZ_CONTACT_POINT_DS',
                       'NOMATCH')
    AND prv_owner = g_schema_name
    AND prv_attribute='COLUMNS'
    AND (upper(prv_value) like '%'||p_stg_col||' %'
         OR upper(prv_value) like '%'||p_stg_col||'||%');

CURSOR check_any_tx(p_ATTRIBUTE_ID NUMBER) IS
  SELECT 1 FROM hz_trans_functions_vl f
  where f.attribute_id = p_attribute_id
  and nvl(f.ACTIVE_FLAG,'Y') = 'Y'
  and primary_flag = 'Y'
  AND NVL(STAGED_FLAG,'N') ='Y';

tmp NUMBER;
BEGIN
log('-------------------------------') ; -- VJN ADDED
log('Inside procedure get_datastore_cols '); -- VJN ADDED

-- Note: For creating preferences in intermedia, using the multicolumn datastore approach
--       the length of the string that connotes the concatenation of the attributes
--       cannot exceed 500 bytes. In other words, limit = the max allowed length of the actual concatenation
--       of the attributes. So, limit +  length of other strings, that are part of the pref value <= 500

-- changed this from 300 to 275, since the denorm part of the party preference itself takes 215
IF entity = 'PARTY' THEN
   limit := 275 ;
 END IF;

 prefcols := '';
 FOR ATTRS IN (
    SELECT ATTRIBUTE_ID
    FROM HZ_TRANS_ATTRIBUTES_VL a
    WHERE ENTITY_NAME = entity
    AND TEMP_SECTION IS NULL
    ORDER BY ATTRIBUTE_ID) LOOP

   prefattrs := '';
   FUNCSF:=FALSE;
   FOR FUNCS IN (
     SELECT STAGED_ATTRIBUTE_COLUMN
     FROM HZ_TRANS_FUNCTIONS_VL f
     WHERE ATTRIBUTE_ID = ATTRS.ATTRIBUTE_ID
     AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
     AND nvl(f.PRIMARY_FLAG,'Y') = 'Y') LOOP

     FUNCSF:=TRUE;

     prefattrs := prefattrs||'||'||FUNCS.STAGED_ATTRIBUTE_COLUMN;
   END LOOP;

   IF FUNCSF THEN
     IF lengthb(prefcols)+lengthb(prefattrs)+5>limit THEN
        IF EXTRAF THEN
            extracols:=replace(substrb(prefattrs,3),'||',',');
            fetchcols:='''<A'||ATTRS.ATTRIBUTE_ID||'>''||rec.'||replace(substrb(prefattrs,3),'||','||rec.')||'||''</A'||ATTRS.ATTRIBUTE_ID||'>''';
            EXTRAF:=FALSE;
        ELSE
            extracols:=extracols||','||replace(substrb(prefattrs,3),'||',',');
            fetchcols:=fetchcols||'||'||'''<A'||ATTRS.ATTRIBUTE_ID||'>''||rec.'||replace(substrb(prefattrs,3),'||','||rec.')||'||''</A'||ATTRS.ATTRIBUTE_ID||'>''';
        END IF;
     ELSE
       IF PREFF THEN
         prefcols := substrb(prefattrs,3)||' A'||ATTRS.ATTRIBUTE_ID;
         PREFF:=FALSE;
       ELSE
         prefcols := prefcols||','||substrb(prefattrs,3)||' A'||ATTRS.ATTRIBUTE_ID;
       END IF;
     END IF;
   END IF;
 END LOOP;


 log('In get_datastore_cols before appending ctxsys procedure sections --- length of prefcols = ' || length(prefcols) ); -- VJN ADDED

 IF entity = 'PARTY' THEN
   prefcols := prefcols||',decode(D_PS,''SYNC'',ctxsys.HZDQM.dps(party_id),D_PS) D_PS, decode(D_CT,''SYNC'',ctxsys.HZDQM.dct(party_id),D_CT) D_CT,decode(D_CPT,''SYNC'',ctxsys.HZDQM.dcpt(party_id),D_CPT) D_CPT';
 END IF;
 IF entity = 'PARTY' THEN
   prefcols := prefcols||',STATUS';
 ELSIF entity = 'CONTACT_POINTS' THEN
   prefcols := prefcols||',CONTACT_POINT_TYPE';
 END IF;
 IF entity = 'PARTY' THEN
     prefcols := prefcols||',ctxsys.HZDQM.mp(ROWID) MS';
 ELSIF entity = 'PARTY_SITES' THEN
     prefcols := prefcols||',ctxsys.HZDQM.mps(ROWID) MS';
 ELSIF entity = 'CONTACTS' THEN
     prefcols := prefcols||',ctxsys.HZDQM.mct(ROWID) MS';
 ELSIF entity = 'CONTACT_POINTS' THEN
     prefcols := prefcols||',ctxsys.HZDQM.mcpt(ROWID) MS';
 END IF;

 IF extracols IS NOT NULL THEN
   EXTRAF := FALSE;
 ELSE
   EXTRAF := TRUE;
 END IF;

 FOR ATTRS IN (
    SELECT ATTRIBUTE_ID, TEMP_SECTION
    FROM HZ_TRANS_ATTRIBUTES_VL a
    WHERE ENTITY_NAME = entity
    ORDER BY ATTRIBUTE_ID) LOOP
   prefattrs := '';
   FUNCSF:=FALSE;
   FOR FUNCS IN (
     SELECT STAGED_ATTRIBUTE_COLUMN
     FROM HZ_TRANS_FUNCTIONS_VL f
     WHERE ATTRIBUTE_ID = ATTRS.ATTRIBUTE_ID
     AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
     AND nvl(f.PRIMARY_FLAG,'Y') = 'Y') LOOP

     IF ATTRS.TEMP_SECTION IS NULL THEN
       OPEN check_any_tx(ATTRS.ATTRIBUTE_ID);
       FETCH check_any_tx INTO tmp;
       IF check_any_tx%FOUND THEN
         CLOSE check_any_tx;
         OPEN check_ds_misc_tx(FUNCS.STAGED_ATTRIBUTE_COLUMN);
         FETCH check_ds_misc_tx INTO tmp;
         IF check_ds_misc_tx%NOTFOUND THEN
            IF instrb(extracols,FUNCS.STAGED_ATTRIBUTE_COLUMN) < 1 THEN
	         FUNCSF:=TRUE;
                 prefattrs := prefattrs||'||'||FUNCS.STAGED_ATTRIBUTE_COLUMN;
            END IF;
         END IF;
         CLOSE check_ds_misc_tx;
       ELSE
         CLOSE check_any_tx;
       END IF;

     ELSE
       FUNCSF:=TRUE;
       prefattrs := prefattrs||'||'||FUNCS.STAGED_ATTRIBUTE_COLUMN;
     END IF;
   END LOOP;

   IF FUNCSF THEN
     IF EXTRAF THEN
          extracols:=replace(substrb(prefattrs,3),'||',',');
          fetchcols:='''<'||nvl(ATTRS.TEMP_SECTION,'A'||ATTRS.ATTRIBUTE_ID)||'>''||rec.'||replace(substrb(prefattrs,3),'||','||rec.')||'||''</'||nvl(ATTRS.TEMP_SECTION,'A'||ATTRS.ATTRIBUTE_ID)||'>''';
          -- extracols := '''<'||nvl(ATTRS.TEMP_SECTION,'A'||ATTRS.ATTRIBUTE_ID)||'>'''||prefattrs||'||''</'||nvl(ATTRS.TEMP_SECTION,'A'||ATTRS.ATTRIBUTE_ID)||'>''';
          EXTRAF:=FALSE;
     ELSE
          extracols:=extracols||','||replace(substrb(prefattrs,3),'||',',');
          fetchcols:=fetchcols||'||'||'''<'||nvl(ATTRS.TEMP_SECTION,'A'||ATTRS.ATTRIBUTE_ID)||'>''||rec.'||replace(substrb(prefattrs,3),'||','||rec.')||'||''</'||nvl(ATTRS.TEMP_SECTION,'A'||ATTRS.ATTRIBUTE_ID)||'>''';
          -- extracols := extracols||'||'||'''<'||nvl(ATTRS.TEMP_SECTION,'A'||ATTRS.ATTRIBUTE_ID)||'>'''||prefattrs||'||''</'||nvl(ATTRS.TEMP_SECTION,'A'||ATTRS.ATTRIBUTE_ID)||'>''';
     END IF;
   END IF;
 END LOOP;


 pref_cols := prefcols;
 proc_cols := extracols;
 fetch_cols := fetchcols;

exception
  when others then
     log('Exception raised in get_datastore_cols for ' || entity ); -- VJN ADDED
     log('Error Message is  ' || SQLERRM ); -- VJN ADDED
    RAISE;
END;


PROCEDURE generate_map_pkg IS
BEGIN
    log('Generating package body for HZ_STAGE_MAP_TRANSFORM');
    HZ_GEN_PLSQL.new('HZ_STAGE_MAP_TRANSFORM', 'PACKAGE BODY');
    l('CREATE OR REPLACE PACKAGE BODY HZ_STAGE_MAP_TRANSFORM AS');

    generate_declarations;
    generate_ds_proc;
    generate_party_query_proc;
    generate_contact_query_proc;
    generate_contact_pt_query_proc;
    generate_party_site_query_proc;

    l('END;');

    log('Compiling package body .. ', false);
    HZ_GEN_PLSQL.compile_code;
    log('Done');
END;

PROCEDURE set_misc (p_entity VARCHAR2) IS
CURSOR check_ds_misc_proc(p_attr_id NUMBER) IS
    select 1 from ctx_preference_values
    where prv_preference =
       decode(p_entity,'PARTY','HZ_PARTY_DS',
                       'PARTY_SITES','HZ_PARTY_SITE_DS',
                       'CONTACTS','HZ_CONTACT_DS',
                       'CONTACT_POINTS','HZ_CONTACT_POINT_DS',
                       'NOMATCH')
    AND prv_owner = g_schema_name
    AND prv_attribute='COLUMNS'
    AND upper(prv_value) like '% A'||p_attr_id||',%';
tmp NUMBER;
l_next_misc NUMBER;
BEGIN
  BEGIN
    SELECT max(to_number(substrb(temp_section,2)))
    INTO l_next_misc
    from hz_trans_attributes_vl a
    where a.entity_name = p_entity
    and a.temp_section IS NOT NULL;
    IF l_next_misc is null THEN
      l_next_misc := 0;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      l_next_misc := 0;
  END;

  FOR ATTRS IN (
    SELECT ATTRIBUTE_ID
    from hz_trans_attributes_vl a
    where a.entity_name = p_entity
    and exists (
      SELECT 1 from hz_trans_functions_vl f
      where a.attribute_id = f.attribute_id
      and nvl(f.ACTIVE_FLAG,'Y') = 'Y'
      and primary_flag = 'Y'
      AND NVL(STAGED_FLAG,'N') ='N')
      AND TEMP_SECTION IS NULL) LOOP
    OPEN check_ds_misc_proc(ATTRS.ATTRIBUTE_ID);
    FETCH check_ds_misc_proc INTO tmp;
    IF check_ds_misc_proc%NOTFOUND THEN
      l_next_misc:=l_next_misc+1;

      UPDATE HZ_TRANS_ATTRIBUTES_B
      SET TEMP_SECTION='M'||l_next_misc
      WHERE ATTRIBUTE_ID = ATTRS.ATTRIBUTE_ID;
    END IF;
    CLOSE check_ds_misc_proc;
  END LOOP;
END;

PROCEDURE generate_map_upd_pkg(
  x_rebuild_party_idx OUT NOCOPY BOOLEAN,
  x_rebuild_psite_idx OUT NOCOPY BOOLEAN,
  x_rebuild_contact_idx OUT NOCOPY BOOLEAN,
  x_rebuild_cpt_idx OUT NOCOPY BOOLEAN) IS

BEGIN

    log('Generating package body for HZ_STAGE_MAP_TRANSFORM_UPD');
    HZ_GEN_PLSQL.new('HZ_STAGE_MAP_TRANSFORM_UPD', 'PACKAGE BODY');
    l('CREATE OR REPLACE PACKAGE BODY HZ_STAGE_MAP_TRANSFORM_UPD AS');

    generate_declarations;
    generate_party_query_upd(x_rebuild_party_idx);
    generate_contact_query_upd(x_rebuild_psite_idx);
    generate_party_site_query_upd(x_rebuild_contact_idx);
    generate_contact_pt_query_upd(x_rebuild_cpt_idx);

    l('END;');
    log('Compiling package body .. ', false);
    HZ_GEN_PLSQL.compile_code;
    log('Done');

    IF NOT x_rebuild_party_idx THEN
      set_misc('PARTY');
    END IF;
    IF NOT x_rebuild_psite_idx THEN
      set_misc('PARTY_SITES');
    END IF;
    IF NOT x_rebuild_contact_idx THEN
      set_misc('CONTACTS');
    END IF;
    IF NOT x_rebuild_cpt_idx THEN
      set_misc('CONTACT_POINTS');
    END IF;
    generate_map_pkg;
END;

PROCEDURE add_section (
  p_dsname VARCHAR2,
  p_attr VARCHAR2,
  p_stype VARCHAR2) IS
BEGIN
  IF p_stype = 'ZONE' THEN
    ctx_ddl.add_zone_section(p_dsname, p_attr,p_attr);
  ELSE
    ctx_ddl.add_field_section(p_dsname, p_attr,p_attr,TRUE);
  END IF;
END;


PROCEDURE generate_datastore_prefs(p_entity VARCHAR2) IS
  CURSOR c_num_attrs(cp_entity VARCHAR2) IS
    SELECT COUNT(1)
    FROM HZ_TRANS_ATTRIBUTES_VL a
    WHERE ENTITY_NAME = cp_entity
    AND EXISTS (SELECT 1 FROM HZ_TRANS_FUNCTIONS_VL f
                WHERE f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
                AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                AND nvl(f.PRIMARY_FLAG,'Y') = 'Y');

  CURSOR c_attrs(cp_entity VARCHAR2) IS
    SELECT 'A'||ATTRIBUTE_ID
    FROM HZ_TRANS_ATTRIBUTES_VL a
    WHERE ENTITY_NAME = cp_entity
    AND EXISTS (SELECT 1 FROM HZ_TRANS_FUNCTIONS_VL f
                WHERE f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
                AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                AND nvl(f.PRIMARY_FLAG,'Y') = 'Y');

  l_cnt NUMBER;
  l_stype VARCHAR2(255);
  l_attr VARCHAR2(255);

  pref_cols VARCHAR2(1000);
  proc_cols VARCHAR2(2000);
  tmp VARCHAR2(2000);

BEGIN
   log('-------------------------------------');
   log('In generate_datastore_prefs for ' || p_entity);
   log('Trying to update the temp_section of HZ_TRANS_ATTRIBUTES_B for ' || p_entity);
  BEGIN
    IF p_entity='PARTY' THEN
      ctx_ddl.drop_section_group(g_schema_name || '.HZ_DQM_PARTY_GRP');
      UPDATE HZ_TRANS_ATTRIBUTES_B set TEMP_SECTION=NULL
      WHERE ENTITY_NAME='PARTY';
    END IF;

    IF p_entity='PARTY_SITES' THEN
      ctx_ddl.drop_section_group(G_SCHEMA_NAME || '.HZ_DQM_PS_GRP');
      UPDATE HZ_TRANS_ATTRIBUTES_B set TEMP_SECTION=NULL
      WHERE ENTITY_NAME='PARTY_SITES';
    END IF;

    IF p_entity='CONTACTS' THEN
      ctx_ddl.drop_section_group(G_SCHEMA_NAME || '.HZ_DQM_CONTACT_GRP');
      UPDATE HZ_TRANS_ATTRIBUTES_B set TEMP_SECTION=NULL
      WHERE ENTITY_NAME='CONTACTS';
    END IF;

    IF p_entity='CONTACT_POINTS' THEN
      ctx_ddl.drop_section_group(G_SCHEMA_NAME || '.HZ_DQM_CPT_GRP');
      UPDATE HZ_TRANS_ATTRIBUTES_B set TEMP_SECTION=NULL
      WHERE ENTITY_NAME='CONTACT_POINTS';
    END IF;
  log('Update of HZ_TRANS_ATTRIBUTES_B successful for ' || p_entity);
  EXCEPTION
   WHEN OTHERS THEN
     NULL;
  END;

  IF p_entity='PARTY' THEN
    log('Creating party_ds..',FALSE);
    ctx_ddl.create_section_group(G_SCHEMA_NAME || '.HZ_DQM_PARTY_GRP','BASIC_SECTION_GROUP');
    OPEN c_num_attrs('PARTY');
    FETCH c_num_attrs INTO l_cnt;
    CLOSE c_num_attrs;
    l_cnt := l_cnt+4;
    IF l_cnt>54 THEN
      l_stype := 'ZONE';
    ELSE
      l_stype := 'FIELD';
    END IF;
    add_section(G_SCHEMA_NAME || '.HZ_DQM_PARTY_GRP','D_PS',l_stype);
    add_section(G_SCHEMA_NAME || '.HZ_DQM_PARTY_GRP','D_CT',l_stype);
    add_section(G_SCHEMA_NAME || '.HZ_DQM_PARTY_GRP','D_CPT',l_stype);
    add_section(G_SCHEMA_NAME || '.HZ_DQM_PARTY_GRP','STATUS',l_stype);
    OPEN c_attrs('PARTY');
    LOOP
      FETCH c_attrs INTO l_attr;
      EXIT WHEN c_attrs%NOTFOUND;
      add_section(G_SCHEMA_NAME || '.HZ_DQM_PARTY_GRP',l_attr,l_stype);
    END LOOP;
    CLOSE c_attrs;
    IF l_stype='FIELD' THEN
      FOR I in 1..(64-l_cnt) LOOP
        add_section(G_SCHEMA_NAME || '.HZ_DQM_PARTY_GRP','M'||I,l_stype);
      END LOOP;
    ELSE
      FOR I in 1..(255-l_cnt) LOOP
        add_section(G_SCHEMA_NAME || '.HZ_DQM_PARTY_GRP','M'||I,l_stype);
      END LOOP;
    END IF;


  END IF;

  IF p_entity='PARTY_SITES' THEN
    log('Creating party_site_ds..',FALSE);
    ctx_ddl.create_section_group(G_SCHEMA_NAME || '.HZ_DQM_PS_GRP','BASIC_SECTION_GROUP');
    OPEN c_num_attrs('PARTY_SITES');
    FETCH c_num_attrs INTO l_cnt;
    CLOSE c_num_attrs;
    l_cnt := l_cnt;
    IF l_cnt>54 THEN
      l_stype := 'ZONE';
    ELSE
      l_stype := 'FIELD';
    END IF;
    OPEN c_attrs('PARTY_SITES');
    LOOP
      FETCH c_attrs INTO l_attr;
      EXIT WHEN c_attrs%NOTFOUND;
      add_section(G_SCHEMA_NAME || '.HZ_DQM_PS_GRP',l_attr,l_stype);
    END LOOP;
    CLOSE c_attrs;
    IF l_stype='FIELD' THEN
      FOR I in 1..(64-l_cnt) LOOP
        add_section(G_SCHEMA_NAME || '.HZ_DQM_PS_GRP','M'||I,l_stype);
      END LOOP;
    ELSE
      FOR I in 1..(255-l_cnt) LOOP
        add_section(G_SCHEMA_NAME || '.HZ_DQM_PS_GRP','M'||I,l_stype);
      END LOOP;
    END IF;

  END IF;

  IF p_entity='CONTACTS' THEN
    log('Creating contact_ds..',FALSE);
    ctx_ddl.create_section_group(G_SCHEMA_NAME || '.HZ_DQM_CONTACT_GRP','BASIC_SECTION_GROUP');
    OPEN c_num_attrs('CONTACTS');
    FETCH c_num_attrs INTO l_cnt;
    CLOSE c_num_attrs;
    l_cnt := l_cnt;
    IF l_cnt>64 THEN
      l_stype := 'ZONE';
    ELSE
      l_stype := 'FIELD';
    END IF;
    OPEN c_attrs('CONTACTS');
    LOOP
      FETCH c_attrs INTO l_attr;
      EXIT WHEN c_attrs%NOTFOUND;
      add_section(G_SCHEMA_NAME || '.HZ_DQM_CONTACT_GRP',l_attr,l_stype);
    END LOOP;
    CLOSE c_attrs;
    IF l_stype='FIELD' THEN
      FOR I in 1..(64-l_cnt) LOOP
        add_section(G_SCHEMA_NAME || '.HZ_DQM_CONTACT_GRP','M'||I,l_stype);
      END LOOP;
    ELSE
      FOR I in 1..(255-l_cnt) LOOP
        add_section(G_SCHEMA_NAME || '.HZ_DQM_CONTACT_GRP','M'||I,l_stype);
      END LOOP;
    END IF;

  END IF;

  IF p_entity='CONTACT_POINTS' THEN
    log('Creating contact_pt_ds..',FALSE);
    ctx_ddl.create_section_group(G_SCHEMA_NAME || '.HZ_DQM_CPT_GRP','BASIC_SECTION_GROUP');
    add_section(G_SCHEMA_NAME || '.HZ_DQM_CPT_GRP','CONTACT_POINT_TYPE',l_stype);
    OPEN c_num_attrs('CONTACT_POINTS');
    FETCH c_num_attrs INTO l_cnt;
    CLOSE c_num_attrs;
    l_cnt := l_cnt+1;
    IF l_cnt>64 THEN
      l_stype := 'ZONE';
    ELSE
      l_stype := 'FIELD';
    END IF;
    OPEN c_attrs('CONTACT_POINTS');
    LOOP
      FETCH c_attrs INTO l_attr;
      EXIT WHEN c_attrs%NOTFOUND;
      add_section(G_SCHEMA_NAME || '.HZ_DQM_CPT_GRP',l_attr,l_stype);
    END LOOP;
    CLOSE c_attrs;
    IF l_stype='FIELD' THEN
      FOR I in 1..(64-l_cnt) LOOP
        add_section(G_SCHEMA_NAME || '.HZ_DQM_CPT_GRP','M'||I,l_stype);
      END LOOP;
    ELSE
      FOR I in 1..(255-l_cnt) LOOP
        add_section(G_SCHEMA_NAME || '.HZ_DQM_CPT_GRP','M'||I,l_stype);
      END LOOP;
    END IF;
  END IF;

  IF p_entity='PARTY' THEN
    get_datastore_cols('PARTY', pref_cols, proc_cols, tmp);
    create_pref(G_SCHEMA_NAME || '.hz_party_ds',pref_cols);
  END IF;

  IF p_entity='PARTY_SITES' THEN
    get_datastore_cols('PARTY_SITES', pref_cols, proc_cols, tmp);
    create_pref(G_SCHEMA_NAME || '.hz_party_site_ds',pref_cols);
  END IF;

  IF p_entity='CONTACTS' THEN
    get_datastore_cols('CONTACTS', pref_cols, proc_cols, tmp);
    create_pref(G_SCHEMA_NAME || '.hz_contact_ds',pref_cols);
  END IF;

  IF p_entity='CONTACT_POINTS' THEN
    get_datastore_cols('CONTACT_POINTS', pref_cols, proc_cols, tmp);
    create_pref(G_SCHEMA_NAME || '.hz_contact_point_ds',pref_cols);
  END IF;

  log('Done creating datastore prefs for ' || p_entity );
EXCEPTION
  WHEN OTHERS THEN
    log('Error in gen ds '||SQLERRM);
    RAISE;
END;


PROCEDURE generate_datastore_prefs IS

BEGIN
  generate_datastore_prefs('PARTY');
  generate_datastore_prefs('PARTY_SITES');
  generate_datastore_prefs('CONTACTS');
  generate_datastore_prefs('CONTACT_POINTS');
END;

PROCEDURE drop_indexes IS

l_status VARCHAR2(255);
l_index_owner VARCHAR2(255);
l_temp VARCHAR2(255);

l_bool BOOLEAN;

BEGIN

  l_bool := fnd_installation.GET_APP_INFO('AR',l_status,l_temp,l_index_owner);

  log('Dropping Indexes');
  BEGIN
      EXECUTE IMMEDIATE 'DROP INDEX ' || l_index_owner || '.hz_stage_parties_t1 FORCE';
      log('Dropped hz_stage_parties_t1');
  EXCEPTION
      WHEN OTHERS THEN
        NULL;
  END;
  BEGIN
      EXECUTE IMMEDIATE 'DROP INDEX ' || l_index_owner || '.hz_stage_party_sites_t1 FORCE';
      log('Dropped hz_stage_party_sites_t1');
  EXCEPTION
      WHEN OTHERS THEN
        NULL;
  END;
  BEGIN
      EXECUTE IMMEDIATE 'DROP INDEX ' || l_index_owner || '.hz_stage_contact_t1 FORCE';
      log('Dropped hz_stage_contact_t1');
  EXCEPTION
      WHEN OTHERS THEN
        NULL;
  END;
  BEGIN
      EXECUTE IMMEDIATE 'DROP INDEX ' || l_index_owner || '.hz_stage_cpt_t1 FORCE';
      log('Dropped hz_stage_cpt_t1');
  EXCEPTION
      WHEN OTHERS THEN
        NULL;
  END;
  log('Done with dropping indexes');
END;

PROCEDURE drop_btree_indexes IS
l_status VARCHAR2(255);
l_owner1 VARCHAR2(255);
l_temp VARCHAR2(255);
BEGIN
IF (fnd_installation.GET_APP_INFO('AR',l_status,l_temp,l_owner1)) THEN
  FOR IDX in (
    SELECT OWNER||'.'||INDEX_NAME idx_name
    FROM sys.all_indexes i, hz_trans_attributes_vl a, hz_trans_functions_vl f
    WHERE f.attribute_id = a.attribute_id
    AND i.owner = l_owner1
    AND f.index_required_flag in ('Y','T')
    AND i.INDEX_NAME = decode(a.entity_name,'PARTY','HZ_STAGED_PARTIES',
                  'PARTY_SITES','HZ_STAGED_PARTY_SITES','CONTACTS','HZ_STAGED_CONTACTS',
                  'CONTACT_POINTS','HZ_STAGED_CONTACT_POINTS')||'_N'||f.function_id) LOOP
    EXECUTE IMMEDIATE 'DROP INDEX '||IDX.idx_name;
  END LOOP;
  UPDATE hz_trans_functions_b set index_required_flag='N' where index_required_flag='T';
END IF;
END;

PROCEDURE create_log(
   p_operation VARCHAR2,
   p_step VARCHAR2,
   p_worker_number NUMBER DEFAULT 0,
   p_num_workers NUMBER DEFAULT 0) IS

BEGIN

  INSERT INTO HZ_DQM_STAGE_LOG (
	OPERATION,
	NUMBER_OF_WORKERS,
        WORKER_NUMBER,
	STEP,
	START_FLAG,
	START_TIME,
	END_FLAG,
	END_TIME,
	CREATED_BY,
	CREATION_DATE,
	LAST_UPDATE_LOGIN,
	LAST_UPDATE_DATE,
	LAST_UPDATED_BY)
   VALUES (
        substr(p_operation,1,30),
        p_num_workers,
        p_worker_number,
	p_step,
        NULL,
	NULL,
	NULL,
	NULL,
	hz_utility_pub.created_by,
        hz_utility_pub.creation_date,
        hz_utility_pub.last_update_login,
        hz_utility_pub.last_update_date,
        hz_utility_pub.user_id
   );
END;

FUNCTION get_size (
        p_table_name       IN   VARCHAR2
        ) RETURN  NUMBER IS
   l_status VARCHAR2(255);
   l_owner1 VARCHAR2(255);
   l_temp VARCHAR2(255);

   CURSOR c_number_of_blocks is
                  SELECT blocks - empty_blocks
                  FROM sys.dba_tables
                  WHERE table_name = p_table_name and owner = l_owner1;
   CURSOR  c_db_block_size is  SELECT value
                  FROM v$parameter
                  WHERE name = 'db_block_size' ;
   l_db_block_size NUMBER;
   l_number_of_blocks NUMBER;

   BEGIN
      IF (fnd_installation.GET_APP_INFO('AR',l_status,l_temp,l_owner1)) THEN
         OPEN c_number_of_blocks;
         FETCH c_number_of_blocks into l_number_of_blocks;
         CLOSE c_number_of_blocks;
         OPEN c_db_block_size;
         FETCH c_db_block_size into l_db_block_size;
         CLOSE c_db_block_size;
     END IF;
     RETURN  (l_number_of_blocks * l_db_block_size) / 1000000;
    EXCEPTION
      WHEN OTHERS THEN
      RETURN 0;
   END;

FUNCTION check_rebuild(p_entity VARCHAR2)
  RETURN BOOLEAN IS
-- this cursor will return the number of active transformations
-- that have not been staged, corresponding to the passed in entity
  CURSOR check_any_acq IS
    SELECT count(1)
    from hz_trans_attributes_vl a
    where a.entity_name = p_entity
    and exists (
      SELECT 1 from hz_trans_functions_vl f
      where a.attribute_id = f.attribute_id
      and nvl(f.ACTIVE_FLAG,'Y') = 'Y'
      and primary_flag = 'Y'
      AND NVL(STAGED_FLAG,'N') ='N');
-- this cursor will return if there are any preference values
-- that exist, for the passed in entity
  CURSOR check_ds_misc_proc IS
    select 1 from ctx_preference_values
    where prv_preference =
       decode(p_entity,'PARTY','HZ_PARTY_DS',
                       'PARTY_SITES','HZ_PARTY_SITE_DS',
                       'CONTACTS','HZ_CONTACT_DS',
                       'CONTACT_POINTS','HZ_CONTACT_POINT_DS',
                       'NOMATCH')
    AND prv_owner = g_schema_name
    AND prv_attribute='COLUMNS'
    AND upper(prv_value) like '%HZDQM.M%';

tmp NUMBER;
l_num_primary NUMBER;
l_next_misc_section NUMBER;
check_section_str VARCHAR2(2000);
l_table_name VARCHAR2(255);
BEGIN
log ('--------------------------------------');
-- If profile option is Optimal we FORCE A REBUILD.
IF upper ( nvl( FND_PROFILE.value('HZ_DQM_INDEX_BUILD_TYPE'), 'Optimal') ) = upper('Optimal')
THEN
     IF new_transformations_exist(p_entity)
     THEN
          log(' Chosen Profile Option is OPTIMAL');
          log(' check rebuild returns TRUE -- Do a REBUILD');
          RETURN TRUE ;
     ELSE
          log(' Chosen Profile Option is OPTIMAL');
          log(' But there are no new transformations to be staged for ' || p_entity );
          log(' check rebuild returns FALSE -- Do not REBUILD');
          RETURN FALSE  ;
     END IF ;
-- If profile option is incremental, we attempt TO SEE IF WE CAN AVOID A REBUILD
ELSE
          log(' Chosen Profile Option is INCREMENTAL ');
          log(' Starting to figure out, if a REBUILD can be avoided');
          -- if no active unstaged transformatons exist for the passed in entity return FALSE
          -- ie., DO NOT REBUILD
          OPEN check_any_acq;
          FETCH check_any_acq INTO l_num_primary;
          IF l_num_primary=0 THEN
            CLOSE check_any_acq;
            log(' check rebuild returns FALSE -- Do not REBUILD');
            RETURN FALSE;
          END IF;
          CLOSE check_any_acq;
          -- if atleast one active unstaged transformation exists, check if the preference
          -- values exist for this entity. If preference values do not exist, return TRUE
          -- ie., DO A REBUILD
          OPEN check_ds_misc_proc;
          FETCH check_ds_misc_proc INTO tmp;
          IF check_ds_misc_proc%NOTFOUND THEN
            CLOSE check_ds_misc_proc;
            log(' check rebuild returns TRUE -- Do a REBUILD');
            RETURN TRUE;
          END IF;
          CLOSE check_ds_misc_proc;

          -- if preference values exist for this entity, find the maximum temp_section for this entity
          -- and offset it by how many ever unstaged active transformations are found
          BEGIN
            SELECT max(to_number(substrb(temp_section,2)))+l_num_primary
            INTO l_next_misc_section
            from hz_trans_attributes_vl a
            where a.entity_name = p_entity
            and a.temp_section IS NOT NULL;
            IF l_next_misc_section IS NULL THEN
               l_next_misc_section := l_num_primary;
            END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              l_next_misc_section := l_num_primary;
          END;

          SELECT decode(p_entity,'PARTY','HZ_STAGED_PARTIES',
                               'PARTY_SITES','HZ_STAGED_PARTIES',
                               'CONTACTS','HZ_STAGED_CONTACTS',
                               'CONTACT_POINTS','HZ_STAGED_CONTACT_POINTS','DUMMY')
          INTO l_table_name
          from DUAL;

          -- See if the intermedia index on the corresponding staging table for the entity
          -- has the placeholders for these sections.
          -- The check that is done here is to see if the dummy string CHECK exists with in the section
          -- by executing the folowing SQL. If this SQL errors out, it means the section doesnt exist
          -- or equivalently there are no placeholders.
          check_section_str :=
            'SELECT 1 FROM '||l_table_name||
            ' WHERE ROWNUM=1 AND CONTAINS(concat_col,''({CHECK} within M'||l_next_misc_section||')'')>0';
          log('Check STR ' ||check_section_str);
          BEGIN
            EXECUTE IMMEDIATE check_section_str;
            -- if section exists DO NOT REBUILD
            log(' check rebuild returns FALSE -- Do not REBUILD');
            RETURN FALSE;
          EXCEPTION
            WHEN OTHERS THEN
              log('Error ' ||SQLERRM);
              -- if section does not exist REBUILD
              log(' check rebuild returns TRUE -- Do a REBUILD');
              RETURN TRUE;
          END;
  END IF ;
END;


PROCEDURE Stage (
        errbuf                  OUT NOCOPY    VARCHAR2,
        retcode                 OUT NOCOPY   VARCHAR2,
        p_num_workers           IN      VARCHAR2,
        p_command		IN	VARCHAR2,
        p_continue		IN	VARCHAR2,
        p_tablespace		IN	VARCHAR2,
	p_index_creation	IN	VARCHAR2
) IS

TYPE nTable IS TABLE OF NUMBER index by binary_integer;
TYPE vTable IS TABLE OF VARCHAR2(255) index by binary_integer;
l_sub_requests nTable;
l_req_status vTable;

uphase VARCHAR2(255);
dphase VARCHAR2(255);
ustatus VARCHAR2(255);
dstatus VARCHAR2(255);
message VARCHAR2(32000);

CURSOR c_primary(cp_entity_name VARCHAR2) IS
  SELECT f.TRANSFORMATION_NAME, f.STAGED_ATTRIBUTE_COLUMN
  FROM HZ_TRANS_FUNCTIONS_VL f, HZ_TRANS_ATTRIBUTES_VL a
  WHERE PRIMARY_FLAG = 'Y'
  AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
  AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
  AND a.ENTITY_NAME = cp_entity_name;

l_trans_name HZ_TRANS_FUNCTIONS_VL.TRANSFORMATION_NAME%TYPE;
l_stg_attr HZ_TRANS_FUNCTIONS_VL.STAGED_ATTRIBUTE_COLUMN%TYPE;

l_cols VARCHAR2(4000);
l_message VARCHAR2(4000);
l_status VARCHAR2(255) := 'NORMAL';

l_num_workers NUMBER;
l_num_funcs NUMBER;
l_req_id  NUMBER;
l_bool BOOLEAN;
l_continue VARCHAR2(1) := 'N';

l_party_prim_tx NUMBER := 1;
l_ps_prim_tx NUMBER := 1;
l_contact_prim_tx NUMBER := 1;
l_cpt_prim_tx NUMBER := 1;

l_index_owner VARCHAR2(255);
l_temp VARCHAR2(255);

l_num_prll VARCHAR2(255);
l_idx_mem VARCHAR2(255);


T NUMBER;

l_index_creation VARCHAR2(255) := 'PARALLEL';

l_command VARCHAR2(255);
l_last_num_workers NUMBER;
l_num_stage_stepS NUMBER;
reco_staging_size NUMBER;
reco_staging_parties NUMBER;
reco_staging_party_sites NUMBER;
reco_staging_contacts NUMBER;
reco_staging_contact_points NUMBER;
reco_index_size NUMBER;
safety_factor NUMBER(5, 1) := 2.0 ;
sizing_factor NUMBER(5, 1) := 5;

l_index VARCHAR2(255);

ctx_tbsp VARCHAR2(255);
ctx_index_tbsp VARCHAR2(255);

l_rebuild_party_idx BOOLEAN:=FALSE;
l_rebuild_psite_idx BOOLEAN:=FALSE;
l_rebuild_contact_idx BOOLEAN:=FALSE;
l_rebuild_cpt_idx BOOLEAN:=FALSE;

l_step VARCHAR2(255);
l_is_wildchar NUMBER;

BEGIN

  l_index_creation := nvl(p_index_creation,'PARALLEL');

  IF p_num_workers IS NULL THEN
    l_num_workers:=1;
  ELSE
    l_num_workers := to_number(p_num_workers);
  END IF;

  retcode := 0;

  log('------------------------------');
  outandlog('Starting Concurrent Program ''Stage Party Data''');
  outandlog('Start Time ' || TO_CHAR(SYSDATE, 'MM-DD-YY HH24:MI:SS'));
  outandlog('NEWLINE');

  l_command:=p_command;
  l_continue:=nvl(p_continue,'N');
  FND_MSG_PUB.initialize;

  l_bool := fnd_installation.GET_APP_INFO('AR',l_status,l_temp,l_index_owner);

  IF l_command = 'ESTIMATE_SIZE' THEN
      reco_staging_parties := ceil(get_size('HZ_PARTIES') * 1.5 * safety_factor);
      reco_staging_party_sites := ceil(get_size('HZ_PARTY_SITES') * 3.0 * safety_factor);
      reco_staging_contacts := ceil(get_size('HZ_ORG_CONTACTS') * 2.5 * safety_factor);
      reco_staging_contact_points := ceil(get_size('HZ_CONTACT_POINTS') * 2.0 * safety_factor);
      reco_index_size := 0.85 * (reco_staging_parties +  reco_staging_party_sites +  reco_staging_contacts +  reco_staging_contact_points);
      reco_staging_size :=  reco_staging_parties +  reco_staging_party_sites +  reco_staging_contacts +  reco_staging_contact_points + reco_index_size;

      outandlog('The estimated disk space required for HZ_STAGED_PARTIES = ' || reco_staging_parties || 'MB' );
      outandlog('The estimated disk space required for HZ_STAGED_PARTY_SITES = ' ||reco_staging_party_sites || 'MB' );
      outandlog('The estimated disk space required for HZ_STAGED_CONTACTS = ' ||reco_staging_contacts || 'MB' );
      outandlog('The estimated disk space required for HZ_STAGED_CONTACT_POINTS = ' || reco_staging_contact_points || 'MB' );
      outandlog('The estimated disk space required by text indexes = ' ||reco_index_size || 'MB' );
      outandlog(' ');
      outandlog('The estimated total disk space required for staging = ' ||reco_staging_size || 'MB' );
      outandlog('NEWLINE');
   ELSIF l_command = 'ANALYZE_STAGED_TABLES' THEN
       outandlog('Staged tables being analyzed');
       gather_stats(l_index_owner, 'HZ_STAGED_PARTIES');
       gather_stats(l_index_owner, 'HZ_STAGED_PARTY_SITES');
       gather_stats(l_index_owner, 'HZ_STAGED_CONTACTS');
       gather_stats(l_index_owner, 'HZ_STAGED_CONTACT_POINTS');
       outandlog('Staged tables analyzed, End Time : '|| TO_CHAR(SYSDATE, 'MM-DD-YY HH24:MI:SS'));
  END IF;

  IF l_command = 'STAGE_NEW_DENORM' THEN
          outandlog('Staging new denormalized attributes.');
          generate_map_pkg;
          FOR I in 1..10 LOOP
              l_sub_requests(i) := 1;
          END LOOP;
          IF FND_PROFILE.value('HZ_DQM_INDEX_PARALLEL') IS NOT NULL THEN
              l_num_prll := FND_PROFILE.value('HZ_DQM_INDEX_PARALLEL');
          ELSE
              l_num_prll := NULL;
          END IF;
          IF FND_PROFILE.value('HZ_DQM_INDEX_MEMORY') IS NOT NULL THEN
              l_idx_mem := FND_PROFILE.value('HZ_DQM_INDEX_MEMORY');
          ELSE
              BEGIN
                   SELECT PAR_VALUE INTO l_idx_mem
                   FROM CTX_PARAMETERS
                   WHERE PAR_NAME = 'MAX_INDEX_MEMORY';
              EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                   BEGIN
                       SELECT PAR_VALUE INTO l_idx_mem
                       FROM CTX_PARAMETERS
                       WHERE PAR_NAME = 'DEFAULT_INDEX_MEMORY';
                   EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                       l_idx_mem := '0';
                  END;
               END;
           END IF;
           l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
                'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
                FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
                to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
                to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
                to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
                to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
                'STAGE_NEW_DENORM', l_idx_mem, l_num_prll, 'STAGE_NEW_DENORM');
           IF l_req_id = 0 THEN
                log('Error submitting request');
                log(fnd_message.get);
           ELSE
                log('Submitted request ID for Party Index: ' || l_req_id );
                log('Request ID : ' || l_req_id);
           END IF;
  END IF;

  IF l_command = 'STAGE_ALL_DATA' OR
     l_command = 'CREATE_INDEXES' OR
     l_command = 'STAGE_NEW_TRANSFORMATIONS' OR
     l_command = 'CREATE_MISSING_INVALID_INDEXES' THEN
    IF FND_PROFILE.value('HZ_DQM_INDEX_MEMORY') IS NOT NULL THEN
      l_idx_mem := FND_PROFILE.value('HZ_DQM_INDEX_MEMORY');
    ELSE
      BEGIN
        SELECT PAR_VALUE INTO l_idx_mem
        FROM CTX_PARAMETERS
        WHERE PAR_NAME = 'MAX_INDEX_MEMORY';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          BEGIN
            SELECT PAR_VALUE INTO l_idx_mem
            FROM CTX_PARAMETERS
            WHERE PAR_NAME = 'DEFAULT_INDEX_MEMORY';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              l_idx_mem := '0';
          END;
      END;
    END IF;

    IF FND_PROFILE.value('HZ_DQM_INDEX_PARALLEL') IS NOT NULL THEN
      l_num_prll := FND_PROFILE.value('HZ_DQM_INDEX_PARALLEL');
    ELSE
      l_num_prll := NULL;
    END IF;

    BEGIN
        ctx_ddl.drop_preference('HZ_DQM_STORAGE');
      EXCEPTION
       WHEN OTHERS THEN
         NULL;
      END;

    IF p_tablespace IS NOT NULL THEN
      ctx_tbsp := p_tablespace;
      ctx_index_tbsp := p_tablespace;
    ELSE
      select tablespace, index_tablespace
      into ctx_tbsp, ctx_index_tbsp
      from fnd_product_installations
      where application_id = '222';
    END IF;

      ctx_ddl.create_preference('HZ_DQM_STORAGE', 'BASIC_STORAGE');
      ctx_ddl.set_attribute('HZ_DQM_STORAGE', 'I_TABLE_CLAUSE', 'tablespace '|| ctx_tbsp|| ' storage (initial 4K next 8M pctincrease 0)');
      ctx_ddl.set_attribute('HZ_DQM_STORAGE', 'K_TABLE_CLAUSE', 'tablespace ' || ctx_tbsp || ' storage (initial 4K next 8M pctincrease 0)');
      ctx_ddl.set_attribute('HZ_DQM_STORAGE', 'R_TABLE_CLAUSE', 'tablespace '|| ctx_tbsp || ' storage (initial 4K next 8M pctincrease 0)  lob (data) store as (cache) ');
      ctx_ddl.set_attribute('HZ_DQM_STORAGE', 'I_INDEX_CLAUSE', 'tablespace '|| ctx_index_tbsp || '  storage (initial 4K next 8M pctincrease 0)  compress 2');

  END IF;

  BEGIN
    ctx_ddl.drop_preference('dqm_lexer');
  EXCEPTION
    WHEN OTHERS THEN
      null;
  END;

  ctx_ddl.create_preference('dqm_lexer', 'BASIC_LEXER');
  ctx_ddl.set_attribute ( 'dqm_lexer', 'index_themes', 'NO');
  ctx_ddl.set_attribute ( 'dqm_lexer', 'index_text', 'YES');

  IF l_command = 'GENERATE_MAP_PROC' THEN
    log (' In the GENERATE_MAP_PROC flow');
    generate_map_pkg;
  ELSIF l_command = 'STAGE_NEW_TRANSFORMATIONS' THEN
    log (' In the STAGE_NEW_TRANSFORMATIONS flow');
    BEGIN
      SELECT number_of_workers INTO l_last_num_workers
      FROM HZ_DQM_STAGE_LOG
      WHERE operation = l_command
      AND STEP = 'INIT';

      IF l_last_num_workers<>l_num_workers AND l_continue = 'Y' THEN
        log('Cannot continue with different number of workers. Using ' ||
             l_last_num_workers ||' workers, as specified in first run');
        l_num_workers := l_last_num_workers;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_continue := 'N';
    END;
    IF l_continue <> 'Y' THEN
       verify_all_procs;
       generate_map_upd_pkg(l_rebuild_party_idx,l_rebuild_psite_idx,
            l_rebuild_contact_idx,l_rebuild_cpt_idx);
       log('*** After gen upd '||l_continue);

       -- Generate preferences for all entities based on the corresponding boolean populated
       -- by generate_map_upd_pkg.
       -- In particular, if the profile option HZ_DQM_INDEX_BUILD_TYPE is chosen to be Optimal
       -- datastore preferences will always be rebuilt.

       IF l_rebuild_party_idx THEN
         generate_datastore_prefs('PARTY');
       END IF;
       IF l_rebuild_psite_idx THEN
         generate_datastore_prefs('PARTY_SITES');
       END IF;
       IF l_rebuild_contact_idx THEN
         generate_datastore_prefs('CONTACTS');
       END IF;
       IF l_rebuild_cpt_idx THEN
         generate_datastore_prefs('CONTACT_POINTS');
       END IF;

      DELETE from HZ_DQM_STAGE_LOG where operation = l_command;
      create_log(
        p_operation=>l_command,
        p_step=>'INIT',
        p_num_workers=>l_num_workers);

      l_num_stage_steps := g_num_stage_new_steps;

      FOR I in 1..l_num_stage_steps LOOP
        FOR J in 0..(l_num_workers-1) LOOP
          create_log(
            p_operation=>l_command,
            p_step=>'STEP'||I,
            p_worker_number=> J,
            p_num_workers=>l_num_workers);
        END LOOP;
      END LOOP;

      DELETE from HZ_DQM_STAGE_LOG where operation = 'CREATE_INDEXES';
      IF l_rebuild_party_idx THEN
        create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_PARTIES');
      ELSE
        create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_PARTIES_BTREE');
      END IF;

      IF l_rebuild_psite_idx THEN
        create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_PARTY_SITES');
      ELSE
        create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_PARTY_SITES_BTREE');  ----
      END IF;

      IF l_rebuild_contact_idx THEN
        create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_ORG_CONTACTS');
      ELSE
        create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_ORG_CONTACTS_BTREE');
      END IF;

      IF l_rebuild_cpt_idx THEN
        create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_CONTACT_POINTS');
      ELSE
        create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_CONTACT_POINTS_BTREE');
      END IF;

    ELSE
      SELECT step INTO l_step
      FROM HZ_DQM_STAGE_LOG
      WHERE OPERATION = 'CREATE_INDEXES'
      AND step like 'HZ_PARTIES%';

      IF l_step ='HZ_PARTIES' THEN
        l_rebuild_party_idx:=TRUE;
      ELSE
        l_rebuild_party_idx:=FALSE;
      END IF;

      SELECT step INTO l_step
      FROM HZ_DQM_STAGE_LOG
      WHERE OPERATION = 'CREATE_INDEXES'
      AND step like 'HZ_PARTY_SITES%';

      IF l_step ='HZ_PARTY_SITES' THEN
        l_rebuild_psite_idx:=TRUE;
      ELSE
        l_rebuild_psite_idx:=FALSE;
      END IF;

      SELECT step INTO l_step
      FROM HZ_DQM_STAGE_LOG
      WHERE OPERATION = 'CREATE_INDEXES'
      AND step like 'HZ_ORG_CONTACTS%';

      IF l_step ='HZ_ORG_CONTACTS' THEN
        l_rebuild_contact_idx:=TRUE;
      ELSE
        l_rebuild_contact_idx:=FALSE;
      END IF;

      SELECT step INTO l_step
      FROM HZ_DQM_STAGE_LOG
      WHERE OPERATION = 'CREATE_INDEXES'
      AND step like 'HZ_CONTACT_POINTS%';

      IF l_step ='HZ_CONTACT_POINTS' THEN
        l_rebuild_cpt_idx:=TRUE;
      ELSE
        l_rebuild_cpt_idx:=FALSE;
      END IF;
    END IF;
    FOR I in 1..10 LOOP
        l_sub_requests(i) := 1;
    END LOOP;
    log('Spawning ' || l_num_workers || ' Workers for staging');
    FOR I in 1..l_num_workers LOOP
      l_sub_requests(i) := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMSTW',
                    'Stage Party Data Worker ' || to_char(i),
                    to_char(sysdate,'DD-MON-YY HH:MI:SS'),
                    FALSE, to_char(l_num_workers), TO_CHAR(I), l_command,l_continue);
      IF l_sub_requests(i) = 0 THEN
        log('Error submitting worker ' || i);
        log(fnd_message.get);
      ELSE
        log('Submitted request for Worker ' || TO_CHAR(I) );
        log('Request ID : ' || l_sub_requests(i));
      END IF;
      EXIT when l_sub_requests(i) = 0;
    END LOOP;


    l_req_id := l_sub_requests(1);

    IF l_req_id>0 THEN
      IF l_rebuild_party_idx THEN
        l_index := 'HZ_PARTIES';
      ELSE
        l_index := 'HZ_PARTIES_BTREE';
      END IF;
      l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
             'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
             FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
             to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
             to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
             to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
             to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
             l_command, l_idx_mem, l_num_prll, l_index);
      IF l_req_id = 0 THEN
          log('Error submitting request');
          log(fnd_message.get);
      ELSE
          log('Submitted request ID for Party Index: ' || l_req_id );
          log('Request ID : ' || l_req_id);
      END IF;
    END IF;

    IF l_req_id>0 THEN
      IF l_rebuild_psite_idx THEN
        l_index := 'HZ_PARTY_SITES';
      ELSE
        l_index := 'HZ_PARTY_SITES_BTREE';
      END IF;

      l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
             'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
               FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
               to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
               to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
               to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
               to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
               l_command, l_idx_mem, l_num_prll, l_index);
      IF l_req_id = 0 THEN
          log('Error submitting request');
          log(fnd_message.get);
      ELSE
          log('Submitted request ID for Party Site Index: ' || l_req_id );
          log('Request ID : ' || l_req_id);
      END IF;
    END IF;

    IF l_req_id>0 THEN
      IF l_rebuild_contact_idx THEN
        l_index := 'HZ_ORG_CONTACTS';
      ELSE
        l_index := 'HZ_ORG_CONTACTS_BTREE';
      END IF;
      l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
               'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
               FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
               to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
               to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
               to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
               to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
               l_command, l_idx_mem, l_num_prll, l_index);
      IF l_req_id = 0 THEN
          log('Error submitting request');
          log(fnd_message.get);
      ELSE
          log('Submitted request ID for Party Index: ' || l_req_id );
          log('Request ID : ' || l_req_id);
      END IF;
    END IF;

    IF l_req_id>0 THEN
      IF l_rebuild_cpt_idx THEN
        l_index := 'HZ_CONTACT_POINTS';
      ELSE
        l_index := 'HZ_CONTACT_POINTS_BTREE';
      END IF;
      l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
               'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
               FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
               to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
               to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
               to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
               to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
               l_command, l_idx_mem, l_num_prll, l_index);
      IF l_req_id = 0 THEN
          log('Error submitting request');
          log(fnd_message.get);
      ELSE
          log('Submitted request ID for Contact Point Index: ' || l_req_id );
          log('Request ID : ' || l_req_id);
      END IF;
    END IF;
  ELSIF l_command = 'STAGE_NEW_TRANSFORMATIONS_NO_INDEXING' THEN
      log (' In the STAGE_NEW_TRANSFORMATIONS_NO_INDEXING flow');
      BEGIN
          SELECT number_of_workers INTO l_last_num_workers
          FROM HZ_DQM_STAGE_LOG
          WHERE operation = substr(l_command,1,30)
          AND STEP = 'INIT';


          IF l_last_num_workers<>l_num_workers AND l_continue = 'Y' THEN
            log('Cannot continue with different number of workers. Using ' ||
                 l_last_num_workers ||' workers, as specified in first run');
            l_num_workers := l_last_num_workers;
          END IF;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            l_continue := 'N';
       END;
        IF l_continue <> 'Y' THEN
                 verify_all_procs;
                 generate_map_upd_pkg(l_rebuild_party_idx,l_rebuild_psite_idx,
                      l_rebuild_contact_idx,l_rebuild_cpt_idx);
                 log('*** After gen upd '||l_continue);

                 -- Generate preferences for all entities regardless
                 generate_datastore_prefs ;



                DELETE from HZ_DQM_STAGE_LOG where operation = substr(l_command,1,30) ;
                create_log(
                  p_operation=>l_command,
                  p_step=>'INIT',
                  p_num_workers=>l_num_workers);

                l_num_stage_steps := g_num_stage_new_steps;

                FOR I in 1..l_num_stage_steps LOOP
                  FOR J in 0..(l_num_workers-1) LOOP
                    create_log(
                      p_operation=>l_command,
                      p_step=>'STEP'||I,
                      p_worker_number=> J,
                      p_num_workers=>l_num_workers);
                  END LOOP;
                END LOOP;
              END IF;

              FOR I in 1..10 LOOP
                  l_sub_requests(i) := 1;
              END LOOP;

              log('Spawning ' || l_num_workers || ' Workers for staging');

              -- Dispatch the Stage Data Worker
              FOR I in 1..l_num_workers LOOP
                l_sub_requests(i) := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMSTW',
                              'Stage Party Data Worker ' || to_char(i),
                              to_char(sysdate,'DD-MON-YY HH:MI:SS'),
                              FALSE, to_char(l_num_workers), TO_CHAR(I), l_command,l_continue);
                IF l_sub_requests(i) = 0 THEN
                  log('Error submitting worker ' || i);
                  log(fnd_message.get);
                ELSE
                  log('Submitted request for Worker ' || TO_CHAR(I) );
                  log('Request ID : ' || l_sub_requests(i));
                END IF;
                EXIT when l_sub_requests(i) = 0;
              END LOOP;

ELSIF l_command = 'STAGE_ALL_DATA' THEN

    BEGIN
      SELECT count(*) into l_is_wildchar from HZ_DQM_STAGE_LOG where operation = 'STAGE_FOR_WILDCHAR_SEARCH' and rownum = 1 ;
      IF l_is_wildchar < 1 THEN
          INSERT INTO HZ_DQM_STAGE_LOG(operation, number_of_workers, worker_number, step,
                            last_update_date, creation_date, created_by, last_updated_by)
          VALUES ('STAGE_FOR_WILDCHAR_SEARCH', '-1', '-1', 'Y', SYSDATE, SYSDATE, 0, 0);
      END IF;

      SELECT number_of_workers INTO l_last_num_workers
      FROM HZ_DQM_STAGE_LOG
      WHERE operation = l_command
      AND STEP = 'INIT';

      IF l_last_num_workers<>l_num_workers AND l_continue = 'Y' THEN
        log('Cannot continue with different number of workers. Using ' ||
             l_last_num_workers ||' workers, as specified in first run');
        l_num_workers := l_last_num_workers;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_continue := 'N';
    END;

    IF l_continue <> 'Y' THEN
      verify_all_procs;
      IF l_command = 'STAGE_ALL_DATA' THEN
        drop_indexes;
        delete_existing_data;
	UPDATE HZ_TRANS_FUNCTIONS_B SET STAGED_FLAG='N'; --Bug No: 3907584.
      END IF;

      generate_datastore_prefs;
      IF l_command = 'STAGE_ALL_DATA' THEN
        generate_map_pkg;
      END IF;

      DELETE from HZ_DQM_STAGE_LOG where operation = l_command;
      create_log(
        p_operation=>l_command,
        p_step=>'INIT',
        p_num_workers=>l_num_workers);

      IF l_command = 'STAGE_ALL_DATA' THEN
        l_num_stage_steps := g_num_stage_steps;
      ELSE
        l_num_stage_steps := g_num_stage_new_steps;
      END IF;

      FOR I in 1..l_num_stage_steps LOOP
        FOR J in 0..(l_num_workers-1) LOOP
          create_log(
            p_operation=>l_command,
            p_step=>'STEP'||I,
            p_worker_number=> J,
            p_num_workers=>l_num_workers);
        END LOOP;
      END LOOP;
      DELETE from HZ_DQM_STAGE_LOG where operation = 'CREATE_INDEXES';
      create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_PARTIES');
      create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_PARTY_SITES');
      create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_ORG_CONTACTS');
      create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_CONTACT_POINTS');
    END IF;

    FOR I in 1..10 LOOP
      l_sub_requests(i) := 1;
    END LOOP;


    log('Spawning ' || l_num_workers || ' Workers for staging');
    FOR I in 1..l_num_workers LOOP
      l_sub_requests(i) := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMSTW',
                    'Stage Party Data Worker ' || to_char(i),
                    to_char(sysdate,'DD-MON-YY HH:MI:SS'),
                    FALSE, to_char(l_num_workers), TO_CHAR(I), l_command,l_continue);
      IF l_sub_requests(i) = 0 THEN
        log('Error submitting worker ' || i);
        log(fnd_message.get);
      ELSE
        log('Submitted request for Worker ' || TO_CHAR(I) );
        log('Request ID : ' || l_sub_requests(i));
      END IF;
      EXIT when l_sub_requests(i) = 0;
    END LOOP;

    l_req_id := l_sub_requests(1);

    IF l_req_id>0 THEN
      l_index := 'HZ_PARTIES';
      l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
             'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
             FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
             to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
             to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
             to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
             to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
             l_command, l_idx_mem, l_num_prll, l_index);
      IF l_req_id = 0 THEN
          log('Error submitting request');
          log(fnd_message.get);
      ELSE
          log('Submitted request ID for Party Index: ' || l_req_id );
          log('Request ID : ' || l_req_id);
      END IF;
    END IF;

    IF l_req_id>0 THEN
      l_index := 'HZ_PARTY_SITES';
      l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
             'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
               FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
               to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
               to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
               to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
               to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
               l_command, l_idx_mem, l_num_prll, l_index);
      IF l_req_id = 0 THEN
          log('Error submitting request');
          log(fnd_message.get);
      ELSE
          log('Submitted request ID for Party Site Index: ' || l_req_id );
          log('Request ID : ' || l_req_id);
      END IF;
    END IF;

    IF l_req_id>0 THEN
      l_index := 'HZ_ORG_CONTACTS';
      l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
               'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
               FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
               to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
               to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
               to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
               to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
               l_command, l_idx_mem, l_num_prll, l_index);
      IF l_req_id = 0 THEN
          log('Error submitting request');
          log(fnd_message.get);
      ELSE
          log('Submitted request ID for Party Index: ' || l_req_id );
          log('Request ID : ' || l_req_id);
      END IF;
    END IF;

    IF l_req_id>0 THEN
      l_index := 'HZ_CONTACT_POINTS';
      l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
               'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
               FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
               to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
               to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
               to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
               to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
               l_command, l_idx_mem, l_num_prll, l_index);
      IF l_req_id = 0 THEN
          log('Error submitting request');
          log(fnd_message.get);
      ELSE
          log('Submitted request ID for Contact Point Index: ' || l_req_id );
          log('Request ID : ' || l_req_id);
      END IF;
    END IF;
  ELSIF l_command = 'CREATE_INDEXES' THEN
    IF l_continue = 'N' THEN
      drop_indexes;
      generate_datastore_prefs;
      DELETE from HZ_DQM_STAGE_LOG where operation = 'CREATE_INDEXES';
      create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_PARTIES');
      create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_PARTY_SITES');
      create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_ORG_CONTACTS');
      create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_CONTACT_POINTS');

    END IF;

    FOR I in 1..10 LOOP
      l_sub_requests(i) := 1;
    END LOOP;

    l_req_id := 1;
    IF l_req_id<>0 THEN
      l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
             'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
             FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
             to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
             to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
             to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
             to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
             l_command, l_idx_mem, l_num_prll, 'HZ_PARTIES');
      IF l_req_id = 0 THEN
        log('Error submitting request');
        log(fnd_message.get);
      ELSE
        log('Submitted request ID for Party Index: ' || l_req_id );
        log('Request ID : ' || l_req_id);
      END IF;
    END IF;

    IF l_req_id<>0 THEN
      IF l_index_creation = 'SERIAL' THEN
        l_sub_requests(1) := l_req_id;
      END IF;

      l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
             'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
               FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
               to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
               to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
               to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
               to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
               l_command, l_idx_mem, l_num_prll, 'HZ_PARTY_SITES');
      IF l_req_id = 0 THEN
        log('Error submitting request');
        log(fnd_message.get);
      ELSE
        log('Submitted request ID for Party Site Index: ' || l_req_id );
        log('Request ID : ' || l_req_id);
      END IF;
    END IF;

    IF l_req_id<>0 THEN
      IF l_index_creation = 'SERIAL' THEN
        l_sub_requests(1) := l_req_id;
      END IF;

      l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
               'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
               FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
               to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
               to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
               to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
               to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
               l_command, l_idx_mem, l_num_prll, 'HZ_ORG_CONTACTS');
      IF l_req_id = 0 THEN
        log('Error submitting request');
        log(fnd_message.get);
      ELSE
        log('Submitted request ID for Party Index: ' || l_req_id );
        log('Request ID : ' || l_req_id);
      END IF;
    END IF;

    IF l_req_id<>0 THEN
      IF l_index_creation = 'SERIAL' THEN
        l_sub_requests(1) := l_req_id;
      END IF;

      l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
               'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
               FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
               to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
               to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
               to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
               to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
               l_command, l_idx_mem, l_num_prll, 'HZ_CONTACT_POINTS');
      IF l_req_id = 0 THEN
        log('Error submitting request');
        log(fnd_message.get);
      ELSE
        log('Submitted request ID for Contact Point Index: ' || l_req_id );
        log('Request ID : ' || l_req_id);
      END IF;
    END IF;
  ELSIF l_command='CREATE_MISSING_INVALID_INDEXES' THEN
    IF l_continue = 'N' THEN
      generate_datastore_prefs;
      DELETE from HZ_DQM_STAGE_LOG where operation = 'CREATE_INDEXES';
      create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_PARTIES');
      create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_PARTY_SITES');
      create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_ORG_CONTACTS');
      create_log(
          p_operation=>'CREATE_INDEXES',
          p_step=>'HZ_CONTACT_POINTS');
    END IF;
    FOR I in 1..10 LOOP
      l_sub_requests(i) := 1;
    END LOOP;

    l_req_id := 1;
    BEGIN
      SELECT 1 INTO T FROM HZ_STAGED_PARTIES
      WHERE ROWNUM=1
      AND CONTAINS (concat_col, 'dummy_string')>0;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        UPDATE HZ_DQM_STAGE_LOG
        SET START_FLAG ='Y', START_TIME=SYSDATE,END_FLAG = 'Y', END_TIME=SYSDATE
        WHERE OPERATION = 'CREATE_INDEXES' AND step = 'HZ_PARTIES';
      WHEN OTHERS THEN
        BEGIN
          EXECUTE IMMEDIATE 'DROP INDEX ' || l_index_owner || '.hz_stage_parties_t1 FORCE';
          log('Dropped hz_stage_parties_t1');
        EXCEPTION
          WHEN OTHERS THEN
            log('Error dropping hz_stage_parties_t1 ' || SQLERRM);
        END;

        l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
               'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
               FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
               to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
               to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
               to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
               to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
               l_command, l_idx_mem, l_num_prll, 'HZ_PARTIES');
        IF l_req_id = 0 THEN
          log('Error submitting request');
          log(fnd_message.get);
        ELSE
          log('Submitted request ID for Party Index: ' || l_req_id );
          log('Request ID : ' || l_req_id);
        END IF;
    END;

    BEGIN
      SELECT 1 INTO T FROM HZ_STAGED_PARTY_SITES
      WHERE ROWNUM=1
      AND CONTAINS (concat_col, 'dummy_string')>0;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        UPDATE HZ_DQM_STAGE_LOG
        SET START_FLAG ='Y', START_TIME=SYSDATE,END_FLAG = 'Y', END_TIME=SYSDATE
        WHERE OPERATION = 'CREATE_INDEXES' AND step = 'HZ_PARTY_SITES';
      WHEN OTHERS THEN

        BEGIN
          EXECUTE IMMEDIATE 'DROP INDEX ' || l_index_owner || '.hz_stage_party_sites_t1 FORCE';
          log('Dropped hz_stage_party_sites_t1');
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;

        IF l_index_creation = 'SERIAL' THEN
          l_sub_requests(1):=l_req_id;
        END IF;

        l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
               'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
               FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
               to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
               to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
               to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
               to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
               l_command, l_idx_mem, l_num_prll, 'HZ_PARTY_SITES');
        IF l_req_id = 0 THEN
          log('Error submitting request');
          log(fnd_message.get);
        ELSE
          log('Submitted request ID for Party Index: ' || l_req_id );
          log('Request ID : ' || l_req_id);
        END IF;
    END;

    BEGIN
      SELECT 1 INTO T FROM HZ_STAGED_CONTACTS
      WHERE ROWNUM=1
      AND CONTAINS (concat_col, 'dummy_string')>0;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        UPDATE HZ_DQM_STAGE_LOG
        SET START_FLAG ='Y', START_TIME=SYSDATE,END_FLAG = 'Y', END_TIME=SYSDATE
        WHERE OPERATION = 'CREATE_INDEXES' AND step = 'HZ_ORG_CONTACTS';
      WHEN OTHERS THEN

        BEGIN
          EXECUTE IMMEDIATE 'DROP INDEX ' || l_index_owner || '.hz_stage_contact_t1 FORCE';
          log('Dropped hz_stage_contact_t1');
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;

        IF l_index_creation = 'SERIAL' THEN
          l_sub_requests(1):=l_req_id;
        END IF;

        l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
               'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
               FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
               to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
               to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
               to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
               to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
               l_command, l_idx_mem, l_num_prll, 'HZ_ORG_CONTACTS');
        IF l_req_id = 0 THEN
          log('Error submitting request');
          log(fnd_message.get);
        ELSE
          log('Submitted request ID for Contact Index: ' || l_req_id );
          log('Request ID : ' || l_req_id);
        END IF;
    END;

    BEGIN
      SELECT 1 INTO T FROM HZ_STAGED_CONTACT_POINTS
      WHERE ROWNUM=1
      AND CONTAINS (concat_col, 'dummy_string')>0;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        UPDATE HZ_DQM_STAGE_LOG
        SET START_FLAG ='Y', START_TIME=SYSDATE,END_FLAG = 'Y', END_TIME=SYSDATE
        WHERE OPERATION = 'CREATE_INDEXES' AND step = 'HZ_CONTACT_POINTS';
      WHEN OTHERS THEN

        BEGIN
          EXECUTE IMMEDIATE 'DROP INDEX ' || l_index_owner || '.hz_stage_cpt_t1 FORCE';
          log('Dropped hz_stage_cpt_t1');
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;

        IF l_index_creation = 'SERIAL' THEN
          l_sub_requests(1):=l_req_id;
        END IF;

        l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
               'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
               FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
               to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
               to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
               to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
               to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
               l_command, l_idx_mem, l_num_prll, 'HZ_CONTACT_POINTS');
        IF l_req_id = 0 THEN
          log('Error submitting request');
          log(fnd_message.get);
        ELSE
          log('Submitted request ID for Contact Point Index: ' || l_req_id );
          log('Request ID : ' || l_req_id);
        END IF;
    END;
  ELSIF p_command='RECREATE_BTREE_INDEXES' THEN
    drop_btree_indexes;
    FOR I in 1..10 LOOP
      l_sub_requests(i) := 1;
    END LOOP;

    l_index := 'HZ_PARTIES_BTREE';
    l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
             'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
             FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
             to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
             to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
             to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
             to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
             l_command, l_idx_mem, l_num_prll, l_index);
    IF l_req_id = 0 THEN
          log('Error submitting request');
          log(fnd_message.get);
    ELSE
          log('Submitted request ID for Party Index: ' || l_req_id );
          log('Request ID : ' || l_req_id);
    END IF;

    l_index := 'HZ_PARTY_SITES_BTREE';

    l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
             'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
               FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
               to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
               to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
               to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
               to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
               l_command, l_idx_mem, l_num_prll, l_index);
    IF l_req_id = 0 THEN
          log('Error submitting request');
          log(fnd_message.get);
    ELSE
          log('Submitted request ID for Party Site Index: ' || l_req_id );
          log('Request ID : ' || l_req_id);
    END IF;

    l_index := 'HZ_ORG_CONTACTS_BTREE';

    l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
               'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
               FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
               to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
               to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
               to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
               to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
               l_command, l_idx_mem, l_num_prll, l_index);
    IF l_req_id = 0 THEN
          log('Error submitting request');
          log(fnd_message.get);
    ELSE
          log('Submitted request ID for Contact Index: ' || l_req_id );
          log('Request ID : ' || l_req_id);
    END IF;

    l_index := 'HZ_CONTACT_POINTS_BTREE';

    l_req_id := FND_REQUEST.SUBMIT_REQUEST('AR', 'ARHDQMCR',
               'DQM Create Index', to_char(sysdate,'DD-MON-YY HH:MI:SS'),
               FALSE, to_char(l_sub_requests(1)), to_char(l_sub_requests(2)),
               to_char(l_sub_requests(3)), to_char(l_sub_requests(4)),
               to_char(l_sub_requests(5)), to_char(l_sub_requests(6)),
               to_char(l_sub_requests(7)), to_char(l_sub_requests(8)),
               to_char(l_sub_requests(9)), to_char(l_sub_requests(10)),
               l_command, l_idx_mem, l_num_prll, l_index);
    IF l_req_id = 0 THEN
          log('Error submitting request');
          log(fnd_message.get);
    ELSE
          log('Submitted request ID for Contact Point Index: ' || l_req_id );
          log('Request ID : ' || l_req_id);
    END IF;

  END IF;
  outandlog('Concurrent Program Execution completed ');
  outandlog('End Time : '|| TO_CHAR(SYSDATE, 'MM-DD-YY HH24:MI:SS'));
EXCEPTION
  WHEN FND_API.G_EXC_ERROR THEN
    outandlog('Error: Aborting staging');
    retcode := 2;
    errbuf := errbuf || logerror || SQLERRM;
    FND_FILE.close;
  WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    outandlog('Error: Aborting staging');
    retcode := 2;
    errbuf := errbuf || logerror || SQLERRM;
   FND_FILE.close;
  WHEN OTHERS THEN
    log(fnd_message.get);
    outandlog('Error: Aborting staging');
    retcode := 2;
    errbuf := errbuf || logerror || SQLERRM;
    FND_FILE.close;
END;


PROCEDURE gather_stats(
         table_owner          VARCHAR2,
         table_name           VARCHAR2
) IS
BEGIN
     fnd_stats.gather_table_stats(table_owner, table_name);
END gather_stats;

PROCEDURE Stage_worker(
        errbuf                  OUT NOCOPY   VARCHAR2,
        retcode                 OUT NOCOPY   VARCHAR2,
        p_num_workers           IN      VARCHAR2,
        p_worker_number         IN      VARCHAR2,
        p_command         	IN      VARCHAR2,
        p_continue         	IN      VARCHAR2

) IS

CURSOR l_log_cur(p_command VARCHAR2, l_worker_number NUMBER, l_step VARCHAR2) is
   ( SELECT start_flag, end_flag
      FROM HZ_DQM_STAGE_LOG
      WHERE OPERATION = p_command
      AND WORKER_NUMBER = l_worker_number AND step = l_step);

l_party_id		NUMBER;
l_party_type		HZ_PARTIES.PARTY_TYPE%TYPE;

l_party_staged VARCHAR2(1);
l_temp_party_id		NUMBER;
l_worker_number		NUMBER;
l_num_workers		NUMBER;

l_index_owner VARCHAR2(255);
l_temp VARCHAR2(255);
l_bool BOOLEAN;
l_status VARCHAR2(255);

l_error  VARCHAR2(2000);

l_party_cur StageCurTyp;
l_party_site_cur StageCurTyp;
l_contact_cur StageCurTyp;
l_cpt_cur StageCurTyp;

l_start_flag VARCHAR2(30);
l_end_flag VARCHAR2(30);

l_number_of_workers NUMBER;
l_startdate DATE;

l_log_step VARCHAR2(30);

BEGIN

  retcode := 0;
  l_worker_number := TO_NUMBER(p_worker_number);
  l_num_workers := TO_NUMBER(p_num_workers);
  IF l_worker_number = l_num_workers THEN
    l_worker_number := 0;
  END IF;


  log('Starting Concurrent Program ''Stage Party Data'', Worker:  ' ||
            p_worker_number);
  log('Start Time ' || TO_CHAR(SYSDATE, 'MM-DD-YY HH24:MI:SS'));
  log('NEWLINE');

  log('This worker stages all parties whose party_id/10 produces a remainder equal to the worker number ');

  log('');
  log('Stage Parties begin');

  FND_MSG_PUB.initialize;

  IF p_command='STAGE_ALL_DATA' THEN

    SELECT SYSDATE INTO l_startdate FROM DUAL;

    log('Staging Organization Party Records');

    OPEN l_log_cur(p_command, l_worker_number, 'STEP1');
    FETCH l_log_cur INTO l_start_flag, l_end_flag;
    IF (l_log_cur%NOTFOUND) THEN
       l_start_flag:=NULL;
       l_end_flag:=NULL;
    END IF;
    CLOSE l_log_cur;

    IF nvl(l_end_flag,'N') = 'N' THEN
      IF nvl(l_start_flag ,'N') = 'N' THEN

        l_log_step := 'STEP1';
        UPDATE HZ_DQM_STAGE_LOG set start_flag='Y', start_time = SYSDATE
        WHERE OPERATION = p_command
        AND WORKER_NUMBER = l_worker_number AND step = l_log_step;
        COMMIT;

        HZ_TRANS_PKG.set_party_type('ORGANIZATION');
        HZ_STAGE_MAP_TRANSFORM.open_party_cursor(
         'ALL_PARTIES', 'ORGANIZATION',l_worker_number, l_num_workers, NULL,'N', l_party_cur);
        HZ_STAGE_MAP_TRANSFORM.insert_stage_parties('N',l_party_cur);
      ELSE
        HZ_TRANS_PKG.set_party_type('ORGANIZATION');
        log(' Continue for Org cursor');
        HZ_STAGE_MAP_TRANSFORM.open_party_cursor(
         'ALL_PARTIES', 'ORGANIZATION',l_worker_number, l_num_workers, NULL,'Y', l_party_cur);
        HZ_STAGE_MAP_TRANSFORM.insert_stage_parties('Y',l_party_cur);
      END IF;

      CLOSE l_party_cur;
      l_log_step := 'STEP1';
      UPDATE HZ_DQM_STAGE_LOG set end_flag='Y', end_time = SYSDATE
      WHERE OPERATION = p_command
      AND WORKER_NUMBER = l_worker_number AND step = l_log_step;

      COMMIT;
    END IF;

    log('Staging Person Party Records');
    OPEN l_log_cur(p_command, l_worker_number, 'STEP2');
    FETCH l_log_cur INTO l_start_flag, l_end_flag;
    IF (l_log_cur%NOTFOUND) THEN
       l_start_flag:=NULL;
       l_end_flag:=NULL;
    END IF;
    CLOSE l_log_cur;

    IF nvl(l_end_flag,'N') = 'N' THEN
      IF nvl(l_start_flag,'N') = 'N' THEN
        l_log_step := 'STEP2';
        UPDATE HZ_DQM_STAGE_LOG set start_flag='Y', start_time = SYSDATE
        WHERE OPERATION = p_command
        AND WORKER_NUMBER = l_worker_number AND step = l_log_step;
        COMMIT;

        HZ_TRANS_PKG.set_party_type('PERSON');
        HZ_STAGE_MAP_TRANSFORM.open_party_cursor(
          'ALL_PARTIES', 'PERSON',l_worker_number, l_num_workers, NULL,'N', l_party_cur);
        HZ_STAGE_MAP_TRANSFORM.insert_stage_parties('N',l_party_cur);
      ELSE
log(' Continue for Per cursor');
        HZ_TRANS_PKG.set_party_type('PERSON');
        HZ_STAGE_MAP_TRANSFORM.open_party_cursor(
          'ALL_PARTIES', 'PERSON',l_worker_number, l_num_workers, NULL,'Y', l_party_cur);
        HZ_STAGE_MAP_TRANSFORM.insert_stage_parties('Y',l_party_cur);
      END IF;

      CLOSE l_party_cur;
      l_log_step := 'STEP2';
      UPDATE HZ_DQM_STAGE_LOG set end_flag='Y', end_time = SYSDATE
      WHERE OPERATION = p_command
      AND WORKER_NUMBER = l_worker_number AND step = l_log_step;

      COMMIT;
    END IF;

    log('Staging Group Party Records');
    OPEN l_log_cur(p_command, l_worker_number, 'STEP3');
    FETCH l_log_cur INTO l_start_flag, l_end_flag;
    IF (l_log_cur%NOTFOUND) THEN
       l_start_flag:=NULL;
       l_end_flag:=NULL;
    END IF;
    CLOSE l_log_cur;

    IF nvl(l_end_flag,'N') = 'N' THEN
      IF nvl(l_start_flag,'N') = 'N' THEN
        l_log_step := 'STEP3';
        UPDATE HZ_DQM_STAGE_LOG set start_flag='Y', start_time = SYSDATE
        WHERE OPERATION = p_command
        AND WORKER_NUMBER = l_worker_number AND step = l_log_step;
        COMMIT;

        HZ_TRANS_PKG.set_party_type('OTHER');
        HZ_STAGE_MAP_TRANSFORM.open_party_cursor(
          'ALL_PARTIES', 'OTHER',l_worker_number, l_num_workers, NULL,'N', l_party_cur);
        HZ_STAGE_MAP_TRANSFORM.insert_stage_parties('N',l_party_cur);
      ELSE
log(' Continue for Oth cursor');

        HZ_TRANS_PKG.set_party_type('OTHER');
        HZ_STAGE_MAP_TRANSFORM.open_party_cursor(
          'ALL_PARTIES', 'OTHER',l_worker_number, l_num_workers, NULL,'Y', l_party_cur);
        HZ_STAGE_MAP_TRANSFORM.insert_stage_parties('Y',l_party_cur);
      END IF;

      CLOSE l_party_cur;
      l_log_step := 'STEP3';
      UPDATE HZ_DQM_STAGE_LOG set end_flag='Y', end_time = SYSDATE
      WHERE OPERATION = p_command
      AND WORKER_NUMBER = l_worker_number AND step = l_log_step;

      COMMIT;

    END IF;

    DELETE FROM HZ_DQM_SYNC_INTERFACE WHERE mod(PARTY_ID,l_num_workers) = l_worker_number
    AND creation_date<=l_startdate;

  ELSE
    log('Updating Organization Party Records');
    OPEN l_log_cur(p_command, l_worker_number, 'STEP1');
    FETCH l_log_cur INTO l_start_flag, l_end_flag;
    IF (l_log_cur%NOTFOUND) THEN
       l_start_flag:=NULL;
       l_end_flag:=NULL;
    END IF;
    CLOSE l_log_cur;

    IF nvl(l_end_flag,'N') = 'N' THEN
      IF nvl(l_start_flag,'N') = 'N' THEN
        l_log_step := 'STEP1';
        UPDATE HZ_DQM_STAGE_LOG set start_flag='Y', start_time = SYSDATE
        WHERE OPERATION = p_command
        AND WORKER_NUMBER = l_worker_number AND step = l_log_step;
        COMMIT;

      END IF;

      HZ_TRANS_PKG.set_party_type('ORGANIZATION');
      HZ_STAGE_MAP_TRANSFORM_UPD.open_party_cursor(
        'ORGANIZATION',l_worker_number, l_num_workers, l_party_cur);
      IF l_party_cur IS NOT NULL THEN
        HZ_STAGE_MAP_TRANSFORM_UPD.update_stage_parties(l_party_cur);
        CLOSE l_party_cur;
      END IF;

      l_log_step := 'STEP1';
      UPDATE HZ_DQM_STAGE_LOG set end_flag='Y', end_time = SYSDATE
      WHERE OPERATION = p_command
      AND WORKER_NUMBER = l_worker_number AND step = l_log_step;

      COMMIT;
    END IF;

    log('Updating Person Party Records');
    OPEN l_log_cur(p_command, l_worker_number, 'STEP2');
    FETCH l_log_cur INTO l_start_flag, l_end_flag;
    IF (l_log_cur%NOTFOUND) THEN
       l_start_flag:=NULL;
       l_end_flag:=NULL;
    END IF;
    CLOSE l_log_cur;

    IF nvl(l_end_flag,'N') = 'N' THEN
      IF nvl(l_start_flag,'N') = 'N' THEN
        l_log_step := 'STEP2';
        UPDATE HZ_DQM_STAGE_LOG set start_flag='Y', start_time = SYSDATE
        WHERE OPERATION = p_command
        AND WORKER_NUMBER = l_worker_number AND step = l_log_step;

      END IF;

      HZ_TRANS_PKG.set_party_type('PERSON');
      HZ_STAGE_MAP_TRANSFORM_UPD.open_party_cursor(
        'PERSON',l_worker_number, l_num_workers, l_party_cur);

      IF l_party_cur IS NOT NULL THEN
        HZ_STAGE_MAP_TRANSFORM_UPD.update_stage_parties(l_party_cur);
        CLOSE l_party_cur;
      END IF;
      l_log_step := 'STEP2';
      UPDATE HZ_DQM_STAGE_LOG set end_flag='Y', end_time = SYSDATE
      WHERE OPERATION = p_command
      AND WORKER_NUMBER = l_worker_number AND step = l_log_step;

      COMMIT;
    END IF;

    log('Updating Group Party Records');

    OPEN l_log_cur(p_command, l_worker_number, 'STEP3');
    FETCH l_log_cur INTO l_start_flag, l_end_flag;
    IF (l_log_cur%NOTFOUND) THEN
       l_start_flag:=NULL;
       l_end_flag:=NULL;
    END IF;
    CLOSE l_log_cur;

    IF nvl(l_end_flag,'N') = 'N' THEN
      IF nvl(l_start_flag,'N') = 'N' THEN
        l_log_step := 'STEP3';
        UPDATE HZ_DQM_STAGE_LOG set start_flag='Y', start_time = SYSDATE
        WHERE OPERATION = p_command
        AND WORKER_NUMBER = l_worker_number AND step = l_log_step;
      END IF;

      HZ_TRANS_PKG.set_party_type('OTHER');
      HZ_STAGE_MAP_TRANSFORM_UPD.open_party_cursor(
        'OTHER',l_worker_number, l_num_workers, l_party_cur);

      IF l_party_cur IS NOT NULL THEN
        HZ_STAGE_MAP_TRANSFORM_UPD.update_stage_parties(l_party_cur);
        CLOSE l_party_cur;
      END IF;

      l_log_step := 'STEP3';
      UPDATE HZ_DQM_STAGE_LOG set end_flag='Y', end_time = SYSDATE
      WHERE OPERATION = p_command
      AND WORKER_NUMBER = l_worker_number AND step = l_log_step;

      COMMIT;
    END IF;

    log('Updating Contact Records');
    OPEN l_log_cur(p_command, l_worker_number, 'STEP4');
    FETCH l_log_cur INTO l_start_flag, l_end_flag;
    IF (l_log_cur%NOTFOUND) THEN
       l_start_flag:=NULL;
       l_end_flag:=NULL;
    END IF;
    CLOSE l_log_cur;


    IF nvl(l_end_flag,'N') = 'N' THEN
      IF nvl(l_start_flag,'N') = 'N' THEN
        l_log_step := 'STEP4';
        UPDATE HZ_DQM_STAGE_LOG set start_flag='Y', start_time = SYSDATE
        WHERE OPERATION = p_command
        AND WORKER_NUMBER = l_worker_number AND step = l_log_step;

      END IF;

      HZ_STAGE_MAP_TRANSFORM_UPD.open_contact_cursor(
        l_worker_number, l_num_workers, l_contact_cur);
      IF l_contact_cur IS NOT NULL THEN
        HZ_STAGE_MAP_TRANSFORM_UPD.update_stage_contacts(l_contact_cur);
        CLOSE l_contact_cur;
      END IF;
      l_log_step := 'STEP4';
      UPDATE HZ_DQM_STAGE_LOG set end_flag='Y', end_time = SYSDATE
      WHERE OPERATION = p_command
      AND WORKER_NUMBER = l_worker_number AND step = l_log_step;

      COMMIT;
    END IF;

    log('Updating Party Site Records');
    OPEN l_log_cur(p_command, l_worker_number, 'STEP5');
    FETCH l_log_cur INTO l_start_flag, l_end_flag;
    IF (l_log_cur%NOTFOUND) THEN
       l_start_flag:=NULL;
       l_end_flag:=NULL;
    END IF;
    CLOSE l_log_cur;


    IF nvl(l_end_flag,'N') = 'N' THEN
      IF nvl(l_start_flag,'N') = 'N' THEN
        l_log_step := 'STEP5';
        UPDATE HZ_DQM_STAGE_LOG set start_flag='Y', start_time = SYSDATE
        WHERE OPERATION = p_command
        AND WORKER_NUMBER = l_worker_number AND step = l_log_step;

      END IF;

      HZ_STAGE_MAP_TRANSFORM_UPD.open_party_site_cursor(
        l_worker_number, l_num_workers, l_party_site_cur);
      IF l_party_site_cur IS NOT NULL THEN
        HZ_STAGE_MAP_TRANSFORM_UPD.update_stage_party_sites(l_party_site_cur);
        CLOSE l_party_site_cur;
      END IF;

      l_log_step := 'STEP5';
      UPDATE HZ_DQM_STAGE_LOG set end_flag='Y', end_time = SYSDATE
      WHERE OPERATION = p_command
      AND WORKER_NUMBER = l_worker_number AND step = l_log_step;

      COMMIT;
    END IF;

    log('Updating Contact Point Records');
    OPEN l_log_cur(p_command, l_worker_number, 'STEP6');
    FETCH l_log_cur INTO l_start_flag, l_end_flag;
    IF (l_log_cur%NOTFOUND) THEN
       l_start_flag:=NULL;
       l_end_flag:=NULL;
    END IF;
    CLOSE l_log_cur;

    IF nvl(l_end_flag,'N') = 'N' THEN
      IF nvl(l_start_flag,'N') = 'N' THEN
        l_log_step := 'STEP6';
        UPDATE HZ_DQM_STAGE_LOG set start_flag='Y', start_time = SYSDATE
        WHERE OPERATION = p_command
        AND WORKER_NUMBER = l_worker_number AND step = l_log_step;

      END IF;

      HZ_STAGE_MAP_TRANSFORM_UPD.open_contact_pt_cursor(
        l_worker_number, l_num_workers, l_cpt_cur);
      IF l_cpt_cur IS NOT NULL THEN
        HZ_STAGE_MAP_TRANSFORM_UPD.update_stage_contact_pts(l_cpt_cur);
        CLOSE l_cpt_cur;
      END IF;
      l_log_step := 'STEP6';
      UPDATE HZ_DQM_STAGE_LOG set end_flag='Y', end_time = SYSDATE
      WHERE OPERATION = p_command
      AND WORKER_NUMBER = l_worker_number AND step = l_log_step;

      COMMIT;
    END IF;

  END IF;
  log('Concurrent Program Execution completed ');
  log('End Time : '|| TO_CHAR(SYSDATE, 'MM-DD-YY HH24:MI:SS'));

EXCEPTION
  WHEN FND_API.G_EXC_ERROR THEN
    outandlog('Error: Aborting staging ' || FND_MESSAGE.GET);
    retcode := 2;
    errbuf := errbuf || logerror;
    FND_FILE.close;
  WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    outandlog('Error: Aborting staging ' || FND_MESSAGE.GET);
    retcode := 2;
    errbuf := errbuf || logerror;
   FND_FILE.close;
  WHEN OTHERS THEN
    outandlog('Error: Aborting staging '|| SQLERRM);
    retcode := 2;
    errbuf := errbuf || logerror;
    FND_FILE.close;
END;

FUNCTION new_primary_trans(p_entity VARCHAR2
)    RETURN BOOLEAN IS
  cursor is_new_tran (p_entity VARCHAR2) is
        select 'Y'
        from hz_trans_functions_vl t, hz_trans_attributes_b a
        where  a.attribute_id = t.attribute_id
        and ENTITY_NAME = p_entity
        and  nvl(staged_flag, 'N') = 'N'
        and primary_flag = 'Y'
        and nvl(active_flag, 'Y') = 'Y'
        and rownum = 1;
  l_var VARCHAR2(1);
BEGIN
     l_var := 'N';
     OPEN is_new_tran(p_entity);
     FETCH is_new_tran INTO l_var;
     CLOSE is_new_tran;
     IF (l_var = 'Y') THEN
         return true;
     ELSE
         return false;
     END IF;
EXCEPTION WHEN OTHERS THEN
     CLOSE is_new_tran;
     return true;
END new_primary_trans;

PROCEDURE Stage_create_index (
        errbuf                  OUT NOCOPY    VARCHAR2,
        retcode                 OUT NOCOPY   VARCHAR2,
	p_req1			IN      VARCHAR2,
	p_req2			IN	VARCHAR2,
	p_req3			IN	VARCHAR2,
	p_req4			IN	VARCHAR2,
	p_req5			IN	VARCHAR2,
	p_req6			IN	VARCHAR2,
	p_req7			IN	VARCHAR2,
	p_req8			IN	VARCHAR2,
	p_req9			IN	VARCHAR2,
	p_req10			IN	VARCHAR2,
	p_command		IN	VARCHAR2,
	p_idx_mem		IN	VARCHAR2,
	p_num_prll		IN	VARCHAR2,
	p_index			IN	VARCHAR2
) IS

  CURSOR c_num_attrs (p_entity VARCHAR2) IS
    SELECT count(1) FROM
      (SELECT distinct f.staged_attribute_column
      FROM HZ_TRANS_FUNCTIONS_VL f, HZ_TRANS_ATTRIBUTES_VL a
      WHERE PRIMARY_FLAG = 'Y'
      AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
      and f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
      AND a.entity_name = p_entity
      );

  l_num_sections NUMBER;
  l_req1 CONSTANT NUMBER := TO_NUMBER(p_req1);
  l_req2 CONSTANT NUMBER := TO_NUMBER(p_req2);
  l_req3 CONSTANT NUMBER := TO_NUMBER(p_req3);
  l_req4 CONSTANT NUMBER := TO_NUMBER(p_req4);
  l_req5 CONSTANT NUMBER := TO_NUMBER(p_req5);
  l_req6 CONSTANT NUMBER := TO_NUMBER(p_req6);
  l_req7 CONSTANT NUMBER := TO_NUMBER(p_req7);
  l_req8 CONSTANT NUMBER := TO_NUMBER(p_req8);
  l_req9 CONSTANT NUMBER := TO_NUMBER(p_req9);
  l_req10 CONSTANT NUMBER := TO_NUMBER(p_req10);

  uphase VARCHAR2(255);
  dphase VARCHAR2(255);
  ustatus VARCHAR2(255);
  dstatus VARCHAR2(255);
  l_index_owner VARCHAR2(255);
  message VARCHAR2(32000);

  l_bool BOOLEAN;

  -- VJN created for making code user friendly
  CREATE_PARTY_TEXT_INDEX BOOLEAN := FALSE ;
  CREATE_PS_TEXT_INDEX BOOLEAN := FALSE ;
  CREATE_CONTACT_TEXT_INDEX BOOLEAN := FALSE ;
  CREATE_CPT_TEXT_INDEX BOOLEAN := FALSE ;
  CREATE_ALL_BTREE_INDEXES BOOLEAN := FALSE ;
  CREATE_ALL_TEXT_INDEXES BOOLEAN := FALSE ;
  SYNC_PARTY_TEXT_INDEX BOOLEAN := FALSE ;
  SYNC_PS_TEXT_INDEX BOOLEAN := FALSE ;
  SYNC_CONTACT_TEXT_INDEX BOOLEAN := FALSE ;
  SYNC_CPT_TEXT_INDEX BOOLEAN := FALSE ;
  SYNC_DENORM_PARTY_TEXT_INDEX BOOLEAN := FALSE ;
  index_build_type VARCHAR2(255);


  l_num_parts NUMBER;
  l_num_jobs NUMBER;
  l_num_prll NUMBER;

  l_start_flag VARCHAR2(30);
  l_end_flag VARCHAR2(30);
  l_command VARCHAR2(255);

  l_section_grp VARCHAR2(255);
  l_min_id number;
  l_max_id number;
  tmp number;


BEGIN

  retcode := 0;
  l_command := p_command;

  log ('--------------------------------------');
  outandlog('Starting Concurrent Program ''Create DQM indexes''');
  outandlog('Start Time ' || TO_CHAR(SYSDATE, 'MM-DD-YY HH24:MI:SS'));
  outandlog('NEWLINE');

  outandlog('Waiting for workers to complete');

  BEGIN
    IF l_req1 <> 1 THEN
      l_bool := FND_CONCURRENT.wait_for_request(TO_NUMBER(l_req1),
         30, 144000, uphase, ustatus, dphase, dstatus, message);
      IF dphase <> 'COMPLETE' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req1);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      ELSIF dphase = 'COMPLETE' and dstatus <> 'NORMAL' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req1);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;
    IF l_req2 <> 1 THEN
      l_bool := FND_CONCURRENT.wait_for_request(TO_NUMBER(l_req2),
         30, 144000, uphase, ustatus, dphase, dstatus, message);
      IF dphase <> 'COMPLETE' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req2);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      ELSIF dphase = 'COMPLETE' and dstatus <> 'NORMAL' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req2);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;
    IF l_req3 <> 1 THEN
      l_bool := FND_CONCURRENT.wait_for_request(TO_NUMBER(l_req3),
         30, 144000, uphase, ustatus, dphase, dstatus, message);
      IF dphase <> 'COMPLETE' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req3);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      ELSIF dphase = 'COMPLETE' and dstatus <> 'NORMAL' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req3);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;
    IF l_req4 <> 1 THEN
      l_bool := FND_CONCURRENT.wait_for_request(TO_NUMBER(l_req4),
         30, 144000, uphase, ustatus, dphase, dstatus, message);
      IF dphase <> 'COMPLETE' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req3);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      ELSIF dphase = 'COMPLETE' and dstatus <> 'NORMAL' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req4);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;
    IF l_req5 <> 1 THEN
      l_bool := FND_CONCURRENT.wait_for_request(TO_NUMBER(l_req5),
         30, 144000, uphase, ustatus, dphase, dstatus, message);
      IF dphase <> 'COMPLETE' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req4);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      ELSIF dphase = 'COMPLETE' and dstatus <> 'NORMAL' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req5);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;
    IF l_req6 <> 1 THEN
      l_bool := FND_CONCURRENT.wait_for_request(TO_NUMBER(l_req6),
         30, 144000, uphase, ustatus, dphase, dstatus, message);
      IF dphase <> 'COMPLETE' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req5);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      ELSIF dphase = 'COMPLETE' and dstatus <> 'NORMAL' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req6);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;
    IF l_req7 <> 1 THEN
      l_bool := FND_CONCURRENT.wait_for_request(TO_NUMBER(l_req7),
         30, 144000, uphase, ustatus, dphase, dstatus, message);
      IF dphase <> 'COMPLETE' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req6);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      ELSIF dphase = 'COMPLETE' and dstatus <> 'NORMAL' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req7);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;
    IF l_req8 <> 1 THEN
      l_bool := FND_CONCURRENT.wait_for_request(TO_NUMBER(l_req8),
         30, 144000, uphase, ustatus, dphase, dstatus, message);
      IF dphase <> 'COMPLETE' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req8);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      ELSIF dphase = 'COMPLETE' and dstatus <> 'NORMAL' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req8);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;
    IF l_req9 <> 1 THEN
      l_bool := FND_CONCURRENT.wait_for_request(TO_NUMBER(l_req9),
         30, 144000, uphase, ustatus, dphase, dstatus, message);
      IF dphase <> 'COMPLETE' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req9);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      ELSIF dphase = 'COMPLETE' and dstatus <> 'NORMAL' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req9);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;
    IF l_req10 <> 1 THEN
      l_bool := FND_CONCURRENT.wait_for_request(TO_NUMBER(l_req10),
         30, 144000, uphase, ustatus, dphase, dstatus, message);
      IF dphase <> 'COMPLETE' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req10);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      ELSIF dphase = 'COMPLETE' and dstatus <> 'NORMAL' THEN
        FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_WORKER_ERROR');
        FND_MESSAGE.SET_TOKEN('ID' ,l_req10);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;
  EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
      RAISE FND_API.G_EXC_ERROR;
    WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_SQL_ERROR');
      FND_MESSAGE.SET_TOKEN('PROC' ,'Index Creation Worker Completion Check');
      FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
      FND_MSG_PUB.ADD;
      RAISE FND_API.G_EXC_ERROR;
  END;

  COMMIT;
  log('Workers have completed successfully');

  l_bool := fnd_installation.GET_APP_INFO('AR',ustatus,dstatus,l_index_owner);


  -- DECODE WHAT p_index MEANS IN MEANINGFUL TERMS
  IF p_index = 'ALL'
  THEN
        CREATE_ALL_TEXT_INDEXES := TRUE ;
        CREATE_PARTY_TEXT_INDEX := TRUE ;
        CREATE_PS_TEXT_INDEX := TRUE ;
        CREATE_CONTACT_TEXT_INDEX := TRUE ;
        CREATE_CPT_TEXT_INDEX := TRUE ;
        index_build_type := 'CREATE' ;

  ELSIF p_index = 'ALL_BTREE'
  THEN
        CREATE_ALL_BTREE_INDEXES := TRUE ;
        index_build_type := 'CREATE' ;

  ELSIF p_index = 'HZ_PARTIES'
  THEN
        CREATE_PARTY_TEXT_INDEX := TRUE ;
        index_build_type := 'CREATE' ;

  ELSIF p_index = 'HZ_PARTY_SITES'
  THEN
        CREATE_PS_TEXT_INDEX := TRUE ;
        index_build_type := 'CREATE' ;

  ELSIF p_index = 'HZ_ORG_CONTACTS'
  THEN
        CREATE_CONTACT_TEXT_INDEX := TRUE ;
        index_build_type := 'CREATE' ;


  ELSIF p_index = 'HZ_CONTACT_POINTS'
  THEN
        CREATE_CPT_TEXT_INDEX := TRUE ;
        index_build_type := 'CREATE' ;

  ELSIF p_index = 'HZ_PARTIES_BTREE'
  THEN
        SYNC_PARTY_TEXT_INDEX := TRUE ;
        index_build_type := 'SYNC' ;

  ELSIF p_index = 'HZ_PARTY_SITES_BTREE'
  THEN
        SYNC_PS_TEXT_INDEX := TRUE ;
        index_build_type := 'SYNC' ;

  ELSIF p_index = 'HZ_ORG_CONTACTS_BTREE'
  THEN
        SYNC_CONTACT_TEXT_INDEX := TRUE ;
        index_build_type := 'SYNC' ;

  ELSIF p_index = 'HZ_CONTACT_POINTS_BTREE'
  THEN
        SYNC_CPT_TEXT_INDEX := TRUE ;
        index_build_type := 'SYNC' ;

  ELSIF p_index = 'STAGE_NEW_DENORM'
  THEN
        SYNC_DENORM_PARTY_TEXT_INDEX := TRUE ;
        index_build_type := 'SYNC' ;

  END IF  ;

  -- NOTE ::
  --      TEXT INDEXES -- THESE ARE CREATED OR SYNCED, DEPENDING ON THE FLOW
  --      B-TREE INDEXES -- 1. THERE IS NO CONCEPT OF SYNC FOR THESE. IT IS ALWAYS A CREATE FOR THEM WITH THE
  --                           UNDERSTANDING THAT CREATION HAPPENS AFTER MAKING SURE THEY DO NOT EXIST ALREADY.
  --                        2. THESE ARE ALWAYS CREATED, REGARDLESS OF THE BUILD TYPE.



  -- SYNC FLOW
  IF index_build_type = 'SYNC'
  THEN
            log(' Index build type is SYNC for the INDEX Worker');
            -- SYNC DENORM PARTY TEXT INDEX
            IF SYNC_DENORM_PARTY_TEXT_INDEX THEN
                outandlog('Submitting index request for new denorm attributes.');
                create_btree_indexes ('PARTY');
                BEGIN
                       select min(party_id), max(party_id)
                       into l_min_id, l_max_id
                       from hz_staged_parties;
                       WHILE (l_min_id <= l_max_id )
                       LOOP
                           select party_id into tmp
                           from (
                                 select party_id, rownum rnum
                                 from (  SELECT party_id
                                             from hz_staged_parties
                                             where party_id>l_min_id
                                             and rownum<1001 ) a )
                           where rnum = 1000;
                           update hz_staged_parties set d_ps = 'SYNC', d_ct = 'SYNC', d_cpt = 'SYNC', concat_col = concat_col
                               where party_id between l_min_id and tmp;
                           AD_CTX_DDL.sync_index(l_index_owner|| '.hz_stage_parties_t1');
                           FND_Concurrent.af_commit;
                           l_min_id:=tmp+1;
                      END LOOP;
                 EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                          update hz_staged_parties set concat_col = concat_col,
                               d_ps = 'SYNC', d_ct = 'SYNC', d_cpt = 'SYNC'
                               where party_id between l_min_id and l_max_id ;
                          AD_CTX_DDL.sync_index(l_index_owner ||'.hz_stage_parties_t1');
                          FND_Concurrent.af_commit;
                      WHEN OTHERS THEN
                          FND_FILE.put_line(FND_FILE.log, 'Error during DENORM PARTY Index Synchronization SQLEERM=' ||SQLERRM);
                          retcode := 2;
                         errbuf := SQLERRM;
                 END;

               outandlog('Done index request for new denorm attributes.');
        -- SYNC DENORM PARTY INDEX
        ELSIF SYNC_PARTY_TEXT_INDEX  THEN
          create_btree_indexes ('PARTY');
          IF (new_primary_trans('PARTY')) THEN
             BEGIN
                   select min(party_id), max(party_id)
                   into l_min_id, l_max_id
                   from hz_staged_parties;
                   WHILE (l_min_id <= l_max_id )
                   LOOP
                       select party_id into tmp
                       from (
                             select party_id, rownum rnum
                             from (  SELECT party_id
                                         from hz_staged_parties
                                         where party_id>l_min_id
                                         and rownum<1001 ) a )
                       where rnum = 1000;
                       update hz_staged_parties set concat_col = concat_col
                           where party_id between l_min_id and tmp;
                       FND_FILE.put_line(FND_FILE.log, 'Attempting to SYNC the hz_stage_parties_t1 index');
                       AD_CTX_DDL.sync_index(l_index_owner|| '.hz_stage_parties_t1');
                       FND_FILE.put_line(FND_FILE.log, 'SYNC of the hz_stage_parties_t1 index successful');
                       FND_Concurrent.af_commit;
                       l_min_id:=tmp+1;
                  END LOOP;
             EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      update hz_staged_parties set concat_col = concat_col
                           where party_id between l_min_id and l_max_id ;
                      FND_FILE.put_line(FND_FILE.log, 'Attempting to SYNC the hz_stage_parties_t1 index');
                      AD_CTX_DDL.sync_index(l_index_owner ||'.hz_stage_parties_t1');
                      FND_FILE.put_line(FND_FILE.log, 'SYNC of the hz_stage_parties_t1 index successful');
                      FND_Concurrent.af_commit;
                  WHEN OTHERS THEN
                      FND_FILE.put_line(FND_FILE.log, 'Error during PARTY Index Synchronization SQLEERM=' ||SQLERRM);
                      retcode := 2;
                     errbuf := SQLERRM;
             END;

          END IF;
          UPDATE HZ_TRANS_FUNCTIONS_B
                SET STAGED_FLAG='Y'
                WHERE nvl(ACTIVE_FLAG,'Y') = 'Y' and staged_flag='N'
                and attribute_id in (
                      select attribute_id from hz_trans_attributes_vl where entity_name='PARTY');
          -- SYNC DENORM PARTY SITE TEXT INDEX
          ELSIF SYNC_PS_TEXT_INDEX THEN
            create_btree_indexes ('PARTY_SITES');
            IF (new_primary_trans('PARTY_SITES')) THEN
               BEGIN
                     select min(party_site_id), max(party_site_id)
                     into l_min_id, l_max_id
                     from hz_staged_party_sites;
                     WHILE (l_min_id <= l_max_id )
                     LOOP
                         select party_site_id into tmp
                         from (
                               select party_site_id, rownum rnum
                               from (  SELECT party_site_id
                                           from hz_staged_party_sites
                                           where party_site_id > l_min_id
                                           and rownum<1001 ) a )
                         where rnum = 1000;
                         update hz_staged_party_sites set concat_col = concat_col
                             where party_id between l_min_id and tmp;
                         FND_FILE.put_line(FND_FILE.log, 'Attempting to SYNC the hz_stage_party_sites_t1 index');
                         AD_CTX_DDL.sync_index(l_index_owner ||'.hz_stage_party_sites_t1');
                         FND_FILE.put_line(FND_FILE.log, 'SYNC of the hz_stage_party_sites_t1 index successful');
                         FND_Concurrent.af_commit;
                         l_min_id:=tmp+1;
                    END LOOP;
               EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        update hz_staged_party_sites set concat_col = concat_col
                             where party_site_id between l_min_id and l_max_id ;
                         FND_FILE.put_line(FND_FILE.log, 'Attempting to SYNC the hz_stage_party_sites_t1 index');
                         AD_CTX_DDL.sync_index(l_index_owner ||'.hz_stage_party_sites_t1');
                         FND_FILE.put_line(FND_FILE.log, 'SYNC of the hz_stage_party_sites_t1 index successful');
                         FND_Concurrent.af_commit;
                    WHEN OTHERS THEN
                        FND_FILE.put_line(FND_FILE.log, 'Error during PARTY SITES Index Synchronization SQLEERM=' ||SQLERRM);
                        retcode := 2;
                       errbuf := SQLERRM;
               END;
            END IF;
            UPDATE HZ_TRANS_FUNCTIONS_B
                  SET STAGED_FLAG='Y'
                  WHERE nvl(ACTIVE_FLAG,'Y') = 'Y' and staged_flag='N'
                  and attribute_id in (
                        select attribute_id from hz_trans_attributes_vl where entity_name='PARTY_SITES');
            create_denorm_attribute_pref ('PARTY_SITES');

            -- SYNC DENORM CONTACT TEXT INDEX
            ELSIF SYNC_CONTACT_TEXT_INDEX THEN
              create_btree_indexes ('CONTACTS');
              IF (new_primary_trans('CONTACTS')) THEN
                 BEGIN
                       select min(org_contact_id), max(org_contact_id)
                       into l_min_id, l_max_id
                       from hz_staged_contacts;
                       WHILE (l_min_id <= l_max_id )
                       LOOP
                           select org_contact_id into tmp
                           from (
                                 select org_contact_id, rownum rnum
                                 from (  SELECT org_contact_id
                                             from hz_staged_contacts
                                             where org_contact_id > l_min_id
                                             and rownum<1001 ) a )
                           where rnum = 1000;
                           update hz_staged_contacts set concat_col = concat_col
                               where org_contact_id between l_min_id and tmp;
                           FND_FILE.put_line(FND_FILE.log, 'Attempting to SYNC the hz_stage_contact_t1 index');
                          AD_CTX_DDL.sync_index(l_index_owner||'.hz_stage_contact_t1');
                          FND_FILE.put_line(FND_FILE.log, 'SYNC of the hz_stage_contact_t1 index successful');
                           FND_Concurrent.af_commit;
                           l_min_id:=tmp+1;
                      END LOOP;
                 EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                          update hz_staged_contacts set concat_col = concat_col
                               where org_contact_id between l_min_id and l_max_id ;
                          FND_FILE.put_line(FND_FILE.log, 'Attempting to SYNC the hz_stage_contact_t1 index');
                          AD_CTX_DDL.sync_index(l_index_owner||'.hz_stage_contact_t1');
                          FND_FILE.put_line(FND_FILE.log, 'SYNC of the hz_stage_contact_t1 index successful');
                          FND_Concurrent.af_commit;
                      WHEN OTHERS THEN
                          FND_FILE.put_line(FND_FILE.log, 'Error during CONTACTS Index Synchronization SQLEERM=' ||SQLERRM);
                          retcode := 2;
                         errbuf := SQLERRM;
                 END;

              END IF;
              UPDATE HZ_TRANS_FUNCTIONS_B
                    SET STAGED_FLAG='Y'
                    WHERE nvl(ACTIVE_FLAG,'Y') = 'Y' and staged_flag='N'
                    and attribute_id in (
                          select attribute_id from hz_trans_attributes_vl where entity_name='CONTACTS');
              create_denorm_attribute_pref ('CONTACTS');
              -- SYNC DENORM CONTACT POINT TEXT INDEX
              ELSIF SYNC_CPT_TEXT_INDEX THEN
                create_btree_indexes ('CONTACT_POINTS');
                IF (new_primary_trans('CONTACT_POINTS')) THEN
                   BEGIN
                         select min(contact_point_id), max(contact_point_id)
                         into l_min_id, l_max_id
                         from hz_staged_contact_points;
                         WHILE (l_min_id <= l_max_id )
                         LOOP
                             select contact_point_id into tmp
                             from (
                                   select contact_point_id, rownum rnum
                                   from (  SELECT contact_point_id
                                               from hz_staged_contact_points
                                               where contact_point_id > l_min_id
                                               and rownum<1001 ) a )
                             where rnum = 1000;
                             update hz_staged_contact_points set concat_col = concat_col
                                 where contact_point_id between l_min_id and tmp;
                             FND_FILE.put_line(FND_FILE.log, 'Attempting to SYNC the hz_stage_cpt_t1 index');
                             AD_CTX_DDL.sync_index(l_index_owner||'.hz_stage_cpt_t1');
                             FND_FILE.put_line(FND_FILE.log, 'SYNC of the hz_stage_cpt_t1 index successful');
                             FND_Concurrent.af_commit;
                             l_min_id:=tmp+1;
                        END LOOP;
                   EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            update hz_staged_contact_points set concat_col = concat_col
                                 where contact_point_id between l_min_id and l_max_id ;
                             FND_FILE.put_line(FND_FILE.log, 'Attempting to SYNC the hz_stage_cpt_t1 index');
                             AD_CTX_DDL.sync_index(l_index_owner||'.hz_stage_cpt_t1');
                             FND_FILE.put_line(FND_FILE.log, 'SYNC of the hz_stage_cpt_t1 index successful');
                            FND_Concurrent.af_commit;
                        WHEN OTHERS THEN
                            FND_FILE.put_line(FND_FILE.log, 'Error during CONTACT POINTS Index Synchronization SQLEERM=' ||SQLERRM);
                            retcode := 2;
                           errbuf := SQLERRM;
                   END;


                END IF;
                UPDATE HZ_TRANS_FUNCTIONS_B
                      SET STAGED_FLAG='Y'
                      WHERE nvl(ACTIVE_FLAG,'Y') = 'Y' and staged_flag='N'
                      and attribute_id in (
                            select attribute_id from hz_trans_attributes_vl where entity_name='CONTACT_POINTS');
                create_denorm_attribute_pref ('CONTACT_POINTS');
            END IF;
    -- CREATE FLOW
    ELSIF index_build_type = 'CREATE'
    THEN

                   log(' Index build type is CREATE for the INDEX Worker');
                   IF CREATE_ALL_BTREE_INDEXES THEN
                          create_btree_indexes ('PARTY');
                          create_btree_indexes ('PARTY_SITES');
                          create_btree_indexes ('CONTACTS');
                          create_btree_indexes ('CONTACT_POINTS');
                          UPDATE HZ_TRANS_FUNCTIONS_B
                                SET STAGED_FLAG='Y'
                               WHERE nvl(ACTIVE_FLAG,'Y') = 'Y' ;
                          create_denorm_attribute_pref ('PARTY_SITES');
                          create_denorm_attribute_pref ('CONTACTS');
                          create_denorm_attribute_pref ('CONTACT_POINTS');
                   END IF ;


                 IF CREATE_PARTY_TEXT_INDEX THEN
                    create_btree_indexes ('PARTY');
                    BEGIN
                      SELECT start_flag, end_flag INTO l_start_flag, l_end_flag
                      FROM HZ_DQM_STAGE_LOG
                      WHERE OPERATION = 'CREATE_INDEXES'
                      AND step = 'HZ_PARTIES';
                    EXCEPTION
                      WHEN no_data_found THEN
                        l_start_flag:=NULL;
                        l_end_flag:=NULL;
                    END;

                    IF nvl(l_end_flag,'N') = 'N' THEN
                      BEGIN
                        execute immediate 'begin ctx_output.start_log(''party_index''); end;';
                      EXCEPTION
                        WHEN OTHERS THEN
                          NULL;
                      END;

                      IF nvl(l_start_flag,'N') = 'Y' THEN
                        BEGIN
                          log('Attempting restart build of index '||l_index_owner || '.hz_stage_parties_t1');
                          EXECUTE IMMEDIATE 'ALTER INDEX ' || l_index_owner ||
                              '.hz_stage_parties_t1 rebuild parameters(''resume memory ' || p_idx_mem || ''')';
                          log('Index Successfully built');

                          UPDATE HZ_DQM_STAGE_LOG set END_FLAG = 'Y', END_TIME=SYSDATE
                          WHERE operation = 'CREATE_INDEXES' AND step ='HZ_PARTIES';
                          COMMIT;

                        EXCEPTION
                          WHEN OTHERS THEN
                            log('Restart Unsuccesful .. Recreating');
                            BEGIN
                              EXECUTE IMMEDIATE 'DROP INDEX ' || l_index_owner || '.hz_stage_parties_t1 FORCE';
                              log('Dropped hz_stage_parties_t1');
                            EXCEPTION
                              WHEN OTHERS THEN
                                NULL;
                            END;
                            l_start_flag := 'N';
                            l_command := 'STAGE_ALL_DATA';

                        END;
                      END IF;

                      IF nvl(l_start_flag,'N') = 'N' THEN
                        UPDATE HZ_DQM_STAGE_LOG set START_FLAG = 'Y', START_TIME=SYSDATE
                        WHERE operation = 'CREATE_INDEXES' AND step ='HZ_PARTIES';
                        COMMIT;

                        l_section_grp := g_schema_name || '.HZ_DQM_PARTY_GRP';

                        IF l_command <> 'STAGE_NEW_TRANSFORMATIONS' THEN
                          log(' Creating hz_stage_parties_t1 on hz_staged_parties.');
                          log(' Index Memory ' || p_idx_mem);
                          log(' Starting at ' || to_char(SYSDATE, 'HH24:MI:SS') );

                          EXECUTE IMMEDIATE 'CREATE INDEX ' || l_index_owner || '.hz_stage_parties_t1 ON ' ||
                              'hz_staged_parties(concat_col) indextype is ctxsys.context ' ||
                              'parameters (''storage  '||g_schema_name || '.HZ_DQM_STORAGE datastore '||g_schema_name || '.hz_party_ds ' ||
                              'SECTION GROUP '||l_section_grp||' STOPLIST CTXSYS.EMPTY_STOPLIST LEXER '||g_schema_name || '.dqm_lexer memory ' || p_idx_mem || ''')';
                        ELSE
                          log(' Attempting to drop and create hz_stage_parties_t1 on hz_staged_parties with new transformations.');
                          log(' Index Memory ' || p_idx_mem);
                          log(' Starting at ' || to_char(SYSDATE, 'HH24:MI:SS') );

                          BEGIN
                              -- DROP AND CREATE
                              EXECUTE IMMEDIATE 'DROP INDEX ' || l_index_owner || '.hz_stage_parties_t1 FORCE';
                              log('Dropped hz_stage_parties_t1');
                              EXCEPTION
                              WHEN OTHERS THEN
                              NULL;

                          END ;
                          EXECUTE IMMEDIATE 'CREATE INDEX ' || l_index_owner || '.hz_stage_parties_t1 ON ' ||
                              'hz_staged_parties(concat_col) indextype is ctxsys.context ' ||
                              'parameters (''storage  '||g_schema_name || '.HZ_DQM_STORAGE datastore '||g_schema_name || '.hz_party_ds ' ||
                              'SECTION GROUP '||l_section_grp||' STOPLIST CTXSYS.EMPTY_STOPLIST LEXER '||g_schema_name || '.dqm_lexer memory ' || p_idx_mem || ''')';
                          log('Done creating hz_stage_parties_t1');
                        END IF;

                        UPDATE HZ_DQM_STAGE_LOG set END_FLAG = 'Y', END_TIME=SYSDATE
                        WHERE operation = 'CREATE_INDEXES' AND step ='HZ_PARTIES';
                        COMMIT;
                      END IF;
                      log(' Completed at ' || to_char(SYSDATE, 'HH24:MI:SS'));

                    END IF;
                  END IF;

                  IF CREATE_PS_TEXT_INDEX THEN
                    create_btree_indexes ('PARTY_SITES');
                    BEGIN
                      SELECT start_flag, end_flag INTO l_start_flag, l_end_flag
                      FROM HZ_DQM_STAGE_LOG
                      WHERE OPERATION = 'CREATE_INDEXES'
                      AND step = 'HZ_PARTY_SITES';
                    EXCEPTION
                      WHEN no_data_found THEN
                        l_start_flag:=NULL;
                        l_end_flag:=NULL;
                    END;

                    IF nvl(l_end_flag,'N') = 'N' THEN
                      BEGIN
                        execute immediate 'begin ctx_output.start_log(''party_site_index''); end;';
                      EXCEPTION
                        WHEN OTHERS THEN
                          NULL;
                      END;

                      IF nvl(l_start_flag,'N') = 'Y' THEN
                        BEGIN
                          log('Attempting restart build of index '||l_index_owner || '.hz_stage_party_sites_t1');
                          EXECUTE IMMEDIATE 'ALTER INDEX ' || l_index_owner ||
                              '.hz_stage_party_sites_t1 rebuild parameters(''resume memory ' || p_idx_mem || ''')';
                          log('Index Successfully built');

                          UPDATE HZ_DQM_STAGE_LOG set END_FLAG = 'Y', END_TIME=SYSDATE
                          WHERE operation = 'CREATE_INDEXES' AND step ='HZ_PARTY_SITES';
                          COMMIT;

                        EXCEPTION
                          WHEN OTHERS THEN
                            log('Restart Unsuccesful .. Recreating');
                            BEGIN
                              EXECUTE IMMEDIATE 'DROP INDEX ' || l_index_owner || '.hz_stage_party_sites_t1 FORCE';
                              log('Dropped hz_stage_party_sites_t1');
                            EXCEPTION
                              WHEN OTHERS THEN
                                NULL;
                            END;
                            l_start_flag := 'N';
                            l_command := 'STAGE_ALL_DATA';

                        END;
                      END IF;

                      IF nvl(l_start_flag,'N') = 'N' THEN
                        UPDATE HZ_DQM_STAGE_LOG set START_FLAG = 'Y', START_TIME=SYSDATE
                        WHERE operation = 'CREATE_INDEXES' AND step ='HZ_PARTY_SITES';
                        COMMIT;

                        l_section_grp := g_schema_name || '.HZ_DQM_PS_GRP';

                        IF l_command <> 'STAGE_NEW_TRANSFORMATIONS' THEN
                          log(' Creating hz_stage_party_sites_t1 on hz_staged_party_sites. ');
                          log(' Index Memory ' || p_idx_mem);
                          log(' Starting at ' || to_char(SYSDATE, 'HH24:MI:SS'));

                          EXECUTE IMMEDIATE 'CREATE INDEX ' || l_index_owner || '.hz_stage_party_sites_t1 ON ' ||
                              'hz_staged_party_sites(concat_col) indextype is ctxsys.context ' ||
                              'parameters (''storage '||g_schema_name || '.HZ_DQM_STORAGE datastore '||g_schema_name || '.hz_party_site_ds ' ||
                              'SECTION GROUP '||l_section_grp||' STOPLIST CTXSYS.EMPTY_STOPLIST LEXER '||g_schema_name || '.dqm_lexer memory ' || p_idx_mem || ''')';
                        ELSE
                          log(' Attempting to drop and create hz_stage_party_sites_t1 on hz_staged_party_sites with new transformations.');
                          log(' Index Memory ' || p_idx_mem);
                          log(' Starting at ' || to_char(SYSDATE, 'HH24:MI:SS') );

                          -- DROP AND CREATE
                          BEGIN
                              EXECUTE IMMEDIATE 'DROP INDEX ' || l_index_owner || '.hz_stage_party_sites_t1 FORCE';
                              log('Dropped hz_stage_party_sites_t1');
                              EXCEPTION
                              WHEN OTHERS THEN
                              NULL;
                          END ;
                          EXECUTE IMMEDIATE 'CREATE INDEX ' || l_index_owner || '.hz_stage_party_sites_t1 ON ' ||
                              'hz_staged_party_sites(concat_col) indextype is ctxsys.context ' ||
                              'parameters (''storage '||g_schema_name || '.HZ_DQM_STORAGE datastore '||g_schema_name || '.hz_party_site_ds ' ||
                              'SECTION GROUP '||l_section_grp||' STOPLIST CTXSYS.EMPTY_STOPLIST LEXER '||g_schema_name || '.dqm_lexer memory ' || p_idx_mem || ''')';
                          log('Done creating hz_stage_party_sites_t1');
                        END IF;

                        UPDATE HZ_DQM_STAGE_LOG set END_FLAG = 'Y', END_TIME=SYSDATE
                        WHERE operation = 'CREATE_INDEXES' AND step ='HZ_PARTY_SITES';
                        COMMIT;
                      END IF;
                      log(' Completed at ' || to_char(SYSDATE, 'HH24:MI:SS'));
                    END IF;
                  END IF;
                  log('');

                  IF CREATE_CONTACT_TEXT_INDEX  THEN
                    create_btree_indexes ('CONTACTS');
                    BEGIN
                      SELECT start_flag, end_flag INTO l_start_flag, l_end_flag
                      FROM HZ_DQM_STAGE_LOG
                      WHERE OPERATION = 'CREATE_INDEXES'
                      AND step = 'HZ_ORG_CONTACTS';
                    EXCEPTION
                      WHEN no_data_found THEN
                        l_start_flag:=NULL;
                        l_end_flag:=NULL;
                    END;

                    IF nvl(l_end_flag,'N') = 'N' THEN
                      BEGIN
                        execute immediate 'begin ctx_output.start_log(''contact_index''); end;';
                      EXCEPTION
                        WHEN OTHERS THEN
                          NULL;
                      END;

                      IF nvl(l_start_flag,'N') = 'Y' THEN
                        BEGIN
                          log('Attempting restart build of index '||l_index_owner || '.hz_stage_contact_t1');
                          EXECUTE IMMEDIATE 'ALTER INDEX ' || l_index_owner ||
                              '.hz_stage_contact_t1 rebuild parameters(''resume memory ' || p_idx_mem || ''')';
                          log('Index Successfully built');

                          UPDATE HZ_DQM_STAGE_LOG set END_FLAG = 'Y', END_TIME=SYSDATE
                          WHERE operation = 'CREATE_INDEXES' AND step ='HZ_ORG_CONTACTS';
                          COMMIT;

                        EXCEPTION
                          WHEN OTHERS THEN
                            log('Restart uncessful. Recreating Index');
                            BEGIN
                              EXECUTE IMMEDIATE 'DROP INDEX ' || l_index_owner || '.hz_stage_contact_t1 FORCE';
                              log('Dropped hz_stage_contact_t1');
                            EXCEPTION
                              WHEN OTHERS THEN
                                NULL;
                            END;
                            l_start_flag := 'N';
                            l_command := 'STAGE_ALL_DATA';

                        END;
                      END IF;

                      IF nvl(l_start_flag,'N') = 'N' THEN
                        UPDATE HZ_DQM_STAGE_LOG set START_FLAG = 'Y', START_TIME=SYSDATE
                        WHERE operation = 'CREATE_INDEXES' AND step ='HZ_ORG_CONTACTS';
                        COMMIT;

                        l_section_grp := g_schema_name || '.HZ_DQM_CONTACT_GRP';

                        IF l_command <> 'STAGE_NEW_TRANSFORMATIONS' THEN
                          log(' Creating hz_stage_contact_t1 on hz_staged_contacts. ');
                          log(' Index Memory ' || p_idx_mem);
                          log(' Starting at ' || to_char(SYSDATE, 'HH24:MI:SS'));

                          EXECUTE IMMEDIATE 'CREATE INDEX ' || l_index_owner || '.hz_stage_contact_t1 ON ' ||
                              'hz_staged_contacts(concat_col) indextype is ctxsys.context ' ||
                              'parameters (''storage '||g_schema_name || '.HZ_DQM_STORAGE datastore '||g_schema_name || '.hz_contact_ds ' ||
                              'SECTION GROUP '||l_section_grp||' STOPLIST CTXSYS.EMPTY_STOPLIST LEXER '||g_schema_name || '.dqm_lexer memory ' || p_idx_mem || ''')';
                        ELSE
                          log(' Attempting to drop and create hz_stage_contact_t1 on hz_staged_contacts with new transformations.');
                          log(' Index Memory ' || p_idx_mem);
                          log(' Starting at ' || to_char(SYSDATE, 'HH24:MI:SS') );

                           BEGIN
                              -- DROP AND CREATE
                              EXECUTE IMMEDIATE 'DROP INDEX ' || l_index_owner || '.hz_stage_contact_t1 FORCE';
                              log('Dropped hz_stage_contact_t1');
                              EXCEPTION
                              WHEN OTHERS THEN
                              NULL;

                          END ;

                          EXECUTE IMMEDIATE 'CREATE INDEX ' || l_index_owner || '.hz_stage_contact_t1 ON ' ||
                              'hz_staged_contacts(concat_col) indextype is ctxsys.context ' ||
                              'parameters (''storage '||g_schema_name || '.HZ_DQM_STORAGE datastore '||g_schema_name || '.hz_contact_ds ' ||
                              'SECTION GROUP '||l_section_grp||' STOPLIST CTXSYS.EMPTY_STOPLIST LEXER '||g_schema_name || '.dqm_lexer memory ' || p_idx_mem || ''')';
                          log('Created hz_stage_contact_t1');

                        END IF;

                        UPDATE HZ_DQM_STAGE_LOG set END_FLAG = 'Y', END_TIME=SYSDATE
                        WHERE operation = 'CREATE_INDEXES' AND step ='HZ_ORG_CONTACTS';
                        COMMIT;
                      END IF;
                      log(' Completed at ' || to_char(SYSDATE, 'HH24:MI:SS'));
                    END IF;
                  END IF;
                  log('');

                  IF CREATE_CPT_TEXT_INDEX THEN
                    create_btree_indexes ('CONTACT_POINTS');
                    BEGIN
                      SELECT start_flag, end_flag INTO l_start_flag, l_end_flag
                      FROM HZ_DQM_STAGE_LOG
                      WHERE OPERATION = 'CREATE_INDEXES'
                      AND step = 'HZ_CONTACT_POINTS';
                    EXCEPTION
                      WHEN no_data_found THEN
                        l_start_flag:=NULL;
                        l_end_flag:=NULL;
                    END;

                    IF nvl(l_end_flag,'N') = 'N' THEN
                      BEGIN
                        execute immediate 'begin ctx_output.start_log(''contact_point_index''); end;';
                      EXCEPTION
                        WHEN OTHERS THEN
                          NULL;
                      END;

                      IF nvl(l_start_flag,'N') = 'Y' THEN
                        BEGIN
                          log('Attempting restart build of index '||l_index_owner || '.hz_stage_cpt_t1');
                          EXECUTE IMMEDIATE 'ALTER INDEX ' || l_index_owner ||
                              '.hz_stage_cpt_t1 rebuild parameters(''resume memory ' || p_idx_mem || ''')';

                          log('Index Successfully built');
                          UPDATE HZ_DQM_STAGE_LOG set END_FLAG = 'Y', END_TIME=SYSDATE
                          WHERE operation = 'CREATE_INDEXES' AND step ='HZ_CONTACT_POINTS';
                          COMMIT;

                        EXCEPTION
                          WHEN OTHERS THEN
                            log('Restart unsuccessful. Rebuilding index.');
                            BEGIN
                              EXECUTE IMMEDIATE 'DROP INDEX ' || l_index_owner || '.hz_stage_cpt_t1 FORCE';
                              log('Dropped hz_stage_cpt_t1');
                            EXCEPTION
                              WHEN OTHERS THEN
                                NULL;
                            END;
                            l_start_flag := 'N';
                            l_command := 'STAGE_ALL_DATA';

                        END;
                      END IF;

                      IF nvl(l_start_flag,'N') = 'N' THEN
                        UPDATE HZ_DQM_STAGE_LOG set START_FLAG = 'Y', START_TIME=SYSDATE
                        WHERE operation = 'CREATE_INDEXES' AND step ='HZ_CONTACT_POINTS';
                        COMMIT;

                        l_section_grp := g_schema_name || '.HZ_DQM_CPT_GRP';

                        IF l_command <> 'STAGE_NEW_TRANSFORMATIONS' THEN
                          log(' Creating hz_stage_cpt_t1 on hz_staged_contact_points. ');
                          log(' Index Memory ' || p_idx_mem);
                          log(' Starting at ' || to_char(SYSDATE, 'HH24:MI:SS'));

                          EXECUTE IMMEDIATE 'CREATE INDEX ' || l_index_owner || '.hz_stage_cpt_t1 ON ' ||
                              'hz_staged_contact_points(concat_col) indextype is ctxsys.context ' ||
                              'parameters (''storage '||g_schema_name || '.HZ_DQM_STORAGE datastore '||g_schema_name || '.hz_contact_point_ds ' ||
                              'SECTION GROUP '||l_section_grp||' STOPLIST CTXSYS.EMPTY_STOPLIST LEXER '||g_schema_name || '.dqm_lexer memory ' || p_idx_mem || ''')';
                        ELSE
                          log(' Attempting to drop and create hz_stage_cpt_t1 on hz_staged_contact_points with new transformations.');
                          log(' Index Memory ' || p_idx_mem);
                          log(' Starting at ' || to_char(SYSDATE, 'HH24:MI:SS') );


                           BEGIN
                              -- DROP AND CREATE
                              EXECUTE IMMEDIATE 'DROP INDEX ' || l_index_owner || '.hz_stage_cpt_t1 FORCE';
                              log('Dropped hz_stage_contact_t1');
                              EXCEPTION
                              WHEN OTHERS THEN
                              NULL;

                           END ;
                          EXECUTE IMMEDIATE 'CREATE INDEX ' || l_index_owner || '.hz_stage_cpt_t1 ON ' ||
                              'hz_staged_contact_points(concat_col) indextype is ctxsys.context ' ||
                              'parameters (''storage '||g_schema_name || '.HZ_DQM_STORAGE datastore '||g_schema_name || '.hz_contact_point_ds ' ||
                              'SECTION GROUP '||l_section_grp||' STOPLIST CTXSYS.EMPTY_STOPLIST LEXER '||g_schema_name || '.dqm_lexer memory ' || p_idx_mem || ''')';

                          log('Done creating hz_stage_contact_t1');
                        END IF;

                        UPDATE HZ_DQM_STAGE_LOG set END_FLAG = 'Y', END_TIME=SYSDATE
                        WHERE operation = 'CREATE_INDEXES' AND step ='HZ_CONTACT_POINTS';
                        COMMIT;
                      END IF;
                      log(' Completed at ' || to_char(SYSDATE, 'HH24:MI:SS'));
                    END IF;
                  END IF;

                   -- FINALLY UPDATE THE STAGED_FLAG IN HZ_TRANS_FUNCTIONS
                   UPDATE HZ_TRANS_FUNCTIONS_B
                   SET STAGED_FLAG='Y' WHERE nvl(ACTIVE_FLAG,'Y') = 'Y';

                   IF CREATE_ALL_TEXT_INDEXES
                   THEN
                         log(' Creating preferences for all the denorm attributes');
                         create_denorm_attribute_pref ('PARTY_SITES');
                         create_denorm_attribute_pref ('CONTACTS');
                         create_denorm_attribute_pref ('CONTACT_POINTS');
                   ELSIF CREATE_PS_TEXT_INDEX
                   THEN
                        log(' Creating preference for the PARTY SITE denorm attribute');
                        create_denorm_attribute_pref ('PARTY_SITES');
                   ELSIF CREATE_CONTACT_TEXT_INDEX
                   THEN
                        log(' Creating preference for the CONTACT denorm attribute');
                        create_denorm_attribute_pref ('CONTACTS');
                   ELSIF CREATE_CPT_TEXT_INDEX
                   THEN
                        log(' Creating preference for the CONTACT POINT denorm attribute');
                        create_denorm_attribute_pref ('CONTACT_POINTS');
                   END IF ;


  END IF;

  log('');
  log('Concurrent Program Execution completed ');
  log('End Time : '|| TO_CHAR(SYSDATE, 'MM-DD-YY HH24:MI:SS'));

EXCEPTION
  WHEN FND_API.G_EXC_ERROR THEN
    outandlog('Error:  ' || FND_MESSAGE.GET);
    log('Error ' || SQLERRM);
    retcode := 2;
    errbuf := errbuf || logerror;
    outandlog('Aborting concurrent program execution');
    FND_FILE.close;
  WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    outandlog('Error:  ' || FND_MESSAGE.GET);
    log('Error ' || SQLERRM);
    retcode := 2;
    errbuf := errbuf || logerror;
    outandlog('Aborting concurrent program execution');
    FND_FILE.close;
  WHEN OTHERS THEN
    outandlog('Error:  ' || FND_MESSAGE.GET);
    log('SQL Error ' || SQLERRM);
    retcode := 2;
    errbuf := errbuf || logerror || SQLERRM;
    outandlog('Aborting concurrent program execution');
    FND_FILE.close;
END;

PROCEDURE generate_map_proc (
   p_entity 		IN	VARCHAR2,
   p_proc_name 		IN	VARCHAR2,
   p_command 		IN	VARCHAR2
) IS
  l_update_str VARCHAR2(4000);
  FIRST BOOLEAN;
BEGIN


  l('FUNCTION ' || p_proc_name || '( ');
  l('      p_record_id NUMBER,');
  IF p_entity = 'PARTY' THEN
    l('      p_search_rec HZ_PARTY_SEARCH.party_search_rec_type');
    l('  ) RETURN HZ_PARTY_STAGE.party_stage_rec_type IS ');
    l('l_stage_rec HZ_PARTY_STAGE.party_stage_rec_type;');
    l('BEGIN');
    l('  l_stage_rec.party_id := p_record_id;');
    l('  l_stage_rec.status := p_search_rec.STATUS;');
  ELSIF p_entity = 'PARTY_SITES' THEN
    l('      p_party_id NUMBER,');
    l('      p_search_rec HZ_PARTY_SEARCH.party_site_search_rec_type');
    l('  ) RETURN HZ_PARTY_STAGE.party_site_stage_rec_type IS ');
    l('l_stage_rec HZ_PARTY_STAGE.party_site_stage_rec_type;');
    l('BEGIN');
    l('  l_stage_rec.party_id := p_party_id;');
    l('  l_stage_rec.party_site_id := p_record_id;');
  ELSIF p_entity = 'CONTACTS' THEN
    l('      p_party_id NUMBER,');
    l('      p_search_rec HZ_PARTY_SEARCH.contact_search_rec_type');
    l('  ) RETURN HZ_PARTY_STAGE.contact_stage_rec_type IS ');
    l('l_stage_rec HZ_PARTY_STAGE.contact_stage_rec_type;');
    l('BEGIN');
    l('  l_stage_rec.party_id := p_party_id;');
    l('  l_stage_rec.org_contact_id := p_record_id;');
  ELSIF p_entity = 'CONTACT_POINTS' THEN
    l('      p_party_id NUMBER,');
    l('      p_search_rec HZ_PARTY_SEARCH.contact_point_search_rec_type');
    l('  ) RETURN HZ_PARTY_STAGE.contact_pt_stage_rec_type IS ');
    l('l_stage_rec HZ_PARTY_STAGE.contact_pt_stage_rec_type;');
    l('BEGIN');
    l('  l_stage_rec.party_id := p_party_id;');
    l('  l_stage_rec.contact_point_id := p_record_id;');
    l('  l_stage_rec.contact_point_type := p_search_rec.CONTACT_POINT_TYPE;');
  END IF;

  IF p_command = 'STAGE_NEW_TRANSFORMATIONS' THEN
    FIRST := TRUE;
    l_update_str := null;

    for ATTRS IN (SELECT ATTRIBUTE_ID, ATTRIBUTE_NAME
                  FROM HZ_TRANS_ATTRIBUTES_VL
                  WHERE ENTITY_NAME = p_entity)

    LOOP
       for FUNCS IN (SELECT PROCEDURE_NAME, STAGED_ATTRIBUTE_COLUMN
                     FROM HZ_TRANS_FUNCTIONS_VL
                     WHERE ATTRIBUTE_ID = ATTRS.ATTRIBUTE_ID
                     AND nvl(ACTIVE_FLAG,'Y') = 'Y'
                     AND NVL(STAGED_FLAG,'N') <> 'Y')
       LOOP
          l('  l_stage_rec.'||FUNCS.STAGED_ATTRIBUTE_COLUMN || ' := ');
          l('        ' || FUNCS.PROCEDURE_NAME ||'(');
          l('             p_search_rec.'||ATTRS.ATTRIBUTE_NAME);
          l('             ,null,''' || ATTRS.ATTRIBUTE_NAME || '''');
          l('             ,''' ||p_entity||''');');
          IF FIRST THEN
            l_update_str := ' '|| FUNCS.STAGED_ATTRIBUTE_COLUMN || ' = ' ||
                            ' l_stage_rec.'||FUNCS.STAGED_ATTRIBUTE_COLUMN || ' ';
            FIRST := FALSE;
          ELSE
            l_update_str := l_update_str || ','|| FUNCS.STAGED_ATTRIBUTE_COLUMN || ' = ' ||
                            ' l_stage_rec.'||FUNCS.STAGED_ATTRIBUTE_COLUMN || ' ';
          END IF;
       END LOOP;
    END LOOP;

    IF l_update_str IS NOT NULL THEN
      IF p_entity = 'PARTY' THEN
        l('  UPDATE HZ_STAGED_PARTIES SET ');
        l('  ' || l_update_str);
        l('  WHERE party_id = p_record_id;');
      ELSIF p_entity = 'PARTY_SITES' THEN
        l('  UPDATE HZ_STAGED_PARTY_SITES SET ');
        l('  ' || l_update_str);
        l('  WHERE party_site_id = p_record_id;');
      ELSIF p_entity = 'CONTACTS' THEN
        l('  UPDATE HZ_STAGED_CONTACTS SET ');
        l('  ' || l_update_str);
        l('  WHERE org_contact_id = p_record_id;');
      ELSIF p_entity = 'CONTACT_POINTS' THEN
        l('  UPDATE HZ_STAGED_CONTACT_POINTS SET ');
        l('  ' || l_update_str);
        l('  WHERE contact_point_id = p_record_id;');
      END IF;
    END IF;

  ELSE

    for ATTRS IN (SELECT ATTRIBUTE_ID, ATTRIBUTE_NAME
                  FROM HZ_TRANS_ATTRIBUTES_VL
                  WHERE ENTITY_NAME = p_entity)
    LOOP
       for FUNCS IN (SELECT PROCEDURE_NAME, STAGED_ATTRIBUTE_COLUMN
                     FROM HZ_TRANS_FUNCTIONS_VL
                     WHERE ATTRIBUTE_ID = ATTRS.ATTRIBUTE_ID
                     AND nvl(ACTIVE_FLAG,'Y') = 'Y')
       LOOP
          l('  l_stage_rec.'||FUNCS.STAGED_ATTRIBUTE_COLUMN || ' := ');
          l('        ' || FUNCS.PROCEDURE_NAME ||'(');
          l('             p_search_rec.'||ATTRS.ATTRIBUTE_NAME);

          -- Temporary fix for bug 2265498
          -- Will be fixed when bug 2269873
          l('             ,null,''' || ATTRS.ATTRIBUTE_NAME || '''');
          l('             ,''' ||p_entity||''');');
       END LOOP;
    END LOOP;
  END IF;

  l('  RETURN l_stage_rec;');
  l('EXCEPTION');
  l('  WHEN OTHERS THEN');
  l('    FND_MESSAGE.SET_NAME(''AR'', ''HZ_MAP_PROC_ERROR'');');
  l('    FND_MESSAGE.SET_TOKEN(''PROC'' ,''' || p_proc_name||''');');
  l('    FND_MESSAGE.SET_TOKEN(''ERROR'' ,SQLERRM);');
  l('    FND_MSG_PUB.ADD;');
  l('    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;');

  l('END;');

EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_STAGE_SQL_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'generate_transform_proc');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_ERROR;
END;

PROCEDURE generate_declarations IS

BEGIN
  l('  TYPE NumberList IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;');
  l('  TYPE Char1List IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;');
  l('  TYPE Char2List IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;');
  l('  TYPE CharList IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;');
  l('  ');
  l('  H_P_PARTY_ID NumberList;');
  l('  H_PS_DEN CharList;');
  l('  H_CT_DEN CharList;');
  l('  H_CPT_DEN CharList;');
  l('  H_PARTY_INDEX NumberList;');
  l('  H_PARTY_ID NumberList;');
  l('  H_C_PARTY_ID NumberList;');
  l('  H_PS_PARTY_ID NumberList;');
  l('  H_CPT_PARTY_ID NumberList;');
  l('  H_R_PARTY_ID NumberList;');
  l('  H_STATUS Char1List;');
  l('  H_PARTY_SITE_ID NumberList;');
  l('  H_CPT_PARTY_SITE_ID NumberList;');
  l('  H_ORG_CONTACT_ID NumberList;');
  l('  H_PS_ORG_CONTACT_ID NumberList;');
  l('  H_CPT_ORG_CONTACT_ID NumberList;');
  l('  H_CONTACT_POINT_ID NumberList;');
  l('  H_CONTACT_POINT_TYPE Char2List;');
  l('  H_TX1 CharList;');
  l('  H_TX2 CharList;');
  l('  H_TX3 CharList;');
  l('  H_TX4 CharList;');
  l('  H_TX5 CharList;');
  l('  H_TX6 CharList;');
  l('  H_TX7 CharList;');
  l('  H_TX8 CharList;');
  l('  H_TX9 CharList;');
  l('  H_TX10 CharList;');
  l('  H_TX11 CharList;');
  l('  H_TX12 CharList;');
  l('  H_TX13 CharList;');
  l('  H_TX14 CharList;');
  l('  H_TX15 CharList;');
  l('  H_TX16 CharList;');
  l('  H_TX17 CharList;');
  l('  H_TX18 CharList;');
  l('  H_TX19 CharList;');
  l('  H_TX20 CharList;');
  l('  H_TX21 CharList;');
  l('  H_TX22 CharList;');
  l('  H_TX23 CharList;');
  l('  H_TX24 CharList;');
  l('  H_TX25 CharList;');
  l('  H_TX26 CharList;');
  l('  H_TX27 CharList;');
  l('  H_TX28 CharList;');
  l('  H_TX29 CharList;');
  l('  H_TX30 CharList;');
  l('  H_TX31 CharList;');
  l('  H_TX32 CharList;');
  l('  H_TX33 CharList;');
  l('  H_TX34 CharList;');
  l('  H_TX35 CharList;');
  l('  H_TX36 CharList;');
  l('  H_TX37 CharList;');
  l('  H_TX38 CharList;');
  l('  H_TX39 CharList;');
  l('  H_TX40 CharList;');
  l('  H_TX41 CharList;');
  l('  H_TX42 CharList;');
  l('  H_TX43 CharList;');
  l('  H_TX44 CharList;');
  l('  H_TX45 CharList;');
  l('  H_TX46 CharList;');
  l('  H_TX47 CharList;');
  l('  H_TX48 CharList;');
  l('  H_TX49 CharList;');
  l('  H_TX50 CharList;');
  l('  H_TX51 CharList;');
  l('  H_TX52 CharList;');
  l('  H_TX53 CharList;');
  l('  H_TX54 CharList;');
  l('  H_TX55 CharList;');
  l('  H_TX56 CharList;');
  l('  H_TX57 CharList;');
  l('  H_TX58 CharList;');
  l('  H_TX59 CharList;');
  l('  H_TX60 CharList;');
  l('  H_TX61 CharList;');
  l('  H_TX62 CharList;');
  l('  H_TX63 CharList;');
  l('  H_TX64 CharList;');
  l('  H_TX65 CharList;');
  l('  H_TX66 CharList;');
  l('  H_TX67 CharList;');
  l('  H_TX68 CharList;');
  l('  H_TX69 CharList;');
  l('  H_TX70 CharList;');
  l('  H_TX71 CharList;');
  l('  H_TX72 CharList;');
  l('  H_TX73 CharList;');
  l('  H_TX74 CharList;');
  l('  H_TX75 CharList;');
  l('  H_TX76 CharList;');
  l('  H_TX77 CharList;');
  l('  H_TX78 CharList;');
  l('  H_TX79 CharList;');
  l('  H_TX80 CharList;');
  l('  H_TX81 CharList;');
  l('  H_TX82 CharList;');
  l('  H_TX83 CharList;');
  l('  H_TX84 CharList;');
  l('  H_TX85 CharList;');
  l('  H_TX86 CharList;');
  l('  H_TX87 CharList;');
  l('  H_TX88 CharList;');
  l('  H_TX89 CharList;');
  l('  H_TX90 CharList;');
  l('  H_TX91 CharList;');
  l('  H_TX92 CharList;');
  l('  H_TX93 CharList;');
  l('  H_TX94 CharList;');
  l('  H_TX95 CharList;');
  l('  H_TX96 CharList;');
  l('  H_TX97 CharList;');
  l('  H_TX98 CharList;');
  l('  H_TX99 CharList;');
  l('  H_TX100 CharList;');
  l('  H_TX101 CharList;');
  l('  H_TX102 CharList;');
  l('  H_TX103 CharList;');
  l('  H_TX104 CharList;');
  l('  H_TX105 CharList;');
  l('  H_TX106 CharList;');
  l('  H_TX107 CharList;');
  l('  H_TX108 CharList;');
  l('  H_TX109 CharList;');
  l('  H_TX110 CharList;');
  l('  H_TX111 CharList;');
  l('  H_TX112 CharList;');
  l('  H_TX113 CharList;');
  l('  H_TX114 CharList;');
  l('  H_TX115 CharList;');
  l('  H_TX116 CharList;');
  l('  H_TX117 CharList;');
  l('  H_TX118 CharList;');
  l('  H_TX119 CharList;');
  l('  H_TX120 CharList;');
  l('  H_TX121 CharList;');
  l('  H_TX122 CharList;');
  l('  H_TX123 CharList;');
  l('  H_TX124 CharList;');
  l('  H_TX125 CharList;');
  l('  H_TX126 CharList;');
  l('  H_TX127 CharList;');
  l('  H_TX128 CharList;');
  l('  H_TX129 CharList;');
  l('  H_TX130 CharList;');
  l('  H_TX131 CharList;');
  l('  H_TX132 CharList;');
  l('  H_TX133 CharList;');
  l('  H_TX134 CharList;');
  l('  H_TX135 CharList;');
  l('  H_TX136 CharList;');
  l('  H_TX137 CharList;');
  l('  H_TX138 CharList;');
  l('  H_TX139 CharList;');
  l('  H_TX140 CharList;');
  l('  H_TX141 CharList;');
  l('  H_TX142 CharList;');
  l('  H_TX143 CharList;');
  l('  H_TX144 CharList;');
  l('  H_TX145 CharList;');
  l('  H_TX146 CharList;');
  l('  H_TX147 CharList;');
  l('  H_TX148 CharList;');
  l('  H_TX149 CharList;');
  l('  H_TX150 CharList;');
  l('  H_TX151 CharList;');
  l('  H_TX152 CharList;');
  l('  H_TX153 CharList;');
  l('  H_TX154 CharList;');
  l('  H_TX155 CharList;');
  l('  H_TX156 CharList;');
  l('  H_TX157 CharList;');
  l('  H_TX158 CharList;');
  l('  H_TX159 CharList;');
  l('  H_TX160 CharList;');
  l('  H_TX161 CharList;');
  l('  H_TX162 CharList;');
  l('  H_TX163 CharList;');
  l('  H_TX164 CharList;');
  l('  H_TX165 CharList;');
  l('  H_TX166 CharList;');
  l('  H_TX167 CharList;');
  l('  H_TX168 CharList;');
  l('  H_TX169 CharList;');
  l('  H_TX170 CharList;');
  l('  H_TX171 CharList;');
  l('  H_TX172 CharList;');
  l('  H_TX173 CharList;');
  l('  H_TX174 CharList;');
  l('  H_TX175 CharList;');
  l('  H_TX176 CharList;');
  l('  H_TX177 CharList;');
  l('  H_TX178 CharList;');
  l('  H_TX179 CharList;');
  l('  H_TX180 CharList;');
  l('  H_TX181 CharList;');
  l('  H_TX182 CharList;');
  l('  H_TX183 CharList;');
  l('  H_TX184 CharList;');
  l('  H_TX185 CharList;');
  l('  H_TX186 CharList;');
  l('  H_TX187 CharList;');
  l('  H_TX188 CharList;');
  l('  H_TX189 CharList;');
  l('  H_TX190 CharList;');
  l('  H_TX191 CharList;');
  l('  H_TX192 CharList;');
  l('  H_TX193 CharList;');
  l('  H_TX194 CharList;');
  l('  H_TX195 CharList;');
  l('  H_TX196 CharList;');
  l('  H_TX197 CharList;');
  l('  H_TX198 CharList;');
  l('  H_TX199 CharList;');
  l('  H_TX200 CharList;');
  l('  H_TX201 CharList;');
  l('  H_TX202 CharList;');
  l('  H_TX203 CharList;');
  l('  H_TX204 CharList;');
  l('  H_TX205 CharList;');
  l('  H_TX206 CharList;');
  l('  H_TX207 CharList;');
  l('  H_TX208 CharList;');
  l('  H_TX209 CharList;');
  l('  H_TX210 CharList;');
  l('  H_TX211 CharList;');
  l('  H_TX212 CharList;');
  l('  H_TX213 CharList;');
  l('  H_TX214 CharList;');
  l('  H_TX215 CharList;');
  l('  H_TX216 CharList;');
  l('  H_TX217 CharList;');
  l('  H_TX218 CharList;');
  l('  H_TX219 CharList;');
  l('  H_TX220 CharList;');
  l('  H_TX221 CharList;');
  l('  H_TX222 CharList;');
  l('  H_TX223 CharList;');
  l('  H_TX224 CharList;');
  l('  H_TX225 CharList;');
  l('  H_TX226 CharList;');
  l('  H_TX227 CharList;');
  l('  H_TX228 CharList;');
  l('  H_TX229 CharList;');
  l('  H_TX230 CharList;');
  l('  H_TX231 CharList;');
  l('  H_TX232 CharList;');
  l('  H_TX233 CharList;');
  l('  H_TX234 CharList;');
  l('  H_TX235 CharList;');
  l('  H_TX236 CharList;');
  l('  H_TX237 CharList;');
  l('  H_TX238 CharList;');
  l('  H_TX239 CharList;');
  l('  H_TX240 CharList;');
  l('  H_TX241 CharList;');
  l('  H_TX242 CharList;');
  l('  H_TX243 CharList;');
  l('  H_TX244 CharList;');
  l('  H_TX245 CharList;');
  l('  H_TX246 CharList;');
  l('  H_TX247 CharList;');
  l('  H_TX248 CharList;');
  l('  H_TX249 CharList;');
  l('  H_TX250 CharList;');
  l('  H_TX251 CharList;');
  l('  H_TX252 CharList;');
  l('  H_TX253 CharList;');
  l('  H_TX254 CharList;');
  l('  H_TX255 CharList;');
END;

PROCEDURE generate_ds_proc IS

FIRST BOOLEAN := TRUE;
uname VARCHAR2(255);

pref_cols VARCHAR2(1000);
proc_cols VARCHAR2(2000);
fetch_cols VARCHAR2(2000);
CURSOR l_ent_cur(l_ent_name VARCHAR2) IS (SELECT STAGED_ATTRIBUTE_COLUMN
                FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
                WHERE ENTITY_NAME = l_ent_name
                AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                AND nvl(f.PRIMARY_FLAG,'Y') = 'Y'
                AND nvl(a.DENORM_FLAG,'N') = 'Y'
                AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID);
l_attr VARCHAR2(255);

BEGIN

  SELECT SYS_CONTEXT ('USERENV', 'SESSION_USER') INTO uname
  FROM DUAL;

  get_datastore_cols('PARTY', pref_cols, proc_cols, fetch_cols);

  l('  FUNCTION miscp (rid IN ROWID) RETURN CLOB IS');
  IF proc_cols IS NULL THEN
    l('  BEGIN');
    l('    RETURN NULL;');
    l('  END;');
  ELSE
    l('  CURSOR P IS');
    l('       SELECT '||proc_cols||' FROM '||uname||'.HZ_STAGED_PARTIES WHERE ROWID=rid;');
    l('  val CLOB;');
    l('  BEGIN');
    l('      val:=null;');
    l('      FOR rec in P LOOP');
    l('           val:='||fetch_cols||';');
    l('      END LOOP;');
    l('      return val;');
    l('  END;');
  END IF;


  get_datastore_cols('PARTY_SITES', pref_cols, proc_cols, fetch_cols);
  l('  FUNCTION miscps (rid IN ROWID) RETURN CLOB IS');
  IF proc_cols IS NULL THEN
    l('  BEGIN');
    l('    RETURN NULL;');
    l('  END;');
  ELSE
    l('  CURSOR P IS');
    l('       SELECT '||proc_cols||' FROM '||uname||'.HZ_STAGED_PARTY_SITES WHERE ROWID=rid;');
    l('  val CLOB ;');
    l('  BEGIN');
    l('      val:=null;');
    l('      FOR rec in P LOOP');
    l('           val:='||fetch_cols||';');
    l('      END LOOP;');
    l('      return val;');
    l('  END;');
  END IF;

  get_datastore_cols('CONTACTS', pref_cols, proc_cols, fetch_cols);
  l('  FUNCTION miscct (rid IN ROWID) RETURN CLOB IS');
  IF proc_cols IS NULL THEN
    l('  BEGIN');
    l('    RETURN NULL;');
    l('  END;');
  ELSE
    l('  CURSOR P IS');
    l('       SELECT '||proc_cols||' FROM '||uname||'.HZ_STAGED_CONTACTS WHERE ROWID=rid;');
    l('  val CLOB;');
    l('  BEGIN');
    l('      val:=null;');
    l('      FOR rec in P LOOP');
    l('          val:='||fetch_cols||';');
    l('      END LOOP;');
    l('      return val;');
    l('  END;');

  END IF;

  get_datastore_cols('CONTACT_POINTS', pref_cols, proc_cols, fetch_cols);
  l('  FUNCTION misccpt (rid IN ROWID) RETURN CLOB IS');
  IF proc_cols IS NULL THEN
    l('  BEGIN');
    l('    RETURN NULL;');
    l('  END;');
  ELSE
    l('  CURSOR P IS');
    l('       SELECT '||proc_cols||' FROM '||uname||'.HZ_STAGED_CONTACT_POINTS WHERE ROWID=rid;');
    l('  val CLOB;');
    l('  BEGIN');
    l('      val:=null;');
    l('      FOR rec in P LOOP');
    l('           val:='||fetch_cols||';');
    l('      END LOOP;');
    l('      return val;');
    l('  END;');
  END IF;

  l('  FUNCTION den_ps (party_id NUMBER) RETURN VARCHAR2 IS');
  l('   CURSOR party_site_denorm (cp_party_id NUMBER) IS');
  l('    SELECT distinct');
  OPEN l_ent_cur('PARTY_SITES');
  LOOP
      FETCH l_ent_cur INTO l_attr;
      EXIT WHEN l_ent_cur%NOTFOUND;
      l('      '||l_attr ||'||'' ''||');
  END LOOP;
  CLOSE l_ent_cur;
  l('        '' ''');
  l('    FROM '||uname||'.HZ_STAGED_PARTY_SITES');
  l('    WHERE party_id = cp_party_id;');
  l('    l_buffer VARCHAR2(4000);');
  l('    l_den_ps VARCHAR2(2000);');
  l('  BEGIN');
  l('     OPEN party_site_denorm(party_id);');
  l('     LOOP');
  l('       FETCH party_site_denorm INTO l_den_ps;');
  l('       EXIT WHEN party_site_denorm%NOTFOUND;');
  l('       l_buffer := l_buffer||'' ''||l_den_ps;');
  l('     END LOOP;');
  l('     CLOSE party_site_denorm;');
  l('     RETURN l_buffer;');
  l('  EXCEPTION');
  l('    WHEN OTHERS THEN');
  l('      RETURN l_buffer;');

  l('  END;');


  l('  FUNCTION den_ct (party_id NUMBER) RETURN VARCHAR2 IS');
  l('   CURSOR contact_denorm (cp_party_id NUMBER) IS');
  l('    SELECT distinct');
  OPEN l_ent_cur('CONTACTS');
  LOOP
      FETCH l_ent_cur INTO l_attr;
      EXIT WHEN l_ent_cur%NOTFOUND;
      l('      '||l_attr ||'||'' ''||');
  END LOOP;
  CLOSE l_ent_cur;
  l('        '' ''');
  l('    FROM '||uname||'.HZ_STAGED_CONTACTS');
  l('    WHERE party_id = cp_party_id;');
  l('    l_buffer VARCHAR2(4000);');
  l('    l_den_ct VARCHAR2(2000);');
  l('  BEGIN');
  l('     OPEN contact_denorm(party_id);');
  l('     LOOP');
  l('       FETCH contact_denorm INTO l_den_ct;');
  l('       EXIT WHEN contact_denorm%NOTFOUND;');
  l('       l_buffer := l_buffer||'' ''||l_den_ct;');
  l('     END LOOP;');
  l('     CLOSE contact_denorm;');
  l('     RETURN l_buffer;');
  l('  EXCEPTION');
  l('    WHEN OTHERS THEN');
  l('      RETURN l_buffer;');
  l('  END;');

  l('  FUNCTION den_cpt (party_id NUMBER) RETURN VARCHAR2 IS');
  l('   CURSOR contact_pt_denorm (cp_party_id NUMBER) IS');
  l('    SELECT distinct');
  OPEN l_ent_cur('CONTACT_POINTS');
  LOOP
      FETCH l_ent_cur INTO l_attr;
      EXIT WHEN l_ent_cur%NOTFOUND;
      l('      '||l_attr ||'||'' ''||');
  END LOOP;
  CLOSE l_ent_cur;
  l('        '' ''');
  l('    FROM '||uname||'.HZ_STAGED_CONTACT_POINTS');
  l('    WHERE party_id = cp_party_id;');
  l('    l_buffer VARCHAR2(4000);');
  l('    l_den_cpt VARCHAR2(2000);');
  l('  BEGIN');
  l('     OPEN contact_pt_denorm(party_id);');
  l('     LOOP');
  l('       FETCH contact_pt_denorm INTO l_den_cpt;');
  l('       EXIT WHEN contact_pt_denorm%NOTFOUND;');
  l('       l_buffer := l_buffer||'' ''||l_den_cpt;');
  l('     END LOOP;');
  l('     CLOSE contact_pt_denorm;');
  l('     RETURN l_buffer;');
  l('  EXCEPTION');
  l('    WHEN OTHERS THEN');
  l('      RETURN l_buffer;');
  l('  END;');

END;

PROCEDURE generate_party_query_proc IS
 cur_col_num NUMBER := 1;

 TYPE coltab IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;

 l_org_select coltab;
 l_per_select coltab;
 l_oth_select coltab;

 l_forall_list coltab;
 l_custom_list coltab;
 l_mincol_list coltab;
 l_min_colnum NUMBER;
 idx NUMBER :=1;
 is_first boolean := true;

 -- VJN Introduced for conditional word replacements
 l_cond_attrib_list coltab ;
 l_idx number ;

BEGIN
  l('  PROCEDURE open_party_cursor( ');
  l('    p_select_type	IN	VARCHAR2,');
  l('    p_party_type	IN	VARCHAR2,');
  l('    p_worker_number IN	NUMBER,');
  l('    p_num_workers	IN	NUMBER,');
  l('    p_party_id	IN	NUMBER,');
  l('    p_continue	IN	VARCHAR2,');
  l('    x_party_cur	IN OUT	HZ_PARTY_STAGE.StageCurTyp) IS ');
  l('');
  l('    l_party_type VARCHAR2(255);');
  l('  BEGIN');

  FOR ATTRS IN (SELECT a.ATTRIBUTE_ID,
                       a.ATTRIBUTE_NAME,
                       a.SOURCE_TABLE,
                       a.CUSTOM_ATTRIBUTE_PROCEDURE,
                       f.PROCEDURE_NAME,
                       f.STAGED_ATTRIBUTE_COLUMN,
                       to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3)) COLNUM
                FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
                WHERE ENTITY_NAME = 'PARTY'
                AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
                ORDER BY COLNUM) LOOP

    IF cur_col_num<ATTRS.COLNUM THEN
      FOR I in cur_col_num..ATTRS.COLNUM-1 LOOP
        l_mincol_list(I) := 'N';
        l_forall_list(I) := 'N';
        l_custom_list(I) := 'N';
      END LOOP;
    END IF;
    cur_col_num:=ATTRS.COLNUM+1;
    IF has_trx_context(ATTRS.PROCEDURE_NAME) THEN
      l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||ATTRS.COLNUM||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''PARTY'',''STAGE'')';
    ELSE
      l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||ATTRS.COLNUM||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''PARTY'')';
    END IF;
    l_mincol_list(ATTRS.COLNUM) := 'N';

    SELECT min(to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3))) INTO l_min_colnum
    FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
    WHERE ENTITY_NAME = 'PARTY'
    AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
    AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
    AND a.ATTRIBUTE_NAME=ATTRS.ATTRIBUTE_NAME;

    IF ATTRS.colnum>l_min_colnum THEN
      l_mincol_list(ATTRS.COLNUM) := 'N';
    IF has_trx_context(ATTRS.PROCEDURE_NAME) THEN
      l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||l_min_colnum||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''PARTY'',''STAGE'')';
    ELSE
      l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||l_min_colnum||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''PARTY'')';
    END IF;
    ELSE
      l_mincol_list(ATTRS.COLNUM) := 'Y';
    END IF;

    IF ATTRS.CUSTOM_ATTRIBUTE_PROCEDURE IS NULL THEN
      IF l_mincol_list(ATTRS.COLNUM) = 'Y' THEN
        IF ATTRS.SOURCE_TABLE='HZ_ORGANIZATION_PROFILES' THEN
          l_org_select(idx) := 'op.'||ATTRS.ATTRIBUTE_NAME;
          l_per_select(idx) := 'NULL';
          l_oth_select(idx) := 'NULL';
        ELSIF ATTRS.SOURCE_TABLE='HZ_PERSON_PROFILES' THEN
          l_per_select(idx) := 'pe.'||ATTRS.ATTRIBUTE_NAME;
          l_org_select(idx) := 'NULL';
          l_oth_select(idx) := 'NULL';
        ELSIF ATTRS.SOURCE_TABLE='HZ_PERSON_PROFILES, HZ_ORGANIZATION_PROFILES' OR
              ATTRS.SOURCE_TABLE='HZ_ORGANIZATION_PROFILES, HZ_PERSON_PROFILES' THEN
          l_org_select(idx) := 'op.'||ATTRS.ATTRIBUTE_NAME;
          l_per_select(idx) := 'pe.'||ATTRS.ATTRIBUTE_NAME;
          l_oth_select(idx) := 'NULL';
        ELSE
          l_org_select(idx) := 'p.'||ATTRS.ATTRIBUTE_NAME;
          l_per_select(idx) := 'p.'||ATTRS.ATTRIBUTE_NAME;
          l_oth_select(idx) := 'p.'||ATTRS.ATTRIBUTE_NAME;
        END IF;
      ELSE
        l_org_select(idx):='N';
        l_per_select(idx):='N';
        l_oth_select(idx):='N';
      END IF;

      l_custom_list(ATTRS.COLNUM) := 'N';
    ELSE
        l_org_select(idx):='N';
        l_per_select(idx):='N';
        l_oth_select(idx):='N';
        l_custom_list(ATTRS.COLNUM) := 'N';
        IF ATTRS.ATTRIBUTE_NAME = 'PARTY_ALL_NAMES' THEN
          IF l_mincol_list(ATTRS.COLNUM) = 'Y' THEN
            l_org_select(idx) := 'p.PARTY_NAME || '' '' || p.KNOWN_AS || '' '' || p.KNOWN_AS2 || '' '' || p.KNOWN_AS3 || '' ''|| p.KNOWN_AS4 || '' ''|| p.KNOWN_AS5';
            l_per_select(idx) := 'p.PARTY_NAME || '' '' || p.KNOWN_AS || '' '' || p.KNOWN_AS2 || '' '' || p.KNOWN_AS3 || '' ''|| p.KNOWN_AS4 || '' ''|| p.KNOWN_AS5';
            l_oth_select(idx) := 'p.PARTY_NAME || '' '' || p.KNOWN_AS || '' '' || p.KNOWN_AS2 || '' '' || p.KNOWN_AS3 || '' ''|| p.KNOWN_AS4 || '' ''|| p.KNOWN_AS5';
          END IF;
        ELSE
          IF l_mincol_list(ATTRS.COLNUM) = 'Y' THEN
            IF has_context(ATTRS.custom_attribute_procedure) THEN
              l_custom_list(ATTRS.COLNUM) := ATTRS.custom_attribute_procedure || '(H_P_PARTY_ID(I),''PARTY'','''||ATTRS.ATTRIBUTE_NAME|| ''', ''STAGE'')';
            ELSE
              l_custom_list(ATTRS.COLNUM) := ATTRS.custom_attribute_procedure || '(H_P_PARTY_ID(I),''PARTY'','''||ATTRS.ATTRIBUTE_NAME|| ''')';
            END IF;
          END IF;
        END IF;
    END IF;
    idx := idx+1;

    -- VJN ADDED CODE FOR TRACKING CONDITION ATTRIBUTES AT THIS ENTITY LEVEL
    IF HZ_WORD_CONDITIONS_PKG.is_a_cond_attrib( ATTRS.attribute_id)
     THEN
         l_cond_attrib_list(ATTRS.COLNUM) := ATTRS.attribute_id ;
    END IF;


  END LOOP;

  IF cur_col_num<255 THEN
    FOR I in cur_col_num..255 LOOP
      l_mincol_list(I) := 'N';
      l_forall_list(I) := 'N';
      l_custom_list(I) := 'N';
    END LOOP;
  END IF;

  l('    IF p_select_type = ''SINGLE_PARTY'' THEN');
  l('      NULL;');
  l('    ELSIF p_select_type = ''ALL_PARTIES'' THEN');
  l('      IF p_continue IS NULL OR p_continue<>''Y'' THEN');
  l('        IF p_party_type = ''ORGANIZATION'' THEN');
  l('          open x_party_cur FOR ' );
  l('            SELECT p.PARTY_ID, p.STATUS ');
  FOR I in 1..l_org_select.COUNT LOOP
    IF l_org_select(I) <> 'N' THEN
      l('                  ,' || l_org_select(I));
    END IF;
  END LOOP;

  l('            FROM HZ_PARTIES p, HZ_ORGANIZATION_PROFILES op ');
  l('            WHERE mod(p.PARTY_ID, p_num_workers) = p_worker_number ');
  l('            AND p.party_id = op.party_id ');
  l('            AND op.effective_end_date is NULL ');
  l('            AND p.PARTY_TYPE =''ORGANIZATION''; ');
  l('        ELSIF p_party_type = ''PERSON'' THEN');
  l('          open x_party_cur FOR ' );
  l('            SELECT p.PARTY_ID, p.STATUS ');
  FOR I in 1..l_per_select.COUNT LOOP
    IF l_per_select(I) <> 'N' THEN
      l('                  ,' || l_per_select(I));
    END IF;
  END LOOP;
  l('            FROM HZ_PARTIES p, HZ_PERSON_PROFILES pe ');
  l('            WHERE mod(p.PARTY_ID, p_num_workers) = p_worker_number ');
  l('            AND p.party_id = pe.party_id ');
  l('            AND pe.effective_end_date is NULL ');
  l('            AND p.PARTY_TYPE =''PERSON''; ');
  l('        ELSE');
  l('          open x_party_cur FOR ' );
  l('            SELECT p.PARTY_ID, p.STATUS ');
  FOR I in 1..l_oth_select.COUNT LOOP
    IF l_oth_select(I) <> 'N' THEN
      l('                  ,' || l_oth_select(I));
    END IF;
  END LOOP;
  l('            FROM HZ_PARTIES p ');
  l('            WHERE mod(p.PARTY_ID, p_num_workers) = p_worker_number ');
  l('            AND p.party_type <> ''PERSON'' ');
  l('            AND p.party_type <> ''ORGANIZATION'' ');
  l('            AND p.party_type <> ''PARTY_RELATIONSHIP''; ');
  l('        END IF;');
  l('      ELSE');
  l('        IF p_party_type = ''ORGANIZATION'' THEN');
  l('          open x_party_cur FOR ' );
  l('            SELECT p.PARTY_ID, p.STATUS ');
  FOR I in 1..l_org_select.COUNT LOOP
    IF l_org_select(I) <> 'N' THEN
      l('                  ,' || l_org_select(I));
    END IF;
  END LOOP;

  l('            FROM HZ_PARTIES p, HZ_ORGANIZATION_PROFILES op ');
  l('            WHERE mod(p.PARTY_ID, p_num_workers) = p_worker_number ');
  l('            AND NOT EXISTS (select 1 FROM HZ_STAGED_PARTIES sp  ');
  l('                            WHERE sp.party_id = p.party_id)   ' );
  l('            AND p.party_id = op.party_id ');
  l('            AND op.effective_end_date is NULL ');
  l('            AND p.PARTY_TYPE =''ORGANIZATION''; ');
  l('        ELSIF p_party_type = ''PERSON'' THEN');
  l('          open x_party_cur FOR ' );
  l('            SELECT p.PARTY_ID, p.STATUS ');
  FOR I in 1..l_per_select.COUNT LOOP
    IF l_per_select(I) <> 'N' THEN
      l('                  ,' || l_per_select(I));
    END IF;
  END LOOP;
  l('            FROM HZ_PARTIES p, HZ_PERSON_PROFILES pe ');
  l('            WHERE mod(p.PARTY_ID, p_num_workers) = p_worker_number ');
  l('            AND NOT EXISTS (select 1 FROM HZ_STAGED_PARTIES sp  ');
  l('                            WHERE sp.party_id = p.party_id)   ' );
  l('            AND p.party_id = pe.party_id ');
  l('            AND pe.effective_end_date is NULL ');
  l('            AND p.PARTY_TYPE =''PERSON''; ');
  l('        ELSE');
  l('          open x_party_cur FOR ' );
  l('            SELECT p.PARTY_ID, p.STATUS ');
  FOR I in 1..l_oth_select.COUNT LOOP
    IF l_oth_select(I) <> 'N' THEN
      l('                  ,' || l_oth_select(I));
    END IF;
  END LOOP;
  l('            FROM HZ_PARTIES p ');
  l('            WHERE mod(p.PARTY_ID, p_num_workers) = p_worker_number ');
  l('            AND NOT EXISTS (select 1 FROM HZ_STAGED_PARTIES sp  ');
  l('                            WHERE sp.party_id = p.party_id)   ' );
  l('            AND p.party_type <> ''PERSON'' ');
  l('            AND p.party_type <> ''ORGANIZATION'' ');
  l('            AND p.party_type <> ''PARTY_RELATIONSHIP''; ');
  l('        END IF;');
  l('      END IF;');
  l('    END IF;');
  l('  END;');

  l('  PROCEDURE insert_stage_parties ( ');
  l('    p_continue     IN VARCHAR2, ');
  l('    p_party_cur    IN HZ_PARTY_STAGE.StageCurTyp) IS ');
  l(' l_limit NUMBER := ' || g_batch_size || ';');
  l(' l_contact_cur HZ_PARTY_STAGE.StageCurTyp;');
  l(' l_cpt_cur HZ_PARTY_STAGE.StageCurTyp;');
  l(' l_party_site_cur HZ_PARTY_STAGE.StageCurTyp;');
  l(' l_last_fetch BOOLEAN := FALSE;');
  l(' call_status BOOLEAN;');
  l(' rphase varchar2(255);');
  l(' rstatus varchar2(255);');
  l(' dphase varchar2(255);');
  l(' dstatus varchar2(255);');
  l(' message varchar2(255);');
  l(' req_id NUMBER;');
  l(' l_st number; ');
  l(' l_en number; ');
  l(' USER_TERMINATE EXCEPTION;');
  l('');
  l('  BEGIN');
  l('    req_id := FND_GLOBAL.CONC_REQUEST_ID;');
  l('    LOOP');
  l('      call_status := FND_CONCURRENT.GET_REQUEST_STATUS(');
  l('                req_id, null,null,rphase,rstatus,dphase,dstatus,message);');
  l('      IF dstatus = ''TERMINATING'' THEN');
  l('        FND_FILE.put_line(FND_FILE.log,''Aborted by User'');');
  l('        RAISE USER_TERMINATE;');
  l('      END IF;');
  l('      FETCH p_party_cur BULK COLLECT INTO');
  l('        H_P_PARTY_ID');
  l('        , H_STATUS');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' AND l_mincol_list(I) = 'Y' AND
       l_custom_list(I) = 'N' THEN
      l('         ,H_TX'||I);
    END IF;
  END LOOP;
  l('      LIMIT l_limit;');
  l('');
  l('    IF p_party_cur%NOTFOUND THEN');
  l('      l_last_fetch:=TRUE;');
  l('    END IF;');

  l('    IF H_P_PARTY_ID.COUNT=0 AND l_last_fetch THEN');
  l('      EXIT;');
  l('    END IF;');

  l('    FOR I in H_P_PARTY_ID.FIRST..H_P_PARTY_ID.LAST LOOP');

 -- VJN INTRODUCED FOR CONDITIONAL REPLACEMENTS
  -- CYCLE THROUGH THE CONDITON LIST AND GENERATE THE CODE
  -- FOR POPULATING THE GLOBAL CONDITION RECORD

  l_idx := l_cond_attrib_list.FIRST ;
  IF l_idx IS NOT NULL
  THEN
    l('----------- SETTING GLOBAL CONDITION RECORD AT THE PARTY LEVEL ---------');
  END IF ;


  WHILE l_cond_attrib_list.EXISTS(l_idx)
  LOOP

      l('     HZ_WORD_CONDITIONS_PKG.set_gbl_condition_rec ('||l_cond_attrib_list(l_idx)||','||'H_TX'||l_idx||'(I));');
      l_idx := l_idx+1;
  END LOOP;


  l('');


  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_custom_list(I) <> 'N' AND l_mincol_list(I) = 'Y' THEN
        l('         H_TX'||I||'(I):='||l_custom_list(I)||';');
      END IF;
    END IF;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_mincol_list(I) <> 'Y' THEN
        l('         H_TX'||I||'(I):='||l_forall_list(I)||';');
      END IF;
    END IF;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_mincol_list(I) = 'Y' THEN
        l('         H_TX'||I||'(I):='||l_forall_list(I)||';');
      END IF;
    END IF;
  END LOOP;
  l('      H_PARTY_INDEX(I) := I;');
  l('      H_PS_DEN(I) := '' '';');
  l('      H_CT_DEN(I) := '' '';');
  l('      H_CPT_DEN(I) := '' '';');
  l('    END LOOP;');

  l('    SAVEPOINT party_batch;');
  l('    BEGIN ');
  l('      l_st := 1;  ');
  l('      l_en := H_P_PARTY_ID.COUNT; ');
  l('      LOOP ');
  l('          BEGIN  ');
  l('          FORALL I in l_st..l_en');
  l('            INSERT INTO HZ_STAGED_PARTIES (');
  l('	           PARTY_ID');
  l('  	           ,STATUS');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      l('               , TX'||I);
    END IF;
  END LOOP;
  l('             ) VALUES (');
  l('             H_P_PARTY_ID(I)');
  l('             ,H_STATUS(I)');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      l('             , decode(H_TX'||I||'(I),null,H_TX'||I||'(I),H_TX'||I||'(I)||'' '')');
    END IF;
  END LOOP;
  l('            );');
  l('           EXIT; ');
  l('        EXCEPTION  WHEN OTHERS THEN ');
  l('            l_st:= l_st+SQL%ROWCOUNT+1;');
  l('        END; ');
  l('      END LOOP; ');
  l('      FORALL I in H_P_PARTY_ID.FIRST..H_P_PARTY_ID.LAST');
  l('        INSERT INTO HZ_DQM_STAGE_GT ( PARTY_ID, OWNER_ID, PARTY_INDEX) VALUES (');
  l('           H_P_PARTY_ID(I),H_P_PARTY_ID(I),H_PARTY_INDEX(I));');

  l('        insert_stage_contacts;');
  l('        insert_stage_party_sites;');
  l('        insert_stage_contact_pts;');
  l('      FORALL I in H_P_PARTY_ID.FIRST..H_P_PARTY_ID.LAST');
  l('        UPDATE HZ_STAGED_PARTIES SET ');
  l('                D_PS = H_PS_DEN(I),');
  l('                D_CT = H_CT_DEN(I),');
  l('                D_CPT = H_CPT_DEN(I)');
  l('        WHERE PARTY_ID = H_P_PARTY_ID(I);');
  l('      EXCEPTION ');
  l('        WHEN OTHERS THEN');
  l('          ROLLBACK to party_batch;');
  l('          RAISE;');
  l('      END;');
  l('      IF l_last_fetch THEN');
  l('        FND_CONCURRENT.AF_Commit;');
  l('        EXIT;');
  l('      END IF;');
  l('      FND_CONCURRENT.AF_Commit;');
  l('    END LOOP;');
  l('  END;');

  l('  PROCEDURE sync_single_party (');
  l('    p_party_id NUMBER,');
  l('    p_party_type VARCHAR2,');
  l('    p_operation VARCHAR2) IS');
  l('');
  l('  l_tryins BOOLEAN;');
  l('  l_tryupd BOOLEAN;');
  l('   BEGIN');
  l('    IF p_party_type = ''ORGANIZATION'' THEN');
  l('      SELECT p.PARTY_ID, p.STATUS ');
  FOR I in 1..l_org_select.COUNT LOOP
    IF l_org_select(I) <> 'N' THEN
      l('        ,' || l_org_select(I));
    END IF;
  END LOOP;
  l('      INTO H_P_PARTY_ID(1), H_STATUS(1)');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' AND l_mincol_list(I) = 'Y' AND
       l_custom_list(I) = 'N' THEN
      l('         , H_TX'||I||'(1)');
    END IF;
  END LOOP;
  l('      FROM HZ_PARTIES p, HZ_ORGANIZATION_PROFILES op ');
  l('      WHERE p.party_id = p_party_id ');
  l('      AND p.party_id = op.party_id ');
  l('      AND (p.status = ''M'' or op.effective_end_date is NULL)  AND ROWNUM=1; ');
  l('    ELSIF p_party_type = ''PERSON'' THEN');
  l('      SELECT p.PARTY_ID, p.STATUS ');
  FOR I in 1..l_per_select.COUNT LOOP
    IF l_per_select(I) <> 'N' THEN
      l('        ,' || l_per_select(I));
    END IF;
  END LOOP;
  l('      INTO H_P_PARTY_ID(1), H_STATUS(1)');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' AND l_mincol_list(I) = 'Y' AND
       l_custom_list(I) = 'N' THEN
      l('         , H_TX'||I||'(1)');
    END IF;
  END LOOP;
  l('      FROM HZ_PARTIES p, HZ_PERSON_PROFILES pe ');
  l('      WHERE p.party_id = p_party_id ');
  l('      AND p.party_id = pe.party_id ');
  l('      AND (p.status = ''M'' or pe.effective_end_date is NULL) AND ROWNUM=1;');
  l('    ELSE');
  l('      SELECT p.PARTY_ID, p.STATUS ');
  FOR I in 1..l_oth_select.COUNT LOOP
    IF l_per_select(I) <> 'N' THEN
      l('        ,' || l_oth_select(I));
    END IF;
  END LOOP;

  l('      INTO H_P_PARTY_ID(1), H_STATUS(1)');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' AND l_mincol_list(I) = 'Y' AND
       l_custom_list(I) = 'N' THEN
      l('         , H_TX'||I||'(1)');
    END IF;
  END LOOP;
  l('      FROM HZ_PARTIES p ');
  l('      WHERE p.party_id = p_party_id;');
  l('    END IF;');
  -- VJN INTRODUCED CODE FOR GENERATING THE POPULATION
  -- OF THE GLOBAL CONDITION RECORD

  l_idx := l_cond_attrib_list.FIRST ;
  IF l_idx IS NOT NULL
  THEN
    l('----------- SETTING GLOBAL CONDITION RECORD AT THE PARTY LEVEL ---------');
  END IF ;


  WHILE l_cond_attrib_list.EXISTS(l_idx)
  LOOP

      l('     HZ_WORD_CONDITIONS_PKG.set_gbl_condition_rec ('||l_cond_attrib_list(l_idx)||','||'H_TX'||l_idx||'(1));');
      l_idx := l_idx+1;
  END LOOP;


    FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_custom_list(I) <> 'N' AND l_mincol_list(I) = 'Y' THEN
        l('   H_TX'||I||'(1):='||replace(l_custom_list(I),'(I)','(1)')||';');
      END IF;
    END IF;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_mincol_list(I) <> 'Y' THEN
        l('   H_TX'||I||'(1):='||replace(l_forall_list(I),'(I)','(1)')||';');
      END IF;
    END IF;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_mincol_list(I) = 'Y' THEN
        l('   H_TX'||I||'(1):='||replace(l_forall_list(I),'(I)','(1)')||';');
      END IF;
    END IF;
  END LOOP;

  l('   l_tryins := FALSE;');
  l('   l_tryupd := FALSE;');
  l('   IF p_operation=''C'' THEN');
  l('     l_tryins:=TRUE;');
  l('   ELSE ');
  l('     l_tryupd:=TRUE;');
  l('   END IF;');
  l('   WHILE (l_tryins OR l_tryupd) LOOP');
  l('     IF l_tryins THEN');
  l('       BEGIN');
  l('         l_tryins:=FALSE;');
  l('         INSERT INTO HZ_STAGED_PARTIES (');
  l('             PARTY_ID');
  l('            ,STATUS');
  l('            ,D_PS');
  l('            ,D_CT');
  l('            ,D_CPT');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      l('              , TX'||I);
    END IF;
  END LOOP;
  l('           ) VALUES (');
  l('             H_P_PARTY_ID(1)');
  l('            ,H_STATUS(1)');
  l('            ,''SYNC''');
  l('            ,''SYNC''');
  l('            ,''SYNC''');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      l('             , decode(H_TX'||I||'(1),null,H_TX'||I||'(1),H_TX'||I||'(1)||'' '')');
    END IF;
  END LOOP;
  l('         );');
  l('       EXCEPTION');
  l('         WHEN DUP_VAL_ON_INDEX THEN');
  l('           IF p_operation=''C'' THEN');
  l('             l_tryupd:=TRUE;');
  l('           END IF;');
  l('       END;');
  l('     END IF;');
  l('     IF l_tryupd THEN');
  l('       BEGIN');
  l('         l_tryupd:=FALSE;');
  l('         UPDATE HZ_STAGED_PARTIES SET ');
  l('            status =H_STATUS(1) ');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
            l('            ,TX'||I||'=decode(H_TX'||I||'(1),null,H_TX'||I||'(1),H_TX'||I||'(1)||'' '')');
    END IF;
  END LOOP;
  l('         WHERE PARTY_ID=H_P_PARTY_ID(1);');
  l('         IF SQL%ROWCOUNT=0 AND p_operation=''U'' THEN');
  l('           l_tryins := TRUE;');
  l('         END IF;');
  l('       EXCEPTION ');
  l('         WHEN NO_DATA_FOUND THEN');
  l('           IF p_operation=''U'' THEN');
  l('             l_tryins := TRUE;');
  l('           END IF;');
  l('       END;');
  l('     END IF;');
  l('   END LOOP;');
  l('  END;');

END;

PROCEDURE generate_party_site_query_proc IS
 cur_col_num NUMBER := 1;

 TYPE coltab IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;

 l_select coltab;
 FIRST BOOLEAN := FALSE;

 l_forall_list coltab;
 l_custom_list coltab;
 l_mincol_list coltab;
 l_min_colnum NUMBER;
 idx NUMBER :=1;
 is_first boolean := true;

 -- VJN Introduced for conditional word replacements
 l_cond_attrib_list coltab ;
 l_idx number ;

BEGIN

  l('  PROCEDURE insert_stage_party_sites IS ');
  l('  l_limit NUMBER := ' || g_batch_size || ';');
  l('  l_last_fetch BOOLEAN := FALSE;');
  l('  l_denorm VARCHAR2(2000);');
  l('  l_st number; ');
  l('  l_en number; ');

  l(' ');

  FOR ATTRS IN (SELECT a.ATTRIBUTE_ID,
                       a.ATTRIBUTE_NAME,
                       a.SOURCE_TABLE,
                       a.CUSTOM_ATTRIBUTE_PROCEDURE,
                       f.PROCEDURE_NAME,
                       f.STAGED_ATTRIBUTE_COLUMN,
                       to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3)) COLNUM
                FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
                WHERE ENTITY_NAME = 'PARTY_SITES'
                AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
                ORDER BY COLNUM) LOOP
    IF cur_col_num<ATTRS.COLNUM THEN
      FOR I in cur_col_num..ATTRS.COLNUM-1 LOOP
        l_mincol_list(I) := 'N';
        l_forall_list(I) := 'N';
        l_custom_list(I) := 'N';
      END LOOP;
    END IF;
    cur_col_num:=ATTRS.COLNUM+1;
    IF has_trx_context(ATTRS.PROCEDURE_NAME) THEN
      l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||ATTRS.COLNUM||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''PARTY_SITES'',''STAGE'')';
    ELSE
      l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||ATTRS.COLNUM||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''PARTY_SITES'')';
    END IF;

    SELECT min(to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3))) INTO l_min_colnum
    FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
    WHERE ENTITY_NAME = 'PARTY_SITES'
    AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
    AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
    AND a.ATTRIBUTE_NAME=ATTRS.ATTRIBUTE_NAME;

    IF ATTRS.colnum>l_min_colnum THEN
      l_mincol_list(ATTRS.COLNUM) := 'N';
      IF has_trx_context(ATTRS.PROCEDURE_NAME) THEN
        l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||l_min_colnum||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''PARTY_SITES'',''STAGE'')';
      ELSE
        l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||l_min_colnum||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''PARTY_SITES'')';
      END IF;
    ELSE
      l_mincol_list(ATTRS.COLNUM) := 'Y';
    END IF;

    IF ATTRS.CUSTOM_ATTRIBUTE_PROCEDURE IS NULL THEN
      IF l_mincol_list(ATTRS.COLNUM) = 'Y' THEN
        IF ATTRS.SOURCE_TABLE='HZ_LOCATIONS' THEN
          l_select(idx) := 'l.'||ATTRS.ATTRIBUTE_NAME;
        ELSIF ATTRS.SOURCE_TABLE='HZ_PARTY_SITES' THEN
          l_select(idx) := 'ps.'||ATTRS.ATTRIBUTE_NAME;
        END IF;
      ELSE
        l_select(idx) := 'N';
      END IF;

      l_custom_list(ATTRS.COLNUM) := 'N';
    ELSE
      l_select(idx) := 'N';
      l_custom_list(ATTRS.COLNUM) := 'N';
      IF ATTRS.ATTRIBUTE_NAME = 'ADDRESS' THEN
        IF l_mincol_list(ATTRS.COLNUM) = 'Y' THEN
          l_select(idx) := 'rtrim(l.address1 || '' '' || l.address2 || '' '' || l.address3 || '' '' || l.address4)';
        END IF;
      ELSE
        IF l_mincol_list(ATTRS.COLNUM) = 'Y' THEN
          IF has_context(ATTRS.custom_attribute_procedure) THEN
            l_custom_list(ATTRS.COLNUM) := ATTRS.custom_attribute_procedure || '(H_PARTY_SITE_ID(I),''PARTY_SITES'','''||ATTRS.ATTRIBUTE_NAME|| ''', ''STAGE'')';
          ELSE
            l_custom_list(ATTRS.COLNUM) := ATTRS.custom_attribute_procedure || '(H_PARTY_SITE_ID(I), ''PARTY_SITES'','''||ATTRS.ATTRIBUTE_NAME|| ''')';
          END IF;
        END IF;
      END IF;
    END IF;
    idx := idx+1;

    -- VJN ADDED CODE FOR TRACKING CONDITION ATTRIBUTES AT THIS ENTITY LEVEL
    IF HZ_WORD_CONDITIONS_PKG.is_a_cond_attrib( ATTRS.attribute_id)
     THEN
         l_cond_attrib_list(ATTRS.COLNUM) := ATTRS.attribute_id ;
    END IF;

  END LOOP;

  IF cur_col_num<255 THEN
    FOR I in cur_col_num..255 LOOP
      l_mincol_list(I) := 'N';
      l_forall_list(I) := 'N';
      l_custom_list(I) := 'N';
    END LOOP;
  END IF;

  l('    CURSOR party_site_cur IS');
  l('            SELECT /*+ ORDERED USE_NL(ps l) */ ps.PARTY_SITE_ID, g.party_id, g.org_contact_id, g.PARTY_INDEX ');
  FOR I in 1..l_select.COUNT LOOP
    IF l_select(I) <> 'N' THEN
      l('                  ,' || l_select(I));
    END IF;
  END LOOP;

  l('            FROM HZ_DQM_STAGE_GT g, HZ_PARTY_SITES ps, HZ_LOCATIONS l');
  l('            WHERE ps.PARTY_ID = g.owner_id ');
  l('            AND (ps.status is null OR ps.status = ''A'' OR ps.status = ''I'')    ');
  l('            AND ps.location_id = l.location_id; ');

  l('  BEGIN');
  l('    OPEN party_site_cur;');
  l('    LOOP');
  l('      FETCH party_site_cur BULK COLLECT INTO');
  l('        H_PARTY_SITE_ID');
  l('        ,H_PS_PARTY_ID');
  l('        ,H_PS_ORG_CONTACT_ID');
  l('        ,H_PARTY_INDEX');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' AND l_mincol_list(I) = 'Y' AND
       l_custom_list(I) = 'N' THEN
      l('         ,H_TX'||I);
    END IF;
  END LOOP;
  l('      LIMIT l_limit;');
  l('');
  l('    IF party_site_cur%NOTFOUND THEN');
  l('      l_last_fetch:=TRUE;');
  l('    END IF;');

  l('    IF H_PS_PARTY_ID.COUNT=0 AND l_last_fetch THEN');
  l('      EXIT;');
  l('    END IF;');

  l('    FOR I in H_PS_PARTY_ID.FIRST..H_PS_PARTY_ID.LAST LOOP');

  -- VJN INTRODUCED FOR CONDITIONAL REPLACEMENTS
  -- CYCLE THROUGH THE CONDITON LIST AND GENERATE THE CODE
  -- FOR POPULATING THE GLOBAL CONDITION RECORD

  l_idx := l_cond_attrib_list.FIRST ;
  IF l_idx IS NOT NULL
  THEN
    l('----------- SETTING GLOBAL CONDITION RECORD AT THE PARTY SITE LEVEL ---------');
  END IF ;


  l('');


  WHILE l_cond_attrib_list.EXISTS(l_idx)
  LOOP

      l('     HZ_WORD_CONDITIONS_PKG.set_gbl_condition_rec ('||l_cond_attrib_list(l_idx)||','||'H_TX'||l_idx||'(I));');
      l_idx := l_idx+1;
  END LOOP;


  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_custom_list(I) <> 'N' AND l_mincol_list(I) = 'Y' THEN
        l('         H_TX'||I||'(I):='||l_custom_list(I)||';');
      END IF;
    END IF;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_mincol_list(I) <> 'Y' THEN
        l('         H_TX'||I||'(I):='||l_forall_list(I)||';');
      END IF;
    END IF;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_mincol_list(I) = 'Y' THEN
        l('         H_TX'||I||'(I):='||l_forall_list(I)||';');
      END IF;
    END IF;
  END LOOP;

  FIRST := TRUE;
  FOR ATTRS IN (SELECT a.ATTRIBUTE_ID,
                       a.ATTRIBUTE_NAME,
                       a.SOURCE_TABLE,
                       a.CUSTOM_ATTRIBUTE_PROCEDURE,
                       f.PROCEDURE_NAME,
                       f.STAGED_ATTRIBUTE_COLUMN,
                       to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3)) COLNUM
                FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
                WHERE ENTITY_NAME = 'PARTY_SITES'
                AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
                AND nvl(a.DENORM_FLAG,'N') = 'Y') LOOP
     IF FIRST THEN
     -- Fix for bug 4778420
     -- Wrapping the 'l_denorm' portion of code into a begin-excpetion block
     -- and setting the denorm value to 'SYNC' if sqlcode-6502 error occurs
       l('      BEGIN ');
       l('        l_denorm := H_TX'||ATTRS.COLNUM||'(I)');
       FIRST := FALSE;
     ELSE
       l('                  || '' '' ||  H_TX'||ATTRS.COLNUM||'(I)');
     END IF;
  END LOOP;
  IF NOT FIRST THEN
    l('             ;');
    l('        IF H_PS_DEN(H_PARTY_INDEX(I)) = ''SYNC'' THEN');
    l('          NULL;');
    l('        ELSIF lengthb(H_PS_DEN(H_PARTY_INDEX(I)))+lengthb(l_denorm)<2000 THEN');
    l('          IF H_PS_DEN(H_PARTY_INDEX(I)) IS NULL OR instrb(H_PS_DEN(H_PARTY_INDEX(I)),l_denorm)=0 THEN');
    l('            H_PS_DEN(H_PARTY_INDEX(I)) := H_PS_DEN(H_PARTY_INDEX(I)) || '' '' || l_denorm;');
    l('          END IF;');
    l('        ELSE');
    l('          H_PS_DEN(H_PARTY_INDEX(I)) := ''SYNC'';');
    l('        END IF;');
    l('      EXCEPTION WHEN OTHERS THEN ');
    l('        IF SQLCODE=-6502 THEN');
    l('          H_PS_DEN(H_PARTY_INDEX(I)) := ''SYNC'';');
    l('        END IF; ');
    l('      END; ');
  END IF;
  l('    END LOOP;');
  l('      l_st := 1;  ');
  l('      l_en :=  H_PS_PARTY_ID.COUNT; ');
  l('      LOOP ');
  l('          BEGIN  ');
  l('          FORALL I in l_st..l_en');
  l('             INSERT INTO HZ_STAGED_PARTY_SITES (');
  l('	              PARTY_SITE_ID');
  l('	              ,PARTY_ID');
  l('	              ,ORG_CONTACT_ID');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      l('                 , TX'||I);
    END IF;
  END LOOP;
  l('                 ) VALUES (');
  l('                 H_PARTY_SITE_ID(I)');
  l('                ,H_PS_PARTY_ID(I)');
  l('                ,H_PS_ORG_CONTACT_ID(I)');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      l('                 , decode(H_TX'||I||'(I),null,H_TX'||I||'(I),H_TX'||I||'(I)||'' '')');
    END IF;
  END LOOP;
  l('        );');
  l('        EXIT; ');
  l('        EXCEPTION  WHEN OTHERS THEN ');
  l('            l_st:= l_st+SQL%ROWCOUNT+1;');
  l('        END; ');
  l('      END LOOP; ');
  l('      FORALL I in H_PS_PARTY_ID.FIRST..H_PS_PARTY_ID.LAST ');
  l('        INSERT INTO HZ_DQM_STAGE_GT (PARTY_ID, OWNER_ID, OWNER_TABLE, PARTY_SITE_ID,');
  l('                                     ORG_CONTACT_ID,PARTY_INDEX) VALUES (');
  l('        H_PS_PARTY_ID(I),H_PARTY_SITE_ID(I),''HZ_PARTY_SITES'',H_PARTY_SITE_ID(I),');
  l('         H_PS_ORG_CONTACT_ID(I),H_PARTY_INDEX(I));');

  l('      IF l_last_fetch THEN');
  l('        EXIT;');
  l('      END IF;');
  l('    END LOOP;');
  l('    CLOSE party_site_cur;');
  l('  END;');

  l('  PROCEDURE sync_single_party_site (');
  l('    p_party_site_id NUMBER,');
  l('    p_operation VARCHAR2) IS');
  l('');
  l('  l_tryins BOOLEAN;');
  l('  l_tryupd BOOLEAN;');
  l('   BEGIN');

  l('     SELECT ps.PARTY_SITE_ID, d.party_id, d.org_contact_id ');
  FOR I in 1..l_select.COUNT LOOP
    IF l_select(I) <> 'N' THEN
      l('                  ,' || l_select(I));
    END IF;
  END LOOP;
  l('      INTO H_PARTY_SITE_ID(1), H_PARTY_ID(1), H_ORG_CONTACT_ID(1)');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' AND l_mincol_list(I) = 'Y' AND
       l_custom_list(I) = 'N' THEN
      l('         , H_TX'||I||'(1)');
    END IF;
  END LOOP;
  l('     FROM HZ_PARTY_SITES ps, HZ_DQM_SYNC_INTERFACE d, HZ_LOCATIONS l ');
  l('     WHERE d.ENTITY=''PARTY_SITES'' ');
  l('     AND ps.party_site_id = p_party_site_id');
  l('     AND d.record_id = ps.party_site_id ');
  l('     AND ps.location_id = l.location_id ');
  l('     AND (ps.status is null OR ps.status = ''A'' OR ps.status = ''I'')    ');
  l('     AND ROWNUM=1;');

  -- VJN INTRODUCED CODE FOR GENERATING THE POPULATION
  -- OF THE GLOBAL CONDITION RECORD

  l_idx := l_cond_attrib_list.FIRST ;
  IF l_idx IS NOT NULL
  THEN
    l('----------- SETTING GLOBAL CONDITION RECORD AT THE PARTY SITE LEVEL ---------');
  END IF ;


  WHILE l_cond_attrib_list.EXISTS(l_idx)
  LOOP

      l('     HZ_WORD_CONDITIONS_PKG.set_gbl_condition_rec ('||l_cond_attrib_list(l_idx)||','||'H_TX'||l_idx||'(1));');
      l_idx := l_idx+1;
  END LOOP;

  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_custom_list(I) <> 'N' AND l_mincol_list(I) = 'Y' THEN
        l('    H_TX'||I||'(1):='||replace(l_custom_list(I),'(I)','(1)')||';');
      END IF;
    END IF;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_mincol_list(I) <> 'Y' THEN
        l('    H_TX'||I||'(1):='||replace(l_forall_list(I),'(I)','(1)')||';');
      END IF;
    END IF;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_mincol_list(I) = 'Y' THEN
        l('    H_TX'||I||'(1):='||replace(l_forall_list(I),'(I)','(1)')||';');
      END IF;
    END IF;
  END LOOP;

  l('   l_tryins := FALSE;');
  l('   l_tryupd := FALSE;');
  l('   IF p_operation=''C'' THEN');
  l('     l_tryins:=TRUE;');
  l('   ELSE ');
  l('     l_tryupd:=TRUE;');
  l('   END IF;');
  l('   WHILE (l_tryins OR l_tryupd) LOOP');
  l('     IF l_tryins THEN');
  l('       BEGIN');
  l('         l_tryins:=FALSE;');
  l('         INSERT INTO HZ_STAGED_PARTY_SITES (');
  l('           PARTY_SITE_ID');
  l('           ,PARTY_ID');
  l('           ,ORG_CONTACT_ID');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      l('              , TX'||I);
    END IF;
  END LOOP;
  l('           ) VALUES (');
  l('            H_PARTY_SITE_ID(1)');
  l('            ,H_PARTY_ID(1)');
  l('            ,H_ORG_CONTACT_ID(1)');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      l('             , decode(H_TX'||I||'(1),null,H_TX'||I||'(1),H_TX'||I||'(1)||'' '')');
    END IF;
  END LOOP;
  l('         );');
  l('       EXCEPTION');
  l('         WHEN DUP_VAL_ON_INDEX THEN');
  l('           IF p_operation=''C'' THEN');
  l('             l_tryupd:=TRUE;');
  l('           END IF;');
  l('       END;');
  l('     END IF;');
  l('     IF l_tryupd THEN');
  l('       BEGIN');
  l('         l_tryupd:=FALSE;');
  l('         UPDATE HZ_STAGED_PARTY_SITES SET ');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      	IF (is_first) THEN
	     is_first := false;
             l('            TX'||I||'=decode(H_TX'||I||'(1),null,H_TX'||I||'(1),H_TX'||I||'(1)||'' '')');
	ELSE
             l('            ,TX'||I||'=decode(H_TX'||I||'(1),null,H_TX'||I||'(1),H_TX'||I||'(1)||'' '')');
	END IF;
    END IF;
  END LOOP;
  l('         WHERE PARTY_SITE_ID=H_PARTY_SITE_ID(1);');
  l('         IF SQL%ROWCOUNT=0 AND p_operation=''U'' THEN');
  l('           l_tryins := TRUE;');
  l('         END IF;');
  l('       EXCEPTION ');
  l('         WHEN NO_DATA_FOUND THEN');
  l('           IF p_operation=''U'' THEN');
  l('             l_tryins := TRUE;');
  l('           END IF;');
  l('       END;');
  l('     END IF;');
  l('   END LOOP;');
  l('   UPDATE HZ_STAGED_PARTIES set');
  l('   D_PS = ''SYNC''');
  l('   WHERE PARTY_ID = H_PARTY_ID(1);');
  l('  END;');
END;

PROCEDURE generate_contact_query_proc IS
 cur_col_num NUMBER := 1;

 TYPE coltab IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;

 l_select coltab;
 FIRST BOOLEAN := FALSE;

 l_forall_list coltab;
 l_custom_list coltab;
 l_mincol_list coltab;
 l_min_colnum NUMBER;
 idx NUMBER :=1;
 is_first boolean := true;

 -- VJN Introduced for conditional word replacements
 l_cond_attrib_list coltab ;
 l_idx number ;

BEGIN

  l('  PROCEDURE insert_stage_contacts IS ');
  l('    l_limit NUMBER := ' || g_batch_size || ';');
  l('    l_last_fetch BOOLEAN := FALSE;');
  l('    l_denorm VARCHAR2(2000);');
  l('    l_st number; ');
  l('    l_en number; ');
  FOR ATTRS IN (SELECT a.ATTRIBUTE_ID,
                       a.ATTRIBUTE_NAME,
                       a.SOURCE_TABLE,
                       a.CUSTOM_ATTRIBUTE_PROCEDURE,
                       f.PROCEDURE_NAME,
                       f.STAGED_ATTRIBUTE_COLUMN,
                       to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3)) COLNUM
                FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
                WHERE ENTITY_NAME = 'CONTACTS'
                AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
                ORDER BY COLNUM) LOOP
    IF cur_col_num<ATTRS.COLNUM THEN
      FOR I in cur_col_num..ATTRS.COLNUM-1 LOOP
        l_mincol_list(I) := 'N';
        l_forall_list(I) := 'N';
        l_custom_list(I) := 'N';
      END LOOP;
    END IF;
    cur_col_num:=ATTRS.COLNUM+1;
    IF has_trx_context(ATTRS.PROCEDURE_NAME) THEN
        l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||ATTRS.COLNUM||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''CONTACTS'',''STAGE'')';
    ELSE
        l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||ATTRS.COLNUM||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''CONTACTS'')';
    END IF;

    SELECT min(to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3))) INTO l_min_colnum
    FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
    WHERE ENTITY_NAME = 'CONTACTS'
    AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
    AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
    AND a.ATTRIBUTE_NAME=ATTRS.ATTRIBUTE_NAME;

    IF ATTRS.colnum>l_min_colnum THEN
      l_mincol_list(ATTRS.COLNUM) := 'N';
      IF has_trx_context(ATTRS.PROCEDURE_NAME) THEN
        l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||l_min_colnum||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''CONTACTS'',''STAGE'')';
      ELSE
        l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||l_min_colnum||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''CONTACTS'')';
      END IF;

    ELSE
      l_mincol_list(ATTRS.COLNUM) := 'Y';
    END IF;

    IF ATTRS.CUSTOM_ATTRIBUTE_PROCEDURE IS NULL THEN
      IF l_mincol_list(ATTRS.COLNUM) = 'Y' THEN
        IF ATTRS.SOURCE_TABLE='HZ_PERSON_PROFILES' THEN
          l_select(idx) := 'pp.'||ATTRS.ATTRIBUTE_NAME;
        ELSIF ATTRS.SOURCE_TABLE='HZ_ORG_CONTACTS' THEN
          l_select(idx) := 'oc.'||ATTRS.ATTRIBUTE_NAME;
        ELSIF ATTRS.SOURCE_TABLE='HZ_RELATIONSHIPS' THEN
          l_select(idx) := 'r.'||ATTRS.ATTRIBUTE_NAME;
        END IF;
      ELSE
        l_select(idx) := 'N';
      END IF;

      l_custom_list(ATTRS.COLNUM) := 'N';
    ELSE
      l_select(idx) := 'N';
      l_custom_list(ATTRS.COLNUM) := 'N';
      IF ATTRS.ATTRIBUTE_NAME = 'CONTACT_NAME' THEN
        IF l_mincol_list(ATTRS.COLNUM) = 'Y' THEN
          l_select(idx) := 'rtrim(pp.person_first_name || '' '' || pp.person_last_name)';
        END IF;
      ELSE
        IF l_mincol_list(ATTRS.COLNUM) = 'Y' THEN
          IF has_context(ATTRS.custom_attribute_procedure) THEN
            l_custom_list(ATTRS.COLNUM) := ATTRS.custom_attribute_procedure || '(H_ORG_CONTACT_ID(I),''CONTACTS'','''||ATTRS.ATTRIBUTE_NAME|| ''', ''STAGE'')';
          ELSE
            l_custom_list(ATTRS.COLNUM) := ATTRS.custom_attribute_procedure || '(H_ORG_CONTACT_ID(I), ''CONTACTS'','''||ATTRS.ATTRIBUTE_NAME|| ''')';
          END IF;
        END IF;
      END IF;
    END IF;
    idx := idx+1;
    -- VJN ADDED CODE FOR TRACKING CONDITION ATTRIBUTES AT THIS ENTITY LEVEL
    IF HZ_WORD_CONDITIONS_PKG.is_a_cond_attrib( ATTRS.attribute_id)
     THEN
         l_cond_attrib_list(ATTRS.COLNUM) := ATTRS.attribute_id ;
    END IF;
  END LOOP;

  IF cur_col_num<255 THEN
    FOR I in cur_col_num..255 LOOP
      l_mincol_list(I) := 'N';
      l_forall_list(I) := 'N';
      l_custom_list(I) := 'N';
    END LOOP;
  END IF;

  l('  CURSOR contact_cur IS');
  l('            SELECT ');
  l('              /*+ ORDERED USE_NL(R OC PP)*/');
  l('            oc.ORG_CONTACT_ID , r.OBJECT_ID, r.PARTY_ID, g.PARTY_INDEX ');
  FOR I in 1..l_select.COUNT LOOP
    IF l_select(I) <> 'N' THEN
      l('                  ,' || l_select(I));
    END IF;
  END LOOP;
  l('           FROM HZ_DQM_STAGE_GT g, HZ_RELATIONSHIPS r,');
  l('           HZ_ORG_CONTACTS oc, HZ_PERSON_PROFILES pp');
  l('           WHERE oc.party_relationship_id =  r.relationship_id ');
  l('           AND r.object_id = g.party_id ');
  l('           AND r.subject_id = pp.party_id ');
  l('           AND r.SUBJECT_TABLE_NAME = ''HZ_PARTIES''');
  l('           AND r.OBJECT_TABLE_NAME = ''HZ_PARTIES''');
  l('           AND DIRECTIONAL_FLAG= ''F'' ');
  l('           AND pp.effective_end_date is NULL ');
  l('           AND (oc.status is null OR oc.status = ''A'' or oc.status = ''I'')');
  l('           AND (r.status is null OR r.status = ''A'' or r.status = ''I'');');
  l('');
  l('  BEGIN');
  l('    OPEN contact_cur;');
  l('    LOOP');
  l('      FETCH contact_cur BULK COLLECT INTO');
  l('        H_ORG_CONTACT_ID');
  l('        ,H_C_PARTY_ID');
  l('        ,H_R_PARTY_ID');
  l('        ,H_PARTY_INDEX');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' AND l_mincol_list(I) = 'Y' AND
       l_custom_list(I) = 'N' THEN
      l('         ,H_TX'||I);
    END IF;
  END LOOP;
  l('      LIMIT l_limit;');
  l('');
  l('    IF contact_cur%NOTFOUND THEN');
  l('      l_last_fetch:=TRUE;');
  l('    END IF;');

  l('    IF H_C_PARTY_ID.COUNT=0 AND l_last_fetch THEN');
  l('      EXIT;');
  l('    END IF;');

  l('    FOR I in H_C_PARTY_ID.FIRST..H_C_PARTY_ID.LAST LOOP');


  -- VJN INTRODUCED CODE FOR GENERATING THE POPULATION
  -- OF THE GLOBAL CONDITION RECORD
  l_idx := l_cond_attrib_list.FIRST ;
  IF l_idx IS NOT NULL
  THEN
    l('----------- SETTING GLOBAL CONDITION RECORD AT THE CONTACT LEVEL ---------');
  END IF ;


  WHILE l_cond_attrib_list.EXISTS(l_idx)
  LOOP

      l('     HZ_WORD_CONDITIONS_PKG.set_gbl_condition_rec ('||l_cond_attrib_list(l_idx)||','||'H_TX'||l_idx||'(I));');
      l_idx := l_idx+1;
  END LOOP;

  l('');

  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_custom_list(I) <> 'N' AND l_mincol_list(I) = 'Y' THEN
        l('         H_TX'||I||'(I):='||l_custom_list(I)||';');
      END IF;
    END IF;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_mincol_list(I) <> 'Y' THEN
        l('         H_TX'||I||'(I):='||l_forall_list(I)||';');
      END IF;
    END IF;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_mincol_list(I) = 'Y' THEN
        l('         H_TX'||I||'(I):='||l_forall_list(I)||';');
      END IF;
    END IF;
  END LOOP;

  FIRST := TRUE;
  FOR ATTRS IN (SELECT a.ATTRIBUTE_ID,
                       a.ATTRIBUTE_NAME,
                       a.SOURCE_TABLE,
                       a.CUSTOM_ATTRIBUTE_PROCEDURE,
                       f.PROCEDURE_NAME,
                       f.STAGED_ATTRIBUTE_COLUMN,
                       to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3)) COLNUM
                FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
                WHERE ENTITY_NAME = 'CONTACTS'
                AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
                AND nvl(a.DENORM_FLAG,'N') = 'Y') LOOP
     IF FIRST THEN
     -- Fix for bug 4778420
     -- Wrapping the 'l_denorm' portion of code into a begin-excpetion block
     -- and setting the denorm value to 'SYNC' if sqlcode-6502 error occurs
       l('      BEGIN ');
       l('        l_denorm := H_TX'||ATTRS.COLNUM||'(I)');
       FIRST := FALSE;
     ELSE
       l('                  ||'' '' ||  H_TX'||ATTRS.COLNUM||'(I)');
     END IF;
  END LOOP;
  IF NOT FIRST THEN
    l('             ;');
    l('        IF H_CT_DEN(H_PARTY_INDEX(I)) = ''SYNC'' THEN');
    l('          NULL;');
    l('        ELSIF lengthb(H_CT_DEN(H_PARTY_INDEX(I)))+lengthb(l_denorm)<2000 THEN');
    l('          IF H_CT_DEN(H_PARTY_INDEX(I)) IS NULL OR instrb(H_CT_DEN(H_PARTY_INDEX(I)),l_denorm)=0 THEN');
    l('            H_CT_DEN(H_PARTY_INDEX(I)) := H_CT_DEN(H_PARTY_INDEX(I)) || '' '' || l_denorm;');
    l('          END IF;');
    l('        ELSE');
    l('           H_CT_DEN(H_PARTY_INDEX(I)) := ''SYNC'';');
    l('        END IF;');
    l('      EXCEPTION WHEN OTHERS THEN ');
    l('        IF SQLCODE=-6502 THEN');
    l('          H_CT_DEN(H_PARTY_INDEX(I)) := ''SYNC'';');
    l('        END IF; ');
    l('      END; ');    
  END IF;
  l('    END LOOP;');
  l('      l_st :=  1;  ');
  l('      l_en :=  H_C_PARTY_ID.COUNT; ');
  l('      LOOP ');
  l('          BEGIN  ');
  l('             FORALL I in l_st..l_en');
  l('             INSERT INTO HZ_STAGED_CONTACTS (');
  l('	            ORG_CONTACT_ID');
  l('	            ,PARTY_ID');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      l('                , TX'||I);
    END IF;
  END LOOP;
  l('             ) VALUES (');
  l('             H_ORG_CONTACT_ID(I)');
  l('             ,H_C_PARTY_ID(I)');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      l('             , decode(H_TX'||I||'(I),null,H_TX'||I||'(I),H_TX'||I||'(I)||'' '')');
    END IF;
  END LOOP;
  l('          );');
  l('        EXIT; ');
  l('        EXCEPTION  WHEN OTHERS THEN ');
  l('            l_st:= l_st+SQL%ROWCOUNT+1;');
  l('        END; ');
  l('      END LOOP; ');
  l('      FORALL I in H_C_PARTY_ID.FIRST..H_C_PARTY_ID.LAST ');
  l('        INSERT INTO HZ_DQM_STAGE_GT(PARTY_ID,OWNER_ID,ORG_CONTACT_ID,PARTY_INDEX) ');
  l('           SELECT H_C_PARTY_ID(I), H_R_PARTY_ID(I), H_ORG_CONTACT_ID(I), H_PARTY_INDEX(I)');
  l('           FROM DUAL WHERE H_R_PARTY_ID(I) IS NOT NULL;');
  l('      IF l_last_fetch THEN');
  l('        EXIT;');
  l('      END IF;');
  l('    END LOOP;');
  l('     CLOSE contact_cur;');
  l('  END;');

  l('  PROCEDURE sync_single_contact (');
  l('    p_org_contact_id NUMBER,');
  l('    p_operation VARCHAR2) IS');
  l('');
  l('  l_tryins BOOLEAN;');
  l('  l_tryupd BOOLEAN;');
  l('   BEGIN');
  l('     SELECT oc.ORG_CONTACT_ID , d.PARTY_ID ');
  FOR I in 1..l_select.COUNT LOOP
    IF l_select(I) <> 'N' THEN
      l('          ,' || l_select(I));
    END IF;
  END LOOP;
  l('      INTO H_ORG_CONTACT_ID(1), H_PARTY_ID(1)');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' AND l_mincol_list(I) = 'Y' AND
       l_custom_list(I) = 'N' THEN
      l('         , H_TX'||I||'(1)');
    END IF;
  END LOOP;

  l('     FROM HZ_ORG_CONTACTS oc, HZ_DQM_SYNC_INTERFACE d, ');
  l('          HZ_RELATIONSHIPS r, HZ_PERSON_PROFILES pp');
  l('     WHERE d.ENTITY = ''CONTACTS'' ');
  l('     AND oc.org_contact_id = p_org_contact_id');
  l('     AND oc.org_contact_id = d.RECORD_ID');
  l('     AND oc.party_relationship_id =  r.relationship_id ');
  l('     AND r.subject_id = pp.party_id ');
  l('     AND r.SUBJECT_TABLE_NAME = ''HZ_PARTIES''');
  l('     AND r.OBJECT_TABLE_NAME = ''HZ_PARTIES''');
  l('     AND DIRECTIONAL_FLAG= ''F'' ');
  l('     AND pp.effective_end_date is NULL ');
  l('     AND (oc.status is null OR oc.status = ''A'' or oc.status = ''I'')');
  l('     AND (r.status is null OR r.status = ''A'' or r.status = ''I'')');
  l('     AND ROWNUM=1;');

  -- VJN INTRODUCED CODE FOR GENERATING THE POPULATION
  -- OF THE GLOBAL CONDITION RECORD

  l_idx := l_cond_attrib_list.FIRST ;
  IF l_idx IS NOT NULL
  THEN
    l('----------- SETTING GLOBAL CONDITION RECORD AT THE CONTACT LEVEL ---------');
  END IF ;


  WHILE l_cond_attrib_list.EXISTS(l_idx)
  LOOP

      l('     HZ_WORD_CONDITIONS_PKG.set_gbl_condition_rec ('||l_cond_attrib_list(l_idx)||','||'H_TX'||l_idx||'(1));');
      l_idx := l_idx+1;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_custom_list(I) <> 'N' AND l_mincol_list(I) = 'Y' THEN
        l('    H_TX'||I||'(1):='||replace(l_custom_list(I),'(I)','(1)')||';');
      END IF;
    END IF;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_mincol_list(I) <> 'Y' THEN
        l('    H_TX'||I||'(1):='||replace(l_forall_list(I),'(I)','(1)')||';');
      END IF;
    END IF;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_mincol_list(I) = 'Y' THEN
        l('    H_TX'||I||'(1):='||replace(l_forall_list(I),'(I)','(1)')||';');
      END IF;
    END IF;
  END LOOP;

  l('   l_tryins := FALSE;');
  l('   l_tryupd := FALSE;');
  l('   IF p_operation=''C'' THEN');
  l('     l_tryins:=TRUE;');
  l('   ELSE ');
  l('     l_tryupd:=TRUE;');
  l('   END IF;');
  l('   WHILE (l_tryins OR l_tryupd) LOOP');
  l('     IF l_tryins THEN');
  l('       BEGIN');
  l('         l_tryins:=FALSE;');
  l('         INSERT INTO HZ_STAGED_CONTACTS (');
  l('           ORG_CONTACT_ID');
  l('           ,PARTY_ID');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      l('              , TX'||I);
    END IF;
  END LOOP;
  l('           ) VALUES (');
  l('            H_ORG_CONTACT_ID(1)');
  l('            , H_PARTY_ID(1)');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      l('             , decode(H_TX'||I||'(1),null,H_TX'||I||'(1),H_TX'||I||'(1)||'' '')');
    END IF;
  END LOOP;
  l('         );');
  l('       EXCEPTION');
  l('         WHEN DUP_VAL_ON_INDEX THEN');
  l('           IF p_operation=''C'' THEN');
  l('             l_tryupd:=TRUE;');
  l('           END IF;');
  l('       END;');
  l('     END IF;');
  l('     IF l_tryupd THEN');
  l('       BEGIN');
  l('         l_tryupd:=FALSE;');
  l('         UPDATE HZ_STAGED_CONTACTS SET ');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      	IF (is_first) THEN
             is_first := false;
             l('            TX'||I||'=decode(H_TX'||I||'(1),null,H_TX'||I||'(1),H_TX'||I||'(1)||'' '')');
	ELSE
             l('            ,TX'||I||'=decode(H_TX'||I||'(1),null,H_TX'||I||'(1),H_TX'||I||'(1)||'' '')');
	END IF;
    END IF;
  END LOOP;
  l('         WHERE ORG_CONTACT_ID=H_ORG_CONTACT_ID(1);');
  l('         IF SQL%ROWCOUNT=0 AND p_operation=''U'' THEN');
  l('           l_tryins := TRUE;');
  l('         END IF;');
  l('       EXCEPTION ');
  l('         WHEN NO_DATA_FOUND THEN');
  l('           IF p_operation=''U'' THEN');
  l('             l_tryins := TRUE;');
  l('           END IF;');
  l('       END;');
  l('     END IF;');
  l('   END LOOP;');
  l('   UPDATE HZ_STAGED_PARTIES set');
  l('   D_CT = ''SYNC''');
  l('   WHERE PARTY_ID = H_PARTY_ID(1);');
  l('  END;');
END;


PROCEDURE generate_contact_pt_query_proc IS
 cur_col_num NUMBER := 1;

 TYPE coltab IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;

 l_select coltab;
 FIRST BOOLEAN := FALSE;

 l_forall_list coltab;
 l_custom_list coltab;
 l_mincol_list coltab;
 l_min_colnum NUMBER;
 idx NUMBER :=1;
 is_first boolean := true;

 -- VJN Introduced for conditional word replacements
 l_cond_attrib_list coltab ;
 l_idx number ;


BEGIN
  l('  PROCEDURE insert_stage_contact_pts IS ');
  l('   l_limit NUMBER := ' || g_batch_size || ';');
  l('   l_last_fetch BOOLEAN := FALSE;');
  l('   l_denorm VARCHAR2(2000);');
  l('   l_st number; ');
  l('   l_en number; ');

  l('');

  FOR ATTRS IN (SELECT a.ATTRIBUTE_ID,
                       a.ATTRIBUTE_NAME,
                       a.SOURCE_TABLE,
                       a.CUSTOM_ATTRIBUTE_PROCEDURE,
                       f.PROCEDURE_NAME,
                       f.STAGED_ATTRIBUTE_COLUMN,
                       to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3)) COLNUM
                FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
                WHERE ENTITY_NAME = 'CONTACT_POINTS'
                AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
                ORDER BY COLNUM) LOOP
    IF cur_col_num<ATTRS.COLNUM THEN
      FOR I in cur_col_num..ATTRS.COLNUM-1 LOOP
        l_mincol_list(I) := 'N';
        l_forall_list(I) := 'N';
      END LOOP;
    END IF;
    cur_col_num:=ATTRS.COLNUM+1;
    IF has_trx_context(ATTRS.PROCEDURE_NAME) THEN
      l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||ATTRS.COLNUM||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''CONTACT_POINTS'',''STAGE'')';
    ELSE
      l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||ATTRS.COLNUM||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''CONTACT_POINTS'')';
    END IF;

    SELECT min(to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3))) INTO l_min_colnum
    FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
    WHERE ENTITY_NAME = 'CONTACT_POINTS'
    AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
    AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
    AND a.ATTRIBUTE_NAME=ATTRS.ATTRIBUTE_NAME;

    IF ATTRS.colnum>l_min_colnum THEN
      l_mincol_list(ATTRS.COLNUM) := 'N';
      IF has_trx_context(ATTRS.PROCEDURE_NAME) THEN
        l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||l_min_colnum||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''CONTACT_POINTS'',''STAGE'')';
      ELSE
        l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||l_min_colnum||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''CONTACT_POINTS'')';
      END IF;

    ELSE
      l_mincol_list(ATTRS.COLNUM) := 'Y';
    END IF;

    IF ATTRS.CUSTOM_ATTRIBUTE_PROCEDURE IS NULL THEN
      IF l_mincol_list(ATTRS.COLNUM) = 'Y' THEN
        l_select(idx) := 'cp.'||ATTRS.ATTRIBUTE_NAME;
      ELSE
        l_select(idx) := 'N';
      END IF;

      l_custom_list(ATTRS.COLNUM) := 'N';
    ELSE
      l_select(idx) := 'N';
      l_custom_list(ATTRS.COLNUM) := 'N';
      IF ATTRS.ATTRIBUTE_NAME = 'FLEX_FORMAT_PHONE_NUMBER' THEN
        IF l_mincol_list(ATTRS.COLNUM) = 'Y' THEN
          l_select(idx) := 'translate(phone_number,''0123456789ABCDEFGHIJKLMNOPQRSTUV'||
'WXYZabcdefghijklmnopqrstuvwxyz!"#$%&()''''*+,-./:;<=>?@[\]^'||
'_`{|}~ '',''0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ'') || '' '' || ' ||
                           'translate(phone_area_code||'' '' || phone_number,''0123456789ABCDEFGHIJKLMNOPQRSTUV'||
'WXYZabcdefghijklmnopqrstuvwxyz!"#$%&()''''*+,-./:;<=>?@[\]^'||
'_`{|}~ '',''0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ'') || '' '' || '||
                           ' translate(phone_country_code|| '' '' || phone_area_code||'' '' || phone_number,''0123456789ABCDEFGHIJKLMNOPQRSTUV'||
'WXYZabcdefghijklmnopqrstuvwxyz!"#$%&()''''*+,-./:;<=>?@[\]^'||
'_`{|}~ '',''0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ'')';
        END IF;
      ELSIF ATTRS.ATTRIBUTE_NAME = 'RAW_PHONE_NUMBER' THEN
        IF l_mincol_list(ATTRS.COLNUM) = 'Y' THEN
          l_select(idx) := 'translate(raw_phone_number,''0123456789ABCDEFGHIJKLMNOPQRSTUV'||
'WXYZabcdefghijklmnopqrstuvwxyz!"#$%&()''''*+,-./:;<=>?@[\]^_'||
'`{|}~ '',''0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ'')';--bug 5374880

        END IF;
      ELSE
        IF l_mincol_list(ATTRS.COLNUM) = 'Y' THEN
          IF has_context(ATTRS.custom_attribute_procedure) THEN
            l_custom_list(ATTRS.COLNUM) := ATTRS.custom_attribute_procedure || '(H_CONTACT_POINT_ID(I),''CONTACT_POINTS'','''||ATTRS.ATTRIBUTE_NAME|| ''', ''STAGE'')';
          ELSE
            l_custom_list(ATTRS.COLNUM) := ATTRS.custom_attribute_procedure || '(H_CONTACT_POINT_ID(I), ''CONTACT_POINTS'','''||ATTRS.ATTRIBUTE_NAME|| ''')';
          END IF;
        END IF;
      END IF;
    END IF;
    idx := idx+1;

    -- VJN ADDED CODE FOR TRACKING CONDITION ATTRIBUTES AT THIS ENTITY LEVEL
    IF HZ_WORD_CONDITIONS_PKG.is_a_cond_attrib( ATTRS.attribute_id)
     THEN
         l_cond_attrib_list(ATTRS.COLNUM) := ATTRS.attribute_id ;
    END IF;

  END LOOP;

  IF cur_col_num<255 THEN
    FOR I in cur_col_num..255 LOOP
      l_mincol_list(I) := 'N';
      l_forall_list(I) := 'N';
      l_custom_list(I) := 'N';
    END LOOP;
  END IF;

  l('  CURSOR contact_pt_cur IS');
  l('           SELECT /*+ ORDERED USE_NL(cp) */ cp.CONTACT_POINT_ID, g.party_id, g.party_site_id, g.org_contact_id, cp.CONTACT_POINT_TYPE, PARTY_INDEX ');
  FOR I in 1..l_select.COUNT LOOP
    IF l_select(I) <> 'N' THEN
      l('                  ,' || l_select(I));
    END IF;
  END LOOP;
  l('           FROM HZ_DQM_STAGE_GT g,HZ_CONTACT_POINTS cp');
  l('           WHERE cp.owner_table_id  =  g.owner_id ');
  l('           AND cp.OWNER_TABLE_NAME = nvl(g.owner_table,''HZ_PARTIES'') ');
  l('           AND (cp.status is null OR cp.status = ''A'' or cp.status = ''I''); ');
  l('');
  l('  BEGIN');
  l('    OPEN contact_pt_cur;');
  l('    LOOP');
  l('      FETCH contact_pt_cur BULK COLLECT INTO');
  l('        H_CONTACT_POINT_ID');
  l('        ,H_CPT_PARTY_ID');
  l('        ,H_CPT_PARTY_SITE_ID');
  l('        ,H_CPT_ORG_CONTACT_ID');
  l('        ,H_CONTACT_POINT_TYPE');
  l('        ,H_PARTY_INDEX');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' AND l_mincol_list(I) = 'Y' AND
       l_custom_list(I) = 'N' THEN
      l('         ,H_TX'||I);
    END IF;
  END LOOP;
  l('      LIMIT l_limit;');
  l('');
  l('    IF contact_pt_cur%NOTFOUND THEN');
  l('      l_last_fetch:=TRUE;');
  l('    END IF;');

  l('    IF H_CPT_PARTY_ID.COUNT=0 AND l_last_fetch THEN');
  l('      EXIT;');
  l('    END IF;');

  l('    FOR I in H_CPT_PARTY_ID.FIRST..H_CPT_PARTY_ID.LAST LOOP');

  -- VJN INTRODUCED CODE FOR GENERATING THE POPULATION
  -- OF THE GLOBAL CONDITION RECORD

  l_idx := l_cond_attrib_list.FIRST ;
  IF l_idx IS NOT NULL
  THEN
    l('----------- SETTING GLOBAL CONDITION RECORD AT THE CONTACT POINT LEVEL ---------');
  END IF ;

  l('');


  WHILE l_cond_attrib_list.EXISTS(l_idx)
  LOOP

      l('     HZ_WORD_CONDITIONS_PKG.set_gbl_condition_rec ('||l_cond_attrib_list(l_idx)||','||'H_TX'||l_idx||'(I));');
      l_idx := l_idx+1;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_custom_list(I) <> 'N' AND l_mincol_list(I) = 'Y' THEN
        l('         H_TX'||I||'(I):='||l_custom_list(I)||';');
      END IF;
    END IF;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_mincol_list(I) <> 'Y' THEN
        l('         H_TX'||I||'(I):='||l_forall_list(I)||';');
      END IF;
    END IF;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_mincol_list(I) = 'Y' THEN
        l('         H_TX'||I||'(I):='||l_forall_list(I)||';');
      END IF;
    END IF;
  END LOOP;
  FIRST := TRUE;
  FOR ATTRS IN (SELECT a.ATTRIBUTE_ID,
                       a.ATTRIBUTE_NAME,
                       a.SOURCE_TABLE,
                       a.CUSTOM_ATTRIBUTE_PROCEDURE,
                       f.PROCEDURE_NAME,
                       f.STAGED_ATTRIBUTE_COLUMN,
                       to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3)) COLNUM
                FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
                WHERE ENTITY_NAME = 'CONTACT_POINTS'
                AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
                AND nvl(a.DENORM_FLAG,'N') = 'Y') LOOP
     IF FIRST THEN
     -- Fix for bug 4778420
     -- Wrapping the 'l_denorm' portion of code into a begin-excpetion block
     -- and setting the denorm value to 'SYNC' if sqlcode-6502 error occurs
       l('      BEGIN ');
       l('        l_denorm := H_TX'||ATTRS.COLNUM||'(I)');
       FIRST := FALSE;
     ELSE
       l('                  || '' '' || H_TX'||ATTRS.COLNUM||'(I)');
     END IF;
  END LOOP;
  IF NOT FIRST THEN
    l('             ;');
    l('        IF H_CPT_DEN(H_PARTY_INDEX(I)) = ''SYNC'' THEN');
    l('          NULL;');
    l('        ELSIF lengthb(H_CPT_DEN(H_PARTY_INDEX(I)))+lengthb(l_denorm)<2000 THEN');
    l('          IF H_CPT_DEN(H_PARTY_INDEX(I)) IS NULL OR instrb(H_CPT_DEN(H_PARTY_INDEX(I)),l_denorm)= 0 THEN');
    l('            H_CPT_DEN(H_PARTY_INDEX(I)) := H_CPT_DEN(H_PARTY_INDEX(I)) || '' '' || l_denorm;');
    l('          END IF;');
    l('        ELSE');
    l('           H_CPT_DEN(H_PARTY_INDEX(I)) := ''SYNC'';');
    l('        END IF;');
    l('      EXCEPTION WHEN OTHERS THEN ');
    l('        IF SQLCODE=-6502 THEN');
    l('          H_CPT_DEN(H_PARTY_INDEX(I)) := ''SYNC'';');
    l('        END IF; ');
    l('      END; ');    
  END IF;
  l('    END LOOP;');
  l('      l_st := 1;  ');
  l('      l_en := H_CPT_PARTY_ID.COUNT; ');
  l('      LOOP ');
  l('          BEGIN  ');
  l('              FORALL I in l_st..l_en');
  l('                INSERT INTO HZ_STAGED_CONTACT_POINTS (');
  l('	               CONTACT_POINT_ID');
  l('	               ,PARTY_ID');
  l('	               ,PARTY_SITE_ID');
  l('	               ,ORG_CONTACT_ID');
  l('	               ,CONTACT_POINT_TYPE');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      l('                   , TX'||I);
    END IF;
  END LOOP;
  l('                   ) VALUES (');
  l('                   H_CONTACT_POINT_ID(I)');
  l('                   ,H_CPT_PARTY_ID(I)');
  l('                   ,H_CPT_PARTY_SITE_ID(I)');
  l('                   ,H_CPT_ORG_CONTACT_ID(I)');
  l('                   ,H_CONTACT_POINT_TYPE(I)');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      l('                  , decode(H_TX'||I||'(I),null,H_TX'||I||'(I),H_TX'||I||'(I)||'' '')');
    END IF;
  END LOOP;
  l('          );');
  l('        EXIT; ');
  l('        EXCEPTION  WHEN OTHERS THEN ');
  l('            l_st:= l_st+SQL%ROWCOUNT+1;');
  l('        END; ');
  l('      END LOOP; ');
  l('      IF l_last_fetch THEN');
  l('        EXIT;');
  l('      END IF;');
  l('    END LOOP;');
  l('    CLOSE contact_pt_cur;');
  l('  END;');

  l('  PROCEDURE sync_single_contact_point (');
  l('    p_contact_point_id NUMBER,');
  l('    p_operation VARCHAR2) IS');
  l('');
  l('  l_tryins BOOLEAN;');
  l('  l_tryupd BOOLEAN;');
  l('   BEGIN');
  l('     SELECT cp.CONTACT_POINT_ID, d.PARTY_ID, d.PARTY_SITE_ID, d.ORG_CONTACT_ID, cp.CONTACT_POINT_TYPE ');
  FOR I in 1..l_select.COUNT LOOP
    IF l_select(I) <> 'N' THEN
      l('            ,' || l_select(I));
    END IF;
  END LOOP;
  l('      INTO H_CONTACT_POINT_ID(1),H_PARTY_ID(1), H_PARTY_SITE_ID(1),H_ORG_CONTACT_ID(1),H_CONTACT_POINT_TYPE(1)');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' AND l_mincol_list(I) = 'Y' AND
       l_custom_list(I) = 'N' THEN
      l('         , H_TX'||I||'(1)');
    END IF;
  END LOOP;
  l('     FROM HZ_CONTACT_POINTS cp, HZ_DQM_SYNC_INTERFACE d ');
  l('     WHERE  d.ENTITY = ''CONTACT_POINTS'' ');
  l('     AND cp.contact_point_id  =  p_contact_point_id ');
  l('     AND cp.contact_point_id  =  d.RECORD_ID ');
  l('     AND (cp.status is null OR cp.status = ''A'' or cp.status = ''I'') and rownum = 1 ; ');
   -- VJN INTRODUCED CODE FOR GENERATING THE POPULATION
  -- OF THE GLOBAL CONDITION RECORD

  l_idx := l_cond_attrib_list.FIRST ;
  IF l_idx IS NOT NULL
  THEN
    l('----------- SETTING GLOBAL CONDITION RECORD AT THE CONTACT POINT LEVEL ---------');
  END IF ;


  WHILE l_cond_attrib_list.EXISTS(l_idx)
  LOOP

      l('     HZ_WORD_CONDITIONS_PKG.set_gbl_condition_rec ('||l_cond_attrib_list(l_idx)||','||'H_TX'||l_idx||'(1));');
      l_idx := l_idx+1;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_custom_list(I) <> 'N' AND l_mincol_list(I) = 'Y' THEN
        l('    H_TX'||I||'(1):='||replace(l_custom_list(I),'(I)','(1)')||';');
      END IF;
    END IF;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_mincol_list(I) <> 'Y' THEN
        l('    H_TX'||I||'(1):='||replace(l_forall_list(I),'(I)','(1)')||';');
      END IF;
    END IF;
  END LOOP;
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      IF l_mincol_list(I) = 'Y' THEN
        l('    H_TX'||I||'(1):='||replace(l_forall_list(I),'(I)','(1)')||';');
      END IF;
    END IF;
  END LOOP;
  l('   l_tryins := FALSE;');
  l('   l_tryupd := FALSE;');
  l('   IF p_operation=''C'' THEN');
  l('     l_tryins:=TRUE;');
  l('   ELSE ');
  l('     l_tryupd:=TRUE;');
  l('   END IF;');
  l('   WHILE (l_tryins OR l_tryupd) LOOP');
  l('     IF l_tryins THEN');
  l('       BEGIN');
  l('         l_tryins:=FALSE;');
  l('         INSERT INTO HZ_STAGED_CONTACT_POINTS (');
  l('           CONTACT_POINT_ID');
  l('           ,PARTY_ID');
  l('           ,PARTY_SITE_ID');
  l('           ,ORG_CONTACT_ID');
  l('           ,CONTACT_POINT_TYPE');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      l('              , TX'||I);
    END IF;
  END LOOP;
  l('           ) VALUES (');
  l('             H_CONTACT_POINT_ID(1)');
  l('            ,H_PARTY_ID(1)');
  l('            ,H_PARTY_SITE_ID(1)');
  l('            ,H_ORG_CONTACT_ID(1)');
  l('            ,H_CONTACT_POINT_TYPE(1)');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
      l('             , decode(H_TX'||I||'(1),null,H_TX'||I||'(1),H_TX'||I||'(1)||'' '')');
    END IF;
  END LOOP;
  l('         );');
  l('       EXCEPTION');
  l('         WHEN DUP_VAL_ON_INDEX THEN');
  l('           IF p_operation=''C'' THEN');
  l('             l_tryupd:=TRUE;');
  l('           END IF;');
  l('       END;');
  l('     END IF;');
  l('     IF l_tryupd THEN');
  l('       BEGIN');
  l('         l_tryupd:=FALSE;');
  l('         UPDATE HZ_STAGED_CONTACT_POINTS SET ');
  FOR I IN 1..255 LOOP
    IF l_forall_list(I) <> 'N' THEN
   	IF (is_first) THEN
	      is_first := false;
	      l('            TX'||I||'=decode(H_TX'||I||'(1),null,H_TX'||I||'(1),H_TX'||I||'(1)||'' '')');
	ELSE
	      l('            ,TX'||I||'=decode(H_TX'||I||'(1),null,H_TX'||I||'(1),H_TX'||I||'(1)||'' '')');
	END IF;
    END IF;
  END LOOP;
  l('         WHERE CONTACT_POINT_ID=H_CONTACT_POINT_ID(1);');
  l('         IF SQL%ROWCOUNT=0 AND p_operation=''U'' THEN');
  l('           l_tryins := TRUE;');
  l('         END IF;');
  l('       EXCEPTION ');
  l('         WHEN NO_DATA_FOUND THEN');
  l('           IF p_operation=''U'' THEN');
  l('             l_tryins := TRUE;');
  l('           END IF;');
  l('       END;');
  l('     END IF;');
  l('   END LOOP;');
  l('   UPDATE HZ_STAGED_PARTIES set');
  l('   D_CPT = ''SYNC''');
  l('   WHERE PARTY_ID = H_PARTY_ID(1);');
  l('  END;');
END;

PROCEDURE generate_party_query_upd(
  x_rebuild_party_idx OUT NOCOPY BOOLEAN) IS
 cur_col_num NUMBER := 1;

 TYPE coltab IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;

 l_org_select coltab;
 l_per_select coltab;
 l_oth_select coltab;

 l_forall_list coltab;
 l_custom_list coltab;
 l_mincol_list coltab;
 l_min_colnum NUMBER;
 idx NUMBER :=1;
 FIRST BOOLEAN;
-- VJN Introduced for conditional word replacements
 l_cond_attrib_list coltab ;
 l_idx number ;

BEGIN
  l('  PROCEDURE open_party_cursor( ');
  l('    p_party_type	IN	VARCHAR2,');
  l('    p_worker_number IN	NUMBER,');
  l('    p_num_workers	IN	NUMBER,');
  l('    x_party_cur	IN OUT	HZ_PARTY_STAGE.StageCurTyp) IS ');
  l('');
  l('    l_party_type VARCHAR2(255);');
  l('  BEGIN');

  FOR ATTRS IN (SELECT a.ATTRIBUTE_ID,
                       a.ATTRIBUTE_NAME,
                       a.SOURCE_TABLE,
                       a.CUSTOM_ATTRIBUTE_PROCEDURE,
                       f.PROCEDURE_NAME,
                       f.STAGED_ATTRIBUTE_COLUMN,
                       to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3)) COLNUM
                FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
                WHERE ENTITY_NAME = 'PARTY'
                AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
                AND f.STAGED_FLAG='N'
                ORDER BY COLNUM) LOOP
    IF cur_col_num<ATTRS.COLNUM THEN
      FOR I in cur_col_num..ATTRS.COLNUM-1 LOOP
        l_mincol_list(I) := 'N';
        l_forall_list(I) := 'N';
      END LOOP;
    END IF;
    cur_col_num:=ATTRS.COLNUM+1;
    IF has_trx_context(ATTRS.PROCEDURE_NAME) THEN
      l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||ATTRS.COLNUM||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''PARTY'',''STAGE'')';
    ELSE
      l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||ATTRS.COLNUM||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''PARTY'')';
    END IF;

    l_mincol_list(ATTRS.COLNUM) := 'N';
    IF ATTRS.CUSTOM_ATTRIBUTE_PROCEDURE IS NULL THEN
      IF ATTRS.SOURCE_TABLE='HZ_ORGANIZATION_PROFILES' THEN
        l_org_select(idx) := 'op.'||ATTRS.ATTRIBUTE_NAME;
        l_per_select(idx) := 'NULL';
        l_oth_select(idx) := 'NULL';
      ELSIF ATTRS.SOURCE_TABLE='HZ_PERSON_PROFILES' THEN
        l_per_select(idx) := 'pe.'||ATTRS.ATTRIBUTE_NAME;
        l_org_select(idx) := 'NULL';
        l_oth_select(idx) := 'NULL';
      ELSIF ATTRS.SOURCE_TABLE='HZ_PERSON_PROFILES, HZ_ORGANIZATION_PROFILES' OR
            ATTRS.SOURCE_TABLE='HZ_ORGANIZATION_PROFILES, HZ_PERSON_PROFILES' THEN
        l_org_select(idx) := 'op.'||ATTRS.ATTRIBUTE_NAME;
        l_per_select(idx) := 'pe.'||ATTRS.ATTRIBUTE_NAME;
        l_oth_select(idx) := 'NULL';
      ELSE
        l_org_select(idx) := 'p.'||ATTRS.ATTRIBUTE_NAME;
        l_per_select(idx) := 'p.'||ATTRS.ATTRIBUTE_NAME;
        l_oth_select(idx) := 'p.'||ATTRS.ATTRIBUTE_NAME;
      END IF;
    ELSE
        SELECT min(to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3))) INTO l_min_colnum
        FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
        WHERE ENTITY_NAME = 'PARTY'
        AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
        AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
        AND a.ATTRIBUTE_NAME=ATTRS.ATTRIBUTE_NAME
        AND f.STAGED_FLAG='N';

        l_org_select(idx) := 'NULL';
        l_oth_select(idx) := 'NULL';
        l_per_select(idx) := 'NULL';
        IF ATTRS.colnum>l_min_colnum THEN
         IF has_trx_context(ATTRS.PROCEDURE_NAME) THEN
           l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||l_min_colnum||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''PARTY'',''STAGE'')';
         ELSE
           l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||l_min_colnum||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''PARTY'')';
         END IF;

          l_mincol_list(ATTRS.COLNUM) := 'N';
        ELSE
          l_mincol_list(ATTRS.COLNUM) := 'Y';
          IF has_context(ATTRS.custom_attribute_procedure) THEN
            l_custom_list(ATTRS.COLNUM) := ATTRS.custom_attribute_procedure || '(H_PARTY_ID(I),''PARTY'','''||ATTRS.ATTRIBUTE_NAME|| ''', ''STAGE'')';
          ELSE
            l_custom_list(ATTRS.COLNUM) := ATTRS.custom_attribute_procedure || '(H_PARTY_ID(I), ''PARTY'','''||ATTRS.ATTRIBUTE_NAME|| ''')';
          END IF;
        END IF;
    END IF;
    idx := idx+1;
    -- VJN ADDED CODE FOR TRACKING CONDITION ATTRIBUTES AT THIS ENTITY LEVEL
    IF HZ_WORD_CONDITIONS_PKG.is_a_cond_attrib( ATTRS.attribute_id)
     THEN
         l_cond_attrib_list(ATTRS.COLNUM) := ATTRS.attribute_id ;
    END IF;

  END LOOP;
  IF idx=1 THEN
    x_rebuild_party_idx:=FALSE;
    l('    RETURN;');
    l('  END;');
  ELSE
    x_rebuild_party_idx:=check_rebuild('PARTY');

    IF cur_col_num<255 THEN
      FOR I in cur_col_num..255 LOOP
        l_mincol_list(I) := 'N';
        l_forall_list(I) := 'N';
      END LOOP;
    END IF;

    l('    IF p_party_type = ''ORGANIZATION'' THEN');
    l('      open x_party_cur FOR ' );
    l('        SELECT p.PARTY_ID ');
    FOR I in 1..l_org_select.COUNT LOOP
      l('              ,' || l_org_select(I));
    END LOOP;

    l('        FROM HZ_STAGED_PARTIES s, HZ_PARTIES p, HZ_ORGANIZATION_PROFILES op ');
    l('        WHERE s.PARTY_ID = p.PARTY_ID ');
    l('        AND mod(p.PARTY_ID, p_num_workers) = p_worker_number ');
    l('        AND p.party_id = op.party_id ');
    l('        AND op.effective_end_date is NULL; ');
    l('    ELSIF p_party_type = ''PERSON'' THEN');
    l('      open x_party_cur FOR ' );
    l('        SELECT p.PARTY_ID ');
    FOR I in 1..l_per_select.COUNT LOOP
      l('              ,' || l_per_select(I));
    END LOOP;
    l('        FROM HZ_STAGED_PARTIES s,HZ_PARTIES p, HZ_PERSON_PROFILES pe ');
    l('        WHERE s.PARTY_ID = p.PARTY_ID ');
    l('        AND mod(p.PARTY_ID, p_num_workers) = p_worker_number ');
    l('        AND p.party_id = pe.party_id ');
    l('        AND pe.effective_end_date is NULL; ');
    l('    ELSE');
    l('      open x_party_cur FOR ' );
    l('        SELECT p.PARTY_ID ');
    FOR I in 1..l_oth_select.COUNT LOOP
      l('              ,' || l_oth_select(I));
    END LOOP;
    l('        FROM HZ_STAGED_PARTIES s, HZ_PARTIES p ');
    l('        WHERE s.PARTY_ID = p.PARTY_ID ');
    l('        AND mod(p.PARTY_ID, p_num_workers) = p_worker_number ');
    l('        AND p.party_type <> ''PERSON'' ');
    l('        AND p.party_type <> ''ORGANIZATION'' ');
    l('        AND p.party_type <> ''PARTY_RELATIONSHIP''; ');
    l('    END IF;');
    l('  END;');
  END IF;

  l('  PROCEDURE update_stage_parties ( ');
  l('    p_party_cur    IN HZ_PARTY_STAGE.StageCurTyp) IS ');
  l('  l_limit NUMBER := ' || g_batch_size || ';');
  l(' l_last_fetch BOOLEAN := FALSE;');
  l('');
  l('  BEGIN');
  IF idx=1 THEN
    l('      RETURN;');
    l('  END;');
  ELSE
    l('    LOOP');
    l('      FETCH p_party_cur BULK COLLECT INTO');
    l('        H_PARTY_ID');
    FOR I IN 1..255 LOOP
      IF l_forall_list(I) <> 'N' THEN
        l('         ,H_TX'||I);
      END IF;
    END LOOP;
    l('      LIMIT l_limit;');
    l('');
    l('    IF p_party_cur%NOTFOUND THEN');
    l('      l_last_fetch:=TRUE;');
    l('    END IF;');

    l('    IF H_PARTY_ID.COUNT=0 AND l_last_fetch THEN');
    l('      EXIT;');
    l('    END IF;');

    l('    FOR I in H_PARTY_ID.FIRST..H_PARTY_ID.LAST LOOP');
  -- VJN INTRODUCED CODE FOR GENERATING THE POPULATION
  -- OF THE GLOBAL CONDITION RECORD

  l_idx := l_cond_attrib_list.FIRST ;
  IF l_idx IS NOT NULL
  THEN
    l('----------- SETTING GLOBAL CONDITION RECORD AT THE PARTY LEVEL ---------');
  END IF ;


  WHILE l_cond_attrib_list.EXISTS(l_idx)
  LOOP

      l('     HZ_WORD_CONDITIONS_PKG.set_gbl_condition_rec ('||l_cond_attrib_list(l_idx)||','||'H_TX'||l_idx||'(I));');
      l_idx := l_idx+1;
  END LOOP;
    FOR I IN 1..255 LOOP
      IF l_forall_list(I) <> 'N' THEN
        IF l_mincol_list(I) = 'Y' THEN
          l('         H_TX'||I||'(I):='||l_custom_list(I)||';');
        END IF;
      END IF;
    END LOOP;
    FOR I IN 1..255 LOOP
      IF l_forall_list(I) <> 'N' THEN
        IF l_mincol_list(I) <> 'Y' THEN
          l('         H_TX'||I||'(I):='||l_forall_list(I)||';');
        END IF;
      END IF;
    END LOOP;
    FOR I IN 1..255 LOOP
      IF l_forall_list(I) <> 'N' THEN
        IF l_mincol_list(I) = 'Y' THEN
          l('         H_TX'||I||'(I):='||l_forall_list(I)||';');
        END IF;
      END IF;
    END LOOP;
    l('    END LOOP;');

    l('    FORALL I in H_PARTY_ID.FIRST..H_PARTY_ID.LAST');
    l('      UPDATE HZ_STAGED_PARTIES SET ');
    FIRST:=TRUE;
    FOR I IN 1..255 LOOP
      IF l_forall_list(I) <> 'N' THEN
          IF (FIRST) THEN
	        FIRST := false;
                l('            TX'||I||'=decode(H_TX'||I||'(I),null,H_TX'||I||'(I),H_TX'||I||'(I)||'' '')');
          ELSE
                l('            ,TX'||I||'=decode(H_TX'||I||'(I),null,H_TX'||I||'(I),H_TX'||I||'(I)||'' '')');
          END IF;
      END IF;
    END LOOP;
    l('      WHERE PARTY_ID=H_PARTY_ID(I);');
    l('      IF l_last_fetch THEN');
    l('        FND_CONCURRENT.AF_Commit;');
    l('        EXIT;');
    l('      END IF;');
    l('      FND_CONCURRENT.AF_Commit;');
    l('    END LOOP;');
    l('  END;');
  END IF;
END;


PROCEDURE generate_contact_query_upd(
  x_rebuild_contact_idx OUT NOCOPY BOOLEAN) IS
 cur_col_num NUMBER := 1;

 TYPE coltab IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;

 l_select coltab;

 l_forall_list coltab;
 l_custom_list coltab;
 l_mincol_list coltab;
 l_min_colnum NUMBER;
 idx NUMBER :=1;
 FIRST BOOLEAN;
-- VJN Introduced for conditional word replacements
 l_cond_attrib_list coltab ;
 l_idx number ;

BEGIN
 log('Generating upd procedures for CONTACTS' );
 IF new_transformations_exist('CONTACTS') = TRUE
                      OR
     ( new_transformations_exist('CONTACTS') = FALSE AND get_missing_denorm_attrib_cols('CONTACTS') IS NULL )
  THEN
                    log('If block of code -- new transformations exist or there are no missing denorm attrib columns' );
                    l('  PROCEDURE open_contact_cursor( ');
                    l('    p_worker_number IN	NUMBER,');
                    l('    p_num_workers	IN	NUMBER,');
                    l('    x_contact_cur	IN OUT	HZ_PARTY_STAGE.StageCurTyp) IS ');
                    l('');
                    l('  BEGIN');

                    FOR ATTRS IN (SELECT a.ATTRIBUTE_ID,
                                         a.ATTRIBUTE_NAME,
                                         a.SOURCE_TABLE,
                                         a.CUSTOM_ATTRIBUTE_PROCEDURE,
                                         f.PROCEDURE_NAME,
                                         f.STAGED_ATTRIBUTE_COLUMN,
                                         to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3)) COLNUM
                                  FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
                                  WHERE ENTITY_NAME = 'CONTACTS'
                                  AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                                  AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
                                  AND f.staged_flag='N'
                                  ORDER BY COLNUM) LOOP
                      IF cur_col_num<ATTRS.COLNUM THEN
                        FOR I in cur_col_num..ATTRS.COLNUM-1 LOOP
                          l_mincol_list(I) := 'N';
                          l_forall_list(I) := 'N';
                        END LOOP;
                      END IF;
                      cur_col_num:=ATTRS.COLNUM+1;
                      IF has_trx_context(ATTRS.PROCEDURE_NAME) THEN
                        l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||ATTRS.COLNUM||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''CONTACTS'',''STAGE'')';
                      ELSE
                        l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||ATTRS.COLNUM||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''CONTACTS'')';
                      END IF;

                      l_mincol_list(ATTRS.COLNUM) := 'N';
                      IF ATTRS.CUSTOM_ATTRIBUTE_PROCEDURE IS NULL THEN
                        IF ATTRS.SOURCE_TABLE='HZ_PERSON_PROFILES' THEN
                          l_select(idx) := 'pp.'||ATTRS.ATTRIBUTE_NAME;
                        ELSIF ATTRS.SOURCE_TABLE='HZ_ORG_CONTACTS' THEN
                          l_select(idx) := 'oc.'||ATTRS.ATTRIBUTE_NAME;
                        ELSIF ATTRS.SOURCE_TABLE='HZ_RELATIONSHIPS' THEN
                          l_select(idx) := 'r.'||ATTRS.ATTRIBUTE_NAME;
                        END IF;
                      ELSE
                          SELECT min(to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3))) INTO l_min_colnum
                          FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
                          WHERE ENTITY_NAME = 'CONTACTS'
                          AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                          AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
                          AND a.ATTRIBUTE_NAME=ATTRS.ATTRIBUTE_NAME
                          AND f.staged_flag='N';

                          l_select(idx) := 'NULL';
                          IF ATTRS.colnum>l_min_colnum THEN
                            IF has_trx_context(ATTRS.PROCEDURE_NAME) THEN
                              l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||l_min_colnum||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''CONTACTS'',''STAGE'')';
                            ELSE
                              l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||l_min_colnum||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''CONTACTS'')';
                            END IF;

                            l_mincol_list(ATTRS.COLNUM) := 'N';
                          ELSE
                            l_mincol_list(ATTRS.COLNUM) := 'Y';
                            IF has_context(ATTRS.custom_attribute_procedure) THEN
                              l_custom_list(ATTRS.COLNUM) := ATTRS.custom_attribute_procedure || '(H_ORG_CONTACT_ID(I),''CONTACTS'','''||ATTRS.ATTRIBUTE_NAME|| ''', ''STAGE'')';
                            ELSE
                              l_custom_list(ATTRS.COLNUM) := ATTRS.custom_attribute_procedure || '(H_ORG_CONTACT_ID(I), ''CONTACTS'','''||ATTRS.ATTRIBUTE_NAME|| ''')';
                            END IF;
                          END IF;
                      END IF;
                      idx := idx+1;
                      -- VJN ADDED CODE FOR TRACKING CONDITION ATTRIBUTES AT THIS ENTITY LEVEL
                      IF HZ_WORD_CONDITIONS_PKG.is_a_cond_attrib( ATTRS.attribute_id)
                      THEN
                            l_cond_attrib_list(ATTRS.COLNUM) := ATTRS.attribute_id ;
                      END IF;

                    END LOOP;

                    IF idx=1 THEN
                      x_rebuild_contact_idx:=FALSE;
                      l('    RETURN;');
                      l('  END;');
                    ELSE
                      x_rebuild_contact_idx:=check_rebuild('CONTACTS');
                      IF cur_col_num<255 THEN
                        FOR I in cur_col_num..255 LOOP
                          l_mincol_list(I) := 'N';
                          l_forall_list(I) := 'N';
                        END LOOP;
                      END IF;

                      l('        open x_contact_cur FOR');
                      l('            SELECT oc.ORG_CONTACT_ID ');
                      FOR I in 1..l_select.COUNT LOOP
                        l('                  ,' || l_select(I));
                      END LOOP;
                      l('           FROM HZ_STAGED_CONTACTS s, HZ_ORG_CONTACTS oc, ');
                      l('           HZ_RELATIONSHIPS r, HZ_PERSON_PROFILES pp');
                      l('           WHERE mod(s.PARTY_ID, p_num_workers) = p_worker_number ');
                      l('           AND s.ORG_CONTACT_ID=oc.ORG_CONTACT_ID');
                      l('           AND oc.party_relationship_id =  r.relationship_id ');
                      l('           AND r.object_id = s.party_id ');
                      l('           AND r.subject_id = pp.party_id ');
                      l('           AND r.SUBJECT_TABLE_NAME = ''HZ_PARTIES''');
                      l('           AND r.OBJECT_TABLE_NAME = ''HZ_PARTIES''');
                      l('           AND DIRECTIONAL_FLAG= ''F'' ');
                      l('           AND pp.effective_end_date is NULL ');
                      l('           AND (oc.status is null OR oc.status = ''A'' or oc.status = ''I'')');
                      l('           AND (r.status is null OR r.status = ''A'' or r.status = ''I'');');
                      l('  END;');
                    END IF;

                    l('  PROCEDURE update_stage_contacts ( ');
                    l('    p_contact_cur    IN HZ_PARTY_STAGE.StageCurTyp) IS ');
                    l('  l_limit NUMBER := ' || g_batch_size || ';');
                    l('  H_DENORM_PARTY_ID NumberList ;');
                    l('  H_DENORM_VALUE CharList ;');
                    l('  H_ROW_OFFSET Number ;');
                    l(' l_last_fetch BOOLEAN := FALSE;');
                    l('');
                    l('  BEGIN');
                    IF idx=1 THEN
                      l('      RETURN;');
                      l('  END;');
                    ELSE
                      l('    LOOP');
                      l('      H_ROW_OFFSET := 1 ;');
                      l('      FETCH p_contact_cur BULK COLLECT INTO');
                      l('        H_ORG_CONTACT_ID');
                      FOR I IN 1..255 LOOP
                        IF l_forall_list(I) <> 'N' THEN
                          l('         ,H_TX'||I);
                        END IF;
                      END LOOP;
                      l('      LIMIT l_limit;');
                      l('');
                      l('    IF p_contact_cur%NOTFOUND THEN');
                      l('      l_last_fetch:=TRUE;');
                      l('    END IF;');

                      l('    IF H_ORG_CONTACT_ID.COUNT=0 AND l_last_fetch THEN');
                      l('      EXIT;');
                      l('    END IF;');

                      l('    FOR I in H_ORG_CONTACT_ID.FIRST..H_ORG_CONTACT_ID.LAST LOOP');
                       -- VJN INTRODUCED CODE FOR GENERATING THE POPULATION
                      -- OF THE GLOBAL CONDITION RECORD

                      l_idx := l_cond_attrib_list.FIRST ;
                      IF l_idx IS NOT NULL
                      THEN
                            l('----------- SETTING GLOBAL CONDITION RECORD AT THE CONTACT LEVEL ---------');
                      END IF ;


                      WHILE l_cond_attrib_list.EXISTS(l_idx)
                      LOOP

                        l('     HZ_WORD_CONDITIONS_PKG.set_gbl_condition_rec ('||l_cond_attrib_list(l_idx)||','||'H_TX'||l_idx||'(I));');
                        l_idx := l_idx+1;
                       END LOOP;
                      FOR I IN 1..255 LOOP
                        IF l_forall_list(I) <> 'N' THEN
                          IF l_mincol_list(I) = 'Y' THEN
                            l('         H_TX'||I||'(I):='||l_custom_list(I)||';');
                          END IF;
                        END IF;
                      END LOOP;
                      FOR I IN 1..255 LOOP
                        IF l_forall_list(I) <> 'N' THEN
                          IF l_mincol_list(I) <> 'Y' THEN
                            l('         H_TX'||I||'(I):='||l_forall_list(I)||';');
                          END IF;
                        END IF;
                      END LOOP;
                      FOR I IN 1..255 LOOP
                        IF l_forall_list(I) <> 'N' THEN
                          IF l_mincol_list(I) = 'Y' THEN
                            l('         H_TX'||I||'(I):='||l_forall_list(I)||';');
                          END IF;
                        END IF;
                      END LOOP;
                      l('    END LOOP;');

                      l('    FORALL I in H_ORG_CONTACT_ID.FIRST..H_ORG_CONTACT_ID.LAST');
                      l('      UPDATE HZ_STAGED_CONTACTS SET ');
                      FIRST:=TRUE;
                      FOR I IN 1..255 LOOP
                        IF l_forall_list(I) <> 'N' THEN
                  	IF (FIRST) THEN
                               FIRST := false;
                               l('            TX'||I||'=decode(H_TX'||I||'(I),null,H_TX'||I||'(I),H_TX'||I||'(I)||'' '')');
                  	ELSE
                               l('            ,TX'||I||'=decode(H_TX'||I||'(I),null,H_TX'||I||'(I),H_TX'||I||'(I)||'' '')');
                  	END IF;

                        END IF;
                      END LOOP;

                      l('        WHERE ORG_CONTACT_ID = H_ORG_CONTACT_ID(I)');
                      -- ADD CODE FOR UPDATING HZ_STAGED_PARTIES IF THERE ARE ANY NEW CONTACT DENORM ATTRIBUTES
                      IF get_missing_denorm_attrib_cols('CONTACTS') IS NOT NULL
                      THEN
                           l('RETURNING PARTY_ID, ');
                           l(get_missing_denorm_attrib_cols('CONTACTS'));
                           -- THIS BULK COLLECT WILL CHOSE THE PARTY ID COLUMNS OF THE ROWS THAT ARE UPDATED
                           -- AND UPDATE THESE PARTY IDS IN HZ_STAGED_PARTIES, BY APPENDING TO THE D_CT COLUMNS
                           -- VALUES FROM THE NEW DENORM ATTRIBUTE COLUMNS
                           l('BULK COLLECT INTO  H_DENORM_PARTY_ID, H_DENORM_VALUE ;');
                           l('LOOP');
        		           l('BEGIN');
        			       l('   FORALL I IN H_ROW_OFFSET..H_DENORM_PARTY_ID.COUNT');
        			       l('           UPDATE HZ_STAGED_PARTIES');
        				   l('           SET D_CT = D_CT||'' ''||H_DENORM_VALUE(I)');
        			       l('           WHERE PARTY_ID = H_DENORM_PARTY_ID(I) AND D_CT <> ''SYNC'' ;');
                           l('EXIT ;');
        			       l('EXCEPTION');
        			       l('WHEN OTHERS THEN');
        			       l('           H_ROW_OFFSET := H_ROW_OFFSET+SQL%ROWCOUNT;');
                           l('           UPDATE HZ_STAGED_PARTIES');
        				   l('           SET D_CT = ''SYNC'' ');
        				   l('           WHERE PARTY_ID = H_DENORM_PARTY_ID(H_ROW_OFFSET) ;');
                           l('           H_ROW_OFFSET := H_ROW_OFFSET+1 ;');
        		           l('END ;');
                           l('END LOOP ;');
                      ELSE
                           l(';');
                      END IF ;

                      l('      IF l_last_fetch THEN');
                      l('        FND_CONCURRENT.AF_Commit;');
                      l('        EXIT;');
                      l('      END IF;');
                      l('      FND_CONCURRENT.AF_Commit;');
                      l('    END LOOP;');
                      l('  END;');
                END IF ;
-- NO NEW TRANSFORMATIONS BUT THERE ARE SOME NEW DENORM ATTRIBUTES
ELSE
                    log('Else block of code -- No new transformations exist' );
                    l('  PROCEDURE open_contact_cursor( ');
                    l('    p_worker_number IN	NUMBER,');
                    l('    p_num_workers	IN	NUMBER,');
                    l('    x_contact_cur	IN OUT	HZ_PARTY_STAGE.StageCurTyp) IS ');
                    l('');
                    l('  BEGIN');
                    l('    open x_contact_cur FOR');
                    l('      SELECT ct.PARTY_ID,');
                    l(get_missing_denorm_attrib_cols('CONTACTS'));
                    l('      FROM HZ_STAGED_CONTACTS ct');
                    l('      WHERE mod(ct.PARTY_ID, p_num_workers) = p_worker_number ; ');
                    l('  END;');

                    l('  PROCEDURE update_stage_contacts ( ');
                    l('    p_contact_cur    IN HZ_PARTY_STAGE.StageCurTyp) IS ');
                    l('  l_limit NUMBER := ' || g_batch_size || ';');
                    l('  H_DENORM_PARTY_ID NumberList ;');
                    l('  H_DENORM_VALUE CharList ;');
                    l('  H_ROW_OFFSET Number ;');
                    l(' l_last_fetch BOOLEAN := FALSE;');
                    l('');
                    l('  BEGIN');
                    l('    LOOP');
                    l('      H_ROW_OFFSET := 1 ; ');
                    l('      FETCH p_contact_cur BULK COLLECT INTO');
                    l('        H_DENORM_PARTY_ID, H_DENORM_VALUE');
                    l('      LIMIT l_limit;');
                    l('');
                    l('    IF p_contact_cur%NOTFOUND THEN');
                    l('      l_last_fetch:=TRUE;');
                    l('    END IF;');
                    l('    IF H_DENORM_PARTY_ID.COUNT=0 AND l_last_fetch THEN');
                    l('      EXIT;');
                    l('    END IF;');

                    l('LOOP');
  		            l('BEGIN');
  			        l('   FORALL I IN H_ROW_OFFSET..H_DENORM_PARTY_ID.COUNT');
  			        l('           UPDATE HZ_STAGED_PARTIES');
  				    l('           SET D_CT = D_CT||'' ''||H_DENORM_VALUE(I)');
  				    l('           WHERE PARTY_ID = H_DENORM_PARTY_ID(I) AND D_CT <> ''SYNC'' ;');
                    l('EXIT ;');
  			        l('EXCEPTION');
  			        l('WHEN OTHERS THEN');
  			        l('           H_ROW_OFFSET := H_ROW_OFFSET+SQL%ROWCOUNT;');
                    l('           UPDATE HZ_STAGED_PARTIES');
  				    l('           SET D_CT = ''SYNC'' ');
  				    l('           WHERE PARTY_ID = H_DENORM_PARTY_ID(H_ROW_OFFSET) ;');
                    l('           H_ROW_OFFSET := H_ROW_OFFSET+1 ;');
  		            l('END ;');
                    l('END LOOP ;');





                    l('        IF l_last_fetch THEN');
                    l('          FND_CONCURRENT.AF_Commit;');
                    l('          EXIT;');
                    l('        END IF;');
                    l('        FND_CONCURRENT.AF_Commit;');
                    l('    END LOOP ; ');
                    l('  END ; ');
END IF ;

END;


PROCEDURE generate_party_site_query_upd(
  x_rebuild_psite_idx OUT NOCOPY BOOLEAN) IS
 cur_col_num NUMBER := 1;

 TYPE coltab IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;

 l_select coltab;

 l_forall_list coltab;
 l_custom_list coltab;
 l_mincol_list coltab;
 l_min_colnum NUMBER;
 idx NUMBER :=1;
 FIRST BOOLEAN;
-- VJN Introduced for conditional word replacements
 l_cond_attrib_list coltab ;
 l_idx number ;

BEGIN
  log('Generating upd procedures for PARTY SITES' );
  IF new_transformations_exist('PARTY_SITES') = TRUE
                      OR
     ( new_transformations_exist('PARTY_SITES') = FALSE AND get_missing_denorm_attrib_cols('PARTY_SITES') IS NULL )
  THEN

                    log('If block of code -- new transformations exist or there are no missing denorm attrib columns' );
                    l('  PROCEDURE open_party_site_cursor( ');
                    l('    p_worker_number IN	NUMBER,');
                    l('    p_num_workers	IN	NUMBER,');
                    l('    x_party_site_cur	IN OUT	HZ_PARTY_STAGE.StageCurTyp) IS ');
                    l('');
                    l('  BEGIN');

                    FOR ATTRS IN (SELECT a.ATTRIBUTE_ID,
                                         a.ATTRIBUTE_NAME,
                                         a.SOURCE_TABLE,
                                         a.CUSTOM_ATTRIBUTE_PROCEDURE,
                                         f.PROCEDURE_NAME,
                                         f.STAGED_ATTRIBUTE_COLUMN,
                                         to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3)) COLNUM
                                  FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
                                  WHERE ENTITY_NAME = 'PARTY_SITES'
                                  AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                                  AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
                                  AND f.staged_flag='N'
                                  ORDER BY COLNUM) LOOP
                      IF cur_col_num<ATTRS.COLNUM THEN
                        FOR I in cur_col_num..ATTRS.COLNUM-1 LOOP
                          l_mincol_list(I) := 'N';
                          l_forall_list(I) := 'N';
                        END LOOP;
                      END IF;
                      cur_col_num:=ATTRS.COLNUM+1;
                      IF has_trx_context(ATTRS.PROCEDURE_NAME) THEN
                        l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||ATTRS.COLNUM||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''PARTY_SITES'',''STAGE'')';
                      ELSE
                        l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||ATTRS.COLNUM||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''PARTY_SITES'')';
                      END IF;

                      l_mincol_list(ATTRS.COLNUM) := 'N';
                      IF ATTRS.CUSTOM_ATTRIBUTE_PROCEDURE IS NULL THEN
                        IF ATTRS.SOURCE_TABLE='HZ_LOCATIONS' THEN
                          l_select(idx) := 'l.'||ATTRS.ATTRIBUTE_NAME;
                        ELSIF ATTRS.SOURCE_TABLE='HZ_PARTY_SITES' THEN
                          l_select(idx) := 'ps.'||ATTRS.ATTRIBUTE_NAME;
                        END IF;
                      ELSE
                          SELECT min(to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3))) INTO l_min_colnum
                          FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
                          WHERE ENTITY_NAME = 'PARTY_SITES'
                          AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                          AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
                          AND a.ATTRIBUTE_NAME=ATTRS.ATTRIBUTE_NAME
                          AND f.staged_flag='N';

                          l_select(idx) := 'NULL';
                          IF ATTRS.colnum>l_min_colnum THEN
                            IF has_trx_context(ATTRS.PROCEDURE_NAME) THEN
                              l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||l_min_colnum||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''PARTY_SITES'',''STAGE'')';
                            ELSE
                              l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||l_min_colnum||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''PARTY_SITES'')';
                            END IF;

                            l_mincol_list(ATTRS.COLNUM) := 'N';
                          ELSE
                            l_mincol_list(ATTRS.COLNUM) := 'Y';
                            IF has_context(ATTRS.custom_attribute_procedure) THEN
                              l_custom_list(ATTRS.COLNUM) := ATTRS.custom_attribute_procedure || '(H_PARTY_SITE_ID(I),''PARTY_SITES'','''||ATTRS.ATTRIBUTE_NAME|| ''', ''STAGE'')';
                            ELSE
                              l_custom_list(ATTRS.COLNUM) := ATTRS.custom_attribute_procedure || '(H_PARTY_SITE_ID(I), ''PARTY_SITES'','''||ATTRS.ATTRIBUTE_NAME|| ''')';
                            END IF;
                          END IF;
                      END IF;
                      idx := idx+1;
                      -- VJN ADDED CODE FOR TRACKING CONDITION ATTRIBUTES AT THIS ENTITY LEVEL
                      IF HZ_WORD_CONDITIONS_PKG.is_a_cond_attrib( ATTRS.attribute_id)
                      THEN
                            l_cond_attrib_list(ATTRS.COLNUM) := ATTRS.attribute_id ;
                      END IF;

                    END LOOP;

                    IF idx=1 THEN
                      x_rebuild_psite_idx:=FALSE;
                      l('    RETURN;');
                      l('  END;');
                    ELSE
                      x_rebuild_psite_idx:=check_rebuild('PARTY_SITES');
                      IF cur_col_num<255 THEN
                        FOR I in cur_col_num..255 LOOP
                          l_mincol_list(I) := 'N';
                          l_forall_list(I) := 'N';
                        END LOOP;
                      END IF;

                      l('    open x_party_site_cur FOR');
                      l('      SELECT ps.PARTY_SITE_ID ');
                      FOR I in 1..l_select.COUNT LOOP
                        l('            ,' || l_select(I));
                      END LOOP;
                      l('      FROM HZ_PARTY_SITES ps, HZ_STAGED_PARTY_SITES s, HZ_LOCATIONS l ');
                      l('      WHERE mod(s.PARTY_ID, p_num_workers) = p_worker_number ');
                      l('      AND ps.party_site_id = s.party_site_id ');
                      l('      AND ps.party_id = s.party_id ');
                      l('      AND ps.location_id = l.location_id; ');

                      l('  END;');
                    END IF;


                    l('  PROCEDURE update_stage_party_sites ( ');
                    l('    p_party_site_cur    IN HZ_PARTY_STAGE.StageCurTyp) IS ');
                    l('  l_limit NUMBER := ' || g_batch_size || ';');
                    l('  H_DENORM_PARTY_ID NumberList ;');
                    l('  H_DENORM_VALUE CharList ;');
                    l('  H_ROW_OFFSET Number ;');
                    l(' l_last_fetch BOOLEAN := FALSE;');
                    l('');
                    l('  BEGIN');
                    IF idx=1 THEN
                      l('      RETURN;');
                      l('  END;');
                    ELSE
                      l('    LOOP');
                      l('    H_ROW_OFFSET := 1 ;');
                      l('      FETCH p_party_site_cur BULK COLLECT INTO');
                      l('        H_PARTY_SITE_ID');
                      FOR I IN 1..255 LOOP
                        IF l_forall_list(I) <> 'N' THEN
                          l('         ,H_TX'||I);
                        END IF;
                      END LOOP;
                      l('      LIMIT l_limit;');
                      l('');
                      l('    IF p_party_site_cur%NOTFOUND THEN');
                      l('      l_last_fetch:=TRUE;');
                      l('    END IF;');

                      l('    IF H_PARTY_SITE_ID.COUNT=0 AND l_last_fetch THEN');
                      l('      EXIT;');
                      l('    END IF;');

                      l('    FOR I in H_PARTY_SITE_ID.FIRST..H_PARTY_SITE_ID.LAST LOOP');
                      -- VJN INTRODUCED CODE FOR GENERATING THE POPULATION
                      -- OF THE GLOBAL CONDITION RECORD

                      l_idx := l_cond_attrib_list.FIRST ;
                      IF l_idx IS NOT NULL
                      THEN
                            l('----------- SETTING GLOBAL CONDITION RECORD AT THE PARTY SITE LEVEL ---------');
                      END IF ;


                      WHILE l_cond_attrib_list.EXISTS(l_idx)
                      LOOP

                        l('     HZ_WORD_CONDITIONS_PKG.set_gbl_condition_rec ('||l_cond_attrib_list(l_idx)||','||'H_TX'||l_idx||'(I));');
                        l_idx := l_idx+1;
                       END LOOP;
                      FOR I IN 1..255 LOOP
                        IF l_forall_list(I) <> 'N' THEN
                          IF l_mincol_list(I) = 'Y' THEN
                            l('         H_TX'||I||'(I):='||l_custom_list(I)||';');
                          END IF;
                        END IF;
                      END LOOP;
                      FOR I IN 1..255 LOOP
                        IF l_forall_list(I) <> 'N' THEN
                          IF l_mincol_list(I) <> 'Y' THEN
                            l('         H_TX'||I||'(I):='||l_forall_list(I)||';');
                          END IF;
                        END IF;
                      END LOOP;
                      FOR I IN 1..255 LOOP
                        IF l_forall_list(I) <> 'N' THEN
                          IF l_mincol_list(I) = 'Y' THEN
                            l('         H_TX'||I||'(I):='||l_forall_list(I)||';');
                          END IF;
                        END IF;
                      END LOOP;
                      l('    END LOOP;');
                      l('    FORALL I in H_PARTY_SITE_ID.FIRST..H_PARTY_SITE_ID.LAST');
                      l('      UPDATE HZ_STAGED_PARTY_SITES SET');
                      FIRST := TRUE;
                      FOR I IN 1..255 LOOP
                        IF l_forall_list(I) <> 'N' THEN
                          IF (FIRST) THEN
                  	      FIRST := false;
                                l('            TX'||I||'=decode(H_TX'||I||'(I),null,H_TX'||I||'(I),H_TX'||I||'(I)||'' '')');
                          ELSE
                                l('            ,TX'||I||'=decode(H_TX'||I||'(I),null,H_TX'||I||'(I),H_TX'||I||'(I)||'' '')');
                          END IF;
                        END IF;
                      END LOOP;
                      l('        WHERE PARTY_SITE_ID=H_PARTY_SITE_ID(I)');

                      -- ADD CODE FOR UPDATING HZ_STAGED_PARTIES IF THERE ARE ANY NEW PARTY SITE DENORM ATTRIBUTES
                      IF get_missing_denorm_attrib_cols('PARTY_SITES') IS NOT NULL
                      THEN
                           l('RETURNING PARTY_ID, ');
                           l(get_missing_denorm_attrib_cols('PARTY_SITES'));
                           -- THIS BULK COLLECT WILL CHOSE THE PARTY ID COLUMNS OF THE ROWS THAT ARE UPDATED
                           -- AND UPDATE THESE PARTY IDS IN HZ_STAGED_PARTIES, BY APPENDING TO THE D_PS COLUMNS
                           -- VALUES FROM THE NEW DENORM ATTRIBUTE COLUMNS
                           l('BULK COLLECT INTO  H_DENORM_PARTY_ID, H_DENORM_VALUE ;');
                           l('LOOP');
		                   l('BEGIN');
			               l('   FORALL I IN H_ROW_OFFSET..H_DENORM_PARTY_ID.COUNT');
			               l('           UPDATE HZ_STAGED_PARTIES');
				           l('           SET D_PS = D_PS||'' ''||H_DENORM_VALUE(I)');
				           l('           WHERE PARTY_ID = H_DENORM_PARTY_ID(I) AND D_PS <> ''SYNC'' ;');
                           l('EXIT ;');
			               l('EXCEPTION');
			               l('WHEN OTHERS THEN');
			               l('           H_ROW_OFFSET := H_ROW_OFFSET+SQL%ROWCOUNT;');
                           l('           UPDATE HZ_STAGED_PARTIES');
				           l('           SET D_PS = ''SYNC'' ');
				           l('           WHERE PARTY_ID = H_DENORM_PARTY_ID(H_ROW_OFFSET) ;');
                           l('           H_ROW_OFFSET := H_ROW_OFFSET+1;');
		                   l('END ; ');
                           l('END LOOP ;');
                      ELSE
                           l(';');
                      END IF ;
                      l('      IF l_last_fetch THEN');
                      l('        FND_CONCURRENT.AF_Commit;');
                      l('        EXIT;');
                      l('      END IF;');
                      l('      FND_CONCURRENT.AF_Commit;');
                      l('    END LOOP;');
                      l('  END;');
                END IF ;
     -- NO NEW TRANSFORMATIONS BUT THERE ARE SOME NEW DENORM ATTRIBUTES
     ELSE
                    log('Else block of code -- No new transformations exist' );
                    l('  PROCEDURE open_party_site_cursor( ');
                    l('    p_worker_number IN	NUMBER,');
                    l('    p_num_workers	IN	NUMBER,');
                    l('    x_party_site_cur	IN OUT	HZ_PARTY_STAGE.StageCurTyp) IS ');
                    l('');
                    l('  BEGIN');
                    l('    open x_party_site_cur FOR');
                    l('      SELECT ps.PARTY_ID,');
                    l(get_missing_denorm_attrib_cols('PARTY_SITES'));
                    l('      FROM HZ_STAGED_PARTY_SITES ps');
                    l('      WHERE mod(ps.PARTY_ID, p_num_workers) = p_worker_number ; ');
                    l('  END;');

                    l('  PROCEDURE update_stage_party_sites ( ');
                    l('    p_party_site_cur    IN HZ_PARTY_STAGE.StageCurTyp) IS ');
                    l('  l_limit NUMBER := ' || g_batch_size || ';');
                    l('  H_DENORM_PARTY_ID NumberList ;');
                    l('  H_DENORM_VALUE CharList ;');
                    l('  H_ROW_OFFSET Number ;');
                    l(' l_last_fetch BOOLEAN := FALSE;');
                    l('');
                    l('  BEGIN');
                    l('    LOOP');
                    l('      H_ROW_OFFSET := 1 ;');
                    l('      FETCH p_party_site_cur BULK COLLECT INTO');
                    l('        H_DENORM_PARTY_ID, H_DENORM_VALUE');
                    l('      LIMIT l_limit;');
                    l('');
                    l('    IF p_party_site_cur%NOTFOUND THEN');
                    l('      l_last_fetch:=TRUE;');
                    l('    END IF;');
                    l('    IF H_DENORM_PARTY_ID.COUNT=0 AND l_last_fetch THEN');
                    l('      EXIT;');
                    l('    END IF;');

                    l('LOOP');
  		            l('BEGIN');
  			        l('   FORALL I IN H_ROW_OFFSET..H_DENORM_PARTY_ID.COUNT');
  			        l('           UPDATE HZ_STAGED_PARTIES');
  				    l('           SET D_PS = D_PS||'' ''||H_DENORM_VALUE(I)');
  				    l('           WHERE PARTY_ID = H_DENORM_PARTY_ID(I) AND D_PS <> ''SYNC'' ;');
                    l('EXIT ;');
  			        l('EXCEPTION');
  			        l('WHEN OTHERS THEN');
  			        l('           H_ROW_OFFSET := H_ROW_OFFSET+SQL%ROWCOUNT;');
                    l('           UPDATE HZ_STAGED_PARTIES');
  				    l('           SET D_PS = ''SYNC'' ');
  				    l('           WHERE PARTY_ID = H_DENORM_PARTY_ID(H_ROW_OFFSET) ;');
                    l('           H_ROW_OFFSET := H_ROW_OFFSET+1 ;');
  		            l('END ;');
                    l('END LOOP ;');

                    l('        IF l_last_fetch THEN');
                    l('          FND_CONCURRENT.AF_Commit;');
                    l('          EXIT;');
                    l('        END IF;');
                    l('        FND_CONCURRENT.AF_Commit;');
                    l('    END LOOP ;');
                    l('  END ; ');
  END IF ;
END;


PROCEDURE generate_contact_pt_query_upd(
  x_rebuild_cpt_idx OUT NOCOPY BOOLEAN) IS
 cur_col_num NUMBER := 1;

 TYPE coltab IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;

 l_select coltab;

 l_forall_list coltab;
 l_custom_list coltab;
 l_mincol_list coltab;
 l_min_colnum NUMBER;
 idx NUMBER :=1;
 FIRST BOOLEAN;
-- VJN Introduced for conditional word replacements
 l_cond_attrib_list coltab ;
 l_idx number ;

BEGIN
log('Generating upd procedures for CONTACT POINTS' );
IF new_transformations_exist('CONTACT_POINTS') = TRUE
                      OR
     ( new_transformations_exist('CONTACT_POINTS') = FALSE AND get_missing_denorm_attrib_cols('CONTACT_POINTS') IS NULL )
THEN
                  log('If block of code -- new transformations exist or there are no missing denorm attrib columns' );
                  l('  PROCEDURE open_contact_pt_cursor( ');
                  l('    p_worker_number IN	NUMBER,');
                  l('    p_num_workers	IN	NUMBER,');
                  l('    x_contact_pt_cur	IN OUT	HZ_PARTY_STAGE.StageCurTyp) IS ');
                  l('');
                  l('  BEGIN');

                  FOR ATTRS IN (SELECT a.ATTRIBUTE_ID,
                                       a.ATTRIBUTE_NAME,
                                       a.SOURCE_TABLE,
                                       a.CUSTOM_ATTRIBUTE_PROCEDURE,
                                       f.PROCEDURE_NAME,
                                       f.STAGED_ATTRIBUTE_COLUMN,
                                       to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3)) COLNUM
                                FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
                                WHERE ENTITY_NAME = 'CONTACT_POINTS'
                                AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                                AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
                                AND f.STAGED_FLAG='N'
                                ORDER BY COLNUM) LOOP
                    IF cur_col_num<ATTRS.COLNUM THEN
                      FOR I in cur_col_num..ATTRS.COLNUM-1 LOOP
                        l_mincol_list(I) := 'N';
                        l_forall_list(I) := 'N';
                      END LOOP;
                    END IF;
                    cur_col_num:=ATTRS.COLNUM+1;
                    IF has_trx_context(ATTRS.PROCEDURE_NAME) THEN
                      l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||ATTRS.COLNUM||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''CONTACT_POINTS'',''STAGE'')';
                    ELSE
                      l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||ATTRS.COLNUM||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''CONTACT_POINTS'')';
                    END IF;

                    l_mincol_list(ATTRS.COLNUM) := 'N';
                    IF ATTRS.CUSTOM_ATTRIBUTE_PROCEDURE IS NULL THEN
                      l_select(idx) := 'cp.'||ATTRS.ATTRIBUTE_NAME;
                    ELSE
                        SELECT min(to_number(substrb(STAGED_ATTRIBUTE_COLUMN, 3))) INTO l_min_colnum
                        FROM HZ_TRANS_ATTRIBUTES_VL a, HZ_TRANS_FUNCTIONS_VL f
                        WHERE ENTITY_NAME = 'CONTACT_POINTS'
                        AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'
                        AND f.ATTRIBUTE_ID = a.ATTRIBUTE_ID
                        AND a.ATTRIBUTE_NAME=ATTRS.ATTRIBUTE_NAME
                        AND f.STAGED_FLAG='N';

                        l_select(idx) := 'NULL';
                        IF ATTRS.colnum>l_min_colnum THEN
                          IF has_trx_context(ATTRS.PROCEDURE_NAME) THEN
                            l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||l_min_colnum||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''CONTACT_POINTS'',''STAGE'')';
                          ELSE
                            l_forall_list(ATTRS.COLNUM) := ATTRS.PROCEDURE_NAME || '(H_TX'||l_min_colnum||'(I),NULL, ''' || ATTRS.ATTRIBUTE_NAME || ''',''CONTACT_POINTS'')';
                          END IF;

                          l_mincol_list(ATTRS.COLNUM) := 'N';
                        ELSE
                          l_mincol_list(ATTRS.COLNUM) := 'Y';
                          IF has_context(ATTRS.custom_attribute_procedure) THEN
                            l_custom_list(ATTRS.COLNUM) := ATTRS.custom_attribute_procedure || '(H_CONTACT_POINT_ID(I),''CONTACT_POINTS'','''||ATTRS.ATTRIBUTE_NAME|| ''', ''STAGE'')';
                          ELSE
                            l_custom_list(ATTRS.COLNUM) := ATTRS.custom_attribute_procedure || '(H_CONTACT_POINT_ID(I), ''CONTACT_POINTS'','''||ATTRS.ATTRIBUTE_NAME|| ''')';
                          END IF;
                        END IF;
                    END IF;
                    idx := idx+1;
                    -- VJN ADDED CODE FOR TRACKING CONDITION ATTRIBUTES AT THIS ENTITY LEVEL
                    IF HZ_WORD_CONDITIONS_PKG.is_a_cond_attrib( ATTRS.attribute_id)
                    THEN
                        l_cond_attrib_list(ATTRS.COLNUM) := ATTRS.attribute_id ;
                    END IF;

                  END LOOP;

                  IF idx=1 THEN
                    x_rebuild_cpt_idx:=FALSE;
                    l('    RETURN;');
                    l('  END;');
                  ELSE
                    x_rebuild_cpt_idx:=check_rebuild('CONTACT_POINTS');
                    IF cur_col_num<255 THEN
                      FOR I in cur_col_num..255 LOOP
                        l_mincol_list(I) := 'N';
                        l_forall_list(I) := 'N';
                      END LOOP;
                    END IF;
                    l('        open x_contact_pt_cur FOR');
                    l('           SELECT cp.CONTACT_POINT_ID ');
                    FOR I in 1..l_select.COUNT LOOP
                      l('                  ,' || l_select(I));
                    END LOOP;
                    l('           FROM HZ_CONTACT_POINTS cp, HZ_STAGED_CONTACT_POINTS s ');
                    l('           WHERE mod(s.PARTY_ID, p_num_workers) = p_worker_number ');
                    l('           AND cp.contact_point_id  =  s.contact_point_id ');
                    l('           AND cp.owner_table_id  =  s.PARTY_ID ');
                    l('           AND cp.OWNER_TABLE_NAME = ''HZ_PARTIES'' ');
                    l('           AND (cp.status is null OR cp.status = ''A'' or cp.status = ''I''); ');
                    l('  END;');
                  END IF;

                  l('  PROCEDURE update_stage_contact_pts ( ');
                  l('    p_contact_pt_cur    IN HZ_PARTY_STAGE.StageCurTyp) IS ');
                  l('  l_limit NUMBER := ' || g_batch_size || ';');
                  l('  H_DENORM_PARTY_ID NumberList ;');
                  l('  H_DENORM_VALUE CharList ;');
                  l('  H_ROW_OFFSET Number ;');
                  l(' l_last_fetch BOOLEAN := FALSE;');
                  l('');
                  l('  BEGIN');
                  IF idx=1 THEN
                    l('      RETURN;');
                    l('  END;');
                  ELSE
                    l('    LOOP');
                    l('      H_ROW_OFFSET := 1 ;');
                    l('      FETCH p_contact_pt_cur BULK COLLECT INTO');
                    l('        H_CONTACT_POINT_ID');
                    FOR I IN 1..255 LOOP
                      IF l_forall_list(I) <> 'N' THEN
                        l('         ,H_TX'||I);
                      END IF;
                    END LOOP;
                    l('      LIMIT l_limit;');
                    l('');
                    l('    IF p_contact_pt_cur%NOTFOUND THEN');
                    l('      l_last_fetch:=TRUE;');
                    l('    END IF;');

                    l('    IF H_CONTACT_POINT_ID.COUNT=0 AND l_last_fetch THEN');
                    l('      EXIT;');
                    l('    END IF;');

                    l('    FOR I in H_CONTACT_POINT_ID.FIRST..H_CONTACT_POINT_ID.LAST LOOP');
                     -- VJN INTRODUCED CODE FOR GENERATING THE POPULATION
                      -- OF THE GLOBAL CONDITION RECORD

                      l_idx := l_cond_attrib_list.FIRST ;
                      IF l_idx IS NOT NULL
                      THEN
                            l('----------- SETTING GLOBAL CONDITION RECORD AT THE CONTACT POINT LEVEL ---------');
                      END IF ;


                      WHILE l_cond_attrib_list.EXISTS(l_idx)
                      LOOP

                        l('     HZ_WORD_CONDITIONS_PKG.set_gbl_condition_rec ('||l_cond_attrib_list(l_idx)||','||'H_TX'||l_idx||'(I));');
                        l_idx := l_idx+1;
                       END LOOP;

                    FOR I IN 1..255 LOOP
                      IF l_forall_list(I) <> 'N' THEN
                        IF l_mincol_list(I) = 'Y' THEN
                          l('         H_TX'||I||'(I):='||l_custom_list(I)||';');
                        END IF;
                      END IF;
                    END LOOP;

                    FOR I IN 1..255 LOOP
                      IF l_forall_list(I) <> 'N' THEN
                        IF l_mincol_list(I) <> 'Y' THEN
                          l('         H_TX'||I||'(I):='||l_forall_list(I)||';');
                        END IF;
                      END IF;
                    END LOOP;
                    FOR I IN 1..255 LOOP
                      IF l_forall_list(I) <> 'N' THEN
                        IF l_mincol_list(I) = 'Y' THEN
                          l('         H_TX'||I||'(I):='||l_forall_list(I)||';');
                        END IF;
                      END IF;
                    END LOOP;
                    l('    END LOOP;');

                    l('    FORALL I in H_CONTACT_POINT_ID.FIRST..H_CONTACT_POINT_ID.LAST');
                    l('      UPDATE HZ_STAGED_CONTACT_POINTS SET');
                    FIRST:=TRUE;
                    FOR I IN 1..255 LOOP
                      IF l_forall_list(I) <> 'N' THEN
                          IF (FIRST) THEN
                	       FIRST := false;
                               l('            TX'||I||'=decode(H_TX'||I||'(I),null,H_TX'||I||'(I),H_TX'||I||'(I)||'' '')');
                          ELSE
                               l('            ,TX'||I||'=decode(H_TX'||I||'(I),null,H_TX'||I||'(I),H_TX'||I||'(I)||'' '')');
                          END IF;
                      END IF;
                    END LOOP;
                      l('        WHERE CONTACT_POINT_ID = H_CONTACT_POINT_ID(I)');

                      -- ADD CODE FOR UPDATING HZ_STAGED_PARTIES IF THERE ARE ANY NEW CONTACT POINT DENORM ATTRIBUTES
                      IF get_missing_denorm_attrib_cols('CONTACT_POINTS') IS NOT NULL
                      THEN
                           l('RETURNING PARTY_ID, ');
                           l(get_missing_denorm_attrib_cols('CONTACT_POINTS'));
                           -- THIS BULK COLLECT WILL CHOSE THE PARTY ID COLUMNS OF THE ROWS THAT ARE UPDATED
                           -- AND UPDATE THESE PARTY IDS IN HZ_STAGED_PARTIES, BY APPENDING TO THE D_CPT COLUMNS
                           -- VALUES FROM THE NEW DENORM ATTRIBUTE COLUMNS
                            l('BULK COLLECT INTO  H_DENORM_PARTY_ID, H_DENORM_VALUE ;');
                            l('LOOP');
          		            l('BEGIN');
          			        l('   FORALL I IN H_ROW_OFFSET..H_DENORM_PARTY_ID.COUNT');
          			        l('           UPDATE HZ_STAGED_PARTIES');
          				    l('           SET D_CPT = D_CPT||'' ''||H_DENORM_VALUE(I)');
          				    l('           WHERE PARTY_ID = H_DENORM_PARTY_ID(I) AND D_CPT <> ''SYNC'' ;');
                            l('EXIT ;');
          			        l('EXCEPTION');
          			        l('WHEN OTHERS THEN');
          			        l('           H_ROW_OFFSET := H_ROW_OFFSET+SQL%ROWCOUNT;');
                            l('           UPDATE HZ_STAGED_PARTIES');
          				    l('           SET D_CPT = ''SYNC'' ');
          				    l('           WHERE PARTY_ID = H_DENORM_PARTY_ID(H_ROW_OFFSET) ;');
                            l('           H_ROW_OFFSET := H_ROW_OFFSET+1 ;');
          		            l('END ;');
                            l('END LOOP ;');
                      ELSE
                           l(';');
                      END IF ;
                      l('      IF l_last_fetch THEN');
                      l('        FND_CONCURRENT.AF_Commit;');
                      l('        EXIT;');
                      l('      END IF;');
                      l('      FND_CONCURRENT.AF_Commit;');
                      l('    END LOOP;');
                      l('  END;');
                  END IF;
ELSE
                    log('Else block of code -- No new transformations exist' );
                    l('  PROCEDURE open_contact_pt_cursor( ');
                    l('    p_worker_number IN	NUMBER,');
                    l('    p_num_workers	IN	NUMBER,');
                    l('    x_contact_pt_cur	IN OUT	HZ_PARTY_STAGE.StageCurTyp) IS ');
                    l('');
                    l('  BEGIN');
                    l('    open x_contact_pt_cur FOR');
                    l('      SELECT cpt.PARTY_ID,');
                    l(get_missing_denorm_attrib_cols('CONTACT_POINTS'));
                    l('      FROM HZ_STAGED_CONTACT_POINTS cpt');
                    l('      WHERE mod(cpt.PARTY_ID, p_num_workers) = p_worker_number ; ');
                    l('  END;');

                    l('  PROCEDURE update_stage_contact_pts ( ');
                    l('    p_contact_pt_cur    IN HZ_PARTY_STAGE.StageCurTyp) IS ');
                    l('  l_limit NUMBER := ' || g_batch_size || ';');
                    l('  H_DENORM_PARTY_ID NumberList ;');
                    l('  H_DENORM_VALUE CharList ;');
                    l('  H_ROW_OFFSET Number ;');
                    l(' l_last_fetch BOOLEAN := FALSE;');
                    l('');
                    l('  BEGIN');
                    l('    LOOP');
                    l('      H_ROW_OFFSET := 1 ; ');
                    l('      FETCH p_contact_pt_cur BULK COLLECT INTO');
                    l('        H_DENORM_PARTY_ID, H_DENORM_VALUE');
                    l('      LIMIT l_limit;');
                    l('');
                    l('    IF p_contact_pt_cur%NOTFOUND THEN');
                    l('      l_last_fetch:=TRUE;');
                    l('    END IF;');
                    l('    IF H_DENORM_PARTY_ID.COUNT=0 AND l_last_fetch THEN');
                    l('      EXIT;');
                    l('    END IF;');

                    l('LOOP');
  		            l('BEGIN');
  			        l('   FORALL I IN H_ROW_OFFSET..H_DENORM_PARTY_ID.COUNT');
  			        l('           UPDATE HZ_STAGED_PARTIES');
  				    l('           SET D_CPT = D_CPT||'' ''||H_DENORM_VALUE(I)');
  				    l('           WHERE PARTY_ID = H_DENORM_PARTY_ID(I) AND D_CPT <> ''SYNC'' ;');
                    l('EXIT ;');
  			        l('EXCEPTION');
  			        l('WHEN OTHERS THEN');
  			        l('           H_ROW_OFFSET := H_ROW_OFFSET+SQL%ROWCOUNT;');
                    l('           UPDATE HZ_STAGED_PARTIES');
  				    l('           SET D_CPT = ''SYNC'' ');
  				    l('           WHERE PARTY_ID = H_DENORM_PARTY_ID(H_ROW_OFFSET) ;');
                    l('           H_ROW_OFFSET := H_ROW_OFFSET+1 ;');
  		            l('END ;');
                    l('END LOOP ;');





                    l('        IF l_last_fetch THEN');
                    l('          FND_CONCURRENT.AF_Commit;');
                    l('          EXIT;');
                    l('        END IF;');
                    l('        FND_CONCURRENT.AF_Commit;');
                    l('    END LOOP ; ');
                    l('  END ; ');
END IF ;

END;


PROCEDURE create_btree_indexes (p_entity VARCHAR2)
 IS
  l_index_owner VARCHAR2(255);

  CURSOR indexes_reqd IS
    SELECT decode(a.entity_name,'PARTY','HZ_STAGED_PARTIES',
                  'PARTY_SITES','HZ_STAGED_PARTY_SITES','CONTACTS','HZ_STAGED_CONTACTS',
                  'CONTACT_POINTS','HZ_STAGED_CONTACT_POINTS')||'_N0'||substrb(staged_attribute_column,3) index_name,
           decode(a.entity_name,'PARTY','HZ_STAGED_PARTIES',
                  'PARTY_SITES','HZ_STAGED_PARTY_SITES','CONTACTS','HZ_STAGED_CONTACTS',
                  'CONTACT_POINTS','HZ_STAGED_CONTACT_POINTS') table_name,
           decode(a.entity_name,'PARTY','HZ_SRCH_PARTIES',
                  'PARTY_SITES','HZ_SRCH_PSITES','CONTACTS','HZ_SRCH_CONTACTS',
                  'CONTACT_POINTS','HZ_SRCH_CPTS')||'_N0'||substrb(staged_attribute_column,3) srch_index_name,
           decode(a.entity_name,'PARTY','HZ_SRCH_PARTIES',
                  'PARTY_SITES','HZ_SRCH_PSITES','CONTACTS','HZ_SRCH_CONTACTS',
                  'CONTACT_POINTS','HZ_SRCH_CPTS') srch_table_name,
           f.staged_attribute_column column_name
   FROM hz_trans_attributes_vl a, hz_trans_functions_vl f
   WHERE f.attribute_id = a.attribute_id
   AND f.index_required_flag = 'Y'
   AND a.entity_name = p_entity;

 CURSOR check_index(cp_index_name VARCHAR2,cp_table_name VARCHAR2) IS
   SELECT 1 FROM sys.all_indexes
   WHERE INDEX_NAME=cp_index_name
   AND TABLE_NAME=cp_table_name and owner = l_index_owner;

 l_index_name VARCHAR2(255);
 l_table_name VARCHAR2(255);
 l_srch_index_name VARCHAR2(255);
 l_srch_table_name VARCHAR2(255);
 l_column_name VARCHAR2(255);

 ar_index_tbsp VARCHAR2(255);
 l_storage_params VARCHAR2(2000);
 tmp NUMBER;

l_status VARCHAR2(255);
l_temp VARCHAR2(255);

l_bool BOOLEAN;

BEGIN

  l_bool := fnd_installation.GET_APP_INFO('AR',l_status,l_temp,l_index_owner);

  select index_tablespace
  into ar_index_tbsp
  from fnd_product_installations
  where application_id = '222';

  l_storage_params := 'LOGGING STORAGE (INITIAL 4K NEXT 1M MINEXTENTS 1 '||
                      'MAXEXTENTS unlimited PCTINCREASE 0 FREELIST GROUPS 4 '||
                      'FREELISTS 4) PCTFREE 10 INITRANS 4 MAXTRANS 255 '||
                      'COMPUTE STATISTICS TABLESPACE '||ar_index_tbsp;

  OPEN indexes_reqd;
  LOOP
    FETCH indexes_reqd INTO l_index_name, l_table_name,l_srch_index_name, l_srch_table_name, l_column_name;
    EXIT WHEN indexes_reqd%NOTFOUND;

    OPEN check_index(l_index_name,l_table_name);
    FETCH check_index INTO tmp;
    IF check_index%NOTFOUND THEN
      EXECUTE IMMEDIATE 'CREATE INDEX '||l_index_owner||'.'||l_index_name||' ON '||l_table_name||'('||l_column_name||') '||
                        l_storage_params;
    END IF;
    CLOSE check_index;

    OPEN check_index(l_srch_index_name,l_srch_table_name);
    FETCH check_index INTO tmp;
    IF check_index%NOTFOUND THEN
      EXECUTE IMMEDIATE 'CREATE INDEX '||l_index_owner||'.'||l_srch_index_name||' ON '||l_srch_table_name||'('||l_column_name||') '||
                        l_storage_params;
    END IF;
    CLOSE check_index;
  END LOOP;
  CLOSE indexes_reqd;
END;

FUNCTION has_trx_context(proc VARCHAR2) RETURN BOOLEAN IS

  l_sql VARCHAR2(255);
  l_entity VARCHAR2(255);
  l_procedure VARCHAR2(255);
  l_attribute VARCHAR2(255);
  c NUMBER;
  n NUMBER;
  l_custom BOOLEAN;

BEGIN
  c := dbms_sql.open_cursor;
  l_sql := 'select ' || proc ||
           '(:attrval,:lang,:attr,:entity,:ctx) from dual';
  dbms_sql.parse(c,l_sql,2);
  DBMS_SQL.BIND_VARIABLE(c,':attrval','x');
  DBMS_SQL.BIND_VARIABLE(c,':lang','x');
  DBMS_SQL.BIND_VARIABLE(c,':attr','x');
  DBMS_SQL.BIND_VARIABLE(c,':entity','x');
  DBMS_SQL.BIND_VARIABLE(c,':ctx','x');
  n:=DBMS_SQL.execute(c);
  dbms_sql.close_cursor(c);
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    dbms_sql.close_cursor(c);
    RETURN FALSE;
END;

FUNCTION has_context(proc VARCHAR2) RETURN BOOLEAN IS

  l_sql VARCHAR2(255);
  l_entity VARCHAR2(255);
  l_procedure VARCHAR2(255);
  l_attribute VARCHAR2(255);
  c NUMBER;
  n NUMBER;
  l_custom BOOLEAN;

BEGIN
  c := dbms_sql.open_cursor;
  l_sql := 'select ' || proc ||
           '(:record_id,:entity,:attr,:ctx) from dual';
  dbms_sql.parse(c,l_sql,2);
  DBMS_SQL.BIND_VARIABLE(c,':record_id','x');
  DBMS_SQL.BIND_VARIABLE(c,':entity','x');
  DBMS_SQL.BIND_VARIABLE(c,':attr','x');
  DBMS_SQL.BIND_VARIABLE(c,':ctx','x');
  n:=DBMS_SQL.execute(c);
  dbms_sql.close_cursor(c);
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    dbms_sql.close_cursor(c);
    RETURN FALSE;
END;


PROCEDURE verify_all_procs IS

  l_sql VARCHAR2(255);
  l_entity VARCHAR2(255);
  l_procedure VARCHAR2(255);
  l_attribute VARCHAR2(255);
  l_trans_name VARCHAR2(255);
  c NUMBER;
  l_custom BOOLEAN;
BEGIN
  FOR FUNCS IN (SELECT PROCEDURE_NAME, a.ENTITY_NAME, a.ATTRIBUTE_NAME, f.TRANSFORMATION_NAME
                FROM HZ_TRANS_FUNCTIONS_VL f, HZ_TRANS_ATTRIBUTES_VL a
                WHERE a.ATTRIBUTE_ID = f.ATTRIBUTE_ID
                AND nvl(f.ACTIVE_FLAG,'Y') = 'Y' )
    LOOP
        BEGIN
             l_custom := FALSE;
             l_entity := FUNCS.ENTITY_NAME;
             l_attribute := FUNCS.ATTRIBUTE_NAME;
             l_procedure := FUNCS.PROCEDURE_NAME;
             l_trans_name := FUNCS.TRANSFORMATION_NAME;
             c := dbms_sql.open_cursor;
             l_sql := 'select ' || FUNCS.PROCEDURE_NAME ||
               '(:attrval,:lang,:attr,:entity) from dual';
             dbms_sql.parse(c,l_sql,2);
             dbms_sql.close_cursor(c);
          EXCEPTION WHEN OTHERS THEN
               FND_MESSAGE.SET_NAME('AR', 'HZ_TRANS_PROC_ERROR1');
               FND_MESSAGE.SET_TOKEN('PROC' ,l_procedure);
               FND_MESSAGE.SET_TOKEN('ENTITY' ,l_entity);
               FND_MESSAGE.SET_TOKEN('ATTRIBUTE' ,l_attribute);
               FND_MESSAGE.SET_TOKEN('TRANS' ,l_trans_name);
               FND_MSG_PUB.ADD;
          END;
    END LOOP;
   FOR FUNCS IN (SELECT custom_attribute_procedure, ENTITY_NAME, ATTRIBUTE_NAME
                 FROM HZ_TRANS_ATTRIBUTES_VL a
                 WHERE source_table = 'CUSTOM' OR
                 custom_attribute_procedure is NOT NULL
                 AND EXISTS (select 1 from HZ_TRANS_FUNCTIONS_VL f
                             WHERE f.attribute_id = a.attribute_id
                             AND nvl(f.ACTIVE_FLAG,'Y') = 'Y'))
     LOOP
         BEGIN
              l_custom := TRUE;
              l_entity := FUNCS.ENTITY_NAME;
              l_attribute := FUNCS.ATTRIBUTE_NAME;
              l_procedure := FUNCS.custom_attribute_procedure;
              c := dbms_sql.open_cursor;
              l_sql := 'select ' || FUNCS.custom_attribute_procedure ||
               '(:record_id,:entity,:attr) from dual';
              dbms_sql.parse(c,l_sql,2);
              dbms_sql.close_cursor(c);
          EXCEPTION WHEN OTHERS THEN
               FND_MESSAGE.SET_NAME('AR', 'HZ_CUSTOM_PROC_ERROR1');
               FND_MESSAGE.SET_TOKEN('PROC' ,l_procedure);
               FND_MESSAGE.SET_TOKEN('ENTITY' ,l_entity);
               FND_MESSAGE.SET_TOKEN('ATTRIBUTE' ,l_attribute);
               FND_MSG_PUB.ADD;
          END;
    END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    dbms_sql.close_cursor(c);
    RAISE FND_API.G_EXC_ERROR;
END ;



/**
* Procedure to write a message to the out file
**/
PROCEDURE out(
   message      IN      VARCHAR2,
   newline      IN      BOOLEAN DEFAULT TRUE) IS
BEGIN
  IF message = 'NEWLINE' THEN
    FND_FILE.NEW_LINE(FND_FILE.OUTPUT, 1);
  ELSIF (newline) THEN
    FND_FILE.put_line(fnd_file.output,message);
  ELSE
    FND_FILE.put(fnd_file.output,message);
  END IF;
END out;

/**
* Procedure to write a message to the log file
**/
PROCEDURE log(
   message      IN      VARCHAR2,
   newline      IN      BOOLEAN DEFAULT TRUE) IS
BEGIN

  IF message = 'NEWLINE' THEN
   FND_FILE.NEW_LINE(FND_FILE.LOG, 1);
  ELSIF (newline) THEN
    FND_FILE.put_line(fnd_file.log,message);
  ELSE
    FND_FILE.put(fnd_file.log,message);
  END IF;
END log;

/**
* Procedure to write a message to the out and log files
**/
PROCEDURE outandlog(
   message      IN      VARCHAR2,
   newline      IN      BOOLEAN DEFAULT TRUE) IS
BEGIN
  out(message, newline);
  log(message, newline);
END outandlog;

/**
* Function to fetch messages of the stack and log the error
* Also returns the error
**/
FUNCTION logerror(SQLERRM VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS

  l_msg_data VARCHAR2(2000);
BEGIN
  FND_MSG_PUB.Reset;

  FOR I IN 1..FND_MSG_PUB.Count_Msg LOOP
    l_msg_data := l_msg_data || FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE );
  END LOOP;
  IF (SQLERRM IS NOT NULL) THEN
    l_msg_data := l_msg_data || SQLERRM;
  END IF;
  log(l_msg_data);
  RETURN l_msg_data;
END logerror;

FUNCTION wait_for_request(
    p_request_id NUMBER) RETURN VARCHAR2 IS

uphase VARCHAR2(255);
dphase VARCHAR2(255);
ustatus VARCHAR2(255);
dstatus VARCHAR2(255);
message VARCHAR2(32000);

l_bool BOOLEAN;

BEGIN
  l_bool := FND_CONCURRENT.wait_for_request(p_request_id,
             60, 144000, uphase, ustatus, dphase, dstatus, message);

  IF dphase <> 'COMPLETE' and dstatus <> 'NORMAL' THEN
    return 'ERROR';
  ELSE
    return 'SUCCESS';
  END IF;
END wait_for_request;

BEGIN
    g_schema_name := hz_utility_v2pub.get_appsschemaname;

END HZ_PARTY_STAGE;
/
COMMIT;
EXIT;
