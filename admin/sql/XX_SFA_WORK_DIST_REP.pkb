cREATE OR REPLACE PACKAGE BODY XX_SFA_WORK_DIST_REP AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAC/NAIO/WIPRO//Office Depot/Consulting Organization                  |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_SFA_WORK_DIST_REP                                          |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: SFA Work Distribution Report' with               |
-- |                     no parameters.                                                |
-- |                     The package will display following:                           |
-- |                        Number of assigned Customer sites                          |
-- |                        Number of unassigned Customer sites                        |
-- |                        Number of assigned Prospect sites                          |
-- |                        Number of unassigned Prospect sites                        |
-- |                                                                                   |
-- |                       Count of Ruled based assignments by Entity type   Territory |  
-- |                       Count of Hard assignments by Resource and Territory         |
-- |                                                                                   |
-- |                       Count of Party Sites assigned by Resource                   |
-- |                       Count of Leads assigned by Resource                         |
-- |                       Count of Opportunities assigned by Resource                 |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    XX_WORK_DIST_REP               This is the public procedure           |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |1.0       09-Jul-08   Nageswara Rao                Initial version                 |
-- +===================================================================================+


-- +===================================================================+
-- | Name  : WRITE_LOG                                                 |
-- |                                                                   |
-- | Description: This Procedure shall write to the concurrent program |
-- |              log file                                             |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_log(
                    p_message  IN VARCHAR2
                   )
IS

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

EXCEPTION
    WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'unexpected error in procedure write_log- '||SQLERRM);

END write_log;

-- +===================================================================+
-- | Name  : WRITE_OUT                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program output file                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE write_out(
                    p_message IN VARCHAR2
                   )
IS
BEGIN

FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

EXCEPTION
   WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'unexpected error in procedure write_out- '||SQLERRM);
END write_out;

-- +===================================================================+
-- | Name  : print_display                                             |
-- |                                                                   |
-- | Description:       This is the private procedure to print the     |
-- |                    details of the record in the log file          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE print_display(
                        p_assign_count   VARCHAR2  DEFAULT NULL,
                        p_employee_name  VARCHAR2 DEFAULT NULL,
                        p_emp_email     VARCHAR2 DEFAULT NULL,
                        p_employee_number  VARCHAR2 DEFAULT NULL,
                        p_prospect_customer  VARCHAR2 DEFAULT NULL,
                        p_Terr_id   VARCHAR2 DEFAULT NULL,
                        p_Job_name  VARCHAR2 DEFAULT NULL,
                        p_Role_name  VARCHAR2 DEFAULT NULL,
                        p_Division  VARCHAR2 DEFAULT NULL,
                        p_Manager_name  VARCHAR2 DEFAULT NULL,
                        p_Manager_email  VARCHAR2 DEFAULT NULL,
                        p_party_status   VARCHAR2 DEFAULT NULL,
                        p_ps_status       VARCHAR2 DEFAULT NULL,
                        p_legacy_rep    VARCHAR2 DEFAULT NULL
                        )
IS
---------------------------
--Declaring local variables
---------------------------
BEGIN


   WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD(NVL(p_assign_count,' '),10,' ')||chr(9)||
             RPAD(NVL(p_employee_name,' '),50,' ')||chr(9)||
             RPAD(NVL(p_emp_email,' '),50,' ')||chr(9)||
             RPAD(NVL(p_employee_number,' '),20,' ')||chr(9)||
             RPAD(NVL(p_prospect_customer,' '),17,' ')||chr(9)||
             RPAD(NVL(p_Terr_id,' '),10,' ')||chr(9)||
             RPAD(NVL(p_Job_name,' '),60,' ')||chr(9)||
             RPAD(NVL(p_Role_name,' '),40,' ')||chr(9)||
             RPAD(NVL(p_Division,' '),20,' ')||chr(9)||
             RPAD(NVL(p_Manager_name,' '),50,' ')||chr(9)||
             RPAD(NVL(p_Manager_email,' '),50,' ')||chr(9)||
             RPAD(NVL(p_party_status,' '),8,' ')||chr(9)||
             RPAD(NVL(p_ps_status,' '),8,' ')||chr(9)||
             RPAD(NVL(p_legacy_rep,' '),40,' ')           
);
EXCEPTION
   WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'unexpected errorin procedure write_out- '||SQLERRM);
END print_display;

PROCEDURE display_out(
                        p_assign_count   VARCHAR2 DEFAULT NULL,
                        p_source_number  VARCHAR2 DEFAULT NULL,
                        p_source_name  VARCHAR2 DEFAULT NULL,
                        p_NAMED_ACCT_TERR_ID VARCHAR2 DEFAULT NULL,
                        p_NAMED_ACCT_TERR_NAME VARCHAR2 DEFAULT NULL
                       )
IS
---------------------------
--Declaring local variables
---------------------------
BEGIN


   WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD(NVL(p_assign_count,' '),10,' ')||chr(9)||
             RPAD(NVL(p_source_number,' '),20,' ')||chr(9)||
             RPAD(NVL(p_source_name,' '),50,' ')||chr(9)||
             RPAD(NVL(p_named_acct_terr_id,' '),10,' ')||chr(9)||
             RPAD(NVL(p_NAMED_ACCT_TERR_NAME,' '),240,' ')
             );
EXCEPTION
   WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'unexpected errorin display_out procedure write_out- '||SQLERRM);
END display_out;

PROCEDURE display_outterr(
                        p_assign_count   VARCHAR2 DEFAULT NULL,
                        p_entity_type  VARCHAR2 DEFAULT NULL,
                        p_NAMED_ACCT_TERR_ID VARCHAR2 DEFAULT NULL,
                        p_NAMED_ACCT_TERR_NAME VARCHAR2 DEFAULT NULL
                       )
IS
---------------------------
--Declaring local variables
---------------------------
BEGIN


   WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD(NVL(p_assign_count,' '),10,' ')||chr(9)||
             RPAD(NVL(p_entity_type,' '),20,' ')||chr(9)||
             RPAD(NVL(p_named_acct_terr_id,' '),10,' ')||chr(9)||
             RPAD(NVL(p_NAMED_ACCT_TERR_NAME,' '),240,' ')
             );
EXCEPTION
   WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'unexpected error in display_outterr procedure write_out- '||SQLERRM);
END display_outterr;


PROCEDURE XX_WORK_DIST_REP
            (
               x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode              OUT NOCOPY NUMBER
            ) AS
ln_assgn_cust_sites  number:= 0;
ln_unassgn_cust_sites  number:= 0;
ln_assgn_pros_sites number:= 0;
ln_unassgn_pros_sites number:= 0;

CURSOR lcu_dist_ps_report
IS
select
hps.row_count         assign_count,
hps.ps_status,
hps.party_status,
papf.full_name        employee_name,
papf.email_address    emp_email_address,
papf.employee_number,
hps.attribute13       Prospect_Customer,
hps.NAMED_ACCT_TERR_ID Terr_id,
--pj.name                Job_name,
( select name 
from per_jobs
where job_id = paaf.job_id) job_name,
jrrv.role_name ,
jrrv.attribute15      Division,
hps.resource_id,
hps.resource_role_id,
hps.group_id,
--spapf.full_name      Mgr_name,
--spapf.email_address  mgr_email_address,
( select full_name 
from per_all_people_f
where person_id  = paaf.supervisor_id
and   sysdate between effective_start_date and nvl(effective_end_date,sysdate)) Mgr_name,
( select email_address 
from per_all_people_f
where person_id  = paaf.supervisor_id
and   sysdate between effective_start_date and nvl(effective_end_date,sysdate))mgr_email_address,
jrrr.attribute15     legacy_rep_id
from
(select
jrre.source_id,
jrre.source_name,
hp.attribute13,
xtntrd.resource_id,
xtntrd.resource_role_id,
xtntrd.group_id,
xtntd.named_acct_terr_id,
hps.status ps_status,
hp.status party_status,
count(1) row_count
From
apps.xx_tm_nam_terr_entity_dtls xtnted,
apps.xx_tm_nam_terr_rsc_dtls xtntrd,
apps.xx_tm_nam_terr_defn xtntd,
apps.hz_parties hp,
apps.hz_party_sites hps,
apps.jtf_rs_resource_extns jrre
where
xtntd.named_acct_terr_id = xtnted.named_acct_terr_id
and xtntrd.named_acct_terr_id = xtnted.named_acct_terr_id
and sysdate between xtntd.start_date_active and nvl(xtntd.end_date_active,sysdate)
and sysdate between xtnted.start_date_active and nvl(xtnted.end_date_active,sysdate)
and sysdate between xtntrd.start_date_active and nvl(xtntrd.end_date_active,sysdate)
and xtntd.status='A'
and xtnted.status='A'
and xtntrd.status='A'
and xtnted.entity_type='PARTY_SITE'
and xtnted.entity_id = hps.party_site_id
--and hps.status='A'
and hps.party_id = hp.party_id
and hp.party_type='ORGANIZATION'
--and hp.status='A'
and jrre.resource_id = xtntrd.resource_id
group by
jrre.source_id,
jrre.source_name,
hp.attribute13,
xtntrd.resource_id,
xtntrd.resource_role_id,
xtntrd.group_id,
xtntd.named_acct_terr_id,
hps.status,
hp.status
)hps,
per_all_people_f papf,
per_all_assignments_f paaf,
jtf_rs_roles_vl jrrv,
jtf_rs_role_relations jrrr,
jtf_rs_group_members jrgm--,
--per_jobs pj,
--per_all_people_f spapf
where
hps.source_id = papf.person_id
and sysdate between papf.effective_start_date and nvl(papf.effective_end_date,sysdate)
and paaf.person_id        = papf.person_id
and sysdate between paaf.effective_start_date and nvl(paaf.effective_end_date,sysdate)
and jrgm.resource_id      = hps.resource_id
and jrgm.group_id         = hps.group_id
and jrgm.group_member_id  = jrrr.role_resource_id
and nvl(jrgm.delete_flag,'N') = 'N'
and jrrr.role_id          = jrrv.role_id
and jrrv.role_id          = hps.resource_role_id
and jrrv.role_type_code='SALES';
--and spapf.person_id       = paaf.supervisor_id
--and sysdate between spapf.effective_start_date and nvl(spapf.effective_end_date,sysdate)
--and pj.job_id = paaf.job_id;



TYPE dist_ps_report_tbl_type IS TABLE OF lcu_dist_ps_report%ROWTYPE INDEX BY BINARY_INTEGER;
lt_dist_ps_report dist_ps_report_tbl_type;

CURSOR lcu_dist_lead_report
IS
select
hps.row_count         assign_count,
hps.party_status,
hps.ps_status,
papf.full_name        employee_name,
papf.email_address    emp_email_address,
papf.employee_number,
hps.attribute13       Prospect_Customer,
hps.NAMED_ACCT_TERR_ID Terr_id,
--pj.name                Job_name,
( select name 
from per_jobs
where job_id = paaf.job_id) job_name,
jrrv.role_name ,
jrrv.attribute15      Division,
hps.resource_id,
hps.resource_role_id,
hps.group_id,
--spapf.full_name      Mgr_name,
--spapf.email_address  mgr_email_address,
( select full_name 
from per_all_people_f
where person_id  = paaf.supervisor_id
and   sysdate between effective_start_date and nvl(effective_end_date,sysdate)) Mgr_name,
( select email_address 
from per_all_people_f
where person_id  = paaf.supervisor_id
and   sysdate between effective_start_date and nvl(effective_end_date,sysdate))mgr_email_address,
jrrr.attribute15      legacy_rep_id
from
(select
jrre.source_id,
jrre.source_name,
hp.attribute13,
xtntrd.resource_id,
xtntrd.resource_role_id,
xtntrd.group_id,
xtntd.named_acct_terr_id,
hps.status ps_status,
hp.status party_status,
count(1) row_count
From
apps.xx_tm_nam_terr_entity_dtls xtnted,
apps.xx_tm_nam_terr_rsc_dtls xtntrd,
apps.xx_tm_nam_terr_defn xtntd,
apps.as_sales_leads   lead,
apps.hz_parties hp,
apps.hz_party_sites hps,
apps.jtf_rs_resource_extns jrre
where
xtntd.named_acct_terr_id = xtnted.named_acct_terr_id
and xtntrd.named_acct_terr_id = xtnted.named_acct_terr_id
and sysdate between xtntd.start_date_active and nvl(xtntd.end_date_active,sysdate)
and sysdate between xtnted.start_date_active and nvl(xtnted.end_date_active,sysdate)
and sysdate between xtntrd.start_date_active and nvl(xtntrd.end_date_active,sysdate)
and xtntd.status='A'
and xtnted.status='A'
and xtntrd.status='A'
and xtnted.entity_type='LEAD'
and hps.party_site_id = lead.address_id
and xtnted.entity_id = lead.sales_lead_id
--and hps.status='A'
and hps.party_id = hp.party_id
and hp.party_type='ORGANIZATION'
--and hp.status='A'
and jrre.resource_id = xtntrd.resource_id
group by
jrre.source_id,
jrre.source_name,
hp.attribute13,
xtntrd.resource_id,
xtntrd.resource_role_id,
xtntrd.group_id,
xtntd.named_acct_terr_id,
hps.status,
hp.status
)hps,
per_all_people_f papf,
per_all_assignments_f paaf,
jtf_rs_roles_vl jrrv,
jtf_rs_role_relations jrrr,
jtf_rs_group_members jrgm--,
--per_jobs pj,
--per_all_people_f spapf
where
hps.source_id = papf.person_id
and sysdate between papf.effective_start_date and nvl(papf.effective_end_date,sysdate)
and paaf.person_id        = papf.person_id
and sysdate between paaf.effective_start_date and nvl(paaf.effective_end_date,sysdate)
and jrgm.resource_id      = hps.resource_id
and jrgm.group_id         = hps.group_id
and jrgm.group_member_id  = jrrr.role_resource_id
and nvl(jrgm.delete_flag,'N') = 'N'
and jrrr.role_id          = jrrv.role_id
and jrrv.role_id          = hps.resource_role_id
and jrrv.role_type_code='SALES';
--and spapf.person_id       = paaf.supervisor_id
--and sysdate between spapf.effective_start_date and nvl(spapf.effective_end_date,sysdate)
--and pj.job_id = paaf.job_id;


TYPE dist_lead_report_tbl_type IS TABLE OF lcu_dist_lead_report%ROWTYPE INDEX BY BINARY_INTEGER;
lt_dist_lead_report dist_lead_report_tbl_type;

CURSOR lcu_dist_oppor_report
IS
select
hps.row_count         assign_count,
hps.party_status,
hps.ps_status,
papf.full_name        employee_name,
papf.email_address    emp_email_address,
papf.employee_number,
hps.attribute13       Prospect_Customer,
hps.NAMED_ACCT_TERR_ID Terr_id,
--pj.name                Job_name,
( select name 
from per_jobs
where job_id = paaf.job_id) job_name,
jrrv.role_name ,
jrrv.attribute15      Division,
hps.resource_id,
hps.resource_role_id,
hps.group_id,
--spapf.full_name      Mgr_name,
--spapf.email_address  mgr_email_address,
( select full_name 
from per_all_people_f
where person_id  = paaf.supervisor_id
and   sysdate between effective_start_date and nvl(effective_end_date,sysdate)) Mgr_name,
( select email_address 
from per_all_people_f
where person_id  = paaf.supervisor_id
and   sysdate between effective_start_date and nvl(effective_end_date,sysdate))mgr_email_address,
jrrr.attribute15      legacy_rep_id
from
(select
jrre.source_id,
jrre.source_name,
hp.attribute13,
xtntrd.resource_id,
xtntrd.resource_role_id,
xtntrd.group_id,
xtntd.named_acct_terr_id,
hps.status ps_status,
hp.status party_status,
count(1) row_count
From
apps.xx_tm_nam_terr_entity_dtls xtnted,
apps.xx_tm_nam_terr_rsc_dtls xtntrd,
apps.xx_tm_nam_terr_defn xtntd,
apps.as_leads_all   oppor,
apps.hz_parties hp,
apps.hz_party_sites hps,
apps.jtf_rs_resource_extns jrre
where
xtntd.named_acct_terr_id = xtnted.named_acct_terr_id
and xtntrd.named_acct_terr_id = xtnted.named_acct_terr_id
and sysdate between xtntd.start_date_active and nvl(xtntd.end_date_active,sysdate)
and sysdate between xtnted.start_date_active and nvl(xtnted.end_date_active,sysdate)
and sysdate between xtntrd.start_date_active and nvl(xtntrd.end_date_active,sysdate)
and xtntd.status='A'
and xtnted.status='A'
and xtntrd.status='A'
and xtnted.entity_type='OPPORTUNITY'
and hps.party_site_id = oppor.address_id
and xtnted.entity_id = oppor.lead_id
--and hps.status='A'
and hps.party_id = hp.party_id
and hp.party_type='ORGANIZATION'
--and hp.status='A'
and jrre.resource_id = xtntrd.resource_id
group by
jrre.source_id,
jrre.source_name,
hp.attribute13,
xtntrd.resource_id,
xtntrd.resource_role_id,
xtntrd.group_id,
xtntd.named_acct_terr_id,
hps.status ,
hp.status
)hps,
per_all_people_f papf,
per_all_assignments_f paaf,
jtf_rs_roles_vl jrrv,
jtf_rs_role_relations jrrr,
jtf_rs_group_members jrgm--,
--per_jobs pj,
--per_all_people_f spapf
where
hps.source_id = papf.person_id
and sysdate between papf.effective_start_date and nvl(papf.effective_end_date,sysdate)
and paaf.person_id        = papf.person_id
and sysdate between paaf.effective_start_date and nvl(paaf.effective_end_date,sysdate)
and jrgm.resource_id      = hps.resource_id
and jrgm.group_id         = hps.group_id
and jrgm.group_member_id  = jrrr.role_resource_id
and nvl(jrgm.delete_flag,'N') = 'N'
and jrrr.role_id          = jrrv.role_id
and jrrv.role_id          = hps.resource_role_id
and jrrv.role_type_code='SALES';
--and spapf.person_id       = paaf.supervisor_id
--and sysdate between spapf.effective_start_date and nvl(spapf.effective_end_date,sysdate)
--and pj.job_id = paaf.job_id;


-- Autonamed vs Customer conversion creation

TYPE dist_oppor_report_tbl_type IS TABLE OF lcu_dist_oppor_report%ROWTYPE INDEX BY BINARY_INTEGER;
lt_dist_oppor_report dist_oppor_report_tbl_type;

-- Rule based query
-- Assignment Program, Territory ID, Entity type, Count
CURSOR lcu_prog_terr_category
IS
select /*+ PARALLEL */
      count(1) assign_count,
      entity_type,
      xtnted.NAMED_ACCT_TERR_ID,
      xtntd.NAMED_ACCT_TERR_NAME
from apps.xx_tm_nam_terr_entity_dtls    xtnted,
     apps.xx_tm_nam_terr_rsc_dtls       xtntrd,
     apps.xx_tm_nam_terr_defn           xtntd,
     apps.fnd_user                      fnd
WHERE xtntd.named_acct_terr_id = xtnted.named_acct_terr_id
  and xtntrd.named_acct_terr_id = xtnted.named_acct_terr_id
  AND xtnted.status                     ='A'
  AND xtntrd.status                     ='A'
  AND xtntd.status                      ='A'
  AND xtnted.request_id                 IS NULL
  AND fnd.user_id                       = xtnted.created_by
  AND fnd.user_name                     = 'ODSFA'
  AND sysdate between xtnted.start_date_active and nvl(xtnted.end_date_active,sysdate)
  AND sysdate between xtntrd.start_date_active and nvl(xtntrd.end_date_active,sysdate)
  AND sysdate between xtntd.start_date_active and nvl(xtntd.end_date_active,sysdate)  
GROUP BY entity_type,xtnted.named_acct_terr_id ,xtntd.named_acct_terr_name
ORDER BY entity_type;

TYPE prog_terr_category_tbl_type IS TABLE OF lcu_prog_terr_category%ROWTYPE INDEX BY BINARY_INTEGER;
lt_prog_terr_category prog_terr_category_tbl_type;

-- Assignment Program, Territory ID, Resource ID, Count
CURSOR lcu_prog_res_category
IS
SELECT /*+ PARALLEL */
      count(1) assign_count,
      res.source_number,
      res.source_name,
      xtntd.NAMED_ACCT_TERR_ID,
      xtntd.NAMED_ACCT_TERR_NAME
 FROM apps.xx_tm_nam_terr_entity_dtls   xtnted,
      apps.xx_tm_nam_terr_rsc_dtls      xtntrd,
      apps.xx_tm_nam_terr_defn          xtntd,
      apps.jtf_rs_resource_extns        res,
      apps.fnd_user                     fnd
WHERE xtntd.named_acct_terr_id = xtnted.named_acct_terr_id
  and xtntrd.named_acct_terr_id = xtnted.named_acct_terr_id
  AND res.resource_id                   = xtntrd.resource_id
  AND xtnted.status                     ='A'
  AND xtntrd.status                     ='A'
  AND xtntd.status                      ='A'
  AND xtnted.request_id                 IS NOT NULL
  AND fnd.user_id                       = xtnted.created_by
  AND fnd.user_name                     = 'ODSFA'
  AND sysdate between xtnted.start_date_active and nvl(xtnted.end_date_active,sysdate)
  AND sysdate between xtntrd.start_date_active and nvl(xtntrd.end_date_active,sysdate)
  AND sysdate between xtntd.start_date_active and nvl(xtntd.end_date_active,sysdate)
GROUP BY xtntd.NAMED_ACCT_TERR_ID,xtntd.named_acct_terr_name,
         res.source_number,
         res.source_name
ORDER BY res.source_number,
         res.source_name;


TYPE prog_res_category_tbl_type IS TABLE OF lcu_prog_res_category%ROWTYPE INDEX BY BINARY_INTEGER;
lt_prog_res_category prog_res_category_tbl_type;

BEGIN

lt_dist_ps_report.delete;
lt_dist_lead_report.delete;
lt_dist_oppor_report.delete;
lt_prog_terr_category.delete;
lt_prog_res_category.delete;

--Number of Customer sites assigned and un-assigned
select 
sum(decode (flag,'EXISTS',rwcount)) exist_count, 
sum(decode (flag,'NOT EXISTS',rwcount)) not_exist_count
INTO ln_assgn_cust_sites,ln_unassgn_cust_sites
from
(
select flag,count(*) rwcount from (
SELECT /*+ parallel(hp 4) parallel(hps 4) parallel(hca 4) */
   decode( 1 , (SELECT count(*)
                    FROM APPS.XX_TM_NAM_TERR_ENTITY_DTLS XTNTED,
                         APPS.XX_TM_NAM_TERR_RSC_DTLS XTNTRD,
                         APPS.XX_TM_NAM_TERR_DEFN XTNTD
                   WHERE XTNTED.ENTITY_TYPE = 'PARTY_SITE'
                     AND XTNTRD.NAMED_ACCT_TERR_ID = XTNTED.NAMED_ACCT_TERR_ID
                     AND XTNTD.NAMED_ACCT_TERR_ID = XTNTED.NAMED_ACCT_TERR_ID
                     AND XTNTED.ENTITY_ID = HPS.PARTY_SITE_ID
                     AND SYSDATE BETWEEN XTNTED.START_DATE_ACTIVE
                     AND NVL(XTNTED.END_DATE_ACTIVE,SYSDATE)
                     AND SYSDATE BETWEEN XTNTRD.START_DATE_ACTIVE
                     AND NVL(XTNTRD.END_DATE_ACTIVE,SYSDATE)
                     AND SYSDATE BETWEEN XTNTD.START_DATE_ACTIVE
                     AND NVL(XTNTD.END_DATE_ACTIVE,SYSDATE)
                     AND XTNTD.STATUS ='A'
                     AND XTNTED.STATUS ='A'
                     AND XTNTRD.STATUS ='A'
                     AND rownum = 1 ), 'EXISTS','NOT EXISTS' ) flag
 FROM APPS.HZ_PARTIES HP,
      APPS.HZ_PARTY_SITES HPS,
      APPS.HZ_CUST_ACCOUNTS HCA
WHERE HP.PARTY_ID = HCA.PARTY_ID
  AND HP.PARTY_ID = HPS.PARTY_ID
  AND HCA.STATUS ='A'
  AND HPS.STATUS ='A'
  AND HP.STATUS ='A'
  AND HP.PARTY_TYPE = 'ORGANIZATION'
  AND HP.ATTRIBUTE13 = 'CUSTOMER'
  AND HCA.ATTRIBUTE18 = 'CONTRACT'
)
group by flag) ;

--Number of Prospect sites assigned and un-assigned
select 
sum(decode (flag,'EXISTS',rwcount)) exist_count, 
sum(decode (flag,'NOT EXISTS',rwcount)) not_exist_count
INTO ln_assgn_pros_sites,ln_unassgn_pros_sites
from
(
select flag,count(*) rwcount from (
SELECT /*+ parallel(hp 4) parallel(hps 4)  */
   decode( 1 , (SELECT count(*)
                    FROM APPS.XX_TM_NAM_TERR_ENTITY_DTLS XTNTED,
                         APPS.XX_TM_NAM_TERR_RSC_DTLS XTNTRD,
                         APPS.XX_TM_NAM_TERR_DEFN XTNTD
                   WHERE XTNTED.ENTITY_TYPE = 'PARTY_SITE'
                     AND XTNTRD.NAMED_ACCT_TERR_ID = XTNTED.NAMED_ACCT_TERR_ID
                     AND XTNTD.NAMED_ACCT_TERR_ID = XTNTED.NAMED_ACCT_TERR_ID
                     AND XTNTED.ENTITY_ID = HPS.PARTY_SITE_ID
                     AND SYSDATE BETWEEN XTNTED.START_DATE_ACTIVE
                     AND NVL(XTNTED.END_DATE_ACTIVE,SYSDATE)
                     AND SYSDATE BETWEEN XTNTRD.START_DATE_ACTIVE
                     AND NVL(XTNTRD.END_DATE_ACTIVE,SYSDATE)
                     AND SYSDATE BETWEEN XTNTD.START_DATE_ACTIVE
                     AND NVL(XTNTD.END_DATE_ACTIVE,SYSDATE)
                     AND XTNTD.STATUS ='A'
                     AND XTNTED.STATUS ='A'
                     AND XTNTRD.STATUS ='A'
                     AND rownum = 1 ), 'EXISTS','NOT EXISTS' ) flag
 FROM APPS.HZ_PARTIES HP,
      APPS.HZ_PARTY_SITES HPS
WHERE HP.PARTY_ID = HPS.PARTY_ID
  AND HPS.STATUS ='A'
  AND HP.STATUS ='A'
  AND HP.PARTY_TYPE = 'ORGANIZATION'
  AND HP.ATTRIBUTE13 = 'PROSPECT'
)
group by flag); 

 -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------


   WRITE_OUT(p_message=> RPAD(' ',1,' ')||RPAD('Office Depot',90)||RPAD(' ',23,' ')||'Date: '||trunc(SYSDATE));
   WRITE_OUT(p_message=>RPAD(' ',300,'-'));
   WRITE_OUT(p_message=>RPAD(' ',30,' ')||RPAD('OD: Work Distribution Report',60));
   WRITE_OUT(p_message=>RPAD(' ',300,'-'));
   WRITE_OUT(p_message=>'');

   WRITE_OUT(p_message=>RPAD('Number of Assigned Customer sites: ',50)||ln_assgn_cust_sites); -- ln_assgn_cust_sites
   WRITE_OUT(p_message=>RPAD('Number of UnAssigned Customer sites: ',50)||ln_unassgn_cust_sites); --
   WRITE_OUT(p_message=>RPAD('Number of Assigned Party sites: ',50)||ln_assgn_pros_sites);
   WRITE_OUT(p_message=>RPAD('Number of UnAssigned Party sites: ',50)||ln_unassgn_pros_sites);


   OPEN lcu_prog_terr_category;
   FETCH lcu_prog_terr_category BULK COLLECT INTO lt_prog_terr_category;
   CLOSE lcu_prog_terr_category;

 IF lt_prog_terr_category.COUNT = 0 THEN
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No assignments records created by customer assignment conversion process ');
 ELSE
  WRITE_OUT(p_message=>RPAD(' ',300,'-'));
  WRITE_OUT(p_message=>RPAD(' ',30,' ')||RPAD('Count of Ruled based assignments by Entity type and Territory',60));
  WRITE_OUT(p_message=>RPAD(' ',300,'-'));
  WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD('Count',10)||chr(9)||
             RPAD('Entity Type',20)||chr(9)||
             RPAD('Terr ID',10)||chr(9)||
             RPAD('Terr Name ',240)
             );

    FOR i IN lt_prog_terr_category.FIRST..lt_prog_terr_category.LAST
       LOOP
           display_outterr(
                      p_assign_count            =>       TO_CHAR(lt_prog_terr_category(i).assign_count),
                      p_entity_type             =>       lt_prog_terr_category(i).entity_type,
                      p_NAMED_ACCT_TERR_ID      =>       TO_CHAR(lt_prog_terr_category(i).NAMED_ACCT_TERR_ID),
                      p_NAMED_ACCT_TERR_NAME    =>       TO_CHAR(lt_prog_terr_category(i).NAMED_ACCT_TERR_NAME)
                      );
end loop;
end if;


   OPEN lcu_prog_res_category;
   FETCH lcu_prog_res_category BULK COLLECT INTO lt_prog_res_category;
   CLOSE lcu_prog_res_category;

IF lt_prog_res_category.COUNT = 0 THEN
 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No assignments records created by Autonamed rules process ');
 ELSE
 WRITE_OUT(p_message=>RPAD(' ',300,'-'));
 WRITE_OUT(p_message=>RPAD(' ',30,' ')||RPAD('Count of Hard assignments by Resource and Territory',60));
 WRITE_OUT(p_message=>RPAD(' ',300,'-'));
  WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD('Count',10)|| chr(9)||
             RPAD('Resource Number',20)||chr(9)||
             RPAD('Resource Name',50)||chr(9)||
             RPAD('Terr ID',10)||chr(9)||
             RPAD('Terr Name ',240)
             );
    FOR i IN lt_prog_res_category.FIRST..lt_prog_res_category.LAST
       LOOP
           display_out(
                      p_assign_count            =>       TO_CHAR(lt_prog_res_category(i).assign_count),
                      p_source_number           =>       lt_prog_res_category(i).source_number,
                      p_source_name             =>       lt_prog_res_category(i).source_name,
                      p_NAMED_ACCT_TERR_ID      =>       TO_CHAR(lt_prog_res_category(i).NAMED_ACCT_TERR_ID),
                      p_NAMED_ACCT_TERR_NAME    =>       TO_CHAR(lt_prog_res_category(i).NAMED_ACCT_TERR_NAME)
                       );
end loop;
end if;

  OPEN lcu_dist_ps_report;
      FETCH lcu_dist_ps_report BULK COLLECT INTO lt_dist_ps_report;
   CLOSE lcu_dist_ps_report;


IF lt_dist_ps_report.COUNT = 0 THEN

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Party site assignment records found');
 ELSE
  WRITE_OUT(p_message=>RPAD(' ',300,'-'));
  WRITE_OUT(p_message=>RPAD(' ',30,' ')||RPAD('Count of Party Sites assigned by Resource',60));
  WRITE_OUT(p_message=>RPAD(' ',300,'-'));
  WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD('Count',10)||chr(9)||
             RPAD('Employee Name',50)||chr(9)||
             RPAD('Employee Email',50)||chr(9)||
             RPAD('Employee#',20)||chr(9)||
             RPAD('Prospect/Customer',17)||chr(9)||
--             RPAD('Terr ID',10)||chr(9)||
             RPAD('Job Name',60)||chr(9)||
             RPAD('Role Name',40)||chr(9)||
             RPAD('Division',20)||chr(9)||
             RPAD('Manager Name',50)||chr(9)||
             RPAD('Manager Email',50)||chr(9)||
             RPAD('Party St',8)||chr(9)||
             RPAD('Site St',8)||chr(9)||
             RPAD('Legacy Rep#',40)
 );
    FOR i IN lt_dist_ps_report.FIRST..lt_dist_ps_report.LAST
       LOOP
           print_display(
                      p_assign_count                    =>       To_char(lt_dist_ps_report(i).assign_count),
                      p_employee_name                   =>       lt_dist_ps_report(i).employee_name,
                      p_emp_email                       =>       lt_dist_ps_report(i).emp_email_address,
                      p_employee_number                 =>       lt_dist_ps_report(i).employee_number,
                      p_prospect_customer               =>       lt_dist_ps_report(i).prospect_customer,
 --                     p_Terr_id                         =>       To_char(lt_dist_ps_report(i).terr_id),
                      p_Job_name                        =>       lt_dist_ps_report(i).Job_name,
                      p_Role_name                       =>       lt_dist_ps_report(i).role_name,
                      p_Division                        =>       lt_dist_ps_report(i).Division,
                      p_Manager_name                    =>       lt_dist_ps_report(i).mgr_name,
                      p_Manager_email                   =>       lt_dist_ps_report(i).mgr_email_address,
                      p_party_status                    =>       lt_dist_ps_report(i).party_status,
                      p_ps_status                       =>       lt_dist_ps_report(i).ps_status,
                      p_legacy_rep                      =>       lt_dist_ps_report(i).legacy_rep_id
                       );
end loop;
end if;

 OPEN lcu_dist_lead_report;
   FETCH lcu_dist_lead_report BULK COLLECT INTO lt_dist_lead_report;
    CLOSE lcu_dist_lead_report;


IF lt_dist_lead_report.COUNT = 0 THEN

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Lead assignment records found');
 ELSE
 WRITE_OUT(p_message=>RPAD(' ',300,'-'));
 WRITE_OUT(p_message=>RPAD(' ',30,' ')||RPAD('Count of Leads assigned by Resource',60));
 WRITE_OUT(p_message=>RPAD(' ',300,'-'));
 WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD('Count',10)||chr(9)||
             RPAD('Employee Name',50)||chr(9)||
             RPAD('Employee Email',50)||chr(9)||
             RPAD('Employee#',20)||chr(9)||
             RPAD('Prospect/Customer',17)||chr(9)||
--             RPAD('Terr ID',10)||chr(9)||
             RPAD('Job Name',60)||chr(9)||
             RPAD('Role Name',40)||chr(9)||
             RPAD('Division',20)||chr(9)||
             RPAD('Manager Name',50)||chr(9)||
             RPAD('Manager Email',50)||chr(9)||
             RPAD('Party St',8)||chr(9)||
             RPAD('Site St',8)||chr(9)||
             RPAD('Legacy Rep#',40)
 );
    FOR i IN lt_dist_lead_report.FIRST..lt_dist_lead_report.LAST
       LOOP
             print_display(
                      p_assign_count                    =>       To_char(lt_dist_lead_report(i).assign_count),
                      p_employee_name                   =>       lt_dist_lead_report(i).employee_name,
                      p_emp_email                       =>       lt_dist_lead_report(i).emp_email_address,
                      p_employee_number                 =>       lt_dist_lead_report(i).employee_number,
                      p_prospect_customer               =>       lt_dist_lead_report(i).prospect_customer,
--                      p_Terr_id                         =>       To_char(lt_dist_lead_report(i).terr_id),
                      p_Job_name                        =>       lt_dist_lead_report(i).Job_name,
                      p_Role_name                       =>       lt_dist_lead_report(i).role_name,
                      p_Division                        =>       lt_dist_lead_report(i).Division,
                      p_Manager_name                    =>       lt_dist_lead_report(i).mgr_name,
                      p_Manager_email                   =>       lt_dist_lead_report(i).mgr_email_address,
                      p_party_status                    =>       lt_dist_lead_report(i).party_status,
                      p_ps_status                       =>       lt_dist_lead_report(i).ps_status,
                      p_legacy_rep                      =>       lt_dist_lead_report(i).legacy_rep_id
                       );
end loop;
end if;

OPEN lcu_dist_oppor_report;
   FETCH lcu_dist_oppor_report BULK COLLECT INTO lt_dist_oppor_report;
    CLOSE lcu_dist_oppor_report;

IF lt_dist_oppor_report.COUNT = 0 THEN

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Opportunity assignment records found');
 ELSE
 WRITE_OUT(p_message=>RPAD(' ',300,'-'));
 WRITE_OUT(p_message=>RPAD(' ',30,' ')||RPAD('Count of Opportunities assigned by Resource',60));
 WRITE_OUT(p_message=>RPAD(' ',300,'-'));
 WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD('Count',10)||chr(9)||
             RPAD('Employee Name',50)||chr(9)||
             RPAD('Employee Email',50)||chr(9)||
             RPAD('Employee#',20)||chr(9)||
             RPAD('Prospect/Customer',17)||chr(9)||
--             RPAD('Terr ID',10)||chr(9)||
             RPAD('Job Name',60)||chr(9)||
             RPAD('Role Name',40)||chr(9)||
             RPAD('Division',20)||chr(9)||
             RPAD('Manager Name',50)||chr(9)||
             RPAD('Manager Email',50)||chr(9)||
             RPAD('Party St',8)||chr(9)||
             RPAD('Site St',8)||chr(9)||
             RPAD('Legacy Rep#',40)
 );
    FOR i IN lt_dist_oppor_report.FIRST..lt_dist_oppor_report.LAST
       LOOP
           print_display(
                      p_assign_count                    =>       To_char(lt_dist_oppor_report(i).assign_count),
                      p_employee_name                   =>       lt_dist_oppor_report(i).employee_name,
                      p_emp_email                       =>       lt_dist_oppor_report(i).emp_email_address,
                      p_employee_number                 =>       lt_dist_oppor_report(i).employee_number,
                      p_prospect_customer               =>       lt_dist_oppor_report(i).prospect_customer,
--                      p_Terr_id                         =>       To_char(lt_dist_oppor_report(i).terr_id),
                      p_Job_name                        =>       lt_dist_oppor_report(i).Job_name,
                      p_Role_name                       =>       lt_dist_oppor_report(i).role_name,
                      p_Division                        =>       lt_dist_oppor_report(i).Division,
                      p_Manager_name                    =>       lt_dist_oppor_report(i).mgr_name,
                      p_Manager_email                   =>       lt_dist_oppor_report(i).mgr_email_address,
                      p_party_status                    =>       lt_dist_oppor_report(i).party_status,
                      p_ps_status                       =>       lt_dist_oppor_report(i).ps_status,
                      p_legacy_rep                      =>       lt_dist_oppor_report(i).legacy_rep_id
                       );
end loop;
end if;

 EXCEPTION
    WHEN OTHERS THEN
      APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,
                             'Unexpected error in Main Procedure XX_WORK_DIST_REP . Error - ' ||
                             SQLERRM);
      X_RETCODE := 2;
END XX_WORK_DIST_REP;

END XX_SFA_WORK_DIST_REP;
/
show errors;
