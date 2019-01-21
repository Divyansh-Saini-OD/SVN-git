SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_CDH_CUST_ACCT_EXT_VL.vw                          |
-- | Description      :Account Extension view                              |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version   Date         Author             Remarks                      |
-- |=======   ===========  =================  =============================|
-- |DRAFT 1A  09-May-2007  Sathya Prabha Rani   Initial draft version      |
-- +=======================================================================+
-- -----------------------------------------------------
--      DROP view XX_CDH_CUST_ACCT_EXT_VL    --
-- -----------------------------------------------------
	DROP VIEW XX_CDH_CUST_ACCT_EXT_VL;

-- ---------------------------------------------------------------------
--      Create view XX_CDH_CUST_ACCT_EXT_VL    --
-- ---------------------------------------------------------------------
CREATE  VIEW XX_CDH_CUST_ACCT_EXT_VL
(EXTENSION_ID, CUST_ACCOUNT_ID,  ATTR_GROUP_ID, CREATED_BY, 
 CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN, SOURCE_LANG, 
 LANGUAGE, C_EXT_ATTR1, C_EXT_ATTR2, C_EXT_ATTR3, C_EXT_ATTR4, 
 C_EXT_ATTR5, C_EXT_ATTR6, C_EXT_ATTR7, C_EXT_ATTR8, C_EXT_ATTR9, 
 C_EXT_ATTR10, C_EXT_ATTR11, C_EXT_ATTR12, C_EXT_ATTR13, C_EXT_ATTR14, 
 C_EXT_ATTR15, C_EXT_ATTR16, C_EXT_ATTR17, C_EXT_ATTR18, C_EXT_ATTR19, 
 C_EXT_ATTR20, N_EXT_ATTR1, N_EXT_ATTR2, N_EXT_ATTR3, N_EXT_ATTR4, 
 N_EXT_ATTR5, N_EXT_ATTR6, N_EXT_ATTR7, N_EXT_ATTR8, N_EXT_ATTR9, 
 N_EXT_ATTR10, N_EXT_ATTR11, N_EXT_ATTR12, N_EXT_ATTR13, N_EXT_ATTR14, 
 N_EXT_ATTR15, N_EXT_ATTR16, N_EXT_ATTR17, N_EXT_ATTR18, N_EXT_ATTR19, 
 N_EXT_ATTR20, D_EXT_ATTR1, D_EXT_ATTR2, D_EXT_ATTR3, D_EXT_ATTR4, 
 D_EXT_ATTR5, D_EXT_ATTR6, D_EXT_ATTR7, D_EXT_ATTR8, D_EXT_ATTR9, 
 D_EXT_ATTR10, TL_EXT_ATTR1, TL_EXT_ATTR2, TL_EXT_ATTR3, TL_EXT_ATTR4, 
 TL_EXT_ATTR5, TL_EXT_ATTR6, TL_EXT_ATTR7, TL_EXT_ATTR8, TL_EXT_ATTR9, 
 TL_EXT_ATTR10, TL_EXT_ATTR11, TL_EXT_ATTR12, TL_EXT_ATTR13, TL_EXT_ATTR14, 
 TL_EXT_ATTR15, TL_EXT_ATTR16, TL_EXT_ATTR17, TL_EXT_ATTR18, TL_EXT_ATTR19, 
 TL_EXT_ATTR20)
AS 
SELECT B.EXTENSION_ID , B.CUST_ACCOUNT_ID , B.ATTR_GROUP_ID , 
B.CREATED_BY , B.CREATION_DATE , B.LAST_UPDATED_BY , B.LAST_UPDATE_DATE , 
B.LAST_UPDATE_LOGIN , TL.SOURCE_LANG , TL.LANGUAGE , B.C_EXT_ATTR1 , B.C_EXT_ATTR2 , 
B.C_EXT_ATTR3 , B.C_EXT_ATTR4 , B.C_EXT_ATTR5 , B.C_EXT_ATTR6 , B.C_EXT_ATTR7 , 
B.C_EXT_ATTR8 , B.C_EXT_ATTR9 , B.C_EXT_ATTR10 , B.C_EXT_ATTR11 , B.C_EXT_ATTR12 , 
B.C_EXT_ATTR13 , B.C_EXT_ATTR14 , B.C_EXT_ATTR15 , B.C_EXT_ATTR16 , B.C_EXT_ATTR17 , 
B.C_EXT_ATTR18 , B.C_EXT_ATTR19 , B.C_EXT_ATTR20 , B.N_EXT_ATTR1 , B.N_EXT_ATTR2 , 
B.N_EXT_ATTR3 , B.N_EXT_ATTR4 , B.N_EXT_ATTR5 , B.N_EXT_ATTR6 , B.N_EXT_ATTR7 , 
B.N_EXT_ATTR8 , B.N_EXT_ATTR9 , B.N_EXT_ATTR10 , B.N_EXT_ATTR11 , B.N_EXT_ATTR12 , 
B.N_EXT_ATTR13 , B.N_EXT_ATTR14 , B.N_EXT_ATTR15 , B.N_EXT_ATTR16 , B.N_EXT_ATTR17 , 
B.N_EXT_ATTR18 , B.N_EXT_ATTR19 , B.N_EXT_ATTR20 , B.D_EXT_ATTR1 , B.D_EXT_ATTR2 , 
B.D_EXT_ATTR3 , B.D_EXT_ATTR4 , B.D_EXT_ATTR5 , B.D_EXT_ATTR6 , B.D_EXT_ATTR7 , 
B.D_EXT_ATTR8 , B.D_EXT_ATTR9 , B.D_EXT_ATTR10 , TL.TL_EXT_ATTR1 , TL.TL_EXT_ATTR2 , 
TL.TL_EXT_ATTR3 , TL.TL_EXT_ATTR4 , TL.TL_EXT_ATTR5 , TL.TL_EXT_ATTR6 , TL.TL_EXT_ATTR7 , 
TL.TL_EXT_ATTR8 , TL.TL_EXT_ATTR9 , TL.TL_EXT_ATTR10 , TL.TL_EXT_ATTR11 , TL.TL_EXT_ATTR12 , 
TL.TL_EXT_ATTR13 , TL.TL_EXT_ATTR14 , TL.TL_EXT_ATTR15 , TL.TL_EXT_ATTR16 , 
TL.TL_EXT_ATTR17 , TL.TL_EXT_ATTR18 , TL.TL_EXT_ATTR19 , TL.TL_EXT_ATTR20 
FROM XX_CDH_CUST_ACCT_EXT_B B , 
XX_CDH_CUST_ACCT_EXT_TL TL 
WHERE B.EXTENSION_ID = TL.EXTENSION_ID AND TL.LANGUAGE = USERENV('LANG');


SHOW ERRORS;
