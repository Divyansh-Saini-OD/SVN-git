-- +===================================================================+
-- |                  Office Depot - iSupplier Setup                   |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_POS_CUSTOMIZATION_LEVEL                               |
-- | Description: SCRIPT is Created for the PBCGS iSupplier setup      |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      10-Mar-2008  Ian Bassaragh    To set customization_level  |
-- |             |                                                     |
-- +===================================================================+
UPDATE APPS.FND_LOOKUP_TYPES
  SET CUSTOMIZATION_LEVEL = 'U'
      WHERE LOOKUP_TYPE LIKE '%POS_USER_ACCESS_ITEMS%';