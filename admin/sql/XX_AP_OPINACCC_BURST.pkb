create or replace 
PACKAGE BODY XX_AP_OPINACCC_BURST
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_AP_ACCINACCC_BURST                                                            |
  -- |                                                                                            |
  -- |  Description:  Package created afterReport Trigger                                         |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         04/08/2019   Bhargavi Ankolekar Initial version                                |
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
  
BEGIN

select sum(acnt)
into L_COUNT from (
SELECT count(1) acnt
FROM WF_NOTIFICATIONS WN,
  WF_ITEM_ACTIVITY_STATUSES WIAS ,
  WF_ITEM_ATTRIBUTE_VALUES WIAV ,
  PER_ALL_PEOPLE_F PAPF,
  per_periods_of_service ppfs,
  ap_credit_card_trxns_all accta,
  AP_CARDS_ALL ACA
WHERE wn.item_key        =wias.item_key
AND wias.item_key        =wiav.item_key
AND wias.item_type       =wiav.item_type
AND papf.employee_number =wiav.text_value
AND papf.person_id       =aca.employee_id
AND accta.card_id        =aca.card_id
AND accta.card_program_id=aca.card_program_id
AND papf.person_id       =ppfs.person_id
AND WN.MESSAGE_TYPE      ='APCCARD'
AND WIAS.ACTIVITY_STATUS ='ACTIVE'
AND WIAV.NAME            ='INACT_EMP_NAME'
AND TRUNC (SYSDATE) BETWEEN PAPF.EFFECTIVE_START_DATE AND PAPF.EFFECTIVE_END_DATE
AND WN.MESSAGE_NAME = 'OIE_MSG_MGR_INACTIVE_EMPL_EX_1'
AND WN.STATUS NOT  IN ('CANCELED','CLOSED'));

IF L_COUNT > 0 THEN

P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
  fnd_file.put_line(fnd_file.log, 'OD: AP iExpense Credit Card Open Notifications Of Termed Employee Report Request ID: '||P_CONC_REQUEST_ID);
  
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
END XX_AP_OPINACCC_BURST;
/