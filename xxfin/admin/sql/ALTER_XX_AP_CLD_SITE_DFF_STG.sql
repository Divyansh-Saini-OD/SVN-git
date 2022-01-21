-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | RICE ID     :                                                            |
-- | Name        :  Table Alter for contacts table                            |
-- |                                                                          |
-- | SQL Script to create the following object                                |
-- |             Table       : XX_AP_CLD_SITE_DFF_STG                         |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | 1.0      30-JUN-2019  Havish Kasina        Added new columns             |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

alter table XX_AP_CLD_SITE_DFF_STG
modify (CREATION_DATE DATE,
        LAST_UPDATE_DATE DATE
);
  
SHOW ERROR;
