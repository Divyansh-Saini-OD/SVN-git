CREATE OR REPLACE PROCEDURE USAGE_FILE_COPY_TO(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER, p_application VARCHAR2, p_alias_dir VARCHAR2,
                                            p_source_dir VARCHAR2, p_dest_dir VARCHAR2, p_move_flag VARCHAR2) AS

/*--------------------------------------------------------------
--File Copy Program
--
--Parameters Documentation
--
--p_application - name of application - example - xxfin
--
--p_alias_dir - name of alias of directory where file is being copied or moved to.  This would come from 
--the table all_directories and must be created prior.  This is used for the utl_file.fgettattr package.
--An example of this would be XXFIN_INBOUND.  This must be specified in CAPS
--
--p_source_dir - full name of directory (not alias) where the file is being copied or moved from
--
--p_dest_dir - full name of directory (not alias) where the file is being copied or moved to
--
--p_move_flag - value of Y if file is being moved, NULL if file is being copied.
--
----------------------------------------------------------------------
*/

BEGIN

DECLARE
  v_exists       BOOLEAN;
  v_file_length  NUMBER;
  v_block_size   NUMBER;
  v_request_id   NUMBER := 0;
  v_exists_char  VARCHAR2(10);
  v_errbuf       VARCHAR2(2000);
  v_retcode      NUMBER := 0;

  x_req_phase	 VARCHAR2(10); 
  x_req_status   VARCHAR2(50); 
  x_req_dev_phase VARCHAR2(10);
  x_req_dev_status VARCHAR2(50); 
  x_req_message    VARCHAR2(2000);

  x_req_return_status BOOLEAN;
 
  v_sysdate      VARCHAR2(10) := TO_CHAR(SYSDATE,'YYYY.MM.DD');

BEGIN
    
    v_request_id := FND_REQUEST.SUBMIT_REQUEST (p_application
                                                    ,'XXCOMFILCOPY'
                                                    ,''
                                                    ,''
                                                    ,FALSE
                                                    ,p_source_dir
                                                    ,p_dest_dir||'/Usage_Ext_File.psv'
                                                    ,NULL
                                                    ,NULL
						    ,p_move_flag   --Flag for Move Instead of Copy
                                                    );
													
	COMMIT;

     IF v_request_id = 0 THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,' File Copy Program Did Not Run ');
     ELSE

      x_req_return_status := FND_CONCURRENT.WAIT_FOR_REQUEST( 
                                           v_request_id, 2, 1500,x_req_phase, x_req_status, 
                                           x_req_dev_phase, x_req_dev_status, 
                                           x_req_message); 

     
     IF x_req_return_status THEN

     UTL_FILE.FGETATTR(p_alias_dir,'Usage_Ext_File.psv',v_exists,v_file_length,v_block_size);

     
     IF v_exists THEN
       v_exists_char := 'TRUE';
     ELSE
       v_exists_char := 'FALSE';
       v_retcode := 2;
       v_errbuf := 'File Does Not Exist and was not moved ';
     END IF;
     
       FND_FILE.PUT_LINE(FND_FILE.LOG,'File EXists Information for Usage Ext File in the Inbound Directory');

       FND_FILE.PUT_LINE(FND_FILE.LOG,v_exists_char);
       FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(v_file_length));
       FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(v_block_size));

     
     IF v_errbuf IS NOT NULL THEN
       p_errbuf := v_errbuf;
       p_retcode := v_retcode;
     END IF;
     

     ELSE
       FND_FILE.PUT_LINE(FND_FILE.LOG,'The Wait For Request Status Failed');

     END IF; 
    END IF;            



EXCEPTION
   WHEN UTL_FILE.ACCESS_DENIED THEN
       DBMS_OUTPUT.PUT_LINE('No Access!!!');
       FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Access Denied');

   WHEN UTL_FILE.INVALID_OPERATION THEN
       DBMS_OUTPUT.PUT_LINE(' Invalid Operation to the file ');
       FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invalid Operation to the File');   

   WHEN UTL_FILE.INVALID_PATH THEN
       DBMS_OUTPUT.PUT_LINE(' Invalid Path ');
       FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invalid Directory Path');

   WHEN UTL_FILE.INTERNAL_ERROR THEN
       DBMS_OUTPUT.PUT_LINE(' Internal Error ');
       FND_FILE.PUT_LINE(FND_FILE.LOG, 'Internal Error');

   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('SQLERRM: ' || SQLERRM);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'SQLERRM: ' || SQLERRM);

  
END;  
END USAGE_FILE_COPY_TO;
/
