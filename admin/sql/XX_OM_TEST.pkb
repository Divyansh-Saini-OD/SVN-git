SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_TEST
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                                                                   |
-- +===================================================================+
-- | Name  :                                                           |
-- | Description :                                                     |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======  ===========  =============    ============================|
-- |1.0      09-Jan-2009  Matthew Craig    Initial draft version       |
-- |                                                                   |
-- +===================================================================+
-- $Author$ : $Rev$ : $Date$
AS


PROCEDURE TEST 
IS


BEGIN

dbms_output.put_line('Test');

END TEST;


END XX_OM_TEST;
/
SHOW ERRORS PACKAGE BODY XX_OM_TEST;
EXIT;

