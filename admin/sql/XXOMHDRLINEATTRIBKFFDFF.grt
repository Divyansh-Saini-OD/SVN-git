
 -- +=================================================================================+
 -- |                  Office Depot - Project Simplify                                |
 -- |    Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
 -- +=================================================================================+
 -- | Name  :    XXOMHDRLINEATTRIBKFFDFF.grt                                                  |
 -- | Description: This file  grants the acces to apps for custom tables and          |
 -- |              synonyms required for KFF in DFF set up for OM Headers and lines   |
 -- |              To be executed from XXOM Schema.                                   |
 -- |                                                                                 |
 -- |                                                                                 |
 -- |Change Record:                                                                   |
 -- |===============                                                                  |
 -- |Version   Date          Author              Remarks                              |
 -- |=======   ==========  =============    ==========================================|
 -- |1.0       17-APR-2007   Mohan          Initial draft Version                     |
 -- +=================================================================================+

SET VERIFY    OFF 
SET TERM      OFF 
SET FEEDBACK  OFF 
SET SHOW      OFF 
SET ECHO      OFF 
SET TAB       OFF 


PROMPT
PROMPT Providing Grant on Custom Table to Apps......
PROMPT

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Providing Grant on the Table XX_OM_HEADERS_ATTRIBUTES_ALL to Apps .....
PROMPT

GRANT ALL ON XXOM.XX_OM_HEADERS_ATTRIBUTES_ALL TO APPS WITH GRANT OPTION;
/
PROMPT
PROMPT Providing Grant on the Table XX_OM_HEADERS_ATTRIBUTES_ALL_S to Apps .....
PROMPT

GRANT ALL ON XXOM.XX_OM_HEADERS_ATTRIBUTES_ALL_S TO APPS WITH GRANT OPTION;
/
PROMPT
PROMPT Providing Grant on the Table XX_OM_LINES_ATTRIBUTES_ALL to Apps .....
PROMPT


GRANT ALL ON XXOM.XX_OM_LINES_ATTRIBUTES_ALL TO APPS WITH GRANT OPTION;
/
PROMPT
PROMPT Providing Grant on the Table XX_OM_LINES_ATTRIBUTES_ALL to Apps .....
PROMPT

GRANT ALL ON XXOM.XX_OM_LINES_ATTRIBUTES_ALL_S TO APPS WITH GRANT OPTION;
/
WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

