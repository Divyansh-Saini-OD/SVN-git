-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_OPPTY_CLOSE_REASON_DIM_V.vw                   |
-- | Description :  View for Opportunity Close Reasons                 |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author             Remarks                  |
-- |=======   ===========  =================  =========================|
-- |1         09-Mar-2008  Sreekanth Rao        Initial draft version  |
-- +===================================================================+



PROMPT
PROMPT Creating View XXBI_OPPTY_CLOSE_REASON_DIM_V
PROMPT   

CREATE OR REPLACE VIEW XXBI_OPPTY_CLOSE_REASON_DIM_V AS
  SELECT 
       lookup_code id,
       meaning     value
   FROM 
       fnd_lookup_values
   WHERE 
       TRUNC(nvl(start_date_active,sysdate)) <= TRUNC(sysdate)
   AND TRUNC(nvl(end_date_active,sysdate)) >= TRUNC(sysdate)
   AND enabled_flag = 'Y'
   AND lookup_type = 'ASN_OPPTY_CLOSE_REASON'
   AND language = userenv('LANG')   
UNION ALL
   SELECT
      'XX' id,
      'Not Available' value
   FROM
      DUAL;
/

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
