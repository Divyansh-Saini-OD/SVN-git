-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_SFA_WWW_TRUNCATE_ARCHIVE.sql                     |
-- | Description      :I2043 Leads_from_WWW_and_Jmillennia                 |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      15-Feb-2008 David Woods        Initial version                |
-- +=======================================================================+

DELETE FROM XXCRM.XX_SFA_WWW_PROSPECT_ARCHIVE;
COMMIT;
prompt DELETE of XX_SFA_WWW_PROSPECT_ARCHIVE completed

