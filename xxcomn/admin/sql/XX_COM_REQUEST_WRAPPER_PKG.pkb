create or replace
PACKAGE BODY XX_COM_REQUEST_WRAPPER_PKG AS

FUNCTION SUBMIT_REQUEST(
  p_esp_job_name  IN  VARCHAR2
) RETURN NUMBER AS
  ls_Errbuf     VARCHAR2(2000) := NULL;
  ls_Retcode    VARCHAR2(10) := 0;
  ret_REQUESTId NUMBER := 0;
BEGIN

  XX_COM_REQUEST_PKG.SUBMIT(Errbuf         => ls_Errbuf
                           ,Retcode        => ls_Retcode
                           ,p_esp_job_name => p_esp_job_name
                           ,p_simulate     => 'ESP');
  IF ls_Retcode = 0 THEN
    ret_REQUESTId := ls_Errbuf;
  END IF;
    
  RETURN ret_REQUESTId;
END SUBMIT_REQUEST;

END XX_COM_REQUEST_WRAPPER_PKG;
/
