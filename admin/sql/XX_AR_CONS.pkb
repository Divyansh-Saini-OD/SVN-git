SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AR_CONS

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_AR_CONS
AS

   PROCEDURE MAIN ( x_errbuf                   OUT NOCOPY      VARCHAR2
                   ,x_retcode                  OUT NOCOPY      NUMBER
                   ,P_REQUEST_ID             IN              VARCHAR2
                   )
                   IS


   BEGIN

      FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
      update apps.ar_payment_schedules_all 
      set cons_inv_id = null
where cons_inv_id in 
(select cons_inv_id 
from apps.ar_cons_inv_all
where attribute14=P_REQUEST_ID);
FND_FILE.PUT_LINE(FND_FILE.LOG,'ar_payment_schedules_all : '||SQL%ROWCOUNT);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
delete apps.ar_cons_inv_trx_lines_all 
where cons_inv_id in 
(select cons_inv_id 
from apps.ar_cons_inv_all
where attribute14=P_REQUEST_ID);
FND_FILE.PUT_LINE(FND_FILE.LOG,'ar_cons_inv_trx_lines_all : '||SQL%ROWCOUNT);

      FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
delete apps.ar_cons_inv_trx_all 
where cons_inv_id in 
(select cons_inv_id from apps.ar_cons_inv_all
where attribute14=P_REQUEST_ID);
FND_FILE.PUT_LINE(FND_FILE.LOG,'ar_cons_inv_trx_all : '||SQL%ROWCOUNT);


      FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
delete apps.ar_cons_inv_all 
where cons_inv_id in 
(select cons_inv_id from apps.ar_cons_inv_all
where attribute14=P_REQUEST_ID);
FND_FILE.PUT_LINE(FND_FILE.LOG,'ar_cons_inv_all : '||SQL%ROWCOUNT);

      FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');

   EXCEPTION

   WHEN OTHERS THEN

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error While : '  );
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Debug : ' || SQLERRM );

   END MAIN;



END XX_AR_CONS;
/
SHOW ERR