SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name             : XX_TM_NAM_TERR_CURR_ASSIGN_V                       |
-- | Description      : Named Account Territory Current Assignments        |
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
-- |1.0       05-Jun-2009  Nabarun Ghosh      Solution provided by Enliu,  | 
-- |                                          Included:                    |
-- |                                             Ordered hint and          |
-- |                                             Removed Third join        |
-- +=======================================================================+

-- ---------------------------------------------------------------------
--      Create Custom View XX_TM_NAM_TERR_CURR_ASSIGN_V               --
-- ---------------------------------------------------------------------


  CREATE OR REPLACE FORCE VIEW APPS.XX_TM_NAM_TERR_CURR_ASSIGN_V
   (NAMED_ACCT_TERR_ID,
    ENTITY_TYPE,
    ENTITY_ID,
    RESOURCE_ID,
    RESOURCE_ROLE_ID,
    GROUP_ID,
    FULL_ACCESS_FLAG
    ) AS 
  SELECT /*+ ORDERED */
    TERR.NAMED_ACCT_TERR_ID,
    TERR_ENT.ENTITY_TYPE,
    TERR_ENT.ENTITY_ID,
    TERR_RSC.RESOURCE_ID,
    TERR_RSC.RESOURCE_ROLE_ID,
    TERR_RSC.GROUP_ID,
    TERR_ENT.FULL_ACCESS_FLAG
FROM
    XX_TM_NAM_TERR_RSC_DTLS     TERR_RSC,
    XX_TM_NAM_TERR_DEFN         TERR,
    XX_TM_NAM_TERR_ENTITY_DTLS  TERR_ENT
WHERE
   TERR.NAMED_ACCT_TERR_ID     = TERR_RSC.NAMED_ACCT_TERR_ID AND
   TERR_ENT.NAMED_ACCT_TERR_ID = TERR.NAMED_ACCT_TERR_ID     AND
   SYSDATE BETWEEN NVL(TERR.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR.END_DATE_ACTIVE,SYSDATE+1) AND
   SYSDATE BETWEEN NVL(TERR_ENT.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_ENT.END_DATE_ACTIVE,SYSDATE+1) AND
   SYSDATE BETWEEN NVL(TERR_RSC.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_RSC.END_DATE_ACTIVE,SYSDATE+1) AND
   NVL(TERR.status,'A') = 'A'     AND
   NVL(TERR_ENT.status,'A') = 'A' AND
   NVL(TERR_RSC.status,'A') = 'A';
   
SHOW ERRORS;