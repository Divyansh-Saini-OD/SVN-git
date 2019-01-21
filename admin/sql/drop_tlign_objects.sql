Rem    NAME
Rem      drop_tlign_objects - 
Rem
Rem    DESCRIPTION
Rem      Script to drop all the terralign objects
rem  
Rem
Rem    NOTES
Rem      Comments are added for tables, wherever possible.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    Mohan     11/19/2007 - First time creation
Rem

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT
PROMPT DROP TABLE XXCRM.XX_JTF_TERR_QUAL_TLIGN_INT
PROMPT

DROP TABLE XXCRM.XX_JTF_TERR_QUAL_TLIGN_INT;

DROP TABLE XXCRM.XX_JTF_TLIGN_MAP_LOOKUP;

DROP SEQUENCE XXCRM.XX_JTF_GROUP_ID_S;

DROP SEQUENCE XXCRM.XX_JTF_GROUPID_S;

SHOW ERROR

PROMPT
PROMPT END of script drop_tlign_objects

