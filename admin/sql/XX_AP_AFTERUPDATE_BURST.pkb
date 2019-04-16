create or replace 
PACKAGE BODY XX_AP_AFTERUPDATE_BURST
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_AP_AFTERUPDATE_BURST                                                            |
  -- |                                                                                            |
  -- |  Description:  Package created afterReport Trigger                                         |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         04/12/2019   Bhargavi Ankolekar Initial version                                |
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

FUNCTION afterReport
  RETURN BOOLEAN
IS
  ln_request_id NUMBER;
  P_CONC_REQUEST_ID NUMBER;
  
BEGIN

P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
  fnd_file.put_line(fnd_file.log, 'OD: AP iExp Late Payment Credit Card After Update Report Program Report Request ID: '||P_CONC_REQUEST_ID);
  
If P_CONC_REQUEST_ID > 0 THEN

fnd_file.put_line(fnd_file.log, 'Submitting : XML Publisher Report Bursting Program');
      ln_request_id := FND_REQUEST.SUBMIT_REQUEST('XDO',  -- Application short name
	                                              'XDOBURSTREP', --- conc program short name
												  NULL, 
												  NULL, 
												  FALSE, 
												  'N', 
												  P_CONC_REQUEST_ID, 
												  'Y');
END IF;

  RETURN(TRUE);
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Exception in after_report function '||SQLERRM );

END afterReport;
END XX_AP_AFTERUPDATE_BURST;
/