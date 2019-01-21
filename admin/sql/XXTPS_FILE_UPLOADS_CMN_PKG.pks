create or replace
PACKAGE XXTPS_FILE_UPLOADS_CMN_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name             :  XXTPS_FILE_UPLOADS_CMN_PKG                    |
-- | Description      :  This package is used to upload data from      |
-- |                     a .csv file into a staging table and call a   |
-- |                     function which will validate the data and     |
-- |                     insert it into appropriate tables.            |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author              Remarks                  |
-- |=======   ==========  ================    =========================|
-- |1.0       20-FEB-2008 Shabbar Hasan       Initial version          |
-- |                      Wipro Technologies                           |
-- |2.0       25-MAY-2010 Mangalasundari K                             |
-- |                     Wipro Technologies                            |
-- |                         CR739 Included an Out Paramter Request Id |
-- |                               in the Procedure                    |
-- +===================================================================+
AS
  TYPE gt_tbltyp_strings IS TABLE OF VARCHAR2(32000)
  INDEX BY BINARY_INTEGER;

  PROCEDURE XXTPS_INITIATE_FILE_UPLOAD ( x_request_id          OUT NUMBER
                                        ,p_file_upload_id      IN  NUMBER
                                       );

  PROCEDURE XXTPS_FILE_UPLOAD (
                               x_error_code      OUT NOCOPY NUMBER
                              ,x_error_buf      OUT NOCOPY VARCHAR2
                              ,p_file_upload_id IN         NUMBER
                              );

END XXTPS_FILE_UPLOADS_CMN_PKG;
/
SHOW ERR;