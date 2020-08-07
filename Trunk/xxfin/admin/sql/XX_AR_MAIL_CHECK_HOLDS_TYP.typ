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
-- |  Name:  XX_AR_MAIL_CHECK_HOLDS_TYP.sql                                                     |
-- |  Description:  New Object Type                                                             |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         03-NOV-2012  Paddy Sanjeevi   Initial version                                  |
-- +============================================================================================+
CREATE OR REPLACE TYPE XX_AR_MAIL_CHECK_HOLDS_TYP IS OBJECT
(
REF_MAILCHECK_ID                                   NUMBER,
POS_TRANSACTION_NUMBER                             VARCHAR2(50),
AOPS_ORDER_NUMBER                                  VARCHAR2(50),
CHECK_AMOUNT                                       NUMBER,
CUSTOMER_ID                                        NUMBER,
STORE_CUSTOMER_NAME                                VARCHAR2(200),
ADDRESS_LINE_1                                     VARCHAR2(200),
ADDRESS_LINE_2                                     VARCHAR2(200),
ADDRESS_LINE_3                                     VARCHAR2(200),
ADDRESS_LINE_4                                     VARCHAR2(200),
CITY                                               VARCHAR2(100),
STATE_PROVINCE                                     VARCHAR2(100),
POSTAL_CODE                                        VARCHAR2(30),
COUNTRY                                            VARCHAR2(30),
PHONE_NUMBER                                       VARCHAR2(30),
PHONE_EXTENSION                                    VARCHAR2(20),
HOLD_STATUS                                        VARCHAR2(10),
DELETE_STATUS                                      VARCHAR2(10),
CREATION_DATE                                      DATE,
CREATED_BY                                         NUMBER,
LAST_UPDATE_DATE                                   DATE,
LAST_UPDATE_BY                                     NUMBER,
LAST_UPDATE_LOGIN                                  NUMBER,
PROGRAM_APPLICATION_ID                             NUMBER,
PROGRAM_ID                                         NUMBER,
PROGRAM_UPDATE_DATE                                DATE,
REQUEST_ID                                         NUMBER,
PROCESS_CODE                                       VARCHAR2(10),
AP_VENDOR_ID                                       NUMBER,
AP_INVOICE_ID                                      NUMBER,
AR_CASH_RECEIPT_ID                                 NUMBER,
AR_CUSTOMER_TRX_ID                                 NUMBER
);
/


CREATE OR REPLACE TYPE XX_AR_MAIL_CHECK_HOLDS_LIST_T IS TABLE OF XX_AR_MAIL_CHECK_HOLDS_TYP;
/

