create or replace
PACKAGE  BODY  xx_cdh_bpel_sync_alert_pkg
AS
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- +====================================================================================+
-- | Name        :  xx_cdh_bpel_sync_alert_pkg.pkb                                      |
-- | Description :  Checks the last update time for the dummy entity. This package raise|
-- |                an Email alert if the time difference between the last update time  |
-- |                and the system time is more than the expected time                  |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date        Author             Remarks                                    |
-- |========  =========== ================== ===========================================|
-- |DRAFT 1a  18-Aug-2008 Kathirvel          Initial draft version                      |
-- |          23-Jul-2009 Kalyan             Added procedures for Sales Rep Retry       | 
-- |                                         Functionality.                             |
-- |1.1       18-Nov-2015 Manikant Kasu      Removed schema alias as part of GSCC       |
-- |                                         R12.2.2 Retrofit                           |
-- +====================================================================================+

PROCEDURE xx_cdh_raise_alert_proc(
                                            x_errbuf		OUT NOCOPY    VARCHAR2
                                          , x_retcode		OUT NOCOPY    VARCHAR2
                                          , p_mail_server	IN            VARCHAR2
                                          , p_mail_from		IN            VARCHAR2
                                          , p_from_title	IN            VARCHAR2
                                          , p_subject		IN            VARCHAR2
					  , p_page_flag         IN            VARCHAR2
                                          , p_check_minutes     IN            NUMBER
                                          )

 IS


 l_check_minutes          NUMBER;
 mail_con                 utl_smtp.connection;
 l_subject                VARCHAR2(100);
 l_account_osr            VARCHAR2(100);
 l_acct_site_osr          VARCHAR2(100);
 l_org_contact_osr        VARCHAR2(100);
 l_phone_contact_osr      VARCHAR2(100);
 l_email_contact_osr      VARCHAR2(100);
 l_process_entity         VARCHAR2(100);
 l_process_osr            VARCHAR2(100);
 l_mail_to                VARCHAR2(2000);
 l_last_update            DATE;
 AOPS_DOWN_NO_ALERT       EXCEPTION;
 l_database_name          VARCHAR2(100);
 l_cust_acct_id           NUMBER;
 l_web_contact_osr        VARCHAR2(100);
 l_attr_group_id          NUMBER;
 l_spc_card_num           NUMBER;
 l_from_time              VARCHAR2(5);
 l_to_time                VARCHAR2(5);
 l_email_alert_count      NUMBER := 0;

 l_return_status          VARCHAR2(1);
 l_error_message          VARCHAR2(2000);

 CURSOR l_database_name_cur IS
 SELECT name
 FROM   v$database;


 CURSOR l_account_cur IS
 SELECT cac.last_update_date , cac.cust_account_id
 FROM   hz_orig_sys_references osr, hz_cust_accounts cac
 WHERE  osr.orig_system_reference = l_account_osr
 AND    osr.owner_table_name = 'HZ_CUST_ACCOUNTS'
 AND    osr.orig_system      = 'A0'
 AND    osr.owner_table_id   = cac.cust_account_id
 AND    osr.status = 'A';

 CURSOR l_address_cur IS
 SELECT cas.last_update_date
 FROM   hz_orig_sys_references osr, hz_cust_acct_sites_all cas
 WHERE  osr.orig_system_reference = l_acct_site_osr
 AND    osr.owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
 AND    osr.orig_system      = 'A0'
 AND    osr.owner_table_id   = cas.cust_acct_site_id
 AND    osr.status = 'A';


 CURSOR l_org_contact_cur IS
 SELECT hoc.last_update_date
 FROM   hz_orig_sys_references osr, hz_org_contacts hoc
 WHERE  osr.orig_system_reference = l_org_contact_osr
 AND    osr.owner_table_name = 'HZ_ORG_CONTACTS'
 AND    osr.orig_system      = 'A0'
 AND    osr.owner_table_id   = hoc.org_contact_id
 AND    osr.status = 'A';


 CURSOR l_contact_point_cur(l_contact_point_osr VARCHAR2) IS
 SELECT hcp.last_update_date
 FROM   hz_orig_sys_references osr, hz_contact_points hcp
 WHERE  osr.orig_system_reference = l_contact_point_osr
 AND    osr.owner_table_name = 'HZ_CONTACT_POINTS'
 AND    osr.orig_system      = 'A0'
 AND    osr.owner_table_id   = hcp.contact_point_id
 AND    osr.status = 'A';

 CURSOR l_external_user_cur IS
 SELECT last_update_date
 FROM   xx_external_users
 WHERE  webuser_osr = l_web_contact_osr;

 CURSOR l_attr_group_cur IS
 SELECT attr_group_id
 FROM   ego_fnd_dsc_flx_ctx_ext
 WHERE  descriptive_flexfield_name = 'XX_CDH_CUST_ACCOUNT'
 AND descriptive_flex_context_code = 'SPC_INFO';

 CURSOR l_spc_extn_attbt_cur IS
 SELECT last_update_date
 FROM   XX_CDH_CUST_ACCT_EXT_B
 WHERE  cust_account_id = l_cust_acct_id
 AND    attr_group_id = l_attr_group_id
 AND    N_EXT_ATTR1   = l_spc_card_num;


 CURSOR l_aops_down_time_cur IS
 SELECT meaning
 FROM   fnd_lookup_values
 WHERE  lookup_type   = 'XXOD_CDH_BPEL_AOPS_DOWN_TIMES'
 AND    enabled_flag  = 'Y'
 AND    nvl(end_date_active,sysdate) >= sysdate;


 BEGIN

      OPEN  l_database_name_cur;
      FETCH l_database_name_cur INTO l_database_name;
      CLOSE l_database_name_cur;

      l_check_minutes := NVL(p_check_minutes,15)/(24*60);
      l_subject           := NVL(p_subject,l_database_name ||' - BPEL CDH Sync Appears To Be Down');
      l_account_osr       := '35566120-00001-A0';
      l_acct_site_osr     := '35566120-00003-A0';
      l_org_contact_osr   := '00000024952597';
      l_phone_contact_osr := 'P00000025389183';
      l_email_contact_osr := 'E00000007426704';
      l_web_contact_osr   := '00000007196212';
      l_spc_card_num      := 80109132498;

      FOR I IN l_aops_down_time_cur
      LOOP
          l_from_time  := SUBSTR(TRIM(I.meaning),1,5);
          l_to_time    := SUBSTR(TRIM(I.meaning),-5);

          IF SYSDATE BETWEEN TO_DATE(TO_CHAR(SYSDATE,'DD/MON/YYYY ')||l_from_time,'DD/MON/YYYY HH24:MI')
	     AND TO_DATE(TO_CHAR(SYSDATE,'DD/MON/YYYY ')||l_to_time,'DD/MON/YYYY HH24:MI')
	  THEN
               RAISE AOPS_DOWN_NO_ALERT;
	       EXIT;
	  END IF;
      END LOOP;

      l_process_entity  := 'HZ_CUST_ACCOUNTS';
      l_process_osr     := l_account_osr;
      l_last_update     := NULL;

      OPEN  l_account_cur;
      FETCH l_account_cur INTO l_last_update,l_cust_acct_id;
      CLOSE l_account_cur;

      IF SYSDATE - l_last_update > l_check_minutes or l_last_update IS NULL
      THEN
		l_email_alert_count  := l_email_alert_count +1;

                 xx_cdh_send_email_proc(
                                            p_mail_server	=>   p_mail_server
                                          , p_mail_from		=>   p_mail_from
                                          , p_from_title	=>   p_from_title
                                          , p_subject		=>   l_subject
					  , p_page_flag         =>   p_page_flag
					  , p_entity_name       =>   l_process_entity
					  , p_osr		=>   l_process_osr
					  , x_return_status     =>   l_return_status
					  , x_error_message     =>   l_error_message
                                          );

		  x_errbuf := 'BPEL CDH Sync is Down at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.'||l_error_message;
                  --x_retcode := 2;
                  fnd_file.put_line (fnd_file.log, 'BPEL CDH Sync is Down at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.');
      ELSE
              fnd_file.put_line (fnd_file.log, 'BPEL CDH Sync Running Successfully at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.');
      END IF;

      l_process_entity  := 'HZ_CUST_ACCT_SITES_ALL';
      l_process_osr     := l_acct_site_osr;
      l_last_update     := NULL;

      OPEN  l_address_cur;
      FETCH l_address_cur INTO l_last_update;
      CLOSE l_address_cur;

      IF SYSDATE - l_last_update > l_check_minutes or l_last_update IS NULL
      THEN

      		l_email_alert_count  := l_email_alert_count +1;

                 xx_cdh_send_email_proc(
                                            p_mail_server	=>   p_mail_server
                                          , p_mail_from		=>   p_mail_from
                                          , p_from_title	=>   p_from_title
                                          , p_subject		=>   l_subject
					  , p_page_flag         =>   p_page_flag
					  , p_entity_name       =>   l_process_entity
					  , p_osr		=>   l_process_osr
					  , x_return_status     =>   l_return_status
					  , x_error_message     =>   l_error_message
                                          );

		  x_errbuf := 'BPEL CDH Sync is Down at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.'||l_error_message;
                 -- x_retcode := 2;
                  fnd_file.put_line (fnd_file.log, 'BPEL CDH Sync is Down at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.');
      ELSE
              fnd_file.put_line (fnd_file.log, 'BPEL CDH Sync Running Successfully at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.');
      END IF;


      l_process_entity  := 'HZ_ORG_CONTACTS';
      l_process_osr     := l_org_contact_osr;
      l_last_update     := NULL;

      OPEN  l_org_contact_cur;
      FETCH l_org_contact_cur INTO l_last_update;
      CLOSE l_org_contact_cur;

      IF SYSDATE - l_last_update > l_check_minutes or l_last_update IS NULL
      THEN
		l_email_alert_count  := l_email_alert_count +1;

                 xx_cdh_send_email_proc(
                                            p_mail_server	=>   p_mail_server
                                          , p_mail_from		=>   p_mail_from
                                          , p_from_title	=>   p_from_title
                                          , p_subject		=>   l_subject
					  , p_page_flag         =>   p_page_flag
					  , p_entity_name       =>   l_process_entity
					  , p_osr		=>   l_process_osr
					  , x_return_status     =>   l_return_status
					  , x_error_message     =>   l_error_message
                                          );

		  x_errbuf := 'BPEL CDH Sync is Down at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.'||l_error_message;
                 -- x_retcode := 2;
                  fnd_file.put_line (fnd_file.log, 'BPEL CDH Sync is Down at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.');
      ELSE
              fnd_file.put_line (fnd_file.log, 'BPEL CDH Sync Running Successfully at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.');
      END IF;


      l_process_entity  := 'HZ_CONTACT_POINTS';
      l_process_osr     := l_phone_contact_osr;
      l_last_update     := NULL;

      OPEN  l_contact_point_cur(l_phone_contact_osr);
      FETCH l_contact_point_cur INTO l_last_update;
      CLOSE l_contact_point_cur;

      IF SYSDATE - l_last_update > l_check_minutes or l_last_update IS NULL
      THEN

		l_email_alert_count  := l_email_alert_count +1;

                 xx_cdh_send_email_proc(
                                            p_mail_server	=>   p_mail_server
                                          , p_mail_from		=>   p_mail_from
                                          , p_from_title	=>   p_from_title
                                          , p_subject		=>   l_subject
					  , p_page_flag         =>   p_page_flag
					  , p_entity_name       =>   l_process_entity
					  , p_osr		=>   l_process_osr
					  , x_return_status     =>   l_return_status
					  , x_error_message     =>   l_error_message
                                          );

		  x_errbuf := 'BPEL CDH Sync is Down at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.'||l_error_message;
                --  x_retcode := 2;
                  fnd_file.put_line (fnd_file.log, 'BPEL CDH Sync is Down at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.');
      ELSE
              fnd_file.put_line (fnd_file.log, 'BPEL CDH Sync Running Successfully at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.');
      END IF;

      l_process_entity  := 'HZ_CONTACT_POINTS';
      l_process_osr     := l_email_contact_osr;
      l_last_update     := NULL;

      OPEN  l_contact_point_cur(l_email_contact_osr);
      FETCH l_contact_point_cur INTO l_last_update;
      CLOSE l_contact_point_cur;

      IF SYSDATE - l_last_update > l_check_minutes or l_last_update IS NULL
      THEN
      		l_email_alert_count  := l_email_alert_count +1;

                 xx_cdh_send_email_proc(
                                            p_mail_server	=>   p_mail_server
                                          , p_mail_from		=>   p_mail_from
                                          , p_from_title	=>   p_from_title
                                          , p_subject		=>   l_subject
					  , p_page_flag         =>   p_page_flag
					  , p_entity_name       =>   l_process_entity
					  , p_osr		=>   l_process_osr
					  , x_return_status     =>   l_return_status
					  , x_error_message     =>   l_error_message
                                          );

		  x_errbuf := 'BPEL CDH Sync is Down at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.'||l_error_message;
                  --x_retcode := 2;
                  fnd_file.put_line (fnd_file.log, 'BPEL CDH Sync is Down at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.');
      ELSE
              fnd_file.put_line (fnd_file.log, 'BPEL CDH Sync Running Successfully at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.');
      END IF;

      l_process_entity  := 'XX_EXTERNAL_USERS';
      l_process_osr     := l_web_contact_osr;
      l_last_update     := NULL;

      OPEN  l_external_user_cur;
      FETCH l_external_user_cur INTO l_last_update;
      CLOSE l_external_user_cur;

      IF SYSDATE - l_last_update > l_check_minutes or l_last_update IS NULL
      THEN

		l_email_alert_count  := l_email_alert_count +1;

                 xx_cdh_send_email_proc(
                                            p_mail_server	=>   p_mail_server
                                          , p_mail_from		=>   p_mail_from
                                          , p_from_title	=>   p_from_title
                                          , p_subject		=>   l_subject
					  , p_page_flag         =>   p_page_flag
					  , p_entity_name       =>   l_process_entity
					  , p_osr		=>   l_process_osr
					  , x_return_status     =>   l_return_status
					  , x_error_message     =>   l_error_message
                                          );

		  x_errbuf := 'BPEL CDH Sync is Down at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.'||l_error_message;
                  --x_retcode := 2;
                  fnd_file.put_line (fnd_file.log, 'BPEL CDH Sync is Down at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.');
      ELSE
              fnd_file.put_line (fnd_file.log, 'BPEL CDH Sync Running Successfully at the Entity '||l_process_entity||
		              ' for the OSR '||l_process_osr||'.');
      END IF;

      l_process_entity  := 'XX_CDH_CUST_ACCT_EXT_B';
      l_process_osr     := l_spc_card_num;
      l_last_update     := NULL;

      OPEN  l_attr_group_cur;
      FETCH l_attr_group_cur INTO l_attr_group_id;
      CLOSE l_attr_group_cur;

      IF l_cust_acct_id IS NOT NULL and l_attr_group_id IS NOT NULL
      THEN
	   OPEN  l_spc_extn_attbt_cur;
	   FETCH l_spc_extn_attbt_cur INTO l_last_update;
	   CLOSE l_spc_extn_attbt_cur;

	      IF SYSDATE - l_last_update > l_check_minutes or l_last_update IS NULL
	      THEN

		l_email_alert_count  := l_email_alert_count +1;

			 xx_cdh_send_email_proc(
						    p_mail_server	=>   p_mail_server
						  , p_mail_from		=>   p_mail_from
						  , p_from_title	=>   p_from_title
						  , p_subject		=>   l_subject
						  , p_page_flag         =>   p_page_flag
						  , p_entity_name       =>   l_process_entity
						  , p_osr		=>   l_process_osr
						  , x_return_status     =>   l_return_status
						  , x_error_message     =>   l_error_message
						  );

			  x_errbuf := 'BPEL CDH Sync is Down at the Entity '||l_process_entity||
				      ' for the OSR '||l_process_osr||'.'||l_error_message;
			  --x_retcode := 2;
			  fnd_file.put_line (fnd_file.log, 'BPEL CDH Sync is Down at the Entity '||l_process_entity||
				      ' for the OSR '||l_process_osr||'.');
	      ELSE
		      fnd_file.put_line (fnd_file.log, 'BPEL CDH Sync Running Successfully at the Entity '||l_process_entity||
				      ' for the OSR '||l_process_osr||'.');
	      END IF;

      ELSE
       	     x_errbuf := 'Customer Account Does not exist or Extensible Attribute Group Does not exist';

	     fnd_file.put_line (fnd_file.log, 'Customer Account Does not exist or Extensible Attribute Group Does not exist');

      END IF;

      IF  l_email_alert_count  >= 7
      THEN

	 xx_cdh_send_email_proc(
				    p_mail_server	=>   p_mail_server
				  , p_mail_from		=>   p_mail_from
				  , p_from_title	=>   p_from_title
				  , p_subject		=>   l_subject
				  , p_page_flag         =>   'PAGE'
				  , p_entity_name       =>   NULL
				  , p_osr		=>   NULL
				  , x_return_status     =>   l_return_status
				  , x_error_message     =>   l_error_message
				  );

	  x_errbuf := 'BPEL CDH Sync is Down at all the Entity.'||l_error_message;
	  --x_retcode := 2;
	  fnd_file.put_line (fnd_file.log, 'BPEL CDH Sync is Down at all the Entity.');

      END IF;



   EXCEPTION
     WHEN AOPS_DOWN_NO_ALERT THEN
	fnd_file.put_line (fnd_file.log,'AOPS is Down. No need to raise the Alert');
	x_errbuf := 'AOPS is Down. No need to raise the Alert';
     WHEN OTHERS THEN
	fnd_file.put_line (fnd_file.log,'UnExpected Error Occured In the Procedure - xx_cdh_raise_alert_proc : ' || SQLERRM);
	x_errbuf := 'UnExpected Error Occured In the Procedure - xx_cdh_raise_alert_proc : ' || SQLERRM;
	x_retcode := 2;
END xx_cdh_raise_alert_proc;

PROCEDURE xx_cdh_send_email_proc(
                                            p_mail_server	IN            VARCHAR2
                                          , p_mail_from		IN            VARCHAR2
                                          , p_from_title	IN            VARCHAR2
                                          , p_subject		IN            VARCHAR2
					  , p_page_flag         IN            VARCHAR2
					  , p_entity_name       IN            VARCHAR2
					  , p_osr		IN            VARCHAR2
					  , x_return_status     OUT  NOCOPY   VARCHAR2
					  , x_error_message     OUT  NOCOPY   VARCHAR2
                                          )

 IS

 mail_con                 utl_smtp.connection;
 l_subject                VARCHAR2(100);
 l_mail_to                VARCHAR2(2000);
 l_one_mail               VARCHAR2(2000);
 l_last_update            DATE;
 l_alert_email_list       VARCHAR2(2000);
 END_PROGRAME             EXCEPTION;
 l_alert_flag             VARCHAR2(25);
 l_alert_severity         VARCHAR2(25);

 CURSOR l_alert_emails_cur IS
 SELECT ffv.flex_value
 FROM   fnd_flex_value_sets fvs,fnd_flex_values ffv
 WHERE  fvs.flex_value_set_id   = ffv.flex_value_set_id
 AND    fvs.flex_value_set_name = 'XXOD_CDH_BPEL_ALERT_EMAILS'
 AND    ffv.enabled_flag        = 'Y';

 BEGIN
      x_return_status := 'S';

      l_subject         := p_subject;
      l_alert_flag      := NVL(fnd_profile.value('XXOD_CDH_BPEL_EMAIL_ALERT'),'N');
      l_alert_severity  := NVL(fnd_profile.value('XXOD_CDH_BPEL_ALERT_SEVERITY'),'N');

      dbms_output.put_line('l_alert_flag '||l_alert_flag);
      dbms_output.put_line('l_alert_severity '||l_alert_severity);

      IF l_alert_flag <> 'Y'
      THEN
           RAISE END_PROGRAME;
      END IF;

      mail_con := utl_smtp.open_connection(p_mail_server, 25); -- SMTP on port 25
      utl_smtp.helo(mail_con, p_mail_server);
      utl_smtp.mail(mail_con, p_mail_from);

      FOR I IN l_alert_emails_cur
      LOOP
          l_alert_email_list := l_alert_email_list || I.flex_value || ';';
      END LOOP;

      l_mail_to := l_alert_email_list;


      WHILE TRIM(l_mail_to) IS NOT NULL
      LOOP
          l_one_mail := substr(l_mail_to,0,instr(l_mail_to,';')-1);
          IF TRIM(l_one_mail) IS NOT NULL THEN
             utl_smtp.rcpt(mail_con, TRIM(l_one_mail));
          END IF;
          l_mail_to := substr(l_mail_to,instr(l_mail_to,';')+1);
      END LOOP;


      IF p_page_flag = 'Y' or l_alert_severity = 'Y' or p_page_flag = 'PAGE' THEN
          l_subject := '***page***' || l_subject;
      END IF;
      IF p_page_flag = 'PAGE'
      THEN
	      utl_smtp.data(mail_con,'From: ' || NVL(p_from_title,'BPEL CDH Sync Alert') || utl_tcp.crlf ||
			  'To: ' || l_alert_email_list || utl_tcp.crlf ||
			  'Subject: ' || l_subject ||
			  utl_tcp.crlf || 'BPEL CDH Sync Appears to be Down at all the Entity.'||
			  'Please Look into this.' || utl_tcp.crlf ||
			  'This is an Auto Generated Email From CDH-BPEL Sync Monitoring Program. Please DO NOT Reply to this Email.');
      ELSE
	      utl_smtp.data(mail_con,'From: ' || NVL(p_from_title,'BPEL CDH Sync Alert') || utl_tcp.crlf ||
			  'To: ' || l_alert_email_list || utl_tcp.crlf ||
			  'Subject: ' || l_subject ||
			  utl_tcp.crlf || 'BPEL CDH Sync Appears to be Down at the Entity '||p_entity_name||
			  ' for the OSR '||p_osr ||'. Please Look into this.' || utl_tcp.crlf ||
			  'This is an Auto Generated Email From CDH-BPEL Sync Monitoring Program. Please DO NOT Reply to this Email.');
      END IF;
  utl_smtp.quit(mail_con);

  fnd_file.put_line (fnd_file.log, 'Alert Email Sent Successfully To:'||l_alert_email_list);

   EXCEPTION
     WHEN END_PROGRAME
     THEN
	fnd_file.put_line (fnd_file.log,'The profile XXOD_CDH_BPEL_EMAIL_ALERT is not enabled to send Email Alart');
     WHEN OTHERS THEN
	fnd_file.put_line (fnd_file.log,'UnExpected Error Occured In the Procedure - xx_cdh_send_email_proc : ' || SQLERRM);
	x_error_message := 'UnExpected Error Occured In the Procedure - xx_cdh_send_email_proc : ' || SQLERRM;
	x_return_status := 'E';
END xx_cdh_send_email_proc;


PROCEDURE email_rep_errors (
      x_errbuf    OUT NOCOPY  VARCHAR2,
      x_retcode   OUT         NUMBER
) AS

  cursor  c_reps  IS
  select  PARTY_SITE_ORIG_SYS_REFERENCE, error_Text
  from	  XXOD_HZ_SUMMARY
  where	  batch_id = -2000
  and	  status = 'A';
  
  cursor  c_email IS
  select  source_value1
  from    XX_FIN_TRANSLATEVALUES
  where   translate_id IN (
          select  translate_id
          from    XX_FIN_TRANSLATEDEFINITION
          where   translation_name = 'OD_BPEL_REP_EMAIL_ALERT' )
  AND     NVL(SOURCE_VALUE2,'Y') = 'Y';

  l_last_verified_date	  DATE;
  l_last_verified_char    VARCHAR2(20);
  l_email_list            VARCHAR2(4000);

-- email

  l_mailhost              VARCHAR2(64) := FND_PROFILE.VALUE('XX_CS_SMTP_SERVER');
  l_from                  VARCHAR2(64) := 'CRM_CONVERSIONS@OfficeDepot.com';
  l_subject               VARCHAR2(64) := 'BPEL SYNC Missing Sales Rep Error List';
  l_mail_conn             UTL_SMTP.connection;

  l_job_type              VARCHAR2(40);
  l_email_options_flag    VARCHAR2(1);
  l_success               boolean;
  l_sysdate               DATE;
 -- l_temp                  varchar2(32767) default null;
   l_temp                  CLOB := empty_clob;
  l_body_html             clob := empty_clob;
  l_boundary              varchar2(255) default 'a1b2c3d4e3f2g1';
  l_offset                number :=0;
  --l_html                  varchar2(32767);
   l_html                  CLOB := empty_clob;
  l_amount                number;
  l_count                 NUMBER :=0 ;
  l_crlf                  CHAR(2) := CHR(13)||CHR(10);
  
begin
  --dbms_output.put_line('begin of procedure');
      
  select	sysdate into l_sysdate from dual;

  l_mail_conn := UTL_SMTP.open_connection(l_mailhost, 25);
  UTL_SMTP.helo(l_mail_conn, l_mailhost);
  UTL_SMTP.mail(l_mail_conn, l_from);
  
  for email_rec IN c_email loop
             UTL_SMTP.rcpt(l_mail_conn, email_rec.source_value1);
             l_email_list := l_email_list || email_rec.source_value1 || ';';      
        end loop;
 -- dbms_output.put_line('value of l_email_list ' || l_email_list);
      --  UTL_SMTP.rcpt(l_mail_conn, l_email_list);
  
  l_temp := l_temp || 'MIME-Version: 1.0' ||  chr(13) || chr(10);
  l_temp := l_temp || 'To: ' ||  l_email_list || chr(13) || chr(10);
  l_temp := l_temp || 'From: ' || l_from || chr(13) || chr(10);
  l_temp := l_temp || 'Subject: ' || l_subject || chr(13) || chr(10);
  l_temp := l_temp || 'Reply-To: ' || l_from ||  chr(13) || chr(10);
  l_temp := l_temp || 'Content-Type: multipart/alternative; boundary=' || 
                         chr(34) || l_boundary ||  chr(34) || chr(13) || 
                         chr(10);
   ----------------------------------------------------
  -- Write the headers
  dbms_lob.createtemporary( l_body_html, false, 10 );
  dbms_lob.write(l_body_html,length(l_temp),1,l_temp);
   ----------------------------------------------------
    -- Write the text boundary
  l_offset := dbms_lob.getlength(l_body_html) + 1;
  l_temp   := '--' || l_boundary || chr(13)||chr(10);
  l_temp   := l_temp || 'content-type: text/plain; charset=us-ascii' || 
                  chr(13) || chr(10) || chr(13) || chr(10);
  dbms_lob.write(l_body_html,length(l_temp),l_offset,l_temp);
    
    ----------------------------------------------------
    --  Write the plain text portion of the email
    --  l_offset := dbms_lob.getlength(l_body_html) + 1;
    --  dbms_lob.write(l_body_html,length(p_text),l_offset,p_text);
    ----------------------------------------------------
    -- Write the HTML boundary
  l_temp   := chr(13)||chr(10)||chr(13)||chr(10)||'--' || l_boundary || 
                    chr(13) || chr(10);
  l_temp   := l_temp || 'content-type: text/html;' || 
                   chr(13) || chr(10) || chr(13) || chr(10);
  l_offset := dbms_lob.getlength(l_body_html) + 1;
  dbms_lob.write(l_body_html,length(l_temp),l_offset,l_temp);
    
--      UTL_SMTP.open_data(lc_mail_conn);
--	UTL_SMTP.WRITE_DATA(lc_mail_conn,'Date: '  ||TO_CHAR(SYSDATE,'DD MON RRRR hh24:mi:ss')||utl_tcp.CRLF);
--	UTL_SMTP.WRITE_DATA(lc_mail_conn,'From: '  ||lc_from||utl_tcp.CRLF);
--	UTL_SMTP.WRITE_DATA(lc_mail_conn,'To: '    ||p_mail_to||utl_tcp.CRLF);

    fnd_file.put_line(fnd_file.output,'<html><body><table border=1>');
    
     l_offset := dbms_lob.getlength(l_body_html) + 1;
        
        
    
    l_html := l_html ||  '<html><body><table border=1>';
    fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> OSR </TD><TD bgcolor=#6D7B8D><b><font color = white> ERROR
</TD></TR>');
    l_html := l_html ||  '<TR><TD bgcolor=#6D7B8D><b><font color = white> OSR </TD><TD bgcolor=#6D7B8D><b><font color = white> ERROR
</TD></TR>';
dbms_lob.write(l_body_html,length(l_html),l_offset,l_html );

   --dbms_output.put_line('outside for');
    for rec_recps IN c_reps  loop
   -- dbms_output.put_line('inside for');
          -- partySiteOrigSysReference, errorText
        fnd_file.put_line(fnd_file.output,'<TR><TD> ' || rec_recps.PARTY_SITE_ORIG_SYS_REFERENCE  || '</TD><TD>' || rec_recps.error_Text || '</TD></TR>');
        l_html :=  '<TR><TD> ' || rec_recps.PARTY_SITE_ORIG_SYS_REFERENCE  || '</TD><TD>' || substr(rec_recps.error_Text,1,instr(rec_recps.error_Text,'.',-1,2)) || '</TD></TR>';
        l_offset := dbms_lob.getlength(l_body_html) + 1;
        dbms_lob.write(l_body_html,length(l_html),l_offset,l_html );
        l_count := l_count + 1;
        --  dbms_output.put_line('value of count is ' || nvl(l_count,0));
    end loop;
 --dbms_output.put_line('value of count is ' || l_count);
    IF l_count > 0  THEN
  --  dbms_output.put_line('inside count' );
        fnd_file.put_line(fnd_file.output,'</table></body></html>');
        l_html :=  '</table></body></html>';
            
               -- dbms_output.put_line('wite html' );
        ----------------------------------------------------
        -- Write the HTML portion of the message
        l_offset := dbms_lob.getlength(l_body_html) + 1;
        
     --   dbms_output.put_line( ' value of l_offset is ' || l_offset );
      --  DBMS_OUTPUT.put_line(' length of l_html is ' || length(l_html) );
        dbms_lob.write(l_body_html,length(l_html),l_offset,l_html );
    
        ----------------------------------------------------
      --  dbms_output.put_line('wite final html') ;
        -- Write the final html boundary
        l_temp   := chr(13) || chr(10) || '--' ||  l_boundary || '--' || chr(13);
        l_offset := dbms_lob.getlength(l_body_html) + 1;
        dbms_lob.write(l_body_html,length(l_temp),l_offset,l_temp);
        
        ----------------------------------------------------
        -- Send the email in 1900 byte chunks to UTL_SMTP
        l_offset  := 1;
        l_amount := 1900;
        
        --dbms_output.put_line('before open') ;    
        UTL_SMTP.open_data(l_mail_conn);
        while l_offset < dbms_lob.getlength(l_body_html) loop
            utl_smtp.write_data(l_mail_conn,dbms_lob.substr(l_body_html,l_amount,l_offset));
            l_offset  := l_offset + l_amount ;
            l_amount := least(1900,dbms_lob.getlength(l_body_html) - l_amount);
        end loop;
        --dbms_output.put_line('after while') ;  
        UTL_SMTP.close_data(l_mail_conn);    
    END IF;

    UTL_SMTP.quit(l_mail_conn);
    dbms_lob.freetemporary(l_body_html);
      
     -- update the status to 'I' for batches related to this process
    update   xxod_hz_summary
    set      status = 'I'
    where    batch_id in (-1000,-2000)
    AND      status = 'A';
    
    commit;

exception when others then
    fnd_file.put_line(fnd_file.log,'failed in email_rep_errors with error: ' || sqlerrm);
    x_errbuf := 'failed in email_rep_errors with error: ' || sqlerrm;
    x_retcode := 2;
END email_rep_errors;


PROCEDURE store_rep_asmnts (
      x_errbuf    OUT NOCOPY  VARCHAR2,
      x_retcode   OUT   NUMBER
   ) AS

CURSOR  c_min_party_site(p_last_extract_date DATE)  IS
select  min(party_site_id)
from    hz_party_sites
where   trunc(creation_date) = p_last_extract_date;   

CURSOR  c_missing_asmnts(p_party_site_id HZ_PARTY_SITES.party_site_id%TYPE) IS
select  hzps.party_site_id ,
        hzps.orig_system_reference,  
        substr(hzps.orig_system_reference, 1, (instr(hzps.orig_system_reference, '-', 1, 1) - 1)) account,  
        loc.country country  
from    hz_party_sites hzps, hz_parties hzp, hz_locations loc,   
        hz_cust_accounts HCA, hz_cust_acct_sites_all HCAS  
where   hzp.party_type  = 'ORGANIZATION'  
  and   hzp.attribute13 = 'CUSTOMER'  
  and   hzps.party_id   = hzp.party_id  
  and   hzps.party_site_id > p_party_site_id
  and   loc.location_id = hzps.location_id  
  -- donot filter on country
  --and   loc.country = 'US'  
  and   HCAS.cust_account_id = HCA.cust_account_id  
  and   NVL(HCA.customer_type, 'X') <> 'I'  
  AND   HCA.attribute18 = 'CONTRACT'  
  AND   HCA.status='A'  
  AND   HCAS.status ='A'  
  AND   HCA.status = HCAS.status  
  AND   HCAS.party_site_id = hzps.party_site_id  
  and   not exists (
                    SELECT  1  
                    FROM    xx_tm_nam_terr_defn          TERR  
                            , xx_tm_nam_terr_entity_dtls TERR_ENT  
                            , xx_tm_nam_terr_rsc_dtls    TERR_RSC  
                    WHERE   TERR.named_acct_terr_id = TERR_ENT.named_acct_terr_id  
                    AND     TERR.named_acct_terr_id = TERR_RSC.named_acct_terr_id  
                    AND     SYSDATE between TERR.start_date_active AND NVL(TERR.end_date_active,SYSDATE)  
                    AND     SYSDATE between TERR_ENT.start_date_active AND NVL(TERR_ENT.end_date_active,SYSDATE)  
                    AND     SYSDATE between TERR_RSC.start_date_active AND NVL(TERR_RSC.end_date_active,SYSDATE)  
                    AND     NVL(TERR.status,'A')     = 'A'  
                    AND     NVL(TERR_ENT.status,'A') = 'A'  
                    AND     NVL(TERR_RSC.status,'A') = 'A'  
                    AND     TERR_ENT.entity_type = 'PARTY_SITE'  
                    AND     TERR_ENT.entity_id = hzps.party_site_id  
                 );
                 
TYPE   t_party_site is table of hz_party_sites.party_site_id%type INDEX BY PLS_INTEGER;
tab_party_site t_party_site;
TYPE   t_party_site_OSR is table of HZ_PARTY_SITES.orig_system_reference%TYPE INDEX BY PLS_INTEGER;
tab_party_site_osr t_party_site_OSR;
TYPE   t_party_osr is table of HZ_PARTIES.orig_system_reference%TYPE INDEX BY PLS_INTEGER;
tab_party_osr t_party_osr;
TYPE   t_country is table of HZ_LOCATIONS.country%type INDEX BY PLS_INTEGER;
tab_country t_country;

l_last_verified_char  varchar2(50);
l_min_party_site_id   HZ_PARTY_SITES.party_site_id%TYPE;
l_last_verified_date  DATE;
l_limit               NUMBER := 500;
l_rows_exist          boolean := false;
l_success             boolean;
l_sysdate             DATE;

-- business event data
l_key                                   VARCHAR2(240);
l_event                                 VARCHAR2(240);
l_data                                  CLOB := NULL;
l_list                                  WF_PARAMETER_LIST_T;

BEGIN   

  fnd_profile.get('OD_BPEL_REP_DATE', l_last_verified_char);
  l_last_verified_date := nvl(to_date(l_last_verified_char,'DD-MON-YYYY'),trunc(SYSDATE));
  
  select  trunc(sysdate) into l_sysdate from dual;

  open c_min_party_site(trunc(l_last_verified_date));
    IF c_min_party_site%notfound THEN
      l_min_party_site_id := 1000;
    ELSE
      fetch c_min_party_site into l_min_party_site_id;  
    end if;
  close c_min_party_site;
    
  OPEN c_missing_asmnts(l_min_party_site_id);
  LOOP
--    FETCH c_missing_asmnts bulk collect into l_asmnts_table limit l_limit;
    FETCH c_missing_asmnts bulk collect into  tab_party_site ,
                                              tab_party_site_osr,
                                              tab_party_osr,
                                              tab_country limit l_limit;
                                          
    IF tab_party_site.count > 0 THEN
      FORALL i IN tab_party_site.FIRST..tab_party_site.LAST 
      insert  into  XXOD_HZ_SUMMARY (
      SUMMARY_ID,
      BATCH_ID,
      OWNER_TABLE_ID,
      PARTY_SITE_ORIG_SYS_REFERENCE,
      ACCOUNT_ORIG_SYSTEM_REFERENCE,
      COUNTRY,
      STATUS
      )  values
      (
        TO_NUMBER(to_char(sysdate,'DDMMYYHHMI')),
        -1000,
        tab_party_site(i) ,
        tab_party_site_osr(i),
        tab_party_osr(i),
        tab_country(i),
        'A'
      );
      
      l_rows_exist := true;

  END IF;
    
    EXIT WHEN tab_party_site.count < l_limit;
  END LOOP;
  
  CLOSE c_missing_asmnts;
    
  IF l_rows_exist  THEN
  --  raise business event
  l_key := HZ_EVENT_PKG.item_key( 'od.crm.bpel.rep.notify' );
  l_event := HZ_EVENT_PKG.event('od.crm.bpel.rep.notify'); 

  Wf_Event.Raise
        ( p_event_name   =>  l_event,
          p_event_key    =>  l_key,
          p_parameters   =>  l_list,
          p_event_data   =>  l_data);
          
  fnd_file.put_line(fnd_file.log,'Business Event Raised ' );     
 -- DBMS_OUTPUT.PUT_LINE('Business Event Raised ' );    
  END IF;
  
  	l_success := fnd_profile.save(X_NAME  => 'OD_BPEL_REP_DATE',
                  X_VALUE => TO_CHAR(l_sysdate,'DD-MON-YYYY'),
                  X_LEVEL_NAME => 'SITE' );

	IF(l_success) THEN
   		fnd_file.put_line(fnd_file.log, 'profile value set for OD_BPEL_REP_DATE');
 	ELSE
  	 	fnd_file.put_line(fnd_file.log, 'failure setting profile valuefor OD_BPEL_REP_DATE');
 	END IF;
        
EXCEPTION WHEN OTHERS THEN
   fnd_file.put_line(fnd_file.log,'Error in store_rep_asmnts: SQLERRM '|| sqlerrm );
   x_errbuf := 'Error in store_rep_asmnts: SQLERRM '|| sqlerrm;
   x_retcode := 2;
END store_rep_asmnts;

PROCEDURE raise_rep_error_event (
      x_errbuf      OUT   NOCOPY VARCHAR2,
      x_retcode     OUT   NUMBER,
      p_datetime    IN    VARCHAR2
   ) IS

-- business event data
l_key                                   VARCHAR2(240);
l_event                                 VARCHAR2(240);
l_data                                  CLOB := NULL;
l_list                                  WF_PARAMETER_LIST_T;

BEGIN

  l_key := HZ_EVENT_PKG.item_key( 'od.crm.bpel.rep.notify' );
  l_event := HZ_EVENT_PKG.event('od.crm.bpel.rep.notify'); 
  l_data  := p_datetime;

  Wf_Event.Raise
        ( p_event_name   =>  l_event,
          p_event_key    =>  l_key,
          p_parameters   =>  l_list,
          p_event_data   =>  l_data);
          
  fnd_file.put_line(fnd_file.log,'Business Event Raised ' );        
   
EXCEPTION WHEN OTHERS THEN

   fnd_file.put_line(fnd_file.log,'Error in raise_rep_error_event: SQLERRM '|| sqlerrm );
   x_errbuf := 'Error in raise_rep_error_event: SQLERRM '|| sqlerrm;
   x_retcode := 2;
END raise_rep_error_event;

PROCEDURE schedule_rep_event_cp (
      x_errbuf       OUT   NOCOPY VARCHAR2,
      x_retcode      OUT   NUMBER,
      p_datetime     IN    DATE
   ) IS

l_sub_request_id  NUMBER ;
l_message         VARCHAR2(1000);   
l_count           NUMBER ;
l_min             NUMBER;
BEGIN

  select  count(1) into l_count
  from    xxod_hz_summary
  where   batch_id = -1000
  and     status = 'A';
  
  select  greatest(l_count*2,30) into l_min from dual;
  
  l_sub_request_id := FND_REQUEST.SUBMIT_REQUEST(
                            application => 'XXCRM',
                            program     =>'OD_CRM_BPEL_REP_ERROR_EVENT',
                            start_time  => TO_CHAR( SYSDATE + l_min*1/(24*60), 'DD-MON-YY HH24:MI:SS' ),
                            argument1   => to_char(trunc(p_datetime),'YYYY-MM-DD') || 'T' || TO_CHAR(p_datetime,'HH24:MI:SS') || '-04:00'
                            );

  IF l_sub_request_id = 0 THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR SUBMITTING PROGRAM');
        FND_MESSAGE.RETRIEVE(l_message);
        x_retcode := 2;
        RETURN;
  ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'SUCCESS SUBMITTING PROGRAM - Request ID: ' || l_sub_request_id);
        x_retcode := 0;
  END IF;

  fnd_file.put_line(fnd_file.log,'Business Event Raised ' );        
   
EXCEPTION WHEN OTHERS THEN

    fnd_file.put_line(fnd_file.log,'Error in schedule_rep_event_cp: SQLERRM '|| sqlerrm );
    x_retcode := 2;
    x_errbuf := 'Error in schedule_rep_event_cp: SQLERRM '|| sqlerrm;
   
END schedule_rep_event_cp;

END xx_cdh_bpel_sync_alert_pkg;
/
SHOW ERRORS