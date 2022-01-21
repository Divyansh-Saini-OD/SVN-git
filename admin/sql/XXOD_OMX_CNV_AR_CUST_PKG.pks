create or replace PACKAGE XXOD_OMX_CNV_AR_CUST_PKG
AS
 -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XXOD_OMX_CNV_AR_CUST_PKG                                                           |
  -- |                                                                                            |
  -- |  Description:  This package is used to create Office Depot North Customers.                |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         12-DEC-2017  Punit Gupta      Initial version                                  |
  -- +============================================================================================+
PROCEDURE LOAD_CUSTOMERS(
                  x_error_buff         OUT VARCHAR2
                 ,x_ret_code           OUT NUMBER
                 ,p_validate_only_flag IN  VARCHAR2
                 ,p_process_flag  IN VARCHAR2 
                 ,p_reprocess_flag  IN VARCHAR2
  );
END XXOD_OMX_CNV_AR_CUST_PKG;
/
