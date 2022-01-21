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
-- | Name             :  XXOD_AR_SFA_AM_V                              |
-- | RICE ID          :  R0506                                         |
-- | Description      :  This View is used in RICE id R0506 and this   |
-- |                     view is used in the valueset XXOD_AR_SFA_AM to|
-- |                     fetch AM                                      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 22-APR-2008  Sneha Anand   Initial draft version          |
-- |                                                                   |
-- +===================================================================+
CREATE OR REPLACE VIEW XXOD_AR_SFA_AM_V AS  
 SELECT  DISTINCT JRRE.source_name AM
      FROM xx_tm_nam_terr_curr_assign_v  XTNTCA
           ,jtf_rs_group_mbr_role_vl    JRGMRV 
           ,jtf_rs_roles_vl             JRRV
           ,jtf_rs_resource_extns    JRRE
      WHERE XTNTCA.ENTITY_TYPE='PARTY_SITE'       
      AND XTNTCA.GROUP_ID=JRGMRV.group_id
      AND XTNTCA.resource_role_id=JRGMRV.role_id
      AND XTNTCA.RESOURCE_ID=JRGMRV.RESOURCE_ID
      AND JRGMRV.MEMBER_FLAG='Y'
      AND JRRV.ROLE_ID=JRGMRV.role_id
      AND JRRE.resource_id(+)=JRGMRV.resource_id
      AND JRRV.role_type_code in ('SALES','TELESALES')
      AND JRRV.attribute15 ='BSD'
      AND JRRV.Active_flag ='Y'
      AND TRUNC(sysdate) BETWEEN nvl(JRGMRV.start_date_active,sysdate -1) 
         AND nvl(JRGMRV.end_date_active,sysdate + 1)
      AND TRUNC(sysdate) BETWEEN nvl(JRRE.start_date_active,sysdate -1) 
            AND nvl(JRRE.end_date_active,sysdate + 1);
            /
SHOW ERROR