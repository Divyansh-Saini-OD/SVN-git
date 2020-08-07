CREATE OR REPLACE PACKAGE xx_ar_cbi_calc_subtotals AS
---+========================================================================================================+
---|                                        Office Depot - Project Simplify                                 |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_ar_print_summbill.pkb                                            |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                    |
---|    ------------    ----------------- ---------------    ---------------------                          |
---|    1.0             08-MAY-2008       Balaguru Seshadri  Initial Version                                |
---|    1.1             28-JAN-2009       Sambasiva Reddy D  Changes for the CR 460 (Defect # 10750) to     |
---|                                                         handle mail to exceptions                      |
---|    1.2             25-FEB-2009       Sambasiva Reddy D  Changes for the Defect # 13403                 |
-- |    1.3             09-NOV-2009       Tamil Vendhan L    Modified for R1.2 Defect # 1283 (CR 621)       |
-- |    1.4             27-NOV-2009       Tamil Vendhan L    Modified for R1.2 CR 743 Defect 1744           |
-- |    1.5             15-DEC-2015       Suresh Naragam     Mod 4B Release 3 Changes(Defect#36434)         |
-- |    1.6             10-MAY-2016       Havish Kasina      Kitting changes, Defect# 37670                 |
---+========================================================================================================+

/*
  Use these variables to get default soft headers.
*/

  lc_def_cust_title      VARCHAR2(20) :=''''||'Customer :'||''''; 
  lc_def_ship_title      VARCHAR2(20) :=''''||'SHIP TO ID :'||'''';
  lc_def_pohd_title      VARCHAR2(20) :=''''||'Purchase Order :'||'''';
  lc_def_rele_title      VARCHAR2(20) :=''''||'Release :'||'''';
--  lc_def_dept_title      VARCHAR2(20) :=''''||'Department :'||'''';         -- Commented for R1.2 Defect # 1283 (CR 621)
  lc_def_dept_title      VARCHAR2(20) :=''''||'Cost Center :'||'''';          -- Added for R1.2 Defect # 1283 (CR 621)
--  lc_def_desk_title      VARCHAR2(20) :=''''||'Desk Top :'||'''';           -- Commented for R1.2 Defect # 1283 (CR 621)
  lc_def_desk_title      VARCHAR2(20) :=''''||'Desktop :'||'''';              -- Added for R1.2 Defect # 1283 (CR 621)
  lc_US_tax_code         VARCHAR2(20) :=TO_CHAR(NULL);
  lc_CA_prov_tax_code    VARCHAR2(20) :=TO_CHAR(NULL);
  lc_CA_state_tax_code   VARCHAR2(20) :=TO_CHAR(NULL);  
  ln_US_tax_amount       NUMBER :=0;
  ln_CA_prov_tax_amount  NUMBER :=0;
  ln_CA_state_tax_amount NUMBER :=0;
  lv_enter VARCHAR2(1):='
';  

-- =====================   
-- Record Type
-- =====================   

TYPE trx_rec IS RECORD
  (
    sfdata1         VARCHAR2(60)
   ,sfdata2         VARCHAR2(60)
   ,sfdata3         VARCHAR2(60)
   ,sfdata4         VARCHAR2(60)
   ,sfdata5         VARCHAR2(60)
   ,sfdata6         VARCHAR2(60)
   ,sfhdr1          VARCHAR2(30)
   ,sfhdr2          VARCHAR2(30)
   ,sfhdr3          VARCHAR2(30)
   ,sfhdr4          VARCHAR2(30)
   ,sfhdr5          VARCHAR2(30)
   ,sfhdr6          VARCHAR2(30)
   ,customer_trx_id NUMBER
   ,order_header_id NUMBER 
   ,inv_source_id   NUMBER
   ,inv_number      VARCHAR2(20)
   ,inv_type        VARCHAR2(20)
   ,inv_source      VARCHAR2(30)
   ,order_date      DATE
   ,ship_date       DATE
   ,order_subtotal  NUMBER
   ,delvy_charges   NUMBER
   ,order_discount  NUMBER
   ,order_tax       NUMBER   
  );

FUNCTION get_ORDER_by_sql(
                        p_sort_order   IN VARCHAR2
                       ,p_HZtbl_alias  IN VARCHAR2
                       ,p_INVtbl_alias IN VARCHAR2
                       ,p_OMtbl_alias  IN VARCHAR2
                       ,p_SITE_alias   IN VARCHAR2
                      ) RETURN VARCHAR2;  
                      
FUNCTION get_infocopy_SQL(
                     p_sort_order   IN VARCHAR2
                    ,p_HZtbl_alias  IN VARCHAR2
                    ,p_INVtbl_alias IN VARCHAR2
                    ,p_OMtbl_alias  IN VARCHAR2
                    ,p_SITE_alias   IN VARCHAR2
                    ,p_template     IN VARCHAR2
                   ) RETURN VARCHAR2;                      

FUNCTION get_SORT_by_sql(
                     p_sort_order   IN VARCHAR2
                    ,p_HZtbl_alias  IN VARCHAR2
                    ,p_INVtbl_alias IN VARCHAR2
                    ,p_OMtbl_alias  IN VARCHAR2
                    ,p_SITE_alias   IN VARCHAR2
                    ,p_template     IN VARCHAR2
                   ) RETURN VARCHAR2;
                   
PROCEDURE get_invoices(
                       p_req_id          IN NUMBER
                      ,p_cbi_id          IN NUMBER
                      ,p_cbi_amt         IN NUMBER
                      ,p_province        IN VARCHAR2
                      ,p_sort_by         IN VARCHAR2
                      ,p_total_by        IN VARCHAR2
                      ,p_page_by         IN VARCHAR2
                      ,p_template        IN VARCHAR2
                      ,p_doc_type        IN VARCHAR2     
                      ,p_cbi_num         IN VARCHAR2
                      ,p_item_master_org IN NUMBER
                      ,p_site_use_id       IN   NUMBER  --Added for the Defect # 10750
                      ,p_document_id       IN   NUMBER  --Added for the Defect # 10750
                      ,p_cust_doc_id       IN   NUMBER  --Added for the Defect # 10750
                      ,p_direct_flag       IN   VARCHAR2  --Added for the Defect # 10750
                      ,p_cbi_id1           IN   VARCHAR2  -- Added for the Defect # 13403
                      );

PROCEDURE insert_invoices
                         (
                           p_sfdata1    IN VARCHAR2
                          ,p_sfdata2    IN VARCHAR2
                          ,p_sfdata3    IN VARCHAR2
                          ,p_sfdata4    IN VARCHAR2
                          ,p_sfdata5    IN VARCHAR2
                          ,p_sfdata6    IN VARCHAR2
                          ,p_sfhdr1     IN VARCHAR2
                          ,p_sfhdr2     IN VARCHAR2
                          ,p_sfhdr3     IN VARCHAR2
                          ,p_sfhdr4     IN VARCHAR2
                          ,p_sfhdr5     IN VARCHAR2
                          ,p_sfhdr6     IN VARCHAR2
                          ,p_inv_id     IN NUMBER                          
                          ,p_ord_id     IN NUMBER
                          ,p_src_id     IN NUMBER                          
                          ,p_inv_num    IN VARCHAR2
                          ,p_inv_type   IN VARCHAR2
                          ,p_inv_src    IN VARCHAR2
                          ,p_ord_dt     IN DATE
                          ,p_ship_dt    IN DATE
                          ,p_cons_id    IN NUMBER
                          ,p_reqs_id    IN NUMBER 
                          ,p_subtot     IN NUMBER
                          ,p_delvy      IN NUMBER
                          ,p_disc       IN NUMBER
                          ,p_US_tax_amt IN NUMBER
                          ,p_CA_gst_amt IN NUMBER  
                          ,p_CA_tax_amt IN NUMBER                          
                          ,p_US_tax_id  IN VARCHAR2                          
                          ,p_CA_gst_id  IN VARCHAR2                                                  
                          ,p_CA_prov_id IN VARCHAR2
                          ,p_insert_seq IN NUMBER  
                          ,p_doc_tag    IN VARCHAR2
                         );
                         
PROCEDURE insert_invoice_lines
                (
                  p_reqs_id               IN NUMBER
                 ,p_cons_id               IN NUMBER
                 ,p_inv_id                IN NUMBER
                 ,p_line_seq              IN NUMBER
                 ,p_item_code             IN VARCHAR2
                 ,p_customer_product_code IN VARCHAR2
                 ,p_item_description      IN VARCHAR2
                 ,p_manuf_code            IN VARCHAR2
                 ,p_qty                   IN NUMBER
                 ,p_uom                   IN VARCHAR2
                 ,p_unit_price            IN NUMBER
                 ,p_extended_price        IN NUMBER
                 ,p_line_comments         IN VARCHAR2                  -- Added for R1.2 Defect 1744 (CR 743)
                 ,p_cost_center_dept      IN VARCHAR2
                 ,p_cust_dept_description IN VARCHAR2
				 ,p_kit_sku               IN VARCHAR2  -- Added for Kitting, Defect# 37670
                );

PROCEDURE copy_totals
                (
                  p_reqs_id  IN NUMBER
                 ,p_cons_id  IN NUMBER
                 ,p_inv_id   IN NUMBER
                 ,p_linetype IN VARCHAR2
                 ,p_line_seq IN NUMBER
                 ,p_trx_num  IN VARCHAR2
                 ,p_sftext   IN VARCHAR2
                 ,p_sfamount IN NUMBER
                 ,p_page_brk IN VARCHAR2
                 ,p_ord_count IN NUMBER
                );
                
PROCEDURE copy_SUMM_ONE_totals
                (
                  p_reqs_id    IN NUMBER
                 ,p_cons_id    IN NUMBER
                 ,p_inv_id     IN NUMBER
                 ,p_inv_num    IN VARCHAR2 
                 ,p_line_seq   IN NUMBER
                 ,p_total_type IN VARCHAR2
                 ,p_inv_source IN VARCHAR2
                 ,p_subtotl    IN NUMBER
                 ,p_delvy      IN NUMBER
                 ,p_discounts  IN NUMBER
                 ,p_tax        IN NUMBER
                 ,p_page_brk   IN VARCHAR2
                 ,p_ord_count  IN NUMBER
                 ,p_doc_type   IN VARCHAR2
                );                
                
FUNCTION get_line_seq RETURN NUMBER;                

FUNCTION get_CA_prov_tax(p_trx_id IN NUMBER) RETURN NUMBER;

FUNCTION get_CA_state_tax(p_trx_id IN NUMBER) RETURN NUMBER;

PROCEDURE generate_DETAIL_subtotals 
           (
             pn_number_of_soft_headers IN NUMBER
            ,p_billing_id              IN VARCHAR2
            ,p_cons_id                 IN NUMBER 
            ,p_reqs_id                 IN NUMBER 
            ,p_total_by                IN VARCHAR2
            ,p_page_by                 IN VARCHAR2
            ,p_doc_type                IN VARCHAR2
           );
           
PROCEDURE generate_SUMM_ONE_subtotals 
           (
             pn_number_of_soft_headers IN NUMBER
            ,p_billing_id              IN VARCHAR2
            ,p_cons_id                 IN NUMBER 
            ,p_reqs_id                 IN NUMBER 
            ,p_total_by                IN VARCHAR2
            ,p_page_by                 IN VARCHAR2
            ,p_doc_type                IN VARCHAR2            
           );           

/* The function is added as part of CR 460 to get the where clause 'AND' condition
   after considering new mailing address site use id for the scenerio'PAYDOC_IC'
   for the Defect # 10750 */

   FUNCTION get_where_condition_paydoc_ic(p_site_use_id   NUMBER
                                         ,p_document_id   NUMBER
                                         ,p_cust_doc_id   NUMBER
                                         ,p_direct_flag   VARCHAR2
                                         ,p_cons_inv_id   NUMBER)
   RETURN VARCHAR2;

END xx_ar_cbi_calc_subtotals;
/
SHOW ERRORS;