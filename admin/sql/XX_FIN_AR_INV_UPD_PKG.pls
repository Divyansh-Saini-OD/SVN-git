SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE XX_FIN_AR_INV_UPD_PKG
AUTHID CURRENT_USER AS
/* $Header: XX_FIN_AR_INV_UPD_PKG.pls $ */
/*#
* This custom PL/SQL package can be used to stage updates daily from VPS to Oracle using Web Services.  
* @rep:scope public
* @rep:product AR
* @rep:displayname ODVPSUPDInvoiceStage
* @rep:category BUSINESS_ENTITY AR_UPD_Invoice_Interface
*/
  PROCEDURE UPDATE_PROGRAM(
      PGM_ID            IN NUMBER,
      METH_OF_PMT_CD    IN VARCHAR2,
      PGM_DATE          IN VARCHAR2,
      PGM_STATUS        IN VARCHAR2,
      DUE_DATE          IN VARCHAR2,
      TRAN_SOURCE       IN VARCHAR2,
      P_OUT             OUT VARCHAR2)
/*# 
* Use this procedure for VPS daily updates  
* @param PGM_ID Contains Reference Id 
* @param METH_OF_PMT_CD Payment Method 
* @param PGM_DATE Contains Program Date ,
* @param PGM_STATUS Contains Program Status,
* @param DUE_DATE Contains VPS DUE DATE
* @param TRAN_SOURCE Contains VPS Batch Source
* @param P_OUT Contains out parameter value
* @rep:displayname UPDATE_INVOICE 
* @rep:category BUSINESS_ENTITY AR_UPD_Invoice_Interface
* @rep:scope public 
* @rep:lifecycle active 
*/;
  END XX_FIN_AR_INV_UPD_PKG ;
/
SHOW ERRORS;