-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                         WIPRO Technologies                               |
-- +==========================================================================+
-- | SQL Script to populate                                                   |
-- |                                                                          |
-- |                      TABLE: XX_AR_INTSTORECUST                           |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date          Author               Remarks                      |
-- |=======   ===========   ================     =============================|
-- | V1.0     10-JAN-2011   K.Dhillon            Initial version              |
-- |                                             Created for Defect 8950      |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

TRUNCATE TABLE xxfin.xx_ar_intstorecust;

insert into xx_ar_intstorecust(
	 cust_account_id
	,account_number
 )
Select	 cust_account_id
	,account_number
from	hz_cust_accounts
where	Customer_Type = 'I'
and	customer_class_code = 'TRADE - SH'
;

commit;

