create or replace
package  body XX_CS_MPS_AVF_ADDR_UPLD_PKG
as
  gc_ind VARCHAR2(5) := ',';
  -- This variable holds the System Date
  --
  g_dat_sys_date DATE := SYSDATE;
  
  PROCEDURE log(
      P_message IN VARCHAR2)
  IS
  BEGIN
    fnd_file.PUT_LINE(fnd_file.LOG,P_message);
  END;
  
  PROCEDURE output(
      P_message IN VARCHAR2)
  IS
  BEGIN
    fnd_file.PUT_LINE(fnd_file.OUTPUT,P_message);
  END;
  
  --Procedure for logging debug log
  PROCEDURE log_debug_msg ( 
                            p_debug_pkg          IN  VARCHAR2
                           ,p_debug_msg          IN  VARCHAR2 )
  IS
  
    ln_login             PLS_INTEGER  := FND_GLOBAL.Login_Id;
    ln_user_id           PLS_INTEGER  := FND_GLOBAL.User_Id;
  
  BEGIN
  
      XX_COM_ERROR_LOG_PUB.log_error
        (
         p_return_code             => FND_API.G_RET_STS_SUCCESS
        ,p_msg_count               => 1
        ,p_application_name        => 'XXCRM'
        ,p_program_type            => 'DEBUG'              --------index exists on program_type
        ,p_attribute15             => p_debug_pkg          --------index exists on attribute15
        ,p_program_id              => 0                    
        ,p_module_name             => 'CDH'                --------index exists on module_name
        ,p_error_message           => p_debug_msg
        ,p_error_message_severity  => 'LOG'
        ,p_error_status            => 'ACTIVE'
        ,p_created_by              => ln_user_id
        ,p_last_updated_by         => ln_user_id
        ,p_last_update_login       => ln_login
        );
  
  END log_debug_msg;
  
  --Procedure for logging Errors/Exceptions
  PROCEDURE log_error ( 
                        p_error_pkg          IN  VARCHAR2
                       ,p_error_msg          IN  VARCHAR2 )
  IS
  
    ln_login             PLS_INTEGER  := FND_GLOBAL.Login_Id;
    ln_user_id           PLS_INTEGER  := FND_GLOBAL.User_Id;
  BEGIN
      XX_COM_ERROR_LOG_PUB.log_error
        (
         p_return_code             => FND_API.G_RET_STS_SUCCESS
        ,p_msg_count               => 1
        ,p_application_name        => 'XXCRM'
        ,p_program_type            => 'ERROR'              --------index exists on program_type
        ,p_attribute15             => p_error_pkg          --------index exists on attribute15
        ,p_program_id              => 0                    
        ,p_module_name             => 'CDH'                --------index exists on module_name
        ,p_error_message           => p_error_msg
        ,p_error_message_severity  => 'MAJOR'
        ,p_error_status            => 'ACTIVE'
        ,p_created_by              => ln_user_id
        ,p_last_updated_by         => ln_user_id
        ,p_last_update_login       => ln_login
        );
  
  END log_error;

  PROCEDURE upd_devices_addr( errbuf      OUT NOCOPY VARCHAR2
                            , retcode     OUT NOCOPY VARCHAR2
                            , p_batch_id  IN         VARCHAR2
                            ) IS
    cursor C1
	is
	select *
	from   XX_CS_MPS_AVF_LOAD_STG
	where  batch_id = p_batch_id
	and    g1_addr_ver_flag = 'S';
	
  BEGIN
    log_debug_msg('XX_CS_MPS_AVF_ADDR_UPLD_PKG.UPD_DEVICES_ADDR','START');
	for i_rec in C1
	loop
	  
	  update XX_CS_MPS_DEVICE_B
	  set    site_address_1   = i_rec.g1_address_1
	        ,site_address_2   = i_rec.g1_address_2
	        ,site_city        = i_rec.g1_city
			,site_state       = i_rec.g1_state
			,site_zip_code    = i_rec.g1_zip_code
			,ship_site_id     = i_rec.cdh_ship_site_id
			,last_update_date = sysdate
			,last_updated_by  = FND_GLOBAL.user_id
      where serial_no = i_rec.serial_no;
	  
	  commit;
	END loop;
	  
    log_debug_msg('XX_CS_MPS_AVF_ADDR_UPLD_PKG.UPD_DEVICES_ADDR','END');
  EXCEPTION
    WHEN OTHERS THEN
     log_error('XX_CS_MPS_AVF_ADDR_UPLD_PKG.UPD_DEVICES_ADDR','UPD_DEVICES_ADDR EXCEPTION: ' || sqlerrm);  
	 
  END upd_devices_addr;							
  
  PROCEDURE send_avf_mail( p_party_id        IN   NUMBER
                         , x_return_status  OUT VARCHAR2
                         , x_return_mesg    OUT VARCHAR2
                         ) IS
    CURSOR c_ship_to (p_party_id NUMBER) IS
      SELECT DISTINCT 'A'                        action_code
           , SUBSTR(a.orig_system_reference,1,8) account_number
           ,  p.party_name                       customer_name
           , ''                                  address_sequence
           , ''                                  address_id
           , d.site_address_1                    address_1
           , d.site_address_2                    address_2
           , d.site_city                         city
           , d.site_state                        state
           , d.site_zip_code                     zip_code
           , ''                                  desk_top_req_flag
           , ''                                  back_order_flag
           , ''                                  delivery_days
           , ''                                  max_order_amount
           , ''                                  override_address
           , ''                                  province
           , ''                                  country_code
        FROM xx_cs_mps_device_b d
           , hz_cust_accounts        a
           , hz_parties              p
       WHERE d.party_id = a.party_id
         AND a.party_id = p.party_id
         AND D.PARTY_ID = p_party_id;
  
    lc_sequence     VARCHAR2(5);
    ln_seq          NUMBER := 1;
    lf_Handle       utl_file.file_type;
    lc_file_path    VARCHAR2(100) := FND_PROFILE.VALUE('XX_OM_SAS_FILE_DIR');
    lc_file_name    VARCHAR2(200);
    lc_header       VARCHAR2(4000);
    lc_record       VARCHAR2(4000);
    lc_party_name   VARCHAR2(150);
    lc_conn         UTL_SMTP.connection;
    lc_temp_email   VARCHAR2(100) := FND_PROFILE.VALUE('XX_CS_MPS_SHIPTO_ADDR');
    lc_email_add    VARCHAR2(240) := FND_PROFILE.VALUE('XX_CS_MPS_SHIPTO_ADDR');
    lc_subject      VARCHAR2(240) := 'SHIP TO UPLOAD';
  
  BEGIN
  
    SELECT party_name INTO lc_party_name FROM hz_parties where party_id = p_party_id;
    lc_file_name := lc_party_name||'_SHIP_TO.csv';
  
    -- Check if the file is OPEN
    lf_Handle := utl_file.fopen(lc_file_path, lc_file_name, 'W'); --W will write to a new file A will append to existing file
    lc_header := 'ACTION CODE'       ||gc_ind||
                 'ACCOUNT NUMBER'    ||gc_ind||
                 'ADDRESS SEQ'       ||gc_ind||
                 'ADDRESS ID'        ||gc_ind||
                 'BUSINESS NAME'     ||gc_ind||
                 'ADDR LINE 1'       ||gc_ind||
                 'ADDR LINE 2'       ||gc_ind||
                 'CITY'              ||gc_ind||
                 'STATE'             ||gc_ind||
                 'ZIP'               ||gc_ind||
                 'DESK TOP REQ FLAG' ||gc_ind||
                 'BACK ORDER FLAG'   ||gc_ind||
                 'DELIVERY DAYS'     ||gc_ind||
                 'MAX ORDER AMOUNT'  ||gc_ind||
                 'OVERRIDE ADDR'     ||gc_ind||
                 'PROVINCE'          ||gc_ind||
                 'COUNTRY CODE' ;
  
    -- Write it to the file
    utl_file.put_line(lf_Handle, lc_header, FALSE);
    FOR r_ship_to IN c_ship_to(p_party_id) LOOP
      --ln_loop_count := ln_loop_count +1;
  
      ln_seq := ln_seq + 1;
      select LPAD(ln_seq,5,'0') INTO lc_sequence from dual;
  
      lc_record  := r_ship_to.action_code       ||gc_ind||
                    r_ship_to.account_number    ||gc_ind||
                    lc_sequence                 ||gc_ind|| -- r_ship_to.address_sequence  ||gc_ind||
                    r_ship_to.address_id        ||gc_ind||
                    r_ship_to.customer_name     ||gc_ind||
                    r_ship_to.address_1         ||gc_ind||
                    r_ship_to.address_2         ||gc_ind||
                    r_ship_to.city              ||gc_ind||
                    r_ship_to.state             ||gc_ind||
                    r_ship_to.zip_code          ||gc_ind||
                    r_ship_to.desk_top_req_flag ||gc_ind||
                    r_ship_to.back_order_flag   ||gc_ind||
                    r_ship_to.delivery_days     ||gc_ind||
                    r_ship_to.max_order_amount  ||gc_ind||
                    r_ship_to.override_address  ||gc_ind||
                    r_ship_to.province          ||gc_ind||
                    r_ship_to.country_code;
      -- Write it to the file
      utl_file.put_line(lf_Handle, lc_record, FALSE);
    END LOOP;
    utl_file.fflush(lf_Handle);
    utl_file.fclose(lf_Handle);
  
    lc_conn := xx_pa_pb_mail.begin_mail( sender         => lc_email_add
                                       , recipients     => lc_temp_email
                                       , cc_recipients  => NULL
                                       , subject        => lc_subject
                                       , mime_type      => xx_pa_pb_mail.multipart_mime_type
                                       );
  
    xx_pa_pb_mail.xx_email_excel( conn        => lc_conn
                                , p_directory => lc_file_path
                                , p_filename  => lc_file_name
                                );
    xx_pa_pb_mail.end_attachment(conn => lc_conn);
    xx_pa_pb_mail.end_mail(conn => lc_conn);
  EXCEPTION
    WHEN OTHERS THEN
      x_return_status := 'S';
      x_return_mesg   := 'When Others raised at get_ship_to  : '||SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_party_id
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.GET_SHIP_TO'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'When Others raised at get_ship_to  : '||SQLERRM
                                           );
  END send_avf_mail;
  

  PROCEDURE main(  errbuf      OUT NOCOPY VARCHAR2
                 , retcode     OUT NOCOPY VARCHAR2
                 , p_batch_id  IN         VARCHAR2
                )
  IS
  
    cursor C1
	is
    select  int.BATCH_ID           
           ,int.SERIAL_NO          
		   ,int.IP_ADDRESS         
		   ,int.SITE_CONTACT       
		   ,int.SITE_CONTACT_PHONE 
		   ,int.SITE_ADDRESS_1     
		   ,int.SITE_ADDRESS_2     
		   ,int.SITE_CITY          
		   ,int.SITE_STATE         
		   ,int.SITE_ZIP_CODE      
		   ,int.DEVICE_FLOOR       
		   ,int.DEVICE_ROOM        
		   ,int.DEVICE_LOCATION    
		   ,int.DEVICE_COST_CENTER 
		   ,int.MANUFACTURER       
		   ,int.MODEL              
		   ,int.MPS_REP_COMMENTS   
		   ,int.DEVICE_JIT         
		   ,int.PROGRAM_TYPE       
		   ,int.MANAGED_STATUS     
		   ,int.SUPPORT_COVERAGE   
		   ,int.BSD_REP_COMMENTS   
		   ,int.SLA_COVERAGE       
		   ,int.DEVICE_ID          
		   ,int.DEVICE_CONTACT     
		   ,int.DEVICE_PHONE       
		   ,int.CREATION_DATE      
		   ,int.CREATED_BY         
		   ,int.LAST_UPDATE_DATE   
		   ,int.LAST_UPDATED_BY 
		   ,dev.PARTY_ID
    from   XX_CS_MPS_AVF_LOAD_INT  int,
           XX_CS_MPS_DEVICE_B      dev
    where  int.serial_no = dev.serial_no
    and    int.batch_id  = p_batch_id;
	
	cursor C2 ( p_party_id   IN NUMBER
	           ,p_serial_no  IN VARCHAR2)
	is
	SELECT   
      (select orig_system_reference from hz_cust_site_uses_all where site_use_id = mb.ship_site_id and rownum <2) as device_site_sequence
	  , hcs.orig_system_reference as cdh_site_sequence
   	  ,	hcs.site_use_id device_ship_site_id
      , mb.ship_site_id cdh_ship_site_id
    FROM 
         HZ_CUST_SITE_USES_ALL HCS
       , HZ_CUST_ACCT_SITES_ALL HCSA
       , HZ_PARTY_SITES HPS
       , HZ_LOCATIONS HL
	   , XX_CS_MPS_AVF_LOAD_STG stg
       , XX_CS_MPS_DEVICE_B MB
    WHERE 
     MB.SERIAL_NO = stg.SERIAL_NO
     AND MB.party_id = HPS.party_id
     AND HPS.LOCATION_ID               = HL.LOCATION_ID
     AND HL.ADDRESS1                   = UPPER(trim(stg.g1_address_1))
     AND UPPER(HL.CITY)                = UPPER(trim(stg.g1_city))
     AND UPPER(HL.STATE)               = UPPER(trim(stg.g1_state))
     AND SUBSTRB(HL.POSTAL_CODE,1,5)   = SUBSTRB(trim(stg.g1_zip_code),1,5) 
     AND HCSA.CUST_ACCT_SITE_ID        = HCS.CUST_ACCT_SITE_ID
     AND HCSA.PARTY_SITE_ID            = HPS.PARTY_SITE_ID
     AND HCS.STATUS                    = 'A'
     AND HCS.SITE_USE_CODE             = 'SHIP_TO'
     AND MB.PARTY_ID                   = p_party_id
     AND mb.serial_no                  = p_serial_no;

	
    l_g1_address1   	    varchar2(255) := null;
    l_g1_address2           varchar2(255) := null;
    l_g1_city               varchar2(255) := null;
    l_g1_state              varchar2(255) := null;
    l_g1_postal_code        varchar2(255) := null;
	l_g1_county             varchar2(255) := null;
	l_g1_addr_error         varchar2(2000) := null;
	l_g1_addr_code          varchar2(30) := null;
    l_g1_ws_error           VARCHAR2(2000) := null;
	l_party_id              number := null;
	l_device_site_seq       varchar2(60) := null;
	l_cdh_site_seq          varchar2(60) := null;
	l_device_ship_site_id   number := null;
	l_cdh_ship_site_id      number := null;
	
    --lv_db_link                 VARCHAR2(200) := '@' || fnd_profile.value('XX_CS_STANDBY_DBLINK'); -- GMILL_STNDBY
    --lv_db_link                 VARCHAR2(200) :=  fnd_profile.value('XX_CS_STANDBY_DBLINK'); -- GMILL_STNDBY -- for Testing
  
  BEGIN
  
    log_debug_msg('XX_CS_MPS_AVF_ADDR_UPLD_PKG.MAIN','START');
	
	--output('AVF Address Upload Import on '||g_dat_sys_date);
	--output('=============================');
	
	output( 'BATCH_ID            ' || gc_ind ||
	        'SERIAL_NO           ' || gc_ind ||
			'SITE_ADDRESS_1      ' || gc_ind ||
			'g1_address1         ' || gc_ind ||
			'SITE_ADDRESS_2      ' || gc_ind ||
			'g1_address2         ' || gc_ind ||
			'SITE_CITY           ' || gc_ind ||
			'g1_city             ' || gc_ind ||
			'SITE_STATE          ' || gc_ind ||
			'g1_state            ' || gc_ind ||
            'SITE_ZIP_CODE       ' || gc_ind ||
			'g1_postal_code      ' || gc_ind ||
			'g1_county           ' || gc_ind ||
			'g1_addr_error       ' || gc_ind ||
			'g1_addr_code        ' || gc_ind ||
			'g1_ws_error         ' || gc_ind ||
			'device_site_seq     ' || gc_ind ||
			'cdh_site_seq	     ' || gc_ind ||
			'device_ship_site_id ' || gc_ind ||
			'cdh_ship_site_id	 '  
			);
	
	
	for i_rec in C1
	loop
	  l_g1_address1          := null;
	  l_g1_address2          := null;
	  l_g1_city              := null;
	  l_g1_state             := null;
	  l_g1_postal_code       := null;
	  l_g1_county            := null;
	  l_g1_addr_error        := null;
	  l_g1_ws_error          := null;
	  l_device_site_seq      := null;
	  l_cdh_site_seq         := null;
	  l_device_ship_site_id  := null;
	  l_cdh_ship_site_id     := null;
	  	
      insert into XX_CS_MPS_AVF_LOAD_STG
      (
         BATCH_ID                 
        ,SERIAL_NO           
        ,IP_ADDRESS          
        ,SITE_CONTACT        
        ,SITE_CONTACT_PHONE  
        ,SITE_ADDRESS_1      
        ,SITE_ADDRESS_2      
        ,SITE_CITY           
        ,SITE_STATE          
        ,SITE_ZIP_CODE       
        ,DEVICE_FLOOR        
        ,DEVICE_ROOM         
        ,DEVICE_LOCATION     
        ,DEVICE_COST_CENTER  
        ,MANUFACTURER        
        ,MODEL               
        ,MPS_REP_COMMENTS    
        ,DEVICE_JIT          
        ,PROGRAM_TYPE        
        ,MANAGED_STATUS      
        ,SUPPORT_COVERAGE    
        ,BSD_REP_COMMENTS    
        ,SLA_COVERAGE        
        ,DEVICE_ID           
        ,DEVICE_CONTACT      
        ,DEVICE_PHONE        
        ,CREATION_DATE       
        ,CREATED_BY          
        ,LAST_UPDATE_DATE    
        ,LAST_UPDATED_BY 
        ,PARTY_ID	
      ) values (
         i_rec.BATCH_ID           
        ,i_rec.SERIAL_NO          
        ,i_rec.IP_ADDRESS         
        ,i_rec.SITE_CONTACT       
        ,i_rec.SITE_CONTACT_PHONE 
        ,i_rec.SITE_ADDRESS_1     
        ,i_rec.SITE_ADDRESS_2     
        ,i_rec.SITE_CITY          
        ,i_rec.SITE_STATE         
        ,i_rec.SITE_ZIP_CODE      
        ,i_rec.DEVICE_FLOOR       
        ,i_rec.DEVICE_ROOM        
        ,i_rec.DEVICE_LOCATION    
        ,i_rec.DEVICE_COST_CENTER 
        ,i_rec.MANUFACTURER       
        ,i_rec.MODEL              
        ,i_rec.MPS_REP_COMMENTS   
        ,i_rec.DEVICE_JIT         
        ,i_rec.PROGRAM_TYPE       
        ,i_rec.MANAGED_STATUS     
        ,i_rec.SUPPORT_COVERAGE   
        ,i_rec.BSD_REP_COMMENTS   
        ,i_rec.SLA_COVERAGE       
        ,i_rec.DEVICE_ID          
        ,i_rec.DEVICE_CONTACT     
        ,i_rec.DEVICE_PHONE       
        ,i_rec.CREATION_DATE      
        ,i_rec.CREATED_BY         
        ,i_rec.LAST_UPDATE_DATE   
        ,i_rec.LAST_UPDATED_BY 
        ,i_rec.PARTY_ID	
      );	
      COMMIT;
	  
	  --Validate Address
	  XX_CS_MPS_G1_VALIDATION_PKG.validate_address (   errbuf         
	                                                 , retcode        
	                                                 , null           --, i_rec.MPS_REP_COMMENTS  
	                                                 , i_rec.SITE_ADDRESS_1    
	                                                 , i_rec.SITE_ADDRESS_2    
	                                                 , i_rec.SITE_CITY         
	                                                 , i_rec.SITE_STATE        
	                                                 , i_rec.SITE_ZIP_CODE     
	                                                 , l_g1_address1    
	                                                 , l_g1_address2    
	                                                 , l_g1_city        
	                                                 , l_g1_state       
	                                                 , l_g1_postal_code 
	                                                 , l_g1_county      
	                                                 , l_g1_addr_error  
													 , l_g1_addr_code
													 , l_g1_ws_error
                                                   );
      log_debug_msg('XX_CS_MPS_AVF_ADDR_UPLD_PKG.MAIN','After Validate ' || l_g1_addr_code);

	  --Update with g1 suggested addresses
	  update  XX_CS_MPS_AVF_LOAD_STG
	  set     g1_address_1          =  l_g1_address1   
	          ,g1_address_2         =  l_g1_address2   
	          ,g1_city              =  l_g1_city       
	          ,g1_state             =  l_g1_state      
	          ,g1_zip_code          =  l_g1_postal_code
              ,g1_addr_ver_flag     =  decode(trim(l_g1_addr_code),'2', 'E', '0', 'S', 'U')
              ,g1_addr_ver_error    =  l_g1_addr_error
              ,g1_addr_ver_comments =  l_g1_ws_error
              ,g1_addr_ver_date     =  sysdate
	  where   SERIAL_NO = i_rec.SERIAL_NO;
	  
	  COMMIT;
	  
	  open c2( i_rec.party_id, i_rec.serial_no);
	  fetch c2 into l_device_site_seq, l_cdh_site_seq, l_device_ship_site_id, l_cdh_ship_site_id;
	  
	  log_debug_msg('XX_CS_MPS_AVF_ADDR_UPLD_PKG.MAIN','l_device_site_seq:' || l_device_site_seq ||
	                                                   'l_cdh_site_seq:' || l_cdh_site_seq ||
													   'l_device_ship_site_id:' || l_device_ship_site_id ||
													   'l_cdh_ship_site_id:' || l_cdh_ship_site_id 
	               );
	  
	  --Update with g1 suggested ship site ids
	  update  XX_CS_MPS_AVF_LOAD_STG
	  set      device_site_sequence =  l_device_site_seq
              ,cdh_site_sequence	=  l_cdh_site_seq	
              ,device_ship_site_id  =  l_device_ship_site_id
              ,cdh_ship_site_id		=  l_cdh_ship_site_id	  
	  where   SERIAL_NO = i_rec.SERIAL_NO;
	  
	  
      close c2;	  
	  
	  	output( i_rec.BATCH_ID          || gc_ind ||
	            i_rec.SERIAL_NO         || gc_ind ||
			    i_rec.SITE_ADDRESS_1    || gc_ind ||
			    l_g1_address1           || gc_ind ||
			    i_rec.SITE_ADDRESS_2    || gc_ind ||
			    l_g1_address2           || gc_ind ||
			    i_rec.SITE_CITY         || gc_ind ||
			    l_g1_city               || gc_ind ||
			    i_rec.SITE_STATE        || gc_ind ||
			    l_g1_state              || gc_ind ||
                i_rec.SITE_ZIP_CODE     || gc_ind ||
			    l_g1_postal_code        || gc_ind ||
			    l_g1_county             || gc_ind ||
			    l_g1_addr_error         || gc_ind ||
			    l_g1_addr_code          || gc_ind ||
			    l_g1_ws_error           || gc_ind ||
			    l_device_site_seq       || gc_ind ||
			    l_cdh_site_seq	        || gc_ind ||
			    l_device_ship_site_id   || gc_ind ||
			    l_cdh_ship_site_id	   
			);
 
    end loop;
	
	--output('=============================');
	
	upd_devices_addr( errbuf     => errbuf    
                    , retcode    => retcode   
                    , p_batch_id => p_batch_id
                    );
	
    log_debug_msg('XX_CS_MPS_AVF_ADDR_UPLD_PKG.MAIN','END');
  
  EXCEPTION
    WHEN OTHERS THEN
     log_error('XX_CS_MPS_AVF_ADDR_UPLD_PKG.MAIN','MAIN: ' || sqlerrm);
  END main;
  
end XX_CS_MPS_AVF_ADDR_UPLD_PKG;
/
SHOW ERRORS;