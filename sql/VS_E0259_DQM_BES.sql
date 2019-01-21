REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : E0259 DQM Events                                                           |--
--|                                                                                             |--
--| Program Name   :                                                                            |--        
--|                                                                                             |--   
--| Purpose        : Validating script for the object E0259 DQM Events                          |--
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0             134-Apr-2007       Rajeev Kamath           First version                    |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Validation Script for E0259 DQM Business Events ...
PROMPT


SELECT 'Business Event [od.oracle.apps.ar.hz.PartySiteExt.update] ' || CASE COUNT(1) WHEN 1 THEN 'exists.'
                                                                                            ELSE 'does not exist.'
                                                                       END
from apps.WF_EVENTS
where name = 'od.oracle.apps.ar.hz.PartySiteExt.update';

SELECT 'Business Event [od.oracle.apps.ar.hz.PartySiteExt.update] subscription for [XX_CDH_DQM_ACQUIRE_PKG.Party_Site_Contact_Change] - ' 
                 || CASE COUNT(1) WHEN 1 THEN 'exists.'
                                         ELSE 'does not exist.'
                    END
from apps.wf_event_subscriptions
where event_filter_guid = (select guid from apps.wf_events where name = 'od.oracle.apps.ar.hz.PartySiteExt.update')
and upper(rule_function) = upper('XX_CDH_DQM_ACQUIRE_PKG.Party_Site_Contact_Change');


SELECT 'Business Event [od.oracle.apps.ar.hz.PartySiteExt.update] for [SITE_CONTACTS] - ' || CASE COUNT(1) WHEN 1 THEN 'exists.'
                                                                                                              ELSE 'does not exist.'
                                                                       END
from apps.EGO_FND_DSC_FLX_CTX_EXT
where business_event_flag = 'Y'
and   DESCRIPTIVE_FLEX_CONTEXT_CODE = 'SITE_CONTACTS'
AND   DESCRIPTIVE_FLEXFIELD_NAME = 'HZ_PARTY_SITES_GROUP';

SELECT 'Business Event [od.oracle.apps.ar.hz.PartySiteExt.update] for [HZ_PARTY_SITES_GROUP] -  ' || CASE COUNT(1) WHEN 1 THEN 'exists.'
                                                                                                                        ELSE 'does not exist.'
                                                                       END
from apps.EGO_FND_DESC_FLEXS_EXT
WHERE APPLICATION_ID = 222
and   business_Event_name = 'od.oracle.apps.ar.hz.PartySiteExt.update'
AND   DESCRIPTIVE_FLEXFIELD_NAME = 'HZ_PARTY_SITES_GROUP';


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
