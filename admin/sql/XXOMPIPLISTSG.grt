-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        : XXOMPIPLISTSG.grt                                   |
-- | Rice ID     : I1267_PIPInterfacetoSAS                             |
-- | Description  :OD PIP Interface to SAS Grant Creation  Script      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 14-May-2007  Vidhya Valantina Initial draft version       |
-- |1.0      14-May-2007  Vidhya Valantina Baselined after testing     |
-- |1.1      13-Jun-2007  Vidhya Valantina Changed File Name as per the|
-- |                                       Naming Conventions          |
-- |                                                                   |
-- +===================================================================+

SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Providing Grant on Custom Tables to Apps......
PROMPT

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Providing Grant on the Table XX_OM_PIP_LISTS to Apps .....
PROMPT

GRANT ALL ON  XX_OM_PIP_LISTS TO APPS;

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
