-- $Id:  $
-- $Rev:  $
-- $HeadURL:  $
-- $Author:  $
-- $Date:  $
SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace PACKAGE BODY XXCRM_OPPTY_FIX_PKG
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify  Rel 1.2                           |
-- +=====================================================================================+
-- |                                                                                     |
-- | Name             : Remove_Opp_Rec_From_Access                                       |
-- |                                                                                     |
-- | Description      : Fix the opportunities as per Defect - 4487                       |
-- |                                                                                     |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date        Author                       Remarks                           |
-- |=======   ==========  ====================         ==================================|
-- |Draft 1.0 04-APR-10   Nabarun Ghosh                Draft version                     |
-- | 1.1      06-MAY-10   Sreekanth Rao                Updated the Program to use delete |
-- |                                                   API, as data was duplicated and we|
-- |                                                   do not use AS_ACCESSES_ALL        |
-- | 1.2      04-JUN-10   Anitha Devarajulu            Updated the Program to use Update |
-- |                                                   API to update sales group id      |
-- | 1.3      13-SEP-10   Lokesh Kumar                 API to update stage and methodolog|
-- +=====================================================================================+
AS

PROCEDURE Remove_Opp_Rec_From_Access (p_errbuf              OUT NOCOPY VARCHAR2
                                     ,p_retcode             OUT NOCOPY VARCHAR2
                                     ,p_opportunity_number  IN VARCHAR2
                                     )
AS

         lb_status                   BOOLEAN;
         lc_lead_number              VARCHAR2(30);
         l_access_profile_rec_type   AS_ACCESS_PUB.access_profile_rec_type;
         l_sales_team_rec_type       AS_ACCESS_PUB.sales_team_rec_type;
         l_access_id                 PLS_INTEGER;
         l_return_status             VARCHAR2(5);
         l_msg_count                 NUMBER;
         l_msg_index_out             NUMBER;
         l_msg_data                  VARCHAR2(2000);
         lc_delete                   VARCHAR2(2) := NULL;
--       l_application_id     pls_integer;
--       l_responsibility_id  pls_integer;
--       l_user_id            pls_integer;
--       l_global_user_id            pls_integer;

         CURSOR c_leads (p_in_oppty_num IN VARCHAR2)
         IS
         SELECT /*+ no_merge(m) */  lead_id
         FROM
         (
          SELECT  DISTINCT
               LEAD.lead_id
              ,LEAD.lead_number
              ,LEAD.description opportunity
              ,LEAD.status
              ,LEAD.customer_id
              ,LEAD.address_id
              ,HZPS.party_site_id
              ,HP.party_id
              ,HP.party_name
              ,LEAD.owner_salesforce_id
              ,(
                SELECT source_name
                FROM   apps.jtf_rs_resource_extns
                WHERE  resource_id = LEAD.owner_salesforce_id
                AND    TRUNC(SYSDATE) BETWEEN NVL(TRUNC(start_date_active),TRUNC(SYSDATE)-1)
                AND     NVL(TRUNC(end_date_active),TRUNC(SYSDATE)+1)
               )                      resource_name
              ,JTGRP.group_id        resource_group_id
              ,JTGRP.group_name      resource_group_name
              ,LEAD.owner_sales_group_id
              ,ASOSCTYPES.name sales_credit_type
              ,CREDIT.person_id
              ,CREDIT.salesgroup_id
              ,ACCES.sales_group_id access_sales_group_id
        FROM   apps.as_leads_all     LEAD
              ,as_accesses_all       ACCES
              ,apps.as_sales_credits CREDIT
              ,apps.oe_sales_credit_types ASOSCTYPES
              ,apps.hz_party_sites   HZPS
              ,apps.hz_parties         HP
              ,apps.jtf_rs_group_members_vl JTGM
              ,apps.jtf_rs_groups_tl        JTGRP
              ,apps.jtf_rs_roles_b        JROLE
              ,apps.jtf_rs_role_relations   JTRR
        WHERE  (   LEAD.lead_number  = p_in_oppty_num
                 OR p_in_oppty_num IS NULL)
        AND    LEAD.lead_id = ACCES.lead_id
        AND    LEAD.lead_id = CREDIT.lead_id
        AND    LEAD.owner_salesforce_id = CREDIT.salesforce_id
        AND    ACCES.sales_group_id IS NULL
        AND    CREDIT.credit_type_id    = ASOSCTYPES.sales_credit_type_id
        AND    nvl(JTGM.delete_flag,'N')='N'
        AND   JTGM.resource_id         = LEAD.owner_salesforce_id
        AND   JTGM.group_id = JTGRP.group_id
        AND    JROLE.role_type_code  = 'SALES'
        and    JROLE.member_flag = 'Y'
        AND   nvl(JTRR.delete_flag,'N')='N'
        AND   TRUNC(SYSDATE) BETWEEN NVL(TRUNC(JTRR.start_date_active),TRUNC(SYSDATE)-1)
                                 AND     NVL(TRUNC(JTRR.end_date_active),TRUNC(SYSDATE)+1)
        and    JROLE.role_id = JTRR.role_id
        AND    JTRR.role_resource_type  = 'RS_GROUP_MEMBER'
        AND    JTRR.role_resource_id    = JTGM.group_member_id
        AND    LEAD.address_id = HZPS.party_site_id(+)
        AND    HZPS.party_id = HP.party_id(+)
        ORDER BY LEAD.lead_id
        ) m;

CURSOR C_ACCESS_RECORD (P_In_OPP_ID IN NUMBER)
IS
SELECT *
FROM  apps.as_accesses_all
WHERE lead_id = P_In_OPP_ID;

BEGIN

     lc_lead_number := p_opportunity_number;

     FND_FILE.PUT_LINE (FND_FILE.LOG,'Parameter : Opportunity Number: '||lc_lead_number);

     l_sales_team_rec_type.prm_keep_flag := 'Y';

    FOR lead_rec IN c_leads (lc_lead_number)
    LOOP

      FOR j in C_ACCESS_RECORD (lead_rec.lead_id)
      LOOP
--      l_access_profile_rec_type.
        l_sales_team_rec_type.access_id := j.access_id;

            FND_FILE.PUT_LINE (FND_FILE.LOG,'access_id :'||l_sales_team_rec_type.access_id);

            AS_ACCESS_PUB.Delete_SalesTeam
            ( p_api_version_number             => 2.0,
                    p_init_msg_list                  => FND_API.G_FALSE,
                    p_commit                         => FND_API.G_TRUE,
                    p_validation_level                     => FND_API.G_VALID_LEVEL_FULL,--90,
                    p_access_profile_rec                   => l_access_profile_rec_type,
                    p_check_access_flag              => 'N',
                    p_admin_flag                     => 'Y',
                    p_admin_group_id                 => FND_API.G_MISS_NUM,
                    p_identity_salesforce_id         => j.salesforce_id,
                    p_sales_team_rec                 => l_sales_team_rec_type,
                    x_return_status                  => l_return_status,
                    x_msg_count                      => l_msg_count,
                    x_msg_data                       => l_msg_data
             );

        FND_FILE.PUT_LINE (FND_FILE.LOG,'AS_ACCESS_PUB.Update_SalesTeam API Return Status:  '||l_return_status||'  '||'No of messages:  '||l_msg_count||'  '||'Error Descriptions :  '||l_msg_data||'  '||' access_id updated:  '||l_access_id);


            IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
               COMMIT;

               FND_FILE.PUT_LINE (FND_FILE.LOG,'AS_ACCESS_PUB.Update_SalesTeam API Return Status:  '||l_return_status||'  '||'Commit Success ');

            ELSE
                        FOR k IN 1 .. l_msg_count
                        LOOP
                           l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
                      FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Descriptions :'||l_msg_data);
                        END LOOP;

            END IF;

      END LOOP;

    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
      lb_status := FND_CONCURRENT.SET_COMPLETION_STATUS ('ERROR', NULL);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Unexpected Errors: Remove_Opp_Rec_From_Access: ' ||SUBSTR(SQLERRM, 1, 255));

END Remove_Opp_Rec_From_Access;


PROCEDURE Update_Opp_Rec_From_Access (p_errbuf              OUT NOCOPY VARCHAR2
                                     ,p_retcode             OUT NOCOPY VARCHAR2
                                     ,p_opportunity_number  IN VARCHAR2
                                 )
AS


   lb_status                   BOOLEAN;
   lc_lead_number              VARCHAR2(30);
   l_access_profile_rec_type   AS_ACCESS_PUB.access_profile_rec_type;
   l_sales_team_rec_type       AS_ACCESS_PUB.sales_team_rec_type;
   l_access_id                 PLS_INTEGER;
   l_return_status             VARCHAR2(5);
   l_msg_count                 NUMBER;
   l_msg_index_out             NUMBER;
   l_msg_data                  VARCHAR2(2000);
   lc_delete                   VARCHAR2(2) := NULL;

/*   CURSOR c_leads (p_in_oppty_num IN VARCHAR2)
   IS
   SELECT /*+ no_merge(m)  lead_id
   FROM
   (
      SELECT  DISTINCT
              LEAD.lead_id
             ,LEAD.lead_number
             ,LEAD.description opportunity
             ,LEAD.status
             ,LEAD.customer_id
             ,LEAD.address_id
             ,HZPS.party_site_id
             ,HP.party_id
             ,HP.party_name
             ,LEAD.owner_salesforce_id
             ,(
             SELECT source_name
             FROM   apps.jtf_rs_resource_extns
             WHERE  resource_id = LEAD.owner_salesforce_id
             AND    TRUNC(SYSDATE) BETWEEN NVL(TRUNC(start_date_active),TRUNC(SYSDATE)-1)
             AND     NVL(TRUNC(end_date_active),TRUNC(SYSDATE)+1)
             )                      resource_name
             ,JTGRP.group_id        resource_group_id
             ,JTGRP.group_name      resource_group_name
             ,LEAD.owner_sales_group_id
             ,ASOSCTYPES.name sales_credit_type
             ,CREDIT.person_id
             ,CREDIT.salesgroup_id
             ,ACCES.sales_group_id access_sales_group_id
      FROM   apps.as_leads_all     LEAD
             ,as_accesses_all       ACCES
             ,apps.as_sales_credits CREDIT
             ,apps.oe_sales_credit_types ASOSCTYPES
             ,apps.hz_party_sites   HZPS
             ,apps.hz_parties         HP
             ,apps.jtf_rs_group_members_vl JTGM
             ,apps.jtf_rs_groups_tl        JTGRP
             ,apps.jtf_rs_roles_b        JROLE
             ,apps.jtf_rs_role_relations   JTRR
      WHERE  (LEAD.lead_number        = p_in_oppty_num
              OR p_in_oppty_num       IS NULL)
      AND    LEAD.lead_id             = ACCES.lead_id
      AND    LEAD.lead_id             = CREDIT.lead_id
      AND    LEAD.owner_salesforce_id = CREDIT.salesforce_id
      AND    ACCES.sales_group_id     IS NULL
      AND    CREDIT.credit_type_id    = ASOSCTYPES.sales_credit_type_id
      AND    NVL(JTGM.delete_flag,'N')='N'
      AND    JTGM.resource_id         = LEAD.owner_salesforce_id
      AND    JTGM.group_id            = JTGRP.group_id
      AND    JROLE.role_type_code     = 'SALES'
      AND    JROLE.member_flag        = 'Y'
      AND    NVL(JTRR.delete_flag,'N')='N'
      AND    TRUNC(SYSDATE) BETWEEN NVL(TRUNC(JTRR.start_date_active),TRUNC(SYSDATE)-1)
                                 AND     NVL(TRUNC(JTRR.end_date_active),TRUNC(SYSDATE)+1)
      AND    JROLE.role_id = JTRR.role_id
      AND    JTRR.role_resource_type  = 'RS_GROUP_MEMBER'
      AND    JTRR.role_resource_id    = JTGM.group_member_id
      AND    LEAD.address_id          = HZPS.party_site_id(+)
      AND    HZPS.party_id            = HP.party_id(+)
      ORDER BY LEAD.lead_id
      ) m;*/

   CURSOR C_ACCESS_RECORD (P_In_OPP_ID IN NUMBER)
   IS
   SELECT *
   FROM apps.as_accesses_all
   WHERE lead_id        = NVL(P_In_OPP_ID,lead_id)
   AND   sales_group_id IS NULL;

   CURSOR c_sales_group (P_IN_RESOURCE_ID IN NUMBER)
   IS
   SELECT group_id
         ,person_id
   FROM apps.jtf_rs_group_members
   WHERE resource_id = P_IN_RESOURCE_ID
   AND delete_flag   = 'N';

BEGIN

   lc_lead_number := p_opportunity_number;

   FND_FILE.PUT_LINE (FND_FILE.LOG,'Parameter : Opportunity Number: '||lc_lead_number);

   l_sales_team_rec_type.prm_keep_flag := 'Y';

/*   FOR lead_rec IN c_leads (lc_lead_number)
   LOOP*/

      FOR j in C_ACCESS_RECORD (lc_lead_number)--lead_rec.lead_id)
      LOOP

         OPEN c_sales_group(j.salesforce_id);
            FETCH c_sales_group INTO l_sales_team_rec_type.sales_group_id,l_sales_team_rec_type.person_id;
         CLOSE c_sales_group;

         IF (l_sales_team_rec_type.sales_group_id IS NULL) then
            SELECT GROUP_ID
            INTO l_sales_team_rec_type.sales_group_id
            FROM JTF_RS_GROUPS_TL
            WHERE group_name = 'OD_SETUP_GRP'
            AND language='US';
         END IF;

         l_sales_team_rec_type.access_id := j.access_id;
         l_sales_team_rec_type.salesforce_id := j.salesforce_id;
         l_sales_team_rec_type.customer_id := j.customer_id;
         l_sales_team_rec_type.last_update_date :=j.last_update_date;
         l_sales_team_rec_type.lead_id := j.lead_id;

         FND_FILE.PUT_LINE (FND_FILE.LOG,'ACCESS_ID :'||l_sales_team_rec_type.access_id);

            AS_ACCESS_PUB.Update_SalesTeam
            (p_api_version_number             => 2.0,
             p_init_msg_list                  => FND_API.G_FALSE,
             p_commit                         => FND_API.G_TRUE,
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

         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Sales Group id of Opportunity: ' || l_sales_team_rec_type.lead_id
                                            || ' is updated with ' || l_sales_team_rec_type.sales_group_id);

         FND_FILE.PUT_LINE (FND_FILE.LOG,'AS_ACCESS_PUB.Update_SalesTeam API Return Status:  '||l_return_status
                                          ||' access_id updated:  '||l_access_id);

         IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
            COMMIT;
            FND_FILE.PUT_LINE (FND_FILE.LOG,'AS_ACCESS_PUB.Update_SalesTeam API Return Status:  '||l_return_status||'  '||'Commit Success ');
         ELSE
            FND_FILE.PUT_LINE (FND_FILE.LOG,'AS_ACCESS_PUB.Update_SalesTeam API Return Status:  '||l_return_status||'  '
                                  ||'No of messages:  '||l_msg_count||'  '||'Error Descriptions :  '||l_msg_data||'  '
                                  ||' access_id updated:  '||l_access_id);
            FOR k IN 1 .. l_msg_count
            LOOP
               l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
               FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Descriptions :'||l_msg_data);
            END LOOP;

         END IF;

      END LOOP;

--   END LOOP;

EXCEPTION
    WHEN OTHERS THEN
      lb_status := FND_CONCURRENT.SET_COMPLETION_STATUS ('ERROR', NULL);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Unexpected Errors: Update_Opp_Rec_From_Access: ' ||SUBSTR(SQLERRM, 1, 255));

END Update_Opp_Rec_From_Access;




PROCEDURE Update_Opp_Rec_with_stage_meth (p_errbuf              OUT NOCOPY VARCHAR2
                                         ,p_retcode             OUT NOCOPY VARCHAR2
                                         ,p_update              IN VARCHAR2
                                         ,p_lead_num            IN NUMBER
                                         ,p_salesforce_name     IN VARCHAR2
                                        )
AS

  l_return_status VARCHAR2(200);
  l_msg_count     NUMBER;
  l_msg_data      VARCHAR2(2000);
  l_head_rec AS_OPPORTUNITY_PUB.HEADER_REC_TYPE;
  l_err_msg         VARCHAR2(4000);
  l_commit        VARCHAR2(1) := 'N';
  l_lead_id  NUMBER;
  l_lead_num NUMBER := p_lead_num;
  l_salesforce_id NUMBER;
  l_count NUMBER := 0;
  SALESFORCE_ID_NOT_FOUND EXCEPTION;
  
  -- This cursor gets the list of opportunities
  -- linked to customers
   CURSOR GET_OPP_CUST_LIST(lead_count NUMBER)
  IS
     SELECT a.lead_id       ,
      a.last_update_date    ,
      b.stage_name          ,
      c.sales_stage_id      ,
      d.sales_methodology_id,
      d.name,
      a.lead_number ,
      nvl(e.resource_id,f.owner_salesforce_id) resource_id ,
      a.win_probability
       FROM AS_OPPORTUNITIES_V a,
      XX_SFA_PROB_STAGE_MAP b   ,
      as_sales_stages_vl c      ,
      as_sales_methodology_vl d,
       XX_TM_NAM_TERR_CURR_ASSIGN_V e,
       as_leads_all f
      WHERE a.win_probability between b.min_win_prob and b.max_win_prob
    AND c.name                  = b.stage_name
    AND nvl(e.entity_type,'OPPORTUNITY') = 'OPPORTUNITY'
    AND e.entity_id(+) = a.lead_id
    and a.lead_id = f.lead_id
    AND EXISTS
      (SELECT 1 FROM hz_cust_accounts WHERE a.customer_id = party_id
      )
  AND d.name = 'Retain and Grow'
  AND rownum < (lead_count+1);

  -- This cursor gets the list of opportunities
  -- linked to prospects
  CURSOR GET_OPP_PROSP_LIST(lead_count NUMBER)
  IS
     SELECT a.lead_id       ,
      a.last_update_date    ,
      b.stage_name          ,
      c.sales_stage_id      ,
      d.sales_methodology_id,
      d.name,
      a.lead_number,
      nvl(e.resource_id,f.owner_salesforce_id) resource_id,
      a.win_probability
       FROM AS_OPPORTUNITIES_V a,
      XX_SFA_PROB_STAGE_MAP b   ,
      as_sales_stages_vl c      ,
      as_sales_methodology_vl d ,
       XX_TM_NAM_TERR_CURR_ASSIGN_V e,
       as_leads_all f
      WHERE a.win_probability between b.min_win_prob and b.max_win_prob
    AND c.name                  = b.stage_name
    AND nvl(e.entity_type,'OPPORTUNITY') = 'OPPORTUNITY'
    AND e.entity_id(+) = a.lead_id
    and a.lead_id = f.lead_id
    AND NOT EXISTS
      (SELECT 1 FROM hz_cust_accounts WHERE a.customer_id = party_id
      )
  AND d.name = 'New Business'
  AND rownum < (lead_count + 1);

Begin

FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' Starting program to Prospects and Customers  ');

-- If no value is passed then assigning a very high valuee
-- for row count.
IF l_lead_num is null THEN
  l_lead_num := 10000000;
END IF;

l_salesforce_id := null;

IF p_salesforce_name IS NOT NULL THEN
  SELECT count(1) into l_count  FROM jtf_rs_resource_extns_vl where source_name = p_salesforce_name;
  
  IF l_count = 0 THEN
    RAISE SALESFORCE_ID_NOT_FOUND;

  ELSE
    SELECT resource_id into l_salesforce_id  FROM jtf_rs_resource_extns_vl where source_name = p_salesforce_name;
  END IF;  
  
END IF;

FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Updating opportunities of customers');

FOR l_opp IN GET_OPP_CUST_LIST(l_lead_num)
  LOOP
    l_head_rec.lead_id                                         := l_opp.lead_id;
    l_head_rec.sales_stage_id                                  := l_opp.sales_stage_id;
    l_head_rec.Sales_Methodology_Id                            := l_opp.sales_methodology_id;
    l_head_rec.last_update_date                                := l_opp.last_update_date;

    -- If we want to update stage and methodology
    -- then Opportunity update api only works if stage and methodology is null
    -- so updating it
    update as_leads_all
    set sales_stage_id = null, sales_methodology_id = null
    where lead_id = l_opp.lead_id;
    
   l_salesforce_id := NVL(l_salesforce_id,l_opp.resource_id);

   IF p_update = 'Y' THEN
    AS_OPPORTUNITY_PUB.Update_Opp_Header ( p_api_version_number => 2.0
                                         , p_init_msg_list => FND_API.G_TRUE
                                         , p_commit => FND_API.G_TRUE
                                         , p_validation_level => FND_API.G_VALID_LEVEL_NONE
                                         , p_header_rec => l_head_rec
                                         , p_check_access_flag => FND_API.G_FALSE
                                         , p_admin_flag => FND_API.G_FALSE
                                         , p_admin_group_id => FND_API.G_MISS_NUM
                                         , p_identity_salesforce_id => l_salesforce_id
                                         , p_partner_cont_party_id => FND_API.G_MISS_NUM
                                         , p_profile_tbl => AS_UTILITY_PUB.G_MISS_PROFILE_TBL
                                         , x_return_status => l_return_status
                                         , x_msg_count => l_msg_count
                                         , x_msg_data => l_msg_data
                                         , x_lead_id => l_lead_id);

    IF l_return_status = 'S' THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Updated Opportunity number '||l_opp.lead_number||' having probability '||l_opp.win_probability||' with stage as '||l_opp.stage_name||' and methodology as '||l_opp.name);
    ELSE
      p_retcode := '1';
      fnd_msg_pub.count_and_get ( p_encoded => 'F', p_count =>l_msg_count , p_data =>l_err_msg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Opportunity number '||l_opp.lead_number||' errored out with following error while using salesforce_id ' || l_salesforce_id);
      FOR k IN 1 .. l_msg_count
      LOOP
        l_err_msg := fnd_msg_pub.get( p_msg_index => k,p_encoded => 'F');
        FND_FILE.PUT_LINE(FND_FILE.LOG,l_err_msg);
      END LOOP;
      fnd_msg_pub.delete_msg;
    END IF;

   ELSE
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Opportunity number '||l_opp.lead_number||' with probability '||l_opp.win_probability ||' is mapped with stage  '||l_opp.stage_name||' and methodology  '||l_opp.name);
   END IF;
    l_lead_num := l_lead_num - 1;
  END LOOP;

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' Finished updating oportunities of customers  ');

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Going to update prospects');

  FOR l_opp IN GET_OPP_PROSP_LIST(l_lead_num)
  LOOP
    l_head_rec.lead_id                                         := l_opp.lead_id;
    l_head_rec.sales_stage_id                                  := l_opp.sales_stage_id;
    l_head_rec.Sales_Methodology_Id                            := l_opp.sales_methodology_id;
    l_head_rec.last_update_date                                := l_opp.last_update_date;

    -- If we want to update stage and methodology
    -- then Opportunity update api only works if stage and methodology is null
    -- so updating it
    update as_leads_all
    set sales_stage_id = null, sales_methodology_id = null
    where lead_id = l_opp.lead_id;

   l_salesforce_id := NVL(l_salesforce_id,l_opp.resource_id);

   IF p_update = 'Y' THEN
    AS_OPPORTUNITY_PUB.Update_Opp_Header ( p_api_version_number => 2.0
                                         , p_init_msg_list => FND_API.G_TRUE
                                         , p_commit => FND_API.G_TRUE
                                         , p_validation_level => FND_API.G_VALID_LEVEL_NONE
                                         , p_header_rec => l_head_rec
                                         , p_check_access_flag => FND_API.G_FALSE
                                         , p_admin_flag => FND_API.G_FALSE
                                         , p_admin_group_id => FND_API.G_MISS_NUM
                                         , p_identity_salesforce_id => l_salesforce_id
                                         , p_partner_cont_party_id => FND_API.G_MISS_NUM
                                         , p_profile_tbl => AS_UTILITY_PUB.G_MISS_PROFILE_TBL
                                         , x_return_status => l_return_status
                                         , x_msg_count => l_msg_count
                                         , x_msg_data => l_msg_data
                                         , x_lead_id => l_lead_id);

    IF l_return_status = 'S' THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Updated Opportunity number '||l_opp.lead_number||' having probability '||l_opp.win_probability||' with stage as '||l_opp.stage_name||' and methodology as '||l_opp.name);
    ELSE
      p_retcode := '1';
      fnd_msg_pub.count_and_get ( p_encoded => 'F', p_count =>l_msg_count , p_data =>l_err_msg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Opportunity number '||l_opp.lead_number||' errored out with following error while using salesforce_id ' || l_salesforce_id);
      FOR k IN 1 .. l_msg_count
      LOOP
        l_err_msg := fnd_msg_pub.get( p_msg_index => k,p_encoded => 'F');
        FND_FILE.PUT_LINE(FND_FILE.LOG,l_err_msg);
      END LOOP;
      fnd_msg_pub.delete_msg;
    END IF;

   ELSE
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Opportunity number '||l_opp.lead_number||' with probability '||l_opp.win_probability ||' is mapped with stage  '||l_opp.stage_name||' and methodology  '||l_opp.name);
    END IF;

  END LOOP;

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' Finished updating oportunities of prospects');

EXCEPTION
WHEN SALESFORCE_ID_NOT_FOUND THEN
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Resource was found for the salesforce ' || p_salesforce_name);
    p_errbuf  := 'No Resource was found for the salesforce ' || p_salesforce_name;
    p_retcode := '2';
WHEN OTHERS THEN
    p_errbuf  := sqlerrm;
    p_retcode := '2';

end  Update_Opp_Rec_with_stage_meth;


END XXCRM_OPPTY_FIX_PKG;

/
SHOW ERRORS;