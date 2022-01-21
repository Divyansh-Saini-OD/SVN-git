CREATE OR REPLACE
PACKAGE BODY XXFIN_FILE_UPLOADS_CMN_PKG AS

-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       Oracle AMS                                       |
-- +========================================================================+
-- | Name        : XXFIN_FILE_UPLOADS_CMN_PKG                               |
-- | Description : 1) Bulk import OD_FIN_HIER Relationships and credit Limit|
-- |                  into Oracle.                                          |
-- |                                                                        |
-- | RICE : E3056                                                           |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      05-MAY-2013  Dheeraj V            Initial version, QC 22804    |
-- |1.1      11-DEC-2015  Vasu Raparla         Removed Schema References    |
-- |                                           for R.12.2                   |
-- |1.2      19-Oct-2016  Sridevi K	           Modified for moving from     |
-- |                                           xxtps to xxcrm               |
-- +========================================================================+


PROCEDURE XXFIN_INITIATE_FILE_UPLOAD (x_request_id       OUT NUMBER
                                      ,p_file_upload_id  IN  NUMBER
                                     )

AS
  ln_req_id NUMBER;
  lc_prog_name VARCHAR2(25);
  lc_template VARCHAR2(25);
  
BEGIN

  
  SELECT clob_code 
  INTO lc_template
  FROM xxcrm_file_uploads
  WHERE file_upload_id = p_file_upload_id;

  
  SELECT flv.DESCRIPTION 
  INTO lc_prog_name
  FROM fnd_lookup_types flt, fnd_lookup_values flv
  WHERE flt.lookup_type = 'XX_FIN_TEMPLATE_PROG_MAPPING'
  AND flt.lookup_type = flv.lookup_type
  AND NVL(flv.enabled_flag,'N') = 'Y' 
  AND sysdate BETWEEN flv.start_date_active AND NVL(flv.end_date_active, sysdate+1)
  AND flv.meaning = lc_template;
    
    

  ln_req_id := FND_REQUEST.SUBMIT_REQUEST(
                   application => 'XXFIN'            
                   ,program    => lc_prog_name
                   ,start_time => sysdate
                   ,sub_request => false
                   ,argument1  => p_file_upload_id );
   COMMIT;
  IF ln_req_id = 0 THEN
    UPDATE xxcrm_file_uploads
    SET    error_file_data = TO_CLOB('Request failed' || chr(10))
           ,file_status = 'E'
           ,last_updated_by = -1
           ,last_update_date = SYSDATE
    WHERE  file_upload_id = p_file_upload_id;
  ELSE
    UPDATE xxcrm_file_uploads
    SET    request_id = ln_req_id
    WHERE  file_upload_id = p_file_upload_id;
  END IF;
  COMMIT;
  x_request_id := ln_req_id ;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Unexpected Error: ' || SQLERRM);
END XXFIN_INITIATE_FILE_UPLOAD;

END XXFIN_FILE_UPLOADS_CMN_PKG;
/