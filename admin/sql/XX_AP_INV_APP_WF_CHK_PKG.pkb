CREATE OR REPLACE PACKAGE BODY XX_AP_INV_APP_WF_CHK_PKG
AS
---+==============================================================================================+
---|                              Office Depot - Project Simplify                                 |
---|                                   Wipro Technologies                                         |
---+==============================================================================================+
---|    Application     : AP                                                                      |
---|                                                                                              |
---|    Name            : XX_AP_INV_APP_WF_CHK_PKG.pkb                                            |
---|                                                                                              |
---|    RICE ID         : E2040                                                                   |
---|                                                                                              |
---|    Description     : This is to hold the AP Taxware Adapter program until the invoice        |
---|                      workflow Approval Program gets completed successfully.                  |
---|                      So that the all approved invoices are processed by AP Taxware Adapter   |
---|                      Program.                                                                |
---|                                                                                              |
---|                                                                                              |
---|                                                                                              |
---|    Change Record                                                                             |
---|    ---------------------------------                                                         |
---|    Version         DATE              AUTHOR             DESCRIPTION                          |
---|    ------------    ----------------- ---------------    ---------------------                |
---|    1.0             12-MAY-2009       Ganga Devi R       Initial Version - Defect# 15074      |
---|                                                                                              |
---|                                                                                              |
---|                                                                                              |
---|                                                                                              |
---+==============================================================================================+
   PROCEDURE MAIN ( x_errbuf                   OUT NOCOPY      VARCHAR2
                   ,x_retcode                  OUT NOCOPY      NUMBER
                   ,p_polling_frequency        IN              NUMBER
                   ,p_no_of_iterations         IN              NUMBER
                   )
   IS
   ln_count   NUMBER;
   lc_corrid  VARCHAR2(250):='APPS:oracle.apps.ap.event.invoice.approval';
   ln_wait    NUMBER := p_polling_frequency * 60; -- Converting to Seconds

   BEGIN

         SELECT COUNT(1) 
         INTO   ln_count
         FROM   wf_deferred 
         WHERE  corrid =lc_corrid;

         FND_FILE.PUT_LINE (FND_FILE.LOG,'Initial Number of Records in WF_Deferred Table :'||ln_count);

         IF (ln_count=0) THEN
            x_retcode :=0;
         ELSE

            FOR i IN 1 .. p_no_of_iterations 
            LOOP

               DBMS_LOCK.SLEEP(ln_wait);

               SELECT COUNT(1)
               INTO ln_count
               FROM wf_deferred 
               WHERE corrid = lc_corrid;

            EXIT WHEN ln_count=0;

            END LOOP;

            IF (ln_count=0) THEN
               x_retcode :=0;
            ELSE
               x_retcode :=2;
               FND_FILE.PUT_LINE (FND_FILE.LOG,'Maximum Iterations are complete,so program exits with Error');
            END IF;

         END IF;

   EXCEPTION 
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Code : ' || SQLCODE || ' Error Msg : ' || SQLERRM );
         RAISE;
   END;    
END XX_AP_INV_APP_WF_CHK_PKG;
/
Show Errors