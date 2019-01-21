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
-- | Name        :  XXBI_SALES_CHANNEL_DIM_V.vw                        |
-- | Description :  View for Lead and Opportunity Sales Channels       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author             Remarks                  |
-- |=======   ===========  =================  =========================|
-- |1         06-Mar-2008  Sreekanth Rao        Initial draft version  |
-- +===================================================================+



PROMPT
PROMPT Creating View XXBI_SALES_CHANNEL_DIM_V
PROMPT   

CREATE OR REPLACE VIEW XXBI_SALES_CHANNEL_DIM_V AS
SELECT 
     lookup_code ID,
     meaning     VALUE
FROM 
    FND_LOOKUP_VALUES FLV,
    FND_APPLICATION   FNDA
WHERE 
    FLV.lookup_type = 'SALES_CHANNEL'
AND FNDA.application_id = FLV.view_application_id    
AND FNDA.application_short_name = 'ONT'
AND FLV.language = userenv('LANG')
AND nvl(FLV.enabled_flag,'N') = 'Y'
AND trunc(sysdate) between nvl(start_date_active,sysdate-1) and nvl(end_date_active,sysdate+1)
UNION ALL
   SELECT
      'XX'        id,
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
