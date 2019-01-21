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
-- | Name        :  XXBI_LEAD_STATUS_DIM_V.vw                          |
-- | Description :  View for Lead Statuses                             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author             Remarks                  |
-- |=======   ===========  =================  =========================|
-- |1         06-Mar-2008  Sreekanth Rao        Initial draft version  |
-- +===================================================================+



PROMPT
PROMPT Creating View XXBI_LEAD_STATUS_DIM_V
PROMPT   

CREATE OR REPLACE VIEW XXBI_LEAD_STATUS_DIM_V AS
SELECT 
  b.status_code id,
  tl.meaning    value
FROM 
  AS_STATUSES_B  b,
  AS_STATUSES_TL tl
WHERE 
     b.status_code = tl.status_code
 AND b.lead_flag = 'Y'
 AND nvl(b.enabled_flag,'Y') = 'Y'
 AND tl.language = userenv('LANG')
UNION ALL
SELECT 'XX' ID, 'Not Available' VALUE
FROM DUAL
/

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
