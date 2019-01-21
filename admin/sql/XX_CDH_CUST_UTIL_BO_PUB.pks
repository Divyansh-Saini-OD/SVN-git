
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_CUST_UTIL_BO_PVT
  -- +==================================================================================================+
  -- |                  Office Depot - Project Simplify                                                 |
  -- +==================================================================================================|
  -- |Name       : XX_CDH_CUST_UTIL_BO_PVT                                                              |
  -- |Description: Wrapper for having utility procs and functions. Contains log messages and            |
  -- |             exceptions                                                                           |
  -- |                                                                                                  |
  -- |Change Record:                                                                                    |
  -- |                                                                                                  |
  -- |Version     Date            Author               Remarks                                          |
  -- |                                                                                                  |
  -- |DRAFT 1   18-OCT-2012   Sreedhar Mohan           Initial draft version                            |
  -- |                                                                                                  |
  -- |==================================================================================================|
  -- |Subversion Info:                                                                                  |
  -- |$HeadURL: http://svn.na.odcorp.net/svn/od/crm/trunk/xxcrm/admin/sql/XX_CDH_CUST_UTIL_BO_PVT.pks $ |                                                                          |
  -- |$Rev: 103271 $                                                                                    |
  -- |$Date: 2012-10-18 01:56:07 -0400 (Thu, 18 Oct 2012) $                                             |
  -- |                                                                                                  |
  -- +==================================================================================================+
AS
  -- +================================================================================================+
  -- | Name             : LOG_MSG                                                                     |
  -- | Description      : This procedure inserts log messages into XX_CDH_CUSTOMER_BO_LOG             |
  -- |                                                                                                |
  -- +================================================================================================+

  PROCEDURE log_msg(   
    p_bo_process_id           IN NUMBER DEFAULT 0,
    p_msg                     IN VARCHAR2
  );
                   
  PROCEDURE log_exception (
    p_bo_process_id           IN NUMBER DEFAULT 0,
    p_bpel_process_id         IN NUMBER,  
    p_bo_object_name          IN VARCHAR2,
    p_log_date                IN DATE, 
    p_logged_by               IN NUMBER,
    p_package_name            IN VARCHAR2,
    p_procedure_name          IN VARCHAR2,
    p_bo_table_name           IN VARCHAR2,
    p_bo_column_name          IN VARCHAR2,
    p_bo_column_value         IN VARCHAR2,
    p_orig_system             IN VARCHAR2,
    p_orig_system_reference   IN VARCHAR2,
    p_exception_log           IN VARCHAR2,
    p_oracle_error_code       IN VARCHAR2,
    p_oracle_error_msg        IN VARCHAR2 
   ); 

  PROCEDURE save_gt(
    P_BO_PROCESS_ID           IN NUMBER,
    P_BO_ENTITY_NAME          IN VARCHAR2,
    P_BO_TABLE_ID             IN NUMBER,
    P_ORIG_SYSTEM             IN VARCHAR2,
    P_ORIG_SYSTEM_REFERENCE   IN VARCHAR2
  );   

  PROCEDURE purge_gt;
  
  FUNCTION get_orig_system_ref_id(
    p_orig_system             IN VARCHAR2,
    p_orig_system_reference   IN VARCHAR2, 
    p_owner_table_name        IN VARCHAR2
  ) RETURN NUMBER;

  function get_os_owner_table_id(
    p_orig_system             IN VARCHAR2,
    p_orig_system_reference   IN VARCHAR2, 
    p_owner_table_name        IN VARCHAR2
  ) RETURN NUMBER;

  FUNCTION is_account_exists(
    p_acct_orig_sys_ref       IN VARCHAR2,
    p_acct_orig_sys           IN VARCHAR2
  ) RETURN NUMBER;

  FUNCTION is_acct_site_exists(
    p_site_orig_sys_ref       IN VARCHAR2,
    p_site_orig_sys           IN VARCHAR2
  ) RETURN NUMBER;	

  FUNCTION is_acct_site_use_exists(
    p_site_orig_sys_ref       IN VARCHAR2,
    p_orig_sys                IN VARCHAR2,
    p_site_code               IN VARCHAR2
  ) RETURN NUMBER;	

  FUNCTION bill_to_use_id_val(
    p_bill_to_orig_sys        IN VARCHAR2,
    p_bill_to_orig_add_ref    IN VARCHAR2
  ) RETURN NUMBER;	

  FUNCTION ar_lookup_val(
    p_site_orig_sys_ref       IN VARCHAR2,
    p_site_orig_sys           IN VARCHAR2
  ) RETURN BOOLEAN;	
  
END XX_CDH_CUST_UTIL_BO_PVT;
/
SHOW ERRORS
