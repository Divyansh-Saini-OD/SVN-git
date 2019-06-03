CREATE OR REPLACE VIEW XX_QA_QUALITY_SKU_TRANS_RPT_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA/QA-Project                 |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_QA_QUALITY_SKU_TRANS_RPT_V                            |
-- | Description: This View is Created for the PBCGS Reporting         |
-- |              for the QA team.                                     |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      21-Mar-2008  Ian Bassaragh    Created The View            |
-- |             |                                                     |
-- +===================================================================+
(        TRANSACTION_DESCR
   	,ROWSEQ
	,OD_PB_SKU	
	,VENDOR_DESCR
	,VENDOR_ID
	,FACTORY
	,LOC
	,COST
	,ENGINEERING_CR
	,PASSES
	,FAILS
	,AUTHORIZED_TOSHIP
	,CRITICAL
	,MAJOR
	,MINOR
	,EFFECTIVE_DATE1
	,EFFECTIVE_DATE2 )
AS
SELECT
 '0.0 SKU Vendor Factory Details' as TRANSACTION_DESCR,
  3 as ROWSEQ,
  V.OD_PB_SKU,
  V.OD_PB_SUPPLIER   AS VENDOR_DESCR,
  V.OD_PB_VENDOR_ID  AS VENDOR_ID,
  V.OD_PB_MANUF_NAME AS FACTORY,
  V.OD_PB_MANUF_CITY AS LOC,
  NULL as COST,
  NULL as ENGINEERING_CR,
  NULL as PASSES,
  NULL as FAILS,
  NULL as AUTHORIZED_TOSHIP,
  NULL as CRITICAL,
  NULL as MAJOR,
  NULL as MINOR,
  V.OD_PB_MAX_DT_ENT as EFFECTIVE_DATE1,
  V.OD_PB_MAX_DT_CHG as EFFECTIVE_DATE2
  FROM APPS.Q_OD_PB_VEND_FACTORY_SKU_V V
  WHERE V.OD_PB_SKU is not null 
    GROUP BY
        V.OD_PB_SKU,
        V.OD_PB_SUPPLIER,
        V.OD_PB_VENDOR_ID,
        V.OD_PB_MANUF_NAME,
        V.OD_PB_MANUF_CITY,
        V.OD_PB_MAX_DT_ENT,
        V.OD_PB_MAX_DT_CHG
UNION ALL
SELECT
  '1.0 Engineering Change Request' as TRANSACTION_DESCR,
  1 as ROWSEQ,
  A.OD_PB_SKU,
  '',
  '',
  '',
  '',
  NULL as COST,
  COUNT(A.OD_PB_SKU) AS ENGINEERING_CR,
  NULL as PASSES,
  NULL as FAILS,
  NULL as AUTHORIZED_TOSHIP,
  NULL as CRITICAL,
  NULL as MAJOR,
  NULL as MINOR,
  A.OD_PB_DATE_QA_RESPONSE as EFFECTIVE_DATE1,
  A.OD_PB_DATE_QA_RESPONSE as EFFECTIVE_DATE2
  FROM APPS.Q_OD_PB_ECR_V A
  WHERE A.OD_PB_SKU is not null 
    GROUP BY
        A.OD_PB_SKU,
        A.OD_PB_DATE_QA_RESPONSE
UNION ALL
SELECT '2.0 Pre Purchase Testing Results',
        1,
        B.OD_PB_SKU,
        '',
        '',
        '',
        '',
        NULL,
        NULL,
        SUM((CASE   
            WHEN B.OD_PB_RESULTS = 'PASS' THEN +1 ELSE 0
        END) ) AS PRPURCH_PASSES,
        SUM ( (CASE   
            WHEN B.OD_PB_RESULTS = 'FAIL' THEN +1 ELSE 0        
        END)) AS PRPURCH_FAILURES,
        NULL,
        NULL,
        NULL,
        NULL,
        B.OD_PB_STATUS_TIMESTAMP,
        B.OD_PB_STATUS_TIMESTAMP
        FROM APPS.Q_OD_PB_PRE_PURCHASE_V B
          WHERE B.OD_PB_RESULTS IN ('PASS','FAIL')  
            AND B.OD_PB_SKU is not null 
       GROUP BY B.OD_PB_SKU,
                B.OD_PB_STATUS_TIMESTAMP
UNION ALL
SELECT '2.0 Pre Purchase Testing Results',
        2,
        J.OD_PB_SKU,
        '',
        '',
        '',
        '',
        NULL,
        NULL,
        NULL,
        NULL,
        COUNT(J.OD_PB_SKU),
        NULL,
        NULL,
        NULL,
        J.OD_PB_DATE_APPROVED,
        J.OD_PB_DATE_APPROVED
        FROM APPS.Q_OD_PB_CA_REQUEST_V J
        WHERE J.OD_PB_QA_APPROVER IS NOT NULL  
          AND J.OD_PB_SKU is not null 
       GROUP BY J.OD_PB_SKU,
                J.OD_PB_DATE_APPROVED
UNION ALL
SELECT '3.0 Pre Shipment Testing Results',
        1,
        C.OD_PB_SKU,
        '',
        '',
        '',
        '',
        NULL,
        NULL,
        SUM((CASE   
            WHEN C.OD_PB_RESULTS = 'PASS' THEN +1 ELSE 0
        END) ) AS PRSHIP_PASSES,
        SUM ( (CASE   
            WHEN C.OD_PB_RESULTS = 'FAIL' THEN +1 ELSE 0        
        END)) AS PRSHIP_FAILURES,
        NULL,
        SUM (C.OD_PB_CRITICAL) AS PRSHIP_CRITICAL,
        SUM (C.OD_PB_MAJOR) AS PRSHIP_MAJOR,
        SUM (C.OD_PB_MINOR) AS PRSHIP_MINOR,
        C.OD_PB_DATE_REPORTED,
        C.OD_PB_DATE_REPORTED
        FROM APPS.Q_OD_PB_TESTING_V C
    WHERE C.OD_PB_SKU is not null 
      AND C.OD_PB_PROGRAM_TEST_TYPE ='PRSHIP' 
 GROUP BY C.OD_PB_SKU,
          C.OD_PB_DATE_REPORTED
UNION ALL
SELECT '4.0 Post Purchase Testing Results',
        1,
        D.OD_PB_SKU,
        '',
        '',
        '',
        '',
        NULL,
        NULL,
        SUM((CASE   
            WHEN D.OD_PB_RESULTS = 'PASS' THEN +1 ELSE 0
        END) ) AS POPTST_PASSES,
        SUM ( (CASE   
            WHEN D.OD_PB_RESULTS = 'FAIL' THEN +1 ELSE 0        
        END)) AS POPTST_FAILURES,
        NULL,
        SUM (D.OD_PB_CRITICAL) AS POPTST_CRITICAL,
        SUM (D.OD_PB_MAJOR) AS POPTST_MAJOR,
        SUM (D.OD_PB_MINOR) AS POPTST_MINOR,
        D.OD_PB_DATE_REPORTED,
        D.OD_PB_DATE_REPORTED
    FROM APPS.Q_OD_PB_TESTING_V D
        WHERE D.OD_PB_SKU is not null 
        AND D.OD_PB_PROGRAM_TEST_TYPE ='POPT' 
    GROUP BY D.OD_PB_SKU,
             D.OD_PB_DATE_REPORTED
UNION ALL
SELECT
'5.0 Withdrawal And Safety Details',
 1,
 W.OD_PB_SKU,
 W.OD_PB_DEFECT_SUM,
 '',
 '',
 '',
  SUM(W.OD_PB_COST_ASSOCIATED),
 NULL,
 NULL,
 NULL,
 NULL,
 NULL,
 NULL,
 NULL,
 W.OD_PB_DATE_REPORTED,
 W.OD_PB_DATE_REPORTED 
 FROM APPS.Q_OD_PB_WITHDRAW_SAFETY_V W
 WHERE W.OD_PB_SKU is not null 
    GROUP BY W.OD_PB_SKU,
           W.OD_PB_DEFECT_SUM,
           W.OD_PB_DATE_REPORTED
UNION ALL
SELECT
  '0.1 SKU Vendor Factory Details',
  0,
  '',
  '',
  '',
  '',
  '',
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  TRUNC(SYSDATE),
  TRUNC(SYSDATE)
  FROM DUAL
UNION ALL
SELECT
  '1.1 Engineering Change Request',
  0,
  '',
  '',
  '',
  '',
  '',
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  TRUNC(SYSDATE),
  TRUNC(SYSDATE)
  FROM DUAL
UNION ALL
SELECT '2.1 Pre Purchase Testing Results',
 0,
  '',
  '',
  '',
  '',
  '',
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  TRUNC(SYSDATE),
  TRUNC(SYSDATE)
  FROM DUAL
UNION ALL
SELECT '3.1 Pre Shipment Testing Results',
  0,
  '',
  '',
  '',
  '',
  '',
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  TRUNC(SYSDATE),
  TRUNC(SYSDATE)
  FROM DUAL
UNION ALL
SELECT '4.1 Post Purchase Testing Results',  
 0,
  '',
  '',
  '',
  '',
  '',
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  TRUNC(SYSDATE),
  TRUNC(SYSDATE)
  FROM DUAL
UNION ALL
SELECT
'5.1 Withdrawal And Safety Details',  
 0,
  '',
  '',
  '',
  '',
  '',
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  TRUNC(SYSDATE),
  TRUNC(SYSDATE)
  FROM DUAL;
GRANT SELECT ON XX_QA_QUALITY_SKU_TRANS_RPT_V  TO EUL10_US;
/
