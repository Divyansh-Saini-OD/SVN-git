SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +=======================================================================+
-- |               Office Depot - Credit Card Purge                         |
-- |      Oracle NAIO/Office Depot/Consulting Organization                 |
-- +=======================================================================+
-- | Name        : XX_CC_PURGE_BKUP_TBLS.sql                               |
-- | Description : Script used to take backup of the tables before deletion|
-- |              The schema,which executes this script, must contain the  |
-- |              create privilleges in the schema XXFIN
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | DraftA  25-Feb-2015  Rajeev            Created by Rajeev              |
-- | 1.0     04-Mar-2015  Madhu Bolli       Created the backup tables in separate script |
-- +=======================================================================+

-- Backup the iby tables to XXFIN schema 

CREATE TABLE xxfin.iby_pmt_instr_uses_all_bkp AS
(SELECT /*+parallel(IPU,16) full(IPU) */ *
  FROM iby.iby_pmt_instr_uses_all IPU); 
  

CREATE TABLE xxfin.iby_security_segments_bkp AS
(SELECT /*+parallel(ISS,16) full(ISS) */ *
  FROM iby.iby_security_segments ISS); 


CREATE TABLE xxfin.iby_creditcard_bkp AS
(SELECT /*+parallel(ICC,16) full(ICC) */ *
  FROM iby.iby_creditcard ICC); 

-- Backup the ap bank accounts tables to XXFIN schema  

CREATE TABLE XXFIN.AP_BANK_ACCOUNTS_ALL_BKP AS
(SELECT /*+parallel(ABA,16) full(ABA) */ *
  FROM AP.AP_BANK_ACCOUNTS_ALL ABA); 

  
CREATE TABLE XXFIN.AP_BANK_ACCOUNT_USES_ALL_BKP AS
(SELECT /*+parallel(ABAU,16) full(ABAU) */ *
  FROM AP.AP_BANK_ACCOUNT_USES_ALL ABAU); 
