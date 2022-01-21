create or replace package body      XXOD_UNBILLED_RPT_BURST_PKG
AS
   FUNCTION AfterReport
      RETURN BOOLEAN
   IS
      P_CONC_REQUEST_ID NUMBER;
      l_request_id   NUMBER :=0 ;
   BEGIN
      
      
      P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
      Fnd_File.PUT_LINE (
         Fnd_File.LOG,
         'Submitting : XML Publisher Report Bursting Program.');
      l_request_id :=
         FND_REQUEST.SUBMIT_REQUEST ('XDO',
                                     'XDOBURSTREP',
                                     NULL,
                                     NULL,
                                     FALSE,
                                     'Y',
                                     P_CONC_REQUEST_ID,
                                     'Y');
		COMMIT;							 
	IF l_request_id <> 0 THEN 
		Fnd_File.PUT_LINE (Fnd_File.LOG, 'Request ID of Bursting Program : '||l_request_id);
	ELSE 
		Fnd_File.PUT_LINE (Fnd_File.LOG, 'After Report Trigger is unable to submit Bursting Program.');
	END IF;

      RETURN TRUE;
   EXCEPTION
      WHEN OTHERS
      THEN
         Fnd_File.PUT_LINE (Fnd_File.LOG, 'Unable to submit request of Bursting Program' || SQLERRM);
      RETURN FALSE;
   END AfterReport;
   
END XXOD_UNBILLED_RPT_BURST_PKG;
/