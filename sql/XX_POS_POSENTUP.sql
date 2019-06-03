-- +===================================================================+
-- |                  Office Depot - iSupplier Setup                   |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_POS_POSENTUP.SQL                                      |
-- | Description: SCRIPT is Created for the PBCGS iSupplier setup      |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      10-Mar-2008  Ian Bassaragh    SET ENTERPRISE NAME         |
-- |             |                                                     |
-- +===================================================================+
UPDATE APPS.HZ_PARTIES
SET PARTY_NAME = 'Office Depot',
    LAST_UPDATE_DATE=sysdate,
    LAST_UPDATED_BY = -2
WHERE PARTY_ID = 1021;
   