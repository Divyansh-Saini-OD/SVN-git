 SET SERVEROUTPUT ON
 
 DECLARE
 -- Local Variables
    lc_file_name                VARCHAR2(200); 	
    lc_filehandle               UTL_FILE.file_type;
    lc_string                   VARCHAR2 (1000);
    lc_source_path              VARCHAR2(100)      := 'XXFIN_OUTBOUND';
    lc_newline                  VARCHAR2(4000);
    lc_credit_card_number_new   VARCHAR2(80);
    lc_cc_key_label_new         VARCHAR2(80);    
    ln_record_id		NUMBER;
    ln_total_records_processed  NUMBER             := 0;
 BEGIN    
 
    DBMS_OUTPUT.PUT_LINE ('Initialize the EXCEPTION STAGE LOAD Program');    
    DBMS_OUTPUT.PUT_LINE('TRUNCATE TABLE XXFIN.XX_C2T_CC_TOKEN_STG_EXCPTNS ');
    EXECUTE IMMEDIATE 'TRUNCATE  TABLE XXFIN.XX_C2T_CC_TOKEN_STG_EXCPTNS';
    
    DBMS_OUTPUT.PUT_LINE ('Start load_staging from file:'||lc_file_name);
    lc_file_name := 'xx_c2t_cnv_cc_exceptions_ibyhist.txt'; 	

    lc_filehandle := UTL_FILE.fopen (lc_source_path, lc_file_name, 'r');
    DBMS_OUTPUT.PUT_LINE ('File open successfull');
    
    LOOP
       BEGIN
          UTL_FILE.GET_LINE(lc_filehandle,lc_newline);
          IF lc_newline IS NULL THEN
 	     exit;
 	  END IF;
 	  
 	  lc_credit_card_number_new  := substr(lc_newline,1,instr(lc_newline,' ',1)-1);
	  lc_cc_key_label_new        := substr(lc_newline,instr(lc_newline,' ',1,1)+1);
	  
	  SELECT XX_C2T_CC_STG_EXCPTNS_SEQ.nextval
	    INTO ln_record_id
            FROM dual;
	  
	  INSERT into XX_C2T_CC_TOKEN_STG_EXCPTNS(RECORD_ID 
						  ,CREDIT_CARD_NUMBER_NEW
						  ,CC_KEY_LABEL_NEW
						  ,AJB_TOKEN_STATUS
						  ,ERROR_ACTION
						  ,ERROR_MESSAGE
						  ,CREATED_BY
						  ,CREATION_DATE
						  ,LAST_UPDATED_BY
						  ,LAST_UPDATE_DATE
						  ,LAST_UPDATE_LOGIN)
                                          VALUES (ln_record_id
                                                 ,lc_credit_card_number_new
                                                 ,lc_cc_key_label_new
                                                 ,'N'
                                                 ,''
                                                 ,''
                                                 ,-1
                                                 ,SYSDATE
                                                 ,-1
                                                 ,SYSDATE
                                                 ,-1);
	  
 	  ln_total_records_processed := ln_total_records_processed + 1;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
           exit;
       END; 
    END LOOP;
    
    UTL_FILE.FCLOSE(lc_filehandle);
    COMMIT;   
    --========================================================================
    -- Updating the OUTPUT FILE
    --========================================================================
    DBMS_OUTPUT.PUT_LINE ('TOTAL Records Processed :: '||ln_total_records_processed);

 EXCEPTION 
     WHEN UTL_FILE.INVALID_MODE
     THEN
       UTL_FILE.FCLOSE_ALL;
       RAISE_APPLICATION_ERROR (-20051, 'Invalid Mode Parameter');
     WHEN UTL_FILE.INVALID_PATH
     THEN
       UTL_FILE.FCLOSE_ALL;
       RAISE_APPLICATION_ERROR (-20052, 'Invalid File Location');
     WHEN UTL_FILE.INVALID_FILEHANDLE
     THEN
       UTL_FILE.FCLOSE_ALL;
       RAISE_APPLICATION_ERROR (-20053, 'Invalid Filehandle');
     WHEN UTL_FILE.INVALID_OPERATION
     THEN
       UTL_FILE.FCLOSE_ALL;
       RAISE_APPLICATION_ERROR (-20054, 'Invalid Operation');
     WHEN UTL_FILE.WRITE_ERROR
     THEN
       UTL_FILE.FCLOSE_ALL;
       RAISE_APPLICATION_ERROR (-20056, 'Write Error');
     WHEN UTL_FILE.INTERNAL_ERROR
     THEN
       UTL_FILE.FCLOSE_ALL;
       RAISE_APPLICATION_ERROR (-20057, 'Internal Error');
     WHEN UTL_FILE.FILE_OPEN
     THEN
       UTL_FILE.FCLOSE_ALL;
       RAISE_APPLICATION_ERROR (-20059, 'File Already Opened');
     WHEN OTHERS 
     THEN
       DBMS_OUTPUT.PUT_LINE (' When OTHERS Exception :'||SQLERRM);
 END;
 /