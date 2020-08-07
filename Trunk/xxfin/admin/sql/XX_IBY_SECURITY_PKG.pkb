CREATE OR REPLACE PACKAGE BODY APPS.XX_IBY_SECURITY_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :        OD:Project Simpilfy                                 |
-- | Description : This Package is used to do decrypt credit card      |
-- |                number.                                            |
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
lb_gv_debug_on   BOOLEAN DEFAULT FALSE;
-- +===================================================================+
-- | Name  : PUT_LINE                                                  |
-- | Description: This Procedure is set enable or disable DBMS_OUTPUT  |
-- |                                                                   |
-- |                                                                   |
-- | Parameters : p_debug_flag                                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE PUT_LINE(
   p_buffer IN VARCHAR2)
AS
BEGIN
  IF (lb_gv_debug_on) THEN
    DBMS_OUTPUT.PUT_LINE( SUBSTR(p_buffer,1,255) );
  END IF;
END PUT_LINE;
-- +===================================================================+
-- | Name  : SET_DEBUG                                                 |
-- | Description: This Procedure is set enable or disable debuge flag. |
-- |                                                                   |
-- |                                                                   |
-- | Parameters : p_debug_flag                                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE SET_DEBUG(
   p_debug_flag IN BOOLEAN DEFAULT FALSE )
AS
BEGIN
  lb_gv_debug_on := p_debug_flag;
END SET_DEBUG;
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
        p_cc_segment_ref    IN  VARCHAR2)
        RETURN VARCHAR2
AS
  ln_segment_id			NUMBER           DEFAULT NULL;
  lw_subkey			RAW(400)         DEFAULT NULL;
  lw_segment_cipher		RAW(400)         DEFAULT NULL;
  lc_cc_num_segment		VARCHAR2(400)    DEFAULT NULL;
  lc_cc_num			VARCHAR2(400)    DEFAULT NULL;
  lc_error_message_code		VARCHAR2(1);
  ln_msg_count			NUMBER	:= 1;
  -- Cursor to fetch Segment
  CURSOR c_segment ( ln_psegment_id     IN    NUMBER ) IS
  (
    SELECT iss.sec_segment_id
           ,iss.sec_subkey_id
           ,iss.segment_cipher_text
           ,iss.cc_unmask_digits
           ,isss.subkey_cipher_text
           ,icir.card_issuer_code
           ,icir.card_number_prefix
           -- B.Looman - 11-27-07 - CC Number Length defaults from segments (Defect 2843)
           --,icir.card_number_length
           ,NVL(icir.card_number_length,iss.cc_number_length) card_number_length
      FROM iby_security_segments iss
           ,iby_sys_security_subkeys isss
           ,iby_cc_issuer_ranges icir
     WHERE iss.sec_subkey_id = isss.sec_subkey_id
     -- B.Looman - 11-27-07 - Issuer Range Id is not always given (Defect 2843)
     AND   iss.cc_issuer_range_id = icir.cc_issuer_range_id(+)
     AND   iss.sec_segment_id = ln_psegment_id
  );
  lcu_segment			c_segment%ROWTYPE;
BEGIN
  PUT_LINE( 'BEGIN' );
  PUT_LINE( 'CC Ref = ' || p_cc_segment_ref );

  -- get segment id from reference parameter
  ln_segment_id :=  IBY_CC_SECURITY_PUB.get_segment_id
			(p_sec_card_ref => p_cc_segment_ref );
  PUT_LINE( 'Segment ID = ' || ln_segment_id );
  -- fetch iby security record for credit card
  OPEN c_segment ( ln_psegment_id => ln_segment_id );
	FETCH c_segment INTO lcu_segment;
  CLOSE c_segment;
  PUT_LINE( 'Sec Segment ID = ' || lcu_segment.sec_segment_id );

  -- get the sub-key given the current master key
  --  defect #3408, this function does not just get the sys subkey, but generates
  --  a new one if the sys subkey has been used beyond the tolerance
  --    THIS IS NOT DESIRED, so we are now using FND_VAULT to get the master key
  --    and decrypt the sys subkey using DBMS_OBFUSCATION_TOOLKIT.des3decrypt
  --IBY_SECURITY_PKG.Get_Sys_Subkey(
	--FND_API.G_FALSE
	--,'N'
	--,lcu_segment.sec_subkey_id
	--,lw_subkey);
  
  lw_subkey :=
    DBMS_OBFUSCATION_TOOLKIT.des3decrypt
    ( input  => lcu_segment.subkey_cipher_text, 
      key    => UTL_RAW.CAST_TO_RAW(FND_VAULT.get('IBY','IBY_SYS_SECURITY_KEY')),
      which  => dbms_obfuscation_toolkit.ThreeKeyMode );
  -- end defect #3408
  
  PUT_LINE( 'lw_subkey = ' || lw_subkey );
  -- decrypt the credit card segment using the sub-key
  lw_segment_cipher := DBMS_OBFUSCATION_TOOLKIT.des3decrypt(
			input  => lcu_segment.segment_cipher_text
			,key   => lw_subkey
			,which => dbms_obfuscation_toolkit.ThreeKeyMode);
  PUT_LINE( 'lw_segment_cipher = ' || lw_segment_cipher );
  
  PUT_LINE( 'CC Number Length = ' || lcu_segment.card_number_length );
  PUT_LINE( 'CC Prefix Length = ' || LENGTH(lcu_segment.card_number_prefix)  );
  PUT_LINE( 'Unmask Digits Length = ' || LENGTH(lcu_segment.cc_unmask_digits) );
  
  -- decode the credit card number from the credit card segment
  lc_cc_num_segment := IBY_SECURITY_PKG.decode_number(
			p_number   => RAWTOHEX(lw_segment_cipher)
      -- B.Looman - 11-27-07 - Card Number Prefix can be NULL, so default to Length=0
			,p_length  => lcu_segment.card_number_length - 
               (NVL(LENGTH(lcu_segment.card_number_prefix),0) 
                 + LENGTH(lcu_segment.cc_unmask_digits) )
			,p_des3mask => TRUE);

  lc_cc_num := lcu_segment.card_number_prefix || lc_cc_num_segment || lcu_segment.cc_unmask_digits;

  -- return the cc number
  PUT_LINE( 'CC Number = ' || lc_cc_num );
  PUT_LINE( 'END' );
  PUT_LINE( '' );
  RETURN lc_cc_num;
  
  -- B.Looman - 11-27-07 - Removed common error handling, this is a component to other functions
  --    that would call the common error handling instead (if this function errors out) 
END;

END XX_IBY_SECURITY_PKG;
/
