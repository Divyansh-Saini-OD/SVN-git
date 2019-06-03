CREATE OR REPLACE FUNCTION APPS.xx_pos_oid_decrypt(
                  encrypted_password CHAR,
                      encryption_key CHAR)
                              RETURN CHAR AUTHID CURRENT_USER IS
/*======================================================================
-- +===================================================================+
-- |                  Office Depot - iSupplier-Project                 |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name       :  XX_POS_OID_DECRYPT                                  |
-- | Description:  This function is Created for the PBCGS iSupplier    |
-- |               registration worflow process to decrypt the staging |
-- |               table password.                                     |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      07-Mar-2008  Ian Bassaragh    Created This Function       |
-- |                                                                   |
-- +===================================================================+
+======================================================================*/

 decrypted_string  CHAR(64) := NULL;       -- Length needs to be multiple of eigth
 iv_string         CHAR(64) := NULL;       -- Length needs to be multiple of eigth
 which             PLS_INTEGER  := 0;      -- If = 0, (default), then TwoKeyMode is used.
                                           -- If = 1, then ThreeKeyMode is used



BEGIN
-- Decrypt data
  decrypted_string := DBMS_OBFUSCATION_TOOLKIT.DES3Decrypt(input_string => encrypted_password
                                                           ,key_string  => encryption_key
                                                           ,which       => which
                                                           ,iv_string   => iv_string
                                                           );


   RETURN substr(decrypted_string,1,10);
END xx_pos_oid_decrypt;
/
