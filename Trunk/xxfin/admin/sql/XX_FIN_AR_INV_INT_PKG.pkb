SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace PACKAGE BODY XX_FIN_AR_INV_INT_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_FIN_AR_INV_INT_PKG                                                              |
  -- |                                                                                            |
  -- |  Description:  This package is used by WEB services to load AR Invoice H/L data from VPS.  |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         26-MAY-2017  Thejaswini Rajula    Initial version                              |
  -- +============================================================================================+
PROCEDURE INSERT_ROW(
    P_INVOICE_DATE      IN VARCHAR2,
    P_INVOICE_NUM       IN VARCHAR2,
    P_CUSTOMER_NUM      IN VARCHAR2,
    P_TRAN_SOURCE       IN VARCHAR2,
    P_TRAN_TYPE         IN VARCHAR2,
    P_PGM_TYPE          IN VARCHAR2,
    P_PGM_NAME          IN VARCHAR2,
    P_PGM_STATUS        IN VARCHAR2,
    P_PGM_ID            IN NUMBER,
    P_METH_OF_PMT_CD    IN VARCHAR2,
    P_FREQ_CD           IN VARCHAR2,
    P_INVOICE_AMT       IN NUMBER,
    P_PGM_BASIS_AMT     IN NUMBER,
    P_PGM_VALUE         IN VARCHAR2,
    P_PGM_DATE          IN VARCHAR2,
    P_PGM_BASIS         IN VARCHAR2,
    P_DUE_DATE          IN VARCHAR2,
    P_UPLOADED_BY       IN VARCHAR2,
    P_BATCH_ID          IN VARCHAR2,
    P_COMMENTS          IN VARCHAR2,
    P_VPS_CREATION_DATE IN VARCHAR2,
    P_VPS_SENT_DATE     IN VARCHAR2,
    P_OUT_STATUS        OUT VARCHAR2
   )
IS
V1        NUMBER;
BEGIN
INSERT
  INTO RA_INTERFACE_LINES_ALL
    (INTERFACE_LINE_ID,
      TRX_DATE,
      TRX_NUMBER ,
      BATCH_SOURCE_NAME,
      CUST_TRX_TYPE_NAME,
      HEADER_ATTRIBUTE1,
      HEADER_ATTRIBUTE2,
      HEADER_ATTRIBUTE4,
      HEADER_ATTRIBUTE5,
      HEADER_ATTRIBUTE6,
      HEADER_ATTRIBUTE8,
      HEADER_ATTRIBUTE9,
      HEADER_ATTRIBUTE10,
      HEADER_ATTRIBUTE11,
      --HEADER_ATTRIBUTE1,
      HEADER_ATTRIBUTE14,
      AMOUNT,
      DESCRIPTION,
      LINE_TYPE,															
      CURRENCY_CODE,							
      CONVERSION_TYPE,	
      CONVERSION_RATE,
      HEADER_ATTRIBUTE_CATEGORY,
      LAST_UPDATE_DATE,
      LAST_UPDATED_BY,
      CREATION_DATE,
      CREATED_BY,
      LAST_UPDATE_LOGIN,
      HEADER_ATTRIBUTE12,
      HEADER_ATTRIBUTE13,
      INTERFACE_LINE_CONTEXT,
      INTERFACE_LINE_ATTRIBUTE1,
      INTERFACE_LINE_ATTRIBUTE15,
      HEADER_ATTRIBUTE15,
      --HEADER_ATTRIBUTE3,
      COMMENTS
    )
    VALUES
    ( RA_CUSTOMER_TRX_LINES_S.NEXTVAL,
      TO_DATE (P_INVOICE_DATE,'DD-MON-YYYY HH:MI:SS'),
      P_INVOICE_NUM,
      P_TRAN_SOURCE,
      P_TRAN_TYPE,
      P_CUSTOMER_NUM, 
      P_PGM_VALUE, 
      P_PGM_NAME, 
      P_PGM_TYPE, 
      P_PGM_DATE, 
      P_PGM_STATUS, 
      P_METH_OF_PMT_CD, 
      P_PGM_BASIS_AMT, 
      P_PGM_BASIS, 
    --  P_PGM_ID,
      P_PGM_ID,
      ROUND(P_INVOICE_AMT,2),
      'VPS Invoice Line',
      'LINE',																
      'USD',							
      'User',
      1,
      'US_VPS',
      SYSDATE,
      fnd_global.user_id,
      SYSDATE,
      fnd_global.user_id,
      fnd_global.user_id,
      P_DUE_DATE,
      P_FREQ_CD,
      'VPS INVOICES',
      P_INVOICE_NUM,
      P_PGM_ID,
      P_UPLOADED_BY,
      --P_BATCH_ID,
      P_COMMENTS
    );
  V1:=sql%rowcount;
  DBMS_OUTPUT.PUT_LINE('V1'||V1);
  IF V1>0 THEN
    P_OUT_STATUS:='P';
    DBMS_OUTPUT.PUT_LINE('P_OUT_STATUS'||P_OUT_STATUS);
  COMMIT;
  ELSE
    P_OUT_STATUS:='E';
    DBMS_OUTPUT.PUT_LINE('P_OUT_STATUS'||P_OUT_STATUS);
 END IF;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error inserting into staging table'||SUBSTR(sqlerrm,1,200));
  FND_FILE.PUT_LINE(FND_FILE.LOG,'');
  P_OUT_STATUS:='E'||'|'||SUBSTR(sqlerrm,1,200);
END INSERT_ROW;

 PROCEDURE CREATE_INVOICE(
      INVOICE_DATE      IN VARCHAR2,
      INVOICE_NUM       IN VARCHAR2,
      CUSTOMER_NUM      IN VARCHAR2,
      TRAN_SOURCE       IN VARCHAR2,
      TRAN_TYPE         IN VARCHAR2,
      PGM_TYPE          IN VARCHAR2,
      PGM_NAME          IN VARCHAR2,
      PGM_STATUS        IN VARCHAR2,
      PGM_ID            IN NUMBER,
      METH_OF_PMT_CD    IN VARCHAR2,
      FREQ_CD           IN VARCHAR2,
      INVOICE_AMT       IN NUMBER,
      PGM_BASIS_AMT     IN NUMBER,
      PGM_VALUE         IN VARCHAR2,
      PGM_DATE          IN VARCHAR2,
      PGM_BASIS         IN VARCHAR2,
      DUE_DATE          IN VARCHAR2,
      UPLOADED_BY       IN VARCHAR2,
      BATCH_ID          IN VARCHAR2,
      COMMENTS          IN VARCHAR2,
      VPS_CREATION_DATE IN VARCHAR2,
      VPS_SENT_DATE     IN VARCHAR2,
      OUT_STATUS        OUT VARCHAR2)
  IS
  BEGIN 
    XX_FIN_AR_INV_INT_PKG.INSERT_ROW(
    P_INVOICE_DATE      =>  INVOICE_DATE,
    P_INVOICE_NUM       =>  INVOICE_NUM,
    P_CUSTOMER_NUM      =>  CUSTOMER_NUM,
    P_TRAN_SOURCE       =>  TRAN_SOURCE,
    P_TRAN_TYPE         =>  TRAN_TYPE,
    P_PGM_TYPE          =>  PGM_TYPE,
    P_PGM_NAME          =>  PGM_NAME,
    P_PGM_STATUS        =>  PGM_STATUS,
    P_PGM_ID            =>  PGM_ID,
    P_METH_OF_PMT_CD    =>  METH_OF_PMT_CD,
    P_FREQ_CD           =>  FREQ_CD,
    P_INVOICE_AMT       =>  INVOICE_AMT,
    P_PGM_BASIS_AMT     =>  PGM_BASIS_AMT,
    P_PGM_VALUE         =>  PGM_VALUE,
    P_PGM_DATE          =>  PGM_DATE,
    P_PGM_BASIS         =>  PGM_BASIS,
    P_DUE_DATE          =>  DUE_DATE,
    P_UPLOADED_BY       =>  UPLOADED_BY,
    P_BATCH_ID          =>  BATCH_ID,
    P_COMMENTS          =>  COMMENTS,
    P_VPS_CREATION_DATE =>  VPS_CREATION_DATE,
    P_VPS_SENT_DATE     =>  VPS_SENT_DATE,
    P_OUT_STATUS        =>  OUT_STATUS
    );
  DBMS_OUTPUT.PUT_LINE('TEST');
  EXCEPTION
 WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error in calling INSERT ROW pkg'||SUBSTR(sqlerrm,1,200));
  FND_FILE.PUT_LINE(FND_FILE.LOG,'');
  END CREATE_INVOICE;
END XX_FIN_AR_INV_INT_PKG;
/
SHOW ERRORS;