SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +======================================================================================+
-- |                  Office Depot - Project Simplify                                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
-- +======================================================================================|
-- | Name       : XX_HZ_CONTACT_POINTS_BIR1                                               |
-- | Description: This trigger shall be fired for each row being inserted or updated      |
-- |              on HZ_CONTACT_POINTS table.  This shall call the custom package to      | 
-- |              validate the email id and terminate if there is an error.               |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version   Date         Author           Remarks                                       |
-- |=======   ===========  =============    ==============================================|
-- |DRAFT 1A  25-APR-2007  Prem Kumar B     Initial draft version                         |
-- |1.0       21-Jul-2007  Rajeev Kamath    Move drop trigger to new file                 |
-- +======================================================================================+


PROMPT
PROMPT Dropping Existing Custom Trigger...
PROMPT

WHENEVER SQLERROR CONTINUE;

SET TERM OFF

PROMPT
PROMPT Drop Trigger XX_HZ_CONTACT_POINTS_BIR1
PROMPT

DROP Trigger XX_HZ_CONTACT_POINTS_BIR1;


SHOW ERRORS
EXIT;

