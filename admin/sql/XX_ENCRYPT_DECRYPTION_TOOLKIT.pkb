create or replace
package body XX_ENCRYPT_DECRYPTION_TOOLKIT as
-- +===============================================================================+
-- |                     Office Depot                                              |
-- +===============================================================================+
-- | Name             : XX_ENCRYPT_DECRYPTION_TOOLKIT                              |
-- | Description      : This Package is used for enryption and decryption          |
-- |                                                                               |
-- |                                                                               |
-- |Type        Name         Description                                           |
-- |=========   =======      ===================================================   |
-- |FUNCTION    encrypt       This function encrypts the text and return the       |
-- |                          encrypted text                                       |
-- |FUNCTION    decrypt      This function decrypts the message                    |
-- |                          the confirmation number                              |
-- |PROCEDURE   padstring     This prcodeure converts the text length to           |
-- |                          multiple of 8                                        |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version      Date          Author             Remarks                          |
-- |=======   ==========   ===============      ===================================|
-- |DRAFT 1A  29-JUN-2012     Deepti S            Initial draft version            |
-- +===============================================================================+

  g_key     RAW(32767)  := UTL_RAW.cast_to_raw('dev01apps');
  g_pad_chr VARCHAR2(1) := '~';

 PROCEDURE padstring (p_text  IN OUT  VARCHAR2);


  -- --------------------------------------------------
  FUNCTION encrypt (p_text  IN  VARCHAR2) RETURN RAW IS
  -- --------------------------------------------------
    l_text       VARCHAR2(32767) := p_text;
    l_encrypted  RAW(32767);
  begin
   padstring(l_text);
    DBMS_OBFUSCATION_TOOLKIT.desencrypt(input          => UTL_RAW.cast_to_raw(l_text),
                                        key            => g_key,
                                        encrypted_data => l_encrypted);
    RETURN l_encrypted;
  END;
  -- --------------------------------------------------



  -- --------------------------------------------------
  FUNCTION decrypt (p_raw  IN  RAW) RETURN VARCHAR2 IS
  -- --------------------------------------------------
    l_decrypted  VARCHAR2(32767);
  BEGIN
    DBMS_OBFUSCATION_TOOLKIT.desdecrypt(input => p_raw,
                                        key   => g_key,
                                        decrypted_data => l_decrypted);
                                        
    RETURN RTrim(UTL_RAW.cast_to_varchar2(l_decrypted), g_pad_chr);
  END;
  -- --------------------------------------------------


  -- --------------------------------------------------
  PROCEDURE padstring (p_text  IN OUT  VARCHAR2) IS
  -- --------------------------------------------------
    l_units  NUMBER;
  BEGIN
    IF LENGTH(p_text) MOD 8 > 0 THEN
      l_units := TRUNC(LENGTH(p_text)/8) + 1;
      p_text  := RPAD(p_text, l_units * 8, g_pad_chr);
    END IF;
  END;
  -- --------------------------------------------------

END XX_ENCRYPT_DECRYPTION_TOOLKIT;
/