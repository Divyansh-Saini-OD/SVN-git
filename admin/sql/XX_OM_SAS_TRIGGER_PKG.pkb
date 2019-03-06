SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_OM_SAS_TRIGGER_PKG AS

-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_OM_SAS_TRIGGER_PKG                                           |
-- | Description      : This Program will trigger HVOP runs based on the     |
-- |                    Trigger file received from SAS                       |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    05-JUN-2007   Manish Chavan     Initial code                  |
-- +=========================================================================+


PROCEDURE SUBMIT_HVOP( x_retcode          OUT NOCOPY NUMBER
                     , x_errbuf           OUT NOCOPY VARCHAR2
                     , p_trigger_fname    IN VARCHAR2
                     , p_batch_size       IN NUMBER DEFAULT 1500
                     , p_debug_level      IN NUMBER DEFAULT 0
                     ) IS

lc_short_name           VARCHAR2(200);
ln_request_id           NUMBER := 0;
lc_fname                VARCHAR2(100);
lc_error_flag           VARCHAR2(1);
lc_return_status        VARCHAR2(1);
lc_file_date            VARCHAR2(30);
lc_date                 VARCHAR2(30);
lc_req_data             VARCHAR2(10);
ln_req_data_counter     NUMBER;
ln_child_req_counter    NUMBER;
ln_count                BINARY_INTEGER;
lc_file_path            VARCHAR2(100) := FND_PROFILE.VALUE('XX_OM_SAS_FILE_DIR');
lc_file_name            VARCHAR2(30);
lc_mfile_name           VARCHAR2(30);
lc_input_file_handle    UTL_FILE.file_type;
lc_input_file_path      VARCHAR2(250);
lc_curr_line            VARCHAR2(100);
ln_hvop_file_cnt        BINARY_INTEGER;
ln_dep_file_cnt         BINARY_INTEGER;
ln_wave_number          BINARY_INTEGER; 
lc_o_unit               VARCHAR2(3);
lb_file_found           BOOLEAN;
i                       BINARY_INTEGER;
lb_deposit_run          BOOLEAN := FALSE;
lb_HVOP_run             BOOLEAN := FALSE;
lc_arch_path            VARCHAR2(100);
NULL_FILE               EXCEPTION;

-- Cursor to fetch file history
CURSOR c_file_validate ( p_fname VARCHAR2) IS
      SELECT file_name
        FROM xx_om_sacct_file_history
       WHERE file_name = p_fname
       AND NVL(ERROR_FLAG,'N') = 'N';

BEGIN
    x_retcode := 0;
    ln_child_req_counter := 0;

    -- In Master logic the file sequence number will be NULL
    -- Get the current request_count
    lc_req_data := fnd_conc_global.request_data;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'LC_REQ_DATA is '||lc_req_data);

    IF lc_req_data IS NOT NULL THEN
        ln_req_data_counter := TO_NUMBER(lc_req_data);
    ELSE
        ln_req_data_counter := 1;
    END IF;

    FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting  Master');

    --lc_file_date := TO_CHAR(SYSDATE,'DDMONYYYY');
    --lc_mfile_name := 'SAS'||lc_file_date||lc_o_unit||'EOT.TXT';
    lc_mfile_name := p_trigger_fname;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Start Procedure ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Path : ' || lc_file_path);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Name : ' || lc_mfile_name);

    -- Exit out if master is trying to run second time..
    -- and remove the Trigger File
    IF ln_req_data_counter = 2 THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Removing the Master file ');
        --UTL_FILE.FREMOVE(lc_file_path, lc_mfile_name);
        -- try to move the file to archieve folder
        lc_arch_path := FND_PROFILE.VALUE('XX_OM_SAS_ARCH_FILE_DIR'); 
        lc_file_date := TO_CHAR(SYSDATE,'DDMONYYYY:HH24:MI:SS');
        --UTL_FILE.FRENAME(lc_file_path, lc_mfile_name, lc_arch_path, lc_mfile_name||'.'||lc_file_date);
        UTL_FILE.FCOPY(lc_file_path, lc_mfile_name, lc_arch_path, lc_mfile_name||'.'||lc_file_date);
        UTL_FILE.FREMOVE(lc_file_path, lc_mfile_name);
        x_retcode := 0;
        RETURN;
    END IF;

    -- Open the file
    BEGIN
        lc_input_file_handle := UTL_FILE.fopen(lc_file_path, lc_mfile_name, 'R',1000);
        lb_file_found := TRUE;
    EXCEPTION
        WHEN UTL_FILE.invalid_path THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invalid file Path: ' || SQLERRM);
            RAISE FND_API.G_EXC_ERROR;
        WHEN UTL_FILE.invalid_mode THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invalid Mode: ' || SQLERRM);
            RAISE FND_API.G_EXC_ERROR;
        WHEN UTL_FILE.invalid_filehandle THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invalid file handle: ' || SQLERRM);
            RAISE FND_API.G_EXC_ERROR;
        WHEN UTL_FILE.invalid_operation THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'File has not arrived yet : ' );
            lb_file_found := FALSE;
            RAISE FND_API.G_EXC_ERROR;
        WHEN UTL_FILE.read_error THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Read Error: ' || SQLERRM);
            RAISE FND_API.G_EXC_ERROR;
        WHEN UTL_FILE.internal_error THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Internal Error: ' || SQLERRM);
            RAISE FND_API.G_EXC_ERROR;
        WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Empty File: ' || SQLERRM);
            lb_file_found := FALSE;
            RAISE FND_API.G_EXC_ERROR;
        WHEN VALUE_ERROR THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Value Error: ' || SQLERRM);
            RAISE FND_API.G_EXC_ERROR;
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, SQLERRM);
            UTL_FILE.fclose (lc_input_file_handle);
            RAISE FND_API.G_EXC_ERROR;
    END;

    -- If the file is not found then close the Master Program
    IF NOT lb_file_found THEN
        x_retcode := 0;
        RETURN;
    END IF;

    i := 0;
  
    -- Start the loop for reading the file names from trigger file
    LOOP
        -- Set Batch Counter Global
        BEGIN
            lc_curr_line := NULL;
            /* UTL FILE READ START */
            UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO MORE RECORDS TO READ');
                IF i = 0 THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'THE FILE '|| lc_mfile_name ||' IS EMPTY, NO RECORDS');
                    RAISE NULL_FILE;
                END IF;
                EXIT;
            WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while reading '||sqlerrm);
                RAISE FND_API.G_EXC_ERROR;
        END;

        -- Always get the exact byte length in lc_curr_line to avoid reading new line characters
        lc_curr_line := TRIM(SUBSTR(lc_curr_line ,1,INSTR(lc_curr_line,'TXT',1)+2));
        FND_FILE.PUT_LINE(FND_FILE.LOG,'My Line Is :'||lc_curr_line);

        OPEN c_file_validate (lc_curr_line);
        FETCH c_file_validate INTO lc_fname;
        IF c_file_validate%NOTFOUND THEN

            IF SUBSTR(lc_curr_line,16,3) = 'DEP' THEN
                -- Submit the deposit concurrent program
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Before submitting Deposit Concurrent Program ');
                lc_short_name := 'Import SAS Deposits :: ' || lc_curr_line;
                ln_request_id := fnd_request.submit_request('XXOM'
                                      , 'XXOMDEPIMP'
                                      , lc_short_name
                                      , NULL
                                      , TRUE
                                      , p_debug_level
                                      , lc_curr_line
                                      );
                IF ln_request_id = 0
                THEN
                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error in submitting SAS Deposit Import request');
                    x_errbuf  := FND_MESSAGE.GET;
                    x_retcode := 2;
                    RETURN;
                ELSE
                    ln_child_req_counter := ln_child_req_counter + 1;
                END IF;

            ELSIF SUBSTR(lc_curr_line,16,4) = 'HVOP' THEN
                -- Submit HVOP upload concurrent program
                lc_short_name := 'Import SAS feed :: ' || lc_curr_line;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'File Name is '||lc_curr_line);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Short Name is '||lc_short_name);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Before submitting child ');
                ln_request_id := fnd_request.submit_request('XXOM'
                                      , 'XXOMSASIMP'
                                      , lc_short_name
                                      , NULL
                                      , TRUE
                                      , lc_curr_line
                                      , p_debug_level
                                      , p_batch_size
                                      );
                FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_request_id ::::: '||ln_request_id);

                IF ln_request_id = 0 THEN
                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error in submitting HVOP Upload request for file '|| lc_file_name);
                    x_errbuf  := FND_MESSAGE.GET;
                    x_retcode := 2;
                    RETURN;
                ELSE
                    ln_child_req_counter := ln_child_req_counter + 1;
                END IF;
            ELSE
                FND_FILE.PUT_LINE(FND_FILE.LOG,'No files to process ');
            END IF;  -- IF SUBSTR(lc_curr_line

        ELSE
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'This file has already been processed : '||lc_curr_line);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'This file has already been processed : ');
        END IF; -- IF c_file_validate%NOTFOUND  

        CLOSE c_file_validate;

        i := i +1;

    END LOOP;

    -- Close the file handle
    UTL_FILE.fclose (lc_input_file_handle);
 
    -- IF master submitted any child request then put it in PAUSE mode
    IF ln_child_req_counter > 0 THEN
        ln_req_data_counter := ln_req_data_counter + 1;   
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Pausing the master request'||ln_req_data_counter);
        fnd_conc_global.set_req_globals(conc_status  => 'PAUSED',
                                        request_data => to_char(ln_req_data_counter));
        x_errbuf  := 'Sub-Request ' || to_char(ln_req_data_counter) || 'submitted!';
        x_retcode := 0;
    ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG,'No more files to process');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No more Files to process');
        x_retcode := 0; 
        RETURN;
    END IF;

EXCEPTION
    WHEN NULL_FILE THEN
        x_retcode := 1;
        x_errbuf := 'WARNING:The trigger file is empty';
    WHEN FND_API.G_EXC_ERROR THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'TRIGGER_HVOP raised error');
        x_retcode := 2;
        x_errbuf := 'Please check the log file for error messages';
        raise FND_API.G_EXC_ERROR;
    WHEN OTHERS THEN
      x_retcode := 2;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Unexpected error '||substr(sqlerrm,1,200));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
      x_errbuf := 'Please check the log file for error messages';
      raise FND_API.G_EXC_ERROR;
END SUBMIT_HVOP;

END XX_OM_SAS_TRIGGER_PKG;
/
SHOW ERRORS PACKAGE BODY XX_OM_SAS_TRIGGER_PKG;
EXIT;
