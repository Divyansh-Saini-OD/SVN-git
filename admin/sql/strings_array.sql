SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +==================================================================================+  
-- |                      Office Depot - Project Simplify                                                  |
-- |                                                                                                       |
-- +==================================================================================+
-- | SQL Script to create the following objects                               |
-- |             Table       : strings_array                                  |
-- |             Schema      :                                                |
-- |                                                                          |
-- |Create Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | 1.0     17-JUN-18	   Ragni Gupta          strings_array                 | 
-- |                                                                          |
-- +==========================================================================+


create or replace type strings_array is varray(50) of VARCHAR2(100); 


   /
Show error
	