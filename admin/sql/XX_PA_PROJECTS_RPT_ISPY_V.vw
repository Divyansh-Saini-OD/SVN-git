CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_ISPY_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_ISPY_V                                |
-- | Description: This View is Created for the PBCGS Reporting         |
-- |              for the PLM/PA team.                                 |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      24-JAN-2008  Ian Bassaragh    Created The View            |
-- |             |                                                     |
-- +===================================================================+
(  EMPLOYEE_NUMBER
  ,USER_ID
  ,FULL_NAME
  ,LAST_CONNECT
  ,PROJECT_ID
  ,PROJECT_NUMBER
  ,PROJECT_NAME
  ,TEMPLATE_FLAG
  ,UPDATED_TABLE
  ,LAST_UPDATE_DATE
 )
AS
SELECT 
 X.EMPLOYEE_NUMBER
,X.USER_ID
,X.FULL_NAME
,Y.LAST_CONNECT
,Z.PROJECT_ID
,Z.SEGMENT1 as PROJECT_NUMBER
,Z.NAME as PROJECT_NAME
,Z.TEMPLATE_FLAG
,Z.UPDATED_TABLE
,Z.LAST_UPDATE_DATE
FROM 
 (SELECT 
   A.EMPLOYEE_NUMBER
  ,A.FULL_NAME
  ,C.USER_ID
  ,C.USER_NAME
  FROM APPS.PA_EMPLOYEES A
      ,APPS.FND_USER C
  WHERE A.EMPLOYEE_NUMBER = C.USER_NAME
    AND A.ACTIVE = '*'  
  ORDER BY C.USER_ID) X
    LEFT OUTER JOIN
  (SELECT
      USER_ID,
      MAX(LAST_CONNECT) as LAST_CONNECT
   FROM APPS.ICX_SESSIONS
  WHERE USER_ID != '-1'
    AND USER_ID = USER_ID
  GROUP BY USER_ID
  ORDER BY USER_ID) Y
   ON  X.USER_ID = Y.USER_ID ,
 (SELECT 
    A.EMPLOYEE_NUMBER
   ,A.FULL_NAME
   ,C.USER_ID
   ,C.USER_NAME
  FROM APPS.PA_EMPLOYEES A
      ,APPS.FND_USER C
  WHERE A.EMPLOYEE_NUMBER = C.USER_NAME
    AND A.ACTIVE = '*'  
  ORDER BY C.USER_ID) W
   LEFT OUTER JOIN 
  ( (  SELECT DISTINCT 
      PPA.PROJECT_ID
    ,PPA.NAME
    ,PPA.SEGMENT1
    ,PPR.LAST_UPDATED_BY
    ,PPR.LAST_UPDATE_DATE
    ,PPA.TEMPLATE_FLAG
    ,'Project Level'AS UPDATED_TABLE
    FROM APPS.PA_PROJECTS_ALL PPA,
         APPS.PA_PROGRESS_ROLLUP PPR
     WHERE PPA.PROJECT_ID = PPR.PROJECT_ID 
       AND PPR.LAST_UPDATED_BY = PPR.LAST_UPDATED_BY
       AND PPR.LAST_UPDATE_DATE =
           (SELECT MAX(PPX.LAST_UPDATE_DATE)
            FROM APPS.PA_PROGRESS_ROLLUP PPX
            WHERE PPX.LAST_UPDATED_BY = PPR.LAST_UPDATED_BY) )
      UNION
    (SELECT 
      PPA.PROJECT_ID
    ,PPA.NAME
    ,PPA.SEGMENT1
    ,PPA.LAST_UPDATED_BY
    ,PPA.LAST_UPDATE_DATE
    ,PPA.TEMPLATE_FLAG
    ,'Task Level' AS UPDATED_TABLE
    FROM APPS.PA_PROJECTS_ALL PPA
     WHERE PPA.LAST_UPDATED_BY = PPA.LAST_UPDATED_BY
       AND PPA.LAST_UPDATE_DATE =
             (SELECT MAX(PPB.LAST_UPDATE_DATE)
            FROM APPS.PA_PROJECTS_ALL PPB
              WHERE PPA.LAST_UPDATED_BY = PPB.LAST_UPDATED_BY)) ) Z
          ON W.USER_ID = Z.LAST_UPDATED_BY
       WHERE X.USER_ID = W.USER_ID;

GRANT SELECT ON  XX_PA_PROJECTS_RPT_ISPY_V TO EUL10_US;

