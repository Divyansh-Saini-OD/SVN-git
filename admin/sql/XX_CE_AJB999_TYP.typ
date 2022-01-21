SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_CE_AJB999_TYP.sql                                                               |
-- |  Description:  New Object Type                                                             |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         03-NOV-2012  Paddy Sanjeevi   Initial version                                  |
-- +============================================================================================+
CREATE OR REPLACE TYPE XX_CE_AJB999_TYP IS OBJECT
(
RECORD_TYPE                                        VARCHAR2(50),
STORE_NUM                                          VARCHAR2(30),
PROVIDER_TYPE                                      VARCHAR2(50),
SUBMISSION_DATE                                    DATE,
COUNTRY_CODE                                       VARCHAR2(6),
CURRENCY_CODE                                      VARCHAR2(10),
PROCESSOR_ID                                       VARCHAR2(50),
BANK_REC_ID                                        VARCHAR2(50),
CARDTYPE                                           VARCHAR2(50),
NET_SALES                                          NUMBER,
NET_REJECT_AMT                                     NUMBER,
CHARGEBACK_AMT                                     NUMBER,
DISCOUNT_AMT                                       NUMBER,
NET_DEPOSIT_AMT                                    NUMBER,
CREATION_DATE                                      DATE,
CREATED_BY                                         NUMBER,
LAST_UPDATE_DATE                                   DATE,
LAST_UPDATED_BY                                    NUMBER,
ATTRIBUTE1                                         VARCHAR2(50),
ATTRIBUTE2                                         VARCHAR2(50),
ATTRIBUTE3                                         VARCHAR2(50),
ATTRIBUTE4                                         VARCHAR2(50),
ATTRIBUTE5                                         VARCHAR2(50),
ATTRIBUTE6                                         VARCHAR2(50),
ATTRIBUTE7                                         VARCHAR2(50),
ATTRIBUTE8                                         VARCHAR2(50),
ATTRIBUTE9                                         VARCHAR2(50),
ATTRIBUTE10                                        VARCHAR2(50),
ATTRIBUTE11                                        VARCHAR2(50),
ATTRIBUTE12                                        VARCHAR2(50),
ATTRIBUTE13                                        VARCHAR2(50),
ATTRIBUTE14                                        VARCHAR2(50),
ATTRIBUTE15                                        VARCHAR2(50),
STATUS                                             VARCHAR2(30),
STATUS_1310                                        VARCHAR2(30),
STATUS_1295                                        VARCHAR2(30),
MONTHLY_DISCOUNT_AMT                               NUMBER,
MONTHLY_ASSESSMENT_FEE                             NUMBER,
DEPOSIT_HOLD_AMT                                   NUMBER,
DEPOSIT_RELEASE_AMT                                NUMBER,
SERVICE_FEE                                        NUMBER,
ADJ_FEE                                            NUMBER,
COST_FUNDS_AMT                                     NUMBER,
COST_FUNDS_ALPHA_CODE                              VARCHAR2(60),
COST_FUNDS_NUM_CODE                                NUMBER,
RESERVED_AMT                                       NUMBER,
RESERVED_AMT_ALPHA_CODE                            VARCHAR2(60),
RESERVED_AMT_NUM_CODE                              NUMBER,
SEQUENCE_ID_999                                    NUMBER,
ORG_ID                                             NUMBER,
AJB_FILE_NAME                                      VARCHAR2(200)
);
/

CREATE OR REPLACE TYPE XX_CE_AJB999_LIST_T IS TABLE OF XX_CE_AJB999_TYP;
/

