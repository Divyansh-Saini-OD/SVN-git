Rem    NAME
Rem      xxcrmtlpreload.sql - 
Rem
Rem    DESCRIPTION
Rem      Terralign preload clearing existing data
Rem      I0405_Territories_Terralign_Inbound_Interface
rem  
Rem
Rem    NOTES
Rem      Comments are added for tables, wherever possible.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    Mohan      10/23/2007 - First time creation
Rem    Hema       01/10/2008 - Removed the Alter Table command
Rem
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT
PROMPT Start of script xxcrmtlpreload.sql
PROMPT


PROMPT
PROMPT truncate table xxcrm.xx_jtf_terr_qual_tlign_int
PROMPT

truncate table xxcrm.xx_jtf_terr_qual_tlign_int;


SHOW ERROR

PROMPT
PROMPT END of script xxcrmtlpreload.sql
PROMPT


