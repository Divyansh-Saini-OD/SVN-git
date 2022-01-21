-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name       :                                                      |
-- | Description: Defect  2774  - (Script Update to DB) Invoice and    |
-- |              Credit Memos - Header Level Rounding Option is       |
-- |              creating 0 rows for every Invoice                    |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version  Date         Author           Remarks                     |
-- |=======  ===========  =============    ============================|
-- |1.0      17-DEC-2009  R.Aldridge       Initial Creation            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

UPDATE AR.AR_SYSTEM_PARAMETERS_ALL
SET TRX_HEADER_LEVEL_ROUNDING = 'N'
WHERE SET_OF_BOOKS_ID IN (6002,6003);

COMMIT;
/