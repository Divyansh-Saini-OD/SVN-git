REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--|                                                                                             |--
--| Object Name    :                                                                            |--                                                           --|                                                                                             |--
--| Program Name   :                                                                            |--
--|                                                                                             |--
--| Purpose        : Drop synonyms starting WITH XXCS% in APPS schema.                          |--
--|                                                                                             |--
--|                                                                                             |--
--| Change History :                                                                            |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              30-Mar-2009       Kalyan                  Original                         |--
--+=============================================================================================+--

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Dropping synonyms...............
PROMPT



drop synonym APPS.XXCS_POTENTIAL_ID_S;
drop synonym APPS.XXCS_POTENTIAL_STG;
drop synonym APPS.XXCS_POTENTIAL_REP_STG;
drop synonym APPS.XXCS_POTENTIAL_REP_ID_S;
drop synonym APPS.XXCS_POTENTIAL_NEW_RANK_S;
drop synonym APPS.XXCS_POTENTIAL_NEW_RANK;
drop synonym APPS.XXCS_ACTION_ID_S;
drop synonym APPS.XXCS_ACTIONS;
drop synonym APPS.XXCS_FDBK_HDR;
drop synonym APPS.XXCS_FDBK_HDR_STG;
drop synonym APPS.XXCS_FDBK_ID_S;
drop synonym APPS.XXCS_FDBK_LINE_DTL;
drop synonym APPS.XXCS_FDBK_LINE_DTL_STG;
drop synonym APPS.XXCS_FDBK_QSTN;
drop synonym APPS.XXCS_FDBK_QSTN_ID_S;
drop synonym APPS.XXCS_FDBK_QSTN_STG;
drop synonym APPS.XXCS_FDBK_RESP;
drop synonym APPS.XXCS_FDBK_RESP_ID_S;
drop synonym APPS.XXCS_FDBK_RESP_STG;
drop synonym APPS.XXCS_POTENTIAL_ID_S;
drop synonym APPS.XXCS_TOP_CUST_EXSTNG_LEAD_OPP;

WHENEVER SQLERROR CONTINUE;

SET FEEDBACK ON

EXIT;

REM=================================================================================================
REM                                   End Of Script
REM=================================================================================================
