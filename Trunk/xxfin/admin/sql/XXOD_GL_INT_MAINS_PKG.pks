CREATE OR REPLACE
PACKAGE  XXOD_GL_INT_MAINS_PKG
AS
 -- +====================================================================+
  -- |                  Office Depot - Project Simplify                   |
  -- +====================================================================+
  -- | Name         : XXOD_GL_INT_MAINS_PKG                               |
  -- | Description  : This package is used to submit the OD: Journal GL   |
  -- |                Interface Report with default output as EXCEL.      |
  -- |                                                                    |
  -- |Change Record:                                                      |
  -- |===============                                                     |
  -- |Version  Date         Author         Remarks                        |
  -- |=======  ===========  =============  ===============================|
  -- | 1       26-NOV-2013  Ankit Arora    Initial version                |
  -- |                                     Created for Defect 15713  
  -- | 2       01-AUG-2014  Manjusha Tangirala Defect 30541               |
  -- +====================================================================+
  -- +====================================================================+
  -- | Name        : XXOD_GL_INT_MAINS_PKG.MAIN                           |
  -- | Description : This procedure is used to the OD: Journal GL         |
  -- |                Interface Report with default output as EXCEL.      |
  -- |                                                                    |
  -- | Parameters  : 1. P_START_PERIOD                                    |
  -- |               2  P_END_PERIOD                                      |
  -- |               3. P_SET_OF_BOOK_ID    
  -- |               4. P_ALL_OR_ERROR                                    |
  -- |                                                                    |
  -- | Returns     :   x_errbuf, x_ret_code                               |
  -- |                                                                    |
  -- |                                                                    |
  -- +====================================================================+
PROCEDURE MAIN( x_err_buf OUT VARCHAR2 ,
    x_retcode OUT NUMBER ,
    P_START_PERIOD IN VARCHAR2 ,
    P_END_PERIOD  IN VARCHAR2 ,
    P_SET_OF_BOOK_ID IN VARCHAR2,
    P_all_or_error  In Varchar2
                            );

END ;
/