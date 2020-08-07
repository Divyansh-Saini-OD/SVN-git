SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE      XX_AP_SUBMIT_DESTROY_RTV73_PKG
AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                            Providge                                      |
-- +==========================================================================+
-- | Name             :    XX_AP_SUBMIT_DESTROY_RTV73_PKG                     |
-- | Description      :    OD: Destroy RTV73 Consignment Report               |
-- | RICE ID          :                                                       |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author              Remarks                        |
-- |=======   ===========  ================    ========================       |
-- | 1.0      21-Feb-2018  Priyam Parmar      Initial   
---| 1.1      02-MAY-2018   Priyam Parmar    Code change for Run date as parameter.
-- | 1.2      30-APR-2018 Priyam P             g_ret_code added to make the parent program complete in warning rather than error.
-- | 1.3      31-MAY-2018 Jitendra A           Added procedure xx_AP_RTV73_EMAIL
-- +==========================================================================+

G_RET_CODE number;

PROCEDURE xx_ap_rtv73_email(
    p_start_date  IN DATE,
    p_end_Date    IN DATE,
    p_frequency   IN VARCHAR2,
    p_vendor_site IN VARCHAR2);

PROCEDURE SUBMIT_DESTROY_RTV73_REPORT  ( x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER,
    P_START_DATE IN VARCHAR2,
    P_END_DATE IN VARCHAR2,
    P_FREQUENCY IN VARCHAR2,p_vendor_site_code varchar2, P_RUN_DATE IN VARCHAR2
                               );
                               
TYPE email_null_rec IS RECORD
(
SUPPLIER_NUM ap_suppliers.segment1%TYPE,
SUPPLIER_NAME ap_suppliers.vendor_name%TYPE,
SUPPLIER_SITE ap_supplier_sites_all.vendor_site_code%TYPE
);

type email_null_rec_tb is table of email_null_rec;


END XX_AP_SUBMIT_DESTROY_RTV73_PKG;
/

SHOW ERRORS;