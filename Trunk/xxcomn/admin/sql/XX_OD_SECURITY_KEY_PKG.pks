SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package XX_OD_SECURITY_KEY_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL 

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_OD_SECURITY_KEY_PKG AUTHID DEFINER
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
--                                       INSERT_KEY for Defect ID:7603  |
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
      p_module         IN VARCHAR2,
      p_key_label      IN VARCHAR2,
      p_algorithm      IN VARCHAR2 DEFAULT '3DES',
      p_encrypted_val  IN VARCHAR2 DEFAULT NULL,
      p_format				 IN VARCHAR2 DEFAULT 'BASE64'      
      );

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
      );
      
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
      );

-- +==========================================================================+
-- | Name : GET_KEYS_BASE64                                                   |
-- | This procedure fetches key values when the module or the key label       |
-- | is passed as an input. The key value is encoded Base64                   |
-- | Input Parameters:  P_MODULE, P_KEY_LABEL                                 |
-- | Output Parameters: X_KEY_VALUE                                           |
-- +==========================================================================+

   PROCEDURE GET_KEYS_BASE64(
      p_module         IN VARCHAR2,
      p_key_label      IN VARCHAR2,
      x_key_value      OUT VARCHAR2
      );

-- +==========================================================================+
-- | Name : INSERT_KEY                                                        |
-- | This procedure inserts new values in the table                           |
-- |XX_OD_SECURITY_KEYS when the appropriate                                  |
-- |input values are passed                                                   |
-- | Input Parameters:  P_MODULE, P_KEY_LABEL, P_KEY_LABEL, P_KEY_VALUE       |
-- | Output Parameters: X_ERROR_MESSAGE                                       |
-- +==========================================================================+

   PROCEDURE INSERT_KEY(
      p_module         IN  VARCHAR2,
      p_effective_date IN  DATE,
      p_key_label      IN VARCHAR2,
      p_key_value      IN RAW,
      x_error_message  OUT VARCHAR2
      );

END XX_OD_SECURITY_KEY_PKG;
/

SHOW ERROR