create or replace PACKAGE BODY XX_EXTERNAL_USERS_CONV
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_EXTERNAL_USERS_CONV                                                               |
-- | Description : Package body for E1328_BSD_iReceivables_interface                                    |
-- |               This package performs the following                                                  |
-- |               1. Setup the contact at a bill to level                                              |
-- |               2. Insert web user details into xx_external_users                                    |
-- |               3. Assign responsibilites and party id  when the webuser is created in fnd_user      |
-- |                                                                                                    |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       30-Jan-2008 Alok Sahay         Initial draft version.      		                        |
-- |1.1       12-Jun-2008 Indra Varada       Added new procedure update_external_table_status           |
-- |1.2       18-Nov-2008 Indra Varada       Modified logic to exit with warning if no users exist      |
-- |                                         in AOPS table                                              |   
-- |1.3       11-Nov-2015 Manikant Kasu      Made code changes as part of BSD - iRec Webpassword Sync   |
-- |                                         enhancements. Code changes to remove schema references as  |
-- |                                         per GSCC R12.2.2 compliance                                |
-- |1.4       20-Jul-2016 Vasu Raparla       Made code changes for defect #38393.Added new procedures   |
-- |                                         to Purge xx_external_users_stg and debug/update single user|
-- |1.5       12-Sep-2016 Vasu Raparla       Made code changes to procedure process_new_user_access for |
-- |                                         Defect 39239                                               |
-- |1.6       26-Feb-2019 Havish Kasina      Made code changes for Lift and Shift to extract AOPS       |
-- |                                         External users information from the new custom table       |
-- |                                         XX_CDH_AOPS_EXTERNAL_USERS                                 |  
-- |1.7       27-JAN-2019 BIAS               Changed to replace user_lock to dbms_lock                                              |                
-- +====================================================================================================+
*/

   g_pkg_name                     CONSTANT VARCHAR2(30)  := 'XX_EXTERNAL_USERS_CONV';

   g_batch_max_size               NUMBER  := 0;
   g_batch_id                     NUMBER  := 0;
   g_counter                      NUMBER  := 0;
   g_session_id                   NUMBER;

   g_batch_list                   DBMS_SQL.varchar2_table;

   PROCEDURE write_log( p_msg VARCHAR2);
   PROCEDURE write_output( p_msg VARCHAR2);

   -- ===========================================================================
   -- Name             : write_log
   -- Description      : Writes a message to the concurrent log
   --
   -- Parameters :      p_msg          : Message
   --
   -- ===========================================================================
   PROCEDURE write_log( p_msg VARCHAR2)
   IS
   BEGIN
        fnd_file.put_line (fnd_file.log, p_msg);
   END;

   -- ===========================================================================
   -- Name             : write_output
   -- Description      : Writes a message to the concurrent output
   --
   -- Parameters :      p_msg          : Message
   --
   -- ===========================================================================
   PROCEDURE write_output( p_msg VARCHAR2)
   IS
   BEGIN
        fnd_file.put_line (fnd_file.output, p_msg);
   END;

   -- ===========================================================================
   -- Name             :
   -- Description      :
   --
   --
   --
   -- Parameters       :
   --
   -- ===========================================================================
   PROCEDURE print_batch_id
   IS
   BEGIN
        XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Number of Batches : ' || g_batch_list.count());
        FOR lc_counter  IN g_batch_list.FIRST..g_batch_list.LAST
        LOOP
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2,'Counter [' || lc_counter || '] := ' ||  g_batch_list(lc_counter) );
        END LOOP; -- FOR lc_counter  IN g_batch_list.FIRST..g_batch_list.LAST

   END print_batch_id;

   -- ===========================================================================
   -- Name             :
   -- Description      :
   --
   --
   --
   -- Parameters       :
   --
   -- ===========================================================================
   PROCEDURE test_batch_id
   IS
     lc_batch_name VARCHAR2(100);
   BEGIN
      lc_batch_name :=  gen_batch_id();
      DBMS_OUTPUT.PUT_LINE('Batch Name ' || lc_batch_name);

   END test_batch_id;

   -- ===========================================================================
   -- Name             :
   -- Description      :
   --
   --
   --
   -- Parameters       :
   --
   -- ===========================================================================
   FUNCTION gen_batch_id
            RETURN VARCHAR2
   IS
     lc_batch_name VARCHAR2(30);
   BEGIN

     IF g_session_id IS NULL
     THEN
         SELECT SYS_CONTEXT('USERENV','SESSIONID') sessionid
         INTO   g_session_id
         FROM   DUAL;
     END IF; -- g_session_id IS NULL


     g_counter := g_counter + 1;

     lc_batch_name := g_session_id || '-' || g_batch_id;

     IF g_counter = 1
     THEN
         g_batch_list(g_batch_id) := lc_batch_name;
     END IF; -- g_counter = 0

     IF g_counter >= g_batch_max_size
     THEN
         g_counter := 0;
         g_batch_id      := g_batch_id + 1;
     END IF; -- g_counter >= g_batch_max_size

     RETURN   lc_batch_name;

   END gen_batch_id;

   -- ===========================================================================
   -- Name             :
   -- Description      :
   --
   --
   --
   -- Parameters       :
   --
   -- ===========================================================================
   PROCEDURE update_fnd_user( p_cur_extuser_rec         IN         XX_EXTERNAL_USERS_PVT.external_user_rec_type
                            , p_new_extuser_rec         IN         XX_EXTERNAL_USERS_PVT.external_user_rec_type
                            , p_fnd_user_rec            IN         XX_EXTERNAL_USERS_PVT.fnd_user_rec_type
                            , x_return_status           OUT NOCOPY VARCHAR2
                            , x_msg_count               OUT        NUMBER
                            , x_msg_data                OUT NOCOPY VARCHAR2
                         );
   -- ===========================================================================
   -- Name             : compare_guid
   -- Description      :
   --
   --
   --
   -- Parameters       :
   --
   -- ===========================================================================
   FUNCTION compare_guid (p_user_name  IN VARCHAR2) RETURN VARCHAR2
   IS
   lc_oid_user_guid   fnd_user.user_guid%type := NULL; 
   lc_fnd_user_guid   fnd_user.user_guid%type:=NULL;
   lc_oid_user_exists VARCHAR2(1):= 'N';  
   lc_fnd_user_exists VARCHAR2(1):= 'N';
   lc_guid_match      VARCHAR2(1):= 'N';
   BEGIN
     lc_oid_user_exists := XX_OID_SUBSCRIPTION_UPD_PKG.get_oid_user_exists(p_user_name,lc_oid_user_guid);
     lc_fnd_user_exists := XX_OID_SUBSCRIPTION_UPD_PKG.get_fnd_user_exists(p_user_name,lc_fnd_user_guid);
     IF(nvl(lc_oid_user_guid,'XXXXXX') = nvl(lc_fnd_user_guid,'XXXXXX')) THEN 
       lc_guid_match :='Y';
      ELSE
       lc_guid_match :='N';
      END IF;
       RETURN lc_guid_match;
   EXCEPTION
   WHEN OTHERS THEN 
      fnd_file.put_line (fnd_file.log, 'Error Comparing GUID - Error - '||SQLERRM);
      RETURN lc_guid_match;
   END compare_guid;
  -- ===========================================================================
   -- Name             : get_oid_guid
   -- Description      :
   --
   --
   --
   -- Parameters       :
   --
   -- ===========================================================================
   FUNCTION get_oid_guid (p_user_name  IN VARCHAR2) RETURN fnd_user.user_guid%type
   IS
   
   l_oid_guid fnd_user.user_guid%type:=null;
   lc_oid_user_exists VARCHAR2(1):= 'N';
   BEGIN
     lc_oid_user_exists := XX_OID_SUBSCRIPTION_UPD_PKG.get_oid_user_exists(p_user_name,l_oid_guid);
     RETURN l_oid_guid;
   EXCEPTION
   WHEN OTHERS THEN 
   fnd_file.put_line (fnd_file.log, 'Error Deriving OID GUID  - '||SQLERRM);
   RETURN l_oid_guid;
   END get_oid_guid;
   
    -- ===========================================================================
   -- Name             : get_subscription_status
   -- Description      :
   --
   --
   --
   -- Parameters       :
   --
   -- ===========================================================================
   FUNCTION get_subscription_status(p_fnd_user in VARCHAR2) 
                                  RETURN VARCHAR2 
    IS
    lc_oid_user_guid   fnd_user.user_guid%type := NULL; 
    lc_oid_sub_status  VARCHAR2(50):=NULL;
    lc_oid_user_exists VARCHAR2(1):= 'N'; 
    BEGIN 
       lc_oid_user_exists := XX_OID_SUBSCRIPTION_UPD_PKG.get_oid_user_exists(p_fnd_user,lc_oid_user_guid);
       lc_oid_sub_status  := XX_OID_SUBSCRIPTION_UPD_PKG.check_subscription(p_fnd_user,lc_oid_user_guid);
       RETURN lc_oid_sub_status;
    EXCEPTION 
      WHEN OTHERS THEN 
       fnd_file.put_line (fnd_file.log, 'Unexpected Error in generating Subscription status for user '||p_fnd_user||' - Error - '||SQLERRM);
       RETURN NULL;
    END get_subscription_status;
   -- ===========================================================================
   -- Name             :get_usrs_pwd_mismatch
   -- Description      :
   --
   --
   --
   -- Parameters       :
   --
   -- ===========================================================================
   procedure get_usrs_pwd_mismatch( p_batch_id      IN VARCHAR2
                                   ,p_report_only   IN VARCHAR2 DEFAULT 'Y')
   IS
   cursor c_mismatched_records (p_batch_id varchar2)
     is 
     select rpad(xeus.batch_id,30,' ')                                                                                      BATCH_ID 
           ,rpad(xeu.userid,40,' ')                                                                                         USER_ID
           ,rpad(xeu.fnd_user_name,25,' ')                                                                                  FND_USER_NAME
           ,rpad(nvl(to_char(xeus.ext_upd_timestamp,'DD-MON-YYYY HH24:MI:SS:FF'),'00-000-0000 00:00:00:000000000'),25,' ')  STG_LAST_UPDATE_TIMESTAMP
           ,rpad(nvl(to_char(xeu.ext_upd_timestamp,'DD-MON-YYYY HH24:MI:SS:FF'), '00-000-0000 00:00:00:000000000'),25,' ')  USERS_LAST_UPDATE_TIMESTAMP
           ,rpad(to_char(xeu.oid_update_date,'DD-MON-YYYY HH24:MI:SS'),25,' ')                                              OID_UPDATE_DATE 
           ,rpad(decode(fnd_ldap_wrapper.user_exists(xeu.fnd_user_name),1,'Y','N'),15,' ')                                  OID_USER_EXISTS                                                             
     from   xx_external_users_stg xeus
           ,xx_external_users     xeu
     where  1 = 1
     and    xeu.userid    = xeus.userid
     and    xeu.password != xeus.password  
     and    xeu.access_code IN ('02', '03', '05', '06')
     and    xeu.fnd_user_name = '100100' || xeus.webuser_osr
     and    xeus.batch_id = p_batch_id; --g_batch_list(lc_counter)
     
     lc_subs_status varchar2(50);
     l_guid_match   varchar2(25);
     
     ln_mimatches_count            NUMBER := 0;
   BEGIN               
                    write_output('----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
                    write_output('                                                             List Of Users who have a Password Mismatch                                                        ');
                    write_output('----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
                    write_output('BATCH_ID                       USER_ID                                       FND_USER_NAME                 STG_LAST_UPDATE_TIMESTAMP           USERS_LAST_UPDATE_TIMESTAMP          OID_UPDATE_DATE        OID_USER_EXISTS       GUID_MATCH     ');
                    write_output('----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
                    
                        FOR i IN c_mismatched_records (p_batch_id)
                        LOOP
                             
                             l_guid_match  :=rpad(compare_guid(trim(i.fnd_user_name)),15,' ') ;
                             ln_mimatches_count := ln_mimatches_count + 1;
                             write_output(rpad(i.batch_id,30,' ') || ' ' || i.user_id || '      '||i.fnd_user_name|| '     '|| i.STG_LAST_UPDATE_TIMESTAMP ||'           '|| i.USERS_LAST_UPDATE_TIMESTAMP ||'            '|| i.OID_UPDATE_DATE ||'    '||i.OID_USER_EXISTS ||'     '|| l_guid_match );
                        
                        END LOOP; -- All the records for each batch_id

                    write_output('-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
                 
                 IF(p_report_only ='Y') THEN
                    IF ( NVL(ln_mimatches_count,0) = 0) THEN
                      --send notification email to support teams
                      write_output('# No Users exist in xx_external_users whose passwords do not match with, xx_external_users_stg, Staging table ');
                      ELSE
                        XX_COM_EMAIL_NOTIFICATION_PKG.SEND_NOTIFICATIONS(
                           p_email_identifier  => 'XXCNV_WEBUSER_CONV_MASTER'
                          ,p_body              => ln_mimatches_count  || ' exception(s) found in Web User Conversion Master Program. Please check the output of request_id:' || fnd_global.conc_request_id() || ', and re-submit the program, "XXCNV: Web User Conversion master" in Update mode.'
                        );
                    END IF;
                  END IF;
   EXCEPTION 
   WHEN OTHERS THEN
   fnd_file.put_line (fnd_file.log, 'Unexpected Error in generating report for password mismatch in get_usrs_pwd_mismatch - Error - '||SQLERRM);
   END get_usrs_pwd_mismatch;

   -- ===========================================================================
   -- Name             :
   -- Description      :
   --
   --
   --
   -- Parameters       :
   --
   -- ===========================================================================
   PROCEDURE web_contact_conv_master ( x_errbuf            OUT NOCOPY    VARCHAR2
                                     , x_retcode           OUT NOCOPY    VARCHAR2
                                     , p_load_status       IN            VARCHAR2 DEFAULT NULL
                                     , p_report_only       IN            VARCHAR2 DEFAULT 'Y'
                                     )
   IS
     lc_src_table_name             VARCHAR2(100);
     lc_insert_sql                 VARCHAR2(4000);
     ln_request_id                 NUMBER;
     no_records_excp               EXCEPTION;
     l_rows_processed              NUMBER := 0;
     l_last_run_date               DATE := null;
     l_mimatches_exist             VARCHAR2(1) := 'N';
     ln_mimatches_count            NUMBER := 0;
     lb_complete                   BOOLEAN;
     lc_phase                      VARCHAR2 (100);
     lc_status                     VARCHAR2 (100);
     lc_dev_phase                  VARCHAR2 (100);
     lc_dev_status                 VARCHAR2 (100);
     lc_message                    VARCHAR2 (100);
     lc_oid_user_guid              fnd_user.user_guid%type := NULL;       

     CURSOR c_ext_users
     IS 
       SELECT EXTERNAL_USERS_STG_ID
            , trim(to_char(CONTACT_OSR, '00000000000000')) "CONTACT_OSR"
            , trim(to_char(WEBUSER_OSR, '00000000000000')) "WEBUSER_OSR"
            , trim(USERID) "USERID"
            , trim(to_char(ACCT_SITE_OSR, '00000000')) || '-00001-A0' "ACCT_SITE_OSR"
            , trim(RECORD_TYPE) "RECORD_TYPE"
            , SUBSTR(ACCESS_CODE,1,2) "ACCESS_CODE"
            , trim(PASSWORD) "PASSWORD"
            , trim(STATUS) "STATUS"
            , trim(PERSON_FIRST_NAME) "PERSON_FIRST_NAME"
            , trim(PERSON_MIDDLE_NAME) "PERSON_MIDDLE_NAME"
            , trim(PERSON_LAST_NAME) "PERSON_LAST_NAME"
            , trim(EMAIL) "EMAIL"
            , trim(PERMISSION_FLAG) "PERMISSION_FLAG"
            , 'A0' "ORIG_SYSTEM"
            , 'P' "LOAD_STATUS"
            , XX_EXTERNAL_USERS_CONV.gen_batch_id() "BATCH_ID"
            , PWD_LAST_CHANGE
            , 'BATCH_PROCESS' "PROCESS_NAME"
         FROM XX_CDH_AOPS_EXTERNAL_USERS
        WHERE LOAD_STATUS = 'N';
		
   BEGIN

      -- --------------------------------------------------------------
      -- First Insrt all Records from the AS/400 Database File Into a
      -- Staging table on EBS
      -- ---------------------------------------------------------------
      XX_EXTERNAL_USERS_DEBUG.enable_debug;
      lc_src_table_name := fnd_profile.value('XXOD_WEB_USERS_SOURCE_TABLE');
      IF  NVL(lc_src_table_name, '') = ''
      THEN
         x_retcode := 2;
         x_errbuf  := 'PROFILE XXOD_WEB_USERS_SOURCE_TABLE not set';
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, x_errbuf);
      END IF; --  NVL(AOPS_table_name, '') = ''
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2,  'Source Table : ' || lc_src_table_name);


      g_batch_max_size := fnd_profile.value('XXOD_WEB_USERS_CONV_BATCH_SIZE');
      IF  NVL(g_batch_max_size, 0) = 0
      THEN
         x_retcode := 2;
         x_errbuf  := 'PROFILE XXOD_WEB_USERS_CONV_BATCH_SIZE not set';
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, x_errbuf);
      END IF; --  NVL(AOPS_table_name, '') = ''
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2,  'Batch Size : ' || g_batch_max_size);
      write_log ('Batch Size : ' || g_batch_max_size);
      DBMS_SESSION.SET_NLS('nls_timestamp_format','''YYYY-MM-DD HH24:MI:SS.FF''');
	  
	  write_log ('Inserting into XX_EXTERNAL_USERS_STG Table');
	  FOR ext in c_ext_users
	  LOOP
	  l_rows_processed := 0;
      INSERT INTO XX_EXTERNAL_USERS_STG
                           ( EXTERNAL_USERS_STG_ID
                           , CONTACT_OSR
                           , WEBUSER_OSR
                           , USERID
                           , ACCT_SITE_OSR
                           , RECORD_TYPE
                           , ACCESS_CODE
                           , PASSWORD
                           , STATUS
                           , PERSON_FIRST_NAME
                           , PERSON_MIDDLE_NAME
                           , PERSON_LAST_NAME
                           , EMAIL
                           , PERMISSION_FLAG
                           , ORIG_SYSTEM
                           , LOAD_STATUS
                           , BATCH_ID
                           , CREATION_DATE
                           , EXT_UPD_TIMESTAMP
                           , PROCESS_NAME
                           )
				    VALUES ( ext.EXTERNAL_USERS_STG_ID
                           , ext.CONTACT_OSR
                           , ext.WEBUSER_OSR
                           , ext.USERID
                           , ext.ACCT_SITE_OSR
                           , ext.RECORD_TYPE
                           , ext.ACCESS_CODE
                           , ext.PASSWORD
                           , ext.STATUS
                           , ext.PERSON_FIRST_NAME
                           , ext.PERSON_MIDDLE_NAME
                           , ext.PERSON_LAST_NAME
                           , ext.EMAIL
                           , ext.PERMISSION_FLAG
                           , ext.ORIG_SYSTEM
                           , ext.LOAD_STATUS
                           , ext.BATCH_ID
                           , to_date(sysdate,'DD-MON-RRRR HH24:MI:SS')
                           , ext.PWD_LAST_CHANGE
                           , ext.PROCESS_NAME
						   );

      l_rows_processed := SQL%ROWCOUNT;
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2,  'Rows Extracted : ' || l_rows_processed);
      write_log ('Rows Extracted : ' || l_rows_processed);
      
      IF l_rows_processed = 0 THEN
        RAISE no_records_excp;
	  ELSE
	    write_log ('Updating the Status to C in XX_CDH_AOPS_EXTERNAL_USERS Table');
	    UPDATE XX_CDH_AOPS_EXTERNAL_USERS
		   SET LOAD_STATUS = 'C'
		 WHERE EXTERNAL_USERS_STG_ID = ext.EXTERNAL_USERS_STG_ID;
		 
      END IF;
	END LOOP;
    write_log ('End of inserting into XX_EXTERNAL_USERS_STG Table');  
    
	COMMIT;

      -- -------------------------------------------------------
      -- Update Stats on the Staging Table
      -- -------------------------------------------------------
  /*	  	DBMS_STATS.GATHER_TABLE_STATS ( ownname => 'XXCNV'
                                    , tabname => 'XX_EXTERNAL_USERS_STG'
                                    , estimate_percent => 100
                                    );*/


      -- -------------------------------------------------------------------
      -- Submit Conacurrent Requests for all the batches
      -- -------------------------------------------------------------------
      $if $$enable_debug
      $then
         print_batch_id;
      $end

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2,  'Number of Batches : ' || g_batch_list.count());
      
      FOR lc_counter  IN g_batch_list.FIRST..g_batch_list.LAST
      LOOP
         FND_FILE.PUT_LINE(FND_FILE.log, 'Processing Batch ID [' || lc_counter || '] : ' || g_batch_list(lc_counter));
                    
            IF (p_report_only <> 'Y') THEN
            
                  get_usrs_pwd_mismatch(g_batch_list(lc_counter),p_report_only);
                  write_output('Submitting  "XXCNV Web User Conversion Batch Program" ');
              
                   ln_request_id := FND_REQUEST.submit_request ( 'XXCNV'                        --application
                                                             , 'XXCNV_WEBUSER_CONV_BATCH'     --program
                                                             , NULL                           --description
                                                             , NULL                           --start_time
                                                             , FALSE                          --sub_request
                                                             , 'A0'                           --argument1
                                                             , g_batch_list(lc_counter)       --argument2
                                                             , p_load_status                  --argument3
                                                             );
                 -- -----------------------------------------------------------
                 -- TODO: Check the Concurrent Request ID
                 -- -----------------------------------------------------------
              
              -- -------------------------------------------------------------------
              -- Commit
              -- -------------------------------------------------------------------
              XX_EXTERNAL_USERS_DEBUG.log_debug_message(2,  'Commiting ...');
              COMMIT;
              
              XX_EXTERNAL_USERS_DEBUG.disable_debug;
            ELSE
                            
              --select all external_users from the STG table and compare password with external_users password and do FND_FILE.OUTPUT
                  get_usrs_pwd_mismatch(g_batch_list(lc_counter),p_report_only);
            
          END IF;
      
        END LOOP; -- FOR lc_counter  IN g_batch_list.FIRST..g_batch_list.LAST   
     
     EXCEPTION WHEN no_records_excp THEN
       XX_EXTERNAL_USERS_DEBUG.log_debug_message(2,'Table:' || lc_src_table_name || 'Has No Records To Process');
       x_retcode := 1;  
      WHEN OTHERS THEN 
       XX_EXTERNAL_USERS_DEBUG.log_debug_message(2,'When others ');
       write_log('Unexpected Error in web_contact_conv_master - Error- :'||SQLERRM );
       x_retcode := 1;         
   END web_contact_conv_master;


   -- ===========================================================================
   -- Name             :
   -- Description      :
   --
   --
   --
   -- Parameters       :
   --
   -- ===========================================================================
   PROCEDURE web_contact_conv_batch ( x_errbuf            OUT  NOCOPY   VARCHAR2
                                    , x_retcode           OUT  NOCOPY   VARCHAR2
                                    , p_orig_system       IN            VARCHAR2
                                    , p_batch_id          IN            VARCHAR2
                                    , p_load_status       IN            VARCHAR2 DEFAULT NULL
                                    )
   IS
     
      CURSOR c_webcontact_stg_cur(p_orig_system VARCHAR2, p_batch_id VARCHAR2)
      IS
         SELECT *
         FROM   xx_external_users_stg
         WHERE  orig_system = p_orig_system
         AND    batch_id    = p_batch_id
         AND    load_status = 'P';

      TYPE EXT_USER_REC_TYP   IS TABLE OF c_webcontact_stg_cur%ROWTYPE INDEX BY BINARY_INTEGER;

      CURSOR c_webcontact_cur(p_userid VARCHAR2)
      IS
         SELECT *
         FROM   xx_external_users
         WHERE  userid = p_userid;

      lc_new_users                      EXT_USER_REC_TYP;
      lc_webcontact_rec                 c_webcontact_cur%ROWTYPE;

      lt_insert_ext_user_stg_id         dbms_sql.number_table;
      lt_insert_ext_user_id             dbms_sql.number_table;
      lt_insert_party_id                dbms_sql.number_table;
      lt_insert_userid                  dbms_sql.varchar2_table;
      lt_insert_password                dbms_sql.varchar2_table;
      lt_insert_person_first_name       dbms_sql.varchar2_table;
      lt_insert_person_middle_name      dbms_sql.varchar2_table;
      lt_insert_person_last_name        dbms_sql.varchar2_table;
      lt_insert_email                   dbms_sql.varchar2_table;
      lt_insert_orig_system             dbms_sql.varchar2_table;
      lt_insert_contact_osr             dbms_sql.varchar2_table;
      lt_insert_acct_site_osr           dbms_sql.varchar2_table;
      lt_insert_webuser_osr             dbms_sql.varchar2_table;
      lt_insert_record_type             dbms_sql.varchar2_table;
      lt_insert_access_code             dbms_sql.varchar2_table;
      lt_insert_permission_flag	       dbms_sql.varchar2_table;
      lt_insert_status                  dbms_sql.varchar2_table;
      lt_insert_user_locked             dbms_sql.varchar2_table;
      lt_insert_load_status             dbms_sql.varchar2_table;
      lt_insert_batch_id                dbms_sql.varchar2_table;
      lt_insert_fnd_user_name           dbms_sql.varchar2_table;
      lt_insert_ext_upd_timestamp       dbms_sql.varchar2_table;

      lt_update_ext_user_stg_id         dbms_sql.number_table;
      lt_update_ext_user_id             dbms_sql.number_table;
      lt_update_party_id                dbms_sql.number_table;
      lt_update_userid                  dbms_sql.varchar2_table;
      lt_update_password                dbms_sql.varchar2_table;
      lt_update_person_first_name       dbms_sql.varchar2_table;
      lt_update_person_middle_name      dbms_sql.varchar2_table;
      lt_update_person_last_name        dbms_sql.varchar2_table;
      lt_update_email                   dbms_sql.varchar2_table;
      lt_update_orig_system             dbms_sql.varchar2_table;
      lt_update_contact_osr             dbms_sql.varchar2_table;
      lt_update_acct_site_osr           dbms_sql.varchar2_table;
      lt_update_webuser_osr             dbms_sql.varchar2_table;
      lt_update_record_type             dbms_sql.varchar2_table;
      lt_update_access_code             dbms_sql.varchar2_table;
      lt_update_permission_flag	       dbms_sql.varchar2_table;
      lt_update_status                  dbms_sql.varchar2_table;
      lt_update_user_locked             dbms_sql.varchar2_table;
      lt_update_load_status             dbms_sql.varchar2_table;
      lt_update_batch_id                dbms_sql.varchar2_table;
      lt_update_fnd_user_name           dbms_sql.varchar2_table;
      lt_update_ext_upd_timestamp       dbms_sql.varchar2_table;

      lt_record_id                      dbms_sql.number_table;
      lt_load_status                    dbms_sql.varchar2_table;
      lt_load_message                   dbms_sql.varchar2_table;

      lt_bulkerror_record_id            dbms_sql.number_table;
      lt_bulkerror_load_status          dbms_sql.varchar2_table;
      lt_bulkerror_load_message         dbms_sql.varchar2_table;

      lb_error_flag                     BOOLEAN;
      ln_ext_user_id                    XX_EXTERNAL_USERS.ext_user_id%TYPE;
      ln_party_id                       XX_EXTERNAL_USERS.party_id%TYPE;
      lc_fnd_user_name                  XX_EXTERNAL_USERS.fnd_user_name%TYPE;
      lc_orig_system                    XX_EXTERNAL_USERS.orig_system%TYPE;
      l_site_key                        XX_EXTERNAL_USERS.site_key%TYPE;

      ln_bulk_limit                     NUMBER := 100;
      lc_return_status                  VARCHAR(60);
      ln_msg_count                      NUMBER;
      lc_msg_data                       VARCHAR2(4000);

      ln_record_index                   PLS_INTEGER  := 0;
      ln_counter                        PLS_INTEGER  := 0;
      ln_insert_counter                 PLS_INTEGER  := 0;
      ln_update_counter                 PLS_INTEGER  := 0;
      ln_sucess_count                   PLS_INTEGER  := 0;
      ln_failed_count                   PLS_INTEGER  := 0;
      ln_record_count                   PLS_INTEGER  := 0;
      ln_bulkerror_count                PLS_INTEGER  := 0;

      l_update                          BOOLEAN := FALSE;

      ln_size                           NUMBER;
      ln_errors                         NUMBER;
      ln_exception_count                PLS_INTEGER;
      le_api_error                      EXCEPTION;

      l_external_users_stg_id       xx_external_users_stg.external_users_stg_id%TYPE;
      l_batch_id                    xx_external_users_stg.batch_id%TYPE;             
      l_userid                      xx_external_users_stg.userid%TYPE;               
      l_password                    xx_external_users_stg.password%TYPE;             
      l_ext_upd_timestamp           xx_external_users_stg.ext_upd_timestamp%TYPE;    
      l_process_name                xx_external_users_stg.process_name%TYPE;         
      l_creation_date               xx_external_users_stg.creation_date%TYPE;        
      l_last_update_date            xx_external_users_stg.last_update_date%TYPE;     
      l_last_updated_by             xx_external_users_stg.last_updated_by%TYPE;      
      l_last_update_login           xx_external_users_stg.last_update_login%TYPE;    
      l_record_flag                 xx_external_users_stg.record_flag%TYPE;    
      l_rank                        NUMBER;


   BEGIN

      XX_EXTERNAL_USERS_DEBUG.enable_debug;
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2,  'Executing XX_EXTERNAL_USERS_CONV.process_new_ext_user');

      -- ------------------------------------------------------------------
      -- Validate p_orig_system
      -- ------------------------------------------------------------------
      IF p_orig_system IS NULL
      THEN
          x_retcode := 2;
          x_errbuf  := 'Missing Parameter <p_orig_sytem>';
          fnd_file.put_line (fnd_file.output, x_errbuf);
          RETURN;
      END IF; -- p_orig_system IS NULL

      -- ------------------------------------------------------------------
      -- Validate p_batch_id
      -- ------------------------------------------------------------------
      IF p_batch_id IS NULL
      THEN
          x_retcode := 2;
          x_errbuf  := 'Missing Parameter <p_batch_id>';
          fnd_file.put_line (fnd_file.output, x_errbuf);
          RETURN;
      END IF; -- p_orig_system IS NULL

      ln_sucess_count :=  0;
      ln_failed_count :=  0;
      ln_record_count :=  0;

      -- -------------------------------------------------------------------------
      -- Get the Site Prefix for the User
      -- -------------------------------------------------------------------------
      XX_EXTERNAL_USERS_PVT.get_user_prefix ( p_system_name     => p_orig_system
                                            , x_site_key        => l_site_key
                                            , x_return_status   => lc_return_status
                                            , x_msg_count       => ln_msg_count
                                            , x_msg_data        => lc_msg_data
                                            );

      IF lc_return_status <> FND_API.G_RET_STS_SUCCESS
      THEN
         fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_003_MISSING_SETUP');
         fnd_message.set_token ('SETUP_NAME', 'XX_ECOM_SITE_KEY');
         ln_msg_count := ln_msg_count + 1;
         lc_msg_data := fnd_message.get();
         RAISE le_api_error;
      END IF;

      -- -------------------------------------------------------------------------
      -- Get All Records for Batch from Staging Table
      -- -------------------------------------------------------------------------
      OPEN c_webcontact_stg_cur(p_orig_system, p_batch_id );
      LOOP
         -- -------------------------------------------------------------------------
         -- Bulk Collect from Cursor
         -- -------------------------------------------------------------------------
         FETCH c_webcontact_stg_cur BULK COLLECT INTO lc_new_users LIMIT ln_bulk_limit ;

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'Fetched  : ' || c_webcontact_stg_cur%ROWCOUNT);
         IF lc_new_users.COUNT = 0
         THEN
             EXIT;
         END IF; -- lc_new_users.COUNT =0 THEN

         ln_update_counter := 0;
         ln_insert_counter := 0;


         FOR ln_counter in lc_new_users.FIRST .. lc_new_users.LAST
         LOOP
            l_update := FALSE;
            ln_record_count           :=   ln_record_count+1;

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  ' ');
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'Processing Record ' || ln_record_count);

            $if $$enable_debug $then
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  '*********************************************************** ');
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'external_users_stg_id     : ' ||  lc_new_users(ln_counter).external_users_stg_id  );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'webuser_osr               : ' ||  lc_new_users(ln_counter).webuser_osr            );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'contact_osr               : ' ||  lc_new_users(ln_counter).contact_osr            );
            $end

            lb_error_flag  := FALSE;
            IF lc_new_users(ln_counter).contact_osr IS NULL
            THEN
               lb_error_flag  := TRUE;
               lc_msg_data    := 'Manadatory Data <CONTACT_OSR> is missing';
            END IF; --  lc_new_users(ln_counter).contact_osr IS NULL

            IF lc_new_users(ln_counter).webuser_osr IS NULL
            THEN
               lb_error_flag  := TRUE;
               lc_msg_data    := 'Manadatory Data <WEBUSER_OSR> is missing';
            END IF; --  lc_new_users(ln_counter).webuser_osr IS NULL

            IF lc_new_users(ln_counter).contact_osr IS NULL
            THEN
               lb_error_flag  := TRUE;
               lc_msg_data    := 'Manadatory Data <CONTACT_OSR> is missing';
            END IF; --  lc_new_users(ln_counter).contact_osr IS NULL

            IF lc_new_users(ln_counter).userid IS NULL
            THEN
               lb_error_flag  := TRUE;
               lc_msg_data    := 'Manadatory Data <USERID> is missing';
            END IF; --  lc_new_users(ln_counter).userid IS NULL

            IF NOT lb_error_flag
            THEN
               lc_fnd_user_name := l_site_key || lc_new_users(ln_counter).webuser_osr;

               OPEN c_webcontact_cur(lc_new_users(ln_counter).userid);
               FETCH c_webcontact_cur INTO lc_webcontact_rec;
               IF c_webcontact_cur%NOTFOUND
               THEN
                  XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'Processing New User  ' || lc_fnd_user_name);
                  l_update          := FALSE;

                  -- --------------------------------------------------------------------
                  -- Generate the Unique Identifier for the xx_external_users row
                  -- --------------------------------------------------------------------
                  SELECT xx_external_users_s.nextval
                  INTO   ln_ext_user_id
                  FROM DUAL;
               ELSE
                  XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'Processing Existing User  ' || lc_fnd_user_name);
                  l_update          := TRUE;
                  ln_ext_user_id    := lc_webcontact_rec.ext_user_id;
               END IF;  -- c_webcontact_cur%NOTFOUND
               CLOSE c_webcontact_cur;

               -- --------------------------------------------------------------------
               -- Fetch party id only if a new record or
               -- Party was null
               -- --------------------------------------------------------------------
               IF  (NOT l_update) OR
                   (lc_webcontact_rec.party_id IS NULL)
               THEN
                  XX_EXTERNAL_USERS_PVT.get_contact_id ( p_orig_system          => lc_new_users(ln_counter).orig_system
                                                       , p_cust_acct_cnt_osr    => lc_new_users(ln_counter).contact_osr
                                                       , x_party_id             => ln_party_id
                                                       , x_return_status        => lc_return_status
                                                       , x_msg_count            => ln_msg_count
                                                       , x_msg_data             => lc_msg_data
                                                       );

                  IF lc_return_status <> FND_API.G_RET_STS_SUCCESS
                  THEN
                     XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'Error Getting Contact ID - ' || lc_msg_data);
                     lb_error_flag                          := TRUE;
                     ln_party_id                            := NULL;
                  END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
               END IF; -- lc_new_users(ln_counter).party_id IS NULL

               IF NOT lb_error_flag
               THEN
                  lt_record_id(ln_counter)             := lc_new_users(ln_counter).external_users_stg_id;
                  lt_load_status(ln_counter)           := 'S';
                  lt_load_message(ln_counter)          := NULL;

                  IF l_update
                  THEN
                    BEGIN
                           select  nvl(ext_upd_timestamp,'01-JAN-0001 01:01:01.000000000')
                           into    l_ext_upd_timestamp
                           from    xx_external_users x
                           WHERE   1 = 1 
                           and     x.userid = lc_new_users(ln_counter).userid
                           and     x.fnd_user_name = '100100' || lc_new_users(ln_counter).webuser_osr
                           ;
                    EXCEPTION
                      WHEN OTHERS THEN
                         null; -- nothing to be done
                    END;  
                    
                    BEGIN
                    
                      IF lc_new_users(ln_counter).ext_upd_timestamp > l_ext_upd_timestamp THEN
                      
                         ln_update_counter := ln_update_counter + 1;
                         
                         lt_update_ext_user_id(ln_update_counter)         := ln_ext_user_id                                 ;
                         lt_update_party_id(ln_update_counter)            := ln_party_id                                    ;
                         lt_update_fnd_user_name(ln_update_counter)       := lc_fnd_user_name                               ;
                         lt_update_orig_system(ln_update_counter)         := lc_orig_system                                 ;
                         lt_update_userid(ln_update_counter)              := lc_new_users(ln_counter).userid                ;
                         lt_update_password(ln_update_counter)            := lc_new_users(ln_counter).password              ;
                         lt_update_person_first_name(ln_update_counter)   := lc_new_users(ln_counter).person_first_name     ;
                         lt_update_person_middle_name(ln_update_counter)  := lc_new_users(ln_counter).person_middle_name    ;
                         lt_update_person_last_name(ln_update_counter)    := lc_new_users(ln_counter).person_last_name      ;
                         lt_update_email(ln_update_counter)               := lc_new_users(ln_counter).email                 ;
                         lt_update_contact_osr(ln_update_counter)         := lc_new_users(ln_counter).contact_osr           ;
                         lt_update_acct_site_osr(ln_update_counter)       := lc_new_users(ln_counter).acct_site_osr         ;
                         lt_update_webuser_osr(ln_update_counter)         := lc_new_users(ln_counter).webuser_osr           ;
                         lt_update_record_type(ln_update_counter)         := lc_new_users(ln_counter).record_type           ;
                         lt_update_access_code(ln_update_counter)         := lc_new_users(ln_counter).access_code           ;
                         lt_update_permission_flag(ln_update_counter)     := lc_new_users(ln_counter).permission_flag       ;
                         lt_update_status(ln_update_counter)              := lc_new_users(ln_counter).status                ;
                         lt_update_user_locked(ln_update_counter)         := lc_new_users(ln_counter).user_locked           ;
                         lt_update_load_status(ln_update_counter)         := lc_new_users(ln_counter).load_status           ;
                         lt_update_ext_user_stg_id(ln_update_counter)     := lc_new_users(ln_counter).external_users_stg_id ;
                         lt_update_ext_upd_timestamp(ln_update_counter)   := lc_new_users(ln_counter).ext_upd_timestamp     ;
                         
                         write_output('Batch_ID: ' || rpad(p_batch_id,30,' ') || '   UserID: ' || lc_new_users(ln_counter).userid || '      FND_USER_NAME: 100100'||lc_new_users(ln_counter).webuser_osr|| '     TIMESTAMP: '|| lc_new_users(ln_counter).ext_upd_timestamp );
                         
                         $if $$enable_debug $then
                            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'ext_user_id_tbl     : ' ||  lt_update_ext_user_id(ln_update_counter)        );
                            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'party_id_tbl        : ' ||  lt_update_party_id(ln_update_counter)           );
                            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'fnd_user_name_tbl   : ' ||  lt_update_fnd_user_name(ln_update_counter)      );
                            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'orig_system_tbl     : ' ||  lt_update_orig_system(ln_update_counter)        );
                         $end
                      END IF;
                    EXCEPTION
                      WHEN OTHERS THEN
                         null; -- nothing to be done
                    END;
                  ELSE
                     ln_insert_counter := ln_insert_counter + 1;

                     lt_insert_ext_user_id(ln_insert_counter)         := ln_ext_user_id                                 ;
                     lt_insert_party_id(ln_insert_counter)            := ln_party_id                                    ;
                     lt_insert_fnd_user_name(ln_insert_counter)       := lc_fnd_user_name                               ;
                     lt_insert_orig_system(ln_insert_counter)         := lc_orig_system                                 ;
                     lt_insert_userid(ln_insert_counter)              := lc_new_users(ln_counter).userid                ;
                     lt_insert_password(ln_insert_counter)            := lc_new_users(ln_counter).password              ;
                     lt_insert_person_first_name(ln_insert_counter)   := lc_new_users(ln_counter).person_first_name     ;
                     lt_insert_person_middle_name(ln_insert_counter)  := lc_new_users(ln_counter).person_middle_name    ;
                     lt_insert_person_last_name(ln_insert_counter)    := lc_new_users(ln_counter).person_last_name      ;
                     lt_insert_email(ln_insert_counter)               := lc_new_users(ln_counter).email                 ;
                     lt_insert_contact_osr(ln_insert_counter)         := lc_new_users(ln_counter).contact_osr           ;
                     lt_insert_acct_site_osr(ln_insert_counter)       := lc_new_users(ln_counter).acct_site_osr         ;
                     lt_insert_webuser_osr(ln_insert_counter)         := lc_new_users(ln_counter).webuser_osr           ;
                     lt_insert_record_type(ln_insert_counter)         := lc_new_users(ln_counter).record_type           ;
                     lt_insert_access_code(ln_insert_counter)         := lc_new_users(ln_counter).access_code           ;
                     lt_insert_permission_flag(ln_insert_counter)     := lc_new_users(ln_counter).permission_flag       ;
                     lt_insert_status(ln_insert_counter)              := lc_new_users(ln_counter).status                ;
                     lt_insert_user_locked(ln_insert_counter)         := lc_new_users(ln_counter).user_locked           ;
                     lt_insert_load_status(ln_insert_counter)         := lc_new_users(ln_counter).load_status           ;
                     lt_insert_ext_user_stg_id(ln_insert_counter)     := lc_new_users(ln_counter).external_users_stg_id ;
                     lt_insert_ext_upd_timestamp(ln_insert_counter)   := lc_new_users(ln_counter).ext_upd_timestamp     ;

                     $if $$enable_debug $then
                        XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'ext_user_id_tbl     : ' ||  lt_insert_ext_user_id(ln_insert_counter)        );
                        XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'party_id_tbl        : ' ||  lt_insert_party_id(ln_insert_counter)           );
                        XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'fnd_user_name_tbl   : ' ||  lt_insert_fnd_user_name(ln_insert_counter)      );
                        XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'orig_system_tbl     : ' ||  lt_insert_orig_system(ln_insert_counter)        );
                     $end

                  END IF; -- l_update
               ELSE
                  ln_failed_count                      := ln_failed_count+1;
                  lt_record_id(ln_counter)             := lc_new_users(ln_counter).external_users_stg_id;
                  lt_load_status(ln_counter)           := 'E';
                  lt_load_message(ln_counter)          := lc_msg_data;

               END IF; -- NOT lb_error_flag


            ELSE

               ln_failed_count                      := ln_failed_count+1;
               lt_record_id(ln_counter)             := lc_new_users(ln_counter).external_users_stg_id;
               lt_load_status(ln_counter)           := 'E';
               lt_load_message(ln_counter)          := lc_msg_data;

            END IF; -- lb_error_flag

         END LOOP; -- ln_counter in lc_new_users.FIRST .. lc_new_users.LAST

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  '*********************************************************** ');
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'Error Records : ' ||  ln_failed_count  );

         
         IF ln_update_counter > 0
         THEN
             XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'Records to Be Updated : ' ||  ln_update_counter  );
             BEGIN
             
                FORALL ln_counter1 IN lt_update_fnd_user_name.FIRST .. lt_update_fnd_user_name.LAST SAVE EXCEPTIONS
                       UPDATE xx_external_users
                       SET    userid             = lt_update_userid(ln_counter1)                            ,
                              password           = lt_update_password(ln_counter1)                          ,
                              person_first_name  = lt_update_person_first_name(ln_counter1)                 ,
                              person_middle_name = lt_update_person_middle_name(ln_counter1)                ,
                              person_last_name   = lt_update_person_last_name(ln_counter1)                  ,
                              email              = lt_update_email(ln_counter1)                             ,
                              orig_system        = NVL(orig_system, lt_update_orig_system(ln_counter1))     ,
                              contact_osr        = NVL(contact_osr, lt_update_contact_osr(ln_counter1))     ,
                              acct_site_osr      = NVL(acct_site_osr, lt_update_acct_site_osr(ln_counter1)) ,
                              webuser_osr        = NVL(webuser_osr, lt_update_webuser_osr(ln_counter1))     ,
                              access_code        = lt_update_access_code(ln_counter1)                       ,
                              permission_flag    = lt_update_permission_flag(ln_counter1)                   ,
                              status             = lt_update_status(ln_counter1)                            ,
                              site_key           = l_site_key                                               ,
                              party_type         = 'customer'                                               ,
                              party_id           = NVL(party_id, lt_update_party_id(ln_counter1))           ,
                              load_status        = NVL(p_load_status,'P')                                   ,
                              user_locked        = lt_update_user_locked(ln_counter1)                       ,
                              last_update_date   = SYSDATE                                                  ,
                              oid_update_date    = SYSDATE                                                  ,
                              last_updated_by    = fnd_global.user_id()                                     ,
                              last_update_login  = fnd_global.login_id()                                    ,
                              ext_upd_timestamp  = lt_update_ext_upd_timestamp(ln_counter1)                 
                       WHERE  fnd_user_name =  lt_update_fnd_user_name(ln_counter1);
                                   
            EXCEPTION
               WHEN OTHERS THEN
                    ln_exception_count := SQL%BULK_EXCEPTIONS.COUNT;
                    XX_EXTERNAL_USERS_DEBUG.log_debug_message(0,  'Number of Rows that failed Bulk Update: ' || ln_exception_count);
                    FOR i IN 1..ln_exception_count
                    LOOP
                        ln_record_index := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
                        XX_EXTERNAL_USERS_DEBUG.log_debug_message(0, 'Error #' || i || ' occurred during iteration #' || ln_record_index );
                        XX_EXTERNAL_USERS_DEBUG.log_debug_message(0, 'Error message is ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                        /*
                        XX_EXTERNAL_USERS_DEBUG.log_debug_message(0, 'Record #' || lt_update_ext_user_stg_id(ln_record_index));

                        ln_bulkerror_count                            := ln_bulkerror_count + 1;
                        lt_bulkerror_load_status(ln_bulkerror_count)  := 'E';
                        lt_bulkerror_load_message(ln_bulkerror_count) := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                        lt_bulkerror_record_id(ln_bulkerror_count)    := lt_update_ext_user_stg_id(ln_record_index);
                        */

                    END LOOP;
            END;
                        
            lt_update_ext_user_stg_id.DELETE;
            lt_update_ext_user_id.DELETE;
            lt_update_party_id.DELETE;
            lt_update_userid.DELETE;
            lt_update_password.DELETE;
            lt_update_person_first_name.DELETE;
            lt_update_person_middle_name.DELETE;
            lt_update_person_last_name.DELETE;
            lt_update_email.DELETE;
            lt_update_orig_system.DELETE;
            lt_update_contact_osr.delete;
            lt_update_acct_site_osr.DELETE;
            lt_update_webuser_osr.DELETE;
            lt_update_record_type.DELETE;
            lt_update_access_code.DELETE;
            lt_update_permission_flag.DELETE;
            lt_update_status.DELETE;
            lt_update_user_locked.DELETE;
            lt_update_load_status.DELETE;
            lt_update_batch_id.DELETE;
            lt_update_fnd_user_name.DELETE;
            lt_update_ext_upd_timestamp.DELETE;
         END IF; -- ln_update_counter > 0

         IF ln_insert_counter > 0
         THEN
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'Records to Be Added : ' ||  ln_insert_counter  );
            /*
            $if $$enable_debug $then
               FOR ln_counter1 IN lt_insert_fnd_user_name.FIRST..lt_insert_fnd_user_name.LAST
               LOOP
                  XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Insert Record[' || ln_counter1 || '] := ' || lt_insert_ext_user_id(ln_counter1) || ',' || lt_insert_fnd_user_name(ln_counter1) || ',' || l_site_key || ',' ||lt_insert_userid(ln_counter1));
               END LOOP; -- FOR ln_counter1 IN lt_update_fnd_user_name.FIRST .. lt_update_fnd_user_name.LAST
            $end
            */

            BEGIN
                FORALL ln_counter1 IN lt_insert_fnd_user_name.FIRST .. lt_insert_fnd_user_name.LAST SAVE EXCEPTIONS
                    INSERT INTO xx_external_users
                           ( ext_user_id
                           , userid
                           , password
                           , person_first_name
                           , person_middle_name
                           , person_last_name
                           , email
                           , orig_system
                           , contact_osr
                           , acct_site_osr
                           , webuser_osr
                           , access_code
                           , permission_flag
                           , status
                           , site_key
                           , party_type
                           , party_id
                           , fnd_user_name
                           , load_status
                           , user_locked
                           , creation_date
                           , created_by
                           , last_update_date
                           , last_updated_by
                           , last_update_login
                           , ext_upd_timestamp
                           )
                           VALUES
                           ( lt_insert_ext_user_id(ln_counter1)
                           , lt_insert_userid(ln_counter1)
                           , lt_insert_password(ln_counter1)
                           , lt_insert_person_first_name(ln_counter1)
                           , lt_insert_person_middle_name(ln_counter1)
                           , lt_insert_person_last_name(ln_counter1)
                           , lt_insert_email(ln_counter1)
                           , lt_insert_orig_system(ln_counter1)
                           , lt_insert_contact_osr(ln_counter1)
                           , lt_insert_acct_site_osr(ln_counter1)
                           , lt_insert_webuser_osr(ln_counter1)
                           , lt_insert_access_code(ln_counter1)
                           , lt_insert_permission_flag(ln_counter1)
                           , lt_insert_status(ln_counter1)
                           , l_site_key
                           , 'customer'
                           , lt_insert_party_id(ln_counter1)
                           , lt_insert_fnd_user_name(ln_counter1)
                           , NVL(p_load_status,'P')
                           , lt_insert_user_locked(ln_counter1)
                           , SYSDATE
                           , fnd_global.user_id()
                           , SYSDATE
                           , fnd_global.user_id()
                           , fnd_global.login_id()
                           , lt_insert_ext_upd_timestamp(ln_counter1)
                           );
            EXCEPTION
               WHEN OTHERS THEN
                    ln_exception_count := SQL%BULK_EXCEPTIONS.COUNT;
                    XX_EXTERNAL_USERS_DEBUG.log_debug_message(0,  'Number of Rows that failed Bulk Insert: ' || ln_exception_count);

                    FOR i IN 1..ln_exception_count
                    LOOP
                        ln_record_index := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
                        XX_EXTERNAL_USERS_DEBUG.log_debug_message(0, 'Error # ' || i || ' occurred during iteration # ' || ln_record_index );
                        XX_EXTERNAL_USERS_DEBUG.log_debug_message(0, 'Error message is ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                        /*
                        XX_EXTERNAL_USERS_DEBUG.log_debug_message(0, 'Record # ' || lt_insert_ext_user_stg_id(ln_record_index));

                        ln_bulkerror_count                            := ln_bulkerror_count + 1;
                        lt_bulkerror_load_status(ln_bulkerror_count)  := 'E';
                        lt_bulkerror_load_message(ln_bulkerror_count) := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                        lt_bulkerror_record_id(ln_bulkerror_count)    := lt_insert_ext_user_stg_id(ln_record_index);
                        */

                    END LOOP;
            END;

            lt_insert_ext_user_stg_id.DELETE;
            lt_insert_ext_user_id.DELETE;
            lt_insert_party_id.DELETE;
            lt_insert_userid.DELETE;
            lt_insert_password.DELETE;
            lt_insert_person_first_name.DELETE;
            lt_insert_person_middle_name.DELETE;
            lt_insert_person_last_name.DELETE;
            lt_insert_email.DELETE;
            lt_insert_orig_system.DELETE;
            lt_insert_contact_osr.DELETE;
            lt_insert_acct_site_osr.DELETE;
            lt_insert_webuser_osr.DELETE;
            lt_insert_record_type.DELETE;
            lt_insert_access_code.DELETE;
            lt_insert_permission_flag.DELETE;
            lt_insert_status.DELETE;
            lt_insert_user_locked.DELETE;
            lt_insert_load_status.DELETE;
            lt_insert_batch_id.DELETE;
            lt_insert_fnd_user_name.DELETE;
            lt_insert_ext_upd_timestamp.DELETE;

         END IF; -- ln_insert_counter > 0

         -- --------------------------------------------------------------------------
         -- Update Status and Message on Staging Table
         -- --------------------------------------------------------------------------
         /*
         $if $$enable_debug $then
            FOR ln_counter1 IN lt_record_id.FIRST..lt_record_id.LAST
            LOOP
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Record[' || ln_counter1 || '] := ' || lt_record_id(ln_counter1) || ',' || lt_load_status(ln_counter1) || ',' || lt_load_message(ln_counter1));
            END LOOP; -- FOR ln_counter1 IN lt_update_fnd_user_name.FIRST .. lt_update_fnd_user_name.LAST

         $end
         */

         BEGIN
            FORALL ln_counter1 IN lt_record_id.FIRST .. lt_record_id.LAST SAVE EXCEPTIONS
               UPDATE XX_EXTERNAL_USERS_STG
               SET    load_status  = lt_load_status(ln_counter1),
                      error_text   = lt_load_message(ln_counter1)
               WHERE  external_users_stg_id = lt_record_id(ln_counter1);
         EXCEPTION
            WHEN OTHERS THEN
                 ln_exception_count := SQL%BULK_EXCEPTIONS.COUNT;
                 XX_EXTERNAL_USERS_DEBUG.log_debug_message(0,  'Number of Rows that failed : ' || ln_exception_count);
                 FOR i IN 1..ln_exception_count
                 LOOP
                     XX_EXTERNAL_USERS_DEBUG.log_debug_message(0, 'Error #' || i || ' occurred during ' || 'iteration #' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX );
                     XX_EXTERNAL_USERS_DEBUG.log_debug_message(0, 'Error message is ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                 END LOOP;
         END;

         /*
         IF ln_bulkerror_count > 0
         THEN
            BEGIN
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(0,  'Number of Rows that failed Bulk Update : ' || ln_bulkerror_count);
               FORALL ln_counter1 IN lt_bulkerror_record_id.FIRST .. lt_bulkerror_record_id.LAST SAVE EXCEPTIONS
                  UPDATE XX_EXTERNAL_USERS_STG
                  SET    load_status  = lt_bulkerror_load_status(ln_counter1),
                         error_text   = lt_bulkerror_load_message(ln_counter1)
                  WHERE  external_users_stg_id = lt_bulkerror_record_id(ln_counter1);
            EXCEPTION
               WHEN OTHERS THEN
                    ln_exception_count := SQL%BULK_EXCEPTIONS.COUNT;
                    XX_EXTERNAL_USERS_DEBUG.log_debug_message(0,  'Number of Rows that failed : ' || ln_exception_count);
                    FOR i IN 1..ln_exception_count
                    LOOP
                        XX_EXTERNAL_USERS_DEBUG.log_debug_message(0, 'Error #' || i || ' occurred during '|| 'iteration #' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
                        XX_EXTERNAL_USERS_DEBUG.log_debug_message(0, 'Error message is ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                    END LOOP;
            END;

            ln_failed_count    := ln_failed_count +  ln_bulkerror_count;
            ln_bulkerror_count := 0;

            lt_bulkerror_load_status.DELETE;
            lt_bulkerror_load_message.DELETE;
            lt_bulkerror_record_id.DELETE;

         END IF; -- ln_bulkerror_count > 0
         */

         EXIT WHEN c_webcontact_stg_cur%NOTFOUND;

         lt_record_id.DELETE;
         lt_load_status.DELETE;
         lt_load_message.DELETE;

         COMMIT;

      END LOOP;

      CLOSE c_webcontact_stg_cur;

      --fnd_file.put_line (fnd_file.output, 'Total Count            : ' || ln_record_count);
      --fnd_file.put_line (fnd_file.output, 'Erorrs                 : ' || ln_failed_count);

      IF ln_record_count > 0
      THEN
         IF  ln_failed_count = ln_record_count
         THEN
             x_retcode := 2;
             x_errbuf  := to_char(ln_failed_count) || ' records failed';
         ELSIF  ln_failed_count > 0
         THEN
             x_retcode := 1;
             x_errbuf  := to_char(ln_failed_count) || ' records failed';
         ELSE
             x_retcode := 0;
             x_errbuf  := 'Successfully Processed ' || ln_sucess_count || ' Records';
         END IF; --  ln_failed_count > 0
      ELSE
          x_retcode := 0;
          x_errbuf  := 'No records Processed';
      END IF; -- ln_record_count > 0
      XX_EXTERNAL_USERS_DEBUG.disable_debug;

/*
   EXCEPTION
     WHEN OTHERS THEN
         ROLLBACK;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.web_contact_conv_batch');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         fnd_file.put_line (fnd_file.output, fnd_message.get());
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,  fnd_message.get());

         IF c_webcontact_stg_cur%ISOPEN
         THEN
            CLOSE c_webcontact_stg_cur;
         END IF; -- c_fnd_user%ISOPEN

         x_retcode := 2;
         x_errbuf  := fnd_message.get();
*/
   END web_contact_conv_batch;

   -- ===========================================================================
   -- Name             :
   -- Description      :
   --
   --
   --
   -- Parameters       :
   --
   -- ===========================================================================
   PROCEDURE process_new_user_access ( x_errbuf            OUT NOCOPY    VARCHAR2
                                     , x_retcode           OUT NOCOPY    VARCHAR2
                                     , p_force             IN            VARCHAR2  DEFAULT NULL
                                     , p_date              IN            VARCHAR2  DEFAULT NULL
                                     , p_load_status       IN            VARCHAR2  DEFAULT NULL
                                     )
   IS

      TYPE C_FND_NEW_USER_TYPE   IS TABLE OF webcontact_user_rec_type INDEX BY BINARY_INTEGER;
      TYPE r_webcontact_cur_type IS REF CURSOR;

      c_webcontact_cur           r_webcontact_cur_type;

      lc_fnd_new_users         C_FND_NEW_USER_TYPE;
      ln_bulk_limit            NUMBER := 100;

      lt_curr_run_date         TIMESTAMP;
      lt_last_run_date         TIMESTAMP;
      lc_return_status         VARCHAR(60);
      ln_msg_count             NUMBER;
      lc_msg_data              VARCHAR2(4000);
      p_date2                  DATE := NULL; 
      ln_counter               PLS_INTEGER  :=  0;
      ln_sucess_count          PLS_INTEGER  :=  0;
      ln_failed_count          PLS_INTEGER  :=  0;
      ln_record_count          PLS_INTEGER  :=  0;

      l_date                   DATE;
      l_fnd_user_rec           XX_EXTERNAL_USERS_PVT.fnd_user_rec_type;
      l_cur_extuser_rec        XX_EXTERNAL_USERS_PVT.external_user_rec_type;
      l_new_extuser_rec        XX_EXTERNAL_USERS_PVT.external_user_rec_type;

   BEGIN
      
      XX_EXTERNAL_USERS_DEBUG.enable_debug;
      
      IF p_date IS NOT NULL THEN
        p_date2 := TO_DATE(p_date,'RRRR/MM/DD HH24:MI:SS');
      END IF;
   
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Executing XX_EXTERNAL_USERS_CONV.process_new_user_access');
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Parameters:');
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, '  Force = ' || p_force);
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, '  Date  = ' || p_date2);
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, '  Load Status  = ' || p_load_status);
      
      XX_COM_JOB_RUN_STATUS_PKG.get_program_run_date ( p_program_name       => 'PROCESS_NEW_USER_ACCESS'
                                                     , x_run_date           => lt_last_run_date
                                                     , x_return_status      => lc_return_status
                                                     , x_msg_count          => ln_msg_count
                                                     , x_msg_data           => lc_msg_data
                                                     );

      ln_sucess_count :=  0;
      ln_failed_count :=  0;
      ln_record_count :=  0;

      SELECT SYSTIMESTAMP
      INTO   lt_curr_run_date
      FROM DUAL;

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Last Run Date    : ' || lt_last_run_date);
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Current Run Date : ' || lt_curr_run_date);

      -- CURSOR  c_fnd_new_user (lt_last_run_date, lt_curr_run_date)
         l_date  :=   NVL(p_date2, lt_last_run_date);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Extract Date     : ' || l_date);

         OPEN c_webcontact_cur FOR  SELECT fnd.rowid "fnd_user_rowid",
                                           fnd.user_id,
                                           fnd.user_name,
                                           fnd.description,
                                           fnd.customer_id,
                                           ext.rowid "ext_user_rowid",
                                           ext.ext_user_id,
                                           ext.userid,
                                           ext.password,
                                           ext.person_first_name,
                                           ext.person_middle_name,
                                           ext.person_last_name,
                                           ext.email,
                                           ext.party_id,
                                           ext.status,
                                           'A0' "orig_system",
                                           ext.contact_osr,
                                           ext.acct_site_osr,
                                           ext.webuser_osr,
                                           ext.access_code,
                                           ext.permission_flag,
                                           ext.site_key,
                                           ext.end_date,
                                           ext.load_status,
                                           ext.user_locked,
                                           ext.created_by,
                                           ext.creation_date,
                                           ext.last_update_date,
                                           ext.last_updated_by,
                                           ext.last_update_login
                                    FROM   fnd_user fnd,
                                           xx_external_users ext
                                    WHERE fnd.user_name = ext.fnd_user_name
                                    AND   ext.load_status = NVL(p_load_status,'P')
                                    AND   fnd.creation_date >= l_date;

      LOOP
         FETCH c_webcontact_cur BULK COLLECT INTO lc_fnd_new_users Limit ln_bulk_limit ;

         $if $$enable_debug $then
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Fetched  : ' || c_webcontact_cur%ROWCOUNT);
         $end

         IF lc_fnd_new_users.COUNT = 0
         THEN
             EXIT;
         END IF; -- lc_fnd_new_users.COUNT =0 THEN

         FOR ln_counter in lc_fnd_new_users.FIRST .. lc_fnd_new_users.LAST
         LOOP
            ln_record_count           :=   ln_record_count+1;

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Processing Record ' || ln_record_count);

            l_fnd_user_rec.fnd_user_rowid              := lc_fnd_new_users(ln_counter).fnd_user_rowid;
            l_fnd_user_rec.user_id                     := lc_fnd_new_users(ln_counter).user_id;
            l_fnd_user_rec.user_name                   := lc_fnd_new_users(ln_counter).user_name;
            l_fnd_user_rec.description                 := lc_fnd_new_users(ln_counter).description;
            l_fnd_user_rec.customer_id                 := lc_fnd_new_users(ln_counter).customer_id;

            l_new_extuser_rec.ext_user_rowid           := lc_fnd_new_users(ln_counter).ext_user_rowid;
            l_new_extuser_rec.ext_user_id              := lc_fnd_new_users(ln_counter).ext_user_id;
            l_new_extuser_rec.userid                   := lc_fnd_new_users(ln_counter).userid;
            l_new_extuser_rec.password                 := lc_fnd_new_users(ln_counter).password;
            l_new_extuser_rec.person_first_name        := lc_fnd_new_users(ln_counter).person_first_name;
            l_new_extuser_rec.person_middle_name       := lc_fnd_new_users(ln_counter).person_middle_name;
            l_new_extuser_rec.person_last_name         := lc_fnd_new_users(ln_counter).person_last_name;
            l_new_extuser_rec.email                    := lc_fnd_new_users(ln_counter).email;
            l_new_extuser_rec.party_id                 := lc_fnd_new_users(ln_counter).party_id;
            l_new_extuser_rec.status                   := lc_fnd_new_users(ln_counter).status;
            l_new_extuser_rec.orig_system              := lc_fnd_new_users(ln_counter).orig_system;
            l_new_extuser_rec.contact_osr              := lc_fnd_new_users(ln_counter).contact_osr;
            l_new_extuser_rec.acct_site_osr            := lc_fnd_new_users(ln_counter).acct_site_osr;
            l_new_extuser_rec.access_code              := lc_fnd_new_users(ln_counter).access_code;
            l_new_extuser_rec.permission_flag          := lc_fnd_new_users(ln_counter).permission_flag;
            l_new_extuser_rec.site_key                 := lc_fnd_new_users(ln_counter).site_key;
            l_new_extuser_rec.end_date                 := lc_fnd_new_users(ln_counter).end_date;
            l_new_extuser_rec.load_status              := lc_fnd_new_users(ln_counter).load_status;
            l_new_extuser_rec.user_locked              := lc_fnd_new_users(ln_counter).user_locked;
            l_new_extuser_rec.created_by               := lc_fnd_new_users(ln_counter).created_by;
            l_new_extuser_rec.creation_date            := lc_fnd_new_users(ln_counter).creation_date;
            l_new_extuser_rec.last_update_date         := lc_fnd_new_users(ln_counter).last_update_date;
            l_new_extuser_rec.last_updated_by          := lc_fnd_new_users(ln_counter).last_updated_by;
            l_new_extuser_rec.last_update_login        := lc_fnd_new_users(ln_counter).last_update_login;

            $if $$enable_debug $then
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  '*********************************************************** ');
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_fnd_user_rec.fnd_user_rowid              : ' ||  l_fnd_user_rec.fnd_user_rowid        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_fnd_user_rec.user_id                     : ' ||  l_fnd_user_rec.user_id               );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_fnd_user_rec.user_name                   : ' ||  l_fnd_user_rec.user_name             );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_fnd_user_rec.description                 : ' ||  l_fnd_user_rec.description           );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_fnd_user_rec.customer_id                 : ' ||  l_fnd_user_rec.customer_id           );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  '------------------------------------------------------------------------' );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.ext_user_rowid           : ' ||  l_new_extuser_rec.ext_user_rowid     );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.ext_user_id              : ' ||  l_new_extuser_rec.ext_user_id        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.userid                   : ' ||  l_new_extuser_rec.userid             );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.password                 : ' ||  l_new_extuser_rec.password           );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.person_first_name        : ' ||  l_new_extuser_rec.person_first_name  );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.person_middle_name       : ' ||  l_new_extuser_rec.person_middle_name );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.person_last_name         : ' ||  l_new_extuser_rec.person_last_name   );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.email                    : ' ||  l_new_extuser_rec.email              );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.party_id                 : ' ||  l_new_extuser_rec.party_id           );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.status                   : ' ||  l_new_extuser_rec.status             );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.orig_system              : ' ||  l_new_extuser_rec.orig_system        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.contact_osr              : ' ||  l_new_extuser_rec.contact_osr        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.acct_site_osr            : ' ||  l_new_extuser_rec.acct_site_osr      );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.webuser_osr              : ' ||  l_new_extuser_rec.webuser_osr        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.access_code              : ' ||  l_new_extuser_rec.access_code        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.permission_flag          : ' ||  l_new_extuser_rec.permission_flag    );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.site_key                 : ' ||  l_new_extuser_rec.site_key           );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.end_date                 : ' ||  l_new_extuser_rec.end_date           );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.load_status              : ' ||  l_new_extuser_rec.load_status        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.user_locked              : ' ||  l_new_extuser_rec.user_locked        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.created_by               : ' ||  l_new_extuser_rec.created_by);
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.creation_date            : ' ||  l_new_extuser_rec.creation_date);
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.last_update_date         : ' ||  l_new_extuser_rec.last_update_date);
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.last_updated_by          : ' ||  l_new_extuser_rec.last_updated_by);
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.last_update_login        : ' ||  l_new_extuser_rec.last_update_login);
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  '------------------------------------------------------------------------' );
            $end

            update_fnd_user ( p_cur_extuser_rec            => l_cur_extuser_rec
                            , p_new_extuser_rec            => l_new_extuser_rec
                            , p_fnd_user_rec               => l_fnd_user_rec
                            , x_return_status              => lc_return_status
                            , x_msg_count                  => ln_msg_count
                            , x_msg_data                   => lc_msg_data
                            );

            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS
            THEN
               ln_failed_count          := ln_failed_count+1;
            ELSE
               ln_sucess_count          := ln_sucess_count+1;
            END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS

         END LOOP;

         EXIT WHEN c_webcontact_cur%NOTFOUND;

      END LOOP;

      CLOSE c_webcontact_cur;

      fnd_file.put_line (fnd_file.output, 'Processed Successfully : ' || ln_sucess_count);
      fnd_file.put_line (fnd_file.output, 'Erorrs                 : ' || ln_failed_count);
      fnd_file.put_line (fnd_file.output, 'Total Count            : ' || ln_record_count);

      XX_COM_JOB_RUN_STATUS_PKG.update_program_run_date ( p_program_name       => 'PROCESS_NEW_USER_ACCESS'
                                                        , p_run_date           => lt_curr_run_date
                                                        , x_return_status      => lc_return_status
                                                        , x_msg_count          => ln_msg_count
                                                        , x_msg_data           => lc_msg_data
                                                        );

      IF ln_record_count > 0
      THEN
         IF  ln_failed_count = ln_record_count
         THEN
             x_retcode := 2;
             x_errbuf  := to_char(ln_failed_count) || ' records failed';
         ELSIF  ln_failed_count > 0
         THEN
             x_retcode := 1;
             x_errbuf  := to_char(ln_failed_count) || ' records failed';
         ELSE
             x_retcode := 0;
             x_errbuf  := 'Successfully Processed ' || ln_sucess_count || ' Records';
         END IF; --  ln_failed_count > 0
      ELSE
          x_retcode := 0;
          x_errbuf  := 'No records Processed';
      END IF; -- ln_record_count > 0

   EXCEPTION
     WHEN OTHERS THEN
         ROLLBACK;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.process_new_user_access');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         fnd_file.put_line (fnd_file.output, fnd_message.get());
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,  fnd_message.get());

         IF c_webcontact_cur%ISOPEN
         THEN
            CLOSE c_webcontact_cur;
         END IF; -- c_fnd_user%ISOPEN

   END process_new_user_access;


   -- ===========================================================================
   -- Name             :
   -- Description      :
   --
   --
   --
   -- Parameters       :
   --
   -- ===========================================================================
   PROCEDURE update_fnd_user( p_cur_extuser_rec         IN         XX_EXTERNAL_USERS_PVT.external_user_rec_type
                            , p_new_extuser_rec         IN         XX_EXTERNAL_USERS_PVT.external_user_rec_type
                            , p_fnd_user_rec            IN         XX_EXTERNAL_USERS_PVT.fnd_user_rec_type
                            , x_return_status           OUT NOCOPY VARCHAR2
                            , x_msg_count               OUT        NUMBER
                            , x_msg_data                OUT NOCOPY VARCHAR2
                         )
   AS
   BEGIN
      SAVEPOINT update_fnd_user_sv;

      XX_EXTERNAL_USERS_PVT.update_fnd_user ( p_cur_extuser_rec            => p_cur_extuser_rec
                                            , p_new_extuser_rec            => p_new_extuser_rec
                                            , p_fnd_user_rec               => p_fnd_user_rec
                                            , x_return_status              => x_return_status
                                            , x_msg_count                  => x_msg_count
                                            , x_msg_data                   => x_msg_data
                                            );

      IF X_return_status <> FND_API.G_RET_STS_SUCCESS
      THEN
         ROLLBACK TO SAVEPOINT update_fnd_user_sv;
      ELSE
         COMMIT;
      END IF;


   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK TO SAVEPOINT update_fnd_user_sv;

   END update_fnd_user;


   -- ===========================================================================
   -- Name             :
   -- Description      :
   --
   --
   --
   -- Parameters       :
   --
   -- ===========================================================================
   PROCEDURE generate_ldif_file ( x_errbuf            OUT NOCOPY    VARCHAR2
                                , x_retcode           OUT NOCOPY    VARCHAR2
                                , p_load_status       IN            VARCHAR2 DEFAULT NULL
                                )
   IS
      /*CURSOR c_webusers_declare
      IS
         SELECT trim('cn=' ||  FND_USER_NAME || ',ou=na,cn=odcustomer,cn=odexternal,cn=users,dc=odcorp,dc=net') "DN",
                trim(PERSON_FIRST_NAME)  "GIVENNAME",
                trim(PERSON_LAST_NAME)  "SN",
                trim(REPLACE(person_last_name || NVL2(person_middle_name,  ' ' || person_middle_name , '') || ' ' ||person_first_name,'  ',' '))  "DISPLAYNAME",
                trim(EMAIL)  "MAIL",
                trim(FND_USER_NAME)  "UID",
                trim(FND_USER_NAME)  "CN",
                trim(XX_DECIPHER(PASSWORD))  "USERPASSWORD",
                trim(EMAIL)  "ORCLUSERPRINCIPALNAME"
         FROM   xx_external_users;*/
         
      TYPE c_webusers_rec_type IS RECORD (
        DN                      VARCHAR2(100),
        GIVENNAME               VARCHAR2(150),
        SN                      VARCHAR2(150),
        DISPLAYNAME             VARCHAR2(400),
        MAIL                    VARCHAR2(255),
        UID                     VARCHAR2(100),
        CN                      VARCHAR2(100),
        USERPASSWORD            VARCHAR2(255),
        ORCLUSERPRINCIPALNAME   VARCHAR2(255)
      );
      
         
      TYPE c_webusers_type    IS REF CURSOR;
      c_webusers              c_webusers_type;
      TYPE EXT_USER_REC_TYP   IS TABLE OF c_webusers_rec_type INDEX BY BINARY_INTEGER;
      lc_external_users       EXT_USER_REC_TYP;          
      l_password_hash         RAW(2000);
      l_password_hash_str     VARCHAR2(2000);

      lv_select_query         VARCHAR2(2000);
      ln_bulk_limit           PLS_INTEGER := 100;
      

   BEGIN
    
    IF TRIM(p_load_status) IS NULL THEN
    
      lv_select_query := 'SELECT trim(''cn='' ||  FND_USER_NAME || '',ou=na,cn=odcustomer,cn=odexternal,cn=users,dc=odcorp,dc=net''),
                trim(PERSON_FIRST_NAME),
                trim(PERSON_LAST_NAME),
                trim(REPLACE(person_first_name || NVL2(person_middle_name,  '' '' || person_middle_name , '''') || '' '' ||person_last_name,''  '','' '')),
                trim(EMAIL),
                trim(FND_USER_NAME),
                trim(FND_USER_NAME),
                trim(XX_DECIPHER(PASSWORD)),
                trim(EMAIL)
         FROM   xx_external_users';
         
    ELSE     
    
      lv_select_query := 'SELECT trim(''cn='' ||  FND_USER_NAME || '',ou=na,cn=odcustomer,cn=odexternal,cn=users,dc=odcorp,dc=net''),
                trim(PERSON_FIRST_NAME),
                trim(PERSON_LAST_NAME),
                trim(REPLACE(person_first_name || NVL2(person_middle_name,  '' '' || person_middle_name , '''') || '' '' ||person_last_name,''  '','' '')),
                trim(EMAIL),
                trim(FND_USER_NAME),
                trim(FND_USER_NAME),
                trim(XX_DECIPHER(PASSWORD)),
                trim(EMAIL)
         FROM   xx_external_users ' ||
         ' WHERE  load_status = ''' || p_load_status || '''';
         
    END IF;

      XX_EXTERNAL_USERS_DEBUG.enable_debug;
      write_output('#');
      write_output('# LDIF FILE for BSD Users having Usage or Billing Access ');
      write_output('#');
      write_output('');
      write_output('');
      fnd_file.put_line (fnd_file.log, 'Query Used - ' || lv_select_query);
      OPEN c_webusers FOR lv_select_query;
      LOOP
         -- -------------------------------------------------------------------------
         -- Bulk Collect from Cursor
         -- -------------------------------------------------------------------------
         FETCH c_webusers BULK COLLECT INTO lc_external_users LIMIT ln_bulk_limit ;

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'Fetched  : ' || c_webusers%ROWCOUNT);
         IF lc_external_users.COUNT = 0
         THEN
             EXIT;
         END IF; -- lc_new_users.COUNT =0 THEN


         FOR ln_counter1 in lc_external_users.FIRST..lc_external_users.LAST
         LOOP
            write_output('');
            write_output('# '                       || lc_external_users(ln_counter1).dn);

                
            write_output('dn: '                     || lc_external_users(ln_counter1).dn);
            IF lc_external_users(ln_counter1).givenname IS NOT NULL THEN
             write_output('givenname: '              || lc_external_users(ln_counter1).givenname);
            END IF; 
    
            write_output('sn: '                     || NVL(lc_external_users(ln_counter1).sn,'.'));
            
            IF lc_external_users(ln_counter1).displayname IS NOT NULL THEN
             write_output('displayname: '            || lc_external_users(ln_counter1).displayname);
            END IF;
            IF lc_external_users(ln_counter1).mail IS NOT NULL THEN
             write_output('mail: '                   || lc_external_users(ln_counter1).mail);
            END IF;
            
            write_output('uid: '                    || lc_external_users(ln_counter1).uid);
            write_output('cn: '                     || lc_external_users(ln_counter1).CN);

            IF lc_external_users(ln_counter1).userpassword IS NOT NULL
            THEN
               l_password_hash     := DBMS_CRYPTO.HASH (UTL_RAW.CAST_TO_RAW(lc_external_users(ln_counter1).userpassword),DBMS_CRYPTO.HASH_SH1);
               l_password_hash_str := UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_ENCODE(l_password_hash));
               write_output('userpassword: {SHA}'      || l_password_hash_str);
            END IF; -- lc_external_users(ln_counter1).userpassword IS NOT NULL

            -- write_output('orcluserprincipalname: '  || lc_external_users(ln_counter1).orcluserprincipalname);
            write_output('objectclass: inetorgperson');
            write_output('objectclass: person');
            write_output('objectclass: orcluserv2');
            -- write_output('objectclass: orcladuser');
            write_output('objectclass: organizationalPerson');
            write_output('objectclass: top');
            write_output('');
            write_output('');

         END LOOP; -- FOR ln_counter1 in lc_external_users.FIRST..lc_external_users.LAST

      END LOOP;

      CLOSE c_webusers;

      write_output('#');
      write_output('# End of LDIF FILE for BSD Users having Usage or Billing Access ');
      write_output('#');

   END generate_ldif_file;
  
   -- ===========================================================================
   -- Name             :update_external_table_status
   -- Description      :This procedure is used to update the load_status to 'C'
   --                   in xx_external_users for all the records for which
   --                   responsibilities are processed
   --
   --
   -- Parameters       : --
   --
   -- ===========================================================================
   PROCEDURE update_external_table_status ( x_errbuf            OUT NOCOPY    VARCHAR2
                                          , x_retcode           OUT NOCOPY    VARCHAR2 
                                          )
   IS
   
   CURSOR ext_user_cur IS
   SELECT fnd_user_name,access_code,party_id,ext_user_id,orig_system
   FROM xx_external_users
   WHERE load_status NOT LIKE 'C' AND access_code NOT LIKE '01';
   
   TYPE ext_user_rec_type IS RECORD (
    fnd_name      VARCHAR2(100),
    acc_code      VARCHAR2(30),
    pid           NUMBER,
    usrid         NUMBER,
    orig_sys       VARCHAR2(30)
   );
   
   TYPE EXT_USER_REC_TBL   IS TABLE OF ext_user_rec_type INDEX BY BINARY_INTEGER;
   lc_external_users       EXT_USER_REC_TBL; 
   ln_bulk_limit           PLS_INTEGER := 100;
   total_count             NUMBER := 0;
   fnd_failures            NUMBER := 0;
   org_id_failures         NUMBER := 0;
   irec_failures           NUMBER := 0;
   resp_not_created        NUMBER := 0;
   success_count           NUMBER := 0;
   l_org_id                HZ_CUST_ACCT_SITES_ALL.ORG_ID%TYPE;
   l_org_name              HR_ALL_ORGANIZATION_UNITS.NAME%TYPE;
   l_user_id               FND_USER.USER_ID%TYPE;
   l_resp_id               FND_RESPONSIBILITY.responsibility_id%TYPE;
   l_appl_id               FND_RESPONSIBILITY.application_id%TYPE;
   l_resp_desc             FND_RESPONSIBILITY_TL.responsibility_name%TYPE;
   x_return_status         VARCHAR2(30);
   x_msg_count             NUMBER;
   x_msg_data              VARCHAR2(2000);
   l_exists                VARCHAR2(10);
   BEGIN
    
    fnd_file.put_line (fnd_file.log,'Updating Load Status to C for Users having access code 01');
    
    UPDATE xx_external_users SET load_status = 'C'
    WHERE load_status NOT LIKE 'C' AND access_code = '01';

    COMMIT;

    fnd_file.put_line (fnd_file.log,'Updation for access code 01 Complete');
    
    fnd_file.put_line (fnd_file.log,'Processing Other Access Codes.......');
    
     OPEN ext_user_cur;
     
    LOOP
     
     FETCH ext_user_cur BULK COLLECT INTO lc_external_users LIMIT ln_bulk_limit;
      
      IF lc_external_users.COUNT = 0
      THEN
         EXIT;
      END IF; -- lc_new_users.COUNT =0 THEN

      total_count := total_count + lc_external_users.COUNT;

     FOR ln_counter1 IN lc_external_users.FIRST..lc_external_users.LAST
     LOOP
     
         l_user_id := NULL;
         
         BEGIN
            SELECT user_id INTO l_user_id
            FROM FND_USER
            WHERE USER_NAME = lc_external_users(ln_counter1).fnd_name;
         EXCEPTION WHEN NO_DATA_FOUND THEN
             fnd_failures := fnd_failures + 1;
         END;
         
      IF l_user_id IS NOT NULL THEN     
        
          xx_external_users_pvt.get_account_org( p_cust_acct_id      => NULL
                     , p_acct_site_id      => NULL
                     , p_org_contact_id    => lc_external_users(ln_counter1).pid
                     , px_org_id           => l_org_id
                     , x_org_name          => l_org_name
                     , x_return_status     => x_return_status
                     , x_msg_count         => x_msg_count
                     , x_msg_data          => x_msg_data
                     );
        
        IF x_return_status <> FND_API.G_RET_STS_SUCCESS
        THEN
            org_id_failures := org_id_failures + 1;
        ELSE
          
           xx_external_users_pvt.get_resp_id ( p_orig_system      => lc_external_users(ln_counter1).orig_sys
                  , p_orig_system_access     => lc_external_users(ln_counter1).acc_code
                  , p_org_name               => l_org_name
                  , x_resp_id                => l_resp_id
                  , x_appl_id                => l_appl_id
                  , x_responsibility_name    => l_resp_desc
                  , x_return_status          => x_return_status
                  , x_msg_count              => x_msg_count
                  , x_msg_data               => x_msg_data
                  );

           IF x_return_status <> FND_API.G_RET_STS_SUCCESS
           THEN
               irec_failures := irec_failures + 1;
           ELSE
              BEGIN
              
                l_exists := NULL;
                
                SELECT '1' INTO l_exists
                FROM fnd_user_resp_groups
                WHERE user_id=l_user_id 
                AND responsibility_id=l_resp_id 
                AND responsibility_application_id=l_appl_id
                AND TRUNC(end_date) IS NULL;
              EXCEPTION WHEN NO_DATA_FOUND THEN
                NULL;
                resp_not_created := resp_not_created + 1;
              END;

             IF l_exists IS NOT NULL THEN
               UPDATE xx_external_users
               SET load_status = 'C',
                   last_update_date   = SYSDATE,
                   last_updated_by    = fnd_global.user_id(),
                   last_update_login  = fnd_global.login_id()
               WHERE ext_user_id = lc_external_users(ln_counter1).usrid;
               success_count := success_count + 1;
             END IF;  
             
           END IF;     
        END IF;  
      END IF; -- l_user_id condition ends
     END LOOP; -- For Loop Ends
     COMMIT;
    END LOOP; -- Cursor loop Ends
   
   fnd_file.put_line (fnd_file.log,'Processing Complete.');
    
   fnd_file.put_line (fnd_file.output, '############################## Start Run Statistics For Records NOT Having Access Code 01 ###############################'); 
   fnd_file.put_line (fnd_file.output, 'Total Records Processed:' || total_count);
   fnd_file.put_line (fnd_file.output, 'Records Not In FND_USER:' || fnd_failures);
   fnd_file.put_line (fnd_file.output, 'Records For Which Load_Status Updated In xx_external_users:' || success_count);
   fnd_file.put_line (fnd_file.output, 'Org ID Derivation Failed:' || org_id_failures);
   fnd_file.put_line (fnd_file.output, 'IREC Responsibility ID Derivation Failed:' || irec_failures);
   fnd_file.put_line (fnd_file.output, 'Responsibility Does not exist in fnd_user_resp_groups:' || resp_not_created);
   fnd_file.put_line (fnd_file.output, '########################################################## End Run Statistics ############################################'); 
   
 EXCEPTION WHEN OTHERS THEN
   fnd_file.put_line (fnd_file.log, 'Unexpected Error in proecedure update_external_table_status - Error - '||SQLERRM);
   x_errbuf := 'Unexpected Error in proecedure update_external_table_status - Error - '||SQLERRM;
   x_retcode := 2;    
 END update_external_table_status;  


   -- ===========================================================================
   -- Name             :update_external_table_status
   -- Description      :This procedure is used to update the load_status to 'C'
   --                   in xx_external_users for all the records for which
   --                   responsibilities are processed
   --
   --
   -- Parameters       : --
   --
   -- ===========================================================================
   
    PROCEDURE webuser_conv_wrapper         ( x_errbuf        OUT NOCOPY    VARCHAR2
                                          , x_retcode       OUT NOCOPY    VARCHAR2
                                          , p_load_status   IN            VARCHAR2
                                          , p_force         IN            VARCHAR2
                                          , p_date          IN            VARCHAR2
                                          , p_submit_ext    IN            VARCHAR2
                                          , p_submit_main   IN            VARCHAR2
                                          , p_submit_ldif   IN            VARCHAR2
                                          , p_submit_access IN            VARCHAR2
                                          )      
                                          
   IS
   
   lv_phase              VARCHAR2(50);
   lv_status             VARCHAR2(50);
   lv_dev_phase          VARCHAR2(15);
   lv_dev_status         VARCHAR2(15);
   lb_wait               BOOLEAN;
   lv_message            VARCHAR2(4000);
   lv_error_exist        VARCHAR2(1);
   lv_warning            VARCHAR2(1);
   lt_conc_request_id    fnd_concurrent_requests.request_id%TYPE;
   submit_fail_e         EXCEPTION;
   
   BEGIN
   
   ----------------------------------------------------------------------
   -- Submit The WebUser Externsibility Creation Program
   ----------------------------------------------------------------------
   
    IF p_submit_ext = 'Y' THEN
    
       lt_conc_request_id := 0;
    
       lt_conc_request_id := FND_REQUEST.submit_request
                                 (   application => 'XXCNV',
                                     program     => 'XXCNV_UPD_EXT_WEBCONTACTS',
                                     description => NULL,
                                     start_time  => NULL,
                                     sub_request => FALSE
                                 );

       IF lt_conc_request_id = 0 THEN
            fnd_file.put_line (fnd_file.log, 'Extensible Attributes Program failed to submit: ' || SQLERRM);
            x_errbuf  := 'Extensible Attributes Program failed to submit: ' || SQLERRM;
           RAISE submit_fail_e;
       ELSE
          fnd_file.put_line (fnd_file.log, 'Extensible Attributes Program Submitted');
          COMMIT;
       END IF;
        
    END IF;                            
    
   ----------------------------------------------------------------------
   -- Submit The WebUser Conversion MAIN concurrent Program
   ----------------------------------------------------------------------
    
    IF p_submit_main = 'Y' THEN
    
       lt_conc_request_id := 0;
    
       lt_conc_request_id := FND_REQUEST.submit_request
                                 (   application => 'XXCNV',
                                     program     => 'XXCNV_WEBUSER_CONV_MASTER',
                                     description => NULL,
                                     start_time  => NULL,
                                     sub_request => FALSE,
                                     argument1   => p_load_status
                                 );
                                 
        IF lt_conc_request_id = 0 THEN
           fnd_file.put_line (fnd_file.log, 'Web User Conversion Main failed to submit: ' || SQLERRM);
           x_errbuf  := 'Web User Conversion Main failed to submit: ' || SQLERRM;
           RAISE submit_fail_e;
        ELSE   
           fnd_file.put_line (fnd_file.log, 'Web User Conversion Main Submitted');
           COMMIT;
        END IF;   
        
        lv_phase       := NULL;
        lv_status      := NULL;
        lv_dev_phase   := NULL;
        lv_dev_status  := NULL;
        lv_message     := NULL;
        lv_error_exist := NULL;
        lv_warning     := NULL;
                                 
        lb_wait := FND_CONCURRENT.wait_for_request
                       (   request_id      => lt_conc_request_id,
                           interval        => 10,
                           phase           => lv_phase,
                           status          => lv_status,
                           dev_phase       => lv_dev_phase,
                           dev_status      => lv_dev_status,
                           message         => lv_message
                       );
                       
         IF lv_status = 'Error' THEN
             fnd_file.put_line (fnd_file.log, 'XXCNV_WEBUSER_CONV_MASTER has Errors');
             x_errbuf  := 'XXCNV_WEBUSER_CONV_MASTER has Errors';
             RAISE submit_fail_e;
         ELSE
             fnd_file.put_line (fnd_file.log, 'XXCNV_WEBUSER_CONV_MASTER has Completed as Normal or Warning');
         END IF;   

         IF lv_dev_status = 'PAUSED' THEN

            lb_wait := FND_CONCURRENT.wait_for_request
                          (   request_id      => lt_conc_request_id,
                              interval        => 10,
                              phase           => lv_phase,
                              status          => lv_status,
                              dev_phase       => lv_dev_phase,
                              dev_status      => lv_dev_status,
                              message         => lv_message
                          );
                          
            IF lv_status = 'Error' THEN
              fnd_file.put_line (fnd_file.log, 'XXCNV_WEBUSER_CONV_MASTER has Errors');
              x_errbuf  := 'XXCNV_WEBUSER_CONV_MASTER has Errors';
              RAISE submit_fail_e;
            ELSE
              fnd_file.put_line (fnd_file.log, 'XXCNV_WEBUSER_CONV_MASTER has Completed as Normal or Warning');
            END IF;               
                          
         END IF;                         
    END IF;
    
   ---------------------------------------------------------------------
   -- Submit The LDIF Generation Program
   ----------------------------------------------------------------------
    
    IF p_submit_ldif = 'Y' THEN
    
       lt_conc_request_id := 0;
    
       lt_conc_request_id := FND_REQUEST.submit_request
                                 (   application => 'XXCNV',
                                     program     => 'XXCNV_WEBUSER_EXP_TO_LDIF',
                                     description => NULL,
                                     start_time  => NULL,
                                     sub_request => FALSE,
                                     argument1   => p_load_status
                                 );
                                 
        IF lt_conc_request_id = 0 THEN
           fnd_file.put_line (fnd_file.log, 'LDIF Generation failed to submit: ' || SQLERRM);
           x_errbuf  := 'LDIF Generation failed to submit: ' || SQLERRM;
           RAISE submit_fail_e;
        ELSE
           fnd_file.put_line (fnd_file.log, 'LDIF Generation Submitted');
           COMMIT;
        END IF;   
        
        lv_phase       := NULL;
        lv_status      := NULL;
        lv_dev_phase   := NULL;
        lv_dev_status  := NULL;
        lv_message     := NULL;
        lv_error_exist := NULL;
        lv_warning     := NULL;
                                 
        lb_wait := FND_CONCURRENT.wait_for_request
                       (   request_id      => lt_conc_request_id,
                           interval        => 10,
                           phase           => lv_phase,
                           status          => lv_status,
                           dev_phase       => lv_dev_phase,
                           dev_status      => lv_dev_status,
                           message         => lv_message
                       );  
                       
         IF lv_status = 'Error' THEN
               fnd_file.put_line (fnd_file.log, 'XXCNV_WEBUSER_EXP_TO_LDIF has Errors');
               x_errbuf  := 'XXCNV_WEBUSER_EXP_TO_LDIF has Errors';
               RAISE submit_fail_e;
         ELSE
            fnd_file.put_line (fnd_file.log, 'XXCNV_WEBUSER_EXP_TO_LDIF has Completed as Normal or Warning');
            COMMIT;
         END IF;      
    END IF;
    
    
   ---------------------------------------------------------------------
   -- Submit The Responsibility Generation Program
   ----------------------------------------------------------------------
    
    IF p_submit_access = 'Y' THEN
    
       lt_conc_request_id := 0;
    
       lt_conc_request_id := FND_REQUEST.submit_request
                                 (   application => 'XXCOMN',
                                     program     => 'XX_COM_EXTERNAL_USER_ACCESS',
                                     description => NULL,
                                     start_time  => NULL,
                                     sub_request => FALSE,
                                     argument1   => p_force,
                                     argument2   => p_date,
                                     argument3   => p_load_status
                                 );
                                 
        IF lt_conc_request_id = 0 THEN
           fnd_file.put_line (fnd_file.log, 'Responsibility Creation failed to submit: ' || SQLERRM);
            x_errbuf  := 'Responsibility Creation failed to submit: ' || SQLERRM;
           RAISE submit_fail_e;
        ELSE
           fnd_file.put_line (fnd_file.log, 'Responsibility Creation Submitted');
           COMMIT;
        END IF;  
        
        lv_phase       := NULL;
        lv_status      := NULL;
        lv_dev_phase   := NULL;
        lv_dev_status  := NULL;
        lv_message     := NULL;
        lv_error_exist := NULL;
        lv_warning     := NULL;
                                 
        lb_wait := FND_CONCURRENT.wait_for_request
                       (   request_id      => lt_conc_request_id,
                           interval        => 10,
                           phase           => lv_phase,
                           status          => lv_status,
                           dev_phase       => lv_dev_phase,
                           dev_status      => lv_dev_status,
                           message         => lv_message
                       );  
         
         IF lv_status = 'Error' THEN
               fnd_file.put_line (fnd_file.log, 'XX_COM_EXTERNAL_USER_ACCESS has Errors');
               x_errbuf  := 'XX_COM_EXTERNAL_USER_ACCESS has Errors';
               RAISE submit_fail_e;
         ELSE
            fnd_file.put_line (fnd_file.log, 'XX_COM_EXTERNAL_USER_ACCESS has Completed Normal or Warning');
         END IF;                  
                       
    END IF;
 
 EXCEPTION WHEN submit_fail_e THEN
    x_retcode := 2;
 WHEN OTHERS THEN
    fnd_file.put_line (fnd_file.log,'UnExpected Error Occured In the Procedure - webuser_conv_wrapper : ' || SQLERRM);
    x_errbuf := 'UnExpected Error Occured In the Procedure - webuser_conv_wrapper : ' || SQLERRM;
    x_retcode := 2;
 END webuser_conv_wrapper; 


 PROCEDURE webuser_dip_monitor          ( x_errbuf           OUT NOCOPY    VARCHAR2
                                          , x_retcode        OUT NOCOPY    VARCHAR2
                                          , p_mail_server    IN            VARCHAR2
                                          , p_mail_from      IN            VARCHAR2
                                          , p_mail_to        IN            VARCHAR2
                                          , p_from_title     IN            VARCHAR2
                                          , p_subject        IN            VARCHAR2
                                          , p_page_flag      IN            VARCHAR2
                                          , p_wait_time      IN            NUMBER
                                          , p_retry_count    IN            NUMBER
                                          )  
                                          
 IS
 
 
 l_wait_time              NUMBER;
 l_fnd_user_name          VARCHAR2(30);
 l_fnd_user_name2         VARCHAR2(30);
 l_current_date           DATE;
 l_exists                 VARCHAR2(10);
 mail_con                 utl_smtp.connection; 
 l_subject                VARCHAR2(100);
 l_retry_count            NUMBER;
 l_mail_to                VARCHAR2(2000);
 l_one_mail               VARCHAR2(50);
 l_mail_unique            TIMESTAMP;
 BEGIN
      l_wait_time := NVL(p_wait_time,600) * 100;
      l_fnd_user_name := 'TEST_WEB_CONTACT_DONOTUSE';    
      l_subject := NVL(p_subject,'DIP Process Appears To Be Down');
      l_retry_count := NVL(p_retry_count,1);

 FOR i IN 1..l_retry_count LOOP     

      l_current_date  := SYSDATE;
      l_mail_unique := SYSTIMESTAMP;
      
      BEGIN
        
      SELECT fnd_user_name INTO l_fnd_user_name2
      FROM xx_external_users
      WHERE FND_USER_NAME = l_fnd_user_name;
      
      fnd_file.put_line (fnd_file.log, 'Updating Test User In xx_external_users');   
       
      UPDATE xx_external_users SET email = 'testemail' || l_mail_unique || '@em.com',
               last_update_date = l_current_date,
               oid_update_date  = l_current_date
      WHERE fnd_user_name = l_fnd_user_name;       
      COMMIT;
    
      EXCEPTION WHEN NO_DATA_FOUND THEN  
      
        fnd_file.put_line (fnd_file.log, 'Creating New Test User In xx_external_users');
              
          INSERT INTO xx_external_users
                           ( ext_user_id
                           , userid
                           , password
                           , person_first_name
                           , person_middle_name
                           , person_last_name
                           , email
                           , orig_system
                           , contact_osr
                           , acct_site_osr
                           , webuser_osr
                           , access_code
                           , permission_flag
                           , status
                           , site_key
                           , party_type
                           , party_id
                           , fnd_user_name
                           , load_status
                           , user_locked
                           , creation_date
                           , created_by
                           , last_update_date
                           , last_updated_by
                           , last_update_login
                           )
                           VALUES
                           ( XX_EXTERNAL_USERS_S.nextval
                           , l_fnd_user_name
                           , l_fnd_user_name
                           , 'FirstName' || l_current_date
                           , 'MiddleName' || l_current_date
                           , 'LastName' || l_current_date
                           , 'testemail' || l_mail_unique || '@em.com'
                           , 'Test'
                           , 'Test1122'
                           , 'Test2233'
                           , 'Test3344'
                           , 'DL'
                           , 'M'
                           , 'A'
                           , 'TEST11'
                           , 'customer'
                           , '11223344'
                           , l_fnd_user_name
                           , 'C'
                           , NULL
                           , l_current_date
                           , fnd_global.user_id()
                           , l_current_date
                           , fnd_global.user_id()
                           , fnd_global.login_id()
                           );
          COMMIT;                 
      END;
           
         
      DBMS_LOCK.SLEEP(l_wait_time);
      
      BEGIN
           Select '1' INTO l_exists
           FROM FND_USER
           WHERE USER_NAME = l_fnd_user_name
           AND email_address = 'testemail' || l_mail_unique || '@em.com';
           
           fnd_file.put_line (fnd_file.log, 'DIP Running Successfully');
           
           EXIT;
           
      EXCEPTION WHEN NO_DATA_FOUND THEN
      
       IF i=l_retry_count THEN
             
          mail_con := utl_smtp.open_connection(p_mail_server, 25); -- SMTP on port 25     
          utl_smtp.helo(mail_con, p_mail_server);
          utl_smtp.mail(mail_con, p_mail_from);
          
          -- Code For Multiple Receipients
          l_mail_to := p_mail_to || ';';
          WHILE TRIM(l_mail_to) IS NOT NULL 
          LOOP
          l_one_mail := substr(l_mail_to,0,instr(l_mail_to,';')-1);
          IF TRIM(l_one_mail) IS NOT NULL THEN
            utl_smtp.rcpt(mail_con, TRIM(l_one_mail));
          END IF;
          l_mail_to := substr(l_mail_to,instr(l_mail_to,';')+1);
          END LOOP;
          
          IF (p_page_flag = 'Y') THEN
             l_subject := '***page***' || l_subject;
          END IF;   
          utl_smtp.data(mail_con,'From: ' || NVL(p_from_title,'DIP Process Alert') || utl_tcp.crlf ||
                          'To: ' || p_mail_to || utl_tcp.crlf ||
                          'Subject: ' || l_subject || 
                          utl_tcp.crlf || 'DIP Process Appears to be Down.Please Look into this.' || utl_tcp.crlf || 'This is an Auto Generated Email From DIP Monitoring Program. DO NOT Reply.');
          utl_smtp.quit(mail_con);
          fnd_file.put_line (fnd_file.log, 'Alert Email Sent Successfully To:'|| p_mail_to);     
          x_errbuf := 'DIP Process is Down';
          x_retcode := 2;
          fnd_file.put_line (fnd_file.log, 'DIP Process is Down');
       ELSE
         NULL;
       END IF;            
      END;    
      
  END LOOP;      
      
   EXCEPTION WHEN OTHERS THEN
     fnd_file.put_line (fnd_file.log,'UnExpected Error Occured In the Procedure - webuser_dip_monitor : ' || SQLERRM);
     x_errbuf := 'UnExpected Error Occured In the Procedure - webuser_dip_monitor : ' || SQLERRM;
     x_retcode := 2;      
END webuser_dip_monitor;  

PROCEDURE process_new_user_access_delta (
      x_errbuf            OUT NOCOPY    VARCHAR2
    , x_retcode           OUT NOCOPY    VARCHAR2
    , p_load_status       IN            VARCHAR2  DEFAULT NULL
) IS

      TYPE C_FND_NEW_USER_TYPE   IS TABLE OF webcontact_user_rec_type INDEX BY BINARY_INTEGER;
      TYPE r_webcontact_cur_type IS REF CURSOR;

      c_webcontact_cur           r_webcontact_cur_type;

      lc_fnd_new_users         C_FND_NEW_USER_TYPE;
      ln_bulk_limit            NUMBER := 100;

      lt_last_run_date         TIMESTAMP;
      lc_return_status         VARCHAR(60);
      ln_msg_count             NUMBER;
      lc_msg_data              VARCHAR2(4000);
      p_date2                  DATE := NULL; 
      ln_counter               PLS_INTEGER  :=  0;
      ln_sucess_count          PLS_INTEGER  :=  0;
      ln_failed_count          PLS_INTEGER  :=  0;
      ln_record_count          PLS_INTEGER  :=  0;

      l_date                   DATE;
      l_fnd_user_rec           XX_EXTERNAL_USERS_PVT.fnd_user_rec_type;
      l_cur_extuser_rec        XX_EXTERNAL_USERS_PVT.external_user_rec_type;
      l_new_extuser_rec        XX_EXTERNAL_USERS_PVT.external_user_rec_type;
      l_same_rel_exists        BOOLEAN := false; 
      l_access_code            VARCHAR2(10);
      
      CURSOR rel_exists_check (usr_name  VARCHAR2) 
      IS
      SELECT FINV.SOURCE_VALUE2 source_value2
      FROM FND_USER USR
          ,FND_USER_RESP_GROUPS GRP
          ,XX_FIN_TRANSLATEDEFINITION FIND
          ,XX_FIN_TRANSLATEVALUES FINV
          ,FND_RESPONSIBILITY_VL RESP
      WHERE USR.USER_ID=GRP.USER_ID
      AND FIND.TRANSLATE_ID=FINV.TRANSLATE_ID
      AND GRP.RESPONSIBILITY_ID=RESP.RESPONSIBILITY_ID
      AND RESP.RESPONSIBILITY_KEY = FINV.TARGET_VALUE1
      AND USR.USER_NAME=USR_NAME;

   BEGIN
      
      XX_EXTERNAL_USERS_DEBUG.enable_debug;
      
   
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Executing XX_EXTERNAL_USERS_CONV.process_new_user_access');
      

      ln_sucess_count :=  0;
      ln_failed_count :=  0;
      ln_record_count :=  0;


      OPEN c_webcontact_cur FOR  SELECT fnd.rowid "fnd_user_rowid",
                                           fnd.user_id,
                                           fnd.user_name,
                                           fnd.description,
                                           fnd.customer_id,
                                           ext.rowid "ext_user_rowid",
                                           ext.ext_user_id,
                                           ext.userid,
                                           ext.password,
                                           ext.person_first_name,
                                           ext.person_middle_name,
                                           ext.person_last_name,
                                           ext.email,
                                           ext.party_id,
                                           ext.status,
                                           'A0' "orig_system",
                                           ext.contact_osr,
                                           ext.acct_site_osr,
                                           ext.webuser_osr,
                                           ext.access_code,
                                           ext.permission_flag,
                                           ext.site_key,
                                           ext.end_date,
                                           ext.load_status,
                                           ext.user_locked,
                                           ext.created_by,
                                           ext.creation_date,
                                           ext.last_update_date,
                                           ext.last_updated_by,
                                           ext.last_update_login
                                    FROM   fnd_user fnd,
                                           xx_external_users ext
                                    WHERE fnd.user_name = ext.fnd_user_name
                                    AND   ext.load_status = NVL(p_load_status,'B');
     

      LOOP
         FETCH c_webcontact_cur BULK COLLECT INTO lc_fnd_new_users Limit ln_bulk_limit ;

         $if $$enable_debug $then
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Fetched  : ' || c_webcontact_cur%ROWCOUNT);
         $end

         IF lc_fnd_new_users.COUNT = 0
         THEN
             EXIT;
         END IF; -- lc_fnd_new_users.COUNT =0 THEN

         FOR ln_counter in lc_fnd_new_users.FIRST .. lc_fnd_new_users.LAST
         LOOP
            ln_record_count           :=   ln_record_count+1;

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Processing Record ' || ln_record_count);

            l_fnd_user_rec.fnd_user_rowid              := lc_fnd_new_users(ln_counter).fnd_user_rowid;
            l_fnd_user_rec.user_id                     := lc_fnd_new_users(ln_counter).user_id;
            l_fnd_user_rec.user_name                   := lc_fnd_new_users(ln_counter).user_name;
            l_fnd_user_rec.description                 := lc_fnd_new_users(ln_counter).description;
            l_fnd_user_rec.customer_id                 := lc_fnd_new_users(ln_counter).customer_id;

            l_new_extuser_rec.ext_user_rowid           := lc_fnd_new_users(ln_counter).ext_user_rowid;
            l_new_extuser_rec.ext_user_id              := lc_fnd_new_users(ln_counter).ext_user_id;
            l_new_extuser_rec.userid                   := lc_fnd_new_users(ln_counter).userid;
            l_new_extuser_rec.password                 := lc_fnd_new_users(ln_counter).password;
            l_new_extuser_rec.person_first_name        := lc_fnd_new_users(ln_counter).person_first_name;
            l_new_extuser_rec.person_middle_name       := lc_fnd_new_users(ln_counter).person_middle_name;
            l_new_extuser_rec.person_last_name         := lc_fnd_new_users(ln_counter).person_last_name;
            l_new_extuser_rec.email                    := lc_fnd_new_users(ln_counter).email;
            l_new_extuser_rec.party_id                 := lc_fnd_new_users(ln_counter).party_id;
            l_new_extuser_rec.status                   := lc_fnd_new_users(ln_counter).status;
            l_new_extuser_rec.orig_system              := lc_fnd_new_users(ln_counter).orig_system;
            l_new_extuser_rec.contact_osr              := lc_fnd_new_users(ln_counter).contact_osr;
            l_new_extuser_rec.acct_site_osr            := lc_fnd_new_users(ln_counter).acct_site_osr;
            l_new_extuser_rec.access_code              := lc_fnd_new_users(ln_counter).access_code;
            l_new_extuser_rec.permission_flag          := lc_fnd_new_users(ln_counter).permission_flag;
            l_new_extuser_rec.site_key                 := lc_fnd_new_users(ln_counter).site_key;
            l_new_extuser_rec.end_date                 := lc_fnd_new_users(ln_counter).end_date;
            l_new_extuser_rec.load_status              := lc_fnd_new_users(ln_counter).load_status;
            l_new_extuser_rec.user_locked              := lc_fnd_new_users(ln_counter).user_locked;
            l_new_extuser_rec.created_by               := lc_fnd_new_users(ln_counter).created_by;
            l_new_extuser_rec.creation_date            := lc_fnd_new_users(ln_counter).creation_date;
            l_new_extuser_rec.last_update_date         := lc_fnd_new_users(ln_counter).last_update_date;
            l_new_extuser_rec.last_updated_by          := lc_fnd_new_users(ln_counter).last_updated_by;
            l_new_extuser_rec.last_update_login        := lc_fnd_new_users(ln_counter).last_update_login;

            $if $$enable_debug $then
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  '*********************************************************** ');
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_fnd_user_rec.fnd_user_rowid              : ' ||  l_fnd_user_rec.fnd_user_rowid        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_fnd_user_rec.user_id                     : ' ||  l_fnd_user_rec.user_id               );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_fnd_user_rec.user_name                   : ' ||  l_fnd_user_rec.user_name             );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_fnd_user_rec.description                 : ' ||  l_fnd_user_rec.description           );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_fnd_user_rec.customer_id                 : ' ||  l_fnd_user_rec.customer_id           );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  '------------------------------------------------------------------------' );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.ext_user_rowid           : ' ||  l_new_extuser_rec.ext_user_rowid     );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.ext_user_id              : ' ||  l_new_extuser_rec.ext_user_id        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.userid                   : ' ||  l_new_extuser_rec.userid             );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.password                 : ' ||  l_new_extuser_rec.password           );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.person_first_name        : ' ||  l_new_extuser_rec.person_first_name  );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.person_middle_name       : ' ||  l_new_extuser_rec.person_middle_name );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.person_last_name         : ' ||  l_new_extuser_rec.person_last_name   );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.email                    : ' ||  l_new_extuser_rec.email              );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.party_id                 : ' ||  l_new_extuser_rec.party_id           );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.status                   : ' ||  l_new_extuser_rec.status             );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.orig_system              : ' ||  l_new_extuser_rec.orig_system        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.contact_osr              : ' ||  l_new_extuser_rec.contact_osr        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.acct_site_osr            : ' ||  l_new_extuser_rec.acct_site_osr      );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.webuser_osr              : ' ||  l_new_extuser_rec.webuser_osr        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.access_code              : ' ||  l_new_extuser_rec.access_code        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.permission_flag          : ' ||  l_new_extuser_rec.permission_flag    );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.site_key                 : ' ||  l_new_extuser_rec.site_key           );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.end_date                 : ' ||  l_new_extuser_rec.end_date           );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.load_status              : ' ||  l_new_extuser_rec.load_status        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.user_locked              : ' ||  l_new_extuser_rec.user_locked        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.created_by               : ' ||  l_new_extuser_rec.created_by);
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.creation_date            : ' ||  l_new_extuser_rec.creation_date);
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.last_update_date         : ' ||  l_new_extuser_rec.last_update_date);
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.last_updated_by          : ' ||  l_new_extuser_rec.last_updated_by);
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'l_new_extuser_rec.last_update_login        : ' ||  l_new_extuser_rec.last_update_login);
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  '------------------------------------------------------------------------' );
            $end
            
            l_access_code := NULL;
            l_same_rel_exists := FALSE;
            
            FOR acc_code IN rel_exists_check (l_fnd_user_rec.user_name) LOOP
               l_access_code := acc_code.source_value2;
               EXIT;
            END LOOP;
            
            IF l_access_code IS NOT NULL THEN
                l_cur_extuser_rec.access_code := l_access_code;
                l_cur_extuser_rec.orig_system  := l_new_extuser_rec.orig_system;
            END IF;
            
            update_fnd_user ( p_cur_extuser_rec            => l_cur_extuser_rec
                            , p_new_extuser_rec            => l_new_extuser_rec
                            , p_fnd_user_rec               => l_fnd_user_rec
                            , x_return_status              => lc_return_status
                            , x_msg_count                  => ln_msg_count
                            , x_msg_data                   => lc_msg_data
                            );

            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS
            THEN
               ln_failed_count          := ln_failed_count+1;
            ELSE
               ln_sucess_count          := ln_sucess_count+1;
            END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS

         END LOOP;

         EXIT WHEN c_webcontact_cur%NOTFOUND;

      END LOOP;

      CLOSE c_webcontact_cur;

      fnd_file.put_line (fnd_file.output, 'Processed Successfully : ' || ln_sucess_count);
      fnd_file.put_line (fnd_file.output, 'Erorrs                 : ' || ln_failed_count);
      fnd_file.put_line (fnd_file.output, 'Total Count            : ' || ln_record_count);

      IF ln_record_count > 0
      THEN
         IF  ln_failed_count = ln_record_count
         THEN
             x_retcode := 2;
             x_errbuf  := to_char(ln_failed_count) || ' records failed';
         ELSIF  ln_failed_count > 0
         THEN
             x_retcode := 1;
             x_errbuf  := to_char(ln_failed_count) || ' records failed';
         ELSE
             x_retcode := 0;
             x_errbuf  := 'Successfully Processed ' || ln_sucess_count || ' Records';
         END IF; --  ln_failed_count > 0
      ELSE
          x_retcode := 0;
          x_errbuf  := 'No records Processed';
      END IF; -- ln_record_count > 0

   EXCEPTION
     WHEN OTHERS THEN
         ROLLBACK;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.process_new_user_access');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         fnd_file.put_line (fnd_file.output, fnd_message.get());
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,  fnd_message.get());

         IF c_webcontact_cur%ISOPEN
         THEN
            CLOSE c_webcontact_cur;
         END IF; -- c_fnd_user%ISOPEN

END process_new_user_access_delta;


-- +===================================================================+
-- | Name             : purge_external_usr_stg                         |
-- | Description      : Procedure to purge the data from               |
-- |                    xx_external_users_stg based on parameters      |
-- | Parameters :       p_age                                          |
-- |                                                                   |
-- | Returns :          x_errbuf                                       |
-- |                    x_retcode                                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE purge_external_usr_stg ( x_errbuf               OUT NOCOPY VARCHAR2
                                   ,x_retcode              OUT NOCOPY VARCHAR2
                                   ,p_age                  IN         NUMBER
                                 )
IS
------------------------------------------------
--Declaring local Exceptions and local Variables
------------------------------------------------
ln_delete_rec_count      PLS_INTEGER;
lc_error_message        VARCHAR2(4000);
EX_DELETE_STG           EXCEPTION;
BEGIN

    write_output(RPAD('Age               :',30,' ') || p_age);
    write_output('');

    -------------------------------------------
    --Deleting data from xx_external_users_stg table
    -------------------------------------------
    BEGIN
        DELETE FROM xx_external_users_stg XEUS
        WHERE  trunc(xeus.last_update_date) <= trunc(SYSDATE - p_age);
        ln_delete_rec_count := SQL%ROWCOUNT;
    EXCEPTION
        WHEN OTHERS THEN
            lc_error_message := 'Unexpected error while deleting records from the table xx_external_users_stg. Error : '||substr(SQLERRM,1,1000);
            RAISE EX_DELETE_STG;
    END;
    
    write_output('Number of Records deleted from xx_external_users_stg table  : '||ln_delete_rec_count );

COMMIT;
EXCEPTION
WHEN EX_DELETE_STG THEN
    ROLLBACK;
    write_log(lc_error_message);

WHEN OTHERS THEN
    write_log('Unexpected error in Procedure PURGE_EXTERNAL_USR_STG Error: '||SQLERRM);
END purge_external_usr_stg; 
-- +===================================================================+
-- | Name             : debug_external_user                            |
-- | Description      : Procedure to debug/update user information     |
-- |                                                                   |
-- | Parameters       : p_fnd_user                                     |
-- |                    p_report_only                                  |
-- |                        Y -- report mode                           |
-- |                        N -- update mode                           |
-- |                    p_debug_flag                                   |
-- |                                                                   |
-- | Returns :          x_errbuf                                       |
-- |                    x_retcode                                      |
-- |                                                                   |
-- +===================================================================+
PROCEDURE  debug_external_user( x_errbuf       OUT NOCOPY   VARCHAR2
                              ,x_retcode       OUT NOCOPY   NUMBER
                              ,p_fnd_user      IN           VARCHAR2 DEFAULT NULL
                              ,p_report_only   IN           VARCHAR2 DEFAULT 'Y'
                              ,p_debug_flag    IN           VARCHAR2 DEFAULT 'N'
                                                      ) is
 cursor c_get_extusr_stg(p_user_name in varchar2 ) 
        is
           select rpad(batch_id,20,' ')                      batch_id
                 ,rpad (userid,40,' ')                       user_id
                 ,rpad(nvl(Process_name,' '),30,' ')         Process_name
                 ,rpad(nvl(webuser_osr,' '),20,' ')          webuser_osr
                 ,rpad(nvl(to_char(ext_upd_timestamp,'DD-MON-YYYY HH24:MI:SS:FF'),'00-000-0000 00:00:00:000000000'),33,' ') ext_update_timestamp
                 ,rpad(nvl(access_code,' '),13,' ')          access_code
                 ,rpad(nvl(action_type,' '),12,' ')          action_type
                 ,rpad(nvl(to_char(creation_date,'DD-MON-YYYY'),' '),20,' ')    creation_date        
                 ,rpad(nvl(to_char(last_update_date,'DD-MON-YYYY'),' '),20,' ') last_update_date
            from  xx_external_users_stg 
           where  1=1
             and '100100' || webuser_osr = trim(p_user_name)
             and rownum <11
        order by nvl(EXT_UPD_TIMESTAMP,'01-JAN-0001 01:01:01.000000000') desc;
        
cursor c_get_extusr(p_user_name in varchar2 ) 
        is
           select 
                  rpad (userid,40,' ')                        user_id
              --   ,rpad (password,40,' ')              password
                 ,rpad(nvl(fnd_user_name,' '),50,' ')         fnd_user_name
                 ,rpad(nvl(webuser_osr,' '),20,' ')           webuser_osr
                 ,rpad(nvl(to_char(ext_upd_timestamp,'DD-MON-YYYY HH24:MI:SS:FF'),'00-000-0000 00:00:00:000000000'),33,' ') ext_upd_timestamp
                 ,rpad(nvl(access_code,' '),13,' ')           access_code
                 ,rpad(nvl(subscription_exists,' '),25,' ')   subscription_exists
                 ,rpad(nvl(to_char(creation_date,'DD-MON-YYYY'),' '),20,' ')    creation_date        
                 ,rpad(nvl(to_char(last_update_date,'DD-MON-YYYY'),' '),20,' ') last_update_date
            from  xx_external_users 
           where  1=1
             and  FND_USER_NAME = trim(p_user_name);  
cursor c_get_fnd_user(p_user_name in varchar2 ) 
        is
           select 
                  rpad (user_id,20,' ')                              user_id
                 ,rpad(nvl(user_name,' '),60,' ')                    user_name
                 ,rpad(nvl(last_logon_date,sysdate),20,' ')          last_logon_date
                 ,rpad(nvl(last_update_login,0),20,' ')              last_update_login
                 ,rpad(nvl(to_char(creation_date,'DD-MON-YYYY'),' '),15,' ')    creation_date        
                 ,rpad(nvl(to_char(last_update_date,'DD-MON-YYYY'),' '),18,' ') last_update_date
                 ,user_guid                    
            from  fnd_user 
           where  1=1
             and  user_name = trim(p_user_name);
cursor c_mismatch_pwd(p_user_name in varchar2) is             
           select 
                  xeus.external_users_stg_id  
                 ,xeus.stg_password 
                 ,xeu.EXT_USER_ID
                 ,xeu.password
                 ,xeu.fnd_user_name
                 ,xeus.ext_upd_timestamp
                 ,xeus.rank1
		             ,stg_fnd_user_name
            from (SELECT 
                         x.external_users_stg_id
                        ,x.batch_id
                        ,x.userid
                        ,x.password  stg_password
                        ,x.ext_upd_timestamp
                        ,'100100'||x.webuser_osr stg_fnd_user_name
                        ,RANK() OVER 
                         (ORDER BY nvl(EXT_UPD_TIMESTAMP,'01-JAN-0001 01:01:01.000000000') desc, x.last_update_date desc, x.EXTERNAL_USERS_STG_ID desc) as rank1
                  from xx_external_users_stg x
                 where 1 = 1 
                   and '100100'||webuser_osr = trim(p_user_name)
                   and process_name ='UpdateExtUserPwd'
                 ) xeus,
				         xx_external_users xeu	 
           where 1=1
             and  xeu.fnd_user_name = xeus.stg_fnd_user_name
		         and  xeu.userid    = xeus.userid
             and  xeu.password != xeus.stg_password  
             and  xeu.access_code IN ('02', '03', '05', '06')
		         and  rank1=1;
          
lc_oid_user_guid            fnd_user.user_guid%type := NULL; 
lc_fnd_user_guid            fnd_user.user_guid%type:=NULL;
lc_oid_user_exists          VARCHAR2(1) := 'N';  
lc_fnd_user_exists          VARCHAR2(1) := 'N';
lc_oid_sub_status           VARCHAR2(50):= NULL;
lc_oid_sub_status_upd       VARCHAR2(50):= NULL;
lc_ext_usr_stg_exists        VARCHAR2(1) := 'N';
lc_ext_usr_exists            VARCHAR2(1) := 'N';
lc_fnd_usr_exists            VARCHAR2(1) := 'N';
lc_pwd_mismatch              VARCHAR2(1) := 'N';

BEGIN 
              write_log(' Process Begins....');
              write_log(' Current system time is '|| systimestamp);
              x_retcode:=0;

            ----------------------------------
             -- OID SUBSCRIPTION CHECK and GUID
            ----------------------------------
              write_output('User                    :'||p_fnd_user);
              write_output('-----------    ');
              write_output('OID Details              ');
              write_output('-----------    ');
              lc_oid_user_exists := XX_OID_SUBSCRIPTION_UPD_PKG.get_oid_user_exists(p_fnd_user,lc_oid_user_guid);
              write_output('OID User Exists         :'||lc_oid_user_exists);
              write_output('OID Guid                :'||lc_oid_user_guid);
              lc_oid_sub_status  := XX_OID_SUBSCRIPTION_UPD_PKG.check_subscription(p_fnd_user,lc_oid_user_guid);
              write_output('OID Subscription Status :'|| lc_oid_sub_status);  
             write_output(' ');
             write_output(' '); 
             write_output(' ');
             ---------------------------
             -- xx_external_users_stg
             ---------------------------              
              write_output('                                                            -----------------------------------------------------------------------------------------------');
              write_output('                                                                   List Of recent records for user '||p_fnd_user||' from xx_external_users_stg                                                    ');
              write_output('                                                            -----------------------------------------------------------------------------------------------');
              write_output(rpad('BATCH_ID',20,' ')||rpad ('USERID',40,' ')||rpad('PROCESS_NAME',30,' ')||rpad('WEBUSER_OSR',20,' ')||rpad('EXT_UPD_TIMESTAMP',33,' ')||rpad('ACCESS_CODE',13,' ')   
                          || rpad('ACTION_TYPE',12,' ')||rpad('CREATION_DATE',20,' ')|| rpad('LAST_UPDATE_DATE',20,' '));
              write_output('-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
             
             for usr_stg in c_get_extusr_stg(p_fnd_user)
                loop
                 lc_ext_usr_stg_exists :='Y';
                 write_output(usr_stg.batch_id||usr_stg.user_id ||usr_stg.Process_name||usr_stg.webuser_osr ||usr_stg.ext_update_timestamp||usr_stg.access_code||usr_stg.action_type||usr_stg.creation_date||usr_stg.last_update_date  );
              end loop;
              
             IF(lc_ext_usr_stg_exists='N') THEN
             write_output('No Data found for user  '||p_fnd_user|| '   in xx_external_users_stg');
             END IF;            
             write_output(' ');

             ---------------------------
             -- xx_external_users
             ---------------------------
              write_output('                                                            -----------------------------------------------------------------------------------------------');
              write_output('                                                                   Record for user '||p_fnd_user||' from xx_external_users                                                    ');
              write_output('                                                            -----------------------------------------------------------------------------------------------');
              write_output(rpad ('USERID',40,' ')||rpad('FND_USER_NAME',50,' ')||rpad('WEBUSER_OSR',20,' ') ||rpad('EXT_UPD_TIMESTAMP',33,' ')||rpad('ACCESS_CODE',13,' ')   
                          ||rpad('SUBSCRIPTION_EXISTS',25,' ') ||rpad('CREATION_DATE',20,' ') ||rpad('LAST_UPDATE_DATE',20,' '));
              write_output('-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
              for usr in c_get_extusr(p_fnd_user)
                 loop
                      lc_ext_usr_exists:='Y';
                      write_output(usr.user_id ||usr.fnd_user_name||usr.webuser_osr ||usr.ext_upd_timestamp  ||usr.access_code||usr.subscription_exists||usr.creation_date||usr.last_update_date  );
                end loop;
                
             IF(lc_ext_usr_exists='N') THEN
             write_output('No Data found for user  '||p_fnd_user|| '   in xx_external_users');
             END IF;            
             write_output(' ');
             ---------------------------
             -- FND_USER
             ---------------------------
              write_output('                                                            -----------------------------------------------------------------------------------------------');
              write_output('                                                                   Record for user '||p_fnd_user||' from fnd_user                                                    ');
              write_output('                                                            -----------------------------------------------------------------------------------------------');
              write_output(rpad ('USER_ID',20,' ')||rpad('USER_NAME',60,' ')||rpad('LAST_LOGON_DATE',20,' ')||rpad('LAST_UPDATE_LOGIN',20,' ')||rpad('CREATION_DATE',15,' ')||rpad('LAST_UPDATE_DATE',17,' ')||'USER_GUID');
              write_output('------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
              for usr_fnd in c_get_fnd_user(p_fnd_user)
                loop
                   lc_fnd_usr_exists:='Y';
                   write_output(usr_fnd.user_id ||usr_fnd.user_name||usr_fnd.last_logon_date||usr_fnd.last_update_login||usr_fnd.creation_date||usr_fnd.last_update_date||usr_fnd.user_guid  );
                end loop;
             IF(lc_fnd_usr_exists='N') THEN
             write_output('No Data found for user  '||p_fnd_user|| '   in fnd_user');
             END IF;            
             write_output(' ');  
     ------
     -- Update Mode
     ------
     IF(nvl(p_report_only,'Y') <>'Y')
        THEN
            write_output('Update Process Begins... ');
          /* Updating Records with Password Mismatch */
                     
            FOR rec in c_mismatch_pwd(p_fnd_user)
               loop
               BEGIN
                   lc_pwd_mismatch :='Y';
                    IF (p_debug_flag ='Y') 
                       THEN
                          write_log('Updating Password for User: ' ||p_fnd_user || ' in XX_EXTERNAL_USERS' );
                    END IF;
                    
                update xx_external_users
                   set password = rec.stg_password
                      ,oid_update_date  = sysdate
                      ,last_update_date = sysdate
                      ,last_updated_by  = fnd_global.user_id()                  
                 where EXT_USER_ID =rec.EXT_USER_ID; 
                 
                 COMMIT;
                            

                   write_output('Successfully Updated the Password for User: ' ||p_fnd_user || ' in XX_EXTERNAL_USERS' );

            
                EXCEPTION
                 WHEN OTHERS THEN 
                 write_log('Error updating  password for User:' ||p_fnd_user ||' in xx_external_users:  '||SQLERRM );
                 x_errbuf := 'Error updating  password for User:' ||p_fnd_user ||' in xx_external_users:  '||substr(SQLERRM,1,100);
                 x_retcode := 1;
                 END;
               end loop;
               
               IF (lc_pwd_mismatch ='N') THEN
                    write_output('No Record found in xx_external_users for user : '|| p_fnd_user ||' whose password does not match with xx_external_users_stg having process_name "UpdateExtUserPwd"'  );
               END IF;
                
                -------------------------------
                -- Verifying if FND_USER Exists
                -------------------------------             
            lc_fnd_user_exists :=XX_OID_SUBSCRIPTION_UPD_PKG.get_fnd_user_exists(p_fnd_user,lc_fnd_user_guid);   
             IF (p_debug_flag ='Y') 
                 THEN
                   write_log('FND_USER_EXISTS      : '||lc_fnd_user_exists);
                   write_log('FND_USER_GUID        : '||lc_fnd_user_guid );
              END IF;
           IF((nvl(lc_oid_user_exists,'N') = 'Y' AND nvl(lc_fnd_user_exists,'N') = 'Y') )
           THEN
           
           ----------------------------------
           -- CREATE SUBSCRIPTION
           ----------------------------------
           IF(lc_oid_sub_status ='SUBSCRIBED')
                THEN
                 write_output('Subscription exists for user    :'||p_fnd_user );
           ELSE    
                BEGIN
                      IF (p_debug_flag ='Y') 
                         THEN
                            write_log('Creating Subscription for user :'||p_fnd_user );
                       END IF;  
                       
                      XX_OID_SUBSCRIPTION_UPD_PKG.UPDATE_SUBSCRIPTION(p_fnd_user);
                      lc_oid_sub_status_upd  := get_subscription_status(p_fnd_user);
                
                    IF (nvl(lc_oid_sub_status_upd,'XXX') ='SUBSCRIBED')
                       THEN
                          write_output('Successfully Created subscription for user  '|| p_fnd_user);
                     ELSE
                          write_output('Create Susbscription for User:' ||p_fnd_user ||' failed  ' );
                          x_errbuf := 'Create Susbscription for User:' ||p_fnd_user ||' failed  ';
                          x_retcode := 1;
                     END IF;--SUB created Y/N 
                EXCEPTION
                        WHEN OTHERS THEN 
                          write_log('Error creating  Susbscription for User:' ||p_fnd_user ||':  '||SQLERRM );
                          x_errbuf := 'Error creating  Susbscription for User:' ||p_fnd_user ||':  '||substr(SQLERRM,1,100);
                          x_retcode := 1;
                END;
            END IF;--Create Subscription
                ----------------------------------
                -- UPDATE GUID
                ----------------------------------
              lc_oid_user_guid   :=get_oid_guid(p_fnd_user);
              
              IF (lc_oid_user_guid is not null) THEN 
                IF(lc_fnd_user_guid = lc_oid_user_guid)THEN 
                     write_output('No Guid Mismatch found for user : '|| p_fnd_user);
                 ELSE
                   BEGIN
                       IF (p_debug_flag ='Y') 
                         THEN
                            write_log('Updating FND_USER GUID for user :'||p_fnd_user );
                       END IF;
                          
                           FND_USER_PKG.UPDATEUSER
                                (x_user_name => p_fnd_user
                                ,x_owner     => null                            
                                ,x_user_guid => lc_oid_user_guid 
                                );
                              commit;
                           IF(compare_guid(p_fnd_user)='Y') THEN
                                  write_output('Successfully updated user_guid for FND_USER :'||p_fnd_user );
                           ELSE
                                  write_output('Update GUID for FND_USER   :'||p_fnd_user||' failed' );
                           END IF;
                  EXCEPTION
                        WHEN OTHERS THEN 
                          write_log('Error Updating GUID  for User:' ||p_fnd_user ||':  '||SQLERRM ); 
                          x_errbuf := 'Error Updating GUID  for User:' ||p_fnd_user ||':  '||substr(SQLERRM,1,100);
                          x_retcode := 1;
                  END;
                END IF;--update_guid
              END IF;--lc_oid_guid 
            ELSE
              write_output('FND_USER_EXISTS      : '||lc_fnd_user_exists);
              write_output('OID_USER_EXISTS      : '||lc_oid_user_exists);
              write_output('Uable to update Subscription and GUID for user  '||p_fnd_user||'- user does not exist either in FND or OID  ');
            END IF;--user_exists
            write_output('Update Process Ends... ');
        END IF; --p_report_only
           
         commit; 
          write_log('     ');
          write_log('End of Process...');
          write_log('Current system time is '|| systimestamp);
           
EXCEPTION 
 WHEN OTHERS THEN 
    write_log('UnExpected Error Occured In the Procedure - debug_external_user : ' || SQLERRM);
    write_log('END of Process...');
    write_log('Current system time is '|| systimestamp);
    x_errbuf := 'UnExpected Error Occured In the Procedure - debug_external_user : ' || substr(SQLERRM,1,100);
    x_retcode := 2;                                                      
                                                                                                        
END debug_external_user;

END XX_EXTERNAL_USERS_CONV;
/

SHOW ERRORS;
