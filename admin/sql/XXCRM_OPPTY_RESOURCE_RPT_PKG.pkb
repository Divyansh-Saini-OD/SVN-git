CREATE OR REPLACE PACKAGE BODY XXCRM_OPPTY_RESOURCE_RPT_PKG
AS

PROCEDURE xxcrm_oppty_resource_rpt_proc (p_errbuf             OUT NOCOPY VARCHAR2
                                        ,p_retcode             OUT NOCOPY VARCHAR2
                                        ,p_opportunity_number  IN VARCHAR2
                                        ,p_lead_status         IN VARCHAR2
                                 )
AS

   CURSOR C_ACCESS_RECORD (p_in_opp_id IN NUMBER,p_lead_status IN VARCHAR2)
   IS
   SELECT aaa.salesforce_id  old_resource_id
         ,aaa.sales_group_id old_group_id
         ,aaa.lead_id
         ,asv.meaning           opp_status
         ,aaa.customer_id
         ,ala.address_id
         ,hzp.attribute13 party_type
         ,hzp.party_number
       --,hza.orig_system_reference osr --Added by Renu
       --  ,hzos.orig_system_reference osr
         ,aaa.access_id
         ,aaa.last_update_date
         ,jrb.source_name       old_resource_name
         ,jrb.user_name         old_resource_user_name
         ,jrb.start_date_active old_resource_start_date_active
         ,jrb.end_date_active   old_resource_end_date_active
         ,agn.resource_role_id   new_role_id 
         ,agn.resource_id        new_resource_id
         ,agn.group_id           new_group_id
   FROM   apps.as_accesses_all aaa
         ,apps.as_leads_all ala
         ,apps.as_statuses_vl asv
         ,apps.jtf_rs_resource_extns jrb
         ,apps.XX_TM_NAM_TERR_CURR_ASSIGN_V AGN
         ,apps.hz_parties hzp
       --  ,hz_cust_accounts hza --Added by Renu
       --  ,apps.hz_orig_sys_references hzos
   WHERE jrb.resource_id=aaa.salesforce_id
   AND  AGN.entity_type     = 'OPPORTUNITY'
   AND ala.customer_id = hzp.party_id
  -- AND hzos.owner_table_name(+) = 'HZ_PARTY_SITES'
 --  AND hzos.owner_table_id(+) = ala.address_id
   AND  AGN.entity_id       = NVL(P_In_OPP_ID,ala.lead_id)      -- opportunity id 
   AND  ala.status = asv.status_code
   AND  ala.lead_id =aaa.lead_id
   AND  ala.status = NVL(p_lead_status,ala.status)
   AND aaa.lead_id is not null
   AND trunc(jrb.end_date_active) < TRUNC(SYSDATE)
   --AND hza.party_id(+)=hzp.party_id   --Added by Renu
   ORDER BY agn.resource_id; 

   CURSOR c_sales_group (p_in_resource_id IN NUMBER,p_in_group_id IN NUMBER)
   IS
   SELECT person_id
   FROM apps.jtf_rs_group_members
   WHERE resource_id = P_IN_RESOURCE_ID
   and group_id = p_in_group_id
   AND delete_flag   = 'N';

-- Query for resource 

   CURSOR c_resource_name (p_in_resource_id IN NUMBER)
   IS
   SELECT  source_name
         , user_name
         , start_date_active new_res_start_date_active
         , end_date_active   new_res_end_date_active
   FROM  jtf_rs_resource_extns 
   WHERE resource_id=p_in_resource_id;

-- Query for group 

   CURSOR c_group_name (p_in_group_id IN NUMBER)
   IS
   SELECT  group_desc
          ,start_date_active grp_start_date_active
          ,end_date_active   grp_end_date_active
   FROM  Jtf_rs_groups_vl 
   WHERE group_id=p_in_group_id;

-- Query for new resource role ID, role name and group-role start date and end date
   CURSOR c_role_det (p_in_resource_id IN NUMBER,p_in_group_id IN NUMBER,p_in_role_id IN NUMBER)
   IS
   SELECT  roled.role_name
         , grprole.role_id
         , grprole.start_date_active role_start_date_active
         , grprole.end_date_active   role_end_date_active
         , grprole.delete_flag role_deltete_flag
         , grpmem.delete_flag
   FROM 
        jtf_rs_groups_vl      grp,
        jtf_rs_group_members  grpmem,
        jtf_rs_role_relations grprole,
        jtf_rs_roles_vl       roled
   WHERE  grp.group_id = grpmem.group_id  
   AND    grprole.role_resource_id = grpmem.group_member_id 
   AND    grprole.role_resource_type = 'RS_GROUP_MEMBER' 
   AND    roled.role_id = grprole.role_id 
   AND    grpmem.resource_id =p_in_resource_id 
   AND    grp.group_id = p_in_group_id 
   AND    grprole.role_id = p_in_role_id;

-- Query for OSR

   CURSOR c_orig_sys_reference(ln_address_id IN NUMBER)
   IS
   SELECT orig_system_reference osr
   FROM apps.hz_orig_sys_references hzos
   WHERE hzos.owner_table_name = 'HZ_PARTY_SITES'
   AND hzos.owner_table_id = ln_address_id;



   lc_lead_status                 VARCHAR2(30);
   lc_new_resource_name           VARCHAR2(100);
   lc_new_resource_user_name      VARCHAR2(100);
   lc_old_role_name               VARCHAR2(100);
   lc_new_role_name               VARCHAR2(100);
   lc_old_group_name              VARCHAR2(100);
   lc_new_group_name              VARCHAR2(100);
   lb_status                      BOOLEAN;
   lc_lead_number                 VARCHAR2(30);
   lrec_old_res_group             c_group_name%ROWTYPE;
   lrec_new_res_group             c_group_name%ROWTYPE;
   lrec_resource_name             c_resource_name%ROWTYPE;
   lrec_role_det                  c_role_det%ROWTYPE;
   lrec_orig_sys_reference        c_orig_sys_reference%ROWTYPE;


BEGIN

    FND_FILE.PUT_LINE (FND_FILE.OUTPUT, ' Opportunity Number '||','||
                                        ' Opportunity Status '||','||
                                        ' Party Number '||','||
                                        ' Party Type '||','||
                                        ' OSR '||','||
                                        ' Old Resource Id '||','||
                                        ' New Resource Id '||','||
                                        ' Old Resource Name'||','||
                                        ' New Resource Name '||','||
                                        ' Old Resource User Name'||','||
                                        ' New Resource User Name '||','||
                                        ' Old Resource Start Date Active ' ||','||
                                        ' Old Resource End Date Active ' ||','||
                                        ' New Resource Start Date Active ' ||','||
                                        ' New Resource End Date Active ' ||','||
                                        ' Old Resource group Id '||','||
                                        ' Old Resource group Name '||','||
                                        ' Old Resource Group Start Date Active ' ||','||
                                        ' Old Resource Group End Date Active ' ||','||
                                        ' New Resource group Id '||','||
                                        ' New Resource group Name ' ||','||
                                        ' New Resource Group Start Date Active ' ||','||
                                        ' New Resource Group End Date Active '||','||
                                        ' New Resource Role Id '||','||
                                        ' New Resource Role Name ' ||','||
                                        ' New Resource Role Start Date Active ' ||','||
                                        ' New Resource Role End Date Active ' ||','||
                                        ' New Resource Role Delete Flag ' 
                                        ); 

     FOR j in C_ACCESS_RECORD (lc_lead_number,lc_lead_status) 
     LOOP

        lc_lead_number := p_opportunity_number;
        lc_lead_status := p_lead_status;
        lrec_old_res_group := NULL;
        lrec_new_res_group := NULL;
        lrec_resource_name := NULL;
        lrec_role_det := NULL;
        lrec_orig_sys_reference := NULL;

     -- Get new resource name
     OPEN c_resource_name(j.new_resource_id);
            FETCH c_resource_name INTO lrec_resource_name;
     CLOSE c_resource_name;

     -- Get old resource group name
     OPEN c_group_name(j.old_group_id);
            FETCH c_group_name INTO lrec_old_res_group;
     CLOSE c_group_name;

     -- Get new resource group name
     OPEN c_group_name(j.new_group_id);
            FETCH c_group_name INTO lrec_new_res_group;
     CLOSE c_group_name;

     -- Get new resource role name
     OPEN c_role_det(j.new_resource_id,j.new_group_id,j.new_role_id );
            FETCH c_role_det INTO lrec_role_det;
     CLOSE c_role_det;

     -- Get OSR 
     OPEN c_orig_sys_reference(j.address_id );
            FETCH c_orig_sys_reference INTO lrec_orig_sys_reference;
     CLOSE c_orig_sys_reference;


    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,   NVL(j.lead_id,null)||','||
                                               NVL(j.opp_status,null)||','||
                                               NVL(j.party_number,null)||','||
                                               NVL(j.party_type,null)||','||
                                               NVL(lrec_orig_sys_reference.osr,null)||','||
                                               NVL(j.old_resource_id,null)||','||
                                               NVL(j.new_resource_id,null)||','||
                                               '"'||j.old_resource_name||'"'||','||
                                               '"'||lrec_resource_name.source_name||'"'||','||
                                               j.old_resource_user_name||','||
                                               '"'||lrec_resource_name.user_name||'"'||','||
                                               j.old_resource_start_date_active||','||
                                               j.old_resource_end_date_active||','||
                                               lrec_resource_name.new_res_start_date_active||','||
                                               lrec_resource_name.new_res_end_date_active||','||
                                               j.old_group_id||','||
                                               '"'||lrec_old_res_group.group_desc||'"'||','||
                                               lrec_old_res_group.grp_start_date_active||','||
                                               lrec_old_res_group.grp_end_date_active||','||
                                               j.new_group_id||','||
                                               lrec_new_res_group.group_desc||','||
                                               lrec_new_res_group.grp_start_date_active||','||
                                               lrec_new_res_group.grp_end_date_active||','||
                                               j.new_role_id ||','||
                                               '"'||lrec_role_det.role_name||'"'||','||
                                               lrec_role_det.role_start_date_active||','||
                                               lrec_role_det.role_end_date_active ||','||
                                               lrec_role_det.role_deltete_flag
                                               ); 

    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
      lb_status := FND_CONCURRENT.SET_COMPLETION_STATUS ('ERROR', NULL);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Unexpected Errors: xxcrm_oppty_resource_rpt_proc: ' ||SUBSTR(SQLERRM, 1, 255));

END xxcrm_oppty_resource_rpt_proc;
END XXCRM_OPPTY_RESOURCE_RPT_PKG;

/
SHOW ERR;
