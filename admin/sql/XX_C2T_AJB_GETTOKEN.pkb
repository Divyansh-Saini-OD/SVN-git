CREATE OR REPLACE PACKAGE BODY XX_C2T_AJB_GetToken AS
-- +=====================================================================================================+
-- |                              Office Depot                                                           |
-- +=====================================================================================================+
-- |  Name:  XX_C2T_AJB_GetToken                                                                         |
-- |                                                                                                     |
-- |  Description: Package to call AJB service to getToken for cc value                                  |
-- |                                                                                                     |
-- |  Rice ID: C0705                                                                                     |
-- +=====================================================================================================+
-- | Version     Date         Author               Remarks                                               |
-- | =========   ===========  =============        ======================================================|
-- |    1.0      01-Mar-2016  Avinash Baddam       Initial Version                                       |
-- |    1.1      07-Apr-2016  Avinash Baddam       Fixed the store number                                |
-- |    1.2      08-Dec-2016  Avinash Baddam       Changes during Amex Conv TLS                          |
-- +=====================================================================================================+
  
    FUNCTION getToken(Timeout NUMBER, AJBServerIP VARCHAR2, Port NUMBER, request_message VARCHAR2) return VARCHAR2 
    AS LANGUAGE JAVA 
    NAME 'ODAJBGetToken.getToken(int, java.lang.String, int, java.lang.String) return java.lang.String'; 
    
    PROCEDURE get_cc_token(p_cc_value IN VARCHAR2,p_token OUT NOCOPY VARCHAR2, x_error_message OUT NOCOPY VARCHAR2) IS
   
      ln_Timeout	   NUMBER;
      lc_AJBServerIP	   VARCHAR2(100);
      ln_Port		   NUMBER;
      
   
      lc_IxTransactionType VARCHAR2(4);
      lc_IxActionCode      VARCHAR2(25);
      lc_IxTimeOut         VARCHAR2(25);
      lc_IxDebitCredit     VARCHAR2(25);
      lc_IxStoreNumber     VARCHAR2(25);
      lc_IxTerminalNumber  VARCHAR2(25);
      lc_IxTranType        VARCHAR2(25);
      lc_IxAccount         VARCHAR2(50);
      lc_IxExpDate         VARCHAR2(25);
      lc_IxOptions	   VARCHAR2(100);
      lc_Reserved23        VARCHAR2(25);
      lc_IxToken           VARCHAR2(50);
      lc_IxPosEchoField    VARCHAR2(10);
      lc_IxClerkNumber     VARCHAR2(10);
      lc_IxReceiptDisplay  VARCHAR2(250);
      lc_RequestMessage    VARCHAR2(2000);
      lc_ResponseMessage   VARCHAR2(2000);
      lc_message           VARCHAR2(2000);
      lc_database	   VARCHAR2(20);
      
      ajb_exception        EXCEPTION;
    BEGIN  
       --Set Connection Values
       
       SELECT name
         INTO lc_database
         FROM V$database;
       
       IF lc_database =  'GSIPRDGB' THEN
          lc_AJBServerIP 	:= 'AJBPRD2.na.odcorp.net';
          --ln_Port		:= 26301; v1.2 changes
          ln_Port		:= 26509;
       ELSE
          /*V1.2 Changes
          lc_AJBServerIP	:= 'USCHAJBUATAPP04.na.odcorp.net';
          ln_Port		:= 26306;
          
          lc_AJBServerIP	:= 'uschajbapps01d.na.odcorp.net';*/
          
          lc_AJBServerIP	:= 'USCHAJBUATAPP04.na.odcorp.net';
          ln_Port		:= 26509;          
       END IF;
       
       ln_Timeout 		:= 60;
       --Set Request values
       lc_IxTransactionType 	:= '100'; 	--Field 1
       lc_IxActionCode		:= ''; 		--Field 4
       lc_IxTimeOut		:= '25'; 	--Field 5
       lc_IxDebitCredit		:= 'Credit'; 	--Field 6
       lc_IxStoreNumber         := ''; 	        --Field 8
       lc_IxTerminalNumber 	:= '1099'; 	--Field 9 V 1.1
       lc_IxTranType 		:= 'GetToken';  --Field 10
       lc_IxAccount		:=  p_cc_value; --Field 13
       lc_IxExpDate		:= ''; 	        --Field 14
       
       /*V1.2 Changes */
       --lc_IxOptions		:= '*Tokenization';    --Field 21
       lc_IxOptions		:= '*Tokenization *forcebankfamily MPSCRD';    --Field 21
       
       lc_Reserved23		:= '';		       --Field 23
       lc_IxToken		:= '';	       	       --Field 33
       lc_IxPosEchoField        := '';	       	       --Field 34
       lc_IxReceiptDisplay      := '';                 --Field 38
       lc_IxClerkNumber         := '';		       --Field 95
    
       lc_RequestMessage := lc_IxTransactionType||',,,,'||lc_IxTimeOut||','||lc_IxDebitCredit||',,'||lc_IxStoreNumber||','||lc_IxTerminalNumber||','||lc_IxTranType||
       			    ',,,'||lc_IxAccount||','||lc_IxExpDate||',,,,,,,'||lc_IxOptions||',,'||lc_Reserved23||',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'||
       			    lc_IxClerkNumber||',,,,,';
       
       lc_ResponseMessage := getToken(lc_IxTimeOut,lc_AJBServerIP,ln_Port,lc_RequestMessage);
       
       --dbms_output.put_line(lc_ResponseMessage);
       
       IF SUBSTR(lc_ResponseMessage,1,9) = 'Exception' THEN
          raise ajb_exception;
       END IF;
          
       lc_IxActionCode := substr(lc_ResponseMessage,instr(lc_ResponseMessage,',',1,3)+1,instr(lc_ResponseMessage,',',1,4)-instr(lc_ResponseMessage,',',1,3)-1);
       
       IF lc_IxActionCode = 0 THEN
          lc_message := 'Successful';
       ELSIF lc_IxActionCode = 1 THEN
          lc_message := 'Declined';
       ELSIF lc_IxActionCode = 2 THEN 
          lc_message := 'Referral';
       ELSIF lc_IxActionCode = 3 THEN 
          lc_message := 'Bank Down';
       ELSIF lc_IxActionCode = 5 THEN
          lc_message := 'Modem/Phone Line Issue (dial backup only)';
       ELSIF lc_IxActionCode = 6 THEN
          lc_message := 'Report Error (Formatting problem)';
       ELSIF lc_IxActionCode = 8 THEN
          lc_message := 'Try Later';
       ELSIF lc_IxActionCode = 10 THEN
          lc_message := 'Timed Out';
       ELSIF lc_IxActionCode = 14 THEN
          lc_message := 'Request not supported by the authorizer';
       END IF;
       
       IF lc_IxActionCode = 0 THEN
          p_token := substr(lc_ResponseMessage,instr(lc_ResponseMessage,',',1,32)+1,instr(lc_ResponseMessage,',',1,33)-instr(lc_ResponseMessage,',',1,32)-1);
          x_error_message := null;
       ELSE
          lc_IxReceiptDisplay := substr(lc_ResponseMessage,instr(lc_ResponseMessage,',',1,37)+1,instr(lc_ResponseMessage,',',1,38)-instr(lc_ResponseMessage,',',1,37)-1);
          x_error_message     := 'Exception:'||lc_message||'-'||lc_IxReceiptDisplay;
       END IF; 
    EXCEPTION
      WHEN ajb_exception THEN
         x_error_message :=  lc_ResponseMessage;
      WHEN others THEN
         x_error_message := 'Exception in ODAJB_GetToken.get_cc_token '||substr(sqlerrm,1,250);
    END get_cc_token;  
END; 
/