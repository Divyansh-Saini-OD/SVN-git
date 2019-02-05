-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :CREATE_XX_GI_VALIDATE_ITEM_T.typ                    |
-- | Rice ID      :E0341 Inventory Transfer                            |
-- | Description  :OD serial numbers type creation script.             |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ===========================|
-- | 1.0       06-Dec-2007 Arun Andavar      No previous version       |
-- +===================================================================+

SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Creating the Custom Types ......
PROMPT

CREATE TYPE XX_GI_VALIDATE_ITEM_T AS OBJECT
(
 item           VARCHAR2(200)
,transfer_qty   NUMBER
,serial_numbers XX_GI_SERIAL_NUMBERS_TAB_T    
,line_id        NUMBER  
);

/
WHENEVER SQLERROR EXIT 1


CREATE TYPE XX_GI_VALIDATE_ITEM_TAB_T AS TABLE OF XX_GI_VALIDATE_ITEM_T;
/

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;