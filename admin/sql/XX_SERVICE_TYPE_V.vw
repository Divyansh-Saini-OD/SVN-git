-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_SERVICE_TYPE_V.sql                                            |
-- | Description      : SQL Script to replace view XX_SERVICE_TYPE_V                     |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   29-Jun-2012       Adithya          Initial draft version                      |
---|      1B   11-FEB-2016       Vasu Raparla     Removed Schema References for R.12.2       | 
-- +=========================================================================================+
SET VERIFY OFF
SET TERM ON
SET FEEDBACK OFF
SET SHOW OFF
SET ECHO OFF
SET TAB OFF
WHENEVER SQLERROR CONTINUE
-- ************************************************
-- Replacing view XX_SERVICE_TYPE_V
-- ************************************************
WHENEVER SQLERROR CONTINUE
SET TERM ON
PROMPT
PROMPT Replacing view XX_SERVICE_TYPE_V
PROMPT
SET TERM OFF
CREATE OR REPLACE FORCE VIEW "XX_SERVICE_TYPE_V" ("SERVICE_TYPE")
AS
  SELECT SEGMENT_VALUE_LOOKUP service_type -- ,SEGMENT_VALUE
  FROM PA_SEGMENT_VALUE_LOOKUPS
  WHERE EXISTS
    (SELECT 1
    FROM PA_SEGMENT_VALUE_LOOKUP_SETS S
    WHERE PA_SEGMENT_VALUE_LOOKUPS.SEGMENT_VALUE_LOOKUP_SET_ID = S.SEGMENT_VALUE_LOOKUP_SET_ID
    AND upper(segment_value_lookup_set_name)                   = upper('SERVICE TYPE TO CIP ACCOUNT')
    )
  UNION ALL
  SELECT DISTINCT SEGMENT_VALUE service_type -- ,SEGMENT_VALUE
  FROM PA_SEGMENT_VALUE_LOOKUPS
  WHERE EXISTS
    (SELECT 1
    FROM PA_SEGMENT_VALUE_LOOKUP_SETS S
    WHERE PA_SEGMENT_VALUE_LOOKUPS.SEGMENT_VALUE_LOOKUP_SET_ID = S.SEGMENT_VALUE_LOOKUP_SET_ID
    AND upper(segment_value_lookup_set_name)                   = upper('SERVICE TYPE TO CIP ACCOUNT')
    )
  UNION ALL
  SELECT 'ALL' service_type FROM DUAL;
  SHOW ERRORS
  EXIT;
  -- ************************************
  -- *          END OF SCRIPT           *
  -- ************************************