SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package XX_IBY_SEC_HTTP_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_IBY_SEC_HTTP_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Transmitting the settlement file thru Secure HTTP   |
-- | RICE ID     :                                                     |
-- | Description : Transmitting the generated settlement file          |
-- |                    thru Secure HTTP to AJB                        |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======  ===========  ==================    =======================|
-- |1.0      13-FEB-2007  Gowri Shankar         Initial version        |
-- |                                                                   |
-- +===================================================================+

-- +===================================================================+
-- | Name : TRANSFER                                                   |
-- | Description : To tranmit the file thru Secure HTTP                |
-- | Parameters :  p_file_path, p_file_name                            |
-- | Returns    :  x_error_buf, x_ret_code                             |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE TRANSFER     (
                             x_error_buf             OUT VARCHAR2
                            ,x_ret_code              OUT NUMBER
                            ,p_file_path             IN  VARCHAR2
                            ,p_file_name             IN  VARCHAR2
                            );

END XX_IBY_SEC_HTTP_PKG;
/
SHOW ERR