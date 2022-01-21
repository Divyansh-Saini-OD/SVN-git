	-- +===================================================================+ 
	-- |                  Office Depot - Project Simplify                  |
	-- |                       WIPRO Technologies                          |
	-- +===================================================================+
	-- | SQL Script to create the Synonyms for the Sequences               |
	-- |    XX_RA_INTERFACE_LINE_STG_BT_S,XX_RA_INTERFACE_LINE_STG_CT_S    |
	-- |                                                                   |
	-- |                                                                   |
	-- |                                                                   |
	-- |Change Record:                                                     |
	-- |===============                                                    |
	-- |Version   Date         Author               Remarks                |
	-- |=======   ==========   =============        =======================|
	-- | V1.0     04-DEC-2006  Gowri Shankar        Initial version        |
	-- |                                                                   |
	-- +===================================================================+

CREATE SYNONYM xx_ra_interface_line_stg_bt_s FOR xxfin.xx_ra_interface_line_stg_bt_s;

CREATE SYNONYM xx_ra_interface_line_stg_ct_s FOR xxfin.xx_ra_interface_line_stg_ct_s;

SHOW ERROR
