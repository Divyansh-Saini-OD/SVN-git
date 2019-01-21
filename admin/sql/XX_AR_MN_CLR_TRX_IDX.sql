SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Index on table  XX_CE_AJB998(ORDER_PAYMENT_ID);

PROMPT Program exits if the creation is not successful

WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

-- =================================================================================
--   NAME:       XX_AR_MN_CLR_TRX_PKG
--   PURPOSE:    This script is used to index on XX_CE_AJB998 table

--   REVISIONS:
--   Ver        Date        Author           Description
--   ---------  ----------  ---------------  ------------------------------------
--   1.0        02/05/2011  Jay Gupta        Initial Version
-- =================================================================================


CREATE INDEX XXFIN.XX_CE_AJB998_N15 ON XXFIN.XX_CE_AJB998(ORDER_PAYMENT_ID);

/
SHOW ERROR;
