---+========================================================================================================+        
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       XX_AR_TAX_SUMMARY_V.vw                                      |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                     |
---|    ------------    ----------------- ---------------    ---------------------                           |
---|    1.0             02-AUG-2007       Balaguru Seshadri  Initial Version                                 |
---|                                                                                                        |
---|    1.1             11-DEC-2013       Veronica Mairembam Modified for R12 Upgrade retrofit as part of   |
---|                                                         defect# 26781                                  |
---+========================================================================================================+
CREATE OR REPLACE VIEW XX_AR_TAX_SUMMARY_V AS 
SELECT   trx.customer_trx_id customer_trx_id,
         lines2.customer_trx_line_id,
         prof.tax_printing_option tax_printing_option,
         lines.description description,
         NVL (SUM (lines.extended_amount), 0) tax_amount,
         lines.tax_rate tax_rate,
         ar_invoice_sql_func_pub.get_inv_tax_code_name
                                     (trx.ship_to_site_use_id,
                                      prof.cust_account_id,
                                      prof.tax_printing_option,
                                      --vat.printed_tax_name,
                                      --vat.tax_code
									  vat.tax_rate_name,
									  vat.tax_rate_code   --Added/commented by Veronica for R12 Upgrade retrofit
                                     ) tax_code_name,
         lines.tax_exemption_id tax_exemption_id,
         lines.sales_tax_id sales_tax_id, lines.tax_precedence tax_precedence,
         SUM (lines2.extended_amount) euro_taxable_amount
    FROM --ar_vat_tax_vl vat,
	     zx_rates_vl    vat,                              --Added/commented by Veronica for R12 Upgrade retrofit
         hz_customer_profiles prof,
         ra_customer_trx_lines lines2,
         ra_customer_trx_lines lines,
         ra_customer_trx trx
   WHERE lines.customer_trx_id = trx.customer_trx_id
     AND lines.line_type = 'TAX'
    -- AND lines.vat_tax_id = vat.vat_tax_id(+)
	 AND lines.vat_tax_id = vat.tax_rate_id(+)            --Added/commented by Veronica for R12 Upgrade retrofit
     AND lines2.customer_trx_line_id(+) = lines.link_to_cust_trx_line_id
     AND trx.ship_to_customer_id = prof.cust_account_id(+)
     AND prof.site_use_id IS NULL
GROUP BY trx.customer_trx_id,
         lines2.customer_trx_line_id,
         prof.tax_printing_option,
         lines.description,
         lines.tax_rate,
         trx.ship_to_site_use_id,
         prof.cust_account_id,
         prof.tax_printing_option,
         --vat.printed_tax_name,
         --vat.tax_code,
		 vat.tax_rate_name,
		 vat.tax_rate_code,                                 --Added/commented by Veronica for R12 Upgrade retrofit
         lines.tax_exemption_id,
         lines.sales_tax_id,
         lines.tax_precedence
/