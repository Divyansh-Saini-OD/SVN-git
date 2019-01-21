SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name             : XX_TM_TERR_LOOKUP_STATE_V                          |
-- | Description      : Information state codes based on the country (US/CA)|
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version   Date         Author             Remarks                      |
-- |=======   ===========  =================  =============================|
-- |DRAFT 1A  05-Aug-2009  Nabarun            Initial draft version        |
-- |                                                                       |
-- +=======================================================================+

-- ---------------------------------------------------------------------
--      Create Custom View XX_TM_TERR_LOOKUP_STATE_V               --
-- ---------------------------------------------------------------------


CREATE OR REPLACE FORCE VIEW APPS.XX_TM_TERR_LOOKUP_STATE_V
(STATE_CODE,
 STATE_DESCRIPTION
) AS 
SELECT lookup_code, 
       meaning  
FROM   apps.fnd_common_lookups  
WHERE  lookup_type IN ('CA_PROVINCE','US_STATE')
ORDER BY 1
/
SHOW ERRORS;

EXIT;