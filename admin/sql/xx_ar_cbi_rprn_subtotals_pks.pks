CREATE OR REPLACE PACKAGE xx_ar_cbi_rprn_subtotals AS
---+========================================================================================================+
---|                                        Office Depot - Project Simplify                                 |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :      xx_ar_cbi_rprn_subtotals                                             |
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
-- |    1.1             09-NOV-2009       Tamil Vendhan L    Modified for R1.2 Defect # 1283 (CR 621)       |
-- |    1.2             26-NOV-2009       Tamil Vendhan L    Modified for R1.2 Defect # 1744 (CR 743)       |
-- |    1.3             25-DEC-2009       Gokila Tamilselvam Modified for R1.2 Defect # 1210 (CR 466)       |
-- |    1.4             19-MAY-2010       Gokila Tamilselvam Modified for R 1.4 CR 586.                     |
-- |    1.5             14-DEC-2015       Havish Kasina      Modified code to display Line level cost center|
-- |                                                         code and cost center description Defect #36434 |
-- |                                                         (Module 4B Release 3)                          |
-- |    1.6             11-MAY-2015       Havish Kasina      Added a new parameter to insert_invoice_lines  |
-- |                                                         procedure as part of Kitting changes           |
-- |                                                         Defect# 37670                                  | 
---+========================================================================================================+

/*
  Use these variables to get default soft headers.
*/
  lc_def_cust_title      VARCHAR2(20) :=''''||'Customer :'||'''';
  lc_def_ship_title      VARCHAR2(20) :=''''||'SHIP TO ID :'||'''';
  lc_def_pohd_title      VARCHAR2(20) :=''''||'Purchase Order :'||'''';
  lc_def_rele_title      VARCHAR2(20) :=''''||'Release :'||'''';
--  lc_def_dept_title      VARCHAR2(20) :=''''||'Department :'||'''';                -- Commented for R1.2 Defect # 1283 (CR 621)
  lc_def_dept_title      VARCHAR2(20) :=''''||'Cost Center :'||'''';                 -- Added for R1.2 Defect # 1283 (CR 621)
--  lc_def_desk_title      VARCHAR2(20) :=''''||'Desk Top :'||'''';                  -- Commented for R1.2 Defect # 1283 (CR 621)
  lc_def_desk_title      VARCHAR2(20) :=''''||'Desktop :'||'''';                     -- Added for R1.2 Defect # 1283 (CR 621)
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
    sfdata1         VARCHAR2(120)
   ,sfdata2         VARCHAR2(120)
   ,sfdata3         VARCHAR2(120)
   ,sfdata4         VARCHAR2(120)
   ,sfdata5         VARCHAR2(120)
   ,sfdata6         VARCHAR2(120)
   ,sfhdr1          VARCHAR2(60)
   ,sfhdr2          VARCHAR2(60)
   ,sfhdr3          VARCHAR2(60)
   ,sfhdr4          VARCHAR2(60)
   ,sfhdr5          VARCHAR2(60)
   ,sfhdr6          VARCHAR2(60)
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
		       ,p_sort_by      IN VARCHAR2 DEFAULT ''
                      ) RETURN VARCHAR2;

FUNCTION get_infocopy_SQL(
                     p_sort_order      IN VARCHAR2
                    ,p_HZtbl_alias     IN VARCHAR2
                    ,p_INVtbl_alias    IN VARCHAR2
                    ,p_OMtbl_alias     IN VARCHAR2
                    ,p_SITE_alias      IN VARCHAR2
                    ,p_template        IN VARCHAR2
                    ,p_virtual_flag    IN VARCHAR2
                   ) RETURN VARCHAR2;

FUNCTION get_SORT_by_sql(
                     p_sort_order      IN VARCHAR2
                    ,p_HZtbl_alias     IN VARCHAR2
                    ,p_INVtbl_alias    IN VARCHAR2
                    ,p_OMtbl_alias     IN VARCHAR2
                    ,p_SITE_alias      IN VARCHAR2
                    ,p_template        IN VARCHAR2
                   ) RETURN VARCHAR2;

PROCEDURE get_invoices(
                       p_req_id            IN NUMBER
                      ,p_cbi_id            IN NUMBER
                      ,p_cbi_amt           IN NUMBER
                      ,p_province          IN VARCHAR2
                      ,p_sort_by           IN VARCHAR2
                      ,p_total_by          IN VARCHAR2
                      ,p_page_by           IN VARCHAR2
                      ,p_template          IN VARCHAR2
                      ,p_doc_type          IN VARCHAR2
                      ,p_cbi_num           IN VARCHAR2
                      ,p_site_use_id       IN NUMBER    -- Added for R1.2 Defect# 1210 CR# 466.
                      ,p_virtual_flag      IN VARCHAR2  -- Added for R1.2 Defect# 1210 CR# 466.
                      ,p_cust_doc_id       IN NUMBER    -- Added for R1.2 Defect# 1210 CR# 466.
                      ,p_cbi_id1           IN NUMBER    -- Added for R1.2 Defect# 1210 CR# 466.
                      ,p_ebill_ind         IN VARCHAR2  -- Added for R1.4 CR# 586.
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
                          ,p_cbi_num     IN VARCHAR2        -- Added for R1.2 Defect# 1210 CR# 466.
                          ,p_site_use_id IN NUMBER          -- Added for R1.2 Defect# 1210 CR# 466.
                          ,p_cbi_id1     IN NUMBER          -- Added for R1.2 Defect# 1210 CR# 466.
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
                 ,p_line_comments         IN VARCHAR2                     --Added for R1.2 Defect 1744 (CR 743)
				 ,p_cost_center_dept      IN VARCHAR2       -- Added for Defect 36434
				 ,p_cost_center_desc      IN VARCHAR2       -- Added for Defect 36434
				 ,p_kit_sku               IN VARCHAR2       -- Added for Kitting, Defect# 37670 
                );

PROCEDURE insert_rprn_rows
                (
                  p_reqs_id      IN NUMBER
                 ,p_cons_id      IN NUMBER
                 ,p_line_type    IN VARCHAR2
                 ,p_line_seq     IN NUMBER
                 ,p_sf_text      IN VARCHAR2
                 ,p_pg_brk       IN VARCHAR2
                 ,p_ordnum_attr1 IN VARCHAR2
                 ,p_ord_dt_attr2 IN VARCHAR2
                 ,p_subtotal     IN VARCHAR2
                 ,p_delivery     IN VARCHAR2
                 ,p_discounts    IN VARCHAR2
                 ,p_tax          IN VARCHAR2
                 ,p_total        IN VARCHAR2
                 ,p_sf_data1     IN VARCHAR2
                 ,p_sf_data2     IN VARCHAR2
                 ,p_sf_data3     IN VARCHAR2
                 ,p_sf_data4     IN VARCHAR2
                 ,p_sf_data5     IN VARCHAR2
                 ,p_invoice_id   IN NUMBER
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
                 ,p_prov_tax  IN VARCHAR2
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
                );

FUNCTION get_line_seq RETURN NUMBER;

FUNCTION get_rprn_seq RETURN NUMBER;

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
            ,p_province                IN VARCHAR2
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
            ,p_province                IN VARCHAR2
           );

END xx_ar_cbi_rprn_subtotals;
/
SHOW ERRORS;