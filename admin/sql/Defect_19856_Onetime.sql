DELETE FROM XX_CRM_WCELG_CUST  A
 WHERE cust_account_id in (
 SELECT cust_Account_id FROM HZ_CUSTOMER_PROFILES HCP , xx_ar_recon_open_itm OP
                        WHERE   HCP.cust_account_id=OP.customer_id
                        AND  HCP.ATTRIBUTE3='N'
                        AND HCP.CREDIT_CHECKING='N'
                        AND HCP.STANDARD_TERMS=
                           (SELECT TERM_ID 
                            FROM RA_TERMS 
                            WHERE NAME ='IMMEDIATE') )
OR cust_Account_id  in (    SELECT cust_Account_id   FROM HZ_CUSTOMER_PROFILES HCP1 , xx_ar_recon_open_itm OP
                        WHERE   HCP1.cust_account_id=OP.customer_id
                            and hcp1.status='I'                         
                            );
/
COMMIT;