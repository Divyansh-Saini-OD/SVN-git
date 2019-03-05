SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace PACKAGE BODY XX_CDH_CUST_CONV_VPSUPLOAD_PKG
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
  -- | 1.1         05-MAR-2019  Dinesh Nagapuri      GSCC Violation Removing xxcrm                |
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
    )
IS
v1    NUMBER;
BEGIN
  INSERT
  INTO XX_CDH_VPS_CUSTOMER_STG						-- V1.1 Removed xxcrm
    (
      VENDOR_SITE_CODE ,
      VENDOR_NUM ,
      GLOBAL_SUPPLIER_NUM ,
      VPS_CUST_TYPE ,
      VPS_AR_SUP_SITE_CAT ,
      VPS_BILLING_FREQUENCY ,
      VPS_BILLING_EXCEPTION ,
      VPS_AP_NETTING_EXCEPTION ,
      VPS_SENSITIVE_VENDOR_FLAG ,
      VPS_VENDOR_REPORT_FLAG ,
      VPS_VENDOR_REPORT_FMT ,
      VPS_INV_BACKUP ,
      VPS_TIERED_PROGRAM ,
      VPS_FOB_DEST_ORIGIN ,
      VPS_POST_AUDIT_TF ,
      VPS_SUPPLIER_SITE_PAY_GRP ,
      CONTACT_FNAME1 ,
      CONTACT_LNAME1 ,
      CONTACT_JOB_TITLE1 ,
      CONTACT_EMAIL1 ,
      CONTACT_PHONE1 ,
      CONTACT_FNAME2 ,
      CONTACT_LNAME2 ,
      CONTACT_JOB_TITLE2 ,
      CONTACT_EMAIL2 ,
      CONTACT_PHONE2 ,
      CONTACT_FNAME3 ,
      CONTACT_LNAME3 ,
      CONTACT_JOB_TITLE3 ,
      CONTACT_EMAIL3 ,
      CONTACT_PHONE3 ,
      CONTACT_FNAME4 ,
      CONTACT_LNAME4 ,
      CONTACT_JOB_TITLE4 ,
      CONTACT_EMAIL4 ,
      CONTACT_PHONE4 ,
      CONTACT_FNAME5 ,
      CONTACT_LNAME5 ,
      CONTACT_JOB_TITLE5 ,
      CONTACT_EMAIL5 ,
      CONTACT_PHONE5 ,
      INTERFACE_ID ,
      REQUEST_ID ,
      RECORD_STATUS ,
      ERROR_MESSAGE ,
      GLOBAL_SUPPLIER_FLAG ,
      VALIDATE_PROCESS_DATA ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CREATION_DATE ,
      CREATED_BY
    )
    VALUES
    (
      P_VENDOR_SITE_CODE ,
      P_VENDOR_NUM ,
      P_GLOBAL_SUPPLIER_NUM ,
      P_VPS_CUST_TYPE ,
      P_VPS_AR_SUP_SITE_CAT ,
      P_VPS_BILLING_FREQUENCY ,
      P_VPS_BILLING_EXCEPTION ,
      P_VPS_AP_NETTING_EXCEPTION ,
      P_VPS_SENSITIVE_VENDOR_FLAG ,
      P_VPS_VENDOR_REPORT_FLAG ,
      P_VPS_VENDOR_REPORT_FMT ,
      P_VPS_INV_BACKUP ,
      P_VPS_TIERED_PROGRAM ,
      P_VPS_FOB_DEST_ORIGIN ,
      P_VPS_POST_AUDIT_TF ,
      P_VPS_SUPPLIER_SITE_PAY_GRP ,
      P_CONTACT_FNAME1 ,
      P_CONTACT_LNAME1 ,
      P_CONTACT_JOB_TITLE1 ,
      P_CONTACT_EMAIL1 ,
      P_CONTACT_PHONE1 ,
      P_CONTACT_FNAME2 ,
      P_CONTACT_LNAME2 ,
      P_CONTACT_JOB_TITLE2 ,
      P_CONTACT_EMAIL2 ,
      P_CONTACT_PHONE2 ,
      P_CONTACT_FNAME3 ,
      P_CONTACT_LNAME3 ,
      P_CONTACT_JOB_TITLE3 ,
      P_CONTACT_EMAIL3 ,
      P_CONTACT_PHONE3 ,
      P_CONTACT_FNAME4 ,
      P_CONTACT_LNAME4 ,
      P_CONTACT_JOB_TITLE4 ,
      P_CONTACT_EMAIL4 ,
      P_CONTACT_PHONE4 ,
      P_CONTACT_FNAME5 ,
      P_CONTACT_LNAME5 ,
      P_CONTACT_JOB_TITLE5 ,
      P_CONTACT_EMAIL5 ,
      P_CONTACT_PHONE5 ,
      XX_CDH_VPS_CUSTOMER_STG_S.nextval,
      NULL ,
      'N' ,
      NULL ,
      NULL,
      NULL,
      SYSDATE ,
      fnd_global.user_id ,
      SYSDATE ,
      fnd_global.user_id
    );
 /* v1 := sql%rowcount;
  IF v1>0 THEN
    P_OUT_STATUS:='I';
  END IF; */
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error inserting into staging table'||SUBSTR(sqlerrm,1,200));
  FND_FILE.PUT_LINE(FND_FILE.LOG,'');
  --P_OUT_STATUS:='E'||SUBSTR(sqlerrm,1,200);
END INSERT_VPS_CUST_UPLOAD;
END XX_CDH_CUST_CONV_VPSUPLOAD_PKG;
/
SHOW ERRORS;