SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XXBI_OPPTY_AMT_RANGES_DIM_V AS
SELECT 
   LOOKUP_CODE   ID,
   MEANING       VALUE,
   TAG,
   TO_NUMBER(SUBSTR(TAG,1,INSTR(TAG,'-',1,1)-1)) LOW_VAL,
   TO_NUMBER(SUBSTR(TAG,INSTR(TAG,'-',1,1)+1)) HIGH_VAL
FROM
   APPS.FND_LOOKUP_VALUES 
WHERE
    LOOKUP_TYPE = 'XXBI_LEAD_OPPTY_AMT_BUCKETS'
AND NVL(ENABLED_FLAG,'N') = 'Y'
AND SYSDATE BETWEEN NVL(START_DATE_ACTIVE,SYSDATE-1) AND NVL(END_DATE_ACTIVE,SYSDATE+1);


SHOW ERRORS;
EXIT;