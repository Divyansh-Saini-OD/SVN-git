SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE XX_GL_JRNLS_CLD_INTF_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_GL_JRNLS_CLD_INTF_PKG                                                       |
  -- |                                                                                            |
  -- |  Description: This package body is load Oracle Cloud journals file into EBS Staging,Validate 
  -- |					and load into NA_STG Table.                                               |
  -- |  RICE ID   :  I3091_Oracle Cloud GL Interface                 |
  -- |  Description:  load Oracle Cloud journals file into EBS Staging,Validate 				  |
  -- |					and load into NA_STG Table.                                               |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         12/08/2018   M K Pramod Kumar     Initial version                              |
  -- +============================================================================================+
  /****************
  * MAIN PROCEDURE *
  ****************/
PROCEDURE MAIN_PROCESS(
    errbuff OUT VARCHAR2,
    retcode OUT NUMBER,
    p_process_name VARCHAR2,
    p_debug_flag   VARCHAR2);
	  
	PROCEDURE load_utl_file_staging(
    p_process_name VARCHAR2,
    p_file_name    VARCHAR2,
    p_debug_flag   VARCHAR2,
    p_request_id   NUMBER,
	p_user_id   number,
	p_errbuf  OUT nocopy  VARCHAR2 ,
    p_retcode OUT nocopy NUMBER );
	
	PROCEDURE MAIN_LOAD_PROCESS(
    p_process_name VARCHAR2,
    p_file_name    VARCHAR2,
    p_debug_flag   VARCHAR2,
    p_request_id   NUMBER,
	p_user_id      NUMBER);
	

	  
	  TYPE varchar2_table
IS
  TABLE OF VARCHAR2(32767) INDEX BY BINARY_INTEGER;
  
END XX_GL_JRNLS_CLD_INTF_PKG;
/
show errors;
exit;