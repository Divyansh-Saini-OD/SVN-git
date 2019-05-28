create or replace 
PACKAGE BODY XX_AP_XXAUNMATCHRECEIPT_PKG
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- +===================================================================+
  -- | Name        :  XX_AP_XXAUNMATCHRECEIPT_PKG.pkb                    |
  -- | Description :  Plsql package for XXAPUNMATCHRECEIPTS Report       |
  -- |                Created this package to calculate receipts amount  |
  -- | RICE ID     :                                                     |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author             Remarks                   |
  -- |========  =========== ================== ==========================|
  -- |1.0       14-Nov-2017 Ragni Gupta     Initial version              |
  -- |1.1       14-FEB-2018  Priyam         Code change for Reciept Correction  |
  -- |1.2       23-Apr-2019  Shanti Sethuraj  Adding new procedure XX_AP_UNMATCH_WRAP_PROC for NAIT-27081 |
  -- +===================================================================+
AS
FUNCTION BEFOREREPORT
  RETURN BOOLEAN
IS
  L_VAR           VARCHAR2(1)  := '';
  L_TRANS_NAME    VARCHAR2(30) := 'XX_AP_TRADE_CATEGORIES';
  L_ENABLED_FLAG  VARCHAR2(1)  := 'Y';
  L_EXP_TYPE      VARCHAR2(10) := 'EX%';
  L_EXCLUDE_TYPE  VARCHAR2(10) := 'TR-TDS';
  L_DIRECT_IMPORT VARCHAR2(10) := 'TR-IMP';
BEGIN
  IF P_PO_TYPE         IS NOT NULL THEN
    IF P_PO_TYPE        = 'TRADE' THEN
      G_PO_TYPE_CLAUSE := ' WHERE UPPER(a.SUPPLIER_SITE_CATEGORY) IN (SELECT UPPER (XFTV.TARGET_VALUE1)                                
FROM xx_fin_translatedefinition xftd,                                
xx_fin_translatevalues xftv                                
WHERE  xftd.translation_name =  ''' || L_TRANS_NAME || '''                              
AND xftd.translate_id     = xftv.translate_id                              
AND xftv.enabled_flag     =  ''' ||L_ENABLED_FLAG || '''                              
AND xftv.target_value1 <> '''|| L_DIRECT_IMPORT|| '''                              
AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate))' ;
    ELSIF P_PO_TYPE     = 'EXPENSE' THEN
      G_PO_TYPE_CLAUSE := ' WHERE UPPER(a.SUPPLIER_SITE_CATEGORY) like '''||L_EXP_TYPE||'''';
    ELSIF P_PO_TYPE     = 'DIRECT IMPORT' THEN
      G_PO_TYPE_CLAUSE := ' WHERE UPPER(a.SUPPLIER_SITE_CATEGORY) like '''||L_DIRECT_IMPORT||'''';
    END IF ;
  ELSE
    G_PO_TYPE_CLAUSE := ' WHERE UPPER(a.SUPPLIER_SITE_CATEGORY) <> '''|| L_EXCLUDE_TYPE||'''';
  END IF;
  RETURN TRUE;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR at XX_AP_XXAPUNMATCHRECEIPT.beforeReport:- ' || SQLERRM);
END BEFOREREPORT;
FUNCTION XX_AP_UNMATCH_DETAIL(
    P_DATE             VARCHAR2,
    P_SEGMENT_FROM     VARCHAR2,
    P_SEGMENT_TO       VARCHAR2,
    P_SUP_SITE_CD_FROM VARCHAR2,
    P_SUP_SITE_CD_TO   VARCHAR2,
    P_CURRENCY_CODE    VARCHAR2 )
  RETURN XX_AP_XXAUNMATCHRECEIPT_PKG.UNMATCH_DETAIL_REC_CTT PIPELINED
IS
  CURSOR C_UNMATCH_REC( P_DATE DATE, P_SEGMENT_FROM VARCHAR2 , P_SEGMENT_TO VARCHAR2, P_SUP_SITE_CD_FROM VARCHAR2, P_SUP_SITE_CD_TO VARCHAR2, P_CURRENCY_CODE VARCHAR2)
  IS
    SELECT POH.SEGMENT1 PO_NUMBER,
      POH.CURRENCY_CODE PO_CURRENCY,
      HR.NAME C_LOCATION ,
      RSH.RECEIPT_NUM ,
      NVL2(RSH.ATTRIBUTE1, TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'),RT.TRANSACTION_DATE) RECEIPT_DATE ,
      ASU.VENDOR_NAME,
      APS.VENDOR_SITE_CODE,
      APS.ATTRIBUTE8 SUPPLIER_SITE_CATEGORY,
      DECODE(NVL(APS.ATTRIBUTE6,'XX'),'XX','Open',
      (SELECT XFTV.TARGET_VALUE2
      FROM XX_FIN_TRANSLATEDEFINITION XFTD,
        XX_FIN_TRANSLATEVALUES XFTV
      WHERE XFTD.TRANSLATION_NAME = 'XX_AP_VENDOR_ASSISTANTS'
      AND XFTD.TRANSLATE_ID       = XFTV.TRANSLATE_ID
      AND XFTV.ENABLED_FLAG       = 'Y'
      AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)
      AND XFTV.TARGET_VALUE1 =APS.ATTRIBUTE6
      )) VENDOR_ASSISTANT,
      CASE
        WHEN (TO_DATE (P_DATE)                                                                                                                - NVL2(RSH.ATTRIBUTE1, TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'), TO_DATE (RT.TRANSACTION_DATE))) BETWEEN 0 AND 30
        THEN SUM((XX_AP_XXAUNMATCHRECEIPT_PKG.CALCULATE_CST_REC_AMT(CAPR.PO_DISTRIBUTION_ID, CAPR.ACCRUAL_ACCOUNT_ID, CAPR.RCV_TRANSACTION_ID)*-1))
        ELSE 0
      END BUC_D_0,
      CASE
        WHEN (TO_DATE (P_DATE)                                                                                                                - NVL2(RSH.ATTRIBUTE1 ,TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'),TO_DATE (RT.TRANSACTION_DATE) )) BETWEEN 31 AND 60
        THEN SUM((XX_AP_XXAUNMATCHRECEIPT_PKG.CALCULATE_CST_REC_AMT(CAPR.PO_DISTRIBUTION_ID, CAPR.ACCRUAL_ACCOUNT_ID, CAPR.RCV_TRANSACTION_ID)*-1))
        ELSE 0
      END BUC_D_1,
      CASE
        WHEN (TO_DATE (P_DATE)                                                                                                                - NVL2(RSH.ATTRIBUTE1, TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'),TO_DATE (RT.TRANSACTION_DATE) )) BETWEEN 61 AND 90
        THEN SUM((XX_AP_XXAUNMATCHRECEIPT_PKG.CALCULATE_CST_REC_AMT(CAPR.PO_DISTRIBUTION_ID, CAPR.ACCRUAL_ACCOUNT_ID, CAPR.RCV_TRANSACTION_ID)*-1))
        ELSE 0
      END BUC_D_2,
      CASE
        WHEN (TO_DATE (P_DATE)                                                                                                                - NVL2(RSH.ATTRIBUTE1, TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'),TO_DATE (RT.TRANSACTION_DATE) )) BETWEEN 91 AND 120
        THEN SUM((XX_AP_XXAUNMATCHRECEIPT_PKG.CALCULATE_CST_REC_AMT(CAPR.PO_DISTRIBUTION_ID, CAPR.ACCRUAL_ACCOUNT_ID, CAPR.RCV_TRANSACTION_ID)*-1))
        ELSE 0
      END BUC_D_3,
      CASE
        WHEN (TO_DATE (P_DATE)                                                                                                                - NVL2(RSH.ATTRIBUTE1, TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'),TO_DATE (RT.TRANSACTION_DATE)) ) BETWEEN 121 AND 180
        THEN SUM((XX_AP_XXAUNMATCHRECEIPT_PKG.CALCULATE_CST_REC_AMT(CAPR.PO_DISTRIBUTION_ID, CAPR.ACCRUAL_ACCOUNT_ID, CAPR.RCV_TRANSACTION_ID)*-1))
        ELSE 0
      END BUC_D_4,
      CASE
        WHEN (TO_DATE (P_DATE)                                                                                                                - NVL2(RSH.ATTRIBUTE1, TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'),TO_DATE (RT.TRANSACTION_DATE) )) BETWEEN 181 AND 240
        THEN SUM((XX_AP_XXAUNMATCHRECEIPT_PKG.CALCULATE_CST_REC_AMT(CAPR.PO_DISTRIBUTION_ID, CAPR.ACCRUAL_ACCOUNT_ID, CAPR.RCV_TRANSACTION_ID)*-1))
        ELSE 0
      END BUC_D_5,
      CASE
        WHEN (TO_DATE (P_DATE)                                                                                                                - NVL2(RSH.ATTRIBUTE1, TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'),TO_DATE (RT.TRANSACTION_DATE)) ) BETWEEN 241 AND 300
        THEN SUM((XX_AP_XXAUNMATCHRECEIPT_PKG.CALCULATE_CST_REC_AMT(CAPR.PO_DISTRIBUTION_ID, CAPR.ACCRUAL_ACCOUNT_ID, CAPR.RCV_TRANSACTION_ID)*-1))
        ELSE 0
      END BUC_D_6,
      CASE
        WHEN (TO_DATE (P_DATE)                                                                                                                - NVL2(RSH.ATTRIBUTE1, TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'),TO_DATE (RT.TRANSACTION_DATE)) ) > 300
        THEN SUM((XX_AP_XXAUNMATCHRECEIPT_PKG.CALCULATE_CST_REC_AMT(CAPR.PO_DISTRIBUTION_ID, CAPR.ACCRUAL_ACCOUNT_ID, CAPR.RCV_TRANSACTION_ID)*-1))
        ELSE 0
      END BUC_D_7
    FROM
      --apps.PO_DISTRIBUTIONS_ALL POD,
      PO_HEADERS_ALL POH,
      RCV_SHIPMENT_HEADERS RSH,
      RCV_TRANSACTIONS RT,
      HR_ORGANIZATION_UNITS HR,
      AP_SUPPLIERS ASU,
      GL_CODE_COMBINATIONS_KFV GCC,
      AP_SUPPLIER_SITES_ALL APS,
      CST_RECONCILIATION_SUMMARY CSR,
      CST_AP_PO_RECONCILIATION CAPR
    WHERE 1                                                                                                                          = 1
    AND CAPR.TRANSACTION_TYPE_CODE                                                                                                   = 'RECEIVE'
    AND CAPR.OPERATING_UNIT_ID                                                                                                       =404
    AND CSR.PO_DISTRIBUTION_ID                                                                                                       = CAPR.PO_DISTRIBUTION_ID
    AND CSR.ACCRUAL_ACCOUNT_ID                                                                                                       = CAPR.ACCRUAL_ACCOUNT_ID
    AND NVL((CSR.PO_BALANCE +CSR.AP_BALANCE + CSR.WRITE_OFF_BALANCE),0)                                                              <0
    AND XX_AP_XXAUNMATCHRECEIPT_PKG.CALCULATE_CST_REC_AMT(CAPR.PO_DISTRIBUTION_ID, CAPR.ACCRUAL_ACCOUNT_ID, CAPR.RCV_TRANSACTION_ID) > 0
    AND APS.VENDOR_ID                                                                                                                = CSR.VENDOR_ID
    AND ((P_PO_TYPE                                                                                                                  = 'TRADE'
    AND EXISTS
      (SELECT 1
      FROM XX_FIN_TRANSLATEDEFINITION XFTD,
        XX_FIN_TRANSLATEVALUES XFTV
      WHERE XFTD.TRANSLATION_NAME = 'XX_AP_TRADE_CATEGORIES'
      AND XFTD.TRANSLATE_ID       = XFTV.TRANSLATE_ID
      AND XFTV.ENABLED_FLAG       = 'Y'
      AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)
      AND XFTV.TARGET_VALUE1 LIKE 'TR-%'
      AND XFTV.TARGET_VALUE1 <> 'TR-IMP'
      AND APS.ATTRIBUTE8      = XFTV.TARGET_VALUE1
      ))
    OR (P_PO_TYPE = 'EXPENSE'
    AND APS.ATTRIBUTE8 LIKE 'EX%')
    OR (P_PO_TYPE              = 'DIRECT IMPORT'
    AND APS.ATTRIBUTE8         = 'TR-IMP')
    OR (P_PO_TYPE             IS NULL
    AND APS.ATTRIBUTE8        <> 'TR-TDS') )
    AND RT.TRANSACTION_ID      = CAPR.RCV_TRANSACTION_ID
    AND RSH.SHIPMENT_HEADER_ID = RT.SHIPMENT_HEADER_ID
      --AND POD.PO_DISTRIBUTION_ID     = CAPR.PO_DISTRIBUTION_ID
      --AND POH.PO_HEADER_ID           = POD.PO_HEADER_ID
    AND POH.PO_HEADER_ID = RT.PO_HEADER_ID + 0
      --AND POH.VENDOR_ID              = CSR.VENDOR_ID
    AND POH.VENDOR_SITE_ID      = APS.VENDOR_SITE_ID
    AND POH.CURRENCY_CODE       = NVL(P_CURRENCY_CODE, POH.CURRENCY_CODE)
    AND HR.ORGANIZATION_ID      = RT.ORGANIZATION_ID --RSH.SHIP_TO_ORG_ID +0
    AND ASU.VENDOR_ID           = APS.VENDOR_ID
    AND GCC.CODE_COMBINATION_ID = CAPR.ACCRUAL_ACCOUNT_ID
    AND GCC.SEGMENT1 BETWEEN NVL(P_SEGMENT_FROM,GCC.SEGMENT1) AND NVL(P_SEGMENT_TO, GCC.SEGMENT1)
    AND APS.VENDOR_SITE_CODE BETWEEN NVL(P_SUP_SITE_CD_FROM, APS.VENDOR_SITE_CODE) AND NVL(P_SUP_SITE_CD_TO, APS.VENDOR_SITE_CODE)
    GROUP BY POH.SEGMENT1 ,
      POH.CURRENCY_CODE ,
      HR.NAME ,
      RSH.RECEIPT_NUM ,
      RSH.ATTRIBUTE1,
      RT.TRANSACTION_DATE,
      ASU.VENDOR_NAME,
      APS.VENDOR_SITE_CODE,
      APS.ATTRIBUTE8,
      APS.ATTRIBUTE6
    UNION ALL
    SELECT POH.SEGMENT1 PO_NUMBER,
      POH.CURRENCY_CODE PO_CURRENCY,
      HR.NAME C_LOCATION ,
      MAX(RSH.RECEIPT_NUM) RECEIPT_NUM,
      MAX(NVL2(RSH.ATTRIBUTE1, TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'),RT.TRANSACTION_DATE))RECEIPT_DATE ,
      ASU.VENDOR_NAME,
      APS.VENDOR_SITE_CODE,
      APS.ATTRIBUTE8 SUPPLIER_SITE_CATEGORY,
      DECODE(NVL(APS.ATTRIBUTE6,'XX'),'XX','Open',
      (SELECT XFTV.TARGET_VALUE2
      FROM XX_FIN_TRANSLATEDEFINITION XFTD,
        XX_FIN_TRANSLATEVALUES XFTV
      WHERE XFTD.TRANSLATION_NAME = 'XX_AP_VENDOR_ASSISTANTS'
      AND XFTD.TRANSLATE_ID       = XFTV.TRANSLATE_ID
      AND XFTV.ENABLED_FLAG       = 'Y'
      AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)
      AND XFTV.TARGET_VALUE1 =APS.ATTRIBUTE6
      )) VENDOR_ASSISTANT,
      CASE
        WHEN MAX((TO_DATE (P_DATE) - NVL2(RSH.ATTRIBUTE1, TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'), TO_DATE (RT.TRANSACTION_DATE)))) BETWEEN 0 AND 30
        THEN (CSR.PO_BALANCE       +CSR.AP_BALANCE + CSR.WRITE_OFF_BALANCE)
        ELSE 0
      END BUC_D_0,
      CASE
        WHEN MAX((TO_DATE (P_DATE) - NVL2(RSH.ATTRIBUTE1 ,TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'),TO_DATE (RT.TRANSACTION_DATE) ))) BETWEEN 31 AND 60
        THEN (CSR.PO_BALANCE       +CSR.AP_BALANCE + CSR.WRITE_OFF_BALANCE)
        ELSE 0
      END BUC_D_1,
      CASE
        WHEN MAX((TO_DATE (P_DATE) - NVL2(RSH.ATTRIBUTE1, TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'),TO_DATE (RT.TRANSACTION_DATE) ))) BETWEEN 61 AND 90
        THEN (CSR.PO_BALANCE       +CSR.AP_BALANCE + CSR.WRITE_OFF_BALANCE)
        ELSE 0
      END BUC_D_2,
      CASE
        WHEN MAX((TO_DATE (P_DATE) - NVL2(RSH.ATTRIBUTE1, TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'),TO_DATE (RT.TRANSACTION_DATE) ))) BETWEEN 91 AND 120
        THEN (CSR.PO_BALANCE       +CSR.AP_BALANCE + CSR.WRITE_OFF_BALANCE)
        ELSE 0
      END BUC_D_3,
      CASE
        WHEN MAX((TO_DATE (P_DATE) - NVL2(RSH.ATTRIBUTE1, TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'),TO_DATE (RT.TRANSACTION_DATE)) )) BETWEEN 121 AND 180
        THEN (CSR.PO_BALANCE       +CSR.AP_BALANCE + CSR.WRITE_OFF_BALANCE)
        ELSE 0
      END BUC_D_4,
      CASE
        WHEN MAX((TO_DATE (P_DATE) - NVL2(RSH.ATTRIBUTE1, TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'),TO_DATE (RT.TRANSACTION_DATE) ))) BETWEEN 181 AND 240
        THEN (CSR.PO_BALANCE       +CSR.AP_BALANCE + CSR.WRITE_OFF_BALANCE)
        ELSE 0
      END BUC_D_5,
      CASE
        WHEN MAX((TO_DATE (P_DATE) - NVL2(RSH.ATTRIBUTE1, TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'),TO_DATE (RT.TRANSACTION_DATE)) )) BETWEEN 241 AND 300
        THEN (CSR.PO_BALANCE       +CSR.AP_BALANCE + CSR.WRITE_OFF_BALANCE)
        ELSE 0
      END BUC_D_6,
      CASE
        WHEN MAX((TO_DATE (P_DATE) - NVL2(RSH.ATTRIBUTE1, TO_DATE(RSH.ATTRIBUTE1,'MM/DD/YY'),TO_DATE (RT.TRANSACTION_DATE)) )) > 300
        THEN (CSR.PO_BALANCE       +CSR.AP_BALANCE + CSR.WRITE_OFF_BALANCE)
        ELSE 0
      END BUC_D_7
    FROM PO_HEADERS_ALL POH,
      RCV_SHIPMENT_HEADERS RSH,
      --apps.PO_DISTRIBUTIONS_ALL POD,
      RCV_TRANSACTIONS RT,
      HR_ORGANIZATION_UNITS HR,
      AP_SUPPLIERS ASU,
      GL_CODE_COMBINATIONS_KFV GCC,
      AP_SUPPLIER_SITES_ALL APS,
      CST_AP_PO_RECONCILIATION CAPR,
      CST_RECONCILIATION_SUMMARY CSR
    WHERE 1                                                            = 1
    AND NVL((CSR.PO_BALANCE +CSR.AP_BALANCE + CSR.WRITE_OFF_BALANCE),0)>0
    AND APS.VENDOR_ID                                                  = CSR.VENDOR_ID
    AND ((P_PO_TYPE                                                    = 'TRADE'
    AND EXISTS
      (SELECT 1
      FROM XX_FIN_TRANSLATEDEFINITION XFTD,
        XX_FIN_TRANSLATEVALUES XFTV
      WHERE XFTD.TRANSLATION_NAME = 'XX_AP_TRADE_CATEGORIES'
      AND XFTD.TRANSLATE_ID       = XFTV.TRANSLATE_ID
      AND XFTV.ENABLED_FLAG       = 'Y'
      AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)
      AND XFTV.TARGET_VALUE1 LIKE 'TR-%'
      AND XFTV.TARGET_VALUE1 <> 'TR-IMP'
      AND APS.ATTRIBUTE8      = XFTV.TARGET_VALUE1
      ))
    OR (P_PO_TYPE = 'EXPENSE'
    AND APS.ATTRIBUTE8 LIKE 'EX%')
    OR (P_PO_TYPE               = 'DIRECT IMPORT'
    AND APS.ATTRIBUTE8          = 'TR-IMP')
    OR (P_PO_TYPE              IS NULL
    AND APS.ATTRIBUTE8         <> 'TR-TDS') )
    AND CAPR.PO_DISTRIBUTION_ID = CSR.PO_DISTRIBUTION_ID
    AND CAPR.ACCRUAL_ACCOUNT_ID = CSR.ACCRUAL_ACCOUNT_ID
    AND RT.TRANSACTION_ID       = CAPR.RCV_TRANSACTION_ID
    AND RSH.SHIPMENT_HEADER_ID  = RT.SHIPMENT_HEADER_ID
      --AND POD.PO_DISTRIBUTION_ID  = CAPR.PO_DISTRIBUTION_ID
      --AND POH.PO_HEADER_ID        = POD.PO_HEADER_ID
    AND POH.PO_HEADER_ID = RT.PO_HEADER_ID + 0
      --AND POH.VENDOR_ID           = CSR.VENDOR_ID
    AND POH.VENDOR_SITE_ID      = APS.VENDOR_SITE_ID
    AND POH.CURRENCY_CODE       = NVL(P_CURRENCY_CODE, POH.CURRENCY_CODE)
    AND HR.ORGANIZATION_ID      = RT.ORGANIZATION_ID--RSH.SHIP_TO_ORG_ID+0
    AND ASU.VENDOR_ID           = APS.VENDOR_ID
    AND CAPR.ACCRUAL_ACCOUNT_ID = GCC.CODE_COMBINATION_ID
    AND GCC.SEGMENT1 BETWEEN NVL(P_SEGMENT_FROM,GCC.SEGMENT1) AND NVL(P_SEGMENT_TO, GCC.SEGMENT1)
    AND APS.VENDOR_SITE_CODE BETWEEN NVL(P_SUP_SITE_CD_FROM, APS.VENDOR_SITE_CODE) AND NVL(P_SUP_SITE_CD_TO, APS.VENDOR_SITE_CODE)
    GROUP BY POH.SEGMENT1 ,
      --CSR.PO_DISTRIBUTION_ID,
      POH.CURRENCY_CODE ,
      HR.NAME ,
      (CSR.PO_BALANCE +CSR.AP_BALANCE + CSR.WRITE_OFF_BALANCE),
      ASU.VENDOR_NAME,
      APS.VENDOR_SITE_CODE,
      APS.ATTRIBUTE8,
      APS.ATTRIBUTE6 ;
  TYPE UNMATCH_DETAIL_CTT
IS
  TABLE OF XX_AP_XXAUNMATCHRECEIPT_PKG.UNMATCH_DETAIL_REC INDEX BY PLS_INTEGER;
  L_UNMATCH_DETAIL_REC UNMATCH_DETAIL_CTT;
  N NUMBER := 0;
BEGIN
  FOR I IN C_UNMATCH_REC( P_DATE , P_SEGMENT_FROM , P_SEGMENT_TO , P_SUP_SITE_CD_FROM , P_SUP_SITE_CD_TO , P_CURRENCY_CODE)
  LOOP
    L_UNMATCH_DETAIL_REC(N).PO_NUMBER              := I.PO_NUMBER;
    L_UNMATCH_DETAIL_REC(N).PO_CURRENCY            := I.PO_CURRENCY;
    L_UNMATCH_DETAIL_REC(N).C_LOCATION             := I.C_LOCATION;
    L_UNMATCH_DETAIL_REC(N).RECEIPT_NUM            := I.RECEIPT_NUM;
    L_UNMATCH_DETAIL_REC(N).SHIPMENT_HEADER_ID     := NULL;
    L_UNMATCH_DETAIL_REC(N).RECEIPT_DATE           := I.RECEIPT_DATE;
    L_UNMATCH_DETAIL_REC(N).VENDOR_ID              := NULL;
    L_UNMATCH_DETAIL_REC(N).VENDOR_NAME            := I.VENDOR_NAME;
    L_UNMATCH_DETAIL_REC(N).VENDOR_SITE_CODE       := I.VENDOR_SITE_CODE;
    L_UNMATCH_DETAIL_REC(N).SUPPLIER_SITE_CATEGORY := I.SUPPLIER_SITE_CATEGORY;
    L_UNMATCH_DETAIL_REC(N).VENDOR_ASSISTANT       := I.VENDOR_ASSISTANT;
    L_UNMATCH_DETAIL_REC(N).BUC_D_0                := I.BUC_D_0;
    L_UNMATCH_DETAIL_REC(N).BUC_D_1                := I.BUC_D_1;
    L_UNMATCH_DETAIL_REC(N).BUC_D_2                := I.BUC_D_2;
    L_UNMATCH_DETAIL_REC(N).BUC_D_3                := I.BUC_D_3;
    L_UNMATCH_DETAIL_REC(N).BUC_D_4                := I.BUC_D_4;
    L_UNMATCH_DETAIL_REC(N).BUC_D_5                := I.BUC_D_5;
    L_UNMATCH_DETAIL_REC(N).BUC_D_6                := I.BUC_D_6;
    L_UNMATCH_DETAIL_REC(N).BUC_D_7                := I.BUC_D_7;
    N                                              := N+1;
  END LOOP;
  FOR I IN L_UNMATCH_DETAIL_REC.FIRST .. L_UNMATCH_DETAIL_REC.LAST
  LOOP
    PIPE ROW ( L_UNMATCH_DETAIL_REC(I) ) ;
  END LOOP;
  RETURN;
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Exception caurght '||SQLERRM);
END XX_AP_UNMATCH_DETAIL;

FUNCTION CALCULATE_CST_REC_AMT(
    P_PO_DISTRIBUTION_ID NUMBER,
    P_PO_ACCRUAL_ID      NUMBER,
    P_RCV_TRANS_ID       NUMBER)
  RETURN NUMBER
IS
  L_TOTAL_REC_QTY NUMBER :=0;
  --l_rec_qty       NUMBER;
  L_FINAL_REC_QTY    NUMBER :=0;
  L_PREV_REC_AMT     NUMBER :=0;
  L_REC_AMT          NUMBER :=0;
  L_INV_AMT          NUMBER :=0;
  L_RETURN_AMT       NUMBER := 0;
  L_MAX_RCV_TRANS_ID NUMBER;
  L_REC_CORR_AMT     NUMBER :=0;
BEGIN
  SELECT NVL(SUM(AMOUNT),0)
  INTO L_INV_AMT
  FROM CST_AP_PO_RECONCILIATION
  WHERE PO_DISTRIBUTION_ID  = P_PO_DISTRIBUTION_ID
  AND ACCRUAL_ACCOUNT_ID    = P_PO_ACCRUAL_ID
  AND TRANSACTION_TYPE_CODE = 'AP PO MATCH';
  SELECT NVL(SUM(AMOUNT*-1),0)
  INTO L_REC_AMT
  FROM CST_AP_PO_RECONCILIATION
  WHERE PO_DISTRIBUTION_ID  = P_PO_DISTRIBUTION_ID
  AND ACCRUAL_ACCOUNT_ID    = P_PO_ACCRUAL_ID
  AND RCV_TRANSACTION_ID    = P_RCV_TRANS_ID
  AND TRANSACTION_TYPE_CODE = 'RECEIVE';
  -----Added for defect NAIT-27043
  SELECT NVL(SUM((CAPR.AMOUNT*-1)),0)
  INTO L_REC_CORR_AMT
  FROM CST_AP_PO_RECONCILIATION CAPR,
    RCV_TRANSACTIONS RT,
    RCV_SHIPMENT_HEADERS RSH
  WHERE CAPR.PO_DISTRIBUTION_ID  = P_PO_DISTRIBUTION_ID
  AND CAPR.ACCRUAL_ACCOUNT_ID    = P_PO_ACCRUAL_ID
  AND CAPR.TRANSACTION_TYPE_CODE = 'CORRECT'
  AND CAPR.RCV_TRANSACTION_ID    = RT.TRANSACTION_ID
  AND RSH.SHIPMENT_HEADER_ID     = RT.SHIPMENT_HEADER_ID
  AND RSH.RECEIPT_NUM            =
    (SELECT RSHS.RECEIPT_NUM
    FROM RCV_TRANSACTIONS RTS,
      RCV_SHIPMENT_HEADERS RSHS
    WHERE RTS.TRANSACTION_ID    = P_RCV_TRANS_ID
    AND RSHS.SHIPMENT_HEADER_ID = RTS.SHIPMENT_HEADER_ID
    );
  SELECT NVL(SUM((CAPR.AMOUNT)),0)
  INTO L_RETURN_AMT
  FROM CST_AP_PO_RECONCILIATION CAPR,
    RCV_TRANSACTIONS RT,
    RCV_SHIPMENT_HEADERS RSH
  WHERE CAPR.PO_DISTRIBUTION_ID  = P_PO_DISTRIBUTION_ID
  AND CAPR.ACCRUAL_ACCOUNT_ID    = P_PO_ACCRUAL_ID
  AND CAPR.TRANSACTION_TYPE_CODE = 'RETURN TO VENDOR'
  AND CAPR.RCV_TRANSACTION_ID    = RT.TRANSACTION_ID
  AND RSH.SHIPMENT_HEADER_ID     = RT.SHIPMENT_HEADER_ID
  AND RSH.RECEIPT_NUM            =
    (SELECT RSHS.RECEIPT_NUM
    FROM RCV_TRANSACTIONS RTS,
      RCV_SHIPMENT_HEADERS RSHS
    WHERE RTS.TRANSACTION_ID    = P_RCV_TRANS_ID
    AND RSHS.SHIPMENT_HEADER_ID = RTS.SHIPMENT_HEADER_ID
    );
  L_REC_AMT := L_REC_AMT - L_RETURN_AMT;
  BEGIN
    SELECT (AMOUNT*-1)
    INTO L_PREV_REC_AMT
    FROM CST_AP_PO_RECONCILIATION
    WHERE PO_DISTRIBUTION_ID                = P_PO_DISTRIBUTION_ID
    AND ACCRUAL_ACCOUNT_ID                  = P_PO_ACCRUAL_ID
    AND RCV_TRANSACTION_ID                  < P_RCV_TRANS_ID
    AND TRANSACTION_TYPE_CODE                                IN ('RECEIVE','RETURN TO VENDOR');
    IF (L_PREV_REC_AMT                                        - L_INV_AMT) < 0 THEN
      L_FINAL_REC_QTY                      := ((L_PREV_REC_AMT+L_REC_AMT) -L_INV_AMT); --*p_po_unit_price;
    ELSE
      L_FINAL_REC_QTY:= L_REC_AMT;
    END IF;
    RETURN L_FINAL_REC_QTY+L_REC_CORR_AMT;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    L_FINAL_REC_QTY := L_REC_AMT-L_INV_AMT;
  WHEN TOO_MANY_ROWS THEN
    SELECT NVL(SUM(AMOUNT*-1),0)
    INTO L_PREV_REC_AMT
    FROM CST_AP_PO_RECONCILIATION
    WHERE PO_DISTRIBUTION_ID   = P_PO_DISTRIBUTION_ID
    AND ACCRUAL_ACCOUNT_ID     = P_PO_ACCRUAL_ID
    AND RCV_TRANSACTION_ID     < P_RCV_TRANS_ID
    AND TRANSACTION_TYPE_CODE IN ('RECEIVE','RETURN TO VENDOR');
    IF L_PREV_REC_AMT         >= L_INV_AMT THEN
      L_FINAL_REC_QTY         := L_REC_AMT;
    ELSE
      L_FINAL_REC_QTY := (L_PREV_REC_AMT+L_REC_AMT)-L_INV_AMT;
    END IF;
  END;
  RETURN L_FINAL_REC_QTY+L_REC_CORR_AMT;
END CALCULATE_CST_REC_AMT;
--Start of new procedure (NAIT-27081)
PROCEDURE XX_AP_UNMATCH_WRAP_PROC(
    x_errbuf OUT VARCHAR2,
    X_RETCODE OUT NUMBER,
    p_date                       IN VARCHAR2,
    p_Currency_Code              IN VARCHAR2,
    p_GL_Accounting_Segment_From IN VARCHAR2,
    p_GL_Accounting_Segment_To   IN VARCHAR2,
    p_Supplier_Site_Code_From    IN VARCHAR2,
    p_Supplier_Site_Code_To      IN VARCHAR2,
    p_as_of_date                 IN VARCHAR2,
    p_po_type                    IN VARCHAR2 )
AS
  l_layout             NUMBER;
  l_request_id         NUMBER;
  l_date               DATE;
  lc_phase1            VARCHAR2(100);
  LC_MESSAGE1          VARCHAR2(300);
  lc_status1           VARCHAR2(300);
  lc_dev_phase1        VARCHAR2(300);
  lc_dev_status1       VARCHAR2(300);
  lb_bool              BOOLEAN;
  ln_pub_request_id    NUMBER;
  ln_application_id    NUMBER;
  ln_request_id        NUMBER;
  l_add_layout         BOOLEAN;
  l_req_return_status  BOOLEAN;
  lb_bool2             BOOLEAN;
  LC_PHASE2            VARCHAR2(100);
  LC_DEV_PHASE2        VARCHAR2(100);
  LC_DEV_STATUS2       VARCHAR2(100);
  lc_status2           VARCHAR2(100);
  lc_message2          VARCHAR2(100);
  l_req_return_status1 BOOLEAN;
  LB_BOOL3             BOOLEAN;
BEGIN
  fnd_file.put_line(fnd_file.log,'Printing parameters');
  fnd_file.put_line(fnd_file.log,'---------------------');
  fnd_file.put_line(fnd_file.log, 'p_date: '||p_date);
  fnd_file.put_line(fnd_file.log, 'p_Currency_Code: '||p_Currency_Code);
  fnd_file.put_line(fnd_file.log, 'p_gl_accounting_segment_from:  '||p_gl_accounting_segment_from);
  fnd_file.put_line(fnd_file.log, 'p_gl_accounting_segment_to: '||p_gl_accounting_segment_to);
  fnd_file.put_line(fnd_file.log, 'p_supplier_site_code_from: '||p_supplier_site_code_from);
  fnd_file.put_line(fnd_file.log, 'p_supplier_site_code_to: '||p_supplier_site_code_to);
  fnd_file.put_line(fnd_file.log, 'p_as_of_date: '||p_as_of_date);
  fnd_file.put_line(fnd_file.log, 'p_po_type: '||p_po_type);
  ln_request_id := fnd_global.conc_request_id;
  SELECT APP.application_id
  INTO ln_application_id
  FROM fnd_application_vl APP ,
    fnd_concurrent_programs FCP ,
    fnd_concurrent_requests R
  WHERE FCP.concurrent_program_id = R.concurrent_program_id
  AND R.request_id                = ln_request_id
  AND APP.application_id          = FCP.application_id;
  fnd_file.put_line(fnd_file.log,'Adding layout');
  l_add_layout :=fnd_request.add_layout('XXFIN', 'XXAPUNMTCHNONCONS', 'en', 'US', 'EXCEL');
  IF l_add_layout THEN
    fnd_file.put_line(fnd_file.log,'Layout added successfully');
  ELSE
    fnd_file.put_line(fnd_file.log,'Unable to add layout');
  END IF;
  --
  --Submitting Concurrent Request
  --
  fnd_file.put_line(fnd_file.log,'Submitting OD: Unmatched Receipts Summary Report');
  l_request_id := fnd_request.submit_request ( application => 'XXFIN', program => 'XXAPUNMTCHNONCONS', description => 'OD: Unmatched Receipts Summary Report', start_time => sysdate, sub_request => false, argument1 => p_date, argument2 => p_Currency_Code, argument3 => p_gl_accounting_segment_from, argument4 => p_gl_accounting_segment_to, argument5 => p_supplier_site_code_from, argument6 => p_supplier_site_code_to, argument7 => p_as_of_date, argument8 => p_po_type );
  --
  COMMIT;
  --
  IF l_request_id = 0 THEN
    fnd_file.put_line(fnd_file.log,'Concurrent request failed to submit');
  ELSE
    fnd_file.put_line(fnd_file.log, 'Program submitted successfully. Request_ID is : '||l_request_id);
    LOOP
      --
      --To make process execution to wait for 1st program to complete
      --
      l_req_return_status := fnd_concurrent.wait_for_request (request_id => l_request_id ,interval => 5 --interval Number of seconds to wait between checks
      ,max_wait => 50000                                                                                --Maximum number of seconds to wait for the request completion
      -- out arguments
      ,phase => lc_phase1 ,status => lc_status1 ,dev_phase => lc_dev_phase1 ,dev_status => lc_dev_status1 ,MESSAGE => lc_message1 );
      EXIT
    WHEN UPPER (lc_phase1) = 'COMPLETED' OR UPPER (lc_status1) IN ('CANCELLED', 'ERROR', 'TERMINATED');
    END LOOP;
    --
    --
    IF upper (lc_phase1) = 'COMPLETED' AND upper (lc_status1) = 'ERROR' THEN
      fnd_file.put_line(fnd_file.log,'The OD: Unmatched Receipts Summary Report completed in error. Oracle request id: '||l_request_id );
    END IF;
    --
    IF ((lc_dev_phase1 = 'COMPLETE') AND (lc_dev_status1 = 'NORMAL')) THEN
	fnd_file.put_line(fnd_file.log,'Program OD: Unmatched Receipts Summary Report completed successfully');
      fnd_file.put_line(fnd_file.log,'Submitting XML Report Publisher');
      lb_bool3:= FND_REQUEST.SET_PRINT_OPTIONS ('XPTR' --printer name
      ,'PORTRAIT'                                      --style
      ,1 ,TRUE ,'N');
      ln_pub_request_id := fnd_request.submit_request ('XDO' --- application sort name
      ,'XDOREPPB'                                            --- program short name
      ,NULL                                                  --- description
      ,sysdate                                               --- start_time
      ,TRUE                                                  --- sub_request
      ,'N'                                                   --- Dummy for Data Security
      ,l_request_id                                          ---  Request_Id of Previous Program
      --,200
      ,ln_application_id   ---  Template Application_id=20043
      ,'XXAPUNMTCHNONCONS' --- Template Code
      ,'en-US'             ---  Template Locale
      , 'N'                ---  Debug Flag
      ,'RTF'                --template_type,      --- Template Type
      ,'EXCEL'              --output type         --- Output Type
      ,chr(0) ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'' );
      COMMIT;
    ELSE
      fnd_file.put_line(fnd_file.log, 'Unable to submit XML Report Publisher Program');
    END IF;
    IF ln_pub_request_id > 0 THEN
      UPDATE fnd_concurrent_requests
      SET phase_code   = 'P',
        status_code    = 'I'
      WHERE request_id = ln_pub_request_id;
      fnd_file.put_line(fnd_file.log,'Successfully Submitted the XML Report Publiser: '||ln_pub_request_id);
      COMMIT;
      LOOP
        --
        --To make process execution to wait for 1st program to complete
        --
        l_req_return_status1 := fnd_concurrent.wait_for_request (request_id => ln_pub_request_id ,interval => 5 --interval Number of seconds to wait between checks
        ,max_wait => 50000                                                                                      --Maximum number of seconds to wait for the request completion
        -- out arguments
        ,phase => lc_phase2 ,status => lc_status2 ,dev_phase => lc_dev_phase2 ,dev_status => lc_dev_status2 ,MESSAGE => lc_message2 );
        EXIT
      WHEN UPPER (lc_phase2) = 'COMPLETED' OR UPPER (lc_status2) IN ('CANCELLED', 'ERROR', 'TERMINATED');
      END LOOP;
      --
      --
      IF upper (lc_phase2) = 'COMPLETED' AND upper (lc_status2) = 'ERROR' THEN
        fnd_file.put_line(fnd_file.log,'XML Report Publisher program completed in error. Oracle request id: '||ln_pub_request_id );
      END IF;
      --
      IF ((lc_dev_phase1 = 'COMPLETE') AND (lc_dev_status1 = 'NORMAL')) THEN
        fnd_file.put_line(fnd_file.log,'XML Report Publisher completed successfully');
      END IF;
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  x_errbuf  := 'Error';-- While Submitting Concurrent Request';
  x_retcode := 2;
  fnd_file.put_line(fnd_file.log,x_errbuf);
END xx_ap_unmatch_wrap_proc;
--end of new procedure(NAIT-27081)


PROCEDURE XX_AP_UNMATCH_DETAIL_WRAP_PROC(
    x_errbuf OUT VARCHAR2,
    X_RETCODE OUT NUMBER,
    p_date                       IN VARCHAR2,
    p_Currency_Code              IN VARCHAR2,
    p_GL_Accounting_Segment_From IN VARCHAR2,
    p_GL_Accounting_Segment_To   IN VARCHAR2,
    p_Supplier_Site_Code_From    IN VARCHAR2,
    p_Supplier_Site_Code_To      IN VARCHAR2,
    p_as_of_date                 IN VARCHAR2,
    p_po_type                    IN VARCHAR2 )
AS
  l_layout             NUMBER;
  l_request_id         NUMBER;
  l_date               DATE;
  lc_phase1            VARCHAR2(100);
  LC_MESSAGE1          VARCHAR2(300);
  lc_status1           VARCHAR2(300);
  lc_dev_phase1        VARCHAR2(300);
  lc_dev_status1       VARCHAR2(300);
  lb_bool              BOOLEAN;
  ln_pub_request_id    NUMBER;
  ln_application_id    NUMBER;
  ln_request_id        NUMBER;
  l_add_layout         BOOLEAN;
  l_req_return_status  BOOLEAN;
  lb_bool2             BOOLEAN;
  LC_PHASE2            VARCHAR2(100);
  LC_DEV_PHASE2        VARCHAR2(100);
  LC_DEV_STATUS2       VARCHAR2(100);
  lc_status2           VARCHAR2(100);
  lc_message2          VARCHAR2(100);
  l_req_return_status1 BOOLEAN;
  LB_BOOL3             BOOLEAN;
BEGIN
  fnd_file.put_line(fnd_file.log,'Printing parameters');
  fnd_file.put_line(fnd_file.log,'---------------------');
  fnd_file.put_line(fnd_file.log, 'p_date: '||p_date);
  fnd_file.put_line(fnd_file.log, 'p_Currency_Code: '||p_Currency_Code);
  fnd_file.put_line(fnd_file.log, 'p_gl_accounting_segment_from:  '||p_gl_accounting_segment_from);
  fnd_file.put_line(fnd_file.log, 'p_gl_accounting_segment_to: '||p_gl_accounting_segment_to);
  fnd_file.put_line(fnd_file.log, 'p_supplier_site_code_from: '||p_supplier_site_code_from);
  fnd_file.put_line(fnd_file.log, 'p_supplier_site_code_to: '||p_supplier_site_code_to);
  fnd_file.put_line(fnd_file.log, 'p_as_of_date: '||p_as_of_date);
  fnd_file.put_line(fnd_file.log, 'p_po_type: '||p_po_type);
  ln_request_id := fnd_global.conc_request_id;
  SELECT APP.application_id
  INTO ln_application_id
  FROM fnd_application_vl APP ,
    fnd_concurrent_programs FCP ,
    fnd_concurrent_requests R
  WHERE FCP.concurrent_program_id = R.concurrent_program_id
  AND R.request_id                = ln_request_id
  AND APP.application_id          = FCP.application_id;
  fnd_file.put_line(fnd_file.log,'Adding layout');
  l_add_layout :=fnd_request.add_layout('XXFIN', 'XXAPUNMATCHEDRTFRPT', 'en', 'US', 'EXCEL');
  IF l_add_layout THEN
    fnd_file.put_line(fnd_file.log,'Layout added successfully');
  ELSE
    fnd_file.put_line(fnd_file.log,'Unable to add layout');
  END IF;
  --
  --Submitting Concurrent Request
  --
  fnd_file.put_line(fnd_file.log,'Submitting OD: Unmatched Receipts Detail Report');
  l_request_id := fnd_request.submit_request ( application => 'XXFIN', program => 'XX_AP_UNMATCH_DTL', description => 'OD: Unmatched Receipts Detail Report', start_time => sysdate, sub_request => false, argument1 => p_date, argument2 => p_Currency_Code, argument3 => p_gl_accounting_segment_from, argument4 => p_gl_accounting_segment_to, argument5 => p_supplier_site_code_from, argument6 => p_supplier_site_code_to, argument7 => p_as_of_date, argument8 => p_po_type );
  --
  COMMIT;
  --
  IF l_request_id = 0 THEN
    fnd_file.put_line(fnd_file.log,'Concurrent request failed to submit');
  ELSE
    fnd_file.put_line(fnd_file.log, 'Program submitted successfully. Request_ID is : '||l_request_id);
    LOOP
      --
      --To make process execution to wait for 1st program to complete
      --
      l_req_return_status := fnd_concurrent.wait_for_request (request_id => l_request_id ,interval => 5 --interval Number of seconds to wait between checks
      ,max_wait => 50000                                                                                --Maximum number of seconds to wait for the request completion
      -- out arguments
      ,phase => lc_phase1 ,status => lc_status1 ,dev_phase => lc_dev_phase1 ,dev_status => lc_dev_status1 ,MESSAGE => lc_message1 );
      EXIT
    WHEN UPPER (lc_phase1) = 'COMPLETED' OR UPPER (lc_status1) IN ('CANCELLED', 'ERROR', 'TERMINATED');
    END LOOP;
    --
    --
    IF upper (lc_phase1) = 'COMPLETED' AND upper (lc_status1) = 'ERROR' THEN
      fnd_file.put_line(fnd_file.log,'The OD: Unmatched Receipts Detail Report completed in error. Oracle request id: '||l_request_id );
    END IF;
    --
    IF ((lc_dev_phase1 = 'COMPLETE') AND (lc_dev_status1 = 'NORMAL')) THEN
	fnd_file.put_line(fnd_file.log,'Program OD: Unmatched Receipts Detail Report completed successfully');
      fnd_file.put_line(fnd_file.log,'Submitting XML Report Publisher');
      lb_bool3:= FND_REQUEST.SET_PRINT_OPTIONS ('XPTR' --printer name
      ,'PORTRAIT'                                      --style
      ,1 ,TRUE ,'N');
      ln_pub_request_id := fnd_request.submit_request ('XDO' --- application sort name
      ,'XDOREPPB'                                            --- program short name
      ,NULL                                                  --- description
      ,sysdate                                               --- start_time
      ,TRUE                                                  --- sub_request
      ,'N'                                                   --- Dummy for Data Security
      ,l_request_id                                          ---  Request_Id of Previous Program
      --,200
      ,ln_application_id   ---  Template Application_id=20043
      ,'XXAPUNMATCHEDRTFRPT' --- Template Code
      ,'en-US'             ---  Template Locale
      , 'N'                ---  Debug Flag
      ,'RTF'                --template_type,      --- Template Type
      ,'EXCEL'              --output type         --- Output Type
      ,chr(0) ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'' );
      COMMIT;
    ELSE
      fnd_file.put_line(fnd_file.log, 'Unable to submit XML Report Publisher Program');
    END IF;
    IF ln_pub_request_id > 0 THEN
      UPDATE fnd_concurrent_requests
      SET phase_code   = 'P',
        status_code    = 'I'
      WHERE request_id = ln_pub_request_id;
      fnd_file.put_line(fnd_file.log,'Successfully Submitted the XML Report Publiser: '||ln_pub_request_id);
      COMMIT;
      LOOP
        --
        --To make process execution to wait for 1st program to complete
        --
        l_req_return_status1 := fnd_concurrent.wait_for_request (request_id => ln_pub_request_id ,interval => 5 --interval Number of seconds to wait between checks
        ,max_wait => 50000                                                                                      --Maximum number of seconds to wait for the request completion
        -- out arguments
        ,phase => lc_phase2 ,status => lc_status2 ,dev_phase => lc_dev_phase2 ,dev_status => lc_dev_status2 ,MESSAGE => lc_message2 );
        EXIT
      WHEN UPPER (lc_phase2) = 'COMPLETED' OR UPPER (lc_status2) IN ('CANCELLED', 'ERROR', 'TERMINATED');
      END LOOP;
      --
      --
      IF upper (lc_phase2) = 'COMPLETED' AND upper (lc_status2) = 'ERROR' THEN
        fnd_file.put_line(fnd_file.log,'XML Report Publisher program completed in error. Oracle request id: '||ln_pub_request_id );
      END IF;
      --
      IF ((lc_dev_phase1 = 'COMPLETE') AND (lc_dev_status1 = 'NORMAL')) THEN
        fnd_file.put_line(fnd_file.log,'XML Report Publisher completed successfully');
      END IF;
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  x_errbuf  := 'Error';-- While Submitting Concurrent Request';
  x_retcode := 2;
  fnd_file.put_line(fnd_file.log,x_errbuf);
END XX_AP_UNMATCH_DETAIL_WRAP_PROC;
--end of new procedures(NAIT-27081)
END xx_ap_xxaunmatchreceipt_pkg;