-- +==========================================================================+
-- |                     Office Depot - Project Simplify                      |
-- +==========================================================================+
-- | Name    :  XX_TM_DELETE_ASSIGNMENTS                                      |
-- | RICE ID :                                                                |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                          |
-- | Description:                                                             |
-- |                                                                          |
-- | This script deletes records from the custom territory assignment tables  |
-- | in order to exercise the Autoname software in the PRFGB environment.     |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date         Author           Remarks                            |
-- |=======  ===========  =============    ===================================|
-- |1.0      14-SEP-2009  Phil Price        Initial version                   |
-- +==========================================================================+
--

define NUM_PARTY_SITES_TO_DELETE=&1
define NUM_LEADS_TO_DELETE=&2
define NUM_OPPORS_TO_DELETE=&3
define NUM_TOPS_ASSIGN_TO_RESET=&4
define NUM_HRCRM_RECS_TO_RESET=&5

set timing on
set feedback 1
set serveroutput on size 1000000

declare
  GN_PS_ROWS_TO_DELETE         constant number := &NUM_PARTY_SITES_TO_DELETE;
  GN_LEAD_ROWS_TO_DELETE       constant number := &NUM_LEADS_TO_DELETE;
  GN_OPPOR_ROWS_TO_DELETE      constant number := &NUM_OPPORS_TO_DELETE;
  GN_TOPS_ASSIGNMENTS_TO_RESET constant number := &NUM_TOPS_ASSIGN_TO_RESET;
  GN_HRCRM_RECS_TO_RESET       constant number := &NUM_HRCRM_RECS_TO_RESET;

  GN_NO_PARTY_SITE_ID     constant number := 99999999;

  --
  -- Dont delete any assignments assigned to these users
  --
  gt_exclude_users VARCHAR2_TABLE_100;

  gc_cust_prosp        varchar2(20);
  gc_lead_oppor        varchar2(20);
  gn_attr_group_id     number;
  gn_max_rows          number;
  gn_min_party_site_id number := GN_NO_PARTY_SITE_ID;

  --
  -- Get the PARTY_SITE entity records we want to delete.
  --
  cursor c_ps (c_prosp_cust    varchar2,
               c_attr_group_id number,
               c_max_rows      number,
               c_exclude_users VARCHAR2_TABLE_100) is
    select entity_info.named_acct_terr_entity_id, entity_id
      from (select /*+ parallel(ent,8) */
                   named_acct_terr_entity_id, entity_id
              from apps.xx_tm_nam_terr_entity_dtls ent
             where entity_type = 'PARTY_SITE'
               and status      = 'A'
               and sysdate between nvl(start_date_active, sysdate-1)
                               and nvl(end_date_active, sysdate+1)
               --
               -- The party site needs to already be enriched by GDW
               --
               and exists (select 1
                             from apps.hz_parties           hp,
                                  apps.hz_party_sites       hps,
                                  apps.hz_party_sites_ext_b hpse,
                                 (select batch_id
                                    from apps.hz_imp_batch_summary
                                   where original_system = 'GDW') bat
                            where hp.party_id         = hps.party_id
                              and hps.party_site_id   = hpse.party_site_id
                              and hpse.n_ext_attr20   = bat.batch_id
                              and hpse.attr_group_id  = c_attr_group_id
                              and hps.party_id        = ent.entity_id
                              and hp.status           = 'A'
                              and hps.status          = 'A'
                              and hp.attribute13      = c_prosp_cust)
               --
               -- Exclude assignments for specific users for UI perf testing
               --
               and not exists (select 1
                                 from apps.xx_tm_nam_terr_rsc_dtls    res,
                                      apps.jtf_rs_resource_extns      jres
                                where res.named_acct_terr_id = ent.named_acct_terr_id
                                  and res.resource_id        = jres.resource_id
                                  and jres.source_number     in (select column_value from table(c_exclude_users)))
             order by named_acct_terr_entity_id desc) entity_info
    where rownum <= c_max_rows;

 
  --
  -- Get the LEAD or OPPORTUNITY entity records we want to delete.
  --
  cursor c_lead_oppor (c_entity_type   varchar2,
                       c_max_rows      number,
                       c_exclude_users VARCHAR2_TABLE_100) is
    select entity_info.named_acct_terr_entity_id
      from (select /*+ parallel(ent,8) */
                   named_acct_terr_entity_id
              from apps.xx_tm_nam_terr_entity_dtls ent
             where entity_type = c_entity_type
               and status      = 'A'
               and sysdate between nvl(start_date_active, sysdate-1)
                               and nvl(end_date_active, sysdate+1)
               --
               -- Exclude assignments for specific users for UI perf testing
               --
               and not exists (select 1
                                 from apps.xx_tm_nam_terr_rsc_dtls    res,
                                      apps.jtf_rs_resource_extns      jres
                                where res.named_acct_terr_id = ent.named_acct_terr_id
                                  and res.resource_id        = jres.resource_id
                                  and jres.source_number     in (select column_value from table(c_exclude_users)))
             order by named_acct_terr_entity_id desc) entity_info
    where rownum <= c_max_rows;

  --
  -- Get TOPS assignments to reset
  --
  cursor c_tops (c_max_rows number,
                 c_exclude_users VARCHAR2_TABLE_100) is
    select tops_info.site_request_id
      from (select /*+ parallel(tsr,8) */
                   site_request_id
              from apps.xxtps_site_requests tsr
             where request_status_code = 'QUEUED'
               --
               -- Exclude assignments to / from specific users for UI perf testing
               --
               and not exists (select 1
                                 from apps.jtf_rs_resource_extns jres
                                where jres.resource_id   = tsr.from_resource_id
                                  and jres.source_number in (select column_value from table(c_exclude_users)))
               and not exists (select 1
                                 from apps.jtf_rs_resource_extns jres
                                where jres.resource_id   = tsr.to_resource_id
                                  and jres.source_number in (select column_value from table(c_exclude_users)))
             order by site_request_id desc) tops_info
    where rownum <= c_max_rows;

  --
  -- Get HR/CRM records to reset
  --
  cursor c_hrcrm (c_max_rows number,
                 c_exclude_users VARCHAR2_TABLE_100) is
    select res_info.resource_id
      from (select resource_id
              from apps.jtf_rs_resource_extns_vl res
             where category = 'EMPLOYEE'
               and substr(resource_name,1,1) != 'X'
               and trunc(sysdate) between trunc(nvl(start_date_active, sysdate-1))
                                      and trunc(nvl(end_date_active,   sysdate+1))
               and source_number not in (select column_value from table(c_exclude_users))
           connect by prior source_id = source_mgr_id
             start with resource_id = (select resource_id
                                         from apps.jtf_rs_resource_extns
                                         where source_number = '052991') -- Dave Trudnowski
      order siblings by source_name) res_info
    where rownum <= c_max_rows;

  TYPE numArray IS TABLE OF NUMBER INDEX BY BINARY_INTEGER; 

  ps_arr       numArray;
  terr_ent_arr numArray;
  tops_arr     numArray;
  res_arr      numArray;

function dti return varchar2 is
begin
  return (to_char(sysdate,'DD-MON-YYYY hh24:mi:ss'));
end dti;

procedure wrtout (p_txt in varchar2) is
begin
  dbms_output.put_line (dti || ': ' || p_txt);
end wrtout;

begin
  --
  -- Populate list of users we dont want to delete assignments from
  --
  gt_exclude_users   := VARCHAR2_TABLE_100('055017', '173821', '205547', '211558', '262052',
                                           '267568', '407249', '470276', '470279', '542800',
                                           '555978', '556905', '557356', '559432', '560088',                                                                             '532950', '174029', '497921', '520779', '402106',
                                           '159086', '417138', '139822');

  --
  -- Get attr_group_id for Site Demographics party site extension record 
  --
  select eag.attr_group_id
   into gn_attr_group_id
   from apps.ego_attr_groups_v eag,
        apps.fnd_application   app
  where eag.application_id = app.application_id
    and app.application_short_name = 'AR'
    and eag.attr_group_type        = 'HZ_PARTY_SITES_GROUP'
    and eag.attr_group_name        = 'SITE_DEMOGRAPHICS';

  --
  -- Delete records for PROSPECT assignments.
  --
  gc_cust_prosp := 'PROSPECT';
  terr_ent_arr.DELETE;
  ps_arr.DELETE;

  wrtout (' ');
  wrtout ('Working on ' || gc_cust_prosp || ' assignments...');
  open  c_ps (gc_cust_prosp, gn_attr_group_id, GN_PS_ROWS_TO_DELETE, gt_exclude_users);
  fetch c_ps BULK COLLECT INTO terr_ent_arr, ps_arr LIMIT GN_PS_ROWS_TO_DELETE;

  wrtout (c_ps%ROWCOUNT || ' rows fetched from xx_tm_nam_terr_entity_dtls for deletion of ' ||
                           gc_cust_prosp || ' party sites.');

  FORALL i IN 1..terr_ent_arr.COUNT
    delete from apps.xx_tm_nam_terr_entity_dtls
     where entity_type = 'PARTY_SITE'
       and status      = 'A'
       and sysdate     between nvl(start_date_active, sysdate-1)
                           and nvl(end_date_active, sysdate+1)
       and named_acct_terr_entity_id = terr_ent_arr(i);

  --
  -- Dont use sql%rowcount here because if terr_ent_arr.COUNT = 0 the DELETE statement is not executed and
  -- sql%rowcount still has the value from the prior SQL statement
  --
  wrtout (terr_ent_arr.COUNT || ' rows deleted from xx_tm_nam_terr_entity_dtls for ' ||
                        gc_cust_prosp || ' party sites.');
  close c_ps;

  IF (ps_arr.COUNT > 0) THEN
    FOR i in 1..ps_arr.LAST LOOP
      IF gn_min_party_site_id > ps_arr(i) THEN
        gn_min_party_site_id := ps_arr(i);
      END IF;
    END LOOP;
  END IF;


  --
  -- Delete records for CUSTOMER assignments.
  --
  gc_cust_prosp := 'CUSTOMER';
  terr_ent_arr.DELETE;
  ps_arr.DELETE;

  wrtout (' ');
  wrtout ('Working on ' || gc_cust_prosp || ' assignments...');
  open  c_ps (gc_cust_prosp, gn_attr_group_id, GN_PS_ROWS_TO_DELETE, gt_exclude_users);
  fetch c_ps BULK COLLECT INTO terr_ent_arr, ps_arr LIMIT GN_PS_ROWS_TO_DELETE;

  wrtout (c_ps%ROWCOUNT || ' rows fetched from xx_tm_nam_terr_entity_dtls for deletion of ' ||
                        gc_cust_prosp || ' party sites.');

  FORALL i IN 1..terr_ent_arr.COUNT
    delete from apps.xx_tm_nam_terr_entity_dtls
     where entity_type = 'PARTY_SITE'
       and status      = 'A'
       and sysdate     between nvl(start_date_active, sysdate-1)
                           and nvl(end_date_active, sysdate+1)
       and named_acct_terr_entity_id = terr_ent_arr(i);

  --
  -- Dont use sql%rowcount here because if terr_ent_arr.COUNT = 0 the DELETE statement is not executed and
  -- sql%rowcount still has the value from the prior SQL statement
  --
  wrtout (terr_ent_arr.COUNT || ' rows deleted from xx_tm_nam_terr_entity_dtls for ' ||
                        gc_cust_prosp || ' party sites.');

  close c_ps;

  IF (ps_arr.COUNT > 0) THEN
    FOR i in 1..ps_arr.LAST LOOP
      IF gn_min_party_site_id > ps_arr(i) THEN
        gn_min_party_site_id := ps_arr(i);
      END IF;
    END LOOP;
  END IF;

  IF (gn_min_party_site_id != GN_NO_PARTY_SITE_ID) then
    wrtout ('Setting profile option XX_TM_AUTO_MAX_PARTY_SITE_ID to ' || gn_min_party_site_id);

    IF NOT fnd_profile.save('XX_TM_AUTO_MAX_PARTY_SITE_ID',gn_min_party_site_id,'SITE') then
      raise_application_error (-20001,'Could not set profile option XX_TM_AUTO_MAX_PARTY_SITE_ID');
    END IF;
  ELSE
    wrtout ('No party sites deleted so profile option XX_TM_AUTO_MAX_PARTY_SITE_ID will not be updated.');
  END IF;

  --
  -- Delete LEAD assignments
  --
  gc_lead_oppor := 'LEAD';
  gn_max_rows   := GN_LEAD_ROWS_TO_DELETE;

  terr_ent_arr.DELETE;

  wrtout (' ');
  wrtout ('Working on ' || gc_lead_oppor || ' assignments...');
  open  c_lead_oppor (gc_lead_oppor, gn_max_rows, gt_exclude_users);
  fetch c_lead_oppor BULK COLLECT INTO terr_ent_arr LIMIT gn_max_rows;

  wrtout (c_lead_oppor%ROWCOUNT || ' rows fetched from xx_tm_nam_terr_entity_dtls for deletion of ' ||
                        gc_lead_oppor || ' entity type.');

  FORALL i IN 1..terr_ent_arr.COUNT
    delete from apps.xx_tm_nam_terr_entity_dtls
     where entity_type = gc_lead_oppor
       and status      = 'A' 
       and sysdate     between nvl(start_date_active, sysdate-1) 
                           and nvl(end_date_active, sysdate+1) 
       and named_acct_terr_entity_id = terr_ent_arr(i);

  wrtout (terr_ent_arr.COUNT  || ' rows deleted from xx_tm_nam_terr_entity_dtls for ' ||
                        gc_lead_oppor || ' entity type.');

  close c_lead_oppor;

  --
  -- Delete OPPOR assignments
  --
  gc_lead_oppor := 'OPPORTUNITY';
  gn_max_rows   := GN_OPPOR_ROWS_TO_DELETE;

  terr_ent_arr.DELETE;

  wrtout (' ');
  wrtout ('Working on ' || gc_lead_oppor || ' assignments...');
  open  c_lead_oppor (gc_lead_oppor, gn_max_rows, gt_exclude_users);
  fetch c_lead_oppor BULK COLLECT INTO terr_ent_arr LIMIT gn_max_rows;

  wrtout (c_lead_oppor%ROWCOUNT || ' rows fetched from xx_tm_nam_terr_entity_dtls for deletion of ' ||
                        gc_lead_oppor || ' entity type.');

  FORALL i IN 1..terr_ent_arr.COUNT
    delete from apps.xx_tm_nam_terr_entity_dtls
     where entity_type = gc_lead_oppor
       and status      = 'A' 
       and sysdate     between nvl(start_date_active, sysdate-1) 
                           and nvl(end_date_active, sysdate+1) 
       and named_acct_terr_entity_id = terr_ent_arr(i);

  wrtout (terr_ent_arr.COUNT  || ' rows deleted from xx_tm_nam_terr_entity_dtls for ' ||
                        gc_lead_oppor || ' entity type.');

  close c_lead_oppor;

  --
  -- Reset TOPS assignments
  --
  gn_max_rows   := GN_TOPS_ASSIGNMENTS_TO_RESET;

  tops_arr.DELETE;

  wrtout (' ');
  wrtout ('Working on TOPS assignments...');
  open  c_tops (gn_max_rows, gt_exclude_users);
  fetch c_tops BULK COLLECT INTO tops_arr LIMIT gn_max_rows;

  wrtout (c_tops%ROWCOUNT || ' rows fetched from xxtps_site_requests for assignment reset.');

  FORALL i IN 1..tops_arr.COUNT
    update apps.xxtps_site_requests
       set request_status_code = 'ERROR'
     where site_request_id = tops_arr(i);

  wrtout (tops_arr.COUNT  || ' rows updated in xxtps_site_requests.');

  close c_tops;

  --
  -- Reset THR/CRM records
  --
  gn_max_rows := GN_HRCRM_RECS_TO_RESET;

  res_arr.DELETE;

  wrtout (' ');
  wrtout ('Working on HER/CRM records...');
  open  c_hrcrm (gn_max_rows, gt_exclude_users);
  fetch c_hrcrm BULK COLLECT INTO res_arr LIMIT gn_max_rows;

  wrtout (c_hrcrm%ROWCOUNT || ' rows fetched from jtf_rs_resource_extns_vl for resource name update.');

  FORALL i IN 1..res_arr.COUNT
    update apps.jtf_rs_resource_extns_tl
       set resource_name = 'X' || resource_name
     where language = userenv('LANG')
       and resource_id = res_arr(i);

  wrtout (res_arr.COUNT  || ' rows updated in jtf_rs_resource_extns_tl.');

  close c_hrcrm;

end;
/

prompt Delete xx_tm_nam_terr_rsc_dtls records with no entiy records.
delete from apps.xx_tm_nam_terr_rsc_dtls
 where named_acct_terr_id in (select named_acct_terr_id
                                from apps.xx_tm_nam_terr_rsc_dtls
                               minus
                              select named_acct_terr_id
                                from apps.xx_tm_nam_terr_entity_dtls);

prompt Delete xx_tm_nam_terr_defn records with no resource records.
delete from apps.xx_tm_nam_terr_defn
 where named_acct_terr_id in (select named_acct_terr_id
                                from apps.xx_tm_nam_terr_defn
                               minus
                              select named_acct_terr_id
                                from apps.xx_tm_nam_terr_rsc_dtls);

commit;

