SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package XX_OD_SECURITY_KEY_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL 

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_OD_SECURITY_KEY_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- +=====================================================================+
-- | This package processes encryption and decryption procedures.        |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       07/27/2007    Prakash Sankaran      Initial version        |
-- |1.1       11/26/2007    Cecilia Macean        Added GET_KEYS_BASE64  |
-- |1.2       06/02/2008    Ram                   Added procedure        |
--                                    INSERT_KEY for Defect ID:7603     |
-- +=====================================================================+

-- +==========================================================================+
-- | Name : DECRYPT                                                           |
-- | This procedure runs decryption routines based on DES, AES or 3DES        |
-- | algorithms.                                                              |
-- | Input Parameters:  P_MODULE, P_KEY_LABEL, P_ALGORITHM, P_ENCRYPTED_VAL,  |
-- |                    P_FORMAT                                              |
-- | Output Parameters: X_DECRYPTED_VAL, X_ERROR_MESSAGE                      |
-- +==========================================================================+

   PROCEDURE DECRYPT(
      x_decrypted_val  OUT VARCHAR2,
      x_error_message  OUT VARCHAR2,
      p_module         IN  VARCHAR2,
      p_key_label      IN  VARCHAR2,
      p_algorithm      IN  VARCHAR2 DEFAULT '3DES',
      p_encrypted_val  IN  VARCHAR2 DEFAULT NULL,
      p_format         IN  VARCHAR2 DEFAULT 'BASE64'
      )
   IS

      lb_continue 			BOOLEAN := TRUE;
      lr_key_value 			RAW(1000);
      lr_encrypted_val 	RAW(1000);
      lr_decrypted_val 	RAW(1000);
      ln_mod						NUMBER;

   BEGIN

------------------------------------------------------------------------------------------
-- Verify if either the module (application) name or key label is passed
------------------------------------------------------------------------------------------

      IF TRIM(p_module) IS NULL AND TRIM(p_key_label) IS NULL THEN
         x_decrypted_val := ' ';
         x_error_message := 'ERROR in XX_OD_SECURITY_KEY_PKG.DECRYPT: Either module name or key label is required for this decryption procedure';
         DBMS_OUTPUT.PUT_LINE(X_ERROR_MESSAGE);
         lb_continue := FALSE;
      END IF;

------------------------------------------------------------------------------------------
-- Check for the algorithm
------------------------------------------------------------------------------------------

      IF p_algorithm <> '3DES' AND p_algorithm <> 'AES' THEN
         x_decrypted_val := ' ';
         x_error_message := 'ERROR in XX_OD_SECURITY_KEY_PKG.DECRYPT: Algorithm must either be 3DES or AES';
         DBMS_OUTPUT.PUT_LINE(x_error_message);
         lb_continue := FALSE;
      ELSE
         IF p_algorithm = '3DES' THEN
            ln_mod := DBMS_CRYPTO.ENCRYPT_3DES + DBMS_CRYPTO.CHAIN_CBC + DBMS_CRYPTO.PAD_ZERO;
         ELSE
            ln_mod := DBMS_CRYPTO.ENCRYPT_AES + DBMS_CRYPTO.CHAIN_CBC + DBMS_CRYPTO.PAD_ZERO;
         END IF;
      END IF;

------------------------------------------------------------------------------------------
-- Using EBCDIC for the mainframe and the value is passed in HEX representation
-- For Linux and Windows system, pass regular ASCII representation
------------------------------------------------------------------------------------------

      IF TRIM(p_format) IS NOT NULL THEN
         IF p_format <> 'ASCII' AND p_format <> 'EBCDIC' AND p_format <> 'BASE64' THEN
            x_decrypted_val := ' ';
            x_error_message := 'ERROR in XX_OD_SECURITY_KEY_PKG.DECRYPT: Encryption format can only be of ASCII, EBCDIC or BASE64 types';
            DBMS_OUTPUT.PUT_LINE(x_error_message);
            lb_continue := FALSE;
         END IF;
      END IF;

      IF lb_continue THEN

------------------------------------------------------------------------------------------
-- This procedure will get the keys so the calling application need not know the keys
------------------------------------------------------------------------------------------
         GET_KEYS(RTRIM(p_module),RTRIM(p_key_label),lr_key_value);

         IF lr_key_value IS NULL THEN
            x_error_message := 'ERROR in XX_OD_SECURITY_KEY_PKG.DECRYPT: Key value for the key label ' || p_key_label || ' or module name ' || p_module || ' not found ';
            DBMS_OUTPUT.PUT_LINE(x_error_message);
            lb_continue := FALSE;
         END IF;
      END IF;

      IF lb_continue THEN
--         DBMS_OUTPUT.PUT_LINE(p_encrypted_val);

------------------------------------------------------------------------------------------
-- For EBCDIC, the encrypted value has to be in a HEX(RAW) format.
-- For ASCII (Binary), the encrypted value is converted to RAW before decryption.
-- For BASE64, the encrypted value is decoded and converted to RAW before decryption.
------------------------------------------------------------------------------------------
         IF p_format = 'EBCDIC' THEN
            lr_encrypted_val := p_encrypted_val;      -- *** Copy to a Raw variable
         ELSE
            IF p_format = 'ASCII' THEN
               lr_encrypted_val := UTL_RAW.CAST_TO_RAW(p_encrypted_val);
            ELSE
               lr_encrypted_val := UTL_ENCODE.BASE64_DECODE(UTL_RAW.CAST_TO_RAW(p_encrypted_val));
            END IF;
         END IF;

--         DBMS_OUTPUT.PUT_LINE(lr_encrypted_val);
--         DBMS_OUTPUT.PUT_LINE(p_format);
         lr_decrypted_val := DBMS_CRYPTO.DECRYPT(lr_encrypted_val, ln_mod, lr_key_value);

------------------------------------------------------------------------------------------
-- Use the appropriate character set to convert the RAW decrypted value to ASCII
------------------------------------------------------------------------------------------
         IF TRIM(p_format) IS NOT NULL THEN
         		IF p_format = 'EBCDIC' THEN
               x_decrypted_val := TRIM(UTL_I18N.RAW_TO_CHAR(lr_decrypted_val, 'WE8EBCDIC500'));
            ELSE
               IF p_format = 'ASCII' THEN
                  x_decrypted_val := TRIM(UTL_RAW.CAST_TO_VARCHAR2(lr_decrypted_val));
               ELSE
                  x_decrypted_val := TRIM(UTL_RAW.CAST_TO_VARCHAR2(lr_decrypted_val));
               END IF;
            END IF;
         ELSE
            x_decrypted_val := TRIM(UTL_RAW.CAST_TO_VARCHAR2(lr_decrypted_val));
         END IF;
--         DBMS_OUTPUT.PUT_LINE(x_decrypted_val);
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         x_error_message := 'ERROR in XX_OD_SECURITY_KEY_PKG.DECRYPT:'||SQLERRM; -- Added for Defect ID 7612
         DBMS_OUTPUT.PUT_LINE(x_error_message);

   END DECRYPT;





-- +==========================================================================+
-- | Name : ENCRYPT                                                           |
-- | This procedure runs encryption routines based on DES, AES or 3DES        |
-- | algorithms.                                                              |
-- | Input Parameters:  P_MODULE, P_KEY_LABEL, P_ALGORITHM, P_DECRYPTED_VAL   |
-- |                    P_FORMAT                                              |
-- | Output Parameters: X_ENCRYPTED_VAL, X_ERROR_MESSAGE                      |
-- +==========================================================================+

   PROCEDURE ENCRYPT(
      x_encrypted_val  OUT VARCHAR2,
      x_error_message  OUT VARCHAR2,
      p_module         IN VARCHAR2,
      p_key_label      IN VARCHAR2,
      p_algorithm      IN VARCHAR2 DEFAULT '3DES',
      p_decrypted_val  IN VARCHAR2 DEFAULT NULL,
      p_format         IN VARCHAR2 DEFAULT 'BASE64'
      )
   IS

      lb_continue     	BOOLEAN := TRUE;
      lr_key_value 			RAW(1000);
      ln_mod						NUMBER;
      lr_encrypted_val 	RAW(1000);
      lr_decrypted_val  RAW(1000);
   BEGIN

------------------------------------------------------------------------------------------
-- Verify if either the module (application) name or key label is passed
------------------------------------------------------------------------------------------

      IF TRIM(p_module) IS NULL AND TRIM(p_key_label) IS NULL THEN
         x_encrypted_val := NULL;
         x_error_message := 'ERROR in XX_OD_SECURITY_KEY_PKG.ENCRYPT: Either module name or key label is required for this encryption procedure';
         DBMS_OUTPUT.PUT_LINE(x_error_message);
         lb_continue := FALSE;
      END IF;

------------------------------------------------------------------------------------------
-- Check for the algorithm
------------------------------------------------------------------------------------------

      IF p_algorithm <> '3DES' AND p_algorithm <> 'AES' THEN
         x_encrypted_val := NULL;
         x_error_message := 'ERROR in XX_OD_SECURITY_KEY_PKG.DECRYPT: Algorithm must either be 3DES or AES';
         DBMS_OUTPUT.PUT_LINE(x_error_message);
         lb_continue := FALSE;
      ELSE
         IF p_algorithm = '3DES' THEN
            ln_mod := DBMS_CRYPTO.ENCRYPT_3DES + DBMS_CRYPTO.CHAIN_CBC + DBMS_CRYPTO.PAD_ZERO;
         ELSE
            ln_mod := DBMS_CRYPTO.ENCRYPT_AES + DBMS_CRYPTO.CHAIN_CBC + DBMS_CRYPTO.PAD_ZERO;
         END IF;
      END IF;

      IF TRIM(p_format) IS NOT NULL THEN
         IF p_format <> 'ASCII' AND p_format <> 'EBCDIC' AND p_format <> 'BASE64' THEN
            x_encrypted_val := ' ';
            x_error_message := 'ERROR in XX_OD_SECURITY_KEY_PKG.ENCRYPT: Decryption format can only be of ASCII, EBCDIC or BASE64 types';
            DBMS_OUTPUT.PUT_LINE(x_error_message);
            lb_continue := FALSE;
         END IF;
      END IF;

      IF lb_continue THEN

------------------------------------------------------------------------------------------
-- This procedure will get the keys so the calling application need not know the keys
------------------------------------------------------------------------------------------
         GET_KEYS(RTRIM(p_module),RTRIM(p_key_label),lr_key_value);

         IF lr_key_value IS NULL THEN
            x_encrypted_val := NULL;
            x_error_message := 'ERROR in XX_OD_SECURITY_KEY_PKG.ENCRYPT: Key value for the key label ' || p_key_label || ' or module name ' || p_module || ' not found ';
            DBMS_OUTPUT.PUT_LINE(x_error_message);
            lb_continue := FALSE;
         END IF;
      END IF;

------------------------------------------------------------------------------------------
-- Convert the encrypted value to an ascii string before passing it back to the caller
------------------------------------------------------------------------------------------
      IF lb_continue THEN
         lr_decrypted_val := UTL_RAW.CAST_TO_RAW(p_decrypted_val);
         lr_encrypted_val := DBMS_CRYPTO.ENCRYPT(lr_decrypted_val, ln_mod, lr_key_value);

         IF p_format = 'BASE64' THEN
            x_encrypted_val := UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_ENCODE(lr_encrypted_val));
         ELSE
            x_encrypted_val := UTL_RAW.CAST_TO_VARCHAR2(lr_encrypted_val);
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         x_error_message := 'ERROR in XX_OD_SECURITY_KEY_PKG.ENCRYPT:'||SQLERRM; --Added for Defect ID 7612
         DBMS_OUTPUT.PUT_LINE(x_error_message);

   END ENCRYPT;



-- +==========================================================================+
-- | Name : GET_KEYS                                                          |
-- | This procedure fetches key values when the module or the key label       |
-- | is passed as an input.                                                   |
-- | Input Parameters:  P_MODULE, P_KEY_LABEL                                 |
-- | Output Parameters: X_KEY_VALUE                                           |
-- +==========================================================================+

   PROCEDURE GET_KEYS(
      p_module         IN VARCHAR2,
      p_key_label      IN VARCHAR2,
      x_key_value      OUT RAW
      )
   IS
      lr_key_value 		RAW(1000);
   BEGIN
   /*
      SELECT sec.key_value INTO lr_key_value
      FROM xx_od_security_keys SEC
      WHERE ((p_key_label IS NOT NULL AND key_label = p_key_label) OR
             (p_key_label IS NULL AND module = p_module)); 
	     */
-- added for defect 7612
      SELECT sec.key_value INTO lr_key_value 
      FROM xx_od_security_keys SEC
      WHERE ((p_key_label IS NOT NULL AND key_label = p_key_label) OR
             (p_key_label IS NULL AND module = p_module))
      AND effective_date =
          ( SELECT max(effective_date)
             FROM xx_od_security_keys
             WHERE module = sec.module
             AND effective_date <= sysdate );


      x_key_value := lr_key_value;

   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      x_key_value := NULL;

   END GET_KEYS;


-- +==========================================================================+
-- | Name : GET_KEYS_BASE64                                                   |
-- | This procedure fetches key values when the module or the key label       |
-- | is passed as an input. It returns the key value encoded base64           |
-- | Input Parameters:  P_MODULE, P_KEY_LABEL                                 |
-- | Output Parameters: X_KEY_VALUE                                           |
-- +==========================================================================+

   PROCEDURE GET_KEYS_BASE64(
      p_module         IN  VARCHAR2,
      p_key_label      IN  VARCHAR2,
      x_key_value      OUT VARCHAR2
      )
   IS
      lr_key_value 		RAW(1000);
   BEGIN

      GET_KEYS(p_module,p_key_label,lr_key_value);
      IF lr_key_value IS NOT NULL THEN
        x_key_value := UTL_ENCODE.base64_encode( lr_key_value );
      ELSE
        x_key_value := NULL;
      END IF;

   END GET_KEYS_BASE64;

-- Added for defect ID 7603
-- +==========================================================================+
-- | Name : INSERT_KEY                                                        |
-- | This procedure inserts new values in the table XX_OD_SECURITY_KEYS       |
-- |when the appropriate input values are passed                              |
-- | Input Parameters:  P_MODULE, P_KEY_LABEL, P_KEY_LABEL, P_KEY_VALUE       |
-- | Output Parameters: X_ERROR_MESSAGE                                       |
-- +==========================================================================+

   PROCEDURE INSERT_KEY (
      p_module         IN VARCHAR2,
      p_effective_date IN DATE,
      p_key_label      IN VARCHAR2,
      p_key_value      IN RAW,
      x_error_message  OUT VARCHAR2
      )
   IS
        lc_count             NUMBER;
        EX_MANDATORY_FIELD   EXCEPTION ;
        EX_EFFECTIVE_DATE    EXCEPTION ;
        EX_DUPLICATE_VALUE   EXCEPTION ;
       
   BEGIN
  
      IF (TRIM(p_module) IS NULL
         OR TRIM(p_effective_date) IS NULL
         OR TRIM(p_key_label) IS NULL
         OR TRIM(p_key_value) IS NULL) THEN
         x_error_message := 'ERROR in XX_OD_SECURITY_KEY_PKG.UPDATE_SECURITY_TABLE: All the parameters are needed for the procedure';
--         DBMS_OUTPUT.PUT_LINE(x_error_message);       
         RAISE EX_MANDATORY_FIELD ; 
      END IF;

      IF p_effective_date< trunc(SYSDATE) THEN
         x_error_message:= 'ERROR in XX_OD_SECURITY_KEY_PKG.UPDATE_SECURITY_TABLE: Effective date cannot be less than the current date';
--         DBMS_OUTPUT.PUT_LINE(x_error_message);         
         RAISE EX_EFFECTIVE_DATE ;
      END IF;

      SELECT COUNT(1) 
      INTO   lc_count
      FROM   xx_od_security_keys
      WHERE  module =p_module
      AND    effective_date =p_effective_date
      AND    key_label=p_key_label
      AND    key_value=p_key_value;

      IF lc_count>0 THEN
              x_error_message:= 'ERROR in XX_OD_SECURITY_KEY_PKG.UPDATE_SECURITY_TABLE: Cannot insert duplicate row into the table';
              RAISE EX_DUPLICATE_VALUE;
      ELSE
              INSERT INTO
                  xx_od_security_keys
                  (module
                  ,effective_date
                  ,key_label
                  ,key_value)
                VALUES
                  (p_module
                  ,p_effective_date
                  ,p_key_label
                  ,p_key_value);
              COMMIT;
      END IF;

  EXCEPTION
   WHEN  EX_MANDATORY_FIELD THEN
      DBMS_OUTPUT.PUT_LINE (x_error_message); 
   WHEN  EX_EFFECTIVE_DATE THEN
      DBMS_OUTPUT.PUT_LINE (x_error_message);
   WHEN  EX_DUPLICATE_VALUE THEN
      DBMS_OUTPUT.PUT_LINE (x_error_message); 

   WHEN OTHERS THEN
       x_error_message := 'Unknown ERROR in call to INSERT_KEY procedure :'||SQLERRM;
       DBMS_OUTPUT.PUT_LINE(x_error_message); 

   END INSERT_KEY  ;

END XX_OD_SECURITY_KEY_PKG;
/

SHOW ERROR