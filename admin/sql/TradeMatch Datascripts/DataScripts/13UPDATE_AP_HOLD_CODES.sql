SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- +================================================================================+
-- | Name :UPDATE_AP_HOLD_CODES                                         	    |
-- | Description :   SQL Script to update ap_hold_codes                             | 
-- |              				  		                    |
-- | Rice ID     :  E3523                                                      	    |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author               Remarks                             |
-- |=======   ==========   =============        ====================================|
-- | V1.0     28-Nov-2017  Naveen.P	    	Initial version                     |
-- +================================================================================+

Update ap.ap_hold_codes
   set postable_flag='X'
where hold_lookup_code like 'OD%';
Commit;
/
