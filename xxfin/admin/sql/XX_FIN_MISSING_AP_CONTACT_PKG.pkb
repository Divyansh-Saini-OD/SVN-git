SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_FIN_MISSING_AP_CONTACT_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_FIN_MISSING_AP_CONTACT_PKG                                                    |
  -- |                                                                                            |
  -- |  Description:  Package created for Customer sites missing AP contacts Report               |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         09/10/2018   Havish Kasina    Initial version                                  |
  -- +============================================================================================+
  
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  afterReport                                                                      |
  -- |                                                                                            |
  -- |  Description:  Common Report for XML bursting                                              |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  
FUNCTION beforeReport RETURN BOOLEAN
IS
BEGIN
   RETURN TRUE;
END beforeReport;

FUNCTION afterReport RETURN BOOLEAN
IS
  ln_request_id        NUMBER := 0;
BEGIN
  P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
  fnd_file.put_line(fnd_file.log, 'OD: US Customer sites missing AP contacts Report Request ID: '||P_CONC_REQUEST_ID);
  IF P_CONC_REQUEST_ID > 0
  THEN
      fnd_file.put_line(fnd_file.log, 'Submitting : XML Publisher Report Bursting Program');
      ln_request_id := FND_REQUEST.SUBMIT_REQUEST('XDO',         --- Application short name
	                                              'XDOBURSTREP', --- Conc program short name
												  NULL, 
												  NULL, 
												  FALSE, 
												  'N', 
												  P_CONC_REQUEST_ID, 
												  'Y'
												 );
												  
	  IF ln_request_id > 0
      THEN
         COMMIT;
	     fnd_file.put_line(fnd_file.log,'Able to submit the XML Bursting Program to e-mail the output file');
      ELSE
         fnd_file.put_line(fnd_file.log,'Failed to submit the XML Bursting Program to e-mail the file - ' || SQLERRM);
      END IF;
  ELSE
      fnd_file.put_line(fnd_file.log,'Failed to submit the Report Program to generate the output file - ' || SQLERRM);
  END IF;
  RETURN(TRUE);
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Unable to submit burst request ' || SQLERRM);
END afterReport;
END XX_FIN_MISSING_AP_CONTACT_PKG;
/
SHOW ERRORS;