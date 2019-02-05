  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  UPDATE_XXPO_PUNCHOUT_CONFIG.sql                                                    |
  -- |                                                                                            |
  -- |  Description:  This SQL Script is used to end date the Punchout Config Translation         |
  -- |                (One time script)                                                           |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         08-NOV-2017  Suresh Naragam   Initial version                                  |
  -- +============================================================================================+

UPDATE xx_fin_translatedefinition
SET translation_name = 'XXPO_PUNCHOUT_CONFIG_old',
    enabled_flag = 'N',
	end_date_active = SYSDATE
WHERE translation_name = 'XXPO_PUNCHOUT_CONFIG';

COMMIT;
/