SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_QA_CONV_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_CONV_PKG.pks    	 	               |
-- | Description :  OD QA Conversion Package Spec                      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       01-Jun-2010 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS


PROCEDURE OD_PB_ATS_DOC;

PROCEDURE OD_PB_ATS_EU_DOC;

PROCEDURE OD_PB_CA_DOC;

PROCEDURE OD_PB_CUST_COMP_DOC;

PROCEDURE OD_PB_CUST_COMP_EU_DOC;

PROCEDURE OD_PB_ECR_DOC;

PROCEDURE OD_PB_PRE_PUR_DOC;

PROCEDURE OD_PB_PSI_DOC;

PROCEDURE OD_PB_REG_CERT_DOC;

PROCEDURE OD_PB_TESTING_DOC;

PROCEDURE OD_PB_WITHDRAW_DOC;

PROCEDURE OD_PB_FQA_ODC;

PROCEDURE OD_PB_HOUSE_ART_DOC;

PROCEDURE OD_PB_CAP_APPRV_DOC;

PROCEDURE OD_PB_PROT_REV_DOC;

PROCEDURE OD_PB_QA_REPORT_DOC;

PROCEDURE OD_PB_RET_GOODS_DOC;

PROCEDURE OD_PB_PROC_LOG_DOC;

PROCEDURE OD_PB_FQA_US_DOC;

PROCEDURE OD_PB_FAI_DOC;

PROCEDURE OD_PB_SPEC_APR_DOC;

PROCEDURE OD_PB_ATS_HIS_DOC;

PROCEDURE OD_PB_CA_HIS_DOC;

PROCEDURE OD_PB_PROLOG_HIS_DOC;

PROCEDURE OD_PB_TESTING_HIS_DOC;

PROCEDURE OD_PB_PSI_HIS_DOC;

PROCEDURE OD_PB_ECR_HIS_DOC;

PROCEDURE OD_PB_PREPUR_HIS_DOC;

PROCEDURE OD_PB_FQA_HIS_DOC;

PROCEDURE OD_PB_SPECAPR_HIS_DOC;

PROCEDURE OD_PB_REGFEE_HIS_DOC;

PROCEDURE OD_PB_FAI_HIS_DOC;

PROCEDURE OD_PB_CUSTCOM_HIS_DOC;

END;
/
