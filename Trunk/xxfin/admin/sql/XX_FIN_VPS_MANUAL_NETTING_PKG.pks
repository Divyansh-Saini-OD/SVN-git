SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace PACKAGE XX_FIN_VPS_MANUAL_NETTING_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                          	  |
  -- +============================================================================================+
  -- |  Name:  XX_FIN_VPS_MANUAL_NETTING_PKG                                                     	|
  -- |                                                                                            |
  -- |  Description:  This package is used to create AR AP Manual Netting.        	              |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         07-AUG-2017  Thejaswini Rajula    Initial version                              |
  -- +============================================================================================+

g_pkg_name VARCHAR2(100) :='XX_FIN_VPS_MANUAL_NETTING_PKG';

PROCEDURE Send_Email_Notif(  p_errbuf_out              OUT      VARCHAR2
                            ,p_retcod_out              OUT      VARCHAR2);


  /* PROCEDURE Process_AP_Invoice(  
                              p_vendor_num                IN VARCHAR2
                            , p_vendor_site_code          IN VARCHAR2
                            , p_source                    IN VARCHAR2
                            , p_group_id                  IN VARCHAR2
                            , p_invoice_id                IN NUMBER
                            , p_invoice_num               IN VARCHAR2
                            , p_invoice_type_lookup_code  IN VARCHAR2
                            , p_invoice_date              IN DATE
                            , p_invoice_amount            IN NUMBER
                            , p_description               IN VARCHAR2
                            , p_attribute_category        IN VARCHAR2
                            , p_attribute10               IN VARCHAR2
                            , p_attribute11               IN VARCHAR2
                            , p_vendor_email_address      IN VARCHAR2
                            , p_external_doc_ref          IN VARCHAR2
                            , p_legacy_segment2           IN VARCHAR2
                            , p_legacy_segment3           IN VARCHAR2
                            , p_legacy_segment4           IN VARCHAR2
                            , p_invoice_line_id           IN NUMBER
                            , p_line_number               IN VARCHAR2
                            , p_line_type_lookup_code     IN VARCHAR2
                            , p_invoice_line_amount       IN NUMBER
                            , p_global_attribute11        IN VARCHAR2 
                            , p_receipt_method            IN VARCHAR2
                            , o_invoice_id                OUT NUMBER
                            , x_err_msg                   OUT VARCHAR2
                            ); */
   PROCEDURE main (
      p_errbuf_out              OUT      VARCHAR2
     ,p_retcod_out              OUT      VARCHAR2
   );

END XX_FIN_VPS_MANUAL_NETTING_PKG;
/
