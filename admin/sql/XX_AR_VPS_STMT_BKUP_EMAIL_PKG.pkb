create or replace PACKAGE BODY XX_AR_VPS_STMT_BKUP_EMAIL_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	     :  XX_AR_VPS_STMT_BKUP_EMAIL_PKG                                               |
-- |  RICE ID 	 :  I3108                                          			                    |
-- |  Description:                                                                          	|
-- |                                                           				                    |        
-- +============================================================================================+
-- | Version     Date          Author              Remarks                                      |
-- | =========   ===========   =============       =============================================|
-- | 1.0         18-JUL-2018   Havish Kasina       Initial version                              |
-- | 1.1         09-AUG-2018   Havish Kasina       Added vendor name in the email subject       |
-- | 1.2         21-AUG-2018   Havish Kasina       Added the translation to get the CC Email ID |
-- +============================================================================================+

gc_debug 	                VARCHAR2(2);
gn_request_id               fnd_concurrent_requests.request_id%TYPE;
gn_user_id                  fnd_concurrent_requests.requested_by%TYPE;
gn_login_id    	            NUMBER;
gc_error_loc                VARCHAR2(100);  
gc_error_msg                VARCHAR2(1000);
gc_errcode                  VARCHAR2(100);

TYPE t_num IS TABLE OF NUMBER
 INDEX BY BINARY_INTEGER;
 
TYPE t_v100 IS TABLE OF VARCHAR2(100)
 INDEX BY BINARY_INTEGER;
 
TYPE blob_data_type IS RECORD (row_id                 T_NUM,
                               file_name  		      t_v100
		                      );

-- +============================================================================================+
-- |  Name	 : Log Exception                                                                    |
-- |  Description: The log_exception procedure logs all exceptions                              |
-- =============================================================================================|
PROCEDURE log_exception (p_program_name       IN  VARCHAR2
                        ,p_error_location     IN  VARCHAR2
		                ,p_error_msg          IN  VARCHAR2)
IS
ln_login     NUMBER   :=  FND_GLOBAL.LOGIN_ID;
ln_user_id   NUMBER   :=  FND_GLOBAL.USER_ID;
BEGIN
XX_COM_ERROR_LOG_PUB.log_error(
			     p_return_code             => FND_API.G_RET_STS_ERROR
			    ,p_msg_count               => 1
			    ,p_application_name        => 'XXFIN'
			    ,p_program_type            => 'Custom Messages'
			    ,p_program_name            => p_program_name
			    ,p_attribute15             => p_program_name
			    ,p_program_id              => null
			    ,p_module_name             => 'AP'
			    ,p_error_location          => p_error_location
			    ,p_error_message_code      => null
			    ,p_error_message           => p_error_msg
			    ,p_error_message_severity  => 'MAJOR'
			    ,p_error_status            => 'ACTIVE'
			    ,p_created_by              => ln_user_id
			    ,p_last_updated_by         => ln_user_id
			    ,p_last_update_login       => ln_login
			    );

EXCEPTION 
WHEN OTHERS 
THEN 
    fnd_file.put_line(fnd_file.log, 'Error while writing to the log ...'|| SQLERRM);
END log_exception;

/*********************************************************************
* Procedure used to log based on gb_debug value or if p_force is TRUE.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program log file.  Will prepend
* timestamp to each message logged.  This is useful for determining
* elapse times.
*********************************************************************/
PROCEDURE print_debug_msg (p_message   IN VARCHAR2,
                           p_force     IN BOOLEAN DEFAULT FALSE)
IS
    lc_message   VARCHAR2 (4000) := NULL;
BEGIN
    IF (gc_debug = 'Y' OR p_force)
    THEN
        lc_Message := p_message;
        fnd_file.put_line (fnd_file.log, lc_Message);

        IF ( fnd_global.conc_request_id = 0
            OR fnd_global.conc_request_id = -1)
        THEN
            dbms_output.put_line (lc_message);
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS
    THEN
        NULL;
END print_debug_msg;

/*********************************************************************
* Procedure used to out the text to the concurrent program.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program output file.
*********************************************************************/
PROCEDURE print_out_msg (p_message IN VARCHAR2)
IS
    lc_message   VARCHAR2 (4000) := NULL;
BEGIN
    lc_message := p_message;
    fnd_file.put_line (fnd_file.output, lc_message);

    IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1)
    THEN
        dbms_output.put_line (lc_message);
    END IF;
EXCEPTION
WHEN OTHERS
THEN
    NULL;
END print_out_msg;

FUNCTION get_address(addr_list IN OUT VARCHAR2) RETURN VARCHAR2 IS
    addr VARCHAR2(256);
    i    pls_integer;
    FUNCTION lookup_unquoted_char(str  IN VARCHAR2,
                  chrs IN VARCHAR2) RETURN pls_integer AS
      c            VARCHAR2(5);
      i            pls_integer;
      len          pls_integer;
      inside_quote BOOLEAN;
    BEGIN
       inside_quote := false;
       i := 1;
       len := length(str);
       WHILE (i <= len) LOOP
     c := substr(str, i, 1);
     IF (inside_quote) THEN
       IF (c = '"') THEN
         inside_quote := false;
       ELSIF (c = '\') THEN
         i := i + 1; -- Skip the quote character
       END IF;
       GOTO next_char;
     END IF;
     IF (c = '"') THEN
       inside_quote := true;
       GOTO next_char;
     END IF;
     IF (instr(chrs, c) >= 1) THEN
        RETURN i;
     END IF;
     <<next_char>>
     i := i + 1;
       END LOOP;
       RETURN 0;
    END;
  BEGIN
    addr_list := ltrim(addr_list);
    i := lookup_unquoted_char(addr_list, ',;');
    IF (i >= 1) THEN
      addr      := substr(addr_list, 1, i - 1);
      addr_list := substr(addr_list, i + 1);
    ELSE
      addr := addr_list;
      addr_list := '';
    END IF;
    i := lookup_unquoted_char(addr, '<');
    IF (i >= 1) THEN
      addr := substr(addr, i + 1);
      i := instr(addr, '>');
      IF (i >= 1) THEN
    addr := substr(addr, 1, i - 1);
      END IF;
    END IF;
    RETURN addr;
END;
  -- Write a MIME header
PROCEDURE write_mime_header(conn  IN OUT NOCOPY utl_smtp.connection,
                name  IN VARCHAR2,
                value IN VARCHAR2) IS
BEGIN
  utl_smtp.write_data(conn, name || ': ' || value || utl_tcp.CRLF);
END;
  
  ------------------------------------------------------------------------
PROCEDURE write_text(conn    IN OUT NOCOPY utl_smtp.connection,
             message IN VARCHAR2) IS
BEGIN
  utl_smtp.write_data(conn, message);
END;

-- +===============================================================================================+
-- |  Name	 : begin_session                                                                       |                 	
-- |  Description: This procedure is to begin session                                              |
-- ================================================================================================|
  -- Mark a message-part boundary.  Set <last> to TRUE for the last boundary.
  PROCEDURE write_boundary(conn  IN OUT NOCOPY utl_smtp.connection,
               last  IN            BOOLEAN DEFAULT FALSE) AS
  BEGIN
    IF (last) THEN
      utl_smtp.write_data(conn, LAST_BOUNDARY);
    ELSE
      utl_smtp.write_data(conn, FIRST_BOUNDARY);
    END IF;
  END;

-- +===============================================================================================+
-- |  Name	 : begin_session                                                                       |                 	
-- |  Description: This procedure is to begin session                                              |
-- ================================================================================================|
FUNCTION begin_session 
RETURN utl_smtp.connection IS
conn utl_smtp.connection;
BEGIN
    -- open SMTP connection
    conn := utl_smtp.open_connection(smtp_host, smtp_port);
    utl_smtp.helo(conn, smtp_domain);
    RETURN conn;
END;

-- +===============================================================================================+
-- |  Name	 : begin_mail_in_session                                                               |                 	
-- |  Description: This procedure is to begin email session                                        |
-- ================================================================================================|
PROCEDURE begin_mail_in_session(conn       IN OUT NOCOPY utl_smtp.connection,
                                sender     IN VARCHAR2,
                                recipients IN VARCHAR2,
                                cc_recipients IN VARCHAR2,
                                subject    IN VARCHAR2,
                                mime_type  IN VARCHAR2  DEFAULT 'text/plain',
                                priority   IN PLS_INTEGER DEFAULT NULL) IS
my_recipients VARCHAR2(32767) := recipients;
my_cc_recipients VARCHAR2(32767) := cc_recipients ;
my_sender     VARCHAR2(32767) := sender;
BEGIN
    -- Specify sender's address (our server allows bogus address
    -- as long as it is a full email address (xxx@yyy.com).
    utl_smtp.mail(conn, get_address(my_sender));
    -- Specify recipient(s) of the email.
    WHILE (my_recipients IS NOT NULL) LOOP
      utl_smtp.rcpt(conn, get_address(my_recipients));
    END LOOP;
    -- Specify cc recipient(s) of the email.
    WHILE (my_cc_recipients IS NOT NULL) LOOP
      utl_smtp.rcpt(conn, get_address(my_cc_recipients));
    END LOOP;
    -- Start body of email
    utl_smtp.open_data(conn);
    -- Set "From" MIME header
    write_mime_header(conn, 'From', sender);
    -- Set "To" MIME header
    write_mime_header(conn, 'To', recipients);
    -- Set "Cc" MIME header
    write_mime_header(conn, 'Cc', cc_recipients);
    -- Set "Subject" MIME header
    write_mime_header(conn, 'Subject', subject);
    -- Set "Content-Type" MIME header
    write_mime_header(conn, 'Content-Type', mime_type);
    -- Set "X-Mailer" MIME header
    write_mime_header(conn, 'X-Mailer', MAILER_ID);
    -- Set priority:
    --   High      Normal       Low
    --   1     2     3     4     5
    IF (priority IS NOT NULL) THEN
      write_mime_header(conn, 'X-Priority', priority);
    END IF;
    -- Send an empty line to denotes end of MIME headers and
    -- beginning of message body.
    utl_smtp.write_data(conn, utl_tcp.CRLF);
    IF (mime_type LIKE 'multipart/mixed%') THEN
      write_text(conn, 'This is a multi-part message in MIME format.' ||
    utl_tcp.crlf);
    END IF;
END;

-- +===============================================================================================+
-- |  Name	 : begin_mail                                                                          |                 	
-- |  Description: This procedure is to begin email                                                |
-- ================================================================================================|
FUNCTION begin_mail(sender        IN VARCHAR2,
                    recipients    IN VARCHAR2,
                    cc_recipients IN VARCHAR2,
                    subject       IN VARCHAR2,
                    mime_type     IN VARCHAR2    DEFAULT 'text/plain',
                    priority      IN PLS_INTEGER DEFAULT NULL)
RETURN utl_smtp.connection IS
conn utl_smtp.connection;
BEGIN
    conn := begin_session;
    begin_mail_in_session(conn, sender, recipients,cc_recipients, subject, mime_type,
      priority);
    RETURN conn;
  END;

-- +===============================================================================================+
-- |  Name	 : end_mail_in_session                                                                 |                 	
-- ================================================================================================|  
PROCEDURE end_mail_in_session(conn IN OUT NOCOPY utl_smtp.connection) IS
BEGIN
  utl_smtp.close_data(conn);
END;

-- +===============================================================================================+
-- |  Name	 : end_session                                                                         |                 	
-- ================================================================================================|    
PROCEDURE end_session(conn IN OUT NOCOPY utl_smtp.connection) IS
BEGIN
  utl_smtp.quit(conn);
END;

-- +===============================================================================================+
-- |  Name	 : end_mail                                                                         |                 	
-- ================================================================================================|      
PROCEDURE end_mail(conn IN OUT NOCOPY utl_smtp.connection) IS
BEGIN
    end_mail_in_session(conn);
    end_session(conn);
END;

-- +===============================================================================================+
-- |  Name	 : xx_email_excel                                                                      |                 	
-- |  Description: This procedure is to email the statement and Backup files                       |
-- ================================================================================================|

PROCEDURE xx_email_excel(conn         IN OUT NOCOPY utl_smtp.connection,
                         p_directory  IN VARCHAR2,
                         p_filename   IN VARCHAR2)
IS

  pos 			     PLS_INTEGER := 1; /* pointer for each piece */
  data 			     RAW(2100);     
  err_num 		     NUMBER;
  err_msg 		     VARCHAR2(100);
  v_mime_type_bin 	 VARCHAR2(30) := 'application/vnd.ms-excel';
  bfile_handle 	     BFILE;
  bfile_len 	     NUMBER;
  read_bytes 	     NUMBER;
  line 		         VARCHAR2 (1000);

BEGIN

    xx_pa_pb_mail.begin_attachment(conn => conn,
		                           mime_type => 'application/vnd.ms-excel',
	                               inline => TRUE,
        	                       filename => p_filename, 
	                               transfer_enc => 'base64');

    bfile_handle := BFILENAME(p_directory,p_filename);
    bfile_len := DBMS_LOB.getlength (bfile_handle);
    pos := 1;
    DBMS_LOB.OPEN (bfile_handle, DBMS_LOB.lob_readonly);

    -- Append the file contents to the end of the message

    LOOP
    -- If it is a binary file, process it 57 bytes at a time,
    -- reading them in with a LOB read, encoding them in BASE64,
    -- and writing out the encoded binary string as raw data

        IF pos + 57 - 1 > bfile_len  
	    THEN
           read_bytes := bfile_len - pos + 1;
        ELSE
           read_bytes := 57;
        END IF;

        DBMS_LOB.READ (bfile_handle, read_bytes, pos, DATA);
        xx_pa_pb_mail.write_raw( conn    => conn,
                                 message => utl_encode.base64_encode(data )
				               );
        pos := pos + 57;

        IF pos > bfile_len 
	    THEN
            EXIT;
         END IF;

    END LOOP;
    DBMS_LOB.CLOSE (bfile_handle);
    xx_pa_pb_mail.end_attachment(conn => conn);
EXCEPTION
    WHEN NO_DATA_FOUND
	THEN
        NULL;
    WHEN OTHERS 
	THEN
        err_num := SQLCODE;
        err_msg := SQLERRM;
        fnd_file.put_line (fnd_file.log,'Error code ' || err_num || ': ' || err_msg);
END xx_email_excel;

-- +===============================================================================================+
-- |  Name	 : process_documents                                                                   |                 	
-- |  Description: This procedure is to get all the VPS Vendor Details                             |
-- ================================================================================================|
							  
PROCEDURE process_documents( p_errbuf         OUT  VARCHAR2
                            ,p_retcode        OUT  VARCHAR2   
                            ,p_debug          IN   VARCHAR2
							)
AS 

   -- Cursor to fetch the Penny adjustments
    CURSOR get_vps_details 
	IS
       SELECT NVL(SUBSTR(hca.account_name,1,INSTR(hca.account_name, '-',1) -1),account_name)vendor_name ,
              SUBSTR(hca.orig_system_reference,1,INSTR(hca.orig_system_reference, '-',1)-1) vendor_num ,
	          hca.cust_account_id,
	          XX_FIN_VPS_STMT_EMAIL(hca.party_id) to_email,
			  'vendorprograms@officedepot.com' from_email
         FROM hz_cust_accounts_all hca ,
              xx_cdh_cust_acct_ext_b extb,
              ego_attr_groups_v eagv 
        WHERE 1 = 1
          AND hca.cust_account_id  =extb.cust_account_id
          AND extb.attr_group_id   =eagv.attr_group_id
		  -- AND SUBSTR(hca.orig_system_reference,1,INSTR(hca.orig_system_reference, '-',1)-1) IN ('100','109')
          AND eagv.attr_group_type ='XX_CDH_CUST_ACCOUNT'
          AND eagv.attr_group_name = 'XX_CDH_VPS_CUST_ATTR'
          AND UPPER(c_ext_attr4)  IN ('YES','Y')
		  AND XX_FIN_VPS_STMT_EMAIL(hca.party_id) IS NOT NULL;
		  
	-- Cursor to get the Backup details
	CURSOR get_backup_details(p_vendor_num  VARCHAR2)
	IS
	  SELECT bkdata.program_id program_id
            ,bkdata.vendor_number vendor_num
            ,FND_PROFILE.VALUE('XX_COMN_SMTP_MAIL_SERVER') smtp_server
            ,'vendorprograms@officedepot.com' from_mail
            ,(SELECT listagg(hcp.email_address,', ')
                     within group (order by hca.party_id) as list    
                FROM hz_cust_accounts hca
                    ,hz_parties obj
                    ,hz_relationships rel
                    ,hz_org_contacts hoc
                    ,hz_contact_points hcp
                    ,hz_parties sub
               WHERE 1=1
                 AND bkdata.vendor_number || '-VPS' = hca.orig_system_reference
                 AND hca.party_id          = rel.object_id
                 AND hca.party_id          = obj.party_id
                 AND rel.subject_id        = sub.party_id
                 AND rel.relationship_type = 'CONTACT'
                 AND rel.directional_flag  = 'F'
                 AND rel.relationship_id   =hoc.party_relationship_id
                 AND UPPER(hoc.job_title) like 'CORE%NON%BACKUP%BILLING%'
                 AND rel.party_id          = hcp.owner_table_id
                 AND hcp.owner_table_name  = 'HZ_PARTIES'
             )to_email_address
       FROM xx_fin_vps_stmt_backup_data bkdata
      WHERE 1 = 1 
        AND bkdata.vendor_number = p_vendor_num
        AND bkdata.backup_type in ('SKUS', 'INVOICES')
      GROUP BY bkdata.program_id
              ,bkdata.vendor_number;
    
	/* Local Variables */
	lv_file_name_cc                  VARCHAR2 (100);
    lv_dest_loc                      BLOB;
    lv_src_loc                       BFILE;
    ex                               NUMBER;
	ex1                              NUMBER;
    temp_os_file                     BFILE;
    lv_directory_name                VARCHAR2 (250) := 'XXVPS_OUTBOUND_EMAIL';
    lv_src_filename                  VARCHAR2 (250);
    lv_user_id                       VARCHAR2 (150);
    lv_request_id                    NUMBER;
    v_sub_req                        NUMBER;
    v_cp_description                 VARCHAR2(100);
    v_user_id                        NUMBER;
    lv_request_num                   NUMBER;
	ln_stmt_request_id               NUMBER;
	ln_backup_request_id             NUMBER;
	lv_file_location                 VARCHAR2 (250);
	l_blob_data                      blob_data_type;
    indx                             NUMBER;
	-- Constants                     
    lv_mime_type_bin                 VARCHAR2 (30) := 'application/xls';
    lv_crlf                          VARCHAR2 (2) := CHR (13) || CHR (10);
	lc_conn                          UTL_SMTP.connection;
	ln_conc_file_copy_request_id     NUMBER;
    lc_dest_file_name                VARCHAR2(200);
	lc_source_file_name              VARCHAR2(200);
	lc_mail_cc                       VARCHAR2(100);
BEGIN

    lv_file_name_cc        := NULL;
    lv_dest_loc            := NULL;
    lv_src_loc             := NULL;
    -- ex                     := 0;
    temp_os_file           := NULL;
    lv_src_filename        := NULL;
    lv_user_id             := NULL;
    ln_stmt_request_id     := 0;
	ln_backup_request_id   := 0;
	lv_file_location       := NULL;
    v_sub_req              := NULL;
    v_cp_description       := NULL;
    v_user_id              := NULL;
    lv_request_num         := NULL;
	lc_mail_cc             := NULL;
	
	-- To get the CC email id
	BEGIN
	     SELECT target_value2 
		   INTO lc_mail_cc
           FROM xx_fin_translatedefinition xftd
               ,xx_fin_translatevalues xftv
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name ='OD_VPS_TRANSLATION'
            AND source_value1='VPS_CUST_STATEMENTS'
            AND NVL (xftv.enabled_flag, 'N') = 'Y';
	EXCEPTION
	WHEN OTHERS
	THEN
	    lc_mail_cc := 'vendorprogramsar@officedepot.com';
	END;
	
	
	    -- Get the BLOB
	    FOR x IN get_vps_details
	    LOOP
	      -- l_blob_data.delete;
		  l_blob_data.row_id.delete;
	      l_blob_data.file_name.delete;
		  ex := 0;
		  fnd_file.put_line(fnd_file.log,'                          ');
	      fnd_file.put_line(fnd_file.log,'Processing Vendor Number :'||x.vendor_num);
	      
	      fnd_file.put_line(fnd_file.log,'Directory Name: '||lv_directory_name);
	       
	      -- To derive the File Name
	      lv_src_filename := 'ODVPSCUSTOMERSTMT_'||x.vendor_num||'.xls';
	      indx:= 1;
	      temp_os_file := BFILENAME (lv_directory_name, lv_src_filename);
          ex := DBMS_LOB.fileexists (temp_os_file);
	      
	      IF ex =1 
	      THEN
	          l_blob_data.row_id(indx) := indx;
	          l_blob_data.file_name(indx) := lv_src_filename;
			  fnd_file.put_line(fnd_file.log,'Statement File Name is '||lv_src_filename);
			  
			  lc_conn := begin_mail(sender             => x.from_email,
                                recipients         => x.to_email,
                                cc_recipients      => lc_mail_cc,
                                subject            => 'Office Depot Customer Statement and Invoice SKU Backup - '||x.vendor_name||' - '||x.vendor_num,
                                mime_type          => xx_pa_pb_mail.multipart_mime_type
                               );
	          -- fnd_file.put_line(fnd_file.log,'Test 20');								 
	          xx_pa_pb_mail.attach_text( conn => lc_conn,
                                         data => 'Attached please find customer Statement and Backup requested.'||lv_crlf||
                                                 'Thank you for your continued business.'
                                       );
	      END IF;
	  	  
	        FOR y IN get_backup_details(p_vendor_num => x.vendor_num)
	        LOOP
	            IF x.vendor_num = y.vendor_num
		        THEN
		            lv_src_filename := NULL;
	                lv_src_filename := 'ODVPSCUSTOMERBKUP_'||y.vendor_num||'_'||y.program_id||'.xls';	
		      	    ex1                     := 0;
                    temp_os_file           := NULL;
		            lv_dest_loc            := NULL;
            
                    temp_os_file := BFILENAME (lv_directory_name, lv_src_filename);
                    ex1 := DBMS_LOB.fileexists (temp_os_file);
	                
		      	  IF ex1 = 1
		      	  THEN
		      	      indx := indx + 1;	
		      	      l_blob_data.row_id(indx) := indx;
	                  l_blob_data.file_name(indx) := lv_src_filename;
					  fnd_file.put_line(fnd_file.log,'Backup File Name: '||lv_src_filename);
		      	  END IF;
		        END IF;

	        END LOOP; -- get_backup_details

          FOR i IN 1..l_blob_data.row_id.COUNT
          LOOP 	
		    fnd_file.put_line(fnd_file.log,'files to be attached: '||l_blob_data.file_name(i));
            xx_email_excel (conn         => lc_conn,
                            p_directory  => lv_directory_name,
                            p_filename   => l_blob_data.file_name(i)
		    			    );
			
			lc_source_file_name := NULL;
			lc_dest_file_name := NULL;
			lc_source_file_name := '$XXFIN_DATA/outbound/vps/'||l_blob_data.file_name(i);
            lc_dest_file_name   := '$XXFIN_ARCHIVE/outbound/vps/' || SUBSTR(l_blob_data.file_name(i),1,LENGTH(l_blob_data.file_name(i)) - 4)||'_' 
                                                   || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.xls';
                                                   
            ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN',
          					                                           'XXCOMFILCOPY',
          					   		                                   '',
          							                                   '',
          							                                   FALSE,
          							                                   lc_source_file_name,   -- Source File Name
          							                                   lc_dest_file_name,     -- Dest File Name
          							                                   '',
          							                                   '',
          							                                   'Y'   --Deleting the Source File
	    						                                       ); 
			
	      END LOOP; -- l_blob_data
		  -- Calling end_mail function
		  
		  IF ex > 0
		  THEN
              end_mail (conn => lc_conn);
			  fnd_file.put_line(fnd_file.log,'Email sent to Vendor :'||x.vendor_num);
          END IF;			  
		  
        END LOOP; -- get_vps_details	
	
EXCEPTION
WHEN OTHERS
THEN
    fnd_file.put_line(fnd_file.log,'Error Message :'||SQLERRM);
	
END;
 
END XX_AR_VPS_STMT_BKUP_EMAIL_PKG;
/
SHOW ERRORS;