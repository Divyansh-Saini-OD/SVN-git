  ---+============================================================================================+
  ---|                              Office Depot - Project Simplify                               |
  ---|                                   Provide Consulting                                       |
  ---+============================================================================================+
  ---|    Application : AR                                                                        |
  ---|                                                                                            |
  ---|    Name        : UPDATE_BILL_COMPLETE_DOCS.sql                                             |
  ---|                                                                                            |
  ---|    Description : Update bill complete flags for existing in_process and complete cust docs |
  ---|                                                                                            |
  ---|                                                                                            |
  ---|                                                                                            |
  ---|    Change Record                                                                           |
  ---|    ---------------------------------                                                       |
  ---|    Version         DATE              AUTHOR             DESCRIPTION                        |
  ---|    ------------    ----------------- ---------------    ---------------------              |
  ---|    1.0             25-OCT-2018       Thilak CG            Initial Version                  |
  ---+============================================================================================+
 
 UPDATE xx_cdh_cust_acct_ext_b 
    SET c_ext_attr18 = 'Y'
  WHERE n_ext_attr2 IN (SELECT xxcab.n_ext_attr2
						  FROM xx_cdh_cust_acct_ext_b xxcab
						  INNER JOIN hz_customer_profiles hcp
						  ON xxcab.cust_account_id = hcp.cust_account_id
						WHERE xxcab.c_ext_attr1 = 'Consolidated Bill'
						  AND xxcab.c_ext_attr16 IN ('IN_PROCESS','COMPLETE')
						  AND hcp.cons_inv_flag = 'Y'
						  AND hcp.site_use_id IS NULL
						  AND hcp.attribute6 = 'Y'
						  AND TRUNC(SYSDATE) BETWEEN D_Ext_Attr1 AND NVL(D_Ext_Attr2,SYSDATE));  
  
 UPDATE xx_cdh_cust_acct_ext_b 
    SET c_ext_attr18 = 'N'
  WHERE n_ext_attr2 IN (SELECT xxcab.n_ext_attr2
						  FROM xx_cdh_cust_acct_ext_b xxcab
						  INNER JOIN hz_customer_profiles hcp
						  ON xxcab.cust_account_id = hcp.cust_account_id
						WHERE xxcab.c_ext_attr1 = 'Consolidated Bill'
						  AND xxcab.c_ext_attr16 IN ('IN_PROCESS','COMPLETE')
						  AND hcp.cons_inv_flag = 'Y'
						  AND hcp.site_use_id IS NULL
						  AND NVL(hcp.attribute6,'N') = 'N'
						  AND TRUNC(SYSDATE) BETWEEN D_Ext_Attr1 AND NVL(D_Ext_Attr2,SYSDATE));
  
  
 UPDATE xx_cdh_cust_acct_ext_b 
    SET c_ext_attr18 = 'N'
  WHERE c_ext_attr1 = 'Invoice'
    AND c_ext_attr16 IN ('IN_PROCESS','COMPLETE')
    AND TRUNC(SYSDATE) BETWEEN D_Ext_Attr1 AND NVL(D_Ext_Attr2,SYSDATE);

COMMIT;