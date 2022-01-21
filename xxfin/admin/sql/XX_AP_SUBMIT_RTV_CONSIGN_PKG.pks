SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE      XX_AP_SUBMIT_RTV_CONSIGN_PKG
AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                                                                          |
-- +==========================================================================+
-- | Name             :    XX_AP_SUBMIT_RTV_CONSIGN_PKG                       |
-- | Description      :    Package for Submit request for RTV Consignment Rep |
-- | RICE ID          :    R70                                              |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author              Remarks                        |
-- |=======   ===========  ================    ========================       |
-- | 1.0      23-Feb-2018  Priyam Parmar       Initial                        |
-- +==========================================================================+


PROCEDURE SUBMIT_RTV_CONSIGN_REPORT  (   x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER,
    P_START_DATE IN VARCHAR2,
    P_END_DATE IN VARCHAR2,
    --P_FREQUENCY IN VARCHAR2,
    P_VENDOR_SITE_CODE IN VARCHAR2,P_SEND_EMAIL VARCHAR2
                               );

END XX_AP_SUBMIT_RTV_CONSIGN_PKG;

/

SHOW ERRORS;