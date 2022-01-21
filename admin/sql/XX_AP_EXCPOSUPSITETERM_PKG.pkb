SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE BODY XX_AP_EXCPOSUPSITETERM_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_AP_EXCPOSUPSITETERM_PKG                                                       |
  -- |  RICE ID   : R7037 AP Exceptions of PO vs Supplier Site Terms                              |
  -- |  Description:  Common Report package for XML bursting                                      |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         11/10/2017   PrabeethSoy       Initial version                                 |
  -- | 1.1         12/06/2017   Jitendra          NAIT-17180 restricted 0 size email output       |
  -- +============================================================================================+

FUNCTION beforeReport
  RETURN BOOLEAN
IS
  L_EMAIL_SUBJECT     VARCHAR2(250);
  L_EMAIL_CONTENT     VARCHAR2(500);
  L_DISTRIBUTION_LIST VARCHAR2(500);
 
BEGIN

 XX_AP_XML_BURSTING_PKG.Get_email_detail( 'XXAPEXCPOSUPSITTERM' ,G_SMTP_SERVER, G_EMAIL_SUBJECT, G_EMAIL_CONTENT, G_DISTRIBUTION_LIST);
  RETURN(TRUE);

EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Exception in before_report function '||SQLERRM );
END beforeReport;
--
FUNCTION afterReport
  RETURN BOOLEAN
IS
  l_request_id NUMBER;
  p_request_id NUMBER;
  L_COUNT      NUMBER :=0;
BEGIN
select sum(acnt)
into L_COUNT from (
SELECT count(1) acnt
FROM PO_HEADERS_INTERFACE PHI,
  AP_TERMS APT,
  AP_TERMS APT2,
  AP_SUPPLIER_SITES_ALL ASSA,
  AP_SUPPLIERS APS,
  PO_INTERFACE_ERRORS PIE
WHERE TRUNC(PHI.LAST_UPDATE_DATE) BETWEEN P_START_DATE AND P_END_DATE
AND PHI.INTERFACE_HEADER_ID = PIE.INTERFACE_HEADER_ID
AND PIE.TABLE_NAME          = 'PO_HEADERS_INTERFACE'
AND APS.VENDOR_ID           = ASSA.VENDOR_ID
AND ASSA.VENDOR_SITE_ID     = PHI.VENDOR_SITE_ID
AND PHI.TERMS_ID            = APT.TERM_ID
AND ASSA.TERMS_ID(+)        = APT2.TERM_ID
AND NVL(ASSA.TERMS_ID,0)   <> PHI.TERMS_ID
AND UPPER(ASSA.attribute8) IN
  (SELECT UPPER (XFTV.TARGET_VALUE1)
  FROM xx_fin_translatedefinition xftd,
    xx_fin_translatevalues xftv
  WHERE xftd.translation_name = 'XX_AP_TRADE_CATEGORIES'
  AND xftd.translate_id       = xftv.translate_id
  AND xftv.enabled_flag       = 'Y'
  AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate)
  )
UNION ALL
SELECT count(1) acnt 
FROM PO_HEADERS_ALL PHA,
  AP_SUPPLIER_SITES_ALL ASSA,
  AP_SUPPLIERS APS,
  AP_TERMS APT,
  AP_TERMS APT2
WHERE TRUNC(PHA.LAST_UPDATE_DATE) BETWEEN P_START_DATE AND P_END_DATE
AND PHA.VENDOR_ID           = ASSA.VENDOR_ID
AND PHA.VENDOR_SITE_ID      = ASSA.VENDOR_SITE_ID
AND ASSA.VENDOR_ID          = APS.VENDOR_ID
AND PHA.TERMS_ID            = APT.TERM_ID
AND ASSA.TERMS_ID           = APT2.TERM_ID
AND PHA.TERMS_ID           <> ASSA.TERMS_ID
AND UPPER(ASSA.attribute8) IN
  (SELECT UPPER (XFTV.TARGET_VALUE1)
  FROM xx_fin_translatedefinition xftd,
    xx_fin_translatevalues xftv
  WHERE xftd.translation_name = 'XX_AP_TRADE_CATEGORIES'
  AND xftd.translate_id       = xftv.translate_id
  AND xftv.enabled_flag       = 'Y'
  AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate)));

IF L_COUNT > 0 THEN

  FND_FILE.PUT_LINE(FND_FILE.LOG,'afterReport get email info function');
  p_request_id := FND_GLOBAL.CONC_REQUEST_ID;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_request_id  >>>>>'||P_REQUEST_ID);
  IF G_DISTRIBUTION_LIST IS NOT NULL THEN
    fnd_file.put_line(fnd_file.log, 'Submitting : XML Publisher Report Bursting Program');
    l_request_id := FND_REQUEST.SUBMIT_REQUEST('XDO', 'XDOBURSTREP', NULL, NULL, FALSE, 'Y', p_request_id, 'Y');
    Fnd_File.PUT_LINE(Fnd_File.LOG, 'After submitting bursting ');
    COMMIT;
  END IF;

END IF;
  RETURN(TRUE);
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Exception in after_report function '||SQLERRM );
END afterReport;
END XX_AP_EXCPOSUPSITETERM_PKG;
/

SHOW ERROR