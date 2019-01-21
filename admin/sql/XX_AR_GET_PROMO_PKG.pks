CREATE OR REPLACE
PACKAGE XX_AR_GET_PROMO_PKG AS

-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                       WIPRO Technologies                           |
-- +====================================================================+
-- | Name :  Promo Codes - E0997                                        |
-- | Description : This Extenstion will derive the Pormotional Codes    |
-- | for credit cards on the basis of promotion criteria                |
-- |                                                                    |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version   Date          Author              Remarks                 |
-- |=======   ==========   =============        ========================|
-- |1.0       01-MAR-2007  Raji Natarajan,      Initial version         |
-- |                       Wipro Technologies                           |
-- +====================================================================+
-- +====================================================================+
-- | Name : xx_ar_get_promo_pkg                                         |
-- | Description : This Procedure is to assign                          |
-- | the promotion code to the credit cards with the help of the        |
-- | promotion criterias of the card selected.                          |
-- |                                                                    |
-- | Parameters :  p_receipt_number                                     |
-- |                                                                    |
-- +====================================================================+

PROCEDURE XX_AR_GETPROMO_PROC( x_error_buff      OUT VARCHAR2
                             ,x_ret_code        OUT NUMBER,
                              p_receipt_number IN VARCHAR2);
END;
/

