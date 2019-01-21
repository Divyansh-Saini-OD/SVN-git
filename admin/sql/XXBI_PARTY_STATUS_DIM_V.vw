SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR  REPLACE VIEW XXBI_PARTY_STATUS_DIM_V AS
SELECT LOOKUP_CODE AS ID, MEANING AS VALUE FROM FND_LOOKUP_VALUES WHERE LOOKUP_TYPE = 'ACTIVE_INACTIVE'
AND LOOKUP_CODE IN ('A','I') AND ENABLED_FLAG = 'Y';

SHOW ERRORS;
EXIT;