REM================================================================================================
REM                                 Start Of Script
REM================================================================================================
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name        :XX_INV_ITEM_PURGE_CS.sql                                 |
-- | Description : Rebuild index script for CS_incidents_all_b             |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      02-Oct-2012 Paddy Sanjeevi     Initial  Version               |
-- +=======================================================================+

PROMPT
PROMPT Rebuilding Index....
PROMPT

alter index CS.CS_INCIDENTS_U1 rebuild;
alter index CS.CS_INCIDENTS_U2 rebuild;
alter index CS.CS_INCIDENTS_U3 rebuild;
alter index CS.CS_INCIDENTS_N1 rebuild;
alter index CS.CS_INCIDENTS_N2 rebuild;
alter index CS.CS_INCIDENTS_N3 rebuild;
alter index CS.CS_INCIDENTS_N4 rebuild;
alter index CS.CS_INCIDENTS_N5 rebuild;
alter index CS.CS_INCIDENTS_N6 rebuild;
alter index CS.CS_INCIDENTS_N7 rebuild;
alter index CS.CS_INCIDENTS_N8 rebuild;
alter index CS.CS_INCIDENTS_N9 rebuild;
alter index CS.CS_INCIDENTS_N12 rebuild;
alter index CS.CS_INCIDENTS_N13 rebuild;
alter index CS.CS_INCIDENTS_N14 rebuild;
alter index CS.CS_INCIDENTS_N15 rebuild;
alter index CS.CS_INCIDENTS_N16 rebuild;
alter index CS.CS_INCIDENTS_N17 rebuild;
alter index CS.CS_INCIDENTS_N18 rebuild;
alter index CS.CS_INCIDENTS_N19 rebuild;
alter index CS.CS_INCIDENTS_N20 rebuild;
alter index CS.CS_INCIDENTS_N21 rebuild;


SHOW ERRORS;


REM================================================================================================
REM                                 Start Of Script
REM================================================================================================