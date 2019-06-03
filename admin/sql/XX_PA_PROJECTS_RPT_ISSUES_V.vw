CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_ISSUES_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_ISSUES_V                              |
-- | Description: This View is Created for the PBCGS Reporting         |
-- |              for the PLM/PA team.                                 |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      04-Oct-2007  Ian Bassaragh    Created The View            |
-- |             |                                                     |
-- +===================================================================+
(       PROJECT_ID
       ,PROJECT_NUMBER
       ,PROJECT_NAME
       ,SUMMARY
       ,STATUS_CODE
       ,DESCRIPTION
       ,STATUS_OVERVIEW
       ,RESOLUTION
       ,PRIORITY_CODE
       ,OWNER_ID
       ,HIGHLIGHTED_FLAG
       ,PROGRESS_STATUS_CODE
       ,PROGRESS_AS_OF_DATE
       ,TRACK_NAME
       ,TRACK_DESCRIPTION )
AS
SELECT  PPCI.PROJECT_ID
       ,PPA.SEGMENT1
       ,PPA.NAME
       ,PPCI.SUMMARY
       ,PPCI.STATUS_CODE
       ,PPCI.DESCRIPTION
       ,PPCI.STATUS_OVERVIEW
       ,PPCI.RESOLUTION
       ,PPCI.PRIORITY_CODE
       ,PPCI.OWNER_ID
       ,PPCI.HIGHLIGHTED_FLAG
       ,PPCI.PROGRESS_STATUS_CODE
       ,PPCI.PROGRESS_AS_OF_DATE
       ,PPCTT.NAME
       ,PPCTT.DESCRIPTION
       FROM PA.PA_CONTROL_ITEMS PPCI,
            PA.PA_CI_TYPES_TL PPCTT,
            PA.PA_PROJECTS_ALL PPA
       WHERE PPCI.PROJECT_ID > 0 AND
             PPCI.CI_TYPE_ID = PPCTT.CI_TYPE_ID AND
             PPCI.PROJECT_ID = PPA.PROJECT_ID
       ORDER BY PPCI.PROJECT_ID;
GRANT SELECT ON  XX_PA_PROJECTS_RPT_ISSUES_V TO EUL10_US;
/