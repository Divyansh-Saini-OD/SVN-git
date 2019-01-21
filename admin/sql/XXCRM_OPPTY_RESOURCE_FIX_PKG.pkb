
SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT CREATING PACKAGE BODY XXCRM_OPPTY_RESOURCE_FIX_PKG
PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XXCRM_OPPTY_RESOURCE_FIX_PKG

AS

 -- +===========================================================================+
 -- |===========================================================================|
 -- |                  Office Depot - Project Simplify                          |
 -- |                       WIPRO Technologies                                  |
 -- +===========================================================================+
 -- | Name        : XXCRM_OPPTY_RESOURCE_FIX_PKG                                |
 -- |                                                                           |
 -- | Description : Data Fix for the Invalid Resource_id and Group_id           |
 -- |               for the given opportunity number and status.                |
 -- |                                                                           |
 -- |Change Record:                                                             |
 -- |===============                                                            |
 -- |Version   Date            Author              Remarks                      |
 -- |=======   ==========    =============        ==============================|
 -- |1.0       03-AUG-10      RenuPriya           Initial version               |
 -- |1.1       14-SEP-10      Navin Agarwal       Code Changes for Defect 6089  |
 -- |                                                                           |
 -- |===========================================================================|
 -- +===========================================================================+


   PROCEDURE UPDATE_OPP_REC_FROM_ACCESS (p_errbuf              OUT NOCOPY VARCHAR2
                                        ,p_retcode             OUT NOCOPY VARCHAR2
                                        ,p_opportunity_number  IN VARCHAR2
                                        ,p_lead_status         IN VARCHAR2
                                        ,p_commit              IN VARCHAR2
                                        )
   AS

      CURSOR C_ACCESS_RECORD (p_in_opp_id IN NUMBER,p_lead_status IN VARCHAR2)
      IS
      SELECT aaa.salesforce_id
            ,aaa.sales_group_id   old_group_id
            ,aaa.lead_id
            ,aaa.customer_id
            ,aaa.access_id
            ,aaa.last_update_date
            ,jrb.source_name       old_resource_name
            ,jrb.user_name         old_resource_user_name
            ,jrb.start_date_active old_resource_start_date_active
            ,jrb.end_date_active   old_resource_end_date_active
            ,ala.status
            ,agn.resource_role_id   new_role_id
            ,agn.resource_id        new_resource_id
            ,agn.group_id           new_group_id
      FROM   apps.as_accesses_all aaa
            ,apps.as_leads_all ala
            ,apps.jtf_rs_resource_extns jrb
            ,apps.XX_TM_NAM_TERR_CURR_ASSIGN_V AGN
      WHERE jrb.resource_id=aaa.salesforce_id
      AND  AGN.entity_type     = 'OPPORTUNITY'
      AND  AGN.entity_id       = NVL(P_In_OPP_ID,AGN.entity_id)            -- opportunity id
      AND  AGN.entity_id       = ala.lead_id
      AND  ala.lead_id=aaa.lead_id
      AND  ala.status=NVL(p_lead_status,ala.status)
      AND  aaa.lead_id is not null
      AND  trunc(jrb.end_date_active) < TRUNC(SYSDATE)
      ORDER BY agn.resource_id;

      -- Query for Group Members
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

      lb_status                        BOOLEAN;
      lc_lead_number                   VARCHAR2(30);
      l_access_profile_rec_type        AS_ACCESS_PUB.access_profile_rec_type;
      l_sales_team_rec_type            AS_ACCESS_PUB.sales_team_rec_type;
      l_access_id                      PLS_INTEGER;
      l_return_status                  VARCHAR2(5);
      l_msg_count                      NUMBER;
      l_msg_index_out                  NUMBER;
      l_msg_data                       VARCHAR2(2000);
      lc_lead_status                   VARCHAR2(30);
      lc_commit                        VARCHAR2(20);
      ln_new_resource_id               NUMBER;
      ln_new_group_id                  NUMBER;
      ln_count_report                  NUMBER                   DEFAULT 0;
      ln_count_success                 NUMBER                   DEFAULT 0;
      ln_count_error                   NUMBER                   DEFAULT 0;
      ln_count_rows                    NUMBER                   DEFAULT 0;
      lc_hard_coded_value              VARCHAR2(5)              DEFAULT NULL;
      lc_report_status                 VARCHAR2(10)             DEFAULT NULL;
      lrec_old_res_group               c_group_name%ROWTYPE;
      lrec_new_res_group               c_group_name%ROWTYPE;
      lrec_resource_name               c_resource_name%ROWTYPE;

   BEGIN

      lc_lead_number := p_opportunity_number;
      l_sales_team_rec_type.prm_keep_flag := 'Y';
      p_retcode := 0;
      lc_report_status := ' Report ';

      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, ' Opportunity Number '||'|'||
                                          ' Old Resource Id '||'|'||
                                          ' New Resource Id '||'|'||
                                          ' Old Resource Name'||'|'||
                                          ' New Resource Name '||'|'||
                                          ' Old Resource User Name'||'|'||
                                          ' New Resource User Name '||'|'||
                                          ' Old Resource Start Date Active ' ||'|'||
                                          ' Old Resource End Date Active ' ||'|'||
                                          ' New Resource Start Date Active ' ||'|'||
                                          ' New Resource End Date Active ' ||'|'||
                                          ' Old Resource group Id '||'|'||
                                          ' Old Resource group Name '||'|'||
                                          ' Old Resource Group Start Date Active ' ||'|'||
                                          ' Old Resource Group End Date Active ' ||'|'||
                                          ' New Resource group Id '||'|'||
                                          ' New Resource group Name ' ||'|'||
                                          ' New Resource Group Start Date Active ' ||'|'||
                                          ' New Resource Group End Date Active '||'|'||
                                          ' New Resource Role Id '||'|'||
                                          ' Overridden Resource '||'|'||
                                          ' Status '
                                          );

      -- Query to get the Dummy resource for the invalid resources.
      SELECT res.resource_id
            ,grp.group_id
      INTO   ln_new_resource_id
            ,ln_new_group_id
      FROM   jtf_rs_resource_extns  res
            ,jtf_rs_groups_vl       grp
            ,jtf_rs_group_members   grpmem
      WHERE res.resource_id = grpmem.resource_id
      AND   grp.group_id = grpmem.group_id
      AND   res.source_name ='Resource1, Setup'
      AND   grp.group_name ='OD_SETUP_GRP';

      FOR j in C_ACCESS_RECORD (lc_lead_number,lc_lead_status)
      LOOP

         OPEN c_sales_group(j.new_resource_id,j.new_group_id);
            FETCH c_sales_group INTO l_sales_team_rec_type.person_id;
         CLOSE c_sales_group;

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

         -- Added for Defect 6089.( To assign Dummy Resource to the invalid resource name. )
         IF (trunc(lrec_resource_name.new_res_end_date_active) < TRUNC(SYSDATE)) THEN
            l_sales_team_rec_type.salesforce_id  := ln_new_resource_id;
            l_sales_team_rec_type.sales_group_id := ln_new_group_id;
            lc_hard_coded_value := 'YES';
         ELSE
            l_sales_team_rec_type.salesforce_id  := j.new_resource_id;
            l_sales_team_rec_type.sales_group_id := j.new_group_id;
            lc_hard_coded_value := 'NO';
         END IF;

         l_sales_team_rec_type.access_id := j.access_id;
         l_sales_team_rec_type.customer_id := j.customer_id;
         l_sales_team_rec_type.last_update_date :=j.last_update_date;
         l_sales_team_rec_type.lead_id := j.lead_id;

         FND_FILE.PUT_LINE (FND_FILE.LOG,'ACCESS_ID :'||l_sales_team_rec_type.access_id);

         IF (p_commit ='Y') THEN
            lc_commit :='F';


SELECT count(*)
   INTO ln_count_rows
   FROM as_accesses_all aaa
   WHERE aaa.lead_id = j.lead_id;


IF ln_count_rows > 1 THEN
   UPDATE apps.as_accesses_all aaa
      SET aaa.lead_id = j.lead_id||'11'
   WHERE aaa.lead_id = j.lead_id
   AND   aaa.access_id != l_sales_team_rec_type.access_id;
END IF;


            AS_ACCESS_PUB.Update_SalesTeam (p_api_version_number             => 2.0,
                                            p_init_msg_list                  => FND_API.G_FALSE,
                                            p_commit                         => lc_commit,
                                            p_validation_level               => FND_API.G_VALID_LEVEL_FULL,
                                            p_access_profile_rec             => l_access_profile_rec_type,
                                            p_check_access_flag              => 'N',
                                            p_admin_flag                     => 'Y',
                                            p_admin_group_id                 => FND_API.G_MISS_NUM,
                                            p_identity_salesforce_id         => j.salesforce_id,
                                            p_sales_team_rec                 => l_sales_team_rec_type,
                                            x_return_status                  => l_return_status,
                                            x_msg_count                      => l_msg_count,
                                            x_msg_data                       => l_msg_data,
                                            x_access_id                      => l_access_id
                                            );

            IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
               COMMIT;
               FND_FILE.PUT_LINE (FND_FILE.LOG,'AS_ACCESS_PUB.Update_SalesTeam API Return Status:  '||l_return_status||'  '||'Commit Success ');
               lc_report_status := ' Success ';
               ln_count_success := ln_count_success + 1;
            ELSE
               FND_FILE.PUT_LINE (FND_FILE.LOG,'AS_ACCESS_PUB.Update_SalesTeam API Return Status:  '||l_return_status||'  '
                                  ||'No of messages:  '||l_msg_count||'  '||'Error Descriptions :  '||l_msg_data);
               p_retcode := 1;
               lc_report_status := ' Error ';
               ln_count_error := ln_count_error + 1;

               FOR k IN 1 .. l_msg_count
               LOOP
                  l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
                  FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Descriptions :'||l_msg_data);
               END LOOP;

            END IF;
         END IF;

         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,NVL(j.lead_id,null)||'|'||
                                            NVL(j.salesforce_id,null)||'|'||
                                            NVL(ln_new_resource_id,null)||'|'||
                                            '"'||j.old_resource_name||'"'||'|'||
                                            '"'||lrec_resource_name.source_name||'"'||'|'||
                                            j.old_resource_user_name||'|'||
                                            '"'||lrec_resource_name.user_name||'"'||'|'||
                                            j.old_resource_start_date_active||'|'||
                                            j.old_resource_end_date_active||'|'||
                                            lrec_resource_name.new_res_start_date_active||'|'||
                                            lrec_resource_name.new_res_end_date_active||'|'||
                                            j.old_group_id||'|'||
                                            '"'||lrec_old_res_group.group_desc||'"'||'|'||
                                            lrec_old_res_group.grp_start_date_active||'|'||
                                            lrec_old_res_group.grp_end_date_active||'|'||
                                            ln_new_group_id||'|'||
                                            lrec_new_res_group.group_desc||'|'||
                                            lrec_new_res_group.grp_start_date_active||'|'||
                                            lrec_new_res_group.grp_end_date_active||'|'||
                                            j.new_role_id||'|'||
                                            lc_hard_coded_value||'|'||
                                            lc_report_status
                                            );
         ln_count_report := ln_count_report + 1;

      END LOOP;

         FND_FILE.PUT_LINE (FND_FILE.LOG, '+---------------------------------------------------------------------------+');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Count of Reported records               : '||ln_count_report);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Count of Successfully processed records : '||ln_count_success);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Count of not processed records          : '||ln_count_error);

   EXCEPTION
      WHEN OTHERS THEN

         lb_status := FND_CONCURRENT.SET_COMPLETION_STATUS ('ERROR', NULL);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Unexpected Errors: Update_Opp_Rec_From_Access: ' ||SUBSTR(SQLERRM, 1, 255));
         p_retcode := 2;

   END UPDATE_OPP_REC_FROM_ACCESS;

END XXCRM_OPPTY_RESOURCE_FIX_PKG;
/
SHOW ERR;