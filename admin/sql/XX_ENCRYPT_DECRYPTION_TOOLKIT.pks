create or replace
package XX_ENCRYPT_DECRYPTION_TOOLKIT as
-- +=============================================================================+
-- |                     Office Depot                                            |
-- +=============================================================================+
-- | Name             : XX_ENCRYPT_DECRYPTION_TOOLKIT                            |
-- | Description      : This Package 1.Encrypts the given text and returns the   |
-- |                   encrypted text  2. Decrypts the text and returns the      |
-- |                   decrypted message                                         |
-- |                                                                             |
-- |Change Record:                                                               |
-- |===============                                                              |
-- |Version    Date          Author            Remarks                           |
-- |=======    ==========    =============     ==================================|
-- |DRAFT 1A   29-JUN-2012   Deepti S          Initial draft version             |
-- +=============================================================================+

  FUNCTION encrypt (p_text  IN  VARCHAR2) RETURN RAW;
  
  FUNCTION decrypt (p_raw  IN  RAW) RETURN VARCHAR2;
  
end XX_ENCRYPT_DECRYPTION_TOOLKIT;
/