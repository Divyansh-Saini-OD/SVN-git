SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CRM_CUST360DETAILS_PKG
AS
PROCEDURE GET_CUST_INFO (
                           P_AOPS_ACCT_ID  IN   NUMBER,
                           P_CUST_OUT      OUT  XX_CRM_FULL_CUST_INFO_BO
);
END XX_CRM_CUST360DETAILS_PKG;
/
show errors;
