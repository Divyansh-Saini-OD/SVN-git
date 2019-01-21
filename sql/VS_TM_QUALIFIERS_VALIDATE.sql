REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : E0401_TerritoryManager_Qualifiers                                          |--
--|                                                                                             |--
--| Program Name   : XX_TM_QUALIFIERS_VALIDATE.sql                                              |--
--|                                                                                             |--
--| Purpose        : Validating script for the object E0401_TerritoryManager_Qualifiers         |--
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              26-Dec-2007      Nabarun Ghosh           Original                          |--
--| 1.1              13-Mar-2008      Abhradip Ghosh          Updated with the latest files     |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Validation Script for E0401_TerritoryManager_Qualifiers....
PROMPT

PROMPT
PROMPT Validating whether the custom packages are compiled in database....
PROMPT

SELECT 'The package specification XX_JTF_CUSTOM_QUALIFIER_PKG.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_CUSTOM_QUALIFIER_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' ; 

SELECT 'The package body XX_JTF_CUSTOM_QUALIFIER_PKG.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_CUSTOM_QUALIFIER_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 

SELECT 'The package specification XX_JTF_UPDATE_CUST_ACCT_PKG.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_UPDATE_CUST_ACCT_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' ; 

SELECT 'The package body XX_JTF_UPDATE_CUST_ACCT_PKG.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_UPDATE_CUST_ACCT_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 


SELECT 'The package specification XXCRM_JTF_UPD_CUST_ACCOUNT_PKG.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXCRM_JTF_UPD_CUST_ACCOUNT_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' ; 

SELECT 'The package body XXCRM_JTF_UPD_CUST_ACCOUNT_PKG.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXCRM_JTF_UPD_CUST_ACCOUNT_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 

PROMPT
PROMPT
PROMPT Validating whether the required profiles are present....
PROMPT

SELECT 'The profile OD: TM Max Party Id '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                         ELSE 'Does Not Exists'
                                           END
FROM  fnd_profile_options_tl FPO
WHERE FPO.profile_option_name = 'XXCRM_E401_MAX_PARTY_ID';

PROMPT
PROMPT
PROMPT Validating whether the required concurrent programs are present....
PROMPT

SELECT 'The concurrent program OD: TM Custom Transaction Qualifiers '||
                           CASE COUNT(1) WHEN 1 THEN 'Exists'
                                         ELSE 'Does Not Exists'
                           END
FROM  fnd_concurrent_programs_vl FCPV
WHERE FCPV.concurrent_program_name = 'XXJTFCUSTQUAL'
AND   FCPV.enabled_flag            = 'Y';

SELECT 'The concurrent program OD: TM Update Customer/Prospect Flag Master '||
                        CASE COUNT(1) WHEN 1 THEN 'Exists'
                                      ELSE 'Does Not Exists'
                        END
FROM  fnd_concurrent_programs_vl FCPV
WHERE FCPV.concurrent_program_name = 'XXCRMUPDCUSTPROSMST'
AND   FCPV.enabled_flag            = 'Y';

SELECT 'The concurrent program OD: TM Update Customer/Prospect Flag '||
                        CASE COUNT(1) WHEN 1 THEN 'Exists'
                                      ELSE 'Does Not Exists'
                        END
FROM  fnd_concurrent_programs_vl FCPV
WHERE FCPV.concurrent_program_name = 'XXCRMUPDCUSTPROSPECT'
AND   FCPV.enabled_flag            = 'Y';

PROMPT
PROMPT
PROMPT Validating whether the subscriptions created for the BES CustAccount Create / Update....
PROMPT

SELECT 
'Package XX_JTF_UPDATE_CUST_ACCT_PKG.Update_Party_Status '||
                 CASE COUNT(1) WHEN 1 THEN 'subscribed to oracle.apps.ar.hz.CustAccount.create'
                               ELSE 'not subscribed to oracle.apps.ar.hz.CustAccount.create'
                 END
FROM   wf_events_vl           WEV
      ,wf_event_subscriptions WES
WHERE WEV.guid          = WES.event_filter_guid
AND   WEV.name          = 'oracle.apps.ar.hz.CustAccount.create' 
AND   WEV.type          = 'EVENT'
AND   WEV.status        = 'ENABLED'
AND   WES.rule_function = 'XX_JTF_UPDATE_CUST_ACCT_PKG.Update_Party_Status';

SELECT 
'Package XX_JTF_UPDATE_CUST_ACCT_PKG.Update_Party_Status '||
                 CASE COUNT(1) WHEN 1 THEN 'subscribed to oracle.apps.ar.hz.CustAccount.update'
                               ELSE 'not subscribed to oracle.apps.ar.hz.CustAccount.update'
                 END
FROM   wf_events_vl           WEV
      ,wf_event_subscriptions WES
WHERE WEV.guid          = WES.event_filter_guid
AND   WEV.name          = 'oracle.apps.ar.hz.CustAccount.update' 
AND   WEV.type          = 'EVENT'
AND   WEV.status        = 'ENABLED'
AND   WES.rule_function = 'XX_JTF_UPDATE_CUST_ACCT_PKG.Update_Party_Status';

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================

