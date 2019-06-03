/*======================================================================
-- +===================================================================+
-- |                  Office Depot - PA PROJECT - MESSAGE TYPE         |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name       :  XX_PA_MESSAGE_TYPE                                  |
-- | Description:  AQ MESSAGE TYPE FOR trigger is Created for the PBCGS|
-- |               to synchronize number of SKUS on a project with     |
-- |               project item ids.                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      03-Apr-2008  Ian Bassaragh    Created This MESSAGE TYPE   |
-- |                                                                   |
-- +===================================================================+
+======================================================================*/
CREATE OR REPLACE TYPE XX_PA_MESSAGE_TYPE AS OBJECT (PRJ_ID NUMBER, SKU_NUM NUMBER, UPDT_BY NUMBER);
/
