-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | RICE ID     :  E3023                                                     |
-- | Name        :  AP Trade Match Dashboard                                  |
-- |                                                                          |
-- | SQL Script to create the following object                                |
-- |             Table       : xxfin.xx_ap_inv_match_detail_219                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | 1.0      25-jan-2018  Priyam         Added new columns             |
-- |          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

alter table xx_ap_inv_match_detail_219 add (invoice_source varchar2(25),
invoice_num varchar2(50), 
created_by varchar2(64),
last_update_date date,
last_updated_by varchar2(64), 
validation_flag varchar2(5), 
hold_count number,
hold_last_updated_by varchar2(64),
hold_last_update_date date,
vendor_id number,
vendor_site_id number);   
	   
SHOW ERROR;
