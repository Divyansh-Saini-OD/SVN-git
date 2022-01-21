-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : DRROP_ALL_CC_IBY_INDEXES.sql                                            	|
-- | Rice Id      :                                                                             | 
-- | Description  : Drop all indexes on 3 tables   												|
-- |					IBY_PMT_INSTR_USES_ALL                        							|
-- |					IBY_SECURITY_SEGMENTS													|
-- |	  				IBY_CREDITCARD															|
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

--IBY_PMT_INSTR_USES_ALL(6 indexes)

drop index IBY.IBY_PMT_INSTR_USES_ALL_N1;
drop index IBY.IBY_PMT_INSTR_USES_ALL_N2;
drop index IBY.IBY_PMT_INSTR_USES_ALL_N3;
drop index IBY.IBY_PMT_INSTR_USES_ALL_U1;
drop index XXFIN.XXIBY_PMT_INSTR_USES_ALL_N1;
drop index XXFIN.XXIBY_PMT_INSTR_USES_ALL_N4;
				 
				 
--IBY_SECURITY_SEGMENTS(2 indexes) 

drop index IBY.IBY_SECURITY_SEGMENTS_U1;
drop index XXFIN.XX_IBY_SECURITY_SEGMENTS_N1;


--IBY_CREDITCARD(6 indexes)

drop index XXFIN.IBY_CREDITCARD_INSTRID_U1;
drop index IBY.XX_IBY_CREDIT_CARD_N99;
drop index IBY.IBY_CREDITCARD_CCNUMBER_N1;
drop index IBY.IBY_CREDITCARD_ENCRYPTED_N2;
drop index IBY.IBY_CREDITCARD_MASK_N4;
drop index IBY.IBY_CREDITCARD_OWNER;
