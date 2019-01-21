Rem    -- +=======================================================================+
Rem    -- |               Office Depot - Project Simplify                         |
Rem    -- +=======================================================================+
Rem    -- | Name             : XXTMPURGEPREPROCTAB.tbl                            |
Rem    -- | Description      : Refresh Autonamed Preprocessor table.              |
Rem    -- |                                                                       |
rem    -- |                                                                       |
Rem    -- |Change History:                                                        |
Rem    -- |---------------                                                        |
Rem    -- |                                                                       |
Rem    -- |Change Record:                                                         |
Rem    -- |===============                                                        |
Rem    -- |Version   Date         Author             Remarks                      |
Rem    -- |=======   ===========  =================  =============================|
Rem    -- |Draft 1a  11-Jun-2008  Nabarun            Initial Draft Version        |
Rem    -- +=======================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT
PROMPT Start of script XXTMPURGEPREPROCTAB.sql
PROMPT

PROMPT
PROMPT TRUNCATE TABLE xxcrm.xx_tm_nmdactasgn_preprocessor
PROMPT

TRUNCATE TABLE xxcrm.xx_tm_nmdactasgn_preprocessor;

SHOW ERROR

PROMPT
PROMPT END of script XXTMPURGEPREPROCTAB.sql
PROMPT


