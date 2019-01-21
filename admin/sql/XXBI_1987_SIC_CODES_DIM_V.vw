SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR  REPLACE VIEW  XXBI_1987_SIC_CODES_DIM_V AS
SELECT DISTINCT '1987 SIC: ' || LOOKUP_CODE ID, MEANING VALUE FROM FND_LOOKUP_VALUES 
WHERE LOOKUP_TYPE = '1987 SIC' AND ENABLED_FLAG = 'Y';


SHOW ERRORS;
EXIT;