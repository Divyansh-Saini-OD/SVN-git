CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_FINISTAT_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_FINISTAT_V                            |
-- | Description: This View is Created for the PBCGS Reporting         |
-- |              for the PLM/PA team.                                 |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      26-Oct-2007  Ian Bassaragh    Created The View            |
-- |             |                                                     |
-- +===================================================================+
(       BRAND_MANAGER
       ,PROJECT_STATUS
       ,BUDGET_YEAR
       ,TOT_SKU_NUM 
       ,TOT_PROJECTS
       ,TOTAL
       ,QTR1_TOTAL
       ,QTR2_TOTAL
       ,QTR3_TOTAL
       ,QTR4_TOTAL)
AS
SELECT  A.BRAND_MANAGER
       ,A.PROJECT_STATUS
       ,B.BUDGET_YEAR
       ,SUM(A.SKU_NUM) AS SKU_COUNT
       ,COUNT(*) AS PROJECT_NUM
       ,SUM(NVL(B.TOTAL,0)) AS TOTAL
       ,SUM(NVL(B.QTR1_TOT,0)) AS QTR1_TOTAL
       ,SUM(NVL(B.QTR2_TOT,0)) AS QTR2_TOTAL
       ,SUM(NVL(B.QTR3_TOT,0)) AS QTR3_TOTAL
       ,SUM(NVL(B.QTR4_TOT,0)) AS QTR4_TOTAL 
   FROM 
   (SELECT
        PPA1.PROJECT_ID  AS PROJECT_ID
       ,(CASE   
            WHEN PPS1.PROJECT_STATUS_NAME = 'Closed'     THEN 'COMPLETE'
            WHEN PPS1.PROJECT_STATUS_NAME = 'Unapproved' THEN 'CONCEPT'
	    WHEN PPS1.PROJECT_STATUS_NAME = 'On Hold'    THEN 'CONCEPT'
            WHEN EEB1.C_EXT_ATTR4 = 'ON_TARGET_GREEN'    THEN 'GREEN'
	    WHEN EEB1.C_EXT_ATTR4 = 'LATE_RED'           THEN 'RED'
            WHEN EEB1.C_EXT_ATTR4 = 'AT_RISK_YELLOW'     THEN 'YELLOW'
            ELSE 'NOT CLASSIFIED'
        END) AS PROJECT_STATUS
       ,COALESCE(EEB1.N_EXT_ATTR1,0) AS SKU_NUM
       ,COALESCE(PRT1.RESOURCE_SOURCE_NAME,'')  AS BRAND_MANAGER 
       FROM PA_PROJECT_STATUSES PPS1,
            PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID,
            PA_PROJECTS_ALL PPA2 LEFT OUTER JOIN 
                PA_PROJ_PARTIES_PROG_EDIT_V PRT1 ON 
                PPA2.PROJECT_ID = PRT1.PROJECT_ID AND PRT1.PROJECT_ROLE_NAME = 'Business Manager'
       WHERE PPA1.PROJECT_ID > 0 
         AND PPA1.PROJECT_STATUS_CODE = PPS1.PROJECT_STATUS_CODE
         AND PPA1.PROJECT_STATUS_CODE <> 'REJECTED'
         AND PPA1.TEMPLATE_FLAG = 'N'
         AND PPA1.SEGMENT1 LIKE 'PB%' 
         AND PPA1.PROJECT_ID = PPA2.PROJECT_ID
    ORDER BY PPA1.PROJECT_ID ) A
       ,(SELECT  C.PROJECT_ID
                ,C.BUDGET_YEAR
                ,SUM(C.REVENUE) AS TOTAL
                ,SUM(C.QTR1) AS QTR1_TOT
                ,SUM(C.QTR2) AS QTR2_TOT
                ,SUM(C.QTR3) AS QTR3_TOT
                ,SUM(C.QTR4) AS QTR4_TOT
       FROM
        (SELECT 
                 XD.PROJECT_ID
                ,NVL(E.BUDGET_YEAR,EXTRACT(YEAR FROM XD.ALT_LAUNCH_DATE)) AS BUDGET_YEAR
                ,NVL(E.REVENUE,0) AS REVENUE
                ,NVL(E.QTR1,0) AS QTR1 
                ,NVL(E.QTR2,0) AS QTR2 
                ,NVL(E.QTR3,0) AS QTR3
                ,NVL(E.QTR4,0) AS QTR4 
           FROM 
            XX_PA_PROJECTS_RPT_ALTLNCHDT_V XD LEFT OUTER JOIN
	   (SELECT PRA.PROJECT_ID
        	,PBL.REVENUE
        	,PBL.START_DATE
        	,PBL.END_DATE
                ,EXTRACT(YEAR FROM PBL.END_DATE) AS BUDGET_YEAR
        	,EXTRACT(MONTH FROM END_DATE)
        	,CASE WHEN EXTRACT(MONTH FROM END_DATE) BETWEEN 1 AND 3
            		THEN PBL.REVENUE ELSE 0 END AS QTR1
        	,CASE WHEN EXTRACT(MONTH FROM END_DATE) BETWEEN 4 AND 6
            		THEN PBL.REVENUE ELSE 0 END AS QTR2
        	,CASE WHEN EXTRACT(MONTH FROM END_DATE) BETWEEN 7 AND 9
            		THEN PBL.REVENUE ELSE 0 END AS QTR3
        	,CASE WHEN EXTRACT(MONTH FROM END_DATE) BETWEEN 10 AND 12
            		THEN PBL.REVENUE ELSE 0 END AS QTR4    
         	FROM 
                 PA_BUDGET_LINES PBL
             	,PA_RESOURCE_ASSIGNMENTS PRA
             	,PA_BUDGET_VERSIONS PBV
             	,APPS.XX_PA_PROJECTS_RPT_LAUNCHDT_V XL
        	WHERE PBL.RESOURCE_ASSIGNMENT_ID = PRA.RESOURCE_ASSIGNMENT_ID 
         		 AND PRA.BUDGET_VERSION_ID = PBV.BUDGET_VERSION_ID 
          	AND PBV.BUDGET_STATUS_CODE='B'
          	AND PBV.CURRENT_FLAG='Y'
          	AND TRUNC(PBL.START_DATE) >=  TRUNC(XL.CURRENT_LAUNCH_DATE)
          	AND PRA.PROJECT_ID = XL.PROJECT_ID
          AND PRA.PROJECT_ID > 0 
          ORDER BY PRA.PROJECT_ID ) E 
          ON XD.PROJECT_ID = E.PROJECT_ID ) C 
          GROUP BY C.PROJECT_ID
                  ,C.BUDGET_YEAR) B
          WHERE  A.PROJECT_ID = B.PROJECT_ID
          GROUP BY A.BRAND_MANAGER
                  ,A.PROJECT_STATUS
                  ,B.BUDGET_YEAR ;
GRANT SELECT ON  XX_PA_PROJECTS_RPT_FINISTAT_V  TO EUL10_US;
/
