SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace PACKAGE      XXOD_UNBILLED_RPT_BURST_PKG
AS

  P_DATE VARCHAR2(50);
   FUNCTION AfterReport
      RETURN BOOLEAN;
TYPE UNBILLED_RPT_DATA
IS
  RECORD
  (
       CUST_NAME 				apps.hz_parties.party_name%TYPE
     , LEGACY_CUST_NAME 	apps.hz_cust_accounts.orig_system_reference%TYPE
     , CUST_DOC_ID 				apps.xx_cdh_cust_acct_ext_b.n_ext_attr2%TYPE
     , MBS_DOC_ID 				apps.xx_cdh_cust_acct_ext_b.n_ext_attr1%TYPE
     , BILLING_FREQUENCY  			apps.xx_cdh_cust_acct_ext_b.c_ext_attr14%TYPE 
     , DOC_TYPE 				VARCHAR2(40) 
	 , ORI_PAY_DOC 				apps.xx_cdh_cust_acct_ext_b.c_ext_attr2%TYPE 
     , DELIVERY_METHOD			apps.xx_cdh_cust_acct_ext_b.c_ext_attr3%TYPE
     , TRX_NUMBER 				apps.ra_customer_trx_all.trx_number%TYPE
     , TRX_DATE 				DATE
     , ORDERED_DATE 			DATE
     , BILLING_DATE 			DATE
     , TRX_TYPE_NAME 			apps.ra_cust_trx_types_all.name%TYPE
     , TRX_CLASS 				apps.ra_cust_trx_types_all.type%TYPE
     , BATCH_SOURCE_NAME 		apps.ra_batch_sources_all.name%TYPE
	 , AMOUNT_DUE_ORIGINAL  	apps.ar_payment_schedules_all.amount_due_original%TYPE
	 , AMOUNT_DUE_REMAINING 	apps.ar_payment_schedules_all.amount_due_remaining%TYPE
	 , PARENT_ORDER_NUM 		apps.xx_scm_bill_signal.parent_order_number%TYPE
	 , X 						NUMBER 
  );
TYPE UNBILLED_RPT_DATA_TAB
IS
  TABLE OF XXOD_UNBILLED_RPT_BURST_PKG.UNBILLED_RPT_DATA;
  FUNCTION UNBILLED_GET_RPT_DATA(
      P_DATE     VARCHAR2
       )RETURN XXOD_UNBILLED_RPT_BURST_PKG.UNBILLED_RPT_DATA_TAB PIPELINED;
   
END;
/
SHOW ERRORS;