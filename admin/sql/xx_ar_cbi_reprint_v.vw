---+========================================================================================================+        
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       XX_AR_CBI_REPRINT_V                                                 |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                    |
---|    ------------    ----------------- ---------------    ---------------------                          |
---|    1.0             02-AUG-2007       Balaguru Seshadri  Initial Version                                |
---|    1.1             15-OCT-2007       Balaguru Seshadri  Changes the print instance field value.        |
---|    1.2             20-MAR-2009       Gokila Tamilselvam Chaged for Defect# 13372 - CR 562. Alternate   |
---|                                                         Customer name is fetched for customer name.    |
-- |    1.2             29-MAY-2009       Gokila Tamilselvam Defect# 15063. The logic of the attribute1     |
-- |                                                         column is handled in the procedure             |
-- |                                                         XX_AR_PRINT_NEW_CON_PKG.MAIN                   |
---|                                                                                                        |
---+========================================================================================================+
/* Formatted on 2008/05/01 16:40 (Formatter Plus v4.8.8) */
CREATE OR REPLACE VIEW xx_ar_cbi_reprint_v 
AS
  SELECT arci.org_id cons_inv_org,
          TRIM (SUBSTR (arsp.tax_registration_number, 1, 16)) tax_id,
          DECODE (arci.currency_code,
                  'USD', 'FEDERAL ID #:',
                  'CAD', 'GST REGISTRATION #:'
                 ) tax_id_desc,
          xx_ar_print_summbill.get_od_contact_info(hzca.attribute18 ,hzlo.country ,'ACCOUNT') account_contact,
          xx_ar_print_summbill.get_od_contact_info(hzca.attribute18 ,hzlo.country ,'ORDER') order_contact,
          arci.currency_code currency, arci.customer_id customer_id,
          arci.site_use_id site_use_id, arci.cons_inv_id cons_inv_id,
          arci.cons_billing_number billing_no,
          TO_CHAR (arci.creation_date, 'MM/DD/RRRR') import_date,
          TO_CHAR (arci.issue_date, 'MM/DD/RRRR') issue_date,
          --TO_CHAR (arci.cut_off_date, 'MM/DD/RRRR') cut_off_date, -- Commented for Defect# 15063.
	  TO_CHAR(TO_DATE(arci.attribute1),'MM/DD/RRRR') cut_off_date, -- Added for Defect# 15063.
          TO_CHAR (arci.due_date, 'MM/DD/RRRR') due_date,
          hzca.account_number customer_number,-- hzp.party_name customer_name, --Commented for Defect# 13372 - CR 562.
          SUBSTR(NVL(hzlo.address_lines_phonetic,hzp.party_name),1,40) customer_name,--Added for Defect# 13372 - CR 562.
          TRIM (SUBSTR (hzca.orig_system_reference, 1, 8)) account_number,
          hzlo.province province, 
          ftl.territory_short_name country,
          rftl.territory_short_name rcountry,
          REPLACE (hzlo.postal_code, '-', '') billing_postal_code,
          REPLACE (rhzlo.postal_code, '-', '') remit_postal_code
     FROM ar_cons_inv arci,
          hz_cust_accounts hzca,
          hz_parties hzp,
          ar_system_parameters arsp,
          hz_cust_acct_sites hzas,
          hz_cust_site_uses hzsu,
          hz_party_sites hzps,
          hz_locations hzlo,
          hz_cust_acct_sites rhzca,
          hz_party_sites rhzps,
          hz_locations rhzlo,
          fnd_territories_tl ftl,
          fnd_territories_tl rftl
    WHERE hzca.cust_account_id = arci.customer_id
      AND hzp.party_id = hzca.party_id
      AND arsp.tax_currency_code = arci.currency_code
      AND hzas.cust_account_id = hzca.cust_account_id
      AND hzsu.cust_acct_site_id = hzas.cust_acct_site_id
      AND hzsu.site_use_id = arci.site_use_id
      AND hzps.party_site_id = hzas.party_site_id
      AND hzlo.location_id = hzps.location_id
      AND rhzca.cust_acct_site_id = xx_ar_utilities_pkg.get_remitaddressid (arci.site_use_id)
      AND rhzps.party_site_id = rhzca.party_site_id
      AND rhzlo.location_id = rhzps.location_id
      AND ftl.territory_code =hzlo.country
      AND ftl.LANGUAGE = 'US'
      AND rftl.territory_code =rhzlo.country
      AND rftl.LANGUAGE = 'US'
/