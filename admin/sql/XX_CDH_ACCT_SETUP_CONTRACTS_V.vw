SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name             : XX_CDH_ACCT_SETUP_CONTRACTS_V.vw               |
-- | Rice ID          : E0806_SalesCustomerAccountCreation             |
-- | Description      : This scipt creates view                        |
-- |                    XX_CDH_ACCT_SETUP_CONTRACTS_V                  |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1   14-SEP-2007 Rizwan A         Initial Version             |
-- |1.1       12-Mar-2008 Rizwan A         Modified to pass party id   |
-- |                                       instead of Party Number.    |
-- |1.2       26-Apr-2010 Sreedhar         Modified to take contracts  |
-- |                                       from new table              |
-- |                                                                   |
-- +===================================================================+

-- ---------------------------------------------------------------------
--      Create view XX_CDH_ACCT_SETUP_CONTRACTS_V    --
-- ---------------------------------------------------------------------

CREATE OR REPLACE VIEW "APPS"."XX_CDH_ACCT_SETUP_CONTRACTS_V" ("PARTY_NUMBER", "REQUEST_ID", "SETUP_CONTRACT_ID", "CONTRACT_NUMBER", "CONTRACT_DESCRIPTION", "PRIORITY", "CUSTOM", "STATUS", "STATUS_TRANSITION_DATE") AS 
SELECT
HZP.PARTY_ID,
XCASR.REQUEST_ID,
XCASC.SETUP_CONTRACT_TEMPLATE_ID,
XCASC.CONTRACT_NUMBER,
XCASC.CONTRACT_DESCRIPTION,
XCASC.PRIORITY,
XCASC.CUSTOM,
XCASR.STATUS,
XCASR.STATUS_TRANSITION_DATE
FROM
XX_CDH_ACCT_TEMPLATE_CONTRACTS XCASC,
XX_CDH_ACCOUNT_SETUP_REQ XCASR,
HZ_PARTY_SITES HZPS,
HZ_PARTIES HZP
WHERE XCASC.ACCOUNT_REQUEST_ID = XCASR.REQUEST_ID
AND XCASR.BILL_TO_SITE_ID = HZPS.PARTY_SITE_ID
AND HZPS.PARTY_ID = HZP.PARTY_ID
AND XCASC.SETUP_CONTRACT_TEMPLATE_ID IS NOT NULL;

SHOW ERROR;