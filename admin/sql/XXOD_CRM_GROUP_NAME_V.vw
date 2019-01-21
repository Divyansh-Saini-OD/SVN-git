CREATE OR REPLACE VIEW XXOD_CRM_GROUP_NAME_V (GROUP_NAME
                                              ,GROUP_ID
                                              ,RESP_ID
                                              )
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name         : XXOD_CRM_GROUP_NAME_V                              |
-- | Rice ID      : CTR Reports                                        |
-- | Description  : This view is used by XXOD_SR_GROUP_NAME value set  |
-- |                to fetch the Group Name for which the User logging |
-- |                in is associated.                                  |
-- |Change Record :                                                    |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  23-OCT-2007 Christina S        Initial draft version     |
-- |Version 1.0  08-JUL-2008  M.Gautier modifed view to defect # 8481  |
-- |Version 1.1  17-NOV-2008  Agnes      Modified view for defect#12013|
-- +===================================================================+
AS 
  SELECT DISTINCT JRGT.GROUP_NAME,JRGT.GROUP_ID, CSRS.RESP_ID
FROM   JTF_RS_GROUPS_VL JRGT,
       JTF_RS_GROUP_USAGES JRGU,
       JTF_RS_GROUP_MEMBERS JRGM,
      JTF_RS_RESOURCE_EXTNS JRRE,
       (SELECT  CSVL.ATTRIBUTE3 GROUP_ID,
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
              ) CSRS
WHERE  CSRS.GROUP_ID = JRGT.GROUP_ID
AND    JRGU.GROUP_ID = JRGT.GROUP_ID
AND    JRGM.GROUP_ID = JRGT.GROUP_ID
AND    JRGM.RESOURCE_ID = JRRE.RESOURCE_ID
AND    JRRE.USER_ID = DECODE(CSRS.RESP_FLAG,'1',JRRE.USER_ID, FND_PROFILE.VALUE('USER_ID'))
AND    JRGM.DELETE_FLAG = 'N'
AND    JRGU.USAGE = 'SUPPORT'
AND    JRGT.END_DATE_ACTIVE IS NULL;


