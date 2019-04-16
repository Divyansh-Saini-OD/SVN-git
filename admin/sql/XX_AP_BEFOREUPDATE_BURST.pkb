create or replace 
package body XX_AP_BEFOREUPDATE_BURST
as
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


function AFTERREPORT
  return BOOLEAN
is
  LN_REQUEST_ID number;
  P_CONC_REQUEST_ID number;
  L_COUNT      number :=0;
  l_start_date date;
l_end_date date;
 
begin

  l_start_date := FND_DATE.CANONICAL_TO_DATE(p_start_date);
   l_end_date   := FND_DATE.CANONICAL_TO_DATE(p_end_date);

select SUM(ACNT)
into L_COUNT from (
select COUNT(1) ACNT
from AP_CREDIT_CARD_TRXNS_ALL
where TRANSACTION_TYPE = '0402'
and DEBIT_FLAG         in ('D','C')
and PAYMENT_FLAG       ='Y'
and DESCRIPTION        ='LATE PAYMENT CHARGE'
and TRUNC(CREATION_DATE) between (l_start_date) and (l_end_date));

if L_COUNT > 0 then

P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
  FND_FILE.PUT_LINE(FND_FILE.log, 'OD: AP iExp Late Payment Credit Card Before Update Report Program Report Request ID: '||P_CONC_REQUEST_ID);
  
if P_CONC_REQUEST_ID > 0 then

FND_FILE.PUT_LINE(FND_FILE.log, 'Submitting : XML Publisher Report Bursting Program');
      LN_REQUEST_ID := FND_REQUEST.SUBMIT_REQUEST('XDO',  -- Application short name
	                                              'XDOBURSTREP', --- conc program short name
												  null, 
												  null, 
												  false, 
												  'N', 
												  P_CONC_REQUEST_ID, 
												  'Y');
end if;
end if;
  return(true);
EXCEPTION
when OTHERS then
  FND_FILE.PUT_LINE(FND_FILE.log, 'Exception in after_report function '||SQLERRM );

end AFTERREPORT;
end XX_AP_BEFOREUPDATE_BURST;
/