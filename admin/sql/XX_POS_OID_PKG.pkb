CREATE OR REPLACE PACKAGE BODY APPS.XX_POS_OID_PKG IS
/*======================================================================
-- +===================================================================+
-- |                  Office Depot - iSupplier-Project                 |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name       :  XX_POS_OID_PKG                                      |
-- | Description:  This package is Created for the PBCGS iSupplier     |
-- |               registration worflow process to create a staging    |
-- |               table from FND_USER to OID via XX_POS_OID_USER.     |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      12-Feb-2008  Ian Bassaragh    Created The Package         |
-- |                                                                   |
-- +===================================================================+
+======================================================================*/

/*---------------------------------------

    private constants used by this package

----------------------------------------*/
FND_MSG_APP CONSTANT VARCHAR2(3) := '';
-- a global error message holder
ERROR_MESSAGE FND_NEW_MESSAGES.MESSAGE_NAME%TYPE := NULL;
-- error message names

MSG_UNEXPECTED_ERROR CONSTANT FND_NEW_MESSAGES.MESSAGE_NAME%TYPE := 'POS_OID_UNEXPECTED_ERR';
MSG_FND_USER_MISSING CONSTANT FND_NEW_MESSAGES.MESSAGE_NAME%TYPE := 'POS_FND_USER_MISSING';
MSG_OID_STAGE_CREATION_FAIL CONSTANT FND_NEW_MESSAGES.MESSAGE_NAME%TYPE := 'POS_OID_STAGE_CREATION_FAIL';

-- global variable for logging
g_log_module_name VARCHAR2(30) := 'pos.plsql.XXPOSOIDWB';
g_log_proc_start VARCHAR2(30) := 'start';
g_log_proc_end VARCHAR2(30) := 'end';
g_log_reg_key_notfound VARCHAR2(30) := 'Registration key is NOT FOUND.';
g_log_reg_id_invalid VARCHAR2(30) := 'Registration ID is INVALID.';

/*----------------------------------------

  private FUNCTION CheckError

    Check whether the error message has been set.

  PARAMS:
     none

  RETURN:
     VARCHAR2 : the error message that has been set, or NULL if not yet set

----------------------------------------*/

FUNCTION CheckError RETURN VARCHAR2
IS
BEGIN
  RETURN ERROR_MESSAGE;
END CheckError;


/*----------------------------------------

  private PROCEDURE SetErrMsg

     Private procedure. Put message on FND message stack to signal an error
     attributes. This procedure only supports up to two tokens.

  PARAMS:
    p_err_msg         IN  VARCHAR2 : the FND message name
    p_token1          IN  VARCHAR2 DEFAULT NULL : the name of token 1
    p_token1_val      IN  VARCHAR2 DEFAULT NULL : the token 1 value
    p_token2          IN  VARCHAR2 DEFAULT NULL : the name of token 2
    p_token2_val      IN  VARCHAR2 DEFAULT NULL : the token 2 value
    p_translate       IN  BOOLEAN  DEFAULT TRUE : translation flag for tokens

----------------------------------------*/

PROCEDURE SetErrMsg
(
  p_err_msg         IN  VARCHAR2
, p_token1          IN  VARCHAR2 DEFAULT NULL
, p_token1_val      IN  VARCHAR2 DEFAULT NULL
, p_token2          IN  VARCHAR2 DEFAULT NULL
, p_token2_val      IN  VARCHAR2 DEFAULT NULL
, p_translate       IN  BOOLEAN  DEFAULT TRUE
)

IS
lv_prev_msg FND_NEW_MESSAGES.MESSAGE_TEXT%TYPE;
lv_proc_name VARCHAR2(30) := 'SetErrMsg';
BEGIN

  -- just to lot previous messages if any
  lv_prev_msg := FND_MESSAGE.get();

  IF ( lv_prev_msg IS NOT NULL ) THEN

    IF ( fnd_log.level_statement >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) THEN
      FND_LOG.string(fnd_log.level_statement, g_log_module_name || '.' || lv_proc_name, 'Previous error message: ' || lv_prev_msg);
    END IF;

  END IF;

  ERROR_MESSAGE := p_err_msg;

  FND_MESSAGE.set_name(FND_MSG_APP, p_err_msg);

  IF ( p_token1 IS NOT NULL ) THEN
    FND_MESSAGE.set_token(p_token1, p_token1_val, p_translate);
  END IF;

  IF ( p_token2 IS NOT NULL ) THEN
    FND_MESSAGE.set_token(p_token2, p_token2_val, p_translate);
  END IF;

EXCEPTION
WHEN OTHERS THEN
  RAISE;
END SetErrMsg;

/*----------------------------------------*/

PROCEDURE XX_CREATE_OID_STAGE(
  itemtype IN VARCHAR2
, itemkey IN VARCHAR2
, actid IN NUMBER
, funcmode IN VARCHAR2
, resultout OUT NOCOPY VARCHAR2
)
IS

lv_reg_key WF_ITEM_ATTRIBUTE_VALUES.TEXT_VALUE%TYPE;
lv_user_name FND_USER.USER_NAME%TYPE;
lv_user_email FND_USER.EMAIL_ADDRESS%TYPE;
lv_user_firstname WF_ITEM_ATTRIBUTE_VALUES.TEXT_VALUE%TYPE;
lv_user_lastname WF_ITEM_ATTRIBUTE_VALUES.TEXT_VALUE%TYPE;
lv_user_middlename WF_ITEM_ATTRIBUTE_VALUES.TEXT_VALUE%TYPE;
lv_unencrypted_password VARCHAR2(30);
lv_proc_name VARCHAR2(30) := 'XX_CREATE_OID_STAGE';

--  [ encryption parameters to be passed ] *******

input_string      CHAR(64)    := NULL;	 -- Length needs to be multiple of eigth
key_string        CHAR(16)    := NULL;   -- Key needs to be exactly 8 bytes
encrypted_string  CHAR(64)    := NULL;   -- Length needs to be multiple of eigth
iv_string         CHAR(64)    := NULL;   -- Length needs to be multiple of eigth
which             PLS_INTEGER := 0;      -- If = 0, (default), then TwoKeyMode is used.
                                         -- If = 1, then ThreeKeyMode is used


CURSOR l_fnd_user_cur(l_user_name VARCHAR2) IS
   SELECT * FROM fnd_user WHERE user_name = l_user_name;

l_fnd_user_rec l_fnd_user_cur%ROWTYPE;


--  [ ******* MAIN LINE PROCEDURE *******
BEGIN


IF ( fnd_log.level_procedure >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) THEN
  fnd_log.string(fnd_log.level_procedure,g_log_module_name || '.' || lv_proc_name, g_log_proc_start);
END IF;


IF ( funcmode = 'RUN' ) then

  -- [ ******* retrieve user info from stored workflow attributes ******
  lv_reg_key := WF_ENGINE.GetItemAttrText(itemtype, itemkey, 'REGISTRATION_KEY',TRUE);
  IF ( lv_reg_key IS NULL ) THEN

    IF ( fnd_log.level_exception >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) THEN
      fnd_log.string(fnd_log.level_exception, g_log_module_name || '.' || lv_proc_name, g_log_reg_key_notfound);
    END IF;

    RAISE NO_DATA_FOUND;
  END IF;

  
  lv_user_name := upper(WF_ENGINE.GetItemAttrText(itemtype, itemkey, 'ASSIGNED_USER_NAME'));
  lv_user_email := WF_ENGINE.GetItemAttrText(itemtype, itemkey, 'REGISTRANT_EMAIL');
  lv_user_firstname := WF_ENGINE.GetItemAttrText(itemtype, itemkey, 'FIRST_NAME');
  lv_user_lastname := WF_ENGINE.GetItemAttrText(itemtype, itemkey, 'LAST_NAME');
  lv_user_middlename := WF_ENGINE.GetItemAttrText(itemtype, itemkey, 'MIDDLE_NAME');
  lv_unencrypted_password := WF_ENGINE.GetItemAttrText(itemtype, itemkey, 'FIRST_LOGON_KEY');
 
  

  -- [ ****** Get the FND_USER record based on the assigned user name ******
 
  BEGIN
    OPEN l_fnd_user_cur(lv_user_name);
    FETCH l_fnd_user_cur INTO l_fnd_user_rec;
    IF l_fnd_user_cur%notfound THEN
       CLOSE l_fnd_user_cur;
 
       IF ( fnd_log.level_exception >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) THEN
          fnd_log.string(fnd_log.level_exception, g_log_module_name || '.' || lv_proc_name, 'FND_USER user_name not found');
       END IF;

       RAISE NO_DATA_FOUND;

    END IF;  
    CLOSE l_fnd_user_cur;

  
   
    IF ( fnd_log.level_procedure >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) THEN
       fnd_log.string(fnd_log.level_procedure, g_log_module_name || '.' || lv_proc_name, 'Creating XX_XXSEC_POS_OID_USER');
    END IF;

 -- [ ****** Call 3Des to encrypt the cleartext password for the OID Interface ******

    -- get random key then encrypt the password
    key_string 	     := dbms_crypto.randombytes(8);
    input_string     := lv_unencrypted_password; 
    encrypted_string := DBMS_OBFUSCATION_TOOLKIT.DES3Encrypt(input_string => input_string
                                                            ,key_string   => key_string
                                                            ,which        => which
                                                            ,iv_string    => iv_string
                                                            );


    INSERT INTO XX_XXSEC_POS_OID_USER
    (EXT_USER_ID  
	,USERID
        ,PASSWORD
        ,ENCRYPTED_FOUNDATION_PASSWORD
        ,ENCRYPTED_USER_PASSWORD
	,PERSON_FIRST_NAME
	,PERSON_MIDDLE_NAME
	,PERSON_LAST_NAME
	,EMAIL
	,PARTY_ID
	,STATUS
	,SITE_KEY
	,END_DATE
	,LOAD_STATUS
	,CREATED_BY
	,CREATION_DATE
	,LAST_UPDATE_DATE
	,LAST_UPDATED_BY
	,LAST_UPDATE_LOGIN
	,PERMISSION_FLAG
       )
     VALUES
       (l_fnd_user_rec.user_id
       ,l_fnd_user_rec.user_name
       ,null
       ,key_string
       ,encrypted_string
       ,SUBSTR(l_fnd_user_rec.description, (INSTR(l_fnd_user_rec.description,',') - LENGTH(l_fnd_user_rec.description) ))
       ,null
       ,SUBSTR(l_fnd_user_rec.description,1, (INSTR(l_fnd_user_rec.description,',')-1 ))
       ,l_fnd_user_rec.email_address
       ,l_fnd_user_rec.person_party_id
       ,'0'
       ,null
       ,l_fnd_user_rec.end_date
       ,'Not Available'
       ,l_fnd_user_rec.created_by
       ,Sysdate
       ,Sysdate
       ,l_fnd_user_rec.last_updated_by
       ,l_fnd_user_rec.last_update_login
       ,' '
       );


   
     IF ( fnd_log.level_procedure >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) THEN
        fnd_log.string(fnd_log.level_procedure, g_log_module_name || '.' || lv_proc_name, 'XX_XXSEC_POS_OID_USER created');
     END IF;

  resultout := 'COMPLETE:SUCCESS';

   IF ( fnd_log.level_procedure >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) THEN
     fnd_log.string(fnd_log.level_procedure,g_log_module_name || '.' || lv_proc_name, g_log_proc_end);
   END IF;

   RETURN;
   END;

END IF; -- funcmode = 'RUN'

EXCEPTION
   WHEN OTHERS THEN

      IF ( fnd_log.level_exception >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) THEN
        fnd_log.string(fnd_log.level_exception, g_log_module_name || '.' || lv_proc_name || '.exception', Sqlerrm);
      END IF;

      IF ( CheckError() IS NULL ) THEN
	     SetErrMsg(MSG_UNEXPECTED_ERROR);
	     resultout := 'COMPLETE:ERROR';
      END IF;
      WF_CORE.CONTEXT (V_PACKAGE_NAME, 'XX_CREATE_OID_STAGE', itemtype, itemkey, to_char(actid), funcmode);
      RAISE;
END XX_CREATE_OID_STAGE;


END   XX_POS_OID_PKG;
/