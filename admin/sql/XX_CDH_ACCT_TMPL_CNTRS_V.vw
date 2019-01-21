SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name             : XX_CDH_ACCT_TMPL_CNTRS_V.vw                    |
-- | Rice ID          : E0806_SalesCustomerAccountCreation             |
-- | Description      : This scipt creates view                        |
-- |                    XX_CDH_ACCT_TMPL_CNTRS_V                       |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1   26-APR-2006 Sreedhar         Initial Version             |
-- +===================================================================+

-- ---------------------------------------------------------------------
--      Create view XX_CDH_ACCT_TMPL_CNTRS_V    --
-- ---------------------------------------------------------------------

CREATE OR REPLACE VIEW "APPS"."XX_CDH_ACCT_TMPL_CNTRS_V" ("PARTY_NUMBER", "REQUEST_ID", "SETUP_CONTRACT_ID", "CONTRACT_NUMBER", "CONTRACT_DESCRIPTION", "PRIORITY", "CUSTOM", "STATUS", "STATUS_TRANSITION_DATE") AS 
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
AND HZPS.PARTY_ID = HZP.PARTY_ID;

SHOW ERROR;