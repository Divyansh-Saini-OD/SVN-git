create or replace 
PACKAGE BODY XX_AP_BEFOREUPDATE_BURST
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_AP_BEFOREUPDATE_BURST                                                            |
  -- |                                                                                            |
  -- |  Description:  Package created beforeReport Trigger                                         |
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
  L_COUNT      NUMBER :=0;
  L_START_DATE DATE;
L_END_DATE DATE;
 
BEGIN

  l_start_date := fnd_date.canonical_to_date(p_start_date);
   l_end_date   := fnd_date.canonical_to_date(p_end_date);

select sum(acnt)
into L_COUNT from (
SELECT count(1) acnt
FROM AP_CREDIT_CARD_TRXNS_ALL
WHERE TRANSACTION_TYPE = '0402'
AND DEBIT_FLAG         in ('D','C')
AND PAYMENT_FLAG       ='Y'
AND DESCRIPTION        ='LATE PAYMENT CHARGE'
AND TRUNC(CREATION_DATE) BETWEEN (L_START_DATE) AND (L_END_DATE));

IF L_COUNT > 0 THEN

P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
  fnd_file.put_line(fnd_file.log, 'OD: AP iExp Late Payment Credit Card Before Update Report Program Report Request ID: '||P_CONC_REQUEST_ID);
  
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
END IF;
  RETURN(TRUE);
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Exception in after_report function '||SQLERRM );

END afterReport;
END XX_AP_BEFOREUPDATE_BURST;
/