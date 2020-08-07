CREATE OR REPLACE VIEW XX_AR_LOCKBOX_ERR_BANK_INFO_V AS 
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                            Office Depot                                        |
-- +================================================================================+
-- | Name  : XX_AR_LOCKBOX_ERR_BANK_INFO_V                                          |
-- | Description: Custom view for the bank account and Branch details               |
-- |              to create Lockbox Transmission error Reports                      |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- | Version     Date           Author             Remarks                          |
-- |=======   ==========   =============     =======================================|
-- |1.0       31-DEC-2009  Priyanka Nagesh    Initial version                       |
-- |                                          for defect 497,498                    |
-- |1.1       01-Oct-2012  Jay Gupta         Change for CR868                       |
-- |1.2       29-Jul-2013  Pratesh Shukla     Change As a part of R12 Retrofit for RICE R1157  |
-- +===============================================================================+|
/*  This query is commented as tables are obsolete in R12 and a new query is written below for Retrofit.
SELECT           ABB.bank_num
                ,ABA.bank_account_num
                ,ABAU.start_date
                ,ABAU.End_Date
                ,ABAU.customer_site_use_id
                ,HCA.account_number  
                ,HCA.account_name
                ,HCSU.site_use_id
                ,HCSU.cust_acct_site_id
                ,HCASA.orig_system_reference  
                ,ABAU.attribute1  -- V1.1
FROM           apps.ap_bank_accounts           ABA
               ,apps.ap_bank_branches              ABB
               ,apps.ap_bank_account_uses      ABAU
               ,apps.hz_cust_accounts              HCA
               ,apps.hz_cust_site_uses         HCSU 
               ,apps.hz_cust_acct_sites        HCASA
WHERE ABA.bank_branch_id = ABB.bank_branch_id 
AND ABA.bank_account_id= ABAU.external_bank_account_id
AND ABAU.customer_id= HCA.cust_account_id
AND ABAU.customer_site_use_id = HCSU.site_use_id(+)
AND HCSU.cust_acct_site_id = HCASA.cust_acct_site_id(+); 
*/

CREATE OR REPLACE FORCE VIEW apps.xx_ar_lockbox_err_bank_info_v (bank_num,
                                                                 bank_account_num,
                                                                 start_date,
                                                                 end_date,
                                                                 customer_site_use_id,
                                                                 account_number,
                                                                 account_name,
                                                                 site_use_id,
                                                                 cust_acct_site_id,
                                                                 orig_system_reference,
                                                                 attribute1
                                                                )
AS
   SELECT brpr.bank_or_branch_number , 
          ieba.bank_account_num, 
		  ipi.start_date,
          ipi.end_date, 
		  iepa.acct_site_use_id, 
		  hca.account_number,
          hca.account_name, 
		  hcsu.site_use_id, 
		  hcsu.cust_acct_site_id,
          hcasa.orig_system_reference, 
		  ipi.attribute1
     FROM iby_ext_bank_accounts  ieba,
          iby_external_payers_all iepa,
          iby_pmt_instr_uses_all ipi,
          hz_cust_accounts hca,
          hz_cust_site_uses_all hcsu,
          hz_cust_acct_sites hcasa,
          hz_organization_profiles brpr
    WHERE ieba.branch_id = brpr.party_id(+)
      AND ieba.ext_bank_account_id = ipi.instrument_id
      AND ipi.ext_pmt_party_id = iepa.ext_payer_id
      AND iepa.cust_account_id = hca.cust_account_id
      AND iepa.acct_site_use_id = hcsu.site_use_id(+)
      AND hcsu.cust_acct_site_id = hcasa.cust_acct_site_id(+);
/
