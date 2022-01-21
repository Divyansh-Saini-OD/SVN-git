SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_AR_PERIOD_STATUS_CHK_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_AR_PERIOD_STATUS_CHK_PKG IS
---+============================================================================================+
---|                              Office Depot - Project Simplify                               |
---|                                   Wipro Technologies                                       |
---+============================================================================================+
---|    Application     : AR                                                                    |
---|                                                                                            |
---|    Name            : XX_AR_PERIOD_STATUS_CHK_PKG.pks                                       |
---|                                                                                            |
---|    Description     : Current,Prior,Next Period Status Extract                              |
---|                                                                                            |
---|                                                                                            |
---|                                                                                            |
---|    Change Record                                                                           |
---|    ---------------------------------                                                       |
---|    Version         DATE              AUTHOR             DESCRIPTION                        |
---|    ------------    ----------------- ---------------    ---------------------              |
---|    1.0             30-APR-2009       RamyaPriya M       Initial Version - Defect# 14073    |
---|                                                                                            |
---|    1.1             20-DEC-2013       Veronica M         E2039: Modified for Defect#27324   |
---|                                                                                            |
---+============================================================================================+

   FUNCTION  XX_CLOSING_STATUS (p_application_id IN NUMBER
                               ,p_closing_status IN VARCHAR2) RETURN VARCHAR2;
   PROCEDURE MAIN (x_errbuf                   OUT NOCOPY      VARCHAR2
                  ,x_retcode                  OUT NOCOPY      NUMBER
                  ,p_run_date                 IN              VARCHAR2
                  );
				  
    --Added for Defect# 27324 by Veronica
   FUNCTION XX_PA_PERIOD_NAME (p_period_type IN VARCHAR2,
                               p_date        IN DATE     ) RETURN VARCHAR2;   
							   
  END XX_AR_PERIOD_STATUS_CHK_PKG;
/
SHO ERR