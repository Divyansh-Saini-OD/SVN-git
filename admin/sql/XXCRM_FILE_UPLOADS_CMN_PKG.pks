create or replace 
PACKAGE XXCRM_FILE_UPLOADS_CMN_PKG
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name             :  XXCRM_FILE_UPLOADS_CMN_PKG                           |
-- | Description      :  This package is used to upload data from             |
-- |                     a .csv file into a staging table and call a          |
-- |                     function which will validate the data and            |
-- |                     insert it into appropriate tables.                   |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date        Author            Remarks                           |
-- |=======   ==========  ================  ==================================|
-- |1.0       20-FEB-2008 Shabbar Hasan     Initial version                   |
-- |                                                                          |
-- |2.0       25-MAY-2010 Mangalasundari K                                    |
-- |                         CR739 Included an Out Paramter Request Id        |
-- |                               in the Procedure                           |
-- |                                                                          |
-- |3.0       27-JAN-2011 Srini             Add TRUNCATE_TABLE function(CR864)|
-- |                                                                          |
-- |4.0       04-OCT-2016 Shubhashree R     Modified the pkg to move it from  |
-- |                                        XXTPS to XXCRM                    |
-- +==========================================================================+
AS
  TYPE gt_tbltyp_strings IS TABLE OF VARCHAR2(32000)
  INDEX BY BINARY_INTEGER;

  PROCEDURE XXCRM_INITIATE_FILE_UPLOAD ( x_request_id          OUT NUMBER
                                        ,p_file_upload_id      IN  NUMBER
                                       );

  PROCEDURE XXCRM_FILE_UPLOAD (
                               x_error_code      OUT NOCOPY NUMBER
                              ,x_error_buf      OUT NOCOPY VARCHAR2
                              ,p_file_upload_id IN         NUMBER
                              );

  FUNCTION TRUNCATE_TABLE ( p_table_name   VARCHAR2
                            )
  RETURN VARCHAR2;

  FUNCTION ANALYZE_TABLE (
        p_owner_name         VARCHAR2
       ,p_table_name         VARCHAR2
       ,p_estimate_percent   NUMBER
                            )
  RETURN VARCHAR2;

END XXCRM_FILE_UPLOADS_CMN_PKG;
/

SHOW ERRORS;