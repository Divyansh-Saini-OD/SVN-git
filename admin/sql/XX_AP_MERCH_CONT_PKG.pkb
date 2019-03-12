SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_MERCH_CONT_PKG

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE BODY XX_AP_MERCH_CONT_PKG
IS
-- +=====================================================================================================+
-- |                              Office Depot                                                           |
-- +=====================================================================================================+
-- | Name        :  XX_AP_MERCH_CONT_PKG                                                                 |
-- |                                                                                                     |
-- | Description :  Package to Create the AP Merch Contact Details using webadi                          |
-- | Rice ID     :                                                                                       |
-- |Change Record:                                                                                       |
-- |===============                                                                                      |
-- |Version   Date         Author           Remarks                                                      |
-- |=======   ==========   =============    ======================                                       |
-- | 1.0      07-Jul-2017  Havish Kasina    Initial Version                                              |
-- | 1.1      12-Mar-2019  Shanti Sethuraj  Added Instance name in email subject for the jira NAIT-87654  |                                
-- +=====================================================================================================+
g_proc              VARCHAR2(80) := NULL;
g_debug             VARCHAR2(1)  := 'N';
gc_success          VARCHAR2(100)   := 'SUCCESS';
gc_failure          VARCHAR2(100)   := 'FAILURE';
gn_request_id       NUMBER;

-- +======================================================================+
-- | Name             : log_debug_msg                                     |
-- | Description      :                                                   |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      07-Jul-2017  Havish Kasina    Initial Version               |
-- +======================================================================+

PROCEDURE log_debug_msg ( p_debug_msg          IN  VARCHAR2 )
IS
 ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.LOGIN_ID;
 ln_user_id           FND_USER.USER_ID%TYPE  := FND_GLOBAL.USER_ID;
 lc_user_name         FND_USER.USER_NAME%TYPE  := FND_GLOBAL.USER_NAME;

BEGIN
  
  IF (g_debug = 'Y') THEN
    XX_COM_ERROR_LOG_PUB.log_error
      (
         p_return_code             => FND_API.G_RET_STS_SUCCESS
        ,p_msg_count               => 1
        ,p_application_name        => 'XXFIN'
        ,p_program_type            => 'LOG'             
        ,p_attribute15             => 'XX_AP_MERCH_CONT_PKG'      
        ,p_attribute16             => g_proc
        ,p_program_id              => 0                    
        ,p_module_name             => 'AP'      
        ,p_error_message           => p_debug_msg
        ,p_error_message_severity  => 'LOG'
        ,p_error_status            => 'ACTIVE'
        ,p_created_by              => ln_user_id
        ,p_last_updated_by         => ln_user_id
        ,p_last_update_login       => ln_login
        );
    FND_FILE.PUT_LINE(FND_FILE.log, p_debug_msg);
  END IF;
END log_debug_msg;
-- +======================================================================+
-- | Name             : log_error                                         |
-- | Description      :                                                   |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      07-Jul-2017  Havish Kasina    Initial Version               |
-- +======================================================================+

PROCEDURE log_error ( p_error_msg          IN  VARCHAR2 )
IS
 ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.LOGIN_ID;
 ln_user_id           FND_USER.USER_ID%TYPE  := FND_GLOBAL.USER_ID;
 lc_user_name         FND_USER.USER_NAME%TYPE  := FND_GLOBAL.USER_NAME;
 
BEGIN
  
  XX_COM_ERROR_LOG_PUB.log_error
      (
       p_return_code             => FND_API.G_RET_STS_SUCCESS
      ,p_msg_count               => 1
      ,p_application_name        => 'XXFIN'
      ,p_program_type            => 'ERROR'             
      ,p_attribute15             => 'XX_AP_MERCH_CONT_PKG'      
      ,p_attribute16             => g_proc
      ,p_program_id              => 0                    
      ,p_module_name             => 'AP'      
      ,p_error_message           => p_error_msg
      ,p_error_message_severity  => 'MAJOR'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      );
  FND_FILE.PUT_LINE(FND_FILE.LOG, p_error_msg);    

END log_error;

-- +=====================================================================+
-- | Name  : insert_stg_table                                            |
-- | Description     : The insert stg table inserts the records into     |
-- |                   xx_ap_merch_contacts from xx_ap_merch_cont_stg    |
-- | Parameters      :                                                   |
-- +=====================================================================+

PROCEDURE insert_stg_table(  x_return_status   OUT    VARCHAR2 )

  AS
  BEGIN   
    x_return_status := null;
    INSERT INTO xx_ap_merch_contacts(dept,
                                     dept_name,
		                             vp, 
                                     dmm, 
									 channel,  
									 scm, 
									 cm, 
									 acm, 
									 ca, 
									 repl_plannaer,
									 enabled_flag,
									 request_id,
									 creation_date,
									 created_by,
									 last_update_date,
									 last_updated_by)
	                    SELECT       dept,
						             dept_name,
						             vp, 
                                     dmm, 
									 channel,  
									 scm, 
									 cm, 
									 acm, 
									 ca, 
									 repl_plannaer,
									 'Y',
									 gn_request_id,
									 creation_date,
									 created_by,
									 last_update_date,
									 last_updated_by
						 FROM        xx_ap_merch_cont_stg
						WHERE        process_flag = 'N'
                          AND        creation_date > = sysdate -1						   
									 ;
    log_debug_msg( SQL%ROWCOUNT ||' Row(s) inserted in xx_ap_merch_contacts');
    COMMIT;
    x_return_status := gc_success;
  EXCEPTION
    WHEN OTHERS
    THEN
      x_return_status := gc_failure;
      log_error('Error Inserting into Staging table xx_ap_merch_contacts '||substr(sqlerrm,1,100));
  END INSERT_stg_table;

  -- +===================================================================+
  -- | Name  : fetch_data                                                |
  -- | Description     : The fetch_data procedure will fetch data from   |
  -- |                   WEBADI to XX_AP_MERCH_CONT_STG table            |
  -- |                                                                   |
  -- | Parameters      : p_dept                                          |
  -- |                   p_dept_name                                     |
  -- |                   p_vp                                            |
  -- |                   p_dmm                                           |
  -- |                   p_channel                                       |
  -- |                   p_scm                                           |
  -- |                   p_cm                                            |
  -- |                   p_acm                                           |
  -- |                   p_ca                                            |
  -- |                   p_repl_planner                                  |
  -- +===================================================================+                                   
PROCEDURE fetch_data(p_dept        		IN  NUMBER,
                     p_dept_name   		IN  VARCHAR2,
                     p_vp          		IN  VARCHAR2,
                     p_dmm         		IN  VARCHAR2,
					 p_channel     		IN  VARCHAR2,
					 p_scm         		IN  VARCHAR2,
					 p_cm               IN  VARCHAR2,
					 p_acm              IN  VARCHAR2,
					 p_ca               IN  VARCHAR2,
					 p_repl_planner     IN  VARCHAR2
                     ) 
IS
BEGIN 
  g_proc :='FETCH_DATA';
   INSERT INTO XX_AP_MERCH_CONT_STG(dept,        
                                    dept_name, 
                                    vp, 
                                    dmm, 
									channel,  
									scm, 
									cm, 
									acm, 
									ca, 
									repl_plannaer,
									process_flag, 
									creation_date,          
									created_by,        
									last_update_date,          
									last_updated_by,
									last_update_login
                                    )
                            values (p_dept,
									p_dept_name,
									p_vp,
									p_dmm,
									p_channel,
									p_scm,
									p_cm,
									p_acm,
									p_ca,
									p_repl_planner,
                                    'N',
                                    sysdate,
                                    fnd_global.user_id,
                                    sysdate,
                                    fnd_global.user_id,
									fnd_global.login_id
                                   );
   COMMIT;   
EXCEPTION 
WHEN OTHERS THEN        
        log_error('Error Inserting Data into XX_AP_MERCH_CONT_STG '||substr(sqlerrm,1,50));
        Raise_Application_Error (-20343, 'Error inserting the data..'||SQLERRM);
END fetch_data ;

  -- +===================================================================+
  -- | Name  : extract                                                   |
  -- | Description     : The extract procedure is the main               |
  -- |                   procedure that will extract all the unprocessed |
  -- |                   records from XX_AP_MERCH_CONT_STG               |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- +===================================================================+                     
PROCEDURE extract(x_errbuf          OUT NOCOPY     VARCHAR2,
                  x_retcode         OUT NOCOPY     NUMBER) 
IS
   --------------------------------
   -- Local Variable Declaration --
   -------------------------------- 
  lc_err_flag           VARCHAR2(1);
  ln_user_id            fnd_user.user_id%TYPE;
  lc_user_name          fnd_user.user_name%TYPE;
  lc_debug_flag         VARCHAR2(1) := NULL;
  lc_upd_ret_status     VARCHAR2(20);
  ln_count              NUMBER;
  ln_count_stg          NUMBER;

BEGIN
      g_proc :='EXTRACT';
      x_retcode :=0;
	  lc_upd_ret_status := null;
      ln_user_id := NULL;
	  lc_user_name := NULL;
	  ln_count := NULL;
	  ln_count_stg := NULL;
	  
	  gn_request_id := FND_GLOBAL.CONC_REQUEST_ID;
    
	lc_debug_flag := 'Y';
    log_debug_msg ('Debug Flag :'||lc_debug_flag);

    IF (lc_debug_flag = 'Y')
      THEN
         g_debug := 'Y';
    ELSE
         g_debug := 'N';
    END IF; 
    
    ln_user_id := fnd_global.user_id;
    log_debug_msg('Getting the user name ..');
    
    SELECT user_name
    INTO lc_user_name
    FROM fnd_user
    WHERE user_id = ln_user_id;

    log_debug_msg('User Name :'|| lc_user_name);

    fnd_file.put_line(fnd_file.log, 'User id       :'||  ln_user_id);
	
	insert_stg_table(x_return_status  => lc_upd_ret_status);
	 
	IF lc_upd_ret_status = gc_success
	THEN
	   	   UPDATE xx_ap_merch_cont_stg
              SET process_flag  = 'Y'
            WHERE 1 =1 
              AND process_flag  = 'N';
		   fnd_file.put_line(fnd_file.log ,SQL%ROWCOUNT||'  records Updated in the Staging table xx_ap_merch_cont_stg to make the process flag as Y');  
		   COMMIT;
			  
		   DELETE FROM xx_ap_merch_contacts
		    WHERE creation_date <= SYSDATE -60;
		   fnd_file.put_line(fnd_file.log ,SQL%ROWCOUNT||'  records Deleted in the table xx_ap_merch_contacts '); 
           COMMIT;
		   
           UPDATE xx_ap_merch_contacts
              SET enabled_flag = 'N'
            where request_id <> gn_request_id;			  
		   COMMIT;
		   
	END IF;

EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,'AP Merch Contacts creation - Process Ended in Error....'||SQLERRM);
      x_retcode := 2;
END extract;

/* Added the below procedures by Naveen */
PROCEDURE email_merchant(p_errbuf      OUT NOCOPY VARCHAR2,
                         p_return_code OUT NOCOPY VARCHAR2)
IS
  CURSOR parent_req 
  IS
    SELECT priority_request_id
      FROM fnd_concurrent_requests
     WHERE request_id = FND_GLOBAL.CONC_REQUEST_ID;

  l_priority_request_id NUMBER;

  CURSOR req_set 
  IS
    SELECT fnd_global.tab||PROGRAM ||' with Request ID: '||
           TO_CHAR(request_id)||fnd_global.newline
     FROM  fnd_conc_req_summary_v
    WHERE  priority_request_id = l_priority_request_id
    ORDER BY request_id;

  l_request VARCHAR2(1000);
  l_requests VARCHAR2(3000);
  l_email_address VARCHAR2(200);
  v_email_list                     VARCHAR2(2000);
  v_sfile_name                   VARCHAR2(200);
  l_http_request   UTL_HTTP.req;
  l_http_response  UTL_HTTP.resp;
  l_blob           BLOB;
  l_raw            RAW(32767);
  lc_temp_email                VARCHAR2(2000);
  conn utl_smtp.connection;
  v_file VARCHAR2(100);
  instance_name varchar2(50);   --added for jira NAIT-87654
  email_subject varchar2(100);   --added for jira NAIT-87654
  
BEGIN
  ap_debug_pkg.print('Y','AP_XML_INVOICE_INBOUND_PKG.send email(+)');
  fnd_profile.get('AP_NOTIFICATION_EMAIL', l_email_address);
  ap_debug_pkg.print('Y','email address: '||l_email_address);
   lc_temp_email:=get_distribution_list;
  OPEN parent_req;
  FETCH parent_req INTO l_priority_request_id;
  CLOSE parent_req;

  OPEN req_set;
  LOOP
    FETCH req_set INTO l_request;
    EXIT WHEN req_set%notfound;
    IF l_request IS NOT NULL THEN
      l_requests := l_requests || l_request;
    END IF;
  END LOOP;
  CLOSE req_set;

  IF l_requests IS NOT NULL THEN
    l_requests := 'The following requests are submitted:'||
                  fnd_global.newline||fnd_global.newline||
                  l_requests||fnd_global.newline||
                  'Please check the result for each request.';

    ap_debug_pkg.print('Y','l_requests:'||l_requests);
    ap_debug_pkg.print('Y','sending email +');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Personal Expenses sent to :'||lc_temp_email);
v_sfile_name:='Merchant%20Contact%20List.xlsx';
   --  v_dfile_name:='$XXMER_DATA/outbound/'||v_sfile_name;

BEGIN
lc_temp_email:=get_distribution_list;

select instance_name into instance_name from v$instance;    --added for jira NAIT-87654
email_subject:=instance_name||' '||'OD: Trade Match Merchant Contacts';   --added for jira NAIT-87654


                        conn := xx_pa_pb_mail.begin_mail(
                                        sender => 'noreply@officedepot.com',
                                        recipients => lc_temp_email,
                                                cc_recipients=>null,
                                        subject => email_subject, --'OD: Trade Match Merchant Contacts',  commented and added email_subject for jira NAIT-87654
                                        mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);

             --xx_attch_rpt(conn,v_sfile_name);
           --  xx_pa_pb_mail.xx_attach_excel(conn,'Merchant%20Contact%20List.xlsx');
             xx_pa_pb_mail.end_attachment(conn => conn);
             xx_pa_pb_mail.attach_text( conn => conn,
                                        data => 'Please click on the http://sp.na.odcorp.net/sites/Merch/Home/TO%20BE%20PUBLISHED/Links/Merchant%20Contact%20List.xlsx for the merchant contact details ' 
                                       );

             xx_pa_pb_mail.end_mail( conn => conn );

                     COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ap_debug_pkg.print('Y',
                 'ap_xml_invoice_inbound_pkg.notify_recipient EXCEPTION(-)');
    p_return_code := '2';
END;
END IF;
END ;

FUNCTION get_distribution_list 
RETURN VARCHAR2
IS

  lc_first_rec       VARCHAR2(1);
  lc_temp_email                VARCHAR2(2000);
  lc_boolean            BOOLEAN;
  lc_boolean1           BOOLEAN;

  Type TYPE_TAB_EMAIL IS TABLE OF XX_FIN_TRANSLATEVALUES.target_value1%TYPE INDEX BY BINARY_INTEGER ;
  EMAIL_TBL                       TYPE_TAB_EMAIL;

BEGIN

     BEGIN
       ------------------------------------------
       -- Selecting emails from translation table
       ------------------------------------------
       SELECT TV.target_value1
             ,TV.target_value2
             ,TV.target_value3
             ,TV.target_value4
             ,TV.target_value5
             ,TV.target_value6
             ,TV.target_value7
             ,TV.target_value8
             ,TV.target_value9
             ,TV.target_value10
       INTO
              EMAIL_TBL(1)
             ,EMAIL_TBL(2)
             ,EMAIL_TBL(3)
             ,EMAIL_TBL(4)
             ,EMAIL_TBL(5)
             ,EMAIL_TBL(6)
             ,EMAIL_TBL(7)
             ,EMAIL_TBL(8)
             ,EMAIL_TBL(9)
             ,EMAIL_TBL(10)
       FROM   XX_FIN_TRANSLATEVALUES TV
             ,XX_FIN_TRANSLATEDEFINITION TD
       WHERE TV.TRANSLATE_ID  = TD.TRANSLATE_ID
       AND   TRANSLATION_NAME = 'XX_AP_TRADE_MATCH_DL'
       AND   source_value1    = 'MERCHANT_CONTACTS';
       ------------------------------------
       --Building string of email addresses
       ------------------------------------
       lc_first_rec  := 'Y';
       FOR ln_cnt in 1..10 
	   LOOP
            IF EMAIL_TBL(ln_cnt) IS NOT NULL THEN
                 IF lc_first_rec = 'Y' THEN
                     lc_temp_email := EMAIL_TBL(ln_cnt);
                     lc_first_rec := 'N';
                 ELSE
                     lc_temp_email :=  lc_temp_email ||' ; ' || EMAIL_TBL(ln_cnt);
                 END IF;
            END IF;
       End loop ;
                
       IF lc_temp_email IS NULL THEN

                  lc_temp_email:='iexpense-admin@officedepot.com';

       END IF;

       RETURN(lc_temp_email);
     EXCEPTION
       WHEN OTHERS THEN
         lc_temp_email:='iexpense-admin@officedepot.com';
         RETURN(lc_temp_email);
     END;
END get_distribution_list;

FUNCTION xx_ap_get_hold_date(p_invoice_id NUMBER) 
RETURN date AS
 BEGIN
   RETURN SYSDATE;
END xx_ap_get_hold_date;

FUNCTION merch_name (p_dept_no in number) return varchar2 is
cursor c1 is
select * 
from XX_AP_MERCH_CONTACTS a
where a.dept = p_dept_no;
v_merch varchar2(1000):=null;
v_count number:=0;
v_sep varchar2(5):='';
begin
for x in c1 loop
  if v_count = 0 then
    v_sep := '';
  else
    v_sep := ', ';
  end if;
  v_merch:= v_merch||v_sep||x.CHANNEL||'-'||nvl(x.SCM,nvl(x.CM,nvl(x.ACM,x.DMM)));
  v_count := v_count+1;
end loop;
return v_merch;
exception
when others then 
  return 'Error: '||SQLERRM;
end merch_name; 
 
END XX_AP_MERCH_CONT_PKG;
/
show errors;
