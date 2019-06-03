CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_ACTIVITY_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_ACTIVITY_V                            |
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
(        PROJECT_ID
        ,PROJECT_NUMBER
        ,PROJECT_NAME
        ,ACTIVITY_DESCRIPTION
        ,PROJECT_TYPE)                                            
AS
SELECT  A.PROJECT_ID
       ,A.SEGMENT1  
       ,A.NAME
       ,B.CLASS_CODE
       ,B.CLASS_CATEGORY  
  FROM  PAFV_CLASSES B,
        PA_PROJECTS_ALL A
 WHERE  A.PROJECT_ID > 0 
   AND  A.PROJECT_ID = B.PROJECT_ID
   AND  A.TEMPLATE_FLAG = 'N'  
   AND  B.CLASS_CODE =
        (SELECT C.CLASS_CODE FROM PAFV_CLASSES C
         WHERE C.PROJECT_ID = A.PROJECT_ID
           AND ROWNUM = 1)
ORDER BY A.PROJECT_ID;
GRANT SELECT ON  XX_PA_PROJECTS_RPT_ACTIVITY_V TO EUL10_US;
/