SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace 
PACKAGE xx_ap_approval_cent_pkg
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  xx_ap_approval_cent_pkg                                                         |
  -- |  RICE ID   :
  -- |  Solution ID:                                                                    |
  -- |  Description:
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         26-Mar-2018   Priyam Parmar       Initial version                                  |
  -- +============================================================================================+
  PROCEDURE xx_ap_apprvl_wrapper(
      x_error_buff out varchar2 ,
      x_ret_code out number);
  PROCEDURE xx_submit_invoice_validation(
      x_error_buff OUT VARCHAR2 ,
      x_ret_code OUT NUMBER,
      p_cutoff_date varchar2);
  -- P_OU varchar2);
  PROCEDURE xx_ap_apprvl_reprocess(
      x_error_buff OUT VARCHAR2 ,
      x_ret_code OUT NUMBER,
      p_invoice_id NUMBER);
END xx_ap_approval_cent_pkg;
/
SHOW ERROR;