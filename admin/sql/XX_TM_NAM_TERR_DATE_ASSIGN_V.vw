SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name             : XX_TM_NAM_TERR_DATE_ASSIGN_V                       |
-- | Description      : Named Account Territory Date Assignemnets          |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version   Date         Author             Remarks                      |
-- |=======   ===========  =================  =============================|
-- |DRAFT 1A  13-Sep-2007  Sreekanth          Initial draft version        |
-- |                                                                       |
-- +=======================================================================+

-- ---------------------------------------------------------------------
--      Create Custom View XX_TM_NAM_TERR_DATE_ASSIGN_V               --
-- ---------------------------------------------------------------------

CREATE OR REPLACE FORCE VIEW APPS.XX_TM_NAM_TERR_DATE_ASSIGN_V
 ( NAMED_ACCT_TERR_ID,
   ENTITY_TYPE, 
   ENTITY_ID, 
   RESOURCE_ID, 
   RESOURCE_ROLE_ID, 
   GROUP_ID, 
   FULL_ACCESS_FLAG,
   TERR_START_DATE,
   TERR_END_DATE, 
   TERR_RES_START_DATE, 
   TERR_RES_END_DATE, 
   TERR_ENT_START_DATE, 
   TERR_ENT_END_DATE) AS 
  SELECT
    TERR.NAMED_ACCT_TERR_ID,
    TERR_ENT.ENTITY_TYPE,
    TERR_ENT.ENTITY_ID,
    TERR_RSC.RESOURCE_ID,
    TERR_RSC. RESOURCE_ROLE_ID,
    TERR_RSC.GROUP_ID,
    TERR_ENT.FULL_ACCESS_FLAG,
    TERR.START_DATE_ACTIVE,
    TERR.END_DATE_ACTIVE,
    TERR_RSC.START_DATE_ACTIVE,
    TERR_RSC.END_DATE_ACTIVE,
    TERR_ENT.START_DATE_ACTIVE,
    TERR_ENT.END_DATE_ACTIVE
FROM
    XX_TM_NAM_TERR_DEFN         TERR,
    XX_TM_NAM_TERR_ENTITY_DTLS  TERR_ENT,
    XX_TM_NAM_TERR_RSC_DTLS     TERR_RSC
WHERE
   TERR.NAMED_ACCT_TERR_ID = TERR_ENT.NAMED_ACCT_TERR_ID AND
   TERR.NAMED_ACCT_TERR_ID = TERR_RSC.NAMED_ACCT_TERR_ID   AND
   TERR_ENT.ENTITY_TYPE = 'PARTY_SITE' AND
   nvl(TERR.END_DATE_ACTIVE,sysdate-1) > sysdate-90 AND
   nvl(TERR_ENT.END_DATE_ACTIVE,sysdate-1) > sysdate-90 AND
   nvl(TERR_RSC.END_DATE_ACTIVE,sysdate-1) > sysdate-90; 
 
SHOW ERRORS;