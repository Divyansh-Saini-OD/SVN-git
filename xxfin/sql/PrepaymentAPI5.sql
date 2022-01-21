-- Added for testing the Subversion on 02-JAN-2007
<<<<<<< .mine
--RK Test
-- RK TESTSSS
=======
-- Added for testing the Subversion on 02-JAN-2007 - Raj
-- Added for testing the Subversion on 02-JAN-2007 - Raj
 

>>>>>>> .r40
DECLARE
	x_return_status 	VARCHAR2(250);
	x_msg_count		NUMBER;-- output message count
	x_msg_data		VARCHAR2(2000);-- reference string for output message text
	l_receipt_number	ar_cash_receipts.receipt_number%TYPE := 11060;
	l_currency_code		ar_cash_receipts.currency_code%TYPE;-- := 'USD';
	p_payment_amount	NUMBER := 122;
	l_receipt_method_id	ar_cash_receipts.receipt_method_id%TYPE := 1000; --8001; --1000;
	p_customer_id		ar_cash_receipts.pay_from_customer%TYPE := 24040;
	l_site_use_id		hz_cust_site_uses.site_use_id%TYPE := 1780;
	l_receipt_currency_code	ar_cash_receipts.currency_code%TYPE; --:= 'USD';
	p_bank_account_id	ar_cash_receipts.customer_bank_account_id%TYPE := 10121;
	l_receipt_exchange_rate	ar_cash_receipts.exchange_rate%TYPE;
	l_receipt_exchange_rate_type	ar_cash_receipts.exchange_rate_type%TYPE;
	l_receipt_exchange_rate_date	ar_cash_receipts.exchange_date%TYPE;
	l_application_ref_type	VARCHAR2(100);-- := 'OM';
	l_application_ref_num	VARCHAR2(1000);-- := 2421;
	l_application_ref_id	NUMBER;-- := 17189;
	l_cr_id			ar_cash_receipts.cash_receipt_id%TYPE;
	l_receivable_application_id	ar_receivable_applications.receivable_application_id%TYPE;
	l_call_payment_processor	VARCHAR2(1000);
	l_payment_response_error_code	VARCHAR2(1000);
	l_payment_set_id 		NUMBER;--If not passed generate a new number
	p_payment_schedule_id		NUMBER := -6;

	l_called_from			VARCHAR2(100) := NULL; --'OM'; --NULL;
	l_secondary_application_ref_id 	NUMBER;
	l_payment_server_order_num	VARCHAR2(80); -- := 'CRP_2545';
	l_approval_code			VARCHAR2(80) := 2233;
t_output VARCHAR2(2000);
t_msg_dummy NUMBER;
BEGIN

	dbms_application_info.set_client_info('101');

	FND_GLOBAL.APPS_INITIALIZE(2983, 50249, 222);

	AR_PREPAYMENTS_PUB1.create_prepayment(
	p_api_version => 1.0,
---	p_init_msg_list => FND_API.G_TRUE,
	p_commit => FND_API.G_FALSE,
	p_validation_level => FND_API.G_VALID_LEVEL_FULL, --
	x_return_status => x_return_status,
	x_msg_count => x_msg_count,
	x_msg_data => x_msg_data,
--	p_usr_currency_code => 'USD', --
	p_currency_code => l_currency_code,
	p_usr_exchange_rate_type => NULL, --
	p_exchange_rate_type => l_receipt_exchange_rate_type,
	p_exchange_rate => l_receipt_exchange_rate,
	p_exchange_rate_date => l_receipt_exchange_rate_date,
	p_amount => p_payment_amount,
--	p_factor_discount_amount => NULL, --
	p_receipt_number => l_receipt_number,
	p_receipt_date => SYSDATE, --NULL, --
--	p_gl_date => NULL, --
--	p_maturity_date => NULL, --
--	p_postmark_date => NULL, --
	p_customer_id => p_customer_id,
--	p_customer_name => 'A Advantage Inc', --
--	p_customer_number => 1360, --NULL, --
	p_customer_bank_account_id => p_bank_account_id,
	p_customer_bank_account_num => '4111111111111111', --NULL, --
	p_customer_bank_account_name => 'Credit Card Bank', --NULL, --
--	p_location => NULL, --
	p_customer_site_use_id => l_site_use_id,
--	p_customer_receipt_reference => NULL, --
--	p_override_remit_account_flag => NULL, --
--	p_remittance_bank_account_id => NULL, --
--	p_remittance_bank_account_num => '4111111111111111', --
--	p_remittance_bank_account_name =>'Credit Card Bank' , --
--	p_deposit_date		 => NULL, --
	p_receipt_method_id => l_receipt_method_id,
--	p_receipt_method_name => NULL, --
	p_doc_sequence_value => NULL, --
--	p_ussgl_transaction_code => NULL, --
--	p_anticipated_clearing_date => NULL, --
	p_called_from => l_called_from, --
--	p_attribute_rec => ar_receipt_api_pub.attribute_rec_const, --
--	p_global_attribute_rec => ar_receipt_api_pub.global_attribute_rec_const, --
	p_receipt_comments => NULL, --
--	p_issuer_name => NULL, --
--	p_issue_date => NULL, --
--	p_issuer_bank_branch_id => NULL, --
	p_cr_id => l_cr_id,	
	p_applied_payment_schedule_id => p_payment_schedule_id,
--	p_amount_applied => p_payment_amount, -- 28NOV NULL, --
	p_application_ref_type => l_application_ref_type , --Ordertype
	p_application_ref_num => l_application_ref_num, --Order Number
	p_secondary_application_ref_id => L_SECONDARY_APPLICATION_REF_ID, --
--	p_receivable_trx_id => NULL, --
--	p_amount_applied_from => NULL, --
--	p_apply_date => NULL, --
--	p_apply_gl_date => NULL, --
--	app_ussgl_transaction_code => NULL, --
--	p_show_closed_invoices => 'FALSE',--
--	p_move_deferred_tax => 'Y',--
--	app_attribute_rec => ar_receipt_api_pub.attribute_rec_const,--
--	app_global_attribute_rec => ar_receipt_api_pub.global_attribute_rec_const,--
--	app_comments => NULL, --
	p_payment_server_order_num => l_payment_server_order_num,
	p_approval_code => l_approval_code,
	p_call_payment_processor => FND_API.G_TRUE,	
	p_payment_response_error_code => l_payment_response_error_code,
	p_receivable_application_id => l_receivable_application_id, --OUT
	p_payment_set_id => l_payment_set_id,
	p_application_ref_id => l_application_ref_id --Order Id


	);

dbms_output.put_line('l_cr_id : ' || l_cr_id);
		dbms_output.put_line('x_return_status : ' || x_return_status);

	dbms_output.put_line('Pre Payment Error : ' || l_payment_response_error_code);
	dbms_output.put_line('x_msg_data : ' || substr(x_msg_data, 1, 40));
	-- printing the error messages, if any from the API message list.
/*	FOR i IN 1..x_msg_count LOOP
		dbms_output.put('msg # '||to_char(i)|| fnd_msg_pub.get(i));
		dbms_output.new_line();
	END LOOP;
*/
if x_msg_count > 0
then
for j in 1 .. x_msg_count loop
fnd_msg_pub.get
( j
, FND_API.G_FALSE
, x_msg_data
, t_msg_dummy
);
t_output := ( 'Msg'
|| To_Char
( j
)
|| ': '
|| x_msg_data
);
dbms_output.put_line
( SubStr
( t_output
, 1
, 255
)
);
end loop;
end if;

dbms_output.put_line('x_return_status = '||x_return_status);
dbms_output.put_line('x_msg_count = '||TO_CHAR(x_msg_count));
dbms_output.put_line('x_msg_data = '||x_msg_data);

	EXCEPTION

	WHEN OTHERS THEN
		dbms_output.put_line('In When others Exception');
		dbms_output.put_line('SQlerr is :'||substr(SQLERRM,1,200));
END;
/
