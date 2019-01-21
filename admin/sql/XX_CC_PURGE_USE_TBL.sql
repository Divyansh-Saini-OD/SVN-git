SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +=======================================================================+
-- |               Office Depot - Credit Card Purge                         |
-- |      Oracle NAIO/Office Depot/Consulting Organization                 |
-- +=======================================================================+
-- | Name        : XX_CC_PURGE_USE_TBL.sql                                |
-- | Description : Script used to purge the Credit Card data for few CreditCardTypes |
-- |               This script creates table used in Credit Card Purge SQL |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | DraftA  25-Feb-2015  Rajeev            Created by Rajeev              |
-- | 1.0     25-Feb-2015  Madhu Bolli       Created the table in separate script |
-- | 1.1     07-May-2016  Madhu Bolli       Added / at end of the script   |
-- +=======================================================================+

CREATE TABLE xxfin.xx_ar_intstore_r12_temp TABLESPACE "XXOD_TEMP_BACKUP"  AS
(SELECT /*+parallel(HCA,8) full(HCA) */ XAIO.cust_account_id
      ,XAIO.account_number
      ,HCA.party_id
  FROM xxfin.xx_ar_intstorecust_otc  XAIO
      ,ar.hz_cust_accounts           HCA    
 WHERE XAIO.cust_account_id = HCA.cust_account_id); 
  
 begin fnd_stats.gather_table_stats('XXFIN', 'XX_AR_INTSTORE_R12_TEMP'); end; 
 /
 