	-- +==========================================================================+ 
	-- |                  Office Depot - Project Simplify                         |
	-- |                       WIPRO Technologies                                 |
	-- +==========================================================================+
	-- | SQL Script to create the Sequences                                       |
	-- | XX_RA_INTERFACE_LINE_STG_BT_S - BATCH_ID of XX_RA_INTERFACE_LINES_STG    |
    -- | XX_RA_INTERFACE_LINE_STG_CT_S - CONTROL_ID of XX_RA_INTERFACE_LINES_STG  |
	-- |                                                                          |
	-- |                                                                          |
	-- |                                                                          |
	-- |Change Record:                                                            |
	-- |===============                                                           |
	-- |Version   Date         Author               Remarks                       |
	-- |=======   ==========   =============        ==============================|
	-- | V1.0     04-DEC-2006  Gowri Shankar        Initial version               |
	-- |                                                                          |
	-- +==========================================================================+

CREATE SEQUENCE xxfin.xx_ra_interface_line_stg_bt_s START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE xxfin.xx_ra_interface_line_stg_ct_s START WITH 1 INCREMENT BY 1;

SHOW ERROR