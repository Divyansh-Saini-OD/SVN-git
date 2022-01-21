	-- +==========================================================================+
	-- |                  Office Depot - Project Simplify                         |
	-- |                       WIPRO Technologies                                 |
	-- +==========================================================================+
	-- | SQL Script to create the Sequences                                       |
	-- | xx_fa_mass_additions_stg_bt_s1 - BATCH_ID of xx_fa_mass_additions_stg    |
        -- | xx_fa_mass_additions_stg_ct_s1 - CONTROL_ID of xx_fa_mass_additions_stg  |
	-- |                                                                          |
	-- |                                                                          |
	-- |                                                                          |
	-- |Change Record:                                                            |
	-- |===============                                                           |
	-- |Version   Date         Author               Remarks                       |
	-- |=======   ==========   =============        ==============================|
	-- | 1.0          02-JAN-2007  Amaresh Rath        Initial version            |
	-- |                                                                          |
	-- +==========================================================================+

CREATE SEQUENCE xxfin.xx_fa_mass_additions_stg_bt_s1 START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE xxfin.xx_fa_mass_additions_stg_ct_s1 START WITH 1 INCREMENT BY 1;

SHOW ERROR