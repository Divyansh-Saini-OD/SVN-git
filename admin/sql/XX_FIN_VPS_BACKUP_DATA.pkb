create or replace package body XX_FIN_VPS_BACKUP_DATA
as
-- +===========================================================================+
-- |                  Office Depot                                             |
-- +===========================================================================+
-- |Description : Create index ON XX_FIN_VPS_BACKUP_DATA.pkb                   |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                  Remarks                |
-- |=======    ==========     =============             ====================== |
-- | 1.0       09-JUL-17      Sreedhar Mohan            Initial draft version  |
-- +===========================================================================+

  PROCEDURE VPS_BACKUP_GET( ERRBUF                OUT  VARCHAR2
                           ,RETCODE               OUT  NUMBER
                           ,P_PROGRAM_ID          IN   NUMBER
                           ,P_VENDOR_NUMBER       IN   VARCHAR2
                           ,P_BACKUP_TYPE         IN   VARCHAR2
                          )
  IS
      request UTL_HTTP.REQ;
      response UTL_HTTP.RESP;
      n NUMBER;
      buff VARCHAR2(10000);
      clob_buff CLOB;

      l_wallet_location     VARCHAR2(256)   := NULL;
      l_password            VARCHAR2(256)   := NULL;   
      l_url                 VARCHAR2(4000);
      
      VPS_BACKUP_SERVICE_URL varchar2(1000) := null; --'https://agerndev.na.odcorp.net/vpsservice/api/v2/PGM_DETAILS';
      
  BEGIN
  
      BEGIN
      
        SELECT 
            TARGET_VALUE1
         INTO
            VPS_BACKUP_SERVICE_URL
         FROM  XX_FIN_TRANSLATEVALUES VALS
              ,XX_FIN_TRANSLATEDEFINITION DEFN
         WHERE 1=1
         AND DEFN.TRANSLATE_ID=VALS.TRANSLATE_ID
         AND DEFN.TRANSLATION_NAME = 'OD_VPS_TRANSLATION'
         AND SOURCE_VALUE1 LIKE 'BKUP_INT_URL'
         ;        
        
      EXCEPTION 
        WHEN OTHERS THEN
        RETCODE:=2;
        ERRBUF:='Error in getting Backup interface Service URL from Translation';
        fnd_file.put_line (fnd_file.LOG,ERRBUF);
        RETURN;
      END;
  
      BEGIN
      
        SELECT 
           TARGET_VALUE1
          ,TARGET_VALUE2
        into
          l_wallet_location
         ,l_password
        FROM XX_FIN_TRANSLATEVALUES     VAL,
             XX_FIN_TRANSLATEDEFINITION DEF
        WHERE 1=1
        and   DEF.TRANSLATE_ID = VAL.TRANSLATE_ID
        and   DEF.TRANSLATION_NAME='XX_FIN_IREC_TOKEN_PARAMS'
        and   VAL.SOURCE_VALUE1 = 'WALLET_LOCATION'     
        and   VAL.ENABLED_FLAG = 'Y'
        and   SYSDATE between VAL.START_DATE_ACTIVE and nvl(VAL.END_DATE_ACTIVE, SYSDATE+1); 
        
      EXCEPTION 
        WHEN OTHERS THEN
        l_wallet_location := NULL;
        l_password := NULL;
        RETCODE:=2;
        ERRBUF:='Error in getting Wallet Location from Translation';
        fnd_file.put_line (fnd_file.LOG,ERRBUF);
        RETURN;        
      END;
      
      IF l_wallet_location IS NOT NULL THEN
        UTL_HTTP.SET_WALLET(l_wallet_location,l_password);
      END IF;
           
      UTL_HTTP.SET_RESPONSE_ERROR_CHECK(FALSE);

      
    request := UTL_HTTP.BEGIN_REQUEST(VPS_BACKUP_SERVICE_URL || '/' || P_PROGRAM_ID || '/' || P_VENDOR_NUMBER || '/2017/' || P_BACKUP_TYPE, 'GET');
    
      UTL_HTTP.SET_HEADER(request, 'User-Agent', 'Mozilla/4.0');
      response := UTL_HTTP.GET_RESPONSE(request);
      --insert into a(log_msg) values ('HTTP response status code: ' || response.status_code); 
      commit; 
      --DBMS_OUTPUT.PUT_LINE('HTTP response status code: ' || response.status_code);
      l_url:= VPS_BACKUP_SERVICE_URL || '/' || P_PROGRAM_ID || '/' || P_VENDOR_NUMBER || '/2017/' || P_BACKUP_TYPE;
      fnd_file.put_line (fnd_file.LOG,'l_url:'||l_url);
      fnd_file.put_line (fnd_file.LOG,'HTTP response status code: ' || response.status_code);
      IF response.status_code = 200 THEN
          BEGIN
              clob_buff := EMPTY_CLOB;
              LOOP
                UTL_HTTP.READ_TEXT(response, buff, LENGTH(buff));
  		        clob_buff := clob_buff || buff;
              END LOOP;
  	          UTL_HTTP.END_RESPONSE(response);
          EXCEPTION
  	          WHEN UTL_HTTP.END_OF_BODY THEN
                  UTL_HTTP.END_RESPONSE(response);
  	          WHEN OTHERS THEN
                  DBMS_OUTPUT.PUT_LINE(SQLERRM);
                  DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                  UTL_HTTP.END_RESPONSE(response);
          END;
  
          BEGIN
            fnd_file.put_line (fnd_file.LOG,'Before inserting into XX_FIN_VPS_STMT_BACKUP_DATA: ');
            INSERT INTO XX_FIN_VPS_STMT_BACKUP_DATA VALUES (XX_FIN_VPS_STMT_BACKUP_S.nextval, p_program_id, p_vendor_number, clob_buff, P_BACKUP_TYPE, sysdate, 0, sysdate, 0);
            fnd_file.put_line (fnd_file.LOG,'After inserting into XX_FIN_VPS_STMT_BACKUP_DATA: ' || SQL%ROWCOUNT);
            COMMIT;
          EXCEPTION
      	    WHEN OTHERS THEN
                  ERRBUF := 'Exception in inserting into XX_FIN_VPS_STMT_BACKUP_DATA: ' || SQLERRM;
                  DBMS_OUTPUT.PUT_LINE('Exception in inserting into XX_FIN_VPS_STMT_BACKUP_DATA: ' || SQLERRM);
          END;
      ELSE
          DBMS_OUTPUT.PUT_LINE('ERROR');
          ERRBUF := 'ERROR';
          UTL_HTTP.END_RESPONSE(response);
      END IF;
  EXCEPTION
      	    WHEN OTHERS THEN
                  DBMS_OUTPUT.PUT_LINE('Exception: ' || SQLERRM);
                  commit;  
  END VPS_BACKUP_GET;

  PROCEDURE VPS_BACKUP_GET( VPS_BACKUP_SERVICE_URL VARCHAR2
                           ,P_PROGRAM_ID           NUMBER
                           ,P_VENDOR_NUMBER        VARCHAR2
                           ,P_BACKUP_TYPE          VARCHAR2
                          )
  IS
      request UTL_HTTP.REQ;
      response UTL_HTTP.RESP;
      n NUMBER;
      buff VARCHAR2(4000);
      clob_buff CLOB;

      l_wallet_location     VARCHAR2(256)   := NULL;
      l_password            VARCHAR2(256)   := NULL;   
      
  BEGIN
  
      BEGIN
      
        SELECT 
           TARGET_VALUE1
          ,TARGET_VALUE2
        into
          l_wallet_location
         ,l_password
        FROM XX_FIN_TRANSLATEVALUES     VAL,
             XX_FIN_TRANSLATEDEFINITION DEF
        WHERE 1=1
        and   DEF.TRANSLATE_ID = VAL.TRANSLATE_ID
        and   DEF.TRANSLATION_NAME='XX_FIN_IREC_TOKEN_PARAMS'
        and   VAL.SOURCE_VALUE1 = 'WALLET_LOCATION'     
        and   VAL.ENABLED_FLAG = 'Y'
        and   SYSDATE between VAL.START_DATE_ACTIVE and nvl(VAL.END_DATE_ACTIVE, SYSDATE+1); 
        
      EXCEPTION 
        WHEN OTHERS THEN
        l_wallet_location := NULL;
        l_password := NULL;
        
      END;
      
      IF l_wallet_location IS NOT NULL THEN
        UTL_HTTP.SET_WALLET(l_wallet_location,l_password);
      END IF;
           
      UTL_HTTP.SET_RESPONSE_ERROR_CHECK(FALSE);

      request := UTL_HTTP.BEGIN_REQUEST(VPS_BACKUP_SERVICE_URL || '/' || P_PROGRAM_ID || '/' || P_VENDOR_NUMBER || '/' || P_BACKUP_TYPE, 'GET');
      UTL_HTTP.SET_HEADER(request, 'User-Agent', 'Mozilla/4.0');
      response := UTL_HTTP.GET_RESPONSE(request);
     -- insert into a(log_msg) values ('HTTP response status code: ' || response.status_code); 
      commit; 
      DBMS_OUTPUT.PUT_LINE('HTTP response status code: ' || response.status_code);
  
      IF response.status_code = 200 THEN
          BEGIN
              clob_buff := EMPTY_CLOB;
              LOOP
                UTL_HTTP.READ_TEXT(response, buff, LENGTH(buff));
  		        clob_buff := clob_buff || buff;
              END LOOP;
  	          UTL_HTTP.END_RESPONSE(response);
          EXCEPTION
  	          WHEN UTL_HTTP.END_OF_BODY THEN
                  UTL_HTTP.END_RESPONSE(response);
  	          WHEN OTHERS THEN
                  DBMS_OUTPUT.PUT_LINE(SQLERRM);
                  DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                  UTL_HTTP.END_RESPONSE(response);
          END;
  
  	--SELECT COUNT(*) + 1 INTO n FROM WWW_DATA;
          INSERT INTO XX_FIN_VPS_STMT_BACKUP_DATA VALUES (XX_FIN_VPS_STMT_BACKUP_S.nextval, p_program_id, p_vendor_number, clob_buff, P_BACKUP_TYPE, sysdate, 0, sysdate, 0);
          COMMIT;
      ELSE
          DBMS_OUTPUT.PUT_LINE('ERROR');
          UTL_HTTP.END_RESPONSE(response);
      END IF;
  EXCEPTION
      	    WHEN OTHERS THEN
                  DBMS_OUTPUT.PUT_LINE('Exception: ' || SQLERRM);
                  commit;  
  END VPS_BACKUP_GET;
  
END XX_FIN_VPS_BACKUP_DATA;
/
