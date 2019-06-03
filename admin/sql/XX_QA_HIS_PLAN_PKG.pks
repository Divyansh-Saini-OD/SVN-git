SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_QA_HIS_PLAN_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_HIS_PLAN_PKG.pks    	 	               |
-- | Description :  OD QA Conversion Package Spec                      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       01-Jun-2010 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS


PROCEDURE OD_PB_CA_HIS_INS;

PROCEDURE OD_PB_CA_HIS;

PROCEDURE OD_PB_ECR_HIS_INS;

PROCEDURE OD_PB_ECR_HIS;

PROCEDURE OD_PB_FAI_HIS_INS;

PROCEDURE OD_PB_FAI_HIS;

PROCEDURE OD_PB_PPUR_HIS_INS;

PROCEDURE OD_PB_PPUR_HIS;

PROCEDURE OD_PB_PLOG_HIS_INS;

PROCEDURE OD_PB_PLOG_HIS;

PROCEDURE OD_PB_PSI_HIS_INS;

PROCEDURE OD_PB_PSI_HIS;

PROCEDURE OD_PB_SAPR_HIS_INS;

PROCEDURE OD_PB_SAPR_HIS;

PROCEDURE OD_PB_ATS_HIS_INS;

PROCEDURE OD_PB_ATS_HIS;

PROCEDURE OD_PB_CUSCOMP_HIS_INS;

PROCEDURE OD_PB_CUSCOMP_HIS;

PROCEDURE OD_PB_CUSCOMPEU_HIS_INS;

PROCEDURE OD_PB_CUSCOMPEU_HIS;

PROCEDURE OD_PB_FQA_HIS_INS;

PROCEDURE OD_PB_FQA_HIS;

PROCEDURE OD_PB_REGCERT_HIS_INS;

PROCEDURE OD_PB_REGCERT_HIS;

PROCEDURE OD_PB_TESTING_HIS_INS;

PROCEDURE OD_PB_TESTING_HIS;

END;
/
