-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PO_SHORT_TEXT_TAB.sql                                             |
-- | Description      : SQL Script to create a new TABLE TYPE object for Short Text          |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    | 
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   23-APR-2007       Sarah Justina    Initial draft version                      |              
-- |1.0        02-MAY-2007       Sarah Justina    Baseline                                   |
-- +=========================================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

WHENEVER SQLERROR CONTINUE
-- ************************************************
-- Creating TABLE TYPE XX_PO_SHORT_TEXT_TAB
-- ************************************************

WHENEVER SQLERROR CONTINUE
SET TERM ON
PROMPT
PROMPT Creating TYPE XX_PO_SHORT_TEXT_TAB
PROMPT
SET TERM OFF

create type xx_po_short_text_tab as table of xx_po_short_text_rec;
/
EXIT;

-- ************************************
-- *          END OF SCRIPT           *
-- ************************************