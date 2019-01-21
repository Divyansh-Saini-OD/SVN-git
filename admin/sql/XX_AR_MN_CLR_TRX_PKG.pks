SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Specification XX_AR_MN_CLR_TRX_PKG

PROMPT Program exits if the creation is not successful

WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_AR_MN_CLR_TRX_PKG AS
-- =================================================================================
--   NAME:       XX_AR_MN_CLR_TRX_PKG
--   PURPOSE:    This package is used to clear the transaction

--   REVISIONS:
--   Ver        Date        Author           Description
--   ---------  ----------  ---------------  ------------------------------------
--   1.0        29/04/2011  Jay Gupta        Initial Version
-- =================================================================================
   TYPE tbl_rcpt_det IS TABLE OF NUMBER index by binary_integer;
   PROCEDURE update_receipts(p_gt_rcpt_det tbl_rcpt_det,p_status OUT VARCHAR2);
   PROCEDURE update_interface(p_bank_rec_id VARCHAR2, p_processor_id VARCHAR2,p_status OUT VARCHAR2);
END XX_AR_MN_CLR_TRX_PKG;
/
SHOW ERROR;
