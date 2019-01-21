create or replace 
package body XX_SFDC_SALES_CONV
as
  -- +====================================================================+
  -- | Name        :  display_log                                         |
  -- | Description :  This procedure is invoked to print in the log file  |
  -- |                                                                    |
  -- | Parameters  :  Log Message                                         |
  -- |1.1       18-May-2016   Shubashree R     Removed the schema reference for GSCC compliance QC#37898|
  -- +====================================================================+
procedure display_log(
    p_message in varchar2 )
is
begin
  fnd_file.put_line(fnd_file.log,p_message);
end display_log;

-- +====================================================================+
-- | Name        :  display_out                                         |
-- | Description :  This procedure is invoked to print in the output    |
-- |                file                                                |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+
procedure display_out(
    p_message in varchar2 )
is
begin
  fnd_file.put_line(fnd_file.output,p_message);
end display_out;








-- +====================================================================+
-- | Name        :  create_assignments                                |
-- | Description :  This procedure is create/generate the output        |
-- |                file for assignments data                         |
-- |                                                                    |
-- |                                                                    |
-- +====================================================================+



PROCEDURE create_assignments(
    x_errbuf OUT nocopy  VARCHAR2,
    x_retcode OUT nocopy VARCHAR2,
    p_start_date IN DATE,
    p_conv_flag  IN VARCHAR2 )
IS
  ln_st_date DATE;
  ln_end_date DATE:=sysdate;
  ln_row_count  NUMBER;
  l_rec_status  VARCHAR2(5);
  l_rec_msg     VARCHAR2(2000);
  l_tot_updated NUMBER := 0;
  l_batch_id    NUMBER := 1;
  ln_batch_size  NUMBER := 10000;
  ln_max_size   NUMBER := 10000;
  ln_request_id NUMBER := 0;
  l_wait_result BOOLEAN;
lv_phase VARCHAR2(20);
lv_status VARCHAR2(20);
lv_dev_phase VARCHAR2(20);
lv_dev_status VARCHAR2(20);
lv_message1 VARCHAR2(20);
lb_result BOOLEAN;
prog_failed EXCEPTION;
TYPE num_array IS TABLE OF NUMBER
 INDEX BY BINARY_INTEGER;

req_array num_array;

--Get the entities for assignments.

  
--Get the Grand Parent entities for assignments.

  CURSOR gp_assignment_master
  IS
    SELECT g.PARTY_ID entity_id
      FROM xx_cdh_GP_MASTER G
      WHERE G.status='A';
 /*
 -- Chnaged in Sprint 15 to process all gps every day.
	  upper(NVL(p_conv_flag,'N'))= 'Y'
      AND
      UNION
      SELECT g.PARTY_ID entity_id
      FROM apps.xx_cdh_GP_MASTER G
      WHERE last_update_date BETWEEN NVL(p_start_date,ln_st_date) AND ln_end_date
      AND upper(NVL(p_conv_flag,'N'))= 'N'
      UNION
      SELECT OVRL_DET.party_gparent_id entity_id
      FROM XXTPS.xxtps_ovrl_relationships OVRL,
        XXTPS.XXTPS_OVRL_RLTNSHPS_DTLS OVRL_DET
      WHERE ovrl.ovrl_relationship_id     = OVRL_DET.ovrl_relationship_id
      AND OVRL_DET.relationship_type_code ='GPARENT'
      AND OVRL_DET.logic_action_code      ='IN'
      AND OVRL_DET.last_update_date BETWEEN NVL(p_start_date,ln_st_date) AND ln_end_date
      AND OVRL.last_update_date BETWEEN NVL(p_start_date,ln_st_date) AND ln_end_date
      AND upper(NVL(p_conv_flag,'N'))= 'N';
*/
-- Get the assignments details of an GP entity.

   CURSOR gp_assignment_dtl( ln_p_id NUMBER)
  IS
  SELECT mn.orcl_party_id entity_id ,
      owner_empno,
      owner_legacy_repid,
	  owner_role_relate_id,
     null as owner_empno1 ,
     null as owner_legacy_repid1 ,
     null as owner_empno2 ,
     null as owner_legacy_repid2 ,
	 null as owner_empno3 ,
     null as owner_legacy_repid3 ,
     null as owner_empno4 ,
     null as owner_legacy_repid4 ,
     null as owner_empno5 ,
     null as owner_legacy_repid5 ,
     null as owner_empno6 ,
     null as owner_legacy_repid6 ,
     null as owner_empno7 ,
     null as owner_legacy_repid7 ,
     null as owner_empno8 ,
     null as owner_legacy_repid8 ,
     null as owner_empno9 ,
     null as owner_legacy_repid9 ,
     null as owner_empno10 ,
     null as owner_legacy_repid10,
      'Y'  acct_flag,
      mn.orcl_party_id party_id,
      mn.orig_system_reference,
	  null as owner_empno11 ,
      null as owner_legacy_repid11 ,
      null as owner_empno12 ,
      null as owner_legacy_repid12 ,
	  null as owner_empno13 ,
      null as owner_legacy_repid13 ,
      null as owner_empno14 ,
      null as owner_legacy_repid14 ,
      null as owner_empno15 ,
      null as owner_legacy_repid15,
	  null as owner_empno16 ,
      null as owner_legacy_repid16 ,
      null as owner_empno17 ,
      null as owner_legacy_repid17 ,
	  null as owner_empno18 ,
      null as owner_legacy_repid18 ,
      null as owner_empno19 ,
      null as owner_legacy_repid19 ,
      null as owner_empno20 ,
      null as owner_legacy_repid20,
	  null as owner_empno21 ,
      null as owner_legacy_repid21 ,
      null as owner_empno22 ,
      null as owner_legacy_repid22 ,
	  null as owner_empno23 ,
      null as owner_legacy_repid23 ,
      null as owner_empno24 ,
      null as owner_legacy_repid24 ,
      null as owner_empno25 ,
      null as owner_legacy_repid25,
	  null as owner_empno26 ,
      null as owner_legacy_repid26 ,
      null as owner_empno27 ,
      null as owner_legacy_repid27 ,
	  null as owner_empno28 ,
      null as owner_legacy_repid28 ,
      null as owner_empno29 ,
      null as owner_legacy_repid29 ,
      null as owner_empno30 ,
      null as owner_legacy_repid30,
      'CUSTOMER' entity_type
	FROM
      ( SELECT g.party_id orcl_party_id,
       nvl(r.source_number,'000000') owner_empno,
       nvl(g.legacy_rep_id,'000000')  owner_legacy_repid,
      nvl(gm.role_relate_id, '000000') owner_role_relate_id,
       g.gp_id orig_system_reference       
         FROM xx_cdh_GP_MASTER G ,
        jtf_rs_resource_extns_vl r,
       ( select resource_id,role_id,group_id, max(role_relate_id) role_relate_id from 
        jtf_rs_group_mbr_role_vl group  by resource_id,role_id,group_id) gm
             WHERE gm.resource_id  = g.resource_id
        AND gm.role_id        = g.role_id
        AND gm.group_id       = g.group_id
        AND r.resource_id(+)   = gm.resource_id
         and   g.status='A'
        AND g.party_id  =ln_p_id
      ) mn;
  CURSOR assign_dups( ln_b_id NUMBER) is
select  account_id,account_type ,max(record_id) record_id
from xx_crm_exp_assignments  a where batch_id=ln_b_id
group by account_id, account_type
having count(1)>1;

TYPE assign_master_cur_tbl_typ
IS
  TABLE OF gp_assignment_master%rowtype INDEX BY binary_integer;
  lc_assign_master_cur_tbl assign_master_cur_tbl_typ;



BEGIN
  BEGIN
    SELECT NVL(fpov.profile_option_value,1000)
    INTO ln_batch_size
    FROM fnd_profile_option_values fpov ,
      fnd_profile_options fpo
    WHERE fpo.profile_option_id    = fpov.profile_option_id
    AND fpo.application_id         = fpov.application_id
    AND fpov.level_id              = g_level_id
    AND fpov.level_value           = g_level_value
    AND fpov.profile_option_value IS NOT NULL
    AND fpo.profile_option_name    = 'XXCRM_SFDC_ASSIGN_BATCH_SIZE';
    SELECT NVL(fpov.profile_option_value,1000)
    INTO ln_max_size
    FROM fnd_profile_option_values fpov ,
      fnd_profile_options fpo
    WHERE fpo.profile_option_id    = fpov.profile_option_id
    AND fpo.application_id         = fpov.application_id
    AND fpov.level_id              = g_level_id
    AND fpov.level_value           = g_level_value
    AND fpov.profile_option_value IS NOT NULL
    AND fpo.profile_option_name    = 'XXCRM_SFDC_MAX_ASSIGNMENTS';
  EXCEPTION
  WHEN OTHERS THEN
    ln_batch_size := 10000;
    ln_max_size   := 50000;
  END;
  BEGIN
    SELECT to_date(fpov.profile_option_value,'MM/DD/YYYY HH24:MI:SS')
    INTO ln_st_date
    FROM fnd_profile_option_values fpov ,
      fnd_profile_options fpo
    WHERE fpo.profile_option_id    = fpov.profile_option_id
    AND fpo.application_id         = fpov.application_id
    AND fpov.level_id              = g_level_id
    AND fpov.level_value           = g_level_value
    AND fpov.profile_option_value IS NOT NULL
    AND fpo.profile_option_name    = 'XX_CRM_SFDC_CUST_CONV_START_DATE';
    SELECT to_date(fpov.profile_option_value,'MM/DD/YYYY HH24:MI:SS')
    INTO ln_end_date
    FROM fnd_profile_option_values fpov ,
      fnd_profile_options fpo
    WHERE fpo.profile_option_id    = fpov.profile_option_id
    AND fpo.application_id         = fpov.application_id
    AND fpov.level_id              = g_level_id
    AND fpov.level_value           = g_level_value
    AND fpov.profile_option_value IS NOT NULL
    AND fpo.profile_option_name    = 'XX_CRM_SFDC_CUST_CONV_END_DATE';
  EXCEPTION
  WHEN OTHERS THEN
    ln_st_date  := NULL;
    ln_end_date := sysdate;
  END;

  IF p_start_date is not NULL THEN ln_end_date := sysdate; END IF;

  xx_crm_exp_batch_pkg.generate_batch_id (l_batch_id, '', 'ASSIGNMENTS');
  -- Fetch GrandParent data
  OPEN gp_assignment_master;
  FETCH gp_assignment_master bulk collect INTO lc_assign_master_cur_tbl ;
  ln_row_count := gp_assignment_master%rowcount;
  CLOSE gp_assignment_master;
  IF lc_assign_master_cur_tbl.count > 0 THEN
    FOR i                          IN lc_assign_master_cur_tbl.first .. lc_assign_master_cur_tbl.last
    LOOP
      l_rec_status := NULL;
      l_rec_msg    := NULL;
      BEGIN
        FOR lc_assignments_cur_tbl IN gp_assignment_dtl(lc_assign_master_cur_tbl(i).entity_id)
        LOOP
          BEGIN
            BEGIN
             xx_sfdc_sales_conv_pvt.insert_xx_crm_exp_assignment ( batch_id => l_batch_id, oracle_entity_id => lc_assignments_cur_tbl.entity_id, account_type => 'A', account_id => lc_assignments_cur_tbl.entity_id, primary_emp_id => lc_assignments_cur_tbl.owner_empno
, primary_spid => lc_assignments_cur_tbl.owner_legacy_repid
, primary_rrlid => lc_assignments_cur_tbl.owner_role_relate_id,
 ovrly_emp_id1 => lc_assignments_cur_tbl.owner_empno1,
 ovrly_spid1 => lc_assignments_cur_tbl.owner_legacy_repid1,
 ovrly_emp_id2 => lc_assignments_cur_tbl.owner_empno2,
 ovrly_spid2 =>lc_assignments_cur_tbl.owner_legacy_repid2,
 ovrly_emp_id3 => lc_assignments_cur_tbl.owner_empno3,
 ovrly_spid3 =>lc_assignments_cur_tbl.owner_legacy_repid3,
 ovrly_emp_id4 => lc_assignments_cur_tbl.owner_empno4,
 ovrly_spid4 =>lc_assignments_cur_tbl.owner_legacy_repid4,
 ovrly_emp_id5 => lc_assignments_cur_tbl.owner_empno5,
 ovrly_spid5 =>lc_assignments_cur_tbl.owner_legacy_repid5,
 ovrly_emp_id6 => lc_assignments_cur_tbl.owner_empno6,
 ovrly_spid6 => lc_assignments_cur_tbl.owner_legacy_repid6,
 ovrly_emp_id7 => lc_assignments_cur_tbl.owner_empno7,
 ovrly_spid7 =>lc_assignments_cur_tbl.owner_legacy_repid7,
 ovrly_emp_id8 => lc_assignments_cur_tbl.owner_empno8,
 ovrly_spid8 =>lc_assignments_cur_tbl.owner_legacy_repid8,
 ovrly_emp_id9 => lc_assignments_cur_tbl.owner_empno9,
 ovrly_spid9 =>lc_assignments_cur_tbl.owner_legacy_repid9,
 ovrly_emp_id10 =>lc_assignments_cur_tbl.owner_empno10,
 ovrly_spid10 =>lc_assignments_cur_tbl.owner_legacy_repid10,
 ovrly_emp_id11 => lc_assignments_cur_tbl.owner_empno11,
 ovrly_spid11 => lc_assignments_cur_tbl.owner_legacy_repid11,
 ovrly_emp_id12 => lc_assignments_cur_tbl.owner_empno12,
 ovrly_spid12 =>lc_assignments_cur_tbl.owner_legacy_repid12,
 ovrly_emp_id13 => lc_assignments_cur_tbl.owner_empno13,
 ovrly_spid13 =>lc_assignments_cur_tbl.owner_legacy_repid13,
 ovrly_emp_id14 => lc_assignments_cur_tbl.owner_empno14,
 ovrly_spid14 =>lc_assignments_cur_tbl.owner_legacy_repid14,
 ovrly_emp_id15 => lc_assignments_cur_tbl.owner_empno15,
 ovrly_spid15 =>lc_assignments_cur_tbl.owner_legacy_repid15,
 ovrly_emp_id21 => lc_assignments_cur_tbl.owner_empno21,
  ovrly_spid21 => lc_assignments_cur_tbl.owner_legacy_repid21,
  ovrly_emp_id22 => lc_assignments_cur_tbl.owner_empno22,
  ovrly_spid22 =>lc_assignments_cur_tbl.owner_legacy_repid22,
  ovrly_emp_id23 => lc_assignments_cur_tbl.owner_empno23,
  ovrly_spid23 =>lc_assignments_cur_tbl.owner_legacy_repid23,
  ovrly_emp_id24 => lc_assignments_cur_tbl.owner_empno24,
  ovrly_spid24 =>lc_assignments_cur_tbl.owner_legacy_repid24,
  ovrly_emp_id25 => lc_assignments_cur_tbl.owner_empno25,
  ovrly_spid25 =>lc_assignments_cur_tbl.owner_legacy_repid25,
  ovrly_emp_id26 => lc_assignments_cur_tbl.owner_empno26,
  ovrly_spid26 => lc_assignments_cur_tbl.owner_legacy_repid26,
  ovrly_emp_id27 => lc_assignments_cur_tbl.owner_empno27,
  ovrly_spid27 =>lc_assignments_cur_tbl.owner_legacy_repid27,
  ovrly_emp_id28 => lc_assignments_cur_tbl.owner_empno28,
  ovrly_spid28 =>lc_assignments_cur_tbl.owner_legacy_repid28,
  ovrly_emp_id29 => lc_assignments_cur_tbl.owner_empno29,
  ovrly_spid29 =>lc_assignments_cur_tbl.owner_legacy_repid29,
  ovrly_emp_id30 =>lc_assignments_cur_tbl.owner_empno30,
  ovrly_spid30 =>lc_assignments_cur_tbl.owner_legacy_repid30,
  ovrly_emp_id16 => lc_assignments_cur_tbl.owner_empno16,
  ovrly_spid16 => lc_assignments_cur_tbl.owner_legacy_repid16,
  ovrly_emp_id17 => lc_assignments_cur_tbl.owner_empno17,
  ovrly_spid17 =>lc_assignments_cur_tbl.owner_legacy_repid17,
  ovrly_emp_id18 => lc_assignments_cur_tbl.owner_empno18,
  ovrly_spid18 =>lc_assignments_cur_tbl.owner_legacy_repid18,
  ovrly_emp_id19 => lc_assignments_cur_tbl.owner_empno19,
  ovrly_spid19 =>lc_assignments_cur_tbl.owner_legacy_repid19,
  ovrly_emp_id20 => lc_assignments_cur_tbl.owner_empno20,
 ovrly_spid20 =>lc_assignments_cur_tbl.owner_legacy_repid20,
  entity_type=>lc_assignments_cur_tbl.entity_type,
osr =>lc_assignments_cur_tbl.orig_system_reference,
 x_ret_status => l_rec_status,
 x_ret_msg => l_rec_msg
);
              IF l_rec_status = 'E' THEN
                fnd_file.put_line(fnd_file.log,'Error During EntityId:' || lc_assignments_cur_tbl.entity_id || ':' || l_rec_msg);
              ELSE
                l_tot_updated := l_tot_updated + 1;
              END IF;
            EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,'Error During EntityId:' || lc_assignments_cur_tbl.entity_id || ':' || sqlerrm);
            END;
          END;
        END LOOP;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,'Assignment ID:' || lc_assign_master_cur_tbl(i).entity_id || ' Could Not be Inserted' || '::' || SQLERRM);
      END;
    END LOOP ;
    display_log('Number Of GP  Assignments  at '||TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS')||'   :'||l_tot_updated );
  END IF ;
COMMIT;
  -- process the batch to generate the output file
  xx_crm_exp_batch_pkg.generate_file (l_rec_status,l_rec_msg, l_batch_id );
  COMMIT;
  display_log('Total records : '||l_tot_updated);
  display_out('Total records : '||l_tot_updated);
END ;


END XX_SFDC_SALES_CONV;
/

SHOW ERRORS;