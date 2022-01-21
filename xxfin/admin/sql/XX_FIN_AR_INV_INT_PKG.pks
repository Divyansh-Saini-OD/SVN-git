SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace PACKAGE XX_FIN_AR_INV_INT_PKG
AUTHID CURRENT_USER AS
/* $Header: XX_FIN_AR_INV_INT_PKG.pls $ */
/*#
* This custom PL/SQL package can be used to stage data from VPS to Oracle using Web Services.  
* @rep:scope public
* @rep:product AR
* @rep:displayname ODVPSInvoiceStage
* @rep:category BUSINESS_ENTITY AR_Invoice_Interface
*/
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
/*# 
* Use this procedure to insert data into Custom AR Interface Table 
* @param INVOICE_DATE Transaction Date 
* @param INVOICE_NUM Transaction Number 
* @param CUSTOMER_NUM Vendor Number 
* @param TRAN_SOURCE Transaction Source 
* @param TRAN_TYPE Transaction Type 
* @param PGM_TYPE Additional Attributes 
* @param PGM_NAME Contains Program Name 
* @param PGM_STATUS Contains Program Status 
* @param PGM_ID Contains Reference Id 
* @param METH_OF_PMT_CD Contains Payment Method 
* @param FREQ_CD Contains Billing Frequency 
* @param INVOICE_AMT Contains Transaction Amount
* @param PGM_BASIS_AMT Contains Total Purchase Amount,
* @param PGM_VALUE Contains Program Value
* @param PGM_DATE Contains Program Date 
* @param PGM_BASIS Contains Program Basis
* @param DUE_DATE Contains Due Date
* @param UPLOADED_BY Contains Uploaded By
* @param BATCH_ID Contains Batch Id
* @param COMMENTS Contains Comments
* @param VPS_CREATION_DATE Contains VPS Creation Date
* @param VPS_SENT_DATE Contains VPS SENT DATE
* @param OUT_STATUS Contains status of program
* @rep:displayname STAGE_INVOICE 
* @rep:category BUSINESS_ENTITY AR_Invoice_Interface
* @rep:scope public 
* @rep:lifecycle active 
*/;
  END XX_FIN_AR_INV_INT_PKG ;
/
SHOW ERRORS;