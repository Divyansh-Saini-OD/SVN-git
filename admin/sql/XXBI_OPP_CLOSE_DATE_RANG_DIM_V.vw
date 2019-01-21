SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XXBI_OPP_CLOSE_DATE_RANG_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_OPP_CLOSE_DATE_RANG_DIM_V.vw                  |
-- | Description :  View to create dimension object for Close Date     |
-- |                filter                                             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       31-Aug-2010 Lokesh Kumar       Initial draft version     |  
-- |                                                                   | 
-- +===================================================================+
AS 
SELECT 
   LOOKUP_CODE   ID,
   MEANING       VALUE,
   TAG,
   TO_NUMBER(SUBSTR(TAG,1,INSTR(TAG,'|',1,1)-1)) LOW_VAL,
   TO_NUMBER(SUBSTR(TAG,INSTR(TAG,'|',1,1)+1)) HIGH_VAL
FROM
   APPS.FND_LOOKUP_VALUES 
WHERE
    LOOKUP_TYPE = 'XXBI_CLOSE_DATE_BUCKETS'
AND NVL(ENABLED_FLAG,'N') = 'Y'
AND SYSDATE BETWEEN NVL(START_DATE_ACTIVE,SYSDATE-1) AND NVL(END_DATE_ACTIVE,SYSDATE+1);

Grant select on apps.XXBI_OPP_CLOSE_DATE_RANG_DIM_V to xxcrm;

/
SHOW ERRORS;
EXIT;