REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Program Name   : XX_Qa_fnd_lobs.grt                                                         |--
--|                                                                                             |--
--| Purpose        : Create Grant Privilegs                                                     |--
--|                  The Objects created are:                                                   |--
--|                                                                                             |--
--|                                                                                             |--
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              21-Jun-2010       Paddy Sanjeevi          Original                         |--
--+=============================================================================================+--

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Creating the Custom Table ......
PROMPT

GRANT SELECT ON xxmer.xx_qa_fnd_lobs to apps,u510093,u499103;

