SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_AP_XXAUNMATCHRECEIPT_PKG
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- +===================================================================+
  -- | Name        :  XX_AP_XXAUNMATCHRECEIPT_PKG.pks                   |
  -- | Description :  Plsql package for XXAPUNMATCHRECEIPTS Report       |
  -- |                 												     |
  -- | RICE ID     :                                                     |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author             Remarks                   |
  -- |========  =========== ================== ==========================|
  -- |1.0       14-Nov-2017 Ragni Gupta     Initial version           |
  -- |                                                     |
  -- +===================================================================+
AS
  P_DATE             VARCHAR2(20);
  P_CURRENCY_CODE    VARCHAR2(3);
  P_SEGMENT_FROM     VARCHAR2(10);
  P_SEGMENT_TO       VARCHAR2(10);
  P_SUP_SITE_CD_FROM VARCHAR2(100);
  P_SUP_SITE_CD_TO   VARCHAR2(100);
  P_PO_TYPE          VARCHAR2(15);
  G_PO_TYPE_CLAUSE   VARCHAR2(2000) := ' ';
TYPE UNMATCH_DETAIL_REC
IS
  RECORD
  (
    PO_NUMBER              VARCHAR2(20),
    PO_CURRENCY            VARCHAR2(15 ),
    C_LOCATION             VARCHAR2(240 ),
    RECEIPT_NUM            VARCHAR2(30 ),
    SHIPMENT_HEADER_ID     NUMBER,
    RECEIPT_DATE           DATE,
    VENDOR_ID              NUMBER,
    VENDOR_NAME            VARCHAR2(240 ),
    VENDOR_SITE_CODE       VARCHAR2(15 ),
    SUPPLIER_SITE_CATEGORY VARCHAR2(150),
    VENDOR_ASSISTANT       VARCHAR2(240 ),
    BUC_D_0                NUMBER,
    BUC_D_1                NUMBER,
    BUC_D_2                NUMBER,
    BUC_D_3                NUMBER,
    BUC_D_4                NUMBER,
    BUC_D_5                NUMBER,
    BUC_D_6                NUMBER,
    BUC_D_7                NUMBER );
TYPE UNMATCH_DETAIL_REC_CTT
IS
  TABLE OF XX_AP_XXAUNMATCHRECEIPT_PKG.UNMATCH_DETAIL_REC;
  FUNCTION XX_AP_UNMATCH_DETAIL(
      P_DATE             VARCHAR2,
      P_SEGMENT_FROM     VARCHAR2,
      P_SEGMENT_TO       VARCHAR2,
      P_SUP_SITE_CD_FROM VARCHAR2,
      P_SUP_SITE_CD_TO   VARCHAR2,
      P_CURRENCY_CODE    VARCHAR2 )
    RETURN XX_AP_XXAUNMATCHRECEIPT_PKG.UNMATCH_DETAIL_REC_CTT PIPELINED;
  FUNCTION BEFOREREPORT
    RETURN BOOLEAN;
	 FUNCTION AFTERREPORT
    RETURN BOOLEAN;
  FUNCTION CALCULATE_CST_REC_AMT(
      P_PO_DISTRIBUTION_ID NUMBER,
      P_PO_ACCRUAL_ID      NUMBER,
      P_RCV_TRANS_ID       NUMBER)
    RETURN NUMBER;
END;
/

SHOW ERROR