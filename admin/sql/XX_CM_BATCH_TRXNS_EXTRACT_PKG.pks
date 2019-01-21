SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
SET DEFINE OFF

PROMPT Creating Package XX_CM_BATCH_TRXNS_EXTRACT_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_CM_BATCH_TRXNS_EXTRACT_PKG
AS

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_CM_BATCH_TRXNS_EXTRACT_PKG                               |
-- | RICE ID : R1053                                                     |
-- | Description : This package is to extract the Credit Card settlement |
-- |               transactions as a text file from the batch            |
-- |               transactions history table.                           |
-- |                                                                     |
-- |                                                                     |
-- |                                                                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A 12-JUL-2008      Aravind A.          Initial version        |
-- |                                              (Created as part of fix|
-- |                                              for defect 8403)       |
-- |                                                                     |
-- +=====================================================================+


-- +===================================================================+
-- | Name : XX_GET_BATCH_TRXNS_DETAILS                                 |
-- | Description: Extracts the details from batch transactions history |
-- |              table and writes to a flat file.                     |
-- +===================================================================+

PROCEDURE XX_GET_BATCH_TRXNS_DETAILS(
                                     x_err_buff            OUT VARCHAR2
                                    ,x_ret_code            OUT NUMBER
                                    ,p_payment_bat_num     IN  VARCHAR2
                                    );

END XX_CM_BATCH_TRXNS_EXTRACT_PKG;

/

SHOW ERROR