CREATE OR REPLACE VIEW XXOD_CRM_SR_CSR_V (RESOURCE_ID
                                          ,RESOURCE_NAME
                                          ,GROUP_NAME
                                          ,GROUP_ID
                                          ,RESP_ID
                                          )
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name         : XXOD_CRM_SR_CSR_V                                  |
-- | Rice ID      : CTR Reports                                        |
-- | Description  : This view is used by XXOD_SR_CSR to fetch the      |
-- |                Agents Name.                                       |
-- |Change Record :                                                    |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  12-DEC-2007 Gokila T         Initial draft version       |
-- |1.0       09-JUL-2008 M.Gautier        modifed for Def# 8481       |
-- |1.1       07-Nov-2008 Agnes P          Modified for defect # 12013 |
-- +===================================================================+
AS 
  SELECT JRRE.resource_id
          ,JRRE.source_name
          ,JRGV.group_name
         ,JRGV.GROUP_ID
          ,CSRS.RESP_ID
   FROM (SELECT  CSVL.ATTRIBUTE3 GROUP_ID,
                INSTR(REPLACE(FNDR.RESPONSIBILITY_NAME,'Agent','-'),'-')+1 RESP_FLAG,
                FNDR.RESPONSIBILITY_ID RESP_ID
        FROM    CS_INCIDENT_TYPES_VL CSVL,
                CS_SR_TYPE_MAPPING CSTM,
                FND_RESPONSIBILITY_TL FNDR
        WHERE   FNDR.RESPONSIBILITY_ID = CSTM.RESPONSIBILITY_ID
        AND     CSTM.INCIDENT_TYPE_ID = CSVL.INCIDENT_TYPE_ID
        AND     CSTM.END_DATE IS NULL
        AND     CSVL.END_DATE_ACTIVE IS NULL
        AND     FNDR.responsibility_id = FND_PROFILE.VALUE('RESP_ID')
     ) CSRS,
        jtf_rs_resource_extns    JRRE
        ,jtf_rs_group_members_vl JRGMV
        ,jtf_rs_groups_vl        JRGV
        ,jtf_rs_group_usages     JRGU
   WHERE CSRS.GROUP_ID       = JRGV.GROUP_ID
   AND   JRRE.user_id        = DECODE(CSRS.RESP_FLAG,'1',JRRE.USER_ID, FND_PROFILE.VALUE('USER_ID'))
   AND   JRGV.group_id       = JRGMV.group_id
   AND   JRGMV.resource_id   = JRRE.resource_id
   AND   JRGV.GROUP_ID       = JRGU.group_id
   AND   JRGMV.DELETE_FLAG   = 'N'
   AND   JRRE.CATEGORY       = 'EMPLOYEE'
   AND   NVL(jrgu.usage,'X') = 'SUPPORT';