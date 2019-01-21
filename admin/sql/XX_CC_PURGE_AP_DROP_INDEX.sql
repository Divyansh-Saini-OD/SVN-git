-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_CC_PURGE_AP_DROP_INDEX.sql                                            	|
-- | Rice Id      :                                                                             | 
-- | Description  : Drop all indexes on 2 tables  AP_BANK_ACCOUNTS_ALL and 						|
-- |					AP_BANK_ACCOUNT_USES_ALL                        						|	  
-- | Purpose      :                                                                             |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      | 
-- |=======    ==========    =================    ==============================================+
-- |1.0        09-MAY-2016   Avinash Baddam       Initial Version                               |
-- +============================================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON


--AP_BANK_ACCOUNTS_ALL(8 indexes)

drop index AP.AP_BANK_ACCOUNTS_N1;
drop index AP.AP_BANK_ACCOUNTS_N2;
drop index AP.AP_BANK_ACCOUNTS_N3;
drop index AP.AP_BANK_ACCOUNTS_N4;
drop index AP.AP_BANK_ACCOUNTS_U1;
drop index AP.AP_BANK_ACCOUNTS_U2;
drop index XXFIN.XX_AP_BANK_ACCOUNTS_N1;
drop index XXFIN.XX_AP_BANK_ACCOUNTS_ALL_N2;
				 
				 
--AP_BANK_ACCOUNT_USES_ALL(2 indexes) 

drop index AP.AP_BANK_ACCOUNT_USES_N1;
drop index AP.AP_BANK_ACCOUNT_USES_N2;
drop index AP.AP_BANK_ACCOUNT_USES_N4;
drop index AP.AP_BANK_ACCOUNT_USES_N5;
drop index AP.AP_BANK_ACCOUNT_USES_U1;
drop index XXFIN.XX_AP_BANK_ACCTS_ALL_N1;


