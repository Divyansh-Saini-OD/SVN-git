CREATE OR REPLACE PACKAGE BODY XX_AR_CREATE_ACCT_CHILD_PKG
AS
   -- +=====================================================================================+
   -- |                  Office Depot - Project Simplify                    				|
   -- |                       WIPRO Technologies                            				|
   -- +=====================================================================================+
   -- | Name       : XX_AR_CREATE_ACCT_CHILD_PKG                            				|
   -- | RICE ID    : E0080                                                  				|
   -- | Description: Child package to extend the existing Oracle process    				|
   -- |              of creating accounting segments based on the           				|
   -- |              business rules of office depot                         				|
   -- |                                                                     				|
   -- |Change Record:                                                       				|
   -- |===============                                                      				|
   -- |Version    Date         Author         Remarks                       				|
   -- |=========  ===========  =============  ============================= 				|
   -- |1.0 - 3.2  Various      Various        See Code revision #?????      				|
   -- |                                                                     				|
   -- |3.3        27-MAR-2011                 R11.3 - Summarization of      				|
   -- |                                       POS invoices                  				|
   -- |3.4        22-JUL-2011  Peter Marco    Defect 12725                  				|
   -- |3.5        16-SEP-2011  Abdul Khan     Defect 13438                  				|
   -- |3.6        25-JUN-2012  Jay Gupta      defect 13153 using hint       				|
   -- |4.0        24-OCT-2012  R.Aldridge     Defect 20687 - Enable batch   				|
   -- |                                       group processing              				|
   -- |4.1	  	  04-JUL-2013  Manasa         E0080 -R12 Upgrade Retrofit   				|
   -- |                                       changes                       				|
   -- |4.2        11-Sep-2013  Manasa         E0080 - Changed the approach  				|
   -- |                                       to update the tax columns     				|
   -- |4.3        16-SEP-2013  Manasa         E0080 - R12 Upgrade change    				|
   -- |                                       to set taxable_flag to 'N'    				|
   -- |4.4        10-DEC-2013  Deepak V       Changes for R12 retrofit.     				|
   -- |                                       AR_VAT_TAX_ALL is now obsolete				|
   -- |                                       in R12, hence replaced by     				|
   -- |                                       zx_rates_b. QC Defect : 26781 				|
   -- |4.5        11-Feb-2014  Avinash B      For defect 27985		        				|
   -- |4.6        23-Jul-2015  Madhan Sanjeevi Defect# 35156                				|
   -- |If condition included for FND_LOG messages inserted for R12 Retrofit 				|
   -- |4.7        21-OCT-2015  Vasu Raparla   Removed Schema References     				|
   -- |4.8        02-MAR-2016  Arun Gannarapu Defect# 2072/37352 rebates location 			|
   -- |                                        issue                        				|
   -- |4.9        13-Jun-2016  Arun Gannarapu Made changes for Kitting 37676 				|
   -- |5.0        26-JUL-2016  Arun Gannarapu Made changes fix the defect 2381 				|
   -- |5.1        11-JAN-2018  Atul Khard     Made changes for Defect 43851 				|
   -- |5.2        05-NOV-2018  Dinesh N       Made Changes for Bill Complete NAIT-67165 	|
   -- |5.3        02-JAN-2019  Havish K       Made Changes for Defect NAIT-75351            |
   -- |5.4		  04-APR-2019  Dinesh N		  Made Changes for Defect NAIT-86554			|
   -- +=====================================================================================+

   ------------------------
   -- GLOBAL VARIABLES   --
   ------------------------
   gn_msg_cnt                   NUMBER := 1;
   gt_tbl_ora_segments          FND_FLEX_EXT.SEGMENTARRAY;
   gn_user_id                   NUMBER;
   gn_resp_id                   NUMBER;
   gn_resp_appl_id              NUMBER;
   gn_request_id                NUMBER;

   gc_ou_name                   hr_operating_units.name%TYPE;
   gc_country_value             VARCHAR2(2);
   gc_sob_name                  VARCHAR2(240);
   gn_sob_id                    gl_ledgers.ledger_id%TYPE;					-- Changed for R12 Retrofit gl_sets_of_books.set_of_books_id%TYPE;
   gn_coa_id                    gl_ledgers.chart_of_accounts_id%TYPE;	-- Changed for R12 Retrofit gl_sets_of_books.chart_of_accounts_id%TYPE;

   gc_line_type_LINE_hc        ra_interface_lines_all.line_type%TYPE := 'LINE';
   gc_line_type_TAX_hc         ra_interface_lines_all.line_type%TYPE := 'TAX';
   gc_tax_type_GST_hc          ra_interface_lines_all.interface_line_attribute9%TYPE := 'GST';
   gc_tax_type_PST_hc          ra_interface_lines_all.interface_line_attribute9%TYPE := 'PST';
   gc_order_source_spc         oe_order_sources.name%TYPE := 'SPC';
   gc_ln_orgid                 VARCHAR2(30) := FND_PROFILE.VALUE('ORG_ID');  --Added for Defect # 43851
   gn_ln_loginid               NUMBER	    := fnd_profile.VALUE('LOGIN_ID'); --Added for Bill Complete NAIT-67165
   gn_bill_date				   NUMBER;

   --------------------------------------
   --Added for R12 Retrofit for tax lines
   ---------------------------------------
   --US
   gc_tax_rate_code            zx_rates_b.tax_rate_code%TYPE     := 'SALES';
   gc_tax_rate_code1           zx_rates_b.tax_rate_code%TYPE     := 'SALES1';
   gc_tax_line1                zx_rates_b.tax%TYPE               := 'SALES_TAX1';
   gc_tax_line2                zx_rates_b.tax%TYPE               := 'SALES_TAX2';
   --CANADA
   gc_tax_rate_county          zx_rates_b.tax_rate_code%TYPE     := 'COUNTY';
   gc_tax_rate_state           zx_rates_b.tax_rate_code%TYPE     := 'STATE';
   gc_tax_regime_code_ca       zx_rates_b.tax_regime_code%TYPE   := 'OD_CA_SALES_TAX';
   gc_tax_code_county          zx_rates_b.tax_rate_code%TYPE     := 'COUNTY';
   gc_tax_code_state           zx_rates_b.tax_rate_code%TYPE     := 'STATE';
   --US
   gc_tax_regime_code_us       zx_rates_b.tax_regime_code%TYPE;
   gc_tax_status_code_us       zx_rates_b.tax_status_code%TYPE;
   gc_tax_regime_code_us1      zx_rates_b.tax_regime_code%TYPE;
   gc_tax_status_code_us1      zx_rates_b.tax_status_code%TYPE;
   gc_rate_percent             zx_rates_b.percentage_rate%TYPE;
   gc_rate_percent1            zx_rates_b.percentage_rate%TYPE;
   --CANADA
   gc_tax_status_code_ca       zx_rates_b.tax_status_code%TYPE;
   gc_tax_status_code_ca1      zx_rates_b.tax_status_code%TYPE;
   gc_tax_county               zx_rates_b.tax%TYPE;
   gc_tax_state                zx_rates_b.tax%TYPE;
   gc_rate_percent_state       zx_rates_b.percentage_rate%TYPE;
   gc_rate_percent_county      zx_rates_b.percentage_rate%TYPE;


   -- +=====================================================================+
   -- |                  Office Depot - Project Simplify                    |
   -- |                       WIPRO Technologies                            |
   -- | Name : XX_AR_CREATE_ACCT_CHILD_PROC                                 |
   -- +=====================================================================+
   -- | Description : proceudure to extend the existing Oracle process      |
   -- |               of  creating accounting segments based on the         |
   -- |               business rules of office depot                        |
   -- |                                                                     |
   -- | Parameters : x_err_buff          =>                                 |
   -- |              x_ret_code          =>                                 |
   -- |              p_run_flag          =>                                 |
   -- |              p_email_address     =>                                 |
   -- |              p_sales_order_low   =>                                 |
   -- |              p_sales_order_high  =>                                 |
   -- |              p_display_log       =>                                 |
   -- |              p_invoice_source    =>                                 |
   -- |              p_default_date      =>                                 |
   -- |              p_error_message     =>                                 |
   -- |              p_request_id        => post updates used only for      |
   -- |                                     updating int Status to NULL     |
   -- |                                                                     |
   -- | Returns   : x_error_buff, x_ret_code                                |
   -- +=====================================================================+
   PROCEDURE XX_AR_CREATE_ACCT_CHILD_PROC(
                              x_err_buff         OUT   VARCHAR2
                             ,x_ret_code         OUT   NUMBER
                             ,p_org_id           IN    NUMBER
                             ,p_run_flag         IN    VARCHAR2   DEFAULT 'B'
                             ,p_email_address    IN    VARCHAR2   DEFAULT NULL
                             ,p_sales_order_low  IN    VARCHAR2
                             ,p_sales_order_high IN    VARCHAR2
                             ,p_display_log      IN    VARCHAR2   DEFAULT 'N'
                             ,p_batch_group      IN    VARCHAR2   DEFAULT NULL -- Defect 20687 V4.0
                             ,p_invoice_source   IN    VARCHAR2   DEFAULT NULL
                             ,p_default_date     IN    VARCHAR2
                             ,p_error_message    IN    VARCHAR2   DEFAULT 'N'
                             ,p_request_id       IN    NUMBER )
   AS
      ------------------------
      -- LOCAL VARIABLES    --
      ------------------------

      -- Variables used for translation values obtained for batch source, attribute category, etc.
      lc_batch_source_prefix    xx_fin_translatevalues.source_value1%TYPE;
      lc_attribute_category     xx_fin_translatevalues.target_value1%TYPE;
      lc_trans_batch_name       xx_fin_translatevalues.source_value1%TYPE;
      ln_display_err_cnt        NUMBER;

      -- Record Type Defination based on some columns of the RA_INTERFACE_LINES_ALL table.
      TYPE ra_interface_lines_rec_type IS RECORD (
            ROWID                           VARCHAR2(255)
           ,currency_code                   ra_interface_lines_all.currency_code%TYPE
           ,cust_trx_type_id                ra_interface_lines_all.cust_trx_type_id%TYPE
           ,sales_order                     ra_interface_lines_all.sales_order%TYPE
           ,inventory_item_id               ra_interface_lines_all.inventory_item_id%TYPE
           ,accounting_rule_id              ra_interface_lines_all.accounting_rule_id%TYPE
           ,batch_source_name               ra_interface_lines_all.batch_source_name%TYPE
           ,warehouse_id                    ra_interface_lines_all.warehouse_id%TYPE
           ,sales_order_line                ra_interface_lines_all.sales_order_line%TYPE
           ,interface_line_id               ra_interface_lines_all.interface_line_id%TYPE
           ,interface_line_context          ra_interface_lines_all.interface_line_context%TYPE
           ,interface_line_attribute1       ra_interface_lines_all.interface_line_attribute1%TYPE
           ,interface_line_attribute2       ra_interface_lines_all.interface_line_attribute2%TYPE
           ,interface_line_attribute3       ra_interface_lines_all.interface_line_attribute3%TYPE
           ,interface_line_attribute4       ra_interface_lines_all.interface_line_attribute4%TYPE
           ,interface_line_attribute5       ra_interface_lines_all.interface_line_attribute5%TYPE
           ,interface_line_attribute6       ra_interface_lines_all.interface_line_attribute6%TYPE
           ,interface_line_attribute7       ra_interface_lines_all.interface_line_attribute7%TYPE
           ,interface_line_attribute8       ra_interface_lines_all.interface_line_attribute8%TYPE
           ,interface_line_attribute9       ra_interface_lines_all.interface_line_attribute9%TYPE
           ,interface_line_attribute10      ra_interface_lines_all.interface_line_attribute10%TYPE
           ,interface_line_attribute11      ra_interface_lines_all.interface_line_attribute11%TYPE
           ,interface_line_attribute12      ra_interface_lines_all.interface_line_attribute12%TYPE
           ,interface_line_attribute13      ra_interface_lines_all.interface_line_attribute13%TYPE
           ,interface_line_attribute14      ra_interface_lines_all.interface_line_attribute14%TYPE
           ,interface_line_attribute15      ra_interface_lines_all.interface_line_attribute15%TYPE
           ,orig_system_bill_customer_id    ra_interface_lines_all.orig_system_bill_customer_id%TYPE
           ,amount                          ra_interface_lines_all.amount%TYPE
           ,reference_line_id               ra_interface_lines_all.reference_line_id%TYPE
           ,attribute6                      ra_interface_lines_all.attribute6%TYPE
           ,attribute7                      ra_interface_lines_all.attribute7%TYPE
           ,attribute8                      ra_interface_lines_all.attribute8%TYPE
           ,attribute11                     ra_interface_lines_all.attribute11%TYPE
           ,credit_method_for_acct_rule     ra_interface_lines_all.credit_method_for_acct_rule%TYPE
           ,credit_method_for_installments  ra_interface_lines_all.credit_method_for_installments%TYPE
           ,purchase_order                  ra_interface_lines_all.purchase_order%TYPE
           ,reason_code                     ra_interface_lines_all.reason_code%TYPE
           ,fob_point                       ra_interface_lines_all.fob_point%TYPE
           ,term_id                         ra_interface_lines_all.term_id%TYPE
           ,description                     ra_interface_lines_all.description%TYPE
           ,header_attribute_category       ra_interface_lines_all.header_attribute_category%TYPE
           ,header_attribute1               ra_interface_lines_all.header_attribute1%TYPE
           ,header_attribute2               ra_interface_lines_all.header_attribute2%TYPE
           ,header_attribute3               ra_interface_lines_all.header_attribute3%TYPE
           ,header_attribute4               ra_interface_lines_all.header_attribute4%TYPE
           ,header_attribute5               ra_interface_lines_all.header_attribute5%TYPE
           ,header_attribute6               ra_interface_lines_all.header_attribute6%TYPE
           ,header_attribute7               ra_interface_lines_all.header_attribute7%TYPE
           ,header_attribute8               ra_interface_lines_all.header_attribute8%TYPE
           ,header_attribute9               ra_interface_lines_all.header_attribute9%TYPE
           ,header_attribute10              ra_interface_lines_all.header_attribute10%TYPE
           ,header_attribute11              ra_interface_lines_all.header_attribute11%TYPE
           ,header_attribute12              ra_interface_lines_all.header_attribute12%TYPE
           ,header_attribute13              ra_interface_lines_all.header_attribute13%TYPE
           ,header_attribute14              ra_interface_lines_all.header_attribute14%TYPE
           ,header_attribute15              ra_interface_lines_all.header_attribute15%TYPE
           ,quantity                        ra_interface_lines_all.quantity%TYPE
           ,Payment_set_id                  ra_interface_lines_all.Payment_set_id%TYPE
           ,line_type                       ra_interface_lines_all.line_type%TYPE
           ,ship_date_actual                ra_interface_lines_all.ship_date_actual%TYPE
           ,tax_code                        ra_interface_lines_all.tax_code%TYPE
           ,request_id                      ra_interface_lines_all.request_id%TYPE
           ,tax_rate                        ra_interface_lines_all.tax_rate%TYPE               			 --Added for R12 Retrofit to include new tax cols
           ,tax_regime_code                 ra_interface_lines_all.tax_regime_code%TYPE        			 --Added for R12 Retrofit to include new tax cols
           ,tax                             ra_interface_lines_all.tax%TYPE                    			 --Added for R12 Retrofit to include new tax cols
           ,tax_status_code                 ra_interface_lines_all.tax_status_code%TYPE        			 --Added for R12 Retrofit to include new tax cols
           ,tax_rate_code                   ra_interface_lines_all.tax_rate_code%TYPE          			 --Added for R12 Retrofit to include new tax cols
           ,line_number                     ra_interface_lines_all.line_number%TYPE            			 --Added for R12 Retrofit to include new tax cols
		   );

      --  Variables of the record type ra_interface_lines_rec_type
      lcu_process_interface_lines       ra_interface_lines_rec_type;

      --   Long Variable for the SELECT statement to be used in the REF CURSOR.
      lc_cursor_query            VARCHAR2(4000)
         := 'SELECT ROWID'
          ||',currency_code'
          ||',cust_trx_type_id'
          ||',sales_order'
          ||',inventory_item_id'
          ||',accounting_rule_id'
          ||',batch_source_name'
          ||',warehouse_id'
          ||',sales_order_line'
          ||',interface_line_id'
          ||',interface_line_context'
          ||',interface_line_attribute1'
          ||',interface_line_attribute2'
          ||',interface_line_attribute3'
          ||',interface_line_attribute4'
          ||',interface_line_attribute5'
          ||',interface_line_attribute6'
          ||',interface_line_attribute7'
          ||',interface_line_attribute8'
          ||',interface_line_attribute9'
          ||',interface_line_attribute10'
          ||',interface_line_attribute11'
          ||',interface_line_attribute12'
          ||',interface_line_attribute13'
          ||',interface_line_attribute14'
          ||',interface_line_attribute15'
          ||',orig_system_bill_customer_id'
		  ||',amount'
          ||',reference_line_id'
          ||',attribute6'
          ||',attribute7'
          ||',attribute8'
          ||',attribute11'
          ||',credit_method_for_acct_rule'
          ||',credit_method_for_installments'
          ||',purchase_order'
          ||',reason_code'
          ||',fob_point'
          ||',term_id'
          ||',description'
          ||',header_attribute_category'
          ||',header_attribute1'
          ||',header_attribute2'
          ||',header_attribute3'
          ||',header_attribute4'
          ||',header_attribute5'
          ||',header_attribute6'
          ||',header_attribute7'
          ||',header_attribute8'
          ||',header_attribute9'
          ||',header_attribute10'
          ||',header_attribute11'
          ||',header_attribute12'
          ||',header_attribute13'
          ||',header_attribute14'
          ||',header_attribute15'
          ||',quantity'
          ||',Payment_set_id'
          ||',line_type'
          ||',ship_date_actual'
          ||',tax_code'
          ||',request_id'
          ||',tax_rate'                                                 --Added for R12 Retrofit to include new tax cols
          ||',tax_regime_code'                                          --Added for R12 Retrofit to include new tax cols
          ||',tax'                                                      --Added for R12 Retrofit to include new tax cols
          ||',tax_status_code'                                          --Added for R12 Retrofit to include new tax cols
          ||',tax_rate_code'                                            --Added for R12 Retrofit to include new tax cols
          ||',line_number'                                              --Added for R12 Retrofit to include new tax cols
          ||' FROM ra_interface_lines_all ';

      -- Long Variable declaration to Build the WHERE clause in the REF CURSOR.
       lc_where_clause           VARCHAR2 (500) ;

      -- REF CURSOR Type Definition.
      TYPE t_interface_lines IS REF CURSOR;

      -- Defination of REF CURSOR Type Variable.
      c_interface_lines          t_interface_lines;

      --Added for R12 Retrofit
      --This cursor is used to derive the interface attribute cols to update tax colums
      CURSOR lcu_upd_tax_cols(p_sales_order        IN VARCHAR2,
                              p_batch_source_name  IN VARCHAR2)
      IS
         SELECT RILA.line_type
               ,RILA.sales_order
               ,RILA.interface_line_attribute2
           FROM ra_interface_lines_all     RILA
          WHERE RILA.org_id                       = FND_PROFILE.VALUE('ORG_ID')
            AND RILA.batch_source_name            = NVL(p_batch_source_name,RILA.batch_source_name)
            AND RILA.line_type                    = gc_line_type_TAX_hc
            AND RILA.sales_order                  = p_sales_order
          ORDER BY RILA.sales_order,ROWNUM;

      lc_interface_PREV  VARCHAR2(1000);
      lc_interface_CURR  VARCHAR2(1000);

      -- Local Variable Declaration
      lc_customer_type          hz_cust_accounts.attribute18%TYPE;				-- Changed for R12 Retrofit ar_customers_v.attribute18%TYPE;
      lc_trx_type               ra_interface_lines_all.CUST_TRX_TYPE_ID%TYPE;

      lc_line_type              ra_interface_lines_all.LINE_TYPE%TYPE;
      lc_description            ra_interface_lines_all.DESCRIPTION%TYPE;
      lc_exc_err                VARCHAR2(250);
      ln_no_tax_lines_RIL       NUMBER;

      ln_oloc                   gl_code_combinations.segment4%TYPE;
      lc_sloc                   gl_code_combinations.segment4%TYPE;
      lc_oloc_type              hr_lookups.meaning%TYPE;
      lc_sloc_type              hr_lookups.meaning%TYPE;

      ln_created_by_store_id    xx_om_header_attributes_all.created_by_store_id%TYPE;
      lc_order_type             xx_om_header_attributes_all.od_order_type%TYPE;
      lc_tax_state              VARCHAR2(2) := NULL;
      lc_delivery_code          xx_om_header_attributes_all.delivery_code%TYPE;
      lc_ship_from_state        hr_locations_all.REGION_1%TYPE;
      lc_ship_to_state          HZ_LOCATIONS.STATE%TYPE;

      lc_embed_ship_to_state    xx_om_header_attributes_all.ship_to_state%TYPE;

      lc_source_type_code       oe_order_lines_all.source_type_code%TYPE;
      ln_ship_from_org_id       oe_order_lines_all.ship_from_org_id%TYPE;
      ls_disc_description       ra_interface_lines_all.description%TYPE;
      lc_item_source            xx_om_line_attributes_all.item_source%TYPE;
      lc_dept                   mtl_item_categories_v.category_concat_segs%TYPE;
      lc_item                   mtl_system_items_b.segment1%TYPE;						-- Changed for R12 Retrofit mtl_system_items.segment1%TYPE;
      lc_item_type              mtl_system_items_fvl.item_type%TYPE;
      lc_coupon_code            oe_price_adjustments_v.attribute8%type;
      lc_coupon_owner           oe_price_adjustments_v.attribute9%type;
      lc_avg_cost               xx_om_line_attributes_all.average_cost%type;
      lc_cost_center_dept       xx_om_header_attributes_all.cost_center_dept%TYPE;
      lc_desk_del_addr          xx_om_header_attributes_all.desk_del_addr%TYPE;
      lc_contract_details       xx_om_line_attributes_all.contract_details%TYPE;
      lc_release_num            xx_om_line_attributes_all.release_num%TYPE;
      lc_consignment            xx_om_line_attributes_all.consignment_bank_code%TYPE;
      lc_actual_ship_date       oe_order_lines_all.actual_shipment_date%TYPE;
      ln_order_number           oe_order_headers_all.order_number%TYPE;
      ln_inventory_item_id      oe_order_lines_all.inventory_item_id%TYPE;
      ln_request_id             fnd_concurrent_requests.request_id%TYPE;
      --ln_ccid                   ar_vat_tax_all.tax_account_id%TYPE; Commented by for R12 Retrofit Defect 26781
	  ln_ccid					NUMBER;	-- Added for R12retrofit      
      ln_category_strucutre_id  mtl_item_categories_v.category_structure_id%TYPE;
      ln_mtl_org_id             mtl_parameters.master_organization_id%TYPE;
      lc_error_flag_val         VARCHAR2(1) := 'N';
      ln_sleep                  VARCHAR2(1) := 'N';
      ln_master_req_id          NUMBER :=0;
      ln_invoice_quantity       oe_order_lines_all.invoiced_quantity%TYPE;
      lc_order_type_mixed       VARCHAR2(1) := 'N';
      lc_mixed_credit           VARCHAR2(1) := 'N';
      lc_ret_org_order_num      xx_om_line_attributes_all.ret_orig_order_num%TYPE;
      ln_cust_trx_line_id       ra_customer_trx_lines_all.customer_trx_line_id%TYPE;
      ln_ret_ref_line_id        xx_om_line_attributes_all.ret_ref_line_id%TYPE;

      ln_interface_line_id      NUMBER := NULL;
      lc_error_msg              VARCHAR2(4000);
      lc_error_loc              VARCHAR2(2000);
      ln_count                  NUMBER := 0;
      ln_tot_count              NUMBER := 0;
      ln_total_count            NUMBER := 0; -- Added by Manovinayak on 22-JUL-08 for the defect#9040
      ln_rec_acct_count         NUMBER := 0;
      ln_rev_acct_count         NUMBER := 0;
      ln_tax_acct_count         NUMBER := 0; -- Added for Defect # 2569
      ln_err_count              NUMBER := 0;
      ln_err_order_count        NUMBER := 0;
      ln_req_id                 NUMBER;
      lc_prev_sales_order       ra_interface_lines_all.sales_order%TYPE := 0;
      lc_prev_currency          ra_interface_lines_all.currency_code%TYPE := 'N';
      lc_cogs_flag              ra_interface_distributions_all.attribute6%TYPE; --Added by Anusha for defect# 4129
      ln_translation_id         xx_fin_translatedefinition.translate_id%TYPE;
      ln_int_amount             NUMBER := 0;
      ln_dummysku_count         NUMBER := 0;
      lc_so_attribute           VARCHAR2(150);
      lc_mixed_updated          VARCHAR2(1) := 'N';
      lc_default_date           DATE;
      EX_SALES_ORDER            EXCEPTION;
      EX_SALES_TAX              EXCEPTION;                  /**** Defect 2569 ****/
      EX_XX_RA_INT_LINES        EXCEPTION;

      EX_XX_BATCH_NAME_ERR      EXCEPTION;
      -- lc_tax_line_insert       VARCHAR2(1) := 'Y';
      ln_orgid                  VARCHAR2(30) := FND_PROFILE.VALUE('ORG_ID');
      ln_master_organization_id mtl_parameters.master_organization_id%TYPE := 0; --Added by Mano for the defect#8895
      ln_category_set_id        mtl_category_sets.category_set_id%TYPE   := 0; --Added for the defect#8895 By Manovinayak

      -- Local Variable Declaration for translation matrix
      lc_sales_value1           xx_fin_translatevalues.target_value1%TYPE;
      lc_cogs_value2            xx_fin_translatevalues.target_value2%TYPE;
      lc_inv_value3             xx_fin_translatevalues.target_value3%TYPE;
      lc_cons_value4            xx_fin_translatevalues.target_value4%TYPE;
      lc_target_value4          xx_fin_translatevalues.target_value4%TYPE;
      lc_target_value5          xx_fin_translatevalues.target_value5%TYPE;
      lc_target_value6          xx_fin_translatevalues.target_value6%TYPE;
      lc_target_value7          xx_fin_translatevalues.target_value7%TYPE;
      lc_target_value8          xx_fin_translatevalues.target_value8%TYPE;
      lc_target_value9          xx_fin_translatevalues.target_value9%TYPE;
      lc_target_value10         xx_fin_translatevalues.target_value10%TYPE;
      lc_target_value11         xx_fin_translatevalues.target_value11%TYPE;
      lc_target_value12         xx_fin_translatevalues.target_value12%TYPE;
      lc_target_value13         xx_fin_translatevalues.target_value13%TYPE;
      lc_target_value14         xx_fin_translatevalues.target_value14%TYPE;
      lc_target_value15         xx_fin_translatevalues.target_value15%TYPE;
      lc_target_value16         xx_fin_translatevalues.target_value16%TYPE;
      lc_target_value17         xx_fin_translatevalues.target_value17%TYPE;
      lc_target_value18         xx_fin_translatevalues.target_value18%TYPE;
      lc_target_value19         xx_fin_translatevalues.target_value19%TYPE;
      lc_target_value20         xx_fin_translatevalues.target_value20%TYPE;
      lc_rev_cons_location      xx_fin_translatevalues.target_value5%TYPE;
      lc_trans_error_msg        VARCHAR2(4000);

      -- Local Variable Declaration for Segments
      lc_rev_company             gl_code_combinations.segment1%TYPE;
      lc_rev_costcenter          gl_code_combinations.segment1%TYPE;
      lc_rev_account             gl_code_combinations.segment1%TYPE;
      lc_rev_location            gl_code_combinations.segment1%TYPE;
      lc_rev_intercompany        gl_code_combinations.segment1%TYPE;
      lc_rev_lob                 gl_code_combinations.segment1%TYPE;
      lc_rev_future              gl_code_combinations.segment1%TYPE;
      ln_rev_ccid                NUMBER;

      lc_rec_company             gl_code_combinations.segment1%TYPE;
      lc_rec_costcenter          gl_code_combinations.segment1%TYPE;
      lc_rec_account             gl_code_combinations.segment1%TYPE;
      lc_rec_location            gl_code_combinations.segment1%TYPE;
      lc_rec_intercompany        gl_code_combinations.segment1%TYPE;
      lc_rec_lob                 gl_code_combinations.segment1%TYPE;
      lc_rec_future              gl_code_combinations.segment1%TYPE;
      ln_rec_ccid                NUMBER;

      lc_tax_company             gl_code_combinations.segment1%TYPE;
      lc_tax_costcenter          gl_code_combinations.segment1%TYPE;
      lc_tax_account             gl_code_combinations.segment1%TYPE;
      lc_tax_location            gl_code_combinations.segment1%TYPE;
      lc_tax_intercompany        gl_code_combinations.segment1%TYPE;
      lc_tax_lob                 gl_code_combinations.segment1%TYPE;
      lc_tax_future              gl_code_combinations.segment1%TYPE;
      ln_tax_ccid                NUMBER;
      ln_order_header_id         oe_order_headers_all.header_id%TYPE;
      ln_mixed_order_line_cnt    oe_order_lines_all.line_id%TYPE;
      ln_order_net_amount        ra_interface_lines_all.amount%TYPE;
      lc_orig_doc_ref            oe_order_headers_all.orig_sys_document_ref%TYPE;

      lc_oloc_company            gl_code_combinations.segment1%TYPE;
      lc_sloc_company            gl_code_combinations.segment1%TYPE;
      ln_code_combination_id     NUMBER;
      ln_cust_trx_id             NUMBER;
      lc_rev_segment1            VARCHAR2(25);
      lc_ccid_flag               VARCHAR2(1);
      lc_segments_concat         VARCHAR2(2000);
      ln_ora_tot_segments        NUMBER(1) :=7;
      lb_return_val              BOOLEAN;
      lc_gl_date                 VARCHAR2(240);
      ln_poe_order_source_id     NUMBER;
      ln_hed_order_source_id     NUMBER;
      ln_order_source_id         NUMBER;
      ln_pro_order_source_id     NUMBER;
      ln_spc_order_source_id     oe_order_sources.order_source_id%TYPE; -- Added for defect#2569-V-2.94
      lc_header_attribute15      ra_interface_lines_all.header_attribute15%TYPE; -- DEFECT 12227
      ln_summary_inv_line_cnt    NUMBER;
      ln_detail_inv_line_cnt     NUMBER;
      lc_pos_summary_flg         VARCHAR2(1);
	  lc_Bill_comp_flag          VARCHAR2(1);
	  lc_bill_comp_upd_flag		 VARCHAR2(1) := 'N';	  
	  ln_bill_comp_ln_cnt		 NUMBER := 0;
	  ln_bill_comp_cnt			 NUMBER := 0;
      ln_ra_rows_ins_cnt         NUMBER := 0;
      ln_ra_rows_del_cnt         NUMBER := 0;
      ln_ra_rows_ins_int_cnt     NUMBER := 0;
      ln_ra_rows_del_int_cnt     NUMBER := 0;
      ln_ra_rows_ins_int_cnt_gt  NUMBER := 0;
      ln_ra_rows_del_int_cnt_gt  NUMBER := 0;
      ln_ra_rows_ins_dist_cnt    NUMBER := 0;
      ln_ra_rows_del_dist_cnt    NUMBER := 0;
      ln_ra_rows_ins_dist_cnt_gt NUMBER := 0;
      ln_ra_rows_del_dist_cnt_gt NUMBER := 0;
      ln_ra_rows_del_sales_cnt   NUMBER := 0;
      ln_ra_rows_del_sales_cnt_gt NUMBER := 0;
	  ln_site_use_id			 oe_order_headers_all.invoice_to_org_id%TYPE;					-- Added for Bill Complete NAIT-67165
      lc_prev_order			     VARCHAR2(50):='1';	                                            -- Added for Bill Complete NAIT-67165
	  lc_parent_order_num	   xx_om_header_attributes_all.parent_order_num%TYPE := NULL;		-- Added for Bill Complete NAIT-67165
      lc_kit_sku               ra_interface_lines_all.attribute6%TYPE := NULL;
      lc_bill_level            ra_interface_lines_all.attribute6%TYPE := NULL;
      lc_kit_parent            ra_interface_lines_all.attribute6%TYPE := NULL;
	  ln_orig_sysref_len		 	NUMBER := 0;
	  ln_trx_num_len			 	NUMBER := 0;
	  ln_bill_comp_check_count 		NUMBER := 0;
	  lc_bc_spc_flag			 	VARCHAR2(1);


      lc_err_location            VARCHAR2(250);

      ----------------------------------------------------------
      -- Cursor to delete POS summerized invoices from RA tables
      -- and insert into the XX tables
      ----------------------------------------------------------
      CURSOR lcu_pos_inv
      IS
         SELECT  DISTINCT INTERFACE_LINE_ATTRIBUTE1
            FROM RA_INTERFACE_LINES_ALL RI
           WHERE RI.request_id    = gn_request_id
             AND RI.batch_source_name = lc_trans_batch_name
             AND EXISTS (SELECT *
                           FROM XX_AR_INTSTORECUST_OTC OTC
                          WHERE RI.orig_system_bill_customer_id = OTC.cust_account_id)
             AND interface_status is null;


      ------------------------------------------------------------
      -- Cursor to find exception POS invoices. Invoices that have
      -- trx_date or ccid null will be updated to a interface_status X.
      -- If distribution line do not exist for given ra_interface_line_
      -- attribute1 the interface_status will be updated to X
      ----------------------------------------------------------
      CURSOR lcu_pos_exp_inv
          IS
        SELECT DISTINCT RI.INTERFACE_LINE_ATTRIBUTE1
          FROM RA_INTERFACE_LINES_ALL RI
         WHERE RI.request_id           =  gn_request_id
           AND RI.TRX_DATE  is NULL
        UNION
        SELECT DISTINCT rid.INTERFACE_LINE_ATTRIBUTE1
          FROM ra_interface_distributions_all RID
         WHERE RId.request_id          = gn_request_id
           AND RID.CODE_COMBINATION_ID is NULL
        UNION
        SELECT DISTINCT RI.INTERFACE_LINE_ATTRIBUTE1
          FROM RA_INTERFACE_LINES_ALL RI
         WHERE RI.request_id    = gn_request_id
           AND NOT EXISTS (SELECT 1
                             FROM ra_interface_distributions_all RID2
                            WHERE RID2.interface_line_context     = RI.interface_line_context
                              AND ((RI.line_type ='LINE' AND RID2.account_class = 'REV')
                                   OR (RI.line_type ='TAX'  AND RID2.account_class = 'TAX'))
                              AND RID2.INTERFACE_LINE_ATTRIBUTE1 = RI.INTERFACE_LINE_ATTRIBUTE1
                              AND RID2.INTERFACE_LINE_ATTRIBUTE2 = RI.INTERFACE_LINE_ATTRIBUTE2
                              AND RID2.INTERFACE_LINE_ATTRIBUTE3 = RI.INTERFACE_LINE_ATTRIBUTE3
                              AND RID2.INTERFACE_LINE_ATTRIBUTE4 = RI.INTERFACE_LINE_ATTRIBUTE4
                              AND RID2.INTERFACE_LINE_ATTRIBUTE5 = RI.INTERFACE_LINE_ATTRIBUTE5
                              AND RID2.INTERFACE_LINE_ATTRIBUTE6 = RI.INTERFACE_LINE_ATTRIBUTE6
                              AND RID2.INTERFACE_LINE_ATTRIBUTE7 = RI.INTERFACE_LINE_ATTRIBUTE7
                              AND RID2.INTERFACE_LINE_ATTRIBUTE8 = RI.INTERFACE_LINE_ATTRIBUTE8
                              AND RID2.INTERFACE_LINE_ATTRIBUTE9 = RI.INTERFACE_LINE_ATTRIBUTE9
                              AND RID2.INTERFACE_LINE_ATTRIBUTE10 = RI.INTERFACE_LINE_ATTRIBUTE10
                              AND RID2.INTERFACE_LINE_ATTRIBUTE11 = RI.INTERFACE_LINE_ATTRIBUTE11
                              AND RID2.INTERFACE_LINE_ATTRIBUTE12 = RI.INTERFACE_LINE_ATTRIBUTE12
                              AND RID2.INTERFACE_LINE_ATTRIBUTE13 = RI.INTERFACE_LINE_ATTRIBUTE13
                              AND RID2.INTERFACE_LINE_ATTRIBUTE14 = RI.INTERFACE_LINE_ATTRIBUTE14
                              and rid2.request_id                 = ri.request_id )
        UNION
        SELECT DISTINCT RI.INTERFACE_LINE_ATTRIBUTE1
          FROM RA_INTERFACE_LINES_ALL RI
         WHERE RI.request_id    = gn_request_id
           AND RI.line_type     ='LINE'
           AND NOT EXISTS (SELECT 1
                             FROM ra_interface_distributions_all RID2
                            WHERE RID2.interface_line_context     = RI.interface_line_context
                              AND RID2.INTERFACE_LINE_ATTRIBUTE1  = RI.INTERFACE_LINE_ATTRIBUTE1
                              AND (RI.line_type ='LINE'  AND RID2.account_class = 'REC')
                              AND rid2.request_id                 = ri.request_id );


      TYPE l_trx_tbl_type     IS TABLE OF lcu_pos_inv%ROWTYPE INDEX BY PLS_INTEGER;
      TYPE l_trx_tbl_type2    IS TABLE OF lcu_pos_exp_inv%ROWTYPE INDEX BY PLS_INTEGER;
      TYPE l_trx_number_type  IS TABLE OF xx_ra_int_lines_all.interface_line_attribute1%TYPE INDEX BY PLS_INTEGER;
      TYPE l_trx_number_type2 IS TABLE OF xx_ra_int_lines_all.interface_line_attribute1%TYPE INDEX BY PLS_INTEGER;

      lt_pos_trx             l_trx_tbl_type;
      lt_pos_trx2            l_trx_tbl_type2;
      lt_trx_number          l_trx_number_type;
      lt_trx_number2          l_trx_number_type2;

   BEGIN
      /***************************************
      ** Step #1 - Initialize Variables     **
      ***************************************/
      gn_request_id := FND_GLOBAL.CONC_REQUEST_ID;

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'gn_request_id ='||gn_request_id);

      BEGIN
         -- Retrieve Master Organization ID
         BEGIN
            SELECT master_organization_id
              INTO ln_master_organization_id
              FROM mtl_parameters
             WHERE organization_id = master_organization_id;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
               FND_MESSAGE.SET_TOKEN('COL','master_organization_id');
               lc_error_msg := FND_MESSAGE.GET;
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
               XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                 p_program_type            => 'CONCURRENT PROGRAM'
                                ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                ,p_module_name             => 'AR'
                                ,p_error_location          => 'Oracle Error '||SQLERRM
                                ,p_error_message_count     => gn_msg_cnt
                                ,p_error_message_code      => 'E'
                                ,p_error_message           => lc_error_msg
                                ,p_error_message_severity  => 'Major'
                                ,p_notify_flag             => 'N'
                                ,p_object_type             => 'Creating Accounts '
                                );
               RAISE EX_SALES_ORDER;
            WHEN TOO_MANY_ROWS THEN
               lc_error_msg :='Multiple Master Orgs Defined';
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
               XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                 p_program_type            => 'CONCURRENT PROGRAM'
                                ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                ,p_module_name             => 'AR'
                                ,p_error_location          => 'Oracle Error '||SQLERRM
                                ,p_error_message_count     => gn_msg_cnt
                                ,p_error_message_code      => 'E'
                                ,p_error_message           => lc_error_msg
                                ,p_error_message_severity  => 'Major'
                                ,p_notify_flag             => 'N'
                                ,p_object_type             => 'Creating Accounts '
                                 );
               RAISE EX_SALES_ORDER;
            WHEN OTHERS THEN
               FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
               FND_MESSAGE.SET_TOKEN('COL','master_organization_id');
               lc_error_msg := FND_MESSAGE.GET || SQLERRM;
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
               XX_COM_ERROR_LOG_PUB.LOG_ERROR(
                                  p_program_type            => 'CONCURRENT PROGRAM'
                                 ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                 ,p_module_name             => 'AR'
                                 ,p_error_location          => 'Oracle Error '||SQLERRM
                                 ,p_error_message_count     => gn_msg_cnt + 1
                                 ,p_error_message_code      => 'E'
                                 ,p_error_message           => lc_error_msg
                                 ,p_error_message_severity  => 'Major'
                                 ,p_notify_flag             => 'N'
                                 ,p_object_type             => 'Creating Accounts '
                                  );
               RAISE EX_SALES_ORDER;
         END; -- Retrieve Master Organization ID

         -- Retrieve Category Set ID
         BEGIN
            SELECT category_set_id
              INTO ln_category_set_id
              FROM mtl_category_sets
             WHERE category_set_name = 'Inventory';

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
               FND_MESSAGE.SET_TOKEN('COL','category_set_id');
               lc_error_msg := FND_MESSAGE.GET;
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
               XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                  p_program_type            => 'CONCURRENT PROGRAM'
                                 ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                 ,p_module_name             => 'AR'
                                 ,p_error_location          => 'Oracle Error '||SQLERRM
                                 ,p_error_message_count     => gn_msg_cnt
                                 ,p_error_message_code      => 'E'
                                 ,p_error_message           => lc_error_msg
                                 ,p_error_message_severity  => 'Major'
                                 ,p_notify_flag             => 'N'
                                 ,p_object_type             => 'Creating Accounts '
                                  );
            WHEN OTHERS THEN
               FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
               FND_MESSAGE.SET_TOKEN('COL','category_set_id');
               lc_error_msg := FND_MESSAGE.GET || SQLERRM;
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
               XX_COM_ERROR_LOG_PUB.LOG_ERROR(
                                  p_program_type            => 'CONCURRENT PROGRAM'
                                 ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                 ,p_module_name             => 'AR'
                                 ,p_error_location          => 'Oracle Error '||SQLERRM
                                 ,p_error_message_count     => gn_msg_cnt + 1
                                 ,p_error_message_code      => 'E'
                                 ,p_error_message           => lc_error_msg
                                 ,p_error_message_severity  => 'Major'
                                 ,p_notify_flag             => 'N'
                                 ,p_object_type             => 'Creating Accounts '
                                  );
         END;  -- Retrieve Category Set ID

         --Added the query to fetch the translations for the batch source prefix and attribute category
         lc_default_date := fnd_date.canonical_to_date(p_default_date);


         -- added for defect 12227 to default header_attribute15 , mohan for Perf improvement for billing programs
         SELECT OOS1.order_source_id
               ,OOS2.order_source_id
               ,OOS3.order_source_id
           INTO ln_poe_order_source_id
               ,ln_hed_order_source_id
               ,ln_pro_order_source_id
           FROM xx_fin_translatevalues     XFTV
               ,xx_fin_translatedefinition XFTD
               ,oe_order_sources           OOS1
               ,oe_order_sources           OOS2
               ,oe_order_sources           OOS3
          WHERE XFTV.translate_id     = XFTD.translate_id
            AND XFTD.translation_name = 'OD_AR_BILLING_SOURCE_EXCL'
            AND SYSDATE BETWEEN XFTV.start_date_active
                            AND NVL(XFTV.end_date_active, SYSDATE+1)
            AND SYSDATE BETWEEN XFTD.start_date_active
                            AND NVL(XFTD.end_date_active, SYSDATE+1)
            AND OOS1.name             = XFTV.source_value2
            AND OOS2.name             = XFTV.source_value3
            AND OOS3.name             = XFTV.source_value4
            AND XFTV.enabled_flag     = 'Y'
            AND XFTD.enabled_flag     = 'Y';

         -- Retrieve SPC Order Source ID
         BEGIN
            SELECT order_source_id
              INTO ln_spc_order_source_id
              FROM oe_order_sources
             WHERE name = gc_order_source_spc;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Order Source ID not found for the order source SPC');
            WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to fetch order source id for SPC '|| SQLERRM);
         END; -- Retrieve SPC Order Source ID

         -- Long Variable to Build the WHERE clause in the REF CURSOR
         lc_where_clause := ' WHERE  '
                          ||'batch_source_name = '
                          || 'NVL('''||p_invoice_source||''', batch_source_name)'--added per POS SDR
                          ||' AND org_id = FND_PROFILE.VALUE(''ORG_ID'')';

         -- Retrieve Operating Unit Name based on ORG ID
         SELECT name
           INTO gc_ou_name
           FROM hr_operating_units
          WHERE organization_id = FND_PROFILE.VALUE('ORG_ID');

         -- Retrieve Country Name from translation based on operating unit name
         SELECT VAL.source_value1
           INTO gc_country_value
           FROM xx_fin_translatedefinition DEF
               ,xx_fin_translatevalues     VAL
          WHERE DEF.translate_id     = VAL.translate_id
            AND DEF.translation_name = 'OD_COUNTRY_DEFAULTS'
            AND VAL.target_value2    = gc_ou_name;

         -- Retrieve SOB Name based on country
         SELECT VAL.target_value1
           INTO gc_sob_name
           FROM xx_fin_translatedefinition DEF
               ,xx_fin_translatevalues     VAL
          WHERE DEF.translate_id     = VAL.translate_id
            AND DEF.translation_name = 'OD_COUNTRY_DEFAULTS'
            AND VAL.source_value1    = gc_country_value;

         -- Retrieve Ledger ID based on SOB name
         SELECT GLL.ledger_id							-- Changed for R12 Retrofit GSB.set_of_books_id
           INTO gn_sob_id
           FROM gl_ledgers	GLL						-- Changed for R12 Retrofitgl_sets_of_books GSB
          WHERE GLL.short_name = gc_sob_name;	-- Changed for R12 Retrofit GSB.short_name = gc_sob_name;

         -- Retrieve Chart of Accounts ID based on SOB ID
         SELECT GLL.chart_of_accounts_id
           INTO gn_coa_id
           FROM gl_ledgers	GLL														-- Changed for R12 Retrofit gl_sets_of_books GSB
          WHERE GLL.ledger_id = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');  -- Changed for R12 Retrofit GSB.set_of_books_id = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');
		 
		 -- Added for Bill Complete Dinesh NAIT-86554
			BEGIN
				SELECT target_value1
				INTO gn_bill_date
				FROM xx_fin_translatedefinition xftd ,
					 xx_fin_translatevalues xftv
				WHERE xftv.translate_id          = xftd.translate_id
				AND xftd.translation_name        ='OD_BC_BILLING_DATE'
				AND source_value1                ='Bill Complete'
				AND NVL (xftv.enabled_flag, 'N') = 'Y';
			EXCEPTION
			WHEN NO_DATA_FOUND THEN
				gn_bill_date	:=NULL;
			WHEN OTHERS THEN
				gn_bill_date	:=NULL;
			END;

         ------------------------------------------------
         -- Added for R12 Retrofit to derive tax columns
         ------------------------------------------------
         BEGIN
         IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
              FND_FILE.PUT_LINE(FND_FILE.LOG,' before Derive Tax rate code and Tax Regime code');
		 END IF;

            IF  gc_country_value = 'US' THEN
                  IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
                      FND_FILE.PUT_LINE(FND_FILE.LOG,' inside US Derive Tax rate code and Tax Regime code');
				  END IF;

                  --Retrive Tax regime code, tax_status_code for US FOR LINE1
                  SELECT zrb.tax_status_code,
                         zrb.tax_regime_code,
                         zrb.percentage_rate
                  INTO   gc_tax_status_code_us,
                         gc_tax_regime_code_us,
                         gc_rate_percent
                  FROM   zx_rates_b zrb
                  WHERE  zrb.tax_rate_code = gc_tax_rate_code
                  AND    zrb.tax           = gc_tax_line1
                  AND    zrb.active_flag   = 'Y'
                  AND    TRUNC(SYSDATE) BETWEEN zrb.effective_from AND NVL(zrb.effective_to,TRUNC(SYSDATE));
                  IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
                     FND_FILE.PUT_LINE(FND_FILE.LOG,' Derived Tax rate code and Tax Regime code - ' || gc_tax_regime_code_us || ' - ' || gc_tax_status_code_us );
				  END IF;

                  --Retrive Tax regime code, tax_status_code for US FOR LINE2
                  SELECT zrb.tax_status_code,
                         zrb.tax_regime_code,
                         zrb.percentage_rate
                  INTO   gc_tax_status_code_us1,
                         gc_tax_regime_code_us1,
                         gc_rate_percent1
                  FROM   zx_rates_b zrb
                  WHERE  zrb.tax_rate_code = gc_tax_rate_code1
                  AND    zrb.tax           = gc_tax_line2
                  AND    zrb.active_flag   = 'Y'
                  AND    TRUNC(SYSDATE) BETWEEN zrb.effective_from AND NVL(zrb.effective_to,TRUNC(SYSDATE));
                  IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
                      FND_FILE.PUT_LINE(FND_FILE.LOG,' Derived Tax rate code and Tax Regime code for line2 - ' || gc_tax_regime_code_us1 || ' - ' || gc_tax_status_code_us1 );
				  END IF;

            ELSIF gc_country_value = 'CA' THEN

                  --Retrive tax, tax_status_code for CA for COUNTY
                  SELECT  zrb.tax_status_code,
                          zrb.tax,
                          zrb.percentage_rate
                  INTO    gc_tax_status_code_ca1,
                          gc_tax_county,
                          gc_rate_percent_county
                  FROM    zx_rates_b zrb
                  WHERE   tax_rate_code   = gc_tax_rate_county
                  AND     tax_regime_code = gc_tax_regime_code_ca
                  AND     zrb.active_flag = 'Y'
                  AND     TRUNC(SYSDATE) BETWEEN zrb.effective_from AND NVL(zrb.effective_to,TRUNC(SYSDATE));
                  IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
                                    FND_FILE.PUT_LINE(FND_FILE.LOG,' Derived Tax rate code and Tax Regime code county - ' || gc_tax_status_code_ca1 || ' - ' || gc_tax_rate_county );
			      END IF;

                  --Retrive tax, tax_status_code for CA for STATE
                  SELECT  zrb.tax_status_code,
                          zrb.tax,
                          zrb.percentage_rate
                  INTO    gc_tax_status_code_ca,
                          gc_tax_state,
                          gc_rate_percent_state
                  FROM    zx_rates_b zrb
                  WHERE   zrb.tax_rate_code   = gc_tax_rate_state
                  AND     zrb.tax_regime_code = gc_tax_regime_code_ca
                  AND     zrb.active_flag     = 'Y'
                  AND     TRUNC(SYSDATE) BETWEEN zrb.effective_from AND NVL(zrb.effective_to,TRUNC(SYSDATE));
                  IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
                    FND_FILE.PUT_LINE(FND_FILE.LOG,' Derived Tax rate code and Tax Regime code state - ' || gc_tax_status_code_ca || ' - ' || gc_tax_rate_state );
				  END IF;

            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN

                IF  gc_country_value = 'US' THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND: For US TAX LINE1 Tax rate code and Tax '
                                                     || gc_tax_rate_code || gc_tax_line1 );

                     FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND: For US TAX LINE2 Tax rate code and Tax '
                                                     || gc_tax_rate_code || gc_tax_line2  );
                ELSIF  gc_country_value = 'CA' THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND: For CANADA COUNTY Tax rate code and Tax Regime code'
                                                     || gc_tax_rate_county || gc_tax_regime_code_ca  );

                     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'NO_DATA_FOUND: For CANADA STATE Tax rate code and Tax Regime code '
                                                     || gc_tax_rate_state || gc_tax_regime_code_ca  );
                END IF;
            WHEN TOO_MANY_ROWS THEN

                IF  gc_country_value = 'US' THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'TOO_MANY_ROWS: For US TAX LINE1 Tax rate code and Tax '
                                                     || gc_tax_rate_code || ' - ' || gc_tax_line1 );

                     FND_FILE.PUT_LINE(FND_FILE.LOG,'TOO_MANY_ROWS: For US TAX LINE2 Tax rate code and Tax '
                                                     || gc_tax_rate_code || ' - ' || gc_tax_line2  );
                ELSIF  gc_country_value = 'CA' THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'TOO_MANY_ROWS: For CANADA COUNTY Tax rate code and Tax Regime code'
                                                     || gc_tax_rate_county || ' - ' || gc_tax_regime_code_ca );

                     FND_FILE.PUT_LINE(FND_FILE.LOG,'TOO_MANY_ROWS: For CANADA STATE Tax rate code and Tax Regime code '
                                                     || gc_tax_rate_state || ' - ' || gc_tax_regime_code_ca  );
                END IF;

            WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Other EXCEPTION: UNABLE TO DERIVE TAX COLUMNS FOR COUNTRY '
                                                    ||gc_country_value || ' - ' || SQLERRM );

         END;

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The List of Processed/Unprocessed Order Transaction Lines');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------------------------------');

      END;

      /************************************************
      ** Step #2 - Determine Processing/Run Type     **
      ************************************************/
      IF UPPER(SUBSTR(p_run_flag,1,1)) = 'A' AND (gc_country_value IN ('CA','US')) THEN

         -- POST-Autoinvoice processing/updates
         FND_FILE.PUT_LINE(FND_FILE.LOG,'   Reset Interface Status to NULL');

         -- Reset Interface Status to NULL
         UPDATE ra_interface_lines_all RIL
            SET interface_status = NULL
          WHERE interface_status = 'X'
            AND request_id IS NOT NULL
            -- Added condition for Defect 20687 V4.0
            AND EXISTS (SELECT 1
                          FROM xx_fin_translatedefinition TD
                              ,xx_fin_translatevalues     TV
                         WHERE td.translation_name = 'OD_AR_INVOICING_DEFAULTS'
                           AND TV.translate_id  = td.translate_id
                           AND TD.enabled_flag  = 'Y'
                           AND TV.enabled_flag  = 'Y'
                           AND TV.target_value6 = p_batch_group
                           AND TV.target_value1 = RIL.batch_source_name);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of Records Updated for Reset '||
                                        'of interface_status from X to null: ' || SQL%ROWCOUNT);


         COMMIT;

      ELSIF UPPER(SUBSTR(p_run_flag,1,1)) = 'B' THEN

         -- PRE-Autoinvoice processing/updates

         /*********************************************************
         ** Step #3 ? Determine if E0080 Children Should Sleep   **
         *********************************************************/
         IF p_sales_order_low IS NULL AND p_sales_order_high IS NULL THEN

            BEGIN
               -- To fetch the E0080 Master request id
               FND_FILE.PUT_LINE(FND_FILE.LOG,'   Fetch the E0080 Master request id');
               SELECT parent_request_id
                 INTO ln_master_req_id
                 FROM fnd_concurrent_requests
                WHERE request_id = gn_request_id;

               ln_sleep :='Y';

            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  ln_sleep :='N';
               WHEN OTHERS THEN
                  ln_sleep :='N';
            END;

            IF ln_sleep = 'Y' THEN

               FND_FILE.PUT_LINE(FND_FILE.LOG,'   Calling XX_AR_CREATE_ACCT_SLEEP_PROC');
               XX_AR_CREATE_ACCT_SLEEP_PROC(p_master_req_id => ln_master_req_id
                                           ,p_inv_source    => p_invoice_source
                                            );
            END IF;

         END IF;

         /**********************************************************************
         ** Step #4 ? Clean-up for Reprocessing for a Range of Sales Orders   **
         **********************************************************************/
         -- This section of the code is only called if submitted for specific range of sales orders
         IF p_sales_order_low IS NOT NULL AND p_sales_order_high IS NOT NULL THEN

            -- Delete distributions created from previous run to avoid duplicate rows
            FND_FILE.PUT_LINE(FND_FILE.LOG,'   Delete distributions created from previous run to avoid duplicate rows');
            DELETE FROM ra_interface_distributions_all RID
             WHERE RID.org_id                     = ln_orgid
               AND RID.interface_line_context     ='ORDER ENTRY'
               -- Added condition for Defect 20687 V4.0
               AND RID.interface_line_id IN (SELECT RIL.interface_line_id
                                               FROM ra_interface_lines_all RIL
                                              WHERE RIL.sales_order           >= p_sales_order_low
                                                AND RIL.sales_order           <= p_sales_order_high
                                                AND RIL.batch_source_name      = NVL(p_invoice_source,RIL.batch_source_name)
                                                AND RIL.org_id                 = ln_orgid
                                                AND RIL.interface_line_context = 'ORDER ENTRY');

            -- Delete TAX lines created from previous run to avoid duplicate rows
            FND_FILE.PUT_LINE(FND_FILE.LOG,'   Delete TAX lines created from previous run to avoid duplicate rows');
            DELETE FROM ra_interface_lines_all RIL
             WHERE RIL.org_id                 = ln_orgid
               AND RIL.interface_line_context = 'ORDER ENTRY'
               AND RIL.line_type              = gc_line_type_TAX_hc
               AND RIL.sales_order           >= p_sales_order_low
               AND RIL.sales_order           <= p_sales_order_high
               AND RIL.batch_source_name      =  NVL(p_invoice_source,RIL.batch_source_name);

            -- Update lines to allow
            FND_FILE.PUT_LINE(FND_FILE.LOG,'   Update lines to allow processing');

            UPDATE ra_interface_lines_all ril
               SET ril.interface_status = NULL
                  ,ril.request_id       = NULL
                  ,ril.trx_number       = sales_order
             WHERE RIL.batch_source_name      =  NVL(p_invoice_source,RIL.batch_source_name)  --added 11.3  POS SDR
               AND RIL.org_id = FND_PROFILE.VALUE('ORG_ID')
               AND RIL.sales_order >= p_sales_order_low
               AND RIL.sales_order <= p_sales_order_high ;

            COMMIT;
         END IF;

         /**********************************
         ** Step #5 ? Create TAX Lines    **
         **********************************/
         IF   (p_sales_order_low IS NOT NULL AND p_sales_order_high IS NOT NULL)
            OR
              (p_sales_order_low IS NULL AND p_sales_order_high IS NULL) THEN

            BEGIN
               IF gc_country_value IN ('US','CA') THEN
                  XX_AR_INSERT_TAX_LINES(p_sales_order_low
                                        ,p_sales_order_high
                                        ,gc_country_value
                                        ,NVL(gn_request_id,0)
                                        ,p_invoice_source
                                        ,lc_exc_err
                                         );

                  IF lc_exc_err IS NOT NULL THEN
                     FND_FILE.PUT_LINE (FND_FILE.LOG, lc_exc_err );
                     RAISE EX_SALES_TAX;
                  END IF;
               END IF;
               COMMIT;
            END;

         END IF;

         /***************************************************
         ** Step #6 ? Finalize Cursor Criteria and Open    **
         ***************************************************/
         BEGIN
            IF p_sales_order_low IS NOT NULL AND p_sales_order_high is NOT NULL AND p_sales_order_low = p_sales_order_high THEN
               OPEN c_interface_lines FOR
                  lc_cursor_query || ' ' || lc_where_clause
                                  ||' AND (interface_status IS NULL '
                                  ||' OR   interface_status = ''E'')'
                                  ||' AND  sales_order = ''' || p_sales_order_low || ''''
                                  ||' ORDER BY currency_code '
                                  ||',sales_order '
                                  ||',sales_order_line'
                                  ||',line_type';

            ELSIF p_sales_order_low IS NOT NULL AND p_sales_order_high IS NOT NULL THEN
               OPEN c_interface_lines FOR
                  lc_cursor_query || ' ' || lc_where_clause
                                  ||' AND (interface_status IS NULL '
                                  ||' OR   interface_status = ''E'')'
                                  ||' AND  sales_order >= '''|| p_sales_order_low  || ''''
                                  ||' AND  sales_order <= '''|| p_sales_order_high || ''''
                                  ||'  ORDER BY currency_code '
                                  ||',sales_order '
                                  ||',sales_order_line'
                                  ||',line_type';

            ELSIF p_sales_order_low IS NOT NULL AND p_sales_order_high IS NULL THEN
               -- If above condition is satisfied then EX_SALES_ORDER user defined exception is raised and make the requestset error out
               RAISE EX_SALES_ORDER;

            ELSIF p_sales_order_low IS NULL AND p_sales_order_high IS NOT NULL THEN
               -- If above condition is satisfied then EX_SALES_ORDER user defined exception is raised and make the requestset error out
               RAISE EX_SALES_ORDER;

            ELSIF p_sales_order_low IS NULL AND p_sales_order_high IS NULL THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'CONC_REQUEST_ID:' || gn_request_id);
               OPEN c_interface_lines FOR
                  lc_cursor_query || ' ' || lc_where_clause
                                  ||'AND   request_id = ' || gn_request_id
                                  ||' ORDER BY currency_code '
                                  ||',sales_order '
                                  ||',sales_order_line'
                                  ||',line_type';
            END IF;
         END;

         ln_detail_inv_line_cnt  :=0;                                           --added counters 11.3 POS SDR
         ln_summary_inv_line_cnt :=0;

         IF  p_invoice_source IS NOT NULL  THEN
              BEGIN
                  SELECT NVL(tv.target_value2,' ')
                        ,NVL(tv.target_value3,'N')
                    INTO lc_attribute_category
                         ,lc_pos_summary_flg                                    --added summary_flg 11.3 POS SDR
                    FROM  xx_fin_translatedefinition    td
                           ,xx_fin_translatevalues      tv
                   WHERE translation_name = 'OD_AR_INVOICING_DEFAULTS'
                     AND tv.translate_id  = td.translate_id
                     AND tv.target_value1 = p_invoice_source
                     AND tv.source_value1 = (SELECT NAME
                                               FROM hr_all_organization_units
                                              WHERE Organization_id  = p_org_id)
                     AND td.enabled_flag  = 'Y'
                     AND tv.enabled_flag  = 'Y';

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND: OD_AR_INVOICING_DEFAULTS '
                                                     || 'transaltion table' );

                  WHEN OTHERS THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Other EXCEPTION: OD_AR_INVOICING_DEFAULTS '
                                                    ||SQLERRM );

               END;
         END IF;


         /**************************************************
         ** Step #7 ? Begin Processing Interface Lines    **
         **************************************************/
         LOOP
            FETCH c_interface_lines INTO lcu_process_interface_lines;
            EXIT WHEN c_interface_lines%NOTFOUND;

            -- Initialize/Reset Loop variables
            lc_rev_account           := NULL;
            lc_rev_company           := NULL;
            ln_oloc                  := NULL;
            lc_oloc_type             := NULL;
            lc_sloc                  := NULL;
            lc_sloc_type             := NULL;
            ln_rev_ccid              := NULL;
            ln_rec_ccid              := NULL;
            lc_rev_company           := NULL;
            lc_rec_company           := NULL;
            lc_tax_company           := NULL;
            lc_coupon_code           := NULL;
            lc_coupon_owner          := NULL;
            ln_dummysku_count        := 0;
            lc_so_attribute          := NULL;
            lc_trx_type              := lcu_process_interface_lines.cust_trx_type_id;
            lc_line_type             := lcu_process_interface_lines.line_type;
            lc_description           := lcu_process_interface_lines.description;
            ln_order_header_id       := 0;
            ln_mixed_order_line_cnt  := 0;
            lc_customer_type         := NULL;
            lc_item_source           := NULL;
            lc_consignment           := NULL;
            lc_source_type_code      := NULL;
            lc_cost_center_dept      := NULL;
            lc_desk_del_addr         := NULL;
            lc_contract_details      := NULL;
            lc_release_num           := NULL;
            lc_actual_ship_date      := NULL;
            lc_cogs_value2           := NULL;
            lc_inv_value3            := NULL;
            lc_cons_value4           := NULL;
            lc_avg_cost              := NULL;
            lc_item_type             := NULL;
            lc_dept                  := NULL;
            lc_item                  := NULL;
            ln_order_source_id       := NULL;
            lc_header_attribute15    := NULL;
            lc_cogs_flag             := 'N';
            lc_order_type_mixed      := 'N';
            lc_mixed_credit          := 'N';
			lc_bill_comp_flag        := 'N';							-- Added for Bill Complete NAIT-67165
			lc_parent_order_num		 := NULL;							-- Added for Bill Complete NAIT-67165
			ln_site_use_id			 := NULL;							-- Added for Bill Complete NAIT-67165
			lc_bill_comp_upd_flag	 := 'Y';
			ln_bill_comp_cnt		 :=-1;
            lc_ret_org_order_num     := NULL;
            ln_cust_trx_line_id      := NULL;
            lc_rev_cons_location     := NULL;
            lc_kit_sku               := NULL;
            lc_bill_level            := NULL;
            lc_kit_parent            := NULL;
			ln_orig_sysref_len		 :=-1;
			ln_trx_num_len			 :=0;
			ln_bill_comp_check_count :=0;
			lc_bc_spc_flag			 := 'N';

            IF  p_invoice_source IS NULL  THEN
               BEGIN
                  SELECT NVL(tv.target_value2,' ')
                        ,NVL(tv.target_value3,'N')
                    INTO lc_attribute_category
                        ,lc_pos_summary_flg                                   --added summary_flg 11.3 POS SDR
                    FROM xx_fin_translatedefinition  td
                        ,xx_fin_translatevalues      tv
                   WHERE translation_name = 'OD_AR_INVOICING_DEFAULTS'
                     AND tv.translate_id  = td.translate_id
                     AND tv.target_value1 = lcu_process_interface_lines.batch_source_name
                     AND tv.source_value1 = (SELECT NAME
                                               FROM hr_all_organization_units
                                              WHERE Organization_id  = p_org_id)
                       AND td.enabled_flag  = 'Y'
                       AND tv.enabled_flag  = 'Y';

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Summary_flag: '|| lc_pos_summary_flg );

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND: OD_AR_INVOICING_DEFAULTS '
                                                     || 'transaltion table' );

                  WHEN OTHERS THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Other EXCEPTION: OD_AR_INVOICING_DEFAULTS '
                                                    ||SQLERRM );
               END;

            END IF;

            ----------------------------------------------
            -- Track total of summary and detail invoices
            ----------------------------------------------
            IF lc_pos_summary_flg = 'Y'  THEN
               ln_summary_inv_line_cnt := ln_summary_inv_line_cnt +1;
            ELSE
               ln_detail_inv_line_cnt := ln_detail_inv_line_cnt + 1;
            END IF;
				---------------------------------------------------------------
				-- Getting Bill Comp Flag for Bill Complete Customers NAIT-67165
				---------------------------------------------------------------
				---/* Start for Bill Comp Change NAIT-67165 /
				
				IF lc_prev_order <>	lcu_process_interface_lines.sales_order
				THEN
					IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
						FND_FILE.PUT_LINE(FND_FILE.LOG,'Processing for Customer'||lcu_process_interface_lines.orig_system_bill_customer_id);
					END IF;
					BEGIN
						SELECT COUNT(1)
						INTO ln_bill_comp_check_count
						FROM Hz_Customer_Profiles HCP
						WHERE 1                  =1
						AND Hcp.Site_Use_Id     IS NULL
						AND Hcp.Cons_Inv_Flag     = 'Y'
						AND Hcp.Cust_Account_Id   = lcu_process_interface_lines.orig_system_bill_customer_id	--33059690
						AND Hcp.attribute6        in ('Y','B');
					EXCEPTION
					WHEN NO_DATA_FOUND THEN
						ln_bill_comp_check_count := 0;
						FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found while getting Bill Complete Customer from Hz_Customer_Profiles');
					WHEN OTHERS THEN
						ln_bill_comp_check_count := 0;
						FND_FILE.PUT_LINE(FND_FILE.LOG,'When others while getting Bill Complete Customer from Hz_Customer_Profiles');
					END;
					
					ln_trx_num_len:= LENGTH(lcu_process_interface_lines.sales_order);					

					BEGIN						
						SELECT 	xoha.bill_comp_flag
							,	ooh.invoice_to_org_id
							,	NVL(xoha.parent_order_num,ooh.order_number)
							,	LENGTH(orig_sys_document_ref)	
						INTO lc_Bill_Comp_Flag,
							 ln_site_use_id,
							 lc_parent_order_num,
							 ln_orig_sysref_len
						FROM oe_order_headers_all ooh,
							 xx_om_header_attributes_all xoha
						Where ooh.order_number = lcu_process_interface_lines.sales_order
						-- AND parent_order_num     IS NOT NULL -- Commented for Defect NAIT-75351
						AND (xoha.bill_comp_flag IN ('B','Y') OR (ln_trx_num_len =10 AND ln_bill_comp_check_count >0)) -- Added for Defect NAIT-75351
						AND ooh.header_id      = xoha.header_id
						AND ROWNUM        <2; 						
					EXCEPTION
					WHEN NO_DATA_FOUND THEN
						 lc_Bill_Comp_Flag	:='N';
					WHEN OTHERS THEN
						lc_Bill_Comp_Flag	:='N';
					END;
					IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
						FND_FILE.PUT_LINE(FND_FILE.LOG,'SPC Order : ln_orig_sysref_len : '||ln_orig_sysref_len ||' ln_trx_num_len : '||ln_trx_num_len||' ln_bill_comp_check_count : '||ln_bill_comp_check_count);
					END IF;
					IF ln_orig_sysref_len=20 AND ln_trx_num_len =10 AND ln_bill_comp_check_count > 0
					THEN
						lc_bc_spc_flag	:=	'Y';
						IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
							FND_FILE.PUT_LINE(FND_FILE.LOG,'Bill Complete Customer with SPC Order : '||lcu_process_interface_lines.sales_order ||' with Amount : '||lcu_process_interface_lines.amount||' lc_prev_order : '||lc_prev_order);
						END IF;
					END IF;
					-----------------------------------------------------------------------------------------
					-- If Bill Complete and no SCM Signal push billing date of invoice to future + 90 days.
					-----------------------------------------------------------------------------------------
					IF NVL(lc_Bill_Comp_Flag,'N') IN ('B','Y')  OR lc_bc_spc_flag = 'Y' THEN
						IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
							FND_FILE.PUT_LINE(FND_FILE.LOG,'Bill Complete Customer : '||lcu_process_interface_lines.sales_order ||' with Amount : '||lcu_process_interface_lines.amount||' lc_prev_order : '||lc_prev_order);
						END IF;
							lc_bill_comp_upd_flag	:='N';
							-- Inserting Credit Memos into Bill Signal table
							IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
								FND_FILE.PUT_LINE(FND_FILE.LOG,'Bill Complete Customer : before xx_scm_bill_signal order : '||lcu_process_interface_lines.sales_order ||' attribute2 : '||NVL(UPPER(lcu_process_interface_lines.interface_line_attribute2),'XX'));
							END IF;
							IF NVL(UPPER(lcu_process_interface_lines.interface_line_attribute2),'XX') like '%RETURN%' OR (lc_bc_spc_flag = 'Y')
							THEN
								IF lc_bc_spc_flag ='Y'
								THEN
									lc_parent_order_num	:=lcu_process_interface_lines.sales_order;
									IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
										FND_FILE.PUT_LINE(FND_FILE.LOG,'Bill Complete Customer SPC Order : '||lc_parent_order_num);
									END IF;
								END IF;
								BEGIN							
									IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
										FND_FILE.PUT_LINE(FND_FILE.LOG,'Updating BC Flag in Header_Attributes for order : '||lcu_process_interface_lines.sales_order||' to parent_order_num : '||lc_parent_order_num);
									END IF;
							
									UPDATE xx_om_header_attributes_all
									SET parent_order_num =lc_parent_order_num,
										bill_comp_flag   = 'B'
									WHERE header_id      =
									  (SELECT max(header_id)
									  FROM oe_order_headers_all
									  WHERE order_number = lcu_process_interface_lines.sales_order	--'2282501742'
									  --AND LENGTH(orig_sys_document_ref)	=20	
									  )
									AND parent_order_num IS NULL 
									AND NVL(bill_comp_flag,'X')  NOT IN ('B','Y')										
									 ;			  
									IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
										FND_FILE.PUT_LINE(FND_FILE.LOG,' After Update Count : '||SQL%ROWCOUNT);
									END IF;
									
									INSERT
									INTO xx_scm_bill_signal
									  (
										Parent_Order_Number,
										Child_Order_Number,
										billing_date_flag,
										Creation_Date,
										Created_By,
										Last_Update_Date,
										Last_Updated_By,
										Last_Update_Login
									  )
									  VALUES
									  (
										lc_parent_order_num,
										lcu_process_interface_lines.sales_order,
										'N',
										SYSDATE,
										FND_PROFILE.VALUE('USER_ID'),
										SYSDATE,
										FND_PROFILE.VALUE('USER_ID'),
										gn_ln_loginid
									  );
									IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
										FND_FILE.PUT_LINE(FND_FILE.LOG,'Inserted Return Order into Bill Signal Table for Order : '||lcu_process_interface_lines.sales_order );
									END IF;
								EXCEPTION
								WHEN OTHERS THEN
									FND_FILE.PUT_LINE(FND_FILE.LOG,'Insertion Failed for Bill Complete customer into xx_scm_bill_signal '||SUBSTR(SQLERRM,1,255));
								END;	  
							END IF;
						IF lc_bill_comp_upd_flag = 'N' 
						THEN								
							BEGIN
								SELECT COUNT(1)
								INTO ln_bill_comp_cnt
								FROM xx_scm_bill_signal
								WHERE child_order_number =	lcu_process_interface_lines.sales_order
								AND billing_date_flag    = 'N' ;
								IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
									FND_FILE.PUT_LINE(FND_FILE.LOG,'Bill_Comp_Flag Exists Count : '|| ln_bill_comp_cnt ||' for Order : '||lcu_process_interface_lines.sales_order);
								END IF;
							END;	
						END IF;
						IF ln_bill_comp_cnt =0
						THEN
							BEGIN
								UPDATE ra_interface_lines_all RIL
								SET billing_date			= trunc(sysdate)+NVL(TO_NUMBER(gn_bill_date),90)
								WHERE ril.sales_order       = lcu_process_interface_lines.sales_order
								AND ril.batch_source_name 	= NVL(p_invoice_source,batch_source_name)
								AND ril.org_id            	= gc_ln_orgid;
								IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
									FND_FILE.PUT_LINE(FND_FILE.LOG,'Billing Date updated to future since no signal from SCM for order : '|| lcu_process_interface_lines.sales_order ||' TO : '||gn_bill_date||' Days. '||' for Count '||SQL%ROWCOUNT);
								END IF;
							EXCEPTION
							WHEN NO_DATA_FOUND THEN
								 FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND: TO Update to future for Bill Complete order : '||lcu_process_interface_lines.sales_order);
							WHEN OTHERS THEN
								FND_FILE.PUT_LINE(FND_FILE.LOG,'Other EXCEPTION: TO Update to future for Bill Complete Order: '||lcu_process_interface_lines.sales_order||' '||SUBSTR(SQLERRM,1,255) );
							END;
						ELSE 
							IF lc_bill_comp_upd_flag ='N'
							THEN
								BEGIN
									UPDATE  xx_scm_bill_signal
									SET 	billing_date_flag    = 'C'
										,	customer_id			 = lcu_process_interface_lines.orig_system_bill_customer_id
										,	site_use_id			 = ln_site_use_id
										,   shipped_flag		 = 'Y'
										, 	last_update_date	 = sysdate
										,	last_updated_by		 = gn_ln_loginid
									WHERE child_order_number 	 = lcu_process_interface_lines.sales_order
									AND billing_date_flag    	 = 'N';	
									lc_bill_comp_upd_flag		 :='C';
								IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
									FND_FILE.PUT_LINE(FND_FILE.LOG,'Bill Complete Customer Updated Customer id and Site Use Id for Order : '||lcu_process_interface_lines.sales_order);
								END IF;
								EXCEPTION
								WHEN NO_DATA_FOUND THEN
									 FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND: TO Update in xx_scm_bill_signal for order : '||lcu_process_interface_lines.sales_order);
								WHEN OTHERS THEN
									FND_FILE.PUT_LINE(FND_FILE.LOG,'Other EXCEPTION: TO Update in xx_scm_bill_signal for order : '||lcu_process_interface_lines.sales_order||SUBSTR(SQLERRM,1,255));
								END;
							END IF;
						END IF;
					END IF;
				END IF;
				---/* End for Bill Comp Change NAIT-67165 /
				lc_prev_order	:=	lcu_process_interface_lines.sales_order;	
			
            ---------------------------------------------------------------
            -- Update TRX_NUMBER for Services Invoices (Defect 20687 V4.0)
            ---------------------------------------------------------------
            IF lcu_process_interface_lines.batch_source_name IN ('OD_SERVICES_US','OD_SERVICES_CA') THEN
               UPDATE ra_interface_lines_all RIL
                  SET RIL.trx_number = (sales_order || (SELECT attribute1
                                                          FROM hr_all_organization_units
                                                         WHERE organization_id = lcu_process_interface_lines.warehouse_id))
                WHERE RIL.sales_order       = lcu_process_interface_lines.sales_order
                  AND RIL.batch_source_name = NVL(p_invoice_source,batch_source_name)
                  AND RIL.org_id            = FND_PROFILE.VALUE('ORG_ID');
            END IF;

            -- Ensure retrieved sales order between low and high parameter values
            -- or both parameters are null
            IF (lcu_process_interface_lines.sales_order BETWEEN p_sales_order_low
                                                            AND p_sales_order_high)
               OR
               (p_sales_order_high IS NULL and p_sales_order_low IS NULL) THEN

               BEGIN
                  -- Retrieve Order Attribues
                  SELECT OEH.order_number
                        ,OEH.header_id
                        ,OEH.orig_sys_document_ref
                        ,OEH.order_source_id
                        ,XXOH.delivery_code
                        ,XXOH.ship_to_state
                        ,XXOH.cost_center_dept
                        ,XXOH.desk_del_addr
                        ,XXOH.created_by_store_id
                        ,XXOH.od_order_type
                        ,OEL.source_type_code
                        ,OEL.actual_shipment_date
                        ,OEL.ship_from_org_id
                        ,XXOL.item_source
                        ,XXOL.consignment_bank_code
                        ,XXOL.average_cost
                        ,XXOL.contract_details
                        ,XXOL.release_num
                        ,CUST.attribute18
                        ,DECODE(HL.country, 'CA', HL.province, 'US', HL.state)
                    INTO ln_order_number
                        ,ln_order_header_id
                        ,lc_orig_doc_ref
                        ,ln_order_source_id
                        ,lc_delivery_code
                        ,lc_embed_ship_to_state
                        ,lc_cost_center_dept
                        ,lc_desk_del_addr
                        ,ln_created_by_store_id
                        ,lc_order_type
                        ,lc_source_type_code
                        ,lc_actual_ship_date
                        ,ln_ship_from_org_id
                        ,lc_item_source
                        ,lc_consignment
                        ,lc_avg_cost
                        ,lc_contract_details
                        ,lc_release_num
                        ,lc_customer_type
                        ,lc_ship_to_state
                    FROM oe_order_headers_all        OEH
                        ,xx_om_header_attributes_all XXOH
                        ,oe_order_lines_all          OEL
                        ,xx_om_line_attributes_all   XXOL
                        ,hz_cust_accounts_all        CUST
                        ,hz_cust_site_uses_all       HCSU
                        ,hz_cust_acct_sites_all      HCAS
                        ,hz_party_sites              HPS
                        ,hz_locations                HL
                   WHERE OEH.order_number       = lcu_process_interface_lines.sales_order
                     AND XXOH.header_id         = OEH.header_id
                     AND OEL.header_id          = OEH.header_id
                     AND OEL.line_id            = lcu_process_interface_lines.interface_line_attribute6
                     AND OEL.inventory_item_id  = lcu_process_interface_lines.inventory_item_id
                     AND XXOL.line_id           = OEL.line_id
                     AND CUST.cust_account_id   = lcu_process_interface_lines.orig_system_bill_customer_id
                     AND HCSU.site_use_id       = OEH.ship_to_org_id
                     AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
                     AND HPS.party_site_id      = HCAS.party_site_id
                     AND HL.location_id         = HPS.location_id;

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND: Order attributes not found for Sales Order '
                                                     || lcu_process_interface_lines.sales_order );

                     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'NO_DATA_FOUND: Order attributes not found for Sales Order '
                                                   || lcu_process_interface_lines.sales_order );
                  WHEN OTHERS THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'EXCEPTION: Order attributes not found for Sales Order '
                                                    || lcu_process_interface_lines.sales_order );

                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'EXCEPTION: Order attributes not found for Sales Order '
                                                   || lcu_process_interface_lines.sales_order );
               END;

               -- Set header attribute15 based on order_source_id of POE, HED, or PRO
               IF ln_order_source_id IN (ln_poe_order_source_id ,ln_hed_order_source_id ,ln_pro_order_source_id) THEN
                  lc_header_attribute15 := 'P';
               ELSE
                  lc_header_attribute15 := 'N';
               END IF;

               /**********************************************************************************
               ** Step #7.8 ? Update taxable_flag to 'N' for LINE Line type R12 Retrofit Start  **
               ***********************************************************************************/
                 IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Before updating LINE line type taxable_flag to N : ');
				  END IF;

                  UPDATE ra_interface_lines_all
                  SET taxable_flag   = 'N'
                  WHERE sales_order     = lcu_process_interface_lines.sales_order
                  AND batch_source_name =  NVL(p_invoice_source,batch_source_name)
                  AND line_type         = gc_line_type_LINE_hc
                  AND org_id            = FND_PROFILE.VALUE('ORG_ID');
                  IF (p_display_log ='Y') THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of LINE line type taxable_flag updates are : ' || SQL%ROWCOUNT);
				  END IF;

               /********************************************************************************
               ** Step #7.8 ? Update taxable_flag to 'N' for LINE Line type R12 Retrofit End  **
               *********************************************************************************/

               /*********************************************************
               ** Step #7.9 ? Update tax cols  for R12 Retrofit Start  **
               **********************************************************/
			   IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
               FND_FILE.PUT_LINE(FND_FILE.LOG,'BEFORE CALLING update US/CANADA TAX lines  in RA_INTERFACE_LINES : ' );
			   END IF;

               IF  gc_country_value = 'US' THEN
                  IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
                  --FND_FILE.PUT_LINE(FND_FILE.LOG,'update US TAX lines in RA_INTERFACE_LINES : ' );
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'lcu_process_interface_lines.LINE_NUMBER : ' || lcu_process_interface_lines.LINE_NUMBER);

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'gc_tax_regime_code_us : ' || gc_tax_regime_code_us);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'gc_tax_line1 : ' || gc_tax_line1);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'gc_tax_status_code_us : ' || gc_tax_status_code_us);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'gc_tax_rate_code : ' || gc_tax_rate_code);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'gc_rate_percent : ' || gc_rate_percent);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'lcu_process_interface_lines.sales_order : ' || lcu_process_interface_lines.sales_order);
				  END IF;

                  lc_interface_PREV := NULL;
                  lc_interface_CURR := NULL;

                  --Based on the above cursor sales order derive the other interface attributes

                  FOR ln_disc_cnt IN lcu_upd_tax_cols(lcu_process_interface_lines.sales_order,lcu_process_interface_lines.batch_source_name)
                  LOOP

                     --Set the current value as interface line attribute2

                     lc_interface_CURR := ln_disc_cnt.interface_line_attribute2;
                     IF (p_display_log ='Y') THEN
                     fnd_file.put_line(FND_FILE.LOG,'lc_interface_PREV ' || lc_interface_PREV);
                     fnd_file.put_line(FND_FILE.LOG,'ln_interface_CURR ' || lc_interface_CURR);
					 END IF;

                     --If Check if interface line type is TAX for US
                     IF ln_disc_cnt.line_type = gc_line_type_TAX_hc
                     THEN

                        --Check if prev value is null, if yes this means it is the first line for that sales order
                        IF      lc_interface_PREV IS NULL
                        THEN

                           UPDATE ra_interface_lines_all
                              SET tax_regime_code  = gc_tax_regime_code_us,                        --Added for R12 Retrofit Changes
                                  tax              = gc_tax_line1,                                 --Added for R12 Retrofit Changes
                                  tax_status_code  = gc_tax_status_code_us,                        --Added for R12 Retrofit Changes
                                  tax_rate_code    = gc_tax_rate_code,                             --Added for R12 Retrofit Changes
                                  tax_rate         = gc_rate_percent
                           WHERE org_id                       = FND_PROFILE.VALUE('ORG_ID')
                           AND   batch_source_name            = NVL(p_invoice_source,batch_source_name)
                           AND   line_type                    = gc_line_type_TAX_hc
                           AND   interface_line_attribute2    = ln_disc_cnt.interface_line_attribute2
                           AND   sales_order                  = ln_disc_cnt.sales_order;

                       --Check if prev value is not equal to cur value. If yes then it means it is second line for that sales order
                        ELSIF lc_interface_PREV != lc_interface_CURR
                        THEN

                            UPDATE ra_interface_lines_all
                            SET tax_regime_code  = gc_tax_regime_code_us1,                          --Added for R12 Retrofit Changes
                                tax              = gc_tax_line2,                                    --Added for R12 Retrofit Changes
                                tax_status_code  = gc_tax_status_code_us1,                          --Added for R12 Retrofit Changes
                                tax_rate_code    = gc_tax_rate_code1,                               --Added for R12 Retrofit Changes
                                tax_rate         = gc_rate_percent1
                           WHERE org_id                       = FND_PROFILE.VALUE('ORG_ID')
                           AND   batch_source_name            = NVL(p_invoice_source,batch_source_name)
                           AND   line_type                    = gc_line_type_TAX_hc
                           AND   interface_line_attribute2    = ln_disc_cnt.interface_line_attribute2
                           AND   sales_order                  = ln_disc_cnt.sales_order;
                        END IF;

                        lc_interface_PREV := ln_disc_cnt.interface_line_attribute2;
                        IF (p_display_log ='Y') THEN
                        fnd_file.put_line(FND_FILE.LOG,'updated lines ' || SQL%ROWCOUNT);
                        fnd_file.put_line(FND_FILE.LOG,'lc_interface_PREV ' || lc_interface_PREV);
                        fnd_file.put_line(FND_FILE.LOG,'lc_interface_CURR ' || lc_interface_CURR);
						END IF;
                     END IF;

                  END LOOP;

               ELSIF gc_country_value = 'CA' THEN
                  IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'update CANADA TAX lines  in RA_INTERFACE_LINES : ' );
				  END IF;

                  UPDATE ra_interface_lines_all
                  SET tax_regime_code   = gc_tax_regime_code_ca,
                      tax               = gc_tax_county,
                      tax_status_code   = gc_tax_status_code_ca1,
                      tax_rate_code     = gc_tax_rate_county,
                      tax_rate          = gc_rate_percent_county
                  WHERE sales_order     = lcu_process_interface_lines.sales_order
                  AND batch_source_name =  NVL(p_invoice_source,batch_source_name)
                  AND line_type         = gc_line_type_TAX_hc
                  AND org_id            = FND_PROFILE.VALUE('ORG_ID')
                  AND tax_code          = gc_tax_code_county;
                  IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of TAX lines updated for CA County in RA_INTERFACE_LINES : ' || SQL%ROWCOUNT);
				  END IF;

                  UPDATE ra_interface_lines_all
                  SET tax_regime_code   = gc_tax_regime_code_ca,
                      tax               = gc_tax_state,
                      tax_status_code   = gc_tax_status_code_ca,
                      tax_rate_code     = gc_tax_rate_state,
                      tax_rate          = gc_rate_percent_state
                  WHERE sales_order     = lcu_process_interface_lines.sales_order
                  AND batch_source_name =  NVL(p_invoice_source,batch_source_name)
                  AND line_type         = gc_line_type_TAX_hc
                  AND org_id            = FND_PROFILE.VALUE('ORG_ID')
                  AND tax_code          = gc_tax_code_state;
                  IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of TAX lines updated for CA State in RA_INTERFACE_LINES : ' || SQL%ROWCOUNT);
				  END IF;

               END IF;

               /*********************************************************
               ** Step #7.9 ? Update tax cols  for R12 Retrofit End  **
               **********************************************************/

               /*****************************************
               ** Step #8 ? Mixed Order Processing     **
               *****************************************/
               BEGIN
                  -- Check if sales order retrieved in this loop is the same as the previous loop
                  -- If it is the same, then mixed order processing/updating has already been performed
                  IF lcu_process_interface_lines.sales_order <> lc_prev_sales_order
                  THEN
                     lc_mixed_updated   := 'N';
                  END IF;

                  -- Check if mix order processing/updating has already been performed or not.
                  IF lc_mixed_updated = 'N' THEN
                     BEGIN
                        -- Checking the Order Line id is a MIXED ORDER or not
                        SELECT COUNT(OLA.line_id)
                          INTO ln_mixed_order_line_cnt
                          FROM oe_order_lines_all OLA
                         WHERE OLA.header_id                 = ln_order_header_id
                           AND UPPER(OLA.line_category_code) = 'RETURN'
                           AND EXISTS (SELECT OLA1.line_id
                                         FROM oe_order_lines_all OLA1
                                        WHERE OLA.header_id = OLA1.header_id
                                          AND OLA.line_id   <> OLA1.line_id
                                          AND UPPER(OLA1.line_category_code) = 'ORDER');
                     EXCEPTION
                        WHEN OTHERS THEN
                           FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
                           FND_MESSAGE.SET_TOKEN('COL','mixed_order_line_cnt : '||ln_mixed_order_line_cnt ||'For Sales order : '||
                           lcu_process_interface_lines.sales_order);
                           lc_error_msg := FND_MESSAGE.GET || SQLERRM;
                           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
                           XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                        p_program_type            => 'CONCURRENT PROGRAM'
                                       ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                       ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                       ,p_module_name             => 'AR'
                                       ,p_error_location          => 'Oracle Error '||SQLERRM
                                       ,p_error_message_count     => gn_msg_cnt + 1
                                       ,p_error_message_code      => 'E'
                                       ,p_error_message           => lc_error_msg
                                       ,p_error_message_severity  => 'Major'
                                       ,p_notify_flag             => 'N'
                                       ,p_object_type             => 'Creating Accounts');
                     END;

                     IF (p_display_log ='Y' ) THEN
                        FND_FILE.PUT_LINE (FND_FILE.LOG, '---------------------------------------');
                        FND_FILE.PUT_LINE (FND_FILE.LOG,  ' Number of Mixed Order Lines : ' || ln_mixed_order_line_cnt);
                     END IF;

                     IF (ln_mixed_order_line_cnt > 0  AND lc_mixed_updated = 'N') THEN
                        lc_order_type_mixed := 'Y';

                        -- Taking the net amount of a sales_order
                        BEGIN
                           -- Modified the above query for Defect 3479
                           SELECT SUM((NVL(invoiced_quantity,1) * NVL(unit_selling_price,0))
                                  +  (SIGN(invoiced_quantity) * NVL(tax_value,0)))
                             INTO ln_order_net_amount
                             FROM oe_order_lines_all
                            WHERE header_id = ln_order_header_id;

                           IF (p_display_log )='Y' THEN
                              FND_FILE.PUT_LINE (FND_FILE.LOG, ' Sales Order Net amount : ' || ln_order_net_amount);
                           END IF;

                           -- Checking the condition if net amount is positive
                           IF (ln_order_net_amount >= 0) THEN

                              -- To get the first Invoice(Positive) line
                              IF (lcu_process_interface_lines.quantity >= 0) THEN

                                 IF (p_display_log ='Y') THEN
                                    FND_FILE.PUT_LINE (FND_FILE.LOG, ' Transaction Type : Invoice ' );
                                    FND_FILE.PUT_LINE (FND_FILE.LOG, ' Sales Order Net amount is POSITIVE : '
                                                                     || ln_order_net_amount);
                                    FND_FILE.PUT_LINE (FND_FILE.LOG, '---------------------------------------');
                                 END IF;

                                 UPDATE ra_interface_lines_all
                                    SET credit_method_for_acct_rule    = lcu_process_interface_lines.credit_method_for_acct_rule
                                       ,credit_method_for_installments = lcu_process_interface_lines.credit_method_for_installments
                                       ,purchase_order                 = lcu_process_interface_lines.purchase_order
                                       ,reason_code                    = lcu_process_interface_lines.reason_code
                                       ,fob_point                      = lcu_process_interface_lines.fob_point
                                       ,term_id                        = lcu_process_interface_lines.term_id
                                       ,cust_trx_type_id               = lcu_process_interface_lines.cust_trx_type_id
                                       ,header_attribute_category      = lcu_process_interface_lines.header_attribute_category
                                       ,header_attribute1              = lcu_process_interface_lines.header_attribute1
                                       ,header_attribute2              = lcu_process_interface_lines.header_attribute2
                                       ,header_attribute3              = lcu_process_interface_lines.header_attribute3
                                       ,header_attribute4              = lcu_process_interface_lines.header_attribute4
                                       ,header_attribute5              = lcu_process_interface_lines.header_attribute5
                                       ,header_attribute6              = lcu_process_interface_lines.header_attribute6
                                       ,header_attribute7              = lcu_process_interface_lines.header_attribute7
                                       ,header_attribute8              = lcu_process_interface_lines.header_attribute8
                                       ,header_attribute9              = lcu_process_interface_lines.header_attribute9
                                       ,header_attribute10             = lcu_process_interface_lines.header_attribute10
                                       ,header_attribute11             = lcu_process_interface_lines.header_attribute11
                                       ,header_attribute12             = lcu_process_interface_lines.header_attribute12
                                       ,header_attribute13             = lcu_process_interface_lines.header_attribute13
                                       ,header_attribute14             = lcu_process_interface_lines.header_attribute14
                                       ,header_attribute15             = lcu_process_interface_lines.header_attribute15
                                       ,interface_line_attribute3      = lcu_process_interface_lines.interface_line_attribute3
                                       ,interface_line_attribute10     = lcu_process_interface_lines.interface_line_attribute10
                                       ,Payment_set_id                 = lcu_process_interface_lines.Payment_set_id
                                  WHERE sales_order       = lcu_process_interface_lines.sales_order
                                    AND batch_source_name =  NVL(p_invoice_source,batch_source_name)  --added 11.3  POS SDR
                                    AND quantity < 0
                                    AND org_id            = FND_PROFILE.VALUE('ORG_ID');

                                 UPDATE ra_interface_lines_all
                                    SET cust_trx_type_id  = lcu_process_interface_lines.cust_trx_type_id
                                  WHERE sales_order       = lcu_process_interface_lines.sales_order
                                    AND batch_source_name =  NVL(p_invoice_source,batch_source_name)
                                    AND line_type         = 'TAX'
                                    AND org_id            = FND_PROFILE.VALUE('ORG_ID');

                                 lc_mixed_updated :='Y';
                              END IF;

                           -- Checking  the condition if net amount is negative
                           ELSIF (ln_order_net_amount < 0) THEN

                              lc_mixed_credit := 'Y';

                              -- To get the first Credit Memo line
                              IF (lcu_process_interface_lines.quantity  < 0) THEN

                                 IF (p_display_log ='Y') THEN
                                    FND_FILE.PUT_LINE (FND_FILE.LOG, ' Transaction Type : Credit Memo ' );
                                    FND_FILE.PUT_LINE (FND_FILE.LOG, ' Sales Order Net amount is NEGATIVE : '
                                                                    || ln_order_net_amount);
                                    FND_FILE.PUT_LINE (FND_FILE.LOG, '---------------------------------------');

                                    FND_FILE.PUT_LINE (FND_FILE.LOG, 'p_invoice_source = '||p_invoice_source);

                                 END IF;

                                 UPDATE ra_interface_lines_all
                                    SET credit_method_for_acct_rule    = lcu_process_interface_lines.credit_method_for_acct_rule
                                       ,credit_method_for_installments = lcu_process_interface_lines.credit_method_for_installments
                                       ,purchase_order                 = lcu_process_interface_lines.purchase_order
                                       ,reason_code                    = lcu_process_interface_lines.reason_code
                                       ,fob_point                      = lcu_process_interface_lines.fob_point
                                       ,term_id                        = lcu_process_interface_lines.term_id
                                       ,cust_trx_type_id               = lcu_process_interface_lines.cust_trx_type_id
                                       ,header_attribute_category      = lcu_process_interface_lines.header_attribute_category
                                       ,header_attribute1              = lcu_process_interface_lines.header_attribute1
                                       ,header_attribute2              = lcu_process_interface_lines.header_attribute2
                                       ,header_attribute3              = lcu_process_interface_lines.header_attribute3
                                       ,header_attribute4              = lcu_process_interface_lines.header_attribute4
                                       ,header_attribute5              = lcu_process_interface_lines.header_attribute5
                                       ,header_attribute6              = lcu_process_interface_lines.header_attribute6
                                       ,header_attribute7              = lcu_process_interface_lines.header_attribute7
                                       ,header_attribute8              = lcu_process_interface_lines.header_attribute8
                                       ,header_attribute9              = lcu_process_interface_lines.header_attribute9
                                       ,header_attribute10             = lcu_process_interface_lines.header_attribute10
                                       ,header_attribute11             = lcu_process_interface_lines.header_attribute11
                                       ,header_attribute12             = lcu_process_interface_lines.header_attribute12
                                       ,header_attribute13             = lcu_process_interface_lines.header_attribute13
                                       ,header_attribute14             = lcu_process_interface_lines.header_attribute14
                                       ,header_attribute15             = lcu_process_interface_lines.header_attribute15
                                       ,interface_line_attribute3      = lcu_process_interface_lines.interface_line_attribute3
                                       ,interface_line_attribute10     = lcu_process_interface_lines.interface_line_attribute10
                                       ,Payment_set_id                 = lcu_process_interface_lines.Payment_set_id
                                   WHERE sales_order       = lcu_process_interface_lines.sales_order
                                    -- AND batch_source_name = p_invoice_source      removed 11.3  POS SDR
                                     AND batch_source_name =  NVL(p_invoice_source,batch_source_name)  --added 11.3  POS SDR
                                     AND ((quantity >= 0 and line_type = 'LINE') or line_type = 'TAX')
                                     AND org_id            = FND_PROFILE.VALUE('ORG_ID');

                                 UPDATE ra_interface_lines_all
                                    SET cust_trx_type_id  = lcu_process_interface_lines.cust_trx_type_id
                                  WHERE sales_order       = lcu_process_interface_lines.sales_order
                                    AND batch_source_name =  NVL(p_invoice_source,batch_source_name)
                                    AND line_type         = 'TAX'
                                    AND org_id            = FND_PROFILE.VALUE('ORG_ID');

                                 lc_mixed_updated :='Y';
                              END IF;
                           END IF;  --Checking the net amount
                        EXCEPTION
                           WHEN OTHERS THEN
                              FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
                              FND_MESSAGE.SET_TOKEN('COL',' Updating Mixed Order for the Sales order : '||
                                                          lcu_process_interface_lines.sales_order);
                              lc_error_msg := FND_MESSAGE.GET || SQLERRM;
                              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
                              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                              p_program_type             => 'CONCURRENT PROGRAM'
                                             ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                             ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                             ,p_module_name             => 'AR'
                                             ,p_error_location          => 'Oracle Error '||SQLERRM
                                             ,p_error_message_count     => gn_msg_cnt + 1
                                             ,p_error_message_code      => 'E'
                                             ,p_error_message           => lc_error_msg
                                             ,p_error_message_severity  => 'Major'
                                             ,p_notify_flag             => 'N'
                                             ,p_object_type             => 'Creating Accounts');
                        END;
                     ELSE
                        -- Indicates Mixed Order Processing check (or update) has completed.
                        lc_mixed_updated :='Y';
                     END IF;  -- For checking the sales order is a mixed order
                  END IF;
               END;

               /********************************************************************
               ** Step #9 ? Retrieve Location, Source, Item, and Avg Cost Info   **
               *********************************************************************/
            BEGIN
              -- Retrieve Order Location.
              -- Order Location is not mandatory for derive accounting segments
               BEGIN
                  SELECT SUBSTR(HLA.location_code,1,6)  "LOCATION_CODE"
                        ,HL.meaning                     "ORGANIZATION_TYPE"
                    INTO ln_oloc
                        ,lc_oloc_type
                    FROM hr_lookups                HL
                        ,hr_locations_all          HLA
                        ,hr_all_organization_units HAOU
                   WHERE HAOU.type            = HL.lookup_code
                     AND HAOU.location_id     = HLA.location_id
                     AND HAOU.organization_id = ln_created_by_store_id
                     AND HL.lookup_type       = 'ORG_TYPE'
                     AND HL.enabled_flag      = 'Y';
               EXCEPTION
                  WHEN OTHERS THEN
                     FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
                     FND_MESSAGE.SET_TOKEN('COL','Order Location for sales order:'||lcu_process_interface_lines.sales_order);
                     lc_error_msg := FND_MESSAGE.GET;
                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => gn_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts');
               END;

               -- Retrieve Shipping Location
               -- Shipping Location is mandatory for derive accounting segments
               BEGIN
                  SELECT SUBSTR (hla.location_code,1,6)   "LOCATION_CODE"
                        ,hl.meaning                       "ORGANIZATION_TYPE"
                    INTO lc_sloc
                        ,lc_sloc_type
                    FROM hr_lookups                HL
                        ,hr_locations_all          HLA
                        ,hr_all_organization_units HAOU
                   WHERE HAOU.type            = HL.lookup_code
                     AND HAOU.location_id     = HLA.location_id
                     AND HAOU.organization_id = ln_ship_from_org_id
                     AND HL.lookup_type       = 'ORG_TYPE'
                     AND HL.enabled_flag      = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
                     FND_MESSAGE.SET_TOKEN('COL','Shipping Location for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                     FND_MESSAGE.SET_TOKEN('COL','Shipping Location Type for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                     lc_error_msg := FND_MESSAGE.GET;
                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => gn_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts');
               WHEN OTHERS THEN
                  FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
                  FND_MESSAGE.SET_TOKEN('COL','Shipping Location for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                  FND_MESSAGE.SET_TOKEN('COL','Shipping Location Typefor sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                  lc_error_msg := FND_MESSAGE.GET;
                  XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => gn_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts');
               END;

               -- Retrieve Source Type Code
               BEGIN
                  SELECT OLA.source_type_code
                    INTO lc_source_type_code
                    FROM oe_order_headers_all OHA
                        ,oe_order_lines_all   OLA
                   WHERE OHA.order_number      = lcu_process_interface_lines.sales_order
                     AND OHA.header_id         = OLA.header_id
                     AND OLA.inventory_item_id = lcu_process_interface_lines.inventory_item_id
                     AND OLA.line_number       = lcu_process_interface_lines.sales_order_line;

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
                     FND_MESSAGE.SET_TOKEN('COL','Source Type for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                     lc_error_msg :=  FND_MESSAGE.GET;
                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => gn_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts');
                  WHEN OTHERS THEN
                     FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
                     FND_MESSAGE.SET_TOKEN('COL','Source Type for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                     lc_error_msg := FND_MESSAGE.GET;
                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => gn_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts');
               END;

               -- Validate Item Source
               -- Check if discount item line (interface_line_attribute11 is price adjustment id)
               IF lcu_process_interface_lines.interface_line_attribute11 = '0' THEN

                  -- This is not a discount item line
                  -- Note: Need to determine if this query is really required since a similar query
                  --       is performed in Step #7.  In fact, this query will overwrite previously
                  --       derived values.
                  BEGIN
                     SELECT OOL.item_source
                           ,OOL.consignment_bank_code
                       INTO lc_item_source
                           ,lc_consignment
                       FROM xx_om_line_attributes_all OOL
                           ,oe_order_headers_all      OHA
                           ,oe_order_lines_all        OLA
                      WHERE OHA.order_number      = lcu_process_interface_lines.sales_order
                        AND OHA.header_id         = OLA.header_id
                        AND OLA.line_id           = OOL.line_id
                        AND OLA.inventory_item_id = lcu_process_interface_lines.inventory_item_id
                        AND OLA.line_number       = lcu_process_interface_lines.sales_order_line;
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
                        FND_MESSAGE.SET_TOKEN('COL','Item Source for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                        lc_error_msg := FND_MESSAGE.GET;
                        XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                    p_program_type            => 'CONCURRENT PROGRAM'
                                   ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                   ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                   ,p_module_name             => 'AR'
                                   ,p_error_location          => 'Oracle Error '||SQLERRM
                                   ,p_error_message_count     => gn_msg_cnt + 1
                                   ,p_error_message_code      => 'E'
                                   ,p_error_message           => lc_error_msg
                                   ,p_error_message_severity  => 'Major'
                                   ,p_notify_flag             => 'N'
                                   ,p_object_type             => 'Creating Accounts');
                     WHEN OTHERS THEN
                        FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
                        FND_MESSAGE.SET_TOKEN('COL','Item Source for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                        lc_error_msg := FND_MESSAGE.GET;
                        XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                    p_program_type            => 'CONCURRENT PROGRAM'
                                   ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                   ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                   ,p_module_name             => 'AR'
                                   ,p_error_location          => 'Oracle Error '||SQLERRM
                                   ,p_error_message_count     => gn_msg_cnt + 1
                                   ,p_error_message_code      => 'E'
                                   ,p_error_message           => lc_error_msg
                                   ,p_error_message_severity  => 'Major'
                                   ,p_notify_flag             => 'N'
                                   ,p_object_type             => 'Creating Accounts');
                  END;

                  BEGIN
                     IF lc_item_source ='00' OR lc_item_source = 'OD' THEN
                        lc_item_source := NULL;

                     ELSIF lc_item_source IS NULL THEN

                        SELECT COUNT(*)
                          INTO ln_dummysku_count
                          FROM fnd_lookup_values
                         WHERE lookup_type='OD_FEES_ITEMS'
                           AND ATTRIBUTE6   = lcu_process_interface_lines.inventory_item_id
                           AND NVL(TAG,'Y') = 'Y';

                        IF ln_dummysku_count >=1 THEN
                            SELECT DISTINCT SEGMENT1
                              INTO lc_item_source
                              FROM mtl_system_items_b
                             WHERE inventory_item_id = lcu_process_interface_lines.inventory_item_id ;
                        END IF;

                     END IF;

                  END;

               ELSE

                  -- COUPON AND OWNER
                  BEGIN
                     SELECT OPA.attribute8
                           ,OPA.attribute9
                       INTO lc_coupon_code
                           ,lc_coupon_owner
                       FROM oe_price_adjustments_v OPA
                           ,oe_order_headers_all    OHA
                           ,oe_order_lines_all      OLA
                      WHERE lcu_process_interface_lines.sales_order = OHA.order_number
                        AND OHA.header_id           = OPA.header_id
                        AND OHA.header_id           = OLA.header_id
                        AND OLA.inventory_item_id   = lcu_process_interface_lines.inventory_item_id
                        AND OLA.line_number         = lcu_process_interface_lines.sales_order_line
                        AND OPA.price_adjustment_id = lcu_process_interface_lines.interface_line_attribute11
                        AND OPA.automatic_flag      = 'N';

                     IF lc_coupon_owner IS NOT NULL THEN
                        lc_item_source := lc_coupon_code||'-'||lc_coupon_owner;
                     ELSE
                        lc_item_source := lc_coupon_code;
                     END IF;
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
                        FND_MESSAGE.SET_TOKEN('COL','Coupon for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                        FND_MESSAGE.SET_TOKEN('COL','Owner for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                        lc_error_msg := FND_MESSAGE.GET;
                        XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                     p_program_type            => 'CONCURRENT PROGRAM'
                                    ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                    ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                    ,p_module_name             => 'AR'
                                    ,p_error_location          => 'Oracle Error '||SQLERRM
                                    ,p_error_message_count     => gn_msg_cnt + 1
                                    ,p_error_message_code      => 'E'
                                    ,p_error_message           => lc_error_msg
                                    ,p_error_message_severity  => 'Major'
                                    ,p_notify_flag             => 'N'
                                    ,p_object_type             => 'Creating Accounts');
                     WHEN OTHERS THEN
                        FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
                        FND_MESSAGE.SET_TOKEN('COL','Coupon for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                        FND_MESSAGE.SET_TOKEN('COL','Owner for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                        lc_error_msg := FND_MESSAGE.GET;
                        XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => gn_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts');
                     END;
               END IF;

               -- Retrieve Item Number for Order Line
               BEGIN
                  SELECT MSI.segment1
                    INTO lc_item
                    FROM mtl_system_items_b MSI     --Changed for R12 Retrofit mtl_system_items MSI
                   WHERE MSI.inventory_item_id = lcu_process_interface_lines.inventory_item_id
                     AND organization_id       = ln_master_organization_id;

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
                     FND_MESSAGE.SET_TOKEN('COL','Item for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                     lc_error_msg := FND_MESSAGE.GET;
                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                   p_program_type            => 'CONCURRENT PROGRAM'
                                  ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                  ,p_module_name             => 'AR'
                                  ,p_error_location          => 'Oracle Error '||SQLERRM
                                  ,p_error_message_count     => gn_msg_cnt + 1
                                  ,p_error_message_code      => 'E'
                                  ,p_error_message           => lc_error_msg
                                  ,p_error_message_severity  => 'Major'
                                  ,p_notify_flag             => 'N'
                                  ,p_object_type             => 'Creating Accounts');
                  WHEN OTHERS THEN
                     FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
                     FND_MESSAGE.SET_TOKEN('COL','Item for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                     lc_error_msg := FND_MESSAGE.GET;
                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                   p_program_type            => 'CONCURRENT PROGRAM'
                                  ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                  ,p_module_name             => 'AR'
                                  ,p_error_location          => 'Oracle Error '||SQLERRM
                                  ,p_error_message_count     => gn_msg_cnt + 1
                                  ,p_error_message_code      => 'E'
                                  ,p_error_message           => lc_error_msg
                                  ,p_error_message_severity  => 'Major'
                                  ,p_notify_flag             => 'N'
                                  ,p_object_type             => 'Creating Accounts');
               END;

               -- Retrieve Department for Inventory Item
               BEGIN
                  SELECT MC.segment3
                    INTO lc_dept
                    FROM mtl_item_categories MIC
                        ,mtl_categories_b    MC
                   WHERE MIC.category_set_id   = ln_category_set_id
                     AND MIC.category_id       = MC.category_id
                     AND MIC.inventory_item_id = lcu_process_interface_lines.inventory_item_id
                     AND MIC.organization_id   = ln_master_organization_id;

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
                     FND_MESSAGE.SET_TOKEN('COL','Department for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                     lc_error_msg := FND_MESSAGE.GET;
                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                   p_program_type            => 'CONCURRENT PROGRAM'
                                  ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                  ,p_module_name             => 'AR'
                                  ,p_error_location          => 'Oracle Error '||SQLERRM
                                  ,p_error_message_count     => gn_msg_cnt + 1
                                  ,p_error_message_code      => 'E'
                                  ,p_error_message           => lc_error_msg
                                  ,p_error_message_severity  => 'Major'
                                  ,p_notify_flag             => 'N'
                                  ,p_object_type             => 'Creating Accounts');
                  WHEN OTHERS THEN
                     FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
                     FND_MESSAGE.SET_TOKEN('COL','Department for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                     lc_error_msg := FND_MESSAGE.GET;
                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                   p_program_type            => 'CONCURRENT PROGRAM'
                                  ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                  ,p_module_name             => 'AR'
                                  ,p_error_location          => 'Oracle Error '||SQLERRM
                                  ,p_error_message_count     => gn_msg_cnt + 1
                                  ,p_error_message_code      => 'E'
                                  ,p_error_message           => lc_error_msg
                                  ,p_error_message_severity  => 'Major'
                                  ,p_notify_flag             => 'N'
                                  ,p_object_type             => 'Creating Accounts');
               END;

               -- Retrieve Item Type for Inventory Item
               BEGIN
                  SELECT MSIB.item_type
                    INTO lc_item_type
                    FROM mtl_system_items_b MSIB
                   WHERE MSIB.inventory_item_id = lcu_process_interface_lines.inventory_item_id
                     AND MSIB.organization_id   = ln_master_organization_id;

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
                     FND_MESSAGE.SET_TOKEN('COL','Item Type for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                     lc_error_msg := FND_MESSAGE.GET;
                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                   p_program_type            => 'CONCURRENT PROGRAM'
                                  ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                  ,p_module_name             => 'AR'
                                  ,p_error_location          => 'Oracle Error '||SQLERRM
                                  ,p_error_message_count     => gn_msg_cnt + 1
                                  ,p_error_message_code      => 'E'
                                  ,p_error_message           => lc_error_msg
                                  ,p_error_message_severity  => 'Major'
                                  ,p_notify_flag             => 'N'
                                  ,p_object_type             => 'Creating Accounts');
                  WHEN OTHERS THEN
                     FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
                     FND_MESSAGE.SET_TOKEN('COL','Item Type for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                     lc_error_msg := FND_MESSAGE.GET;
                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                   p_program_type            => 'CONCURRENT PROGRAM'
                                  ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                  ,p_module_name             => 'AR'
                                  ,p_error_location          => 'Oracle Error '||SQLERRM
                                  ,p_error_message_count     => gn_msg_cnt + 1
                                  ,p_error_message_code      => 'E'
                                  ,p_error_message           => lc_error_msg
                                  ,p_error_message_severity  => 'Major'
                                  ,p_notify_flag             => 'N'
                                  ,p_object_type             => 'Creating Accounts');
               END;

               -- Retrieve Average Cost
               BEGIN
                  SELECT OOL.average_cost
                    INTO lc_avg_cost
                    FROM xx_om_line_attributes_all OOL
                        ,oe_order_lines_all        OLA
                        ,oe_order_headers_all      OHA
                   WHERE OLA.line_id           = OOL.line_id
                     AND OLA.header_id         = OHA.header_id
                     AND OHA.order_number      = lcu_process_interface_lines.sales_order
                     AND OLA.inventory_item_id = lcu_process_interface_lines.inventory_item_id
                     AND OLA.ship_from_org_id  = lcu_process_interface_lines.warehouse_id
                     AND OLA.line_number       = lcu_process_interface_lines.sales_order_line;

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
                     FND_MESSAGE.SET_TOKEN('COL','Item Average Cost for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                     lc_error_msg := FND_MESSAGE.GET;
                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                   p_program_type            => 'CONCURRENT PROGRAM'
                                  ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                  ,p_module_name             => 'AR'
                                  ,p_error_location          => 'Oracle Error '||SQLERRM
                                  ,p_error_message_count     => gn_msg_cnt + 1
                                  ,p_error_message_code      => 'E'
                                  ,p_error_message           => lc_error_msg
                                  ,p_error_message_severity  => 'Major'
                                  ,p_notify_flag             => 'N'
                                  ,p_object_type             => 'Creating Accounts');
                  WHEN OTHERS THEN
                     FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
                     FND_MESSAGE.SET_TOKEN('COL','Item Average Cost for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
                     lc_error_msg := FND_MESSAGE.GET;
                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                   p_program_type            => 'CONCURRENT PROGRAM'
                                  ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                  ,p_module_name             => 'AR'
                                  ,p_error_location          => 'Oracle Error '||SQLERRM
                                  ,p_error_message_count     => gn_msg_cnt + 1
                                  ,p_error_message_code      => 'E'
                                  ,p_error_message           => lc_error_msg
                                  ,p_error_message_severity  => 'Major'
                                  ,p_notify_flag             => 'N'
                                  ,p_object_type             => 'Creating Accounts');
               END;
            END;
               /*********************************************************************************
               ** Step #10 ? Retrieve Revenue, COGS, Inventory, and Consignment Account Values **
               *********************************************************************************/
               -- Retrieve Revenue, COGS, Inventory, and Consignment Account Values
               BEGIN
                  SELECT translate_id
                    INTO ln_translation_id
                    FROM xx_fin_translatedefinition
                   WHERE translation_name = 'SALES ACCOUNTING MATRIX'
                     AND enabled_flag = 'Y'
                     AND (start_date_active <= SYSDATE
                     AND (end_date_active >= SYSDATE OR end_date_active IS NULL));

                  -- Getting Sales Account For ITEM_SOURCE And DEPT Combination
                  IF lc_item_source IS NOT NULL AND lc_dept IS NOT NULL THEN
                     BEGIN
                        SELECT target_value1
                              ,target_value2
                              ,target_value3
                              ,target_value4
                          INTO lc_rev_account
                              ,lc_cogs_value2
                              ,lc_inv_value3
                              ,lc_cons_value4
                          FROM xx_fin_translatevalues
                         WHERE translate_id = ln_translation_id
                           AND (source_value1 = lc_item_source)
                           AND (source_value2 IS NULL)
                           AND (source_value3 = lc_dept)
                           AND enabled_flag   = 'Y'
                           AND (start_date_active <= SYSDATE
                           AND (end_date_active >= SYSDATE OR end_date_active IS NULL));
                     EXCEPTION
                        WHEN OTHERS THEN
                           NULL; --To Proceed Further
                     END;

                     -- Getting Sales Account For ITEM_SOURCE Alone
                     IF lc_rev_account IS NULL THEN
                        BEGIN
                          SELECT target_value1
                                ,target_value2
                                ,target_value3
                                ,target_value4
                            INTO lc_rev_account
                                ,lc_cogs_value2
                                ,lc_inv_value3
                                ,lc_cons_value4
                            FROM xx_fin_translatevalues
                           WHERE translate_id = ln_translation_id
                             AND (source_value1 = lc_item_source)
                             AND (source_value2 IS NULL )
                             AND (source_value3 IS NULL )
                             AND enabled_flag   = 'Y'
                             AND (start_date_active <= SYSDATE
                             AND (end_date_active >= SYSDATE OR end_date_active IS NULL));
                        EXCEPTION
                           WHEN OTHERS THEN
                              NULL; -- To Proceed Further
                        END;
                     END IF;

                     -- Getting Sales Account For Default
                     IF lc_rev_account IS NULL THEN
                        lc_item_source := 'DEFAULT';
                        BEGIN
                           SELECT target_value1
                                 ,target_value2
                                 ,target_value3
                                 ,target_value4
                             INTO lc_rev_account
                                 ,lc_cogs_value2
                                 ,lc_inv_value3
                                 ,lc_cons_value4
                             FROM xx_fin_translatevalues
                            WHERE translate_id = ln_translation_id
                              AND (source_value1 = lc_item_source)
                              AND (source_value2 IS NULL )
                              AND (source_value3 IS NULL )
                              AND enabled_flag   = 'Y'
                              AND (start_date_active <= SYSDATE
                              AND (end_date_active >= SYSDATE OR end_date_active IS NULL));
                        EXCEPTION
                           WHEN OTHERS THEN
                              NULL; -- To Proceed Further
                        END;
                     END IF;

                  ELSIF lc_item_type IS NOT NULL AND lc_dept IS NOT NULL THEN
                     -- Getting Sales Account For ITEM_TYPE And DEPT Combination
                     BEGIN
                        SELECT target_value1
                              ,target_value2
                              ,target_value3
                              ,target_value4
                          INTO lc_rev_account
                              ,lc_cogs_value2
                              ,lc_inv_value3
                              ,lc_cons_value4
                          FROM xx_fin_translatevalues
                         WHERE translate_id = ln_translation_id
                           AND (source_value1 IS NULL )
                           AND (source_value2 = lc_item_type)
                           AND (source_value3 = lc_dept)
                           AND enabled_flag   = 'Y'
                           AND (start_date_active <= SYSDATE
                           AND (end_date_active >= SYSDATE OR end_date_active IS NULL));
                     EXCEPTION
                        WHEN OTHERS THEN
                           NULL; -- To Proceed Further
                     END;
                     -- Getting Sales Account For  DEPT Alone
                     IF lc_rev_account IS NULL THEN
                        BEGIN
                           SELECT target_value1
                                 ,target_value2
                                 ,target_value3
                                 ,target_value4
                             INTO lc_rev_account
                                 ,lc_cogs_value2
                                 ,lc_inv_value3
                                 ,lc_cons_value4
                             FROM xx_fin_translatevalues
                            WHERE translate_id = ln_translation_id
                              AND (source_value1 IS NULL )
                              AND (source_value2 IS NULL )
                              AND (source_value3 = lc_dept)
                              AND enabled_flag   = 'Y'
                              AND (start_date_active <= SYSDATE
                              AND (end_date_active >= SYSDATE OR end_date_active IS NULL));
                        EXCEPTION
                           WHEN OTHERS THEN
                              NULL; -- To Proceed Further
                        END;
                     END IF;

                     -- Getting Sales Account For ITEM_TYPE Alone
                     IF lc_rev_account IS NULL THEN
                        BEGIN
                           SELECT target_value1
                                 ,target_value2
                                 ,target_value3
                                 ,target_value4
                             INTO lc_rev_account
                                 ,lc_cogs_value2
                                 ,lc_inv_value3
                                 ,lc_cons_value4
                            FROM xx_fin_translatevalues
                           WHERE translate_id = ln_translation_id
                             AND (source_value1 IS NULL )
                             AND (source_value2 = lc_item_type)
                             AND (source_value3 IS NULL )
                             AND enabled_flag   = 'Y'
                             AND (start_date_active <= SYSDATE
                             AND (end_date_active >= SYSDATE OR end_date_active IS NULL));
                        EXCEPTION
                           WHEN OTHERS THEN
                              NULL; -- To Proceed Further
                        END;
                     END IF;
                  END IF;

                  -- If the Item is found, Then Derive the REV Account and Overwrite it.
                  IF lc_item IS NOT NULL THEN
                     BEGIN
                        SELECT target_value1
                              ,target_value2
                              ,target_value3
                              ,target_value4
                              ,target_value5  -- Added per defect 2072 
                          INTO lc_rev_account
                              ,lc_cogs_value2
                              ,lc_inv_value3
                              ,lc_cons_value4
                              ,lc_rev_cons_location
                          FROM xx_fin_translatevalues
                         WHERE translate_id = ln_translation_id
                           AND (source_value1 IS NULL)
                           AND (source_value2 IS NULL)
                           AND (source_value3 IS NULL)
                           AND (source_value4 = lc_item)
                           AND enabled_flag   = 'Y'
                           AND (start_date_active <= SYSDATE
                           AND (end_date_active >= SYSDATE OR end_date_active IS NULL));
                     EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                           NULL; -- To Proceed Further
                        WHEN OTHERS THEN
                           NULL; -- To Proceed Further
                     END;
                  END IF;
               EXCEPTION
                  WHEN OTHERS THEN
                     FND_MESSAGE.SET_NAME(application => 'XXFIN'
                                                ,name => 'XX_AR_0011_CREATE_ACT_OTHERS');
                     FND_MESSAGE.SET_TOKEN(token => 'COL'
                                          ,value => 'Deriving Sales Account');
                     lc_error_msg := FND_MESSAGE.GET;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_msg);
                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                   p_program_type            => 'CONCURRENT PROGRAM'
                                  ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                  ,p_module_name             => 'AR'
                                  ,p_error_location          => 'Oracle Error '||SQLERRM
                                  ,p_error_message_count     => gn_msg_cnt + 1
                                  ,p_error_message_code      => 'E'
                                  ,p_error_message           => lc_error_msg
                                  ,p_error_message_severity  => 'Major'
                                  ,p_notify_flag             => 'N'
                                  ,p_object_type             => 'Creating Accounts');
               END;

               /**********************************************
               ** Step #11 ? Perform Validations for COGS   **
               **********************************************/
               BEGIN
                  IF (lcu_process_interface_lines.interface_line_attribute11 <> 0 ) THEN
                     -- This is a discount line and therefore there is no COGS
                     lc_avg_cost           := NULL;
                     lc_cogs_flag          := 'NA';
                  END IF;

                  -- COGS and Inventory and Consignment are blank in the matrix then there is no COGS.
                  IF (lc_cogs_value2 IS NULL AND lc_inv_value3 IS NULL AND lc_cons_value4 IS NULL ) THEN
                     lc_cogs_flag := 'NA';
                  END IF;
               END;

               -- Print Sales Order Information to Log File based on parameter value
               IF (p_display_log ='Y') THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------------------------------------------');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Sales Order Number   : '||lcu_process_interface_lines.sales_order);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------------------------------------------');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Customer Type        : '||lc_customer_type);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Trx Type             : '||lc_trx_type);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Order Location id    : '||ln_oloc);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Shipping Location id : '||lc_sloc);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Order Location       : '||lc_oloc_type);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Shipping Location    : '||lc_sloc_type);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Item Source          : '||lc_item_source);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Source Type          : '||lc_source_type_code );
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Item Number          : '||lc_item);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Dept                 : '||lc_dept);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Item Type            : '||lc_item_type);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Average Cost         : '||lc_avg_cost);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Line Quantity        : '||lcu_process_interface_lines.quantity); --Defect 3418
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Revenue Account      : '||lc_rev_account);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'COGS    Account      : '||lc_cogs_value2);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Inventory Account    : '||lc_inv_value3);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Consignment Bank code: '||lc_consignment);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Consignment Account  : '||lc_cons_value4);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Revenue cons Location: '||lc_rev_cons_location);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------------------------------------------');
                  END IF;

               /**************************************************
               ** Step #12 ? Derive GL string for REVENUE class **
               **************************************************/
               -- Derive GL Account string for REVENUE (account class = REV)
                 -- Order Location can be blank for Web or Sales order
               -- Shipping location and type are both required in order to derive the account string
               IF lc_sloc_type IS NOT NULL AND
                  lc_sloc IS NOT NULL AND
                  lc_line_type <> gc_line_type_TAX_hc THEN

                  -- Deriving the REV oracle account segments
                  XX_GET_GL_COA(p_oloc          => ln_oloc
                               ,p_sloc          => lc_sloc
                               ,p_oloc_type     => lc_oloc_type
                               ,p_sloc_type     => lc_sloc_type
                               ,p_line_id       => ln_interface_line_id
                               ,p_rev_account   => lc_rev_account
                               ,p_acc_class     => 'REV'
                               ,p_cust_type     => lc_customer_type
                               ,p_trx_type      => lc_trx_type
                               ,p_log_flag      => p_display_log
                               ,p_tax_state     => NULL
                               ,p_tax_loc       => NULL
                               ,p_description   => NULL
                               ,x_company       => lc_rev_company
                               ,x_costcenter    => lc_rev_costcenter
                               ,x_account       => lc_rev_account
                               ,x_location      => lc_rev_location
                               ,x_intercompany  => lc_rev_intercompany
                               ,x_lob           => lc_rev_lob
                               ,x_future        => lc_rev_future
                               ,x_ccid          => ln_rev_ccid
                               ,x_error_message => lc_error_msg);

                   -- Defect 2072 
                   IF lc_rev_cons_location IS NOT NULL
                   THEN 
                     lc_rev_location := lc_rev_cons_location;
                     lc_rev_company := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(LTRIM(RTRIM(lc_rev_location))); 

                     -- Derive the NEW CCID 
                     BEGIN
                       SELECT GCC.code_combination_id
                       INTO ln_rev_ccid
                       FROM gl_code_combinations GCC
                           ,gl_ledgers     GLL	--Changed for R12 Retrofit gl_sets_of_books     GSB
                       WHERE GCC.segment1 = lc_rev_company
                       AND GCC.segment2   = lc_rev_costcenter
                       AND GCC.segment3   = lc_rev_account
                       AND GCC.segment4   = lc_rev_location
                       AND GCC.segment5   = lc_rev_intercompany
                       AND GCC.segment6   = lc_rev_lob
                       AND GCC.segment7   = lc_rev_future
                       AND GCC.chart_of_accounts_id = GLL.chart_of_accounts_id
                       AND GLL.ledger_id = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID'); 
                    EXCEPTION 
                      WHEN OTHERS
                      THEN 
                       ln_ccid := NULL;
                    END;
                   END IF;
               ELSE
                  IF lc_sloc_type IS NULL OR lc_sloc IS NULL  THEN
                     IF (p_display_log ='Y') THEN
                        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Shipping Location Type is Mandatory for Sales Order : '
                                                        || lcu_process_interface_lines.sales_order);
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'The Shipping Location Type is Mandatory for Sales Order : '
                                                     || lcu_process_interface_lines.sales_order);
                     END IF;

                     -- lt_ril(ln_array) := lcu_process_interface_lines.sales_order;
                     lc_error_flag_val := 'Y';
                  END IF;
               END IF;

               /**********************************************************************************
               ** Step #13 ? Derive GL string for UNEARNED REVENUE class and create dist. line  **
               **********************************************************************************/
               -- Derive GL Account string for UNEARNED REVENUE and insert distribution line (account class = UNEARN)
               IF lcu_process_interface_lines.accounting_rule_id IS NOT NULL THEN
                  BEGIN
                     XX_GET_GL_COA(p_oloc          => ln_oloc
                                  ,p_sloc          => lc_sloc
                                  ,p_oloc_type     => lc_oloc_type
                                  ,p_sloc_type     => lc_sloc_type
                                  ,p_line_id       => ln_interface_line_id
                                  ,p_rev_account   => lc_rev_account
                                  ,p_cust_type     => lc_customer_type
                                  ,p_trx_type      => lc_trx_type
                                  ,p_acc_class     => 'UNEARN'
                                  ,p_log_flag      => p_display_log
                                  ,p_tax_state     => NULL
                                  ,p_tax_loc       => NULL
                                  ,p_description   => NULL
                                  ,x_company       => lc_rec_company
                                  ,x_costcenter    => lc_rec_costcenter
                                  ,x_account       => lc_rec_account
                                  ,x_location      => lc_rec_location
                                  ,x_intercompany  => lc_rec_intercompany
                                  ,x_lob           => lc_rec_lob
                                  ,x_future        => lc_rec_future
                                  ,x_ccid          => ln_rec_ccid
                                  ,x_error_message => lc_error_msg);
                  EXCEPTION
                     WHEN OTHERS THEN
                        IF (p_display_log ='Y') THEN
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised while deriving UNEARN Accounts for Sales Order '
                                                        || lcu_process_interface_lines.sales_order );
                        END IF;
                  END;

                  BEGIN
                     -- inserting data into ra_distributions_all with acc_class "UNEARN"
                     INSERT INTO ra_interface_distributions_all(
                                     interface_line_context
                                    ,interface_line_attribute1
                                    ,interface_line_attribute2
                                    ,interface_line_attribute3
                                    ,interface_line_attribute4
                                    ,interface_line_attribute5
                                    ,interface_line_attribute6
                                    ,interface_line_attribute7
                                    ,interface_line_attribute8
                                    ,interface_line_attribute9
                                    ,interface_line_attribute10
                                    ,interface_line_attribute11
                                    ,interface_line_attribute12
                                    ,interface_line_attribute13
                                    ,interface_line_attribute14
                                    ,interface_line_attribute15
                                    ,amount
                                    ,account_class
                                    ,code_combination_id
                                    ,segment1
                                    ,segment2
                                    ,segment3
                                    ,segment4
                                    ,segment5
                                    ,segment6
                                    ,segment7
                                    ,org_id
                                    ,percent
                                    ,created_by
                                    ,creation_date
                                    ,last_updated_by
                                    ,last_update_date
                                    ,last_update_login
                                    ,request_id
                                     )
                        VALUES(
                                     lcu_process_interface_lines.interface_line_context
                                    ,lcu_process_interface_lines.interface_line_attribute1
                                    ,lcu_process_interface_lines.interface_line_attribute2
                                    ,lcu_process_interface_lines.interface_line_attribute3
                                    ,lcu_process_interface_lines.interface_line_attribute4
                                    ,lcu_process_interface_lines.interface_line_attribute5
                                    ,lcu_process_interface_lines.interface_line_attribute6
                                    ,lcu_process_interface_lines.interface_line_attribute7
                                    ,lcu_process_interface_lines.interface_line_attribute8
                                    ,lcu_process_interface_lines.interface_line_attribute9
                                    ,lcu_process_interface_lines.interface_line_attribute10
                                    ,lcu_process_interface_lines.interface_line_attribute11
                                    ,lcu_process_interface_lines.interface_line_attribute12
                                    ,lcu_process_interface_lines.interface_line_attribute13
                                    ,lcu_process_interface_lines.interface_line_attribute14
                                    ,lcu_process_interface_lines.interface_line_attribute15
                                    ,lcu_process_interface_lines.amount
                                    ,'UNEARN'
                                    ,ln_rec_ccid
                                    ,lc_rec_company
                                    ,lc_rec_costcenter
                                    ,lc_rec_account
                                    ,lc_rec_location
                                    ,lc_rec_intercompany
                                    ,lc_rec_lob
                                    ,lc_rec_future
                                    ,FND_PROFILE.VALUE('ORG_ID')
                                    ,100
                                    ,FND_PROFILE.VALUE('USER_ID')
                                    ,SYSDATE
                                    ,FND_PROFILE.VALUE('USER_ID')
                                    ,SYSDATE
                                    ,FND_PROFILE.VALUE('LOGIN_ID')
                                    ,gn_request_id
                                    );
                  EXCEPTION
                     WHEN OTHERS THEN
                        IF (p_display_log ='Y') THEN
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised while inserting UNEARN Accounts for Sales Order '
                                                       || lcu_process_interface_lines.sales_order );
                        END IF;
                  END;
               END IF;

               /*********************************************************************
               ** Step #14 ? Derive GL string for TAX class and create dist. line  **
               *********************************************************************/
               BEGIN
                  -- Derive GL Account string for TAX and insert distribution line (account class = UNEARN)
                  IF lc_line_type = gc_line_type_TAX_hc THEN
                     IF lc_order_type = 'X' THEN
                        lc_tax_state := lc_ship_to_state;
                     ELSIF lc_delivery_code = 'P' OR ln_order_source_id IN (ln_poe_order_source_id
                                                                           ,ln_spc_order_source_id
                                                                           ,ln_pro_order_source_id) THEN
                        BEGIN
                           SELECT DECODE(HLA.country,'US',HLA.region_2,HLA.Region_1)
                             INTO lc_ship_from_state
                             FROM hr_lookups                HL
                                 ,hr_locations_all          HLA
                                 ,hr_all_organization_units HAOU
                            WHERE HAOU.type            = HL.lookup_code
                              AND HAOU.location_id     = HLA.location_id
                              AND HAOU.organization_id = ln_ship_from_org_id
                              AND HL.lookup_type       = 'ORG_TYPE'
                              AND HL.enabled_flag      = 'Y';

                           lc_tax_state :=  lc_ship_from_state;

                        EXCEPTION
                           WHEN NO_DATA_FOUND THEN
                              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'PICKUP/POS - Unable to find the state for Ship From Location for Sales Order : '
                                                             || lcu_process_interface_lines.sales_order);
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'PICKUP/POS - Unable to find the state for Ship From Location for Sales Order : '
                                                             || lcu_process_interface_lines.sales_order);
                           WHEN OTHERS THEN
                              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'PICKUP/POS - Unable to find the state for Ship From Location for Sales Order : '
                                                             || lcu_process_interface_lines.sales_order);
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'PICKUP/POS - Unable to find the state for Ship From Location for Sales Order : '
                                                             || lcu_process_interface_lines.sales_order);
                        END;

                     ELSE
                        lc_tax_state := lc_embed_ship_to_state;
                     END IF;

                     IF lc_tax_state IS NOT NULL THEN
                        BEGIN
                           --For defect 27985
                           /*SELECT GCC.segment4
                             INTO lc_tax_location
                             FROM ar_location_values_v ALV
                                 ,gl_code_combinations GCC
                            WHERE ALV.tax_account_ccid           = GCC.code_combination_id
                              AND ALV.location_segment_qualifier = DECODE(gc_country_value,'US','STATE','CA','PROVINCE')
                              AND ALV.location_segment_value     = lc_tax_state;*/
                              
                           select ffv.flex_value 
                             into lc_tax_location
			     from fnd_flex_values ffv,
			          fnd_flex_value_sets ffvs
			   where ffv.flex_value_set_id = ffvs.flex_value_set_id
			     and ffvs.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
			     and ffv.flex_value like '8%'
  			     and ffv.attribute4 = lc_tax_state;   
                              
                        EXCEPTION
                           WHEN NO_DATA_FOUND THEN
                              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Unable to find SEGMENT4 for Tax Location for Sales Order : '
                                                             || lcu_process_interface_lines.sales_order);
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to find SEGMENT4 for Tax Location for Sales Order : '
                                                             || lcu_process_interface_lines.sales_order);
                           WHEN OTHERS THEN
                              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Unable to find SEGMENT4 for Tax Location for Sales Order : '
                                                             || lcu_process_interface_lines.sales_order);
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to find SEGMENT4 for Tax Location for Sales Order : '
                                                             || lcu_process_interface_lines.sales_order);
                        END;
                     ELSE
                        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Deriving the Segment3 and Location from System Options for Sales Order : '
                                                       || lcu_process_interface_lines.sales_order);
                     END IF;

                     -- Derive Tax Account id
                     XX_GET_GL_COA(p_oloc          => ln_oloc
                                  ,p_sloc          => lc_sloc
                                  ,p_oloc_type     => lc_oloc_type
                                  ,p_sloc_type     => lc_sloc_type
                                  ,p_line_id       => ln_interface_line_id
                                  ,p_rev_account   => lc_rev_account
                                  ,p_cust_type     => lc_customer_type
                                  ,p_trx_type      => lc_trx_type
                                  ,p_acc_class     => gc_line_type_TAX_hc
                                  ,p_log_flag      => p_display_log
                                  ,p_tax_state     => lc_tax_state
                                  ,p_tax_loc       => lc_tax_location
                                  ,p_description   => lc_description
                                  ,x_company       => lc_tax_company
                                  ,x_costcenter    => lc_tax_costcenter
                                  ,x_account       => lc_tax_account
                                  ,x_location      => lc_tax_location
                                  ,x_intercompany  => lc_tax_intercompany
                                  ,x_lob           => lc_tax_lob
                                  ,x_future        => lc_tax_future
                                  ,x_ccid          => ln_tax_ccid
                                  ,x_error_message => lc_error_msg);

                     BEGIN
                        INSERT INTO ra_interface_distributions_all(
                                       interface_line_context
                                      ,interface_line_attribute1
                                      ,interface_line_attribute2
                                      ,interface_line_attribute3
                                      ,interface_line_attribute4
                                      ,interface_line_attribute5
                                      ,interface_line_attribute6
                                      ,interface_line_attribute7
                                      ,interface_line_attribute8
                                      ,interface_line_attribute9
                                      ,interface_line_attribute10
                                      ,interface_line_attribute11
                                      ,interface_line_attribute12
                                      ,interface_line_attribute13
                                      ,interface_line_attribute14
                                      ,interface_line_attribute15
                                      ,amount
                                      ,account_class
                                      ,code_combination_id
                                      ,segment1
                                      ,segment2
                                      ,segment3
                                      ,segment4
                                      ,segment5
                                      ,segment6
                                      ,segment7
                                      ,org_id
                                      ,percent
                                      ,created_by
                                      ,creation_date
                                      ,last_updated_by
                                      ,last_update_date
                                      ,last_update_login
                                      ,request_id
                                      )
                        VALUES(
                                       lcu_process_interface_lines.interface_line_context
                                      ,lcu_process_interface_lines.interface_line_attribute1
                                      ,lcu_process_interface_lines.interface_line_attribute2
                                      ,lcu_process_interface_lines.interface_line_attribute3
                                      ,lcu_process_interface_lines.interface_line_attribute4
                                      ,lcu_process_interface_lines.interface_line_attribute5
                                      ,lcu_process_interface_lines.interface_line_attribute6
                                      ,lcu_process_interface_lines.interface_line_attribute7
                                      ,lcu_process_interface_lines.interface_line_attribute8
                                      ,lcu_process_interface_lines.interface_line_attribute9
                                      ,lcu_process_interface_lines.interface_line_attribute10
                                      ,lcu_process_interface_lines.interface_line_attribute11
                                      ,lcu_process_interface_lines.interface_line_attribute12
                                      ,lcu_process_interface_lines.interface_line_attribute13
                                      ,lcu_process_interface_lines.interface_line_attribute14
                                      ,lcu_process_interface_lines.interface_line_attribute15
                                      ,lcu_process_interface_lines.amount
                                      ,gc_line_type_TAX_hc
                                      ,ln_tax_ccid
                                      ,lc_tax_company
                                      ,lc_tax_costcenter
                                      ,lc_tax_account
                                      ,lc_tax_location
                                      ,lc_tax_intercompany
                                      ,lc_tax_lob
                                      ,lc_tax_future
                                      ,FND_PROFILE.VALUE('ORG_ID')
                                      ,100
                                      ,FND_PROFILE.VALUE('USER_ID')
                                      ,SYSDATE
                                      ,FND_PROFILE.VALUE('USER_ID')
                                      ,SYSDATE
                                      ,FND_PROFILE.VALUE('LOGIN_ID')
                                      ,gn_request_id
                                      );

                        IF ln_tax_ccid  IS NOT NULL THEN
                           ln_tax_acct_count := ln_tax_acct_count + 1;
                        END IF;
                     EXCEPTION
                        WHEN OTHERS THEN
                           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error while inserting distribution for Tax for Sales Order : '
                                                          || lcu_process_interface_lines.sales_order);
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while inserting distribution for Tax for Sales Order : '
                                                        || lcu_process_interface_lines.sales_order);
                     END;

                  END IF;
               END;

               /*****************************************************************************
               ** Step #15 ? Derive GL string for RECEIVABLES class and create dist. line  **
               *****************************************************************************/
               BEGIN
                  -- Derive GL Account string for Receivable and insert distribution line (account class = REC)
                  IF lcu_process_interface_lines.sales_order <> lc_prev_sales_order THEN
                     lc_prev_sales_order := lcu_process_interface_lines.sales_order;
                     lc_prev_currency    := lcu_process_interface_lines.currency_code;

                     BEGIN
                        -- Deriving the REC oracle account segments
                        XX_GET_GL_COA(p_oloc          => ln_oloc
                                     ,p_sloc          => lc_sloc
                                     ,p_oloc_type     => lc_oloc_type
                                     ,p_sloc_type     => lc_sloc_type
                                     ,p_line_id       => ln_interface_line_id
                                     ,p_rev_account   => lc_rev_account
                                     ,p_cust_type     => lc_customer_type
                                     ,p_trx_type      => lc_trx_type
                                     ,p_acc_class     => 'REC'
                                     ,p_log_flag      => p_display_log
                                     ,p_tax_state     => NULL
                                     ,p_tax_loc       => NULL
                                     ,p_description   => NULL
                                     ,x_company       => lc_rec_company
                                     ,x_costcenter    => lc_rec_costcenter
                                     ,x_account       => lc_rec_account
                                     ,x_location      => lc_rec_location
                                     ,x_intercompany  => lc_rec_intercompany
                                     ,x_lob           => lc_rec_lob
                                     ,x_future        => lc_rec_future
                                     ,x_ccid          => ln_rec_ccid
                                     ,x_error_message => lc_error_msg);
                     EXCEPTION
                        WHEN OTHERS THEN
                           IF (p_display_log ='Y') THEN
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised while deriving REC Accounts '
                                                          || 'for Sales Order ' || lcu_process_interface_lines.sales_order );
                           END IF;
                     END;

                     BEGIN
                        IF ln_rec_ccid  IS NULL THEN
                           IF (p_display_log ='Y') THEN
                              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Unprocessed Sales Order : '||lcu_process_interface_lines.sales_order);
                              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Invalid REC Segment : ' ||
                              lc_rec_company ||  '.' || lc_rec_costcenter || '.' ||
                              lc_rec_account ||  '.' || lc_rec_location || '.' ||
                              lc_rec_intercompany ||  '.' || lc_rec_lob || '.' ||
                              lc_rec_future);
                           END IF;

                           IF (p_display_log ='N') THEN
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'The Unprocessed Sales Order  : '|| lcu_process_interface_lines.sales_order);
                              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Unprocessed Sales Order  : '|| lcu_process_interface_lines.sales_order);
                           END IF;

                           BEGIN
                              -- lt_ril(ln_array) := lcu_process_interface_lines.sales_order;
                              --ln_array := ln_array + 1;
                              lc_error_flag_val := 'Y';
                           EXCEPTION
                              WHEN OTHERS THEN
                                 IF (p_display_log ='Y') THEN
                                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised while marking error record for Sales Order '
                                                                || lcu_process_interface_lines.sales_order );
                                 END IF;
                           END;

                        END IF;

                        INSERT INTO ra_interface_distributions_all(
                                              interface_line_context
                                             ,interface_line_attribute1
                                             ,interface_line_attribute2
                                             ,interface_line_attribute3
                                             ,interface_line_attribute4
                                             ,interface_line_attribute5
                                             ,interface_line_attribute6
                                             ,interface_line_attribute7
                                             ,interface_line_attribute8
                                             ,interface_line_attribute9
                                             ,interface_line_attribute10
                                             ,interface_line_attribute11
                                             ,interface_line_attribute12
                                             ,interface_line_attribute13
                                             ,interface_line_attribute14
                                             ,interface_line_attribute15
                                             ,account_class
                                             ,code_combination_id
                                             ,segment1
                                             ,segment2
                                             ,segment3
                                             ,segment4
                                             ,segment5
                                             ,segment6
                                             ,segment7
                                             ,org_id
                                             ,percent
                                             ,created_by
                                             ,creation_date
                                             ,last_updated_by
                                             ,last_update_date
                                             ,last_update_login
                                             ,request_id
                                             )
                        VALUES(               lcu_process_interface_lines.interface_line_context
                                             ,lcu_process_interface_lines.interface_line_attribute1
                                             ,lcu_process_interface_lines.interface_line_attribute2
                                             ,lcu_process_interface_lines.interface_line_attribute3
                                             ,lcu_process_interface_lines.interface_line_attribute4
                                             ,lcu_process_interface_lines.interface_line_attribute5
                                             ,lcu_process_interface_lines.interface_line_attribute6
                                             ,lcu_process_interface_lines.interface_line_attribute7
                                             ,lcu_process_interface_lines.interface_line_attribute8
                                             ,lcu_process_interface_lines.interface_line_attribute9
                                             ,lcu_process_interface_lines.interface_line_attribute10
                                             ,lcu_process_interface_lines.interface_line_attribute11
                                             ,lcu_process_interface_lines.interface_line_attribute12
                                             ,lcu_process_interface_lines.interface_line_attribute13
                                             ,lcu_process_interface_lines.interface_line_attribute14
                                             ,lcu_process_interface_lines.interface_line_attribute15
                                             ,'REC'
                                             ,ln_rec_ccid
                                             ,lc_rec_company
                                             ,lc_rec_costcenter
                                             ,lc_rec_account
                                             ,lc_rec_location
                                             ,lc_rec_intercompany
                                             ,lc_rec_lob
                                             ,lc_rec_future
                                             ,FND_PROFILE.VALUE('ORG_ID')
                                             ,100
                                             ,FND_PROFILE.VALUE('USER_ID')
                                             ,SYSDATE
                                             ,FND_PROFILE.VALUE('USER_ID')
                                             ,SYSDATE
                                             ,FND_PROFILE.VALUE('LOGIN_ID')
                                             ,gn_request_id
                                              );

                        IF ln_rec_ccid  IS NOT NULL THEN
                           ln_rec_acct_count := ln_rec_acct_count + 1;
                        END IF;

                     EXCEPTION
                        WHEN OTHERS THEN
                           IF (p_display_log ='Y') THEN
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised while inserting REC Accounts for Sales Order '
                                                           || lcu_process_interface_lines.sales_order );
                           END IF;
                     END;
                  END IF;
               END;

               /***********************************************************
               ** Step #16 ? Create distribution line for REVENUE class  **
               ***********************************************************/
               BEGIN
                  -- Insert REVENUE distibution line (account class = REV)
                  IF ln_rev_ccid  IS NULL AND
                     lc_line_type <> gc_line_type_TAX_hc THEN
                     -- Display the Sales Order Number if Account is not derived.
                     IF (p_display_log ='Y') THEN
                        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Invalid REV Segment : ' ||
                                                          lc_rev_company ||  '.' || lc_rev_costcenter || '.' ||
                                                          lc_rev_account ||  '.' || lc_rev_location || '.' ||
                                                          lc_rev_intercompany ||  '.' || lc_rev_lob || '.' ||
                                                          lc_rev_future);
                     END IF;

                     BEGIN
                        -- lt_ril(ln_array)  := lcu_process_interface_lines.sales_order;
                        -- ln_array          := ln_array + 1;
                        ln_err_count      := ln_err_count + 1;
                        lc_error_flag_val := 'Y';
                     EXCEPTION
                        WHEN OTHERS THEN
                           IF (p_display_log ='Y') THEN
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised while marking error records for Sales Order and line id '
                                                          || lcu_process_interface_lines.sales_order || lcu_process_interface_lines.interface_line_id );
                           END IF;
                     END;

                  END IF;

                  IF lc_consignment IS NULL THEN
                     lc_cons_value4 := '';
                  END IF;

                  lc_so_attribute := lc_customer_type||','||lc_trx_type||','||ln_oloc||','||lc_sloc||','||
                                     lc_oloc_type||','||lc_sloc_type||','||lc_item_source||','||lc_source_type_code||','||
                                     lc_item||','||lc_dept||','||lc_item_type||','||lc_consignment;

                  IF lc_line_type <> gc_line_type_TAX_hc THEN

                     INSERT INTO ra_interface_distributions_all(
                                   interface_line_context
                                  ,interface_line_attribute1
                                  ,interface_line_attribute2
                                  ,interface_line_attribute3
                                  ,interface_line_attribute4
                                  ,interface_line_attribute5
                                  ,interface_line_attribute6
                                  ,interface_line_attribute7
                                  ,interface_line_attribute8
                                  ,interface_line_attribute9
                                  ,interface_line_attribute10
                                  ,interface_line_attribute11
                                  ,interface_line_attribute12
                                  ,interface_line_attribute13
                                  ,interface_line_attribute14
                                  ,interface_line_attribute15
                                  ,amount
                                  ,account_class
                                  ,code_combination_id
                                  ,segment1
                                  ,segment2
                                  ,segment3
                                  ,segment4
                                  ,segment5
                                  ,segment6
                                  ,segment7
                                  ,org_id
                                  ,percent
                                  ,Attribute_category
                                  ,attribute6
                                  ,attribute7
                                  ,attribute8
                                  ,attribute9
                                  ,attribute10   --requirment for defect 2426
                                  ,attribute11   --requirment for defect 7082
                                  ,created_by
                                  ,creation_date
                                  ,last_updated_by
                                  ,last_update_date
                                  ,last_update_login
                                  ,request_id
                                  )
                    VALUES        (
                                   lcu_process_interface_lines.interface_line_context
                                  ,lcu_process_interface_lines.interface_line_attribute1
                                  ,lcu_process_interface_lines.interface_line_attribute2
                                  ,lcu_process_interface_lines.interface_line_attribute3
                                  ,lcu_process_interface_lines.interface_line_attribute4
                                  ,lcu_process_interface_lines.interface_line_attribute5
                                  ,lcu_process_interface_lines.interface_line_attribute6
                                  ,lcu_process_interface_lines.interface_line_attribute7
                                  ,lcu_process_interface_lines.interface_line_attribute8
                                  ,lcu_process_interface_lines.interface_line_attribute9
                                  ,lcu_process_interface_lines.interface_line_attribute10
                                  ,lcu_process_interface_lines.interface_line_attribute11
                                  ,lcu_process_interface_lines.interface_line_attribute12
                                  ,lcu_process_interface_lines.interface_line_attribute13
                                  ,lcu_process_interface_lines.interface_line_attribute14
                                  ,lcu_process_interface_lines.interface_line_attribute15
                                  ,lcu_process_interface_lines.amount
                                  ,'REV'
                                  ,ln_rev_ccid
                                  ,lc_rev_company
                                  ,lc_rev_costcenter
                                  ,lc_rev_account
                                  ,lc_rev_location
                                  ,lc_rev_intercompany
                                  ,lc_rev_lob
                                  ,lc_rec_future
                                  ,FND_PROFILE.VALUE('ORG_ID')
                                  ,100
                                  ,lc_attribute_category
                                  ,lc_cogs_flag
                                  ,lc_cogs_value2
                                  ,lc_inv_value3
                                  ,lc_avg_cost
                                  ,lc_cons_value4
                                  ,lc_so_attribute
                                  ,FND_PROFILE.VALUE('USER_ID')
                                  ,SYSDATE
                                  ,FND_PROFILE.VALUE('USER_ID')
                                  ,SYSDATE
                                  ,FND_PROFILE.VALUE('LOGIN_ID')
                                  ,gn_request_id
                                   );
                  END IF;

                  IF ln_rev_ccid  IS NOT NULL THEN
                     ln_rev_acct_count := ln_rev_acct_count + 1;
                  END IF;

               EXCEPTION
                  WHEN OTHERS THEN
                     IF (p_display_log ='Y') THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised while inserting REV Accounts for Sales Order and line id'
                                                     || lcu_process_interface_lines.sales_order || lcu_process_interface_lines.interface_line_id );
                     END IF;
               END;

               /********************************************************************************
               ** Step #17 ? Required updates for Sales Order Lines (ra_interface_lines_all)  **
               ********************************************************************************/
               BEGIN
                  -- Update Invoice Header Attributes for Line Types of 'LINE' or 'TAX'
                  BEGIN
                     IF (lcu_process_interface_lines.line_type = gc_line_type_LINE_hc OR
                         lcu_process_interface_lines.line_type = gc_line_type_TAX_hc) THEN

                        --  header_attribute_category is updated with SALES_ACCT
                        --  header_attribute13 is updated with the prig system ref number
                        --  header_attribute14 is updated with the order header id for E1356 RICE#
                        --  header_attribute15 is updated with the derived value for billing
                        UPDATE ra_interface_lines_all ril
                           SET RIL.header_attribute_category = lc_attribute_category
                              ,RIL.header_attribute13        = lc_orig_doc_ref        -- Defect#5872
                              ,RIL.header_attribute14        = ln_order_header_id
                              ,RIL.header_attribute15        = lc_header_attribute15  --Defect # 12227 by Sowmya Mohanasundaram
                         WHERE sales_order                   = lcu_process_interface_lines.sales_order
                           AND RIL.interface_line_context    = 'ORDER ENTRY'
                           AND RIL.line_type                 = lcu_process_interface_lines.line_type -- Replaced hard coded value - Defect#2569-V-2.84
                           AND RIL.org_id                    = FND_PROFILE.VALUE('ORG_ID') ;
                     END IF;
                  END;

                  -- Update Invoice description for Price Adjustments
                  BEGIN
                     IF (lcu_process_interface_lines.interface_line_attribute11 <> 0 AND
                         lcu_process_interface_lines.attribute8 IS NOT NULL) THEN

                        BEGIN
                           SELECT meaning
                             INTO ls_disc_description
                             FROM fnd_lookup_values
                            WHERE lookup_type='OD_DISCOUNT_ITEMS'
                              AND lookup_code = lcu_process_interface_lines.attribute8;

                           UPDATE ra_interface_lines_all RIL
                              SET RIL.description = ls_disc_description
                            WHERE RIL.sales_order = lcu_process_interface_lines.sales_order
                              AND RIL.org_id = FND_PROFILE.VALUE('ORG_ID')
                              AND RIL.inventory_item_id = lcu_process_interface_lines.inventory_item_id
                              AND RIL.sales_order_line  = lcu_process_interface_lines.sales_order_line
                              AND RIL.interface_line_attribute11 = lcu_process_interface_lines.interface_line_attribute11;
                        EXCEPTION
                           WHEN NO_DATA_FOUND THEN
                              FND_MESSAGE.SET_NAME(application => 'XXFIN'
                                                  ,name        => 'XX_AR_0010_CREATE_ACT_NO_DATA');
                              FND_MESSAGE.SET_TOKEN(token => 'COL'
                                                   ,value => 'No Description for Discount line:'||
                                                             lcu_process_interface_lines.sales_order||
                                                             'Coupon code:'||lcu_process_interface_lines.attribute8);
                              lc_error_msg := FND_MESSAGE.GET;

                              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                  p_program_type            => 'CONCURRENT PROGRAM'
                                 ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                 ,p_module_name             => 'AR'
                                 ,p_error_location          => 'Oracle Error '||SQLERRM
                                 ,p_error_message_count     => gn_msg_cnt + 1
                                 ,p_error_message_code      => 'E'
                                 ,p_error_message           => lc_error_msg
                                 ,p_error_message_severity  => 'Major'
                                 ,p_notify_flag             => 'N'
                                 ,p_object_type             => 'Creating Accounts');

                           WHEN OTHERS THEN
                              FND_MESSAGE.SET_NAME(application => 'XXFIN'
                                                  ,name        => 'XX_AR_0011_CREATE_ACT_OTHERS');
                              FND_MESSAGE.SET_TOKEN(token  => 'COL'
                                                   ,value => 'No Description for Discount line:'||
                                                              lcu_process_interface_lines.sales_order||
                                                              'Coupon code:'||lcu_process_interface_lines.attribute8);
                              lc_error_msg := FND_MESSAGE.GET;
                              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_msg);
                              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                    p_program_type            => 'CONCURRENT PROGRAM'
                                   ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                   ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                   ,p_module_name             => 'AR'
                                   ,p_error_location          => 'Oracle Error '||SQLERRM
                                   ,p_error_message_count     => gn_msg_cnt+1
                                   ,p_error_message_code      => 'E'
                                   ,p_error_message           => lc_error_msg
                                   ,p_error_message_severity  => 'Major'
                                   ,p_notify_flag             => 'N'
                                   ,p_object_type             => 'Creating Accounts');
                           END;
                     END IF;
                  END;

                  -- Update Invoice with Order Attributes
                  BEGIN
                     -- Retrieve Order Attributes and Return Order Information
                     BEGIN
                        SELECT XOHA.cost_center_dept
                              ,XOHA.desk_del_addr
                              ,XOLA.contract_details
                              ,XOLA.release_num
                              ,OLA.actual_shipment_date
                              ,XOLA.ret_ref_line_id
                              ,CASE WHEN lc_order_type_mixed = 'Y' AND lc_mixed_credit = 'Y'
                                       THEN XOLA.ret_orig_order_num
                                    WHEN lc_order_type_mixed = 'N' AND OLA.invoiced_quantity <0  AND lcu_process_interface_lines.interface_line_attribute11 =0
                                       THEN XOLA.ret_orig_order_num
                                    WHEN lc_order_type_mixed = 'N' AND OLA.invoiced_quantity >0  AND lcu_process_interface_lines.interface_line_attribute11  <>0
                                       THEN XOLA.ret_orig_order_num
                                    END ret_org_order_num
                              ,xola.kit_sku
                              ,xola.kit_parent
                              ,DECODE(xoha.bill_level,NULL ,NULL ,DECODE(xola.kit_parent , NULL, DECODE(xola.kit_SKU, NULL, NULL,Xoha.bill_level), xoha.bill_level)) bill_level
                          INTO lc_cost_center_dept
                              ,lc_desk_del_addr
                              ,lc_contract_details
                              ,lc_release_num
                              ,lc_actual_ship_date
                              ,ln_ret_ref_line_id
                              ,lc_ret_org_order_num
                              ,lc_kit_sku
                              ,lc_kit_parent
                              ,lc_bill_level
                          FROM oe_order_headers_all OHA
                              ,oe_order_lines_all OLA
                              ,xx_om_header_attributes_all XOHA
                              ,xx_om_line_attributes_all   XOLA
                         WHERE OHA.order_number = lcu_process_interface_lines.sales_order
                           AND OHA.header_id = OLA.header_id
                           AND OHA.header_id = XOHA.header_id
                           AND OLA.line_id = XOLA.line_id
                           AND OLA.inventory_item_id = lcu_process_interface_lines.inventory_item_id
                           AND OLA.line_number       = lcu_process_interface_lines.sales_order_line;

                     EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                           lc_cost_center_dept  := NULL;
                           lc_desk_del_addr     := NULL;
                           lc_contract_details  := NULL;
                           lc_release_num       := NULL;
                           lc_actual_ship_date  := NULL;
                           lc_kit_sku           := NULL;
                           lc_kit_parent        := NULL;
                           lc_bill_level        := NULL;
                        WHEN OTHERS THEN
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to fectch DFF informatiom from OM'|| SQLERRM);
                     END;

                     -- Update ra_interface_lines_all with order attributes
                     UPDATE ra_interface_lines_all
                        SET attribute6         = lc_cost_center_dept
                           ,attribute7         = lc_desk_del_addr
                           ,attribute8         = SUBSTR(lc_contract_details,1,1)
                           ,attribute9         = SUBSTR(lc_contract_details,3,7)
                           ,attribute10        = SUBSTR(lc_contract_details,11,3)
                           ,attribute11        = lc_release_num
                           ,trx_date           = ship_date_actual
                           ,attribute_category = lc_attribute_category
                           ,gl_date            = lc_gl_date
                           ,request_id         = gn_request_id                  --added 11.3  POS SDR
                           ,attribute4         = TRIM(lc_kit_sku)
                           ,attribute5         = TRIM(lc_kit_parent)
                           ,attribute3         = TRIM(lc_bill_level)
                      WHERE sales_order       = lcu_process_interface_lines.sales_order
                        AND inventory_item_id = lcu_process_interface_lines.inventory_item_id
                        AND sales_order_line  = lcu_process_interface_lines.sales_order_line
                        AND org_id            = FND_PROFILE.VALUE('ORG_ID');



                     IF (p_display_log ='Y' AND lc_ret_org_order_num IS NOT NULL)
                        THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_ret_org_order_num '||lc_ret_org_order_num);
                     END IF;
                  END;

                  -- Updates for Return Order With Reference to Orginal Order
                  BEGIN
                     -- Check if return references orignal order
                     IF lc_ret_org_order_num IS NOT NULL THEN

                        -- Retrieve customer_trx_line_id of original order (for line types of LINE and TAX)
                        IF lcu_process_interface_lines.line_type = 'LINE' THEN
                           IF TO_NUMBER(lcu_process_interface_lines.interface_line_attribute11) = 0 THEN
                              IF (p_display_log ='Y')
                              THEN
                                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside IF - LINE of lc_ret_org_order_num ');
                              END IF;

                              BEGIN
                                 SELECT RCTL.customer_trx_line_id
                                   INTO ln_cust_trx_line_id
                                   FROM ra_customer_trx_lines_all RCTL
                                  WHERE RCTL.line_type=gc_line_type_LINE_hc
                                    AND RCTL.interface_line_attribute6 = TO_CHAR(ln_ret_ref_line_id)
                                    AND RCTL.interface_line_context = 'ORDER ENTRY'
                                    AND TO_NUMBER(RCTL.interface_line_attribute11) = 0 ;
                              EXCEPTION
                                 WHEN NO_DATA_FOUND THEN
                                    ln_cust_trx_line_id  := NULL;
                                 WHEN OTHERS THEN
                                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to fetch the customer trx line id'|| SQLERRM);
                              END;

                           ELSE
                              IF (p_display_log ='Y')
                              THEN
                                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside ELSE - LINE of lc_ret_org_order_num ');
                              END IF;

                              BEGIN
                                 SELECT RCTL.customer_trx_line_id
                                   INTO ln_cust_trx_line_id
                                   FROM ra_customer_trx_lines_all RCTL
                                  WHERE RCTL.line_type=gc_line_type_LINE_hc
                                    AND RCTL.interface_line_attribute6 = TO_CHAR(ln_ret_ref_line_id)
                                    AND RCTL.interface_line_context = 'ORDER ENTRY'
                                    AND TO_NUMBER(RCTL.interface_line_attribute11) <> 0 ;
                              EXCEPTION
                                 WHEN NO_DATA_FOUND THEN
                                    ln_cust_trx_line_id  := NULL;
                                 WHEN OTHERS THEN
                                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to fetch the customer trx line id'|| SQLERRM);
                              END;
                           END IF;

                        ELSIF lcu_process_interface_lines.line_type = 'TAX' THEN
                           IF TO_NUMBER(lcu_process_interface_lines.interface_line_attribute11) = 0 THEN

                              IF (p_display_log ='Y')
                              THEN
                                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside IF - TAX of lc_ret_org_order_num ');
                              END IF;

                              BEGIN
                                 SELECT RCTL1.customer_trx_line_id
                                   INTO ln_cust_trx_line_id
                                   FROM ra_customer_trx_lines_all RCTL
                                       ,ra_customer_trx_lines_all RCTL1
                                       --,ar_vat_tax_all AVTA Commented for R12 upgrade retrofit. QC Defect 26781
									   ,zx_rates_b AVTA -- Added for R12 upgrade retrofit. QC Defect 26781                                       
                                  WHERE RCTL.line_type=gc_line_type_LINE_hc
                                    AND RCTL.interface_line_attribute6 = TO_CHAR(ln_ret_ref_line_id)
                                    AND RCTL.interface_line_context    = 'ORDER ENTRY'
                                    AND TO_NUMBER(RCTL.interface_line_attribute11) = 0
                                    AND RCTL.customer_trx_id = RCTL1.customer_trx_id
                                    AND RCTL1.line_type = gc_line_type_TAX_hc
                                    AND ((RCTL.VAT_TAX_ID IS NOT NULL AND RCTL1.link_to_cust_trx_line_id = RCTL.customer_trx_line_id) OR (RCTL.VAT_TAX_ID IS NULL))
                                    --AND AVTA.vat_tax_id = RCTL1.vat_tax_id Commented for R12 upgrade retrofit. QC Defect 26781
									AND AVTA.tax_rate_id = RCTL1.vat_tax_id --Added for R12 upgrade retrofit. QC Defect 26781
                                    AND (
                                          --(gc_country_value = 'CA' AND AVTA.tax_code = NVL(lcu_process_interface_lines.tax_code, AVTA.tax_code))
										  (gc_country_value = 'CA' AND AVTA.tax_rate_code = NVL(lcu_process_interface_lines.tax_code, AVTA.tax_rate_code))
                                          OR
                                          --(gc_country_value = 'US' AND AVTA.tax_code IN ('SALES', 'STATE')) -- Added Sales and State condition for US to take care of both Old and New Tax Codes
										  (gc_country_value = 'US' AND AVTA.tax_rate_code IN ('SALES', 'STATE')) -- Added for R12 upgrade retrofit. QC Defect 26781
                                        );

									EXCEPTION
                                 WHEN NO_DATA_FOUND THEN
                                    ln_cust_trx_line_id  := NULL;
                                 WHEN OTHERS THEN
                                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to fetch the customer trx line id'|| SQLERRM);
                              END;

                           ELSE
                              IF (p_display_log ='Y')
                              THEN
                                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside ELSE - TAX of lc_ret_org_order_num ');
                              END IF;

                              BEGIN
                                 SELECT RCTL1.customer_trx_line_id
                                   INTO ln_cust_trx_line_id
                                   FROM ra_customer_trx_lines_all RCTL
                                       ,ra_customer_trx_lines_all RCTL1
                                       --,ar_vat_tax_all AVTA	Commented for R12 upgrade retrofit. QC Defect 26781
									   ,zx_rates_b AVTA -- Added for R12 upgrade retrofit. QC Defect 26781                                       
                                  WHERE RCTL.line_type=gc_line_type_LINE_hc
                                    AND RCTL.interface_line_attribute6 = TO_CHAR(ln_ret_ref_line_id)
                                    AND RCTL.interface_line_context    = 'ORDER ENTRY'
                                    AND TO_NUMBER(RCTL.interface_line_attribute11) <> 0
                                    AND RCTL.customer_trx_id = RCTL1.customer_trx_id
                                    AND RCTL1.line_type = gc_line_type_TAX_hc
                                    AND ((RCTL.VAT_TAX_ID IS NOT NULL AND RCTL1.link_to_cust_trx_line_id = RCTL.customer_trx_line_id) OR (RCTL.VAT_TAX_ID IS NULL))
                                    --AND AVTA.vat_tax_id = RCTL1.vat_tax_id  Commented for R12 upgrade retrofit. QC Defect 26781
									AND AVTA.tax_rate_id = RCTL1.vat_tax_id -- Added for R12 upgrade retrofit. QC Defect 26781
                                    AND (
                                          --(gc_country_value = 'CA' AND AVTA.tax_code = NVL(lcu_process_interface_lines.tax_code, AVTA.tax_code)) --Commented for QC Defect 26781.
										  (gc_country_value = 'CA' AND AVTA.tax_rate_code = NVL(lcu_process_interface_lines.tax_code, AVTA.tax_rate_code)) -- Added for R12 upgrade retrofit QC Defect 26781.
                                          OR
                                          --(gc_country_value = 'US' AND AVTA.tax_code IN ('SALES', 'STATE')) -- Added Sales and State condition for US to take care of both Old and New Tax Codes
										  (gc_country_value = 'US' AND AVTA.tax_rate_code IN ('SALES', 'STATE'))  -- Added for R12 upgrade retrofit QC Defect 26781.
                                        );
									EXCEPTION
                                 WHEN NO_DATA_FOUND THEN
                                    ln_cust_trx_line_id  := NULL;
                                 WHEN OTHERS THEN
                                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to fetch the customer trx line id'|| SQLERRM);
                              END;

                           END IF;

                        END IF;

                        IF (p_display_log ='Y')
                        THEN
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_cust_trx_line_id ' || ln_cust_trx_line_id);
                        END IF;

                        ---------------------------------------------------------------------
                        -- This update will only occur for Return orders that are credit
                        -- memos and will exclude order sources of POE and JDA
                        ---------------------------------------------------------------------
                        BEGIN
                           UPDATE ra_interface_lines_all
                              SET reference_line_id  = NULL                                                -- Added for CR 733 Defect # 2627
                            WHERE sales_order       = lcu_process_interface_lines.sales_order
                              AND inventory_item_id = lcu_process_interface_lines.inventory_item_id
                              AND sales_order_line  = lcu_process_interface_lines.sales_order_line
                              AND line_type         = lcu_process_interface_lines.line_type               -- Added this as part of Credit Memo scenario 2569 RK
                              AND NVL(tax_code, 1)  = NVL(lcu_process_interface_lines.tax_code, 1)        -- Added this as part of Credit Memo scenario 2569 RK
                              AND org_id            = FND_PROFILE.VALUE('ORG_ID')
                              AND cust_trx_type_id IN (SELECT cust_trx_type_id
                                                         FROM ra_cust_trx_types_all   -- Added for Defect 12365
                                                        WHERE type = 'CM')            -- by P.Marco on 30-JAN-09
                              AND sales_order  NOT IN (SELECT order_number
                                                         FROM oe_order_headers_all a                                 -- Added for Defect 12365
                                                        WHERE a.order_source_id IN (SELECT order_source_id           -- by P.Marco on 30-JAN-09
                                                                                      FROM oe_order_sources          -- Added for Defect 12365
                                                                                     WHERE NAME IN ('POE', 'JDA'))); -- by P.Marco on 30-JAN-09

                           IF (p_display_log ='Y') THEN
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------------------------------------------');
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'Tax Code             : '||lcu_process_interface_lines.tax_code);
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'Inventory Item Id    : '||lcu_process_interface_lines.inventory_item_id);
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'Sales Order Line     : '||lcu_process_interface_lines.sales_order_line);

                              IF lcu_process_interface_lines.line_type = gc_line_type_LINE_hc THEN
                                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of RA_INTERFACE_LINES Revenue lines updated for Return Reference : ' || SQL%ROWCOUNT); -- Added log as part of Credit Memo Scenario - RK 2569
                              ELSIF lcu_process_interface_lines.line_type = gc_line_type_TAX_hc THEN
                                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of RA_INTERFACE_LINES Tax lines updated for Return Reference : ' || SQL%ROWCOUNT); -- Added log as part of Credit Memo Scenario - RK 2569
                              END IF;

                              FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------------------------------------------');
                           END IF;

                        EXCEPTION
                           WHEN NO_DATA_FOUND THEN
                              FND_MESSAGE.SET_NAME(application => 'XXFIN'
                                                  ,name        => 'XX_AR_0010_CREATE_ACT_NO_DATA');
                              FND_MESSAGE.SET_TOKEN(token => 'COL'
                                                   ,value => ' OE table values for CM sales order:'||
                                                             lcu_process_interface_lines.sales_order||
                                                             'and inventory intem ID:'||lcu_process_interface_lines.inventory_item_id||
                                                             SQLErrm);
                              lc_error_msg := FND_MESSAGE.GET;
                              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_msg);
                              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                  p_program_type            => 'CONCURRENT PROGRAM'
                                 ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                 ,p_module_name             => 'AR'
                                 ,p_error_location          => 'Oracle Error '||SQLERRM
                                 ,p_error_message_count     => gn_msg_cnt + 1
                                 ,p_error_message_code      => 'E'
                                 ,p_error_message           => lc_error_msg
                                 ,p_error_message_severity  => 'Major'
                                 ,p_notify_flag             => 'N'
                                 ,p_object_type             => 'Creating Accounts');
                           WHEN OTHERS THEN
                              FND_MESSAGE.SET_NAME(application => 'XXFIN'
                                                  ,name        => 'XX_AR_0011_CREATE_ACT_OTHERS');
                              FND_MESSAGE.SET_TOKEN(token => 'COL'
                                                   ,value => ' OE table values for CM sales order:'||
                                                             lcu_process_interface_lines.sales_order||
                                                             'and inventory intem ID:'||lcu_process_interface_lines.inventory_item_id||
                                                            SQLErrm);
                              lc_error_msg := FND_MESSAGE.GET;
                              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_msg);
                              XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                    p_program_type            => 'CONCURRENT PROGRAM'
                                   ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                   ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                   ,p_module_name             => 'AR'
                                   ,p_error_location          => 'Oracle Error '||SQLERRM
                                   ,p_error_message_count     => gn_msg_cnt+1
                                   ,p_error_message_code      => 'E'
                                   ,p_error_message           => lc_error_msg
                                   ,p_error_message_severity  => 'Major'
                                   ,p_notify_flag             => 'N'
                                   ,p_object_type             => 'Creating Accounts');
                        END;

                        ---------------------------------------------------------------------
                        -- Remove reference_line_id for the return / credit memo.
                        -- This prevents Auto Application of credit memo to Invoice
                        -- Only AOPS orders are populated with reference_line_id is.
                        -- Probably should restrict this update to just AOPS in the future.
                        ---------------------------------------------------------------------
                        BEGIN
                           IF (ln_cust_trx_line_id IS NOT NULL) THEN
                              UPDATE ra_interface_lines_all RIL
                                 SET RIL.attribute14        = ln_cust_trx_line_id -- Added for CR 733 Defect # 2627
                                    ,RIL.reference_line_id  = NULL
                               WHERE RIL.sales_order = lcu_process_interface_lines.sales_order
                                 AND RIL.org_id      = FND_PROFILE.VALUE('ORG_ID')
                                 AND RIL.interface_line_context = 'ORDER ENTRY'
                                 AND RIL.interface_line_attribute6 = lcu_process_interface_lines.interface_line_attribute6
                                 AND EXISTS (SELECT 1
                                               FROM oe_order_headers_all     OOH
                                                   ,xx_om_return_tenders_all XORT
                                              WHERE OOH.header_id    = XORT.header_id
                                                AND OOH.order_number = RIL.sales_order);
                           END IF;
                        END;

                     END IF;
                  END;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     FND_MESSAGE.SET_NAME(application => 'XXFIN'
                                         ,name        => 'XX_AR_0010_CREATE_ACT_NO_DATA');
                     FND_MESSAGE.SET_TOKEN(token => 'COL'
                                          ,value => ' OE table values for sales order:'||
                                                    lcu_process_interface_lines.sales_order||
                                                    'and inventory intem ID:'||lcu_process_interface_lines.inventory_item_id||
                                                    SQLErrm);
                     lc_error_msg := FND_MESSAGE.GET;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_msg);
                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                               p_program_type            => 'CONCURRENT PROGRAM'
                              ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                              ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                              ,p_module_name             => 'AR'
                              ,p_error_location          => 'Oracle Error '||SQLERRM
                              ,p_error_message_count     => gn_msg_cnt + 1
                              ,p_error_message_code      => 'E'
                              ,p_error_message           => lc_error_msg
                              ,p_error_message_severity  => 'Major'
                              ,p_notify_flag             => 'N'
                              ,p_object_type             => 'Creating Accounts');
                  WHEN OTHERS THEN
                     FND_MESSAGE.SET_NAME(application => 'XXFIN'
                                         ,name        => 'XX_AR_0011_CREATE_ACT_OTHERS');
                     FND_MESSAGE.SET_TOKEN(token  => 'COL'
                                          ,value => ' OE table values for sales order:'||
                                                    lcu_process_interface_lines.sales_order||
                                                    'and inventory intem ID:'||lcu_process_interface_lines.inventory_item_id||
                                                    SQLErrm);
                     lc_error_msg := FND_MESSAGE.GET;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_msg);
                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                 p_program_type            => 'CONCURRENT PROGRAM'
                                ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                ,p_module_name             => 'AR'
                                ,p_error_location          => 'Oracle Error '||SQLERRM
                                ,p_error_message_count     => gn_msg_cnt+1
                                ,p_error_message_code      => 'E'
                                ,p_error_message           => lc_error_msg
                                ,p_error_message_severity  => 'Major'
                                ,p_notify_flag             => 'N'
                                ,p_object_type             => 'Creating Accounts');
               END;

               -- Track total number of records processed
               ln_tot_count := ln_tot_count + 1;
               ln_count     := ln_count + 1;

               -- Issue commit after processing 2000 invoice lines
               IF ln_count = 2000 THEN
                  ln_count := 1; -- Reset counter
                  COMMIT;
               END IF;

            END IF;----Closing if for the Sales order range

         END LOOP;

         /*************************************************************************
         ** Step #18 ? Update Invoices with No Tax Amount to Prevent Processing  **
         *************************************************************************/
         -- Update invoices lines to prevent Auto Invoice from importing
         -- invoices with TAX line, but no tax value.
         BEGIN
            IF p_sales_order_low IS NULL AND p_sales_order_high IS NULL THEN
               UPDATE ra_interface_lines_all RIL
                  SET RIL.interface_status = 'X'
                WHERE RIL.batch_source_name =
                                    NVL(p_invoice_source,RIL.batch_source_name) --added 11.3  POS SDR
                  AND RIL.org_id = FND_PROFILE.VALUE('ORG_ID')
                  AND RIL.request_id = gn_request_id
                  AND EXISTS(SELECT RIL1.SALES_ORDER
                               FROM ra_interface_lines_all RIL1
                                   ,oe_order_lines_all OOLA
                              WHERE RIL1.sales_order = RIL.sales_order
                                AND RIL1.LINE_TYPE = 'LINE'
                                AND OOLA.line_id = RIL1.interface_line_attribute6
                                AND OOLA.tax_value <> 0)
                                AND NOT EXISTS (SELECT 1
                                                  FROM ra_interface_lines_all RIL2
                                                 WHERE RIL2.sales_order = RIL.sales_order
                                                   AND RIL2.line_type = 'TAX'
                                                   AND RIL2.amount <> 0);

               ln_no_tax_lines_RIL := SQL%ROWCOUNT;
               IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated Invoices with NO tax amt TEST' || SQL%ROWCOUNT);
			   END IF;
                -----------------------------------------------------------------
                -- Open BULK insert for updating POS exception invoices to a
                -- interface status of X
                -----------------------------------------------------------------
                OPEN lcu_pos_exp_inv;
                LOOP
                   FETCH lcu_pos_exp_inv BULK COLLECT INTO lt_pos_trx2 LIMIT 5000;
                   EXIT WHEN lt_pos_trx2.COUNT = 0;

                   FOR i IN 1 .. lt_pos_trx2.COUNT
                   LOOP
                      lt_trx_number2(i) := lt_pos_trx2(i).INTERFACE_LINE_ATTRIBUTE1;
                   END LOOP;
                     IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Updating POS Invoices to X for  '
                                         ||'Exceptions found');
					 END IF;
                     -----------------------------------------
                     -- Bulk Update for POS exceptions
                     -----------------------------------------
                     FORALL i IN 1 .. lt_pos_trx2.count
                        UPDATE ra_interface_lines_all
                           SET interface_status = 'X'
                         WHERE interface_line_attribute1 = lt_trx_number2(i)
                           AND EXISTS (SELECT 1
                                         FROM xx_ar_intstorecust_otc OTC
                                        WHERE orig_system_bill_customer_id = OTC.cust_account_id);


                END LOOP;
                CLOSE lcu_pos_exp_inv;

            ELSIF (    p_sales_order_low  IS NOT NULL
                   AND p_sales_order_high IS NOT NULL
                   AND p_sales_order_low  = p_sales_order_high)
                OR
                  (    p_sales_order_low  IS NOT NULL
                   AND p_sales_order_high IS NOT NULL) THEN

                  UPDATE ra_interface_lines_all RIL
                     SET RIL.interface_status = 'X'
                        ,RIL.request_id = gn_request_id
                   WHERE RIL.batch_source_name =
                                     NVL(p_invoice_source,RIL.batch_source_name) --added 11.3  POS SDR
                     AND RIL.org_id = FND_PROFILE.VALUE('ORG_ID')
                     AND RIL.sales_order >= p_sales_order_low
                     AND RIL.sales_order <= p_sales_order_high
                     AND EXISTS (SELECT RIL1.sales_order
                                   FROM ra_interface_lines_all RIL1
                                       ,oe_order_lines_all     OOLA
                    WHERE RIL1.sales_order = RIL.sales_order
                      AND RIL1.LINE_TYPE = 'LINE'
                      AND OOLA.line_id = RIL1.interface_line_attribute6
                      AND OOLA.tax_value <> 0)
                      AND NOT EXISTS (SELECT 1
                                        FROM ra_interface_lines_all RIL2
                                       WHERE RIL2.sales_order = RIL.sales_order
                                         AND RIL2.line_type = 'TAX'
                                         AND RIL2.amount <> 0);

                 ln_no_tax_lines_RIL := SQL%ROWCOUNT;

                -----------------------------------------------------------------
                -- Open BULK insert for updating POS exception invoices to a
                -- interface status of X
                -----------------------------------------------------------------
                OPEN lcu_pos_exp_inv;
                LOOP
                   FETCH lcu_pos_exp_inv BULK COLLECT INTO lt_pos_trx2 LIMIT 5000;
                   EXIT WHEN lt_pos_trx2.COUNT = 0;

                   FOR i IN 1 .. lt_pos_trx2.COUNT
                   LOOP
                      lt_trx_number2(i) := lt_pos_trx2(i).INTERFACE_LINE_ATTRIBUTE1;
                   END LOOP;
                    IF (p_display_log ='Y') THEN  -- Added IF Condition for Defect# 35156
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Updating POS Invoices to X for  '
                                         ||'Exceptions found');
					END IF;
                     -----------------------------------------
                     -- Bulk Update for POS exceptions
                     -----------------------------------------
                     FORALL i IN 1 .. lt_pos_trx2.count
                        UPDATE ra_interface_lines_all
                           SET interface_status = 'X'
                         WHERE interface_line_attribute1 = lt_trx_number2(i)
                           AND EXISTS (SELECT 1
                                         FROM xx_ar_intstorecust_otc OTC
                                        WHERE orig_system_bill_customer_id = OTC.cust_account_id);


                END LOOP;
                CLOSE lcu_pos_exp_inv;


            END IF;

            IF (p_display_log ='Y')
            THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of Records marked with Interface Status E'||
                                              'for which there were no Tax Rows inserted in '||
                                              'RA_INTERFACE_LINES table through Master: ' || SQL%ROWCOUNT);
            END IF;

            COMMIT;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               FND_MESSAGE.SET_NAME(application => 'XXFIN'
                                   ,name        => 'XX_AR_0010_CREATE_ACT_NO_DATA');
               FND_MESSAGE.SET_TOKEN(token  => 'COL'
                                    ,value  => 'No interface lines are found for Update');
               lc_error_msg := FND_MESSAGE.GET;
            WHEN OTHERS THEN
               FND_MESSAGE.SET_NAME(application => 'XXFIN'
                                   ,name        => 'XX_AR_0011_CREATE_ACT_OTHERS');
               FND_MESSAGE.SET_TOKEN(token  => 'COL'
                                    ,value  => 'No interface lines are found for Update');
               lc_error_msg := FND_MESSAGE.GET;
               FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_msg);
               XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => gn_msg_cnt+1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts');
         END;

         /*********************************************************************
         ** Step #19 ? Stage Invoices Requires Summarization Before Importing **
         ********************************************************************/
         IF ln_summary_inv_line_cnt > 0  THEN     --added 11.3  POS SDR
            FND_FILE.PUT_LINE(FND_FILE.LOG,'SUMMARY Count is greater than 0' );
            BEGIN
                SELECT tv.target_value1
                  INTO lc_trans_batch_name
                  FROM xx_fin_translatedefinition    td
                      ,xx_fin_translatevalues        tv
                 WHERE translation_name ='OD_AR_INVOICING_DEFAULTS'
                   AND tv.translate_id  = td.translate_id
                   AND tv.source_value1 = (SELECT NAME
                                             FROM hr_all_organization_units
                                            WHERE organization_id  = p_org_id)
                   AND tv.target_value3 = 'Y'
                   AND td.enabled_flag  = 'Y'
                   AND tv.enabled_flag  = 'Y'
                   -- Added condition for Defect 20687 V4.0
                   AND tv.target_value6 = p_batch_group;

               FND_FILE.PUT_LINE(FND_FILE.LOG,'Batch name'||lc_trans_batch_name );
            EXCEPTION
              WHEN OTHERS THEN
                     lc_error_loc := 'Retrieving valid batch name from '
                                 ||'translation table OD_AR_INVOICING_DEFAULTS';
                      RAISE EX_XX_BATCH_NAME_ERR;

            END;

            -----------------------------------------------------------------
            -- Open BULK insert for inserting POS invoices to the XX tables
            -- and deleting from the RA tables
            -----------------------------------------------------------------
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameters for POS cursor' || lc_trans_batch_name  || gn_request_id);
            OPEN lcu_pos_inv;
            LOOP
               FETCH lcu_pos_inv BULK COLLECT INTO lt_pos_trx LIMIT 5000;
               EXIT WHEN lt_pos_trx.COUNT = 0;

               FOR i IN 1 .. lt_pos_trx.COUNT
               LOOP
                  lt_trx_number(i) := lt_pos_trx(i).INTERFACE_LINE_ATTRIBUTE1;
               END LOOP;

                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Inserting POS into XX_RA_INT_LINES_ALL ' );
                 -----------------------------------------
                 --Inserting POS into XX_RA_INT_LINES_ALL
                 -----------------------------------------
                 FORALL i IN 1 .. lt_pos_trx.count
                    /*INSERT INTO XX_RA_INT_LINES_ALL
                       (SELECT *
                          FROM RA_INTERFACE_LINES_ALL
                          WHERE interface_line_attribute1 = lt_trx_number(i)
                          AND INTERFACE_LINE_CONTEXT = 'ORDER ENTRY');*/

						  --Changed for R12 Retrofit
						  INSERT INTO XX_RA_INT_LINES_ALL
							 (interface_line_id,
                       interface_line_context,
                       interface_line_attribute1,
                       interface_line_attribute2,
                       interface_line_attribute3,
                       interface_line_attribute4,
                       interface_line_attribute5,
                       interface_line_attribute6,
                       interface_line_attribute7,
                       interface_line_attribute8,
                       batch_source_name,
                       set_of_books_id,
                       line_type,
                       description,
                       currency_code,
                       amount,
                       cust_trx_type_name,
                       cust_trx_type_id,
                       term_name,
                       term_id,
                       orig_system_batch_name,
                       orig_system_bill_customer_ref,
                       orig_system_bill_customer_id,
                       orig_system_bill_address_ref,
                       orig_system_bill_address_id,
                       orig_system_bill_contact_ref,
                       orig_system_bill_contact_id,
                       orig_system_ship_customer_ref,
                       orig_system_ship_customer_id,
                       orig_system_ship_address_ref,
                       orig_system_ship_address_id,
                       orig_system_ship_contact_ref,
                       orig_system_ship_contact_id,
                       orig_system_sold_customer_ref,
                       orig_system_sold_customer_id,
                       link_to_line_id,
                       link_to_line_context,
                       link_to_line_attribute1,
                       link_to_line_attribute2,
                       link_to_line_attribute3,
                       link_to_line_attribute4,
                       link_to_line_attribute5,
                       link_to_line_attribute6,
                       link_to_line_attribute7,
                       receipt_method_name,
                       receipt_method_id,
                       conversion_type,
                       conversion_date,
                       conversion_rate,
                       customer_trx_id,
                       trx_date,
                       gl_date,
                       document_number,
                       trx_number,
                       line_number,
                       quantity,
                       quantity_ordered,
                       unit_selling_price,
                       unit_standard_price,
                       printing_option,
                       interface_status,
                       request_id,
                       related_batch_source_name,
                       related_trx_number,
                       related_customer_trx_id,
                       previous_customer_trx_id,
                       credit_method_for_acct_rule,
                       credit_method_for_installments,
                       reason_code,
                       tax_rate,
                       tax_code,
                       tax_precedence,
                       exception_id,
                       exemption_id,
                       ship_date_actual,
                       fob_point,
                       ship_via,
                       waybill_number,
                       invoicing_rule_name,
                       invoicing_rule_id,
                       accounting_rule_name,
                       accounting_rule_id,
                       accounting_rule_duration,
                       rule_start_date,
                       primary_salesrep_number,
                       primary_salesrep_id,
                       sales_order,
                       sales_order_line,
                       sales_order_date,
                       sales_order_source,
                       sales_order_revision,
                       purchase_order,
                       purchase_order_revision,
                       purchase_order_date,
                       agreement_name,
                       agreement_id,
                       memo_line_name,
                       memo_line_id,
                       inventory_item_id,
                       mtl_system_items_seg1,
                       mtl_system_items_seg2,
                       mtl_system_items_seg3,
                       mtl_system_items_seg4,
                       mtl_system_items_seg5,
                       mtl_system_items_seg6,
                       mtl_system_items_seg7,
                       mtl_system_items_seg8,
                       mtl_system_items_seg9,
                       mtl_system_items_seg10,
                       mtl_system_items_seg11,
                       mtl_system_items_seg12,
                       mtl_system_items_seg13,
                       mtl_system_items_seg14,
                       mtl_system_items_seg15,
                       mtl_system_items_seg16,
                       mtl_system_items_seg17,
                       mtl_system_items_seg18,
                       mtl_system_items_seg19,
                       mtl_system_items_seg20,
                       reference_line_id,
                       reference_line_context,
                       reference_line_attribute1,
                       reference_line_attribute2,
                       reference_line_attribute3,
                       reference_line_attribute4,
                       reference_line_attribute5,
                       reference_line_attribute6,
                       reference_line_attribute7,
                       territory_id,
                       territory_segment1,
                       territory_segment2,
                       territory_segment3,
                       territory_segment4,
                       territory_segment5,
                       territory_segment6,
                       territory_segment7,
                       territory_segment8,
                       territory_segment9,
                       territory_segment10,
                       territory_segment11,
                       territory_segment12,
                       territory_segment13,
                       territory_segment14,
                       territory_segment15,
                       territory_segment16,
                       territory_segment17,
                       territory_segment18,
                       territory_segment19,
                       territory_segment20,
                       attribute_category,
                       attribute1,
                       attribute2,
                       attribute3,
                       attribute4,
                       attribute5,
                       attribute6,
                       attribute7,
                       attribute8,
                       attribute9,
                       attribute10,
                       attribute11,
                       attribute12,
                       attribute13,
                       attribute14,
                       attribute15,
                       header_attribute_category,
                       header_attribute1,
                       header_attribute2,
                       header_attribute3,
                       header_attribute4,
                       header_attribute5,
                       header_attribute6,
                       header_attribute7,
                       header_attribute8,
                       header_attribute9,
                       header_attribute10,
                       header_attribute11,
                       header_attribute12,
                       header_attribute13,
                       header_attribute14,
                       header_attribute15,
                       comments,
                       internal_notes,
                       initial_customer_trx_id,
                       ussgl_transaction_code_context,
                       ussgl_transaction_code,
                       acctd_amount,
                       customer_bank_account_id,
                       customer_bank_account_name,
                       uom_code,
                       uom_name,
                       document_number_sequence_id,
                       link_to_line_attribute10,
                       link_to_line_attribute11,
                       link_to_line_attribute12,
                       link_to_line_attribute13,
                       link_to_line_attribute14,
                       link_to_line_attribute15,
                       link_to_line_attribute8,
                       link_to_line_attribute9,
                       reference_line_attribute10,
                       reference_line_attribute11,
                       reference_line_attribute12,
                       reference_line_attribute13,
                       reference_line_attribute14,
                       reference_line_attribute15,
                       reference_line_attribute8,
                       reference_line_attribute9,
                       interface_line_attribute10,
                       interface_line_attribute11,
                       interface_line_attribute12,
                       interface_line_attribute13,
                       interface_line_attribute14,
                       interface_line_attribute15,
                       interface_line_attribute9,
                       vat_tax_id,
                       reason_code_meaning,
                       last_period_to_credit,
                       paying_customer_id,
                       paying_site_use_id,
                       tax_exempt_flag,
                       tax_exempt_reason_code,
                       tax_exempt_reason_code_meaning,
                       tax_exempt_number,
                       sales_tax_id,
                       created_by,
                       creation_date,
                       last_updated_by,
                       last_update_date,
                       last_update_login,
                       location_segment_id,
                       movement_id,
                       org_id,
                       amount_includes_tax_flag,
                       header_gdf_attr_category,
                       header_gdf_attribute1,
                       header_gdf_attribute2,
                       header_gdf_attribute3,
                       header_gdf_attribute4,
                       header_gdf_attribute5,
                       header_gdf_attribute6,
                       header_gdf_attribute7,
                       header_gdf_attribute8,
                       header_gdf_attribute9,
                       header_gdf_attribute10,
                       header_gdf_attribute11,
                       header_gdf_attribute12,
                       header_gdf_attribute13,
                       header_gdf_attribute14,
                       header_gdf_attribute15,
                       header_gdf_attribute16,
                       header_gdf_attribute17,
                       header_gdf_attribute18,
                       header_gdf_attribute19,
                       header_gdf_attribute20,
                       header_gdf_attribute21,
                       header_gdf_attribute22,
                       header_gdf_attribute23,
                       header_gdf_attribute24,
                       header_gdf_attribute25,
                       header_gdf_attribute26,
                       header_gdf_attribute27,
                       header_gdf_attribute28,
                       header_gdf_attribute29,
                       header_gdf_attribute30,
                       line_gdf_attr_category,
                       line_gdf_attribute1,
                       line_gdf_attribute2,
                       line_gdf_attribute3,
                       line_gdf_attribute4,
                       line_gdf_attribute5,
                       line_gdf_attribute6,
                       line_gdf_attribute7,
                       line_gdf_attribute8,
                       line_gdf_attribute9,
                       line_gdf_attribute10,
                       line_gdf_attribute11,
                       line_gdf_attribute12,
                       line_gdf_attribute13,
                       line_gdf_attribute14,
                       line_gdf_attribute15,
                       line_gdf_attribute16,
                       line_gdf_attribute17,
                       line_gdf_attribute18,
                       line_gdf_attribute19,
                       line_gdf_attribute20,
                       reset_trx_date_flag,
                       payment_server_order_num,
                       approval_code,
                       address_verification_code,
                       warehouse_id,
                       translated_description,
                       cons_billing_number,
                       promised_commitment_amount,
                       payment_set_id,
                       original_gl_date,
                       contract_line_id,
                       contract_id,
                       source_data_key1,
                       source_data_key2,
                       source_data_key3,
                       source_data_key4,
                       source_data_key5,
                       invoiced_line_acctg_level,
                       override_auto_accounting_flag,
                       tax_regime_code,                       --Added for R12 Retrofit Changes
                       tax,                                   --Added for R12 Retrofit Changes
                       tax_status_code,                       --Added for R12 Retrofit Changes
                       tax_rate_code                          --Added for R12 Retrofit Changes
                       )
                    SELECT
                    	  interface_line_id,
                       interface_line_context,
                       interface_line_attribute1,
                       interface_line_attribute2,
                       interface_line_attribute3,
                       interface_line_attribute4,
                       interface_line_attribute5,
                       interface_line_attribute6,
                       interface_line_attribute7,
                       interface_line_attribute8,
                       batch_source_name,
                       set_of_books_id,
                       line_type,
                       description,
                       currency_code,
                       amount,
                       cust_trx_type_name,
                       cust_trx_type_id,
                       term_name,
                       term_id,
                       orig_system_batch_name,
                       orig_system_bill_customer_ref,
                       orig_system_bill_customer_id,
                       orig_system_bill_address_ref,
                       orig_system_bill_address_id,
                       orig_system_bill_contact_ref,
                       orig_system_bill_contact_id,
                       orig_system_ship_customer_ref,
                       orig_system_ship_customer_id,
                       orig_system_ship_address_ref,
                       orig_system_ship_address_id,
                       orig_system_ship_contact_ref,
                       orig_system_ship_contact_id,
                       orig_system_sold_customer_ref,
                       orig_system_sold_customer_id,
                       link_to_line_id,
                       link_to_line_context,
                       link_to_line_attribute1,
                       link_to_line_attribute2,
                       link_to_line_attribute3,
                       link_to_line_attribute4,
                       link_to_line_attribute5,
                       link_to_line_attribute6,
                       link_to_line_attribute7,
                       receipt_method_name,
                       receipt_method_id,
                       conversion_type,
                       conversion_date,
                       conversion_rate,
                       customer_trx_id,
                       trx_date,
                       gl_date,
                       document_number,
                       trx_number,
                       line_number,
                       quantity,
                       quantity_ordered,
                       unit_selling_price,
                       unit_standard_price,
                       printing_option,
                       interface_status,
                       request_id,
                       related_batch_source_name,
                       related_trx_number,
                       related_customer_trx_id,
                       previous_customer_trx_id,
                       credit_method_for_acct_rule,
                       credit_method_for_installments,
                       reason_code,
                       DECODE(LINE_TYPE,'TAX',(decode(INTERFACE_LINE_ATTRIBUTE9,'TAX',gc_rate_percent,'GST',gc_rate_percent_state,'PST',gc_rate_percent_county))),      --Modified for R12 Retrofit
                       tax_code,
                       tax_precedence,
                       exception_id,
                       exemption_id,
                       ship_date_actual,
                       fob_point,
                       ship_via,
                       waybill_number,
                       invoicing_rule_name,
                       invoicing_rule_id,
                       accounting_rule_name,
                       accounting_rule_id,
                       accounting_rule_duration,
                       rule_start_date,
                       primary_salesrep_number,
                       primary_salesrep_id,
                       sales_order,
                       sales_order_line,
                       sales_order_date,
                       sales_order_source,
                       sales_order_revision,
                       purchase_order,
                       purchase_order_revision,
                       purchase_order_date,
                       agreement_name,
                       agreement_id,
                       memo_line_name,
                       memo_line_id,
                       inventory_item_id,
                       mtl_system_items_seg1,
                       mtl_system_items_seg2,
                       mtl_system_items_seg3,
                       mtl_system_items_seg4,
                       mtl_system_items_seg5,
                       mtl_system_items_seg6,
                       mtl_system_items_seg7,
                       mtl_system_items_seg8,
                       mtl_system_items_seg9,
                       mtl_system_items_seg10,
                       mtl_system_items_seg11,
                       mtl_system_items_seg12,
                       mtl_system_items_seg13,
                       mtl_system_items_seg14,
                       mtl_system_items_seg15,
                       mtl_system_items_seg16,
                       mtl_system_items_seg17,
                       mtl_system_items_seg18,
                       mtl_system_items_seg19,
                       mtl_system_items_seg20,
                       reference_line_id,
                       reference_line_context,
                       reference_line_attribute1,
                       reference_line_attribute2,
                       reference_line_attribute3,
                       reference_line_attribute4,
                       reference_line_attribute5,
                       reference_line_attribute6,
                       reference_line_attribute7,
                       territory_id,
                       territory_segment1,
                       territory_segment2,
                       territory_segment3,
                       territory_segment4,
                       territory_segment5,
                       territory_segment6,
                       territory_segment7,
                       territory_segment8,
                       territory_segment9,
                       territory_segment10,
                       territory_segment11,
                       territory_segment12,
                       territory_segment13,
                       territory_segment14,
                       territory_segment15,
                       territory_segment16,
                       territory_segment17,
                       territory_segment18,
                       territory_segment19,
                       territory_segment20,
                       attribute_category,
                       attribute1,
                       attribute2,
                       attribute3,
                       attribute4,
                       attribute5,
                       attribute6,
                       attribute7,
                       attribute8,
                       attribute9,
                       attribute10,
                       attribute11,
                       attribute12,
                       attribute13,
                       attribute14,
                       attribute15,
                       header_attribute_category,
                       header_attribute1,
                       header_attribute2,
                       header_attribute3,
                       header_attribute4,
                       header_attribute5,
                       header_attribute6,
                       header_attribute7,
                       header_attribute8,
                       header_attribute9,
                       header_attribute10,
                       header_attribute11,
                       header_attribute12,
                       header_attribute13,
                       header_attribute14,
                       header_attribute15,
                       comments,
                       internal_notes,
                       initial_customer_trx_id,
                       ussgl_transaction_code_context,
                       ussgl_transaction_code,
                       acctd_amount,
                       customer_bank_account_id,
                       customer_bank_account_name,
                       uom_code,
                       uom_name,
                       document_number_sequence_id,
                       link_to_line_attribute10,
                       link_to_line_attribute11,
                       link_to_line_attribute12,
                       link_to_line_attribute13,
                       link_to_line_attribute14,
                       link_to_line_attribute15,
                       link_to_line_attribute8,
                       link_to_line_attribute9,
                       reference_line_attribute10,
                       reference_line_attribute11,
                       reference_line_attribute12,
                       reference_line_attribute13,
                       reference_line_attribute14,
                       reference_line_attribute15,
                       reference_line_attribute8,
                       reference_line_attribute9,
                       interface_line_attribute10,
                       interface_line_attribute11,
                       interface_line_attribute12,
                       interface_line_attribute13,
                       interface_line_attribute14,
                       interface_line_attribute15,
                       interface_line_attribute9,
                       vat_tax_id,
                       reason_code_meaning,
                       last_period_to_credit,
                       paying_customer_id,
                       paying_site_use_id,
                       tax_exempt_flag,
                       tax_exempt_reason_code,
                       tax_exempt_reason_code_meaning,
                       tax_exempt_number,
                       sales_tax_id,
                       created_by,
                       creation_date,
                       last_updated_by,
                       last_update_date,
                       last_update_login,
                       location_segment_id,
                       movement_id,
                       org_id,
                       amount_includes_tax_flag,
                       header_gdf_attr_category,
                       header_gdf_attribute1,
                       header_gdf_attribute2,
                       header_gdf_attribute3,
                       header_gdf_attribute4,
                       header_gdf_attribute5,
                       header_gdf_attribute6,
                       header_gdf_attribute7,
                       header_gdf_attribute8,
                       header_gdf_attribute9,
                       header_gdf_attribute10,
                       header_gdf_attribute11,
                       header_gdf_attribute12,
                       header_gdf_attribute13,
                       header_gdf_attribute14,
                       header_gdf_attribute15,
                       header_gdf_attribute16,
                       header_gdf_attribute17,
                       header_gdf_attribute18,
                       header_gdf_attribute19,
                       header_gdf_attribute20,
                       header_gdf_attribute21,
                       header_gdf_attribute22,
                       header_gdf_attribute23,
                       header_gdf_attribute24,
                       header_gdf_attribute25,
                       header_gdf_attribute26,
                       header_gdf_attribute27,
                       header_gdf_attribute28,
                       header_gdf_attribute29,
                       header_gdf_attribute30,
                       line_gdf_attr_category,
                       line_gdf_attribute1,
                       line_gdf_attribute2,
                       line_gdf_attribute3,
                       line_gdf_attribute4,
                       line_gdf_attribute5,
                       line_gdf_attribute6,
                       line_gdf_attribute7,
                       line_gdf_attribute8,
                       line_gdf_attribute9,
                       line_gdf_attribute10,
                       line_gdf_attribute11,
                       line_gdf_attribute12,
                       line_gdf_attribute13,
                       line_gdf_attribute14,
                       line_gdf_attribute15,
                       line_gdf_attribute16,
                       line_gdf_attribute17,
                       line_gdf_attribute18,
                       line_gdf_attribute19,
                       line_gdf_attribute20,
                       reset_trx_date_flag,
                       payment_server_order_num,
                       approval_code,
                       address_verification_code,
                       warehouse_id,
                       translated_description,
                       cons_billing_number,
                       promised_commitment_amount,
                       payment_set_id,
                       original_gl_date,
                       contract_line_id,
                       contract_id,
                       source_data_key1,
                       source_data_key2,
                       source_data_key3,
                       source_data_key4,
                       source_data_key5,
                       invoiced_line_acctg_level,
                       override_auto_accounting_flag,
                       DECODE(LINE_TYPE,'TAX',(decode(INTERFACE_LINE_ATTRIBUTE9,'TAX',gc_tax_regime_code_us,'GST',gc_tax_regime_code_ca,'PST',gc_tax_regime_code_ca))),                       --Added for R12 Retrofit Changes
                       DECODE(LINE_TYPE,'TAX',(decode(INTERFACE_LINE_ATTRIBUTE9,'TAX',gc_tax_line1,'GST',gc_tax_state,'PST',gc_tax_county))),                                   --Added for R12 Retrofit Changes
                       DECODE(LINE_TYPE,'TAX',(decode(INTERFACE_LINE_ATTRIBUTE9,'TAX',gc_tax_status_code_us,'GST',gc_tax_status_code_ca,'PST',gc_tax_status_code_ca1))),                       --Added for R12 Retrofit Changes
                       DECODE(LINE_TYPE,'TAX',(decode(INTERFACE_LINE_ATTRIBUTE9,'TAX',gc_tax_rate_code,'GST',gc_tax_rate_state,'PST',gc_tax_rate_county)))                          --Added for R12 Retrofit Changes
                    FROM	RA_INTERFACE_LINES_ALL
                    WHERE 	interface_line_attribute1 = lt_trx_number(i)
                    AND 	INTERFACE_LINE_CONTEXT = 'ORDER ENTRY';

                 ln_ra_rows_ins_int_cnt    := SQL%ROWCOUNT;
                 ln_ra_rows_ins_int_cnt_gt := ln_ra_rows_ins_int_cnt_gt + ln_ra_rows_ins_int_cnt;
                 ln_ra_rows_ins_int_cnt    := 0;

                 FND_FILE.PUT_LINE(FND_FILE.LOG,'       Inserted rows = '||ln_ra_rows_ins_int_cnt );
                 --------------------------------------------------
                 --Inserting into XXFIN.XX_RA_INT_DISTRIBUTIONS_ALL
                 --------------------------------------------------
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Inserting POS into XXFIN.XX_RA_INT_DISTRIBUTIONS_ALL ' );

                  FORALL i IN 1 .. lt_pos_trx.count
                      INSERT INTO  XX_RA_INT_DISTRIBUTIONS_ALL
                         (SELECT 	-- Added column names for defect#32991, as additional global attribute columns added in the table RA_INTERFACE_DISTRIBUTIONS_ALL by the patch#19891654 				
							INTERFACE_DISTRIBUTION_ID,
							INTERFACE_LINE_ID,
							INTERFACE_LINE_CONTEXT,
							INTERFACE_LINE_ATTRIBUTE1,
							INTERFACE_LINE_ATTRIBUTE2,
							INTERFACE_LINE_ATTRIBUTE3,
							INTERFACE_LINE_ATTRIBUTE4,
							INTERFACE_LINE_ATTRIBUTE5,
							INTERFACE_LINE_ATTRIBUTE6,
							INTERFACE_LINE_ATTRIBUTE7,
							INTERFACE_LINE_ATTRIBUTE8,
							ACCOUNT_CLASS,
							AMOUNT,
							PERCENT,
							INTERFACE_STATUS,
							REQUEST_ID,
							CODE_COMBINATION_ID,
							SEGMENT1,
							SEGMENT2,
							SEGMENT3,
							SEGMENT4,
							SEGMENT5,
							SEGMENT6,
							SEGMENT7,
							SEGMENT8,
							SEGMENT9,
							SEGMENT10,
							SEGMENT11,
							SEGMENT12,
							SEGMENT13,
							SEGMENT14,
							SEGMENT15,
							SEGMENT16,
							SEGMENT17,
							SEGMENT18,
							SEGMENT19,
							SEGMENT20,
							SEGMENT21,
							SEGMENT22,
							SEGMENT23,
							SEGMENT24,
							SEGMENT25,
							SEGMENT26,
							SEGMENT27,
							SEGMENT28,
							SEGMENT29,
							SEGMENT30,
							COMMENTS,
							ATTRIBUTE_CATEGORY,
							ATTRIBUTE1,
							ATTRIBUTE2,
							ATTRIBUTE3,
							ATTRIBUTE4,
							ATTRIBUTE5,
							ATTRIBUTE6,
							ATTRIBUTE7,
							ATTRIBUTE8,
							ATTRIBUTE9,
							ATTRIBUTE10,
							ATTRIBUTE11,
							ATTRIBUTE12,
							ATTRIBUTE13,
							ATTRIBUTE14,
							ATTRIBUTE15,
							ACCTD_AMOUNT,
							INTERFACE_LINE_ATTRIBUTE10,
							INTERFACE_LINE_ATTRIBUTE11,
							INTERFACE_LINE_ATTRIBUTE12,
							INTERFACE_LINE_ATTRIBUTE13,
							INTERFACE_LINE_ATTRIBUTE14,
							INTERFACE_LINE_ATTRIBUTE15,
							INTERFACE_LINE_ATTRIBUTE9,
							CREATED_BY,
							CREATION_DATE,
							LAST_UPDATED_BY,
							LAST_UPDATE_DATE,
							LAST_UPDATE_LOGIN,
							ORG_ID,
							INTERIM_TAX_CCID,
							INTERIM_TAX_SEGMENT1,
							INTERIM_TAX_SEGMENT2,
							INTERIM_TAX_SEGMENT3,
							INTERIM_TAX_SEGMENT4,
							INTERIM_TAX_SEGMENT5,
							INTERIM_TAX_SEGMENT6,
							INTERIM_TAX_SEGMENT7,
							INTERIM_TAX_SEGMENT8,
							INTERIM_TAX_SEGMENT9,
							INTERIM_TAX_SEGMENT10,
							INTERIM_TAX_SEGMENT11,
							INTERIM_TAX_SEGMENT12,
							INTERIM_TAX_SEGMENT13,
							INTERIM_TAX_SEGMENT14,
							INTERIM_TAX_SEGMENT15,
							INTERIM_TAX_SEGMENT16,
							INTERIM_TAX_SEGMENT17,
							INTERIM_TAX_SEGMENT18,
							INTERIM_TAX_SEGMENT19,
							INTERIM_TAX_SEGMENT20,
							INTERIM_TAX_SEGMENT21,
							INTERIM_TAX_SEGMENT22,
							INTERIM_TAX_SEGMENT23,
							INTERIM_TAX_SEGMENT24,
							INTERIM_TAX_SEGMENT25,
							INTERIM_TAX_SEGMENT26,
							INTERIM_TAX_SEGMENT27,
							INTERIM_TAX_SEGMENT28,
							INTERIM_TAX_SEGMENT29,
							INTERIM_TAX_SEGMENT30						 
                            FROM RA_INTERFACE_DISTRIBUTIONS_ALL
                            WHERE interface_line_attribute1 = lt_trx_number(i)
                            AND INTERFACE_LINE_CONTEXT = 'ORDER ENTRY');

                 ln_ra_rows_ins_dist_cnt  := SQL%ROWCOUNT;
                 ln_ra_rows_ins_dist_cnt_gt := ln_ra_rows_ins_dist_cnt_gt + ln_ra_rows_ins_dist_cnt;
                 ln_ra_rows_ins_dist_cnt  :=0;
                 -----------------------------------------------
                 --Deleting from ra_interface_distributions_all
                 -----------------------------------------------
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Deleting from RA_INTERFACE_DISTRIBUTIONS_ALL ' );


                  FORALL i IN 1 .. lt_pos_trx.count
                     DELETE FROM RA_INTERFACE_DISTRIBUTIONS_ALL
                            WHERE interface_line_attribute1 = lt_trx_number(i)
                              AND INTERFACE_LINE_CONTEXT = 'ORDER ENTRY';

                 ln_ra_rows_del_dist_cnt := SQL%ROWCOUNT;
                 ln_ra_rows_del_dist_cnt_gt := ln_ra_rows_del_dist_cnt_gt + ln_ra_rows_del_dist_cnt;
                 ln_ra_rows_del_dist_cnt := 0;

                 -- Defect 12725 removed the insert to sales credits since not required to stage

                 -----------------------------------------------
                 -- Deleting from RA_INTERFACE_SALESCREDITS_ALL
                 -----------------------------------------------
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Deleting from RA_INTERFACE_SALESCREDITS_ALL ' );

                 FORALL i IN 1 .. lt_pos_trx.count
                   DELETE FROM RA_INTERFACE_SALESCREDITS_ALL
                    WHERE INTERFACE_LINE_ATTRIBUTE1 = lt_trx_number(i)
                      AND INTERFACE_LINE_CONTEXT = 'ORDER ENTRY';


                 ln_ra_rows_del_sales_cnt := SQL%ROWCOUNT;
                 ln_ra_rows_del_sales_cnt_gt := ln_ra_rows_del_sales_cnt_gt + ln_ra_rows_del_sales_cnt;
                 ln_ra_rows_del_sales_cnt := 0;
                ----------------------------------------------
                -- Deleting POS from RA_INTERFACE_LINES_ALL
                ----------------------------------------------
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Deleting POS from RA_INTERFACE_LINES_ALL  ' );

                 FORALL i IN 1 .. lt_pos_trx.count
                   DELETE  FROM RA_INTERFACE_LINES_ALL
                    WHERE INTERFACE_LINE_ATTRIBUTE1 = lt_trx_number(i)
                      AND INTERFACE_LINE_CONTEXT = 'ORDER ENTRY';

                ln_ra_rows_del_int_cnt := SQL%ROWCOUNT;
                ln_ra_rows_del_int_cnt_gt := ln_ra_rows_del_int_cnt_gt + ln_ra_rows_del_int_cnt;
                ln_ra_rows_del_int_cnt := 0;

            END LOOP;
            CLOSE lcu_pos_inv;

            --------------------------------------------------------
            -- Confirming Distribution deletes and inserts are equal
            --------------------------------------------------------
            IF ln_ra_rows_ins_dist_cnt_gt <> ln_ra_rows_del_dist_cnt_gt THEN

               lc_err_location :='Rows inserted to XX_RA_INT_DISTRIBUTIONS_ALL'
                               ||' and deleted RA_INTERFACE_DISTRIBUTIONS_ALL do not '
                               || ' match';

                ln_ra_rows_ins_cnt := ln_ra_rows_ins_dist_cnt_gt;
                ln_ra_rows_del_cnt :=ln_ra_rows_del_dist_cnt_gt;

                RAISE EX_XX_RA_INT_LINES;

            ELSE
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ' );
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------'
                                           ||'--------------------------------'
                                           ||'--------------------------------' );
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Rows inserted into '
                                           ||'XX_RA_INT_DISTRIBUTIONS_ALL = '
                                           ||ln_ra_rows_ins_dist_cnt_gt );
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Rows Deleted from '
                                           ||'RA_INTERFACE_DISTRIBUTIONS_ALL = '
                                           || ln_ra_rows_del_dist_cnt_gt );

            END IF;

            -- Defect 12725 removed the insert to sales credits since not required to stage

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ' );
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------'
                                            ||'--------------------------------'
                                            ||'--------------------------------' );
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Rows Deleted from '
                                            ||'RA_INTERFACE_SALESCREDITS_ALL = '
                                            || ln_ra_rows_del_sales_cnt_gt );

            --------------------------------------------------------
            -- Confirming lines deletes and inserts are equal
            --------------------------------------------------------
            IF ln_ra_rows_ins_int_cnt_gt <> ln_ra_rows_del_int_cnt_gt THEN

               lc_err_location :='Rows inserted to XXFIN.XX_RA_INT_LINES_ALL'
                              ||' and deleted RA_INTERFACE_LINES_ALL do not '
                              || ' match';

                    ln_ra_rows_ins_cnt := ln_ra_rows_ins_int_cnt_gt;
                    ln_ra_rows_del_cnt :=ln_ra_rows_del_int_cnt_gt;

                    RAISE EX_XX_RA_INT_LINES;

             ELSE

                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ' );
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------'
                                           ||'--------------------------------'
                                           ||'--------------------------------' );
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Rows inserted into '
                            ||'XX_RA_INT_LINES_ALL = '||ln_ra_rows_ins_int_cnt_gt );
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Rows Deleted from '
                           ||'RA_INTERFACE_LINES_ALL = '|| ln_ra_rows_del_int_cnt_gt );

            END IF;

            COMMIT;

        ELSE
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'no invoice lines found for '
                                                 ||'staging/summarizing ');
        END IF;

        -- Fix for QC Defect # 13438 -- Start

        BEGIN
           lc_err_location := 'Exclude invoices that are POS, but not for an internal store customer ';
           UPDATE ra_interface_lines_all ri
              SET ri.interface_status = 'X'
            WHERE ri.request_id = gn_request_id
              AND ri.batch_source_name = lc_trans_batch_name
              AND NOT EXISTS (SELECT *
                                FROM xx_ar_intstorecust_otc otc
                               WHERE ri.orig_system_bill_customer_id = otc.cust_account_id)
              AND ri.interface_status IS NULL;

             FND_FILE.PUT_LINE(FND_FILE.LOG,'Update interface status to X for POS '||SQL%ROWCOUNT);

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                FND_MESSAGE.SET_NAME(application => 'XXFIN'
                                     ,name       => 'XX_AR_0010_CREATE_ACT_NO_DATA');
                FND_MESSAGE.SET_TOKEN(token  => 'COL'
                                     ,value => 'No Request_id is found to Update');
                lc_error_msg := FND_MESSAGE.GET;

             WHEN OTHERS THEN
                FND_MESSAGE.SET_NAME(application => 'XXFIN'
                                    ,name       => 'XX_AR_0011_CREATE_ACT_OTHERS');
                FND_MESSAGE.SET_TOKEN(token  => 'COL'
                                     ,value => 'No Request_id is found to Update');
                lc_error_msg := FND_MESSAGE.GET;

                FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_msg);
                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                                p_program_type            => 'CONCURRENT PROGRAM'
                                               ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                               ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                               ,p_module_name             => 'AR'
                                               ,p_error_location          => 'Oracle Error '||SQLERRM
                                               ,p_error_message_count     => gn_msg_cnt+1
                                               ,p_error_message_code      => 'E'
                                               ,p_error_message           => lc_error_msg
                                               ,p_error_message_severity  => 'Major'
                                               ,p_notify_flag             => 'N'
                                               ,p_object_type             => 'Creating Accounts');
        END;

        COMMIT;

        -- Fix for QC Defect # 13438 -- End

         /****************************************************************
         ** Step #20 ? Updates to allow AutoInvoice to import invoice  **
         ****************************************************************/
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Import Invoices Requiring a DETAILED '
                                                        ||'Import ');

         IF ln_detail_inv_line_cnt > 0 THEN

               BEGIN
                  UPDATE ra_interface_lines_all
                     SET interface_status = NULL
                        ,request_id       = NULL
                   WHERE batch_source_name = NVL(p_invoice_source,batch_source_name) --added 11.3  POS SDR
                     AND org_id = FND_PROFILE.VALUE('ORG_ID')
                     AND    ( request_id = gn_request_id
                          OR
                             (sales_order >= p_sales_order_low AND sales_order <= p_sales_order_high)
                            )
                     AND NVL(interface_status, ' ') <> 'X'; -- Interface status of 'X' means issue with TAX line

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Records updated with interface status and request id to null '|| SQL%ROWCOUNT );

                  IF (p_display_log ='Y') THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of Records Eligible to be processed by Auto Invoice : ' || SQL%ROWCOUNT); -- Added this line as part of Defect #2569 V2.87
                  END IF;

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     FND_MESSAGE.SET_NAME(application => 'XXFIN'
                                         ,name        => 'XX_AR_0010_CREATE_ACT_NO_DATA');
                     FND_MESSAGE.SET_TOKEN(token => 'COL'
                                          ,value => 'No Request_id is found to Update');
                     lc_error_msg := FND_MESSAGE.GET;
                  WHEN OTHERS THEN
                     FND_MESSAGE.SET_NAME(application => 'XXFIN'
                                         ,name        => 'XX_AR_0011_CREATE_ACT_OTHERS');
                     FND_MESSAGE.SET_TOKEN(token => 'COL'
                                          ,value => 'No Request_id is found to Update');
                     lc_error_msg := FND_MESSAGE.GET;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_msg);
                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                               p_program_type            => 'CONCURRENT PROGRAM'
                                              ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                              ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                              ,p_module_name             => 'AR'
                                              ,p_error_location          => 'Oracle Error '||SQLERRM
                                              ,p_error_message_count     => gn_msg_cnt+1
                                              ,p_error_message_code      => 'E'
                                              ,p_error_message           => lc_error_msg
                                              ,p_error_message_severity  => 'Major'
                                              ,p_notify_flag             => 'N'
                                              ,p_object_type             => 'Creating Accounts');
               END;

               COMMIT;

               /******************************************************
               ** Print Records Processing to Log/Output and Email  **
               ******************************************************/
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Print Records Processing to '||
                                    ' Log/Output and Email ');

               BEGIN
                  -- Check if errors should be displayed in log file and output
                  IF (p_error_message ='Y' )THEN

                     -- Retrieve the total sales order and dollar amount of sales orders
                     -- that do not have a CCID for account class of REC.
                     SELECT NVL(SUM(RIL.amount) ,0)
                           ,COUNT(RIL.sales_order)
                       INTO ln_int_amount
                           ,ln_err_order_count
                       FROM ra_interface_lines_all RIL
                      WHERE RIL.org_id = FND_PROFILE.VALUE('ORG_ID')
                        AND EXISTS (SELECT 1
                                      FROM ra_interface_distributions_all RID
                                     WHERE RID.interface_line_attribute1 = RIL.sales_order
                                       AND RID.code_combination_id IS NULL
                                       AND RID.account_class = 'REC')
                       -- Added condition for Defect 20687 V4.0
                        AND EXISTS (SELECT 1
                                      FROM xx_fin_translatedefinition td
                                          ,xx_fin_translatevalues     tv
                                     WHERE td.translation_name = 'OD_AR_INVOICING_DEFAULTS'
                                       AND tv.translate_id  = td.translate_id
                                       AND td.enabled_flag  = 'Y'
                                       AND tv.enabled_flag  = 'Y'
                                       AND TV.target_value3 = 'N'
                                       AND tv.target_value6 = p_batch_group
                                       AND tv.target_value1 = ril.batch_source_name);


                     -- Print errors to log file and output
                     ln_display_err_cnt := ln_err_order_count + ln_no_tax_lines_RIL;
                     FND_FILE.PUT_LINE(FND_FILE.LOG   ,'Total Invoice LINES Updated as ERROR   : ' || ln_display_err_cnt);
                     FND_FILE.PUT_LINE(FND_FILE.LOG   ,'Total Amount of Errored Transactions   : ' || '$' || ln_int_amount);
                     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Invoice LINES Updated as ERROR   : ' || ln_display_err_cnt);
                     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Amount of Errored Transactions   : ' || '$' || ln_int_amount);
                     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------------------------------');
                  END IF;

                  -- Print Invoices Successfully Processed
                  FND_FILE.PUT_LINE (FND_FILE.LOG   ,'Total Invoice LINES Selected           : ' || ln_tot_count);
                  FND_FILE.PUT_LINE (FND_FILE.LOG   ,'Total Invoice RECEIVABLE Lines Created : ' || ln_rec_acct_count);
                  FND_FILE.PUT_LINE (FND_FILE.LOG   ,'Total Invoice REVENUE    Lines Created : ' || ln_rev_acct_count);
                  FND_FILE.PUT_LINE (FND_FILE.LOG   ,'Total Invoice TAX        Lines Created : ' || ln_tax_acct_count);
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------------------------------');
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Invoice LINES Selected           : ' || ln_tot_count);
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Invoice RECEIVABLE Lines Created : ' || ln_rec_acct_count);
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Invoice REVENUE    Lines Created : ' || ln_rev_acct_count);
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Invoice TAX        Lines Created : ' || ln_tax_acct_count);

                  -- Print message if no records were processed
                  IF ln_count = 0 THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG   ,'No Invoice found in Interface table for the source SALES_ACCT%');
                     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Invoice found in Interface table for the source SALES_ACCT%');
                  END IF;

                  -- Sending Output file to the concerned Person
                  ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                (
                                 'xxfin'
                                ,'XXODROEMAILER'
                                ,''
                                ,''
                                ,FALSE
                                ,'OD: AR Create Autoinvoice Accounting'
                                ,p_email_address
                                ,'Sales Order Auto Invoice Create Account Error Records Output File'
                                ,'Sales Order Auto Invoice Create Account Error Records Output File'
                                ,'Y'
                                ,gn_request_id );
                  COMMIT;

               END;

            ELSE
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No detail Invoices found '
                                        || 'for importing ');

            END IF; --(ln_detail_inv_line_cnt > 0)

          END IF;  --(Step #2)

   EXCEPTION
      WHEN EX_XX_BATCH_NAME_ERR THEN

         FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location : Exception Raised: '||lc_error_loc);
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Message : '||SQLERRM);

      WHEN EX_XX_RA_INT_LINES  THEN
        FND_FILE.PUT_LINE (FND_FILE.LOG,'Error: Stage Invoices Requires '
                             ||' Summarization Before Importing');
        FND_FILE.PUT_LINE (FND_FILE.LOG,' '||lc_err_location);
        FND_FILE.PUT_LINE (FND_FILE.LOG,'  Rows inserted = '||ln_ra_rows_ins_cnt);
        FND_FILE.PUT_LINE (FND_FILE.LOG,'  Rows deleted  = '||ln_ra_rows_del_cnt);
        FND_FILE.PUT_LINE (FND_FILE.LOG,'  Program ending in error ');
        ROLLBACK;
        x_ret_code:=2;

      -- EX_SALES_ORDER user defined exception is raised when any one of the Sales Order Parameter IS NULL or certain variables not retrieved
      -- Also makes the request set in error status to prevent further processing by AUTOINVOICE MASTER PROGRAM
      WHEN EX_SALES_ORDER THEN
         x_ret_code:=2; -- making the CONCURENT PROG to ERROR OUT so that the shared Parameter will not pass the values to AUTOINVOICE MASTER PROGRAM
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Exception : Please Pass Values for Both Parameters Sales Order From And Sales Order To ');
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Exception : Please Pass Values for Both Parameters Sales Order From And Sales Order To ');

      -- EX_SALES_TAX user defined exception is raised if XX_AR_INSERT_TAX_LINES procedure returns an error
      WHEN EX_SALES_TAX THEN
         x_ret_code:=2; -- making the CONCURENT PROG to ERROR OUT so that the shared Parameter will not pass the values to AUTOINVOICE MASTER PROGRAM
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Exception : Error while inserting tax lines ');
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Exception : Error while inserting tax lines ');
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,lc_exc_err); -- Added for Defect#2569-V-2.84

      WHEN OTHERS THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location : Exception Raised in Main Procedure: '||lc_error_loc);
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Message : '||SQLERRM);
         FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
         lc_error_msg := FND_MESSAGE.get;
         FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_msg);
         XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Error at ' || lc_error_loc
                                     ,p_error_message_count     => gn_msg_cnt+1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => SQLERRM
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts');

          ROLLBACK;
          x_ret_code:=2;

   END XX_AR_CREATE_ACCT_CHILD_PROC;

   -- +=====================================================================+
   -- |                  Office Depot - Project Simplify                    |
   -- |                       WIPRO Technologies                            |
   -- +=====================================================================+
   -- | Name :        XX_GET_GL_COA                                         |
   -- | Description : proceudure to derive segments                         |
   -- | Parameters : p_oloc,p_sloc,p_line_id,p_acc_class,p_rev_account      |
   -- | Returns    : x_company,x_costcenter,x_account,x_location,           |
   -- |              x_intercompany,x_lob,x_future,x_ccid,x_error_message   |
   -- +=====================================================================+
   PROCEDURE XX_GET_GL_COA(
                           p_oloc           IN   VARCHAR2
                          ,p_sloc           IN   VARCHAR2
                          ,p_oloc_type      IN   VARCHAR2
                          ,p_sloc_type      IN   VARCHAR2
                          ,p_line_id        IN   NUMBER
                          ,p_acc_class      IN   VARCHAR2
                          ,p_rev_account    IN   VARCHAR2
                          ,p_cust_type      IN   VARCHAR2
                          ,p_trx_type       IN   VARCHAR2
                          ,p_log_flag       IN   VARCHAR2 --Defect 3418
                          ,p_tax_state      IN   VARCHAR2 --Defect 2569
                          ,p_tax_loc        IN   VARCHAR2 --Defect 2569
                          ,p_description    IN   VARCHAR2 --Defect 2569
                          ,x_company        OUT  VARCHAR2
                          ,x_costcenter     OUT  VARCHAR2
                          ,x_account        OUT  VARCHAR2
                          ,x_location       OUT  VARCHAR2
                          ,x_intercompany   OUT  VARCHAR2
                          ,x_lob            OUT  VARCHAR2
                          ,x_future         OUT  VARCHAR2
                          ,x_ccid           OUT  VARCHAR2
                          ,x_error_message  OUT  VARCHAR2)
   AS
      -- lt_tbl_ora_segments           FND_FLEX_EXT.SEGMENTARRAY;
      lc_concat_segments            VARCHAR2(2000);
      lc_ccid_enabled_flag          VARCHAR2(1);
      lb_return                     BOOLEAN;
      lc_ccid_exist_flag            VARCHAR2(1);
      lc_error_message              VARCHAR2(4000);
      lc_error_loc                  VARCHAR2(2000);
      lc_error_debug                VARCHAR2(2000);
      /**Defect 2569 - Defined gn_coa_id as global variable     lc_coa_id                     gl_sets_of_books.chart_of_accounts_id%TYPE;  ***/
      ln_tot_segments               NUMBER(1):=7;
      lc_error_msg                  VARCHAR2(4000);
      lc_ora_company                gl_code_combinations.segment1%TYPE;
      lc_ora_cost_center            gl_code_combinations.segment2%TYPE := '00000';
      lc_ora_account                gl_code_combinations.segment3%TYPE;
      lc_ora_location               gl_code_combinations.segment4%TYPE;
      lc_sys_ora_location           gl_code_combinations.segment4%TYPE := NULL; -- Declared variable for Defect #2569 V 2.92
      lc_ora_intercompany           gl_code_combinations.segment5%TYPE := '0000';
      lc_ora_lob                    gl_code_combinations.segment6%TYPE := '10';
      lc_ora_future                 gl_code_combinations.segment7%TYPE := '000000' ;
      ln_ccid                       NUMBER;
      -- DEFECT 2569 - Defined as global     gn_sob_id                     gl_sets_of_books.set_of_books_id%TYPE;
      lc_store_loc                  VARCHAR2(30) := 'STORE%';
      lc_temp_transaction_type      ra_cust_trx_types_all.name%TYPE;
      lc_transaction_type           xx_fin_translatevalues.target_value1%TYPE;
      lc_cvr_name                   xx_fin_translatevalues.target_value1%TYPE;
      lc_tax_type_code              gl_tax_option_accounts.tax_type_code%TYPE;
      lc_flex_validation_rule_name  fnd_flex_vdation_rules_vl.flex_validation_rule_name%TYPE;
      lc_error_message_text         fnd_flex_vdation_rules_vl.error_message_text%TYPE;
      lc_concatenated_segments_low  fnd_flex_validation_rule_lines.concatenated_segments_low%TYPE;
      lc_concatenated_segments_high fnd_flex_validation_rule_lines.concatenated_segments_high%TYPE;
      lc_company_segment1_high      fnd_flex_include_rule_lines.segment1_high%TYPE;
      lc_company_segment1_low       fnd_flex_include_rule_lines.segment1_low%TYPE;
      lc_location_segment4_high     fnd_flex_include_rule_lines.segment4_high%TYPE;
      lc_location_segment4_low      fnd_flex_include_rule_lines.segment4_low%TYPE;
      -- DEFECT 2569 - Defined as global     gc_sob_name                   VARCHAR2(240);
      lc_GL_Acc_Start1              xx_fin_translatevalues.source_value1%TYPE;
      lc_GL_Acc_Start2              xx_fin_translatevalues.source_value2%TYPE;
      lc_GL_Acc_Start3              xx_fin_translatevalues.source_value3%TYPE;
      lc_GL_Acc_Start4              xx_fin_translatevalues.source_value4%TYPE;
      lc_GL_Acc_Start5              xx_fin_translatevalues.source_value5%TYPE;
      lc_GL_Acc_Start6              xx_fin_translatevalues.source_value6%TYPE;
      lc_GL_Acc_Start7              xx_fin_translatevalues.source_value7%TYPE;
      lc_GL_Acc_Start9              xx_fin_translatevalues.source_value8%TYPE;
      lc_CC1                        xx_fin_translatevalues.target_value1%TYPE;
      lc_CC2                        xx_fin_translatevalues.target_value2%TYPE;
      lc_CC3                        xx_fin_translatevalues.target_value3%TYPE;
      lc_CC4                        xx_fin_translatevalues.target_value4%TYPE;
      lc_CC5                        xx_fin_translatevalues.target_value5%TYPE;
      lc_CC6                        xx_fin_translatevalues.target_value6%TYPE;
      lc_CC7                        xx_fin_translatevalues.target_value7%TYPE;
      lc_CC9                        xx_fin_translatevalues.target_value8%TYPE;
	  

      -- Added below procedure as part of Defect #2549 V 2.92 by RK
      PROCEDURE XX_GET_LOC_SYS_PARAMS (
                                       p_line_id         IN   NUMBER
                                      ,x_sys_account    OUT   VARCHAR2
                                      ,x_sys_location   OUT   VARCHAR2 )
      as
          
      BEGIN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Deriving the Account Segment and Location from System Options');
         --for defect 27985
         SELECT segment3
               ,segment4
           INTO x_sys_account
               ,x_sys_location
           FROM gl_code_combinations GCC
               ,ar_system_parameters_all ASP		-- Changed for R12 Retrofit ar_system_parameters ASP
          WHERE GCC.code_combination_id = ASP.location_tax_account
            and SET_OF_BOOKS_ID = GN_SOB_ID
            AND ASP.ORG_ID = gc_ln_orgid;   --Added for Defect # 43851

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'NO_DATA_FOUND: Unable to derive Account Segment and Location from System Options');

         WHEN OTHERS THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'OTHER EXCEPTION: Unable to derive Account Segment and Location from System Options for Tax Line');
      END XX_GET_LOC_SYS_PARAMS;

   BEGIN

      IF p_acc_class = 'REV' THEN
         lc_ora_account := p_rev_account;

      ELSIF p_acc_class = 'REC' THEN
         BEGIN
            SELECT GCC.segment3
              INTO lc_ora_account
              FROM ra_cust_trx_types_all RCTA
                  ,gl_code_combinations  GCC
             WHERE RCTA.cust_trx_type_id = p_trx_type
               AND GCC.chart_of_accounts_id = gn_coa_id
               AND RCTA.gl_id_rec = GCC.code_combination_id;
         EXCEPTION
            WHEN OTHERS THEN
               lc_ora_account := p_rev_account;
               FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
               FND_MESSAGE.SET_TOKEN('COL','Account segment');
               lc_error_msg :=  FND_MESSAGE.GET;
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg
                               || '.Exception Raised While Fetching REC Account');
               XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                          p_program_type            => 'CONCURRENT PROGRAM'
                                         ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                         ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                         ,p_module_name             => 'AR'
                                         ,p_error_location          => 'Oracle Error '||SQLERRM
                                         ,p_error_message_count     => gn_msg_cnt + 1
                                         ,p_error_message_code      => 'E'
                                         ,p_error_message           => lc_error_msg
                                         ,p_error_message_severity  => 'Major'
                                         ,p_notify_flag             => 'N'
                                         ,p_object_type             => 'Creating Accounts');
         END;

      ELSIF p_acc_class = gc_line_type_TAX_hc THEN
         -- Assiging other segments
         lc_ora_cost_center  := '00000';
         lc_ora_lob := '90';

         IF p_tax_state IS NOT NULL THEN -- Added as part of Defect #2569 V 2.92 by RK to derive segment3 and location when tax state is NULL

            BEGIN

               /****  Defect # 2569 - Added IF and ELSIF conditions for including U.S in addition to Canada ****/
               /****  Defect # 2569 - Also added conditions for GST and PST for Canada ***/
               /****  Defect # 2569 - Added a parameter to the XX_GET_GL_COA procedure to pass STATE or PROVINCE ****/
               /****  Defect # 2569 - As a result, the below query does not need to have the HZ tables ****/

               IF gc_country_value = 'CA' THEN

                  IF INSTR(p_description,gc_tax_type_PST_hc) > 0 THEN -- Replace hard coded value for Defect#2569-V-2.84
                     --Added the below query for the defect#9040 on 21-JUL-08 by Manovinayak
					 					 --Commented below query for R12 upgrade
					 /*
                     SELECT gcc1.segment3
                       INTO lc_ora_account
                       FROM ar_vat_tax_all VAT
                           ,gl_code_combinations GCC1
                      WHERE vat.set_of_books_id = gn_sob_id
                        AND vat.tax_code = 'PST_SALES_' || p_tax_state
                        AND    gcc1.code_combination_id = vat.tax_account_id;
					*/
					
					--Added below query for R12 upgrade

                     /*SELECT gcc1.segment3
                       INTO lc_ora_account
                       FROM zx_rates_b VAT
					       ,zx_accounts ACC
                           ,gl_code_combinations GCC1
						   ,hr_operating_units HOU
                      WHERE hou.set_of_books_id = gn_sob_id
					    AND acc.internal_organization_id = hou.organization_id						
						AND vat.tax_rate_code = 'PST_SALES_' || p_tax_state
						AND acc.tax_account_entity_id = vat.tax_rate_id
						AND acc.tax_account_entity_code = 'RATES'
                        AND acc.tax_account_id = gcc1.code_combination_id;*/
                        
                       --For defect 27985 
                       SELECT gcc.segment3
                         INTO lc_ora_account
		         FROM zx_taxes_b ztb,
		              zx_rates_b zrb,
		              zx_accounts za,
		              gl_code_combinations gcc
		        WHERE zrb.tax_rate_code = 'COUNTY'
		          AND ztb.tax = zrb.tax
		          AND za.tax_account_entity_id = zrb.tax_rate_id
		          AND ztb.tax_regime_code= zrb.tax_regime_code
		          AND zrb.tax_regime_code in ('OD_CA_SALES_TAX')
		          AND za.internal_organization_id =  FND_PROFILE.VALUE('ORG_ID')
                          AND gcc.code_combination_id = za.tax_account_ccid;  
                        
						
						/*DEEPAK REMOVE THE NEXT LINE LATER. FOR TESTING PURPOSE*/
						FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_ora_account = ' || lc_ora_account);

                  ELSIF INSTR(p_description,gc_tax_type_GST_hc) > 0 THEN
                     /*SELECT GCC.segment3
                       INTO lc_ora_account
                       FROM ar_location_values_v  ARLV
                           ,gl_code_combinations  GCC
                      WHERE ARLV.location_segment_qualifier = 'PROVINCE'
                        AND ARLV.location_segment_value = p_tax_state
                        AND GCC.code_combination_id = ARLV.tax_account_ccid;*/
                        
                        --For defect 27985 
                       SELECT gcc.segment3
                         INTO lc_ora_account
		         FROM zx_taxes_b ztb,
		              zx_rates_b zrb,
		              zx_accounts za,
		              gl_code_combinations gcc
		        WHERE zrb.tax_rate_code = 'STATE'
		          AND ztb.tax = zrb.tax
		          AND za.tax_account_entity_id = zrb.tax_rate_id
		          AND ztb.tax_regime_code= zrb.tax_regime_code
		          AND zrb.tax_regime_code in ('OD_CA_SALES_TAX')
		          AND za.internal_organization_id =  FND_PROFILE.VALUE('ORG_ID')
                          AND gcc.code_combination_id = za.tax_account_ccid;                          
                        
                        
                  END IF;

               ELSIF gc_country_value = 'US' THEN
                  /*** Defect # 2569 - Get CCID for U.S ***/
                  
                  /*SELECT GCC.segment3
                    INTO lc_ora_account
                    FROM ar_location_values_v ARLV
                        ,gl_code_combinations  GCC
                   WHERE ARLV.location_segment_qualifier = 'STATE'
                     AND ARLV.location_segment_value = p_tax_state
                     AND GCC.code_combination_id = ARLV.tax_account_ccid;*/
                     
                  --for defect 27985
             	  SELECT segment3
          	    INTO lc_ora_account
	            FROM gl_code_combinations GCC
              		 ,ar_system_parameters_all ASP		-- Changed for R12 Retrofit ar_system_parameters ASP
          	   WHERE GCC.code_combination_id = ASP.location_tax_account
                     AND set_of_books_id = gn_sob_id
                     AND ASP.ORG_ID = gc_ln_orgid;  ---Added for Defect # 43851            
                     

               END IF;

            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  XX_GET_LOC_SYS_PARAMS(p_line_id, lc_ora_account, lc_sys_ora_location);
                  --FND_FILE.PUT_LINE (FND_FILE.LOG, 'NO_DATA_FOUND: Unable to derive Account Segment for Tax Line');

               WHEN OTHERS THEN
                  XX_GET_LOC_SYS_PARAMS(p_line_id, lc_ora_account, lc_sys_ora_location);
                  --FND_FILE.PUT_LINE (FND_FILE.LOG, 'OTHER EXCEPTION: Unable to derive Account Segment for Tax Line');
            END;

         ELSE -- Added as part of Defect #2569 V 2.92 by RK to derive segment3 and location when tax state is NULL
            XX_GET_LOC_SYS_PARAMS(p_line_id, lc_ora_account, lc_sys_ora_location);
         END IF; -- Added the END IF as part of Defect #2569 V 2.92 by RK for tax state is NULL

      ELSIF p_acc_class = 'UNEARN' THEN
         BEGIN
            SELECT GCC.segment3
              INTO lc_ora_account
              FROM ra_cust_trx_types_all RCTA
                  ,gl_code_combinations  GCC
             WHERE RCTA.cust_trx_type_id = p_trx_type
               AND GCC.chart_of_accounts_id = gn_coa_id
              AND RCTA.gl_id_unbilled = GCC.code_combination_id;
         EXCEPTION
            WHEN OTHERS THEN
               FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
               FND_MESSAGE.SET_TOKEN('COL','Deriving Account for UNEARN ');
               lc_error_msg := FND_MESSAGE.GET;
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg
                                  || '.Exception Raised while fetching  account');
               XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                             p_program_type            => 'CONCURRENT PROGRAM'
                                            ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                            ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                            ,p_module_name             => 'AR'
                                            ,p_error_location          => 'Oracle Error '||SQLERRM
                                            ,p_error_message_count     => gn_msg_cnt + 1
                                            ,p_error_message_code      => 'E'
                                            ,p_error_message           => lc_error_msg
                                            ,p_error_message_severity  => 'Major'
                                            ,p_notify_flag             => 'N'
                                            ,p_object_type             => 'Creating Accounts');
         END;
      END IF;

      BEGIN
         /*** Defect 2569 - Added IF Condition to derive LOCATION and COMPANY segments for the tax line ***/

         IF NVL(p_oloc_type,1) LIKE lc_store_loc AND p_sloc_type LIKE lc_store_loc THEN
            --Code added for defect 3287. replaced the above sql with the below two lines.
            lc_ora_company  := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(LTRIM(RTRIM(p_oloc)));
            lc_ora_location := LTRIM(RTRIM(p_oloc));
            x_company      := lc_ora_company;
            x_costcenter   := lc_ora_cost_center;
            x_account      := lc_ora_account;
            x_location     := lc_ora_location;
            x_intercompany := lc_ora_intercompany;
            x_lob          := lc_ora_lob;
            x_future       := lc_ora_future;

         ELSIF NVL(p_oloc_type,1) LIKE lc_store_loc AND p_sloc_type NOT LIKE lc_store_loc THEN
            --Code added for defect 3287. replaced the above sql with the below two lines.
            lc_ora_company  := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(LTRIM(RTRIM(p_oloc)));
            lc_ora_location := LTRIM(RTRIM(p_oloc));
            x_company      := lc_ora_company;
            x_costcenter   := lc_ora_cost_center;
            x_account      := lc_ora_account;
            x_location     := lc_ora_location;
            x_intercompany := lc_ora_intercompany;
            x_lob          := lc_ora_lob;
            x_future       := lc_ora_future;

         ELSIF NVL(p_oloc_type,1) NOT LIKE lc_store_loc AND p_sloc_type LIKE lc_store_loc THEN
            --Code added for defect 3287. replaced the above sql with the below two lines.
            lc_ora_company  := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(LTRIM(RTRIM(p_sloc)));
            lc_ora_location := LTRIM(RTRIM(p_sloc));
            x_company      := lc_ora_company;
            x_costcenter   := lc_ora_cost_center;
            x_account      := lc_ora_account;
            x_location     := lc_ora_location;
            x_intercompany := lc_ora_intercompany;
            x_lob          := lc_ora_lob;
            x_future       := lc_ora_future;

         ELSIF NVL(p_oloc_type,1) NOT LIKE lc_store_loc AND p_sloc_type NOT LIKE lc_store_loc THEN
            --Code added for defect 3287. replaced the above sql with the below two lines.
            lc_ora_company  := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(LTRIM(RTRIM(p_sloc)));
            lc_ora_location := LTRIM(RTRIM(p_sloc));

            -- Modified to check the Uppercase of Customer Type on 12-13-07
            IF UPPER(p_cust_type) = 'DIRECT' Then
               SELECT FFVV.Flex_Value
                 INTO lc_ora_lob
                 FROM fnd_flex_value_sets FFVS
                     ,fnd_flex_values_vl  FFVV
                WHERE FFVS.flex_value_set_name = 'OD_GL_GLOBAL_LOB'
                  AND FFVS.flex_value_set_id   = FFVV.flex_value_set_id
                  AND UPPER(FFVV.description)  = UPPER(p_cust_type);

            ELSIF UPPER(p_cust_type) = 'CONTRACT' Then
               SELECT FFVV.flex_value
                 INTO lc_ora_lob
                 FROM fnd_flex_value_sets FFVS
                     ,fnd_flex_values_vl  FFVV
               WHERE FFVS.flex_value_set_name = 'OD_GL_GLOBAL_LOB'
                 AND FFVS.flex_value_set_id   = FFVV.flex_value_set_id
                 AND UPPER(FFVV.description)  = UPPER(p_cust_type) ;
            END IF;

            x_company      := lc_ora_company;
            x_costcenter   := lc_ora_cost_center;
            x_account      := lc_ora_account;
            x_location     := lc_ora_location;
            x_intercompany := lc_ora_intercompany;
            x_lob          := lc_ora_lob;
            x_future       := lc_ora_future;
         END IF;

         IF p_acc_class = gc_line_type_TAX_hc THEN

            -- Added below IF block as part of Defect #2549 V 2.92 by RK
            IF lc_sys_ora_location IS NOT NULL THEN
               lc_ora_location := lc_sys_ora_location;
            ELSE
               lc_ora_location := LTRIM(RTRIM(p_tax_loc));
            END IF;

            lc_ora_cost_center  := '00000';
            lc_ora_lob := '90';
         END IF;

      EXCEPTION
         WHEN TOO_MANY_ROWS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Same location range defined for different companies. Error message= '||sqlerrm);
         WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_NO_DATA');
            FND_MESSAGE.SET_TOKEN('COL','Deriving Accounts');
            lc_error_msg := FND_MESSAGE.GET;
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg
                || '.Exception Raised while fetching Company,Location Segment');
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                       p_program_type            => 'CONCURRENT PROGRAM'
                                      ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                      ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                      ,p_module_name             => 'AR'
                                      ,p_error_location          => 'Oracle Error '||SQLERRM
                                      ,p_error_message_count     => gn_msg_cnt + 1
                                      ,p_error_message_code      => 'E'
                                      ,p_error_message           => lc_error_msg
                                      ,p_error_message_severity  => 'Major'
                                      ,p_notify_flag             => 'N'
                                      ,p_object_type             => 'Creating Accounts' );
      END;

      -- Substituting the hard code of the Cost Center and account with translation values.
      SELECT source_value1
            ,source_value2
            ,source_value3
            ,source_value4
            ,source_value5
            ,source_value6
            ,source_value7
            ,source_value8
            ,target_value1
            ,target_value2
            ,target_value3
            ,target_value4
            ,target_value5
            ,target_value6
            ,target_value7
            ,target_value8
        INTO lc_gl_acc_start1
            ,lc_gl_acc_start2
            ,lc_gl_acc_start3
            ,lc_gl_acc_start4
            ,lc_gl_acc_start5
            ,lc_gl_acc_start6
            ,lc_gl_acc_start7
            ,lc_gl_acc_start9
            ,lc_cc1
            ,lc_cc2
            ,lc_cc3
            ,lc_cc4
            ,lc_cc5
            ,lc_cc6
            ,lc_cc7
            ,lc_cc9
        FROM xx_fin_translatevalues     XFTV
            ,xx_fin_translatedefinition XFTD
       WHERE XFTD.translate_id     = XFTV.translate_id
         AND XFTD.translation_name = 'GL_E0080_DEFAULT_CC'
         AND XFTD.enabled_flag     = 'Y'
         AND XFTV.enabled_flag     = 'Y';


      IF SUBSTR(lc_ora_account,1,1) = lc_gl_acc_start1  THEN
         lc_ora_cost_center   := lc_cc1;
      ELSIF SUBSTR(lc_ora_account,1,1) = lc_gl_acc_start2 THEN
         lc_ora_cost_center   := lc_cc2;
      ELSIF SUBSTR(lc_ora_account,1,1) = lc_gl_acc_start3 THEN
         lc_ora_cost_center   := lc_cc3;
      ELSIF SUBSTR(lc_ora_account,1,1) = lc_gl_acc_start4 THEN
         lc_ora_cost_center   := lc_cc4;
      ELSIF SUBSTR(lc_ora_account,1,1) = lc_gl_acc_start5 THEN
         lc_ora_cost_center   := lc_cc5;
      ELSIF SUBSTR(lc_ora_account,1,1) = lc_gl_acc_start6 THEN
         lc_ora_cost_center   := lc_cc6;
      ELSIF SUBSTR(lc_ora_account,1,1) = lc_gl_acc_start7 THEN
         lc_ora_cost_center   := lc_cc7;
      ELSIF SUBSTR(lc_ora_account,1,1) = lc_gl_acc_start9 THEN
         lc_ora_cost_center   := lc_cc9;
      END IF;

      IF lc_ora_company             IS NOT NULL
           AND lc_ora_cost_center   IS NOT NULL
           AND lc_ora_account       IS NOT NULL
           AND lc_ora_location      IS NOT NULL
           AND lc_ora_intercompany  IS NOT NULL
           AND lc_ora_lob           IS NOT NULL
           AND lc_ora_future        IS NOT NULL THEN

         lc_concat_segments := lc_ora_company ||  '.' || lc_ora_cost_center || '.' ||
                               lc_ora_account ||  '.' || lc_ora_location || '.' ||
                               lc_ora_intercompany ||  '.' || lc_ora_lob || '.' ||
                               lc_ora_future;

         BEGIN
            SELECT GCC.code_combination_id
                  ,GCC.enabled_flag
              INTO ln_ccid
                  ,lc_ccid_enabled_flag
              FROM gl_code_combinations GCC
                  ,gl_ledgers     GLL													--Changed for R12 Retrofit gl_sets_of_books     GSB
             WHERE GCC.segment1 = lc_ora_company
               AND GCC.segment2 = lc_ora_cost_center
               AND GCC.segment3 = lc_ora_account
               AND GCC.segment4 = lc_ora_location
               AND GCC.segment5 = lc_ora_intercompany
               AND GCC.segment6 = lc_ora_lob
               AND GCC.segment7 = lc_ora_future
               AND GCC.chart_of_accounts_id = GLL.chart_of_accounts_id
               AND GLL.ledger_id = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID'); 	--Changed for R12 Retrofit GSB.set_of_books_id = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');

            lc_ccid_exist_flag := 'Y';

            IF lc_ccid_enabled_flag <> 'Y' THEN
               IF (p_log_flag ='Y') THEN
                  FND_FILE.PUT_LINE (FND_FILE.LOG,'Account Combination is not enabled for Oracle Segment : '
                                                  || lc_concat_segments);
               END IF;
            ELSE
               IF (p_log_flag ='Y') THEN
                  FND_FILE.PUT_LINE (FND_FILE.LOG,'Derived '
                                                  || p_acc_class || ' Oracle Segment : ' || lc_concat_segments);
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS THEN
               lc_ccid_exist_flag := 'N';
         END;

         IF lc_ccid_exist_flag = 'N' THEN
            gn_user_id := fnd_global.user_id;
            gn_resp_id := fnd_global.resp_id;
            gn_resp_appl_id := fnd_global.resp_appl_id;
            lb_return := fnd_flex_keyval.validate_segs(operation        => 'CHECK_COMBINATION'
                                                      ,appl_short_name  => 'SQLGL'
                                                      ,key_flex_code    => 'GL#'
                                                      ,structure_number => gn_coa_id
                                                      ,concat_segments  => lc_concat_segments );

            IF lb_return = FALSE  THEN
               x_error_message := x_error_message || 'GL Cross Validation Rule does not allow to create CCID for Oracle Segments:'
                                                  || lc_concat_segments;
               FND_FILE.PUT_LINE (FND_FILE.LOG,'GL Cross Validation Rule does not allow to create CCID for Oracle Segments');
            ELSE
               gt_tbl_ora_segments(1) := lc_ora_company;
               gt_tbl_ora_segments(2) := lc_ora_cost_center;
               gt_tbl_ora_segments(3) := lc_ora_account;
               gt_tbl_ora_segments(4) := lc_ora_location;
               gt_tbl_ora_segments(5) := lc_ora_intercompany;
               gt_tbl_ora_segments(6) := lc_ora_lob;
               gt_tbl_ora_segments(7) := lc_ora_future;

               lb_return := FND_FLEX_EXT.GET_COMBINATION_ID(application_short_name => 'SQLGL'
                                                           ,key_flex_code          => 'GL#'
                                                           ,structure_number       => gn_coa_id
                                                           ,validation_date        => SYSDATE
                                                           ,n_segments             => ln_tot_segments
                                                           ,segments               => gt_tbl_ora_segments
                                                           ,combination_id         => ln_ccid);

               FND_FILE.PUT_LINE (FND_FILE.LOG,'Account Combination created for '  || p_acc_class
                                            || ' Oracle Segment : ' || lc_concat_segments);
            END IF;

            x_ccid := ln_ccid;
         ELSE
            x_error_message := 'To get CCID, all the Oracle segments are required';
         END IF;

      END IF;

      x_company      := lc_ora_company;
      x_costcenter   := lc_ora_cost_center;
      x_account      := lc_ora_account;
      x_location     := lc_ora_location;
      x_intercompany := lc_ora_intercompany;
      x_lob          := lc_ora_lob;
      x_future       := lc_ora_future;
      x_ccid         := ln_ccid;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         lc_error_loc     := 'Exception Raised while Derving GL COA='
                          || lc_concat_segments;
         lc_error_debug   := 'GET_GL_COA';
         lc_error_message := 'Exception raised ' || SQLERRM;
         x_error_message  := x_error_message || lc_error_message || lc_error_loc || lc_error_debug;

         FND_FILE.PUT_LINE (FND_FILE.LOG,x_error_message);
         FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
         FND_MESSAGE.SET_TOKEN('COL','Deriving Accounts');
         lc_error_msg := FND_MESSAGE.GET;
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg
                          || '.Exception Raised while fetching Company,Location Segment');
         XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => gn_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts');
      WHEN OTHERS THEN
         FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
         FND_MESSAGE.SET_TOKEN('COL','Deriving Accounts');
         lc_error_msg := FND_MESSAGE.GET;
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg
                           || '.Exception Raised while fetching Company,Location Segment');
         XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Child'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => gn_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts' );
   END XX_GET_GL_COA;

   -- +=====================================================================+
   -- |                  Office Depot - Project Simplify                    |
   -- |                       WIPRO Technologies                            |
   -- | Name : XX_AR_CREATE_ACCT_SLEEP_PROC                                 |
   -- +=====================================================================+
   -- | Description : This Procedure is used for preventing E0080B Child    |
   -- |               from releasing extra records for Auto invoice Master  |
   -- |               program                                               |
   -- | Parameters :  p_master_req_id,p_inv_source                          |
   -- +=====================================================================+
   PROCEDURE XX_AR_CREATE_ACCT_SLEEP_PROC(p_master_req_id   IN   NUMBER
                                         ,p_inv_source      IN   VARCHAR2)
   AS
      ln_phase_code            VARCHAR2(1) := NULL;
      ln_status_code           VARCHAR2(1) := NULL;

   BEGIN
      <<SLEEP_LOOP>>
      LOOP
         BEGIN
            -- To fetch the phase_code and status_code of Auto invoice Master
            SELECT FCR.phase_code
                  ,FCR.status_code
              INTO ln_phase_code
                  ,ln_status_code
              FROM fnd_concurrent_requests FCR
                  ,fnd_concurrent_programs FCP
             WHERE FCR.concurrent_program_id   = FCP.concurrent_program_id
               AND FCP.concurrent_program_name = 'RAXMTR'
               AND FCR.parent_request_id       = p_master_req_id
              -- AND FCR.argument3               = p_inv_source  -- removed 11.3 POS SDR
               AND FCR.argument3               =  NVL(p_inv_source,FCR.argument3) -- added 11.3  POS SDR
               AND FCR.phase_code              <> 'C';  --Changed the phase code from 'Completed' to 'C' on 09-AUG-08 for defect#9640

            IF ln_phase_code = 'R' AND ln_status_code = 'W' THEN
               EXIT SLEEP_LOOP;
            ELSE
               dbms_lock.sleep(30);
            END IF;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               ln_phase_code    := NULL;
               ln_status_code   := NULL;
               EXIT;
            WHEN OTHERS THEN
               ln_phase_code    := NULL;
               ln_status_code   := NULL;
               FND_FILE.PUT_LINE (FND_FILE.LOG,'Failed to retrieve the Status and Phase of Auto Invoice Master due to Oracle error'||SQLERRM);
               EXIT;
            END;

      END LOOP;
   END XX_AR_CREATE_ACCT_SLEEP_PROC;

   /************************************************************************************/
   /*  Name:  XX_AR_INSERT_TAX_LINES                                                   */
   /*  Description: This procedure introduces tax lines to the RA_INTERFACE_LINES_ALL  */
   /*               table by reading tax values from the OM tables.                    */
   /*               In addition, this procedure will introduce TAX lines only for      */
   /*               REVENUE lines that have a transaction type with the TAX_CALCULATION*/
   /*               flag set to 'N'.                                                   */
   /*  Parameters: p_sales_order_low, p_sales_order_high, p_country, p_request_id      */
   /*              ,p_invoice_source                                                   */
   /*  Change Record:                                                                  */
   /*  ===============                                                                 */
   /*  Version   Date              Author              Remarks                         */
   /*  ======   ==========     =============        ===================================*/
   /*  1.1      10-JUN-10      Ganga Devi R         Modified insert statements to stamp*/
   /*                                               values for global attribute1 AND  */
   /*                                               attribute category for defect 6105 */
   /************************************************************************************/
   PROCEDURE XX_AR_INSERT_TAX_LINES(p_sales_order_low  IN   VARCHAR2
                                   ,p_sales_order_high IN   VARCHAR2
                                   ,p_country          IN   VARCHAR2
                                   ,p_request_id       IN   NUMBER
                                   ,p_invoice_source   IN   VARCHAR2 DEFAULT NULL
                                   ,x_error_msg        OUT  VARCHAR2)
   AS
      lc_exc_err                VARCHAR2(250);           --for Defect#2569-V-2.84
      lc_line_gdf_attr_category VARCHAR2(10) := 'AVP';   --Added for defect 6105 (V 3.2) on 10.6.10
      lc_line_gdf_attribute1    VARCHAR2(10) := 'SALES'; --Added for defect 6105 (V 3.2) on 10.6.10
      lc_line_gdf_attri1ca      VARCHAR2(10) := 'STATE'; --Added for defect 6105 (V 3.2) on 10.6.10
      lc_line_gdf_attri2ca      VARCHAR2(10) := 'COUNTY';--Added for defect 6105 (V 3.2) on 10.6.10
      ln_orgid                  VARCHAR2(30) := FND_PROFILE.VALUE('ORG_ID');
      lc_tax_regime              VARCHAR2(30);        --Added for R12 Retrofit
      lc_tax                     VARCHAR2(30);        --Added for R12 Retrofit
      lc_jurisdiction            VARCHAR2(30);        --Added for R12 Retrofit
      lc_status_code             VARCHAR2(30);        --Added for R12 Retrofit
   BEGIN
      -- FND_FILE.PUT_LINE(FND_FILE.LOG,'p_request_id:'||p_request_id); -- Removed log, Defect#2569

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside tax line insert:'||p_request_id);
      IF p_country = 'US' THEN

         INSERT INTO ra_interface_lines_all(interface_line_context
                                           ,interface_line_attribute1
                                           ,interface_line_attribute2
                                           ,interface_line_attribute3
                                           ,interface_line_attribute4
                                           ,interface_line_attribute5
                                           ,interface_line_attribute6
                                           ,interface_line_attribute7
                                           ,interface_line_attribute8
                                           ,batch_source_name
                                           ,set_of_books_id
                                           ,line_type
                                           ,description
                                           ,currency_code
                                           ,amount
                                           ,interface_line_attribute9
                                           ,interface_line_attribute10
                                           ,interface_line_attribute11
                                           ,interface_line_attribute12
                                           ,interface_line_attribute13
                                           ,interface_line_attribute14
                                           ,attribute6
                                           ,attribute7
                                           ,attribute11
                                           ,cust_trx_type_id
                                           ,link_to_line_context
                                           ,link_to_line_attribute1
                                           ,link_to_line_attribute2
                                           ,link_to_line_attribute3
                                           ,link_to_line_attribute4
                                           ,link_to_line_attribute5
                                           ,link_to_line_attribute6
                                           ,link_to_line_attribute7
                                           ,link_to_line_attribute8
                                           ,link_to_line_attribute9
                                           ,link_to_line_attribute10
                                           ,link_to_line_attribute11
                                           ,link_to_line_attribute12
                                           ,link_to_line_attribute13
                                           ,link_to_line_attribute14
                                           ,tax_code
                                           ,line_gdf_attr_category  -- Added for defect 6105 (V 3.2) on 10.6.10
                                           ,line_gdf_attribute1     -- Added for defect 6105 (V 3.2) on 10.6.10
                                           ,ship_date_actual
                                           ,orig_system_bill_customer_id
                                           ,orig_system_bill_address_id
                                           ,orig_system_ship_customer_id
                                           ,orig_system_ship_address_id
                                           ,orig_system_sold_customer_id
                                           ,conversion_type
                                           ,conversion_rate
                                           ,payment_set_id
                                           ,term_id
                                           ,sales_order_source
                                           ,sales_order_date
                                           ,sales_order
                                           ,sales_order_line
                                           ,inventory_item_id
                                           ,header_attribute_category
                                           ,header_attribute1
                                           ,header_attribute2
                                           ,header_attribute3
                                           ,header_attribute4
                                           ,header_attribute5
                                           ,header_attribute6
                                           ,header_attribute7
                                           ,header_attribute8
                                           ,header_attribute9
                                           ,header_attribute10
                                           ,header_attribute11
                                           ,header_attribute12
                                           ,header_attribute13
                                           ,header_attribute14
                                           ,header_attribute15
                                           ,tax_exempt_flag
                                           ,tax_exempt_reason_code
                                           ,tax_exempt_reason_code_meaning
                                           ,tax_exempt_number
                                           ,interface_status
                                           ,trx_number
                                           ,request_id
                                           ,org_id
                                           ,warehouse_id
                                           ,created_by
                                           ,creation_date
                                           ,last_updated_by
                                           ,last_update_date
                                           ,last_update_login
                                            )
                            SELECT /*+USE_CONCAT index(@SEL$1_2 LINE@SEL$1_2 XX_RA_INTERFACE_LINES_N1)*/  -- V3.6
                                   DISTINCT line.interface_line_context
                                           ,line.interface_line_attribute1
                                           ,line.interface_line_attribute2
                                           ,line.interface_line_attribute3
                                           ,line.interface_line_attribute4
                                           ,line.interface_line_attribute5
                                           ,ordline.line_id
                                           ,line.interface_line_attribute7
                                           ,line.interface_line_attribute8
                                           ,line.batch_source_name
                                           ,line.set_of_books_id
                                           ,gc_line_type_tax_hc
                                           ,'Tax Value for Order'
                                           ,line.currency_code
                                           ,DECODE(ordline.line_category_code,'RETURN',(-1*ordline.tax_value)
                                                                             ,'ORDER' ,ordline.tax_value
                                                                             ,ordline.tax_value)
                                           ,gc_line_type_tax_hc
                                           ,line.interface_line_attribute10
                                           ,line.interface_line_attribute11
                                           ,line.interface_line_attribute12
                                           ,line.interface_line_attribute13
                                           ,line.interface_line_attribute14
                                           ,line.attribute6
                                           ,line.attribute7
                                           ,line.attribute11
                                           ,line.cust_trx_type_id
                                           ,line.interface_line_context
                                           ,line.interface_line_attribute1
                                           ,line.interface_line_attribute2
                                           ,line.interface_line_attribute3
                                           ,line.interface_line_attribute4
                                           ,line.interface_line_attribute5
                                           ,line.interface_line_attribute6
                                           ,line.interface_line_attribute7
                                           ,line.interface_line_attribute8
                                           ,line.interface_line_attribute9
                                           ,line.interface_line_attribute10
                                           ,line.interface_line_attribute11
                                           ,line.interface_line_attribute12
                                           ,line.interface_line_attribute13
                                           ,line.interface_line_attribute14
                                           ,'SALES'
                                           ,lc_line_gdf_attr_category     -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,lc_line_gdf_attribute1        -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,line.ship_date_actual
                                           ,line.orig_system_bill_customer_id
                                           ,line.orig_system_bill_address_id
                                           ,line.orig_system_ship_customer_id
                                           ,line.orig_system_ship_address_id
                                           ,line.orig_system_sold_customer_id
                                           ,line.conversion_type
                                           ,line.conversion_rate
                                           ,line.payment_set_id
                                           ,line.term_id
                                           ,line.sales_order_source
                                           ,line.sales_order_date
                                           ,line.sales_order
                                           ,line.sales_order_line
                                           ,line.inventory_item_id
                                           ,line.header_attribute_category
                                           ,line.header_attribute1
                                           ,line.header_attribute2
                                           ,line.header_attribute3
                                           ,line.header_attribute4
                                           ,line.header_attribute5
                                           ,line.header_attribute6
                                           ,line.header_attribute7
                                           ,line.header_attribute8
                                           ,line.header_attribute9
                                           ,line.header_attribute10
                                           ,line.header_attribute11
                                           ,line.header_attribute12
                                           ,line.header_attribute13
                                           ,line.header_attribute14
                                           ,line.header_attribute15
                                           ,line.tax_exempt_flag
                                           ,line.tax_exempt_reason_code
                                           ,line.tax_exempt_reason_code_meaning
                                           ,line.tax_exempt_number
                                           ,NULL
                                           ,line.trx_number
                                           ,p_request_id
                                           ,line.org_id
                                           ,line.warehouse_id
                                           ,FND_PROFILE.VALUE('USER_ID')
                                           ,SYSDATE
                                           ,FND_PROFILE.VALUE('USER_ID')
                                           ,SYSDATE
                                           ,FND_PROFILE.VALUE('LOGIN_ID')
                                       FROM ra_interface_lines_all line
                                           ,oe_order_headers_all ord
                                           ,oe_order_lines_all ordline
                                           ,ra_cust_trx_types_all trxtype
                                      WHERE (
                                               (    p_sales_order_low IS NOT NULL AND p_sales_order_high IS NOT NULL
                                                AND line.sales_order BETWEEN p_sales_order_low AND p_sales_order_high)
                                             OR
                                               (    p_sales_order_low IS NULL AND p_sales_order_high IS NULL
                                                AND p_request_id IS NOT NULL
                                                AND line.request_id = p_request_id)
                                             )
                                        AND line.line_type = gc_line_type_LINE_hc -- Replaced hard coded value - Defect#2569-V-2.84
                                        AND line.interface_line_attribute11 = '0'
                                      --  AND line.batch_source_name = p_invoice_source   --removed  11.3  POS SDR
                                        AND line.batch_source_name =  NVL(p_invoice_source,line.batch_source_name) --added 11.3  POS SDR
                                        AND line.org_id           = ln_orgid                                       --added 11.3  POS SDR
                                        AND ord.order_number = TO_NUMBER(line.sales_order)
                                        AND ordline.header_id = ord.header_id
                                        AND ordline.line_number = line.sales_order_line
                                        AND ordline.tax_value <> 0
                                        AND trxtype.cust_trx_type_id = line.cust_trx_type_id
                                        AND trxtype.tax_calculation_flag = 'N';

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of RA_INTERFACE_LINES Tax lines inserted for U.S: ' || SQL%ROWCOUNT); -- Removed log, Defect#2569

         -- The below insert will insert 0$ tax lines to ra_interface_lines_all table
         -- when there is an return order referencing the origianl order and
         -- return order line has 0$ tax on Return line on OM Side for US
         -- The below change is w.r.t defect #2569 Version 2.95
         INSERT INTO ra_interface_lines_all(interface_line_context
                                           ,interface_line_attribute1
                                           ,interface_line_attribute2
                                           ,interface_line_attribute3
                                           ,interface_line_attribute4
                                           ,interface_line_attribute5
                                           ,interface_line_attribute6
                                           ,interface_line_attribute7
                                           ,interface_line_attribute8
                                           ,batch_source_name
                                           ,set_of_books_id
                                           ,line_type
                                           ,description
                                           ,currency_code
                                           ,amount
                                           ,interface_line_attribute9
                                           ,interface_line_attribute10
                                           ,interface_line_attribute11
                                           ,interface_line_attribute12
                                           ,interface_line_attribute13
                                           ,interface_line_attribute14
                                           ,attribute6
                                           ,attribute7
                                           ,attribute11
                                           ,cust_trx_type_id
                                           ,link_to_line_context
                                           ,link_to_line_attribute1
                                           ,link_to_line_attribute2
                                           ,link_to_line_attribute3
                                           ,link_to_line_attribute4
                                           ,link_to_line_attribute5
                                           ,link_to_line_attribute6
                                           ,link_to_line_attribute7
                                           ,link_to_line_attribute8
                                           ,link_to_line_attribute9
                                           ,link_to_line_attribute10
                                           ,link_to_line_attribute11
                                           ,link_to_line_attribute12
                                           ,link_to_line_attribute13
                                           ,link_to_line_attribute14
                                           ,tax_code
                                           ,line_gdf_attr_category  -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,line_gdf_attribute1     -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,ship_date_actual
                                           ,orig_system_bill_customer_id
                                           ,orig_system_bill_address_id
                                           ,orig_system_ship_customer_id
                                           ,orig_system_ship_address_id
                                           ,orig_system_sold_customer_id
                                           ,conversion_type
                                           ,conversion_rate
                                           ,payment_set_id
                                           ,term_id
                                           ,sales_order_source
                                           ,sales_order_date
                                           ,sales_order
                                           ,sales_order_line
                                           ,inventory_item_id
                                           ,header_attribute_category
                                           ,header_attribute1
                                           ,header_attribute2
                                           ,header_attribute3
                                           ,header_attribute4
                                           ,header_attribute5
                                           ,header_attribute6
                                           ,header_attribute7
                                           ,header_attribute8
                                           ,header_attribute9
                                           ,header_attribute10
                                           ,header_attribute11
                                           ,header_attribute12
                                           ,header_attribute13
                                           ,header_attribute14
                                           ,header_attribute15
                                           ,tax_exempt_flag
                                           ,tax_exempt_reason_code
                                           ,tax_exempt_reason_code_meaning
                                           ,tax_exempt_number
                                           ,interface_status
                                           ,trx_number
                                           ,request_id
                                           ,org_id
                                           ,warehouse_id
                                           ,created_by
                                           ,creation_date
                                           ,last_updated_by
                                           ,last_update_date
                                           ,last_update_login
                                           )
                            SELECT /*+USE_CONCAT index(@SEL$1_2 LINE@SEL$1_2 XX_RA_INTERFACE_LINES_N1)*/  -- V3.6
                                   DISTINCT line.interface_line_context
                                           ,line.interface_line_attribute1
                                           ,line.interface_line_attribute2
                                           ,line.interface_line_attribute3
                                           ,line.interface_line_attribute4
                                           ,line.interface_line_attribute5
                                           ,ordline.line_id
                                           ,line.interface_line_attribute7
                                           ,line.interface_line_attribute8
                                           ,line.batch_source_name
                                           ,line.set_of_books_id
                                           ,gc_line_type_TAX_hc
                                           ,'Tax Value for Order'
                                           ,line.currency_code
                                           ,0
                                           ,gc_line_type_TAX_hc
                                           ,line.interface_line_attribute10
                                           ,line.interface_line_attribute11
                                           ,line.interface_line_attribute12
                                           ,line.interface_line_attribute13
                                           ,line.interface_line_attribute14
                                           ,line.attribute6
                                           ,line.attribute7
                                           ,line.attribute11
                                           ,line.cust_trx_type_id
                                           ,line.interface_line_context
                                           ,line.interface_line_attribute1
                                           ,line.interface_line_attribute2
                                           ,line.interface_line_attribute3
                                           ,line.interface_line_attribute4
                                           ,line.interface_line_attribute5
                                           ,line.interface_line_attribute6
                                           ,line.interface_line_attribute7
                                           ,line.interface_line_attribute8
                                           ,line.interface_line_attribute9
                                           ,line.interface_line_attribute10
                                           ,line.interface_line_attribute11
                                           ,line.interface_line_attribute12
                                           ,line.interface_line_attribute13
                                           ,line.interface_line_attribute14
                                           ,'SALES'
                                           ,lc_line_gdf_attr_category     -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,lc_line_gdf_attribute1        -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,line.ship_date_actual
                                           ,line.orig_system_bill_customer_id
                                           ,line.orig_system_bill_address_id
                                           ,line.orig_system_ship_customer_id
                                           ,line.orig_system_ship_address_id
                                           ,line.orig_system_sold_customer_id
                                           ,line.conversion_type
                                           ,line.conversion_rate
                                           ,line.payment_set_id
                                           ,line.term_id
                                           ,line.sales_order_source
                                           ,line.sales_order_date
                                           ,line.sales_order
                                           ,line.sales_order_line
                                           ,line.inventory_item_id
                                           ,line.header_attribute_category
                                           ,line.header_attribute1
                                           ,line.header_attribute2
                                           ,line.header_attribute3
                                           ,line.header_attribute4
                                           ,line.header_attribute5
                                           ,line.header_attribute6
                                           ,line.header_attribute7
                                           ,line.header_attribute8
                                           ,line.header_attribute9
                                           ,line.header_attribute10
                                           ,line.header_attribute11
                                           ,line.header_attribute12
                                           ,line.header_attribute13
                                           ,line.header_attribute14
                                           ,line.header_attribute15
                                           ,line.tax_exempt_flag
                                           ,line.tax_exempt_reason_code
                                           ,line.tax_exempt_reason_code_meaning
                                           ,line.tax_exempt_number
                                           ,NULL
                                           ,line.trx_number
                                           ,p_request_id
                                           ,line.org_id
                                           ,line.warehouse_id
                                           ,FND_PROFILE.VALUE('USER_ID')
                                           ,SYSDATE
                                           ,FND_PROFILE.VALUE('USER_ID')
                                           ,SYSDATE
                                           ,FND_PROFILE.VALUE('LOGIN_ID')
                                      FROM ra_interface_lines_all line
                                           ,oe_order_headers_all ord
                                           ,oe_order_lines_all ordline
                                           ,ra_cust_trx_types_all trxtype
                                           ,xx_om_line_attributes_all lineattr
                                     WHERE (
                                             (    p_sales_order_low IS NOT NULL AND p_sales_order_high IS NOT NULL
                                              AND line.sales_order BETWEEN p_sales_order_low AND p_sales_order_high)
                                            OR
                                             (    p_sales_order_low IS NULL AND p_sales_order_high IS NULL
                                              AND p_request_id IS NOT NULL
                                              AND line.request_id = p_request_id)
                                           )
                                       AND line.line_type = gc_line_type_LINE_hc -- Replaced hard coded value - Defect#2569-V-2.84
                                       AND line.interface_line_attribute11 = '0'
                                      -- AND line.batch_source_name = p_invoice_source -- removed 11.3  POS SDR
                                       AND line.batch_source_name =  NVL(p_invoice_source,line.batch_source_name) -- added 11.3  POS SDR
                                       AND line.org_id            = ln_orgid                                      -- added 11.3  POS SDR
                                       AND ord.order_number = TO_NUMBER(line.sales_order)
                                       AND ordline.header_id = ord.header_id
                                       AND ordline.line_number = line.sales_order_line
                                       AND ordline.tax_value = 0
                                       AND trxtype.cust_trx_type_id = line.cust_trx_type_id
                                       AND trxtype.tax_calculation_flag = 'N'
                                       AND lineattr.line_id = ordline.line_id
                                       AND lineattr.ret_orig_order_num IS NOT NULL
                                       /** Modified Defect 2569 for Version 2.96 to refer to original order **/
                                       /** Modified below sub-select to not insert tax lines for non-taxable original invoices - Defect 2569 V3.0 ***/
                                       AND EXISTS (SELECT 1
                                                     FROM ra_customer_trx_all rct
                                                         ,ra_customer_trx_lines_all rctl
                                                    WHERE rct.trx_number = lineattr.ret_orig_order_num
                                                      AND rctl.customer_trx_id = rct.customer_trx_id
                                                      AND rctl.line_type = 'TAX');

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of 0$ TAX lines inserted for US in RA_INTERFACE_LINES which has original order reference with 0$ tax on Return Line from OM: ' || SQL%ROWCOUNT); -- Removed log, Defect#2569


      ELSE
         IF p_country = 'CA' THEN
            INSERT INTO ra_interface_lines_all(interface_line_context
                                              ,interface_line_attribute1
                                              ,interface_line_attribute2
                                              ,interface_line_attribute3
                                              ,interface_line_attribute4
                                              ,interface_line_attribute5
                                              ,interface_line_attribute6
                                              ,interface_line_attribute7
                                              ,interface_line_attribute8
                                              ,batch_source_name
                                              ,set_of_books_id
                                              ,line_type
                                              ,description
                                              ,currency_code
                                              ,amount
                                              ,interface_line_attribute9
                                              ,interface_line_attribute10
                                              ,interface_line_attribute11
                                              ,interface_line_attribute12
                                              ,interface_line_attribute13
                                              ,interface_line_attribute14
                                              ,attribute6
                                              ,attribute7
                                              ,attribute11
                                              ,cust_trx_type_id
                                              ,link_to_line_context
                                              ,link_to_line_attribute1
                                              ,link_to_line_attribute2
                                              ,link_to_line_attribute3
                                              ,link_to_line_attribute4
                                              ,link_to_line_attribute5
                                              ,link_to_line_attribute6
                                              ,link_to_line_attribute7
                                              ,link_to_line_attribute8
                                              ,link_to_line_attribute9
                                              ,link_to_line_attribute10
                                              ,link_to_line_attribute11
                                              ,link_to_line_attribute12
                                              ,link_to_line_attribute13
                                              ,link_to_line_attribute14
                                              ,tax_code
                                              ,line_gdf_attr_category  -- added for defect 6105 (V 3.2) on 10.6.10
                                              ,line_gdf_attribute1     -- added for defect 6105 (V 3.2) on 10.6.10
                                              ,ship_date_actual
                                              ,orig_system_bill_customer_id
                                              ,orig_system_bill_address_id
                                              ,orig_system_ship_customer_id
                                              ,orig_system_ship_address_id
                                              ,orig_system_sold_customer_id
                                              ,conversion_type
                                              ,conversion_rate
                                              ,payment_set_id
                                              ,term_id
                                              ,sales_order_source
                                              ,sales_order_date
                                              ,sales_order
                                              ,sales_order_line
                                              ,inventory_item_id
                                              ,header_attribute_category
                                              ,header_attribute1
                                              ,header_attribute2
                                              ,header_attribute3
                                              ,header_attribute4
                                              ,header_attribute5
                                              ,header_attribute6
                                              ,header_attribute7
                                              ,header_attribute8
                                              ,header_attribute9
                                              ,header_attribute10
                                              ,header_attribute11
                                              ,header_attribute12
                                              ,header_attribute13
                                              ,header_attribute14
                                              ,header_attribute15
                                              ,tax_exempt_flag
                                              ,tax_exempt_reason_code
                                              ,tax_exempt_reason_code_meaning
                                              ,tax_exempt_number
                                              ,interface_status
                                              ,trx_number
                                              ,request_id
                                              ,org_id
                                              ,warehouse_id
                                              ,created_by
                                              ,creation_date
                                              ,last_updated_by
                                              ,last_update_date
                                              ,last_update_login
                                              )
                                        SELECT line.interface_line_context
                                              ,line.interface_line_attribute1
                                              ,line.interface_line_attribute2
                                              ,line.interface_line_attribute3
                                              ,line.interface_line_attribute4
                                              ,line.interface_line_attribute5
                                              ,ordline.line_id
                                              ,line.interface_line_attribute7
                                              ,line.interface_line_attribute8
                                              ,line.batch_source_name
                                              ,line.set_of_books_id
                                              ,gc_line_type_TAX_hc
                                              ,'GST Tax Value for Order'
                                              ,line.currency_code
                                              ,DECODE(ordline.line_category_code,'RETURN',(-1*(ordline.tax_value - lineattr.canada_pst_tax)),
                                                                                 'ORDER',(ordline.tax_value - lineattr.canada_pst_tax),
                                                                                 (ordline.tax_value - lineattr.canada_pst_tax))
                                              ,gc_tax_type_GST_hc
                                              ,line.interface_line_attribute10
                                              ,line.interface_line_attribute11
                                              ,line.interface_line_attribute12
                                              ,line.interface_line_attribute13
                                              ,line.interface_line_attribute14
                                              ,line.attribute6
                                              ,line.attribute7
                                              ,line.attribute11
                                              ,line.cust_trx_type_id
                                              ,line.interface_line_context
                                              ,line.interface_line_attribute1
                                              ,line.interface_line_attribute2
                                              ,line.interface_line_attribute3
                                              ,line.interface_line_attribute4
                                              ,line.interface_line_attribute5
                                              ,line.interface_line_attribute6
                                              ,line.interface_line_attribute7
                                              ,line.interface_line_attribute8
                                              ,line.interface_line_attribute9
                                              ,line.interface_line_attribute10
                                              ,line.interface_line_attribute11
                                              ,line.interface_line_attribute12
                                              ,line.interface_line_attribute13
                                              ,line.interface_line_attribute14
                                              ,'STATE'
                                              ,lc_line_gdf_attr_category     -- added for defect 6105 (V 3.2) on 10.6.10
                                              ,lc_line_gdf_attri1ca          -- added for defect 6105 (V 3.2) on 10.6.10
                                              ,line.ship_date_actual
                                              ,line.orig_system_bill_customer_id
                                              ,line.orig_system_bill_address_id
                                              ,line.orig_system_ship_customer_id
                                              ,line.orig_system_ship_address_id
                                              ,line.orig_system_sold_customer_id
                                              ,line.conversion_type
                                              ,line.conversion_rate
                                              ,line.payment_set_id
                                              ,line.term_id
                                              ,line.sales_order_source
                                              ,line.sales_order_date
                                              ,line.sales_order
                                              ,line.sales_order_line
                                              ,line.inventory_item_id
                                              ,line.header_attribute_category
                                              ,line.header_attribute1
                                              ,line.header_attribute2
                                              ,line.header_attribute3
                                              ,line.header_attribute4
                                              ,line.header_attribute5
                                              ,line.header_attribute6
                                              ,line.header_attribute7
                                              ,line.header_attribute8
                                              ,line.header_attribute9
                                              ,line.header_attribute10
                                              ,line.header_attribute11
                                              ,line.header_attribute12
                                              ,line.header_attribute13
                                              ,line.header_attribute14
                                              ,line.header_attribute15
                                              ,line.tax_exempt_flag
                                              ,line.tax_exempt_reason_code
                                              ,line.tax_exempt_reason_code_meaning
                                              ,line.tax_exempt_number
                                              ,NULL
                                              ,line.trx_number
                                              ,p_request_id
                                              ,line.org_id
                                              ,line.warehouse_id
                                              ,FND_PROFILE.VALUE('USER_ID')
                                              ,SYSDATE
                                              ,FND_PROFILE.VALUE('USER_ID')
                                              ,SYSDATE
                                              ,FND_PROFILE.VALUE('LOGIN_ID')
                                          FROM ra_interface_lines_all line
                                              ,oe_order_headers_all ord
                                              ,oe_order_lines_all ordline
                                              ,xx_om_line_attributes_all lineattr
                                              ,ra_cust_trx_types_all trxtype
                                        WHERE (
                                                 (    p_sales_order_low IS NOT NULL AND p_sales_order_high IS NOT NULL
                                                  AND line.sales_order BETWEEN p_sales_order_low AND p_sales_order_high)
                                               OR
                                                 (    p_sales_order_low IS NULL AND p_sales_order_high IS NULL
                                                   AND p_request_id IS NOT NULL
                                                   AND line.request_id = p_request_id)
                                              )
                                          AND line.line_type = gc_line_type_LINE_hc -- Replaced hard coded value - Defect#2569-V-2.84
                                          AND line.interface_line_attribute11 = '0'
                                         -- AND line.batch_source_name = p_invoice_source -- removed 11.3  POS SDR
                                          AND line.batch_source_name = NVL(p_invoice_source,line.batch_source_name) -- added 11.3  POS SDR
                                          AND line.org_id            = ln_orgid                                     -- added 11.3  POS SDR
                                          AND ord.order_number = TO_NUMBER(line.sales_order)
                                          AND ordline.header_id = ord.header_id
                                          AND ordline.line_number = line.sales_order_line
                                          AND (ordline.tax_value - lineattr.canada_pst_tax) <> 0    -- Defect 2569 V2.97
                                          AND lineattr.line_id = ordline.line_id
                                          AND trxtype.cust_trx_type_id = line.cust_trx_type_id
                                          AND trxtype.tax_calculation_flag = 'N';

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of RA_INTERFACE_LINES GST Tax lines inserted for Canada: ' || SQL%ROWCOUNT); -- -- Removed log, Defect#2569


         INSERT INTO ra_interface_lines_all(interface_line_context
                                           ,interface_line_attribute1
                                           ,interface_line_attribute2
                                           ,interface_line_attribute3
                                           ,interface_line_attribute4
                                           ,interface_line_attribute5
                                           ,interface_line_attribute6
                                           ,interface_line_attribute7
                                           ,interface_line_attribute8
                                           ,batch_source_name
                                           ,set_of_books_id
                                           ,line_type
                                           ,description
                                           ,currency_code
                                           ,amount
                                           ,interface_line_attribute9
                                           ,interface_line_attribute10
                                           ,interface_line_attribute11
                                           ,interface_line_attribute12
                                           ,interface_line_attribute13
                                           ,interface_line_attribute14
                                           ,attribute6
                                           ,attribute7
                                           ,attribute11
                                           ,cust_trx_type_id
                                           ,link_to_line_context
                                           ,link_to_line_attribute1
                                           ,link_to_line_attribute2
                                           ,link_to_line_attribute3
                                           ,link_to_line_attribute4
                                           ,link_to_line_attribute5
                                           ,link_to_line_attribute6
                                           ,link_to_line_attribute7
                                           ,link_to_line_attribute8
                                           ,link_to_line_attribute9
                                           ,link_to_line_attribute10
                                           ,link_to_line_attribute11
                                           ,link_to_line_attribute12
                                           ,link_to_line_attribute13
                                           ,link_to_line_attribute14
                                           ,tax_code
                                           ,line_gdf_attr_category  -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,line_gdf_attribute1     -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,ship_date_actual
                                           ,orig_system_bill_customer_id
                                           ,orig_system_bill_address_id
                                           ,orig_system_ship_customer_id
                                           ,orig_system_ship_address_id
                                           ,orig_system_sold_customer_id
                                           ,conversion_type
                                           ,conversion_rate
                                           ,payment_set_id
                                           ,term_id
                                           ,sales_order_source
                                           ,sales_order_date
                                           ,sales_order
                                           ,sales_order_line
                                           ,inventory_item_id
                                           ,header_attribute_category
                                           ,header_attribute1
                                           ,header_attribute2
                                           ,header_attribute3
                                           ,header_attribute4
                                           ,header_attribute5
                                           ,header_attribute6
                                           ,header_attribute7
                                           ,header_attribute8
                                           ,header_attribute9
                                           ,header_attribute10
                                           ,header_attribute11
                                           ,header_attribute12
                                           ,header_attribute13
                                           ,header_attribute14
                                           ,header_attribute15
                                           ,tax_exempt_flag
                                           ,tax_exempt_reason_code
                                           ,tax_exempt_reason_code_meaning
                                           ,tax_exempt_number
                                           ,interface_status
                                           ,trx_number
                                           ,request_id
                                           ,org_id
                                           ,warehouse_id
                                           ,created_by
                                           ,creation_date
                                           ,last_updated_by
                                           ,last_update_date
                                           ,last_update_login
                                           )
                                     SELECT line.interface_line_context
                                           ,line.interface_line_attribute1
                                           ,line.interface_line_attribute2
                                           ,line.interface_line_attribute3
                                           ,line.interface_line_attribute4
                                           ,line.interface_line_attribute5
                                           ,ordline.line_id
                                           ,line.interface_line_attribute7
                                           ,line.interface_line_attribute8
                                           ,line.batch_source_name
                                           ,line.set_of_books_id
                                           ,gc_line_type_TAX_hc
                                           ,'PST Tax Value for Order'
                                           ,line.currency_code
                                           ,DECODE(ordline.line_category_code,'RETURN',(-1*lineattr.canada_pst_tax)
                                                                             ,'ORDER',lineattr.canada_pst_tax
                                                                             ,lineattr.canada_pst_tax)
                                           ,gc_tax_type_PST_hc
                                           ,line.interface_line_attribute10
                                           ,line.interface_line_attribute11
                                           ,line.interface_line_attribute12
                                           ,line.interface_line_attribute13
                                           ,line.interface_line_attribute14
                                           ,line.attribute6
                                           ,line.attribute7
                                           ,line.attribute11
                                           ,line.cust_trx_type_id
                                           ,line.interface_line_context
                                           ,line.interface_line_attribute1
                                           ,line.interface_line_attribute2
                                           ,line.interface_line_attribute3
                                           ,line.interface_line_attribute4
                                           ,line.interface_line_attribute5
                                           ,line.interface_line_attribute6
                                           ,line.interface_line_attribute7
                                           ,line.interface_line_attribute8
                                           ,line.interface_line_attribute9
                                           ,line.interface_line_attribute10
                                           ,line.interface_line_attribute11
                                           ,line.interface_line_attribute12
                                           ,line.interface_line_attribute13
                                           ,line.interface_line_attribute14
                                           ,'COUNTY'
                                           ,lc_line_gdf_attr_category                  -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,lc_line_gdf_attri2ca                       -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,line.ship_date_actual
                                           ,line.orig_system_bill_customer_id
                                           ,line.orig_system_bill_address_id
                                           ,line.orig_system_ship_customer_id
                                           ,line.orig_system_ship_address_id
                                           ,line.orig_system_sold_customer_id
                                           ,line.conversion_type
                                           ,line.conversion_rate
                                           ,line.payment_set_id
                                           ,line.term_id
                                           ,line.sales_order_source
                                           ,line.sales_order_date
                                           ,line.sales_order
                                           ,line.sales_order_line
                                           ,line.inventory_item_id
                                           ,line.header_attribute_category
                                           ,line.header_attribute1
                                           ,line.header_attribute2
                                           ,line.header_attribute3
                                           ,line.header_attribute4
                                           ,line.header_attribute5
                                           ,line.header_attribute6
                                           ,line.header_attribute7
                                           ,line.header_attribute8
                                           ,line.header_attribute9
                                           ,line.header_attribute10
                                           ,line.header_attribute11
                                           ,line.header_attribute12
                                           ,line.header_attribute13
                                           ,line.header_attribute14
                                           ,line.header_attribute15
                                           ,line.tax_exempt_flag
                                           ,line.tax_exempt_reason_code
                                           ,line.tax_exempt_reason_code_meaning
                                           ,line.tax_exempt_number
                                           ,NULL
                                           ,line.trx_number
                                           ,p_request_id
                                           ,line.org_id
                                           ,line.warehouse_id
                                           ,FND_PROFILE.VALUE('USER_ID')
                                           ,SYSDATE
                                           ,FND_PROFILE.VALUE('USER_ID')
                                           ,SYSDATE
                                           ,FND_PROFILE.VALUE('LOGIN_ID')
                                       FROM ra_interface_lines_all line
                                           ,oe_order_headers_all ord
                                           ,oe_order_lines_all ordline
                                           ,xx_om_line_attributes_all lineattr
                                           ,ra_cust_trx_types_all trxtype
                                     WHERE (
                                               (    p_sales_order_low IS NOT NULL AND p_sales_order_high IS NOT NULL
                                                AND line.sales_order BETWEEN p_sales_order_low AND p_sales_order_high)
                                            OR
                                               (    p_sales_order_low IS NULL AND p_sales_order_high IS NULL
                                                AND p_request_id IS NOT NULL
                                                AND line.request_id = p_request_id)
                                           )
                                       AND line.line_type = gc_line_type_LINE_hc -- Replaced hard coded value - Defect#2569-V-2.84
                                       AND line.interface_line_attribute11 = '0'
                                     --  AND line.batch_source_name = p_invoice_source -- added 11.3  POS SDR
                                       AND line.batch_source_name = NVL(p_invoice_source,line.batch_source_name) -- added 11.3  POS SDR
                                       AND line.org_id            = ln_orgid                                     -- added 11.3  POS SDR
                                       AND ord.order_number = TO_NUMBER(line.sales_order)
                                       AND ordline.header_id = ord.header_id
                                       AND ordline.line_number = line.sales_order_line
                                       AND lineattr.line_id = ordline.line_id
                                       AND lineattr.canada_pst_tax <> 0
                                       AND trxtype.cust_trx_type_id = line.cust_trx_type_id
                                       AND trxtype.tax_calculation_flag = 'N';

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of RA_INTERFACE_LINES PST Tax lines inserted for Canada: ' || SQL%ROWCOUNT); -- Removed log,Defect#2569

         -- The below insert will insert 0$ tax lines to ra_interface_lines_all table
         -- when there is an return order referencing the origianl order and
         -- return order line has 0$ tax on Return line on OM Side for CANADA
         -- The below change is w.r.t defect #2569 Version 2.95
         INSERT INTO ra_interface_lines_all(interface_line_context
                                           ,interface_line_attribute1
                                           ,interface_line_attribute2
                                           ,interface_line_attribute3
                                           ,interface_line_attribute4
                                           ,interface_line_attribute5
                                           ,interface_line_attribute6
                                           ,interface_line_attribute7
                                           ,interface_line_attribute8
                                           ,batch_source_name
                                           ,set_of_books_id
                                           ,line_type
                                           ,description
                                           ,currency_code
                                           ,amount
                                           ,interface_line_attribute9
                                           ,interface_line_attribute10
                                           ,interface_line_attribute11
                                           ,interface_line_attribute12
                                           ,interface_line_attribute13
                                           ,interface_line_attribute14
                                           ,attribute6
                                           ,attribute7
                                           ,attribute11
                                           ,cust_trx_type_id
                                           ,link_to_line_context
                                           ,link_to_line_attribute1
                                           ,link_to_line_attribute2
                                           ,link_to_line_attribute3
                                           ,link_to_line_attribute4
                                           ,link_to_line_attribute5
                                           ,link_to_line_attribute6
                                           ,link_to_line_attribute7
                                           ,link_to_line_attribute8
                                           ,link_to_line_attribute9
                                           ,link_to_line_attribute10
                                           ,link_to_line_attribute11
                                           ,link_to_line_attribute12
                                           ,link_to_line_attribute13
                                           ,link_to_line_attribute14
                                           ,tax_code
                                           ,line_gdf_attr_category  -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,line_gdf_attribute1     -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,ship_date_actual
                                           ,orig_system_bill_customer_id
                                           ,orig_system_bill_address_id
                                           ,orig_system_ship_customer_id
                                           ,orig_system_ship_address_id
                                           ,orig_system_sold_customer_id
                                           ,conversion_type
                                           ,conversion_rate
                                           ,payment_set_id
                                           ,term_id
                                           ,sales_order_source
                                           ,sales_order_date
                                           ,sales_order
                                           ,sales_order_line
                                           ,inventory_item_id
                                           ,header_attribute_category
                                           ,header_attribute1
                                           ,header_attribute2
                                           ,header_attribute3
                                           ,header_attribute4
                                           ,header_attribute5
                                           ,header_attribute6
                                           ,header_attribute7
                                           ,header_attribute8
                                           ,header_attribute9
                                           ,header_attribute10
                                           ,header_attribute11
                                           ,header_attribute12
                                           ,header_attribute13
                                           ,header_attribute14
                                           ,header_attribute15
                                           ,tax_exempt_flag
                                           ,tax_exempt_reason_code
                                           ,tax_exempt_reason_code_meaning
                                           ,tax_exempt_number
                                           ,interface_status
                                           ,trx_number
                                           ,request_id
                                           ,org_id
                                           ,warehouse_id
                                           ,created_by
                                           ,creation_date
                                           ,last_updated_by
                                           ,last_update_date
                                           ,last_update_login
                                           )
                                     SELECT line.interface_line_context
                                           ,line.interface_line_attribute1
                                           ,line.interface_line_attribute2
                                           ,line.interface_line_attribute3
                                           ,line.interface_line_attribute4
                                           ,line.interface_line_attribute5
                                           ,ordline.line_id
                                           ,line.interface_line_attribute7
                                           ,line.interface_line_attribute8
                                           ,line.batch_source_name
                                           ,line.set_of_books_id
                                           ,gc_line_type_TAX_hc
                                           ,'GST Tax Value for Order'
                                           ,line.currency_code
                                           ,0
                                           ,gc_tax_type_GST_hc
                                           ,line.interface_line_attribute10
                                           ,line.interface_line_attribute11
                                           ,line.interface_line_attribute12
                                           ,line.interface_line_attribute13
                                           ,line.interface_line_attribute14
                                           ,line.attribute6
                                           ,line.attribute7
                                           ,line.attribute11
                                           ,line.cust_trx_type_id
                                           ,line.interface_line_context
                                           ,line.interface_line_attribute1
                                           ,line.interface_line_attribute2
                                           ,line.interface_line_attribute3
                                           ,line.interface_line_attribute4
                                           ,line.interface_line_attribute5
                                           ,line.interface_line_attribute6
                                           ,line.interface_line_attribute7
                                           ,line.interface_line_attribute8
                                           ,line.interface_line_attribute9
                                           ,line.interface_line_attribute10
                                           ,line.interface_line_attribute11
                                           ,line.interface_line_attribute12
                                           ,line.interface_line_attribute13
                                           ,line.interface_line_attribute14
                                           ,'STATE'
                                           ,lc_line_gdf_attr_category                  -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,lc_line_gdf_attri1ca                       -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,line.ship_date_actual
                                           ,line.orig_system_bill_customer_id
                                           ,line.orig_system_bill_address_id
                                           ,line.orig_system_ship_customer_id
                                           ,line.orig_system_ship_address_id
                                           ,line.orig_system_sold_customer_id
                                           ,line.conversion_type
                                           ,line.conversion_rate
                                           ,line.payment_set_id
                                           ,line.term_id
                                           ,line.sales_order_source
                                           ,line.sales_order_date
                                           ,line.sales_order
                                           ,line.sales_order_line
                                           ,line.inventory_item_id
                                           ,line.header_attribute_category
                                           ,line.header_attribute1
                                           ,line.header_attribute2
                                           ,line.header_attribute3
                                           ,line.header_attribute4
                                           ,line.header_attribute5
                                           ,line.header_attribute6
                                           ,line.header_attribute7
                                           ,line.header_attribute8
                                           ,line.header_attribute9
                                           ,line.header_attribute10
                                           ,line.header_attribute11
                                           ,line.header_attribute12
                                           ,line.header_attribute13
                                           ,line.header_attribute14
                                           ,line.header_attribute15
                                           ,line.tax_exempt_flag
                                           ,line.tax_exempt_reason_code
                                           ,line.tax_exempt_reason_code_meaning
                                           ,line.tax_exempt_number
                                           ,NULL
                                           ,line.trx_number
                                           ,p_request_id
                                           ,line.org_id
                                           ,line.warehouse_id
                                           ,FND_PROFILE.VALUE('USER_ID')
                                           ,SYSDATE
                                           ,FND_PROFILE.VALUE('USER_ID')
                                           ,SYSDATE
                                           ,FND_PROFILE.VALUE('LOGIN_ID')
                                       FROM ra_interface_lines_all line
                                           ,oe_order_headers_all ord
                                           ,oe_order_lines_all ordline
                                           ,xx_om_line_attributes_all lineattr
                                           ,ra_cust_trx_types_all trxtype
                                      WHERE (
                                               (    p_sales_order_low IS NOT NULL AND p_sales_order_high IS NOT NULL
                                                AND line.sales_order BETWEEN p_sales_order_low AND p_sales_order_high)
                                             OR
                                               (    p_sales_order_low IS NULL AND p_sales_order_high IS NULL
                                                AND p_request_id IS NOT NULL
                                                AND line.request_id = p_request_id)
                                            )
                                        AND line.line_type = gc_line_type_LINE_hc -- Replaced hard coded value - Defect#2569-V-2.84
                                        AND line.interface_line_attribute11 = '0'
                                       -- AND line.batch_source_name = p_invoice_source -- removed 11.3  POS SDR
                                        AND line.batch_source_name = NVL(p_invoice_source,line.batch_source_name) -- added 11.3  POS SDR
                                        AND line.org_id            = ln_orgid                                     -- added 11.3  POS SDR
                                        AND ord.order_number = TO_NUMBER(line.sales_order)
                                        AND ordline.header_id = ord.header_id
                                        AND ordline.line_number = line.sales_order_line
                                        AND (ordline.tax_value - lineattr.canada_pst_tax) = 0   -- Defect 2569 V2.97
                                        AND lineattr.line_id = ordline.line_id
                                        AND trxtype.cust_trx_type_id = line.cust_trx_type_id
                                        AND trxtype.tax_calculation_flag = 'N'
                                        AND lineattr.ret_orig_order_num IS NOT NULL
                                        /** Modified Defect 2569 for Version 2.96 to refer to original order **/
                                        /** Modified below sub-select to not insert tax lines for non-taxable original invoices - Defect 2569 V3.0 ***/
                                        AND EXISTS (SELECT 1
                                                      FROM ra_customer_trx_all rct
                                                          ,ra_customer_trx_lines_all rctl
                                                          --,ar_vat_tax_all vat Commented for R12 upgrade QC Defect 16781
														  ,zx_rates_b vat                                                           
                                                     WHERE rct.trx_number = lineattr.ret_orig_order_num
                                                       AND rctl.customer_trx_id = rct.customer_trx_id
                                                       AND rctl.line_type = 'TAX'
                                                       --AND vat.vat_tax_id = rctl.vat_tax_id Commented for R12upgrade QC Defect 16781
													   AND vat.tax_rate_id = rctl.vat_tax_id -- Added for QC Defect 16781
                                                       --AND vat.tax_code = 'STATE'); Commented for QC Defect 16781
													   AND vat.tax_rate_code = 'STATE'); -- Added for QC Defect 16781                                                       

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of 0$ TAX lines for GST inserted for CANADA in RA_INTERFACE_LINES which has original order reference with 0$ tax on Return Line from OM: ' || SQL%ROWCOUNT); -- Removed log, Defect#2569  -- Added GST for V2.97


         -- The below insert will insert 0$ tax lines to ra_interface_lines_all table
         -- when there is an return order referencing the origianl order and
         -- return order line has 0$ tax on Return line on OM Side for CANADA
         -- This SQL will insert the PST line in addition to the GST line inserted above
         -- The below change is w.r.t defect #2569 Version 2.97
         INSERT INTO ra_interface_lines_all(interface_line_context
                                           ,interface_line_attribute1
                                           ,interface_line_attribute2
                                           ,interface_line_attribute3
                                           ,interface_line_attribute4
                                           ,interface_line_attribute5
                                           ,interface_line_attribute6
                                           ,interface_line_attribute7
                                           ,interface_line_attribute8
                                           ,batch_source_name
                                           ,set_of_books_id
                                           ,line_type
                                           ,description
                                           ,currency_code
                                           ,amount
                                           ,interface_line_attribute9
                                           ,interface_line_attribute10
                                           ,interface_line_attribute11
                                           ,interface_line_attribute12
                                           ,interface_line_attribute13
                                           ,interface_line_attribute14
                                           ,attribute6
                                           ,attribute7
                                           ,attribute11
                                           ,cust_trx_type_id
                                           ,link_to_line_context
                                           ,link_to_line_attribute1
                                           ,link_to_line_attribute2
                                           ,link_to_line_attribute3
                                           ,link_to_line_attribute4
                                           ,link_to_line_attribute5
                                           ,link_to_line_attribute6
                                           ,link_to_line_attribute7
                                           ,link_to_line_attribute8
                                           ,link_to_line_attribute9
                                           ,link_to_line_attribute10
                                           ,link_to_line_attribute11
                                           ,link_to_line_attribute12
                                           ,link_to_line_attribute13
                                           ,link_to_line_attribute14
                                           ,tax_code
                                           ,line_gdf_attr_category  -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,line_gdf_attribute1     -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,ship_date_actual
                                           ,orig_system_bill_customer_id
                                           ,orig_system_bill_address_id
                                           ,orig_system_ship_customer_id
                                           ,orig_system_ship_address_id
                                           ,orig_system_sold_customer_id
                                           ,conversion_type
                                           ,conversion_rate
                                           ,payment_set_id
                                           ,term_id
                                           ,sales_order_source
                                           ,sales_order_date
                                           ,sales_order
                                           ,sales_order_line
                                           ,inventory_item_id
                                           ,header_attribute_category
                                           ,header_attribute1
                                           ,header_attribute2
                                           ,header_attribute3
                                           ,header_attribute4
                                           ,header_attribute5
                                           ,header_attribute6
                                           ,header_attribute7
                                           ,header_attribute8
                                           ,header_attribute9
                                           ,header_attribute10
                                           ,header_attribute11
                                           ,header_attribute12
                                           ,header_attribute13
                                           ,header_attribute14
                                           ,header_attribute15
                                           ,tax_exempt_flag
                                           ,tax_exempt_reason_code
                                           ,tax_exempt_reason_code_meaning
                                           ,tax_exempt_number
                                           ,interface_status
                                           ,trx_number
                                           ,request_id
                                           ,org_id
                                           ,warehouse_id
                                           ,created_by
                                           ,creation_date
                                           ,last_updated_by
                                           ,last_update_date
                                           ,last_update_login
                                           )
                                     SELECT line.interface_line_context
                                           ,line.interface_line_attribute1
                                           ,line.interface_line_attribute2
                                           ,line.interface_line_attribute3
                                           ,line.interface_line_attribute4
                                           ,line.interface_line_attribute5
                                           ,ordline.line_id
                                           ,line.interface_line_attribute7
                                           ,line.interface_line_attribute8
                                           ,line.batch_source_name
                                           ,line.set_of_books_id
                                           ,gc_line_type_TAX_hc
                                           ,'PST Tax Value for Order'
                                           ,line.currency_code
                                           ,0
                                           ,gc_tax_type_PST_hc
                                           ,line.interface_line_attribute10
                                           ,line.interface_line_attribute11
                                           ,line.interface_line_attribute12
                                           ,line.interface_line_attribute13
                                           ,line.interface_line_attribute14
                                           ,line.attribute6
                                           ,line.attribute7
                                           ,line.attribute11
                                           ,line.cust_trx_type_id
                                           ,line.interface_line_context
                                           ,line.interface_line_attribute1
                                           ,line.interface_line_attribute2
                                           ,line.interface_line_attribute3
                                           ,line.interface_line_attribute4
                                           ,line.interface_line_attribute5
                                           ,line.interface_line_attribute6
                                           ,line.interface_line_attribute7
                                           ,line.interface_line_attribute8
                                           ,line.interface_line_attribute9
                                           ,line.interface_line_attribute10
                                           ,line.interface_line_attribute11
                                           ,line.interface_line_attribute12
                                           ,line.interface_line_attribute13
                                           ,line.interface_line_attribute14
                                           ,'COUNTY'
                                           ,lc_line_gdf_attr_category                  -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,lc_line_gdf_attri2ca                       -- added for defect 6105 (V 3.2) on 10.6.10
                                           ,line.ship_date_actual
                                           ,line.orig_system_bill_customer_id
                                           ,line.orig_system_bill_address_id
                                           ,line.orig_system_ship_customer_id
                                           ,line.orig_system_ship_address_id
                                           ,line.orig_system_sold_customer_id
                                           ,line.conversion_type
                                           ,line.conversion_rate
                                           ,line.payment_set_id
                                           ,line.term_id
                                           ,line.sales_order_source
                                           ,line.sales_order_date
                                           ,line.sales_order
                                           ,line.sales_order_line
                                           ,line.inventory_item_id
                                           ,line.header_attribute_category
                                           ,line.header_attribute1
                                           ,line.header_attribute2
                                           ,line.header_attribute3
                                           ,line.header_attribute4
                                           ,line.header_attribute5
                                           ,line.header_attribute6
                                           ,line.header_attribute7
                                           ,line.header_attribute8
                                           ,line.header_attribute9
                                           ,line.header_attribute10
                                           ,line.header_attribute11
                                           ,line.header_attribute12
                                           ,line.header_attribute13
                                           ,line.header_attribute14
                                           ,line.header_attribute15
                                           ,line.tax_exempt_flag
                                           ,line.tax_exempt_reason_code
                                           ,line.tax_exempt_reason_code_meaning
                                           ,line.tax_exempt_number
                                           ,NULL
                                           ,line.trx_number
                                           ,p_request_id
                                           ,line.org_id
                                           ,line.warehouse_id
                                           ,FND_PROFILE.VALUE('USER_ID')
                                           ,SYSDATE
                                           ,FND_PROFILE.VALUE('USER_ID')
                                           ,SYSDATE
                                           ,FND_PROFILE.VALUE('LOGIN_ID')
                                       FROM ra_interface_lines_all line
                                           ,oe_order_headers_all ord
                                           ,oe_order_lines_all ordline
                                           ,xx_om_line_attributes_all lineattr
                                           ,ra_cust_trx_types_all trxtype
                                      WHERE (
                                                (    p_sales_order_low IS NOT NULL AND p_sales_order_high IS NOT NULL
                                                 AND line.sales_order BETWEEN p_sales_order_low AND p_sales_order_high)
                                             OR
                                                (    p_sales_order_low IS NULL AND p_sales_order_high IS NULL
                                                 AND p_request_id IS NOT NULL
                                                 AND line.request_id = p_request_id)
                                            )
                                        AND line.line_type = gc_line_type_LINE_hc -- Replaced hard coded value - Defect#2569-V-2.84
                                        AND line.interface_line_attribute11 = '0'
                                     --   AND line.batch_source_name = p_invoice_source -- removed 11.3  POS SDR
                                        AND line.batch_source_name = NVL(p_invoice_source,line.batch_source_name) -- added 11.3  POS SDR
                                        AND line.org_id           = ln_orgid                                      -- added 11.3  POS SDR
                                        AND ord.order_number = TO_NUMBER(line.sales_order)
                                        AND ordline.header_id = ord.header_id
                                        AND ordline.line_number = line.sales_order_line
                                        AND lineattr.line_id = ordline.line_id
                                        AND lineattr.canada_pst_tax = 0
                                        AND trxtype.cust_trx_type_id = line.cust_trx_type_id
                                        AND trxtype.tax_calculation_flag = 'N'
                                        AND lineattr.ret_orig_order_num IS NOT NULL
                                        /** Modified Defect 2569 for Version 2.96 to refer to original order **/
                                        /** Modified below sub-select to not insert tax lines for non-taxable original invoices - Defect 2569 V3.0 ***/
                                        AND EXISTS (SELECT 1
                                                      FROM ra_customer_trx_all rct
                                                          ,ra_customer_trx_lines_all rctl
                                                          --,ar_vat_tax_all vat
														  ,zx_rates_b vat                                                          
                                                     WHERE rct.trx_number = lineattr.ret_orig_order_num
                                                       AND rctl.customer_trx_id = rct.customer_trx_id
                                                       AND rctl.line_type = 'TAX'
                                                       --AND vat.vat_tax_id = rctl.vat_tax_id Commented for QC Defect 16781
													   AND vat.tax_rate_id = rctl.vat_tax_id -- Added for QC Defect 16781
                                                       --AND vat.tax_code = 'COUNTY'); Commented for QC Defect 16781
													   AND vat.tax_rate_code = 'COUNTY'); --Added for QC Defect 16781

													   
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of 0$ TAX lines for PST inserted for CANADA in RA_INTERFACE_LINES which has original order reference with 0$ tax on Return Line from OM: ' || SQL%ROWCOUNT); -- Removed log,Defect#2569  -- Added GST for V2.97

         END IF;
      END IF;

   /** Added exception part to print the SQLERRM error message for Defect#2569-V-2.84 **/
   EXCEPTION
      WHEN OTHERS THEN
         x_error_msg    := 'Error Message: '||SQLERRM;

   END XX_AR_INSERT_TAX_LINES;


END XX_AR_CREATE_ACCT_CHILD_PKG;
/
