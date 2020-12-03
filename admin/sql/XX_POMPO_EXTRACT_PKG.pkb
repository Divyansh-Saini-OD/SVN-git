CREATE OR REPLACE PACKAGE BODY XX_POMPO_EXTRACT_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_POMPO_EXTRACT_PKG                                                               |
  -- |                                                                                            |
  -- |  Description: Scripts for fetching Po Number from EBS and placed into the XXFIN Top.       |
  -- |  RICE ID:                                                                                  |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  ===============      =============================================|
  -- | 1.0         28-OCT-2020   Karan Varshney      Initial Version Added                        |
  -- +============================================================================================|
  -- +============================================================================================|
  
  PROCEDURE print_out_msg (p_message IN VARCHAR2)
  IS
    lc_message VARCHAR2 (4000) := NULL;
  
  BEGIN
       lc_message := p_message;
       fnd_file.put_line (fnd_file.LOG, lc_message);
       dbms_output.put_line (lc_message);
  EXCEPTION
  WHEN OTHERS THEN
    NULL;
  END print_out_msg;

  PROCEDURE POM_PO_EXPORT_PRC (ERRBUF OUT VARCHAR2,
                               RETCODE OUT NUMBER
                              )
  IS
  
  CURSOR pom_extract (p_act_comp_date  DATE)
  IS
    SELECT SEGMENT1 PO_NUMBER
    FROM  PO_HEADERS_ALL A
    WHERE 1=1
    --AND A.CREATION_DATE > '31-DEC-17'
    AND EXISTS (SELECT 'x'
                FROM AP_SUPPLIER_SITES_ALL B
                WHERE B.VENDOR_SITE_ID = A.VENDOR_SITE_ID
                AND SUBSTR(B.ATTRIBUTE8,1,2) = 'TR'
                )
    AND (INSTR(SEGMENT1,'-',-1,1) -1) = 7            
    AND A.CREATION_DATE > p_act_comp_date
    AND A.LAST_UPDATE_DATE > p_act_comp_date
    ;
    
    lc_file_handle  utl_file.file_type;  
    l_file_name     VARCHAR2(100);
    l_file_path     VARCHAR2(500):= 'XXFIN_PO_TRADE';
    l_col_val       VARCHAR2(5000);
    l_errormsg      VARCHAR2(1000);
    l_act_comp_date	DATE;
    
   BEGIN
    print_out_msg ('Package MAIN START');
    l_file_name    := 'EBS_TRADE_PO' || '.txt';
    lc_file_handle := utl_file.fopen(l_file_path, l_file_name, 'W');
    --l_col_val := 'PO_NUMBER';
    
    --utl_file.put_line(lc_file_handle,l_col_val);
    BEGIN
      SELECT NVL(ACTUAL_COMPLETION_DATE, '31-DEC-17') 
      INTO l_act_comp_date
      FROM FND_CONCURRENT_REQUESTS
      WHERE 1=1
      AND REQUEST_ID = (SELECT MAX(REQUEST_ID)
                        FROM FND_CONCURRENT_REQUESTS
                        WHERE CONCURRENT_PROGRAM_ID = 403298
                        AND PHASE_CODE = 'C'
                        AND STATUS_CODE = 'C'
                        );
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    l_act_comp_date := NULL;
    WHEN OTHERS THEN
    l_act_comp_date := NULL;
    END;
	
    IF l_act_comp_date IS NULL
    THEN
      l_act_comp_date := '31-DEC-17';	
    END IF;
	
    print_out_msg ('ACTUAL_COMPLETION_DATE: '|| l_act_comp_date);
    print_out_msg ('LOOP POM_EXTRACT START');
    FOR i IN pom_extract (l_act_comp_date)
    LOOP
      utl_file.put_line(lc_file_handle, i.PO_NUMBER);
    
    END LOOP;
    COMMIT;
      utl_file.fclose(lc_file_handle);  
    
    print_out_msg ('COPY_FILE START');
    
    /*Copy the file in XXFIN archieve folder */
    BEGIN
      UTL_FILE.FCOPY ('XXFIN_PO_TRADE',
                      'EBS_TRADE_PO.txt',
                      'XXFIN_OUTBOUND_ARCH',
                      'EBS_TRADE_PO.txt'
                      );
    END;
    print_out_msg ('COPY_FILE in Archieve Folder END');
    print_out_msg ('POM_EXTRACT PROCESS END');
   
   EXCEPTION
   WHEN utl_file.access_denied THEN
    l_errormsg := ( 'Error in MAIN procedure :- ' ||
    ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_out_msg (l_errormsg);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
   WHEN utl_file.delete_failed THEN
    l_errormsg := ( 'Error in MAIN procedure :- ' ||
    ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_out_msg (l_errormsg);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
   WHEN utl_file.file_open THEN
    l_errormsg := ( 'Error in MAIN procedure :- ' ||
    ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_out_msg (l_errormsg);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
   WHEN utl_file.internal_error THEN
    l_errormsg := ( 'Error in MAIN procedure :- ' ||
    ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_out_msg (l_errormsg);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
   WHEN utl_file.invalid_filehandle THEN
    l_errormsg := ( 'Error in MAIN procedure:- ' ||
    ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_out_msg (l_errormsg);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
   WHEN utl_file.invalid_filename THEN
    l_errormsg := ( 'Error in MAIN procedure :- ' ||
    ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_out_msg (l_errormsg);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
   WHEN utl_file.invalid_maxlinesize THEN
    l_errormsg := ( 'Error in MAIN procedure :- ' ||
    ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_out_msg (l_errormsg);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
   WHEN utl_file.invalid_mode THEN
    l_errormsg := ( 'Error in MAIN procedure :- ' ||
    ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_out_msg (l_errormsg);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
   WHEN utl_file.invalid_offset THEN
    l_errormsg := ( 'Error in MAIN procedure :- ' ||
    ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_out_msg (l_errormsg);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
   WHEN utl_file.invalid_operation THEN
    l_errormsg := ( 'Error in MAIN procedure :- ' ||
    ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_out_msg (l_errormsg);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
   WHEN utl_file.invalid_path THEN
    l_errormsg := ( 'Error in MAIN procedure :- ' ||
    ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_out_msg (l_errormsg);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
   WHEN utl_file.read_error THEN
    l_errormsg := ( 'Error in MAIN procedure :- ' ||
    ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_out_msg (l_errormsg);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
   WHEN utl_file.rename_failed THEN
    l_errormsg := ( 'Error in MAIN procedure :- ' ||
    ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_out_msg (l_errormsg);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
   WHEN utl_file.write_error THEN
    l_errormsg := ( 'Error in MAIN procedure :- ' ||
    ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_out_msg (l_errormsg);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
   WHEN OTHERS THEN
    l_errormsg := ( 'Error in MAIN procedure :- ' ||
    ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_out_msg (l_errormsg);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  END POM_PO_EXPORT_PRC; 
END XX_POMPO_EXTRACT_PKG;
/