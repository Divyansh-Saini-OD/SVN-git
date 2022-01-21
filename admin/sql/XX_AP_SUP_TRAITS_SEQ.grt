SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +===================================================================+
-- |                        Office Depot                               |
-- |                                                                   |
-- +===================================================================+
-- | Table Name  :  XX_AP_SUP_TRAITS_SEQ.grt                           |
-- | Rice Id     :  I0380                                              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author             Remarks                  |
-- |=======   ===========  =================  =========================|
-- |1.0       08-APR-2018  Sunil Kalal        Grants ALL to APPS Script| 
-- +===================================================================+

WHENEVER SQLERROR CONTINUE;

SET TERM OFF

SET TERM ON

PROMPT
PROMPT Grant XXFIN.XX_AP_SUP_TRAITS_SEQ to APPS
PROMPT   
GRANT ALL ON XXFIN.XX_AP_SUP_TRAITS_SEQ TO APPS
/
            
SET FEEDBACK ON

SHOW ERRORS;
