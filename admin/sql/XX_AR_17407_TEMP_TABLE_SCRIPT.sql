-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | SQL Script to create                                                     |
-- |                                                                          |
-- |                      TABLES: XX_DEPOSITS_TEMP_DTL                        |
-- |                              XX_DEPOSITS_TEMP                            |
-- |                                                                          |
-- |   NAME:    XX_DEFECT_17407_TEMP_TABLE_SCRIPT.tbl                         |
-- |                                                                          |
-- |  Description: Tables created for Defect#17407                            |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   ================     ==============================|
-- | V1.0     04-JUN-2012  Gayathri K           Initial version               |
-- +==========================================================================+
SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK ON
CREATE TABLE XXFIN.Xa AS
SELECT DISTINCT XOLDD.ORIG_SYS_DOCUMENT_REF,
  XOLD.CASH_RECEIPT_ID
FROM APPS.XX_OM_LEGACY_DEP_DTLS XOLDD,
  APPS.XX_OM_LEGACY_DEPOSITS XOLD
WHERE 1=2;
CREATE TABLE XXFIN.Xb AS
SELECT TO_CHAR(OEH.ORDER_NUMBER) ORDER_NUMBER,
  XDT.ORIG_SYS_DOCUMENT_REF,
  XDT.CASH_RECEIPT_ID
FROM APPS.OE_ORDER_HEADERS_ALL OEH,
  XXFIN.XX_DEPOSITS_TEMP_DTL XDT
WHERE 1=2;
SHOW ERROR
