SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE XX_GL_JRNLS_CLD_INTF_PKG
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
  -- | 1.2         09/11/2020   Mayur Palsokar       NAIT-161587 - Fix                            |
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
	
	/*Start: Added for NAIT-161587 */
PROCEDURE XX_SEND_NOTIFICATION(
                     P_REQUEST_ID IN NUMBER,
                     X_STATUS OUT VARCHAR2,
                     X_ERROR OUT VARCHAR2);
					 
Procedure XX_PURGE_STAGING;

	/*End: Added for NAIT-161587 */
	  
TYPE varchar2_table
IS
  TABLE OF VARCHAR2(32767) INDEX BY BINARY_INTEGER;
  
END XX_GL_JRNLS_CLD_INTF_PKG;

/
show errors;
exit;