SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_AR_COLLAUTODIAL_PKG AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_AR_COLLAUTODIAL_PKG                                          |
-- | Description      : This Program will collect data and write to a .csv   |
-- |                    file and send an email once program completes        |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |DRAFT 1A   19-SEP-2011   Bapuji Nanapaneni Initial draft version         |
-- |      1.1  13-NOV-2015   Vasu Raparla      Removed Schema References     |
-- |                                            for R.12.2                   |
-- +=========================================================================+

-- +===================================================================+
-- | Name  : Process_coll_data                                         |
-- | Description     : To get get all OPEN status payments and wirte   |
-- |                   to a .csv file for collections                  |
-- |                                                                   |
-- | Parameters      : p_collector_name        IN -> pass coll name    |
-- |                   p_collector_group       IN -> pass coll group   |
-- |                   p_status                IN -> pass status code  |
-- |                   p_email_from            IN -> email from        |
-- |                   p_email_to              IN -> email to          |
-- |                   p_email_cc_to           IN -> email cc to       |
-- |                   p_debug_level           IN -> debug lavel       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Process_coll_data( x_retcode             OUT NOCOPY  NUMBER
                           , x_errbuf              OUT NOCOPY  VARCHAR2
                           , p_collector_group      IN         NUMBER
                           , p_collector_name       IN         NUMBER
                           , p_status               IN         VARCHAR2
                           , p_email_from           IN         VARCHAR2
                           , p_email_to             IN         VARCHAR2
                           , p_email_cc_to          IN         VARCHAR2
                           , p_debug_level          IN         NUMBER
                           ) IS
				   
CURSOR c_collection_extract ( p_coll_group_id  IN NUMBER
                            , p_coll_name_id IN NUMBER
                            , p_status_code   IN VARCHAR2
                            ) IS 
SELECT haou.name                                                             op_unit
     , hca.account_number                                                    customer_number
     , hca.cust_account_id                                                   customer_id
     , SUBSTR(REPLACE(hp.party_name, ',', NULL),1,40)                        customer_name
     , REPLACE(hcus.location, ',', NULL)                                     bill_to_location
     , hcus.site_use_id                                                      site_use_id
     , REPLACE(jrre1.source_name, ',', NULL)                                 collector_name
     , REPLACE(jrg.group_name, ',', NULL)                                    group_name
     , SUM(aps.acctd_amount_due_remaining)                                   amount_past_due
     , SUBSTR(REPLACE(REPLACE(pc.raw_phone_number,'-', NULL),' ',NULL),1,10) conatct_phone_number
     , SUBSTR(REPLACE(pa.person_first_name,',',NULL),1,10)                   contact_fist_name
     , SUBSTR(REPLACE(pa.person_last_name,',',NULL),1,20)                    contact_last_name
     , SUBSTR(REPLACE(istw.name,',',NULL),1,80)                              work_item_name
  FROM jtf_rs_groups_vl            jrg
     , jtf_rs_group_members_vl     jrgm
     , jtf_rs_resource_extns       jrre1
     , iex_strategy_work_items     iswi
     , iex_stry_temp_work_items_tl istw
     , iex_strategies              isst
     , iex_strategy_templates_tl   istt
     , iex_stry_temp_work_items_b  istb  
     , hz_cust_accounts            hca
     , hz_cust_acct_sites_all      hcas
     , hz_cust_site_uses_all       hcus
     , hz_parties                  hp
     , hr_all_organization_units   haou
     , iex_delinquencies           idq
     , ar_payment_schedules        aps 
     , iex_lookups_v               ilv1
     , hz_contact_points        pc 
     , hz_parties               pa
     , hz_relationships         rel
     , hz_party_sites_ext_b     psext
     , hz_cust_account_roles    hc
     , hz_role_responsibility     hrr
     , hz_org_contacts          hoc
     , hz_cust_accounts         hca1
     , ar_lookups                  look
     , ar_lookups                  look_purpose
 WHERE jrg.group_id                                       = NVL(p_coll_group_id,jrg.group_id)
   AND iswi.resource_id                                   = NVL(p_coll_name_id,iswi.resource_id)
   AND iswi.status_code                                   = NVL(p_status_code,iswi.status_code)
   AND TRUNC(NVL(jrg.end_date_active,SYSDATE+1))          > TRUNC(SYSDATE) 
   AND jrgm.group_id                                      = jrg.group_id
   AND UPPER(NVL(jrgm.delete_flag,'N'))                   = 'N' 
   AND jrre1.resource_id                                  = jrgm.resource_id
   AND TRUNC(NVL(jrre1.end_date_active,SYSDATE+1))        > TRUNC(SYSDATE)
   AND iswi.resource_id                                   = jrre1.resource_id
   AND iswi.work_item_template_id                         = istw.work_item_temp_id
   AND iswi.strategy_temp_id                              = istt.strategy_temp_id
   AND iswi.strategy_id                                   = isst.strategy_id
   AND isst.customer_site_use_id                          = hcus.site_use_id
   AND hcas.cust_acct_site_id                             = hcus.cust_acct_site_id
   AND hca.cust_account_id                                = hcas.cust_account_id
   AND hca.party_id                                       = hp.party_id
   AND hcus.org_id                                        = haou.organization_id
   AND TRUNC(NVL(hca.account_termination_date,SYSDATE+1)) > TRUNC(SYSDATE)     
   AND istw.language                                      = USERENV('LANG')
   AND istt.language                                      = USERENV('LANG')
   AND isst.customer_site_use_id                          = idq.customer_site_use_id
   AND idq.payment_schedule_id                            = aps.payment_schedule_id 
   AND aps.status                                         = 'OP'      
   AND istw.work_item_temp_id                             = istb.work_item_temp_id  
   AND istb.work_type                                    <> 'AUTOMATIC'
   AND istb.category_type                                 = ilv1.lookup_code
   AND ilv1.lookup_type                                   = 'IEX_STRATEGY_WORK_CATEGORY'
   AND ilv1.meaning                                       = 'Phone Call'
   AND idq.status                                        IN ('DELINQUENT','PREDELINQUENT') 
   AND rel.party_id                                       = pc.owner_table_id
   AND pc.owner_table_name                                = 'HZ_PARTIES'
   AND rel.subject_type                                   = 'PERSON'
   AND rel.object_type                                    = 'ORGANIZATION'
   AND rel.subject_id                                     = pa.party_id
   AND rel.relationship_id                                = hoc.party_relationship_id(+)
   AND psext.attr_group_id(+)                             = 169
   AND psext.n_ext_attr1(+)                               = rel.relationship_id
   AND hc.party_id(+)                                     = rel.party_id
   AND hca1.party_id(+)                                   = rel.object_id
   AND hca1.attribute18(+)                                = 'CONTRACT'
   AND pc.status                                          = 'A'
   AND pa.status                                          = 'A'
   AND rel.status                                         = 'A'
   AND hc.status(+)                                       = 'A'
   AND current_role_state(+)                              = 'A' 
   AND pc.contact_point_purpose                           = 'COLLECTIONS'
   AND hc.cust_acct_site_id                               = hcas.cust_acct_site_id
   AND NVL(pc.phone_line_type, pc.contact_point_type)     = LOOK.LOOKUP_CODE
   AND ((look.lookup_type                                 = 'COMMUNICATION_TYPE'
   AND look.lookup_code                                  IN ('PHONE','TLX','EMAIL','WEB'))
    OR (look.lookup_type                                  = 'PHONE_LINE_TYPE') )
   AND (pc.contact_point_purpose                          = LOOK_PURPOSE.LOOKUP_CODE
   AND look_purpose.lookup_type                           = 'CONTACT_POINT_PURPOSE')
   AND look.meaning                                       = 'Telephone'
   AND hc.cust_account_role_id                            = hrr.cust_account_role_id
   AND hrr.responsibility_type                            = 'DUN'
   AND pa.party_name                                   IS NOT NULL
   AND pc.raw_phone_number                             IS NOT NULL
GROUP BY haou.name                               
     , hca.account_number
     , hca.cust_account_id 	 
     , SUBSTR(REPLACE(hp.party_name, ',', NULL),1,40)       
     , REPLACE(hcus.location, ',', NULL)       
     , hcus.site_use_id 
     , REPLACE(jrre1.source_name, ',', NULL)   
     , REPLACE(jrg.group_name, ',', NULL) 
     , SUBSTR(REPLACE(REPLACE(pc.raw_phone_number,'-', NULL),' ',NULL),1,10)
     , SUBSTR(REPLACE(pa.person_first_name,',',NULL),1,10)                  
     , SUBSTR(REPLACE(pa.person_last_name,',',NULL),1,20)   
     , SUBSTR(REPLACE(istw.name,',',NULL),1,80)         
ORDER BY hca.account_number	
       , REPLACE(jrre1.source_name, ',', NULL) ;
   
/* Local Variable Declaration */
  lc_file  UTL_FILE.FILE_TYPE;
  l_conn  UTL_TCP.connection;
  l_email utl_smtp.connection;
  
  lc_file_name               VARCHAR2(100);	
  ln_collector_name_id       NUMBER;
  ln_collector_group_id      NUMBER;   
  ld_item_start_date_low     DATE;
  ld_item_start_date_high    DATE;
  ld_item_end_date_low       DATE;
  ld_item_end_date_high      DATE;
  lc_status_code             VARCHAR2(100);
  ld_item_days_grt           NUMBER;
  lc_delimeter               VARCHAR2(1) := ',';
  
  v_directory_name           VARCHAR2(100) := 'XXFIN_OUTBOUND';
  lb_pos                     PLS_INTEGER := 1; /* pointer for each piece */
  l_bfile_handle             BFILE;
  ln_bfile_len 	             NUMBER;
  lr_data 		             RAW(2100);
  ln_read_bytes 	         NUMBER;
  lc_data                    VARCHAR2 (2000);
  lc_cont_name               VARCHAR2(240);
  lc_cont_p_no               VARCHAR2(30);
  lc_cont_num                VARCHAR2(30);
  lc_mail_from               VARCHAR2(500); 
  lc_mail_to                 VARCHAR2(500); 
  lc_mail_cc_to              VARCHAR2(500); 
  lc_subject                 VARCHAR2(500);
  ln_open_ar_amount          NUMBER;
  ln_org_id         CONSTANT NUMBER := FND_PROFILE.VALUE('ORG_ID');
  lc_opu                     VARCHAR2(100);
  --ln_user                     NUMBER := 29497;
  --ln_resp                     NUMBER := 51050; --51264 for CA OU
  --ln_appl                     NUMBER := 660;
  
BEGIN
   -- FND_GLOBAL.apps_initialize(ln_user,ln_resp,ln_appl);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'BEGIN OF PROGRAM  :::');
    ln_collector_name_id       := p_collector_name;
    ln_collector_group_id      := p_collector_group;
    lc_status_code             := p_status;
    lc_mail_from               := p_email_from;
    lc_mail_to                 := p_email_to;
    lc_mail_cc_to              := p_email_cc_to;
	SELECT name
      INTO lc_opu	
	  FROM hr_all_organization_units 
	 WHERE organization_id = FND_PROFILE.VALUE('ORG_ID');
	 
	SELECT lc_opu||'_OD_AR_AUTO_DIALER_'||SYSDATE||'.csv'
	  INTO lc_file_name 
	  FROM DUAL;
    BEGIN
        IF p_debug_level > 0 THEN
      --      dbms_application_info.set_client_info(404);
			
	        FND_FILE.PUT_LINE(FND_FILE.LOG,'FILE NAME               :::'||lc_file_name);
	        FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_collector_name_id    :::'||ln_collector_name_id);
	        FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_collector_group_id   :::'||ln_collector_group_id);
	        FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_status_code          :::'||lc_status_code);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_mail_from            :::'||lc_mail_from);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_mail_to              :::'||lc_mail_to);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_mail_cc_to           :::'||lc_mail_cc_to);
        END IF;
		
    END;

    lc_file := UTL_FILE.FOPEN( location     => v_directory_name
                             , filename     => lc_file_name
                             , open_mode    => 'w'
                             , max_linesize => 32767
                             );
   
    FOR r_collection_extract IN c_collection_extract ( ln_collector_group_id
                                                     , ln_collector_name_id
                                                     , lc_status_code
                                                     ) LOOP
         SELECT GET_AR_OPEN_AMOUNT( r_collection_extract.customer_id,r_collection_extract.site_use_id)
           INTO ln_open_ar_amount
		   FROM DUAL;		 
         UTL_FILE.PUT_LINE( lc_file
                         , r_collection_extract.customer_number      ||lc_delimeter||
                           r_collection_extract.customer_name        ||lc_delimeter||
                           r_collection_extract.bill_to_location     ||lc_delimeter||
                           r_collection_extract.contact_fist_name    ||lc_delimeter||
						   r_collection_extract.contact_last_name    ||lc_delimeter||
                           r_collection_extract.conatct_phone_number ||lc_delimeter||
                           r_collection_extract.amount_past_due      ||lc_delimeter||
						   ln_open_ar_amount                         ||lc_delimeter||
                           r_collection_extract.work_item_name       ||chr(13)
                          );
						  
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,(  r_collection_extract.customer_number      ||lc_delimeter||
                                             r_collection_extract.customer_name        ||lc_delimeter||
                                             r_collection_extract.bill_to_location     ||lc_delimeter||
                                             r_collection_extract.contact_fist_name    ||lc_delimeter||
						                     r_collection_extract.contact_last_name    ||lc_delimeter||
                                             r_collection_extract.conatct_phone_number ||lc_delimeter||
                                             r_collection_extract.amount_past_due      ||lc_delimeter||
											 ln_open_ar_amount                         ||lc_delimeter||  
                                             r_collection_extract.work_item_name       ||chr(13)
                                           ));						  
    END LOOP;
    UTL_FILE.FCLOSE(lc_file);
	
    lc_subject   := 'OD: AR Collection Auto Dialer Extract';
    l_email := xx_pa_pb_mail.begin_mail( sender        => lc_mail_from
    	                               , recipients    => lc_mail_to
    	                               , cc_recipients => lc_mail_cc_to
    	                               , subject       => lc_subject
    	                               , mime_type     => xx_pa_pb_mail.MULTIPART_MIME_TYPE
	                               );                               
    BEGIN
        xx_pa_pb_mail.begin_attachment( conn         => l_email
                                      , mime_type    => 'application/vnd.ms-excel'
                                      , inline       => TRUE
                                      , filename     => lc_file_name
                                      , transfer_enc => 'base64'
                                      );
        l_bfile_handle := BFILENAME(v_directory_name,lc_file_name);
        ln_bfile_len   := DBMS_LOB.getlength (l_bfile_handle);
        lb_pos         := 1;
        DBMS_LOB.OPEN (l_bfile_handle, DBMS_LOB.lob_readonly);

        -- Append the file contents to the end of the message
        LOOP
            -- If it is a binary file, process it 57 bytes at a time,
            -- reading them in with a LOB read, encoding them in BASE64,
            -- and writing out the encoded binary string as raw data
            IF lb_pos + 57 - 1 > ln_bfile_len  THEN
                ln_read_bytes := ln_bfile_len - lb_pos + 1;
            ELSE
                ln_read_bytes := 57;
            END IF;

            DBMS_LOB.READ (l_bfile_handle, ln_read_bytes, lb_pos, lr_data);
            xx_pa_pb_mail.write_raw( conn    => l_email
                                   , message => utl_encode.base64_encode(lr_data ) 
				                   );
            lb_pos := lb_pos + 57;

            IF lb_pos > ln_bfile_len THEN
                EXIT;
            END IF;
        END LOOP;
        DBMS_LOB.CLOSE (l_bfile_handle);
        xx_pa_pb_mail.end_attachment(conn => l_email);
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('WHEN OTHERS RAISED while writing to file :::'||SQLERRM);
			FND_FILE.PUT_LINE(FND_FILE.LOG, 'WHEN OTHERS RAISED while writing to file :::'||SQLERRM);
    END;

    xx_pa_pb_mail.end_attachment(conn    => l_email);
    lc_data := 'Find the attached file, OD AR Collection Auto Dialer feed.';
    xx_pa_pb_mail.attach_text( conn      => l_email
                             , data      => lc_data
                             , mime_type => 'text/plain'
                             );
    xx_pa_pb_mail.end_mail( conn => l_email );
 EXCEPTION
    WHEN UTL_FILE.INVALID_PATH THEN
        UTL_FILE.FCLOSE(lc_file);
        RAISE_APPLICATION_ERROR(-20000, 'File location is invalid.');
    WHEN UTL_FILE.INVALID_MODE THEN
        UTL_FILE.FCLOSE(lc_file);
        RAISE_APPLICATION_ERROR(-20001, 'The open_mode parameter in FOPEN is invalid.');
    WHEN UTL_FILE.INVALID_FILEHANDLE THEN
        UTL_FILE.FCLOSE(lc_file);
        RAISE_APPLICATION_ERROR(-20002, 'File handle is invalid.');
    WHEN UTL_FILE.INVALID_OPERATION THEN
        UTL_FILE.FCLOSE(lc_file);
        RAISE_APPLICATION_ERROR(-20003, 'File could not be opened or operated on as requested.');
    WHEN UTL_FILE.READ_ERROR THEN
        UTL_FILE.FCLOSE(lc_file);
        RAISE_APPLICATION_ERROR(-20004, 'Operating system error occurred during the read operation.');
    WHEN UTL_FILE.WRITE_ERROR THEN
        UTL_FILE.FCLOSE(lc_file);
       RAISE_APPLICATION_ERROR(-20005, 'Operating system error occurred during the write operation.');
    WHEN UTL_FILE.INTERNAL_ERROR THEN
        UTL_FILE.FCLOSE(lc_file);
        RAISE_APPLICATION_ERROR(-20006, 'Unspecified PL/SQL error.');
    WHEN UTL_FILE.CHARSETMISMATCH THEN
        UTL_FILE.FCLOSE(lc_file);
        RAISE_APPLICATION_ERROR(-20007, 'A file is opened using FOPEN_NCHAR, but later I/O ' ||
                                'operations use nonchar functions such as PUTF or GET_LINE.');
    WHEN UTL_FILE.FILE_OPEN THEN
        UTL_FILE.FCLOSE(lc_file);
        RAISE_APPLICATION_ERROR(-20008, 'The requested operation failed because the file is open.');
    WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
        UTL_FILE.FCLOSE(lc_file);
        RAISE_APPLICATION_ERROR(-20009, 'The MAX_LINESIZE value for FOPEN() is invalid; it should ' ||
                                'be within the range 1 to 32767.');
    WHEN UTL_FILE.INVALID_FILENAME THEN
        UTL_FILE.FCLOSE(lc_file);
        RAISE_APPLICATION_ERROR(-20010, 'The filename parameter is invalid.');
    WHEN UTL_FILE.ACCESS_DENIED THEN
        UTL_FILE.FCLOSE(lc_file);
        RAISE_APPLICATION_ERROR(-20011, 'Permission to access to the file location is denied.'); 
    WHEN UTL_FILE.INVALID_OFFSET THEN
        UTL_FILE.FCLOSE(lc_file);
        RAISE_APPLICATION_ERROR(-20012, 'The ABSOLUTE_OFFSET parameter for FSEEK() is invalid; ' ||
                                'it should be greater than 0 and less than the total ' ||
                                'number of bytes in the file.');
    WHEN UTL_FILE.DELETE_FAILED THEN
        UTL_FILE.FCLOSE(lc_file);
        RAISE_APPLICATION_ERROR(-20013, 'The requested file delete operation failed.');
    WHEN UTL_FILE.RENAME_FAILED THEN
        UTL_FILE.FCLOSE(lc_file);
        RAISE_APPLICATION_ERROR(-20014, 'The requested file rename operation failed.');
    WHEN OTHERS THEN
        UTL_FILE.FCLOSE(lc_file);
        RAISE;
END Process_coll_data;

-- +===================================================================+
-- | Name  : cust_contact_name                                         |
-- | Description     : To get customer contact name, number and phone  |
-- |                   for a customer id and site use id               |
-- |                                                                   |
-- | Parameters      : p_customer_id           IN -> pass customer id  |
-- |                   p_site_use_id           IN -> customer site id  |
-- |                   x_contact_name         OUT -> get cont name     |
-- |                   x_contact_phone        OUT -> get cont po num   |
-- |                   x_contact_number       OUT -> get cont number   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE cust_contact_name ( p_customer_id     IN        NUMBER
                            , p_site_use_id     IN        NUMBER
                            , x_contact_name   OUT NOCOPY VARCHAR2
                            , x_contact_phone  OUT NOCOPY VARCHAR2
                            , x_contact_number OUT NOCOPY VARCHAR2
                            ) IS

  lc_cust_cont_name VARCHAR2(200);
  lc_cust_cont_pno  VARCHAR2(30);
  lc_cust_cont_num  VARCHAR2(30);							

BEGIN
    SELECT pc.raw_phone_number
         , pa.party_name
         , hoc.contact_number
      INTO lc_cust_cont_pno
         , lc_cust_cont_name
         , lc_cust_cont_num
      FROM hz_contact_points       pc 
         , hz_parties              pa
         , hz_relationships        rel
         , hz_party_sites_ext_b    psext
         , hz_cust_account_roles   hc
         , hz_org_contacts         hoc
         , hz_cust_accounts        hca
         , hz_cust_site_uses_all   ua
         , ar_lookups                 look
         , ar_lookups                 look_purpose
		 , hz_role_responsibility     hrr
     WHERE rel.party_id                                   = pc.owner_table_id
       AND pc.owner_table_name                            = 'HZ_PARTIES'
       AND rel.subject_type                               = 'PERSON'
       AND rel.object_type                                = 'ORGANIZATION'
       AND rel.subject_id                                 = pa.party_id
       AND rel.relationship_id                            = hoc.party_relationship_id(+)
       AND psext.attr_group_id(+)                         = 169
       AND psext.n_ext_attr1(+)                           = rel.relationship_id
       AND hc.party_id(+)                                 = rel.party_id
       AND hca.party_id(+)                                = rel.object_id
       AND hca.attribute18(+)                             = 'CONTRACT'
       AND pc.status                                      = 'A'
       AND pc.primary_flag                                = 'Y'
       AND hc.primary_flag                                = 'Y'
       AND pa.status                                      = 'A'
       AND rel.status                                     = 'A'
       AND hc.status(+)                                   = 'A'
       AND current_role_state(+)                          = 'A' 
       AND pc.contact_point_purpose                       = 'COLLECTIONS'
       AND hc.cust_acct_site_id                           = ua.cust_acct_site_id
       AND NVL(pc.phone_line_type, pc.contact_point_type) = LOOK.LOOKUP_CODE
       AND ((look.lookup_type                             = 'COMMUNICATION_TYPE'
       AND look.lookup_code                              IN ('PHONE','TLX','EMAIL','WEB'))
        OR (look.lookup_type                              = 'PHONE_LINE_TYPE') )
       AND (pc.contact_point_purpose                      = LOOK_PURPOSE.LOOKUP_CODE
       AND look_purpose.lookup_type                       = 'CONTACT_POINT_PURPOSE')
       AND look.meaning                                   = 'Telephone'
	   AND hc.cust_account_role_id                        = hrr.cust_account_role_id
	   AND hrr.responsibility_type                        = 'DUN'
       AND hc.cust_account_id                             = p_customer_id
       AND ua.site_use_id                                 = p_site_use_id;

    x_contact_name   := REPLACE(lc_cust_cont_name,',',NULL);
    x_contact_phone  := REPLACE(lc_cust_cont_pno,'-',NULL);
    x_contact_number := lc_cust_cont_num;	   
EXCEPTION
    WHEN NO_DATA_FOUND THEN
	    FND_FILE.PUT_LINE(FND_FILE.LOG, 'No Data Found for site use id :::'||p_site_use_id);
	    x_contact_name   := NULL;
        x_contact_phone  := NULL;
	    x_contact_number := NULL;
		
    WHEN OTHERS THEN
        dbms_output.put_line('WHEN OTHERS RAISED for site id:::'||p_site_use_id||'SQLERRM '||SQLERRM);
	    FND_FILE.PUT_LINE(FND_FILE.LOG, 'WHEN OTHERS RAISED for site id:::'||p_site_use_id||'  SQLERRM :::'||SQLERRM);
	    x_contact_name   := NULL;
	    x_contact_phone  := NULL;
	    x_contact_number := NULL;
END cust_contact_name;

-- +===================================================================+
-- | Name  : Get_ar_open_amount                                        |
-- | Description     : To get AR INVOICE OPEN AMT                      |
-- |                   for a customer id and site use id               |
-- | Parameters      : p_customer_id           IN -> pass customer id  |
-- |                   p_site_use_id           IN -> customer site id  |
-- |                   x_ar_op_amt            OUT -> get opne amt      |
-- |                                                                   |
-- +===================================================================+
FUNCTION Get_ar_open_amount(  p_customer_id     IN        NUMBER
                           ,  p_site_use_id     IN        NUMBER
                           ) RETURN NUMBER IS
  ln_open_amt NUMBER;						   
BEGIN
    SELECT SUM(acctd_amount_due_remaining) 
	  INTO ln_open_amt
	  FROM ar_payment_schedules 
	 WHERE status               = 'OP'
	   AND customer_id          = p_customer_id
	   AND customer_site_use_id = p_site_use_id;
	   
	  RETURN(ln_open_amt);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
	    FND_FILE.PUT_LINE(FND_FILE.LOG, 'No Data Found for site use id :::'||p_site_use_id);
		RETURN(NULL);
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'WHEN OTHERS RAISED for site id:::'||p_site_use_id||'  SQLERRM :::'||SQLERRM);
		RETURN(NULL);
END Get_ar_open_amount;						  
END XX_AR_COLLAUTODIAL_PKG;
/
SHOW ERRORS PACKAGE BODY XX_AR_COLLAUTODIAL_PKG;
--EXIT;

