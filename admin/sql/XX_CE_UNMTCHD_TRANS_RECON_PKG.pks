SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_CE_UNMTCHD_TRANS_RECON_PKG
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- +===================================================================+
  -- | Name        :  XX_CE_UNMTCHD_TRANS_RECON_PKG.pks                  |
  -- | Description :  Plsql package for CE Unmatched Transactions Report |
  -- |                 												     |
  -- | RICE ID     :                                                     |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author             Remarks                   |
  -- |========  =========== ================== ==========================|
  -- |1.0       31-Oct-2018 M K Pramod Kumar     Initial version           |
  -- |                                                     |
  -- +===================================================================+
AS
  P_PROVIDER_TYPE             VARCHAR2(50);
  P_DEPOSIT_FROM_DATE    VARCHAR2(30);
  P_DEPOSIT_TO_DATE     VARCHAR2(30);
TYPE UNMATCH_AJB998_TRANS_REC
IS
  RECORD
  (
    provider_type        XX_CE_AJB998.provider_type%type,
	invoice_num          XX_CE_AJB998.invoice_num%type,
	receipt_num          XX_CE_AJB998.receipt_num%type,
	bank_rec_id          XX_CE_AJB998.bank_rec_id%type,
	processor_id         XX_CE_AJB998.processor_id%type,
	trx_type             XX_CE_AJB998.trx_type%type,
	order_source         xx_ar_order_receipt_dtl.order_source%type,
	order_type           xx_ar_order_receipt_dtl.order_type%type,
	order_number         xx_ar_order_receipt_dtl.order_number%type,
	store_number         xx_ar_order_receipt_dtl.store_number%type,
	payment_type_code    xx_ar_order_receipt_dtl.payment_type_code%type,
	credit_card_code     xx_ar_order_receipt_dtl.credit_card_code%type,	
	receipt_number       xx_ar_order_receipt_dtl.receipt_number%type,
	header_id 				xx_ar_order_receipt_dtl.header_id%type,
	ORDT_payment_amount  xx_ar_order_receipt_dtl.payment_amount%type,
	AJB998_TRX_AMOUNT   XX_CE_AJB998.trx_amount%type,
	VARIANCE_AMOUNT      XX_CE_AJB998.trx_amount%type,
	ERROR_CODE 			 VARCHAR2(100),
	ERROR_DESCRIPTION    vARCHAR2(1000)	
	);
TYPE UNMATCH_AJB998_TRANS_TBL
IS
  TABLE OF XX_CE_UNMTCHD_TRANS_RECON_PKG.UNMATCH_AJB998_TRANS_REC;
  FUNCTION XX_CE_UNMATCH_TRANS_DETAILS(
      P_PROVIDER_TYPE             VARCHAR2,
      P_DEPOSIT_FROM_DATE     VARCHAR2,
      P_DEPOSIT_TO_DATE       VARCHAR2
      )
    RETURN XX_CE_UNMTCHD_TRANS_RECON_PKG.UNMATCH_AJB998_TRANS_TBL PIPELINED;
  FUNCTION BEFOREREPORT
    RETURN BOOLEAN;
 
END XX_CE_UNMTCHD_TRANS_RECON_PKG;
/
SHOW ERROR