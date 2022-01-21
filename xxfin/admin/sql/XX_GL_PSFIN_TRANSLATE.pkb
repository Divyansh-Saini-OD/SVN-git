create or replace PACKAGE BODY XX_GL_PSFIN_TRANSLATE_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		       |
-- +===================================================================+
-- | Name  : XX_GL_PSFIN_TRANSLATE_PKG                                 |
-- | Description      :  Package to extract PeopleSoft GL translation  |
-- |                     values to be stored in the DB2 table          |
-- |                     OD.TRANTBL for use in converting accounts in  |
-- |                     legacy programs.  Defect #8345.               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       26-JUN-2008 D.Nardo          Initial version             |
-- |1.1       12-SEP-2008 D.Nardo          Defect 11092                |
-- |1.2       29-OCT-2008 D.Nardo          Defect 11966                |
-- |1.3       14-JAN-2011 L.LEE            Defect 8779                 |
-- |1.4       17-Nov-15   Avinash Baddam   R12.2 Compliance Changes    |
-- +===================================================================+
    ---------------------
    -- Global Variables
    ---------------------
    g_FileHandle           UTL_FILE.FILE_TYPE;
    -- The file name is per BPEL standards for files to be transferred to MVS
    gc_output_file         VARCHAR2 (30) := 'PSFIN_TRANSLATIONS_MVSFTP.txt';      
    ------------------
    --counters
    ------------------
    gn_total_location_cnt  NUMBER := 0;  --Number of GL_PSFIN_LOCATION records
    gn_total_loc_type_cnt  NUMBER := 0;  --Number of GL_PSFIN_LOCATION_TYPE records
    gn_total_cc_cnt        NUMBER := 0;  --Number of GL_PSFIN_COST_CENTER records
    gn_total_account_cnt   NUMBER := 0;  --Number of GL_PSFIN_ACCOUNT records
    gn_total_lob_cnt       NUMBER := 0;  --Number of GL_PSFIN_LOB records
    gn_total_cmpy_cnt      NUMBER := 0;  --Number of GL_PSFIN_COMPANY records
    gn_total_liab_cnt      NUMBER := 0;  --Number of AP_CONSIGN_LIABILITY records   -- defect 8779
    gn_total_unabs_cnt     NUMBER := 0;  --Number of AP_CONSIGN_UNABSORBED records  -- defect 8779
    gn_global_loc_cnt      NUMBER := 0;  --Number of OD_GL_GLOBAL_LOCATION records
    gn_total_record_cnt    NUMBER := 0;  --Total record count in file
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization                                |
-- +===================================================================+
-- | Name  : GL_PSFIN_TRANSLATIONS                                     |
-- | Description      :                                                |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       26-JUN-2008 D.Nardo          Initial version             |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE GL_PSFIN_TRANSLATIONS( errbuff OUT varchar2, retcode OUT varchar2)
    AS
	-- ******************************************
	-- Variables defined
	-- ******************************************
        gn_request_id          NUMBER:= FND_GLOBAL.CONC_REQUEST_ID();
        ln_req_id              NUMBER;
        lc_time_stamp          DATE := sysdate;
	lc_translation_name	VARCHAR2(25);
        lc_source_value1	VARCHAR2(30);
	lc_source_value2	VARCHAR2(30);
	lc_source_value3	VARCHAR2(30);
	lc_source_value4	VARCHAR2(30);
	lc_source_value5	VARCHAR2(30);
	lc_source_value6	VARCHAR2(30);
	lc_source_value7	VARCHAR2(30);
	lc_target_value1	VARCHAR2(30);
	lc_target_value2	VARCHAR2(30);
	lc_target_value3	VARCHAR2(30);
	lc_target_value4	VARCHAR2(30);
	lc_target_value5	VARCHAR2(30);
	lc_target_value6	VARCHAR2(30);
	lc_target_value7	VARCHAR2(30);
	lc_target_value8	VARCHAR2(30);
	lc_target_value9	VARCHAR2(30);
	lc_target_value10	VARCHAR2(30);
	lc_target_value11	VARCHAR2(30);
	lc_target_value12	VARCHAR2(30);
	lc_target_value13	VARCHAR2(30);
	lc_target_value14	VARCHAR2(30);
	lc_target_value15	VARCHAR2(30);
	lc_target_value16	VARCHAR2(30);
	lc_target_value17	VARCHAR2(30);
	lc_target_value18	VARCHAR2(30);
	lc_target_value19	VARCHAR2(30);
	lc_target_value20	VARCHAR2(30);
      lc_filler1              VARCHAR2(180);
	lc_start_date           DATE;        
      lc_print_line           VARCHAR2(950);
        lc_phase               VARCHAR2(50);
        lc_status              VARCHAR2(50);
        lc_dev_phase           VARCHAR2(50);
        lc_dev_status          VARCHAR2(50);
        lc_message             VARCHAR2(1000);
        lb_result              BOOLEAN;
        ------------------------
        --gl translations cursor
        ------------------------
	-- The corresponding table in DB2 is OD.TRANTBL. It has 7 source_value columns and 20 target value columns.
        CURSOR gl_translations_cursor 
        IS
	SELECT SUBSTR(B.TRANSLATION_NAME,1,30),
	       NVL(SUBSTR(A.SOURCE_VALUE1,1,30),' '),
             NVL(SUBSTR(A.SOURCE_VALUE2,1,30),' '),
	       NVL(SUBSTR(A.SOURCE_VALUE3,1,30),' '),
             NVL(SUBSTR(A.SOURCE_VALUE4,1,30),' '),
             NVL(SUBSTR(A.SOURCE_VALUE5,1,30),' '),
             NVL(SUBSTR(A.SOURCE_VALUE6,1,30),' '),
             NVL(SUBSTR(A.SOURCE_VALUE7,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE1,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE2,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE3,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE4,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE5,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE6,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE7,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE8,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE9,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE10,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE11,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE12,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE13,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE14,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE15,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE16,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE17,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE18,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE19,1,30),' '),
             NVL(SUBSTR(A.TARGET_VALUE20,1,30),' '),
             A.START_DATE_ACTIVE
          FROM XX_FIN_TRANSLATEVALUES A,
               XX_FIN_TRANSLATEDEFINITION B
         WHERE A.TRANSLATE_ID = B.TRANSLATE_ID
           AND B.ENABLED_FLAG = 'Y'
           AND B.TRANSLATION_NAME IN ('GL_PSFIN_LOCATION',
                                      'GL_PSFIN_LOCATION_TYPE',
                                      'GL_PSFIN_COST_CENTER',
                                      'GL_PSFIN_ACCOUNT',
                                      'AP_CONSIGN_LIABILITY',   -- defect 8779
                                      'AP_CONSIGN_UNABSORBED',  -- defect 8779
			                    'GL_PSFIN_LOB',
			                    'GL_PSFIN_COMPANY')                    	
         ORDER BY B.TRANSLATION_NAME;
        CURSOR gl_locations_cursor 
        IS
	SELECT NVL(SUBSTR(A.FLEX_VALUE,1,30),' '),
               NVL(SUBSTR(A.ATTRIBUTE1,1,30),' ')        
          FROM FND_FLEX_VALUES  A,
               FND_FLEX_VALUE_SETS B
         WHERE B.FLEX_VALUE_SET_NAME = 'OD_GL_GLOBAL_LOCATION'
          AND A.FLEX_VALUE_SET_ID = B.FLEX_VALUE_SET_ID
          AND A.FLEX_VALUE LIKE '0%';
       BEGIN
      --dbms_output.put_line( 'START');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'GL PSFIN TRANSLATION REQUEST NUMBER IS:'||gn_request_id);
       -- XXFIN_OUTPUT is xxfin/outbound    
       g_FileHandle := UTL_FILE.FOPEN('XXFIN_OUTBOUND',gc_output_file,'w');
       ---------------------------------------------------------------------------
       -- Read each row returned by cursor. Format it and write to the output file
       ---------------------------------------------------------------------------
      dbms_output.put_line( 'Processing GL_Translations');
	OPEN gl_translations_cursor;
            LOOP
		FETCH gl_translations_cursor INTO
                             lc_translation_name
                            ,lc_source_value1
                            ,lc_source_value2
                            ,lc_source_value3
                            ,lc_source_value4
                            ,lc_source_value5
                            ,lc_source_value6
                            ,lc_source_value7
                            ,lc_target_value1
                            ,lc_target_value2
                            ,lc_target_value3
                            ,lc_target_value4
                            ,lc_target_value5
                            ,lc_target_value6
                            ,lc_target_value7
                            ,lc_target_value8
                            ,lc_target_value9
                            ,lc_target_value10
                            ,lc_target_value11
                            ,lc_target_value12
                            ,lc_target_value13
                            ,lc_target_value14
                            ,lc_target_value15
                            ,lc_target_value16
                            ,lc_target_value17
                            ,lc_target_value18
                            ,lc_target_value19
                            ,lc_target_value20
                            ,lc_start_date;
      		EXIT WHEN gl_translations_cursor%NOTFOUND;
	---------------------------------------------------------------------------
        -- Create a string of the returned values to be written to the output file.
        -- Defect 11092 - add carraige return (chr(13)) to end of record 
        ---------------------------------------------------------------------------        
                lc_print_line := RPAD(lc_translation_name,30,' ') ||
                                 RPAD(lc_source_value1,30,' ')    ||
                                 RPAD(lc_source_value2,30,' ')    ||
                                 RPAD(lc_source_value3,30,' ')    ||
                                 RPAD(lc_source_value4,30,' ')    ||
                                 RPAD(lc_source_value5,30,' ')    ||
                                 RPAD(lc_source_value6,30,' ')    ||
                                 RPAD(lc_source_value7,30,' ')    || 
                                 RPAD(lc_target_value1,30,' ')    ||
                                 RPAD(lc_target_value2,30,' ')    || 
                                 RPAD(lc_target_value3,30,' ')    ||
                                 RPAD(lc_target_value4,30,' ')    ||
                                 RPAD(lc_target_value5,30,' ')    ||
                                 RPAD(lc_target_value6,30,' ')    ||
                                 RPAD(lc_target_value7,30,' ')    ||
                                 RPAD(lc_target_value8,30,' ')    ||
                                 RPAD(lc_target_value9,30,' ')    ||
                                 RPAD(lc_target_value10,30,' ')   ||
                                 RPAD(lc_target_value11,30,' ')   ||
                                 RPAD(lc_target_value12,30,' ')   || 
                                 RPAD(lc_target_value13,30,' ')   ||
                                 RPAD(lc_target_value14,30,' ')   ||
                                 RPAD(lc_target_value15,30,' ')   || 
                                 RPAD(lc_target_value16,30,' ')   ||
                                 RPAD(lc_target_value17,30,' ')   ||
                                 RPAD(lc_target_value18,30,' ')   ||
                                 RPAD(lc_target_value19,30,' ')   ||
                                 RPAD(lc_target_value20,30,' ')   ||
                                 lc_start_date                    ||
                                 chr(13) ;
	---------------------------------------------------------------------------------
        -- Write the record to the output file and keep counts of the records processed.
        ---------------------------------------------------------------------------------
	        UTL_FILE.PUT_LINE(g_FileHandle, lc_print_line);
		gn_total_record_cnt := gn_total_record_cnt +1;
		BEGIN
                  CASE lc_translation_name
                  WHEN 'GL_PSFIN_LOCATION' THEN
			gn_total_location_cnt := gn_total_location_cnt +1;
                  WHEN 'GL_PSFIN_LOCATION_TYPE' THEN
			gn_total_loc_type_cnt := gn_total_loc_type_cnt +1;                       
                  WHEN 'GL_PSFIN_COST_CENTER' THEN
			gn_total_cc_cnt := gn_total_cc_cnt +1;
                  WHEN 'GL_PSFIN_ACCOUNT' THEN
			gn_total_account_cnt := gn_total_account_cnt +1;
                  WHEN 'GL_PSFIN_LOB' THEN
			gn_total_lob_cnt := gn_total_lob_cnt +1;
      WHEN 'AP_CONSIGN_LIABILITY' THEN             -- defect 8779
			gn_total_liab_cnt := gn_total_liab_cnt +1;   -- defect 8779
      WHEN 'AP_CONSIGN_UNABSORBED' THEN            -- defect 8779
			gn_total_unabs_cnt := gn_total_unabs_cnt +1; -- defect 8779
			WHEN 'GL_PSFIN_COMPANY' THEN
			gn_total_cmpy_cnt := gn_total_cmpy_cnt +1;
		  END CASE;
		END;              
            END LOOP;
        CLOSE gl_translations_cursor;
        ----------------------------------------------------------------------
        -- Now process the Global Locations and write them to the same
        -- output file.
        ----------------------------------------------------------------------
        lc_translation_name := 'GL_ORAFIN_LOC_TO_CMPY';
        lc_filler1 := ' ';
       dbms_output.put_line( 'Processing GL_LOCATIONS');
        OPEN gl_locations_cursor;
            LOOP
		FETCH gl_locations_cursor INTO
                      lc_source_value1
                     ,lc_target_value1;
                EXIT WHEN gl_locations_cursor%NOTFOUND;
        ---------------------------------------------------------------------------
        -- Create a string of the returned values to be written to the output file.
        -- Defect 11092 - add carraige return (chr(13)) to end of record 
        ---------------------------------------------------------------------------        
              lc_print_line := RPAD(lc_translation_name,30,' ') ||
                               RPAD(lc_source_value1,30,' ')    ||
                               RPAD(lc_filler1,180,' ')         ||         
                               RPAD(lc_target_value1,30,' ')    ||
                               chr(13); 
       	---------------------------------------------------------------------------------
        -- Write the record to the output file and keep counts of the records processed.
        ---------------------------------------------------------------------------------
             UTL_FILE.PUT_LINE(g_FileHandle, lc_print_line);
             gn_global_loc_cnt   := gn_global_loc_cnt +1;            
             gn_total_record_cnt := gn_total_record_cnt +1;
            END LOOP;
        CLOSE gl_locations_cursor;
        --dbms_output.put_line( 'CLOSE');
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'GL TRANSLATION RECORDS EXTRACTED: ' || gn_total_record_cnt);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'GL_PSFIN_LOCATION:      ' || gn_total_location_cnt);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'GL_PSFIN_LOCATION TYPE: ' || gn_total_loc_type_cnt);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'GL_PSFIN_COST_CENTER:   ' || gn_total_cc_cnt);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'GL_PSFIN_ACCOUNT:       ' || gn_total_account_cnt);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'GL_PSFIN_LOB:           ' || gn_total_lob_cnt);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'GL_PSFIN_COMPANY:       ' || gn_total_cmpy_cnt);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'AP_CONSIGN_LIABILITY:   ' || gn_total_liab_cnt);    -- defect 8779
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'AP_CONSIGN_UNABSORBED:  ' || gn_total_unabs_cnt);   -- defect 8779
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'OD_GL_GLOBAL_LOCATION:  ' || gn_global_loc_cnt);
        --dbms_output.put_line( 'GL PSFIN EXTRACTED:     ' || gn_total_record_cnt);
        --dbms_output.put_line( 'GL_PSFIN_LOCATION:      ' || gn_total_location_cnt);
        --dbms_output.put_line( 'GL_PSFIN_LOCATION TYPE: ' || gn_total_loc_type_cnt);
        --dbms_output.put_line( 'GL_PSFIN_COST_CENTER:   ' || gn_total_cc_cnt);
        --dbms_output.put_line( 'GL_PSFIN_ACCOUNT:       ' || gn_total_account_cnt);
        --dbms_output.put_line( 'GL_PSFIN_LOB:           ' || gn_total_lob_cnt);
        --dbms_output.put_line( 'OD_GL_GLOBAL_LOCATION:  ' || gn_global_loc_cnt);
        UTL_FILE.FFLUSH(g_FileHandle);
        UTL_FILE.FCLOSE(g_FileHandle);
       ----------------------------------------------------------
       -- Copy the extract file to directory xxfin/ftp/out/mvsftp
       ----------------------------------------------------------
       dbms_lock.sleep(5);
       ln_req_id := fnd_request.submit_request('XXFIN','XXCOMFILCOPY',
                    '','01-OCT-04 00:00:00',FALSE,'$XXFIN_DATA/outbound/'||
                     gc_output_file ,'$XXFIN_DATA/ftp/out/mvsftp/' ||
                     gc_output_file,'','');
       COMMIT;
      IF ln_req_id > 0 THEN
        fnd_file.put_line(fnd_file.log, ' ');
        fnd_file.put_line(fnd_file.log, 'XXCOMFILCOPY req id: ' || ln_req_id); 
      --  dbms_output.put_line( 'XXCOMFILCOPY req id: ' || ln_req_id);  
        lb_result := fnd_concurrent.wait_for_request(ln_req_id,10,0,lc_phase,
                                                          lc_status,lc_dev_phase,
                                                          lc_dev_status,lc_message);
     ELSE
        fnd_file.put_line(fnd_file.log, 'Request Not Submitted.'); 
        fnd_file.put_line(fnd_file.log, 'Reason: ' || fnd_message.get); 
        --dbms_output.put_line( 'XXCOMFILCOPY was not submitted');  
        --dbms_output.put_line('Reason: ' || fnd_message.get);
     END IF;
    IF TRIM(lc_status) = 'Error' THEN
          fnd_file.PUT_LINE(fnd_file.LOG,'Error : ' || 'Copy of '||
                            'the GL PSFIN TRANSLATION File Failed : ' ||
                            lc_status || ' : ' || lc_message);
     END IF;
COMMIT;
EXCEPTION
  WHEN utl_file.invalid_mode THEN
       RAISE_APPLICATION_ERROR (-20051, 'Invalid Mode Parameter');
  WHEN utl_file.invalid_path THEN
    RAISE_APPLICATION_ERROR (-20052, 'Invalid File Location');
  WHEN utl_file.invalid_filehandle THEN
    RAISE_APPLICATION_ERROR (-20053, 'Invalid Filehandle');
  WHEN utl_file.invalid_operation THEN
    RAISE_APPLICATION_ERROR (-20054, 'Invalid Operation');
  WHEN utl_file.read_error THEN
    RAISE_APPLICATION_ERROR (-20055, 'Read Error');
  WHEN utl_file.internal_error THEN
    RAISE_APPLICATION_ERROR (-20057, 'Internal Error');
  WHEN utl_file.charsetmismatch THEN
    RAISE_APPLICATION_ERROR (-20058, 'Opened With FOPEN_NCHAR
    But Later I/O Inconsistent');
  WHEN utl_file.file_open THEN
    RAISE_APPLICATION_ERROR (-20059, 'File Already Opened');
  WHEN utl_file.invalid_maxlinesize THEN
    RAISE_APPLICATION_ERROR(-20060,'Line Size Exceeds 32K');
  WHEN utl_file.invalid_filename THEN
    RAISE_APPLICATION_ERROR (-20061, 'Invalid File Name');
  WHEN utl_file.access_denied THEN
    RAISE_APPLICATION_ERROR (-20062, 'File Access Denied By');
  WHEN utl_file.invalid_offset THEN
    RAISE_APPLICATION_ERROR (-20063,'FSEEK Param Less Than 0');
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Other Exception' || SQLERRM ());
END;
END XX_GL_PSFIN_TRANSLATE_PKG;

/