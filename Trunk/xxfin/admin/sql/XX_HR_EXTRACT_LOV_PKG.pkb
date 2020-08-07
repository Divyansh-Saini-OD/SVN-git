CREATE OR REPLACE PACKAGE BODY XX_HR_EXTRACT_LOV_PKG AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_HR_EXTRACT_LOV_PKG                                                              |
-- |  Description:  Extract List of Values to feed to hosted Peoplesoft HR.                     |
-- |                I2171 ¿ HR Extract Oracle List of Values                                    |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         05/21/2012   Joe Klein        Initial version                                  |
-- | 1.1         08/21/2012   Paddy Sanjeevi   Changed dba_dir to XXFIN_OUTBOUND                |
-- | 1.2         08/23/2013   Arghya De        I2171 - Changed EXTRACT_SOB_PROC for R12 Upgrade retrofit. |
-- | 1.3         05/19/2014   Paddy Sanjeevi   Defect 30095                                     |
-- | 1.4         11/18/2015   Avinash Baddam   R12.2 Compliance Changes                         |
-- +============================================================================================+

-- +============================================================================================+
-- |  Name: EXTRACT_COMPANY_PROC                                                                |
-- |  Description: This procedure will extract companies from Oracle and create a file.         |
-- =============================================================================================|
PROCEDURE EXTRACT_COMPANY_PROC    (errbuff     OUT VARCHAR2
                                  ,retcode     OUT VARCHAR2)
    AS
         FileHandle                UTL_FILE.FILE_TYPE;
         lc_dba_dir                VARCHAR2 (100) := 'XXFIN_OUTBOUND';
         lc_output_file            VARCHAR2 (100);
         lc_dest_dir               VARCHAR2 (100);
         lc_filerec                VARCHAR2(5000);
         ln_record_cnt             NUMBER;

         --Cursor to select records for extract file
         CURSOR SELECT_EXTRACT_REC IS
                      --    PS Company       Oracle Company
                   SELECT v.source_value1, v.target_value1
                     FROM xx_fin_translatedefinition d, xx_fin_translatevalues v
                    WHERE d.translation_name = 'GL_PSHR_COMPANY'
                      AND v.translate_id = d.translate_id
                      AND v.start_date_active < SYSDATE
                      AND v.end_date_active IS NULL
                 ORDER BY v.source_value1;

    BEGIN

        BEGIN
        SELECT directory_path INTO lc_dest_dir FROM dba_directories WHERE directory_name = lc_dba_dir;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001,'DBA Directory '|| lc_dba_dir || ' not defined');
        END;

        fnd_file.put_line(fnd_file.LOG,'Procedure XX_EXTRACT_COMPANY_PROC started...');
        lc_output_file := 'OD_Oracle_Companies.txt';
        fnd_file.put_line(fnd_file.LOG,'Destination = '||lc_dest_dir);
        fnd_file.put_line(fnd_file.LOG,'Filename = '||lc_output_file);

        FileHandle := UTL_FILE.FOPEN(lc_dba_dir,lc_output_file,'w');

        fnd_file.put_line(fnd_file.LOG,'Writing Extract Records...');

        ln_record_cnt := 0;

        FOR R_EX IN SELECT_EXTRACT_REC LOOP
           ln_record_cnt := ln_record_cnt + 1;
                        --    PS Company               Oracle Company
           lc_filerec := R_EX.source_value1||'|'||R_EX.target_value1;
           UTL_FILE.PUT_LINE(FileHandle, lc_filerec);
        END LOOP;

        UTL_FILE.FFLUSH(FileHandle);
        UTL_FILE.FCLOSE(FileHandle);

        fnd_file.put_line(fnd_file.LOG,'Finished Writing File...');
        fnd_file.put_line(fnd_file.LOG,'Total Record count  = '|| ln_record_cnt);
        COMMIT;

    EXCEPTION
       WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001,'No Data Found. '||SQLERRM);
       WHEN UTL_FILE.INVALID_PATH THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'File location is invalid. '||SQLERRM);
       WHEN UTL_FILE.INVALID_MODE THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The open_mode parameter in FOPEN is invalid. '||SQLERRM);
       WHEN UTL_FILE.INVALID_FILEHANDLE THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'File handle is invalid. '||SQLERRM);
       WHEN UTL_FILE.INVALID_OPERATION THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'File could not be opened or operated on as requested. '||SQLERRM);
       WHEN UTL_FILE.READ_ERROR THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'Operating system error occurred during the read operation. '||SQLERRM);
       WHEN UTL_FILE.WRITE_ERROR THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'Operating system error occurred during the write operation. '||SQLERRM);
       WHEN UTL_FILE.INTERNAL_ERROR THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'Unspecified PL/SQL error. '||SQLERRM);
       WHEN UTL_FILE.CHARSETMISMATCH THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'A file is opened using FOPEN_NCHAR, but later I/O ' ||
                                           'operations use nonchar functions such as PUTF or GET_LINE. '||SQLERRM);
       WHEN UTL_FILE.FILE_OPEN THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The requested operation failed because the file is open. '||SQLERRM);
       WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The MAX_LINESIZE value for FOPEN() is invalid; it should ' ||
                                           'be within the range 1 to 32767. '||SQLERRM);
       WHEN UTL_FILE.INVALID_FILENAME THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The filename parameter is invalid. '||SQLERRM);
       WHEN UTL_FILE.ACCESS_DENIED THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'Permission to access to the file location is denied. '||SQLERRM);
       WHEN UTL_FILE.INVALID_OFFSET THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The ABSOLUTE_OFFSET parameter for FSEEK() is invalid; ' ||
                                           'it should be greater than 0 and less than the total ' ||
                                           'number of bytes in the file. '||SQLERRM);
       WHEN UTL_FILE.DELETE_FAILED THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The requested file delete operation failed. '||SQLERRM);
       WHEN UTL_FILE.RENAME_FAILED THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The requested file rename operation failed. '||SQLERRM);
       WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001,'Other Exception Raised. '||SQLERRM);

    END EXTRACT_COMPANY_PROC;

-- +============================================================================================+
-- |  Name: EXTRACT_LOB_PROC                                                                    |
-- |  Description: This procedure will extract line of business from Oracle and create a file.  |
-- =============================================================================================|
PROCEDURE EXTRACT_LOB_PROC        (errbuff     OUT VARCHAR2
                                  ,retcode     OUT VARCHAR2)
    AS
         FileHandle                UTL_FILE.FILE_TYPE;
         lc_dba_dir                VARCHAR2 (100) := 'XXFIN_OUTBOUND';
         lc_output_file            VARCHAR2 (100);
         lc_dest_dir               VARCHAR2 (100);
         lc_filerec                VARCHAR2(5000);
         p_lob                     VARCHAR2  (10);
         p_error_message           VARCHAR2(1000);
         ln_record_cnt             NUMBER;

         --Cursor to select records for extract file
         CURSOR SELECT_EXTRACT_REC IS
                   --              location  cost center
                   SELECT DISTINCT segment4, segment2
                     FROM gl_code_combinations
                    WHERE enabled_flag = 'Y'
                 ORDER BY segment4, segment2;

    BEGIN

        BEGIN
        SELECT directory_path INTO lc_dest_dir FROM dba_directories WHERE directory_name = lc_dba_dir;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001,'DBA Directory '|| lc_dba_dir || ' not defined');
        END;

        fnd_file.put_line(fnd_file.LOG,'Procedure EXTRACT_LOB_PROC started...');
        lc_output_file := 'OD_Oracle_LOB.txt';
        fnd_file.put_line(fnd_file.LOG,'Destination = '||lc_dest_dir);
        fnd_file.put_line(fnd_file.LOG,'Filename = '||lc_output_file);

        FileHandle := UTL_FILE.FOPEN(lc_dba_dir,lc_output_file,'w');

        fnd_file.put_line(fnd_file.LOG,'Writing Extract Records...');

        ln_record_cnt := 0;

        FOR R_EX IN SELECT_EXTRACT_REC LOOP
           xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc(R_EX.segment4,R_EX.segment2,p_lob,p_error_message);
           IF p_lob IS NOT NULL THEN
              ln_record_cnt := ln_record_cnt + 1;
              --                location          cost center      lob
              lc_filerec := R_EX.segment4||'|'||R_EX.segment2||'|'||p_lob;
              UTL_FILE.PUT_LINE(FileHandle, lc_filerec);
           END IF;
        END LOOP;

        UTL_FILE.FFLUSH(FileHandle);
        UTL_FILE.FCLOSE(FileHandle);

        fnd_file.put_line(fnd_file.LOG,'Finished Writing File...');
        fnd_file.put_line(fnd_file.LOG,'Total Record count  = '|| ln_record_cnt);
        COMMIT;

    EXCEPTION
       WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001,'No Data Found. '||SQLERRM);
       WHEN UTL_FILE.INVALID_PATH THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'File location is invalid. '||SQLERRM);
       WHEN UTL_FILE.INVALID_MODE THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The open_mode parameter in FOPEN is invalid. '||SQLERRM);
       WHEN UTL_FILE.INVALID_FILEHANDLE THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'File handle is invalid. '||SQLERRM);
       WHEN UTL_FILE.INVALID_OPERATION THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'File could not be opened or operated on as requested. '||SQLERRM);
       WHEN UTL_FILE.READ_ERROR THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'Operating system error occurred during the read operation. '||SQLERRM);
       WHEN UTL_FILE.WRITE_ERROR THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'Operating system error occurred during the write operation. '||SQLERRM);
       WHEN UTL_FILE.INTERNAL_ERROR THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'Unspecified PL/SQL error. '||SQLERRM);
       WHEN UTL_FILE.CHARSETMISMATCH THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'A file is opened using FOPEN_NCHAR, but later I/O ' ||
                                           'operations use nonchar functions such as PUTF or GET_LINE. '||SQLERRM);
       WHEN UTL_FILE.FILE_OPEN THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The requested operation failed because the file is open. '||SQLERRM);
       WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The MAX_LINESIZE value for FOPEN() is invalid; it should ' ||
                                           'be within the range 1 to 32767. '||SQLERRM);
       WHEN UTL_FILE.INVALID_FILENAME THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The filename parameter is invalid. '||SQLERRM);
       WHEN UTL_FILE.ACCESS_DENIED THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'Permission to access to the file location is denied. '||SQLERRM);
       WHEN UTL_FILE.INVALID_OFFSET THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The ABSOLUTE_OFFSET parameter for FSEEK() is invalid; ' ||
                                           'it should be greater than 0 and less than the total ' ||
                                           'number of bytes in the file. '||SQLERRM);
       WHEN UTL_FILE.DELETE_FAILED THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The requested file delete operation failed. '||SQLERRM);
       WHEN UTL_FILE.RENAME_FAILED THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The requested file rename operation failed. '||SQLERRM);
       WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001,'Other Exception Raised. '||SQLERRM);

    END EXTRACT_LOB_PROC;


-- +============================================================================================+
-- |  Name: EXTRACT_SOB_PROC                                                                    |
-- |  Description: This procedure will extract Set Of Books from Oracle and create a file.      |
-- =============================================================================================|
PROCEDURE EXTRACT_SOB_PROC        (errbuff     OUT VARCHAR2
                                  ,retcode     OUT VARCHAR2)
    AS
         FileHandle                UTL_FILE.FILE_TYPE;
         lc_dba_dir                VARCHAR2 (100) := 'XXFIN_OUTBOUND';
         lc_output_file            VARCHAR2 (100);
         lc_dest_dir               VARCHAR2 (100);
         lc_filerec                VARCHAR2(5000);
         ln_record_cnt             NUMBER;

         --Cursor to select records for extract file
         CURSOR SELECT_EXTRACT_REC IS
                   SELECT ffv.flex_value company, gll.ledger_id
                     FROM fnd_id_flex_segments_vl   fifs
                         ,fnd_flex_values_vl        ffv
                         ,gl_ledgers            gll     -- Arghya: Changed from gl_sets_of_books to gl_ledgers for R12 Upgrade retrofit
                         ,fnd_id_flex_structures_vl fstr
                    WHERE fifs.application_column_name       = 'SEGMENT1'
                      AND upper(fstr.id_flex_structure_name) = 'OD_GLOBAL_COA'
                      AND fifs.id_flex_num                   = fstr.id_flex_num
                      AND fifs.flex_value_set_id             = ffv.flex_value_set_id
                      AND ffv.attribute1                     = gll.short_name
		      -- Defect 30095 Added the following conditions
                      and fstr.id_flex_code='GL#'
                      and fstr.id_flex_code=fifs.id_flex_code
		      -- Defect 30095 End
                      AND ffv.enabled_flag                   = 'Y'
                      AND NVL(ffv.end_date_active,SYSDATE+1) > SYSDATE
                 ORDER BY ffv.flex_value;

    BEGIN

        BEGIN
        SELECT directory_path INTO lc_dest_dir FROM dba_directories WHERE directory_name = lc_dba_dir;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001,'DBA Directory '|| lc_dba_dir || ' not defined');
        END;

        fnd_file.put_line(fnd_file.LOG,'Procedure EXTRACT_SOB_PROC started...');
        lc_output_file := 'OD_Oracle_SOB.txt';
        fnd_file.put_line(fnd_file.LOG,'Destination = '||lc_dest_dir);
        fnd_file.put_line(fnd_file.LOG,'Filename = '||lc_output_file);

        FileHandle := UTL_FILE.FOPEN(lc_dba_dir,lc_output_file,'w');

        fnd_file.put_line(fnd_file.LOG,'Writing Extract Records...');

        ln_record_cnt := 0;

        FOR R_EX IN SELECT_EXTRACT_REC LOOP
           ln_record_cnt := ln_record_cnt + 1;
           lc_filerec := R_EX.company||'|'||R_EX.ledger_id; -- Arghya changed as cursor defn changed
           UTL_FILE.PUT_LINE(FileHandle, lc_filerec);
        END LOOP;

        UTL_FILE.FFLUSH(FileHandle);
        UTL_FILE.FCLOSE(FileHandle);

        fnd_file.put_line(fnd_file.LOG,'Finished Writing File...');
        fnd_file.put_line(fnd_file.LOG,'Total Record count  = '|| ln_record_cnt);
        COMMIT;

   EXCEPTION
       WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001,'No Data Found. '||SQLERRM);
       WHEN UTL_FILE.INVALID_PATH THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'File location is invalid. '||SQLERRM);
       WHEN UTL_FILE.INVALID_MODE THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The open_mode parameter in FOPEN is invalid. '||SQLERRM);
       WHEN UTL_FILE.INVALID_FILEHANDLE THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'File handle is invalid. '||SQLERRM);
       WHEN UTL_FILE.INVALID_OPERATION THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'File could not be opened or operated on as requested. '||SQLERRM);
       WHEN UTL_FILE.READ_ERROR THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'Operating system error occurred during the read operation. '||SQLERRM);
       WHEN UTL_FILE.WRITE_ERROR THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'Operating system error occurred during the write operation. '||SQLERRM);
       WHEN UTL_FILE.INTERNAL_ERROR THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'Unspecified PL/SQL error. '||SQLERRM);
       WHEN UTL_FILE.CHARSETMISMATCH THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'A file is opened using FOPEN_NCHAR, but later I/O ' ||
                                           'operations use nonchar functions such as PUTF or GET_LINE. '||SQLERRM);
       WHEN UTL_FILE.FILE_OPEN THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The requested operation failed because the file is open. '||SQLERRM);
       WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The MAX_LINESIZE value for FOPEN() is invalid; it should ' ||
                                           'be within the range 1 to 32767. '||SQLERRM);
       WHEN UTL_FILE.INVALID_FILENAME THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The filename parameter is invalid. '||SQLERRM);
       WHEN UTL_FILE.ACCESS_DENIED THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'Permission to access to the file location is denied. '||SQLERRM);
       WHEN UTL_FILE.INVALID_OFFSET THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The ABSOLUTE_OFFSET parameter for FSEEK() is invalid; ' ||
                                           'it should be greater than 0 and less than the total ' ||
                                           'number of bytes in the file. '||SQLERRM);
       WHEN UTL_FILE.DELETE_FAILED THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The requested file delete operation failed. '||SQLERRM);
       WHEN UTL_FILE.RENAME_FAILED THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The requested file rename operation failed. '||SQLERRM);
       WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001,'Other Exception Raised. '||SQLERRM);

    END EXTRACT_SOB_PROC;


-- +============================================================================================+
-- |  Name: EXTRACT_GARN_ACCT_PROC                                                              |
-- |  Description: This procedure will extract Set Of Books from Oracle and create a file.      |
-- =============================================================================================|
PROCEDURE EXTRACT_GARN_ACCT_PROC  (errbuff     OUT VARCHAR2
                                  ,retcode     OUT VARCHAR2)
    AS
         FileHandle                UTL_FILE.FILE_TYPE;
         lc_dba_dir                VARCHAR2 (100) := 'XXFIN_OUTBOUND';
         lc_output_file            VARCHAR2 (100);
         lc_dest_dir               VARCHAR2 (100);
         lc_filerec                VARCHAR2(5000);
         ln_record_cnt             NUMBER;

         --Cursor to select records for extract file
         CURSOR SELECT_EXTRACT_REC IS
                   --    garnishment filename, GL account code
                   SELECT b.source_value1, b.target_value1
                     FROM xx_fin_translatedefinition a,
                          xx_fin_translatevalues b
                    WHERE a.translation_name = 'AP_PSHR_GARN_ACCOUNT_CODE'
                      AND a.translate_id = b.translate_id
                      AND b.enabled_flag = 'Y';

    BEGIN

        BEGIN
        SELECT directory_path INTO lc_dest_dir FROM dba_directories WHERE directory_name = lc_dba_dir;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001,'DBA Directory '|| lc_dba_dir || ' not defined');
        END;

        fnd_file.put_line(fnd_file.LOG,'Procedure EXTRACT_GARN_ACCT_PROC started...');
        lc_output_file := 'OD_Oracle_Garnish_Acct.txt';
        fnd_file.put_line(fnd_file.LOG,'Destination = '||lc_dest_dir);
        fnd_file.put_line(fnd_file.LOG,'Filename = '||lc_output_file);

        FileHandle := UTL_FILE.FOPEN(lc_dba_dir,lc_output_file,'w');

        fnd_file.put_line(fnd_file.LOG,'Writing Extract Records...');

        ln_record_cnt := 0;

        FOR R_EX IN SELECT_EXTRACT_REC LOOP
           ln_record_cnt := ln_record_cnt + 1;
           --          garnishment filename        GL account code
           lc_filerec := R_EX.source_value1||'|'||R_EX.target_value1;
           UTL_FILE.PUT_LINE(FileHandle, lc_filerec);
        END LOOP;

        UTL_FILE.FFLUSH(FileHandle);
        UTL_FILE.FCLOSE(FileHandle);

        fnd_file.put_line(fnd_file.LOG,'Finished Writing File...');
        fnd_file.put_line(fnd_file.LOG,'Total Record count  = '|| ln_record_cnt);
        COMMIT;

    EXCEPTION
       WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001,'No Data Found. '||SQLERRM);
       WHEN UTL_FILE.INVALID_PATH THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'File location is invalid. '||SQLERRM);
       WHEN UTL_FILE.INVALID_MODE THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The open_mode parameter in FOPEN is invalid. '||SQLERRM);
       WHEN UTL_FILE.INVALID_FILEHANDLE THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'File handle is invalid. '||SQLERRM);
       WHEN UTL_FILE.INVALID_OPERATION THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'File could not be opened or operated on as requested. '||SQLERRM);
       WHEN UTL_FILE.READ_ERROR THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'Operating system error occurred during the read operation. '||SQLERRM);
       WHEN UTL_FILE.WRITE_ERROR THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'Operating system error occurred during the write operation. '||SQLERRM);
       WHEN UTL_FILE.INTERNAL_ERROR THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'Unspecified PL/SQL error. '||SQLERRM);
       WHEN UTL_FILE.CHARSETMISMATCH THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'A file is opened using FOPEN_NCHAR, but later I/O ' ||
                                           'operations use nonchar functions such as PUTF or GET_LINE. '||SQLERRM);
       WHEN UTL_FILE.FILE_OPEN THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The requested operation failed because the file is open. '||SQLERRM);
       WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The MAX_LINESIZE value for FOPEN() is invalid; it should ' ||
                                           'be within the range 1 to 32767. '||SQLERRM);
       WHEN UTL_FILE.INVALID_FILENAME THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The filename parameter is invalid. '||SQLERRM);
       WHEN UTL_FILE.ACCESS_DENIED THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'Permission to access to the file location is denied. '||SQLERRM);
       WHEN UTL_FILE.INVALID_OFFSET THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The ABSOLUTE_OFFSET parameter for FSEEK() is invalid; ' ||
                                           'it should be greater than 0 and less than the total ' ||
                                           'number of bytes in the file. '||SQLERRM);
       WHEN UTL_FILE.DELETE_FAILED THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The requested file delete operation failed. '||SQLERRM);
       WHEN UTL_FILE.RENAME_FAILED THEN
            UTL_FILE.FCLOSE(FileHandle);
            RAISE_APPLICATION_ERROR(-20001,'The requested file rename operation failed. '||SQLERRM);
       WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001,'Other Exception Raised. '||SQLERRM);

    END EXTRACT_GARN_ACCT_PROC;


END XX_HR_EXTRACT_LOV_PKG;
/
