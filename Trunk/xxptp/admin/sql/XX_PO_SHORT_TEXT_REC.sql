-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PO_SHORT_TEXT_REC.sql                                             |
-- | Description      : SQL Script to create a new TYPE object for Short Text                |
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
-- Creating TYPE XX_PO_SHORT_TEXT_REC
-- ************************************************

WHENEVER SQLERROR CONTINUE
SET TERM ON
PROMPT
PROMPT Dropping TYPE XX_PO_SHORT_TEXT_TAB
PROMPT
SET TERM OFF

drop type xx_po_short_text_tab;
SET TERM ON
PROMPT
PROMPT Dropping TYPE XX_PO_SHORT_TEXT_REC
PROMPT
SET TERM OFF

drop type xx_po_short_text_rec;

SET TERM ON
PROMPT
PROMPT Creating TYPE XX_PO_SHORT_TEXT_REC
PROMPT
SET TERM OFF

create type xx_po_short_text_rec as object(short_text varchar2(2000));
/
SHOW ERRORS

EXIT;

-- ************************************
-- *          END OF SCRIPT           *
-- ************************************
