SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF


PROMPT
PROMPT Providing Grant on Custom Table and Sequence to Apps......
PROMPT

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Providing Grant on the Table XX_CS_SR_EXCEPTIONS to Apps .....
PROMPT


GRANT ALL ON  XX_CS_SR_EXCEPTIONS TO APPS;


PROMPT
PROMPT Providing Grant on the Sequence XXX_CS_SR_EXCEPTIONS_S to Apps .....
PROMPT


GRANT ALL ON  XX_CS_SR_EXCEPTIONS_S TO APPS;


WHENEVER SQLERROR CONTINUE;


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;