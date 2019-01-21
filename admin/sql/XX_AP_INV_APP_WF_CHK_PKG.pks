SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_AP_INV_APP_WF_CHK_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_AP_INV_APP_WF_CHK_PKG IS
---+============================================================================================+
---|                              Office Depot - Project Simplify                               |
---|                                   Wipro Technologies                                       |
---+============================================================================================+
---|    Application     : AP                                                                    |
---|                                                                                            |
---|    Name            : XX_AP_INV_APP_WF_CHK_PKG.pks                                          |
---|                                                                                            |
-- |    RICE ID         : E2040                                                                 |
---|                                                                                            |
---|    Description     : This is to hold the AP Taxware Adapter program until the invoice      |
---|                      workflow Approval Program gets completed successfully.                |
---|                      So that the all approved invoices are processed by AP Taxware Adapter |
---|                      Program.                                                              |
---|                                                                                            |
---|                                                                                            |
---|                                                                                            |
---|    Change Record                                                                           |
---|    ---------------------------------                                                       |
---|    Version         DATE              AUTHOR             DESCRIPTION                        |
---|    ------------    ----------------- ---------------    ---------------------              |
---|    1.0             12-MAY-2009       Ganga Devi R       Initial Version - Defect# 15074    |
---|                                                                                            |
---|                                                                                            |
---+============================================================================================+

  PROCEDURE MAIN ( x_errbuf                   OUT NOCOPY      VARCHAR2
                  ,x_retcode                  OUT NOCOPY      NUMBER
                  ,p_polling_frequency        IN              Number
                  ,p_no_of_iterations         IN              Number
                 );

  END XX_AP_INV_APP_WF_CHK_PKG;
/
SHO ERR