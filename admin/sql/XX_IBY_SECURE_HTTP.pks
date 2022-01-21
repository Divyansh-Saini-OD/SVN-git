SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package XX_IBY_SECURE_HTTP

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_IBY_SECURE_HTTP
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
-- |1.0      04-FEB-2007  Gowri Shankar         Initial version        |
-- |                                                                   |
-- +===================================================================+

-- +===================================================================+
-- | Name : TRANSMIT                                                   |
-- | Description : To tranmit the file thru Secure HTTP                |
-- | Parameters :  p_file_path, p_file_name                            |
-- | Returns    :  x_status_code, x_reason                             |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE TRANSMIT    (
                             p_file_path             IN  VARCHAR2
                            ,p_file_name             IN  VARCHAR2
                            ,x_status_code           OUT VARCHAR2
                            ,x_reason                OUT VARCHAR2
                           );

END XX_IBY_SECURE_HTTP;
/
SHOW ERR