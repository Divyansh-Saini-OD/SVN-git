SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace PACKAGE XX_FIN_VPS_RECEIPT_UPLOAD_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_FIN_VPS_MANUAL_NET_UPLOAD_PKG                                                   |
  -- |                                                                                            |
  -- |  Description:  This package is used by WEB ADI to load VPS Manual Netting.                 |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         07-AUG-2017  Thejaswini Rajula    Initial version                              |
  -- +============================================================================================+
  PROCEDURE INSERT_VPS_RECEIPT_UPLOAD(P_VENDOR_NUM				IN VARCHAR2	,			  
                                      P_RECEIPT_NUMBER		IN VARCHAR2	,		  
                                      P_RECEIPT_DATE			IN VARCHAR2 ,
                                      P_RECEIPT_METHOD	  IN VARCHAR2 , 
                                      P_RECEIPT_AMOUNT		IN NUMBER   ,
                                      P_INVOICE_NUMBER		IN VARCHAR2 , 
                                      P_INVOICE_AMOUNT		IN NUMBER   
      );
END XX_FIN_VPS_RECEIPT_UPLOAD_PKG ;
/