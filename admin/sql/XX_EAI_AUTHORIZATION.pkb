create or replace PACKAGE body xx_eai_authorization
IS
  -- +===================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- +===================================================================================+
  -- | Name        : XX_EAI_AUTHORIZATION                                                |
  -- | Description : Package for Authorization process                                   |
  -- |Parameters   :                                                                     |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |DRAFT 1.0 27-Jun-2020  Divyansh Saini          Initial draft version               |
  -- +===================================================================================+
  -- +==================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- +===================================================================================+
  -- | Name        : GET_PAYER_INSTR_ASSGN_FAIL                                          |
  -- | Description : Determines cause of the instrument assignments view returning no    |
  -- |               data                                                                |
  -- |Parameters   : p_instr_assign_id                                                   |
  -- |             , p_payer                                                             |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |RAFT 1.0 27-Jun-2020  Divyansh Saini          Initial draft version                |
  -- +===================================================================================+
FUNCTION Get_Payer_Instr_Assgn_Fail(
    p_instr_assign_id IN iby_pmt_instr_uses_all.instrument_payment_use_id%TYPE,
    p_payer           IN IBY_FNDCPT_COMMON_PUB.PayerContext_rec_type )
  RETURN VARCHAR2
IS
  l_msg VARCHAR2(100);
  l_payer_id iby_pmt_instr_uses_all.ext_pmt_party_id%TYPE;
  l_party_id iby_external_payers_all.party_id%TYPE;
  l_count   NUMBER;
  l_dbg_mod VARCHAR2(100) := G_DEBUG_MODULE || '.Get_Payer_Instr_Assgn_Fail';
BEGIN
  IF( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('Enter',G_LEVEL_PROCEDURE,l_dbg_mod);
  END IF;
  IF( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('instr assignment id:=' || p_instr_assign_id, G_LEVEL_STATEMENT,l_dbg_mod);
  END IF;
  l_msg := 'IBY_INVALID_INSTR_ASSIGN';
  -- Bug: 7719030
  -- Handling Exceptions in a different way
  BEGIN
    SELECT ext_pmt_party_id
    INTO l_payer_id
    FROM iby_pmt_instr_uses_all
    WHERE (instrument_payment_use_id = p_instr_assign_id);
    IF( G_LEVEL_STATEMENT           >= G_CURRENT_RUNTIME_LEVEL) THEN
      iby_debug_pub.add('payer id:=' || l_payer_id,G_LEVEL_STATEMENT,l_dbg_mod);
    END IF;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IF( G_LEVEL_EXCEPTION >= G_CURRENT_RUNTIME_LEVEL) THEN
      iby_debug_pub.add('Exception: No Instrument found',G_LEVEL_EXCEPTION,l_dbg_mod);
    END IF;
    RETURN l_msg;
  END;
  l_msg := 'IBY_20491';
  SELECT party_id
  INTO l_party_id
  FROM iby_external_payers_all
  WHERE (ext_payer_id    = l_payer_id);
  IF( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('external payer count:=' || SQL%ROWCOUNT,G_LEVEL_STATEMENT,l_dbg_mod);
  END IF;
  IF (SQL%ROWCOUNT < 1) THEN
    RETURN l_msg;
  END IF;
  l_msg                 := 'IBY_INVALID_PARTY_CONTEXT';
  IF( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('party id:=' || l_party_id,G_LEVEL_STATEMENT,l_dbg_mod);
  END IF;
  IF (l_party_id <> p_payer.Party_Id) THEN
    RETURN l_msg;
  END IF;
  IF( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('Exit',G_LEVEL_PROCEDURE,l_dbg_mod);
  END IF;
  RETURN NULL;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  RETURN l_msg;
END Get_Payer_Instr_Assgn_Fail;
-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_EXTENSION_AUTH_FAIL                                            |
-- | Description : Determine the reason extension lookup failed in the auth API        |
-- |Parameters   : p_trxn_extension_id                                                 |
-- |             , p_payer                                                             |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |RAFT 1.0 27-Jun-2020  Divyansh Saini          Initial draft version                |
-- +===================================================================================+
FUNCTION Get_Extension_Auth_Fail(
    p_trxn_extension_id IN iby_fndcpt_tx_extensions.trxn_extension_id%TYPE,
    p_payer             IN IBY_FNDCPT_COMMON_PUB.PayerContext_rec_type )
  RETURN VARCHAR2
IS
  l_msg VARCHAR2(100);
  l_instr_assign_id iby_pmt_instr_uses_all.instrument_payment_use_id%TYPE;
  l_ext_payer_id iby_fndcpt_tx_extensions.ext_payer_id%TYPE;
  l_dbg_mod VARCHAR2(100) := G_DEBUG_MODULE || '.Get_Extension_Auth_Fail';
BEGIN
  l_msg := 'IBY_INVALID_TXN_EXTENSION';
  -- Bug: 7719030.
  --Changing exception handling.
  BEGIN
    IF( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      iby_debug_pub.add('Enter',G_LEVEL_PROCEDURE,l_dbg_mod);
    END IF;
    SELECT instr_assignment_id,
      ext_payer_id
    INTO l_instr_assign_id,
      l_ext_payer_id
    FROM iby_fndcpt_tx_extensions
    WHERE (p_trxn_extension_id = trxn_extension_id);
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN l_msg;
  END;
  IF( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('checking instrument assignment',G_LEVEL_STATEMENT,l_dbg_mod);
  END IF;
  l_msg         := Get_Payer_Instr_Assgn_Fail(l_instr_assign_id,p_payer);
  IF (NOT l_msg IS NULL) THEN
    RETURN l_msg;
  END IF;
  IF( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('EXIT',G_LEVEL_PROCEDURE,l_dbg_mod);
  END IF;
  RETURN NULL;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  RETURN l_msg;
END Get_Extension_Auth_Fail;
-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_PAYER_INSTR_ASSGN_FAIL                                          |
-- | Description :    This is a Private utility procedure.
-- |                  Used to securely wipe out the CVV after
-- |                  the first authorization.
-- |                  As the PABP guidelines, a secure wipeout of data could be essentially achieved
-- |                  by updating the column with a randomly generated value, issuing a commit, and
-- |                  then updating the value with NULL (or deleting the row) and then issuing another
-- |                  commit.
-- |                   We achieve this through the following autonomous transaction block                                                                |
-- |Parameters   : p_segment_id                                                        |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |RAFT 1.0 27-Jun-2020  Divyansh Saini          Initial draft version                |
-- +===================================================================================+
PROCEDURE Secure_Wipe_Segment(
    p_segment_id IN iby_fndcpt_tx_extensions.instr_code_sec_segment_id%TYPE )
IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  l_random_val NUMBER;
  l_module     CONSTANT VARCHAR2(30) := 'Secure_Wipe_Segment';
  l_dbg_mod    VARCHAR2(100)         := G_DEBUG_MODULE || '.' || l_module;
BEGIN
  IF( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('Enter',G_LEVEL_PROCEDURE,l_dbg_mod);
  END IF;
  IF( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('p_segment_id = '|| p_segment_id,G_LEVEL_STATEMENT,l_dbg_mod);
  END IF;
  IF (p_segment_id IS NOT NULL) THEN
    SELECT TRUNC(DBMS_RANDOM.VALUE(1000,9999)) INTO l_random_val FROM dual;
    IF( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      iby_debug_pub.add('Updating the security code with random value.', G_LEVEL_STATEMENT,l_dbg_mod);
    END IF;
    UPDATE iby_security_segments
    SET segment_cipher_text = RAWTOHEX(fnd_crypto.randombytes(32))
    WHERE sec_segment_id    = p_segment_id;
    COMMIT;
    UPDATE iby_security_segments
    SET segment_cipher_text = NULL
    WHERE sec_segment_id    = p_segment_id;
    -- DELETE iby_security_segments
    -- WHERE sec_segment_id = p_segment_id;
    COMMIT;
  END IF;
  IF( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('Exit',G_LEVEL_PROCEDURE,l_dbg_mod);
  END IF;
END Secure_Wipe_Segment;
-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_TANGIBLE_ID                                                     |
-- | Description : Determine the reason extension lookup failed in the auth API        |
-- |Parameters   : p_trxn_extension_id                                                 |
-- |             , p_payer                                                             |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |RAFT 1.0 27-Jun-2020  Divyansh Saini          Initial draft version                |
-- +===================================================================================+
FUNCTION Get_Tangible_Id(
    p_app_short_name IN fnd_application.application_short_name%TYPE,
    p_trxn_extn_id   IN iby_fndcpt_tx_extensions.trxn_extension_id%TYPE )
  RETURN iby_trxn_summaries_all.tangibleid%TYPE
IS
  l_tangible_id iby_trxn_summaries_all.tangibleid%TYPE;
  l_cust_pson VARCHAR2(30);
  l_msg       VARCHAR2(10);
  l_dbg_mod   VARCHAR2(100) := G_DEBUG_MODULE || '.Get_Tangible_Id(2)';
BEGIN
  IF( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('Enter with 2 params',G_LEVEL_PROCEDURE,l_dbg_mod);
  END IF;
  -- Bug# 8544953
  -- This API returns customized PSON if the customer had implemented the custome code
  IBY_PSON_CUSTOMIZER_PKG.Get_Custom_Tangible_Id(p_app_short_name, p_trxn_extn_id, l_cust_pson, l_msg);
  IF( l_msg        = IBY_PSON_CUSTOMIZER_PKG.G_CUST_PSON_YES ) THEN
    l_tangible_id := l_cust_pson;
    iby_debug_pub.add('Customized PSON :='||l_tangible_id,G_LEVEL_PROCEDURE,l_dbg_mod);
  ELSE
    --Bug# 8535868
    --Removing '_' since this is not accepted by FDC
    -- l_tangible_id := p_app_short_name || '_' || p_trxn_extn_id;
    l_tangible_id := p_app_short_name || p_trxn_extn_id;
    iby_debug_pub.add('PSON:' ||l_tangible_id || ' was not customized',G_LEVEL_PROCEDURE,l_dbg_mod);
  END IF;
  IF( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('Exit',G_LEVEL_PROCEDURE,l_dbg_mod);
  END IF;
  RETURN l_tangible_id;
END Get_Tangible_Id;
--End of Overloaded Function
-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_INTERNAL_PAYEE                                                  |
-- | Description : Gets the internal payee id from a payee context                     |
-- |Parameters   : p_trxn_extension_id                                                 |
-- |             , p_payer                                                             |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |RAFT 1.0 27-Jun-2020  Divyansh Saini          Initial draft version                |
-- +===================================================================================+
FUNCTION Get_Internal_Payee(
    p_payee IN iby_fndcpt_trxn_pub.PayeeContext_rec_type)
  RETURN iby_payee.payeeid%TYPE
IS
  l_payeeid iby_payee.payeeid%TYPE;
  CURSOR c_payeeid (ci_org_type IN iby_fndcpt_payee_appl.org_type%TYPE, ci_org_id IN iby_fndcpt_payee_appl.org_id%TYPE )
  IS
    SELECT p.payeeid
    FROM iby_payee p,
      iby_fndcpt_payee_appl a
    WHERE (p.mpayeeid      = a.mpayeeid)
    AND ((a.org_type       = ci_org_type)
    AND (a.org_id          = ci_org_id));
  l_dbg_mod VARCHAR2(100) := G_DEBUG_MODULE || '.Get_Internal_Payee';
BEGIN
  IF( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('Enter',G_LEVEL_PROCEDURE,l_dbg_mod);
  END IF;
  IF (c_payeeid%ISOPEN) THEN
    CLOSE c_payeeid;
  END IF;
  OPEN c_payeeid(p_payee.Org_Type, p_payee.Org_Id);
  FETCH c_payeeid INTO l_payeeid;
  IF (c_payeeid%NOTFOUND) THEN
    l_payeeid := NULL;
  END IF;
  CLOSE c_payeeid;
  IF( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('Exit',G_LEVEL_PROCEDURE,l_dbg_mod);
  END IF;
  RETURN l_payeeid;
END Get_Internal_Payee;
-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_TX_EXTENSION_COPY_COUNT                                         |
-- | Description : Gets the internal payee id from a payee context                     |
-- |Parameters   : p_trxn_extension_id                                                 |
-- |             , p_payer                                                             |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |RAFT 1.0 27-Jun-2020  Divyansh Saini          Initial draft version                |
-- +===================================================================================+
FUNCTION Get_Tx_Extension_Copy_Count(
    p_trxn_extension_id IN iby_fndcpt_tx_extensions.trxn_extension_id%TYPE)
  RETURN NUMBER
IS
  l_copy_count NUMBER;
  CURSOR c_xe_copies(ci_x_id IN iby_fndcpt_tx_extensions.trxn_extension_id%TYPE)
  IS
    SELECT COUNT(copy_trxn_extension_id)
    FROM iby_fndcpt_tx_xe_copies
    WHERE (source_trxn_extension_id = ci_x_id);
  l_dbg_mod VARCHAR2(100)          := G_DEBUG_MODULE || '.Get_Tx_Extension_Copy_Count';
BEGIN
  IF( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('Enter',G_LEVEL_PROCEDURE,l_dbg_mod);
  END IF;
  IF (c_xe_copies%ISOPEN) THEN
    CLOSE c_xe_copies;
  END IF;
  OPEN c_xe_copies(p_trxn_extension_id);
  FETCH c_xe_copies INTO l_copy_count;
  CLOSE c_xe_copies;
  IF( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('Exit',G_LEVEL_PROCEDURE,l_dbg_mod);
  END IF;
  RETURN NVL(l_copy_count,0);
END Get_Tx_Extension_Copy_Count;
-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_REAUTH_TANGIBLE_ID                                              |
-- | Description : New Function to generate PSON for a re-authorization                |
-- |Parameters   : p_trxn_extension_id                                                 |
-- |             , p_payer                                                             |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |RAFT 1.0 27-Jun-2020  Divyansh Saini          Initial draft version                |
-- +===================================================================================+
-- New Function to generate PSON for a re-authorization
FUNCTION Get_Reauth_Tangible_Id(
    p_app_short_name IN fnd_application.application_short_name%TYPE,
    p_trxn_extn_id   IN iby_fndcpt_tx_extensions.trxn_extension_id%TYPE )
  RETURN iby_trxn_summaries_all.tangibleid%TYPE
IS
  l_tangible_id iby_trxn_summaries_all.tangibleid%TYPE;
  l_prev_pson iby_trxn_summaries_all.tangibleid%TYPE;
  l_reauth_cnt NUMBER;
  l_cust_pson  VARCHAR2(30);
  l_msg        VARCHAR2(10);
  l_dbg_mod    VARCHAR2(100) := G_DEBUG_MODULE || '.Get_Reauth_Tangible_Id';
BEGIN
  iby_debug_pub.add('Enter',G_LEVEL_PROCEDURE,l_dbg_mod);
  --IBY_PSON_CUSTOMIZER_PKG.Get_Custom_Tangible_Id(p_app_short_name, p_trxn_extn_id, l_cust_pson, l_msg);
  --IF( l_msg = IBY_PSON_CUSTOMIZER_PKG.G_CUST_PSON_YES ) THEN
  --  l_tangible_id := l_cust_pson;
  --  iby_debug_pub.add('Customized PSON :='||l_tangible_id,G_LEVEL_PROCEDURE,l_dbg_mod);
  --ELSE
  --Bug# 8535868
  --Removing '_' since this is not accepted by FDC
  -- l_tangible_id := p_app_short_name || '_' || p_trxn_extn_id;
  l_tangible_id := Get_Tangible_Id(p_app_short_name, p_trxn_extn_id);
  SELECT payment_system_order_number
  INTO l_prev_pson
  FROM iby_fndcpt_tx_extensions
  WHERE trxn_extension_id = p_trxn_extn_id;
  IF(l_prev_pson         IS NOT NULL) THEN
    iby_debug_pub.add('PSON for earlier attempt: '||l_prev_pson,G_LEVEL_STATEMENT,l_dbg_mod);
    IF (l_prev_pson = l_tangible_id) THEN -- first re-auth
      iby_debug_pub.add('First time re-auth.',G_LEVEL_STATEMENT,l_dbg_mod);
      l_tangible_id := l_tangible_id||'R1';
    ELSE
      l_reauth_cnt := TO_NUMBER(LTRIM((SUBSTR(l_prev_pson, LENGTH(l_tangible_id)+1)),'R'));
      iby_debug_pub.add((l_reauth_cnt                                           +1)||'th time re-auth.',G_LEVEL_STATEMENT,l_dbg_mod);
      l_tangible_id := l_tangible_id||'R'||(l_reauth_cnt                        +1);
    END IF;
  END IF;
  iby_debug_pub.add('PSON:' ||l_tangible_id ,G_LEVEL_STATEMENT,l_dbg_mod);
  --END IF;
  iby_debug_pub.add('Exit',G_LEVEL_PROCEDURE,l_dbg_mod);
  RETURN l_tangible_id;
END Get_Reauth_Tangible_Id;
  -- +==================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- +===================================================================================+
  -- | Name        : GET_TRANSLATION                                                     |
  -- | Description : Procedure to get translation values                                 |
  -- |Parameters   : p_translation_name                                                  |
  -- |             : p_source_value1                                                     |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |RAFT 1.0 27-Jun-2020  Divyansh Saini          Initial draft version                |
  -- +===================================================================================+
PROCEDURE GET_TRANSLATION(
    p_translation_name IN VARCHAR2 ,
    p_source_value1    IN VARCHAR2 ,
    x_target_value1    IN OUT NOCOPY VARCHAR2 ,
    x_target_value2    IN OUT NOCOPY VARCHAR2 ,
    x_target_value3    IN OUT NOCOPY VARCHAR2 )
IS
  ls_target_value1  VARCHAR2(240);
  ls_target_value2  VARCHAR2(240);
  ls_target_value3  VARCHAR2(240);
  ls_target_value4  VARCHAR2(240);
  ls_target_value5  VARCHAR2(240);
  ls_target_value6  VARCHAR2(240);
  ls_target_value7  VARCHAR2(240);
  ls_target_value8  VARCHAR2(240);
  ls_target_value9  VARCHAR2(240);
  ls_target_value10 VARCHAR2(240);
  ls_target_value11 VARCHAR2(240);
  ls_target_value12 VARCHAR2(240);
  ls_target_value13 VARCHAR2(240);
  ls_target_value14 VARCHAR2(240);
  ls_target_value15 VARCHAR2(240);
  ls_target_value16 VARCHAR2(240);
  ls_target_value17 VARCHAR2(240);
  ls_target_value18 VARCHAR2(240);
  ls_target_value19 VARCHAR2(240);
  ls_target_value20 VARCHAR2(240);
  ls_error_message  VARCHAR2(240);
BEGIN
  XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC( p_translation_name => p_translation_name ,
                                                   p_source_value1 => p_source_value1 ,
                                                   x_target_value1 => x_target_value1 ,
                                                   x_target_value2 => x_target_value2 ,
                                                   x_target_value3 => x_target_value3 ,
                                                   x_target_value4 => ls_target_value4 ,
                                                   x_target_value5 => ls_target_value5 ,
                                                   x_target_value6 => ls_target_value6 ,
                                                   x_target_value7 => ls_target_value7 ,
                                                   x_target_value8 => ls_target_value8 ,
                                                   x_target_value9 => ls_target_value9 ,
                                                   x_target_value10 => ls_target_value10 ,
                                                   x_target_value11 => ls_target_value11 ,
                                                   x_target_value12 => ls_target_value12 ,
                                                   x_target_value13 => ls_target_value13 ,
                                                   x_target_value14 => ls_target_value14 ,
                                                   x_target_value15 => ls_target_value15 ,
                                                   x_target_value16 => ls_target_value16 ,
                                                   x_target_value17 => ls_target_value17 ,
                                                   x_target_value18 => ls_target_value18 ,
                                                   x_target_value19 => ls_target_value19 ,
                                                   x_target_value20 => ls_target_value20 ,
                                                   x_error_message => ls_error_message );
END GET_TRANSLATION;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : XX_CAPTURE                                                          |
-- | Description : Procedure to capture ORAPMTCAPTURE Event and populate               |
-- |                xx_ar_order_details                                                |
-- |Parameters   : p_trxn_extension_id                                                 |
-- |             , p_payer                                                             |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |RAFT 1.0 27-Jun-2020  Divyansh Saini          Initial draft version                |
-- +===================================================================================+
PROCEDURE xx_capture(
    p_trxn_id IN NUMBER,
    x_transaction_id_out OUT iby_trxn_summaries_all.TransactionID%TYPE,
    x_transaction_mid_out OUT iby_trxn_summaries_all.trxnmid%TYPE,
    p_ret_status OUT VARCHAR2,
    p_ret_error OUT VARCHAR2)
IS
  CURSOR c_iby_data
  IS
    SELECT *
    FROM iby_trxn_summaries_all
    WHERE TRANSACTIONID      = p_trxn_id
    AND status              IN (1,11)
    AND TRXNTYPEID           = 8;
  l_module_name VARCHAR2(30):= 'XX_CAPTURE';
  lv_extend_names_in JTF_VARCHAR2_TABLE_100;
  lv_extend_vals_in JTF_VARCHAR2_TABLE_200;
  x_error_buf   VARCHAR2(4000);
  x_ret_code    VARCHAR2(4000);
  x_receipt_ref VARCHAR2(4000);
  ln_status     NUMBER;
BEGIN
    iby_debug_pub.add('Starting xx_capture',1,G_DEBUG_MODULE || l_module_name);
    FOR rec_iby_data IN c_iby_data LOOP
        BEGIN
        XX_IBY_SETTLEMENT_PKG.PRE_CAPTURE_CCRETUNRN( x_error_buf => x_error_buf,
                                                   x_ret_code => x_ret_code,
                                                   x_receipt_ref => x_receipt_ref,
                                                   p_oapfaction => 'ORACAPTURE',
                                                   p_oapfcurrency => rec_iby_data.currencynamecode,
                                                   p_oapfamount => rec_iby_data.amount,
                                                   p_oapfstoreid => rec_iby_data.bepkey,
                                                   p_oapftransactionid => p_trxn_id,
                                                   p_oapftrxn_ref => NULL,
                                                   p_oapforder_id => rec_iby_data.tangibleid );
        IF x_ret_code = 0 THEN
            ln_status  := 0;
        ELSE
            ln_status:= 10;
        END IF;
        iby_debug_pub.add('After PRE_CAPTURE_CCRETUNRN ',1,G_DEBUG_MODULE || l_module_name);
        EXCEPTION
        WHEN OTHERS THEN
            iby_debug_pub.add('Error in PRE_CAPTURE_CCRETUNRN ',1,G_DEBUG_MODULE || l_module_name);
            p_ret_status := 'E';
            p_ret_error  := SQLERRM;
        END;
        BEGIN
            iby_debug_pub.add('Calling insert_other_txn',1,G_DEBUG_MODULE || l_module_name);
            iby_transactioncc_pkg.insert_other_txn ( ecapp_id_in                       => rec_iby_data.ecappid,--IN     iby_trxn_summaries_all.ecappid%TYPE,
                                                    req_type_in                        => rec_iby_data.reqtype,                                         --IN     iby_trxn_summaries_all.ReqType%TYPE,
                                                    order_id_in                        => rec_iby_data.tangibleid,                                      --IN     iby_transactions_v.order_id%TYPE,
                                                    merchant_id_in                     => rec_iby_data.payeeid,                                      --IN     iby_transactions_v.merchant_id%TYPE,
                                                    vendor_id_in                       => rec_iby_data.bepid,                                          --IN     iby_transactions_v.vendor_id%TYPE,
                                                    vendor_key_in                      => rec_iby_data.bepkey,                                        --IN     iby_transactions_v.bepkey%TYPE,
                                                    status_in                          => ln_status,                                                      --IN     iby_transactions_v.status%TYPE,
                                                    time_in                            => sysdate,                                                          --IN     iby_transactions_v.time%TYPE,
                                                    payment_type_in                    => NULL,                                                     --IN     iby_transactions_v.payment_type%TYPE,
                                                    payment_name_in                    => NULL,                                                     --IN     iby_transactions_v.payment_name%TYPE,
                                                    trxn_type_in                       => rec_iby_data.trxntypeid,                                     --IN     iby_transactions_v.trxn_type%TYPE,
                                                    amount_in                          => rec_iby_data.amount,                                            --IN     iby_transactions_v.amount%TYPE,
                                                    currency_in                        => rec_iby_data.currencynamecode,                                --IN     iby_transactions_v.currency%TYPE,
                                                    referencecode_in                   => NULL,                                                    --IN     iby_transactions_v.referencecode%TYPE,
                                                    vendor_code_in                     => NULL,                                                      --IN     iby_transactions_v.vendor_code%TYPE,
                                                    vendor_message_in                  => NULL,                                                   --IN     iby_transactions_v.vendor_message%TYPE,
                                                    error_location_in                  => NULL,                                                   --IN     iby_transactions_v.error_location%TYPE,
                                                    trace_number_in                    => NULL,                                                     --IN     iby_transactions_v.TraceNumber%TYPE,
                                                    org_id_in                          => NULL,                                                           --IN     iby_trxn_summaries_all.org_id%type,
                                                    billeracct_in                      => NULL,                                                       --IN     iby_tangible.acctno%type,
                                                    refinfo_in                         => NULL,                                                          --IN     iby_tangible.refinfo%type,
                                                    memo_in                            => NULL,                                                             --IN     iby_tangible.memo%type,
                                                    order_medium_in                    => NULL,                                                     --IN     iby_tangible.order_medium%TYPE,
                                                    eft_auth_method_in                 => NULL,                                                  --IN     iby_tangible.eft_auth_method%TYPE,
                                                    payerinstrid_in                    => NULL,                                                     --IN     iby_trxn_summaries_all.payerinstrid%type,
                                                    instrnum_in                        => NULL,                                                         --IN     iby_trxn_summaries_all.instrnumber%type,
                                                    payerid_in                         => NULL,                                                          --IN     iby_trxn_summaries_all.payerid%type,
                                                    master_key_in                      => NULL,                                                       --IN     iby_security_pkg.DES3_KEY_TYPE,
                                                    subkey_seed_in                     => NULL,                                                      --IN     RAW,
                                                    trxnref_in                         => NULL,                                                          --IN     iby_trxn_summaries_all.trxnref%TYPE,
                                                    instr_expirydate_in                => NULL,                                                 --=> NULL,--IN     iby_trxn_core.instr_expirydate%TYPE,
                                                    card_subtype_in                    => NULL,                                                     --IN     iby_trxn_core.card_subtype_code%TYPE,
                                                    instr_owner_name_in                => NULL,                                                 --IN  iby_trxn_core.instr_owner_name%TYPE,
                                                    instr_address_line1_in             => NULL,                                              --IN  iby_trxn_core.instr_owner_address_line1%TYPE,
                                                    instr_address_line2_in             => NULL,                                              --IN  iby_trxn_core.instr_owner_address_line2%TYPE,
                                                    instr_address_line3_in             => NULL,                                              --IN  iby_trxn_core.instr_owner_address_line3%TYPE,
                                                    instr_city_in                      => NULL,                                                       --IN     iby_trxn_core.instr_owner_city%TYPE,
                                                    instr_state_in                     => NULL,                                                      --IN     iby_trxn_core.instr_owner_state_province%TYPE,
                                                    instr_country_in                   => NULL,                                                    --IN     iby_trxn_core.instr_owner_country%TYPE,
                                                    instr_postalcode_in                => NULL,                                                 --IN     iby_trxn_core.instr_owner_postalcode%TYPE,
                                                    instr_phonenumber_in               => NULL,                                                --IN    iby_trxn_core.instr_owner_phone%TYPE,
                                                    instr_email_in                     => NULL,                                                      --IN     iby_trxn_core.instr_owner_email%TYPE,
                                                    extend_names_in                    => lv_extend_names_in,                                       --IN     JTF_VARCHAR2_TABLE_100,
                                                    extend_vals_in                     => lv_extend_vals_in,                                         --IN     JTF_VARCHAR2_TABLE_200,
                                                    transaction_id_in_out              => x_transaction_id_out,                               --IN OUT NOCOPY iby_trxn_summaries_all.TransactionID%TYPE,
                                                    transaction_mid_out                => x_transaction_mid_out,                                --OUT NOCOPY iby_trxn_summaries_all.trxnmid%TYPE,
                                                    org_type_in                        => 'OPERATING_UNIT',                                             --IN      iby_trxn_summaries_all.org_type%TYPE,
                                                    payment_channel_code_in            => 'CREDIT_CARD',                                    --IN iby_trxn_summaries_all.payment_channel_code%TYPE,
                                                    factored_flag_in                   => 'N',                                                     --IN iby_trxn_summaries_all.factored_flag%TYPE,
                                                    settlement_date_in                 => NULL,                                                  --IN iby_trxn_summaries_all.settledate%TYPE,
                                                    settlement_due_date_in             => NULL,                                              --IN iby_trxn_summaries_all.settlement_due_date%TYPE,
                                                    process_profile_code_in            => NULL,                                             -- IN iby_trxn_summaries_all.process_profile_code%TYPE,
                                                    instrtype_in                       => rec_iby_data.instrtype                                       -- IN iby_trxn_summaries_all.instrtype%TYPE
                                                    );
        EXCEPTION
        WHEN OTHERS THEN
            iby_debug_pub.add('Error in iby_transactioncc_pkg.insert_other_txn ',1,G_DEBUG_MODULE || l_module_name);
            p_ret_status := 'E';
            p_ret_error  := SQLERRM;
        END;
    END LOOP;
EXCEPTION
WHEN OTHERS THEN
  iby_debug_pub.add('Error in xx_capture ',1,G_DEBUG_MODULE || l_module_name);
  p_ret_status := 'E';
  p_ret_error  := SQLERRM;
END xx_capture;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : EAI_WEBSERVICE_AUTHORIZATION                                        |
-- | Description : New Function to generate PSON for a re-authorization                |
-- |Parameters   : p_trxn_extension_id                                                 |
-- |             , p_payer                                                             |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |RAFT 1.0 27-Jun-2020  Divyansh Saini          Initial draft version                |
-- +===================================================================================+
PROCEDURE EAI_webservice_authorization(
    p_store_number    IN VARCHAR2,
    p_customer_number IN VARCHAR2,
    p_inv_number      IN VARCHAR2,
    p_instrid         IN NUMBER,
    p_amount          IN NUMBER,
    p_order_id        IN VARCHAR2,
    x_reqresp OUT IBY_PAYMENT_ADAPTER_PUB.ReqResp_rec_type )
IS
  PRAGMA autonomous_transaction;
  l_module_name            VARCHAR2(30):= 'EAI_WEBSERVICE_AUTHORIZATION';
  lc_auth_payload          VARCHAR2(4000);
  lv_url                   VARCHAR2(2000);
  lv_user                  VARCHAR2(2000);
  lv_pass                  VARCHAR2(2000);
  x_credit_card_number_dec VARCHAR2(200);
  lc_decrypt_error_msg     VARCHAR2(200);
  lv_key_label             VARCHAR2(200);
  lv_card_masked           VARCHAR2(200);
  lv_card_type             VARCHAR2(200);
  lv_cust_name             VARCHAR2(200);
  lv_wallet_loc            VARCHAR2(200);
  lv_wallet_pass           VARCHAR2(200);
  l_request UTL_HTTP.req;
  l_response UTL_HTTP.resp;
  lc_buffer VARCHAR2(2000);
  lclob_buffer CLOB;
  lv_exp_date         VARCHAR2(20);
  ln_null_value       VARCHAR2(20);
  ln_code             VARCHAR2(200);
  lv_message          VARCHAR2(2000);
  ln_ret_code         NUMBER;
  lv_avsCode          VARCHAR2(200);
  lv_authCode         VARCHAR2(200);
  lv_cofTransactionId VARCHAR2(2000);
  lv_error_message    VARCHAR2(2000);
  lv_error            VARCHAR2(2000);
  lv_ixdate           VARCHAR2(200);
  lv_ixTime           VARCHAR2(200);
  lv_ixBankNodeID     VARCHAR2(200);
  lv_ixPS2000         VARCHAR2(200);
  L_MY_SCHEME         VARCHAR2(256);
  L_MY_REALM          VARCHAR2(256);
  L_MY_PROXY          BOOLEAN;
  ln_trxn_id          NUMBER;
  ln_transaction_id   VARCHAR2(500);
  e_resp_error        EXCEPTION;
  ln_error            NUMBER;
BEGIN
    iby_debug_pub.add('Start EAI_webservice_authorization',1,G_DEBUG_MODULE || l_module_name);
    BEGIN
        SELECT attribute5,
          attribute6,
          card_issuer_code,
          chname,
          TO_CHAR(expirydate,'YYMM')
        INTO lv_key_label,
          lv_card_masked,
          lv_card_type,
          lv_cust_name,
          lv_exp_date
        FROM iby_creditcard
        WHERE 1     =1
        AND instrid = p_instrid;
    EXCEPTION
    WHEN OTHERS THEN
    iby_debug_pub.add('Error getting pmt information '||SQLERRM,1,G_DEBUG_MODULE || l_module_name);
    END;
  -- Logging the details
    iby_debug_pub.add('lv_key_label '||lv_key_label,1,G_DEBUG_MODULE || l_module_name);
    iby_debug_pub.add('lv_card_masked '||lv_card_masked,1,G_DEBUG_MODULE || l_module_name);
    iby_debug_pub.add('lv_card_type '||lv_card_type,1,G_DEBUG_MODULE || l_module_name);
    iby_debug_pub.add('lv_cust_name '||lv_cust_name,1,G_DEBUG_MODULE || l_module_name);
    iby_debug_pub.add('lv_exp_date '||lv_exp_date,1,G_DEBUG_MODULE || l_module_name);
  -- Decrypting the card number
    xx_od_security_key_pkg.decrypt(x_decrypted_val => x_credit_card_number_dec,
                                 x_error_message => lc_decrypt_error_msg,
                                 p_module => 'AJB',
                                 p_key_label => lv_key_label,
                                 p_algorithm => '3DES',
                                 p_encrypted_val => lv_card_masked,
                                 p_format => 'BASE64');
    iby_debug_pub.add('Decrypted card ',1,G_DEBUG_MODULE || l_module_name);
    SELECT p_customer_number|| '-'|| TO_CHAR(SYSDATE, 'DDMONYYYYHH24MISS')
      INTO ln_transaction_id
      FROm DUAL;
    iby_debug_pub.add('Transaction_id '||ln_transaction_id,1,G_DEBUG_MODULE || l_module_name);
    SELECT '{
            "paymentAuthorizationRequest": {
            "transactionHeader": {
            "consumerName": "IREC",
            "consumerTransactionId": "'
                || ln_transaction_id
                || '",
            "consumerTransactionDateTime":"'
                || TO_CHAR(SYSDATE, 'YYYY-MM-DD')
                || 'T'
                || TO_CHAR(SYSDATE, 'HH24:MI:SS')
                || '"
            },
            "customer": {
            "firstName": "'
                || lv_cust_name
                || '",
            "middleName": "",
            "lastName": "",
            "paymentDetails": {
            "paymentType": "CREDITCARD",
            "paymentCard": {
            "cardHighValueToken": "'
                || x_credit_card_number_dec
                || '",
            "expirationDate": "'
                || lv_exp_date
                || '",
            "amount": "'
                ||p_amount
                ||'",
            "cardType": "'
                || lv_card_type
                || '",
            "applicationTransactionNumber": "'
                || p_inv_number
                || '",
            "ixPosEchoField":"'
                ||p_order_id
                ||'",
            "billingAddress": {
            "name": "'
                || lv_cust_name
                || '",
            "address": {
            "address1": "'
                || NULL--lr_bill_to_cust_location_info.address1
                || '",
            "address2": "'
                || NULL--lr_bill_to_cust_location_info.address2
                || '",
            "city": "'
                || NULL--lr_bill_to_cust_location_info.city
                || '",
            "state": "'
                || NULL--lr_bill_to_cust_location_info.state
                || '",
            "postalCode": "'
                || NULL--SUBSTR(lr_bill_to_cust_location_info.postal_code, 1, 5)
                || '",
            "country": "'
                || NULL--lr_bill_to_cust_location_info.country
                || '"
            }
            }
            },
            "billingAgreementId": "'
                || NULL--lc_billing_application_id
                || '",
            "walletId": "'
                || NULL--lc_wallet_id
                || '",
            "avsOnly": true
            },
            "contact": {
            "email": "'
                || NULL--p_contract_info.customer_email
                || '",
            "phoneNumber": "'
                --  || lv_phone_number --??
                || '",
            "faxNumber": "'
                -- || lv_fax_number --??
                || '"
            }
            },
            "storeNumber": "'
                || lpad(p_store_number,6,'0')
                || '",
            "contract": {
            "contractId": "'
                || NULL--p_contract_info.contract_id
                || '",
            "customerId": "'
                || p_customer_number--p_contract_info.bill_to_osr
                || '"
            }
            }
            }
            '
    INTO lc_auth_payload
    FROM DUAL;
    iby_debug_pub.add('getting webservice details ',1,G_DEBUG_MODULE || l_module_name);
    --
    -- Get Webservice details
    --
    XX_EAI_AUTHORIZATION.GET_TRANSLATION('XX_AR_SUBSCRIPTIONS','AUTH_SERVICE',lv_url,lv_user,lv_pass);
    XX_EAI_AUTHORIZATION.GET_TRANSLATION('XX_FIN_IREC_TOKEN_PARAMS','WALLET_LOCATION',lv_wallet_loc,lv_wallet_pass,ln_null_value);
    iby_debug_pub.add('Setting wallet details ',1,G_DEBUG_MODULE || l_module_name);
    IF lv_wallet_loc IS NOT NULL THEN
    UTL_HTTP.SET_WALLET(lv_wallet_loc, lv_wallet_pass);
    END IF;
    --
    -- Begin request
    --
    iby_debug_pub.add('Begin request ',1,G_DEBUG_MODULE || l_module_name);
    l_request := UTL_HTTP.begin_request(lv_url, 'POST', 'HTTP/1.1');
    UTL_HTTP.set_header(l_request, 'user-agent', 'mozilla/4.0');
    UTL_HTTP.set_header(l_request, 'content-type', 'application/json');
    UTL_HTTP.set_header(l_request, 'Content-Length', LENGTH(lc_auth_payload));
    UTL_HTTP.set_header(l_request, 'Authorization', 'Basic ' || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(lv_user|| ':' ||lv_pass))));
    UTL_HTTP.write_text(l_request, lc_auth_payload);
    --
    --Getting response
    l_response := UTL_HTTP.get_response(l_request);
    COMMIT;
    iby_debug_pub.add('Parse response ',1,G_DEBUG_MODULE || l_module_name);
    BEGIN
        lclob_buffer := EMPTY_CLOB;
        LOOP
            UTL_HTTP.read_text(l_response, lc_buffer, LENGTH(lc_buffer));
            lclob_buffer := lclob_buffer || lc_buffer;
        END LOOP;
        UTL_HTTP.end_response(l_response);
    EXCEPTION
    WHEN UTL_HTTP.end_of_body THEN
    UTL_HTTP.end_response(l_response);
    END;
    --
    --Masking Credit card
    --
    IF x_credit_card_number_dec IS NOT NULL THEN
        lclob_buffer              := REPLACE(lclob_buffer, x_credit_card_number_dec, SUBSTR(x_credit_card_number_dec, 1, 6) || '*****' || SUBSTR(x_credit_card_number_dec, LENGTH(x_credit_card_number_dec) - 4, 4));
        lc_auth_payload           := REPLACE(lc_auth_payload, x_credit_card_number_dec, SUBSTR(x_credit_card_number_dec, 1, 6) || '*****' || SUBSTR(x_credit_card_number_dec, LENGTH(x_credit_card_number_dec) - 4, 4));
    END IF;
    iby_debug_pub.add('Return payload Success ',1,G_DEBUG_MODULE || l_module_name);

    IF (l_response.status_code >= 400) AND (l_response.status_code <= 499) THEN
    -- Detect whether the page is password protected,
    -- and we didn't supply the right authorization.
    -- Note the use of utl_http.HTTP_UNAUTHORIZED, a predefined
    -- utl_http package global variable
        IF (l_response.status_code = utl_http.HTTP_UNAUTHORIZED) THEN
            utl_http.get_authentication( l_response, l_my_scheme, l_my_realm, l_my_proxy);
            IF (l_my_proxy) THEN
                lv_error_message            := substrb('Web proxy server is protected. Please supply the required ' || l_my_scheme || ' authentication username/password for realm ' || l_my_realm || ' for the proxy server.',1,199);
                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                    fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'Web proxy server is protected. Please supply the required ' || l_my_scheme || ' authentication username/password for realm ' || l_my_realm || ' for the proxy server.' );
                END IF;
            ELSE
                lv_error_message            := substrb('Web page is protected. Please supply the required ' || l_my_scheme || ' authentication username/password for realm ' || l_my_realm || ' for the proxy server.',1,199);
                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                    fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'Web page ' || lv_url || ' is protected. Please supplied the required ' ||l_my_scheme || ' authentication username/password for realm ' || l_my_realm ||' for the Web page.' );
                END IF;
            END IF;
        ELSE
            lv_error_message            := substrb('Please Check the URL.'|| utl_tcp.crlf ||utl_tcp.crlf ||'URL used :'||lv_url|| utl_tcp.crlf ||utl_tcp.crlf || 'Response :'||lv_url,1,999);
            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'Check the URL...' );
            END IF;
        END IF;
        utl_http.end_response(l_response);
        RETURN;
        -- Look for server-side error and report it.
    elsif (l_response.status_code >= 500) AND (l_response.status_code <= 599) THEN
        lv_error_message            := 'Check if the Web site is up.';
        utl_http.end_response(l_response);
        RETURN;
    END IF;
    --
    --parseing data
    --
    iby_debug_pub.add('Parse response query ',1,G_DEBUG_MODULE || l_module_name);
    BEGIN
        SELECT *
          INTO  ln_code,
                lv_message,
                ln_ret_code,
                lv_avsCode,
                lv_authCode,
                lv_cofTransactionId,
                lv_ixdate,
                lv_ixTime,
                lv_ixBankNodeID,
                lv_ixPS2000
        FROM json_table(lclob_buffer ,'$' COLUMNS ( code NUMBER(10) PATH '$.paymentAuthorizationResponse.transactionStatus.code',
                                                    MESSAGE VARCHAR2(2000 CHAR) PATH '$.paymentAuthorizationResponse.transactionStatus.message',
                                                    ret_code NUMBER(10) PATH '$.paymentAuthorizationResponse.authorizationResult.code',
                                                    avsCode VARCHAR2(20 CHAR) PATH '$.paymentAuthorizationResponse.authorizationResult.avsCode',
                                                    authCode VARCHAR2(20 CHAR) PATH '$.paymentAuthorizationResponse.authorizationResult.authCode',
                                                    cofTransactionId VARCHAR2(2000 CHAR) PATH '$.paymentAuthorizationResponse.authorizationResult.cofTransactionId',
                                                    ixDate VARCHAR2(2000 CHAR) PATH '$.paymentAuthorizationResponse.authorizationResult.ixDate',
                                                    ixTime VARCHAR2(2000 CHAR) PATH '$.paymentAuthorizationResponse.authorizationResult.ixTime',
                                                    ixBankNodeID VARCHAR2(2000 CHAR) PATH '$.paymentAuthorizationResponse.authorizationResult.ixBankNodeID',
                                                    ixPS2000 VARCHAR2(2000 CHAR) PATH '$.paymentAuthorizationResponse.authorizationResult.ixPS2000'
                                                    ));
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        iby_debug_pub.add('no data from AJB',1,G_DEBUG_MODULE || l_module_name);
    WHEN OTHERS THEN
        iby_debug_pub.add('error while parsing data from AJB '||SQLERRM,1,G_DEBUG_MODULE || l_module_name);
    END;

    SELECT xxfin.xx_ar_irec_cc_auth_payloads_s.nextval INTO ln_trxn_id FROM DUAL;
    --
    --Insert Payload Details
    --
    BEGIN
        INSERT INTO xx_ar_irec_cc_auth_payloads VALUES
        (
          ln_trxn_id,
          ln_transaction_id,
          p_customer_number,
          p_inv_number,
          p_order_id,
          lpad(p_store_number,6,'0'),
          lc_auth_payload,
          lclob_buffer,
          sysdate,
          fnd_global.user_id,
          sysdate,
          fnd_global.user_id,
          fnd_global.login_id,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          decode(ln_code,'0','Y','N')
        );
    EXCEPTION WHEN OTHERS THEN
       iby_debug_pub.add('Error while inserting into xx_ar_irec_cc_auth_payloads ' || SQLERRM,1,G_DEBUG_MODULE || l_module_name);
    END;
    iby_debug_pub.add('Return Values ',1,G_DEBUG_MODULE || l_module_name);
    iby_debug_pub.add('   ln_code             '||ln_code,1,G_DEBUG_MODULE || l_module_name);
    iby_debug_pub.add('   lv_message          '||lv_message,1,G_DEBUG_MODULE || l_module_name);
    iby_debug_pub.add('   ln_ret_code         '||ln_ret_code,1,G_DEBUG_MODULE || l_module_name);
    iby_debug_pub.add('   lv_avsCode          '||lv_avsCode,1,G_DEBUG_MODULE || l_module_name);
    iby_debug_pub.add('   lv_authCode         '||lv_authCode,1,G_DEBUG_MODULE || l_module_name);
    iby_debug_pub.add('   lv_cofTransactionId '||lv_cofTransactionId,1,G_DEBUG_MODULE || l_module_name);
    iby_debug_pub.add('updating record type ',1,G_DEBUG_MODULE || l_module_name);

    BEGIN
        SELECT 1
          INTO ln_error
          FROM FND_LOOKUP_VALUES
         WHERE lookup_type = 'XX_AR_IREC_ERROR_CODES'
           AND enabled_flag = 'Y'
           AND lookup_code = ln_ret_code;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_error := 0;
      WHEN OTHERS THEN
        ln_error :=-1;
    END;

    x_reqresp.Response.Status  := ln_ret_code;
    x_reqresp.Authcode         := lv_authCode;
    x_reqresp.AVSCode          := lv_avsCode;
    x_reqresp.CVV2Result       := NULL;
    x_reqresp.Trxn_Date        := to_date(lv_ixdate,'MMDDYYYY');
    x_reqresp.Acquirer         := lv_ixBankNodeID;
    x_reqresp.PmtInstr_Type    := lv_card_type;
    x_reqresp.BEPErrCode       := ln_ret_code;
    x_reqresp.BEPErrMessage    := lv_message;

    IF ln_error !=0 THEN
        BEGIN
           SELECT meaning
             INTO lv_error
             FROM FND_LOOKUP_VALUES
            WHERE lookup_type = 'XX_AR_IREC_ERROR_CODES'
              AND enabled_flag = 'Y'
              AND lookup_code = ln_ret_code;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_error := 0;
          WHEN OTHERS THEN
            lv_error :=-1;
        END;
        x_reqresp.BEPErrMessage := lv_error;
        raise e_resp_error;
    END IF;
    commit; --- commit for pragma transaction
EXCEPTION
WHEN e_resp_error THEN

   x_reqresp.Response.Status     := '0005';
   x_reqresp.Response.ErrCode    := ln_ret_code;
   x_reqresp.Response.ErrMessage := lv_error;
   x_reqresp.ErrorLocation       := 3;
   iby_debug_pub.add('Incorrect response in EAI_webservice_authorization '|| SQLERRM,1,G_DEBUG_MODULE || l_module_name);
   commit;  --- commit for pragma transaction
WHEN OTHERS THEN
    x_reqresp.Response.Status := '0005';
    x_reqresp.Trxn_Date     := sysdate;
    x_reqresp.Authcode      := '';
    x_reqresp.AVSCode       := 6;
    x_reqresp.CVV2Result    := NULL;
    x_reqresp.Trxn_Date     := sysdate;
    x_reqresp.Acquirer      := '';
    x_reqresp.PmtInstr_Type := lv_card_type;
    x_reqresp.BEPErrCode    := 6;
  iby_debug_pub.add('Error in EAI_webservice_authorization '|| SQLERRM,1,G_DEBUG_MODULE || l_module_name);
  x_reqresp.BEPErrMessage := 'Error in EAI_webservice_authorization '|| SQLERRM;
  rollback;
  --   x_ret_status := 'E';
  --   x_ret_msg    := 'Error in EAI_webservice_authorization '|| SQLERRM;
END;

/*    Count number of previous PENDING transactions, ignoring the
	cancelled ones
*/

Function getNumPendingTrxns(i_payeeid in iby_payee.payeeid%type,
			i_tangibleid in iby_tangible.tangibleid%type,
			i_reqtype in iby_trxn_summaries_all.reqtype%type)
return number

IS

l_num_trxns number;

BEGIN

     SELECT count(*)
       INTO l_num_trxns
       FROM iby_trxn_summaries_all
      WHERE TangibleID = i_tangibleid
	AND UPPER(ReqType) = UPPER(i_reqtype)
	AND PayeeID = i_payeeid
	AND (status IN (11,9));

    IF (l_num_trxns > 1) THEN
      -- should never run into this block
       	raise_application_error(-20000, 'IBY_20422#', FALSE);
    END IF;

   return l_num_trxns;
END;
  --
  -- USE: inserts transactional extensibility data
  --
  PROCEDURE insert_extensibility
  (
  p_trxnmid           IN     iby_trxn_summaries_all.trxnmid%TYPE,
  p_commit            IN     VARCHAR2,
  p_extend_names      IN     JTF_VARCHAR2_TABLE_100,
  p_extend_vals       IN     JTF_VARCHAR2_TABLE_200
  )
  IS
  BEGIN

    IF (p_extend_names IS NULL) THEN
      RETURN;
    END IF;


    FOR i IN p_extend_names.FIRST..p_extend_names.LAST LOOP
    -- Bug# 18502475
    -- Check for Null before inserting the data
      IF(p_extend_names(i) IS NOT NULL AND p_extend_vals(i) IS NOT NULL) then
        INSERT INTO iby_trxn_extensibility
        (trxn_extend_id,trxnmid,extend_name,extend_value,created_by,
         creation_date,last_updated_by,last_update_date,last_update_login,
         object_version_number)
        VALUES
        (iby_trxn_extensibility_s.NEXTVAL,
         p_trxnmid,p_extend_names(i),p_extend_vals(i),
         fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,
         fnd_global.login_id,1);
       END IF;
    END LOOP;

    IF (p_commit = 'Y') THEN
      COMMIT;
    END IF;
  END insert_extensibility;

/* get TID based on orderid */
Function getTID(i_payeeid in iby_payee.payeeid%type,
		i_tangibleid in iby_tangible.tangibleid%type)
return number

IS

l_tid number;
cursor c_tid(ci_payeeid in iby_payee.payeeid%type,
		ci_tangibleid in iby_tangible.tangibleid%type)
  is
	SELECT distinct transactionid
	FROM iby_trxn_summaries_all
	WHERE tangibleid = ci_tangibleid
	AND payeeid = ci_payeeid;

BEGIN
	if (c_tid%isopen) then
	   close c_tid;
	end if;

	open c_tid(i_payeeid, i_tangibleid);
	fetch c_tid into l_tid;
	if (c_tid%notfound) then
	  SELECT iby_trxnsumm_trxnid_s.NEXTVAL
	  INTO l_tid
	  FROM dual;
	end if;

	close c_tid;

	return l_tid;

END getTID;


  /* Inserts a new row into the IBY_TRXN_SUMMARIES_ALL table.  This method  */
  /* would be called every time a MIPP authorize operation is performed. */

PROCEDURE insert_auth_txn
	(
	 ecapp_id_in         IN     iby_trxn_summaries_all.ecappid%TYPE,
         req_type_in         IN     iby_trxn_summaries_all.ReqType%TYPE,
         order_id_in         IN     iby_transactions_v.order_id%TYPE,
         merchant_id_in      IN     iby_transactions_v.merchant_id%TYPE,
         vendor_id_in        IN     iby_transactions_v.vendor_id%TYPE,
         vendor_key_in       IN     iby_transactions_v.bepkey%TYPE,
         amount_in           IN     iby_transactions_v.amount%TYPE,
         currency_in         IN     iby_transactions_v.currency%TYPE,
         status_in           IN     iby_transactions_v.status%TYPE,
         time_in             IN     iby_transactions_v.time%TYPE,
         payment_name_in     IN     iby_transactions_v.payment_name%TYPE,
	 payment_type_in     IN	    iby_transactions_v.payment_type%TYPE,
         trxn_type_in        IN     iby_transactions_v.trxn_type%TYPE,
	 authcode_in         IN     iby_transactions_v.authcode%TYPE,
	 referencecode_in    IN     iby_transactions_v.referencecode%TYPE,
         AVScode_in          IN     iby_transactions_v.AVScode%TYPE,
         acquirer_in         IN     iby_transactions_v.acquirer%TYPE,
         Auxmsg_in           IN     iby_transactions_v.Auxmsg%TYPE,
         vendor_code_in      IN     iby_transactions_v.vendor_code%TYPE,
         vendor_message_in   IN     iby_transactions_v.vendor_message%TYPE,
         error_location_in   IN     iby_transactions_v.error_location%TYPE,
         trace_number_in     IN	    iby_transactions_v.TraceNumber%TYPE,
	 org_id_in           IN     iby_trxn_summaries_all.org_id%type,
         billeracct_in       IN     iby_tangible.acctno%type,
         refinfo_in          IN     iby_tangible.refinfo%type,
         memo_in             IN     iby_tangible.memo%type,
         order_medium_in     IN     iby_tangible.order_medium%TYPE,
         eft_auth_method_in  IN     iby_tangible.eft_auth_method%TYPE,
	 payerinstrid_in     IN	    iby_trxn_summaries_all.payerinstrid%type,
	 instrnum_in	     IN     iby_trxn_summaries_all.instrnumber%type,
	 payerid_in          IN     iby_trxn_summaries_all.payerid%type,
	 instrtype_in        IN     iby_trxn_summaries_all.instrType%type,
         cvv2result_in       IN     iby_trxn_core.CVV2Result%type,
         master_key_in       IN     iby_security_pkg.DES3_KEY_TYPE,
         subkey_seed_in      IN     RAW,
         trxnref_in          IN     iby_trxn_summaries_all.trxnref%TYPE,
         dateofvoiceauth_in  IN     iby_trxn_core.date_of_voice_authorization%TYPE,
         instr_expirydate_in IN     iby_trxn_core.instr_expirydate%TYPE,
         instr_sec_val_in    IN     VARCHAR2,
         card_subtype_in     IN     iby_trxn_core.card_subtype_code%TYPE,
         card_data_level_in  IN     iby_trxn_core.card_data_level%TYPE,
         instr_owner_name_in    IN  iby_trxn_core.instr_owner_name%TYPE,
         instr_address_line1_in IN  iby_trxn_core.instr_owner_address_line1%TYPE,
         instr_address_line2_in IN  iby_trxn_core.instr_owner_address_line2%TYPE,
         instr_address_line3_in IN  iby_trxn_core.instr_owner_address_line3%TYPE,
         instr_city_in       IN     iby_trxn_core.instr_owner_city%TYPE,
         instr_state_in      IN     iby_trxn_core.instr_owner_state_province%TYPE,
         instr_country_in    IN     iby_trxn_core.instr_owner_country%TYPE,
         instr_postalcode_in IN     iby_trxn_core.instr_owner_postalcode%TYPE,
         instr_phonenumber_in IN    iby_trxn_core.instr_owner_phone%TYPE,
         instr_email_in      IN     iby_trxn_core.instr_owner_email%TYPE,
         pos_reader_cap_in   IN     iby_trxn_core.pos_reader_capability_code%TYPE,
         pos_entry_method_in IN     iby_trxn_core.pos_entry_method_code%TYPE,
         pos_card_id_method_in IN   iby_trxn_core.pos_id_method_code%TYPE,
         pos_auth_source_in  IN     iby_trxn_core.pos_auth_source_code%TYPE,
         reader_data_in      IN     iby_trxn_core.reader_data%TYPE,
         extend_names_in     IN     JTF_VARCHAR2_TABLE_100,
         extend_vals_in      IN     JTF_VARCHAR2_TABLE_200,
         debit_network_code_in IN   iby_trxn_core.debit_network_code%TYPE,
         surcharge_amount_in  IN    iby_trxn_core.surcharge_amount%TYPE,
         proc_tracenumber_in  IN    iby_trxn_core.proc_tracenumber%TYPE,
         transaction_id_out  OUT NOCOPY iby_trxn_summaries_all.TransactionID%TYPE,
         transaction_mid_out OUT NOCOPY iby_trxn_summaries_all.trxnmid%TYPE,
         org_type_in         IN      iby_trxn_summaries_all.org_type%TYPE,
         payment_channel_code_in  IN iby_trxn_summaries_all.payment_channel_code%TYPE,
         factored_flag_in         IN iby_trxn_summaries_all.factored_flag%TYPE,
         process_profile_code_in     IN iby_trxn_summaries_all.process_profile_code%TYPE,
	 sub_key_id_in       IN     iby_trxn_summaries_all.sub_key_id%TYPE,
	 voiceAuthFlag_in    IN     iby_trxn_core.voiceauthflag%TYPE,
	 reauth_trxnid_in    IN     iby_trxn_summaries_all.TransactionID%TYPE
)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_num_trxns      NUMBER	     := 0;
    l_trxn_mid	     NUMBER;
    l_transaction_id NUMBER;
    l_tmid iby_trxn_summaries_all.mtangibleid%type;
    l_mpayeeid iby_payee.mpayeeid%type;

    l_return_status    VARCHAR2(1);
    l_msg_count        NUMBER;
    l_msg_data         VARCHAR2(200);
    l_checksum_valid   BOOLEAN := FALSE;  -- whether the card number is valid.

    l_cc_type          VARCHAR2(80);
    lx_cc_hash         iby_trxn_summaries_all.instrnum_hash%TYPE;
    lx_range_id        iby_cc_issuer_ranges.cc_issuer_range_id%TYPE;
    lx_instr_len       iby_trxn_summaries_all.instrnum_length%TYPE;
    lx_segment_id      iby_trxn_summaries_all.instrnum_sec_segment_id%TYPE;
    l_old_segment_id   iby_trxn_summaries_all.instrnum_sec_segment_id%TYPE;

    l_instrnum         iby_trxn_summaries_all.instrnumber%type;
    l_expirydate       iby_trxn_core.instr_expirydate%type;

    l_pos_txn          iby_trxn_core.pos_trxn_flag%TYPE;
    l_payer_party_id   iby_trxn_summaries_all.payer_party_id%type;

    l_voiceauth_flag   iby_trxn_core.voiceauthflag%type;
    l_sub_key_id       iby_trxn_summaries_all.sub_key_id%TYPE;

    -- variables for CHNAME and EXPDATE encryption
    l_chname_sec_segment_id iby_security_segments.sec_segment_id%TYPE;
    l_expdate_sec_segment_id iby_security_segments.sec_segment_id%TYPE;
    l_masked_chname     VARCHAR2(100) := NULL;
  --  l_encrypted_date_format VARCHAR2(20);
    l_encrypted         VARCHAR2(1) := 'N';

 BEGIN

     l_num_trxns := getNumPendingTrxns(merchant_id_in,order_id_in,req_type_in);

     iby_transactioncc_pkg.prepare_instr_data
     (FND_API.G_FALSE,master_key_in,instrnum_in,instrType_in,l_instrnum,
      l_cc_type,lx_cc_hash,lx_range_id,lx_instr_len,lx_segment_id);


     --
     -- NOTE: for all subsequent data encryptions, make sure that the
     --       parameter to increment the subkey is set to 'N' so that
     --       all encrypted data for the trxn uses the same key!!
     --       else data will NOT DECRYPT CORRECTLY!!
     --
     l_expirydate := instr_expirydate_in;



     -- PABP Fixes
     -- card holder name and instrument expiry are also considered to be
     -- sensitive. We need to encrypt those before inserting/updating the
     -- record in IBY_TRXN_CORE

     IF ((IBY_CREDITCARD_PKG.Get_CC_Encrypt_Mode() <>
          IBY_SECURITY_PKG.G_ENCRYPT_MODE_NONE)
	--  AND ( IBY_CREDITCARD_PKG.Other_CC_Attribs_Encrypted = 'Y')
	)
     THEN
      l_chname_sec_segment_id :=
                 IBY_SECURITY_PKG.encrypt_field_vals(instr_owner_name_in,
		                                     master_key_in,
						     null,
						     'N'
						     );
      l_expdate_sec_segment_id :=
                 IBY_SECURITY_PKG.encrypt_date_field(l_expirydate,
		                                     master_key_in,
						     null,
						     'N'
						     );

      l_masked_chname :=
                IBY_SECURITY_PKG.Mask_Data(instr_owner_name_in,
		                           IBY_SECURITY_PKG.G_MASK_ALL,
				           0,
					   'X'
					   );
      l_encrypted := 'Y';
      l_expirydate := NULL;
     ELSE
      l_masked_chname := instr_owner_name_in;
      l_encrypted := 'N';

     END IF;

     IF ((pos_reader_cap_in IS NULL)
         AND (pos_entry_method_in IS NULL)
         AND (pos_card_id_method_in IS NULL)
         AND (pos_auth_source_in IS NULL)
         AND (reader_data_in IS NULL)
        )
     THEN
       l_pos_txn := 'N';
     ELSE
       l_pos_txn := 'Y';
     END IF;

     IF (l_num_trxns = 0)    THEN
     	 -- new auth request, insert into table
      	SELECT iby_trxnsumm_mid_s.NEXTVAL
	INTO l_trxn_mid
	FROM dual;

  -- get the payer_party_id if exists
 begin
   if(payerid_in is not NULL) then
       l_payer_party_id :=to_number(payerid_in);
       end if;
  exception
    when others then
   select card_owner_id
   into l_payer_party_id
   from iby_creditcard
   where instrid=payerinstrid_in;
  end;

	IF(reauth_trxnid_in > 0)THEN
	  l_transaction_id := reauth_trxnid_in;
	ELSE
	  l_transaction_id := getTID(merchant_id_in, order_id_in);
	END IF;

	transaction_id_out := l_transaction_id;
        transaction_mid_out := l_trxn_mid;

	iby_accppmtmthd_pkg.getMPayeeId(merchant_id_in, l_mpayeeid);

       --Create an entry in iby_tangible table
       iby_bill_pkg.createBill(order_id_in,amount_in,currency_in,
		   billeracct_in,refinfo_in, memo_in,
                   order_medium_in, eft_auth_method_in, l_tmid);
--test_debug('subkeyid passed as: '|| sub_key_id_in);
       INSERT INTO iby_trxn_summaries_all
	(TrxnMID, TransactionID,TrxntypeID, ReqType, ReqDate,
	 Amount,CurrencyNameCode, UpdateDate,Status, PaymentMethodName,
	 TangibleID,MPayeeID, PayeeID,BEPID,bepKey,mtangibleid,
	 BEPCode,BEPMessage,Errorlocation,ecappid,org_id,
	 payerinstrid, instrnumber, payerid, instrType,

	 last_update_date,last_updated_by,creation_date, created_by,
         last_update_login,object_version_number,instrsubtype,trxnref,
         org_type, payment_channel_code, factored_flag,
         cc_issuer_range_id, instrnum_hash, instrnum_length,
         instrnum_sec_segment_id, payer_party_id, process_profile_code,
         salt_version,needsupdt,sub_key_id)
       VALUES (l_trxn_mid, l_transaction_id, trxn_type_in, req_type_in,
               sysdate,
	       amount_in, currency_in, time_in, status_in, payment_type_in,
	       order_id_in, l_mpayeeid, merchant_id_in, vendor_id_in,
	       vendor_key_in, l_tmid, vendor_code_in, vendor_message_in,
	       error_location_in, ecapp_id_in, org_id_in,
               payerinstrid_in, l_instrnum, payerid_in, instrType_in,
	       sysdate, fnd_global.user_id, sysdate, fnd_global.user_id,
               fnd_global.login_id, 1, l_cc_type, trxnref_in,
               org_type_in, payment_channel_code_in, factored_flag_in,
               lx_range_id, lx_cc_hash, lx_instr_len, lx_segment_id,
               l_payer_party_id, process_profile_code_in,
               iby_security_pkg.get_salt_version,'Y',sub_key_id_in);


      /*
       * Fix for bug 5190504:
       *
       * Set the voice auth flag in iby_trxn_core to 'Y'
       * in case, the voice auth date is not null.
       */
   --   IF (dateofvoiceauth_in IS NOT NULL) THEN
   --       l_voiceauth_flag := 'Y';
   --   ELSE
   --       l_voiceauth_flag := 'N';
   --   END IF;

       /*
        * The above logic will not set the voiceAuthFlag if the
	* voice auth date is NULL.
	* The voiceAuthFlag is now received by this API as an
	* input parameter.
	*/
	l_voiceauth_flag := voiceAuthFlag_in;

      INSERT INTO iby_trxn_core (
        TrxnMID, AuthCode, date_of_voice_authorization, voiceauthflag,
        ReferenceCode, TraceNumber,AVSCode, CVV2Result, Acquirer,
	Auxmsg, InstrName,
        Instr_Expirydate, expiry_sec_segment_id,
	Card_Subtype_Code, Card_Data_Level,
        Instr_Owner_Name, chname_sec_segment_id, encrypted,
	Instr_Owner_Address_Line1, Instr_Owner_Address_Line2,
        Instr_Owner_Address_Line3, Instr_Owner_City, Instr_Owner_State_Province,
        Instr_Owner_Country, Instr_Owner_PostalCode, Instr_Owner_Phone,
        Instr_Owner_Email,
        POS_Reader_Capability_Code, POS_Entry_Method_Code,
        POS_Id_Method_Code, POS_Auth_Source_Code, Reader_Data, POS_Trxn_Flag,
debit_network_code, surcharge_amount, proc_tracenumber,
        last_update_date, last_updated_by,
        creation_date, created_by, last_update_login, object_version_number
        ) VALUES (
        l_trxn_mid, authcode_in, dateofvoiceauth_in, l_voiceauth_flag,
        referencecode_in, trace_number_in, AVScode_in, cvv2result_in,
        acquirer_in, Auxmsg_in, payment_name_in,
        l_expirydate, l_expdate_sec_segment_id,
	card_subtype_in, card_data_level_in,
        l_masked_chname, l_chname_sec_segment_id, l_encrypted,
        instr_address_line1_in, instr_address_line2_in, instr_address_line3_in,
        instr_city_in, instr_state_in, instr_country_in, instr_postalcode_in,
        instr_phonenumber_in, instr_email_in,
        pos_reader_cap_in, pos_entry_method_in, pos_card_id_method_in,
        pos_auth_source_in, reader_data_in, l_pos_txn,debit_network_code_in, surcharge_amount_in, proc_tracenumber_in,
        sysdate,fnd_global.user_id,
        sysdate,fnd_global.user_id,fnd_global.login_id,1
        );

        -- probably a superflous call since the first insert is
        -- to log the transaction before it is sent to the payment system
        insert_extensibility(l_trxn_mid,'N',extend_names_in,extend_vals_in);

	--test_debug('insertion complete..');

    ELSE
	--(l_num_trxns = 1)
      -- One previous PENDING transaction, so update previous row
       SELECT TrxnMID, TransactionID, Mtangibleid, instrnum_sec_segment_id, sub_key_id
       INTO l_trxn_mid, transaction_id_out, l_tmid, l_old_segment_id, l_sub_key_id
       FROM iby_trxn_summaries_all
       WHERE (TangibleID = order_id_in)
       AND (UPPER(ReqType) = UPPER(req_type_in))
       AND (PayeeID = merchant_id_in)
       AND (status IN (11,9));

       transaction_mid_out := l_trxn_mid;

       --Re-use the previous subkey for a retry case
 --      sub_key_id_in := l_sub_key_id;

    -- Update iby_tangible table
      iby_bill_pkg.modBill(l_tmid,order_id_in,amount_in,currency_in,
			   billeracct_in,refinfo_in,memo_in,
                           order_medium_in, eft_auth_method_in);


      UPDATE iby_trxn_summaries_all
	 SET BEPID = vendor_id_in,
	     bepKey = vendor_key_in,
	     Amount = amount_in,
		-- amount, bepid is updated as the request can come in
		-- from another online
	     TrxntypeID = trxn_type_in,
	     CurrencyNameCode = currency_in,
	     UpdateDate = time_in,
	     Status = status_in,
	     ErrorLocation = error_location_in,
	     BEPCode = vendor_code_in,
	     BEPMessage = vendor_message_in,
             instrType = instrType,

		-- we don't update payerinstrid and org_id here
		-- as it may overwrite previous payerinstrid, org_id
		-- (from offline scheduling)
		-- in case this request comes in from scheduler

		-- could be a problem if this request comes in from
		-- another online, w/ a different payment instrment
		-- for a previous failed trxn, regardless, the
		--'instrnumber' will always be correct

		--org_id = org_id_in,
 		--payerinstrid = payerinstrid_in,
                -- same for org_type

             PaymentMethodName = NVL(payment_type_in,PaymentMethodName),
	     instrnumber = l_instrnum,
             instrnum_hash = lx_cc_hash,
             instrnum_length = lx_instr_len,
             cc_issuer_range_id = lx_range_id,
             instrnum_sec_segment_id = lx_segment_id,
             trxnref = trxnref_in,
	     last_update_date = sysdate,
	     last_updated_by = fnd_global.user_id,
	     creation_date = sysdate,
	     created_by = fnd_global.user_id,
	     object_version_number = object_version_number + 1,
             payment_channel_code = payment_channel_code_in,
             factored_flag = factored_flag_in
       WHERE TrxnMID = l_trxn_mid;

      DELETE iby_security_segments WHERE sec_segment_id = l_old_segment_id;

      UPDATE iby_trxn_core
	 SET AuthCode = authcode_in,
             date_of_voice_authorization = dateofvoiceauth_in,
           --voiceauthflag = DECODE(dateofvoiceauth_in, NULL, 'N', 'Y'),
	     voiceauthflag = voiceAuthFlag_in,
	     AvsCode = AVScode_in,
             CVV2Result = cvv2result_in,
	     ReferenceCode = referencecode_in,
	     Acquirer = acquirer_in,
	     Auxmsg = Auxmsg_in,
	     TraceNumber = trace_number_in,
             InstrName = NVL(payment_name_in,InstrName),
	     encrypted = l_encrypted,
             Instr_Expirydate = l_expirydate,
	     expiry_sec_segment_id = l_expdate_sec_segment_id,
	     Card_Subtype_Code = card_subtype_in,
             Card_Data_Level = card_data_level_in,
             Instr_Owner_Name = l_masked_chname,
	     chname_sec_segment_id = l_chname_sec_segment_id,
             Instr_Owner_Address_Line1 = instr_address_line1_in,
             Instr_Owner_Address_Line2 = instr_address_line2_in,
             Instr_Owner_Address_Line3 = instr_address_line3_in,
             Instr_Owner_City = instr_city_in,
             Instr_Owner_State_Province = instr_state_in,
             Instr_Owner_Country = instr_country_in,
             Instr_Owner_PostalCode = instr_postalcode_in,
             Instr_Owner_Phone = instr_phonenumber_in,
             Instr_Owner_Email = instr_email_in,
             POS_Reader_Capability_Code = pos_reader_cap_in,
             POS_Entry_Method_Code = pos_entry_method_in,
             POS_Id_Method_Code = pos_card_id_method_in,
             POS_Auth_Source_Code = pos_auth_source_in,
             Reader_Data = reader_data_in,
             POS_Trxn_Flag = l_pos_txn,
             debit_network_code = debit_network_code_in,
             surcharge_amount  = surcharge_amount_in,
             proc_tracenumber = proc_tracenumber_in,
	     last_update_date = sysdate,
	     last_updated_by = fnd_global.user_id,
	     creation_date = sysdate,
	     created_by = fnd_global.user_id,
	     object_version_number = object_version_number + 1
       WHERE TrxnMID = l_trxn_mid;

       insert_extensibility(l_trxn_mid,'N',extend_names_in,extend_vals_in);
    END IF;

    COMMIT;
  END insert_auth_txn;


-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : XX_CREATE_IBY_SUMMARY                                               |
-- | Description : New procedure to enter summary detail of transaction                |
-- |Parameters   : p_trxn_extension_id                                                 |
-- |             , p_payer                                                             |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |RAFT 1.0 27-Jun-2020  Divyansh Saini          Initial draft version                |
-- +===================================================================================+
PROCEDURE xx_create_iby_summary(
    p_receipt_id IN NUMBER,
    x_transaction_id_out OUT iby_trxn_summaries_all.TransactionID%TYPE,
    x_transaction_mid_out OUT iby_trxn_summaries_all.trxnmid%TYPE,
    x_ret_status OUT VARCHAR2,
    x_ret_msg OUT VARCHAR2,
    x_reqresp IN OUT IBY_PAYMENT_ADAPTER_PUB.ReqResp_rec_type)
IS
  l_module_name   VARCHAR2(30):= 'XX_CREATE_IBY_SUMMARY';
  ln_amt          NUMBER;
  ln_payerinstrid NUMBER;
  ln_payerid      NUMBER;
  lv_order_id     VARCHAR2(100);
  lv_cust_number  VARCHAR2(500);
  lv_inv_num      VARCHAR2(500);
  lv_data         VARCHAR2(500);
  lv_token_flag   VARCHAR2(500);
  ln_org_id       NUMBER;
  ln_merchant     NUMBER;
  ln_bep_id       NUMBER ;
  ln_bep_key      NUMBER ;
  lv_extend_names_in JTF_VARCHAR2_TABLE_100;
  lv_extend_vals_in JTF_VARCHAR2_TABLE_200;
BEGIN
  iby_debug_pub.add('Start ',1,G_DEBUG_MODULE || l_module_name);
  --
  -- Getting receipt information
  --
  BEGIN
    SELECT arc.amount,
      arc.attribute11 payerinstrid,
      hca.party_id payerid,
      'ARI'
      ||trxn_extension_id,
      arc.org_id,
      PAY_FROM_CUSTOMER
    INTO ln_amt,
      ln_payerinstrid,
      ln_payerid,
      lv_order_id,
      ln_org_id,
      lv_cust_number
    FROM ar_cash_receipts_all arc,
         iby_fndcpt_tx_extensions ite,
         hz_cust_accounts hca
    WHERE arc.payment_trxn_extension_id = ite.trxn_extension_id
    AND arc.pay_from_customer           = hca.cust_account_id
    AND arc.payment_trxn_extension_id   = p_receipt_id;
  EXCEPTION
  WHEN OTHERS THEN
    --      iby_debug_pub.add('Receipt not found '|| SQLERRM,'STATEMENT',G_DEBUG_MODULE || l_module_name);
    x_ret_status := 'E';
    x_ret_msg    := 'Receipt not found '|| SQLERRM;
  END;
  iby_debug_pub.add('Calling xx_iby_settlement_pkg.xx_ar_invoice_ods',1,G_DEBUG_MODULE || l_module_name);
  xx_iby_settlement_pkg.xx_ar_invoice_ods(lv_order_id,
                                          lv_inv_num,
                                          lv_data,
                                          lv_token_flag);
  iby_debug_pub.add('getting store info ',1,G_DEBUG_MODULE || l_module_name);
  --
  -- Getting Store information
  --
  BEGIN
    /*SELECT a.bepid,
      lpad(c.key,6,'0')
    INTO ln_bep_id ,
      ln_bep_key
    FROM iby_default_bep a,
      iby_bepinfo b,
      iby_bepkeys c,
      IBY_PAYEE p
    WHERE a.payment_channel_code = 'CREDIT_CARD'
    AND a.mpayeeid               = p.mpayeeid
    AND a.bepid                  = b.bepid
    AND p.payeeid                = p_merchant
    AND UPPER(b.activeStatus)    = 'Y'
    AND c.bep_account_id         = a.bep_account_id;*/
    SELECT source_value2,TARGET_VALUE1,TARGET_VALUE2
      INTO ln_merchant,ln_bep_id,ln_bep_key
      FROM xx_fin_translatedefinition xft, xx_fin_translatevalues xftv
     WHERE xft.translate_id = xftv.translate_id
       AND xft.translation_name  = 'XX_IREC_PAYEE_DTL'
       AND source_value1 = ln_org_id
       AND xft.enabled_flag = 'Y'
       AND xftv.enabled_flag = 'Y';

  EXCEPTION
  WHEN OTHERS THEN
    ln_bep_id  := NULL;
    ln_bep_key := NULL;
    iby_debug_pub.add('Error while getting bep id and key',1,G_DEBUG_MODULE || l_module_name);
  END;
  --
  -- Calling Webservice for Authorization
  --
  iby_debug_pub.add('Calling EAI_webservice_authorization',1,G_DEBUG_MODULE || l_module_name);
  EAI_webservice_authorization( ln_bep_key,--p_store_number     IN  VARCHAR2,
                                lv_cust_number,
                                lv_inv_num,
                                ln_payerinstrid ,
                                ln_amt,
                                lv_order_id,
                                x_reqresp );
      --
      -- Calling iby_transactioncc_pkg insert_auth_txn
      --
    iby_debug_pub.add('Calling insert_auth_txn',1,G_DEBUG_MODULE || l_module_name);
    insert_auth_txn (
                            ecapp_id_in                                  => 222,-- IN     iby_trxn_summaries_all.ecappid%TYPE,
                            req_type_in                                  => 'ORAPMTREQ',                                -- IN     iby_trxn_summaries_all.ReqType%TYPE,
                            order_id_in                                  => lv_order_id,                                -- IN     iby_transactions_v.order_id%TYPE,
                            merchant_id_in                               => ln_merchant,                              -- IN     iby_transactions_v.merchant_id%TYPE,
                            vendor_id_in                                 => ln_bep_id,                                 -- IN     iby_transactions_v.vendor_id%TYPE,
                            vendor_key_in                                => lpad(ln_bep_key,6,'0'),                               -- IN     iby_transactions_v.bepkey%TYPE,
                            amount_in                                    =>ln_amt,                                        --   IN     iby_transactions_v.amount%TYPE,
                            currency_in                                  => 'USD',                                      --   IN     iby_transactions_v.currency%TYPE,
                            status_in                                    => x_reqresp.Response.Status,                    --   IN     iby_transactions_v.status%TYPE,
                            time_in                                      => sysdate,                                        --   IN     iby_transactions_v.time%TYPE,
                            payment_name_in                              => NULL,                                   --IN     iby_transactions_v.payment_name%TYPE,
                            payment_type_in                              => 'US_CC IRECEIVABLES_OD_RR',             --  N        iby_transactions_v.payment_type%TYPE,
                            trxn_type_in                                 => 2,                                         --IN     iby_transactions_v.trxn_type%TYPE,
                            authcode_in                                  => x_reqresp.Authcode,                         --IN     iby_transactions_v.authcode%TYPE,
                            referencecode_in                             => NULL,                                  --IN     iby_transactions_v.referencecode%TYPE,
                            AVScode_in                                   => NULL,                                        --IN     iby_transactions_v.AVScode%TYPE,
                            acquirer_in                                  => NULL,                                       --IN     iby_transactions_v.acquirer%TYPE,
                            Auxmsg_in                                    => 'Transaction Approved_001099',                --IN     iby_transactions_v.Auxmsg%TYPE,
                            vendor_code_in                               => x_reqresp.BEPErrCode,                                     -- IN     iby_transactions_v.vendor_code%TYPE,
                            vendor_message_in                            => x_reqresp.BEPErrMessage,              --IN     iby_transactions_v.vendor_message%TYPE,
                            error_location_in                            => 0,                                    --IN     iby_transactions_v.error_location%TYPE,
                            trace_number_in                              => NULL,                                   --IN       iby_transactions_v.TraceNumber%TYPE,
                            org_id_in                                    => ln_org_id,                                    --IN     iby_trxn_summaries_all.org_id%type,
                            billeracct_in                                => NULL,                                     --IN     iby_tangible.acctno%type,
                            refinfo_in                                   => NULL,                                        --IN     iby_tangible.refinfo%type,
                            memo_in                                      => NULL,                                           --IN     iby_tangible.memo%type,
                            order_medium_in                              => NULL,                                   --IN     iby_tangible.order_medium%TYPE,
                            eft_auth_method_in                           => NULL,                                --IN     iby_tangible.eft_auth_method%TYPE,
                            payerinstrid_in                              => ln_payerinstrid,                        --IN        iby_trxn_summaries_all.payerinstrid%type,----- Need to verify fetch
                            instrnum_in                                  => NULL,                                       -- IN     iby_trxn_summaries_all.instrnumber%type,
                            payerid_in                                   => ln_payerid,                                  --IN     iby_trxn_summaries_all.payerid%type,
                            instrtype_in                                 => 'CREDITCARD',                              --IN     iby_trxn_summaries_all.instrType%type,
                            cvv2result_in                                => NULL,                                     --IN     iby_trxn_core.CVV2Result%type,
                            master_key_in                                => NULL,                                     --IN     iby_security_pkg.DES3_KEY_TYPE,   --- Need to verify
                            subkey_seed_in                               => NULL,                                    --IN     RAW,
                            trxnref_in                                   => NULL,                                        --IN     iby_trxn_summaries_all.trxnref%TYPE,
                            dateofvoiceauth_in                           => NULL,                                --   IN     iby_trxn_core.date_of_voice_authorization%TYPE,
                            instr_expirydate_in                          => NULL,                               --   IN     iby_trxn_core.instr_expirydate%TYPE,
                            instr_sec_val_in                             => NULL,                                  -- IN     VARCHAR2,
                            card_subtype_in                              => NULL,                                   --  IN     iby_trxn_core.card_subtype_code%TYPE,
                            card_data_level_in                           => NULL,                                --IN     iby_trxn_core.card_data_level%TYPE,
                            instr_owner_name_in                          => NULL,                               --IN  iby_trxn_core.instr_owner_name%TYPE,
                            instr_address_line1_in                       => NULL,                            --IN  iby_trxn_core.instr_owner_address_line1%TYPE,
                            instr_address_line2_in                       => NULL,                            --IN  iby_trxn_core.instr_owner_address_line2%TYPE,
                            instr_address_line3_in                       => NULL,                            -- IN  iby_trxn_core.instr_owner_address_line3%TYPE,
                            instr_city_in                                => NULL,                                     --IN     iby_trxn_core.instr_owner_city%TYPE,
                            instr_state_in                               => NULL,                                    --IN     iby_trxn_core.instr_owner_state_province%TYPE,
                            instr_country_in                             => NULL,                                  --IN     iby_trxn_core.instr_owner_country%TYPE,
                            instr_postalcode_in                          => NULL,                               --IN     iby_trxn_core.instr_owner_postalcode%TYPE,
                            instr_phonenumber_in                         => NULL,                              --IN    iby_trxn_core.instr_owner_phone%TYPE,
                            instr_email_in                               => NULL,                                    --IN     iby_trxn_core.instr_owner_email%TYPE,
                            pos_reader_cap_in                            => NULL,                                 --IN     iby_trxn_core.pos_reader_capability_code%TYPE,
                            pos_entry_method_in                          => NULL,                               --IN     iby_trxn_core.pos_entry_method_code%TYPE,
                            pos_card_id_method_in                        => NULL,                             --IN   iby_trxn_core.pos_id_method_code%TYPE,
                            pos_auth_source_in                           => NULL,                                --IN     iby_trxn_core.pos_auth_source_code%TYPE,
                            reader_data_in                               => NULL,                                    --IN     iby_trxn_core.reader_data%TYPE,
                            extend_names_in                              => lv_extend_names_in,                     --IN     JTF_VARCHAR2_TABLE_100,
                            extend_vals_in                               => lv_extend_vals_in,                       --      IN     JTF_VARCHAR2_TABLE_200,
                            debit_network_code_in                        => NULL,                             --IN   iby_trxn_core.debit_network_code%TYPE,
                            surcharge_amount_in                          => NULL,                               --IN    iby_trxn_core.surcharge_amount%TYPE,
                            proc_tracenumber_in                          => NULL,                               -- IN    iby_trxn_core.proc_tracenumber%TYPE,
                            transaction_id_out                           => x_transaction_id_out ,               --OUT NOCOPY iby_trxn_summaries_all.TransactionID%TYPE,
                            transaction_mid_out                          => x_transaction_mid_out,              -- OUT NOCOPY iby_trxn_summaries_all.trxnmid%TYPE,
                            org_type_in                                  => 'OPERATING_UNIT',                           --IN      iby_trxn_summaries_all.org_type%TYPE,
                            payment_channel_code_in                      => 'CREDIT_CARD',                  --IN iby_trxn_summaries_all.payment_channel_code%TYPE,
                            factored_flag_in                             => 'N',                                   -- IN iby_trxn_summaries_all.factored_flag%TYPE,
                            process_profile_code_in                      => NULL,                           --    IN iby_trxn_summaries_all.process_profile_code%TYPE,
                            sub_key_id_in                                => NULL,                                     -- IN     iby_trxn_summaries_all.sub_key_id%TYPE,
                            voiceAuthFlag_in                             => 'N',                                   --           IN     iby_trxn_core.voiceauthflag%TYPE,
                            reauth_trxnid_in                             => NULL                                   --IN     iby_trxn_summaries_all.TransactionID%TYPE
    );
    iby_debug_pub.add('After insert_auth_txn',1,G_DEBUG_MODULE || l_module_name);
    iby_debug_pub.add('transaction_id_out '||x_transaction_id_out,1,G_DEBUG_MODULE || l_module_name);
    iby_debug_pub.add('x_transaction_mid_out '||x_transaction_mid_out,1,G_DEBUG_MODULE || l_module_name);
    x_reqresp.Trxn_ID := x_transaction_id_out;
EXCEPTION
WHEN OTHERS THEN
  iby_debug_pub.add('Error in xx_create_iby_summary '|| SQLERRM,1,G_DEBUG_MODULE || l_module_name);
  x_ret_status := 'E';
  x_ret_msg    := 'Error in xx_create_iby_summary '|| SQLERRM;
END xx_create_iby_summary;

  -- +==================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- +===================================================================================+
  -- | Name        : GET_TRANSLATION                                                     |
  -- | Description : copy of standard iby_fndcpt_trxn_pub.create_authorization, modified |
  -- |               for JIRA  NAIT-129669                                               |
  -- |Parameters   : p_translation_name                                                  |
  -- |             : p_source_value1                                                     |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |RAFT 1.0 27-Jun-2020  Divyansh Saini          Initial draft version                |
  -- +===================================================================================+
PROCEDURE Create_Authorization(
    p_api_version   IN NUMBER,
    p_init_msg_list IN VARCHAR2 := FND_API.G_FALSE,
    x_return_status OUT NOCOPY VARCHAR2,
    x_msg_count OUT NOCOPY     NUMBER,
    x_msg_data OUT NOCOPY      VARCHAR2,
    p_payer             IN IBY_FNDCPT_COMMON_PUB.PayerContext_rec_type,
    p_payer_equivalency IN VARCHAR2 := IBY_FNDCPT_COMMON_PUB.G_PAYER_EQUIV_UPWARD,
    p_payee             IN IBY_FNDCPT_TRXN_PUB.PayeeContext_rec_type,
    p_trxn_entity_id    IN NUMBER,
    p_auth_attribs      IN IBY_FNDCPT_TRXN_PUB.AuthAttribs_rec_type,
    p_amount            IN IBY_FNDCPT_TRXN_PUB.Amount_rec_type,
    x_auth_result OUT NOCOPY IBY_FNDCPT_TRXN_PUB.AuthResult_rec_type,
    x_response OUT NOCOPY IBY_FNDCPT_COMMON_PUB.Result_rec_type )
IS
  l_api_version    CONSTANT NUMBER       := 1.0;
  l_module         CONSTANT VARCHAR2(30) := 'Create_Authorization';
  l_prev_msg_count NUMBER;
  l_payer_level    VARCHAR2(30);
  l_payer_id iby_external_payers_all.ext_payer_id%TYPE;
  l_payer_attribs IBY_FNDCPT_SETUP_PUB.PayerAttributes_rec_type;
  l_copy_count NUMBER;
  l_auth_flag iby_trxn_extensions_v.authorized_flag%TYPE;
  l_instr_auth_flag iby_trxn_extensions_v.authorized_flag%TYPE;
  l_single_use iby_fndcpt_payer_assgn_instr_v.card_single_use_flag%TYPE;
  l_ecapp_id NUMBER;
  l_app_short_name fnd_application.application_short_name%TYPE;
  l_order_id iby_fndcpt_tx_extensions.order_id%TYPE;
  l_trxn_ref1 iby_fndcpt_tx_extensions.trxn_ref_number1%TYPE;
  l_trxn_ref2 iby_fndcpt_tx_extensions.trxn_ref_number2%TYPE;
  l_encrypted iby_fndcpt_tx_extensions.encrypted%TYPE;
  l_code_segment_id iby_fndcpt_tx_extensions.instr_code_sec_segment_id%TYPE;
  l_sec_code_len iby_fndcpt_tx_extensions.instr_sec_code_length%TYPE;
  l_payee IBY_PAYMENT_ADAPTER_PUB.Payee_rec_type;
  l_payer IBY_PAYMENT_ADAPTER_PUB.Payer_rec_type;
  l_tangible IBY_PAYMENT_ADAPTER_PUB.Tangible_rec_type;
  l_pmt_instr IBY_PAYMENT_ADAPTER_PUB.PmtInstr_rec_type;
  l_pmt_trxn IBY_PAYMENT_ADAPTER_PUB.PmtReqTrxn_rec_type;
  l_riskinfo IBY_PAYMENT_ADAPTER_PUB.RiskInfo_rec_type;
  l_reqresp IBY_PAYMENT_ADAPTER_PUB.ReqResp_rec_type;
  l_status iby_trxn_summaries_all.status%TYPE;
  l_trxn_id IBY_TRXN_SUMMARIES_ALL.transactionid%TYPE;
  l_auth_result iby_trxn_ext_auths_v.authorization_result_code%TYPE;
  l_pson iby_fndcpt_tx_extensions.payment_system_order_number%TYPE;
  l_return_status VARCHAR2(1);
  l_msg_count     NUMBER;
  l_msg_data      VARCHAR2(300);
  l_fail_msg      VARCHAR2(500);
  l_op_count      NUMBER;
  l_rec_mth_id    NUMBER;
  x_transaction_id_out iby_trxn_summaries_all.TransactionID%TYPE;
  x_transaction_mid_out iby_trxn_summaries_all.trxnmid%TYPE;
  x_ret_status VARCHAR2(500);
  x_ret_msg    VARCHAR2(500);
  l_tmp_segmdnt_id iby_fndcpt_tx_extensions.instr_code_sec_segment_id%TYPE;
  l_ext_not_found BOOLEAN;
  l_dbg_mod       VARCHAR2(100) := G_DEBUG_MODULE || '.' || l_module;
  --15869503
  l_receipt_id ar_cash_receipts_all.cash_receipt_id%type;
  l_receipt_date ar_cash_receipts_all.receipt_date%type;
  l_ps_due_date ar_payment_schedules.due_date%type;
  --19012201 - changing payment_channel_code to instrument_type to allow validations on custom receipt classes.
  l_instr_type iby_fndcpt_pmt_chnnls_b.instrument_type%type;
  -- ISO changes
  l_py_branch_num ce_bank_branches_v.branch_number%TYPE;
  l_py_branch_bic ce_bank_branches_v.eft_swift_code%TYPE;
  l_py_branch_cntry ce_bank_branches_v.bank_home_country%TYPE;
  l_pr_branch_num ce_bank_branches_v.branch_number%TYPE;
  l_pr_branch_bic ce_bank_branches_v.eft_swift_code%TYPE;
  l_pr_branch_cntry ce_bank_branches_v.bank_home_country%TYPE;
  l_int_bank_acct_id ce_bank_acct_uses_ou_v.bank_account_id%TYPE;
  l_debit_auth_id iby_fndcpt_tx_extensions.debit_authorization_id%TYPE;
  CURSOR c_extension (ci_extension_id IN iby_fndcpt_tx_extensions.trxn_extension_id%TYPE, ci_payer IN IBY_FNDCPT_COMMON_PUB.PayerContext_rec_type, ci_payer_level IN VARCHAR2, ci_payer_equiv IN VARCHAR2 )
  IS
    SELECT NVL(i.instrument_type,pc.instrument_type),
      NVL(i.instrument_id,0),
      x.origin_application_id,
      a.application_short_name,
      x.order_id,
      x.trxn_ref_number1,
      x.trxn_ref_number2,
      x.instrument_security_code,
      x.instr_code_sec_segment_id,
      x.instr_sec_code_length,
      x.encrypted,
      x.po_number,
      x.voice_authorization_flag,
      x.voice_authorization_code,
      x.voice_authorization_date,
      i.card_single_use_flag,
      NVL(x.instr_assignment_id,0),
      x.payment_channel_code
    FROM iby_fndcpt_tx_extensions x,
      iby_fndcpt_payer_assgn_instr_v i,
      iby_external_payers_all p,
      fnd_application a,
      iby_fndcpt_pmt_chnnls_b pc
    WHERE (x.instr_assignment_id = i.instr_assignment_id(+))
    AND (x.payment_channel_code  = pc.payment_channel_code)
    AND (x.origin_application_id = a.application_id)
      -- can assume this assignment is for funds capture
    AND (x.ext_payer_id                                                                                                                                                                                                        = p.ext_payer_id)
    AND (x.trxn_extension_id                                                                                                                                                                                                   = ci_extension_id)
    AND (p.party_id                                                                                                                                                                                                            = ci_payer.Party_Id)
    AND (IBY_FNDCPT_COMMON_PUB.Compare_Payer (ci_payer.org_type, ci_payer.org_id, ci_payer.Cust_Account_Id, ci_payer.Account_Site_Id, ci_payer_level,ci_payer_equiv,p.org_type,p.org_id, p.cust_account_id,p.acct_site_use_id) = 'T');
  /*CURSOR c_auth
  (ci_extension_id IN iby_fndcpt_tx_extensions.trxn_extension_id%TYPE)
  IS
  SELECT authorized_flag
  FROM iby_trxn_extensions_v
  WHERE (trxn_extension_id = ci_extension_id); */
  --Bug# 16353469
  --Changed the cursor query to get the auth status from the base tables.
  CURSOR c_auth (ci_extension_id IN iby_fndcpt_tx_extensions.trxn_extension_id%TYPE)
  IS
    SELECT a.transactionid,
      DECODE(a.status, 0, 'AUTH_SUCCESS', 1, 'COMMUNICATION_ERROR', 2, 'DUPLICATE_AUTH', 4, 'GENERAL_INVALID_PARAM', 5, 'PAYMENT_SYS_REJECT', 11, 'AUTH_PENDING', 12, 'AUTH_PENDING', 13, 'AUTH_PENDING', 16, 'PAYMENT_SYS_REJECT', 17, 'PAYMENT_SYS_REJECT', 18, 'AUTH_PENDING', 19, 'GENERAL_INVALID_PARAM', 20, 'PAYMENT_SYS_REJECT', 100, 'AUTH_PENDING', 101, 'COMMUNICATION_ERROR', 111, 'AUTH_PENDING', 22, 'FULLY_REVERSED', 23, 'PARTIALLY_REVERSED', 'GENERAL_SYS_ERROR') auth_result_code,
      x.payment_system_order_number
    FROM IBY_FNDCPT_TX_EXTENSIONS X,
      IBY_FNDCPT_TX_OPERATIONS O,
      IBY_TRXN_SUMMARIES_ALL A,
      IBY_TRXN_CORE C
    WHERE x.trxn_extension_id = ci_extension_id
    AND (x.trxn_extension_id  = o.trxn_extension_id)
    AND (o.transactionid      = a.transactionid)
    AND (a.trxnmid            = c.trxnmid(+))
    AND (a.reqtype            = 'ORAPMTREQ')
    AND (a.trxntypeid        IN (2,3,20))
    ORDER BY a.trxnmid DESC;
  CURSOR c_instr_extensions (ci_instr_type IN iby_trxn_extensions_v.instrument_type%TYPE, ci_instr_id IN iby_trxn_extensions_v.instrument_id%TYPE, ci_trxn_x_id IN iby_trxn_extensions_v.trxn_extension_id%TYPE )
  IS
    SELECT NVL(authorized_flag,'N')
    FROM iby_trxn_extensions_v
    WHERE (instrument_id    = ci_instr_id)
    AND (instrument_type    = ci_instr_type)
    AND (trxn_extension_id <> ci_trxn_x_id);
  CURSOR c_operation_count (ci_trxn_extension_id IN iby_fndcpt_tx_extensions.trxn_extension_id%TYPE, ci_trxn_id IN iby_trxn_summaries_all.transactionid%TYPE)
  IS
    SELECT COUNT(1)
    FROM iby_fndcpt_tx_operations o
    WHERE o.transactionid   = ci_trxn_id
    AND o.trxn_extension_id = ci_trxn_extension_id;
  CURSOR c_source_extns ( ci_trxn_extension_id IN iby_fndcpt_tx_extensions.trxn_extension_id%TYPE )
  IS
    SELECT cp.source_trxn_extension_id,
      ex.instr_code_sec_segment_id,
      ex.instrument_security_code
    FROM iby_fndcpt_tx_xe_copies cp,
      iby_fndcpt_tx_extensions ex
    WHERE cp.source_trxn_extension_id           = ex.trxn_extension_id
      START WITH cp.copy_trxn_extension_id      = ci_trxn_extension_id
      CONNECT BY PRIOR source_trxn_extension_id = copy_trxn_extension_id;
BEGIN
  IF( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('Enter',G_LEVEL_PROCEDURE,l_module);
  END IF;
  IF (c_extension%ISOPEN) THEN
    CLOSE c_extension;
  END IF;
  IF (c_auth%ISOPEN) THEN
    CLOSE c_auth;
  END IF;
  IF (c_instr_extensions%ISOPEN) THEN
    CLOSE c_instr_extensions;
  END IF;
  IF (c_operation_count%ISOPEN) THEN
    CLOSE c_operation_count;
  END IF;
  IF NOT FND_API.Compatible_API_Call (l_api_version, p_api_version, l_module, G_PKG_NAME) THEN
    IF( G_LEVEL_ERROR >= G_CURRENT_RUNTIME_LEVEL) THEN
      iby_debug_pub.add(debug_msg => 'Incorrect API Version:=' || p_api_version, debug_level => G_LEVEL_ERROR, module => G_DEBUG_MODULE || l_module);
    END IF;
    FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;
  IF FND_API.to_Boolean( p_init_msg_list ) THEN
    FND_MSG_PUB.initialize;
  END IF;
  l_prev_msg_count      := FND_MSG_PUB.Count_Msg;
  IF( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('checking payer context',G_LEVEL_STATEMENT,l_dbg_mod);
    iby_debug_pub.add('party id =' || p_payer.Party_Id,iby_debug_pub.G_LEVEL_INFO,l_dbg_mod);
    iby_debug_pub.add('account id =' || p_payer.Cust_Account_Id,iby_debug_pub.G_LEVEL_INFO,l_dbg_mod);
    iby_debug_pub.add('account site use id =' || p_payer.Account_Site_Id,iby_debug_pub.G_LEVEL_INFO,l_dbg_mod);
    iby_debug_pub.add('org id =' || p_payer.Org_Id,iby_debug_pub.G_LEVEL_INFO,l_dbg_mod);
    iby_debug_pub.add('org type =' || p_payer.Org_Type,iby_debug_pub.G_LEVEL_INFO,l_dbg_mod);
  END IF;
  IBY_FNDCPT_SETUP_PUB.Get_Payer_Id(p_payer,FND_API.G_VALID_LEVEL_FULL, l_payer_level,l_payer_id,l_payer_attribs);
  iby_debug_pub.add('l_payer_level: '|| l_payer_level,G_LEVEL_STATEMENT,l_dbg_mod);
  iby_debug_pub.add('l_payer_id: '|| l_payer_id,G_LEVEL_STATEMENT,l_dbg_mod);
  IF (l_payer_level         = IBY_FNDCPT_COMMON_PUB.G_RC_INVALID_PAYER) THEN
    x_response.Result_Code := IBY_FNDCPT_COMMON_PUB.G_RC_INVALID_PAYER;
  ELSE
    -- verify transaction entity is for a payer equivalent to the
    -- given one
    OPEN c_extension(p_trxn_entity_id,p_payer,l_payer_level,p_payer_equivalency);
    FETCH c_extension
    INTO l_pmt_instr.PmtInstr_Type,
      l_pmt_instr.PmtInstr_Id,
      l_ecapp_id,
      l_app_short_name,
      l_order_id,
      l_trxn_ref1,
      l_trxn_ref2,
      l_pmt_trxn.CVV2,
      l_code_segment_id,
      l_sec_code_len,
      l_encrypted,
      l_pmt_trxn.PONum,
      l_pmt_trxn.VoiceAuthFlag,
      l_pmt_trxn.AuthCode,
      l_pmt_trxn.DateOfVoiceAuthorization,
      l_single_use,
      l_pmt_instr.Pmtinstr_assignment_id,
      l_pmt_trxn.payment_channel_code;
    l_ext_not_found := c_extension%NOTFOUND;
    CLOSE c_extension;
    iby_debug_pub.add('p_trxn_entity_id: '|| p_trxn_entity_id,G_LEVEL_STATEMENT,l_dbg_mod);
    iby_debug_pub.add('p_payer_equivalency: '|| p_payer_equivalency,G_LEVEL_STATEMENT,l_dbg_mod);
    IF( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      iby_debug_pub.add('channel code:=' || l_pmt_trxn.payment_channel_code, G_LEVEL_STATEMENT,l_dbg_mod);
      iby_debug_pub.add('instrument type:=' || l_pmt_instr.pmtinstr_type, G_LEVEL_STATEMENT,l_dbg_mod);
    END IF;
    IF (NOT l_ext_not_found) THEN
      -- map the records
      l_payee.Payee_Id := Get_Internal_Payee(p_payee);
      -- create on the fly??
      l_payer.Party_Id         := p_payer.Party_Id;
      l_copy_count             := Get_Tx_Extension_Copy_Count(p_trxn_entity_id);
      IF (l_payee.Payee_Id     IS NULL) THEN
        x_response.Result_Code := G_RC_INVALID_PAYEE;
        iby_fndcpt_common_pub.Prepare_Result (l_prev_msg_count,x_return_status,x_msg_count,x_msg_data,x_response);
        RETURN;
        -- cannot do operations on a trxn entity already copied
      ELSIF (l_copy_count  >0) THEN
        IF( G_LEVEL_ERROR >= G_CURRENT_RUNTIME_LEVEL) THEN
          iby_debug_pub.add('extension has been copied ' || l_copy_count || ' times; cannot auth',G_LEVEL_ERROR,l_dbg_mod);
        END IF;
        x_response.Result_Code := G_RC_EXTENSION_IMMUTABLE;
        iby_fndcpt_common_pub.Prepare_Result (l_prev_msg_count,x_return_status,x_msg_count,x_msg_data,x_response);
        RETURN;
      END IF;
      --Changing the function here to generate new tangible_id
      l_tangible.Tangible_Id := Get_Tangible_Id(l_app_short_name,p_trxn_entity_id);
      --l_tangible.Tangible_Id :=
      --  Get_Tangible_Id(l_app_short_name,l_order_id,l_trxn_ref1,l_trxn_ref2);
--      IF (l_pmt_instr.PmtInstr_Type = IBY_FNDCPT_COMMON_PUB.G_INSTR_TYPE_BANKACCT) THEN
--        l_pmt_trxn.Auth_Type       := IBY_PAYMENT_ADAPTER_PUB.G_AUTHTYPE_VERIFY;
--      ELSE
      l_pmt_trxn.Auth_Type             := IBY_PAYMENT_ADAPTER_PUB.G_AUTHTYPE_AUTHONLY;
      l_tangible.Tangible_Amount       := p_amount.Value;
      l_tangible.Currency_Code         := p_amount.Currency_Code;
      l_tangible.Memo                  := p_auth_attribs.Memo;
      l_tangible.OrderMedium           := p_auth_attribs.Order_Medium;
      l_pmt_trxn.Org_Id                := p_payee.Org_Id;
      l_pmt_trxn.Int_Bank_Country_Code := p_payee.Int_Bank_Country_Code;
      l_pmt_trxn.TaxAmount             := p_auth_attribs.Tax_Amount.Value;
      l_pmt_trxn.ShipFromZip           := p_auth_attribs.ShipFrom_PostalCode;
      l_pmt_trxn.ShipToZip             := p_auth_attribs.ShipTo_PostalCode;
      l_pmt_trxn.Payment_Factor_Flag   := p_auth_attribs.Payment_Factor_Flag;
      --Added pmt trxn extension irrespective of encryption for mandate validation.
      --15869503
      l_pmt_trxn.Trxn_Extension_Id := p_trxn_entity_id;
      IF( G_LEVEL_ERROR            >= G_CURRENT_RUNTIME_LEVEL) THEN
        iby_debug_pub.add(' l_pmt_trxn.Trxn_Extension_Id: ' || l_pmt_trxn.Trxn_Extension_Id,G_LEVEL_ERROR,l_dbg_mod);
      END IF;
      --ISO - Fetching Debit Auth Id for SPEA Active Mandate Validation.
      BEGIN
        SELECT debit_authorization_id
        INTO l_debit_auth_id
        FROM iby_fndcpt_tx_extensions
        WHERE trxn_extension_id = p_trxn_entity_id;
      EXCEPTION
      WHEN OTHERS THEN
        IF( G_LEVEL_ERROR >= G_CURRENT_RUNTIME_LEVEL) THEN
          iby_debug_pub.add('No debit auth on extension', G_LEVEL_ERROR,l_dbg_mod);
        END IF;
        l_debit_auth_id := NULL;
      END;
      IF( G_LEVEL_ERROR >= G_CURRENT_RUNTIME_LEVEL) THEN
        iby_debug_pub.add(' Debit Auth On Extension: ' || l_debit_auth_id,G_LEVEL_ERROR,l_dbg_mod);
      END IF;
      -- ciphertext; get clear-text value in the engine
      IF (l_encrypted    = 'Y') THEN
        l_pmt_trxn.CVV2 := NULL;
        -- l_pmt_trxn.Trxn_Extension_Id := p_trxn_entity_id;
        l_pmt_trxn.CVV2_Segment_id := l_code_segment_id;
        l_pmt_trxn.CVV2_Length     := l_sec_code_len;
      END IF;
      -- cannot use a single use instrument which already has
      -- an authorization
      IF (l_single_use = 'Y') THEN
        OPEN c_instr_extensions(l_pmt_instr.PmtInstr_Type, l_pmt_instr.PmtInstr_Id, p_trxn_entity_id);
        FETCH c_instr_extensions INTO l_instr_auth_flag;
        CLOSE c_instr_extensions;
        IF (NVL(l_instr_auth_flag,'N') = 'Y') THEN
          IF( G_LEVEL_ERROR           >= G_CURRENT_RUNTIME_LEVEL) THEN
            iby_debug_pub.add('single use instrument cannot be reused',G_LEVEL_ERROR,l_dbg_mod);
          END IF;
          x_response.Result_Code := IBY_FNDCPT_SETUP_PUB.G_RC_INVALID_INSTRUMENT;
          iby_fndcpt_common_pub.Prepare_Result (l_prev_msg_count,x_return_status,x_msg_count,x_msg_data,x_response);
          RETURN;
        END IF;
      END IF;
      --Bug# 16353469 (Begin)
      --If the result code is fully reversed then re-generate the tangibleid for Re-auth
      OPEN c_auth(p_trxn_entity_id);
      FETCH c_auth INTO l_trxn_id, l_auth_result, l_pson;
      IF( G_LEVEL_ERROR >= G_CURRENT_RUNTIME_LEVEL) THEN
        iby_debug_pub.add('p_trxn_entity_id:' || p_trxn_entity_id,G_LEVEL_ERROR,l_dbg_mod);
        iby_debug_pub.add('l_trxn_id:' || l_trxn_id,G_LEVEL_ERROR,l_dbg_mod);
        iby_debug_pub.add('l_auth_result:'||l_auth_result,G_LEVEL_ERROR,l_dbg_mod);
        iby_debug_pub.add('l_pson:' || l_pson,G_LEVEL_ERROR,l_dbg_mod);
      END IF;
      IF (l_auth_result IN ('AUTH_SUCCESS', 'AUTH_PENDING')) THEN
        IF( G_LEVEL_ERROR >= G_CURRENT_RUNTIME_LEVEL) THEN
          iby_debug_pub.add('Extension already authorized',G_LEVEL_ERROR,l_dbg_mod);
        END IF;
        x_response.Result_Code := G_RC_DUPLICATE_AUTHORIZATION;
      ELSE
        IF(l_auth_result          = 'FULLY_REVERSED') THEN
          l_tangible.Tangible_Id := Get_Reauth_Tangible_Id(l_app_short_name,p_trxn_entity_id);
          IF( G_LEVEL_ERROR      >= G_CURRENT_RUNTIME_LEVEL) THEN
            iby_debug_pub.add('Re-auth Tangible_Id:' || l_tangible.Tangible_Id,G_LEVEL_ERROR,l_dbg_mod);
          END IF;
          l_pmt_trxn.Trxn_ID := l_trxn_id;
        ELSE
          l_tangible.Tangible_Id := NVL(l_pson, get_tangible_id(l_app_short_name,p_trxn_entity_id));
          IF( G_LEVEL_ERROR      >= G_CURRENT_RUNTIME_LEVEL) THEN
            iby_debug_pub.add('Other than full reversal case:' || l_tangible.Tangible_Id,G_LEVEL_ERROR,l_dbg_mod);
          END IF;
        END IF;
        --Bug# 16353469 (End)
        --20222709 - to make sure that the risk setup at the payee level takes precedence over the transaction level attribute
        IF (p_auth_attribs.RiskEval_Enable_Flag    = 'Y') THEN
          l_pmt_trxn.AnalyzeRisk                  := 'TRUE';
        ElSIF (p_auth_attribs.RiskEval_Enable_Flag = 'N') THEN
          l_pmt_trxn.AnalyzeRisk                  := 'FALSE';
        ELSE
          l_pmt_trxn.AnalyzeRisk := 'NEUTRAL';
        END IF;
        --  Bug# 7707005. PAYEE ROUTING RULES BASED ON RECEIPT METHOD QUALIFIER ARE NOT WORKING.
        l_rec_mth_id     := p_auth_attribs.Receipt_Method_Id;
        IF (l_rec_mth_id IS NULL) THEN
          BEGIN
            IF( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              iby_debug_pub.add('fetching the rec method id from AR',G_LEVEL_STATEMENT,l_dbg_mod);
            END IF;
            SELECT RECEIPT_METHOD_ID
            INTO l_rec_mth_id
            FROM ar_cash_receipts_all
            WHERE payment_trxn_extension_id = p_trxn_entity_id;
            IF( G_LEVEL_STATEMENT          >= G_CURRENT_RUNTIME_LEVEL) THEN
              iby_debug_pub.add('fetched method id '||l_rec_mth_id ,G_LEVEL_STATEMENT,l_dbg_mod);
            END IF;
          EXCEPTION
          WHEN OTHERS THEN
            l_rec_mth_id := NULL;
          END;
        END IF;
        -- After fetching the receipt method id,populating in p_pmtreqtrxn_rec and sending in orapmtreq
        l_pmt_trxn.Receipt_Method_Id := l_rec_mth_id;
        --19012201 - using intrument_type instaed of payment_channel_code
        BEGIN
          SELECT instrument_type
          INTO l_instr_type
          FROM iby_fndcpt_pmt_chnnls_b
          WHERE payment_channel_code IN
            (SELECT payment_channel_code
            FROM ar_receipt_methods
            WHERE receipt_method_id =l_rec_mth_id
            );
        EXCEPTION
        WHEN OTHERS THEN
          IF( G_LEVEL_ERROR >= G_CURRENT_RUNTIME_LEVEL) THEN
            iby_debug_pub.add('Instr type not found', G_LEVEL_ERROR,l_dbg_mod);
          END IF;
          l_instr_type := NULL;
        END;
        IF( G_LEVEL_ERROR >= G_CURRENT_RUNTIME_LEVEL) THEN
          iby_debug_pub.add('Instr Tpye:' ||l_instr_type , G_LEVEL_ERROR,l_dbg_mod);
        END IF;
        l_pmt_trxn.Pmt_Schedule_Date := l_ps_due_date;
        l_pmt_trxn.Receipt_Date      := l_receipt_date; --15869503
        --ISO:
        l_pmt_trxn.Debit_Auth_Id := l_debit_auth_id;
        -- ISO changes: sending the payer attributes to OraPmtReq l_payer_attribs
        l_pmt_trxn.LocalInstr        := l_payer_attribs.LocalInstr;
        l_pmt_trxn.Service_Level     := l_payer_attribs.Service_Level;
        l_pmt_trxn.Purpose_Code      := l_payer_attribs.Purpose_Code;
        IF( G_LEVEL_STATEMENT      >= G_CURRENT_RUNTIME_LEVEL) THEN
          iby_debug_pub.add('LocalInstr: ' || l_pmt_trxn.LocalInstr ,G_LEVEL_STATEMENT,l_dbg_mod);
          iby_debug_pub.add('Service_Level: ' || l_pmt_trxn.Service_Level,G_LEVEL_STATEMENT,l_dbg_mod);
          iby_debug_pub.add('Purpose_Code: ' || l_pmt_trxn.Purpose_Code,G_LEVEL_STATEMENT,l_dbg_mod);
          -- payer branch details
          iby_debug_pub.add('l_pr_branch_num: ' || l_pr_branch_num,G_LEVEL_STATEMENT,l_dbg_mod);
          iby_debug_pub.add('l_pr_branch_bic: ' || l_pr_branch_bic,G_LEVEL_STATEMENT,l_dbg_mod);
          iby_debug_pub.add('l_pr_branch_cntry: ' || l_pr_branch_cntry,G_LEVEL_STATEMENT,l_dbg_mod);
          -- payee branch details
          iby_debug_pub.add('l_py_branch_num: ' || l_py_branch_num,G_LEVEL_STATEMENT,l_dbg_mod);
          iby_debug_pub.add('l_py_branch_bic: ' || l_py_branch_bic,G_LEVEL_STATEMENT,l_dbg_mod);
          iby_debug_pub.add('l_py_branch_cntry: ' || l_py_branch_cntry,G_LEVEL_STATEMENT,l_dbg_mod);
          iby_debug_pub.add('send auth',G_LEVEL_STATEMENT,l_dbg_mod);
        END IF;
        /*IBY_PAYMENT_ADAPTER_PUB.OraPmtReq
        (1.0,
        p_init_msg_list,
        FND_API.G_FALSE,
        FND_API.G_VALID_LEVEL_FULL,
        l_ecapp_id,
        l_payee,
        l_payer,
        l_pmt_instr,
        l_tangible,
        l_pmt_trxn,
        l_return_status,
        l_msg_count,
        l_msg_data,
        l_reqresp
        );*/
        iby_debug_pub.add('p_trxn_entity_id '||p_trxn_entity_id,G_LEVEL_STATEMENT,l_dbg_mod);
        -- Calling changes for NAIT-129669
        xx_create_iby_summary ( p_trxn_entity_id ,
                                x_transaction_id_out ,
                                x_transaction_mid_out ,
                                x_ret_status ,
                                x_ret_msg ,
                                l_reqresp);
        iby_debug_pub.add('x_transaction_id_out '||x_transaction_id_out,G_LEVEL_STATEMENT,l_dbg_mod);
        iby_debug_pub.add('x_transaction_mid_out '||x_transaction_mid_out,G_LEVEL_STATEMENT,l_dbg_mod);
        iby_debug_pub.add('x_ret_status '||x_ret_status,G_LEVEL_STATEMENT,l_dbg_mod);
        iby_debug_pub.add('x_ret_msg '||x_ret_msg,G_LEVEL_STATEMENT,l_dbg_mod);
        IF( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          iby_debug_pub.add('status :=' || l_return_status, G_LEVEL_STATEMENT,l_dbg_mod);
          iby_debug_pub.add('auth status :=' || TO_CHAR(l_reqresp.Response.Status), G_LEVEL_STATEMENT,l_dbg_mod);
          iby_debug_pub.add('auth engine code :=' || TO_CHAR(l_reqresp.Response.ErrCode), G_LEVEL_STATEMENT,l_dbg_mod);
          iby_debug_pub.add('auth engine msg :=' || TO_CHAR(l_reqresp.Response.ErrMessage), G_LEVEL_STATEMENT,l_dbg_mod);
          iby_debug_pub.add('payment system code :=' || TO_CHAR(l_reqresp.BEPErrCode), G_LEVEL_STATEMENT,l_dbg_mod);
          iby_debug_pub.add('payment system msg :=' || TO_CHAR(l_reqresp.BEPErrMessage), G_LEVEL_STATEMENT,l_dbg_mod);
          iby_debug_pub.add('trxn id :=' || TO_CHAR(l_reqresp.Trxn_ID), G_LEVEL_STATEMENT,l_dbg_mod);
        END IF;
        --20487559 - 20222709
        IF (NVL(p_auth_attribs.RiskEval_Enable_Flag,'Y') = 'Y') THEN
          x_auth_result.Risk_Result.Risk_Score          := l_reqresp.RiskResponse.Risk_Score;
          x_auth_result.Risk_Result.Risk_Threshold_Val  := l_reqresp.RiskResponse.Risk_Threshold_Val;
          IF (l_reqresp.RiskResponse.Risky_Flag          = 'YES') THEN
            x_auth_result.Risk_Result.Risky_Flag        := 'Y';
          ELSE
            x_auth_result.Risk_Result.Risky_Flag := 'N';
          END IF;
        END IF;
        -- consume the security code
        UPDATE iby_fndcpt_tx_extensions
        SET instrument_security_code = NULL,
          --instr_sec_code_length = NULL,
          ENCRYPTED             = 'N',
          last_updated_by       = fnd_global.user_id,
          last_update_date      = SYSDATE,
          last_update_login     = fnd_global.login_id,
          object_version_number = object_version_number + 1
        WHERE trxn_extension_id = p_trxn_entity_id;
        UPDATE iby_fndcpt_tx_extensions
        SET instrument_security_code = NULL,
          --instr_sec_code_length = NULL,
          ENCRYPTED              = 'N',
          last_updated_by        = fnd_global.user_id,
          last_update_date       = SYSDATE,
          last_update_login      = fnd_global.login_id,
          object_version_number  = object_version_number + 1
        WHERE trxn_extension_id                         IN
          (SELECT source_trxn_extension_id
          FROM iby_fndcpt_tx_xe_copies
            START WITH copy_trxn_extension_id         = p_trxn_entity_id
            CONNECT BY PRIOR source_trxn_extension_id = copy_trxn_extension_id
          );
        IF( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          iby_debug_pub.add('No. of source extensions updated= :'||SQL%ROWCOUNT, G_LEVEL_STATEMENT,l_dbg_mod);
        END IF;
        -- As per PABP guidelines, the cvv value should be consumed
        -- securely. i.e, first update with a random value, do a commit
        -- then update with null and issue another commit.
        -- This is handled through the below procedure call.
        IF (l_code_segment_id   IS NOT NULL) THEN
          IF( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            iby_debug_pub.add('Call to Securely_Wipe_Segment.', G_LEVEL_STATEMENT,l_dbg_mod);
          END IF;
          Secure_Wipe_Segment(l_code_segment_id);
          FOR extn_rec IN c_source_extns(p_trxn_entity_id)
          LOOP
            Secure_Wipe_Segment(extn_rec.instr_code_sec_segment_id);
          END LOOP;
        END IF;
        IF (NOT l_reqresp.Trxn_Id IS NULL) THEN
          -- populate the dirdeb_instruction_code column
          -- for settlement
          BEGIN
            IBY_FNDCPT_SETUP_PUB.Get_Trxn_Payer_Attributes(p_payer,p_payer_equivalency, l_payer_attribs);
            UPDATE iby_trxn_summaries_all
            SET dirdeb_instruction_code = l_payer_attribs.DirectDebit_BankInstruction
            WHERE transactionid         = l_reqresp.Trxn_Id;
            IF( G_LEVEL_STATEMENT      >= G_CURRENT_RUNTIME_LEVEL) THEN
              iby_debug_pub.add('Set DirectDebit_BankInstruction for trxn', G_LEVEL_STATEMENT,l_dbg_mod);
            END IF;
          EXCEPTION
          WHEN OTHERS THEN
            IF( G_LEVEL_EXCEPTION >= G_CURRENT_RUNTIME_LEVEL) THEN
              iby_debug_pub.add('Unable to retrieve/set payer attribs for trxn', G_LEVEL_EXCEPTION,l_dbg_mod);
            END IF;
          END;
          -- Fix for bug# 7377455. Stamp the tangibleid on the PSON column of
          -- IBY_FNDCPT_TX_EXTENSIONS table
          IF( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            iby_debug_pub.add( 'Stamping the PSON on the extension as '|| l_tangible.Tangible_Id, G_LEVEL_STATEMENT,l_dbg_mod);
          END IF;
          UPDATE iby_fndcpt_tx_extensions
          SET payment_system_order_number = l_tangible.Tangible_Id
          WHERE trxn_extension_id         = p_trxn_entity_id;
          -- Fix for bug# 7530578. Stamp the initiator transaction extension id
          -- on the corresponding record in iby_trxn_summaries_all
          IF( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            iby_debug_pub.add( 'Stamping '||p_trxn_entity_id ||' as the initiator_extension_id' ||'on the auth record', G_LEVEL_STATEMENT,l_dbg_mod);
          END IF;
          UPDATE iby_trxn_summaries_all
          SET initiator_extension_id = p_trxn_entity_id
          WHERE transactionid        = l_reqresp.Trxn_Id
          AND reqtype                = 'ORAPMTREQ';
          IF( G_LEVEL_STATEMENT     >= G_CURRENT_RUNTIME_LEVEL) THEN
            iby_debug_pub.add('creating extension operation record for=' || p_trxn_entity_id,G_LEVEL_STATEMENT,l_dbg_mod);
          END IF;
          -- check to see if the operation is already recorded
          OPEN c_operation_count(p_trxn_entity_id,l_reqresp.Trxn_Id);
          FETCH c_operation_count INTO l_op_count;
          CLOSE c_operation_count;
          l_op_count              := NVL(l_op_count,0);
          IF ( l_op_count          > 0 ) THEN
            IF( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              iby_debug_pub.add( 'operation already recorded',G_LEVEL_STATEMENT,l_dbg_mod);
            END IF;
          ELSE
            INSERT
            INTO iby_fndcpt_tx_operations
              (
                trxn_extension_id,
                transactionid,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                object_version_number
              )
              VALUES
              (
                p_trxn_entity_id,
                l_reqresp.Trxn_Id,
                fnd_global.user_id,
                SYSDATE,
                fnd_global.user_id,
                SYSDATE,
                fnd_global.login_id,
                1
              );
            --
            -- back-propagate the authorization
            --
            INSERT
            INTO iby_fndcpt_tx_operations
              (
                trxn_extension_id,
                transactionid,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                object_version_number
              )
            SELECT source_trxn_extension_id,
              l_reqresp.Trxn_Id,
              fnd_global.user_id,
              SYSDATE,
              fnd_global.user_id,
              SYSDATE,
              fnd_global.login_id,
              1
            FROM iby_fndcpt_tx_xe_copies
              START WITH copy_trxn_extension_id         = p_trxn_entity_id
              CONNECT BY PRIOR source_trxn_extension_id = copy_trxn_extension_id;
            IF( G_LEVEL_STATEMENT                      >= G_CURRENT_RUNTIME_LEVEL) THEN
              iby_debug_pub.add('back-propogated rows:='||SQL%ROWCOUNT,G_LEVEL_STATEMENT,l_dbg_mod);
            END IF;
            --
            -- forward propogate the authorization
            --
            INSERT
            INTO iby_fndcpt_tx_operations
              (
                trxn_extension_id,
                transactionid,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                object_version_number
              )
            SELECT copy_trxn_extension_id,
              l_reqresp.Trxn_Id,
              fnd_global.user_id,
              SYSDATE,
              fnd_global.user_id,
              SYSDATE,
              fnd_global.login_id,
              1
            FROM iby_fndcpt_tx_xe_copies
              START WITH source_trxn_extension_id = p_trxn_entity_id
              CONNECT BY source_trxn_extension_id = PRIOR copy_trxn_extension_id;
            IF( G_LEVEL_STATEMENT                >= G_CURRENT_RUNTIME_LEVEL) THEN
              iby_debug_pub.add('forward-propogated rows:='||SQL%ROWCOUNT,G_LEVEL_STATEMENT,l_dbg_mod);
            END IF;
          END IF;
          x_auth_result.Auth_Id             := l_reqresp.Trxn_Id;
          x_auth_result.Auth_Date           := l_reqresp.Trxn_Date;
          x_auth_result.Auth_Code           := l_reqresp.Authcode;
          x_auth_result.AVS_Code            := l_reqresp.AVSCode;
          x_auth_result.Instr_SecCode_Check := l_reqresp.CVV2Result;
          x_auth_result.PaymentSys_Code     := l_reqresp.BEPErrCode;
          x_auth_result.PaymentSys_Msg      := l_reqresp.BEPErrMessage;
          --x_auth_result.Risk_Result;
        END IF;
        --COMMIT;
        IF (l_reqresp.Response.Status = 0) THEN
          x_response.Result_Code     := G_RC_AUTH_SUCCESS;
          /* Bug 11903662*/
          IF (l_single_use         = 'Y') THEN
            IF( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              iby_debug_pub.add('Single Use Flag is True for the Credit Card Updating Marking Active Flag to N',G_LEVEL_STATEMENT,l_dbg_mod);
            END IF;
            UPDATE iby_creditcard
            SET active_flag = 'N'
            WHERE instrid   = l_pmt_instr.PmtInstr_Id;
          END IF;
        ELSE
          --x_response.Result_Code := IBY_FNDCPT_COMMON_PUB.G_RC_GENERIC_SYS_ERROR);
          -- check if the result code is seeded in the result definitions
          -- table
          --
          IF (IBY_FNDCPT_COMMON_PUB.Get_Result_Category(x_response.Result_Code,iby_payment_adapter_pub.G_INTERFACE_CODE) IS NULL) THEN
            x_response.Result_Code                                                                                       := 'COMMUNICATION_ERROR';
            --IBY_FNDCPT_COMMON_PUB.G_RC_GENERIC_SYS_ERROR;
          END IF;
          --Start of Bug:10240644.
          IF ( (NOT l_reqresp.BEPErrMessage IS NULL) AND (NOT l_reqresp.BEPErrCode IS NULL) ) THEN
            --Changing Error Message that is displayed
            --This conveys more appropriate than generic msg
            --displayed previously.
            l_reqresp.Response.ErrMessage := l_reqresp.BEPErrMessage || ' (' || l_reqresp.BEPErrCode || ')';
            iby_debug_pub.add('Response Message from BEPErrMessage: '||l_reqresp.Response.ErrMessage,G_LEVEL_STATEMENT,l_dbg_mod);
          ELSIF( (NOT l_reqresp.Response.ErrMessage IS NULL) OR (NOT l_reqresp.Response.ErrCode IS NULL) ) THEN
            --UnCommenting this for Bug: 10240644
            l_reqresp.Response.ErrMessage := l_reqresp.Response.ErrMessage || ' (' || l_reqresp.Response.ErrCode || ')';
            iby_debug_pub.add('Response Message from engine: '||l_reqresp.Response.ErrMessage,G_LEVEL_STATEMENT,l_dbg_mod);
            --End of Bug:10240644.
          ELSE
            l_reqresp.Response.ErrMessage := FND_MSG_PUB.Get(p_msg_index => x_msg_count, p_encoded => FND_API.G_FALSE) || ' (' || FND_MSG_PUB.Get(p_msg_index => x_msg_count, p_encoded => FND_API.G_TRUE) || ')';
            l_reqresp.Response.ErrCode    := FND_MSG_PUB.Get(p_msg_index => x_msg_count, p_encoded => FND_API.G_TRUE);
            iby_debug_pub.add('Response Message from FND Stack: '||l_reqresp.Response.ErrMessage,G_LEVEL_STATEMENT,l_dbg_mod);
          END IF;
          iby_fndcpt_common_pub.Prepare_Result( iby_payment_adapter_pub.G_INTERFACE_CODE, l_reqresp.Response.ErrMessage, l_prev_msg_count, x_return_status, x_msg_count, x_msg_data, x_response );
          --Commenting this for Bug: 9380078
          -- Need to pass the bepmessages to the source products.
          -- x_response.Result_Code := 'COMMUNICATION_ERROR';
          iby_debug_pub.add('*** assigning messages to the response object', G_LEVEL_STATEMENT,l_dbg_mod);
          x_response.Result_Code     := SUBSTR(TO_CHAR(l_reqresp.Response.ErrCode),0,30);
          x_response.Result_Category := SUBSTR(l_reqresp.BEPErrMessage,0,30);
          x_response.Result_Message  := TO_CHAR(l_reqresp.Response.ErrMessage);
          iby_debug_pub.add('x_response.Result_Code  :=' || x_response.Result_Code , G_LEVEL_STATEMENT,l_dbg_mod);
          iby_debug_pub.add('x_response.Result_Category :=' || x_response.Result_Category, G_LEVEL_STATEMENT,l_dbg_mod);
          iby_debug_pub.add('x_response.Result_Message :=' || x_response.Result_Message, G_LEVEL_STATEMENT,l_dbg_mod);
          iby_debug_pub.add('*** assigned messages to the response object', G_LEVEL_STATEMENT,l_dbg_mod);
          RETURN;
        END IF;
      END IF;
    ELSE
      x_response.Result_Code := G_RC_INVALID_EXTENSION_ID;
      l_fail_msg             := Get_Extension_Auth_Fail(p_trxn_entity_id,p_payer);
      IF( G_LEVEL_ERROR      >= G_CURRENT_RUNTIME_LEVEL) THEN
        iby_debug_pub.add('fail msg code:=' || l_fail_msg,G_LEVEL_ERROR,l_dbg_mod);
      END IF;
      IF (NOT l_fail_msg IS NULL) THEN
        FND_MESSAGE.SET_NAME('IBY',l_fail_msg);
        l_fail_msg := FND_MESSAGE.GET();
        iby_fndcpt_common_pub.Prepare_Result (iby_payment_adapter_pub.G_INTERFACE_CODE, l_fail_msg,l_prev_msg_count,x_return_status,x_msg_count,x_msg_data, x_response);
        RETURN;
      END IF;
    END IF;
  END IF;
  iby_fndcpt_common_pub.Prepare_Result (l_prev_msg_count,x_return_status,x_msg_count,x_msg_data,x_response);
  IF( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add('Exit',G_LEVEL_PROCEDURE,l_module);
  END IF;
EXCEPTION
WHEN FND_API.G_EXC_ERROR THEN
  IF( G_LEVEL_EXCEPTION >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add(debug_msg => 'In G_EXC_ERROR Exception', debug_level => G_LEVEL_EXCEPTION, module => G_DEBUG_MODULE || l_module);
  END IF;
  x_return_status := FND_API.G_RET_STS_ERROR;
  FND_MSG_PUB.Count_And_Get ( p_count => x_msg_count, p_data => x_msg_data );
WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
  IF( G_LEVEL_EXCEPTION >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add(debug_msg => 'In G_EXC_UNEXPECTED_ERROR Exception', debug_level => G_LEVEL_UNEXPECTED, module => G_DEBUG_MODULE || l_module);
  END IF;
  x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
  FND_MSG_PUB.Count_And_Get ( p_count => x_msg_count, p_data => x_msg_data );
WHEN OTHERS THEN
  IF( G_LEVEL_EXCEPTION >= G_CURRENT_RUNTIME_LEVEL) THEN
    iby_debug_pub.add(debug_msg => 'In OTHERS Exception '||SQLERRM, debug_level => G_LEVEL_UNEXPECTED, module => G_DEBUG_MODULE || l_module);
  END IF;
  iby_fndcpt_common_pub.Clear_Msg_Stack(l_prev_msg_count);
  x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
  IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
    FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME, l_module, SUBSTR(SQLERRM,1,100));
  END IF;
  FND_MSG_PUB.Count_And_Get( p_count => x_msg_count, p_data => x_msg_data );
END Create_Authorization;

END;
/
SHOW ERROR;