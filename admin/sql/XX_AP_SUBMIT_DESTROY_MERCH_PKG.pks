SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace 
PACKAGE      XX_AP_SUBMIT_DESTROY_MERCH_PKG
AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                            Providge                                      |
-- +==========================================================================+
-- | Name             :    XX_AP_SUBMIT_DESTROY_MERCH_PKG                     |
-- | Description      :    Package for Submit request for Destroyed Merch Rep |
-- | RICE ID          :    R7034                                              |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author              Remarks                        |
-- |=======   ===========  ================    ========================       |
-- | 1.0      20-Feb-2018  Jitendra Atale      Initial                        |
-- | 1.1      03-May-2018  Ragni Gupta         Added run date parameter
-- | 1.2      28-May-2018  Ragni Gupta         Added "NOTIFY_VENDOR_SITE_EMAIL_NULL" to send email to business
--                                             for vendor site email is NULL
-- +==========================================================================+
G_RET_CODE number;

PROCEDURE SUBMIT_DESTROY_MERCH_REPORT  (   x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER,
    P_START_DATE IN VARCHAR2,
    P_END_DATE IN VARCHAR2,
    P_FREQUENCY IN VARCHAR2,
    P_VENDOR_SITE_CODE IN VARCHAR2,
    P_RUN_DATE IN VARCHAR2       );

TYPE email_null_rec IS RECORD
(
SUPPLIER_NUM ap_suppliers.segment1%TYPE,
SUPPLIER_NAME ap_suppliers.vendor_name%TYPE,
SUPPLIER_SITE ap_supplier_sites_all.vendor_site_code%TYPE
);

TYPE email_null_rec_tb IS TABLE OF email_null_rec;

PROCEDURE NOTIFY_VENDOR_SITE_EMAIL_NULL(p_start_date DATE, p_end_Date DATE, p_frequency VARCHAR2, p_vendor_site NUMBER);
END XX_AP_SUBMIT_DESTROY_MERCH_PKG;
/

SHOW ERROR;