---+========================================================================================================+        
---|                                        Office Depot - C2FO                                             |
---+========================================================================================================+
---|    Application             :       AP                                                                  |
---|                                                                                                        |
---|    Name                    :       XX_AP_C2FO_ORGANIZATION_V.vw                                        |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                    |
---|    ------------    ----------------- ---------------    ---------------------                          |
---|    1.0             31-AUG-2018       Antonio Morales    Initial Version                                |
---+========================================================================================================+


CREATE OR REPLACE FORCE VIEW XX_AP_C2FO_ORGANIZATION_V (
	"COMPANY_ID", 
	"COMPANY_NAME", 
	"ADDRESS_1", 
	"ADDRESS_2", 
	"CITY", 
	"STATE", 
	"POSTAL_CODE", 
	"COUNTRY", 
	"RESERVE_PERCENTAGE", 
	"RESERVE_AMOUNT", 
	"RESERVE_INVOICE_PRIORITY", 
	"RESERVE_BEFORE_ADJUSTMENTS", 
	"TAX_ID")
AS SELECT
     replace(replace(assa.org_id|| '|'||assa.vendor_id|| '|'|| assa.vendor_site_id,',',''),'"','') AS company_id,   --concatenation to get a unique ORGANIZATION for each vendor/site combinationa.vendor_id,
     replace(replace(sup.vendor_name,',',''),'"','') AS company_name,
     replace(replace(assa.address_line1,',',''),'"','') AS address_1,
     replace(replace(assa.address_line2,',',''),'"','') AS address_2,
     replace(replace(assa.city,',',''),'"','') AS city,
     replace(replace(assa.state,',',''),'"','') AS state,
     replace(replace(assa.zip,',',''),'"','') AS postal_code,
     replace(replace(assa.country|| '|'|| (select hg.geography_name from hz_geographies hg where hg.geography_type = 'COUNTRY' and hg.country_code =assa.country),',',''),'"','') AS country,
     NULL AS reserve_percentage,
     NULL AS reserve_amount,
     NULL AS reserve_invoice_priority,
     NULL AS reserve_before_adjustments,
	 replace(replace(sup.num_1099,',',''),'"','') AS tax_id
 FROM
     ap_suppliers sup,
     ap_supplier_sites_all assa
 WHERE
         assa.vendor_id = sup.vendor_id
     AND sup.enabled_flag = 'Y'
     AND SYSDATE BETWEEN nvl(sup.start_date_active,SYSDATE - 1) AND nvl(sup.end_date_active,SYSDATE + 1)
     AND nvl(assa.inactive_date,SYSDATE + 1) > SYSDATE;
