SET SHOW         OFF 
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET TERM ON
PROMPT Creating Package Body XX_GL_ENABLED_CURENCY_PKG 
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE BODY XX_GL_ENABLED_CURENCY_PKG  
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
-- |               the  fnd_currencies table.                          |
-- | Returns :     Currencies                                             |
-- +===================================================================+

   FUNCTION GET_CURRENCY RETURN VARCHAR2
   AS

     lc_to_currency             VARCHAR2 (3)   := 'USD';
     lc_currency_words          VARCHAR2 (30)  := 'Curncy';
     lc_enabled_flag            VARCHAR2 (1)   := 'Y';
     lc_currency_code           VARCHAR2 (10)  := 'STAT';
     lc_output                  VARCHAR2(4000) := NULL;
    
     CURSOR c_enabled_currency
     IS
        SELECT   currency_code
                ,enabled_flag 
        FROM     fnd_currencies
        WHERE    enabled_flag   = lc_enabled_flag
        AND      currency_code NOT IN (lc_currency_code,lc_to_currency);

     BEGIN
        FOR lcu_enabled_currency_rec IN c_enabled_currency
        LOOP
                                                           
          lc_output := lc_output||lcu_enabled_currency_rec.currency_code|| lc_to_currency ||' '|| lc_currency_words||chr(13);
                                                           
        END LOOP;
          RETURN lc_output;

     EXCEPTION
     WHEN OTHERS     THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Exception raised in the Function for fetching the Enabled currency in FND_CURRENCIES');

     END GET_CURRENCY;

   END XX_GL_ENABLED_CURENCY_PKG;
/
SHOW ERROR