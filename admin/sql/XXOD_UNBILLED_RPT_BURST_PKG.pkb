SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace package body      XXOD_UNBILLED_RPT_BURST_PKG
AS

	FUNCTION get_parent_order_num(p_child_order_num VARCHAR2)
	RETURN VARCHAR2
	IS 
		l_parent_order_num xx_scm_bill_signal.PARENT_ORDER_NUMBER%TYPE;
		l_bill_forward_flag  xx_scm_bill_signal.bill_forward_flag%TYPE;
	BEGIN
		SELECT PARENT_ORDER_NUMBER , NVL(bill_forward_flag,'N')
		INTO l_parent_order_num , l_bill_forward_flag
		FROM apps.xx_scm_bill_signal xsb
		WHERE child_order_number = p_child_order_num;
    
	IF l_bill_forward_flag = 'C' THEN
		l_parent_order_num := 'NA';
	END IF;
	
	RETURN l_parent_order_num;
	
	EXCEPTION 
	WHEN NO_DATA_FOUND THEN
		RETURN NULL;
	WHEN OTHERS THEN 
		RETURN NULL;
	END get_parent_order_num;
	
	
   FUNCTION UNBILLED_GET_RPT_DATA(
      P_DATE      VARCHAR2
       )
	RETURN XXOD_UNBILLED_RPT_BURST_PKG.UNBILLED_RPT_DATA_TAB PIPELINED
	IS
	 CURSOR C_DATA_1(P_DATE VARCHAR2)
     IS
	 SELECT 
		  hp.party_name CUST_NAME
		 , hca.orig_system_reference LEGACY_CUST_NAME
		 , xce.n_ext_attr2 CUST_DOC_ID
		 , xce.n_ext_attr1 MBS_DOC_ID
		 , xce.c_ext_attr14  BILLING_FREQUENCY 
		 , 'DOC_TYPE' DOC_TYPE
		 , DECODE(xce.c_ext_attr2,'Y','Pay Doc','') ORI_PAY_DOC
		 , DECODE(xce.c_ext_attr3
				  ,'ELEC' ,'EBILL'
				  ,'PRINT' , DECODE( xce.c_ext_attr4
								   , NULL , 'CERTEGY'
								   , 'SPL Handle'
								   )
				  ,xce.c_ext_attr3                                      
				 ) DELIVERY_METHOD
		 , rct.trx_number TRX_NUMBER
		 , TO_CHAR(rct.trx_date,'DD-MON-YYYY') TRX_DATE
		 , TO_CHAR(ooha.ordered_date,'DD-MON-YYYY') ORDERED_DATE
		 , TO_CHAR(rct.billing_date,'DD-MON-YYYY') BILLING_DATE
		 , rctt.name TRX_TYPE_NAME 
		 , rctt.type TRX_CLASS
		 , rbsa.name BATCH_SOURCE_NAME
		 , ar_pay.amount_due_original  AMOUNT_DUE_ORIGINAL
		 , ar_pay.amount_due_remaining AMOUNT_DUE_REMAINING
		 , xoha.parent_order_num PARENT_ORDER_NUM
		 , 1 X
		from apps.oe_order_headers_All ooha 
		   , apps.oe_order_sources oos 
		   , apps.ra_customer_trx_all rct 
		   , apps.ra_batch_sources_all rbsa
		   , apps.xx_om_header_attributes_all xoha 
		   , apps.xx_cdh_cust_acct_ext_b xce 
		   , apps.hz_cust_accounts hca 
		   , apps.hz_parties hp
		   , apps.hz_customer_profiles hcp
		   , apps.ra_cust_trx_types_all rctt
		   , apps.ar_payment_schedules_all ar_pay 
		WHERE 1=1
		AND ooha.order_source_id = oos.order_source_id
		AND xoha.header_id = ooha.header_id
		--AND TO_CHAR(ooha.order_number) = (rct.interface_header_attribute1)
		AND rct.attribute14        = ooha.header_id
		AND rct.batch_source_id = rbsa.batch_source_id 
		AND xce.cust_account_id=rct.bill_to_customer_id
		AND hca.party_id = hp.party_id
		AND hca.cust_account_id = hcp.cust_account_id
		AND hcp.attribute6 IN ('B','Y')
		AND hcp.site_use_id is null
		AND rctt.cust_trx_type_id(+) = rct.cust_trx_type_id
		AND xoha.bill_comp_flag   IN( 'Y','B')
		AND NVL(xce.c_ext_attr1,'Consolidated Bill')  = 'Consolidated Bill'
		AND NVL(xce.c_ext_attr2 ,'Y')                 = 'Y'
		AND xce.attr_group_id (+)                     = 166
		AND xce.d_ext_attr1 <= SYSDATE 
		AND NVL(xce.d_ext_attr2,SYSDATE)  >= SYSDATE
		AND TRUNC(NVL(rct.billing_date,SYSDATE+37))>=TRUNC(SYSDATE+37)
		AND ooha.creation_date <= TO_DATE(P_DATE,'RRRR/MM/DD HH24:MI:SS') -7
		AND hca.cust_account_id       = rct.bill_to_customer_id
		And Parent_Order_Num     IS NOT NULL
		--and ooha.header_id > 1692921448
		AND ar_pay.customer_trx_id = rct.customer_trx_id
		AND ar_pay.amount_due_original = ar_pay.amount_due_remaining
		AND ar_pay.status = 'OP'
		AND NOT EXISTS
		  (SELECT 1
		  FROM apps.xx_scm_bill_signal
		  WHERE 1                =1
		  AND child_order_number = ooha.order_number
		  );
	
	CURSOR C_DATA_SPC (P_DATE VARCHAR2)
	IS
	--SPC Trx --295 sec
	select hp.party_name CUST_NAME
		 , hca.orig_system_reference LEGACY_CUST_NAME
		 , rct.trx_number TRX_NUMBER
		 , TO_CHAR(rct.trx_date,'DD-MON-YYYY') TRX_DATE
		 , TO_CHAR(oe.ordered_date,'DD-MON-YYYY') ORDERED_DATE
		 , TO_CHAR(rct.billing_date,'DD-MON-YYYY') BILLING_DATE
		 , rctt.name TRX_TYPE_NAME 
		 , rctt.type TRX_CLASS
		 , rbsa.name BATCH_SOURCE_NAME
		 , ar_pay.amount_due_original  AMOUNT_DUE_ORIGINAL
		 , ar_pay.amount_due_remaining AMOUNT_DUE_REMAINING
		 , oe.order_number
		 , rct.bill_to_customer_id
	from 
		oe_ordeR_headers_all  oe
	  , apps.ra_customer_trx_all rct 
	  , apps.ra_batch_sources_all rbsa
	  , apps.hz_cust_accounts hca 
	  , apps.hz_parties hp
	  , apps.ra_cust_trx_types_all rctt
	  , apps.ar_payment_schedules_all ar_pay  
	where 1=1
	AND rct.batch_source_id = rbsa.batch_source_id 
	AND hca.cust_account_id       = rct.bill_to_customer_id
	AND rctt.cust_trx_type_id(+) = rct.cust_trx_type_id
	AND ar_pay.customer_trx_id = rct.customer_trx_id
	AND hca.party_id = hp.party_id
	AND ar_pay.status = 'OP'
	AND rct.attribute14 = oe.header_id 
	AND (NVL(rct.billing_date,SYSDATE+37))>=(SYSDATE+37)
	AND oe.order_source_id = 1029 
	AND oe.creation_date <= TO_DATE(P_DATE,'RRRR/MM/DD HH24:MI:SS') -7;
	
	CURSOR C_DATA_ABS (P_DATE VARCHAR2) IS
	  --AB Recurring Trx -- 197 sec
	SELECT 
		   hp.party_name CUST_NAME
		 , hca.orig_system_reference LEGACY_CUST_NAME
		 , rct.trx_number TRX_NUMBER
		 , TO_CHAR(rct.trx_date,'DD-MON-YYYY') TRX_DATE
		 , TO_CHAR(ooha.ordered_date,'DD-MON-YYYY') ORDERED_DATE
		 , TO_CHAR(rct.billing_date,'DD-MON-YYYY') BILLING_DATE
		 , rctt.name TRX_TYPE_NAME 
		 , rctt.type TRX_CLASS
		 , rbsa.name BATCH_SOURCE_NAME
		 , ar_pay.amount_due_original  AMOUNT_DUE_ORIGINAL
		 , ar_pay.amount_due_remaining AMOUNT_DUE_REMAINING
		 , ooha.order_number
		 , rct.bill_to_customer_id
	from apps.oe_order_headers_All ooha 
	   , apps.oe_order_sources oos 
	   , apps.ra_customer_trx_all rct 
	   , apps.ra_batch_sources_all rbsa
	   , apps.hz_cust_accounts hca 
	   , apps.hz_parties hp
	   , apps.ra_cust_trx_types_all rctt
	   , apps.ar_payment_schedules_all ar_pay 
	WHERE 1=1
	AND ooha.order_source_id = oos.order_source_id
	AND rct.attribute14        = ooha.header_id
	AND rct.batch_source_id = rbsa.batch_source_id 
	AND hca.party_id = hp.party_id
	AND rctt.cust_trx_type_id = rct.cust_trx_type_id
	AND hca.cust_account_id       = rct.bill_to_customer_id
	AND TRUNC(NVL(rct.billing_date,SYSDATE+37))>=TRUNC(SYSDATE+37)
	AND ar_pay.customer_trx_id = rct.customer_trx_id
	AND ar_pay.status = 'OP'
	AND rctt.name = 'US_SERVICE_AOPS_OD'
	AND rbsa.name  = 'SUBSCRIPTION_BILLING_US'
	AND ooha.creation_date <= TO_DATE(P_DATE,'RRRR/MM/DD HH24:MI:SS') -7;
		
	TYPE rpt_data_1 IS TABLE OF C_DATA_1%ROWTYPE INDEX BY BINARY_INTEGER;
	l_rpt_data_1 rpt_data_1;
	
	TYPE spc_data IS TABLE OF C_DATA_SPC%ROWTYPE INDEX BY BINARY_INTEGER;
	l_spc_data spc_data;
	
	TYPE abs_data IS TABLE OF C_DATA_ABS%ROWTYPE INDEX BY BINARY_INTEGER;
	l_abs_data abs_data;
	
	
	TYPE UNBILLED_RPT_DATA_TAB
	IS
	TABLE OF XXOD_UNBILLED_RPT_BURST_PKG.UNBILLED_RPT_DATA INDEX BY PLS_INTEGER;
	L_UNBILLED_DATA_REC UNBILLED_RPT_DATA_TAB ;--:= UNBILLED_RPT_DATA_TAB();
	N NUMBER := 0;
	--L_UNBILLED_DATA_REC := 
	l_parent_order_num apps.xx_scm_bill_signal.PARENT_ORDER_NUMBER%TYPE;



	BEGIN
	
	Fnd_File.PUT_LINE (Fnd_File.LOG, 'Inside function - ' || 1);
		
		OPEN C_DATA_1(P_DATE);
		LOOP
			Fnd_File.PUT_LINE (Fnd_File.LOG, 'Main curson open - ' || 2);
			FETCH C_DATA_1 BULK COLLECT INTO l_rpt_data_1 LIMIT 500;
			EXIT WHEN l_rpt_data_1.COUNT = 0;
				
			FOR i IN 1 .. l_rpt_data_1.COUNT
			LOOP
				L_UNBILLED_DATA_REC(N).CUST_NAME 			   := l_rpt_data_1(i).CUST_NAME;
				L_UNBILLED_DATA_REC(N).LEGACY_CUST_NAME 	   := l_rpt_data_1(i).LEGACY_CUST_NAME;
				L_UNBILLED_DATA_REC(N).CUST_DOC_ID 			   := l_rpt_data_1(i).CUST_DOC_ID;
				L_UNBILLED_DATA_REC(N).MBS_DOC_ID 			   := l_rpt_data_1(i).MBS_DOC_ID;
				L_UNBILLED_DATA_REC(N).BILLING_FREQUENCY  	   := l_rpt_data_1(i).BILLING_FREQUENCY;
				L_UNBILLED_DATA_REC(N).DOC_TYPE 			   := l_rpt_data_1(i).DOC_TYPE;
				L_UNBILLED_DATA_REC(N).ORI_PAY_DOC 			   := l_rpt_data_1(i).ORI_PAY_DOC;
				L_UNBILLED_DATA_REC(N).DELIVERY_METHOD		   := l_rpt_data_1(i).DELIVERY_METHOD;
				L_UNBILLED_DATA_REC(N).TRX_NUMBER 			   := l_rpt_data_1(i).TRX_NUMBER;
				L_UNBILLED_DATA_REC(N).TRX_DATE 			   := l_rpt_data_1(i).TRX_DATE;
				L_UNBILLED_DATA_REC(N).ORDERED_DATE 		   := l_rpt_data_1(i).ORDERED_DATE;
				L_UNBILLED_DATA_REC(N).BILLING_DATE 		   := l_rpt_data_1(i).BILLING_DATE;
				L_UNBILLED_DATA_REC(N).TRX_TYPE_NAME 		   := l_rpt_data_1(i).TRX_TYPE_NAME;
				L_UNBILLED_DATA_REC(N).TRX_CLASS 			   := l_rpt_data_1(i).TRX_CLASS;
				L_UNBILLED_DATA_REC(N).BATCH_SOURCE_NAME 	   := l_rpt_data_1(i).BATCH_SOURCE_NAME;
				L_UNBILLED_DATA_REC(N).AMOUNT_DUE_ORIGINAL     := l_rpt_data_1(i).AMOUNT_DUE_ORIGINAL;
				L_UNBILLED_DATA_REC(N).AMOUNT_DUE_REMAINING    := l_rpt_data_1(i).AMOUNT_DUE_REMAINING;
				L_UNBILLED_DATA_REC(N).PARENT_ORDER_NUM 	   := l_rpt_data_1(i).PARENT_ORDER_NUM;
				L_UNBILLED_DATA_REC(N).X 					   := l_rpt_data_1(i).X;
				N                                              := N+1;
			END LOOP;
		END LOOP;
		CLOSE C_DATA_1;
		Fnd_File.PUT_LINE (Fnd_File.LOG, 'Main curson close - ' || 3);
		
		-- SPC Trx Start
		BEGIN
		
		Fnd_File.PUT_LINE (Fnd_File.LOG, 'SPC Trx Begin- ' || 4);
		
			WITH C1  AS  (SELECT /*+ MATERIALIZE */ trx_number ,trx_date , billing_date, bill_to_customer_id , batch_source_id , cust_trx_type_id , customer_trx_id , attribute14 
				FROM apps.ra_customer_trx_all rct 
				WHERE (NVL(rct.billing_date,SYSDATE+37))>=(SYSDATE+37)
				AND rct.attribute14 is not null)
			select  hp.party_name CUST_NAME
				 , hca.orig_system_reference LEGACY_CUST_NAME
				 , rct.trx_number TRX_NUMBER
				 , rct.trx_date
				 , oe.ordered_date
				 , rct.billing_date
				 , rctt.name TRX_TYPE_NAME 
				 , rctt.type TRX_CLASS
				 , rbsa.name BATCH_SOURCE_NAME
				 , ar_pay.amount_due_original  AMOUNT_DUE_ORIGINAL
				 , ar_pay.amount_due_remaining AMOUNT_DUE_REMAINING
				 , oe.order_number
				 , rct.bill_to_customer_id
				 BULK COLLECT INTO l_spc_data
			from 
				oe_ordeR_headers_all  oe
			  , C1 rct 
			  , apps.ra_batch_sources_all rbsa
			  , apps.hz_cust_accounts hca 
			  , apps.hz_parties hp
			  , apps.ra_cust_trx_types_all rctt
			  , apps.ar_payment_schedules_all ar_pay  
			where 1=1
			AND rct.batch_source_id = rbsa.batch_source_id
			AND hca.cust_account_id       = rct.bill_to_customer_id
			AND rctt.cust_trx_type_id = rct.cust_trx_type_id
			AND ar_pay.customer_trx_id = rct.customer_trx_id
			AND hca.party_id = hp.party_id
			AND ar_pay.status = 'OP'
			AND rct.attribute14 = oe.header_id 
			AND oe.order_source_id = 1029 
			AND oe.creation_date <= sysdate -7
      AND EXISTS ( SELECT 1 FROM apps.hz_customer_profiles hcp 
      WHERE 1=1
      AND hcp.cust_account_id = hca.cust_account_id 
      AND hcp.attribute6 IN ('B','Y')
    	AND hcp.site_use_id is null
      );
			
			Fnd_File.PUT_LINE (Fnd_File.LOG, 'SPC Trx Begin- data fetch -' || 4);
			
			BEGIN
			Fnd_File.PUT_LINE (Fnd_File.LOG, 'SPC Trx Begin- before loop -' || 4);
				FOR i in l_spc_data.FIRST..l_spc_data.LAST
				LOOP
				    Fnd_File.PUT_LINE (Fnd_File.LOG, 'SPC Trx Begin- inside loop -' || l_spc_data(i).order_number);
					l_parent_order_num := get_parent_order_num(l_spc_data(i).order_number);
					
					IF NVL(l_parent_order_num,'X') <> 'NA' THEN
						
						BEGIN
							SELECT xce.n_ext_attr2 CUST_DOC_ID
							 , xce.n_ext_attr1 MBS_DOC_ID
							 , xce.c_ext_attr14  BILLING_FREQUENCY 
							 , DECODE(xce.c_ext_attr2,'Y','Pay Doc','') ORI_PAY_DOC
							 , DECODE(xce.c_ext_attr3
									  ,'ELEC' ,'EBILL'
									  ,'PRINT' , DECODE( xce.c_ext_attr4
													   , NULL , 'CERTEGY'
													   , 'SPL Handle'
													   )
									  ,xce.c_ext_attr3                                      
									 ) DELIVERY_METHOD
							INTO 
							L_UNBILLED_DATA_REC(N).CUST_DOC_ID 			   
							,L_UNBILLED_DATA_REC(N).MBS_DOC_ID 			   
							,L_UNBILLED_DATA_REC(N).BILLING_FREQUENCY  	   
							,L_UNBILLED_DATA_REC(N).ORI_PAY_DOC 			   
							,L_UNBILLED_DATA_REC(N).DELIVERY_METHOD		   
							FROM apps.xx_cdh_cust_acct_ext_b xce
							WHERE 1=1 
							AND  (c_ext_attr1 IS NULL OR c_ext_attr1 = 'Consolidated Bill')
							AND  (c_ext_attr2 IS NULL OR  c_ext_attr2 = 'Y')
							AND  d_ext_attr1 <= SYSDATE 
							AND  (d_ext_attr2 IS NULL   OR d_ext_attr2 >= SYSDATE)
							AND  attr_group_id = 166
							AND  cust_account_id = l_spc_data(i).bill_to_customer_id;
						
							L_UNBILLED_DATA_REC(N).PARENT_ORDER_NUM 	   := l_parent_order_num;
							L_UNBILLED_DATA_REC(N).CUST_NAME 			   := l_spc_data(i).CUST_NAME;
							L_UNBILLED_DATA_REC(N).LEGACY_CUST_NAME 	   := l_spc_data(i).LEGACY_CUST_NAME;
							L_UNBILLED_DATA_REC(N).DOC_TYPE 			   := 'DOC_TYPE';
							L_UNBILLED_DATA_REC(N).TRX_NUMBER 			   := l_spc_data(i).TRX_NUMBER;
							L_UNBILLED_DATA_REC(N).TRX_DATE 			   := l_spc_data(i).TRX_DATE;
							L_UNBILLED_DATA_REC(N).ORDERED_DATE 		   := l_spc_data(i).ORDERED_DATE;
							L_UNBILLED_DATA_REC(N).BILLING_DATE 		   := l_spc_data(i).BILLING_DATE;
							L_UNBILLED_DATA_REC(N).TRX_TYPE_NAME 		   := l_spc_data(i).TRX_TYPE_NAME;
							L_UNBILLED_DATA_REC(N).TRX_CLASS 			   := l_spc_data(i).TRX_CLASS;
							L_UNBILLED_DATA_REC(N).BATCH_SOURCE_NAME 	   := l_spc_data(i).BATCH_SOURCE_NAME;
							L_UNBILLED_DATA_REC(N).AMOUNT_DUE_ORIGINAL     := l_spc_data(i).AMOUNT_DUE_ORIGINAL;
							L_UNBILLED_DATA_REC(N).AMOUNT_DUE_REMAINING    := l_spc_data(i).AMOUNT_DUE_REMAINING;
							--L_UNBILLED_DATA_REC(N).PARENT_ORDER_NUM 	   := l_spc_data(i).PARENT_ORDER_NUM;
							L_UNBILLED_DATA_REC(N).X 					   := 1;
							N                                              := N+1;
						
						EXCEPTION
						WHEN OTHERS THEN 
							L_UNBILLED_DATA_REC(N).PARENT_ORDER_NUM 	   := '';
						END;
					END IF;
				END LOOP;
			Fnd_File.PUT_LINE (Fnd_File.LOG, 'SPC Trx Begin- after loop -' || 4);
			END;
			
		EXCEPTION
		WHEN OTHERS THEN 
			Fnd_File.PUT_LINE (Fnd_File.LOG, 'SPC Trx Begin- exception -' || 4);
			Fnd_File.PUT_LINE (Fnd_File.LOG, 'Unable to fetch data' || SQLERRM);
		END;
		--SPC Trx End
		
		-- ABS Trx START
		
		BEGIN
		
		Fnd_File.PUT_LINE (Fnd_File.LOG, 'ABS Trx Begin- ' || 4);
		
			WITH C1  AS  (SELECT /*+ MATERIALIZE */ trx_number ,trx_date , billing_date, bill_to_customer_id , batch_source_id , cust_trx_type_id , customer_trx_id , attribute14 
				FROM apps.ra_customer_trx_all rct 
				WHERE (NVL(rct.billing_date,SYSDATE+37))>=(SYSDATE+37)
				AND rct.attribute14 is not null)
			SELECT 
				   hp.party_name CUST_NAME
				 , hca.orig_system_reference LEGACY_CUST_NAME
				 , rct.trx_number TRX_NUMBER
				 , TO_CHAR(rct.trx_date,'DD-MON-YYYY') TRX_DATE
				 , TO_CHAR(ooha.ordered_date,'DD-MON-YYYY') ORDERED_DATE
				 , TO_CHAR(rct.billing_date,'DD-MON-YYYY') BILLING_DATE
				 , rctt.name TRX_TYPE_NAME 
				 , rctt.type TRX_CLASS
				 , rbsa.name BATCH_SOURCE_NAME
				 , ar_pay.amount_due_original  AMOUNT_DUE_ORIGINAL
				 , ar_pay.amount_due_remaining AMOUNT_DUE_REMAINING
				 , ooha.order_number
				 , rct.bill_to_customer_id
			BULK COLLECT INTO l_abs_data	 
			from apps.oe_order_headers_All ooha 
			   , apps.oe_order_sources oos 
			   , C1 rct 
			   , apps.ra_batch_sources_all rbsa
			   , apps.hz_cust_accounts hca 
			   , apps.hz_parties hp
			   , apps.ra_cust_trx_types_all rctt
			   , apps.ar_payment_schedules_all ar_pay 
			WHERE 1=1
			AND ooha.order_source_id = oos.order_source_id
			AND rct.attribute14        = ooha.header_id
			AND rct.batch_source_id = rbsa.batch_source_id 
			AND hca.party_id = hp.party_id
			AND rctt.cust_trx_type_id = rct.cust_trx_type_id
			AND hca.cust_account_id       = rct.bill_to_customer_id
			AND ar_pay.customer_trx_id = rct.customer_trx_id
			AND ar_pay.status = 'OP'
			AND rctt.name = 'US_SERVICE_AOPS_OD'
			AND rbsa.name  = 'SUBSCRIPTION_BILLING_US'
			AND ooha.creation_date <= TO_DATE(P_DATE,'RRRR/MM/DD HH24:MI:SS') -7
			AND EXISTS ( SELECT 1 FROM apps.hz_customer_profiles hcp 
			WHERE 1=1
			AND hcp.cust_account_id = hca.cust_account_id 
			AND hcp.attribute6 IN ('B','Y')
			AND hcp.site_use_id is null
			);
			
			Fnd_File.PUT_LINE (Fnd_File.LOG, 'ABS Trx Begin- data fetch -' || 4);
			
			BEGIN
			Fnd_File.PUT_LINE (Fnd_File.LOG, 'ABS Trx Begin- before loop -' || 4);
				FOR i in l_abs_data.FIRST..l_abs_data.LAST
				LOOP
				    Fnd_File.PUT_LINE (Fnd_File.LOG, 'ABS Trx Begin- inside loop -' || l_abs_data(i).order_number);
					l_parent_order_num := get_parent_order_num(l_abs_data(i).order_number);
					
					IF NVL(l_parent_order_num,'X') <> 'NA' THEN
						Fnd_File.PUT_LINE (Fnd_File.LOG, 'ABS Trx Begin- inside if -' || l_abs_data(i).TRX_NUMBER);
						BEGIN
						Fnd_File.PUT_LINE (Fnd_File.LOG, 'ABS Trx Begin- before customer details -' || l_abs_data(i).CUST_NAME);
							SELECT xce.n_ext_attr2 CUST_DOC_ID
							 , xce.n_ext_attr1 MBS_DOC_ID
							 , xce.c_ext_attr14  BILLING_FREQUENCY 
							 , DECODE(xce.c_ext_attr2,'Y','Pay Doc','') ORI_PAY_DOC
							 , DECODE(xce.c_ext_attr3
									  ,'ELEC' ,'EBILL'
									  ,'PRINT' , DECODE( xce.c_ext_attr4
													   , NULL , 'CERTEGY'
													   , 'SPL Handle'
													   )
									  ,xce.c_ext_attr3                                      
									 ) DELIVERY_METHOD
							INTO 
							L_UNBILLED_DATA_REC(N).CUST_DOC_ID 			   
							,L_UNBILLED_DATA_REC(N).MBS_DOC_ID 			   
							,L_UNBILLED_DATA_REC(N).BILLING_FREQUENCY  	   
							,L_UNBILLED_DATA_REC(N).ORI_PAY_DOC 			   
							,L_UNBILLED_DATA_REC(N).DELIVERY_METHOD		   
							FROM apps.xx_cdh_cust_acct_ext_b xce
							WHERE 1=1 
							AND  (c_ext_attr1 IS NULL OR c_ext_attr1 = 'Consolidated Bill')
							AND  (c_ext_attr2 IS NULL OR  c_ext_attr2 = 'Y')
							AND  d_ext_attr1 <= SYSDATE 
							AND  (d_ext_attr2 IS NULL   OR d_ext_attr2 >= SYSDATE)
							AND  attr_group_id = 166
							AND  cust_account_id = l_abs_data(i).bill_to_customer_id;
						
						Fnd_File.PUT_LINE (Fnd_File.LOG, 'ABS Trx Begin- after customer details -' || l_abs_data(i).CUST_NAME);
						
							L_UNBILLED_DATA_REC(N).PARENT_ORDER_NUM 	   := l_parent_order_num;
							L_UNBILLED_DATA_REC(N).CUST_NAME 			   := l_abs_data(i).CUST_NAME;
							L_UNBILLED_DATA_REC(N).LEGACY_CUST_NAME 	   := l_abs_data(i).LEGACY_CUST_NAME;
							L_UNBILLED_DATA_REC(N).DOC_TYPE 			   := 'DOC_TYPE';
							L_UNBILLED_DATA_REC(N).TRX_NUMBER 			   := l_abs_data(i).TRX_NUMBER;
							L_UNBILLED_DATA_REC(N).TRX_DATE 			   := l_abs_data(i).TRX_DATE;
							L_UNBILLED_DATA_REC(N).ORDERED_DATE 		   := l_abs_data(i).ORDERED_DATE;
							L_UNBILLED_DATA_REC(N).BILLING_DATE 		   := l_abs_data(i).BILLING_DATE;
							L_UNBILLED_DATA_REC(N).TRX_TYPE_NAME 		   := l_abs_data(i).TRX_TYPE_NAME;
							L_UNBILLED_DATA_REC(N).TRX_CLASS 			   := l_abs_data(i).TRX_CLASS;
							L_UNBILLED_DATA_REC(N).BATCH_SOURCE_NAME 	   := l_abs_data(i).BATCH_SOURCE_NAME;
							L_UNBILLED_DATA_REC(N).AMOUNT_DUE_ORIGINAL     := l_abs_data(i).AMOUNT_DUE_ORIGINAL;
							L_UNBILLED_DATA_REC(N).AMOUNT_DUE_REMAINING    := l_abs_data(i).AMOUNT_DUE_REMAINING;
							--L_UNBILLED_DATA_REC(N).PARENT_ORDER_NUM 	   := l_spc_data(i).PARENT_ORDER_NUM;
							L_UNBILLED_DATA_REC(N).X 					   := 1;
							N                                              := N+1;
						
						EXCEPTION
						WHEN OTHERS THEN 
						    Fnd_File.PUT_LINE (Fnd_File.LOG, 'ABS Trx Begin- Customer Query exception -' || SQLERRM);
							L_UNBILLED_DATA_REC(N).PARENT_ORDER_NUM 	   := '';
						END;
					END IF;
				END LOOP;
			Fnd_File.PUT_LINE (Fnd_File.LOG, 'ABS Trx Begin- after loop -' || 4);
			END;
			
		EXCEPTION
		WHEN OTHERS THEN 
			Fnd_File.PUT_LINE (Fnd_File.LOG, 'ABS Trx Begin- exception -' || 4);
			Fnd_File.PUT_LINE (Fnd_File.LOG, 'Unable to fetch data' || SQLERRM);
		END;
		
		-- ABS Trx End 

FOR I IN L_UNBILLED_DATA_REC.FIRST .. L_UNBILLED_DATA_REC.LAST
  LOOP
    PIPE ROW ( L_UNBILLED_DATA_REC(I) ) ;
  END LOOP;
  RETURN;

	EXCEPTION
      WHEN OTHERS
      THEN
         Fnd_File.PUT_LINE (Fnd_File.LOG, 'Unable to fetch data' || SQLERRM);
	END UNBILLED_GET_RPT_DATA;
	

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
SHOW ERRORS;