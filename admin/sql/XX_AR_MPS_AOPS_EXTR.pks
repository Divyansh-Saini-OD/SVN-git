SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT CREATING PACKAGE SPECIFICATION XX_AR_MPS_AOPS_EXTR
PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL

WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE  XX_AR_MPS_AOPS_EXTR AS
 -- +=======================================================================================+
 -- |  NAME:      XX_AR_MPS_AOPS_EXTR                                                       |
 -- | PURPOSE:    This package contains procedures to extract MPS data and send to AOPS     |
 -- | REVISIONS:                                                                            |
 -- | Ver        Date        Author           Description                                   |
 -- | ---------  ----------  ---------------  ------------------------------------          |
 -- | 1.0        04/23/2013  Ray Strauss      Initial version                               |
 -- ========================================================================================+

   PROCEDURE EXTRACT_MPS ( x_errbuf                       OUT NOCOPY  VARCHAR2
                          ,x_retcode                      OUT NOCOPY  NUMBER
                          );

END XX_AR_MPS_AOPS_EXTR;
/
SHO ERROR
