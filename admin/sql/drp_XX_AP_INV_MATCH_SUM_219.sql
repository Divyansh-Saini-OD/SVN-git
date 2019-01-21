SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                              |
-- +==================================================================================+
-- | SQL Script to create the table:  XX_AP_INV_MATCH_SUM_219                |
-- |                                                                                  |
-- |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       01-JUN-2018    Priyam Parmar       Initial DRAFT version                      |
-- |                                                                                  |
-- +==================================================================================+

 


--+=====================================================================+
--+      DROP  TABLE        XX_AP_INV_MATCH_SUM_219                +
--+=====================================================================+


DROP TABLE XXFIN.XX_AP_INV_MATCH_SUM_219;

show error