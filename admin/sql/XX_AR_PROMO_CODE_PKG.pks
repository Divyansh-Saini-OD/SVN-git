SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_AR_PROMO_CODE_PKG

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Promo Codes                                         |
-- | RICE ID     : E0997                                               |
-- | Description : This Extenstion will derive the Pormotional Codes   |
-- |               for credit cards on the basis of promotion criteria.|
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======  ==========   ==================    =======================|
-- |1.0       01-MAR-2007  Raji Natarajan,      Initial version        |
-- |                       Wipro Technologies                          |
-- +===================================================================+

AS

-- +====================================================================+
-- | Name : XX_AR_GETPROMO_PROC                                         |
-- | Description : This Procedure is to assign the promotion code to    |
-- |               the credit cards with the help of the promotion      |
-- |               criterias of the card selected.                      |
-- |                                                                    |
-- | Parameters :  p_receipt_id,x_promo_code                            |
-- |                                                                    |
-- +====================================================================+

    PROCEDURE XX_AR_GETPROMO_PROC(
                                  p_receipt_id               IN NUMBER
                                  ,x_promo_code              OUT NUMBER
                                 );

END XX_AR_PROMO_CODE_PKG;
/


SHOW ERROR
