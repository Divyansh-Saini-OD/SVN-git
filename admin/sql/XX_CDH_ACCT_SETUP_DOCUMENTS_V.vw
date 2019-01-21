SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name             : XX_CDH_ACCT_SETUP_DOCUMENTS_V.vw               |
-- | Rice ID          : E0806_SalesCustomerAccountCreation             |
-- | Description      : This scipt creates view                        |
-- |                    XX_CDH_ACCT_SETUP_DOCUMENTS_V                  |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1   14-SEP-2007 Rizwan A         Initial Version             |
-- |1.0       10-DEC-2007 Rizwan A         Removed reference to Doc    |
-- |                                       property table.             |
-- |1.1       12-MAR-2007 Rizwan A         Modified code to replace    |
-- |                                       party id in place of party  |
-- |                                       number.                     |
-- +===================================================================+

-- ---------------------------------------------------------------------
--      Create view XX_CDH_ACCT_SETUP_DOCUMENTS_V                     --
-- ---------------------------------------------------------------------

CREATE OR REPLACE VIEW "APPS"."XX_CDH_ACCT_SETUP_DOCUMENTS_V" ("PARTY_NUMBER", "REQUEST_ID", "DOCUMENT_ID", "DOCUMENT_TYPE", "DOCUMENT_NAME", "FREQUENCY", "DETAIL", "INDIRECT", "INCL_BACKUP_INV", "STATUS", "STATUS_TRANSITION_DATE") AS 
SELECT
HZP.PARTY_ID,
XCASR.REQUEST_ID,
XCASD.DOCUMENT_ID,
XCASD.DOCUMENT_TYPE,
XCASD.DOCUMENT_NAME,
XCASD.FREQUENCY,
XCASD.DETAIL,
XCASD.INDIRECT,
XCASD.INCL_BACKUP_INV,
XCASR.STATUS,
XCASR.STATUS_TRANSITION_DATE
FROM
XX_CDH_ACCT_SETUP_DOCUMENTS XCASD,
XX_CDH_ACCOUNT_SETUP_REQ XCASR,
HZ_PARTY_SITES HZPS,
HZ_PARTIES HZP
WHERE XCASD.ACCOUNT_REQUEST_ID = XCASR.REQUEST_ID
AND XCASR.BILL_TO_SITE_ID = HZPS.PARTY_SITE_ID
AND HZPS.PARTY_ID = HZP.PARTY_ID
;

SHOW ERROR;