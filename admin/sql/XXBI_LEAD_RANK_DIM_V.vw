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
-- | Name        :  XXBI_LEAD_RANK_DIM_V.vw                            |
-- | Description :  View for Lead Ranks                                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author             Remarks                  |
-- |=======   ===========  =================  =========================|
-- |1         09-Mar-2008  Sreekanth Rao        Initial draft version  |
-- +===================================================================+



PROMPT
PROMPT Creating View XXBI_LEAD_RANK_DIM_V
PROMPT   

CREATE OR REPLACE VIEW XXBI_LEAD_RANK_DIM_V AS
SELECT 
  LRB.rank_id id,
  LRT.meaning value
FROM 
  AS_SALES_LEAD_RANKS_B  LRB,
  AS_SALES_LEAD_RANKS_TL LRT
WHERE 
     LRB.rank_id = LRT.rank_id
 AND LRB.enabled_flag = 'Y'
 AND LRT.LANGUAGE = userenv('LANG')
UNION ALL
   SELECT
       -1          id,
      'Not Available' value
   FROM
      DUAL
/

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
