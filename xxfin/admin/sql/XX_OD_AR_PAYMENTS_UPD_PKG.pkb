CREATE OR REPLACE
PACKAGE BODY XX_OD_AR_PAYMENTS_UPD_PKG
AS
gRequestId   NUMBER    DEFAULT FND_GLOBAL.CONC_REQUEST_ID;
PROCEDURE XX_OD_AR_PAYMENTS_UPD_PRC(
                             x_err_buff    		OUT VARCHAR2,
							 x_ret_code    		OUT NUMBER,
							 p_gl_date     		IN VARCHAR2							 
                            )
AS

l_p_gl_date  DATE := trunc(to_date(p_gl_date, 'RRRR/MM/DD HH24:MI:SS'));
ln_drequest_id  NUMBER;
l_mail_subject VARCHAR2(40) := 'MEC Update AR Payments Interface';
l_sender_address VARCHAR2(30) :='noreply@officedepot.com';
l_mail_body   VARCHAR2(100) := 'Hi, '||
'Please find the attached report of Updated AR Payments Interface';
l_user_name   fnd_user.user_name%TYPE;
l_full_name   per_people_f.full_name%TYPE;
l_total_rows NUMBER := 0;
l_updated_rows NUMBER := 0;
l_temp_email VARCHAR2(100);
l_email_address VARCHAR2(1000);
CURSOR email_curr IS 
SELECT b.meaning 
FROM FND_LOOKUP_TYPES a, FND_LOOKUP_VALUES b 
WHERE a.lookup_type = 'XX_OD_MEC_TABLES_UPD'
AND b.language = 'US'
and b.enabled_flag = 'Y'
AND   a.lookup_type = b.lookup_type;
BEGIN
		
		BEGIN
			OPEN email_curr;
			LOOP
				FETCH email_curr INTO l_temp_email;
				EXIT WHEN email_curr%NOTFOUND OR email_curr%NOTFOUND IS NULL;
				l_email_address := l_email_address || l_temp_email ||',';
			END LOOP;
			CLOSE email_curr;			
			EXCEPTION
			WHEN NO_DATA_FOUND THEN
			l_email_address := '';
			WHEN OTHERS THEN
			l_email_address := '';
		END;

		BEGIN
		
			select count(*)  INTO l_total_rows 
			from ar_payments_interface_all
			where TRUNC(gl_date) < l_p_gl_date;		
			
			EXCEPTION
			WHEN OTHERS THEN
			l_total_rows := 0;
		END;


		BEGIN
		
			UPDATE ar_payments_interface_all 
			SET GL_DATE = l_p_gl_date,
				LAST_UPDATE_DATE = SYSDATE,
				LAST_UPDATED_BY = NVL(FND_GLOBAL.USER_ID,-1),
				LAST_UPDATE_LOGIN = NVL(FND_GLOBAL.LOGIN_ID,-1)	
			WHERE TRUNC(gl_date) < l_p_gl_date; 
			
			l_updated_rows := SQL%ROWCOUNT;	
			
			COMMIT; 

			
			EXCEPTION
			WHEN NO_DATA_FOUND THEN
			l_updated_rows := 0;
            x_err_buff := 'No Data Found';
            x_ret_code := 0;
			fnd_file.put_line(fnd_file.log,'No Data Found');
			WHEN OTHERS THEN
			l_updated_rows := 0;
			x_err_buff := 'Update Failed'||sqlerrm;
            x_ret_code := 0;
			fnd_file.put_line(fnd_file.log,x_err_buff);
		END;
		BEGIN
		
			SELECT u.user_name v_user_name,p.full_name AS v_person_name
			INTO l_user_name,l_full_name
			from fnd_user u, per_people_f p
			where u.user_id = fnd_global.user_id
			and p.person_id(+) = u.employee_id
			and (p.EFFECTIVE_END_DATE > SYSDATE OR p.EFFECTIVE_END_DATE IS NULL)
			and rownum = 1;
		
			EXCEPTION
			WHEN OTHERS THEN
			l_user_name := ' ';
			l_full_name := ' ';		
		END;
		fnd_file.put_line(fnd_file.log,'l_p_gl_date: '||l_p_gl_date);
		fnd_file.put_line(fnd_file.log,'p_gl_date: '||p_gl_date);		
		fnd_file.put_line(fnd_file.log,'Count of rows update:'||TO_CHAR(l_updated_rows));
		fnd_file.put_line(fnd_file.log,'Count of errors:'||TO_CHAR(l_total_rows - l_updated_rows));		
		
		fnd_file.put_line(fnd_file.output,rpad('Office Depot',50,' ')||' ~ Confidential ~');    		
		fnd_file.put_line(fnd_file.output,rpad('MEC AR Payments Interface Update Program',50,' '));
		fnd_file.put_line(fnd_file.output,rpad('Program Id',49,' ')||': R7004');
		fnd_file.put_line(fnd_file.output,rpad('Date/Time',49,' ')||': '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
		fnd_file.put_line(fnd_file.output,rpad('Run By',49,' ')||': '||l_user_name||' '||l_full_name);
		fnd_file.put_line(fnd_file.output,rpad('+=',99,'=')||'+');
		fnd_file.put_line(fnd_file.output,' ');		
		fnd_file.put_line(fnd_file.output,rpad('Run Parameters:',50,' '));
		fnd_file.put_line(fnd_file.output,rpad('-',14,'-'));
		fnd_file.put_line(fnd_file.output,rpad('Period Open Date',49,' ')||': '||to_char(l_p_gl_date,'DD-MON-RRRR'));
		fnd_file.put_line(fnd_file.output,rpad('Email Address',49,' ')||': '||SUBSTR(l_email_address,0,(length(l_email_address)-1)));
		fnd_file.put_line(fnd_file.output,' ');
		fnd_file.put_line(fnd_file.output,rpad('+-',99,'-')||'+');
		fnd_file.put_line(fnd_file.output,' ');
		fnd_file.put_line(fnd_file.output,rpad('Updated Table',49,' ')||': '||'AR.AR_PAYMENTS_INTERFACE_ALL');
		fnd_file.put_line(fnd_file.output,rpad('Count Of Rows Updated',49,' ')||': '||TO_CHAR(l_updated_rows));
		fnd_file.put_line(fnd_file.output,rpad('Count Of Errors',49,' ')||': '||TO_CHAR(l_total_rows - l_updated_rows));		
		fnd_file.put_line(fnd_file.output,rpad('+-',99,'-')||'+');
		
		--Sending Email with attachment
		ln_drequest_id := FND_REQUEST.SUBMIT_REQUEST(
													'XXFIN'
													,'XXODROEMAILER'
													,NULL
													,TO_CHAR(SYSDATE,'DD-MON-YY HH24:MM:SS')
													,FALSE
													,NULL
													,l_email_address
													,l_mail_subject
													,l_mail_body
													,'Y'
													,gRequestId
													,l_sender_address
													);
		COMMIT;		
		
		EXCEPTION
		  WHEN NO_DATA_FOUND THEN
            x_err_buff := 'No Data Found';
            x_ret_code := 0;
			fnd_file.put_line(fnd_file.log,'No Data Found');				  
		  WHEN OTHERS THEN
            x_err_buff := 'Update Failed'||sqlerrm;
            x_ret_code := 0;
			fnd_file.put_line(fnd_file.log,x_err_buff);		
			
END XX_OD_AR_PAYMENTS_UPD_PRC;

END XX_OD_AR_PAYMENTS_UPD_PKG;
/