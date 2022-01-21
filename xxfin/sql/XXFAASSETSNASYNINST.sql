        -- +===================================================================+
	-- |                  Office Depot - Project Simplify                  |
	-- |                       WIPRO Technologies                          |
	-- +===================================================================+
	-- | SQL Script to create the Synonyms for the Sequences               |
	-- |    xx_fa_mass_additions_stg_bt_s1,xx_fa_mass_additions_stg_ct_s1  |
	-- |                                                                   |
	-- |                                                                   |
	-- |                                                                   |
	-- |Change Record:                                                     |
	-- |===============                                                    |
	-- |Version   Date         Author               Remarks                |
	-- |=======   ==========   =============        =======================|
	-- |1.0          02-JAN-2007  Amaresh Rath        Initial version      |
	-- |                                                                   |
	-- +===================================================================+

CREATE SYNONYM xx_fa_mass_additions_stg_bt_s1 FOR xxfin.xx_fa_mass_additions_stg_bt_s1;

CREATE SYNONYM xx_fa_mass_additions_stg_ct_s1 FOR xxfin.xx_fa_mass_additions_stg_ct_s1;

SHOW ERROR