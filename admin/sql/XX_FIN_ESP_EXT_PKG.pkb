SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_FIN_ESP_EXT_PKG AS

-- +===================================================================+
-- | PROCEDURE: EXTRACT_ESP_DETAILS                                    |
-- |                                                                   |
-- | Concurrent Program : Extract ESP Details                          |
-- | Short_name         : XX_FIN_ESP_EXT_PKG                           |
-- | Executable         : XX_FIN_ESP_EXT_PKG.EXTRACT_ESP_DETAILS       |
-- |                                                                   |
-- | Description      : This Procedure will read a file with ESP data  |
-- |                    extracted on the mainframe, and sent to EBS.   |
-- |                    It will get the program name and query tables  |
-- |                    to get the user program name.                  |
-- |                                                                   |
-- | Parameters      none                                              |
-- |                                                                   |
-- | Notes:                                                            |
-- |     Execute U480326.TEST.JCL(ESPEXTZZ).                           |
-- |                                                                   |
-- |     Creates TEST.RJS.ESP.ESP.ESPEXT4.ESPEXTR.OUTPUT (full extract)|
-- |         and U480326.ESP.ESPEXT4.ESPEXTR.OUT.EBS     (FTP to PRF)  |
-- |         and U480326.ESP.ESPEXT4.ESPEXTR.OUT.LINK    (FTP to PRF)  |
-- |                                                                   |
-- |     Copy /app/ebs/ctgsiprfgb/xxfin/ftp/in/XX_RJS_ESP_DATA.txt     |
-- |       to /app/ebs/ctgsiuatgb/xxfin/inbound/XX_RJS_ESP_DATA.txt    |
-- |                                                                   |
-- |     Execute ESP event ESPEXTZZ, pgm ESP Extract Details           |
-- |                                                                   |
-- |     Copy /app/ebs/ctgsiuatgb/xxfin/outbound/XX_RJS_ESP_OUTPUT.txt |
-- |       to /app/ebs/ctgsiprfgb/xxfin/ftp/in/XX_RJS_ESP_OUTPUT.txt   |
-- |                                                                   |
-- |     Execute FTP to get above dataset. Copy to U drive.            |
-- |                                                                   |
-- |     Need to add a place to track job type (ie. + - L N S etc.)    |
-- |     Need to add a place to store user_concurrent_program_name     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE EXTRACT_ESP_DETAILS(errbuf       OUT NOCOPY VARCHAR2,
                              retcode      OUT NOCOPY NUMBER)
IS
lc_input_file_handle    UTL_FILE.file_type;
lc_output_file_handle   UTL_FILE.file_type;
lc_curr_line            VARCHAR2 (2000);
lc_return_status        VARCHAR2(100);
lc_program_name         VARCHAR2(60);
lc_exec_name            VARCHAR2(60);
lc_user_name            VARCHAR2(80);
lc_short_name           VARCHAR2(60);
lc_resp_name            VARCHAR2(60);
lc_pgm_args             VARCHAR2(585);
lc_parms                VARCHAR2(1000);
lc_appl_name            VARCHAR2(8);
lc_real_appl            VARCHAR2(8);
lc_event_name           VARCHAR2(8);
lc_job_name             VARCHAR2(8);
lc_method               VARCHAR2(1);

BEGIN

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_FIN_ESP_EXT_PKG Begin:');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '1. Truncating table XX_FIN_ESP_DETAILS');
    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_FIN_ESP_DETAILS';
    FND_FILE.PUT_LINE(FND_FILE.LOG, '2. Truncating table XX_FIN_ESP_INVOKE');
    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_FIN_ESP_INVOKE';
    FND_FILE.PUT_LINE(FND_FILE.LOG, '3. Truncating table XX_FIN_ESP_LINK');
    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_FIN_ESP_LINK';
    FND_FILE.PUT_LINE(FND_FILE.LOG, '4. Truncating table XX_FIN_ESP_PARAMETERS');
    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_FIN_ESP_PARAMETERS';
    FND_FILE.PUT_LINE(FND_FILE.LOG, '5. Truncating table XX_FIN_ESP_RUNS');
    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_FIN_ESP_RUNS';
    FND_FILE.PUT_LINE(FND_FILE.LOG, '6. Truncating table XX_FIN_ESP_SCHEDULE');
    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_FIN_ESP_SCHEDULE';
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Opening Input File - XX_RJS_ESP_DATA.txt ');
        lc_input_file_handle := UTL_FILE.fopen('XXFIN_INBOUND', 'XX_RJS_ESP_DATA.txt', 'R',1000);

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Opening Output File - XX_RJS_ESP_OUTPUT.txt');
        lc_output_file_handle := UTL_FILE.fopen('XXFIN_OUTBOUND', 'XX_RJS_ESP_OUTPUT.txt', 'W',2000);

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
                 UTL_FILE.fclose (lc_input_file_handle);
    END;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Start Processing Data - ');

    BEGIN
        LOOP
            BEGIN

                lc_curr_line := NULL;
                UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
                FND_FILE.PUT_LINE(FND_FILE.LOG, '    Data read = '||SUBSTR(lc_curr_line,1,45));

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO MORE RECORDS TO READ');
                         EXIT;
                    WHEN OTHERS THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while reading '||sqlerrm);
                         RETCODE := 2;
                         EXIT;
            END;

            lc_curr_line    := substr(lc_curr_line,1,958);
            lc_program_name := rtrim(substr(lc_curr_line,214,60));
            lc_appl_name    := rtrim(substr(lc_curr_line,84,8));
            lc_parms        := '';
            lc_exec_name    := '';
            lc_user_name    := '';
            lc_method       := '';
            lc_parms        := '';
            lc_real_appl    := '';
            lc_short_name   := '';
            lc_resp_name    := '';
            lc_pgm_args     := '';

            IF lc_program_name is NOT NULL    THEN
               IF lc_program_name <> 'ESP-PROXY' THEN

                  FND_FILE.PUT_LINE(FND_FILE.LOG, '        Appl_name = '||lc_appl_name||' Program = '||lc_program_name);
                  BEGIN
                      SELECT rpad(E.EXECUTION_FILE_NAME, 60,' '),
                             rpad(convert(p.user_concurrent_program_name, 'US7ASCII', 'UTF8'), 60,' '),
                             E.EXECUTION_METHOD_CODE,
                             LISTAGG(cu.END_USER_COLUMN_NAME,', ') WITHIN GROUP
                                    (ORDER BY cu.END_USER_COLUMN_NAME) AS PGM_PARMS
                      INTO   lc_exec_name,
                             lc_user_name,
                             lc_method,
                             lc_parms
                      FROM   FND_EXECUTABLES_VL           E,
                             FND_CONCURRENT_PROGRAMS_vl   P,
                             FND_APPLICATION_VL           A,
                             FND_DESCR_FLEX_COLUMN_USAGES CU
                      WHERE  E.EXECUTABLE_ID                  = P.EXECUTABLE_ID
                      AND    E.APPLICATION_ID                 = A.APPLICATION_ID
                      AND    CU.APPLICATION_ID(+)             = P.application_id 
                      AND    CU.DESCRIPTIVE_FLEXFIELD_NAME(+) = '$SRS$.' || P.concurrent_program_name
                      AND    A.APPLICATION_SHORT_NAME         = lc_appl_name
                      AND    P.CONCURRENT_PROGRAM_NAME        = lc_program_name
                      AND    P.ENABLED_FLAG                   = 'Y'
                      AND    CU.ENABLED_FLAG(+)               = 'Y'
                      GROUP BY rpad(E.EXECUTION_FILE_NAME, 60,' '),
                               rpad(convert(p.user_concurrent_program_name, 'US7ASCII', 'UTF8'), 60,' '),
                               E.EXECUTION_METHOD_CODE;
  
                      FND_FILE.PUT_LINE(FND_FILE.LOG, '        1. Data found = '||lc_exec_name||' '||lc_user_name);
                      lc_resp_name := LTRIM(RTRIM(SUBSTR(lc_curr_line,95,46)),' ');
                      lc_pgm_args  := RTRIM(SUBSTR(lc_curr_line,275,641));
                      lc_curr_line := SUBSTR(lc_curr_line,1,94)||'"'||
                                      SUBSTR(RPAD(lc_resp_name||'"',60,' '),1,47)||
                                      RPAD(RTRIM('"'||lc_user_name)||'"',80,' ')||
                                      SUBSTR(lc_curr_line,214,60)||                                  -- concurrent_program_name
                                      SUBSTR(RPAD('"'||LTRIM(lc_pgm_args)||' "',641,' '),1,641)||
                                      lc_exec_name||
                                      lc_method||
                                      lc_parms;
                      UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);

                      EXCEPTION
                          WHEN NO_DATA_FOUND THEN
                               BEGIN
                                   SELECT rpad(E.EXECUTION_FILE_NAME, 60,' '),
                                          rpad(convert(p.user_concurrent_program_name, 'US7ASCII', 'UTF8'), 60,' '),
                                          A.APPLICATION_SHORT_NAME,
                                          E.EXECUTION_METHOD_CODE,
                                         (SELECT LISTAGG(cu.END_USER_COLUMN_NAME,', ') WITHIN GROUP
                                                        (ORDER BY cu.END_USER_COLUMN_NAME)
                                          FROM   FND_DESCR_FLEX_COLUMN_USAGES CU
                                          WHERE  CU.APPLICATION_ID             = P.application_id 
                                          AND    CU.DESCRIPTIVE_FLEXFIELD_NAME = '$SRS$.' || P.concurrent_program_name
                                          AND    CU.ENABLED_FLAG               = 'Y') AS PGM_PARMS
                                   INTO   lc_exec_name,
                                          lc_user_name,
                                          lc_real_appl,
                                          lc_method,
                                          lc_parms
                                   FROM   FND_EXECUTABLES_VL           E,
                                          FND_CONCURRENT_PROGRAMS_vl   P,
                                          FND_APPLICATION_VL           A
                                   WHERE  E.EXECUTABLE_ID               = P.EXECUTABLE_ID
                                   AND    E.APPLICATION_ID              = A.APPLICATION_ID
                                   AND    P.CONCURRENT_PROGRAM_NAME     = lc_program_name
                                   AND    P.ENABLED_FLAG                = 'Y'
                                   AND    ROWNUM = 1;
  
                                   FND_FILE.PUT_LINE(FND_FILE.LOG, '        2. Data found = '||lc_exec_name||' '||lc_user_name||' Real Applname = '||lc_real_appl);
                                   lc_resp_name := LTRIM(RTRIM(SUBSTR(lc_curr_line,95,46)),' ');
                                   lc_pgm_args  := RTRIM(SUBSTR(lc_curr_line,275,641));
                                   lc_curr_line := SUBSTR(lc_curr_line,1,94)||'"'||
                                                   SUBSTR(RPAD(lc_resp_name||'"',60,' '),1,47)||
                                                   RPAD(RTRIM('"'||lc_user_name)||'"',80,' ')||
                                                   SUBSTR(lc_curr_line,214,60)||                               -- concurrent_program_name
                                                   SUBSTR(RPAD('"'||LTRIM(lc_pgm_args)||' "',641,' '),1,641)||
                                                   lc_exec_name||
                                                   lc_method||
                                                   lc_parms;
                                   UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);
             
                                   EXCEPTION
                                       WHEN NO_DATA_FOUND THEN
                                            FND_FILE.PUT_LINE(FND_FILE.LOG, '3. NO DATA FOUND FOR PGM '||lc_program_name);
                                            lc_resp_name := RTRIM(SUBSTR(lc_curr_line,95,46));
                                            lc_pgm_args  := RTRIM(SUBSTR(lc_curr_line,275,641));
                                            lc_curr_line := SUBSTR(lc_curr_line,1,94)||'"'||
                                                            SUBSTR(RPAD(lc_resp_name||'"',60,' '),1,47)||
                                                            RPAD(RTRIM('"'||lc_user_name)||'"',80,' ')||
                                                            SUBSTR(lc_curr_line,214,60)||                               -- concurrent_program_name
                                                            SUBSTR(RPAD('"'||LTRIM(lc_pgm_args)||' "',641,' '),1,641)||
                                                            lc_exec_name||
                                                            lc_method||
                                                            lc_parms;
                                            UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);
                                            FND_FILE.PUT_LINE(FND_FILE.LOG, '3. Writing out data anyway '||lc_program_name);
                                            RETCODE := 1;
                                       WHEN OTHERS THEN
                                            FND_FILE.PUT_LINE(FND_FILE.LOG, '4. Error retrieving program data '||SQLERRM);
                                            RETCODE := 2;
                                            EXIT;
                               END;
                          WHEN OTHERS THEN
                               FND_FILE.PUT_LINE(FND_FILE.LOG, '1. Error retrieving program data '||SQLERRM);
                               RETCODE := 2;
                               EXIT;
                  END;
               ELSE
                  BEGIN
                      lc_event_name := substr(lc_curr_line,11,8);
                      lc_job_name   := substr(lc_curr_line,20,8);
                      FND_FILE.PUT_LINE(FND_FILE.LOG, '        Event_name = '||lc_event_name||' Job_name = '||lc_job_name);

                      SELECT V.target_value3,
                             convert(p.user_concurrent_program_name, 'US7ASCII', 'UTF8'),
                             rpad(E.EXECUTION_FILE_NAME, 60,' '), 
                             V.target_value1,
                             V.target_value2,
                             V.target_value4,
                             E.EXECUTION_METHOD_CODE,
                             LISTAGG(cu.END_USER_COLUMN_NAME,', ') WITHIN GROUP
                                    (ORDER BY cu.END_USER_COLUMN_NAME) AS PGM_PARMS
                      INTO   lc_short_name,
                             lc_user_name,
                             lc_exec_name,
                             lc_resp_name,
                             lc_appl_name,
                             lc_pgm_args,
                             lc_method,
                             lc_parms
                      FROM   XX_FIN_TRANSLATEDEFINITION   D,
                             XX_FIN_TRANSLATEVALUES       V,
                             FND_EXECUTABLES_VL           E,
                             FND_CONCURRENT_PROGRAMS_vl   P,
                             FND_APPLICATION_vl           A,
                             FND_DESCR_FLEX_COLUMN_USAGES CU
                      WHERE  D.translate_id                   = V.translate_id
                      AND    D.TRANSLATION_NAME               LIKE 'ESP_EF%_JOB_DEF'
                      AND    D.TRANSLATE_DESCRIPTION          LIKE '%ESP%'
                      AND    E.EXECUTABLE_ID                  = P.EXECUTABLE_ID
                      AND    E.APPLICATION_ID                 = A.APPLICATION_ID
                      AND    CU.APPLICATION_ID(+)             = P.application_id 
                      AND    CU.DESCRIPTIVE_FLEXFIELD_NAME(+) = '$SRS$.' || P.concurrent_program_name
                      AND    CU.ENABLED_FLAG(+)               = 'Y'
                      AND    A.PRODUCT_CODE                   = v.target_value2
                      AND    P.CONCURRENT_PROGRAM_NAME        = v.target_value3
                      AND    v.source_value1                  = lc_event_name
                      AND    v.source_value2                  = lc_job_name
                      AND    sysdate BETWEEN V.START_DATE_ACTIVE AND NVL(V.END_DATE_ACTIVE,SYSDATE)
                      GROUP BY V.target_value3,
                               convert(p.user_concurrent_program_name, 'US7ASCII', 'UTF8'),
                               rpad(E.EXECUTION_FILE_NAME, 60,' '), 
                               V.target_value1,
                               V.target_value2,
                               V.target_value4,
                               E.EXECUTION_METHOD_CODE; 

                      FND_FILE.PUT_LINE(FND_FILE.LOG, '        5. Data found = '||lc_exec_name||' '||lc_user_name);
                      lc_curr_line := SUBSTR(lc_curr_line,1,83)||
                                      RPAD(lc_appl_name,11,' ')||'"'||
                                      SUBSTR(RPAD(lc_resp_name||'"',60,' '),1,47)||
                                      RPAD(RTRIM('"'||lc_user_name)||'"',80,' ')||
                                      RPAD(lc_short_name,60,' ')||
                                      SUBSTR(RPAD('"'||LTRIM(lc_pgm_args)||' "',641,' '),1,641)||
                                      lc_exec_name||
                                      lc_method||
                                      lc_parms;
                      UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);

                      EXCEPTION
                          WHEN NO_DATA_FOUND THEN
                               BEGIN
                                   SELECT V.target_value3,
                                          convert(p.user_concurrent_program_name, 'US7ASCII', 'UTF8'),
                                          rpad(E.EXECUTION_FILE_NAME, 60,' '), 
                                          V.target_value1,
                                          V.target_value2,
                                          V.target_value4,
                                          E.EXECUTION_METHOD_CODE,
                                          LISTAGG(cu.END_USER_COLUMN_NAME,', ') WITHIN GROUP
                                                 (ORDER BY cu.END_USER_COLUMN_NAME) AS PGM_PARMS
                                   INTO   lc_short_name,
                                          lc_user_name,
                                          lc_exec_name,
                                          lc_resp_name,
                                          lc_appl_name,
                                          lc_pgm_args,
                                          lc_method,
                                          lc_parms
                                   FROM   XX_FIN_TRANSLATEDEFINITION   D,
                                          XX_FIN_TRANSLATEVALUES       V,
                                          FND_EXECUTABLES_VL           E,
                                          FND_CONCURRENT_PROGRAMS_vl   P,
                                          FND_APPLICATION_vl           A,
                                          FND_DESCR_FLEX_COLUMN_USAGES CU
                                   WHERE  D.translate_id                   = V.translate_id
                                   AND    D.TRANSLATION_NAME               LIKE 'ESP_EF%_JOB_DEF'
                                   AND    D.TRANSLATE_DESCRIPTION          LIKE '%ESP%'
                                   AND    E.EXECUTABLE_ID                  = P.EXECUTABLE_ID
                                   AND    E.APPLICATION_ID                 = A.APPLICATION_ID
                                   AND    CU.APPLICATION_ID(+)             = P.application_id 
                                   AND    CU.DESCRIPTIVE_FLEXFIELD_NAME(+) = '$SRS$.' || P.concurrent_program_name
                                   AND    CU.ENABLED_FLAG(+)               = 'Y'
                                   AND    A.APPLICATION_SHORT_NAME         = v.target_value2
                                   AND    P.CONCURRENT_PROGRAM_NAME        = v.target_value3
                                   AND    v.source_value1                  = lc_event_name
                                   AND    v.source_value2                  = lc_job_name
                                   AND    sysdate BETWEEN V.START_DATE_ACTIVE AND NVL(V.END_DATE_ACTIVE,SYSDATE)
                                   GROUP BY V.target_value3,
                                            convert(p.user_concurrent_program_name, 'US7ASCII', 'UTF8'),
                                            rpad(E.EXECUTION_FILE_NAME, 60,' '), 
                                            V.target_value1,
                                            V.target_value2,
                                            V.target_value4,
                                            E.EXECUTION_METHOD_CODE; 

                                   FND_FILE.PUT_LINE(FND_FILE.LOG, '        6. Data found = '||lc_exec_name||' '||lc_user_name);
                                   lc_curr_line := SUBSTR(lc_curr_line,1,83)||
                                                   RPAD(lc_appl_name,11,' ')||'"'||
                                                   SUBSTR(RPAD(lc_resp_name||'"',60,' '),1,47)||
                                                   RPAD(RTRIM('"'||lc_user_name)||'"',80,' ')||
                                                   RPAD(lc_short_name,60,' ')||
                                                   SUBSTR(RPAD('"'||LTRIM(lc_pgm_args)||' "',641,' '),1,641)||
                                                   lc_exec_name||
                                                   lc_method||
                                                   lc_parms;
                                   UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);
  
                                   EXCEPTION
                                        WHEN NO_DATA_FOUND THEN
                                             FND_FILE.PUT_LINE(FND_FILE.LOG, '7. NO DATA FOUND FOR PGM '||lc_program_name);
                                             lc_resp_name := RTRIM(SUBSTR(lc_curr_line,95,47));
                                             lc_pgm_args  := RTRIM(SUBSTR(lc_curr_line,275,641));
                                             lc_curr_line := SUBSTR(lc_curr_line,1,94)||'"'||
                                                             SUBSTR(RPAD(lc_resp_name||'"',60,' '),1,47)||
                                                             RPAD(RTRIM('"'||lc_user_name)||'"',80,' ')||
                                                             SUBSTR(lc_curr_line,214,60)||
                                                             SUBSTR(RPAD('"'||LTRIM(lc_pgm_args)||' "',641,' '),1,641)|| 
                                                             lc_exec_name||
                                                             lc_method||
                                                             lc_parms;
                                             UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);
                                             FND_FILE.PUT_LINE(FND_FILE.LOG, '8. Writing out data anyway '||lc_program_name);
                                             RETCODE := 1;
                                        WHEN OTHERS THEN
                                             FND_FILE.PUT_LINE(FND_FILE.LOG, '9. Error retrieving program data '||SQLERRM);
                                             RETCODE := 2;
                                             EXIT;
                               END;

                          WHEN OTHERS THEN
                               FND_FILE.PUT_LINE(FND_FILE.LOG, 'OTHERS - Error retrieving program data '||SQLERRM);
                               RETCODE := 2;
                               EXIT;
                  END;
               END IF;
            ELSE
              FND_FILE.PUT_LINE(FND_FILE.LOG, '10. Nothing to do but write it out');
              UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);
            END IF;
        END LOOP;
    END;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Closing files - ');
    UTL_FILE.fclose(lc_input_file_handle);
    UTL_FILE.fclose(lc_output_file_handle);

EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_FIN_ESP_EXT_PKG OTHERS ERROR'||SQLERRM);
         RETCODE := 2;

END EXTRACT_ESP_DETAILS;

-- +===================================================================+
-- | PROCEDURE: XX_GET_TRANS_DEF_ID                                    |
-- |                                                                   |
-- | Description      : This Procedure will get the translatedefinition|
-- |                    translate_id if it exists. If it does not then |
-- |                    it will create a new entry.                    |
-- |                                                                   |
-- | Parameters      none                                              |
-- +===================================================================+
PROCEDURE XX_GET_TRANS_DEF_ID(p_member           IN  VARCHAR2,
                              p_trans_id         OUT NUMBER,
                              p_ret_code         OUT NUMBER)
IS
lc_translate_id         NUMBER;

BEGIN
    lc_translate_id := 0;
    p_ret_code      := 0;
    FND_FILE.PUT_LINE(FND_FILE.LOG, '    GET_TRANS_DEF_ID start for '||p_member);

    SELECT D.translate_id
    INTO   lc_translate_id
    FROM   xx_fin_translatedefinition D
    WHERE  D.translation_name like 'ESP_'||SUBSTR(p_member,1,4)||'_JOB_DEF'
    AND    D.translate_description like '%ESP%';

    p_trans_id := lc_translate_id;
    FND_FILE.PUT_LINE(FND_FILE.LOG, '    Found Definition id '||lc_translate_id);

    EXCEPTION
         WHEN NO_DATA_FOUND THEN
              BEGIN
                  SELECT XX_FIN_TRANSLATEDEFINITION_S.nextval 
                  INTO   lc_translate_id 
                  FROM   DUAL;

                  p_trans_id := lc_translate_id;
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '    Creating Definition for id '||lc_translate_id);

                  INSERT INTO xx_fin_translatedefinition 
                             (TRANSLATE_ID
                             ,TRANSLATION_NAME
                             ,PURPOSE
                             ,TRANSLATE_DESCRIPTION
                             ,RELATED_MODULE
                             ,SOURCE_FIELD1
                             ,SOURCE_FIELD2
                             ,TARGET_FIELD1
                             ,TARGET_FIELD2
                             ,TARGET_FIELD3
                             ,TARGET_FIELD4
                             ,TARGET_FIELD5
                             ,TARGET_FIELD6
                             ,TARGET_FIELD7
                             ,TARGET_FIELD8
                             ,TARGET_FIELD9
                             ,TARGET_FIELD10
                             ,TARGET_FIELD11
                             ,TARGET_FIELD12
                             ,TARGET_FIELD13
                             ,TARGET_FIELD14
                             ,TARGET_FIELD15
                             ,TARGET_FIELD16
                             ,TARGET_FIELD17
                             ,TARGET_FIELD18
                             ,CREATION_DATE
                             ,CREATED_BY
                             ,LAST_UPDATE_DATE
                             ,LAST_UPDATED_BY
                             ,LAST_UPDATE_LOGIN
                             ,START_DATE_ACTIVE
                             ,ENABLED_FLAG
                             ,DO_NOT_REFRESH)
                      VALUES (p_trans_id
                            ,'ESP_'||SUBSTR(p_member,1,4)||'_JOB_DEF'
                            ,'TRANSLATION'
                            ,'Concurrent program definitions for execution from ESP'
                            ,SUBSTR(p_member,3,2)
                            ,'ESP_Job_Name'
                            ,'ESP_Job_Qualifier'
                            ,'Responsibility_Name'
                            ,'Program_Appl_Name'
                            ,'Program_Short_Name'
                            ,'Program_Args'
                            ,'Check_Interval_Secs'
                            ,'Max_Wait_Secs'
                            ,'Wait_For_Child_Level'
                            ,'Use_Program_Defaults'
                            ,'XDO_App_Name'
                            ,'XDO_Template_Code'
                            ,'XDO_Language'
                            ,'XDO_Territory'
                            ,'XDO_Output_Format'
                            ,'Printer_Name'
                            ,'Print_Style'
                            ,'Print_Num_Copies'
                            ,'Fail_On_Warning (No)'
                            ,'Comments'
                            ,CURRENT_DATE
                            ,-1
                            ,CURRENT_DATE
                            ,-1
                            ,-1
                            ,CURRENT_DATE
                            ,'Y'
                            ,'N');
                  COMMIT;
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '    Successfully inserted Definition '||lc_translate_id);

              EXCEPTION
                   WHEN OTHERS THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while inserting Translatedefinitions for '||p_member||' error = '||sqlerrm);
                        p_ret_code := 2;
              END;
         WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while selecting Translatedefinitions for '||p_member||' error = '||sqlerrm);
              p_ret_code := 2;

END XX_GET_TRANS_DEF_ID;

-- +===================================================================+
-- | PROCEDURE: XX_GET_TRANS_VAL_ID                                    |
-- |                                                                   |
-- | Description      : This Procedure will insert, or update the      |
-- |                    translatevalues entry specified by the fields  |
-- |                    source_value1 and source_value2                |
-- |                                                                   |
-- | Parameters      none                                              |
-- +===================================================================+
PROCEDURE XX_GET_TRANS_VAL_ID(p_trans_id         IN  NUMBER,
                              p_member_name      IN  VARCHAR2,
                              p_job_name_1       IN  VARCHAR2,
                              p_job_name_2       IN  VARCHAR2,
                              p_rel_name_1       IN  VARCHAR2,
                              p_rel_name_2       IN  VARCHAR2,
                              p_appl_name        IN  VARCHAR2,
                              p_resp_name        IN  VARCHAR2,
                              p_user_name        IN  VARCHAR2,
                              p_short_name       IN  VARCHAR2,
                              p_pgm_args         IN  VARCHAR2,
                              p_exec_name        IN  VARCHAR2,
                              p_ret_code         OUT NUMBER)
IS
lc_translate_value_id   NUMBER;

BEGIN
    lc_translate_value_id := 0;
    p_ret_code            := 0;
    FND_FILE.PUT_LINE(FND_FILE.LOG, '    GET_TRANS_VAL_ID start for '||p_job_name_1||'-'||p_job_name_2||'-'||p_trans_id);

    BEGIN

        SELECT V.translate_value_id
        INTO   lc_translate_value_id
        FROM   xx_fin_translatevalues V
        WHERE  V.source_value1 = p_job_name_1
        AND    V.source_value2 = p_job_name_2
        AND    V.translate_id  = p_trans_id;

        FND_FILE.PUT_LINE(FND_FILE.LOG, '    Found Definition values id '||lc_translate_value_id);

        UPDATE xx_fin_translatevalues V
        SET    V.target_value1  = P_resp_name, 
               V.target_value2  = P_appl_name, 
               V.target_value3  = P_short_name, 
               V.target_value4  = P_pgm_args, 
               V.target_value19 = P_member_name,
               V.target_value20 = P_exec_name
        WHERE  V.source_value1  = P_job_name_1
        AND    V.source_value2  = P_job_name_2
        AND    V.translate_id   = p_trans_id
        AND    V.translate_value_id = lc_translate_value_id;

        COMMIT;
        FND_FILE.PUT_LINE(FND_FILE.LOG, '    Successfully updated Definition values id '||lc_translate_value_id);

        EXCEPTION
             WHEN NO_DATA_FOUND THEN   
                  BEGIN
                      SELECT XX_FIN_TRANSLATEVALUES_S.nextval 
                      INTO  lc_translate_value_id 
                      FROM DUAL;

                      FND_FILE.PUT_LINE(FND_FILE.LOG, '    Creating Definition values id '||lc_translate_value_id);

                      INSERT INTO xxfin.xx_fin_translatevalues 
                                 (TRANSLATE_ID
                                 ,SOURCE_VALUE1
                                 ,SOURCE_VALUE2
                                 ,TARGET_VALUE1
                                 ,TARGET_VALUE2
                                 ,TARGET_VALUE3
                                 ,TARGET_VALUE4
                                 ,TARGET_VALUE19
                                 ,TARGET_VALUE20
                                 ,CREATION_DATE
                                 ,CREATED_BY
                                 ,LAST_UPDATE_DATE
                                 ,LAST_UPDATED_BY
                                 ,START_DATE_ACTIVE
                                 ,ENABLED_FLAG
                                 ,TRANSLATE_VALUE_ID) 
                          VALUES (p_trans_id
                                 ,p_job_name_1
                                 ,p_job_name_2
                                 ,p_resp_name
                                 ,p_appl_name
                                 ,p_short_name
                                 ,p_pgm_args
                                 ,p_member_name
                                 ,p_exec_name
                                 ,CURRENT_DATE
                                 ,-1
                                 ,CURRENT_DATE
                                 ,-1
                                 ,CURRENT_DATE
                                 ,'Y'
                                 ,lc_translate_value_id);
                             COMMIT;
                             FND_FILE.PUT_LINE(FND_FILE.LOG, '    Successfully created Definition values id '||lc_translate_value_id);
                      EXCEPTION
                           WHEN OTHERS THEN
                                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while inserting Translatevalues for '||p_job_name_1||'.'||p_job_name_2||' error = '||sqlerrm);
                                p_ret_code := 2;
                  END;  
             WHEN OTHERS THEN           
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while updating Translatevalues for '||p_job_name_1||'.'||p_job_name_2||' error = '||sqlerrm);
                  p_ret_code := 2;
    END;

END XX_GET_TRANS_VAL_ID;

-- +===================================================================+
-- | PROCEDURE: UPDATE_ESP_DETAILS                                     |
-- |                                                                   |
-- | Concurrent Program : Update ESP Details                           |
-- | Short_name         : XX_RJS_ESP_EXT_2                             |
-- | Executable         : XX_FIN_ESP_EXT_PKG.UPDATE_ESP_DETAILS        |
-- |                                                                   |
-- | Description      : This Procedure will read the file produced by  |
-- |                    ESP Extract Details, and update the ESP-PROXY  |
-- |                    translation table entries.                     |
-- |                                                                   |
-- | Parameters      none                                              |
-- +===================================================================+
PROCEDURE UPDATE_ESP_DETAILS(errbuf       OUT NOCOPY VARCHAR2,
                             retcode      OUT NOCOPY NUMBER)
IS
lc_curr_line            VARCHAR2 (1200);
lc_return_status        VARCHAR2(100);
lc_input_file_handle    UTL_FILE.file_type;
lc_comment              VARCHAR2(61);
lc_translate_id         NUMBER;
lc_translate_value_id   NUMBER;
lc_ret_code             NUMBER;

lc_member_name          VARCHAR2(8);
lc_job_name             VARCHAR2(34);
lc_job_name_1           VARCHAR2(8);
lc_job_name_2           VARCHAR2(8);
lc_flag_1               VARCHAR2(1);
lc_flag_2               VARCHAR2(1);
lc_flag_3               VARCHAR2(1);
lc_rel_name             VARCHAR2(34);
lc_rel_name_1           VARCHAR2(8);
lc_rel_name_2           VARCHAR2(8);
lc_appl_name            VARCHAR2(8);
lc_resp_name            VARCHAR2(60);
lc_user_name            VARCHAR2(80);
lc_short_name           VARCHAR2(60);
lc_pgm_args_c           VARCHAR2(642);
lc_pgm_args             VARCHAR2(240);
lc_exec_name            VARCHAR2(60);

BEGIN

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_FIN_ESP_EXT_PKG Begin:');

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Opening Input File - XX_RJS_ESP_OUTPUT.txt ');
        lc_input_file_handle := UTL_FILE.fopen('XXFIN_OUTBOUND', 'XX_RJS_ESP_OUTPUT.txt', 'R',1200);

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
                 UTL_FILE.fclose (lc_input_file_handle);
    END;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Start Processing Data - ');

    BEGIN
        LOOP
            BEGIN

                lc_curr_line := NULL;
                UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
                FND_FILE.PUT_LINE(FND_FILE.LOG, '    Data read = '||SUBSTR(lc_curr_line,1,45));

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO MORE RECORDS TO READ');
                         EXIT;
                    WHEN OTHERS THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while reading '||sqlerrm);
                         RETCODE := 2;
                         EXIT;
            END;

            lc_curr_line := substr(lc_curr_line,1,985);

            lc_member_name := rtrim(substr(lc_curr_line,1,8));    
            lc_job_name    := rtrim(substr(lc_curr_line,11,34));           
            lc_job_name_1  := NVL(SUBSTR(lc_job_name,1,INSTRB(lc_job_name, '.', 1, 1)-1),lc_job_name);
            lc_job_name_2  := NVL(SUBSTR(lc_job_name,INSTRB(lc_job_name, '.', 1, 1)+1,LENGTH(lc_job_name)-INSTRB(lc_job_name, '.', 1, 1)),lc_job_name);   
            lc_flag_1      := rtrim(substr(lc_curr_line,45,1));    
            lc_flag_2      := rtrim(substr(lc_curr_line,46,1));           
            lc_flag_3      := rtrim(substr(lc_curr_line,47,1));    
            lc_rel_name    := rtrim(substr(lc_curr_line,49,34));    
            lc_rel_name_1  := NVL(SUBSTR(lc_rel_name,1,INSTRB(lc_rel_name, '.', 1, 1)-1),lc_rel_name);    
            lc_rel_name_2  := NVL(SUBSTR(lc_rel_name,INSTRB(lc_rel_name, '.', 1, 1)+1,LENGTH(lc_rel_name)-INSTRB(lc_rel_name, '.', 1, 1)),lc_rel_name);   
            lc_appl_name   := rtrim(substr(lc_curr_line,84,10));    
            lc_resp_name   := ltrim(rtrim(substr(lc_curr_line,95,45),'" '),' "');    
            lc_user_name   := ltrim(rtrim(substr(lc_curr_line,141,61),'" '),' "');    
            lc_short_name  := rtrim(substr(lc_curr_line,223,60));    
            lc_pgm_args_c  := rtrim(ltrim(rtrim(substr(lc_curr_line,283,642),'" '),' "'));    
            lc_exec_name   := rtrim(substr(lc_curr_line,924,60));  

            IF LENGTH(lc_pgm_args_c) > 240 THEN 
               lc_pgm_args := SUBSTR(lc_pgm_args_c,1,240);
               RETCODE := 1;
               FND_FILE.PUT_LINE(FND_FILE.LOG, 'WARNING: - Program ARGS are longer than TARGET_VALUE4 '||LENGTH(lc_pgm_args_c));
            ELSE
               lc_pgm_args := SUBSTR(lc_pgm_args_c,1,240);
            END IF;

            FND_FILE.PUT_LINE(FND_FILE.LOG, '        Data parse = '||lc_member_name);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '                     '||lc_job_name);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '                     '||lc_job_name_1);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '                     '||lc_job_name_2);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '                     '||lc_flag_1);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '                     '||lc_rel_name);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '                     '||lc_rel_name_1);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '                     '||lc_rel_name_2);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '                     '||lc_appl_name);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '                     '||lc_resp_name);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '                     '||lc_user_name);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '                     '||lc_short_name);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '                     '||lc_pgm_args);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '                     '||lc_exec_name);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '                     '||sqlerrm);

            IF lc_flag_1 = '-'    THEN
               BEGIN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '    Attempting update of ESP-PROXY Definition values for'||lc_job_name_1||'-'||lc_job_name_2);
                  UPDATE xx_fin_translatevalues V
                  SET    V.target_value19 = lc_member_name,
                         V.target_value20 = lc_exec_name
                  WHERE  V.source_value1  = lc_job_name_1
                  AND    V.source_value2  = lc_job_name_2
                  AND    V.translate_id   = (SELECT D.translate_id
                                             FROM   xx_fin_translatedefinition D
                                             WHERE  D.translation_name like 'ESP_'||SUBSTR(lc_member_name,1,4)||'_JOB_DEF'
                                             AND    D.translate_description like '%ESP%');
                  COMMIT;
                  EXCEPTION
                      WHEN OTHERS THEN
                           FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while updating Translatevalues for '||lc_job_name_1||'.'||lc_job_name_2||' error = '||sqlerrm);
                           RETCODE := 1;
               END;
            ELSE
               XX_GET_TRANS_DEF_ID(p_member         => lc_member_name,
                                   p_trans_id       => lc_translate_id,
                                   p_ret_code       => lc_ret_code);

               IF lc_ret_code = 0 THEN
                  XX_GET_TRANS_VAL_ID(p_trans_id         => lc_translate_id,
                                      p_member_name      => lc_member_name, 
                                      p_job_name_1       => lc_job_name_1,
                                      p_job_name_2       => lc_job_name_2,
                                      p_rel_name_1       => lc_rel_name_1,
                                      p_rel_name_2       => lc_rel_name_2,
                                      p_appl_name        => lc_appl_name,
                                      p_resp_name        => lc_resp_name,
                                      p_user_name        => lc_user_name,
                                      p_short_name       => lc_short_name,
                                      p_pgm_args         => lc_pgm_args,
                                      p_exec_name        => lc_exec_name,
                                      p_ret_code         => lc_ret_code);
               ELSE
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '    Translation Definition routine failed rc '||lc_ret_code);
                  RETCODE := lc_ret_code;
               END IF;
            END IF;
        END LOOP;
    END;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Closing files - ');
    UTL_FILE.fclose(lc_input_file_handle);

EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_FIN_ESP_EXT_PKG OTHERS ERROR'||SQLERRM);
         RETCODE := 2;

END UPDATE_ESP_DETAILS;

-- +===================================================================+
-- | PROCEDURE: LOAD_ESP_DETAILS                                       |
-- |                                                                   |
-- | Concurrent Program : Load ESP Details                             |
-- | Short_name         : XX_RJS_ESP_EXT_4                             |
-- | Executable         : XX_FIN_ESP_EXT_PKG.LOAD_ESP_DETAILS          |
-- |                                                                   |
-- | Description      : This Procedure will read the ESP extracted     |
-- |                    LINK detail file and load the data into table  |
-- |                    XX_FIN_ESP_LINK                                |
-- |                                                                   |
-- | Parameters      none                                              |
-- +===================================================================+
PROCEDURE LOAD_ESP_DETAILS(errbuf       OUT NOCOPY VARCHAR2,
                           retcode      OUT NOCOPY NUMBER)
IS
lc_input_file_handle    UTL_FILE.file_type;
lc_curr_line            VARCHAR2 (2000);
lc_translate_value_id   NUMBER;

lc_member_name          VARCHAR2(8);
lc_job_name             VARCHAR2(34);
lc_job_name_1           VARCHAR2(8);
lc_job_name_2           VARCHAR2(8);
lc_flag_1               VARCHAR2(1);
lc_rel_name             VARCHAR2(34);
lc_rel_name_1           VARCHAR2(8);
lc_rel_name_2           VARCHAR2(8);
lc_appl_name            VARCHAR2(8);
lc_resp_name            VARCHAR2(60);
lc_user_name            VARCHAR2(80);
lc_short_name           VARCHAR2(60);
lc_pgm_args             VARCHAR2(642);
lc_parms                VARCHAR2(800);
lc_exec_name            VARCHAR2(60);
lc_type                 VARCHAR2(1);
lc_seq_num              NUMBER;

BEGIN

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_FIN_ESP_EXT_PKG Begin:');

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Opening Input File - XX_RJS_ESP_OUTPUT.txt ');
        lc_input_file_handle := UTL_FILE.fopen('XXFIN_OUTBOUND', 'XX_RJS_ESP_OUTPUT.txt', 'R',2000);

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
                 UTL_FILE.fclose (lc_input_file_handle);
    END;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Deleting XX_FIN_ESP_DETAILS data - ');

    DELETE XXFIN.xx_fin_esp_details;
    COMMIT;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Start Loading Data - ');

    BEGIN
        LOOP
            BEGIN
                lc_curr_line := NULL;
                UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
                FND_FILE.PUT_LINE(FND_FILE.LOG, '    Data read = '||SUBSTR(lc_curr_line,1,45));

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO MORE RECORDS TO READ');
                         EXIT;
                    WHEN OTHERS THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while reading '||sqlerrm);
                         RETCODE := 2;
                         EXIT;
            END;

            lc_curr_line := substr(lc_curr_line,1,2000);

            lc_member_name := rtrim(substr(lc_curr_line,1,8));     
            lc_job_name    := rtrim(substr(lc_curr_line,11,34)); 
            lc_job_name_1  := NVL(SUBSTR(lc_job_name,1,INSTRB(lc_job_name, '.', 1, 1)-1),lc_job_name);
            lc_job_name_2  := NVL(SUBSTR(lc_job_name,INSTRB(lc_job_name, '.', 1, 1)+1,LENGTH(lc_job_name)-INSTRB(lc_job_name, '.', 1, 1)),lc_job_name);            
            lc_flag_1      := rtrim(substr(lc_curr_line,45,1));             
            lc_appl_name   := rtrim(substr(lc_curr_line,84,10));    
            lc_resp_name   := ltrim(rtrim(substr(lc_curr_line,95,45),'" '),'"');    
            lc_user_name   := ltrim(rtrim(substr(lc_curr_line,143,61),'" '),'"');    
            lc_short_name  := rtrim(substr(lc_curr_line,223,59));    
            lc_pgm_args    := ltrim(rtrim(substr(lc_curr_line,283,641),'" '),'"');    
            lc_exec_name   := rtrim(substr(lc_curr_line,924,59));  
            lc_type        := (substr(lc_curr_line,984,1));
            lc_parms       := rtrim((substr(lc_curr_line,985,800)),' ');

          FND_FILE.PUT_LINE(FND_FILE.LOG, 'pgm arg value '||lc_parms);

            IF lc_flag_1 = 'J' THEN
               lc_appl_name  :='';
               lc_resp_name  :='';
               lc_short_name :='';
               lc_pgm_args   :='';
               lc_exec_name  :='';
               lc_type       :='';
               lc_parms      :='';
            END IF;

            IF lc_flag_1 = 'N' OR
               lc_flag_1 = 'M' THEN
               lc_resp_name  :='';
               lc_short_name :='';
               lc_pgm_args   :='';
               lc_exec_name  :='';
               lc_type       :='';
               lc_parms      :='';
            END IF;


            IF lc_flag_1 = 'S' THEN
               lc_appl_name  :='';
               lc_resp_name  :='';
               lc_short_name :='';
               lc_exec_name  :='';
               lc_type       :='';
               lc_parms      :='';
            END IF;

            BEGIN

                SELECT XXFIN.XX_FIN_ESP_DETAILS_S.NEXTVAL 
		    INTO   lc_seq_num
		    FROM DUAL;

                   INSERT INTO XXFIN.XX_FIN_ESP_DETAILS
                           (ESP_DETAIL_ID
                           ,ESP_APPLICATION
                           ,ESP_JOB_NAME_1
                           ,ESP_JOB_NAME_2
                           ,ESP_JOB_TYPE
                           ,ESP_OA_USER
                           ,ESP_RESPONSIBILITY
                           ,ESP_PGM_USER_NAME
                           ,ESP_PGM_SHORT_NAME
                           ,ESP_PGM_EXECUTABLE
                           ,ESP_PGM_TYPE
                           ,ESP_PGM_ARGS
                           ,ESP_PGM_ARG_VALUES
                           ,ATTRIBUTE1
                           ,ATTRIBUTE2
                           ,ATTRIBUTE3
                           ,ATTRIBUTE4
                           ,ATTRIBUTE5
                           ,ATTRIBUTE6
                           ,ATTRIBUTE7
                           ,ATTRIBUTE8
                           ,ATTRIBUTE9
                           ,CREATION_DATE
                           ,CREATED_BY
                           ,LAST_UPDATED_BY
                           ,LAST_UPDATE_DATE)
                     VALUES(lc_seq_num
                           ,lc_member_name
                           ,lc_job_name_1
                           ,lc_job_name_2
                           ,lc_flag_1
                           ,lc_appl_name
                           ,lc_resp_name
                           ,lc_user_name
                           ,lc_short_name
                           ,lc_exec_name
                           ,lc_type
                           ,lc_parms
                           ,lc_pgm_args
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,SYSDATE
                           ,-1
                           ,-1
                           ,SYSDATE);
                   COMMIT;
                   FND_FILE.PUT_LINE(FND_FILE.LOG, '    Created '||lc_flag_1||'-'||lc_job_name_1||'-'||lc_job_name_2);

                   EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                            FND_FILE.PUT_LINE(FND_FILE.LOG, '1. Data not found on translation table, job '||lc_job_name_1||'.'||lc_job_name_2);
                            RETCODE := 1;
                       WHEN OTHERS THEN
                            FND_FILE.PUT_LINE(FND_FILE.LOG, '1. Error - Others '||sqlerrm);
                            RETCODE := 2;
                            EXIT;
               END;

        END LOOP;
    END;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Closing files - ');
    UTL_FILE.fclose(lc_input_file_handle);

EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_FIN_ESP_EXT_PKG OTHERS ERROR'||SQLERRM);
         RETCODE := 2;

END LOAD_ESP_DETAILS;

-- +===================================================================+
-- | PROCEDURE: LOAD_ESP_LINKS                                         |
-- |                                                                   |
-- | Concurrent Program : Load ESP Links                               |
-- | Short_name         : XX_RJS_ESP_EXT_3                             |
-- | Executable         : XX_FIN_ESP_EXT_PKG.LOAD_ESP_LINKS            |
-- |                                                                   |
-- | Description      : This Procedure will read the ESP extracted     |
-- |                    LINK detail file and load the data into table  |
-- |                    XX_FIN_ESP_LINK                                |
-- |                                                                   |
-- | Parameters      none                                              |
-- +===================================================================+
PROCEDURE LOAD_ESP_LINKS(errbuf       OUT NOCOPY VARCHAR2,
                         retcode      OUT NOCOPY NUMBER)
IS
lc_input_file_handle    UTL_FILE.file_type;
lc_curr_line            VARCHAR2 (1200);
lc_detail_id            NUMBER;

lc_member_name          VARCHAR2(8);
lc_job_name             VARCHAR2(34);
lc_job_name_1           VARCHAR2(8);
lc_job_name_2           VARCHAR2(8);
lc_flag_1               VARCHAR2(1);
lc_flag_2               VARCHAR2(1);
lc_flag_3               VARCHAR2(1);
lc_rel_name             VARCHAR2(34);
lc_rel_name_1           VARCHAR2(8);
lc_rel_name_2           VARCHAR2(8);
lc_appl_name            VARCHAR2(8);
lc_resp_name            VARCHAR2(60);
lc_user_name            VARCHAR2(80);
lc_short_name           VARCHAR2(60);
lc_pgm_args             VARCHAR2(642);
lc_exec_name            VARCHAR2(60);

lc_hold_name_1          VARCHAR2(8);
lc_hold_name_2          VARCHAR2(8);

BEGIN

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_FIN_ESP_EXT_PKG Begin:');

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Opening Input File - XX_RJS_ESP_LINK.txt ');
        lc_input_file_handle := UTL_FILE.fopen('XXFIN_INBOUND', 'XX_RJS_ESP_LINK.txt', 'R',1000);

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
                 UTL_FILE.fclose (lc_input_file_handle);
    END;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Deleting XX_FIN_ESP_LINK data - ');

    DELETE XXFIN.xx_fin_esp_link;
    COMMIT;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Start Loading Data - ');

    BEGIN
        LOOP
            BEGIN
                lc_curr_line := NULL;
                UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
                FND_FILE.PUT_LINE(FND_FILE.LOG, '    Data read = '||SUBSTR(lc_curr_line,1,45));

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO MORE RECORDS TO READ');
                         EXIT;
                    WHEN OTHERS THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while reading '||sqlerrm);
                         RETCODE := 2;
                         EXIT;
            END;

            lc_curr_line := substr(lc_curr_line,1,985);

            lc_member_name := rtrim(substr(lc_curr_line,1,8));  
            lc_job_name    := rtrim(substr(lc_curr_line,11,34)); 
            lc_job_name_1  := NVL(SUBSTR(lc_job_name,1,INSTRB(lc_job_name, '.', 1, 1)-1),lc_job_name);
            lc_job_name_2  := NVL(SUBSTR(lc_job_name,INSTRB(lc_job_name, '.', 1, 1)+1,LENGTH(lc_job_name)-INSTRB(lc_job_name, '.', 1, 1)),lc_job_name);               
            lc_flag_1      := rtrim(substr(lc_curr_line,45,1));    
            lc_flag_2      := rtrim(substr(lc_curr_line,46,1));           
            lc_flag_3      := rtrim(substr(lc_curr_line,47,1));
            lc_rel_name    := rtrim(substr(lc_curr_line,49,34));
            lc_rel_name_1  := NVL(SUBSTR(lc_rel_name,1,INSTRB(lc_rel_name, '.', 1, 1)-1),lc_rel_name);    
            lc_rel_name_2  := NVL(SUBSTR(lc_rel_name,INSTRB(lc_rel_name, '.', 1, 1)+1,LENGTH(lc_rel_name)-INSTRB(lc_rel_name, '.', 1, 1)),lc_rel_name);           
            lc_appl_name   := rtrim(substr(lc_curr_line,84,10));    
            lc_resp_name   := ltrim(rtrim(substr(lc_curr_line,95,45),'"'),'"');    
            lc_user_name   := ltrim(rtrim(substr(lc_curr_line,141,61),'"'),'"');    
            lc_short_name  := rtrim(substr(lc_curr_line,223,60));    
            lc_pgm_args    := ltrim(rtrim(substr(lc_curr_line,283,642),'"'),'"');    
            lc_exec_name   := rtrim(substr(lc_curr_line,925,60));  

 

            IF lc_flag_2 = 'E' THEN
               BEGIN
                   SELECT ESP_DETAIL_ID
                   INTO   lc_detail_id
                   FROM   XXFIN.XX_FIN_ESP_DETAILS
                   WHERE  ESP_JOB_NAME_1 = lc_rel_name_1
                   AND    ESP_JOB_NAME_2 = lc_rel_name_2
                   AND    ROWNUM = 1;

                   INSERT INTO XXFIN.XX_FIN_ESP_LINK
                           (ESP_DETAIL_ID
                           ,ESP_PGM_LINK_TYPE
                           ,ESP_PGM_LINK_APPL
                           ,ESP_PGM_LINK_JOB
                           ,ATTRIBUTE1
                           ,ATTRIBUTE2
                           ,ATTRIBUTE3
                           ,ATTRIBUTE4
                           ,ATTRIBUTE5
                           ,ATTRIBUTE6
                           ,ATTRIBUTE7
                           ,ATTRIBUTE8
                           ,ATTRIBUTE9
                           ,ATTRIBUTE10
                           ,CREATION_DATE
                           ,CREATED_BY
                           ,LAST_UPDATED_BY
                           ,LAST_UPDATE_DATE)
                     VALUES(lc_detail_id
                           ,lc_flag_2
                           ,lc_job_name_1
                           ,lc_job_name_2
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,SYSDATE
                           ,-1
                           ,-1
                           ,SYSDATE);
                   COMMIT;
                   FND_FILE.PUT_LINE(FND_FILE.LOG, '    Created '||lc_flag_2||'-'||lc_rel_name_1||'-'||lc_rel_name_2);

                   SELECT ESP_DETAIL_ID
                   INTO   lc_detail_id
                   FROM   XXFIN.XX_FIN_ESP_DETAILS
                   WHERE  ESP_JOB_NAME_1 = lc_job_name_1
                   AND    ESP_JOB_NAME_2 = lc_job_name_2
                   AND    ROWNUM = 1;

                   INSERT INTO XXFIN.XX_FIN_ESP_LINK
                           (ESP_DETAIL_ID
                           ,ESP_PGM_LINK_TYPE
                           ,ESP_PGM_LINK_APPL
                           ,ESP_PGM_LINK_JOB
                           ,ATTRIBUTE1
                           ,ATTRIBUTE2
                           ,ATTRIBUTE3
                           ,ATTRIBUTE4
                           ,ATTRIBUTE5
                           ,ATTRIBUTE6
                           ,ATTRIBUTE7
                           ,ATTRIBUTE8
                           ,ATTRIBUTE9
                           ,ATTRIBUTE10
                           ,CREATION_DATE
                           ,CREATED_BY
                           ,LAST_UPDATED_BY
                           ,LAST_UPDATE_DATE)
                     VALUES(lc_detail_id
                           ,'X'
                           ,lc_rel_name_1
                           ,lc_rel_name_2
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,SYSDATE
                           ,-1
                           ,-1
                           ,SYSDATE);
                   COMMIT;
                   FND_FILE.PUT_LINE(FND_FILE.LOG, '    Created '||'X'||'-'||lc_job_name_1||'-'||lc_job_name_2);
                   lc_flag_3 := '';

                   EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                            FND_FILE.PUT_LINE(FND_FILE.LOG, '1. Data not found on translation table, job '||lc_job_name_1||'.'||lc_job_name_2);
                            RETCODE := 1;
                       WHEN OTHERS THEN
                            FND_FILE.PUT_LINE(FND_FILE.LOG, '1. Error - Others '||sqlerrm);
                            RETCODE := 2;
                            EXIT;
               END;
            END IF;

            IF lc_flag_3 = 'R' OR
               lc_flag_3 = 'T' THEN

               BEGIN

                   SELECT ESP_DETAIL_ID
                   INTO   lc_detail_id
                   FROM   XXFIN.XX_FIN_ESP_DETAILS
                   WHERE  ESP_JOB_NAME_1 = lc_job_name_1
                   AND    ESP_JOB_NAME_2 = lc_job_name_2
                   AND    ROWNUM = 1;

                   INSERT INTO XXFIN.XX_FIN_ESP_LINK
                           (ESP_DETAIL_ID
                           ,ESP_PGM_LINK_TYPE
                           ,ESP_PGM_LINK_APPL
                           ,ESP_PGM_LINK_JOB
                           ,ATTRIBUTE1
                           ,ATTRIBUTE2
                           ,ATTRIBUTE3
                           ,ATTRIBUTE4
                           ,ATTRIBUTE5
                           ,ATTRIBUTE6
                           ,ATTRIBUTE7
                           ,ATTRIBUTE8
                           ,ATTRIBUTE9
                           ,ATTRIBUTE10
                           ,CREATION_DATE
                           ,CREATED_BY
                           ,LAST_UPDATED_BY
                           ,LAST_UPDATE_DATE)
                     VALUES(lc_detail_id
                           ,lc_flag_3
                           ,lc_rel_name_1
                           ,lc_rel_name_2
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,SYSDATE
                           ,-1
                           ,-1
                           ,SYSDATE);
                   COMMIT;
                   FND_FILE.PUT_LINE(FND_FILE.LOG, '    Created '||lc_flag_3||'-'||lc_job_name_1||'-'||lc_job_name_2);

                   IF lc_flag_3  = 'R' THEN
                      lc_flag_3 := 'D';
                   END IF;

                   IF lc_flag_3  = 'T' THEN
                      lc_flag_3 := 'A';
                   END IF;

                   SELECT ESP_DETAIL_ID
                   INTO   lc_detail_id
                   FROM   XXFIN.XX_FIN_ESP_DETAILS
                   WHERE  ESP_JOB_NAME_1 = lc_rel_name_1
                   AND    ESP_JOB_NAME_2 = lc_rel_name_2
                   AND    ROWNUM = 1;

                   INSERT INTO XXFIN.XX_FIN_ESP_LINK
                           (ESP_DETAIL_ID
                           ,ESP_PGM_LINK_TYPE
                           ,ESP_PGM_LINK_APPL
                           ,ESP_PGM_LINK_JOB
                           ,ATTRIBUTE1
                           ,ATTRIBUTE2
                           ,ATTRIBUTE3
                           ,ATTRIBUTE4
                           ,ATTRIBUTE5
                           ,ATTRIBUTE6
                           ,ATTRIBUTE7
                           ,ATTRIBUTE8
                           ,ATTRIBUTE9
                           ,ATTRIBUTE10
                           ,CREATION_DATE
                           ,CREATED_BY
                           ,LAST_UPDATED_BY
                           ,LAST_UPDATE_DATE)
                     VALUES(lc_detail_id
                           ,lc_flag_3
                           ,lc_job_name_1
                           ,lc_job_name_2
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,SYSDATE
                           ,-1
                           ,-1
                           ,SYSDATE);
                   COMMIT;
                   FND_FILE.PUT_LINE(FND_FILE.LOG, '    Created '||lc_flag_3||'-'||lc_rel_name_1||'-'||lc_rel_name_2);

                   EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                            FND_FILE.PUT_LINE(FND_FILE.LOG, '2. Data not found on translation table, job '||lc_job_name_1||'.'||lc_job_name_2);
                            RETCODE := 1;
                       WHEN OTHERS THEN
                            FND_FILE.PUT_LINE(FND_FILE.LOG, '2. Error - Others '||sqlerrm);
                            RETCODE := 2;
                            EXIT;
               END;
            END IF;
  
        END LOOP;
    END;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Closing files - ');
    UTL_FILE.fclose(lc_input_file_handle);

EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_FIN_ESP_EXT_PKG OTHERS ERROR'||SQLERRM);
         RETCODE := 2;

END LOAD_ESP_LINKS;

-- +===================================================================+
-- | PROCEDURE: LOAD_ESP_SCHED                                         |
-- |                                                                   |
-- | Concurrent Program : Load ESP SCHEDULE                            |
-- | Short_name         : XX_RJS_ESP_EXT_5                             |
-- | Executable         : XX_FIN_ESP_EXT_PKG.LOAD_ESP_SCHED            |
-- |                                                                   |
-- | Description      : This Procedure will read the ESP extracted     |
-- |                    SCHEDULE file and load the data into           |
-- |                    table  XX_FIN_ESP_SCHEDULE                     | 
-- |                    table  XX_FIN_ESP_INVOKE                       |
-- |                                                                   |
-- | Parameters      none                                              |
-- +===================================================================+
PROCEDURE LOAD_ESP_SCHED(errbuf       OUT NOCOPY VARCHAR2,
                         retcode      OUT NOCOPY NUMBER)
IS
lc_input_file_handle    UTL_FILE.file_type;
lc_curr_line            VARCHAR2 (2000);
lc_translate_value_id   NUMBER;

lc_member_pref          VARCHAR2(8);
lc_member_event         VARCHAR2(8);
lc_member_sys           VARCHAR2(8);
lc_member_dsn           VARCHAR2(38);
lc_member_mem           VARCHAR2(8);
lc_member_flg           VARCHAR2(1);
lc_member_schd          VARCHAR2(80);
lc_seq_num              NUMBER;

BEGIN

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_FIN_ESP_EXT_PKG Begin:');

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Opening Input File - XX_RJS_ESP_SCHEDULE.txt ');
        lc_input_file_handle := UTL_FILE.fopen('XXFIN_INBOUND', 'XX_RJS_ESP_SCHEDULE.txt', 'R',1000);

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
                 UTL_FILE.fclose (lc_input_file_handle);
    END;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Deleting XX_FIN_ESP_SCHEDULE data - ');

    DELETE XXFIN.xx_fin_esp_schedule;
    COMMIT;

    DELETE XXFIN.xx_fin_esp_invoke;
    COMMIT;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Start Loading Data - ');

    BEGIN
        LOOP
            BEGIN
                lc_curr_line := NULL;
                UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
                FND_FILE.PUT_LINE(FND_FILE.LOG, '    Data read = '||SUBSTR(lc_curr_line,1,45));

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO MORE RECORDS TO READ');
                         EXIT;
                    WHEN OTHERS THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while reading '||sqlerrm);
                         RETCODE := 2;
                         EXIT;
            END;

            lc_curr_line := substr(lc_curr_line,1,2000);
            lc_member_pref  := rtrim(substr(lc_curr_line,1,8));  
            lc_member_event := rtrim(substr(lc_curr_line,11,8)); 
            lc_member_sys   := rtrim(substr(lc_curr_line,21,8)); 
            lc_member_dsn   := rtrim(substr(lc_curr_line,31,38)); 
            lc_member_mem   := rtrim(substr(lc_curr_line,71,8)); 
            lc_member_flg   := rtrim(substr(lc_curr_line,80,1)); 
            lc_member_schd  := rtrim(substr(lc_curr_line,82,50));    


            IF lc_member_flg = 'I' THEN
               BEGIN
                   SELECT XXFIN.XX_FIN_ESP_INVOKE_S.NEXTVAL 
       		    INTO   lc_seq_num
		    FROM DUAL;

                   INSERT INTO XXFIN.XX_FIN_ESP_INVOKE
                           (ESP_DETAIL_ID
                           ,ESP_EVENT
                           ,ESP_PREFIX
                           ,ESP_SYSTEM
                           ,ESP_DATASETNAME
                           ,ESP_MEMBER
                           ,ATTRIBUTE1
                           ,ATTRIBUTE2
                           ,ATTRIBUTE3
                           ,ATTRIBUTE4
                           ,ATTRIBUTE5
                           ,ATTRIBUTE6
                           ,ATTRIBUTE7
                           ,ATTRIBUTE8
                           ,ATTRIBUTE9
                           ,CREATION_DATE
                           ,CREATED_BY
                           ,LAST_UPDATED_BY
                           ,LAST_UPDATE_DATE)
                     VALUES(lc_seq_num
                           ,lc_member_EVENT
                           ,lc_MEMBER_PREF
                           ,lc_MEMBER_SYS
                           ,lc_MEMBER_DSN
                           ,lc_MEMBER_MEM
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,SYSDATE
                           ,-1
                           ,-1
                           ,SYSDATE);
                   COMMIT;
                   FND_FILE.PUT_LINE(FND_FILE.LOG, '    Created '||lc_member_flg||'-'||lc_member_event);

                   EXCEPTION
                       WHEN OTHERS THEN
                            FND_FILE.PUT_LINE(FND_FILE.LOG, '1. Error - Others '||sqlerrm);
                            RETCODE := 2;
                            EXIT;
               END;
            ELSE
               BEGIN

                   SELECT XXFIN.XX_FIN_ESP_SCHEDULE_S.NEXTVAL 
       		    INTO   lc_seq_num
		    FROM DUAL;

                   INSERT INTO XXFIN.XX_FIN_ESP_SCHEDULE
                           (ESP_SCHED_ID
                           ,ESP_EVENT
                           ,ESP_PREFIX
                           ,ESP_SYSTEM
                           ,ESP_SCHED_TYPE
                           ,ESP_SCHEDULE
                           ,ATTRIBUTE1
                           ,ATTRIBUTE2
                           ,ATTRIBUTE3
                           ,ATTRIBUTE4
                           ,ATTRIBUTE5
                           ,ATTRIBUTE6
                           ,ATTRIBUTE7
                           ,ATTRIBUTE8
                           ,ATTRIBUTE9
                           ,CREATION_DATE
                           ,CREATED_BY
                           ,LAST_UPDATED_BY
                           ,LAST_UPDATE_DATE)
                     VALUES(lc_seq_num
                           ,lc_member_EVENT
                           ,lc_MEMBER_PREF
                           ,lc_MEMBER_SYS
                           ,lc_MEMBER_FLG
                           ,lc_MEMBER_SCHD
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,SYSDATE
                           ,-1
                           ,-1
                           ,SYSDATE);
                   COMMIT;
                   FND_FILE.PUT_LINE(FND_FILE.LOG, '    Created '||lc_member_flg||'-'||lc_member_event);

                   EXCEPTION
                       WHEN OTHERS THEN
                            FND_FILE.PUT_LINE(FND_FILE.LOG, '1. Error - Others '||sqlerrm);
                            RETCODE := 2;
                            EXIT;
                END;
            END IF;

        END LOOP;
    END;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Closing files - ');
    UTL_FILE.fclose(lc_input_file_handle);

EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_FIN_ESP_EXT_PKG OTHERS ERROR'||SQLERRM);
         RETCODE := 2;

END LOAD_ESP_SCHED;

-- +===================================================================+
-- | PROCEDURE: LOAD_ESP_RUNS                                          |
-- |                                                                   |
-- | Concurrent Program : Load ESP RUNS                                |
-- | Short_name         : XX_RJS_ESP_EXT_6                             |
-- | Executable         : XX_FIN_ESP_EXT_PKG.LOAD_ESP_RUNS             |
-- |                                                                   |
-- | Description      : This Procedure will read the ESP extracted     |
-- |                    SCHEDULE file and load the data into           |
-- |                    table  XX_FIN_ESP_RUNS                         | 
-- |                                                                   |
-- | Parameters      none                                              |
-- +===================================================================+
PROCEDURE LOAD_ESP_RUNS(errbuf       OUT NOCOPY VARCHAR2,
                        retcode      OUT NOCOPY NUMBER)
IS
lc_input_file_handle    UTL_FILE.file_type;
lc_curr_line            VARCHAR2 (2000);
lc_translate_value_id   NUMBER;

lc_member_appl          VARCHAR2(8);
lc_job_name             VARCHAR2(34);
lc_job_name_1           VARCHAR2(8);
lc_job_name_2           VARCHAR2(8);
lc_runs                 VARCHAR2(80);
lc_seq_num              NUMBER;
lc_detail_id            NUMBER;

BEGIN

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_RJS_ESP_EXT_6_PKG Begin:');

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Opening Input File - XX_RJS_ESP_RUNS.txt ');
        lc_input_file_handle := UTL_FILE.fopen('XXFIN_INBOUND', 'XX_RJS_ESP_RUNS.txt', 'R',1000);

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
                 UTL_FILE.fclose (lc_input_file_handle);
    END;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Deleting XX_FIN_ESP_RUNS data - ');

    DELETE XXFIN.xx_fin_esp_runs;
    COMMIT;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Start Loading Data - ');

    BEGIN
        LOOP
            BEGIN
                lc_curr_line := NULL;
                UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
                FND_FILE.PUT_LINE(FND_FILE.LOG, '    Data read = '||SUBSTR(lc_curr_line,1,45));

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO MORE RECORDS TO READ');
                         EXIT;
                    WHEN OTHERS THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while reading '||sqlerrm);
                         RETCODE := 2;
                         EXIT;
            END;

            lc_curr_line   := substr(lc_curr_line,1,2000);
            lc_member_appl := rtrim(substr(lc_curr_line,1,8));  
            lc_job_name    := rtrim(substr(lc_curr_line,11,34));
            lc_job_name_1  := NVL(SUBSTR(lc_job_name,1,INSTRB(lc_job_name, '.', 1, 1)-1),lc_job_name);
            lc_job_name_2  := NVL(SUBSTR(lc_job_name,INSTRB(lc_job_name, '.', 1, 1)+1,LENGTH(lc_job_name)-INSTRB(lc_job_name, '.', 1, 1)),lc_job_name);  
            lc_runs        := ltrim(rtrim(substr(lc_curr_line,46,72)),' ');    

               BEGIN
                   SELECT ESP_DETAIL_ID
                   INTO   lc_detail_id
                   FROM   XXFIN.XX_FIN_ESP_DETAILS
                   WHERE  ESP_JOB_NAME_1 = lc_job_name_1
                   AND    ESP_JOB_NAME_2 = lc_job_name_2
                   AND    ROWNUM = 1;

                   SELECT XXFIN.XX_FIN_ESP_runs_S.NEXTVAL 
       		    INTO   lc_seq_num
		    FROM DUAL;

                   INSERT INTO XXFIN.XX_FIN_ESP_RUNS
                           (ESP_RUNS_ID
                           ,ESP_APPLICATION
                           ,ESP_JOB_NAME_1
                           ,ESP_JOB_NAME_2
                           ,ESP_PGM_RUNS
                           ,ATTRIBUTE1
                           ,ATTRIBUTE2
                           ,ATTRIBUTE3
                           ,ATTRIBUTE4
                           ,ATTRIBUTE5
                           ,ATTRIBUTE6
                           ,ATTRIBUTE7
                           ,ATTRIBUTE8
                           ,ATTRIBUTE9
                           ,ESP_DETAIL_ID
                           ,CREATION_DATE
                           ,CREATED_BY
                           ,LAST_UPDATED_BY
                           ,LAST_UPDATE_DATE)
                     VALUES(lc_seq_num
                           ,lc_member_appl
                           ,lc_job_name_1
                           ,lc_job_name_2
                           ,lc_runs
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,lc_detail_id
                           ,SYSDATE
                           ,-1
                           ,-1
                           ,SYSDATE);
                   COMMIT;
                   FND_FILE.PUT_LINE(FND_FILE.LOG, '    Created '||lc_job_name_1||'.'||lc_job_name_2||'-'||lc_runs||'-'||lc_detail_id);

                   EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                            FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR - no data found '||lc_job_name_1||'.'||lc_job_name_2);

                       WHEN OTHERS THEN
                            FND_FILE.PUT_LINE(FND_FILE.LOG, '1. Error - Others '||sqlerrm);
                            RETCODE := 2;
                            EXIT;
               END;

        END LOOP;
    END;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Closing files - ');
    UTL_FILE.fclose(lc_input_file_handle);

EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_RJS_ESP_EXT_5_PKG OTHERS ERROR'||SQLERRM);
         RETCODE := 2;

END LOAD_ESP_RUNS;

-- +===================================================================+
-- | PROCEDURE: LOAD_ESP_PARMS                                         |
-- |                                                                   |
-- | Concurrent Program : Load ESP PARMS                               |
-- | Short_name         : XX_RJS_ESP_EXT_8                             |
-- | Executable         : XX_FIN_ESP_EXT_PKG.LOAD_ESP_PARMS            |
-- |                                                                   |
-- | Description      : This Procedure will query the ESP table        |
-- |                    XX_FIN_ESP_DETAILS pgm parm data and parse it  |
-- |                    for entry in the table XX_FIN_ESP_PARMS        | 
-- |                                                                   |
-- | Parameters      none                                              |
-- +===================================================================+
PROCEDURE LOAD_ESP_PARMS(errbuf       OUT NOCOPY VARCHAR2,
                         retcode      OUT NOCOPY NUMBER)
IS
lc_input_file_handle    UTL_FILE.file_type;
lc_curr_line            VARCHAR2 (2000);
lc_translate_value_id   NUMBER;

lc_application          VARCHAR2(8);
lc_job_name_1           VARCHAR2(8);
lc_job_name_2           VARCHAR2(8);
lc_parms                VARCHAR2(1000);
lc_parm_values          VARCHAR2(700);
lc_parm                 VARCHAR2(60);
lc_parm_value           VARCHAR2(60);
lc_seq                  NUMBER;
lc_seq_num              NUMBER;
lc_detail_id            NUMBER;

CURSOR esp_parameters IS
       SELECT D1.ESP_DETAIL_ID,
              D1.esp_application,
              D1.esp_job_name_1,
              D1.esp_job_name_2,
              D1.ESP_PGM_ARGS,
              CASE 
                  WHEN substr(D1.ESP_PGM_ARG_values,length(D1.ESP_PGM_ARG_values),1) = ',' 
                  THEN REPLACE(REPLACE(D1.ESP_PGM_ARG_VALUES,',,',',(null),'),',,',',(null),')||'(null)'
                  ELSE REPLACE(REPLACE(D1.ESP_PGM_ARG_VALUES,',,',',(null),'),',,',',(null),')
              END         AS ESP_PGM_ARG_VALUES
       FROM   xxfin.xx_fin_esp_details D1
       WHERE  D1.ESP_PGM_ARGS       IS NOT NULL
       AND    D1.esp_pgm_arg_values IS NOT NULL
       ORDER BY 2,3,4;

CURSOR esp_parse_parm IS
       SELECT RPAD(regexp_substr(lc_parms,'[^,]+', 1, level),40,' ') AS PARM,
              regexp_substr(lc_parm_values,'[^,]+', 1, level)        AS PARM_VALUE
       FROM  DUAL
       WHERE  regexp_substr(lc_parms,'[^,]+', 1, level) IS NOT NULL
       CONNECT BY LEVEL <= regexp_count(lc_parm_values,',')+1;

BEGIN

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_RJS_ESP_EXT_8_PKG Begin:');
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Deleting XX_FIN_ESP_PARAMETERS data - ');

    DELETE XXFIN.xx_fin_esp_parameters;
    COMMIT;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Start Loading Data - ');

    BEGIN
        FOR parm_rec IN esp_parameters
            LOOP
                lc_detail_id   := parm_rec.esp_detail_id;
                lc_application := parm_rec.esp_application;
                lc_job_name_1  := parm_rec.esp_job_name_1;
                lc_job_name_2  := parm_rec.esp_job_name_2;
                lc_parms       := parm_rec.esp_pgm_args;
                lc_parm_values := parm_rec.esp_pgm_arg_values;
                lc_seq         := 0;

                BEGIN
                    FOR parse_rec IN esp_parse_parm
                        LOOP
                           lc_parm       := parse_rec.parm;
                           lc_parm_value := parse_rec.parm_value;
                           lc_seq        := lc_seq + 1;

                           SELECT XXFIN.XX_FIN_ESP_DETAILS_S.NEXTVAL 
	                      INTO   lc_seq_num
		                 FROM DUAL;

                    INSERT INTO XXFIN.XX_FIN_ESP_PARAMETERS
                            (ESP_DETAIL_ID
                            ,ESP_PARAMETER_ID
                            ,ESP_APPLICATION
                            ,ESP_JOB_NAME_1
                            ,ESP_JOB_NAME_2
                            ,ESP_PGM_PARM_SEQ
                            ,ESP_PGM_PARM_NAME
                            ,ESP_PGM_PARM_VALUE
                            ,ESP_PGM_PARM_VAR
                            ,ATTRIBUTE1
                            ,ATTRIBUTE2
                            ,ATTRIBUTE3
                            ,ATTRIBUTE4
                            ,ATTRIBUTE5
                            ,ATTRIBUTE6
                            ,ATTRIBUTE7
                            ,ATTRIBUTE8
                            ,ATTRIBUTE9
                            ,CREATION_DATE
                            ,CREATED_BY
                            ,LAST_UPDATED_BY
                            ,LAST_UPDATE_DATE
                            ,LAST_UPDATE_LOGIN)
                      VALUES(lc_detail_id
                            ,lc_seq_num
                            ,lc_application
                            ,lc_job_name_1
                            ,lc_job_name_2
                            ,lc_seq
                            ,lc_parm
                            ,lc_parm_value
                            ,NULL
                            ,NULL
                            ,NULL
                            ,NULL
                            ,NULL
                            ,NULL
                            ,NULL
                            ,NULL
                            ,NULL
                            ,NULL
                            ,SYSDATE
                            ,-1
                            ,-1
                            ,SYSDATE
                            ,-1);
                    COMMIT;

                    FND_FILE.PUT_LINE(FND_FILE.LOG, '    Created '||lc_application||'-'||lc_job_name_1||'.'||lc_job_name_2);

                    END LOOP;

                    EXCEPTION
                        WHEN OTHERS THEN
                             FND_FILE.PUT_LINE(FND_FILE.LOG, '1. Error - Others '||sqlerrm);
                    END;
        END LOOP;
    END;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Loading ESP Parameter table complete - ');

EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_RJS_ESP_EXT_8_PKG OTHERS ERROR'||SQLERRM);
         RETCODE := 2;

END LOAD_ESP_PARMS;

-- +===================================================================+
-- | PROCEDURE: UPDT_ESP_STATS                                         |
-- |                                                                   |
-- | Concurrent Program : Update ESP Execution Statistics              |
-- | Short_name         : XX_RJS_ESP_UPDT_1                            |
-- | Executable         : XX_FIN_ESP_EXT_PKG.UPDT_ESP_STATS            |
-- |                                                                   |
-- | Description      : This Procedure will Update the ESP execution   |
-- |                    Statistics for each job                        |
-- |                                                                   |
-- | Parameters      none                                              |
-- +===================================================================+
PROCEDURE UPDT_ESP_STATS(errbuf       OUT NOCOPY VARCHAR2,
                         retcode      OUT NOCOPY NUMBER)
IS
lc_esp_job_1             VARCHAR2(08);
lc_esp_job_2             VARCHAR2(08);
lc_esp_stat              VARCHAR2(50);
lc_msg                   VARCHAR2(300);
ld_from_date             DATE;


CURSOR esp_update_stats IS

SELECT R.request_id,
       R.phase_code,
       R.status_code,
       R.actual_start_date,
       R.actual_completion_date,
       TO_CHAR(CEIL(((R.actual_start_date - R.actual_completion_date) * 1440) + .01),'99999') AS ELAP_MIN
FROM   apps.fnd_concurrent_requests R,
       xxfin.xx_fin_esp_stats       S
WHERE  R.request_id = S.esp_dly_req_id
AND    S.esp_dly_phase_code <> 'C'
AND    S.esp_dly_phase_code IS NOT NULL;

CURSOR esp_dly_stats IS

SELECT SUBSTR(ESP_JOB,1,INSTR(ESP_JOB,'.')-1)                                    AS ESP_JOB_NAME_1,
       SUBSTR(ESP_JOB,INSTR(ESP_JOB,'.')+1,(LENGTH(ESP_JOB)-INSTR(ESP_JOB,'.'))) AS ESP_JOB_NAME_2,
       request_id, phase_code,status_code, str_date, end_date, elap_min
    FROM  (
       SELECT NVL(SUBSTR(desc1,(INSTR(desc1, '(')+1),(INSTR(desc1, ')')-(INSTR(desc1, '(')+1))),desc1) AS ESP_JOB,
              request_id, phase_code,status_code, str_date, end_date,
              TO_CHAR(CEIL(((end_date - str_date) * 1440) + .01),'99999')                        AS ELAP_MIN
       FROM  (SELECT R.description                                           AS desc1,
                     R.request_id,
                     R.phase_code,
                     R.status_code,
                     R.ACTUAL_START_DATE                                     AS STR_DATE,
                    (SELECT MAX(R1.actual_completion_date)
                     FROM   apps.fnd_concurrent_requests    R1
                     START WITH        r1.request_id = r.request_id
                     CONNECT BY PRIOR  r1.request_id = r1.parent_request_id) AS END_DATE
              FROM   apps.fnd_concurrent_requests    R,
                     apps.fnd_concurrent_programs_vl P
              WHERE  R.concurrent_program_id = p.concurrent_program_id
              AND    R.actual_start_date > ld_from_date
              AND    NVL(SUBSTR(R.description, 
                        (INSTR(R.description, '(')+1), 
                        (INSTR(R.description, ')')-(INSTR(R.description, '(')+1))),
                        R.description) in (SELECT ESP_JOB_NAME_1||'.'||ESP_JOB_NAME_2 
                                           FROM   apps.xx_fin_esp_details)))
            ORDER BY 1,4;

CURSOR esp_exec_stats IS

SELECT ESP_JOB,
       SUBSTR(ESP_JOB,1,INSTR(ESP_JOB,'.')-1)                                                          AS job_name_1,
       SUBSTR(ESP_JOB,INSTR(ESP_JOB,'.')+1,(LENGTH(ESP_JOB)-INSTR(ESP_JOB,'.')))                       AS job_name_2,
       JOB_CNT, MIN_MIN, MAX_MIN, AVG_MIN, STDDEV_MIN, MIN_STR_TM, MAX_STR_TM, AVG_STR_TM
       FROM (
       SELECT NVL(SUBSTR(desc1,(INSTR(desc1, '(')+1),(INSTR(desc1, ')')-(INSTR(desc1, '(')+1))),desc1) AS ESP_JOB,
              TO_CHAR(COUNT(*), '999999999')                                                           AS JOB_CNT, 
              TO_CHAR(MIN(CEIL(((end_date - str_date) * 1440) + .01)),'9999.9')                        AS MIN_MIN,
              TO_CHAR(MAX(CEIL(((end_date - str_date) * 1440) + .01)),'9999.9')                        AS MAX_MIN,
              TO_CHAR(AVG(CEIL(((end_date - str_date) * 1440) + .01)),'9999.9')                        AS AVG_MIN,
              TO_CHAR(STDDEV(CEIL(((end_date - str_date) * 1440) + .01)),'9999.9')                     AS stddev_MIN,
              TO_CHAR(TRUNC(sysdate) + ((1/1440)*(MIN(ABS(CEIL(((TRUNC(end_date) - str_date) * 1440) + .01))))),'hh24:mi') AS MIN_STR_tm,
              TO_CHAR(TRUNC(sysdate) + ((1/1440)*(MAX(ABS(CEIL(((TRUNC(end_date) - str_date) * 1440) + .01))))),'hh24:mi') AS MAX_STR_tm,
              TO_CHAR(TRUNC(sysdate) + ((1/1440)*(TO_CHAR(AVG(ABS(CEIL(((TRUNC(end_date) - str_date) * 1440) + .01))),'99999'))),'hh24:mi') AS AVG_STR_tm
       FROM  (SELECT R.description                                           AS desc1,
                     R.ACTUAL_START_DATE                                     AS STR_DATE,
                    (SELECT MAX(R1.actual_completion_date)
                     FROM   apps.fnd_concurrent_requests    R1
                     START WITH        r1.request_id = r.request_id
                     CONNECT BY PRIOR  r1.request_id = r1.parent_request_id) AS END_DATE
              FROM   apps.fnd_concurrent_requests    R,
                     apps.fnd_concurrent_programs_vl P
              WHERE  R.concurrent_program_id = p.concurrent_program_id
              AND    NVL(SUBSTR(R.description, 
                        (INSTR(R.description, '(')+1), 
                        (INSTR(R.description, ')')-(INSTR(R.description, '(')+1))),
                        R.description) in (SELECT ESP_JOB_NAME_1||'.'||ESP_JOB_NAME_2 
                                           FROM   apps.xx_fin_esp_details))
       GROUP BY NVL(SUBSTR(desc1,(INSTR(desc1, '(')+1),(INSTR(desc1, ')')-(INSTR(desc1, '(')+1))),desc1),
                SUBSTR(desc1,1,INSTR(desc1,'.')-1),
                SUBSTR(desc1,INSTR(desc1,'.')+1,(LENGTH(desc1)-INSTR(desc1,'.')))
                )
       ORDER BY 1;

BEGIN

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_RJS_ESP_UPDT_1_PKG Begin:');

    FND_FILE.PUT_LINE(FND_FILE.LOG, '1. Updating non completed stats - ');

    BEGIN
        FOR update_rec IN esp_update_stats
            LOOP
                BEGIN
                    UPDATE xxfin.xx_fin_esp_stats
                    SET    ESP_DLY_PHASE_CODE  = update_rec.phase_code  
                          ,ESP_DLY_STATUS_CODE = update_rec.status_code
                          ,ESP_DLY_STR_DATE    = update_rec.actual_start_date
                          ,ESP_DLY_END_DATE    = update_rec.actual_completion_date
                          ,ESP_DLY_ELAP_MIN    = update_rec.elap_min
                    WHERE  ESP_DLY_REQ_ID      = update_rec.request_id;

                    EXCEPTION
                        WHEN OTHERS THEN
                             FND_FILE.PUT_LINE(FND_FILE.LOG, '1. Error - Loop Others '||SQLERRM);
                END;
        END LOOP;

         EXCEPTION
              WHEN NO_DATA_FOUND THEN
                   FND_FILE.PUT_LINE(FND_FILE.LOG, '1. Error - no_data_found '||SQLERRM);
              WHEN OTHERS THEN
                   FND_FILE.PUT_LINE(FND_FILE.LOG, '1. Error - Others '||SQLERRM);
    END;
------------------------------------------------------------------------------------------------

    FND_FILE.PUT_LINE(FND_FILE.LOG, '2. Getting from_date - ');

    BEGIN
         SELECT MAX(esp_stats_date)
         INTO   ld_from_date
         FROM   xxfin.xx_fin_esp_stats
         WHERE  esp_dly_str_date IS NOT NULL;

         IF ld_from_date IS NULL THEN
            ld_from_date := sysdate-45;
         END IF;
  
         EXCEPTION
              WHEN NO_DATA_FOUND THEN
                   ld_from_date := sysdate-45;
              WHEN OTHERS THEN
                   FND_FILE.PUT_LINE(FND_FILE.LOG, '2. Error - Others '||SQLERRM);
    END;
------------------------------------------------------------------------------------------------

    FND_FILE.PUT_LINE(FND_FILE.LOG,'3. Creating ESP DLY stats - ' || 'from ' || ld_from_date);

    BEGIN
        FOR dly_rec IN esp_dly_stats
            LOOP
                BEGIN
                    INSERT INTO xxfin.xx_fin_esp_stats
                           (ESP_JOB_NAME_1
                           ,ESP_JOB_NAME_2
                           ,ESP_STATS_DATE
                           ,ESP_DLY_REQ_ID
                           ,ESP_DLY_PHASE_CODE
                           ,ESP_DLY_STATUS_CODE
                           ,ESP_DLY_STR_DATE
                           ,ESP_DLY_END_DATE
                           ,ESP_DLY_ELAP_MIN
                           ,ESP_STATS_JOB_CNT
                           ,ESP_STATS_MIN
                           ,ESP_STATS_MAX
                           ,ESP_STATS_AVG
                           ,ESP_STATS_STDDEV
                           ,ESP_STATS_MIN_TM
                           ,ESP_STATS_MAX_TM
                           ,ESP_STATS_AVG_TM
                           ,ATTRIBUTE1
                           ,ATTRIBUTE2
                           ,ATTRIBUTE3
                           ,ATTRIBUTE4
                           ,ATTRIBUTE5
                           ,ATTRIBUTE6
                           ,ATTRIBUTE7
                           ,ATTRIBUTE8
                           ,ATTRIBUTE9
                           ,CREATION_DATE
                           ,CREATED_BY
                           ,LAST_UPDATED_BY
                           ,LAST_UPDATE_DATE
                           ,LAST_UPDATE_LOGIN)
                     VALUES(dly_rec.esp_job_name_1
                           ,dly_rec.esp_job_name_2
                           ,dly_rec.str_date
                           ,dly_rec.request_id
                           ,dly_rec.phase_code
                           ,dly_rec.status_code
                           ,dly_rec.str_date
                           ,dly_rec.end_date
                           ,dly_rec.elap_min
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,SYSDATE
                           ,-1
                           ,-1
                           ,SYSDATE
                           ,-1);
                    COMMIT;

                    EXCEPTION
                        WHEN OTHERS THEN
                             FND_FILE.PUT_LINE(FND_FILE.LOG, '3. Error - Others '||SQLERRM);
                END;
        END LOOP;
    END;
    COMMIT;
------------------------------------------------------------------------------------------------

    FND_FILE.PUT_LINE(FND_FILE.LOG, '4. Creating ESP execution stats - ');

    BEGIN
        FOR stats_rec IN esp_exec_stats
            LOOP
                BEGIN
                    INSERT INTO xxfin.xx_fin_esp_stats
                           (ESP_JOB_NAME_1
                           ,ESP_JOB_NAME_2
                           ,ESP_STATS_DATE
                           ,ESP_DLY_REQ_ID
                           ,ESP_DLY_PHASE_CODE
                           ,ESP_DLY_STATUS_CODE
                           ,ESP_DLY_STR_DATE
                           ,ESP_DLY_END_DATE
                           ,ESP_DLY_ELAP_MIN
                           ,ESP_STATS_JOB_CNT
                           ,ESP_STATS_MIN
                           ,ESP_STATS_MAX
                           ,ESP_STATS_AVG
                           ,ESP_STATS_STDDEV
                           ,ESP_STATS_MIN_TM
                           ,ESP_STATS_MAX_TM
                           ,ESP_STATS_AVG_TM
                           ,ATTRIBUTE1
                           ,ATTRIBUTE2
                           ,ATTRIBUTE3
                           ,ATTRIBUTE4
                           ,ATTRIBUTE5
                           ,ATTRIBUTE6
                           ,ATTRIBUTE7
                           ,ATTRIBUTE8
                           ,ATTRIBUTE9
                           ,CREATION_DATE
                           ,CREATED_BY
                           ,LAST_UPDATED_BY
                           ,LAST_UPDATE_DATE
                           ,LAST_UPDATE_LOGIN)
                     VALUES(stats_rec.job_name_1
                           ,stats_rec.job_name_2
                           ,SYSDATE
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,stats_rec.job_cnt
                           ,stats_rec.min_min
                           ,stats_rec.max_min
                           ,stats_rec.avg_min
                           ,stats_rec.stddev_min
                           ,stats_rec.min_str_tm
                           ,stats_rec.max_str_tm
                           ,stats_rec.avg_str_tm
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,SYSDATE
                           ,-1
                           ,-1
                           ,SYSDATE
                           ,-1);
                    COMMIT;

                    EXCEPTION
                        WHEN OTHERS THEN
                             FND_FILE.PUT_LINE(FND_FILE.LOG, '4. Error - Others ' || SQLERRM);
                END;
        END LOOP;
    END;
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_RJS_ESP_UPDT_1_PKG OTHERS ERROR'||SQLERRM);
         RETCODE := 2;

END UPDT_ESP_STATS;

-- +===================================================================+
-- | PROCEDURE: PRINT_ESP_RPT                                          |
-- |                                                                   |
-- | Concurrent Program : PRINT_ESP_RPT                                |
-- | Short_name         : XX_RJS_ESP_EXT_7                             |
-- | Executable         : XX_FIN_ESP_EXT_PKG.PRINT_ESP_RPT             |
-- |                                                                   |
-- | Description      : This Procedure will read the ESP detail data   |
-- |                                                                   |
-- | Parameters      none                                              |
-- +===================================================================+
PROCEDURE PRINT_ESP_RPT(errbuf       OUT NOCOPY VARCHAR2,
                        retcode      OUT NOCOPY NUMBER,
                        p_application IN VARCHAR2,
                        p_job_name_1  IN VARCHAR2,
                        p_job_name_2  IN VARCHAR2)

IS
lc_output_file_handle   UTL_FILE.file_type;
lc_curr_line            VARCHAR2 (2000);

lc_applICATION          VARCHAR2(8);
lc_job_name             VARCHAR2(34);
lc_job_name_1           VARCHAR2(8);
lc_job_name_2           VARCHAR2(8);
lc_section              VARCHAR2(30);

  CURSOR esp_detailS IS
         SELECT D.esp_application,
                D.esp_job_name_1,
                D.esp_job_name_2,
                D.esp_oa_user,
                D.esp_pgm_short_name,
                D.esp_pgm_user_name,
                D.esp_responsibility
         FROM   xxfin.xx_fin_esp_details  D
         WHERE  D.esp_application = NVL(p_application,D.esp_application)
         AND    D.esp_job_name_1  = NVL(p_job_name_1, D.esp_job_name_1)
         AND    D.esp_job_name_2  = NVL(p_job_name_2,D.esp_job_name_2)
         ORDER BY D.esp_application,
                  D.esp_job_name_1,
                  D.esp_job_name_2,
                  D.esp_oa_user,
                  D.esp_pgm_user_name,
                  D.esp_responsibility;

  CURSOR esp_pgm_parms IS
         SELECT RPAD(regexp_substr(D2.ESP_PGM_ARGS,'[^,]+', 1, level),40,' ')||
                ' = '||regexp_substr(D2.ESP_PGM_ARG_VALUES,'[^,]+', 1, level) AS PARAMETERS
         FROM  (SELECT D1.ESP_PGM_ARGS,
                       CASE 
                          WHEN substr(D1.ESP_PGM_ARG_values,length(D1.ESP_PGM_ARG_values),1) = ',' 
                          THEN REPLACE(REPLACE(D1.ESP_PGM_ARG_VALUES,',,',',(null),'),',,',',(null),')||'(null)'
                          ELSE REPLACE(REPLACE(D1.ESP_PGM_ARG_VALUES,',,',',(null),'),',,',',(null),')
                          END         AS ESP_PGM_ARG_VALUES
                FROM   xxfin.xx_fin_esp_details D1
                WHERE  D1.esp_application = NVL(lc_application,D1.esp_application) 
                AND    D1.esp_job_name_1  = NVL(lc_job_name_1, D1.esp_job_name_1)
                AND    D1.esp_job_name_2  = NVL(lc_job_name_2, D1.esp_job_name_2)
                AND    D1.ESP_PGM_ARGS   IS NOT NULL
                and    d1.esp_pgm_arg_values is not null) D2
         WHERE  regexp_substr(D2.ESP_PGM_ARGS,'[^,]+', 1, level) IS NOT NULL
         CONNECT BY LEVEL <= regexp_count(D2.esp_pgm_arg_values,',')+1;   

  CURSOR esp_schedule IS
         SELECT S.esp_prefix,
                S.esp_system,
                S.esp_schedule
         FROM   xxfin.xx_fin_esp_schedule   S
         WHERE  S.esp_event = NVL(lc_application,S.esp_event);

  CURSOR esp_pgm_runs IS
         SELECT R.esp_pgm_runs
         FROM   xxfin.xx_fin_esp_runs R
         WHERE  R.esp_application = NVL(lc_application,R.esp_application)
         AND    R.esp_job_name_1  = NVL(lc_job_name_1, R.esp_job_name_1)
         AND    R.esp_job_name_2  = NVL(lc_job_name_2,R.esp_job_name_2);

  CURSOR esp_pgm_link IS
         SELECT CASE L.esp_pgm_link_type
                     WHEN 'D' THEN 'Predecessor'
                     WHEN 'E' THEN 'External  '
                     WHEN 'R' THEN 'Releases  '
                     WHEN 'T' THEN 'Triggers  '
                     WHEN 'X' THEN 'External  '
                     ELSE          'UNKNOWN   '
                     END    AS esp_pgm_link_type,
                L.esp_pgm_link_appl,
                L.esp_pgm_link_job
         FROM   xxfin.xx_fin_esp_details D,
                xxfin.xx_fin_esp_LINK    L
         WHERE  D.esp_detail_id   = L.esp_detail_id  
         AND    D.esp_application = 'EFAR1AI2'
         AND    D.esp_job_name_1 = 'EFAR1AI2'
         AND    D.esp_job_name_2 = 'USPGMC00'
         ORDER BY 1,2,
                      CASE L.esp_pgm_link_type
                           WHEN 'D' THEN '3'
                           WHEN 'E' THEN '1'
                           WHEN 'R' THEN '4'
                           WHEN 'T' THEN '5'
                           WHEN 'X' THEN '2'
                           ELSE          '9'
                           END ;

BEGIN

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_RJS_ESP_EXT_6_PKG Begin:');

-- +===================================================================+
-- | OPEN FILE                                                         |
-- +===================================================================+
    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Opening Output File - XX_RJS_ESP_REPORT.txt');
        lc_output_file_handle := UTL_FILE.fopen('XXFIN_OUTBOUND', 'XX_RJS_ESP_REPORT.txt', 'W',2000);

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

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Start Reporting Data - ');

-- +===================================================================+
-- | MAIN DETAIL CURSOR                                                |
-- +===================================================================+
    BEGIN
        FOR detail_rec IN esp_details
            LOOP
                lc_curr_line := RPAD(detail_rec.esp_application,10,' ')||
                                RPAD(detail_rec.esp_job_name_1,10,' ')||
                                RPAD(detail_rec.esp_job_name_2,10,' ')||
                                RPAD(detail_rec.esp_pgm_user_name,60,' ')||
                                RPAD(detail_rec.esp_pgm_short_name,60,' ')||
                                RPAD(detail_rec.esp_oa_user,8,' ')||
                                RPAD(detail_rec.esp_responsibility,40,' ');

                UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);
--              lc_curr_line := ' ';
--              UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);


-- +===================================================================+
-- | PROGRAM PARAMETERS CURSOR                                         |
-- +===================================================================+
                lc_application  := detail_rec.esp_application;
                lc_job_name_1   := detail_rec.esp_job_name_1;
                lc_job_name_2   := detail_rec.esp_job_name_2;
                lc_section      := 'program_parameters => ';
                lc_curr_line    := ' ';

                BEGIN
                    FOR parm_rec IN esp_pgm_parms
                        LOOP

                            lc_curr_line := RPAD(' ',200,' ')||
                                            RPAD(lc_section,30,' ')||
                                            RPAD(parm_rec.parameters,80,' ');

                            UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);
                            lc_section   := ' ';

                        END LOOP;
                END;

-- +===================================================================+
-- | EVENT SCHEDULE CURSOR                                             |
-- +===================================================================+
--              lc_curr_line := ' ';
--              UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);
                lc_section      := 'Event_Schedule => ';
                lc_curr_line    := ' ';

                BEGIN
                    FOR sched_rec IN esp_schedule
                        LOOP

                            lc_curr_line := RPAD(' ',400,' ')||
                                            RPAD(lc_section,30,' ')||
                                            RPAD(' ',25,' ')||
                                            RPAD(sched_rec.esp_schedule,80,' ');

                            UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);
                            lc_section   := ' ';

                        END LOOP;
                    IF lc_section = 'Event_Schedule => ' THEN
                       lc_curr_line := RPAD(' ',400,' ')||
                                       RPAD(lc_section,30,' ')||
                                            RPAD(' ',25,' ')||
                                       RPAD('Triggered ',80,' ');
                       UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);
                    END IF;

                END;

-- +===================================================================+
-- | PROGRAM RUN CURSOR                                                |
-- +===================================================================+
--              lc_curr_line := ' ';
--              UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);
                lc_section      := 'Program_Execution => ';
                lc_curr_line    := ' ';

                BEGIN
                    FOR pgm_run_rec IN esp_pgm_runs
                        LOOP

                            lc_curr_line := RPAD(' ',400,' ')||
                                            RPAD(lc_section,30,' ')||
                                            RPAD(' ',25,' ')||
                                            RPAD(pgm_run_rec.esp_pgm_runs,80,' ');

                            UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);
                            lc_section   := ' ';

                        END LOOP;
                END;

-- +===================================================================+
-- | PROGRAM LINK CURSOR                                               |
-- +===================================================================+
                lc_section      := 'Program_Dependencies => ';
                lc_curr_line := ' ';

                BEGIN
                    FOR pgm_LINK_rec IN esp_pgm_LINK
                        LOOP

                            lc_curr_line := RPAD(' ',400,' ')||
                                            RPAD(lc_section,30,' ')||
                                            RPAD(pgm_link_rec.esp_pgm_link_type,15,' ')||
                                            RPAD(pgm_link_rec.esp_pgm_link_appl,10,' ')||
                                            RPAD(pgm_link_rec.esp_pgm_link_job,10,' ');

                            UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);
                            lc_section   := ' ';

                        END LOOP;
                END;

                lc_curr_line := ' ';
                UTL_FILE.PUT_LINE(lc_output_file_handle,lc_curr_line);

        END LOOP;
    END;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Closing files - ');
    UTL_FILE.fclose(lc_output_file_handle);

EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_RJS_ESP_EXT_6_PKG OTHERS ERROR'||SQLERRM);
         RETCODE := 2;

END PRINT_ESP_RPT;

END XX_FIN_ESP_EXT_PKG;
/
