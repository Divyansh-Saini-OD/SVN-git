create or replace PACKAGE BODY XX_FIN_VPS_DAYS_LATE
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                          	  |
  -- +============================================================================================+
  -- |  Name:  XX_FIN_VPS_DAYS_LATE                                                     	        |
  -- |                                                                                            |
  -- |  Description:  This package is used by datawarehouse team to get days late.        	      |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         07-AUG-2017  Thejaswini Rajula    Initial version                              |
  -- +============================================================================================+
Function AR_DAYS_LATE ( p_cash_receipt_id IN NUMBER )
   RETURN NUMBER
IS
lv_org_id     NUMBER;
lv_days_date  NUMBER;
BEGIN
--Get Org Id
BEGIN
SELECT organization_id 
    INTO lv_org_id
    FROM hr_operating_units
    WHERE name='OU_US_VPS';
    dbms_output.put_line('Org Id  : ' || lv_org_id);
  EXCEPTION
    WHEN OTHERS THEN 
      NULL;
END;   
--Get Days Late
SELECT SUM(TRUNC(ara.APPLY_DATE) -TRUNC(arp.DUE_DATE)) DAYS_LATE 
  INTO lv_days_date
   FROM ar_cash_receipts_all acr
      ,ar_receivable_applications_all ara
      ,ar_payment_schedules_all arp
      ,ra_customer_trx_all rct
  WHERE 1=1
    AND acr.cash_receipt_id=p_cash_receipt_id
    AND acr.org_id=lv_org_id
    AND acr.cash_receipt_id=ara.cash_receipt_id 
    AND ara.org_id=lv_org_id
    AND ara.applied_customer_trx_id = rct.customer_trx_id
    --AND ara.status='APP'
    AND arp.customer_trx_id= rct.customer_trx_id
    AND rct.org_id=lv_org_id;
RETURN lv_days_date;
dbms_output.put_line('Days Late:' ||lv_days_date);
EXCEPTION 
	WHEN NO_DATA_FOUND THEN 
		lv_days_date:=NULL;
		RETURN lv_days_date;
	WHEN OTHERS THEN
		lv_days_date:=NULL;
		RETURN lv_days_date;	
END;
END XX_FIN_VPS_DAYS_LATE;
/