CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_EXECSUM_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_EXECSUM_V                             |
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
(       ACTIVITY_DESCRIPTION
       ,CREATION_DATE
       ,BUDGET_YEAR
       ,TOT_SKU_NUM 
       ,TOT_IMPACT
       ,TOT_COM_IMPACT
       ,TOT_INP_IMPACT
       ,TOT_CON_IMPACT
       ,TOT_CAN_IMPACT
       ,TOT_COM_SKU
       ,TOT_INP_SKU
       ,TOT_CON_SKU
       ,TOT_CAN_SKU )
AS
SELECT  B.ACTIVITY_DESCRIPTION
       ,B.CREATION_DATE
       ,B.BUDGET_YEAR
       ,SUM(B.SKU_NUM)
       ,SUM(B.TOT_IMPACT)
       ,SUM(B.COM_IMPACT)
       ,SUM(B.INP_IMPACT)
       ,SUM(B.CON_IMPACT)
       ,SUM(B.CAN_IMPACT)
       ,SUM ( CASE B.PROJECT_STATUS_CODE WHEN 'Closed'
            THEN (B.SKU_NUM) ELSE  0 END)
                  AS COM_SKU
       ,SUM ( CASE B.PROJECT_STATUS_CODE WHEN 'Approved'
            THEN (B.SKU_NUM) ELSE ( CASE B.PROJECT_STATUS_CODE
               WHEN 'Submitted' THEN (B.SKU_NUM) ELSE ( CASE B.PROJECT_STATUS_CODE
               WHEN 'Pending Close' THEN (B.SKU_NUM) ELSE 0 END) END) END)  
                  AS INP_SKU
       ,SUM ( CASE B.PROJECT_STATUS_CODE WHEN 'Unapproved'
            THEN (B.SKU_NUM) ELSE ( CASE B.PROJECT_STATUS_CODE
               WHEN 'On Hold' THEN (B.SKU_NUM) ELSE ( CASE B.PROJECT_STATUS_CODE
               WHEN 'ONHOLD' THEN (B.SKU_NUM) ELSE 0 END) END) END)  
                  AS CON_SKU
       ,SUM ( CASE B.PROJECT_STATUS_CODE WHEN 'Cancelled'
            THEN (B.SKU_NUM) ELSE ( CASE B.PROJECT_STATUS_CODE
               WHEN 'CANCELLED'
                  THEN (B.SKU_NUM) ELSE 0 END)  END) AS CAN_SKU
FROM
(SELECT A.PROJECT_ID
       ,A.SEGMENT1
       ,A.NAME
       ,A.ACTIVITY_DESCRIPTION
       ,A.PROJECT_STATUS_CODE
       ,A.CREATION_DATE
       ,A.BUDGET_YEAR
       ,A.SKU_NUM 
       ,SUM(A.SUM_IMPACT) AS TOT_IMPACT
       ,SUM ( CASE A.PROJECT_STATUS_CODE WHEN 'Closed'
            THEN (A.SUM_IMPACT) ELSE  0 END)
                  AS COM_IMPACT
       ,SUM ( CASE A.PROJECT_STATUS_CODE WHEN 'Approved'
            THEN (A.SUM_IMPACT) ELSE ( CASE A.PROJECT_STATUS_CODE
               WHEN 'Submitted' THEN (A.SUM_IMPACT) ELSE ( CASE A.PROJECT_STATUS_CODE
               WHEN 'Pending Close' THEN (A.SUM_IMPACT) ELSE 0 END) END) END)  
                  AS INP_IMPACT
       ,SUM ( CASE A.PROJECT_STATUS_CODE WHEN 'Unapproved'
            THEN (A.SUM_IMPACT) ELSE ( CASE A.PROJECT_STATUS_CODE
               WHEN 'On Hold' THEN (A.SUM_IMPACT) ELSE ( CASE A.PROJECT_STATUS_CODE
               WHEN 'ONHOLD' THEN (A.SUM_IMPACT) ELSE 0 END) END) END)  
                  AS CON_IMPACT
       ,SUM ( CASE A.PROJECT_STATUS_CODE WHEN 'Cancelled'
            THEN (A.SUM_IMPACT) ELSE ( CASE A.PROJECT_STATUS_CODE
               WHEN 'CANCELLED'
                  THEN (A.SUM_IMPACT) ELSE 0 END)  END) AS CAN_IMPACT
       FROM 
(SELECT  PPA1.PROJECT_ID
        ,PPA1.SEGMENT1
        ,PPA1.NAME
        ,XA.ACTIVITY_DESCRIPTION
        ,PPS1.PROJECT_STATUS_NAME AS PROJECT_STATUS_CODE
        ,PPA1.CREATION_DATE
        ,NVL(C.BUDGET_YEAR,EXTRACT(YEAR FROM XD.ALT_LAUNCH_DATE)) AS BUDGET_YEAR
        ,NVL(EEB1.N_EXT_ATTR1,0) AS SKU_NUM 
        ,NVL(C.SUM_IMPACT,0) AS SUM_IMPACT
    FROM
         XX_PA_PROJECTS_RPT_ALTLNCHDT_V XD
	    ,XX_PA_PROJECTS_RPT_ACTIVITY_V XA
        ,PA_PROJECT_STATUSES PPS1 
        ,PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN
            (SELECT  PRA.PROJECT_ID
                    ,EXTRACT(YEAR FROM PBL.END_DATE) AS BUDGET_YEAR
                    ,PBL.REVENUE AS SUM_IMPACT  
               FROM  PA_BUDGET_LINES PBL
                    ,PA_RESOURCE_ASSIGNMENTS PRA
                    ,PA_BUDGET_VERSIONS PBV
                    ,XX_PA_PROJECTS_RPT_LAUNCHDT_V XL
             WHERE PBL.RESOURCE_ASSIGNMENT_ID = PRA.RESOURCE_ASSIGNMENT_ID 
               AND PRA.BUDGET_VERSION_ID = PBV.BUDGET_VERSION_ID 
               AND PBV.BUDGET_STATUS_CODE='B'
               AND PBV.CURRENT_FLAG='Y'
               AND TRUNC(PBL.START_DATE) >=  TRUNC(XL.CURRENT_LAUNCH_DATE)
               AND PRA.PROJECT_ID = XL.PROJECT_ID) C
          ON PPA1.PROJECT_ID = C.PROJECT_ID
         ,PA_PROJECTS_ALL PPA2 LEFT OUTER JOIN
	     ( PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
               EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
               EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
               FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
               PPA2.PROJECT_ID = EEB1.PROJECT_ID
     WHERE PPA1.TEMPLATE_FLAG = 'N'
       AND PPA1.PROJECT_STATUS_CODE = PPS1.PROJECT_STATUS_CODE
       AND PPA1.PROJECT_STATUS_CODE <> 'REJECTED'
       AND PPA1.SEGMENT1 LIKE 'PB%'
       AND PPA1.PROJECT_ID > 0 
       AND PPA1.PROJECT_ID = PPA2.PROJECT_ID
       AND PPA1.PROJECT_ID = XA.PROJECT_ID
       AND PPA1.PROJECT_ID = XD.PROJECT_ID
  ORDER BY PPA1.PROJECT_ID) A
  GROUP BY
        A.PROJECT_ID
       ,A.SEGMENT1
       ,A.NAME
       ,A.ACTIVITY_DESCRIPTION
       ,A.PROJECT_STATUS_CODE
       ,A.CREATION_DATE
       ,A.BUDGET_YEAR
       ,A.SKU_NUM 
  ORDER BY A.PROJECT_ID ) B
  GROUP BY  
        B.ACTIVITY_DESCRIPTION
       ,B.CREATION_DATE
       ,B.BUDGET_YEAR;
GRANT SELECT ON  XX_PA_PROJECTS_RPT_EXECSUM_V  TO EUL10_US;
/
