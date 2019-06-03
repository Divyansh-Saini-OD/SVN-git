-- +===================================================================+
-- |                  Office Depot - QA -Project Conversion            |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_QA_ROLEID_PRD_CONVERSION                              |
-- | Description: This View is Created for the PBCGS Reporting         |
-- |              for the QA/PLM/PA team.                              |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      02-Feb-2008  Ian Bassaragh    For QA team Sylvie Pellerin |
-- |             |                         Run only in GSIPRD01 instnc |
-- +===================================================================+
UPDATE PA_PROJECT_PARTIES
  SET PROJECT_ROLE_ID = 3000,
      LAST_UPDATE_DATE = sysdate 
      WHERE (RESOURCE_SOURCE_ID = 649 or
             RESOURCE_SOURCE_ID = 613 or
             RESOURCE_SOURCE_ID = 631)
         AND (PROJECT_ROLE_ID = 1007 OR
              PROJECT_ROLE_ID = 3000);
