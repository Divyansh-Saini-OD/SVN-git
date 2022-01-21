-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_CE_AJB996_TYP.sql                                                               |
-- |  Description:  New Object Type                                                             |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         03-NOV-2012  Paddy Sanjeevi   Initial version                                  |
-- +============================================================================================+

CREATE OR REPLACE TYPE XX_CE_AJB996_TYP AS OBJECT
(
RECORD_TYPE                                        VARCHAR2(15),
VSET_FILE                                          VARCHAR2(50),
SDATE                                              DATE,
ACTION_CODE                                        NUMBER,
ATTRIBUTE1                                         VARCHAR2(50),
PROVIDER_TYPE                                      VARCHAR2(50),
ATTRIBUTE2                                         VARCHAR2(50),
STORE_NUM                                          VARCHAR2(30),
TERMINAL_NUM                                       NUMBER,
TRX_TYPE                                           VARCHAR2(50),
ATTRIBUTE3                                         VARCHAR2(50),
ATTRIBUTE4                                         VARCHAR2(50),
CARD_NUM                                           VARCHAR2(100),
ATTRIBUTE5                                         VARCHAR2(50),
ATTRIBUTE6                                         VARCHAR2(50),
TRX_AMOUNT                                         NUMBER,
INVOICE_NUM                                        VARCHAR2(100),
COUNTRY_CODE                                       VARCHAR2(6),
CURRENCY_CODE                                      VARCHAR2(10),
ATTRIBUTE7                                         VARCHAR2(50),
ATTRIBUTE8                                         VARCHAR2(50),
ATTRIBUTE9                                         VARCHAR2(50),
ATTRIBUTE10                                        VARCHAR2(50),
ATTRIBUTE11                                        VARCHAR2(50),
ATTRIBUTE12                                        VARCHAR2(50),
ATTRIBUTE13                                        VARCHAR2(50),
ATTRIBUTE14                                        VARCHAR2(50),
ATTRIBUTE15                                        VARCHAR2(50),
ATTRIBUTE16                                        VARCHAR2(50),
ATTRIBUTE17                                        VARCHAR2(50),
ATTRIBUTE18                                        VARCHAR2(50),
ATTRIBUTE19                                        VARCHAR2(50),
ATTRIBUTE20                                        VARCHAR2(50),
RECEIPT_NUM                                        VARCHAR2(70),
ATTRIBUTE21                                        VARCHAR2(50),
ATTRIBUTE22                                        VARCHAR2(50),
AUTH_NUM                                           VARCHAR2(50),
ATTRIBUTE23                                        VARCHAR2(50),
ATTRIBUTE24                                        VARCHAR2(50),
ATTRIBUTE25                                        VARCHAR2(50),
ATTRIBUTE26                                        VARCHAR2(50),
ATTRIBUTE27                                        VARCHAR2(50),
ATTRIBUTE28                                        VARCHAR2(50),
ATTRIBUTE29                                        VARCHAR2(50),
ATTRIBUTE30                                        VARCHAR2(50),
BANK_REC_ID                                        VARCHAR2(50),
ATTRIBUTE31                                        VARCHAR2(50),
ATTRIBUTE32                                        VARCHAR2(50),
TRX_DATE                                           DATE,
ATTRIBUTE33                                        VARCHAR2(50),
ATTRIBUTE34                                        VARCHAR2(50),
ATTRIBUTE35                                        VARCHAR2(50),
PROCESSOR_ID                                       VARCHAR2(100),
MASTER_NOAUTH_FEE                                  NUMBER,
CHBK_RATE                                          NUMBER,
CHBK_AMT                                           NUMBER,
CHBK_ACTION_CODE                                   VARCHAR2(50),
CHBK_ACTION_DATE                                   VARCHAR2(50),
CHBK_REF_NUM                                       VARCHAR2(50),
RET_REF_NUM                                        VARCHAR2(100),
OTHER_RATE1                                        NUMBER,
OTHER_RATE2                                        NUMBER,
CREATION_DATE                                      DATE,
CREATED_BY                                         NUMBER,
LAST_UPDATE_DATE                                   DATE,
LAST_UPDATED_BY                                    NUMBER,
ATTRIBUTE36                                        VARCHAR2(50),
ATTRIBUTE37                                        VARCHAR2(50),
ATTRIBUTE38                                        VARCHAR2(50),
ATTRIBUTE39                                        VARCHAR2(50),
ATTRIBUTE40                                        VARCHAR2(50),
ATTRIBUTE41                                        VARCHAR2(50),
ATTRIBUTE42                                        VARCHAR2(50),
ATTRIBUTE43                                        VARCHAR2(50),
STATUS                                             VARCHAR2(30),
STATUS_1310                                        VARCHAR2(30),
STATUS_1295                                        VARCHAR2(30),
CHBK_ALPHA_CODE                                    VARCHAR2(60),
CHBK_NUMERIC_CODE                                  NUMBER,
SEQUENCE_ID_996                                    NUMBER,
ORG_ID                                             NUMBER,
IPAY_BATCH_NUM                                     VARCHAR2(50),
AJB_FILE_NAME                                      VARCHAR2(200),
RECON_DATE                                         DATE,
AR_CASH_RECEIPT_ID                                 NUMBER,
RECON_HEADER_ID                                    NUMBER,
TERRITORY_CODE                                     VARCHAR2(2),
CURRENCY                                           VARCHAR2(15)
);

CREATE OR REPLACE TYPE XX_CE_AJB996_LIST_T AS TABLE OF XX_CE_AJB996_TYP;

