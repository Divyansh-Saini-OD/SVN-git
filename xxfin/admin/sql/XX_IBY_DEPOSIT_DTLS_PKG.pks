SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Specification XX_IBY_DEPOSIT_DTLS_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE


CREATE OR REPLACE PACKAGE XX_IBY_DEPOSIT_DTLS_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :       Line Level 3 Detail for Deposits                     |
-- | RICE ID :     E1325                                               |
-- | Description : To get the sku level details from the AOPS system   |
-- |               for every AOPS order number stored in oracle        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========    =============       =======================|
-- |1.0       05-JUL-2007   Anusha Ramanujam    Initial version        |
-- |                                                                   |
-- +===================================================================+

    gc_concurrent_program_name   fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;

-- +===================================================================+
-- | Name : DETAIL                                                     |
-- | Description : It fetches order deposit details from AOPS system   |
-- |               and inserts the details into the new custom table   |
-- |               XX_IBY_DEPOSIT_AOPS_ORDER_DTLS for every AOPS order |
-- |               number in the XX_IBY_DEPOSIT_AOPS_ORDERS table.     |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE DETAIL(
                     x_error_buff        OUT VARCHAR2
                    ,x_ret_code          OUT NUMBER 
                     );


END XX_IBY_DEPOSIT_DTLS_PKG;
/
SHOW ERROR
