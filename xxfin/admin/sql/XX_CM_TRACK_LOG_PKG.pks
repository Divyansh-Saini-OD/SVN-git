SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_CM_TRACK_LOG_PKG
PROMPT Program exits IF the creation is not successful

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE XX_CM_TRACK_LOG_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_CM_TRACK_LOG_PKG                                          |
-- | RICE ID :  R0472                                                    |
-- | Description : This package is derives the card type based           |
-- |               on the provider code.                                 |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |DRAFT 1A  05-DEC-08     Ganesan JV           Initial Version         |
-- |DRAFT 1B  26-DEC-08     Manovinayak A        Initial Version
-- |DRAFT 1C  25-MAY-09     Usha Ramachandran    Updated as per defect 12461
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  get_card_type                                               |
-- |                                                                     |
-- | Parameters :p_processor_id,p_ajb_file_name,p_card_num               |
-- |             ,p_provider_type                                        |
-- | Description : This function will derive and return the card type if |
-- |               it is not present in the xx_ce_ajb996_ar_v            |
-- | Returns :  card type                                                |
-- +=====================================================================+
  FUNCTION get_card_type(p_processor_id  VARCHAR2
                        ,p_ajb_file_name VARCHAR2
                        ,p_provider_type VARCHAR2
                        ,p_card_number   VARCHAR2)
  RETURN VARCHAR2;
END;
/
SHO ERR;
