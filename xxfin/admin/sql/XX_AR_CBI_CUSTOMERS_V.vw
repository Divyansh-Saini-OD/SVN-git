CREATE OR REPLACE VIEW APPS.XX_AR_CBI_CUSTOMERS_V AS
  SELECT hp.party_name,
         hca.account_number,
         hca.cust_account_id
    FROM ar_cons_inv_all aci,
         hz_parties hp,
         hz_cust_accounts hca
   WHERE aci.customer_id = hca.cust_account_id
     AND hca.party_id = hp.party_id
   GROUP BY hp.party_name,
         hca.account_number,
         hca.cust_account_id
   ORDER BY hp.party_name,
         hca.account_number;
/