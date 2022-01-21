SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  XXOD_AR_SFA_RSD_V                             |
-- | RICE ID          :  R0506                                         |
-- | Description      :  This View is used in RICE id R0506 and this   |
-- |                     view is used in the valueset XXOD_AR_SFA_RSD  |
-- |                     to fetch RSD                                  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 22-APR-2008  Sneha Anand   Initial draft version          |
-- |                                                                   |
-- +===================================================================+
CREATE OR REPLACE VIEW XXOD_AR_SFA_RSD_V AS 
SELECT DISTINCT JRRE.source_name RSD
            FROM jtf_rs_roles_vl JRRV
               ,jtf_rs_group_mbr_role_vl   JRGMRV
               ,jtf_rs_resource_extns      JRRE
               ,jtf_rs_grp_relations       JRGR
            WHERE JRRV.attribute14              ='RSD'
            AND JRRV.attribute15='BSD'
            AND JRRV.role_id = JRGMRV.role_id
            AND JRRV.role_type_code IN ('SALES','TELESALES') 
            AND JRRV.active_flag= 'Y'
            AND JRRV.manager_flag ='Y'
            AND JRGMRV.group_id   = JRGR.related_group_id
            AND JRGMRV.resource_id = JRRE.resource_id
            AND JRGR.relation_type = 'PARENT_GROUP'
            AND NVL(JRGR.delete_flag,'N')='N'
            AND TRUNC(SYSDATE) BETWEEN NVL(JRGMRV.start_date_active,SYSDATE-1) 
                                                   AND NVL(JRGMRV.end_date_active,SYSDATE+1)
            AND TRUNC(SYSDATE) BETWEEN NVL(JRRE.start_date_active,SYSDATE-1) 
                                                   AND NVL(JRRE.end_date_active,SYSDATE+1)
            AND TRUNC(SYSDATE) BETWEEN NVL(JRGR.start_date_active,SYSDATE-1) 
                                                   AND NVL(JRGR.end_date_active,SYSDATE+1);
UNION
SELECT DISTINCT JRRE.source_name RSD
            FROM jtf_rs_roles_vl JRRV
               ,jtf_rs_group_mbr_role_vl   JRGMRV
               ,jtf_rs_resource_extns      JRRE
            WHERE  JRRV.attribute14              ='RSD'
            AND JRRV.attribute15='BSD'
            AND JRRV.role_id = JRGMRV.role_id
            AND JRRV.role_type_code IN ('SALES','TELESALES') 
            AND JRRV.active_flag= 'Y'
            AND JRRV.manager_flag ='Y'
            AND JRGMRV.resource_id = JRRE.resource_id
            AND TRUNC(SYSDATE) BETWEEN NVL(JRGMRV.start_date_active,SYSDATE-1) 
                                             AND NVL(JRGMRV.end_date_active,SYSDATE+1)
            AND TRUNC(SYSDATE) BETWEEN NVL(JRRE.start_date_active,SYSDATE-1) 
                                             AND NVL(JRRE.end_date_active,SYSDATE+1);  
/
SHOW ERROR