SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +=======================================================================+
-- |               Office Depot - Credit Card Purge                         |
-- |      Oracle NAIO/Office Depot/Consulting Organization                 |
-- +=======================================================================+
-- | Name        : XX_CC_NUM_UPD_BANK_BKUP_TBL.sql                               |
-- | Description : Script used to take backup of the tables before deletion|
-- |              The schema,which executes this script, must contain the  |
-- |              create privilleges in the schema XXFIN
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0    14-Oct-2015  Madhu Bolli       initial                         |
-- | 1.1    22-Apr-2016  Madhu Bolli       Modified bkup table name        |
-- +=======================================================================+

-- Backup the ap bank accounts tables to XXFIN schema  

CREATE TABLE XXFIN.XX_C2T_AP_BANK_ACCNTS_ALL_BKP tablespace XXOD_TEMP_BACKUP AS
(SELECT /*+parallel(ABA,16) full(ABA) */ *
  FROM AP.AP_BANK_ACCOUNTS_ALL ABA); 
