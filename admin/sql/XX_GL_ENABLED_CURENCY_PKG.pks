SET SHOW         OFF 
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET TERM ON
PROMPT Creating Package XX_GL_ENABLED_CURENCY_PKG 
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE XX_GL_ENABLED_CURENCY_PKG  
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :        Enabled Curency Fetch                               |
-- | Rice ID:      I0105                                               |
-- | Description : To fetch the enables currencies from the            |
-- |               FND_CURRENCIES                                      |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |1.0       10-JULY-2007 Samitha U M          Initial version        |
-- |                                                                   |
-- +===================================================================+

-- +===================================================================+
-- | Name : XX_GL_ENABLED_CURENCY_PKG                                  |
-- | Description : The procedure fetches the enabled currencies from   |
-- |               the  FND_CURRENCIES table.                          |
-- | Returns :  Currencies                                             |
-- +===================================================================+
     FUNCTION  GET_CURRENCY RETURN VARCHAR2;

END XX_GL_ENABLED_CURENCY_PKG;
/
SHOW ERROR