SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_AR_CONS

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_AR_CONS IS
   PROCEDURE MAIN (x_errbuf                   OUT NOCOPY      VARCHAR2
                  ,x_retcode                  OUT NOCOPY      NUMBER
                  ,p_REQUEST_id             IN              VARCHAR2
                  );
   
   END XX_AR_CONS;
/
SHO ERR