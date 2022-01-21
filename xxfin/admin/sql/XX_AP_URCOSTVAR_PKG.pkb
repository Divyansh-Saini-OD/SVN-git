SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_URCOSTVAR_PKG

WHENEVER SQLERROR CONTINUE
CREATE or REPLACE PACKAGE BODY XX_AP_URCOSTVAR_PKG
  -- +=========================================================================+
  -- |                  Office Depot - Project Simplify                        |
  -- +=========================================================================+
  -- | Name        :  XX_AP_URCOSTVAR_PKG.pkb                                  |
  -- | Description :  Plsql package for OD AP Unresolved Cost Variances Report |
  -- | RICE ID     :  R7036 OD AP Unresolved Cost Variances Report             |
  -- |Change Record:                                                           |
  -- |===============                                                          |
  -- |Version   Date        Author             Remarks                         |
  -- |========  =========== ================== ================================|
  -- |1.0       10-Oct-2017 Jitendra Atale     Initial version                 |
  -- +=======================================================================+
AS
FUNCTION beforeReport
  RETURN BOOLEAN
IS
BEGIN
  XX_AP_XML_BURSTING_PKG.Get_email_detail( 'XXAPPVARXML' ,G_SMTP_SERVER, G_EMAIL_SUBJECT, G_EMAIL_CONTENT, G_DISTRIBUTION_LIST);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'p_request_id  >>>>>'||G_SMTP_SERVER);
  RETURN(TRUE);
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Exception in before_report function '||SQLERRM );
END beforeReport;
FUNCTION afterReport
  RETURN BOOLEAN
IS
  p_request_id NUMBER;
  l_request_id NUMBER;
  L_COUNT      NUMBER :=0;
BEGIN
  SELECT COUNT(1)
  INTO l_COUNT
  FROM
    (SELECT XX_AP_MERCH_CONT_PKG.MERCH_NAME(DEPT) MERCHANT,
      VENDOR_NO VENDOR,
      VENDOR_SITE_CODE VENDOR_SITE_NAME,
      VENDOR_NAME ,
      DEPT,
      SKU,
      SKU_DESCRIPTION ,
      COUNT(LINE_NUM) LINE_COUNT,
      SUM(PO_COST) PO_COST,
      SUM(INVOICE_PRICE) INV_COST,
      SUM(VARIANCE_AMT) VARIANCE
    FROM xx_ap_cost_variance
    WHERE NVL(ANSWER_CODE,'X') = 'X'
    GROUP BY 1,
      Vendor_No,
      Vendor_site_code,
      Vendor_name,
      Dept,
      Sku,
      Sku_Description
    );
  p_request_id := FND_GLOBAL.CONC_REQUEST_ID;
  IF (l_COUNT   >0) THEN
    fnd_file.put_line(fnd_file.log, 'Submitting : XML Publisher Report Bursting Program');
    l_request_id := FND_REQUEST.SUBMIT_REQUEST('XDO', 'XDOBURSTREP', NULL, NULL, FALSE, 'Y', p_request_id, 'Y');
    Fnd_File.PUT_LINE(Fnd_File.LOG, 'After submitting bursting ');
    COMMIT;
  END IF;
  RETURN(TRUE);
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception in after_report function '||SQLERRM );
END afterReport;

END XX_AP_URCOSTVAR_PKG;
/
SHOW ERRORS;