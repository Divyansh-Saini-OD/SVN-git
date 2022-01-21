CREATE OR REPLACE
PACKAGE XX_IBY_SECURITY_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :        OD:Project Simpilfy                                 |
-- | Description : This Package is used to do decrypt credit card      |
--                 number.                                             |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Change Record:                                                    |
-- | ===============                                                   |
-- | Version   Date          Author              Remarks               |
-- | =======   ==========   =============        ======================|
-- |   1.0     19-JUL-07    Raj Patel            Initial version       |
-- |                                                                   |
-- +===================================================================+
-- +===================================================================+
-- | Name  : SET_DEBUG                                                 |
-- | Description: This Procedure is set enable or disable debuge flag. |
-- |                                                                   |
-- |                                                                   |
-- | Parameters : p_debug_flag                                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE SET_DEBUG(
   p_debug_flag IN BOOLEAN DEFAULT FALSE);
-- +===================================================================+
-- | Name  : DECRYPT_CREDIT_CARD                                       |
-- | Description: This function will do  decrypt the Credit card       |
-- |              nunmber.                                             |
-- |                                                                   |
-- |                                                                   |
-- | Parameters : p_cc_segment_ref                                     |
-- |                                                                   |
-- +===================================================================+
FUNCTION DECRYPT_CREDIT_CARD(
   p_cc_segment_ref IN  VARCHAR2)
   RETURN VARCHAR2;
END XX_IBY_SECURITY_PKG;
/
SHOW ERRORS