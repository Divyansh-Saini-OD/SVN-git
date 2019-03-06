SET VERIFY OFF;
  WHENEVER SQLERROR CONTINUE;
  WHENEVER OSERROR EXIT FAILURE ROLLBACK;
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
-- |Version 1.2  17-DEC-2009  Raj/Bala   Modified the View             |
-- /Version 1.3  05-JUN-2013  Arun Gannarapu  Modified as part of R12 retrofit /  
-- |Version 1.4  10-OCT-2016  Poonam Gupta Modified view for defect#39069|
-- +===================================================================+


 CREATE OR REPLACE FORCE VIEW "APPS"."XXOD_CRM_GROUP_NAME_V" ("GROUP_NAME", "GROUP_ID", "RESP_ID") AS 
  SELECT DISTINCT JRGT.GROUP_NAME,JRGT.GROUP_ID, CSRS.RESP_ID
FROM   JTF_RS_GROUPS_VL JRGT,
       JTF_RS_GROUP_USAGES JRGU,
       JTF_RS_GROUP_MEMBERS JRGM,
      JTF_RS_RESOURCE_EXTNS JRRE,
        (SELECT DISTINCT JTFR.RESOURCE_ID GROUP_ID, 
          INSTR(REPLACE(FNDR.RESPONSIBILITY_NAME, 'Agent','-'),'-')+1 RESP_FLAG,
          FNDR.RESPONSIBILITY_ID RESP_ID
              FROM APPS.JTF_TERR_QUAL_ALL JTFQ,
                    APPS.JTF_TERR_VALUES_ALL JTFV,
                    APPS.JTF_TERR_RSC_ALL JTFR,
                    APPS.CS_SR_TYPE_MAPPING CSTM,
                    APPS.FND_RESPONSIBILITY_TL FNDR
              WHERE FNDR.RESPONSIBILITY_ID = CSTM.RESPONSIBILITY_ID
              AND   CSTM.INCIDENT_TYPE_ID = JTFV.LOW_VALUE_CHAR_ID
              AND   JTFV.TERR_QUAL_ID = JTFQ.TERR_QUAL_ID
              AND JTFR.RESOURCE_TYPE = 'RS_GROUP'
              AND ( JTFR.END_DATE_ACTIVE IS NULL OR JTFR.END_DATE_ACTIVE >= SYSDATE)
              AND JTFR.TERR_ID IN (SELECT TERR_ID FROM APPS.JTF_TERR_ALL
                                    WHERE APPLICATION_SHORT_NAME IN ('CSS','JTF')
                                    AND ENABLED_FLAG = 'Y'
                                    START WITH TERR_ID = JTFQ.TERR_ID
                                    CONNECT BY PARENT_TERRITORY_ID = PRIOR TERR_ID )
             AND FNDR.RESPONSIBILITY_ID = FND_PROFILE.VALUE('RESP_ID')
             ) CSRS
WHERE  CSRS.GROUP_ID = JRGT.GROUP_ID
AND    JRGU.GROUP_ID = JRGT.GROUP_ID
AND    JRGM.GROUP_ID = JRGT.GROUP_ID
AND    JRGM.RESOURCE_ID = JRRE.RESOURCE_ID
AND    JRRE.USER_ID = DECODE(CSRS.RESP_FLAG,'1',JRRE.USER_ID, FND_PROFILE.VALUE('USER_ID'))
AND    JRGM.DELETE_FLAG = 'N'
AND    JRGU.USAGE = 'SUPPORT'
AND    ( JRGT.END_DATE_ACTIVE IS NULL OR JRGT.END_DATE_ACTIVE >= SYSDATE);

SHOW ERRORS;
/
