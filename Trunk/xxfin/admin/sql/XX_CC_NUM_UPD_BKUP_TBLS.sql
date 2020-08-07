SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +=======================================================================+
-- |               Office Depot - Credit Card Purge                         |
-- |      Oracle NAIO/Office Depot/Consulting Organization                 |
-- +=======================================================================+
-- | Name        : XX_CC_NUM_UPD_BKUP_TBLS.sql                               |
-- | Description : Script used to take backup of the tables before deletion|
-- |              The schema,which executes this script, must contain the  |
-- |              create privilleges in the schema XXFIN
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0    14-Oct-2015  Madhu Bolli       initial                        |
-- +=======================================================================+

-- Backup the iby tables to XXFIN schema 

CREATE TABLE xxfin.xx_c2t_xx_iby_creditcard_bkp tablespace XXOD_TEMP_BACKUP AS
(SELECT /*+parallel(ICC,16) full(ICC) */ *
  FROM iby.iby_creditcard ICC); 


CREATE TABLE xxfin.xx_c2t_iby_securitysegment_bkp tablespace XXOD_TEMP_BACKUP AS
(SELECT /*+parallel(ISS,16) full(ISS) */ *
  FROM iby.iby_security_segments ISS); 
