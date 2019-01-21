SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name             : XXTPS_OVRL_CURR_SITE_ASSIGN_V                      |
-- | Description      : Current Party Site Assignments for Overlay         |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version   Date         Author             Remarks                      |
-- |=======   ===========  =================  =============================|
-- |DRAFT 1A  13-Apr-2011  Kishore Jena       Initial draft version        |
-- |                                                                       |
-- +=======================================================================+

-- ---------------------------------------------------------------------
--      Create Custom View XXTPS_OVRL_CURR_SITE_ASSIGN_V              --
-- ---------------------------------------------------------------------


  CREATE OR REPLACE FORCE VIEW APPS.XXTPS_OVRL_CURR_SITE_ASSIGN_V AS
  SELECT X.PARTY_SITE_ID,  
         X.OVRL_RESOURCE_ID,
         X.OVRL_ROLE_ID,
         X.OVRL_GROUP_ID,
         MIN(X.START_DATE_ACTIVE) START_DATE_ACTIVE,
         MAX(X.END_DATE_ACTIVE)   END_DATE_ACTIVE,
         COUNT(1) TOTAL_OVRL_ASGNMNTS,
         COUNT(DISTINCT SOURCE_OVRL_RELATIONSHIP_ID) TOTAL_OVRL_RELTN_COUNT
  FROM 
   (
    SELECT  XTNT.ENTITY_ID PARTY_SITE_ID,
            XORR.OVRL_RESOURCE_ID,
            XORR.OVRL_ROLE_ID,
            XORR.OVRL_GROUP_ID,
            XORR.START_DATE_ACTIVE,
            XORR.END_DATE_ACTIVE,
            XORR.SOURCE_OVRL_RELATIONSHIP_ID,
            XORR.LAST_PROCESSED_DATE
    FROM    XXTPS.XXTPS_OVRL_RM_RULES XORR,
            APPS.XX_TM_NAM_TERR_CURR_ASSIGN_V XTNT  
    WHERE   XTNT.RESOURCE_ID      =  XORR.RESOURCE_ID
      AND   XTNT.RESOURCE_ROLE_ID =  XORR.ROLE_ID
      AND   XTNT.GROUP_ID         =  XORR.GROUP_ID 
      AND   XTNT.ENTITY_TYPE      =  'PARTY_SITE'
      AND   SYSDATE BETWEEN XORR.START_DATE_ACTIVE AND NVL(XORR.END_DATE_ACTIVE,  SYSDATE+1)
      AND   NVL(XORR.DELETE_FLAG, 'N')  =  'N'
    UNION
    SELECT  XOEA.ENTITY_ID PARTY_SITE_ID,
            XOEA.OVRL_RESOURCE_ID,
            XOEA.OVRL_ROLE_ID,
            XOEA.OVRL_GROUP_ID,
            XOEA.START_DATE_ACTIVE,
            XOEA.END_DATE_ACTIVE,
            XOEA.SOURCE_OVRL_RELATIONSHIP_ID,
            XOEA.LAST_PROCESSED_DATE
    FROM    XXTPS.XXTPS_OVRL_ENTITY_ASGNMNTS XOEA
    WHERE   XOEA.ENTITY_TYPE  =  'PARTY_SITE'
      AND   SYSDATE BETWEEN XOEA.START_DATE_ACTIVE AND NVL(XOEA.END_DATE_ACTIVE,  SYSDATE+1)
      AND   NVL(XOEA.DELETE_FLAG, 'N')  =  'N'
   ) X
   GROUP BY X.PARTY_SITE_ID,  
            X.OVRL_RESOURCE_ID,
            X.OVRL_ROLE_ID,
            X.OVRL_GROUP_ID;
   
SHOW ERRORS;