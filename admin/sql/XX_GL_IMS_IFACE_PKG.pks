SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE XX_GL_IMS_IFACE_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_GL_IMS_IFACE_PKG                                                       		  |
  -- |                                                                                            |
  -- |  Description: This package body is load IMS Inventory Journals file into EBS Staging,Validate 
  -- |					and load into NA_STG Table.                                               |
  -- |  RICE ID   :  I3131-GL Inventory Journals IMS to EBS                 					  |
  -- |  Description:  load IMS Inventory journals file into EBS Staging,Validate 				  |
  -- |					and load into NA_STG Table.                                               |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         01/02/2021   Amit Kumar			
  -- +============================================================================================+
	  
	PROCEDURE load_utl_file_staging(
    p_file_name    VARCHAR2,
	p_file_dir	   VARCHAR2,
    p_debug_flag   VARCHAR2,
    p_request_id   NUMBER,
	p_user_id   number,
	p_errbuf  OUT nocopy  VARCHAR2 ,
    p_retcode OUT nocopy NUMBER );
	
	PROCEDURE MAIN_LOAD_PROCESS(
    p_file_name    VARCHAR2,
	p_file_dir	   VARCHAR2,
    p_debug_flag   VARCHAR2,
    p_request_id   NUMBER,
	p_user_id      NUMBER);
	
	PROCEDURE MAIN_PROCESS(
    p_debug_flag   VARCHAR2,
    errbuff OUT VARCHAR2,
    retcode OUT NUMBER); 

	  
	  TYPE varchar2_table
IS
  TABLE OF VARCHAR2(32767) INDEX BY BINARY_INTEGER;
  
END XX_GL_IMS_IFACE_PKG;
/
show errors;
exit;