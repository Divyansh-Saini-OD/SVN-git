-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                                                                   |
-- +===================================================================+
-- | Name             :    XX_AR_POD_PKG                               |
-- | Description      :    Package for POD                             |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author              Remarks                 |
-- |=======   ===========  ================    ========================|
-- |1.0                    Bushrod Thomas      Initial version         |
-- |                                                                   |
-- |1.1       17-AUG-2007  Aravind A.          Fixed defect 1426       |
-- |                                                                   |
-- |1.2       08-FEB-2007  Bushrod Thomas      Optimized GET_ORDER_INFO|
-- |                                             like defect 3723      |
-- |2.0       1-Mar-2014   Sridevi K           For Defect 28643        |
-- |2.1       09-11-2015   Shubashree R     R12.2  Compliance changes Defect# 36369 |
-- |2.2       23-May-2018  Suresh Ponnambalam Replaced oe tables with view |
-- +===================================================================+
CREATE OR REPLACE
PACKAGE BODY "XX_AR_POD_PKG"
AS
PROCEDURE LOG_ERROR(
    p_message_name IN VARCHAR2 ,
    p_user_id      IN VARCHAR2 ,
    p_location     IN VARCHAR2 ,
    p_invoice      IN VARCHAR2 ,
    p_severity     IN VARCHAR2 ,
    p_message OUT VARCHAR2 )
IS
BEGIN
  FND_MESSAGE.CLEAR;
  FND_MESSAGE.SET_NAME('XXFIN',p_message_name);
  p_message := FND_MESSAGE.GET();
  XX_COM_ERROR_LOG_PUB.LOG_ERROR( p_program_type => 'UI' ,p_program_name => 'POD' ,p_module_name => 'AR' ,p_attribute1 => p_user_id ,p_error_location => p_location ,p_error_message => p_message ,p_error_message_severity => p_severity ,p_notify_flag => 'N' ,p_object_type => 'Invoice' ,p_object_id => p_invoice );
  --    COMMIT; -- commit is done in asynchronous transaction within API, so don't do it here!
END LOG_ERROR;
PROCEDURE VALIDATE_POD_AUTH(
    p_user_id IN VARCHAR2,
    p_auth OUT VARCHAR2 )
IS
BEGIN
  SELECT USER_HAS_RESP(p_user_id,'OD_%_COLLECTION_AGENT')
  INTO p_auth
  FROM SYS.DUAL;
END VALIDATE_POD_AUTH;
PROCEDURE GET_ORDER_INFO(
    p_invoice IN VARCHAR2,
    p_spcnum OUT VARCHAR2,
    p_docref OUT VARCHAR2 )
IS
BEGIN
  --Modified query to fix defect 1426
  /*SELECT NVL(XX.spc_card_number,' '), NVL(OE.orig_sys_document_ref,' ')
  INTO   p_spcnum, p_docref
  FROM   OE_ORDER_HEADERS_ALL OE, XX_OM_HEADER_ATTRIBUTES_ALL XX, RA_CUSTOMER_TRX_LINES_ALL RA
  WHERE  RA.customer_trx_id = TO_NUMBER(p_invoice)
  AND    RA.sales_order     = OE.order_number
  AND    OE.header_id       = XX.header_id;*/
  /*
  SELECT NVL(XX.spc_card_number,' ')
  ,NVL(OE.orig_sys_document_ref,' ')
  INTO   p_spcnum
  ,p_docref
  FROM   oe_order_headers_all OE
  ,xx_om_header_attributes_all XX
  ,ra_customer_trx_all RATA
  WHERE  RATA.customer_trx_id = TO_CHAR(p_invoice)
  AND    RATA.Interface_header_attribute1 = OE.order_number
  AND    RATA.org_id = FND_PROFILE.VALUE('ORG_ID')
  AND    OE.header_id       = XX.header_id;
  */
  -- query optimized to use attribute14 to avoid table scan
  SELECT NVL(XX.spc_card_number,' ') ,
    NVL(OE.orig_sys_document_ref,' ')
  INTO p_spcnum ,
    p_docref
  FROM xx_oe_order_headers_v OE ,
    xx_om_header_attributes_V XX ,
    ra_customer_trx_all TRX
  WHERE TRX.customer_trx_id = p_invoice
  AND TRX.org_id            = FND_PROFILE.VALUE('ORG_ID')
  AND TRX.attribute14       = OE.header_id
  AND OE.header_id          = XX.header_id;
END GET_ORDER_INFO;
FUNCTION USER_HAS_RESP(
    p_user_id            IN NUMBER,
    p_responsibility_key IN VARCHAR2 )
  RETURN VARCHAR2
AS
  l_rec_count NUMBER := 0;
BEGIN
  SELECT COUNT(*)
  INTO l_rec_count
  FROM FND_USER_RESP_GROUPS
  WHERE user_id          =p_user_id
  AND (end_date         IS NULL
  OR SYSDATE             < end_date)
  AND SYSDATE            > start_date
  AND responsibility_id IN
    (SELECT responsibility_id
    FROM FND_RESPONSIBILITY
    WHERE responsibility_key LIKE p_responsibility_key
    );
  IF l_rec_count > 0 THEN
    RETURN 'Y';
  ELSE
    RETURN 'N';
  END IF;
END USER_HAS_RESP;

/* Added for Defect 28643 */
PROCEDURE GET_PODURL(
    p_devurl OUT VARCHAR2,
    p_url OUT VARCHAR2,
    p_errormsg OUT VARCHAR2 )
IS
BEGIN
  -- query to get URL
  SELECT xftv.SOURCE_VALUE1 POD_DEV_URL,
    xftv.SOURCE_VALUE2 POD_PROD_URL
  INTO p_devurl ,
    p_url
  FROM xx_fin_translatedefinition xftd,
    xx_fin_translatevalues xftv
  WHERE xftd.translate_id   = xftv.translate_id
  AND xftd.translation_name ='XXOD_AR_POD_URL'
  AND xftv.ENABLED_FLAG     ='Y'
  AND SYSDATE BETWEEN xftv.start_date_active AND NVL (xftv.end_date_active, SYSDATE);
EXCEPTION
WHEN OTHERS THEN
  p_errormsg := 'Error fetching POD URL'||SQLERRM;
END GET_PODURL;
END XX_AR_POD_PKG;
/
