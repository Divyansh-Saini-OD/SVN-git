SET SHOW         OFF 
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET TERM ON
PROMPT Creating Package Spec XX_TAXWARE_TEST
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE  PACKAGE XX_TAXWARE_TEST AS

/*******************************************/
PROCEDURE  MAIN_PROGRAM
    (errbuf                         IN OUT NOCOPY VARCHAR2,
     retcode                        IN OUT NOCOPY VARCHAR2,
     p_threads				              IN NUMBER,
     p_batch_size_per_thread        IN NUMBER);


/*******************************************/
PROCEDURE PROCESS_THREAD
   (errbuf												IN OUT NOCOPY VARCHAR2,
    retcode												IN OUT NOCOPY VARCHAR2,
    p_thread											IN NUMBER,
    p_batch_size									IN NUMBER);

END XX_TAXWARE_TEST;
/