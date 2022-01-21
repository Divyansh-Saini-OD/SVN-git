CREATE OR REPLACE
PACKAGE XXFIN_FILE_UPLOADS_CMN_PKG AS 

-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       Oracle AMS                                       |
-- +========================================================================+
-- | Name        : XXFIN_FILE_UPLOADS_CMN_PKG                               |
-- | Description : 1) Bulk import OD_FIN_HIER Relationships and credit Limit|
-- |                  into Oracle.                                          |
-- |                                                                        |
-- | RICE : E3056                                                           |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      05-MAY-2013  Dheeraj V            Initial version, QC 22804    |
-- +========================================================================+

  
  PROCEDURE XXFIN_INITIATE_FILE_UPLOAD (x_request_id       OUT NUMBER
                                      ,p_file_upload_id  IN  NUMBER
                                     );

END XXFIN_FILE_UPLOADS_CMN_PKG;
/