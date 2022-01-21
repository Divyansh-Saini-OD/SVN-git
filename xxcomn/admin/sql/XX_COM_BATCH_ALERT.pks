create or replace
PACKAGE XX_COM_BATCH_ALERT AS

  PROCEDURE send_alert(x_errbuf                   OUT NOCOPY      VARCHAR2
                      ,x_retcode                  OUT NOCOPY      NUMBER
                      ,p_from_time                                VARCHAR2 
                      ,p_batch                                    VARCHAR2
                      ,p_pgm                                      VARCHAR2);

END XX_COM_BATCH_ALERT;
/
