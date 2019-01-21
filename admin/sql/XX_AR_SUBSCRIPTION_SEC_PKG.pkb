create or replace PACKAGE BODY XX_AR_SUBSCRIPTION_SEC_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_AR_SUBSCRIPTION_SEC_PKG                                                         |
  -- |                                                                                            |
  -- |  Description:  This package is to process subscription billing                             |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         25-JAN-2018  Sreedhar Mohan   Initial version                                  |
  -- +============================================================================================+

    procedure get_clear_token (x_errbuf      OUT NOCOPY      VARCHAR2
						     , x_retcode     OUT NOCOPY      NUMBER
						     , p_label       IN              VARCHAR2
						     , p_hash_value  IN              VARCHAR2
    )
    IS
      l_cc_decrypted     VARCHAR2(256);
      l_cc_decrypt_error VARCHAR2(256);
    BEGIN
    
      FND_FILE.PUT_LINE(FND_FILE.LOG, '--Start getting Clear HVT--');
      FND_FILE.PUT_LINE(FND_FILE.LOG, '--Start getting Clear HVT 2--');
      
      /*
      DBMS_SESSION.SET_CONTEXT( namespace => 'XX_C2T_CNV_CRYPTO_CONTEXT'
    						, attribute => 'TYPE'
    						, value     => 'OM');   --'EBS' Version 1.3
      */					  
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'After setting the context, and before calling key package--');
      XX_OD_SECURITY_KEY_PKG.DECRYPT (           
    				                 p_module        => 'HVOP'       --'AJB' Version 1.3
    				               , p_key_label     => p_label      --'DES20060823B'
    				               , p_encrypted_val => p_hash_value --'11444376B19439411E70015EDC2D0677BC40314AA1194C2E'
    				               , p_algorithm     => '3DES'       --Version 1.5
    				               , p_format        => 'EBCDIC'     --Version 1.3
    				               , x_decrypted_val => l_cc_decrypted
    				               , x_error_message => l_cc_decrypt_error);
    
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'clear token: ' || l_cc_decrypted);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'clear token error: ' || l_cc_decrypt_error);
    EXCEPTION 
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception: ' || SQLERRM);    
    END get_clear_token;	

                                 
END XX_AR_SUBSCRIPTION_SEC_PKG;
/

