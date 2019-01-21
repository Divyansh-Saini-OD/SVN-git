SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- +================================================================================+
-- | Name :INSERT_XX_AP_CUSTOM_TOLERANCES                                       		|
-- | Description :   SQL Script to insert supplier site custom tolerance related data into     | 
-- | custom table  XX_AP_CUSTOM_TOLERANCES          									|
-- | Rice ID     :  E3523                                                      		|
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author               Remarks                             |
-- |=======   ==========   =============        ====================================|
-- | V1.0     30-Aug-2017  Sridhar G.	    	Initial version                     |
-- +================================================================================+

SET DEFINE OFF


DECLARE
 cursor cur_tol is
 select * from ap_supplier_sites_all assa  
 where attribute8 in ('TR-STK','TR-VW','TR-FRONTDOOR');
 
 v_tot_count     NUMBER:=0;
BEGIN
 for x in cur_tol loop  
 v_tot_count:=v_tot_count+1;
  insert into xx_ap_custom_tolerances (SUPPLIER_ID, SUPPLIER_SITE_ID, ORG_ID, 
	FAVOURABLE_PRICE_PCT, MAX_PRICE_AMT, MIN_CHARGEBACK_AMT, MAX_FREIGHT_AMT, DIST_VAR_NEG_AMT, DIST_VAR_POS_AMT, CREATION_DATE, LAST_UPDATE_DATE)
	VALUES (x.vendor_id, x.vendor_site_id, x.org_id,
	30, 50, 2, NULL, 1,1, SYSDATE, SYSDATE);
  COMMIT;
 end loop;
 
 dbms_output.put_line('Total no. of records inserted: '||v_tot_count);
END;
/
