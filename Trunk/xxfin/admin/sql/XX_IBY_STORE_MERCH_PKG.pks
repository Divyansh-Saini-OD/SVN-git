SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package XX_IBY_STORE_MERCH_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_IBY_STORE_MERCH_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Loading the Store, Merchant Numbers                 |
-- | RICE ID     : I2059_MerchantnumbersforODAMEX_CPCCards             |
-- | Description : To load the Store and Merchant numbers from the     |
-- |               Mainframe system into the translation table         |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======  ==========   ==================    =======================|
-- |1.0      30-AUG-2007  Gowri Shankar         Initial version        |
-- |                                                                   |
-- +===================================================================+

-- +===================================================================+
-- | Name : LOAD                                                       |
-- | Description : To display UTL_FILE log messages                    |
-- | Parameters :  p_debug_file, p_debug_msg                           |
-- +===================================================================+

    PROCEDURE LOAD        (
                             x_error_buf             OUT VARCHAR2
                            ,x_ret_code              OUT NUMBER
                           );

    gc_concurrent_program_name fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;

END XX_IBY_STORE_MERCH_PKG;
/
SHOW ERR