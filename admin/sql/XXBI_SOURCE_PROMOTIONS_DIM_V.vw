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
-- | Name        :  XXBI_SOURCE_PROMOTIONS_DIM_V.vw                    |
-- | Description :  View for Lead Opportunity Sources                  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author             Remarks                  |
-- |=======   ===========  =================  =========================|
-- |1         06-Mar-2008  Sreekanth Rao        Initial draft version  |
-- +===================================================================+



PROMPT
PROMPT Creating View XXBI_SOURCE_PROMOTIONS_DIM_V
PROMPT   

CREATE OR REPLACE VIEW XXBI_SOURCE_PROMOTIONS_DIM_V AS
   SELECT 
      SOC.source_code_id  id,
      CAMPT.campaign_name value
   FROM 
     AMS_SOURCE_CODES     SOC,
     AMS_CAMPAIGNS_ALL_TL CAMPT,
     AMS_CAMPAIGNS_ALL_B  CAMPB
   WHERE 
       SOC.arc_source_code_for = 'CAMP'
   AND SOC.active_flag = 'Y'
   AND SOC.source_code_for_id = campb.campaign_id
   AND CAMPB.campaign_id = campt.campaign_id
   AND CAMPB.status_code IN('ACTIVE',    'COMPLETED')
   AND CAMPT.LANGUAGE = userenv('LANG')
   UNION ALL
   SELECT 
     SOC.source_code_id      ID,
     eveht.event_header_name VALUE
   FROM 
     AMS_SOURCE_CODES         SOC,
     AMS_EVENT_HEADERS_ALL_B  EVEHB,
     AMS_EVENT_HEADERS_ALL_TL EVEHT
   WHERE 
       SOC.arc_source_code_for = 'EVEH'
   AND SOC.active_flag = 'Y'
   AND SOC.source_code_for_id = evehb.event_header_id
   AND EVEHB.event_header_id = eveht.event_header_id
   AND EVEHB.system_status_code IN('ACTIVE',    'COMPLETED')
   AND EVEHT.LANGUAGE = userenv('LANG')
   UNION ALL
   SELECT 
     SOC.source_code_id      ID,
     eveot.event_offer_name  VALUE
   FROM 
     AMS_SOURCE_CODES          SOC,
     AMS_EVENT_OFFERS_ALL_B   EVEOB,
     AMS_EVENT_OFFERS_ALL_TL  EVEOT
   WHERE 
       SOC.arc_source_code_for IN('EVEO',    'EONE')
   AND SOC.active_flag = 'Y'
   AND SOC.source_code_for_id = eveob.event_offer_id
   AND EVEOB.event_offer_id = eveot.event_offer_id
   AND EVEOB.system_status_code IN('ACTIVE',    'COMPLETED')
   AND EVEOT.LANGUAGE = userenv('LANG')
   UNION ALL
   SELECT 
     SOC.source_code_id   id,
     CHLST.schedule_name  value
   FROM 
     AMS_SOURCE_CODES          SOC,
     AMS_CAMPAIGN_SCHEDULES_TL CHLST,
     AMS_CAMPAIGN_SCHEDULES_B  CHLSB
   WHERE 
       SOC.arc_source_code_for = 'CSCH'
   AND SOC.active_flag = 'Y'
   AND SOC.source_code_for_id = CHLSB.schedule_id
   AND CHLSB.schedule_id = CHLST.schedule_id
   AND CHLSB.status_code IN('ACTIVE',    'COMPLETED')
   AND CHLST.LANGUAGE = userenv('LANG')
   UNION ALL
   SELECT 
     -1     id,
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
