SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY xx_cdh_gp_report_pkg
-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name             :xx_cdh_gp_report_pkg.pkb                            |
-- | Description      :OD: CDH Grandparent Maintenance                     |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     27-JUN-2011 Sreedhar Mohan     Initial Draft                  |
-- | 1.1     28-JUN-2011 Indra Varada       Code added for 2 new reports   |
-- | 1.2     18-May-2016 Shubashree R       Removed the schema reference for GSCC compliance QC#37898|
-- |-------  ----------- -----------------  -------------------------------|
IS
--
--Procedure to Print Log Messages in Concurrent Output file 
--
PROCEDURE out (p_message IN VARCHAR2)
IS

BEGIN

      FND_FILE.put_line (FND_FILE.output, p_message);

END out;
--
--Procedure to Print Log Messages in Concurrent Log file 
--
PROCEDURE log (p_message IN VARCHAR2)
IS

BEGIN

      FND_FILE.put_line (FND_FILE.LOG, p_message);

END log;
--
--Procedure for Daily Grand Parent Changes Report
--
PROCEDURE gp_change_rpt
                            (  x_ret_code            OUT NOCOPY NUMBER
                              ,x_err_buf             OUT NOCOPY VARCHAR2
                              ,p_from_date           IN         VARCHAR2
                              ,p_to_date             IN         VARCHAR2
                            )
IS
  ld_from_date         DATE;
  ld_to_date           DATE;
  ln_request_id        NUMBER;
  lc_new               VARCHAR2(3);
  lb_prof_upd          BOOLEAN;
  
  ln_gp_id             xx_cdh_gp_hist.gp_id%type;
  lc_gp_name           xx_cdh_gp_hist.gp_name%type;
  lc_legacy_rep_id     xx_cdh_gp_hist.legacy_rep_id%type;
  lc_segment           xx_cdh_gp_hist.segment%type;
  lc_revenue_band      xx_cdh_gp_hist.revenue_band%type;
  lc_w_agreement_flag  xx_cdh_gp_hist.w_agreement_flag%type;
  lc_status            xx_cdh_gp_hist.status%type;
  ld_creation_date     xx_cdh_gp_hist.creation_date%type;
  ld_last_update_date  xx_cdh_gp_hist.last_update_date%type;

CURSOR C1 (p_from_date in date, p_to_date in date)
is
select distinct gp_id
from   xx_cdh_gp_hist hist
where  last_update_date between p_from_date and nvl(p_to_date,sysdate)
order by gp_id; 
  
CURSOR c_new (p_gp_id in number, p_from_date in date, p_to_date in date)
IS
select gp_id,
       gp_name,
       legacy_rep_id,
       segment,
       revenue_band,
       status,
       w_agreement_flag,
       last_update_date
from   xx_cdh_gp_hist hist
where  gp_hist_id=(select max(gp_hist_id) from xx_cdh_gp_hist hist2 where hist2.gp_id=p_gp_id and last_update_date <= nvl(p_to_date,sysdate));

CURSOR c_old (p_gp_id in number, p_from_date in date, p_to_date in date)
IS
select gp_id,
       gp_name,
       legacy_rep_id,
       segment,
       revenue_band,
       status,
       w_agreement_flag,
       last_update_date
from   xx_cdh_gp_hist hist
where  gp_hist_id=(select max(gp_hist_id) from xx_cdh_gp_hist hist2 where hist2.gp_id=p_gp_id and last_update_date < p_from_date );

begin
    ld_from_date := NVL(TO_DATE(p_from_date,'RRRR/MM/DD HH24:MI:SS'),TO_DATE(FND_PROFILE.VALUE('XX_CDH_GP_MAINT'),'DD-MON-RRRR HH24:MI:SS'));
    ld_to_date   := NVL(TO_DATE(p_to_date,'RRRR/MM/DD HH24:MI:SS'),SYSDATE);
    ln_request_id := fnd_global.conc_request_id();
    
    log ('Request Id: '        || ln_request_id);
    log ('Report Start Date: ' || TO_CHAR(ld_from_date,'DD-MON-RRRR HH24:MI:SS'));
    log ('Report End Date: '   || TO_CHAR(ld_to_date,'DD-MON-RRRR HH24:MI:SS'));
    
    out ('Report Name: ' || 'Grandparent Maintenance Report');
    out ('Request Id: '        || ln_request_id);
    out ('Report Start Date: ' || TO_CHAR(ld_from_date,'DD-MON-RRRR HH24:MI:SS'));
    out ('Report End Date: '   || TO_CHAR(ld_to_date,'DD-MON-RRRR HH24:MI:SS'));

    out ('OLD/NEW,GRAND PARENT ID,NAME,OWNER,SEGMENT,REVENUE BAND,ACTIVE,WRITTEN AGREEMENT');

    for i in C1(ld_from_date, ld_to_date)
    loop

      ln_gp_id           := null;
      lc_gp_name         := null;
      lc_legacy_rep_id   := null;
      lc_segment         := null;
      lc_revenue_band    := null;
      lc_w_agreement_flag:= null;
      lc_status          := null;
      ld_creation_date   := null;
      ld_last_update_date:= null;
      open c_old (i.gp_id, ld_from_date, ld_to_date);
      fetch c_old into ln_gp_id, lc_gp_name, lc_legacy_rep_id, lc_segment, lc_revenue_band, lc_status, lc_w_agreement_flag, ld_last_update_date;
      --print the values in the report
      out ('"OLD"' || ',' || '"' || ln_gp_id || '",' || '"' || lc_gp_name || '",' || '"' || lc_legacy_rep_id || '",' || '"' || lc_segment || '",' || '"' || lc_revenue_band || '",' || '"' || lc_status || '",' || '"' || lc_w_agreement_flag || '"');
      close c_old;
      ln_gp_id           := null;
      lc_gp_name         := null;
      lc_legacy_rep_id   := null;
      lc_segment         := null;
      lc_revenue_band    := null;
      lc_w_agreement_flag:= null;
      lc_status          := null;
      ld_creation_date   := null;
      ld_last_update_date:= null;

      open c_new (i.gp_id, ld_from_date, ld_to_date);
      fetch c_new into ln_gp_id, lc_gp_name, lc_legacy_rep_id, lc_segment, lc_revenue_band, lc_status, lc_w_agreement_flag, ld_last_update_date;
      --print the values in the report
      out ('"NEW"' || ',' || '"' || ln_gp_id || '",' || '"' || lc_gp_name || '",' || '"' || lc_legacy_rep_id || '",' || '"' || lc_segment || '",' || '"' || lc_revenue_band || '",' || '"' || lc_status || '",' || '"' || lc_w_agreement_flag || '"');
      close c_new;
    end loop;

    --save the profile
    lb_prof_upd := fnd_profile.SAVE('XX_CDH_GP_MAINT',TO_CHAR(sysdate,'DD-MON-RRRR HH24:MI:SS'),'SITE',null);

exception
  when others then
    log('Exception: ' || SQLERRM);
    x_ret_code := 2;
end gp_change_rpt;
--
--Procedure for Grand Parent Active Status Report
--
PROCEDURE gp_active_status_rpt
                            (  x_ret_code            OUT NOCOPY NUMBER
                              ,x_err_buf             OUT NOCOPY VARCHAR2
                              ,p_from_date           IN         VARCHAR2
                              ,p_to_date             IN         VARCHAR2
                            )
IS
cursor c2 (p_from_dt DATE, p_to_dt DATE)
is
select gp_id,
       gp_name,
       legacy_rep_id,
       segment,
       revenue_band,
       status,
       creation_date,
       w_agreement_flag
from   xx_cdh_gp_hist
where  TRUNC(status_update_date) between TRUNC(NVL(p_from_dt,SYSDATE)) and TRUNC(NVL(p_to_dt,SYSDATE))
order by gp_id asc,creation_date desc; 

l_from_dt      DATE;
l_to_dt        DATE;
lb_prof_upd          BOOLEAN;

begin
    IF p_from_date IS NULL THEN
       l_from_dt   := TO_DATE(FND_PROFILE.VALUE('XX_CDH_GP_ACTIVE_STATUS'),'DD-MON-RRRR HH24:MI:SS');
    ELSE
       l_from_dt   := TO_DATE(p_from_date,'RRRR/MM/DD HH24:MI:SS');
    END IF;
    
    IF p_to_date IS NOT NULL THEN
      l_to_dt   := TO_DATE(p_to_date,'RRRR/MM/DD HH24:MI:SS');
    END IF;
    
    out ('Report Name: ' || 'Grandparent Active Flag Status Report');
    out ('Request Id: '        || fnd_global.conc_request_id());
    out ('Report Start Date: ' || TO_CHAR(NVL(l_from_dt,SYSDATE),'DD-MON-RRRR HH24:MI:SS'));
    out ('Report End Date: '   || TO_CHAR(NVL(l_to_dt,SYSDATE),'DD-MON-RRRR HH24:MI:SS'));
    
    out('Grand Parent ID,Name,Owner,Segment,Revenue Band,Active,Modified Date,Written Agreement');

    FOR l_gp IN C2(l_from_dt,l_to_dt)  LOOP  
        out('"' || l_gp.gp_id || '",' || '"' || l_gp.gp_name || '",' || '"' || l_gp.legacy_rep_id || '",' || '"' || l_gp.segment || '",' || '"' || l_gp.revenue_band || '",' || '"' || l_gp.status || '",' || '"' || l_gp.creation_date || '",' || '"' || l_gp.w_agreement_flag || '"');
    END LOOP;
  
  --save the profile
    lb_prof_upd := fnd_profile.SAVE('XX_CDH_GP_ACTIVE_STATUS',TO_CHAR(sysdate,'DD-MON-RRRR HH24:MI:SS'),'SITE',null);     
  
 exception
  when others then
    log('Exception: ' || SQLERRM);
    x_ret_code := 2;
end gp_active_status_rpt;
--
--Procedure for Daily Grand Parent Hierarchy Changes Report
--
PROCEDURE gp_hierarchy_change_rpt
                            (  x_ret_code            OUT NOCOPY NUMBER
                              ,x_err_buf             OUT NOCOPY VARCHAR2
                              ,p_from_date           IN         VARCHAR2
                              ,p_to_date             IN         VARCHAR2
                            )
IS
cursor c3 (p_from_date  DATE, p_to_date DATE)
is
SELECT * FROM
(
SELECT gp.gp_id,
       gp.gp_name,
       r.relationship_id,
       substr(ac.orig_system_reference,0,8) parent_id,
       ac.account_name parent_name,
       NULL customer_id,
       NULL customer_name,
       CASE WHEN TRUNC(gr.end_date) > TRUNC(p_to_date) THEN 'Added'
       ELSE 'Removed'
       END action,
       r.last_update_date  modified_date,
       DECODE(ppl.full_name,null,null,ppl.full_name || '-' || ppl.employee_number) requestorval
FROM xx_cdh_gp_rel_hist r,
     hz_relationships gr,
     hz_cust_accounts ac,
     xx_cdh_gp_master gp,
     per_all_people_f ppl
where r.status_updated = 'Y'
and   ppl.person_id(+) = r.requestor
and   (r.last_update_date BETWEEN p_from_date AND p_to_date OR r.end_date BETWEEN p_from_date AND p_to_date)
and   r.relationship_id = gr.relationship_id
and   ac.party_id = gr.object_id
and   gp.party_id = gr.subject_id
and   gr.direction_code = 'P'
AND EXISTS
(
  SELECT 'Y'
  FROM hz_relationships
  where subject_id = gr.object_id
  AND RELATIONSHIP_TYPE = 'OD_CUST_HIER'
  AND RELATIONSHIP_CODE = 'PARENT_COMPANY'
  AND (SYSDATE BETWEEN START_DATE AND NVL(END_DATE,SYSDATE) OR START_DATE > SYSDATE)
  AND DIRECTION_CODE = 'P'
  AND status = 'A'
)
UNION
SELECT gp.gp_id,
       gp.gp_name,
       r.relationship_id,
       NULL parent_id,
       NULL parent_name,
       substr(ac.orig_system_reference,0,8) customer_id,
       ac.account_name customer_name,
       CASE WHEN TRUNC(r.end_date) > TRUNC(p_to_date) THEN 'Added'
       ELSE 'Removed'
       END action,
       r.last_update_date  modified_date,
       DECODE(ppl.full_name,null,null,ppl.full_name || '-' || ppl.employee_number) requestorval
FROM xx_cdh_gp_rel_hist r,
     hz_relationships gr,
     hz_cust_accounts ac,
     xx_cdh_gp_master gp,
     per_all_people_f ppl
where r.status_updated = 'Y'
and   ppl.person_id(+) = r.requestor
and   (r.last_update_date BETWEEN p_from_date AND p_to_date OR r.end_date BETWEEN p_from_date AND p_to_date)
and   r.relationship_id = gr.relationship_id
and   ac.party_id = gr.object_id
and   gp.party_id = gr.subject_id
and   gr.direction_code = 'P'
AND NOT EXISTS
(
  SELECT 'Y'
  FROM hz_relationships
  where subject_id = gr.object_id
  AND RELATIONSHIP_TYPE = 'OD_CUST_HIER'
  AND RELATIONSHIP_CODE = 'PARENT_COMPANY'
  AND (SYSDATE BETWEEN START_DATE AND NVL(END_DATE,SYSDATE) OR START_DATE > SYSDATE)
  AND DIRECTION_CODE = 'P'
  AND status = 'A'
)
) rel_c
ORDER BY rel_c.gp_id asc, rel_c.modified_date desc;

l_from_dt      DATE;
l_to_dt        DATE;
lb_prof_upd          BOOLEAN;

begin
    IF p_from_date IS NULL THEN
       l_from_dt   := TO_DATE(FND_PROFILE.VALUE('XX_CDH_GP_HIERARCHY_CHNG'),'DD-MON-RRRR HH24:MI:SS');
    ELSE
       l_from_dt   := TO_DATE(p_from_date,'RRRR/MM/DD HH24:MI:SS');
    END IF;
    
    IF p_to_date IS NOT NULL THEN
      l_to_dt   := TO_DATE(p_to_date,'RRRR/MM/DD HH24:MI:SS');
    END IF; 
    
    out ('Report Name: ' || 'Grandparent Hierarchy Changes Report');
    out ('Request Id: '        || fnd_global.conc_request_id());
    out ('Report Start Date: ' || TO_CHAR(NVL(l_from_dt,SYSDATE),'DD-MON-RRRR HH24:MI:SS'));
    out ('Report End Date: '   || TO_CHAR(NVL(l_to_dt,SYSDATE),'DD-MON-RRRR HH24:MI:SS'));
    
    out('Grand Parent ID,Grand Parent Name,Parent ID,Parent Name,Customer ID,Customer Name,Action,Modified Date,Requestor');
    
    FOR l_rel IN c3(NVL(l_from_dt,SYSDATE),NVL(l_to_dt,SYSDATE)) LOOP
      out('"' || l_rel.gp_id || '",' || '"' || l_rel.gp_name || '",' || '"' || l_rel.parent_id || '",' || '"' || l_rel.parent_name || '",' || '"' || l_rel.customer_id || '",' || '"' ||  l_rel.customer_name || '",' || '"' || l_rel.action || '",' || '"' || l_rel.modified_date || '",' || '"' || l_rel.requestorval || '"');  
    END LOOP;
    
    --save the profile
    lb_prof_upd := fnd_profile.SAVE('XX_CDH_GP_HIERARCHY_CHNG',TO_CHAR(sysdate,'DD-MON-RRRR HH24:MI:SS'),'SITE',null);     
  
    
    
exception
  when others then
    log('Exception: ' || SQLERRM);
    x_ret_code := 2;
end gp_hierarchy_change_rpt;
end xx_cdh_gp_report_pkg;
/
SHOW ERRORS;
