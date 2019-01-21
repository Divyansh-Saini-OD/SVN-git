
REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : ESP Scheduled Programs                                                     |--
--|                                                                                             |--
--| Program Name   : VS_ESP_Scheduled_Programs.sql                                              |--
--|                                                                                             |--
--| Purpose        : Verify the status of programs running through ESP                          |--
--|                                                                                             |-- 
--| Change History :                                                                            |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              16-May-2008      Piyush Khandelwal       Original                          |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Validation Script for ESP Scheduled Programs....
PROMPT


SELECT FCP.user_concurrent_program_name Program_Name,
       FCR.Request_id,
       to_char(FCR.actual_start_date,'MMDDYY HH24:MI:SS')Start_Time,
       to_char(FCR.Actual_completion_date,'MMDDYY HH24:MI:SS')Completion_Time,
       FCR.completion_text,
       FCR.status_code,
       FCR.Logfile_name,
       FCR.Outfile_name,
       FU.user_name
FROM fnd_concurrent_requests FCR,
     fnd_concurrent_programs_tl FCP,
     fnd_user FU
     
WHERE trunc(FCR.actual_start_date) between trunc(sysdate-1) and trunc(sysdate)
AND FCR.CONCURRENT_PROGRAM_ID = FCP.concurrent_program_id
AND FU.user_id = FCR.requested_by
AND FU.user_name = 'SVC_ESP_CRM';

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
