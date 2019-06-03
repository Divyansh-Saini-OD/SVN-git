SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_QA_MAIN_PLAN_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_MAIN_PLAN_PKG.pks    	 	               |
-- | Description :  OD QA Conversion Package Spec                      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       01-Jun-2010 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS


PROCEDURE OD_PB_ATS;

PROCEDURE OD_PB_ATS_EU;

PROCEDURE OD_PB_CA;

PROCEDURE OD_PB_CAP_APPRV;

PROCEDURE OD_PB_CUST_COMP;

PROCEDURE OD_PB_CUST_COMP_EU;

PROCEDURE OD_PB_ECR;

PROCEDURE OD_PB_FA_CODES;

PROCEDURE OD_PB_FAI;

PROCEDURE OD_PB_FQA_ODC;

PROCEDURE OD_PB_FQA_RTLF;

PROCEDURE OD_PB_FQA_US;

PROCEDURE OD_PB_HOUSE_ART;

PROCEDURE OD_PB_LAB_INV;

PROCEDURE OD_PB_MONTH_DEF;

PROCEDURE OD_PB_PRE_PUR;

PROCEDURE OD_PB_PROC_LOG;

PROCEDURE OD_PB_PROT_REV;

PROCEDURE OD_PB_PSI_IC;

PROCEDURE OD_PB_QA_REPORT;

PROCEDURE OD_PB_REG_CERT;

PROCEDURE OD_PB_RET_GOODS;

PROCEDURE OD_PB_SRVC_SCORECARD;

PROCEDURE OD_PB_SPEC_APR;

PROCEDURE OD_PB_TEST_DETAILS;

PROCEDURE OD_PB_TESTING;

PROCEDURE OD_PB_WITHDRAW;

END;
/
