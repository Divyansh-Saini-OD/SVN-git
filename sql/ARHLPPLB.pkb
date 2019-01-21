/*                                                                        *
 *  Copyright (c) 2001 Oracle Corporation Redwood Shores, California, USA *
 *                          All rights reserved.                          *
 *========================================================================*
 * FILE       ARHLPPLB.pls                                                *
 *                                                                        *
 * PACKAGE    HZ_IMP_LOAD_POST_PROCESS_PKG                                *
 *                                                                        *
 * DESCRIPTION                                                            *
 *     This package contains procedures for date load post processing.    *
 *                                                                        *
 * RELATED PACKAGES                                                       *
 *                                                                        *
 * PUBLIC PROCEDURES                                                      *
 *        pp_dqm_sync                                                     *
 *        pp_format_person_name                                           *
 *        pp_generate_cust_key                                            *
 *        pp_generate_addr_key                                            *
 *        pp_rel_party_name                                               *     
 *        pp_phone_format                                                 *     
 *        pp_denorm_title                                                 *     
 *        pp_denorm_rel                                                   *     
 *        pp_dnb_hierarchy                                                *  
 *        pp_generate_cp_timezone                                         *  
 *        pp_generate_loc_timezone                                        *  
 * PUBLIC FUNCTIONS                                                       *
 *                                                                        *
 * NOTES                                                                  *
 *                                                                        *
 * MODIFICATION HISTORY                                                   *
 *                                                                        *
 * 22-Jan-2004         Ramesh Ch.  Bug No:3315740.Added extra join to     *
 *				   interface tables in c_timezone_loc,    *
 *				   c_timezone_cp cursors not to generate  *
 *                                 timezone ids if the user has passed    *
 *			           a value.Also added calls to disable	  *
 *				   and enable the content source security *
 * 22-Jan-2004         Ramesh Ch.  Bug No:3341244.Modified REFERENCE_OF   *
 *				   relationship code to REFERENCE_FOR.	  *
 * 17-Feb-2004         P.Suresh    Bug No: 3341272. Corrected the party   *
 *                                 type in pp_rel_party_name.             *
 * 19-Feb-2004         Ramesh Ch   Bug No: 3310967 Modified the           *
 *				   pp_dnb_hierarchy procedure to call the *
 *				   dnb hierarchy api only once for the    *
 *				   candidate party.                       *
 * 12-Mar-2004	       Ramesh Ch   Bug No: 3499282 Replaced the NULLIF	  *
 *				   with decode statement to remove 9i	  *
 *				   dependencies.			  *
 * 16-Mar-2006         vravicha    Bug No: 5091668                        *
 * 31-Jul-2006     achung Bug 5264069 - re-initialize local variables in  *
 *                        pp_dnb_hierarchy                                * 
 * 27-Sep-2006         vravicha    Bug No: 5556468. Closed the unclosed   *
 *                                 cursor c_dqm_person_upd.
 * 10-Oct-2006     achung Bug 5565000 fix pp_dnb_hierarchy cursor         *
 *========================================================================*/

REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile:~PROD:~PATH:~FILE

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY HZ_IMP_LOAD_POST_PROCESS_PKG  AS
/*$Header: ARHLPPLB.pls 115.22.115104.6 2006/10/12 01:18:07 achung noship $ */

TYPE INDEXIDList IS TABLE OF NUMBER(15) INDEX BY BINARY_INTEGER;
TYPE RefCurType IS REF CURSOR;
l_party_id                            PARTY_ID;
l_party_site_id                       PARTY_SITE_ID;
l_party_type                          PARTY_TYPE;
l_insert_update_flag                  INSERT_UPDATE_FLAG;
l_location_id                         LOCATION_ID;    
l_org_contact_id                      ORG_CONTACT_ID;
l_relationship_code                   RELATIONSHIP_CODE;
l_relationship_id                     RELATIONSHIP_ID;
l_contact_point_id                    CONTACT_POINT_ID;
l_person_title                        PERSON_TITLE;
l_person_first_name                   PERSON_FIRST_NAME;
l_person_middle_name                  PERSON_MIDDLE_NAME;
l_person_last_name                    PERSON_LAST_NAME;
l_person_name_suffix                  PERSON_NAME_SUFFIX;
l_known_as                            KNOWN_AS;
l_person_first_name_phonetic          PERSON_FIRST_NAME_PHONETIC;
l_middle_name_phonetic                MIDDLE_NAME_PHONETIC;
l_person_last_name_phonetic           PERSON_LAST_NAME_PHONETIC;
l_party_name                          PARTY_NAME;
l_address1                            ADDRESS1;
l_address2                            ADDRESS2;
l_address3                            ADDRESS3;
l_address4                            ADDRESS4;
l_postal_code                         POSTAL_CODE; 
l_city                                CITY;
l_state                               STATE;
l_country                             COUNTRY;
l_rel_party_id                        PARTY_ID;
l_subject_name                        PARTY_NAME;
l_object_name                         PARTY_NAME;
l_rel_party_number                    PARTY_NUMBER;
l_raw_phone_number                    RAW_PHONE_NUMBER;
l_country_code                        COUNTRY_CODE;
l_phone_area_code                     PHONE_AREA_CODE;
l_phone_number                        PHONE_NUMBER;                           
l_owner_table_name                    OWNER_TABLE_NAME;
l_owner_table_id                      OWNER_TABLE_ID; 
l_primary_flag                        PRIMARY_FLAG;
l_primary_by_purpose                  PRIMARY_BY_PURPOSE;
l_phone_line_type                     PHONE_LINE_TYPE;
l_phone_extension                     PHONE_EXTENSION;
l_title                               TITLE;
l_subject_id                          SUBJECT_ID;
l_object_id                           OBJECT_ID;
l_comp_flag                           COMP_FLAG;
l_ref_flag                            REF_FLAG;
l_par_flag                            PAR_FLAG;
l_created_by_module                   CREATED_BY_MODULE;                         
l_site_orig_system_reference          SITE_ORIG_SYSTEM_REFERENCE;
l_return_status                       VARCHAR2(1);
l_key                                 VARCHAR2(2000);
l_msg_count                           NUMBER;
l_formatted_phone_number              VARCHAR2(2000);
l_msg_data                            VARCHAR2(2000);
l_formatted_lines_cnt                 NUMBER;
l_formatted_name_tbl                  hz_format_pub.string_tbl_type;
x_return_status                       VARCHAR2(1);

-- Data Type for DQM Sync
l_record_id PARTY_ID;
l_entity EntityList;
l_operation INSERT_UPDATE_FLAG;
l_contact_point_type CONTACT_POINT_TYPE;

/*                                                                       *
 *=======================================================================*
 * PROCEDURENAME                                                         *
 *   insert_interface_rec                                                *
 *                                                                       *
 * DESCRIPTION                                                           *
 *                                                                       *
 * NOTES                                                                 *
 *                                                                       *
 * MODIFICATION HISTORY                                                  *
 *                                                                       *
 *=======================================================================*/
 
PROCEDURE insert_interface_rec( p_party_id      IN      NUMBER,
                                p_record_id     IN      NUMBER,
                                p_party_site_id IN      NUMBER,
                                p_org_contact_id IN     NUMBER,
                                p_entity        IN      VARCHAR2,
                                p_operation     IN      VARCHAR2,
                                p_import_osr    IN      VARCHAR2
) IS                                                          
 
BEGIN
INSERT INTO hz_dqm_sync_interface (
                            PARTY_ID,
                            RECORD_ID,
                            PARTY_SITE_ID,
                            ORG_CONTACT_ID,
                            ENTITY,
                            OPERATION,
                            STAGED_FLAG,
                            REALTIME_SYNC_FLAG,
                            CREATED_BY,
                            CREATION_DATE,
                            LAST_UPDATE_LOGIN,
                            LAST_UPDATE_DATE,
                            LAST_UPDATED_BY ,
                            SYNC_INTERFACE_NUM ,
                            IMPORT_OSR
                                                  ) VALUES (
                            p_party_id,
                            p_record_id,
                            p_party_site_id,
                            p_org_contact_id,
                            p_entity,
                            p_operation,
                            'N',
                            'N',
                            hz_utility_pub.created_by,
                            hz_utility_pub.creation_date,
                            hz_utility_pub.last_update_login,
                            hz_utility_pub.last_update_date,
                            hz_utility_pub.user_id ,
                            HZ_DQM_SYNC_INTERFACE_S.nextval,
                            p_import_osr
                        );
END insert_interface_rec;                        

                       
/*                                                                       *
 *=======================================================================*
 * PROCEDURENAME                                                         *
 *   pp_dqm_sync                                                         *
 *                                                                       *
 * DESCRIPTION                                                           *
 *                                                                       *
 * NOTES                                                                 *
 *                                                                       *
 * MODIFICATION HISTORY                                                  *
 *                                                                       *
 *=======================================================================*/

PROCEDURE pp_dqm_sync ( 
   p_batch_mode_flag             IN       VARCHAR2,
   p_batch_id                    IN       NUMBER,
   p_os                          IN       VARCHAR2,
   p_from_osr                    IN       VARCHAR2,
   p_to_osr                      IN       VARCHAR2,
   p_request_id                  IN       NUMBER,
   p_postprocess_status          IN       VARCHAR2
                        ) IS  
                       
l_dqm_party_sync_sql VARCHAR2(2000) := 'SELECT  p.party_id,p.party_type,
                                     decode ( sign(p.program_update_date - p.creation_date),1,''U'',''C'')
                         FROM  HZ_PARTIES p, HZ_IMP_PARTIES_SG ps
                        WHERE  p.request_id = :p_request_id 
                          AND  p.party_type IN (''ORGANIZATION'', ''PERSON'')
                          AND  p.party_id = ps.party_id
                          AND  ps.batch_id = :p_batch_id
                          AND  ps.party_orig_system = :p_os
                          AND  ps.party_orig_system_reference between :p_from_osr and :p_to_osr
                          AND  ps.batch_mode_flag = :p_batch_mode_flag';

l_dqm_party_sync_rerun_sql VARCHAR2(2000) := 'SELECT  p.party_id,p.party_type,
                                     decode ( sign(p.program_update_date - p.creation_date),1,''U'',''C'')
                         FROM  HZ_PARTIES p, HZ_IMP_PARTIES_SG ps, hz_imp_batch_details bd
                        WHERE  p.request_id = bd.main_conc_req_id 
                          AND  bd.batch_id = ps.batch_id 
                          AND  p.party_type IN (''ORGANIZATION'', ''PERSON'')
                          AND  p.party_id = ps.party_id
                          AND  ps.batch_id = :p_batch_id
                          AND  ps.party_orig_system = :p_os
                          AND  ps.party_orig_system_reference between :p_from_osr and :p_to_osr
                          AND  ps.batch_mode_flag = :p_batch_mode_flag';

c_dqm_party_sync RefCurType;

CURSOR c_dqm_person_upd
    (p_party_id  NUMBER)  IS SELECT  oc.org_contact_id
                               FROM  HZ_PARTY_RELATIONSHIPS pr, HZ_ORG_CONTACTS oc
                              WHERE  pr.party_relationship_id = oc.party_relationship_id
                                AND  pr.subject_id            = p_party_id;                             

                                
l_dqm_ps_sync_sql VARCHAR2(2000) := 'SELECT  ps.party_site_id,p.party_id,p.party_type,
                                     decode ( sign(ps.program_update_date - ps.creation_date),1,''U'',''C'')
                         FROM  HZ_PARTY_SITES ps, HZ_PARTIES p, hz_imp_addresses_sg psg
                        WHERE  ps.request_id = :p_request_id 
                          AND  p.party_type IN (''ORGANIZATION'', ''PERSON'')
                          AND  ps.party_id = p.party_id
                          AND  psg.party_site_id = ps.party_site_id
                          AND  psg.batch_id = :p_batch_id
                          AND  psg.party_orig_system = :p_os
                          AND  psg.party_orig_system_reference between :p_from_osr and :p_to_osr
                          AND  psg.batch_mode_flag = :p_batch_mode_flag';

l_dqm_ps_sync_rerun_sql VARCHAR2(2000) := 'SELECT  ps.party_site_id,p.party_id,p.party_type,
                                     decode ( sign(ps.program_update_date - ps.creation_date),1,''U'',''C'')
                         FROM  HZ_PARTY_SITES ps, HZ_PARTIES p, hz_imp_addresses_sg psg, hz_imp_batch_details bd
                        WHERE  ps.request_id = bd.main_conc_req_id 
                          AND  bd.batch_id = psg.batch_id
                          AND  p.party_type IN (''ORGANIZATION'', ''PERSON'')
                          AND  ps.party_id = p.party_id
                          AND  psg.party_site_id = ps.party_site_id
                          AND  psg.batch_id = :p_batch_id
                          AND  psg.party_orig_system = :p_os
                          AND  psg.party_orig_system_reference between :p_from_osr and :p_to_osr
                          AND  psg.batch_mode_flag = :p_batch_mode_flag';
                          
c_dqm_ps_sync RefCurType;

                              
l_dqm_cp_sync_sql VARCHAR2(2000) := 'SELECT  cp.contact_point_id,
                                     decode ( sign(cp.program_update_date - cp.creation_date),1,''U'',''C'')
                               FROM  hz_contact_points cp, hz_imp_contactpts_sg cps
                              WHERE  cp.request_id        = :p_request_id 
			      AND cp.contact_point_id = cps.contact_point_id
			      and cps.batch_id = :p_batch_id
			      and cps.party_orig_system = :p_os
			      and cps.party_orig_system_reference between :p_from_osr and :p_to_osr
                              and cps.batch_mode_flag = :p_batch_mode_flag' ; 
                              
l_dqm_cp_sync_rerun_sql VARCHAR2(2000) := 'SELECT  cp.contact_point_id,
                                     decode ( sign(cp.program_update_date - cp.creation_date),1,''U'',''C'')
                               FROM  hz_contact_points cp, hz_imp_contactpts_sg cps, hz_imp_batch_details bd
                              WHERE  cp.request_id = bd.main_conc_req_id 
                              AND bd.batch_id = cps.batch_id
			      AND cp.contact_point_id = cps.contact_point_id
			      and cps.batch_id = :p_batch_id
			      and cps.party_orig_system = :p_os
			      and cps.party_orig_system_reference between :p_from_osr and :p_to_osr
                              and cps.batch_mode_flag = :p_batch_mode_flag' ; 
                              
c_dqm_cp_sync RefCurType;

l_dqm_contact_sync_sql VARCHAR2(2000) := ' SELECT  oc.org_contact_id, r.object_id ,
                                     decode ( sign(oc.program_update_date - oc.creation_date),1,''U'',''C'')     
                       FROM hz_org_contacts oc, HZ_PARTY_RELATIONSHIPS r, hz_imp_contacts_sg ocsg
                       WHERE oc.request_id = :p_request_id
                         and ocsg.batch_id = :p_batch_id
                         and ocsg.sub_orig_system = :p_os
                         and ocsg.sub_orig_system_reference between :p_from_osr and :p_to_osr
                         and ocsg.batch_mode_flag = :p_batch_mode_flag
                         and ocsg.contact_id = oc.org_contact_id
                         AND  oc.party_relationship_id = r.party_relationship_id';                                

l_dqm_contact_sync_rerun_sql VARCHAR2(2000) := ' SELECT  oc.org_contact_id, r.object_id ,
                                     decode ( sign(oc.program_update_date - oc.creation_date),1,''U'',''C'')     
                       FROM hz_org_contacts oc, HZ_PARTY_RELATIONSHIPS r, hz_imp_contacts_sg ocsg
                       , hz_imp_batch_details bd
                       WHERE ocsg.batch_id = :p_batch_id
                         and ocsg.sub_orig_system = :p_os
                         and ocsg.sub_orig_system_reference between :p_from_osr and :p_to_osr
                         and ocsg.batch_mode_flag = :p_batch_mode_flag
                         and ocsg.contact_id = oc.org_contact_id
                         and oc.request_id = bd.main_conc_req_id 
                         AND bd.batch_id = ocsg.batch_id
                         AND  oc.party_relationship_id = r.party_relationship_id'; 
                         
c_dqm_contact_sync RefCurType;

l_dqm_loc_sync_sql VARCHAR2(2000) := 'SELECT l.location_id
                              FROM   hz_locations l, hz_party_sites ps,hz_imp_addresses_sg addr_sg
                              WHERE l.request_id = :p_request_id 
                              and l.location_id = ps.location_id
                              AND l.program_update_date > l.creation_date
                              and addr_sg.batch_id = :p_batch_id
                              and addr_sg.party_orig_system = :p_os
                              and addr_sg.party_orig_system_reference between :p_from_osr and :p_to_osr
                              and addr_sg.batch_mode_flag = :p_batch_mode_flag
                              and addr_sg.party_site_id = ps.party_site_id';
                 
l_dqm_loc_sync_rerun_sql VARCHAR2(2000) := 'SELECT l.location_id
                              FROM   hz_locations l, hz_party_sites ps,hz_imp_addresses_sg addr_sg
                              , hz_imp_batch_details bd
                              WHERE l.request_id = bd.main_conc_req_id 
                              AND bd.batch_id = addr_sg.batch_id
                              and l.location_id = ps.location_id
                              AND l.program_update_date > l.creation_date
                              and addr_sg.batch_id = :p_batch_id
                              and addr_sg.party_orig_system = :p_os
                              and addr_sg.party_orig_system_reference between :p_from_osr and :p_to_osr
                              and addr_sg.batch_mode_flag = :p_batch_mode_flag
                              and addr_sg.party_site_id = ps.party_site_id';
                                
c_dqm_loc_sync RefCurType;


CURSOR c_dqm_loc_ps_sync
  (p_location_id NUMBER)  IS SELECT  ps.party_site_id,p.party_id,p.party_type
                               FROM  hz_party_sites ps, hz_parties p
                              WHERE  location_id = p_location_id
                                AND  ps.status   = 'A'
                                AND  p.party_id  = ps.party_id;
                              
l_dqm_rel_sync_sql VARCHAR2(2000) := 'SELECT   o.org_contact_id, r.object_id
                              FROM   HZ_RELATIONSHIPS r, hz_org_contacts o, hz_imp_relships_sg rs
                             WHERE   r.request_id = :p_request_id 
                               AND   r.directional_flag    = ''F''
                               AND   r.program_update_date > r.creation_date
                               AND   r.relationship_id     = o.party_relationship_id
                               AND   o.status  = ''A''
                               AND  r.relationship_id = rs.relationship_id
                               AND  rs.batch_id = :p_batch_id
                               AND  rs.batch_mode_flag = :p_batch_mode_flag
			       AND  rs.sub_orig_system = :p_os
                               AND  rs.sub_orig_system_reference between :p_from_osr and :p_to_osr ';

l_dqm_rel_sync_rerun_sql VARCHAR2(2000) := 'SELECT   o.org_contact_id, r.object_id
                              FROM   HZ_RELATIONSHIPS r, hz_org_contacts o, hz_imp_relships_sg rs
                              , hz_imp_batch_details bd
                             WHERE   r.request_id = bd.main_conc_req_id 
                               AND bd.batch_id = rs.batch_id 
                               AND   r.directional_flag    = ''F''
                               AND   r.program_update_date > r.creation_date
                               AND   r.relationship_id     = o.party_relationship_id
                               AND   o.status  = ''A''
                               AND  r.relationship_id = rs.relationship_id
                               AND  rs.batch_id = :p_batch_id
                               AND  rs.batch_mode_flag = :p_batch_mode_flag
			       AND  rs.sub_orig_system = :p_os
                               AND  rs.sub_orig_system_reference between :p_from_osr and :p_to_osr ';

c_dqm_rel_sync RefCurType;

 x_return_status               VARCHAR2(1);
 x_msg_count                   NUMBER;
 x_msg_data                    VARCHAR2(2000);
 l_worker_identifier           VARCHAR2(240) := p_request_id || '-' || p_from_osr || '-' || p_to_osr;
 ps_org_contact_id             NUMBER;  
 p_org_contact_id              NUMBER; 
 ps_party_id1                  NUMBER;
 l_ot_id                       NUMBER;
 l_ot_table                    VARCHAR2(60);
 cp_party_type                 VARCHAR2(60);
 cp_party_id                   NUMBER := 0;
 cp_party_id1                  NUMBER;
 cp_org_contact_id             NUMBER;
 cp_party_site_id              NUMBER; 
 loc_party_site_id             NUMBER;      
 loc_party_id1                 NUMBER;    
 loc_party_id                  NUMBER;
 loc_party_type                VARCHAR2(30); 
 loc_org_contact_id            NUMBER;
BEGIN         

  hz_common_pub.enable_cont_source_security; --Bug No:3315740

  fnd_file.put_line(fnd_file.log, '    pp_dqm_sync+');

  /* HZ_PARTIES */
  fnd_file.put_line(fnd_file.log, '    pp_dqm_sync:c_dqm_party_sync+');
  IF p_postprocess_status IS NULL THEN
    OPEN c_dqm_party_sync FOR l_dqm_party_sync_sql
    USING p_request_id, p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  ELSIF p_postprocess_status = 'U' THEN
    OPEN c_dqm_party_sync FOR l_dqm_party_sync_rerun_sql
    USING p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  END IF;

  FETCH c_dqm_party_sync BULK COLLECT INTO
        l_party_id,l_party_type,l_insert_update_flag;
  CLOSE c_dqm_party_sync ;

  fnd_file.put_line(fnd_file.log, '    # of records to process in pp_dqm_sync:c_dqm_party_sync= ' || l_party_id.COUNT);
         
  IF l_party_id.COUNT > 0 THEN
    FOR i IN 1..l_party_id.count 
    LOOP
         BEGIN
            IF    l_party_type(i) = 'ORGANIZATION' then
                  insert_interface_rec(l_party_id(i),null,null,null,'PARTY',l_insert_update_flag(i),l_worker_identifier);
            ELSIF l_party_type(i) = 'PERSON' then
                  insert_interface_rec(l_party_id(i),null,null,null,'PARTY',l_insert_update_flag(i),l_worker_identifier);
               IF l_insert_update_flag(i) = 'U' THEN
                  OPEN c_dqm_person_upd(l_party_id(i));
                  LOOP
                      FETCH c_dqm_person_upd INTO p_org_contact_id;
                      EXIT WHEN c_dqm_person_upd%NOTFOUND;
                      insert_interface_rec(l_party_id(i),p_org_contact_id,null,null,'CONTACTS','U',l_worker_identifier);
                  END LOOP; 
                  CLOSE c_dqm_person_upd; /* Bug 5556468 */
               END IF;
            END IF;
        EXCEPTION         	
        WHEN OTHERS THEN 
             fnd_file.put_line(fnd_file.log,' Unexpected error occured in the post processing DQM sync program
                                              for Party : ' || l_party_id(i));
             RAISE;
       END;
    END LOOP;
  END IF;  
  fnd_file.put_line(fnd_file.log, '    pp_dqm_sync:c_dqm_party_sync-');
    
  /* HZ_PARTY_SITES */
  fnd_file.put_line(fnd_file.log, '    pp_dqm_sync:c_dqm_ps_sync+');

  IF p_postprocess_status IS NULL THEN
    OPEN c_dqm_ps_sync FOR l_dqm_ps_sync_sql
    USING p_request_id, p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  ELSIF p_postprocess_status = 'U' THEN
    OPEN c_dqm_ps_sync FOR l_dqm_ps_sync_rerun_sql
    USING p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  END IF;

  FETCH c_dqm_ps_sync BULK COLLECT INTO
        l_party_site_id,l_party_id,l_party_type,l_insert_update_flag;
  CLOSE c_dqm_ps_sync;
  
  fnd_file.put_line(fnd_file.log, '    # of records to process in pp_dqm_sync:c_dqm_ps_sync= ' || l_party_site_id.COUNT);
         
  IF l_party_site_id.COUNT > 0 THEN
  
    FOR i IN 1..l_party_site_id.count 
      LOOP                     
      BEGIN
        IF l_party_type(i) = 'PARTY_RELATIONSHIP' THEN
                  SELECT r.object_id, org_contact_id INTO ps_party_id1,ps_org_contact_id
                    FROM HZ_ORG_CONTACTS oc, HZ_RELATIONSHIPS r
                   WHERE r.party_id = l_party_id(i)
                     AND r.relationship_id = oc.party_relationship_id
                     AND r.directional_flag='F'
                     AND r.SUBJECT_TABLE_NAME = 'HZ_PARTIES'
                     AND r.OBJECT_TABLE_NAME = 'HZ_PARTIES';
        ELSE
               ps_party_id1      := l_party_id(i);
               ps_org_contact_id := NULL;
        END IF;
        insert_interface_rec(ps_party_id1,l_party_site_id(i),null,ps_org_contact_id,'PARTY_SITES',l_insert_update_flag(i),l_worker_identifier);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
                NULL;
          WHEN OTHERS THEN 
               fnd_file.put_line(fnd_file.log,' Unexpected error occured in the post processing DQM sync program for 
                                                Party Site :' || l_party_site_id(i));
                RAISE;
        END;
    END LOOP;
  END IF;     
  fnd_file.put_line(fnd_file.log, '    pp_dqm_sync:c_dqm_ps_sync-');
     

   /* HZ_CONTACT_POINTS */
  fnd_file.put_line(fnd_file.log, '    pp_dqm_sync:c_dqm_cp_sync+');

  IF p_postprocess_status IS NULL THEN
    OPEN c_dqm_cp_sync FOR l_dqm_cp_sync_sql
    USING p_request_id, p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  ELSIF p_postprocess_status = 'U' THEN
    OPEN c_dqm_cp_sync FOR l_dqm_cp_sync_rerun_sql
    USING p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  END IF;

  FETCH c_dqm_cp_sync BULK COLLECT INTO
          l_contact_point_id,l_insert_update_flag;
  CLOSE   c_dqm_cp_sync;      

  fnd_file.put_line(fnd_file.log, '    # of records to process in pp_dqm_sync:c_dqm_cp_sync= ' || l_contact_point_id.COUNT);
         
  IF l_contact_point_id.COUNT > 0 THEN
         
    FOR i in 1..l_contact_point_id.count
    LOOP
    BEGIN
--           hz_dqm_sync.sync_contact_point(l_contact_point_id(i), l_insert_update_flag(i));
        cp_party_id := 0;
        SELECT owner_table_name,owner_table_id INTO l_ot_table, l_ot_id
          FROM hz_contact_points
         WHERE contact_point_id = l_contact_point_id(i);

        IF l_ot_table = 'HZ_PARTY_SITES' THEN  
              SELECT  p.party_id, ps.party_site_id, party_type
                INTO  cp_party_id1, cp_party_site_id,cp_party_type
                FROM  HZ_PARTY_SITES ps, HZ_PARTIES p
               WHERE  party_site_id = l_ot_id
                 AND  p.party_id    = ps.party_id; 
               IF cp_party_type = 'PARTY_RELATIONSHIP' THEN
                   SELECT  r.object_id, org_contact_id INTO cp_party_id,cp_org_contact_id
                     FROM  HZ_ORG_CONTACTS oc, HZ_RELATIONSHIPS r
                    WHERE  r.party_id           = cp_party_id1
                      AND  r.relationship_id    = oc.party_relationship_id
                      AND  r.directional_flag   ='F'
                      AND  r.SUBJECT_TABLE_NAME = 'HZ_PARTIES'
                      AND  r.OBJECT_TABLE_NAME  = 'HZ_PARTIES';
               ELSE
                  cp_party_id:=cp_party_id1;
                  l_org_contact_id:=NULL;
               END IF;
       ELSIF l_ot_table = 'HZ_PARTIES' THEN
             cp_party_site_id := NULL;      
             SELECT party_type INTO cp_party_type
               FROM hz_parties
              WHERE party_id = l_ot_id;

             IF cp_party_type <> 'PARTY_RELATIONSHIP' THEN
                cp_party_id := l_ot_id;
                cp_org_contact_id:=NULL;
             ELSE
              SELECT r.object_id, org_contact_id INTO cp_party_id,cp_org_contact_id
                FROM HZ_ORG_CONTACTS oc, HZ_RELATIONSHIPS r
               WHERE r.party_id           = l_ot_id
                 AND r.relationship_id    = oc.party_relationship_id
                 AND r.directional_flag   ='F'
                 AND r.SUBJECT_TABLE_NAME = 'HZ_PARTIES'
                 AND r.OBJECT_TABLE_NAME  = 'HZ_PARTIES';
             END IF;
        END IF;                                   

     insert_interface_rec(cp_party_id,l_contact_point_id(i),cp_party_site_id, cp_org_contact_id, 'CONTACT_POINTS',l_insert_update_flag(i),l_worker_identifier);
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
             NULL; 
       WHEN OTHERS THEN 
            fnd_file.put_line(fnd_file.log,' Unexpected error occured in the post processing DQM sync program 
                                             for contact point id  :' ||l_contact_point_id(i) );
            RAISE;
    END;
    END LOOP;
  END IF;       
  fnd_file.put_line(fnd_file.log, '    pp_dqm_sync:c_dqm_cp_sync-');    
    
    
  /* HZ_ORG_CONTACTS */
  fnd_file.put_line(fnd_file.log, '    pp_dqm_sync:c_dqm_contact_sync+');

  IF p_postprocess_status IS NULL THEN
    OPEN c_dqm_contact_sync FOR l_dqm_contact_sync_sql
    USING p_request_id, p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  ELSIF p_postprocess_status = 'U' THEN
    OPEN c_dqm_contact_sync FOR l_dqm_contact_sync_rerun_sql
    USING p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  END IF;

  FETCH c_dqm_contact_sync BULK COLLECT INTO
        l_org_contact_id,l_object_id,l_insert_update_flag;
  CLOSE c_dqm_contact_sync;
  
  fnd_file.put_line(fnd_file.log, '    # of records to process in pp_dqm_sync:c_dqm_contact_sync= ' || l_org_contact_id.COUNT);
         
  IF l_org_contact_id.COUNT > 0 THEN
    FOR i in 1..l_org_contact_id.count
    LOOP
      BEGIN
          insert_interface_rec(l_object_id(i),l_org_contact_id(i),null,null,'CONTACTS',l_insert_update_flag(i),l_worker_identifier);
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,' Unexpected error occured in the post processing DQM sync program 
                                         for Org Contact : ' || l_org_contact_id(i));
        RAISE;
      END; 
   END LOOP;
  END IF;
  fnd_file.put_line(fnd_file.log, '    pp_dqm_sync:c_dqm_contact_sync-');
 
  /* HZ_LOCATIONS */
  fnd_file.put_line(fnd_file.log, '    pp_dqm_sync:c_dqm_loc_sync+');

  IF p_postprocess_status IS NULL THEN
    OPEN c_dqm_loc_sync FOR l_dqm_loc_sync_sql
    USING p_request_id, p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  ELSIF p_postprocess_status = 'U' THEN
    OPEN c_dqm_loc_sync FOR l_dqm_loc_sync_rerun_sql
    USING p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  END IF;

  FETCH c_dqm_loc_sync BULK COLLECT INTO
        l_location_id;
  CLOSE c_dqm_loc_sync;
  fnd_file.put_line(fnd_file.log, '    # of records to process in pp_dqm_sync:c_dqm_contact_sync= ' || l_location_id.COUNT);
            
  IF l_location_id.COUNT > 0 THEN

     FOR i in 1..l_location_id.count
     LOOP
--          hz_dqm_sync.sync_location(l_location_id(i), l_insert_update_flag(i));
            OPEN c_dqm_loc_ps_sync(l_location_id(i));
            LOOP   
            BEGIN
            FETCH c_dqm_loc_ps_sync INTO loc_party_site_id,loc_party_id,loc_party_type;
            EXIT WHEN c_dqm_loc_ps_sync%NOTFOUND;
--            sync_party_site(loc_party_site_id,'U');
                  IF loc_party_type = 'PARTY_RELATIONSHIP' THEN
                     BEGIN
                       SELECT r.object_id, org_contact_id INTO loc_party_id1,loc_org_contact_id
                         FROM HZ_ORG_CONTACTS oc, HZ_RELATIONSHIPS r
                        WHERE r.party_id           = loc_party_id
                          AND r.relationship_id    = oc.party_relationship_id
                          AND r.directional_flag   ='F'
                          AND r.SUBJECT_TABLE_NAME = 'HZ_PARTIES'
                          AND r.OBJECT_TABLE_NAME  = 'HZ_PARTIES';
                     END;
                 ELSE
                     loc_party_id1      := loc_party_id;
                     loc_org_contact_id := NULL;
                END IF;
               insert_interface_rec(loc_party_id1,loc_party_site_id,null,loc_org_contact_id,'PARTY_SITES','U',l_worker_identifier);
               EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                       NULL;
                 WHEN OTHERS THEN 
                      fnd_file.put_line(fnd_file.log,' Unexpected error occured in the post processing DQM sync program 
                                                       for Location : ' || l_location_id(i));
                      RAISE;
               END;
            END LOOP;
           CLOSE c_dqm_loc_ps_sync;
      END LOOP;
  END IF;  
  fnd_file.put_line(fnd_file.log, '    pp_dqm_sync:c_dqm_loc_sync-');
    
 /*  HZ_RELATIONSHIPS */
  fnd_file.put_line(fnd_file.log, '    pp_dqm_sync:c_dqm_rel_sync+');

  IF p_postprocess_status IS NULL THEN
    OPEN c_dqm_rel_sync FOR l_dqm_rel_sync_sql
    USING p_request_id, p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  ELSIF p_postprocess_status = 'U' THEN
    OPEN c_dqm_rel_sync FOR l_dqm_rel_sync_rerun_sql
    USING p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  END IF;
  
  FETCH c_dqm_rel_sync BULK COLLECT INTO
        l_org_contact_id,l_object_id;
  CLOSE c_dqm_rel_sync;

  fnd_file.put_line(fnd_file.log, '    # of records to process in pp_dqm_sync:c_dqm_rel_sync= ' || l_org_contact_id.COUNT);
            
  IF l_org_contact_id.COUNT > 0 THEN
     FOR i in 1..l_org_contact_id.count
     LOOP
      BEGIN
--        hz_dqm_sync.sync_relationship(l_relationship_id(i), l_insert_update_flag(i));
          insert_interface_rec(l_object_id(i),l_org_contact_id(i),null,null,'CONTACTS','U',l_worker_identifier);
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,' Unexpected error occured in the post processing DQM sync program 
                                         for Relationship - Org Contact :  ' || l_org_contact_id(i));
        RAISE;
      END;               
     END LOOP;
  END IF;
  fnd_file.put_line(fnd_file.log, '    pp_dqm_sync:c_dqm_rel_sync-');

-- OfficeDepot: 21-Apr-2008    Rajeev Kamath    Oracle Consulting
-- Following line is commented out to not execute DQM Sync as a part of each bulk import batch
-- We need the staging/inserts into HZ_DQM_SYNC_INTERFACE, so that
-- a future sync job can be used to update the DQM staging tables.
-- OfficeDepot plan is to scheuled DQM Sync to run at specific times per day
-- All of the data in HZ_DQM_SYNC_INTERFACE will not be real-time from bulk import (Based on responsibility)
if (NVL(FND_PROFILE.VALUE('XX_CDH_CONV_ENABLE_DQM_IN_POSTPROCESSING'), 'N') = 'Y') then
    HZ_DQM_SYNC.sync_work_unit_imp (l_worker_identifier,x_return_status,x_msg_count,x_msg_data);
end if;

hz_common_pub.disable_cont_source_security; --Bug No:3315740

fnd_file.put_line(fnd_file.log, '    pp_dqm_sync-');

END pp_dqm_sync;

/*                                                                       *
 *=======================================================================*
 * PROCEDURENAME                                                         *
 *   pp_denorm_rel                                                       *
 *                                                                       *
 * DESCRIPTION                                                           *
 *                                                                       *
 * NOTES                                                                 *
 *                                                                       *
 * MODIFICATION HISTORY                                                  *
 *                                                                       *
 *=======================================================================*/

PROCEDURE pp_denorm_rel (
   p_batch_mode_flag             IN       VARCHAR2,
   p_batch_id                    IN       NUMBER,
   p_os                          IN       VARCHAR2,
   p_from_osr                    IN       VARCHAR2,
   p_to_osr                      IN       VARCHAR2,
   p_request_id                  IN       NUMBER,
   p_postprocess_status          IN       VARCHAR2
  ) IS
CURSOR c_denorm_rel IS select sub_id,
                              decode(rs.relationship_code, 'COMPETITOR_OF','Y','N') comp_flag,
                              decode(rs.relationship_code, 'REFERENCE_FOR' ,'Y','N') ref_flag,
                              decode(rs.relationship_code, 'PARTNER_OF'   ,'Y','N') par_flag
                              from hz_imp_relships_sg rs
                       where rs.batch_mode_flag = p_batch_mode_flag
                       and rs.batch_id = p_batch_id
                       and rs.action_flag = 'I'
                       and rs.sub_orig_system = p_os
                       and rs.sub_orig_system_reference between p_from_osr and p_to_osr
                       and rs.relationship_code IN ('COMPETITOR_OF','REFERENCE_FOR','PARTNER_OF');

BEGIN

  fnd_file.put_line(fnd_file.log, '    pp_denorm_rel+');
  OPEN c_denorm_rel ;
  FETCH c_denorm_rel BULK COLLECT INTO
        l_subject_id,l_comp_flag,l_ref_flag,l_par_flag;
  CLOSE c_denorm_rel ;

  fnd_file.put_line(fnd_file.log, '    # of records to process in pp_denorm_rel = ' || l_subject_id.COUNT);
        
  IF l_subject_id.COUNT = 0 THEN
    RETURN;
  END IF;        

  BEGIN
    IF p_postprocess_status IS NULL THEN
      FORALL i in 1..l_subject_id.count
        UPDATE hz_parties set
               competitor_flag    = decode(l_comp_flag(i),'Y','Y',competitor_flag), 
               reference_use_flag = decode(l_ref_flag(i) ,'Y','Y',reference_use_flag), 
               third_party_flag   = decode(l_par_flag(i) ,'Y','Y',third_party_flag) 
        WHERE party_id           = l_subject_id(i)
        AND   request_id         = p_request_id;
    ELSIF p_postprocess_status = 'U' THEN
      FORALL i in 1..l_subject_id.count
        UPDATE hz_parties set
               competitor_flag    = decode(l_comp_flag(i),'Y','Y',competitor_flag), 
               reference_use_flag = decode(l_ref_flag(i) ,'Y','Y',reference_use_flag), 
               third_party_flag   = decode(l_par_flag(i) ,'Y','Y',third_party_flag) 
        WHERE party_id           = l_subject_id(i)
        AND   request_id IN (SELECT main_conc_req_id FROM hz_imp_batch_details
                             WHERE batch_id = p_batch_id);
    END IF;
  EXCEPTION
      WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,' Unexpected error occured in the post processing
                                           relationship denormalization program ');
           RAISE;
  END;

  fnd_file.put_line(fnd_file.log, '    pp_denorm_rel-');
END pp_denorm_rel;

/*                                                                       *
 *=======================================================================*
 * PROCEDURENAME                                                         *
 *   pp_format_person_name                                               *
 *                                                                       *
 * DESCRIPTION                                                           *
 *                                                                       *
 * NOTES                                                                 *
 *                                                                       *
 * MODIFICATION HISTORY                                                  *
 *                                                                       *
 *=======================================================================*/      

PROCEDURE pp_format_person_name (
   p_batch_mode_flag             IN       VARCHAR2,
   p_batch_id                    IN       NUMBER,
   p_os                          IN       VARCHAR2,
   p_from_osr                    IN       VARCHAR2,
   p_to_osr                      IN       VARCHAR2,
   p_request_id                  IN       NUMBER,
   p_postprocess_status          IN       VARCHAR2
) IS
l_new_sql varchar2(1300) := 'SELECT  p.party_id 
                               ,p.person_title
                               ,p.person_first_name
                               ,p.person_middle_name
                               ,p.person_last_name
                               ,p.person_name_suffix
                               ,p.known_as
                               ,p.person_first_name_phonetic
                               ,pf.middle_name_phonetic
                               ,p.person_last_name_phonetic
                         FROM  HZ_PARTIES p, HZ_PERSON_PROFILES pf, HZ_IMP_PARTIES_SG ps
                        WHERE  p.request_id = :p_request_id 
                          AND  p.party_type  = ''PERSON''
                          AND  p.party_id    = pf.party_id 
                          AND  pf.effective_end_date is NULL 
                          AND  p.party_id = ps.party_id
                          AND  ps.batch_id = :p_batch_id
                          AND  ps.party_orig_system = :p_os
                          AND  ps.party_orig_system_reference between :p_from_osr and :p_to_osr
                          AND  ps.batch_mode_flag = :p_batch_mode_flag';                          

l_rerun_sql varchar2(1300) := 'SELECT  p.party_id 
                               ,p.person_title
                               ,p.person_first_name
                               ,p.person_middle_name
                               ,p.person_last_name
                               ,p.person_name_suffix
                               ,p.known_as
                               ,p.person_first_name_phonetic
                               ,pf.middle_name_phonetic
                               ,p.person_last_name_phonetic
                         FROM  HZ_PARTIES p, HZ_PERSON_PROFILES pf, HZ_IMP_PARTIES_SG ps, hz_imp_batch_details bd
                        WHERE  p.request_id = bd.main_conc_req_id 
                          AND   bd.batch_id = ps.batch_id 
                          AND  p.party_type  = ''PERSON''
                          AND  p.party_id    = pf.party_id 
                          AND  pf.effective_end_date is NULL 
                          AND  p.party_id = ps.party_id
                          AND  ps.batch_id = :p_batch_id
                          AND  ps.party_orig_system = :p_os
                          AND  ps.party_orig_system_reference between :p_from_osr and :p_to_osr
                          AND  ps.batch_mode_flag = :p_batch_mode_flag';          
                          
l_person_name  HZ_PARTIES.PARTY_NAME%TYPE;
c_person_name  RefCurType;

BEGIN

  fnd_file.put_line(fnd_file.log, '    pp_format_person_name+');
  IF p_postprocess_status IS NULL THEN
    OPEN c_person_name FOR l_new_sql
    USING p_request_id, p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  ELSIF p_postprocess_status = 'U' THEN
    OPEN c_person_name FOR l_rerun_sql
    USING p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  END IF;
  
  FETCH c_person_name BULK COLLECT INTO
        l_party_id, l_person_title,l_person_first_name,l_person_middle_name,l_person_last_name,
        l_person_name_suffix,l_known_as,l_person_first_name_phonetic,
        l_middle_name_phonetic,l_person_last_name_phonetic;
  CLOSE c_person_name;

  fnd_file.put_line(fnd_file.log, '    # of records to process in pp_format_person_name = ' || l_party_id.COUNT);
  IF l_party_id.COUNT = 0 THEN
    RETURN;
  END IF;

  FOR i in 1..l_party_id.count 
    LOOP
      BEGIN
        hz_format_pub.format_name (
          -- input parameters
          p_person_title                => l_person_title(i),
          p_person_first_name           => l_person_first_name(i),
          p_person_middle_name          => l_person_middle_name(i),
          p_person_last_name            => l_person_last_name(i),
          p_person_name_suffix          => l_person_name_suffix(i),
          p_person_known_as             => l_known_as(i),
          p_first_name_phonetic         => l_person_first_name_phonetic(i),
          p_middle_name_phonetic        => l_middle_name_phonetic(i),
          p_last_name_phonetic          => l_person_last_name_phonetic(i),
          -- output parameters
          x_return_status               => l_return_status,
          x_msg_count                   => l_msg_count,
          x_msg_data                    => l_msg_data,
          x_formatted_name              => l_person_name,
          x_formatted_lines_cnt         => l_formatted_lines_cnt,
          x_formatted_name_tbl          => l_formatted_name_tbl
        );
         
        IF l_return_status <> fnd_api.g_ret_sts_success THEN 
          l_person_name := NULL;
        END IF;
        UPDATE hz_person_profiles 
          SET person_name = l_person_name
        WHERE party_id    = l_party_id(i)
        AND  effective_end_date is NULL;

        UPDATE hz_parties 
           SET party_name = substrb(l_person_name,1,360)
        WHERE party_id    = l_party_id(i); 

      EXCEPTION
      WHEN OTHERS THEN
           fnd_file.put_line(fnd_file.log,' Unexpected error occured in the post processing person name format program
                                            for Party : ' || l_party_id(i));
           RAISE;  
      END;

     END LOOP; 
   fnd_file.put_line(fnd_file.log, '    pp_format_person_name-');

END pp_format_person_name;

/*                                                                       *
 *=======================================================================*
 * PROCEDURENAME                                                         *
 *   pp_generate_cust_key                                                *
 *                                                                       *
 * DESCRIPTION                                                           *
 *                                                                       *
 * NOTES                                                                 *
 *                                                                       *
 * MODIFICATION HISTORY                                                  *
 *                                                                       *
 *=======================================================================*/
 
PROCEDURE pp_generate_cust_key (
   p_batch_mode_flag             IN       VARCHAR2,
   p_batch_id                    IN       NUMBER,
   p_os                          IN       VARCHAR2,
   p_from_osr                    IN       VARCHAR2,
   p_to_osr                      IN       VARCHAR2,
   p_request_id                  IN       NUMBER,
   p_generate_fuzzy_key          IN       VARCHAR2,
   p_enable_dqm_sync             IN       VARCHAR2,
   p_postprocess_status          IN       VARCHAR2
  ) IS
l_new_sql varchar2(1100) := 'SELECT p.party_id 
                                ,p.party_type
                                ,p.party_name
                                ,p.person_first_name
                                ,p.person_last_name
                                ,null record_id
                                ,''PARTY'' entity
                                ,decode(ps.action_flag, ''I'', ''C'', ps.action_flag) operation_flag
                          FROM   hz_parties p, HZ_IMP_PARTIES_SG ps
                         WHERE   p.request_id =    :p_request_id 
                           AND   p.party_type IN (''ORGANIZATION'',''PERSON'',''GROUP'') 
                           AND   p.party_id = ps.party_id
                           AND   ps.batch_id = :p_batch_id
                           AND   ps.party_orig_system = :p_os
                           AND   ps.party_orig_system_reference between :p_from_osr and :p_to_osr
                           AND   ps.batch_mode_flag = :p_batch_mode_flag';

l_rerun_sql varchar2(1100) := 'SELECT p.party_id 
                                ,p.party_type
                                ,p.party_name
                                ,p.person_first_name
                                ,p.person_last_name
                                ,null record_id
                                ,''PARTY'' entity
                                ,decode(ps.action_flag, ''I'', ''C'', ps.action_flag) operation_flag
                          FROM   hz_parties p, HZ_IMP_PARTIES_SG ps, hz_imp_batch_details bd
                         WHERE   p.request_id = bd.main_conc_req_id 
                           AND   bd.batch_id = ps.batch_id
                           AND   p.party_type IN (''ORGANIZATION'',''PERSON'',''GROUP'') 
                           AND   p.party_id = ps.party_id
                           AND   ps.batch_id = :p_batch_id
                           AND   ps.party_orig_system = :p_os
                           AND   ps.party_orig_system_reference between :p_from_osr and :p_to_osr
                           AND   ps.batch_mode_flag = :p_batch_mode_flag';
                           
l_return_status                         VARCHAR2(1);
l_msg_count                             NUMBER;
l_msg_data                              VARCHAR2(2000);  
c_gen_cust_key RefCurType;

BEGIN

  fnd_file.put_line(fnd_file.log, '    pp_generate_cust_key+');

  IF p_postprocess_status IS NULL THEN
  fnd_file.put_line(fnd_file.log, 'p_postprocess_status IS NULL');  

    OPEN c_gen_cust_key FOR l_new_sql
    USING p_request_id, p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  ELSIF p_postprocess_status = 'U' THEN
  fnd_file.put_line(fnd_file.log, 'p_postprocess_status IS -NOT- NULL');  
    OPEN c_gen_cust_key FOR l_rerun_sql
    USING p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  END IF;

  FETCH c_gen_cust_key BULK COLLECT INTO
        l_party_id,l_party_type,l_party_name,l_person_first_name,l_person_last_name,
        l_record_id, l_entity, l_operation;
  CLOSE c_gen_cust_key ;

  fnd_file.put_line(fnd_file.log, '    # of records to process in pp_generate_cust_key = ' || l_party_id.COUNT);
  IF l_party_id.COUNT = 0 THEN
    RETURN;
  END IF;

  IF (p_generate_fuzzy_key = 'Y') THEN 
  FOR i in 1..l_party_id.count
    LOOP
    BEGIN
      l_key := HZ_FUZZY_PUB.Generate_Key (
                             p_key_type    => l_party_type(i),
                             p_party_name  => l_party_name(i),
                             p_address1    => NULL,
                             p_address2    => NULL,
                             p_address3    => NULL,
                             p_address4    => NULL,
                             p_postal_code => NULL,
                             p_first_name  => l_person_first_name(i),
                             p_last_name   => l_person_last_name(i));

      UPDATE HZ_PARTIES
      SET   customer_key = l_key
      WHERE  party_id    = l_party_id(i);
    EXCEPTION
        WHEN OTHERS THEN
           fnd_file.put_line(fnd_file.log,' Unexpected error occured in the post processing customer key generation program
                                            for Party :  ' || l_party_id(i));
           RAISE;
    END; 
  END LOOP;
  
  END IF;
  fnd_file.put_line(fnd_file.log, '    pp_generate_cust_key-');
  
END pp_generate_cust_key;

/*                                                                       *
 *=======================================================================*
 * PROCEDURENAME                                                         *
 *   pp_generate_addr_key                                                *
 *                                                                       *
 * DESCRIPTION                                                           *
 *                                                                       *
 * NOTES                                                                 *
 *                                                                       *
 * MODIFICATION HISTORY                                                  *
 *                                                                       *
 *=======================================================================*/
                                      
PROCEDURE pp_generate_addr_key (
   p_batch_mode_flag             IN       VARCHAR2,
   p_batch_id                    IN       NUMBER,
   p_os                          IN       VARCHAR2,
   p_from_osr                    IN       VARCHAR2,
   p_to_osr                      IN       VARCHAR2,
   p_request_id                  IN       NUMBER,
   p_generate_fuzzy_key          IN       VARCHAR2,
   p_enable_dqm_sync             IN       VARCHAR2,
   p_postprocess_status          IN       VARCHAR2
  ) IS
l_new_sql varchar2(1300) := 'SELECT l.location_id
                                ,l.address1
                                ,l.address2
                                ,l.address3
                                ,l.address4
                                ,l.postal_code
                                ,null party_id
                                ,ps.party_site_id record_id
				,''PARTY_SITES'' entity
				,decode(addr_sg.action_flag, ''I'', ''C'', addr_sg.action_flag) operation_flag
                                ,null party_type
                           FROM hz_locations l, hz_party_sites ps,
                                hz_imp_addresses_sg addr_sg
                          WHERE l.request_id = :p_request_id 
                                and l.location_id = ps.location_id
                                and addr_sg.batch_id = :p_batch_id
                                and addr_sg.batch_mode_flag = :p_batch_mode_flag
                                and addr_sg.party_orig_system = :p_os
                                and addr_sg.party_orig_system_reference between :p_from_osr and :p_to_osr
                                and addr_sg.party_site_id = ps.party_site_id';

l_rerun_sql varchar2(1300) := 'SELECT l.location_id
                                ,l.address1
                                ,l.address2
                                ,l.address3
                                ,l.address4
                                ,l.postal_code
                                ,null party_id
                                ,ps.party_site_id record_id
				,''PARTY_SITES'' entity
				,decode(addr_sg.action_flag, ''I'', ''C'', addr_sg.action_flag) operation_flag
                                ,null party_type
                           FROM hz_locations l, hz_party_sites ps,
                                hz_imp_addresses_sg addr_sg, hz_imp_batch_details bd
                          WHERE l.request_id = bd.main_conc_req_id 
                                and bd.batch_id = addr_sg.batch_id 
                                and l.location_id = ps.location_id
                                and addr_sg.batch_id = :p_batch_id
                                and addr_sg.batch_mode_flag = :p_batch_mode_flag
                                and addr_sg.party_orig_system = :p_os
                                and addr_sg.party_orig_system_reference between :p_from_osr and :p_to_osr
                                and addr_sg.party_site_id = ps.party_site_id';
                                
l_return_status                         VARCHAR2(1);
l_msg_count                             NUMBER;
l_msg_data                              VARCHAR2(2000);  
c_gen_addr_key RefCurType;

BEGIN

  fnd_file.put_line(fnd_file.log, '    pp_generate_addr_key+');
  IF p_postprocess_status IS NULL THEN
    OPEN c_gen_addr_key FOR l_new_sql
    USING p_request_id, p_batch_id, p_batch_mode_flag, p_os, p_from_osr, p_to_osr;
  ELSIF p_postprocess_status = 'U' THEN
    OPEN c_gen_addr_key FOR l_rerun_sql
    USING p_batch_id, p_batch_mode_flag, p_os, p_from_osr, p_to_osr;
  END IF;
  
  FETCH c_gen_addr_key BULK COLLECT INTO
        l_location_id,l_address1,l_address2,l_address3,l_address4,l_postal_code,
        l_party_id, l_record_id, l_entity, l_operation, l_party_type;
  CLOSE c_gen_addr_key ;

  fnd_file.put_line(fnd_file.log, '    # of records to process in pp_generate_addr_key = ' || l_location_id.COUNT);
      
  IF l_location_id.COUNT = 0 THEN
    RETURN;
  END IF;

  IF (p_generate_fuzzy_key = 'Y') THEN 
  FOR i in 1..l_location_id.count
    LOOP
      BEGIN
        l_key := HZ_FUZZY_PUB.Generate_Key (
                             p_key_type    => 'ADDRESS',
                             p_party_name  => NULL,
                             p_address1    => l_address1(i),
                             p_address2    => l_address2(i),
                             p_address3    => l_address3(i),
                             p_address4    => l_address4(i),
                             p_postal_code => l_postal_code(i),
                             p_first_name  => NULL,
                             p_last_name   => NULL);

        UPDATE HZ_LOCATIONS
        SET   address_key    = l_key
        WHERE  location_id    = l_location_id(i);
      EXCEPTION
        WHEN OTHERS THEN
           fnd_file.put_line(fnd_file.log,' Unexpected error occured in the post processing address key generation program 
                                            for location : ' || l_location_id(i) );
           RAISE;
      END;   
  END LOOP;
  END IF;
  
  fnd_file.put_line(fnd_file.log, '    pp_generate_addr_key-');

END pp_generate_addr_key;

/*                                                                       *
 *=======================================================================*
 * PROCEDURENAME                                                         *
 *   pp_rel_party_name                                                   *
 *                                                                       *
 * DESCRIPTION                                                           *
 *                                                                       *
 * NOTES                                                                 *
 *                                                                       *
 * MODIFICATION HISTORY                                                  *
 *                                                                       *
 *=======================================================================*/  
 
PROCEDURE pp_rel_party_name (
   p_batch_mode_flag             IN       VARCHAR2,
   p_batch_id                    IN       NUMBER,
   p_os                          IN       VARCHAR2,
   p_from_osr                    IN       VARCHAR2,
   p_to_osr                      IN       VARCHAR2,
   p_request_id                  IN       NUMBER,
   p_postprocess_status          IN       VARCHAR2
  ) IS

l_new_sql varchar2(2000) := 'SELECT  r.party_id,s.party_name, 
                                    o.party_name ,r.party_number 
                             FROM  hz_parties s, hz_parties o, hz_parties r, HZ_IMP_PARTIES_SG ps,
                                   hz_relationships rel
                             WHERE r.request_id  = :p_request_id 
                             AND  ps.batch_id = :p_batch_id
                             AND  ps.party_orig_system = :p_os
                             AND  ps.party_orig_system_reference between :p_from_osr and :p_to_osr
                             AND  ps.batch_mode_flag = :p_batch_mode_flag
                             AND  r.party_id = ps.party_id  
                             AND  r.party_type         = ''PARTY_RELATIONSHIP''
			     AND  r.party_id           = rel.party_id 
			     AND  rel.directional_flag = ''F''
			     AND  rel.object_id        = o.party_id 
			     AND  rel.subject_id       = s.party_id
			     AND  rel.party_id IS NOT NULL 
			     AND rel.subject_table_name= ''HZ_PARTIES''
			     AND rel.object_table_name = ''HZ_PARTIES'' ' ;
			     
l_rerun_sql varchar2(2000) := 'SELECT  r.party_id,s.party_name, 
                                    o.party_name ,r.party_number 
                             FROM  hz_parties s, hz_parties o, hz_parties r, HZ_IMP_PARTIES_SG ps,
                                   hz_relationships rel, hz_imp_batch_details bd
                             WHERE r.request_id  = bd.main_conc_req_id 
                             AND   bd.batch_id = ps.batch_id 
                             AND  ps.batch_id = :p_batch_id
                             AND  ps.party_orig_system = :p_os
                             AND  ps.party_orig_system_reference between :p_from_osr and :p_to_osr
                             AND  ps.batch_mode_flag = :p_batch_mode_flag
                             AND  r.party_id = ps.party_id  
                             AND  r.party_type         = ''PARTY_RELATIONSHIP''
			     AND  r.party_id           = rel.party_id 
			     AND  rel.directional_flag = ''F''
			     AND  rel.object_id        = o.party_id 
			     AND  rel.subject_id       = s.party_id
			     AND  rel.party_id IS NOT NULL 
			     AND rel.subject_table_name= ''HZ_PARTIES''
			     AND rel.object_table_name = ''HZ_PARTIES''  ' ;

c_rel_party_name  RefCurType;

BEGIN

  fnd_file.put_line(fnd_file.log, '    pp_rel_party_name+');
  IF p_postprocess_status IS NULL THEN
    OPEN c_rel_party_name FOR l_new_sql
    USING p_request_id, p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  ELSIF p_postprocess_status = 'U' THEN
    OPEN c_rel_party_name FOR l_rerun_sql
    USING p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  END IF;
  
  FETCH c_rel_party_name BULK COLLECT INTO
        l_rel_party_id, l_subject_name,l_object_name,l_rel_party_number;
  CLOSE c_rel_party_name;

  fnd_file.put_line(fnd_file.log, '    # of records to process in pp_rel_party_name = ' || l_rel_party_id.COUNT);
  IF l_rel_party_id.COUNT = 0 THEN
    RETURN;
  END IF;

  BEGIN
    FORALL i in 1..l_rel_party_id.count
        UPDATE HZ_PARTIES SET 
               PARTY_NAME = SUBSTRB(l_subject_name(I) || '-' || l_object_name(I) || '-' || 
                                    l_rel_party_number(I),1,360) 
         WHERE PARTY_ID = l_rel_party_id(I);  
  EXCEPTION
      WHEN OTHERS THEN   
           fnd_file.put_line(fnd_file.log,' Unexpected error occured in the post processing 
                                            formating relationship party name program ');
           RAISE;
  END;
  fnd_file.put_line(fnd_file.log, '    pp_rel_party_name-');  
   
END pp_rel_party_name;  

/*                                                                       *
 *=======================================================================*
 * PROCEDURENAME                                                         *
 *   pp_denorm_title                                                     *
 *                                                                       *
 * DESCRIPTION                                                           *
 *                                                                       *
 * NOTES                                                                 *
 *                                                                       *
 * MODIFICATION HISTORY                                                  *
 *                                                                       *
 *=======================================================================*/  
PROCEDURE pp_denorm_title (
   p_batch_mode_flag             IN       VARCHAR2,
   p_batch_id                    IN       NUMBER,
   p_os                          IN       VARCHAR2,
   p_from_osr                    IN       VARCHAR2,
   p_to_osr                      IN       VARCHAR2,
   p_request_id                  IN       NUMBER,
   p_postprocess_status          IN       VARCHAR2
  ) IS

l_new_sql varchar2(1100) := 'SELECT p.party_id, o.title 
                       FROM hz_org_contacts o, hz_imp_contacts_sg ocsg, hz_relationships r, hz_parties p
                       WHERE ocsg.batch_mode_flag = :p_batch_mode_flag
                         and ocsg.batch_id = :p_batch_id
                         and ocsg.sub_orig_system = :p_os
                         and ocsg.sub_orig_system_reference between :p_from_osr and :p_to_osr
                         and ocsg.contact_id = o.org_contact_id
                         and o.request_id = :p_request_id
                         AND o.party_relationship_id = r.relationship_id
                         AND r.directional_flag      = ''F''
                         AND r.subject_id            = p.party_id 
                         AND p.party_type            = ''PERSON''
                         AND p.person_pre_name_adjunct is NULL
                         AND o.title IS NOT NULL ';

l_rerun_sql varchar2(1100) := 'SELECT p.party_id, o.title 
                       FROM hz_org_contacts o, hz_imp_contacts_sg ocsg, hz_relationships r, hz_parties p, 
                            hz_imp_batch_details bd
                       WHERE ocsg.batch_mode_flag = :p_batch_mode_flag
                         and ocsg.batch_id = :p_batch_id
                         and ocsg.sub_orig_system = :p_os
                         and ocsg.sub_orig_system_reference between :p_from_osr and :p_to_osr
                         and ocsg.contact_id = o.org_contact_id
                         and o.request_id = bd.main_conc_req_id 
                         and bd.batch_id = ocsg.batch_id
                         AND o.party_relationship_id = r.relationship_id
                         AND r.directional_flag      = ''F''
                         AND r.subject_id            = p.party_id 
                         AND p.party_type            = ''PERSON''
                         AND p.person_pre_name_adjunct is NULL
                         AND o.title IS NOT NULL ';
                         
c_denorm_title RefCurType;

BEGIN

  fnd_file.put_line(fnd_file.log, '    pp_denorm_title+');

  IF p_postprocess_status IS NULL THEN
    OPEN c_denorm_title FOR l_new_sql
    USING p_batch_mode_flag, p_batch_id, p_os, p_from_osr, p_to_osr, p_request_id;
  ELSIF p_postprocess_status = 'U' THEN
    OPEN c_denorm_title FOR l_rerun_sql
    USING p_batch_mode_flag, p_batch_id, p_os, p_from_osr, p_to_osr;
  END IF;
     
  FETCH c_denorm_title BULK COLLECT INTO 
    l_party_id,l_title;
  CLOSE c_denorm_title;
  
  fnd_file.put_line(fnd_file.log, '    # of records to process in c_denorm_title = ' || l_party_id.COUNT);
        
  IF l_party_id.COUNT = 0 THEN
    RETURN;
  END IF;

  BEGIN
    FORALL i in 1..l_party_id.count
         UPDATE HZ_PARTIES SET 
                PERSON_PRE_NAME_ADJUNCT = l_title(i)
         WHERE  party_id = l_party_id(i);

    FORALL i in 1..l_party_id.count
          UPDATE HZ_PERSON_PROFILES SET 
                 PERSON_PRE_NAME_ADJUNCT = l_title(i)
          WHERE  PARTY_ID = l_party_id(i) 
            AND  EFFECTIVE_END_DATE is NULL;
   EXCEPTION
      WHEN OTHERS THEN
           fnd_file.put_line(fnd_file.log,' Unexpected error occured in the post processing title denorm program '  );
           RAISE;
  END;
  fnd_file.put_line(fnd_file.log, '    pp_denorm_title-');
  
END pp_denorm_title;

/*                                                                       *
 *=======================================================================*
 * PROCEDURENAME                                                         *
 *   pp_dnb_hierarchy                                                     *
 *                                                                       *
 * DESCRIPTION                                                           *
 *                                                                       *
 * NOTES                                                                 *
 *                                                                       *
 * MODIFICATION HISTORY                                                  *
 *                                                                       *
 *=======================================================================*/  

PROCEDURE pp_dnb_hierarchy (
   p_batch_mode_flag             IN       VARCHAR2,
   p_batch_id                    IN       NUMBER,
   p_os                          IN       VARCHAR2,
   p_from_osr                    IN       VARCHAR2,
   p_to_osr                      IN       VARCHAR2
  ) IS  
                         

CURSOR c_party IS 
  SELECT r.object_id,r.subject_id, r.relationship_code
  FROM hz_imp_parties_sg ps,hz_imp_relships_sg rs,hz_relationships r
  WHERE ps.batch_id = p_batch_id 
  AND  ps.batch_mode_flag = p_batch_mode_flag
  AND  ps.party_orig_system_reference BETWEEN p_from_osr AND p_to_osr
  AND  ps.party_orig_system = 'DNB' 
  AND  ps.party_id = rs.obj_id
  AND  rs.batch_mode_flag = p_batch_mode_flag
  AND  rs.action_flag = 'I'
  AND  rs.batch_id = p_batch_id			 
  AND  r.subject_id = rs.sub_id
  AND  r.relationship_type IN ('HEADQUARTERS/DIVISION','PARENT/SUBSIDIARY',
			        'DOMESTIC_ULTIMATE','GLOBAL_ULTIMATE') 
  AND  r.relationship_code IN ('PARENT_OF','HEADQUARTERS_OF',
			        'DOMESTIC_ULTIMATE_OF','GLOBAL_ULTIMATE_OF')
  AND  r.object_table_name = 'HZ_PARTIES'
  AND  r.relationship_id = rs.relationship_id
  AND  r.directional_flag = 'F'
  ORDER BY r.object_id;		 
   
l_dup_party_id     NUMBER;
l_gup_party_id     NUMBER;        
l_parent_party_id  NUMBER;
l_parent_type_flg  VARCHAR2(1); 
l_prev_obj_id      NUMBER;
p_init_msg_list    VARCHAR2(1);                                      
l_msg_data         VARCHAR2(2000);
l_msg_count        NUMBER;

BEGIN

  fnd_file.put_line(fnd_file.log, '    pp_dnb_hierarchy+');                                  
  OPEN  c_party;
  FETCH c_party BULK COLLECT INTO
        l_object_id,l_subject_id,l_relationship_code;
  CLOSE c_party;   

  fnd_file.put_line(fnd_file.log, '    # of records to process in pp_dnb_hierarchy = ' || l_object_id.COUNT);
        
  IF l_object_id.COUNT = 0 THEN
    RETURN;
  END IF;
    
  BEGIN  
    FOR j in 1..l_object_id.count LOOP
    
      IF l_prev_obj_id IS NOT NULL AND l_prev_obj_id <> l_object_id(j) THEN   
        fnd_file.put_line(fnd_file.log, '    create dnb hierarchy for : ' || l_prev_obj_id || 
                                        ' parent ' || l_parent_party_id || ' type ' || l_parent_type_flg ||
                                        ' dup ' || l_dup_party_id || ' gup ' || l_gup_party_id );
      
        HZ_DNB_HIERARCHY_PVT.conform_party_to_dnb_hierarchy( p_init_msg_list,        
	                                                     l_prev_obj_id,
	                                                     l_parent_party_id,
	                                                     l_dup_party_id,
	                                                     l_gup_party_id,
	                                                     l_parent_type_flg,
	                                                     l_return_status,
	                                                     l_msg_count,
	                                                     l_msg_data
	                                                   );            

        -- Bug 5264069 : re-initialize local variables for each record in bulk collection
        l_dup_party_id     := null;
        l_gup_party_id     := null;        
        l_parent_party_id  := null;
        l_parent_type_flg  := null;          
      END IF;  

      IF      l_relationship_code(j)  = 'HEADQUARTERS_OF' THEN
              l_parent_party_id      := l_subject_id(j);
              l_parent_type_flg      := 'H';
              fnd_file.put_line(fnd_file.log, ' obj ' || l_object_id(j) || ' HQ ' || l_parent_party_id);
      ELSIF   l_relationship_code(j)  = 'PARENT_OF' THEN    
              l_parent_party_id      := l_subject_id(j);
              l_parent_type_flg      := 'P';
              fnd_file.put_line(fnd_file.log, ' obj ' || l_object_id(j) || ' par ' || l_parent_party_id);
      ELSIF   l_relationship_code(j)  = 'DOMESTIC_ULTIMATE_OF' THEN
              l_dup_party_id         := l_subject_id(j);
              fnd_file.put_line(fnd_file.log, ' obj ' || l_object_id(j) || ' dup ' || l_dup_party_id);
      ELSIF   l_relationship_code(j)  = 'GLOBAL_ULTIMATE_OF' THEN
              l_gup_party_id         := l_subject_id(j);
              fnd_file.put_line(fnd_file.log, ' obj ' || l_object_id(j) || ' gup ' || l_gup_party_id);
      END IF;
      
      l_prev_obj_id := l_object_id(j);
        
    END LOOP;    
    
    -- Call HZ_DNB_HIERARCHY_PVT for last set of data 
    fnd_file.put_line(fnd_file.log, '    create dnb hierarchy for : ' || l_prev_obj_id || 
                                    ' parent ' || l_parent_party_id || ' type ' || l_parent_type_flg ||
                                    ' dup ' || l_dup_party_id || ' gup ' || l_gup_party_id );
     
    HZ_DNB_HIERARCHY_PVT.conform_party_to_dnb_hierarchy( p_init_msg_list,        
                                                         l_prev_obj_id,
                                                         l_parent_party_id,
                                                         l_dup_party_id,
                                                         l_gup_party_id,
                                                         l_parent_type_flg,
                                                         l_return_status,
                                                         l_msg_count,
                                                         l_msg_data
                                                       );            
    
  EXCEPTION 
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,
                         ' Unexpected error occured in the post processing dnb hierarchy program for party : ' || l_prev_obj_id);
        RAISE;
  END;
    
  fnd_file.put_line(fnd_file.log, '    pp_dnb_hierarchy-');

END pp_dnb_hierarchy;                         

/*                                                                       *
 *=======================================================================*
 * PROCEDURENAME                                                         *
 *   pp_generate_loc_assignments                                         *
 *                                                                       *
 * DESCRIPTION                                                           *
 *                                                                       *
 * NOTES                                                                 *
 *                                                                       *
 * MODIFICATION HISTORY                                                  *
 *                                                                       *
 *=======================================================================*/
                                      
PROCEDURE pp_generate_loc_assignments (
   p_batch_mode_flag             IN       VARCHAR2,
   p_batch_id                    IN       NUMBER,
   p_os                          IN       VARCHAR2,
   p_from_osr                    IN       VARCHAR2,
   p_to_osr                      IN       VARCHAR2
  ) IS                          
CURSOR c_loc IS SELECT ps.location_id,ps.created_by_module,site_sg.site_orig_system_reference
                FROM   hz_imp_addresses_sg site_sg,
                       hz_imp_addresses_int site_int,
                       hz_party_sites ps
               WHERE   site_sg.batch_id              = p_batch_id
                 AND   site_sg.batch_mode_flag       = p_batch_mode_flag
                 AND   site_sg.site_orig_system      = p_os
                 AND   site_sg.site_orig_system_reference between p_from_osr and p_to_osr
                 AND   site_sg.action_flag           = 'U'   
                 AND   site_sg.int_row_id            = site_int.rowid
                 AND   site_int.correct_move_indicator = 'C'
                 AND   site_int.interface_status IS NULL  /* check if any validation error */
                 AND   site_sg.party_site_id         = ps.party_site_id;    
                 
l_msg_count                             NUMBER;
l_msg_data                              VARCHAR2(2000);                 
l_loc_id                                NUMBER; 
l_org_id                                VARCHAR2(2000);                 
msg                                     VARCHAR2(2000);

BEGIN       

  fnd_file.put_line(fnd_file.log, '    pp_generate_loc_assignments+');
  OPEN c_loc;
  FETCH c_loc BULK COLLECT INTO l_location_id,l_created_by_module,l_site_orig_system_reference;
  CLOSE c_loc;      
  fnd_file.put_line(fnd_file.log, '    # of records to process in pp_generate_loc_assignments = ' || l_location_id.COUNT);

  IF l_location_id.COUNT = 0 THEN
    RETURN;
  END IF;

  BEGIN
    FOR i in 1..l_location_id.count    
    LOOP
      BEGIN
        HZ_TAX_ASSIGNMENT_V2PUB.update_loc_assignment (
                                       p_location_id                  => l_location_id(i),
                                       p_created_by_module            => l_created_by_module(i),
                                       p_application_id               => 222,
                                       x_return_status                => x_return_status,
                                       x_msg_count                    => l_msg_count,
                                       x_msg_data                     => l_msg_data,
                                       x_loc_id                       => l_loc_id,
                                       x_org_id                       => l_org_id );       
        IF l_org_id IS NOT NULL THEN
                  FND_MESSAGE.SET_NAME('AR', 'HZ_LOC_ASSIGN_ERROR');
                  FND_MESSAGE.SET_TOKEN('LOCATION_ID', l_location_id(i));
                  FND_MESSAGE.SET_TOKEN('SITE_OSR', l_site_orig_system_reference(i));
                  FND_MESSAGE.SET_TOKEN('ORG_ID',l_org_id );   
                  msg := FND_MESSAGE.GET;  
                  fnd_file.put_line('    ' || fnd_file.log,msg);
        END IF;               
      EXCEPTION
      WHEN OTHERS THEN     
        fnd_file.put_line(fnd_file.log,' Unexpected error occured in the post processing loc assignment generation program
                                                    for Location :  ' || l_location_id(i) );
        RAISE;
      END;
    END LOOP;
  END;
  fnd_file.put_line(fnd_file.log, '    pp_generate_loc_assignments-');

END pp_generate_loc_assignments;

/*                                                                       *
 *=======================================================================*
 * PROCEDURENAME                                                         *
 *   pp_generate_loc_timezone                                         *
 *                                                                       *
 * DESCRIPTION                                                           *
 *                                                                       *
 * NOTES                                                                 *
 *                                                                       *
 * MODIFICATION HISTORY                                                  *
 *                                                                       *
 *=======================================================================*/

PROCEDURE pp_generate_loc_timezone (
   p_batch_mode_flag             IN       VARCHAR2,
   p_batch_id                    IN       NUMBER,
   p_os                          IN       VARCHAR2,
   p_from_osr                    IN       VARCHAR2,
   p_to_osr                      IN       VARCHAR2,
   p_request_id                  IN       NUMBER,
   p_g_miss_char                 IN       VARCHAR2
  ) IS         
l_timezone_id                           NUMBER;
l_msg_count                             NUMBER;
l_msg_data                              VARCHAR2(2000);                 

cursor c_timezone_loc is
select l.location_id, l.country, l.state, l.city, l.postal_code
from   hz_locations l,hz_imp_addresses_int addr_int, hz_imp_addresses_sg addr_sg,
       hz_party_sites ps
where  l.location_id = ps.location_id
  and addr_sg.batch_id = p_batch_id
  and addr_sg.batch_mode_flag = p_batch_mode_flag
  and addr_sg.party_orig_system = p_os
  and addr_sg.party_orig_system_reference between p_from_osr and p_to_osr
  and addr_sg.int_row_id = addr_int.rowid
  and addr_sg.party_site_id = ps.party_site_id
  AND  addr_int.timezone_code IS NULL
  AND  addr_int.interface_status IS NULL
  AND  (decode(addr_int.COUNTRY,p_g_miss_char,NULL,addr_int.COUNTRY) IS NOT NULL  OR
	decode(addr_int.STATE,p_g_miss_char,NULL,addr_int.STATE) IS NOT NULL    OR
	decode(addr_int.CITY,p_g_miss_char,NULL,addr_int.CITY) IS NOT NULL     OR
	decode(addr_int.POSTAL_CODE,p_g_miss_char,NULL,addr_int.POSTAL_CODE) IS NOT NULL);

BEGIN  

  fnd_file.put_line(fnd_file.log, '    pp_generate_loc_timezone+');
  OPEN c_timezone_loc;
  FETCH c_timezone_loc BULK COLLECT INTO l_location_id,l_country,l_state,l_city,l_postal_code;
  CLOSE c_timezone_loc;
  fnd_file.put_line(fnd_file.log, '    # of records to process in pp_generate_loc_timezone = ' || l_location_id.COUNT);
      
  IF l_location_id.COUNT = 0 THEN
    RETURN;
  END IF;

  BEGIN
    FOR i in 1..l_location_id.count    
    LOOP
      BEGIN         
        hz_timezone_pub.get_timezone_id(
                                  p_api_version   => 1.0,
                                  p_init_msg_list => FND_API.G_FALSE,
                                  p_postal_code   => l_postal_code(i),
                                  p_city          => l_city(i),
                                  p_state         => l_state(i),
                                  p_country       => l_country(i),
                                  x_timezone_id   => l_timezone_id,
                                  x_return_status => l_return_status ,
                                  x_msg_count     => l_msg_count ,
                                  x_msg_data      => l_msg_data); 
                                   
      IF l_return_status <> fnd_api.g_ret_sts_success THEN  -- we don't raise error
        l_timezone_id := null;
      END IF;
 
      UPDATE hz_locations
      SET timezone_id = l_timezone_id
      WHERE location_id = l_location_id(i);
      EXCEPTION 
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,' Unexpected error occured in the post processing location timezone generation program
                                                    for Location :  ' ||  l_location_id(i));
        RAISE;                
      END;
    END LOOP;
  END; 
  fnd_file.put_line(fnd_file.log, '    pp_generate_loc_timezone-');

END pp_generate_loc_timezone;  

/*                                                                       *
 *=======================================================================*
 * PROCEDURENAME                                                         *
 *   pp_generate_cp_timezone                                         *
 *                                                                       *
 * DESCRIPTION                                                           *
 *                                                                       *
 * NOTES                                                                 *
 *                                                                       *
 * MODIFICATION HISTORY                                                  *
 *                                                                       *
 *=======================================================================*/

PROCEDURE pp_generate_cp_timezone (
   p_batch_mode_flag             IN       VARCHAR2,
   p_batch_id                    IN       NUMBER,
   p_os                          IN       VARCHAR2,
   p_from_osr                    IN       VARCHAR2,
   p_to_osr                      IN       VARCHAR2,
   p_request_id                  IN       NUMBER,
   p_g_miss_char                 IN       VARCHAR2,
   p_postprocess_status          IN       VARCHAR2
  ) IS         
l_timezone_id                           NUMBER;
l_msg_count                             NUMBER;
l_msg_data                              VARCHAR2(2000);                 

l_new_sql varchar2(1000) := 'SELECT cp.contact_point_id, cp.phone_country_code, cp.phone_area_code
          FROM hz_contact_points cp,hz_imp_contactpts_int cpint,hz_imp_contactpts_sg cpsg
          WHERE cpsg.batch_id = :p_batch_id
            AND cpsg.party_orig_system = :p_os
            AND cpsg.party_orig_system_reference between :p_from_osr and :p_to_osr
            AND cpsg.batch_mode_flag = :p_batch_mode_flag             
            AND cp.contact_point_id = cpsg.contact_point_id
            AND cp.request_id = :p_request_id
	    AND cpsg.contact_point_type = ''PHONE''
            AND cpsg.int_row_id = cpint.rowid
	    AND cpint.timezone_code is NULL
	    AND (decode(cpint.phone_country_code,:p_g_miss_char,NULL,cpint.phone_country_code) IS NOT NULL OR decode(cpint.phone_area_code,:p_g_miss_char,NULL,cpint.phone_area_code) IS NOT NULL)';

l_rerun_sql varchar2(1000) := 'SELECT cp.contact_point_id, cp.phone_country_code, cp.phone_area_code
          FROM hz_contact_points cp,hz_imp_contactpts_int cpint,hz_imp_contactpts_sg cpsg, hz_imp_batch_details bd
          WHERE cpsg.batch_id = :p_batch_id
            AND cpsg.party_orig_system = :p_os
            AND cpsg.party_orig_system_reference between :p_from_osr and :p_to_osr
            AND cpsg.batch_mode_flag = :p_batch_mode_flag             
            AND cp.contact_point_id = cpsg.contact_point_id
            AND cp.request_id = bd.main_conc_req_id 
            AND bd.batch_id = cpsg.batch_id
	    AND cpsg.contact_point_type = ''PHONE''
            AND cpsg.int_row_id = cpint.rowid
	    AND cpint.timezone_code is NULL
	    AND (decode(cpint.phone_country_code,:p_g_miss_char,NULL,cpint.phone_country_code) IS NOT NULL OR decode(cpint.phone_area_code,:p_g_miss_char,NULL,cpint.phone_area_code) IS NOT NULL)';

c_timezone_cp RefCurType;

BEGIN  

  fnd_file.put_line(fnd_file.log, '    pp_generate_cp_timezone+');
  IF p_postprocess_status IS NULL THEN
    OPEN c_timezone_cp FOR l_new_sql
    USING p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag, p_request_id, p_g_miss_char, p_g_miss_char;
  ELSIF p_postprocess_status = 'U' THEN
    OPEN c_timezone_cp FOR l_rerun_sql
    USING p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag, p_g_miss_char, p_g_miss_char;
  END IF;

  FETCH c_timezone_cp BULK COLLECT INTO l_contact_point_id,l_country_code,l_phone_area_code;
  CLOSE c_timezone_cp; 
  fnd_file.put_line(fnd_file.log, '    # of records to process in pp_generate_cp_timezone = ' || l_contact_point_id.COUNT);

  IF l_contact_point_id.COUNT = 0 THEN
    RETURN;
  END IF;

  BEGIN
    FOR i in 1..l_contact_point_id.count    
    LOOP
      BEGIN                                                                
        hz_timezone_pub.get_phone_timezone_id(
                        p_api_version        => 1.0,
                        p_init_msg_list      => FND_API.G_FALSE,
                        p_phone_country_code => l_country_code(i),
                        p_area_code          => l_phone_area_code(i),
                        p_phone_prefix       => null,
                        p_country_code       => null,-- don't need to pass in this
                        x_timezone_id        => l_timezone_id,
                        x_return_status      => l_return_status ,
                        x_msg_count          =>l_msg_count ,
                        x_msg_data           => l_msg_data);
                        if l_return_status <> fnd_api.g_ret_sts_success
                        then  -- we don't raise error
                                l_timezone_id := null;
                        end if;

      UPDATE hz_contact_points
      SET timezone_id = l_timezone_id
      WHERE contact_point_id = l_contact_point_id(i);
      EXCEPTION 
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,' Unexpected error occured in the post processing contact point timezone generation program
                                                    for Contact Point :  ' || l_contact_point_id(i));
        RAISE;                
      END;
    END LOOP;
  END;
  fnd_file.put_line(fnd_file.log, '    pp_generate_cp_timezone-');
          
END  pp_generate_cp_timezone ;

/*                                                                       *
 *=======================================================================*
 * PROCEDURENAME                                                         *
 *   pp_phone_format                                                     *
 *                                                                       *
 * DESCRIPTION                                                           *
 *                                                                       *
 * NOTES                                                                 *
 *                                                                       *
 * MODIFICATION HISTORY                                                  *
 *                                                                       *
 *=======================================================================*/  

PROCEDURE pp_phone_format (
   p_batch_mode_flag             IN       VARCHAR2,
   p_batch_id                    IN       NUMBER,
   p_os                          IN       VARCHAR2,
   p_from_osr                    IN       VARCHAR2,
   p_to_osr                      IN       VARCHAR2,
   p_request_id                  IN       NUMBER,
   p_enable_dqm_sync             IN       VARCHAR2,
   p_postprocess_status          IN       VARCHAR2
  ) IS
l_new_sql varchar2(1500) := 'SELECT cp.contact_point_id,cp.raw_phone_number,
                                 cp.phone_country_code,cp.phone_area_code,
                                 cp.phone_number,cp.owner_table_name,cp.owner_table_id,
                                 cp.primary_flag,cp.primary_by_purpose,cp.phone_line_type,
                                 cp.phone_extension,
                                 cps.contact_point_type, 
                                 null party_id,
                                 cp.contact_point_id record_id,
                                 ''CONTACT_POINTS'' entity,
                                 decode(cps.action_flag, ''I'', ''C'', cps.action_flag) operation_flag,
                                 null party_type
                            FROM hz_contact_points cp, hz_imp_contactpts_sg cps
                           WHERE cp.request_id = :p_request_id
                             AND cp.contact_point_id = cps.contact_point_id
                             and cps.batch_id = :p_batch_id
                             and cps.party_orig_system = :p_os
                             and cps.party_orig_system_reference between :p_from_osr and :p_to_osr
                             and cps.batch_mode_flag = :p_batch_mode_flag
                             and cps.action_flag is not null';
                             -- AND cps.contact_point_type = 'PHONE';          

l_rerun_sql varchar2(1500) := 'SELECT cp.contact_point_id,cp.raw_phone_number,
                                 cp.phone_country_code,cp.phone_area_code,
                                 cp.phone_number,cp.owner_table_name,cp.owner_table_id,
                                 cp.primary_flag,cp.primary_by_purpose,cp.phone_line_type,
                                 cp.phone_extension,
                                 cps.contact_point_type, 
                                 null party_id,
                                 cp.contact_point_id record_id,
                                 ''CONTACT_POINTS'' entity,
                                 decode(cps.action_flag, ''I'', ''C'', cps.action_flag) operation_flag,
                                 null party_type
                            FROM hz_contact_points cp, hz_imp_contactpts_sg cps, hz_imp_batch_details bd
                           WHERE cp.request_id = bd.main_conc_req_id 
                             AND bd.batch_id = cps.batch_id
                             AND cp.contact_point_id = cps.contact_point_id
                             and cps.batch_id = :p_batch_id
                             and cps.party_orig_system = :p_os
                             and cps.party_orig_system_reference between :p_from_osr and :p_to_osr
                             and cps.batch_mode_flag = :p_batch_mode_flag
                             and cps.action_flag is not null';
                             
CURSOR c_country (p_site_id IN NUMBER) IS
 SELECT country
   FROM   hz_locations
  WHERE  location_id = (SELECT location_id
                          FROM   hz_party_sites
                         WHERE  party_site_id = p_site_id);

l1_country_code      hz_phone_country_codes.territory_code%type; 
c_phone_format RefCurType;

BEGIN
 
  fnd_file.put_line(fnd_file.log, '    pp_phone_format+');
  IF p_postprocess_status IS NULL THEN
    OPEN c_phone_format FOR l_new_sql
    USING p_request_id, p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  ELSIF p_postprocess_status = 'U' THEN
    OPEN c_phone_format FOR l_rerun_sql
    USING p_batch_id, p_os, p_from_osr, p_to_osr, p_batch_mode_flag;
  END IF;

  FETCH c_phone_format BULK COLLECT INTO
       l_contact_point_id, l_raw_phone_number,l_country_code,l_phone_area_code,
       l_phone_number,l_owner_table_name,l_owner_table_id,l_primary_flag,
       l_primary_by_purpose,l_phone_line_type,l_phone_extension,
       l_contact_point_type,l_party_id, l_record_id, l_entity, l_operation, l_party_type;
  CLOSE c_phone_format;

  fnd_file.put_line(fnd_file.log, '    # of records to process in pp_phone_format = ' || l_contact_point_id.COUNT);

  IF l_contact_point_id.COUNT = 0 THEN
    RETURN;
  END IF;

  FOR i in 1..l_contact_point_id.count
  LOOP
  BEGIN
   IF l_contact_point_type(i) = 'PHONE' THEN 
-- IF RAW_PHONE_NUMBER IS PASSED CALL PHONE_FORMAT API
    IF l_phone_number(i) IS NULL THEN 
      IF l_country_code(i) IS NOT NULL THEN
        BEGIN
          select territory_code into l1_country_code
          from  hz_phone_country_codes
          where  phone_country_code = l_country_code(i) 
          and   rownum = 1;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        END;
      ELSIF l_owner_table_name(i) = 'HZ_PARTY_SITES' AND
            l_country_code(i)  IS NULL 
      THEN
        OPEN c_country(l_owner_table_id(i));
        FETCH c_country INTO l1_country_code;
        IF c_country%NOTFOUND THEN
          CLOSE c_country;
          RAISE NO_DATA_FOUND;
        END IF;
        CLOSE c_country;
      ELSE
        l1_country_code := NULL;
      END IF;

      l_phone_area_code(i)  := NULL;
      hz_contact_point_v2pub.phone_format (
                                 p_raw_phone_number       => l_raw_phone_number(i),
                                 p_territory_code         => l1_country_code,
                                 x_formatted_phone_number => l_formatted_phone_number,
                                 x_phone_country_code     => l_country_code(i),
                                 x_phone_area_code        => l_phone_area_code(i),
                                 x_phone_number           => l_phone_number(i),
                                 x_return_status          => x_return_status,
                                 x_msg_count              => l_msg_count,
                                 x_msg_data               => l_msg_data);      
                                 
      IF x_return_status <> fnd_api.g_ret_sts_success THEN  
        fnd_file.put_line(fnd_file.log,'     The phone format API failed for contact point id ' || l_contact_point_id(i));
--            l_formatted_phone_number := NULL;
      END IF;

      Update hz_contact_points SET   
             phone_number           = l_phone_number(i),
             phone_area_code        = l_phone_area_code(i),   
             phone_country_code     = l_country_code(i),
             transposed_phone_number = hz_phone_number_pkg.transpose(
                                          l_country_code(i)||l_phone_area_code(i)||l_phone_number(i))
      Where contact_point_id = l_contact_point_id(i);
      
    ELSIF l_raw_phone_number(i) IS NULL THEN /* Phone Number is passed */
      Update hz_contact_points SET   
      raw_phone_number        = l_phone_area_code(i) || '-' || l_phone_number(i),
      transposed_phone_number = hz_phone_number_pkg.transpose(
                                          l_country_code(i)||l_phone_area_code(i)||l_phone_number(i))
      Where contact_point_id = l_contact_point_id(i);      
    END IF;   

    /* Denormalize the primary contact point type in hz_parties table */
    IF l_primary_flag(i) = 'Y' AND l_owner_table_name(i) = 'HZ_PARTIES' THEN
      UPDATE hz_parties set 
             primary_phone_contact_pt_id       = l_contact_point_id(i),
             primary_phone_purpose             = l_primary_by_purpose(i),
             primary_phone_line_type           = l_phone_line_type(i),
             primary_phone_country_code        = l_country_code(i),
             primary_phone_area_code           = l_phone_area_code(i),
             primary_phone_number              = l_phone_number(i),
             primary_phone_extension           = l_phone_extension(i)
      WHERE    party_id = l_owner_table_id(i);
    END IF;
    
   END IF; -- end IF l_contact_point_type(i) = 'PHONE' 
   EXCEPTION
    WHEN OTHERS THEN    
       fnd_file.put_line(fnd_file.log,' Unexpected error occured in the post processing phone format program
                                          for Contact Point : ' || l_contact_point_id(i));
    RAISE;
   END;                  
  END LOOP;  
  fnd_file.put_line(fnd_file.log, '    pp_phone_format-');

END pp_phone_format;

/*                                                                       *
 *=======================================================================*
 * PROCEDURENAME                                                         *
 *   WORKER_PROCESS                                                         *
 *                                                                       *
 * DESCRIPTION                                                           *
 *   Main procedure called by each worker unit                           *
 *                                                                       *
 *=======================================================================*/  
 
PROCEDURE WORKER_PROCESS (
  Errbuf                      OUT NOCOPY     VARCHAR2,
  Retcode                     OUT NOCOPY     VARCHAR2,
  P_BATCH_ID                  IN             NUMBER,
  P_ACTUAL_CONTENT_SRC        IN             VARCHAR2,
  P_BATCH_MODE_FLAG	      IN	     VARCHAR2,
  P_REQUEST_ID                IN             NUMBER,
  P_GENERATE_FUZZY_KEY        IN             VARCHAR2 := 'Y'
) IS

  START_TIME        DATE := sysdate;
  P_OS              VARCHAR2(30);
  P_FROM_OSR        VARCHAR2(255);
  P_TO_OSR          VARCHAR2(255);
  l_rerun	    VARCHAR2(1) := 'Y';
  l_g_miss_char     VARCHAR2(1);
  l_hwm_stage       NUMBER := 0;
  l_run_format_person_name_flag boolean;
  l_enable_dqm_sync_flag VARCHAR2(50);

BEGIN

  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Post-processing WORKER_PROCESS+');
  
  /* Check profile if need to format person name */
  l_run_format_person_name_flag := (nvl(fnd_profile.value('HZ_FMT_BKWD_COMPATIBLE'),'Y') = 'N');
  l_enable_dqm_sync_flag := nvl(FND_PROFILE.VALUE('HZ_DQM_ENABLE_REALTIME_SYNC'), 'Y');
  l_g_miss_char := NVL(FND_PROFILE.value('HZ_IMP_G_MISS_CHAR'), '!');
    
  /* Process records with current request_id */  
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Process records with current request_id');
  LOOP
    P_OS := NULL;
    
    /* Pick up work units that have NULL postprocess_status */
    HZ_IMP_LOAD_WRAPPER.RETRIEVE_PP_WORK_UNIT(P_BATCH_ID, NULL, P_OS, P_FROM_OSR, P_TO_OSR);

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_OS = ' || P_OS);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_FROM_OSR = ' || P_FROM_OSR);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_TO_OSR = ' || P_TO_OSR);

    IF (P_OS IS NULL) Then
      EXIT;
    END IF;
    
    /* HZ_PARTIES */
    fnd_file.put_line(fnd_file.log,' Post Processing for HZ_PARTIES entity ');
       
    if (l_run_format_person_name_flag) then
      fnd_file.put_line(fnd_file.log,'   Format Person Name                  (+) ');
      pp_format_person_name(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID, NULL);
      fnd_file.put_line(fnd_file.log,'   Format Person Name                  (-) ');
    end if;
       
    IF (P_GENERATE_FUZZY_KEY = 'Y') THEN
      fnd_file.put_line(fnd_file.log,'   Generate Customer Key               (+) ');
      pp_generate_cust_key(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID,
                           P_GENERATE_FUZZY_KEY,l_enable_dqm_sync_flag, NULL);
      fnd_file.put_line(fnd_file.log,'   Generate Customer Key               (-) ');
    END IF;

    fnd_file.put_line(fnd_file.log,' Generate Relationship Party Name    (+) ');
    pp_rel_party_name(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID, NULL);
    fnd_file.put_line(fnd_file.log,' Generate Relationship Party Name    (-) ');
    
    /* HZ_RELATIONSHIPS */
    fnd_file.put_line(fnd_file.log,' Post Processing for HZ_RELATIONSHIPS entity ');
    fnd_file.put_line(fnd_file.log,'   Relationship Denormalization       (+)  ');
    pp_denorm_rel(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID, NULL);
    fnd_file.put_line(fnd_file.log,'   Relationship Denormalization       (-)  ');

    IF P_OS = 'DNB' THEN
      fnd_file.put_line(fnd_file.log,'   DNB Hierarchy                      (+)  ');
      pp_dnb_hierarchy(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR);
      fnd_file.put_line(fnd_file.log,'   DNB Hierarchy                      (-)  ');
    END IF;

    /* HZ_CONTACT_POINTS */
    fnd_file.put_line(fnd_file.log,' Post Processing for HZ_CONTACT_POINTS entity ');
    fnd_file.put_line(fnd_file.log,'   Phone Format                       (+) ');
    pp_phone_format(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID,
                    l_enable_dqm_sync_flag, NULL);
    fnd_file.put_line(fnd_file.log,'   Phone Format                       (-) ');

    fnd_file.put_line(fnd_file.log,'   Generate Contact point Timezone    (+) ');
    pp_generate_cp_timezone(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID,l_g_miss_char, NULL);
    fnd_file.put_line(fnd_file.log,'   Generate Contact point Timezone    (-) ');

    /* HZ_LOCATIONS */
    fnd_file.put_line(fnd_file.log,' Post Processing for HZ_LOCATIONS entity ');
     
    IF (P_GENERATE_FUZZY_KEY = 'Y') THEN
      fnd_file.put_line(fnd_file.log,'   Generate Address Key              (+) ');
      pp_generate_addr_key(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID,
                           P_GENERATE_FUZZY_KEY,l_enable_dqm_sync_flag, NULL);
      fnd_file.put_line(fnd_file.log,'   Generate Address Key              (-) ');
    END IF;
           
    fnd_file.put_line(fnd_file.log,'   Generate Loc Assignment           (+) ');
    pp_generate_loc_assignments(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR);
    fnd_file.put_line(fnd_file.log,'   Generate Loc Assignment           (-) ');

    fnd_file.put_line(fnd_file.log,'   Generate Loctaion Timezone        (+) ');
    pp_generate_loc_timezone(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID,l_g_miss_char);
    fnd_file.put_line(fnd_file.log,'   Generate Loctaion Timezone        (-) ');

    fnd_file.put_line(fnd_file.log,'   DQM Sync                 (+) ');
    IF (l_enable_dqm_sync_flag <> 'DISABLE') THEN  
      fnd_file.put_line(fnd_file.log,'     Calling pp_dqm_sync.');
      pp_dqm_sync(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID, NULL);
    ELSE
      fnd_file.put_line(fnd_file.log,'     HZ_DQM_ENABLE_REALTIME_SYNC not enabled.');
    END IF;
    fnd_file.put_line(fnd_file.log,'   DQM Sync                 (-) ');
    
    fnd_file.put_line(fnd_file.log,' Denorm Title                     (+) '); 
    pp_denorm_title(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID, NULL);    
    fnd_file.put_line(fnd_file.log,' Denorm Title                     (-) '); 

    /* Update status to Complete for the work unit that just finished */
    UPDATE HZ_IMP_WORK_UNITS
      SET POSTPROCESS_STATUS = 'C'
    WHERE BATCH_ID = P_BATCH_ID
      AND FROM_ORIG_SYSTEM_REF = P_FROM_OSR;

    COMMIT;

  END LOOP;  


  /* Process work units with current and all previous request_ids */
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Process records with current and all previous request_id');
  LOOP
    P_OS := NULL;
    
    /* Pick up work units that have NULL postprocess_status */
    HZ_IMP_LOAD_WRAPPER.RETRIEVE_PP_WORK_UNIT(P_BATCH_ID, 'U', P_OS, P_FROM_OSR, P_TO_OSR);

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_OS = ' || P_OS);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_FROM_OSR = ' || P_FROM_OSR);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_TO_OSR = ' || P_TO_OSR);

    IF (P_OS IS NULL) Then
      EXIT;
    END IF;
    
    /* HZ_PARTIES */
    fnd_file.put_line(fnd_file.log,' Post Processing for HZ_PARTIES entity ');
       
    if (l_run_format_person_name_flag) then
      fnd_file.put_line(fnd_file.log,'   Format Person Name                  (+) ');
      pp_format_person_name(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID, 'U');
      fnd_file.put_line(fnd_file.log,'   Format Person Name                  (-) ');
    end if;
       
    IF (P_GENERATE_FUZZY_KEY = 'Y') THEN
      fnd_file.put_line(fnd_file.log,'   Generate Customer Key               (+) ');
      pp_generate_cust_key(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID,
                           P_GENERATE_FUZZY_KEY,l_enable_dqm_sync_flag, 'U');
      fnd_file.put_line(fnd_file.log,'   Generate Customer Key               (-) ');
    END IF;
    
    fnd_file.put_line(fnd_file.log,' Generate Relationship Party Name    (+) ');
    pp_rel_party_name(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID, 'U');
    fnd_file.put_line(fnd_file.log,' Generate Relationship Party Name    (-) ');
       
    /* HZ_RELATIONSHIPS */
    fnd_file.put_line(fnd_file.log,' Post Processing for HZ_RELATIONSHIPS entity ');
    fnd_file.put_line(fnd_file.log,'   Relationship Denormalization       (+)  ');
    pp_denorm_rel(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID, 'U');
    fnd_file.put_line(fnd_file.log,'   Relationship Denormalization       (-)  ');

    IF P_OS = 'DNB' THEN
      fnd_file.put_line(fnd_file.log,'   DNB Hierarchy                      (+)  ');
      pp_dnb_hierarchy(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR);
      fnd_file.put_line(fnd_file.log,'   DNB Hierarchy                      (-)  ');
    END IF;

    /* HZ_CONTACT_POINTS */
    fnd_file.put_line(fnd_file.log,' Post Processing for HZ_CONTACT_POINTS entity ');
    fnd_file.put_line(fnd_file.log,'   Phone Format                       (+) ');
    pp_phone_format(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID,
                    l_enable_dqm_sync_flag, 'U');
    fnd_file.put_line(fnd_file.log,'   Phone Format                       (-) ');

    fnd_file.put_line(fnd_file.log,'   Generate Contact point Timezone    (+) ');
    pp_generate_cp_timezone(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID,l_g_miss_char, 'U');
    fnd_file.put_line(fnd_file.log,'   Generate Contact point Timezone    (-) ');

    /* HZ_LOCATIONS */
    fnd_file.put_line(fnd_file.log,' Post Processing for HZ_LOCATIONS entity ');
     
    IF (P_GENERATE_FUZZY_KEY = 'Y') THEN
      fnd_file.put_line(fnd_file.log,'   Generate Address Key              (+) ');
      pp_generate_addr_key(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID,
                           P_GENERATE_FUZZY_KEY,l_enable_dqm_sync_flag, 'U');
      fnd_file.put_line(fnd_file.log,'   Generate Address Key              (-) ');
    END IF;
           
    fnd_file.put_line(fnd_file.log,'   Generate Loc Assignment           (+) ');
    pp_generate_loc_assignments(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR);
    fnd_file.put_line(fnd_file.log,'   Generate Loc Assignment           (-) ');

    fnd_file.put_line(fnd_file.log,'   Generate Loctaion Timezone        (+) ');
    pp_generate_loc_timezone(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID,l_g_miss_char);
    fnd_file.put_line(fnd_file.log,'   Generate Loctaion Timezone        (-) ');

    /* HZ_ORG_CONTACTS */
    fnd_file.put_line(fnd_file.log,'   DQM Sync                 (+) ');
    IF (l_enable_dqm_sync_flag <> 'DISABLE') THEN  
      fnd_file.put_line(fnd_file.log,'     Calling pp_dqm_sync.');
      pp_dqm_sync(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID, 'U');
    ELSE
      fnd_file.put_line(fnd_file.log,'     HZ_DQM_ENABLE_REALTIME_SYNC not enabled.');
    END IF;
    fnd_file.put_line(fnd_file.log,'   DQM Sync                 (-) ');

    fnd_file.put_line(fnd_file.log,' Denorm Title                     (+) '); 
    pp_denorm_title(P_BATCH_MODE_FLAG,P_BATCH_ID,P_OS,P_FROM_OSR,P_TO_OSR,P_REQUEST_ID, 'U');     
    fnd_file.put_line(fnd_file.log,' Denorm Title                     (-) '); 
         
    /* Update status to Complete for the work unit that just finished */
    UPDATE HZ_IMP_WORK_UNITS
      SET POSTPROCESS_STATUS = 'C'
    WHERE BATCH_ID = P_BATCH_ID
      AND FROM_ORIG_SYSTEM_REF = P_FROM_OSR;

    COMMIT;

  END LOOP;  

  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Post-processing WORKER_PROCESS-');
    
  RETURN;
  
EXCEPTION  
  WHEN OTHERS THEN
    ROLLBACK;
    FND_MESSAGE.SET_NAME('AR', 'HZ_API_OTHERS_EXCEP');
    FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);

    errbuf  := FND_MESSAGE.get;
    retcode := 2;    
    
    UPDATE hz_imp_batch_summary
    SET import_status = 'ERROR'
    WHERE batch_id = P_BATCH_ID;
    
    UPDATE hz_imp_batch_details
    SET import_status = 'ERROR'
    WHERE batch_id = P_BATCH_ID
    AND run_number = (SELECT max(run_number) 
    		      FROM hz_imp_batch_details
    		      WHERE batch_id = P_BATCH_ID);
    
    COMMIT;
    
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception in Post-processing worker: ' || SQLERRM);
          
END WORKER_PROCESS;

       
END HZ_IMP_LOAD_POST_PROCESS_PKG;
/
COMMIT;
EXIT;
