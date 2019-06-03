-- +===================================================================+
-- |                  Office Depot - QA -Project Conversion            |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_QA_ROLEID_QAS_CONVERSION                              |
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
-- |             |                         Run only in GSIQASGB instnc |
-- +===================================================================+
UPDATE PA_PROJECT_PARTIES
  SET PROJECT_ROLE_ID = 5000,
      LAST_UPDATE_DATE = sysdate 
WHERE (RESOURCE_SOURCE_ID = 666 or
       RESOURCE_SOURCE_ID = 702 or
       RESOURCE_SOURCE_ID = 720)
    AND (PROJECT_ROLE_ID = 1007 OR
         PROJECT_ROLE_ID = 5000);
