create or replace 
PACKAGE XX_FIN_VPS_NETTING_PKG AS  
-- =========================================================================================================================
--   NAME:       XX_FIN_VPS_NETTING_PKG .
--   PURPOSE:    This package contains procedures and functions for the
--                AP/AR Netting process.
--               E7030 - VPS AP/AR Netting - Systematic 
--   REVISIONS:
--   Ver        Date        Author           Description
--   ---------  ----------  ---------------  -------------------------------------------------------------------------------
--   1.0        08/01/2017  Sreedhar Mohan      Created this package.
--   1.1        08/03/2017  Uday Jadhav         Modified the package to add AP invoice import and Email Notification
-- =========================================================================================================================
  g_inv_org_id NUMBER;
  g_pkg_name VARCHAR2(100) :='XX_FIN_VPS_NETTING_PKG';
  
  PROCEDURE main (
      p_errbuf_out              OUT      VARCHAR2
     ,p_retcod_out              OUT      VARCHAR2
     ,p_vendor_number           IN       VARCHAR2
     ,p_run_date                IN       VARCHAR2
   );
   
  PROCEDURE PROCESS_VENDOR_NETTING (
      p_errbuf_out              OUT      VARCHAR2
     ,p_retcod_out              OUT      VARCHAR2
     ,p_vendor_number           IN       VARCHAR2
     ,p_run_date                IN       VARCHAR2
   );
   
   PROCEDURE PROCESS_AP_INVOICE(  
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
                            ,o_invoice_id               OUT NUMBER
                            ,x_err_msg                  OUT VARCHAR2
                            );
                            
end XX_FIN_VPS_NETTING_PKG;
/
