REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--|                                                                                             |--
--| Object Name    :                                                                            |--                                                           --|                                                                                             |--
--| Program Name   :                                                                            |--
--|                                                                                             |--
--| Purpose        : Drop sequences/indexes/constraints/table starting WITH XXCS%               |--
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
PROMPT Dropping sequences...............
PROMPT
-- DROP SEQUENCES
drop sequence XXCRM.XXCS_FDBK_RESP_ID_S;
drop sequence XXCRM.XXCS_ACTION_ID_S;
drop sequence XXCRM.XXCS_FDBK_ID_S;
drop sequence XXCRM.XXCS_FDBK_LINE_ID_S;
drop sequence XXCRM.XXCS_FDBK_QSTN_ID_S;
drop sequence XXCRM.XXCS_POTENTIAL_ID_S;
drop sequence XXCRM.XXCS_POTENTIAL_REP_ID_S;
drop sequence XXCRM.XXCS_POTENTIAL_NEW_RANK_S;


PROMPT
PROMPT Dropping  indexes...............
PROMPT
-- DROP indexes
drop index XXCRM.XXCS_POTENTIAL_STG_U2;
drop index XXCRM.XXCS_POTENTIAL_STG_N1;
drop index XXCRM.XXCS_POTENTIAL_NEW_RANK_U2;


PROMPT
PROMPT Dropping constraints...............
PROMPT
-- DROP constraints
ALTER TABLE XXCRM.XXCS_FDBK_RESP DROP CONSTRAINT FDBK_RESP_PK ;
ALTER TABLE XXCRM.XXCS_ACTIONS DROP CONSTRAINT ACTION_ID_PK ;
ALTER TABLE XXCRM.XXCS_FDBK_HDR DROP CONSTRAINT FDBK_HDR_PK ;
ALTER TABLE XXCRM.XXCS_FDBK_LINE_DTL DROP CONSTRAINT FDBK_LINE_ID_PK ;
ALTER TABLE XXCRM.XXCS_FDBK_LINE_DTL_STG DROP CONSTRAINT FDBK_LINE_PK ;
ALTER TABLE XXCRM.XXCS_FDBK_HDR_STG DROP CONSTRAINT FDBK_PK ;
ALTER TABLE XXCRM.XXCS_FDBK_QSTN DROP CONSTRAINT FDBK_QSTN_PK ;
ALTER TABLE XXCRM.XXCS_POTENTIAL_NEW_RANK DROP CONSTRAINT XXCS_POTENTIAL_NEW_RANK_PK ;
ALTER TABLE XXCRM.XXCS_POTENTIAL_STG DROP CONSTRAINT POTENTIAL_STG_PK ;
ALTER TABLE XXCRM.XXCS_POTENTIAL_REP_STG DROP CONSTRAINT POTENTIAL_REP_PK ;


PROMPT
PROMPT Dropping tables...............
PROMPT
-- DROP TABLES
DROP TABLE XXCRM.XXCS_POTENTIAL_REP_STG;
DROP TABLE XXCRM.XXCS_POTENTIAL_STG;
DROP TABLE XXCRM.XXCS_POTENTIAL_NEW_RANK;
DROP TABLE XXCRM.XXCS_ACTIONS;
DROP TABLE XXCRM.XXCS_FDBK_RESP_STG;
DROP TABLE XXCRM.XXCS_FDBK_RESP;
DROP TABLE XXCRM.XXCS_FDBK_QSTN_STG;
DROP TABLE XXCRM.XXCS_FDBK_QSTN;
DROP TABLE XXCRM.XXCS_FDBK_LINE_DTL_STG;
DROP TABLE XXCRM.XXCS_FDBK_LINE_DTL;
DROP TABLE XXCRM.XXCS_FDBK_HDR_STG;
DROP TABLE XXCRM.XXCS_FDBK_HDR;
DROP TABLE XXCRM.XXCS_TOP_CUST_EXSTNG_LEAD_OPP;

WHENEVER SQLERROR CONTINUE;

SET FEEDBACK ON

EXIT;

REM=================================================================================================
REM                                   End Of Script
REM=================================================================================================



