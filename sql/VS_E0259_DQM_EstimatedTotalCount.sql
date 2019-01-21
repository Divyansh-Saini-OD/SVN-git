REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : E0259_DQM_EstimatedTotalCount                                              |--
--|                                                                                             |--
--| Program Name   : XX_CDH_ADDTNL_ATTRIBUTES_VALIDATE.sql                                      |--        
--|                                                                                             |--   
--| Purpose        : Validating script for the object E0255_CDHAdditionalAttributes             |--
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              12-Apr-2008       Rajeev Kamath           Original                         |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF
SET TIME     ON
SET TIMING   ON

PROMPT
PROMPT Validation Script for E0259_DQM
PROMPT

PROMPT
PROMPT Estimating total count of records to stage....
PROMPT

select * from
(
select /*+ FULL(hz) PARALLEL(hz1, 8) */ '1.Parties:', count(1) from apps.HZ_PARTIES hz1 where party_type <> 'PARTY_RELATIONSHIP'
union
select /*+ FULL(hz) PARALLEL(hz2, 8) */ '2.Site:   ', count(1) from apps.HZ_PARTY_SITES hz2
union
select /*+ FULL(hz) PARALLEL(hz3, 8) */ '3.Contact:', count(1) from apps.HZ_ORG_CONTACTS hz3
union
select /*+ FULL(hz) PARALLEL(hz4, 8) */ '4.Ct. Pts:', count(1) from apps.HZ_CONTACT_POINTS hz4
)
order by 1;


SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
