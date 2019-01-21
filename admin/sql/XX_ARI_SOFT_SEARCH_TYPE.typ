SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- +=====================================================================+
-- | RICE ID     :  E2052 R1.2 CR619                                     |
-- | Name        :  Consolidated Bills and Soft Headers                  |
-- | Description :                                                       |
-- | Name        :  XX_ARI_SOFT_SEARCH_TYPE.typ                          |
-- | Description :   Creates XX_ARI_SOFT_SEARCH_TYPE                     |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       30-NOV-2009   Bushrod Thomas       Created Base version    |
-- +=====================================================================+

CREATE OR REPLACE TYPE XX_ARI_SOFT_SEARCH_TYPE AS OBJECT
(
   lookup_code VARCHAR2(30)
  ,meaning     VARCHAR2(150)
);

/
SHOW ERROR