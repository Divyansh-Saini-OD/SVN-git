SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE SPECIFICATION XX_CM_99X_ADHOC_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_CM_99X_ADHOC_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_CM_99X_ADHOC_PKG                                          |
-- | RICE ID :  R1161                                                    |
-- | Description :This package is the executable of the wrapper program  |
-- |              that used for submitting the OD: CM 996 AdHoc Report   |
-- |              (or) OD: CM 998 AdHoc Report (or) OD: CM 999 AdHoc     |
-- |              Report based on the input parameters for the user and  |
-- |              the default format is EXCEL                            | 
-- |                                                                     |
-- |                                                                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  19-FEB-10     Mohammed Appas          Initial version      |
-- | 1.0      21-APR-10     Mohammed Appas          Defect#5356, 5360    |
-- |                                                                     |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_CM_99X_ADHOC_PROC                                        |
-- | Description : The procedure will submit the OD: CM 996 AdHoc Report |
-- |               (or) OD: CM 998 AdHoc Report                          |
-- |               (or) OD: CM 999 AdHoc Report                          |
-- |                                                                     |
-- | Parameters  : P_99X, P_SUMMARY_DETAIL, P_BANKREC_ID_DATE,           |
-- |               P_DUMMY_BANK_REC_ID, P_DUMMY_BANK_REC_ID,             |
-- |               P_DUMMY_TRX_DATE, P_BANKREC_ID, P_TRXDATE_FROM,       |
-- |               P_TRXDATE_TO, P_DUMMY2, P_LOCATION, P_PROCESSOR_ID,   |
-- |               P_AMOUNT                                              |
-- | Returns    :  x_err_buff,x_ret_code                                 |
-- +=====================================================================+

PROCEDURE XX_CM_99X_ADHOC_PROC(
                               x_err_buff           OUT VARCHAR2
                              ,x_ret_code           OUT NUMBER
                              ,P_99X                IN  VARCHAR2
                              ,P_SUMMARY_DETAIL     IN  VARCHAR2
                              --,P_BANKREC_ID_TRX_DATE  IN  VARCHAR2           --Commented for Defect# 5356/5360
                              --,P_DUMMY                IN  VARCHAR2           --Commented for Defect# 5356/5360
                              ,P_BANKREC_ID_DATE    IN  VARCHAR2               --Added for Defect# 5356/5360
                              ,P_DUMMY_BANK_REC_ID  IN  VARCHAR2               --Added for Defect# 5356/5360
                              ,P_DUMMY_TRX_DATE     IN  VARCHAR2               --Added this parameter P_DUMMY_TRX_DATE for Defect# 5356/5360
                              ,P_BANKREC_ID         IN  VARCHAR2               --Added this parameter P_BANKREC_ID for Defect# 5356/5360
                              ,P_TRXDATE_FROM       IN  DATE
                              ,P_TRXDATE_TO         IN  DATE
                              ,P_DUMMY2             IN  VARCHAR2
                              ,P_LOCATION           IN  VARCHAR2
                              ,P_PROCESSOR_ID       IN  VARCHAR2
                              ,P_AMOUNT             IN  NUMBER
                             );

END  XX_CM_99X_ADHOC_PKG;
/

SHO ERR;