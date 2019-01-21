SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Specification XX_IBY_SETTLE_BKP_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_IBY_SETTLE_BKP_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Settlement and Payment Processing                   |
-- | RICE ID     : I0349   settlement                                  |
-- | Description : To take backup and reprocess the Settlement records |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======  ===========  ==================    =======================|
-- |1.0      29-MAY-2008  Gowri Shankar         Initial version        |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE PROCESS (
                       x_error_buf             OUT VARCHAR2
                      ,x_ret_code              OUT NUMBER
                      ,p_payment_batch         IN VARCHAR2
                       );
END XX_IBY_SETTLE_BKP_PKG;
/
SHOW ERR