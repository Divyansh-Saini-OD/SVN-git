SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_AR_CREATE_DONE_FILES AS

-- +===================================================================+
-- | Name  : XX_AR_CREATE_DONE_FILES.EXTRACT_ESP_DETAILS               |
-- | Description      : This Procedure will create empty DONE files    |
-- |                                                                   |
-- | Parameters      none                                              |
-- +===================================================================+

PROCEDURE CREATE_DONE(errbuf       OUT NOCOPY VARCHAR2,
                      retcode      OUT NOCOPY NUMBER,
                      p_file_mask  IN         VARCHAR2,
                      p_in_file    IN         VARCHAR2,
                      p_out_file   IN         VARCHAR2)
IS
lc_output_file_handle   UTL_FILE.file_type;
lc_curr_line            VARCHAR2 (2000);
lc_return_status        VARCHAR2(100);
lc_file_name_1          VARCHAR2(60) := '';
lc_file_name_2          VARCHAR2(60) := '';
lc_source_path          VARCHAR2(1000);
lc_dest_path            VARCHAR2(1000);
ln_request_id           NUMBER;
lb_complete             BOOLEAN;
lc_phase                VARCHAR2 (100);
lc_status               VARCHAR2 (100);
lc_dev_phase            VARCHAR2 (100);
lc_dev_status           VARCHAR2 (100);
lc_message              VARCHAR2 (100);

BEGIN

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_AR_CREATE_DONE_FILES Begin:');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'PARMS: ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '      INPUT_FILE_PATH  '||p_in_file);
    FND_FILE.PUT_LINE(FND_FILE.LOG, '      OUTPUT_FILE_PATH '||p_out_file);

    BEGIN
	    -- Commented by Havish Kasina 
        /*
		SELECT REPLACE(p_file_mask, 'xxxxx', (SELECT SUBSTR(name,4,5) FROM v$database))
        INTO lc_file_name_1
        FROM DUAL;
        */
		-- Added by Havish Kasina to changed from v$database to DB_NAME
		SELECT REPLACE(p_file_mask, 'xxxxx', (SELECT SUBSTR(SYS_CONTEXT('USERENV','DB_NAME'),4,5) FROM dual))
        INTO lc_file_name_1
        FROM DUAL;
		
        EXCEPTION
            WHEN OTHERS THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'OTHERS - 1: ' || SQLERRM);
    END;

    BEGIN
        SELECT REPLACE(lc_file_name_1, 'yyyymmdd', (select to_char(sysdate,'yyyymmdd') from dual))
        INTO lc_file_name_2
        FROM DUAL;

        EXCEPTION
            WHEN OTHERS THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'OTHERS - 2: ' || SQLERRM);
    END;

    BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Opening Output File - '||lc_file_name_2);
        lc_output_file_handle := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_file_name_2, 'W',2000);

        EXCEPTION
            WHEN UTL_FILE.invalid_path THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invalid file Path: ' || SQLERRM);
            WHEN UTL_FILE.invalid_mode THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invalid Mode: ' || SQLERRM);
            WHEN UTL_FILE.invalid_filehandle THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invalid file handle: ' || SQLERRM);
            WHEN UTL_FILE.invalid_operation THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'File does not exist: ' || SQLERRM);
            WHEN UTL_FILE.read_error THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'Read Error: ' || SQLERRM);
            WHEN UTL_FILE.internal_error THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'Internal Error: ' || SQLERRM);
            WHEN NO_DATA_FOUND THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'Empty File: ' || SQLERRM);
            WHEN VALUE_ERROR THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'Value Error: ' || SQLERRM);
            WHEN OTHERS THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'OTHERS: ' || SQLERRM);
                 UTL_FILE.fclose (lc_output_file_handle);
    END;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Writing dummy record - ');
    UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Closing files - ');
    UTL_FILE.fclose(lc_output_file_handle);

    BEGIN
         lc_source_path := p_in_file||lc_file_name_2;
         lc_dest_path   := p_out_file||lc_file_name_2;

         FND_FILE.PUT_LINE(FND_FILE.LOG, 'input file - '||lc_source_path);
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'output file - '||lc_dest_path);

         ln_request_id := fnd_request.submit_request 
                          (application      => 'XXFIN',
                           program          => 'XXCOMFILCOPY',
                           description      => NULL,
                           start_time       => NULL,
                           sub_request      => FALSE,
                           argument1        => lc_source_path,
                           argument2        => lc_dest_path,
                           argument3        => NULL,
                           argument4        => NULL,
                           argument5        => 'Y',
                           argument6        => NULL,
                           argument7        => NULL,
                           argument8        => NULL,
                           argument9        => NULL,
                           argument10       => NULL,
                           argument11       => NULL,
                           argument12       => NULL,
                           argument13       => NULL);

         IF ln_request_id > 0 THEN
            COMMIT;
            lb_complete := fnd_concurrent.wait_for_request
                                      (request_id      => ln_request_id,
                                       INTERVAL        => 30,
                                       max_wait        => 0,
                                       phase           => lc_phase,
                                       status          => lc_status,
                                       dev_phase       => lc_dev_phase,
                                       dev_status      => lc_dev_status,
                                       MESSAGE         => lc_message
                                      );
         ELSE
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error submitting file copy ');
         END IF;

        EXCEPTION
            WHEN OTHERS THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'OTHERS: ' || SQLERRM);
    END;

EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_AR_CREATE_DONE_FILES OTHERS ERROR'||SQLERRM);
         RETCODE := 2;

END CREATE_DONE;

END XX_AR_CREATE_DONE_FILES;
/
