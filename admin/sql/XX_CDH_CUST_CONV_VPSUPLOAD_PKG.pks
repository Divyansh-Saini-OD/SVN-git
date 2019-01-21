SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE XX_CDH_CUST_CONV_VPSUPLOAD_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_CDH_CUST_CONV_VPSUPLOAD_PKG                                                     |
  -- |                                                                                            |
  -- |  Description:  This package is used by WEB ADI to load VPS Customers.                      |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         13-JUN-2017  Thejaswini Rajula    Initial version                              |
  -- +============================================================================================+
  PROCEDURE INSERT_VPS_CUST_UPLOAD(
      P_VENDOR_SITE_CODE          IN VARCHAR2,
      P_VENDOR_NUM                IN VARCHAR2,
      P_GLOBAL_SUPPLIER_NUM       IN VARCHAR2,
      P_VPS_CUST_TYPE             IN VARCHAR2,
      P_VPS_AR_SUP_SITE_CAT       IN VARCHAR2,
      P_VPS_BILLING_FREQUENCY     IN VARCHAR2,
      P_VPS_BILLING_EXCEPTION     IN VARCHAR2,
      P_VPS_AP_NETTING_EXCEPTION  IN VARCHAR2,
      P_VPS_SENSITIVE_VENDOR_FLAG IN VARCHAR2,
      P_VPS_VENDOR_REPORT_FLAG    IN VARCHAR2,
      P_VPS_VENDOR_REPORT_FMT     IN VARCHAR2,
      P_VPS_INV_BACKUP            IN VARCHAR2,
      P_VPS_TIERED_PROGRAM        IN VARCHAR2,
      P_VPS_FOB_DEST_ORIGIN       IN VARCHAR2,
      P_VPS_POST_AUDIT_TF         IN VARCHAR2,
      P_VPS_SUPPLIER_SITE_PAY_GRP IN VARCHAR2,
      P_CONTACT_FNAME1            IN VARCHAR2,
      P_CONTACT_LNAME1            IN VARCHAR2,
      P_CONTACT_JOB_TITLE1        IN VARCHAR2,
      P_CONTACT_EMAIL1            IN VARCHAR2,
      P_CONTACT_PHONE1            IN VARCHAR2,
      P_CONTACT_FNAME2            IN VARCHAR2,
      P_CONTACT_LNAME2            IN VARCHAR2,
      P_CONTACT_JOB_TITLE2        IN VARCHAR2,
      P_CONTACT_EMAIL2            IN VARCHAR2,
      P_CONTACT_PHONE2            IN VARCHAR2,
      P_CONTACT_FNAME3            IN VARCHAR2,
      P_CONTACT_LNAME3            IN VARCHAR2,
      P_CONTACT_JOB_TITLE3        IN VARCHAR2,
      P_CONTACT_EMAIL3            IN VARCHAR2,
      P_CONTACT_PHONE3            IN VARCHAR2,
      P_CONTACT_FNAME4            IN VARCHAR2,
      P_CONTACT_LNAME4            IN VARCHAR2,
      P_CONTACT_JOB_TITLE4        IN VARCHAR2,
      P_CONTACT_EMAIL4            IN VARCHAR2,
      P_CONTACT_PHONE4            IN VARCHAR2,
      P_CONTACT_FNAME5            IN VARCHAR2,
      P_CONTACT_LNAME5            IN VARCHAR2,
      P_CONTACT_JOB_TITLE5        IN VARCHAR2,
      P_CONTACT_EMAIL5            IN VARCHAR2,
      P_CONTACT_PHONE5            IN VARCHAR2,
      P_GLOBAL_SUPPLIER_FLAG      IN VARCHAR2
      --P_OUT_STATUS                OUT VARCHAR2
      );
END XX_CDH_CUST_CONV_VPSUPLOAD_PKG ;
/
SHOW ERRORS;