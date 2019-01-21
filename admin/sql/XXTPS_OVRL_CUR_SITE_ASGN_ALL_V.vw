SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name             : XXTPS_OVRL_CUR_SITE_ASGN_ALL_V                     |
-- | Description      : Current Party Site Assignments for Overlay(ALL)    |
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
--      Create Custom View XXTPS_OVRL_CUR_SITE_ASGN_ALL_V             --
-- ---------------------------------------------------------------------


  CREATE OR REPLACE FORCE VIEW APPS.XXTPS_OVRL_CUR_SITE_ASGN_ALL_V
   (PARTY_SITE_ID,
    OVRL_RESOURCE_ID,
    OVRL_ROLE_ID,
    OVRL_GROUP_ID,
    START_DATE_ACTIVE,
    END_DATE_ACTIVE,
    SOURCE_OVRL_RELATIONSHIP_ID,
    LAST_PROCESSED_DATE
   ) AS 
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
     AND   NVL(XOEA.DELETE_FLAG, 'N')  =  'N';
   
SHOW ERRORS;