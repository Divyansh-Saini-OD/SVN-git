-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- |Name  :  Create Collection Views                                   |
-- |Description      :   This program is used to create Collection     |
-- |                     Views in the apps schema, which work as       |
-- |                     filters to classify the customers of US       |
-- |                     operating unit into six groups based on the   |
-- |                     categories to which they belong.	       |
-- |Change Record:                                                     |
-- |==============                                                     |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  ================  ===========================|
-- |DRAFT 1A 13-DEC-2006  Anusha Ramanujam  Initial draft version      |
-- |                                ,WIPRO                             |
-- |V1.0     14-DEC-2006  Anusha Ramanujam  Introduced Value Sets to   |
-- |                                ,WIPRO  avoid hardcoding of the    |
-- |                                        categories.                |
-- +===================================================================+

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_US_DIRECT_ACCT_V" ("CUST_ACCOUNT_ID") AS 
SELECT DEL.cust_account_id
FROM   iex_f_accounts_V DEL
WHERE  EXISTS(SELECT cust_account_id 
              FROM   hz_cust_accounts HCA
       	            ,hz_parties       HZP
              WHERE  HCA.cust_account_id = DEL.cust_account_id 
              AND    HCA.party_id        = HZP.party_id 
              AND    HZP.category_code in 
                                      (SELECT FFV.FLEX_VALUE 
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
				       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_DIRECT'));


CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_US_MIDLARG_ACCT_V" ("CUST_ACCOUNT_ID") AS 
SELECT DEL.cust_account_id
FROM   iex_f_accounts_V DEL
WHERE  EXISTS(SELECT cust_account_id 
	      FROM   hz_cust_accounts HCA
		    ,hz_parties       HZP
	      WHERE  HCA.cust_account_id = DEL.cust_account_id 
	      AND    HCA.party_id 	 = HZP.party_id 
	      AND    HZP.category_code in 
				      (SELECT FFV.FLEX_VALUE 
				       FROM   FND_FLEX_VALUE_SETS FFVS
					     ,FND_FLEX_VALUES     FFV                     
			               WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
				       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_MIDLARG'));
									  

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_US_NATION_ACCT_V" ("CUST_ACCOUNT_ID") AS 
SELECT DEL.cust_account_id
FROM   iex_f_accounts_V DEL            
WHERE  EXISTS(SELECT cust_account_id 
	      FROM   hz_cust_accounts HCA
		    ,hz_parties       HZP 
	      WHERE  HCA.cust_account_id = DEL.cust_account_id 
	      AND    HCA.party_id 	 = HZP.party_id 
	      AND    HZP.category_code in 
				      (SELECT FFV.FLEX_VALUE 
				       FROM   FND_FLEX_VALUE_SETS FFVS
				             ,FND_FLEX_VALUES     FFV                     
			               WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
				       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_NATION'));	


CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_US_NONTRAD_ACCT_V" ("CUST_ACCOUNT_ID") AS 
SELECT DEL.cust_account_id
FROM   iex_f_accounts_V DEL          
WHERE  EXISTS(SELECT cust_account_id 
	      FROM   hz_cust_accounts HCA
		    ,hz_parties       HZP 
	      WHERE  HCA.cust_account_id = DEL.cust_account_id 
	      AND    HCA.party_id 	 = HZP.party_id 
	      AND    HZP.category_code in
				      (SELECT FFV.FLEX_VALUE 
				       FROM   FND_FLEX_VALUE_SETS FFVS
					     ,FND_FLEX_VALUES     FFV                     
			               WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
				       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_NONTRAD'));		
									  							  								  									  

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_US_SCHOOL_ACCT_V" ("CUST_ACCOUNT_ID") AS 
SELECT DEL.cust_account_id
FROM   iex_f_accounts_V DEL
WHERE  EXISTS(SELECT cust_account_id 
	      FROM   hz_cust_accounts HCA
		    ,hz_parties       HZP 
	      WHERE  HCA.cust_account_id = DEL.cust_account_id 
	      AND    HCA.party_id 	 = HZP.party_id 
	      AND    HZP.category_code in
				      (SELECT FFV.FLEX_VALUE 
				       FROM   FND_FLEX_VALUE_SETS FFVS
					     ,FND_FLEX_VALUES     FFV                     
			               WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
				       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_SCHOOL'));		

									  
CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_US_GOVT_ACCT_V" ("CUST_ACCOUNT_ID") AS 
SELECT DEL.cust_account_id
FROM   iex_f_accounts_V DEL            
WHERE  EXISTS(SELECT cust_account_id 
	      FROM   hz_cust_accounts HCA
		    ,hz_parties       HZP 
	      WHERE  HCA.cust_account_id = DEL.cust_account_id 
	      AND    HCA.party_id 	 = HZP.party_id 
	      AND    HZP.category_code in
				      (SELECT FFV.FLEX_VALUE 
				       FROM   FND_FLEX_VALUE_SETS FFVS
					     ,FND_FLEX_VALUES     FFV                     
			               WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
				       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_GOVT'));

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_DIRECT_ACCT_V" ("CUST_ACCOUNT_ID") AS 
SELECT DEL.cust_account_id
FROM   iex_f_accounts_V DEL
WHERE  EXISTS(SELECT cust_account_id 
              FROM   hz_cust_accounts HCA
       	            ,hz_parties       HZP
              WHERE  HCA.cust_account_id = DEL.cust_account_id 
              AND    HCA.party_id        = HZP.party_id 
              AND    HZP.category_code in 
                                      (SELECT FFV.FLEX_VALUE 
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
				       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_DIRECT'));


CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_MIDLARG_ACCT_V" ("CUST_ACCOUNT_ID") AS 
SELECT DEL.cust_account_id
FROM   iex_f_accounts_V DEL
WHERE  EXISTS(SELECT cust_account_id 
	      FROM   hz_cust_accounts HCA
		    ,hz_parties       HZP
	      WHERE  HCA.cust_account_id = DEL.cust_account_id 
	      AND    HCA.party_id 	 = HZP.party_id 
	      AND    HZP.category_code in 
				      (SELECT FFV.FLEX_VALUE 
				       FROM   FND_FLEX_VALUE_SETS FFVS
					     ,FND_FLEX_VALUES     FFV                     
			               WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
				       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_MIDLARG'));
									  

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_NATION_ACCT_V" ("CUST_ACCOUNT_ID") AS 
SELECT DEL.cust_account_id
FROM   iex_f_accounts_V DEL            
WHERE  EXISTS(SELECT cust_account_id 
	      FROM   hz_cust_accounts HCA
		    ,hz_parties       HZP 
	      WHERE  HCA.cust_account_id = DEL.cust_account_id 
	      AND    HCA.party_id 	 = HZP.party_id 
	      AND    HZP.category_code in 
				      (SELECT FFV.FLEX_VALUE 
				       FROM   FND_FLEX_VALUE_SETS FFVS
				             ,FND_FLEX_VALUES     FFV                     
			               WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
				       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_NATION'));	


CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_NONTRAD_ACCT_V" ("CUST_ACCOUNT_ID") AS 
SELECT DEL.cust_account_id
FROM   iex_f_accounts_V DEL          
WHERE  EXISTS(SELECT cust_account_id 
	      FROM   hz_cust_accounts HCA
		    ,hz_parties       HZP 
	      WHERE  HCA.cust_account_id = DEL.cust_account_id 
	      AND    HCA.party_id 	 = HZP.party_id 
	      AND    HZP.category_code in
				      (SELECT FFV.FLEX_VALUE 
				       FROM   FND_FLEX_VALUE_SETS FFVS
					     ,FND_FLEX_VALUES     FFV                     
			               WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
				       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_NONTRAD'));		
									  							  								  									  

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_SCHOOL_ACCT_V" ("CUST_ACCOUNT_ID") AS 
SELECT DEL.cust_account_id
FROM   iex_f_accounts_V DEL
WHERE  EXISTS(SELECT cust_account_id 
	      FROM   hz_cust_accounts HCA
		    ,hz_parties       HZP 
	      WHERE  HCA.cust_account_id = DEL.cust_account_id 
	      AND    HCA.party_id 	 = HZP.party_id 
	      AND    HZP.category_code in
				      (SELECT FFV.FLEX_VALUE 
				       FROM   FND_FLEX_VALUE_SETS FFVS
					     ,FND_FLEX_VALUES     FFV                     
			               WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
				       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_SCHOOL'));		

									  
CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_GOVT_ACCT_V" ("CUST_ACCOUNT_ID") AS 
SELECT DEL.cust_account_id
FROM   iex_f_accounts_V DEL            
WHERE  EXISTS(SELECT cust_account_id 
	      FROM   hz_cust_accounts HCA
		    ,hz_parties       HZP 
	      WHERE  HCA.cust_account_id = DEL.cust_account_id 
	      AND    HCA.party_id 	 = HZP.party_id 
	      AND    HZP.category_code in
				      (SELECT FFV.FLEX_VALUE 
				       FROM   FND_FLEX_VALUE_SETS FFVS
					     ,FND_FLEX_VALUES     FFV                     
			               WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
				       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_GOVT'));
SHOW ERROR

