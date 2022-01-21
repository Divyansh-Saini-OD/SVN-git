-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to update the attributes of ar_cons_inv_all                    |	
-- |                                                                          |  
-- |Table    :    ar_cons_inv_all                                             |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          16-DEC-2018   Aniket J                                       |
-- +==========================================================================+


UPDATE AR_CONS_INV_ALL
SET ATTRIBUTE2     =NULL,
  ATTRIBUTE4       =NULL,
  ATTRIBUTE10      =NULL,
  ATTRIBUTE15      =NULL
WHERE cons_inv_id in (8092017) and BILLING_DATE='16-DEC-18';


/*
update  XX_CDH_CUST_ACCT_EXT_B     XCCAE
set C_EXT_ATTR4='Y'
where N_EXT_ATTR1=23000 
and XCCAE.attr_group_id         = 166
AND   XCCAE.c_ext_attr1           ='Consolidated Bill'
        and   XCCAE.C_EXT_ATTR3           ='PRINT'
        and   XCCAE.C_EXT_ATTR2           ='Y'
        and XCCAE.cust_account_id=33727;
		
		
    update HZ_CUSTOMER_PROFILES HCP
    set HCP.attribute6='P'
		WHERE HCP.cust_account_id = 33727	
		AND HCP.site_use_id        IS NULL
		and HCP.STATUS              = 'A'
		;
*/

COMMIT;   

SHOW ERRORS;

EXIT;