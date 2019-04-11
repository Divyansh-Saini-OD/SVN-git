create or replace 
PACKAGE BODY XX_AP_ACCINACCC_BURST
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
from wf_notifications wn, 
wf_item_activity_statuses wias ,
wf_item_attribute_values wiav ,
per_all_people_f papf,
per_periods_of_service ppfs,
(SELECT  PERSON_ID ,MAX(PERIOD_OF_SERVICE_ID) Maxperiodos FROM APPS.PER_PERIODS_OF_SERVICE
GROUP BY PERSON_ID) ppfs1,
(SELECT  item_key ,MAX(notification_id) Maxnotificid FROM APPS.wf_notifications
GROUP BY item_key) wn1,
ap_credit_card_trxns_all accta,
ap_cards_all aca
where
wn.notification_id=wn1.Maxnotificid
and wn1.item_key=wn.item_key
AND WN.MESSAGE_TYPE=WIAS.ITEM_TYPE
and wn1.item_key=wias.item_key
and wias.item_key=wiav.item_key
and wias.item_type=wiav.item_type
and papf.employee_number=wiav.text_value
and papf.person_id=aca.employee_id
and accta.card_id=aca.card_id
AND accta.card_program_id=aca.card_program_id
and ppfs.person_id=ppfs1.person_id
and ppfs.period_of_service_id=ppfs1.Maxperiodos
and papf.person_id=ppfs1.person_id
AND WN.MESSAGE_TYPE='APCCARD'
AND WN.STATUS='CLOSED'
AND WIAS.ACTIVITY_STATUS='COMPLETE'
AND WIAS.ACTIVITY_RESULT_CODE='ACCEPT'
AND ACCTA.REPORT_HEADER_ID IS NULL
AND WIAV.NAME='INACT_EMP_NAME'
AND EXISTS
  (SELECT 1
  FROM xx_hr_ps_stg
  WHERE emplid   =papf.employee_number
  AND EMPL_STATUS='T'
  )
  AND NOT EXISTS
  (
select 1 from apps.wf_item_activity_statuses wis1
WHERE
wis1.item_type=wias.item_type
AND
wis1.item_key=wias.item_key
and
ACTIVITY_STATUS='ERROR'
));

IF L_COUNT > 0 THEN

P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
  fnd_file.put_line(fnd_file.log, 'OD: AP iExpense Accepted CC Notifications of Termed Emp Report Request ID: '||P_CONC_REQUEST_ID);
  
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
END XX_AP_ACCINACCC_BURST;
/