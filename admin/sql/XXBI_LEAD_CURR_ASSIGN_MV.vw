-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE MATERIALIZED VIEW APPS.XXBI_LEAD_CURR_ASSIGN_MV
  BUILD DEFERRED
  REFRESH COMPLETE ON DEMAND
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_LEAD_CURR_ASSIGN_MV.vw                        |
-- | Description :  MV for Lead Current Assignments                    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       16-Mar-2009   Sreekanth Rao    Initial version           |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT 
     TERR.named_acct_terr_id
    ,TERR_ENT.entity_id          lead_id
    ,TERR_RSC.resource_id
    ,TERR_RSC.resource_role_id
    ,TERR_RSC.group_id
    ,JTFRR.role_relate_id
    ,nvl(JTFRR.attribute15,'XX') legacy_rep_id
    ,JTFRE.user_id               user_id
    ,JTFRE.user_name             user_name
    ,JTFRE.source_name           resource_name
    ,JTG.group_name              group_name
    ,JTFRE.source_number
    ,JTFRE.source_job_title
    ,JTFRE.source_email
    ,JTFRE.source_phone
    ,JRV.role_name
    ,JTGMGR.resource_id             mgr_resource_id
    ,JTGMGR.role_id                 mgr_role_id
    ,JTGMGR.group_id                mgr_group_id    
    ,nvl(JTFMRR.attribute15,'XX')   mgr_legacy_rep_id
    ,JTFMRE.user_id                 mgr_user_id
    ,JTFMRE.user_name               mgr_user_name
    ,JTFMRE.source_name             mgr_resource_name
    ,JTFMRE.source_number           mgr_source_number
    ,JTFMRE.source_job_title        mgr_job_title
    ,JTFMRE.source_email            mgr_email
    ,JTFMRE.source_phone            mgr_phone
    ,JRV.role_name                  mgr_role
FROM
     XXCRM.XX_TM_NAM_TERR_DEFN          TERR
    ,XXCRM.XX_TM_NAM_TERR_ENTITY_DTLS   TERR_ENT
    ,XXCRM.XX_TM_NAM_TERR_RSC_DTLS      TERR_RSC
    ,APPS.JTF_RS_GROUP_MEMBERS          JTGM
    ,APPS.JTF_RS_GROUPS_VL              JTG
    ,APPS.jtf_rs_group_mbr_role_vl      JTGMGR
    ,APPS.JTF_RS_ROLE_RELATIONS         JTFRR
    ,APPS.JTF_RS_ROLE_RELATIONS         JTFMRR
    ,APPS.JTF_RS_ROLES_VL               JRV
    ,APPS.JTF_RS_RESOURCE_EXTNS         JTFRE
    ,APPS.JTF_RS_RESOURCE_EXTNS         JTFMRE
WHERE
       TERR_ENT.entity_type = 'LEAD'
   AND TERR.named_acct_terr_id     = TERR_RSC.named_acct_terr_id
   AND TERR_ENT.named_acct_terr_id = TERR_RSC.named_acct_terr_id
   AND TERR_ENT.named_acct_terr_id = TERR.named_acct_terr_id
   AND sysdate between NVL(TERR.start_date_active,sysdate-1) and nvl(TERR.end_date_active,sysdate+1)
   AND sysdate between NVL(TERR_ENT.start_date_active,sysdate-1) and nvl(TERR_ENT.end_date_active,sysdate+1)
   AND sysdate between NVL(TERR_RSC.start_date_active,sysdate-1) and nvl(TERR_RSC.end_date_active,sysdate+1)
   AND sysdate between NVL(JTFRR.start_date_active,sysdate-1) and nvl(JTFRR.end_date_active,sysdate+1)
   AND sysdate between NVL(JTFRE.start_date_active,sysdate-1) and nvl(JTFRE.end_date_active,sysdate+1)
   AND NVL(TERR.status,'A') = 'A'
   AND NVL(TERR_ENT.status,'A') = 'A'
   AND NVL(TERR_RSC.status,'A') = 'A'
   AND JTGM.resource_id = TERR_RSC.resource_id
   AND JTFRR.role_id = TERR_RSC.resource_role_id
   AND JTGM.group_id = TERR_RSC.group_id
   AND JTGM.group_id = JTGMGR.group_id
   AND JTGM.group_id = JTG.group_id
   AND sysdate between NVL(JTG.start_date_active,sysdate-1) and nvl(JTG.end_date_active,sysdate+1)      
   AND JTGMGR.manager_flag = 'Y'
   AND sysdate between NVL(JTGMGR.start_date_active,sysdate-1) and nvl(JTGMGR.end_date_active,sysdate+1)   
   AND JTFMRR.role_relate_id = JTGMGR.role_relate_id
   AND sysdate between NVL(JTFMRR.start_date_active,sysdate-1) and nvl(JTFMRR.end_date_active,sysdate+1)
   AND JTGM.group_member_id = JTFRR.role_resource_id
   AND sysdate between NVL(JTFMRE.start_date_active,sysdate-1) and nvl(JTFMRE.end_date_active,sysdate+1)
   AND JTFMRE.resource_id = JTGMGR.resource_id
   AND nvl(JTFRR.delete_flag,   'N') <> 'Y'
   AND nvl(JTGM.delete_flag,   'N') <> 'Y'
   AND JTFRR.role_resource_type = 'RS_GROUP_MEMBER'
   AND JTFRR.role_id = JRV.role_id
   AND JTFRE.resource_id = TERR_RSC.resource_id;

----------------------------------------------------------
-- Grant to XXCRM
----------------------------------------------------------
GRANT ALL ON XXBI_LEAD_CURR_ASSIGN_MV TO XXCRM;

SHOW ERRORS;
EXIT;