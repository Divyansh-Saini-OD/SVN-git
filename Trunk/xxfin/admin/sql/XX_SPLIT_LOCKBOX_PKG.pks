CREATE OR REPLACE
PACKAGE XX_SPLIT_LOCKBOX_PKG
IS
  -- +===================================================================================+
  -- +===================================================================================+
  -- | Name        : XX_SPLIT_LOCKBOX_PKG                                                |
  -- | Description : This Package is used to split long running lockbox files.           |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |  1.0     15-NOV-2012  Rajeshkumar M R         Initial version                     |
  -- +===================================================================================+
  g_group_threshold NUMBER:=500;
  -- +===================================================================================+
  -- +===================================================================================+
  -- | Name        : Main                                                                |
  -- | Description : This Main Procedure is used to  split long running lockbox files.   |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |  1.0     15-NOV-2012  Rajeshkumar M R         Initial version                     |
  -- +===================================================================================+
PROCEDURE Main(
    x_errbuf OUT VARCHAR2,
    x_retcode OUT VARCHAR2,
    P_file_name       VARCHAR2,
    p_sub_validate    VARCHAR2,
    p_sub_quick_cash  VARCHAR2,
    p_group_threshold NUMBER DEFAULT 500 );
  -- +===================================================================================+
  -- +===================================================================================+
  -- | Name        : insertData                                                          |
  -- | Description : This Main Procedure is used to insert the data into the             |
  -- |               table used for spliting the data.                                   |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |  1.0     15-NOV-2012  Rajeshkumar M R         Initial version                     |
  -- +===================================================================================+
PROCEDURE insertData(
    p_file_name               VARCHAR2 ,
    p_transmission_request_id NUMBER);
PROCEDURE LaunchValidate(
    p_lockbox_file_name   VARCHAR2,
    p_gl_date1            VARCHAR2,
    p_gl_date2            VARCHAR2,
    p_transmission_req_id NUMBER );
PROCEDURE processLB(
    p_file_name VARCHAR2);
END XX_SPLIT_LOCKBOX_PKG;
/