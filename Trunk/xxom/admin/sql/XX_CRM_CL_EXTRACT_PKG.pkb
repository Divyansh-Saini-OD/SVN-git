SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CRM_CL_EXTRACT_PKG AS
-- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- |                                                                               |
-- +===============================================================================+
-- | Name  : XX_CRM_CL_EXTRACT_PKG.pks                                             |
-- | Description: This package will extract the closed loop SR's and DCR SR's      |
-- |              and will send to external server for dasboard reporting          |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version   Date        Author               Remarks                             |
-- |=======  ===========  =============        ====================================|
-- |1.0      06-JAN-2010  Bapuji Nanapaneni    Initial draft version               |
-- |1.1      01-FEB-2016  Vasu Raparla         Removed Schema References for R.12.2|
-- +===============================================================================+

-- +===========================================================================+
-- | Name: get_close_loop_data                                                 |
-- |                                                                           |
-- | Description: This procdure will be called from a CP and will extract      |
-- |              the closed loop service requests                             |
-- |                                                                           |
-- | Parameters:  x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |              p_extract_date_from                                          |
-- |              p_extract_date_to                                            |
-- |                                                                           |
-- | Returns :    x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
PROCEDURE get_close_loop_data( x_retcode          OUT NOCOPY VARCHAR2
                             , x_errbuff          OUT NOCOPY VARCHAR2
                            , p_extract_date_from IN  VARCHAR2
                            , p_extract_date_to   IN  VARCHAR2 ) IS



/* Cursor to extract all columns to be loaded as comma delimeter*/
CURSOR c_extract ( p_ext_date_from IN VARCHAR2
                 , p_ext_date_to   IN VARCHAR2
                 ) IS
SELECT csi.incident_attribute_11 dc
     , csi.incident_number sr
     , csi.creation_date
     , csi.problem_code
     , csi.summary
     , csi.incident_attribute_2 delivery_date
     , csi.incident_attribute_6 promise_date
     , csi.incident_attribute_13 actual_delivery_date
     , csl.name
     , jtf.source_name CFR_Agent
     , resolution_code
FROM   cs_incidents csi
     , cs_incident_statuses_vl csl
     , jtf_rs_resource_extns jtf
WHERE  jtf.resource_id        = csi.incident_owner_id
  AND  csi.incident_status_id = csl.incident_status_id
  AND  csi.incident_type_id   = 11004
  AND  csi.problem_code      IN('RETURN NOT PICKED UP','LATE DELIVERY')
  AND    NOT EXISTS ( SELECT 'x' FROM cs_lookups
                       WHERE lookup_type = 'XX_CS_CL_RESV_TYPES'
                         AND enabled_flag = 'Y'
                         AND end_date_active is null
                         AND NVL(attribute15, csi.owner_group_id) = csi.owner_group_id
                         AND lookup_code = csi.resolution_code)  
  AND  TO_CHAR(csi.creation_date,'YYYY/MM/DD HH24:MI:SS') BETWEEN p_ext_date_from AND p_ext_date_to
ORDER BY creation_date;

v_file  UTL_FILE.FILE_TYPE;
l_conn  UTL_TCP.connection;
lc_ret_code VARCHAR2(30);
lc_errbuff  VARCHAR2(2000);
BEGIN

  --DBMS_OUTPUT.PUT_LINE('BEGIN');
  FND_FILE.put_line(FND_FILE.OUTPUT,('BEGIN'));
  v_file := UTL_FILE.FOPEN( location     => 'XXOM_INBOUND'
                          , filename     => 'CloseLoop.csv'
                          , open_mode    => 'w'
                          , max_linesize => 32767
                          );
    FND_FILE.put_line(FND_FILE.OUTPUT,('p_extract_date_from: '||p_extract_date_from));
    FOR r_extract IN c_extract(p_extract_date_from ,p_extract_date_to ) LOOP
        --DBMS_OUTPUT.PUT_LINE('csi.incident_number ::: '||r_extract.sr);
        UTL_FILE.PUT_LINE( v_file
                         , r_extract.dc                         ||','||
                           r_extract.sr                         ||','||
                           r_extract.creation_date              ||','||
                           r_extract.problem_code               ||','||
                           r_extract.summary                    ||','||
                           r_extract.delivery_date              ||','||
                           r_extract.promise_date               ||','||
                           r_extract.actual_delivery_date       ||','||
                           r_extract.name                       ||','||
                           r_extract.cfr_agent                  ||','||
                           r_extract.resolution_code            );
    END LOOP;

  UTL_FILE.FCLOSE(v_file);
  
    BEGIN
        --DBMS_OUTPUT.PUT_LINE('Start of File Transfer');
        FND_FILE.put_line(FND_FILE.OUTPUT,('Start of File Transfer'));
        XX_CRM_FTP_PKG.Transfer_File( x_retcode          => lc_ret_code
                                    , x_errbuff          => lc_errbuff
                                    , P_from_directory   => 'XXOM_INBOUND'
                                    , p_from_file_name   => 'CloseLoop.csv'
                                    , p_file_to_name     => 'cscreports/CSCWhseRpts/CloseLoop.csv'
                                    );
        --DBMS_OUTPUT.PUT_LINE('End of File Transfer');
        FND_FILE.put_line(FND_FILE.OUTPUT,('End of File Transfer'));
   
    EXCEPTION
        WHEN OTHERS THEN 
       -- DBMS_OUTPUT.PUT_LINE('Not ABle to Transfer File ::: '||SQLERRM);
        FND_FILE.put_line(FND_FILE.OUTPUT,('Not ABle to Transfer File ::: '||SQLERRM));
    END;
        FND_FILE.put_line(FND_FILE.OUTPUT,('END'));
EXCEPTION
WHEN UTL_FILE.INVALID_PATH THEN
    UTL_FILE.FCLOSE(v_file);
    RAISE_APPLICATION_ERROR(-20000, 'File location is invalid.');

  WHEN UTL_FILE.INVALID_MODE THEN
    UTL_FILE.FCLOSE(v_file);
    RAISE_APPLICATION_ERROR(-20001, 'The open_mode parameter in FOPEN is invalid.');

  WHEN UTL_FILE.INVALID_FILEHANDLE THEN
    UTL_FILE.FCLOSE(v_file);
    RAISE_APPLICATION_ERROR(-20002, 'File handle is invalid.');

  WHEN UTL_FILE.INVALID_OPERATION THEN
    UTL_FILE.FCLOSE(v_file);
    RAISE_APPLICATION_ERROR(-20003, 'File could not be opened or operated on as requested.');

  WHEN UTL_FILE.READ_ERROR THEN
    UTL_FILE.FCLOSE(v_file);
    RAISE_APPLICATION_ERROR(-20004, 'Operating system error occurred during the read operation.');

  WHEN UTL_FILE.WRITE_ERROR THEN
    UTL_FILE.FCLOSE(v_file);
    RAISE_APPLICATION_ERROR(-20005, 'Operating system error occurred during the write operation.');

  WHEN UTL_FILE.INTERNAL_ERROR THEN
    UTL_FILE.FCLOSE(v_file);
    RAISE_APPLICATION_ERROR(-20006, 'Unspecified PL/SQL error.');

  WHEN UTL_FILE.CHARSETMISMATCH THEN
    UTL_FILE.FCLOSE(v_file);
    RAISE_APPLICATION_ERROR(-20007, 'A file is opened using FOPEN_NCHAR, but later I/O ' ||
                                    'operations use nonchar functions such as PUTF or GET_LINE.');

  WHEN UTL_FILE.FILE_OPEN THEN
    UTL_FILE.FCLOSE(v_file);
    RAISE_APPLICATION_ERROR(-20008, 'The requested operation failed because the file is open.');

  WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
    UTL_FILE.FCLOSE(v_file);
    RAISE_APPLICATION_ERROR(-20009, 'The MAX_LINESIZE value for FOPEN() is invalid; it should ' ||
                                    'be within the range 1 to 32767.');

  WHEN UTL_FILE.INVALID_FILENAME THEN
    UTL_FILE.FCLOSE(v_file);
    RAISE_APPLICATION_ERROR(-20010, 'The filename parameter is invalid.');

  WHEN UTL_FILE.ACCESS_DENIED THEN
    UTL_FILE.FCLOSE(v_file);
    RAISE_APPLICATION_ERROR(-20011, 'Permission to access to the file location is denied.');

  WHEN UTL_FILE.INVALID_OFFSET THEN
    UTL_FILE.FCLOSE(v_file);
    RAISE_APPLICATION_ERROR(-20012, 'The ABSOLUTE_OFFSET parameter for FSEEK() is invalid; ' ||
                                    'it should be greater than 0 and less than the total ' ||
                                    'number of bytes in the file.');

  WHEN UTL_FILE.DELETE_FAILED THEN
    UTL_FILE.FCLOSE(v_file);
    RAISE_APPLICATION_ERROR(-20013, 'The requested file delete operation failed.');

  WHEN UTL_FILE.RENAME_FAILED THEN
    UTL_FILE.FCLOSE(v_file);
    RAISE_APPLICATION_ERROR(-20014, 'The requested file rename operation failed.');

  WHEN OTHERS THEN
    UTL_FILE.FCLOSE(v_file);
    RAISE;
    

END get_close_loop_data;

-- +==============================================================================+
-- | Name: getdc_request_data                                                     |
-- |                                                                              |
-- | Description: This prcodure will be called from a CP and will extract         |
-- |              the DC Request service requests                                 |
-- |                                                                              |
-- | Parameters:  x_retcode                                                       |
-- |              x_errbuff                                                       |
-- |              p_extract_date_from                                             |
-- |              p_extract_date_to                                               |
-- |                                                                              |
-- | Returns :    x_retcode                                                       |
-- |              x_errbuff                                                       |
-- |                                                                              |
-- |                                                                              |
-- +==============================================================================+

PROCEDURE getdc_request_data( x_retcode          OUT NOCOPY VARCHAR2
                            , x_errbuff          OUT NOCOPY VARCHAR2
                            , p_extract_date_from IN  VARCHAR2
                            , p_extract_date_to   IN  VARCHAR2 ) IS

/* Cursor to extract all columns to be loaded as comma delimeter*/
CURSOR c_extract ( p_ext_date_from IN VARCHAR2
                 , p_ext_date_to   IN VARCHAR2
                 ) IS
SELECT jtfg.group_name group_name
     , inc_b.incident_attribute_11 dc
     , inc_b.incident_number
     , stat.name status
     , decode(aud.group_id, inc_b.owner_group_id,'N','Y') Reassigned_flag
     , inc_b.summary
     , jtfr.source_name owner
     , inc_b.obligation_date due_date
     , inc_b.creation_date	
     , inc_b.last_update_date modified_date
     , inc_b.problem_code
     , inc_b.resolution_code
     , decode(inc_b.incident_attribute_12,null,inc_b.incident_attribute_1,inc_b.incident_attribute_1||','||inc_b.incident_attribute_12) Order_no
     , decode(inc_b.incident_attribute_6,null,inc_b.incident_attribute_2,inc_b.incident_attribute_6) Delivery_date
 FROM  cs_incidents inc_b
     , cs_incident_statuses_tl stat
     , jtf_rs_groups_tl jtfg
     , jtf_rs_resource_extns jtfr
     , cs_incidents_audit_b aud
WHERE  aud.incident_id = inc_b.incident_id
  AND jtfr.resource_id = inc_b.incident_owner_id
  AND inc_b.incident_status_id = stat.incident_status_id
  AND jtfg.group_id = inc_b.owner_group_id
  AND aud.updated_entity_code = 'SR_HEADER'
  AND aud.old_group_id is null
  AND inc_b.incident_type_id = 11004
  AND inc_b.problem_code in ('ADDRESS CHANGE REQUEST','UNDELIVERABLE ORDER','CANCELLATION REQUEST','CARRIER COMPLAINT')
  AND NOT EXISTS ( SELECT 'x' FROM cs_lookups
                    WHERE lookup_type = 'XX_CS_CL_RESV_TYPES'
                      AND enabled_flag = 'Y'
                      AND end_date_active is null
                      AND NVL(attribute15, inc_b.owner_group_id) = inc_b.owner_group_id
                      AND lookup_code = inc_b.resolution_code)
  AND TO_CHAR(inc_b.creation_date,'YYYY/MM/DD HH24:MI:SS') BETWEEN p_ext_date_from AND p_ext_date_to
 -- AND inc_b.creation_date >= sysdate-1
ORDER BY inc_b.owner_group_id, inc_b.creation_date;

v_file  UTL_FILE.FILE_TYPE;
l_conn  UTL_TCP.connection;
lc_ret_code VARCHAR2(30);
lc_errbuff  VARCHAR2(2000);
BEGIN

  --DBMS_OUTPUT.PUT_LINE('BEGIN');
  FND_FILE.put_line(FND_FILE.OUTPUT,('BEGIN'));
  v_file := UTL_FILE.FOPEN( location     => 'XXOM_INBOUND'
                          , filename     => 'DCRequests.csv'
                          , open_mode    => 'w'
                          , max_linesize => 32767
                          );
                          
     FOR r_extract IN c_extract(p_extract_date_from ,p_extract_date_to ) LOOP
         
         --DBMS_OUTPUT.PUT_LINE('csi.incident_number ::: '||r_extract.incident_number);
         UTL_FILE.PUT_LINE( v_file
                          , r_extract.group_name          ||','||
                            r_extract.dc                  ||','||
                            r_extract.incident_number     ||','||
                            r_extract.status              ||','||
                            r_extract.summary             ||','||
                            r_extract.Reassigned_flag     ||','||
                            r_extract.owner               ||','||
                            r_extract.due_date            ||','||
                            r_extract.creation_date       ||','||
                            r_extract.modified_date       ||','||
                            r_extract.problem_code        ||','||
                            r_extract.resolution_code     ||','||
                            r_extract.Order_no            ||','||
                            r_extract.Delivery_date       
                          );
                          
     END LOOP;

   UTL_FILE.FCLOSE(v_file);
   BEGIN
      -- DBMS_OUTPUT.PUT_LINE('Start of File Transfer');
       FND_FILE.put_line(FND_FILE.OUTPUT,('Start of File Transfer'));
      XX_CRM_FTP_PKG.Transfer_File( x_retcode          => lc_ret_code
                                  , x_errbuff          => lc_errbuff
                                  , P_from_directory   => 'XXOM_INBOUND'
                                  , p_from_file_name   => 'DCRequests.csv'
                                  , p_file_to_name     => 'cscreports/CSCWhseRpts/DCRequests.csv'
                                  );
      -- DBMS_OUTPUT.PUT_LINE('End of File Transfer');
       FND_FILE.put_line(FND_FILE.OUTPUT,('End of File Transfer'));

   EXCEPTION
       WHEN OTHERS THEN 
       --DBMS_OUTPUT.PUT_LINE('Not ABle to Transfer File ::: '||SQLERRM);
       FND_FILE.put_line(FND_FILE.OUTPUT,('Not ABle to Transfer File ::: '||SQLERRM));
   END;
   FND_FILE.put_line(FND_FILE.OUTPUT,('END'));

 EXCEPTION
 WHEN UTL_FILE.INVALID_PATH THEN
     UTL_FILE.FCLOSE(v_file);
     RAISE_APPLICATION_ERROR(-20000, 'File location is invalid.');

   WHEN UTL_FILE.INVALID_MODE THEN
     UTL_FILE.FCLOSE(v_file);
     RAISE_APPLICATION_ERROR(-20001, 'The open_mode parameter in FOPEN is invalid.');

   WHEN UTL_FILE.INVALID_FILEHANDLE THEN
     UTL_FILE.FCLOSE(v_file);
     RAISE_APPLICATION_ERROR(-20002, 'File handle is invalid.');

   WHEN UTL_FILE.INVALID_OPERATION THEN
     UTL_FILE.FCLOSE(v_file);
     RAISE_APPLICATION_ERROR(-20003, 'File could not be opened or operated on as requested.');

   WHEN UTL_FILE.READ_ERROR THEN
     UTL_FILE.FCLOSE(v_file);
     RAISE_APPLICATION_ERROR(-20004, 'Operating system error occurred during the read operation.');

   WHEN UTL_FILE.WRITE_ERROR THEN
     UTL_FILE.FCLOSE(v_file);
     RAISE_APPLICATION_ERROR(-20005, 'Operating system error occurred during the write operation.');

   WHEN UTL_FILE.INTERNAL_ERROR THEN
     UTL_FILE.FCLOSE(v_file);
     RAISE_APPLICATION_ERROR(-20006, 'Unspecified PL/SQL error.');

   WHEN UTL_FILE.CHARSETMISMATCH THEN
     UTL_FILE.FCLOSE(v_file);
     RAISE_APPLICATION_ERROR(-20007, 'A file is opened using FOPEN_NCHAR, but later I/O ' ||
                                     'operations use nonchar functions such as PUTF or GET_LINE.');

   WHEN UTL_FILE.FILE_OPEN THEN
     UTL_FILE.FCLOSE(v_file);
     RAISE_APPLICATION_ERROR(-20008, 'The requested operation failed because the file is open.');

   WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
     UTL_FILE.FCLOSE(v_file);
     RAISE_APPLICATION_ERROR(-20009, 'The MAX_LINESIZE value for FOPEN() is invalid; it should ' ||
                                     'be within the range 1 to 32767.');

   WHEN UTL_FILE.INVALID_FILENAME THEN
     UTL_FILE.FCLOSE(v_file);
     RAISE_APPLICATION_ERROR(-20010, 'The filename parameter is invalid.');

   WHEN UTL_FILE.ACCESS_DENIED THEN
     UTL_FILE.FCLOSE(v_file);
     RAISE_APPLICATION_ERROR(-20011, 'Permission to access to the file location is denied.');

   WHEN UTL_FILE.INVALID_OFFSET THEN
     UTL_FILE.FCLOSE(v_file);
     RAISE_APPLICATION_ERROR(-20012, 'The ABSOLUTE_OFFSET parameter for FSEEK() is invalid; ' ||
                                     'it should be greater than 0 and less than the total ' ||
                                     'number of bytes in the file.');

   WHEN UTL_FILE.DELETE_FAILED THEN
     UTL_FILE.FCLOSE(v_file);
     RAISE_APPLICATION_ERROR(-20013, 'The requested file delete operation failed.');

   WHEN UTL_FILE.RENAME_FAILED THEN
     UTL_FILE.FCLOSE(v_file);
     RAISE_APPLICATION_ERROR(-20014, 'The requested file rename operation failed.');

   WHEN OTHERS THEN
     UTL_FILE.FCLOSE(v_file);
     RAISE;

  
END getdc_request_data;

END XX_CRM_CL_EXTRACT_PKG;
/
SHOW ERRORS PACKAGE BODY XX_CRM_CL_EXTRACT_PKG;
EXIT;

