CREATE OR REPLACE PACKAGE APPS.XX_AR_GEN_EBILL_PKG AS 
---+============================================================================================+
---|                              Office Depot - Project Simplify                               |
---|                                   Providge Consulting                                      |
---+============================================================================================+
---|    Application     :       AR                                                              |
---|                                                                                            |
---|    Name           :        xx_ar_gen_ebill_pkg.pks                                         |
---|                                                                                            |
---|    Description   :        Generate text file from Oracle AR to OD's Ebill Central System   |
---|                                                                                            |
---|                                                                                            |
---|                                                                                            |
---|    Change Record                                                                           |
---|    ---------------------------------                                                       |
---|    Version         DATE              AUTHOR             DESCRIPTION                        |
---|    ------------    ----------------- ---------------    ---------------------              |
---|    2.5             29-APR-2016       Havish Kasina      Kitting Changes, Defect#37670      |
-- |    2.4             06-APR-2010       Tamil Vendhan L    Modified for R1.3 CR 738 Defect    |
-- |                                                         2766                               |
-- |    2.3             15-DEC-2009       Tamil Vendhan L    Modified for R1.2 CR 466           |
-- |                                                         Defect 1210                        |
-- |    2.2             16-SEP-2009       Tamil Vendhan L    Modified for R1.1 Defect #1451     |
-- |                                                         (CR 626)                           |
---|    2.1             17-AUG-2009       Vinaykumar S       Defect # 1760                      |
---|    2.0             17-JUL-2009       Samabsiva Reddy D  Defect# 631 (CR# 662)              |
---|                                                         - Applied Credit Memos             |
---|    1.9             27-NOV-2008       Ganga Devi R       Commented a procedure for          |
---|                                                         defect 12435                       |
---|    1.8             21-NOV-2008       Shobana S          Added New Procedure for Defect12468|
---|    1.7             12-AUG-2008       Sarat Uppalapati   Defect# 9077 Add "As of Date"      |
---|                                                                                 Parameter  |
---|    1.6             11-JUL-2008       Sarat Uppalapati   Changed generate_info_copy2        |
---|                                                         to generate_info_copy              |
---|    1.6             11-JUL-2008       Sarat Uppalapati   Deleted generate_info_copy1        |
---|                                                         , we are not using anymore         |
---|    1.6             09-JUL-2008       Sarat Uppalapati   Defect# 8673                       |
---|    1.6             07-JUL-2008       Sarat Uppalapati   Defect# 8673                       |
---|    1.5             30-MAY-2008       Sarat Uppalapati   Modified Info file logic           |
---|    1.4             12-MAY-2008       Sarat Uppalapati   Added Info file logic              |
---|    1.3             04-APR-2008       Balaguru Seshadri  Defect 5615                        |
---|    1.2             31-MAR-2008       Balaguru Seshadri  Defect 5614/16                     |
---|    1.1             03-MAR-2008       Balaguru Seshadri  Defect 4974                        |
---|    1.0             07-AUG-2007       Petritia Sampath   Initial Version                    |
---+============================================================================================+ 

       G_PKG_NAME     VARCHAR2(30) :='XX_AR_GEN_EBILL';
       G_PKS_VERSION  NUMBER(2,1)  :='2.4';
       G_AS_OF_DATE   DATE;
       g_discount     NUMBER       :=0;
       g_misc_charges NUMBER       :=0;       
       g_delivery     NUMBER       :=0;
       g_coupon       NUMBER       :=0;              

       ln_write_off_amt_low  NUMBER  := FND_PROFILE.VALUE('OD_BILLING_WRITE_OFF_AMT_LOW');   --Added for the Defect# 631 (CR 662)
       ln_write_off_amt_high NUMBER  := FND_PROFILE.VALUE('OD_BILLING_WRITE_OFF_AMT_HIGH');  --Added for the Defect# 631 (CR 662)


FUNCTION get_warehouse_name(
                    p_warehouse_id IN NUMBER
                    ) RETURN VARCHAR2;
         
FUNCTION remove_special_char(ps_string VARCHAR2) RETURN VARCHAR2;   

function get_total_discount(p_trx_id in number) return number;

function get_total_misc_chrg(p_trx_id in number) return number;

function get_total_delivery(p_trx_id in number) return number;

function get_total_coupon(p_trx_id in number) return number;

function get_inv_totals(p_type in varchar2 ,p_inv_org in number ,p_trx_id in number) return number;

FUNCTION get_total_gc_chrg(p_trx_id IN NUMBER) RETURN NUMBER;                 -- Added for the R1.1 Defect # 1451 (CR 626)

--Below function is added for the R1.3 Defect # 2766 (CR 738)

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : Infocopies handling logic for INV_IC scenario                       |
-- | Description : This function will return 'Y' or 'N' depending upon whether the     |
-- |               infocopy can be sent or not                                         |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |1.0       01-Apr-10    Tamil Vendhan L      Initial Version                        |
-- +===================================================================================+
FUNCTION XX_AR_INFOCOPY_HANDLING (p_attr             IN VARCHAR2
                                 ,p_doc_term         IN VARCHAR2
                                 ,p_cut_off_date     IN DATE 
                                 ,p_eff_start_date   IN DATE
                                 ,p_as_of_date       IN DATE
                                 ) RETURN VARCHAR2;

-- End of changes for R1.3 CR 738 Defect 2766

TYPE HEADER_REC_TYPE IS RECORD(
    trx_number                    ar_invoice_header_v.trx_number%TYPE
  , billing_site_id               ar_cons_inv.site_use_id%TYPE
  , term_id                       ar_cons_inv.term_id%TYPE
  , cons_inv_id                   ar_cons_inv.cons_inv_id%TYPE
  , cons_billing_number           ar_cons_inv.cons_billing_number%TYPE
  , customer_trx_id               ar_invoice_header_v.customer_trx_id%TYPE
  , interface_header_attribute1   ar_invoice_header_v.interface_header_attribute1%TYPE
  , location                      hz_cust_site_uses.location%TYPE
  , phone_number                  hz_contact_points.phone_number%TYPE
  , invoice_currency_code         ar_invoice_header_v.invoice_currency_code%TYPE
  , orig_system_reference         hz_cust_accounts.orig_system_reference%TYPE
  , site_use_code                 hz_cust_site_uses.site_use_code%TYPE
  , purchase_order_number         ar_invoice_header_v.purchase_order_number%TYPE
  , bill_to_customer_number       ar_invoice_header_v.bill_to_customer_number%TYPE
  , cut_off_date                  ar_cons_inv.cut_off_date%TYPE
  , issue_date                    ar_cons_inv.issue_date%TYPE
  , bus_name                      ar_invoice_header_v.bill_to_customer_name%TYPE
  , due_date                      ar_cons_inv.due_date%TYPE
  , name                          ra_terms_tl.name%TYPE
  , interface_header_attribute2   ar_invoice_header_v.interface_header_attribute2%TYPE
  , tax_registration_number       ar_invoice_header_v.tax_registration_number%TYPE
  , primary_salesrep_name         ar_invoice_header_v.primary_salesrep_name%TYPE
  , ship_to_customer_name         ar_invoice_header_v.ship_to_customer_name%TYPE
  , ship_to_address1              ar_invoice_header_v.ship_to_address1%TYPE
  , ship_to_address2              ar_invoice_header_v.ship_to_address2%TYPE
  , ship_to_city                  ar_invoice_header_v.ship_to_city%TYPE
  , ship_to_state                 ar_invoice_header_v.ship_to_state%TYPE
  , ship_to_postal_code           ar_invoice_header_v.ship_to_postal_code%TYPE
  , ship_to_country               ar_invoice_header_v.ship_to_country%TYPE
  , ship_to_contact               VARCHAR2(50 BYTE)
  , trx_date                      ar_invoice_header_v.trx_date%TYPE
  , ship_to_location              ar_invoice_header_v.ship_to_location%TYPE
  , bill_to_name                  ar_invoice_header_v.bill_to_customer_name%TYPE
  , bill_to_location              ar_invoice_header_v.bill_to_location%TYPE
  , bill_to_address1              ar_invoice_header_v.bill_to_address1%TYPE
  , bill_to_address2              ar_invoice_header_v.bill_to_address2%TYPE
  , bill_to_city                  ar_invoice_header_v.bill_to_city%TYPE
  , bill_to_state                 ar_invoice_header_v.bill_to_state%TYPE
  , bill_to_postal_code           ar_invoice_header_v.bill_to_postal_code%TYPE
  , bill_to_country               ar_invoice_header_v.bill_to_country%TYPE
  , bill_to_attn                  ar_invoice_header_v.bill_to_attn%TYPE
  , org_id                        ar_invoice_header_v.org_id%TYPE
  , extension_id                  xx_cdh_a_ext_billdocs_v.extension_id%TYPE
  , customer_id                   ar_cons_inv.customer_id%TYPE
  , ordsourcecd                   ar_invoice_header_v.interface_header_attribute1%TYPE
  , specl_handlg_cd               xx_cdh_a_ext_billdocs_v.BILLDOCS_SPECIAL_HANDLING%TYPE
  , billing_term                  xx_cdh_a_ext_billdocs_v.billdocs_payment_term%TYPE
  , invoice_date                  ra_customer_trx_all.trx_date%TYPE
  , billing_id                    hz_cust_accounts.account_number%TYPE
  , billing_method                VARCHAR2 (15)                                                -- Added for R1.2 CR 466 Defect 1210
  , cust_doc_id                   NUMBER                                                       -- Added for R1.2 CR 466 Defect 1210
  , creation_date                 DATE                                                         -- Added for Defect# 4136
  );

  TYPE LINE_REC_TYPE IS RECORD(
    interface_line_attribute10    ar_invoice_lines_v.interface_line_attribute10%TYPE
  , cust_item_number              xx_om_line_attributes_all.cust_item_number%TYPE
  , item_description              ar_invoice_lines_v.item_description%TYPE
  , uom_code                      ar_invoice_lines_v.uom_code%TYPE
  , quantity_ordered              ar_invoice_lines_v.quantity_ordered%TYPE
  , quantity                      ar_invoice_lines_v.quantity%TYPE
  , backordered_qty               xx_om_line_attributes_all.backordered_qty%TYPE
  , unit_selling_price            ar_invoice_lines_v.unit_selling_price%TYPE
  , sku_list_price                xx_om_line_attributes_all.sku_list_price%TYPE
  , extended_amount               ar_invoice_lines_v.extended_amount%TYPE
  , vendor_product_code           xx_om_line_attributes_all.vendor_product_code%TYPE
  , taxable_flag                  xx_om_line_attributes_all.taxable_flag%TYPE
  , interface_line_attribute6     ar_invoice_lines_v.interface_line_attribute6%TYPE
  , contract_cd                   xx_om_line_attributes_all.contract_details%TYPE
  , contract_plan                 xx_om_line_attributes_all.contract_details%TYPE
  , contract_seq                  xx_om_line_attributes_all.contract_details%TYPE
  , item_number                   MTL_SYSTEM_ITEMS_B.SEGMENT1%TYPE
  , ordcompletedate               oe_order_lines.actual_shipment_date%TYPE
  , productcdentered              oe_order_lines.user_item_description%TYPE              
  , custpolinenbr                 oe_order_lines.customer_line_number%TYPE  
  , wholesaleprodcd               xx_om_line_attributes_all.wholesaler_item%TYPE
  , xxom_line_comments            xx_om_line_attributes_all.line_comments%TYPE
  , bill_level                    ar_invoice_lines_v.attribute3%TYPE     -- Added for Kitting, Defect# 37670
  , kit_item                      ar_invoice_lines_v.attribute4%TYPE     -- Added for Kitting, Defect# 37670
  );
  
 PROCEDURE generate_file (
      x_errbuf        OUT      VARCHAR2
     ,x_retcode       OUT      VARCHAR2
     ,p_file_path     IN       VARCHAR2
     ,p_as_of_date    IN       VARCHAR2 DEFAULT SYSDATE -- Defect 9077 
     ,p_cust_id_from  IN       NUMBER                            --Added as a part of the defect 1760
     ,p_cust_id_to    IN       NUMBER                             --Added as a part of the defect 1760

   );
   
 PROCEDURE generate_info_copy_file (
         p_file_handle   IN UTL_FILE.file_type
        ,p_last_line_seq IN NUMBER
        ,p_item_org      IN NUMBER
        ,p_current_OU    IN NUMBER
        ,p_US_OU         IN NUMBER
        ,p_CA_OU         IN NUMBER  
        ,p_tax_id        IN VARCHAR2
        ,p_status_code   OUT  VARCHAR2  --Added for the defect 12435
        ,p_error_msg     OUT  VARCHAR2  --Added for the defect 12435
        ,p_cust_id_from    IN   NUMBER     --Added for the defect 1760
        ,p_cust_id_to      IN   NUMBER     --Added for the defect 1760
        );   
      
--PROCEDURE generate_done_file; Commented for the defect 12435

-- Start of new procedure for defect 12468
PROCEDURE UPDATE_BPEL_STATUS( p_file_name           IN   VARCHAR2
                              ,x_return_status      OUT  VARCHAR2) ;
-- End of new  procedure for defect 12468

END XX_AR_GEN_EBILL_PKG;
/
SHOW ERRORS;
